#!/usr/bin/env python3
"""Simplifica el GeoJSON de regiones de Chile para el mapa del juego.

Entrada : GeoJSON de regiones (ver docs/DATOS.md para la fuente y licencia a verificar).
Salida  : data/geo/regiones_mapa.json  (polígonos en coordenadas planas normalizadas, ids del juego).
Uso     : python3 tools/geo/simplificar_regiones.py <regiones.json> [tolerancia_grados=0.02]
"""
import json
import math
import sys
from pathlib import Path

COD_A_ID = {15: "arica", 1: "tarapaca", 2: "antofagasta", 3: "atacama", 4: "coquimbo", 5: "valparaiso",
            13: "metropolitana", 6: "ohiggins", 7: "maule", 16: "nuble", 8: "biobio", 9: "araucania",
            14: "losrios", 10: "loslagos", 11: "aysen", 12: "magallanes"}
CIUDADES = [("Arica", -18.48, -70.31), ("Iquique", -20.21, -70.15), ("Antofagasta", -23.65, -70.40),
           ("La Serena", -29.90, -71.25), ("Valparaíso", -33.05, -71.62), ("Santiago", -33.45, -70.67),
           ("Concepción", -36.83, -73.05), ("Pto. Montt", -41.47, -72.94), ("Punta Arenas", -53.16, -70.91)]
LON_MIN, LON_MAX, LAT_MIN = -76.8, -66.0, -56.6  # solo territorio continental (sin Antártica ni islas oceánicas)


def dp(puntos, tol):
    """Douglas-Peucker iterativo."""
    if len(puntos) < 3:
        return puntos
    mantener = [False] * len(puntos)
    mantener[0] = mantener[-1] = True
    pila = [(0, len(puntos) - 1)]
    while pila:
        a, b = pila.pop()
        (ax, ay), (bx, by) = puntos[a], puntos[b]
        dx, dy = bx - ax, by - ay
        norma = math.hypot(dx, dy) or 1e-12
        mejor, idx = 0.0, -1
        for i in range(a + 1, b):
            px, py = puntos[i]
            d = abs(dy * (px - ax) - dx * (py - ay)) / norma
            if d > mejor:
                mejor, idx = d, i
        if mejor > tol and idx > 0:
            mantener[idx] = True
            pila.append((a, idx))
            pila.append((idx, b))
    return [p for p, m in zip(puntos, mantener) if m]


def dp_anillo(anillo, tol):
    """Anillo cerrado: se parte en el punto más lejano al primero para evitar el segmento degenerado."""
    pts = anillo[:-1] if anillo[0] == anillo[-1] else anillo
    k = max(range(len(pts)), key=lambda i: (pts[i][0] - pts[0][0]) ** 2 + (pts[i][1] - pts[0][1]) ** 2)
    a = dp(pts[:k + 1], tol)
    b = dp(pts[k:] + [pts[0]], tol)
    return a[:-1] + b[:-1]


def anillos(geom):
    polys = geom["coordinates"] if geom["type"] == "MultiPolygon" else [geom["coordinates"]]
    for poly in polys:
        yield poly[0]  # solo anillo exterior


def main() -> int:
    origen = Path(sys.argv[1])
    tol = float(sys.argv[2]) if len(sys.argv) > 2 else 0.02
    gj = json.loads(origen.read_text(encoding="utf-8"))
    coslat = math.cos(math.radians(35.0))
    salida = {"proyeccion": "equirectangular_cos35", "regiones": {}}
    xs, ys = [], []
    for f in gj["features"]:
        rid = COD_A_ID[int(f["properties"]["codregion"])]
        polys = []
        for anillo in anillos(f["geometry"]):
            cx = sum(p[0] for p in anillo) / len(anillo)
            cy = sum(p[1] for p in anillo) / len(anillo)
            if not (LON_MIN <= cx <= LON_MAX and cy >= LAT_MIN):
                continue
            t = tol * (2.0 if rid in ("magallanes", "aysen", "loslagos") else 1.0)
            s = dp_anillo([(p[0], p[1]) for p in anillo], t)
            if len(s) < 4 or abs(sum(s[i][0] * s[(i + 1) % len(s)][1] - s[(i + 1) % len(s)][0] * s[i][1] for i in range(len(s)))) < 0.02:
                continue  # islotes irrelevantes
            polys.append(s)
        salida["regiones"][rid] = polys
        for poly in polys:
            for x, y in poly:
                xs.append(x * coslat)
                ys.append(y)
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    alto = y1 - y0
    for rid, polys in salida["regiones"].items():
        salida["regiones"][rid] = [[[round((x * coslat - x0) / alto, 4), round((y1 - y) / alto, 4)] for x, y in poly] for poly in polys]
    salida["ancho_rel"] = round((x1 - x0) / alto, 4)  # alto normalizado = 1.0
    salida["proy"] = {"coslat": coslat, "x0": x0, "y1": y1, "alto": alto}  # para alinear el relieve
    salida["ciudades"] = [
        {"nombre": n, "x": round((lon * coslat - x0) / alto, 4), "y": round((y1 - lat) / alto, 4)}
        for n, lat, lon in CIUDADES]
    destino = Path(__file__).resolve().parents[2] / "data" / "geo" / "regiones_mapa.json"
    destino.write_text(json.dumps(salida, separators=(",", ":")), encoding="utf-8")
    pts = sum(len(p) for polys in salida["regiones"].values() for p in polys)
    print(f"OK: {destino} ({destino.stat().st_size // 1024} KB, {pts} puntos, ancho relativo {salida['ancho_rel']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
