#!/usr/bin/env python3
"""Cobertura de FUNCIONES de sim/ (GDScript no trae cobertura de líneas). Copia el proyecto a un directorio temporal, inserta una llamada
`Cobertura.tocar("archivo:funcion")` al inicio de cada función de sim/ cuyo encabezado termina en «:» (las de una sola línea no se instrumentan),
ejecuta todos los tests/test_*.gd y el fuzz, y lista las funciones que ningún test llegó a ejecutar. No modifica el repositorio.
Uso: python3 tools/cobertura_funciones.py [ruta_godot]     (≈ 15 minutos)
"""
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = sys.argv[1] if len(sys.argv) > 1 else "godot"
REGISTRO = os.path.join(tempfile.gettempdir(), "cobertura_funciones.log")
CLASE = '''class_name Cobertura
extends RefCounted
static var vistos := {}
static func tocar(k: String) -> void:
	if vistos.has(k):
		return
	vistos[k] = true
	var f := FileAccess.open("%s", FileAccess.READ_WRITE) if FileAccess.file_exists("%s") else FileAccess.open("%s", FileAccess.WRITE)
	f.seek_end()
	f.store_line(k)
''' % (REGISTRO, REGISTRO, REGISTRO)
ENC = r"\)\s*(->\s*[\w\[\], .]+)?:\s*(#.*)?$"


def instrumentar(dest: str) -> list:
    inst = []
    for f in sorted(glob.glob(os.path.join(dest, "sim", "*.gd"))):
        lineas = open(f, encoding="utf-8").read().split("\n")
        out, i = [], 0
        rel = "sim/" + os.path.basename(f)
        while i < len(lineas):
            out.append(lineas[i])
            m = re.match(r"^(static )?func (\w+)\(", lineas[i])
            if m:
                j = i
                while not re.search(ENC, lineas[j]) and j < i + 6 and not re.search(r"\)\s*(->\s*[\w\[\], .]+)?:\s*[^#\s]", lineas[j]):
                    j += 1
                if re.search(ENC, lineas[j]):
                    out.extend(lineas[i + 1:j + 1])
                    i = j
                    out.append('\tCobertura.tocar("%s:%s")' % (rel, m.group(2)))
                    inst.append("%s:%s" % (rel, m.group(2)))
            i += 1
        open(f, "w", encoding="utf-8").write("\n".join(out))
    return inst


def main() -> int:
    dest = tempfile.mkdtemp(prefix="cobertura_")
    shutil.copytree(RAIZ, dest, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git"))
    open(os.path.join(dest, "sim", "cobertura.gd"), "w", encoding="utf-8").write(CLASE)
    inst = instrumentar(dest)
    if os.path.exists(REGISTRO):
        os.remove(REGISTRO)
    subprocess.run([GODOT, "--headless", "--import", "--path", dest], capture_output=True)
    for t in sorted(glob.glob(os.path.join(dest, "tests", "test_*.gd"))) + [os.path.join(dest, "tests", "fuzz_acciones.gd")]:
        extra = ["--", "30", "7000"] if t.endswith("fuzz_acciones.gd") else []
        subprocess.run(["timeout", "280", GODOT, "--headless", "--path", dest, "-s", t] + extra, capture_output=True)
    vistos = set(open(REGISTRO, encoding="utf-8").read().split("\n")) if os.path.exists(REGISTRO) else set()
    sin = [x for x in inst if x not in vistos]
    print("%d funciones instrumentadas, %d ejecutadas (%.1f %%), %d sin ejecutar" % (len(inst), len(inst) - len(sin), 100.0 * (len(inst) - len(sin)) / max(1, len(inst)), len(sin)))
    for x in sin:
        print("  sin ejecutar:", x)
    shutil.rmtree(dest, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
