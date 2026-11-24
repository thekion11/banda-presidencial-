#!/usr/bin/env python3
"""Regenera solo `parques` de data/geo/urbano_real.json desde el extracto OSM, sin tocar lo demás (lugares, líneas, estaciones).
Uso: python3 tools/geo/parques.py <Santiago.osm.pbf>"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import osm_santiago as o  # noqa: E402

RAIZ = Path(__file__).resolve().parents[2]


def main():
    _, _, _, parques, _ = o.leer(sys.argv[1])
    pk = []
    for pts in parques:
        if o.area_km2(pts) > 0.12 and all(o.dentro(*p) for p in pts[::5]):
            p = o.dp_anillo([o.plano(*q) for q in pts], 0.0006)
            if len(p) >= 4:
                pk.append([[round(x, 4), round(y, 4)] for x, y in p])
    ruta = RAIZ / "data/geo/urbano_real.json"
    d = json.loads(ruta.read_text(encoding="utf-8"))
    d["parques"] = pk
    ruta.write_text(json.dumps(d, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"{len(pk)} parques, vértices: {[len(p) for p in pk]}")


if __name__ == "__main__":
    main()
