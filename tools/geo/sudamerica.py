#!/usr/bin/env python3
"""Genera data/geo/sudamerica.json desde Natural Earth 1:50m (dominio público): contornos simplificados de los países de Sudamérica.
Uso: python3 tools/geo/sudamerica.py RUTA/ne_50m_admin_0_countries.geojson
Proyección equirectangular centrada en -23° (x escalada por cos), normalizada a x en [0, ancho_rel] e y en [0, 1] (norte = 0)."""
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXCLUIR = {"FLK"}  # Malvinas: disputa; no se dibuja (aviso de «mapa ilustrativo»)
TOL = 0.12  # grados


def dp(pts: list, tol: float) -> list:
    if len(pts) < 3:
        return pts
    (x1, y1), (x2, y2) = pts[0], pts[-1]
    dx, dy = x2 - x1, y2 - y1
    norma = math.hypot(dx, dy) or 1e-12
    mejor, idx = 0.0, 0
    for i in range(1, len(pts) - 1):
        d = abs(dy * pts[i][0] - dx * pts[i][1] + x2 * y1 - y2 * x1) / norma
        if d > mejor:
            mejor, idx = d, i
    if mejor > tol:
        return dp(pts[: idx + 1], tol)[:-1] + dp(pts[idx:], tol)
    return [pts[0], pts[-1]]


def simplificar_anillo(a: list, tol: float) -> list:
    """Un anillo cerrado se parte en dos por el punto más lejano del primero y cada mitad se simplifica."""
    pts = a[:-1] if a[0] == a[-1] else a
    j = max(range(len(pts)), key=lambda i: (pts[i][0] - pts[0][0]) ** 2 + (pts[i][1] - pts[0][1]) ** 2)
    return dp(pts[: j + 1], tol)[:-1] + dp(pts[j:] + [pts[0]], tol)[:-1]


def anillos(geom: dict) -> list:
    polys = geom["coordinates"] if geom["type"] == "MultiPolygon" else [geom["coordinates"]]
    return [p[0] for p in polys]  # solo el borde exterior de cada isla/pieza


def main() -> None:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
    paises = [f for f in d["features"] if f["properties"].get("CONTINENT") == "South America" and f["properties"]["ISO_A3"] not in EXCLUIR]
    crudos = {}
    for f in paises:
        lista = []
        for a in anillos(f["geometry"]):
            s = simplificar_anillo([(p[0], p[1]) for p in a], TOL)
            if len(s) >= 4 and abs(sum(s[i][0] * s[(i + 1) % len(s)][1] - s[(i + 1) % len(s)][0] * s[i][1] for i in range(len(s)))) / 2 > 0.15:
                lista.append(s)
        crudos[f["properties"]["ISO_A3"]] = (f["properties"]["NAME"], lista)
    xs = [p[0] for _, ls in crudos.values() for l in ls for p in l]
    ys = [p[1] for _, ls in crudos.values() for l in ls for p in l]
    k = math.cos(math.radians(23))
    x0, x1, y0, y1 = min(xs) * k, max(xs) * k, min(ys), max(ys)
    alto = y1 - y0
    out = {"fuente": "Natural Earth 1:50m admin-0 (dominio público), simplificado", "ilustrativo": True, "ancho_rel": round((x1 - x0) / alto, 5), "paises": {}}
    for iso, (nombre, ls) in sorted(crudos.items()):
        out["paises"][iso] = {"nombre": nombre, "contornos": [[[round((p[0] * k - x0) / alto, 4), round((y1 - p[1]) / alto, 4)] for p in l] for l in ls]}
    json.dump(out, open(ROOT / "data" / "geo" / "sudamerica.json", "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(len(out["paises"]), "países;", sum(len(c["contornos"]) for c in out["paises"].values()), "contornos; ancho_rel", out["ancho_rel"])


if __name__ == "__main__":
    main()
