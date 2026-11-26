#!/usr/bin/env python3
"""Mutación acotada de sim/: aplica N mutantes de operadores (comparaciones y signos) sobre una copia del proyecto, corre un conjunto rápido de pruebas y lista los que sobreviven
(ninguna prueba falló). Un sobreviviente es una prueba que falta o un mutante equivalente. No modifica el repositorio.
Uso: python3 tools/mutar.py [godot] [n=30] [semilla=1]"""
import glob
import random
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
GODOT = sys.argv[1] if len(sys.argv) > 1 else "godot"
N = int(sys.argv[2]) if len(sys.argv) > 2 else 30
random.seed(int(sys.argv[3]) if len(sys.argv) > 3 else 1)
PRUEBAS = ["test_prueba_oro_4_semanas", "test_prueba_oro_30_dias", "test_prueba_oro_completa", "test_unidades_sim", "test_rechazos_legales", "test_puntaje_tc",
           "test_finales_limite", "test_congreso_invariantes", "test_coalicion", "test_delegacion", "test_movimientos", "test_gabinete"]
OPS = [(" >= ", " > "), (" > ", " >= "), (" <= ", " < "), (" < ", " <= "), (" == ", " != "), (" and ", " or "), (" + ", " - "), (" - ", " + ")]


def candidatos() -> list:
    res = []
    for f in sorted(glob.glob(str(RAIZ / "sim" / "*.gd"))):
        if f.endswith(("validar_guardado.gd",)):
            continue
        for i, l in enumerate(Path(f).read_text(encoding="utf-8").split("\n")):
            s = l.split("#")[0]
            if not s.strip() or s.strip().startswith(("func", "class_name", "extends", "const", "##")) or '"' in s and s.count('"') > 2:
                continue
            for a, b in OPS:
                if a in s and re.search(r"\b(if|elif|while|return|var|and|or)\b", s):
                    res.append((f, i, a, b))
    return res


def correr(dest: str) -> bool:
    """true si alguna prueba falla (el mutante muere)."""
    for t in PRUEBAS:
        r = subprocess.run(["timeout", "120", GODOT, "--headless", "--path", dest, "-s", f"tests/{t}.gd"], capture_output=True, text=True)
        if r.returncode != 0 or "SCRIPT ERROR" in r.stdout + r.stderr or "FALLO" in r.stdout:
            return True
    return False


def main() -> int:
    cand = candidatos()
    random.shuffle(cand)
    dest = tempfile.mkdtemp(prefix="mutar_")
    shutil.copytree(RAIZ, dest, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git"))
    subprocess.run([GODOT, "--headless", "--import", "--path", dest], capture_output=True)
    vivos, muertos = [], 0
    for f, i, a, b in cand[:N]:
        rel = Path(f).relative_to(RAIZ)
        p = Path(dest) / rel
        L = p.read_text(encoding="utf-8").split("\n")
        original = L[i]
        cuerpo, _, com = original.partition("#")
        L[i] = cuerpo.replace(a, b, 1) + (("#" + com) if com else "")
        p.write_text("\n".join(L), encoding="utf-8")
        if correr(dest):
            muertos += 1
        else:
            vivos.append(f"{rel}:{i + 1} · «{a.strip()}» -> «{b.strip()}» · {original.strip()[:90]}")
        L[i] = original
        p.write_text("\n".join(L), encoding="utf-8")
    print(f"{N} mutantes: {muertos} muertos, {len(vivos)} vivos")
    for v in vivos:
        print("  VIVO:", v)
    shutil.rmtree(dest, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
