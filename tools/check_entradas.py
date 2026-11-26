#!/usr/bin/env python3
"""Cada tipo de entrada que el motor registra (`registrar_entrada("tipo", ...)`) debe estar en la tabla ENTRADAS de sim/validar_guardado.gd; si no, un guardado
con ese tipo se descartaría como inválido. También falla si la tabla tiene tipos que el motor ya no registra."""
import glob
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
tipos = set()
for f in glob.glob(str(RAIZ / "sim" / "*.gd")):
    tipos |= set(re.findall(r'registrar_entrada\("(\w+)"', Path(f).read_text(encoding="utf-8")))
tabla = set(re.findall(r'"(\w+)": \{', (RAIZ / "sim" / "validar_guardado.gd").read_text(encoding="utf-8")))
falta, sobra = sorted(tipos - tabla), sorted(tabla - tipos)
if falta or sobra:
    print("ERROR: tipos de entrada sin validar:", falta, "· en la tabla pero ya no se registran:", sobra)
    sys.exit(1)
print("OK: los %d tipos de entrada del guardado están en la tabla de validación" % len(tipos))
