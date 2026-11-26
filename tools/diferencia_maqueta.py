#!/usr/bin/env python3
"""Diferencia numérica entre la maqueta y las capturas del juego (informe automático, no prueba del CI).

Uso:
  xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/captura_comparar.gd -- /tmp/capturas
  python3 tools/diferencia_maqueta.py /tmp/capturas

Para cada pantalla con maqueta (la mitad izquierda de docs/comparacion/<pantalla>_maqueta_vs_juego.png) recorta el
teléfono de la maqueta, lo lleva a 390x844 y lo compara con la captura del juego. Mide la diferencia de color
perceptual (ΔE CIE76 en CIELAB) por píxel y escribe:
  - docs/comparacion/DIFERENCIA_MAQUETA.md: % de píxeles distintos (ΔE > 20), ΔE medio y la zona que más difiere;
  - docs/comparacion/dif_<pantalla>.jpg: maqueta | juego | mapa de calor de la diferencia (12 x 26 zonas).
Requiere Pillow y numpy. Las cifras de la maqueta son ilustrativas y el juego muestra datos reales de la partida,
así que la diferencia nunca será cero: sirve para ver qué pantalla y qué zona se apartan más y si un cambio acerca o aleja.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
COMP = RAIZ / "docs" / "comparacion"
PANTALLAS = {"dia": "cmp_dia", "nacion": "cmp_nacion", "votacion": "cmp_votacion", "hito": "cmp_hito", "urbano": "cmp_urbano"}
UMBRAL = 20.0  # ΔE sobre el que un píxel cuenta como distinto (diferencia claramente visible)
TAM = (390, 844)
ZONAS = (12, 26)  # columnas x filas del mapa de calor (~32 px por zona)


def lab(rgb: np.ndarray) -> np.ndarray:
    c = rgb.astype(np.float64) / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    return np.stack([116.0 * f[..., 1] - 16.0, 500.0 * (f[..., 0] - f[..., 1]), 200.0 * (f[..., 1] - f[..., 2])], axis=-1)


def maqueta(nombre: str) -> Image.Image:
    """Teléfono de la maqueta: mitad izquierda del lado a lado, sin el fondo crema ni el marco."""
    im = Image.open(COMP / f"{nombre}_maqueta_vs_juego.png").convert("RGB")
    a = np.asarray(im)
    gris = (np.abs(a[..., 0].astype(int) - a[..., 1]) < 8) & (np.abs(a[..., 1].astype(int) - a[..., 2]) < 8) & (a[..., 0] > 150)
    div = next(x for x in range(a.shape[1] // 3, 2 * a.shape[1] // 3) if gris[:, x].mean() > 0.9)  # franja gris central
    izq = a[:, :div]
    fondo = izq[2, 2].astype(int)
    distinto = np.abs(izq.astype(int) - fondo).sum(axis=-1) > 40
    ys, xs = np.where(distinto)
    inset = 7  # marco del teléfono y esquinas redondeadas
    caja = (xs.min() + inset, ys.min() + inset, xs.max() - inset, ys.max() - inset)
    return Image.fromarray(izq).crop(caja).resize(TAM, Image.LANCZOS)


def comparar(nombre: str, capturas: Path) -> dict:
    m = maqueta(nombre)
    j = Image.open(capturas / f"{PANTALLAS[nombre]}.png").convert("RGB").resize(TAM, Image.LANCZOS)
    de = np.linalg.norm(lab(np.asarray(m)) - lab(np.asarray(j)), axis=-1)
    cw, ch = TAM[0] // ZONAS[0], TAM[1] // ZONAS[1]
    zonas = de[: ch * ZONAS[1], : cw * ZONAS[0]].reshape(ZONAS[1], ch, ZONAS[0], cw).mean(axis=(1, 3))
    fy, fx = np.unravel_index(np.argmax(zonas), zonas.shape)
    calor = np.clip(zonas / 60.0, 0, 1)
    rojo = (np.stack([calor, 0.25 * (1 - calor), 0.3 * (1 - calor)], -1) * 255).astype(np.uint8)
    mapa = Image.fromarray(rojo).resize(TAM, Image.NEAREST)
    lienzo = Image.new("RGB", (TAM[0] * 3 + 20, TAM[1]), (200, 200, 200))
    for k, im in enumerate([m, j, Image.blend(j, mapa, 0.6)]):
        lienzo.paste(im, (k * (TAM[0] + 10), 0))
    lienzo.save(COMP / f"dif_{nombre}.jpg", quality=82)
    franja = "superior" if fy < ZONAS[1] / 3 else ("media" if fy < 2 * ZONAS[1] / 3 else "inferior")
    lado = "izquierda" if fx < ZONAS[0] / 3 else ("centro" if fx < 2 * ZONAS[0] / 3 else "derecha")
    return {"pantalla": nombre, "distintos": float((de > UMBRAL).mean() * 100.0), "medio": float(de.mean()),
            "zona": f"{franja} {lado} (y ≈ {int(fy * ch)}–{int((fy + 1) * ch)} px)", "zona_de": float(zonas.max())}


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    capturas = Path(sys.argv[1])
    filas = [comparar(n, capturas) for n in PANTALLAS if (capturas / f"{PANTALLAS[n]}.png").exists()]
    filas.sort(key=lambda f: -f["distintos"])
    lineas = ["# Diferencia numérica con la maqueta", "",
              "Generado por `tools/diferencia_maqueta.py` a partir de `tests/captura_comparar.gd`. Para cada pantalla con maqueta:",
              f"porcentaje de píxeles con diferencia de color visible (ΔE CIE76 > {UMBRAL:.0f}), ΔE medio y la zona de unos 32 px que más difiere.",
              "La maqueta usa cifras ilustrativas y el juego datos reales de la partida, así que nunca da cero: sirve para",
              "comparar pantallas entre sí y ver si un cambio acerca o aleja. Imágenes: `dif_<pantalla>.jpg` (maqueta | juego | calor).", "",
              "| Pantalla | Píxeles distintos | ΔE medio | Zona que más difiere | ΔE de esa zona |", "|---|---|---|---|---|"]
    for f in filas:
        lineas.append(f"| {f['pantalla']} | {f['distintos']:.1f} % | {f['medio']:.1f} | {f['zona']} | {f['zona_de']:.0f} |")
    (COMP / "DIFERENCIA_MAQUETA.md").write_text("\n".join(lineas) + "\n", encoding="utf-8")
    print("\n".join(lineas[-len(filas) - 2:]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
