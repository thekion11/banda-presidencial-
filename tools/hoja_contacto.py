#!/usr/bin/env python3
"""Junta las capturas de tests/hoja_contacto.gd en una hoja de contacto por tamaño y letra (QA visual a ojo).
Uso: python3 tools/hoja_contacto.py /tmp/hc docs/comparacion      (lee /tmp/hc/<tamaño>_<letra>/NN_paso.png)
"""
import glob
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ORIGEN = sys.argv[1] if len(sys.argv) > 1 else "/tmp/hc"
DESTINO = sys.argv[2] if len(sys.argv) > 2 else "docs/comparacion"
COLUMNAS = 6
ALTO_MINI = 400
FUENTE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "game", "fuentes", "Inter.ttf")  # con tildes  # cada captura se reduce a este alto, conservando la proporción del teléfono

for carpeta in sorted(glob.glob(os.path.join(ORIGEN, "*"))):
    fotos = sorted(glob.glob(os.path.join(carpeta, "*.png")))
    if not fotos:
        continue
    minis = []
    for f in fotos:
        im = Image.open(f).convert("RGB")
        ancho = round(im.width * ALTO_MINI / im.height)
        minis.append((os.path.basename(f)[3:-4].replace("_", " "), im.resize((ancho, ALTO_MINI), Image.LANCZOS)))
    celda_w = max(m.width for _, m in minis) + 12
    celda_h = ALTO_MINI + 30
    filas = (len(minis) + COLUMNAS - 1) // COLUMNAS
    hoja = Image.new("RGB", (celda_w * COLUMNAS + 12, celda_h * filas + 40), (11, 34, 54))
    d = ImageDraw.Draw(hoja)
    letra = ImageFont.truetype(FUENTE, 14)
    d.text((12, 12), "Hoja de contacto · %s · %d pantallas" % (os.path.basename(carpeta).replace("_", " · letra "), len(minis)), fill=(242, 193, 78), font=letra)
    for i, (nombre, m) in enumerate(minis):
        x = 12 + (i % COLUMNAS) * celda_w
        y = 40 + (i // COLUMNAS) * celda_h
        hoja.paste(m, (x, y))
        d.text((x, y + ALTO_MINI + 6), nombre[:40], fill=(185, 201, 216), font=letra)
    salida = os.path.join(DESTINO, "hoja_contacto_%s.png" % os.path.basename(carpeta))
    hoja.quantize(colors=256, method=Image.Quantize.MEDIANCUT).save(salida, optimize=True)  # 256 colores: un tercio del peso, legible
    print(salida, hoja.size)
