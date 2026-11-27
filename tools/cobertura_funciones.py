#!/usr/bin/env python3
"""Cobertura de FUNCIONES de sim/ (GDScript no trae cobertura de líneas). Copia el proyecto a un directorio temporal, inserta una llamada
`Cobertura.tocar("archivo:funcion")` al inicio de cada función de sim/ cuyo encabezado termina en «:» (las de una sola línea no se instrumentan),
ejecuta todos los tests/test_*.gd y el fuzz, y lista las funciones que ningún test llegó a ejecutar. No modifica el repositorio.
Con `--game` mide `game/` (interfaz) en lugar de `sim/`: corre las pruebas de interfaz bajo xvfb-run (test_ui_humo, test_textos, test_tactil, test_claridad, test_escenas…)
y las capturas de la maqueta; lista las funciones de pantallas y componentes que ninguna prueba de interfaz ejercita.
Uso: python3 tools/cobertura_funciones.py [ruta_godot] [--game]     (sim ≈ 15 minutos; game ≈ 20 minutos)
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
GODOT = next((a for a in sys.argv[1:] if not a.startswith("--")), "godot")
JUEGO = "--game" in sys.argv
UI = ["test_ui_humo", "test_textos", "test_tactil", "test_claridad", "test_escenas", "test_accesibilidad", "test_movimiento", "test_paleta", "test_estados", "test_tapa",
      "test_mapa_entrada", "test_metro_lineas", "test_identidad", "test_reglas_ui", "test_atras", "test_zonas_seguras", "test_veracidad",
      "test_animaciones_completas", "test_estado_tardio", "test_fichas_largas", "test_cartera", "test_sectra", "test_gestos", "captura_comparar"]
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
    patrones = [os.path.join(dest, "game", "*.gd"), os.path.join(dest, "game", "*", "*.gd")] if JUEGO else [os.path.join(dest, "sim", "*.gd")]
    for f in sorted(g for p in patrones for g in glob.glob(p)):
        lineas = open(f, encoding="utf-8").read().split("\n")
        out, i = [], 0
        rel = os.path.relpath(f, dest)
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
    if JUEGO:
        for n in UI:
            t = os.path.join(dest, "tests", n + ".gd")
            if os.path.exists(t):
                extra = ["--", os.path.join(tempfile.gettempdir(), "cobertura_capturas")] if n == "captura_comparar" else []
                subprocess.run(["timeout", "400", "xvfb-run", "-a", GODOT, "--path", dest, "--rendering-method", "gl_compatibility", "--resolution", "390x844", "-s", t] + extra, capture_output=True)
    else:
        for t in sorted(glob.glob(os.path.join(dest, "tests", "test_*.gd"))) + [os.path.join(dest, "tests", "fuzz_acciones.gd")]:
            extra = ["--", "30", "7000"] if t.endswith("fuzz_acciones.gd") else []
            subprocess.run(["timeout", "280", GODOT, "--headless", "--path", dest, "-s", t] + extra, capture_output=True)
    vistos = set(open(REGISTRO, encoding="utf-8").read().split("\n")) if os.path.exists(REGISTRO) else set()
    sin = [x for x in inst if x not in vistos]
    print(("game/: " if JUEGO else "sim/: ") + "%d funciones instrumentadas, %d ejecutadas (%.1f %%), %d sin ejecutar" % (len(inst), len(inst) - len(sin), 100.0 * (len(inst) - len(sin)) / max(1, len(inst)), len(sin)))
    for x in sin:
        print("  sin ejecutar:", x)
    shutil.rmtree(dest, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
