#!/usr/bin/env python3
"""Determinismo entre procesos: lanza varios procesos de Godot a la vez con las mismas semillas y compara lo que imprime tests/huella_semillas.gd.

Cada proceso usa un HOME distinto y, en la segunda mitad, una copia del proyecto en otro directorio. Si dos procesos dan huellas distintas para la misma semilla,
hay una fuente de azar o de orden no determinista (hash de diccionarios, reloj, directorios, concurrencia...).
Uso: python3 tools/determinismo_procesos.py [procesos] [semillas] [godot]      (por defecto 4 procesos, 6 semillas, `godot`)
"""
import os
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def lanzar(idx: int, semillas: int, godot: str, proyecto: str) -> list:
    home = tempfile.mkdtemp(prefix=f"det_home_{idx}_")
    env = dict(os.environ, HOME=home, XDG_DATA_HOME=home + "/.local/share", XDG_CONFIG_HOME=home + "/.config")
    r = subprocess.run([godot, "--headless", "--path", proyecto, "-s", "tests/huella_semillas.gd", "--", str(semillas), "100"],
                       env=env, capture_output=True, text=True, timeout=900)
    shutil.rmtree(home, ignore_errors=True)
    return [l for l in r.stdout.splitlines() if l.startswith(("HUELLA ", "DATOS "))]


def main() -> int:
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    semillas = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    godot = sys.argv[3] if len(sys.argv) > 3 else "godot"
    copia = tempfile.mkdtemp(prefix="det_copia_")
    destino = os.path.join(copia, "proyecto")
    shutil.copytree(RAIZ, destino, ignore=shutil.ignore_patterns(".git"), symlinks=True)
    proyectos = [RAIZ if i < n // 2 else destino for i in range(n)]
    with ThreadPoolExecutor(max_workers=n) as ex:
        resultados = list(ex.map(lambda i: lanzar(i, semillas, godot, proyectos[i]), range(n)))
    shutil.rmtree(copia, ignore_errors=True)
    base = resultados[0]
    ok = len(base) > semillas and all(r == base for r in resultados)
    for i, r in enumerate(resultados):
        if r != base:
            dif = [(a, b) for a, b in zip(base, r) if a != b]
            print(f"DIFIERE el proceso {i} ({'copia' if proyectos[i] != RAIZ else 'proyecto'}): {len(dif)} líneas distintas; primera: {dif[:1]}")
    print(f"DETERMINISMO ENTRE PROCESOS {'OK' if ok else 'CON DIFERENCIAS'}: {n} procesos en paralelo, {len(base)} líneas de huella cada uno")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
