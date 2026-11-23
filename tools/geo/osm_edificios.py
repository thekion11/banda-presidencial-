#!/usr/bin/env python3
"""Edificios reales y lugares emblemáticos de Gran Santiago desde el extracto de OpenStreetMap (© colaboradores, ODbL).

Salidas: data/geo/edificios_santiago.bin  (8 bytes por edificio: x,y uint16 en el plano 0..65535; ancho,largo m; ángulo°; pisos)
         data/geo/urbano_real.json         (se añade la lista "lugares" con nombre y posición)
Uso    : python3 tools/geo/osm_edificios.py <Santiago.osm.pbf>
"""
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

import osmium

ROOT = Path(__file__).resolve().parents[2]
LON0, LON1, LAT0, LAT1 = -70.80, -70.52, -33.57, -33.38
LUGARES = ["Plaza de Armas", "Cerro San Cristóbal", "Cerro Santa Lucía", "Estación Central", "Plaza Italia", "Mercado Central",
           "Costanera Center", "Parque Bicentenario", "Parque O'Higgins", "Estadio Nacional", "Plaza de Maipú", "Torre Entel",
           "Cementerio General", "Mall Plaza Vespucio", "Aeropuerto"]
MIN_AREA = 110.0


def metros(lon, lat):
    return (lon - LON0) * 111320.0 * math.cos(math.radians(-33.47)), (lat - LAT0) * 111200.0


def caja(pts):
    """Rectángulo orientado aproximado: eje del lado más largo, extensiones en ese eje y su perpendicular."""
    m = [metros(*p) for p in pts]
    mejor, ang = 0.0, 0.0
    for i in range(len(m) - 1):
        d = math.hypot(m[i + 1][0] - m[i][0], m[i + 1][1] - m[i][1])
        if d > mejor:
            mejor, ang = d, math.atan2(m[i + 1][1] - m[i][1], m[i + 1][0] - m[i][0])
    c, s = math.cos(ang), math.sin(ang)
    us = [p[0] * c + p[1] * s for p in m]
    vs = [-p[0] * s + p[1] * c for p in m]
    area = 0.0
    for i in range(len(m) - 1):
        area += m[i][0] * m[i + 1][1] - m[i + 1][0] * m[i][1]
    return max(us) - min(us), max(vs) - min(vs), math.degrees(ang) % 180.0, abs(area) / 2.0


def main():
    pbf = sys.argv[1]
    edif, lugares = [], {}
    for o in osmium.FileProcessor(pbf).with_locations():
        nm = o.tags.get("name", "") if (o.is_node() or o.is_way()) else ""
        if nm in LUGARES and nm not in lugares:
            try:
                lon, lat = (o.location.lon, o.location.lat) if o.is_node() else (o.nodes[0].lon, o.nodes[0].lat)
                if LON0 <= lon <= LON1 and LAT0 <= lat <= LAT1:
                    lugares[nm] = [round((lon - LON0) / (LON1 - LON0), 4), round((LAT1 - lat) / (LAT1 - LAT0), 4)]
            except Exception:
                pass
        if not (o.is_way() and "building" in o.tags):
            continue
        try:
            pts = [(n.lon, n.lat) for n in o.nodes]
        except Exception:
            continue
        if len(pts) < 4 or pts[0] != pts[-1]:
            continue
        cx = sum(p[0] for p in pts) / len(pts)
        cy = sum(p[1] for p in pts) / len(pts)
        if not (LON0 <= cx <= LON1 and LAT0 <= cy <= LAT1):
            continue
        w, d, ang, area = caja(pts)
        if area < MIN_AREA:
            continue
        try:
            pisos = int(float(o.tags.get("building:levels", "0")))
        except ValueError:
            pisos = 0
        h = int(hashlib.md5(str(o.id).encode()).hexdigest(), 16) % 100
        if pisos >= 4 or area >= 1200 or h < 100:
            edif.append((round((cx - LON0) / (LON1 - LON0) * 65535), round((LAT1 - cy) / (LAT1 - LAT0) * 65535),
                         min(255, round(w)), min(255, round(d)), int(ang) % 180, min(60, pisos)))
    datos = bytearray(struct.pack("<I", len(edif)))
    for e in edif:
        datos += struct.pack("<HHBBBB", *e)
    (ROOT / "data/geo/edificios_santiago.bin").write_bytes(bytes(datos))
    f = ROOT / "data/geo/urbano_real.json"
    d = json.loads(f.read_text(encoding="utf-8"))
    d["lugares"] = [{"n": k, "p": v} for k, v in lugares.items()]
    f.write_text(json.dumps(d, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"edificios {len(edif)} ({len(datos) // 1024} KB), lugares {len(lugares)}: {sorted(lugares)}")


if __name__ == "__main__":
    main()
