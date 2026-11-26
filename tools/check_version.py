#!/usr/bin/env python3
"""La versión del juego vive en un solo lugar: `config/version` de project.godot. Debe coincidir con `version/name` de export_presets.cfg (la que ve Android) y con
`version` de data/version.json (la que muestra el informe de prueba, escrita por tools/generar_version.py). `version/code` (entero de Android) debe ser ≥ 1 y subir en cada entrega.
Uso: python3 tools/check_version.py"""
import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]


def leer_versiones(raiz: Path = RAIZ) -> dict:
    godot = (raiz / "project.godot").read_text(encoding="utf-8")
    preset = (raiz / "export_presets.cfg").read_text(encoding="utf-8")
    datos = json.loads((raiz / "data" / "version.json").read_text(encoding="utf-8"))
    g = re.search(r'^config/version="([^"]+)"', godot, re.M)
    n = re.search(r'^version/name="([^"]+)"', preset, re.M)
    c = re.search(r"^version/code=(\d+)", preset, re.M)
    return {"project": g.group(1) if g else None, "preset": n.group(1) if n else None, "codigo": int(c.group(1)) if c else 0, "datos": datos.get("version")}


def problemas(v: dict) -> list:
    p = []
    if not v["project"]:
        p.append("project.godot no tiene config/version")
    if v["preset"] != v["project"]:
        p.append(f"export_presets.cfg version/name ({v['preset']}) difiere de project.godot ({v['project']})")
    if v["datos"] != v["project"]:
        p.append(f"data/version.json ({v['datos']}) difiere de project.godot ({v['project']}): ejecutar tools/generar_version.py")
    if v["codigo"] < 1:
        p.append("version/code debe ser un entero ≥ 1")
    return p


def main() -> int:
    v = leer_versiones()
    p = problemas(v)
    for x in p:
        print("ERROR:", x)
    if not p:
        print(f"OK: versión {v['project']} (código Android {v['codigo']}) igual en project.godot, export_presets.cfg y data/version.json")
    return 1 if p else 0


if __name__ == "__main__":
    sys.exit(main())
