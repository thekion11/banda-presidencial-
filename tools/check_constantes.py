#!/usr/bin/env python3
"""Vigila que ningún número de balance viva en el código de sim/ (CLAUDE.md §3: «Ningún número de balance vive en el código»).

Revisa los literales numéricos de sim/*.gd (sin comentarios ni textos) que no sean triviales (0, 1, 2, 0.5, 100...) y exige que cada par (archivo, literal)
esté en tools/constantes_aceptadas.json, donde se revisaron una vez y se explica por qué no son balance (redondeos, tamaños de datos, valores por defecto del
estado antes de cargar el partido, algoritmos). Un literal nuevo falla hasta que se mueva a data/ o se acepte con su motivo.
Uso: python3 tools/check_constantes.py [--regenerar]   (--regenerar reescribe la lista aceptando lo que haya: solo tras revisar el diff)
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACEPTADAS = ROOT / "tools" / "constantes_aceptadas.json"
TRIVIALES = {"0", "1", "2", "3", "-1", "0.0", "1.0", "0.5", "100.0", "100", "2.0", "-1.0", "10000", "10000.0", "1000", "-1000", "4", "5", "7", "8"}


def literales() -> dict:
    res: dict = {}
    for f in sorted((ROOT / "sim").glob("*.gd")):
        for linea in f.read_text(encoding="utf-8").splitlines():
            codigo = re.sub(r'"[^"]*"', '""', linea.split("#")[0])
            for m in re.finditer(r"(?<![\w.\[])(-?\d+\.?\d*(?:e\d+)?)(?![\w])", codigo):
                if m.group(1) not in TRIVIALES:
                    res.setdefault(f.name, set()).add(m.group(1))
    return {k: sorted(v) for k, v in res.items()}


def main() -> int:
    actuales = literales()
    if "--regenerar" in sys.argv:
        previo = json.loads(ACEPTADAS.read_text(encoding="utf-8")) if ACEPTADAS.exists() else {"motivo": {}}
        ACEPTADAS.write_text(json.dumps({"motivo": previo.get("motivo", {}), "aceptadas": actuales}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print("Lista regenerada:", sum(len(v) for v in actuales.values()), "literales")
        return 0
    ok = json.loads(ACEPTADAS.read_text(encoding="utf-8"))["aceptadas"]
    nuevos = [f"{arch}: {lit}" for arch, lits in actuales.items() for lit in lits if lit not in ok.get(arch, [])]
    for n in nuevos:
        print("ERROR: literal numérico nuevo en sim/ (muévelo a data/ o acéptalo en tools/constantes_aceptadas.json con su motivo):", n)
    if not nuevos:
        print("OK: sin números de balance nuevos en el código de sim/")
    return 1 if nuevos else 0


if __name__ == "__main__":
    sys.exit(main())
