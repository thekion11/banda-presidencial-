#!/usr/bin/env python3
"""Genera el icono del juego (fachada de La Moneda con la banda tricolor al pie, sobre océano) y la imagen de arranque.
Salidas: icon.svg, game/arte/marca/{icono_512,icono_fg_432,icono_bg_432,icono_192,splash}.png. Paleta de CLAUDE.md §5."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OCEANO, PANEL, ORO, ROJO, CREMA, AZUL = "#0B2236", "#16405F", "#F2C14E", "#C23B2E", "#FBF7EC", "#1E4F9C"
SS = 4


def fondo(n: int) -> Image.Image:
    im = Image.new("RGB", (n, n), OCEANO)
    px = im.load()
    for y in range(n):
        for x in range(n):
            t = (x + y) / (2 * n)
            c = [int(a + (b - a) * t) for a, b in zip((0x16, 0x40, 0x5F), (0x07, 0x18, 0x2A))]
            px[x, y] = tuple(c)
    return im


def estrella(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float, color: str) -> None:
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.40
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    d.polygon(pts, fill=color)


def banda(n: int, margen: float) -> Image.Image:
    """Banda diagonal tricolor (azul, crema, rojo) con medallón dorado; sobre fondo transparente."""
    N = n * SS
    capa = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)
    ancho = N * 0.50 * (1 - margen)
    cx, cy = N * 0.5, N * 0.5
    ux, uy = math.cos(math.radians(-35)), math.sin(math.radians(-35))  # dirección de la banda
    nx, ny = -uy, ux
    largo = N * 1.4
    for i, color in enumerate((AZUL, CREMA, ROJO)):
        off0, off1 = (i - 1.5) * ancho / 3, (i - 0.5) * ancho / 3
        poly = [(cx + ux * -largo + nx * off0, cy + uy * -largo + ny * off0), (cx + ux * largo + nx * off0, cy + uy * largo + ny * off0),
                (cx + ux * largo + nx * off1, cy + uy * largo + ny * off1), (cx + ux * -largo + nx * off1, cy + uy * -largo + ny * off1)]
        d.polygon(poly, fill=color)
    r = N * 0.19 * (1 - margen * 0.6)
    d.ellipse([cx - r * 1.12, cy - r * 1.12, cx + r * 1.12, cy + r * 1.12], fill=OCEANO)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PANEL, outline=ORO, width=max(2, int(N * 0.012)))
    estrella(d, cx, cy + r * 0.04, r * 0.72, ORO)
    return capa.resize((n, n), Image.LANCZOS)


def moneda(n: int, escala: float = 1.0, sangrado: bool = True) -> Image.Image:
    """Fachada neoclásica de La Moneda (dorada y crema) con la banda tricolor al pie; capa RGBA transparente."""
    S = n * SS
    capa = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)

    def X(v: float) -> float:
        return S * (0.5 + (v - 0.5) * escala)

    def Y(v: float) -> float:
        return S * (0.5 + (v - 0.5) * escala)

    d.polygon([(X(0.14), Y(0.40)), (X(0.50), Y(0.22)), (X(0.86), Y(0.40))], fill=ORO)
    d.polygon([(X(0.20), Y(0.395)), (X(0.50), Y(0.255)), (X(0.80), Y(0.395))], fill=PANEL)
    d.rectangle([X(0.12), Y(0.40), X(0.88), Y(0.45)], fill=ORO)
    for i in range(6):
        x = 0.17 + i * 0.118
        d.rectangle([X(x), Y(0.45), X(x + 0.07), Y(0.70)], fill=CREMA)
        d.rectangle([X(x - 0.01), Y(0.45), X(x + 0.08), Y(0.47)], fill=ORO)
    d.rectangle([X(0.10), Y(0.70), X(0.90), Y(0.75)], fill=ORO)
    d.rectangle([X(0.07), Y(0.75), X(0.93), Y(0.79)], fill=ORO)
    izq, der = (0.0, 1.0) if sangrado else (0.07, 0.93)
    for color, y in ((AZUL, 0.82), (CREMA, 0.87), (ROJO, 0.92)):
        d.rectangle([X(izq) if not sangrado else 0, Y(y), X(der) if not sangrado else S, Y(y + 0.05)], fill=color)
    estrella(d, X(0.50), Y(0.33), S * 0.045 * escala, ORO)
    return capa.resize((n, n), Image.LANCZOS)


def main() -> None:
    out = ROOT / "game" / "arte" / "marca"
    out.mkdir(parents=True, exist_ok=True)
    moneda(432, 0.66, sangrado=False).save(out / "icono_fg_432.png")  # zona segura de los iconos adaptativos
    fondo(432).save(out / "icono_bg_432.png")
    icono = fondo(512).convert("RGBA")
    icono.alpha_composite(moneda(512))
    mascara = Image.new("L", (512 * SS, 512 * SS), 0)
    ImageDraw.Draw(mascara).rounded_rectangle([0, 0, 512 * SS, 512 * SS], radius=112 * SS, fill=255)
    icono.putalpha(mascara.resize((512, 512), Image.LANCZOS))
    icono.save(out / "icono_512.png")
    icono.resize((192, 192), Image.LANCZOS).save(out / "icono_192.png")
    s = fondo(1080).resize((1080, 1920))
    g = icono.resize((460, 460), Image.LANCZOS)
    s.paste(g, (310, 700), g)
    s.save(out / "splash.png")
    (ROOT / "icon.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><rect width="128" height="128" rx="28" fill="#0B2236"/>'
        '<path d="M18 51L64 28l46 23z" fill="#F2C14E"/><path d="M26 50.5L64 32.6 102 50.5z" fill="#16405F"/><rect x="15" y="51" width="98" height="6" fill="#F2C14E"/>'
        '<g fill="#FBF7EC"><rect x="22" y="57" width="8" height="32"/><rect x="37" y="57" width="8" height="32"/><rect x="52" y="57" width="8" height="32"/>'
        '<rect x="67" y="57" width="8" height="32"/><rect x="82" y="57" width="8" height="32"/><rect x="97" y="57" width="8" height="32"/></g><rect x="13" y="89" width="102" height="6" fill="#F2C14E"/>'
        '<rect x="9" y="95" width="110" height="5" fill="#F2C14E"/><rect y="105" width="128" height="7" fill="#1E4F9C"/><rect y="112" width="128" height="6" fill="#FBF7EC"/>'
        '<rect y="118" width="128" height="10" fill="#C23B2E"/><path d="M64 36l2.4 5.2 5.6.6-4.2 3.8 1.2 5.6-5-2.8-5 2.8 1.2-5.6-4.2-3.8 5.6-.6z" fill="#F2C14E"/></svg>\n', encoding="utf-8")


if __name__ == "__main__":
    main()
