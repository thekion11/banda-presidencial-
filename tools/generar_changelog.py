#!/usr/bin/env python3
"""Compila docs/CHANGELOG.md desde `git log` (sin fusiones), agrupado por área según los archivos que toca cada commit: sim, game, data, tests, tools, docs.
Un commit que toca varias áreas aparece en la que tiene más archivos. Uso: python3 tools/generar_changelog.py [desde YYYY-MM-DD] (por defecto 2026-11-26)."""
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
AREAS = ["sim", "game", "data", "tests", "tools", "docs"]


def git(*a: str) -> str:
    return subprocess.check_output(["git", *a], cwd=RAIZ, text=True)


def main() -> None:
    desde = sys.argv[1] if len(sys.argv) > 1 else "2026-11-26"
    por_area = defaultdict(list)
    total = 0
    for bloque in git("log", "--no-merges", f"--since={desde} 00:00", "--format=@@%h|%ad|%s", "--date=format:%d-%m %H:%M", "--name-only").split("@@")[1:]:
        lineas = [x for x in bloque.split("\n") if x.strip()]
        h, f, s = lineas[0].split("|", 2)
        cnt = Counter(p.split("/")[0] if "/" in p else "raíz" for p in lineas[1:])
        area = next((a for a, _ in cnt.most_common() if a in AREAS), "otros")
        por_area[area].append(f"- `{h}` {f} — {s[:140]}")
        total += 1
    out = ["# Registro de cambios (generado)", "", f"Commits sin fusiones desde {desde}: {total}. Generado con `tools/generar_changelog.py`; cada commit está en el área donde toca más archivos.", ""]
    nombres = {"sim": "Núcleo de simulación (`sim/`)", "game": "Interfaz y presentación (`game/`)", "data": "Datos (`data/`)", "tests": "Pruebas (`tests/`)", "tools": "Herramientas y CI (`tools/`, `.github/`)", "docs": "Documentos (`docs/`)", "otros": "Otros (raíz, CI)"}
    for a in AREAS + ["otros"]:
        if por_area[a]:
            out += [f"## {nombres[a]} ({len(por_area[a])})", ""] + por_area[a] + [""]
    (RAIZ / "docs" / "CHANGELOG.md").write_text("\n".join(out), encoding="utf-8")
    print("docs/CHANGELOG.md:", total, "commits")


if __name__ == "__main__":
    main()
