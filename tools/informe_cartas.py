#!/usr/bin/env python3
"""Informe de arte de cartas: cuántas cartas usan cada ilustración (`arte` o, si no lleva, la de su categoría), cuáles existen en
game/arte/cartas/ y cuáles faltan por producir, priorizadas por número de cartas. No crea imágenes.
Uso: python3 tools/informe_cartas.py [--md]   (--md imprime la lista priorizada en Markdown para docs/ESTADO_FASES.md)"""
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from cartas_arte import DESCRIPCIONES  # noqa: E402


def main() -> int:
    cartas = json.loads((ROOT / "data" / "cartas.json").read_text(encoding="utf-8")) + json.loads((ROOT / "data" / "cartas_reales.json").read_text(encoding="utf-8"))
    carpeta = ROOT / "game" / "arte" / "cartas"
    existe = {p.stem for p in carpeta.glob("*.jpg")}
    especificas = Counter(c["arte"] for c in cartas if c.get("arte"))
    categorias = Counter(c["categoria"] for c in cartas if not c.get("arte") or c["arte"] not in existe)
    efectivo = Counter()
    for c in cartas:
        a = c.get("arte")
        efectivo[a if a in existe else c["categoria"]] += 1
    faltan = [(k, n) for k, n in especificas.most_common() if k not in existe]
    sin_cat = sorted(k for k in categorias if k not in existe)
    if "--md" in sys.argv:
        print("| Prioridad | Arte (`game/arte/cartas/<arte>.jpg`) | Cartas | Motivo |\n|---|---|---|---|")
        for i, (k, n) in enumerate(faltan, 1):
            print(f"| {i} | `{k}` | {n} | {DESCRIPCIONES.get(k, '')} |")
        return 0
    print(f"Cartas: {len(cartas)}; con arte específico: {sum(especificas.values())}; ilustraciones existentes: {len(existe)}")
    print("\nIlustración efectiva por carta (la específica si existe el archivo; si no, la de su categoría):")
    for k, n in efectivo.most_common():
        print(f"  {n:5d}  {k}{'' if k in existe else '   (FALTA el archivo)'}")
    print(f"\nArtes específicas definidas: {len(especificas)}; faltan por producir: {len(faltan)} ({sum(n for _, n in faltan)} cartas las usarían)")
    for i, (k, n) in enumerate(faltan, 1):
        print(f"  {i:2d}. {k:30s} {n:4d} cartas  — {DESCRIPCIONES.get(k, '')}")
    if sin_cat:
        print("\nATENCIÓN: categorías sin archivo:", ", ".join(sin_cat))
    return 1 if sin_cat else 0


if __name__ == "__main__":
    sys.exit(main())
