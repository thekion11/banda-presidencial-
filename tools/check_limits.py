#!/usr/bin/env python3
"""Verifica el límite de 450 líneas por archivo de código (CLAUDE.md §3) y que sim/ no use nodos."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LIMITE = 450
PROHIBIDOS_SIM = re.compile(r"\b(extends\s+(Node|Control|Node2D|Node3D|SceneTree|Resource)\b|get_tree\(|add_child\()")


def main() -> int:
    errores = []
    for carpeta in ("sim", "game", "tests", "tools"):
        for f in sorted((ROOT / carpeta).rglob("*")):
            if f.suffix not in (".gd", ".py"):
                continue
            lineas = f.read_text(encoding="utf-8").splitlines()
            if len(lineas) > LIMITE:
                errores.append(f"{f.relative_to(ROOT)}: {len(lineas)} líneas (máx {LIMITE})")
            if carpeta == "sim" and PROHIBIDOS_SIM.search("\n".join(lineas)):
                errores.append(f"{f.relative_to(ROOT)}: sim/ no puede depender de nodos de Godot")
    for e in errores:
        print("ERROR:", e)
    if not errores:
        print("OK: límites de tamaño y separación de capas")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main())
