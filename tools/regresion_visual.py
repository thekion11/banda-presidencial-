#!/usr/bin/env python3
"""Regresión visual con capturas de referencia («golden»): pantallas clave con ventana real (1×) en 360×640, 390×844 y
412×915, comparadas con tests/golden/<tamaño>/<pantalla>.png con tolerancia. No bloquea: informa y deja imágenes de
diferencias (rojo = píxel distinto) para el artefacto del CI. Necesita xvfb-run y Godot.

Uso:
  python3 tools/regresion_visual.py                    # compara; diferencias en /tmp/regresion_visual/diferencias
  python3 tools/regresion_visual.py --generar          # regenera tests/golden (tras un cambio visual a propósito)
  python3 tools/regresion_visual.py --estricto         # sale con código 1 si alguna pantalla supera la tolerancia
"""
import glob
import os
import shutil
import subprocess
import sys

from PIL import Image, ImageChops

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GOLDEN = os.path.join(RAIZ, "tests", "golden")
TRABAJO = "/tmp/regresion_visual"
TAMANOS = ["360x640", "390x844", "412x915"]
UMBRAL_CANAL = 24  # diferencia por canal que cuenta como píxel distinto (tras llevar la captura a la paleta de la referencia)
TOLERANCIA_PCT = 1.5  # % de píxeles distintos aceptado por pantalla (antialias del rasterizador, versión de Mesa)
GODOT = os.environ.get("GODOT", "godot")


def capturar(destino: str) -> None:
    for t in TAMANOS:
        carpeta = os.path.join(destino, t)
        shutil.rmtree(carpeta, ignore_errors=True)
        cmd = ["xvfb-run", "-a", "-s", "-screen 0 1400x1400x24", GODOT, "--path", RAIZ, "--rendering-method", "gl_compatibility",
               "--resolution", t, "-s", "tests/golden_capturar.gd", "--", carpeta, t]
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        linea = [l for l in r.stdout.splitlines() if l.startswith("golden:")]
        print(t, linea[0] if linea else "sin capturas (revisa xvfb y Godot)")


def pequeno(src: str, dst: str) -> None:
    Image.open(src).convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT).save(dst, optimize=True)


def comparar() -> int:
    capturar(os.path.join(TRABAJO, "nuevas"))
    dif_dir = os.path.join(TRABAJO, "diferencias")
    shutil.rmtree(dif_dir, ignore_errors=True)
    os.makedirs(dif_dir)
    malas = 0
    print("| Tamaño | Pantalla | Píxeles distintos | Estado |")
    print("|---|---|---|---|")
    for ref in sorted(glob.glob(os.path.join(GOLDEN, "*", "*.png"))):
        t, nombre = ref.split(os.sep)[-2], os.path.basename(ref)
        nueva = os.path.join(TRABAJO, "nuevas", t, nombre)
        if not os.path.exists(nueva):
            print("| %s | %s | — | falta la captura nueva |" % (t, nombre[:-4]))
            malas += 1
            continue
        ref_p = Image.open(ref)  # referencia en 256 colores: la captura nueva se lleva a la misma paleta (sin tramado) para que
        a = ref_p.convert("RGB")  # la cuantización no cuente como diferencia en las ilustraciones
        b_rgb = Image.open(nueva).convert("RGB")
        b = b_rgb.quantize(palette=ref_p, dither=Image.Dither.NONE).convert("RGB") if ref_p.mode == "P" else b_rgb
        if a.size != b.size:
            print("| %s | %s | — | tamaño distinto %s / %s |" % (t, nombre[:-4], a.size, b.size))
            malas += 1
            continue
        d = ImageChops.difference(a, b).split()
        mascara = ImageChops.lighter(ImageChops.lighter(d[0], d[1]), d[2]).point(lambda v: 255 if v > UMBRAL_CANAL else 0)
        pct = mascara.histogram()[255] * 100.0 / (a.size[0] * a.size[1])
        estado = "ok" if pct <= TOLERANCIA_PCT else "DISTINTA"
        if pct > TOLERANCIA_PCT:
            malas += 1
        if pct > 0:  # referencia | nueva | píxeles distintos en rojo
            rojo = Image.new("RGB", a.size, (230, 40, 40))
            marcada = Image.composite(rojo, b.point(lambda v: v // 3), mascara)
            lado = Image.new("RGB", (a.size[0] * 3 + 20, a.size[1]), (11, 34, 54))
            for i, im in enumerate([a, b, marcada]):
                lado.paste(im, (i * (a.size[0] + 10), 0))
            lado.save(os.path.join(dif_dir, "%s_%s" % (t, nombre)))
        print("| %s | %s | %.2f %% | %s |" % (t, nombre[:-4], pct, estado))
    print("Pantallas fuera de tolerancia (%.1f %%): %d. Diferencias en %s" % (TOLERANCIA_PCT, malas, dif_dir))
    return malas


if __name__ == "__main__":
    if "--generar" in sys.argv:
        tmp = os.path.join(TRABAJO, "generar")
        capturar(tmp)
        shutil.rmtree(GOLDEN, ignore_errors=True)
        for src in glob.glob(os.path.join(tmp, "*", "*.png")):
            dst = os.path.join(GOLDEN, src.split(os.sep)[-2], os.path.basename(src))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            pequeno(src, dst)
        print("referencias en %s: %d" % (GOLDEN, len(glob.glob(os.path.join(GOLDEN, "*", "*.png")))))
    else:
        n = comparar()
        sys.exit(1 if n and "--estricto" in sys.argv else 0)
