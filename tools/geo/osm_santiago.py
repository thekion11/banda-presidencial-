#!/usr/bin/env python3
"""Pipeline OSM -> datos del juego para Gran Santiago (Fase 3 del plan: calles reales, Metro y grafo de Dijkstra).

Entrada : extracto Santiago.osm.pbf (BBBike, © colaboradores de OpenStreetMap, ODbL).
Salidas : data/geo/urbano_real.json  (calles, río, parques, líneas y estaciones de Metro, marcadores)
          data/geo/grafo_urbano.json (grafo de calles para el Comité: nodos, aristas con polilíneas y costos)
          data/propuestas.json       (se actualizan 'trazado' y 'estaciones' de las variantes)
Uso     : python3 tools/geo/osm_santiago.py <Santiago.osm.pbf>
Requiere: pip install osmium
Atribución obligatoria en el juego: © colaboradores de OpenStreetMap.
"""
import hashlib
import heapq
import json
import math
import sys
from pathlib import Path

import osmium

ROOT = Path(__file__).resolve().parents[2]
LON0, LON1, LAT0, LAT1 = -70.80, -70.52, -33.57, -33.38
CENTRO = (-70.6506, -33.4372)  # Plaza de Armas
CLASES = {"motorway": 0, "trunk": 1, "primary": 2, "secondary": 3, "tertiary": 4}
MAX_CLASE_GRAFO = 2  # el grafo usa vías principales (primary o superior); el resto solo se dibuja
MAX_NODOS = 700


def plano(lon, lat):
    return ((lon - LON0) / (LON1 - LON0), (LAT1 - lat) / (LAT1 - LAT0))


def dentro(lon, lat):
    return LON0 <= lon <= LON1 and LAT0 <= lat <= LAT1


def km(a, b):
    """Distancia aproximada en km entre dos puntos (lon, lat)."""
    dx = (a[0] - b[0]) * 111.32 * math.cos(math.radians((a[1] + b[1]) / 2))
    dy = (a[1] - b[1]) * 111.2
    return math.hypot(dx, dy)


def dp(puntos, tol):
    if len(puntos) < 3:
        return puntos
    mant = [False] * len(puntos)
    mant[0] = mant[-1] = True
    pila = [(0, len(puntos) - 1)]
    while pila:
        a, b = pila.pop()
        (ax, ay), (bx, by) = puntos[a], puntos[b]
        dx, dy = bx - ax, by - ay
        n = math.hypot(dx, dy) or 1e-12
        m, idx = 0.0, -1
        for i in range(a + 1, b):
            d = abs(dy * (puntos[i][0] - ax) - dx * (puntos[i][1] - ay)) / n
            if d > m:
                m, idx = d, i
        if m > tol and idx > 0:
            mant[idx] = True
            pila += [(a, idx), (idx, b)]
    return [p for p, k in zip(puntos, mant) if k]


def segmentos_cruzan(p1, p2, p3, p4):
    def o(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
    return o(p1, p2, p3) * o(p1, p2, p4) < 0 and o(p3, p4, p1) * o(p3, p4, p2) < 0


def leer(pbf):
    # Pasada 1: relaciones de Metro (ref y color por vía)
    via_linea = {}
    for r in osmium.FileProcessor(pbf, osmium.osm.RELATION):
        if r.tags.get("route") == "subway":
            for m in r.members:
                if m.type == "w":
                    via_linea[m.ref] = (r.tags.get("ref", "?"), r.tags.get("colour", "#888888"))
    carreteras, metro, rio, parques, estaciones = [], {}, [], [], []
    # Pasada 2: vías con geometría
    for o in osmium.FileProcessor(pbf).with_locations():
        if o.is_node() and o.tags.get("railway") == "station" and (o.tags.get("subway") == "yes" or o.tags.get("station") == "subway"):
            if dentro(o.location.lon, o.location.lat):
                estaciones.append({"n": o.tags.get("name", ""), "p": plano(o.location.lon, o.location.lat)})
        if not o.is_way():
            continue
        t = o.tags
        try:
            pts = [(n.lon, n.lat) for n in o.nodes]
            refs = [n.ref for n in o.nodes]
        except Exception:
            continue
        hw = t.get("highway", "").replace("_link", "")
        if hw in CLASES:
            carreteras.append({"c": CLASES[hw], "pts": pts, "refs": refs, "nombre": t.get("name", "")})
        elif t.get("railway") == "subway" and o.id in via_linea:
            ref, col = via_linea[o.id]
            metro.setdefault(ref, {"color": col, "vias": []})["vias"].append(pts)
        elif t.get("waterway") in ("river", "canal") and "Mapocho" in t.get("name", ""):
            rio.append(pts)
        elif t.get("leisure") == "park" and pts[0] == pts[-1] and len(pts) > 5:
            parques.append(pts)
    return carreteras, metro, rio, parques, estaciones


def recortar(pts):
    """Divide una polilínea en tramos contenidos en el recuadro."""
    tramos, actual = [], []
    for p in pts:
        if dentro(*p):
            actual.append(p)
        elif len(actual) > 1:
            tramos.append(actual)
            actual = []
        else:
            actual = []
    if len(actual) > 1:
        tramos.append(actual)
    return tramos


def area_km2(poly):
    s = 0.0
    for i in range(len(poly) - 1):
        s += poly[i][0] * poly[i + 1][1] - poly[i + 1][0] * poly[i][1]
    return abs(s) / 2.0 * 111.32 * math.cos(math.radians(-33.45)) * 111.2


def construir_grafo(carreteras, rio_plano):
    """Nodos = cruces (nodo OSM compartido por 2+ vías) y extremos; aristas con polilínea, largo real y costos."""
    uso = {}
    sel = [c for c in carreteras if c["c"] <= MAX_CLASE_GRAFO]
    for c in sel:
        for r in c["refs"]:
            uso[r] = uso.get(r, 0) + 1
    pos = {}
    aristas = []
    for c in sel:
        pts, refs = c["pts"], c["refs"]
        idx = [i for i, r in enumerate(refs) if dentro(*pts[i]) and (uso[r] >= 2 or i in (0, len(refs) - 1))]
        for a, b in zip(idx, idx[1:]):
            if b - a < 1 or any(not dentro(*pts[k]) for k in range(a, b + 1)):
                continue
            seg = pts[a:b + 1]
            largo = sum(km(seg[k], seg[k + 1]) for k in range(len(seg) - 1))
            ra, rb = refs[a], refs[b]
            if ra == rb:
                continue
            pos[ra], pos[rb] = pts[a], pts[b]
            aristas.append({"a": ra, "b": rb, "clase": c["c"], "largo": largo, "poly": [plano(*p) for p in seg]})
    # componente conexa más grande
    ady = {}
    for e in aristas:
        ady.setdefault(e["a"], []).append(e["b"])
        ady.setdefault(e["b"], []).append(e["a"])
    visto, mejor = set(), set()
    for n in ady:
        if n in visto:
            continue
        comp, pila = set(), [n]
        while pila:
            x = pila.pop()
            if x in comp:
                continue
            comp.add(x)
            pila.extend(ady[x])
        visto |= comp
        if len(comp) > len(mejor):
            mejor = comp
    # deduplicar aristas paralelas, quedándose con la más corta
    unicas = {}
    for e in aristas:
        if e["a"] in mejor and e["b"] in mejor:
            k = tuple(sorted((e["a"], e["b"])))
            if k not in unicas or e["largo"] < unicas[k]["largo"]:
                unicas[k] = e
    unicas = contraer(unicas)
    nodos_ids = sorted({x for k in unicas for x in k})
    ids = {r: f"n{i}" for i, r in enumerate(nodos_ids)}
    nodos = [{"id": ids[r], "x": round(plano(*pos[r])[0], 5), "y": round(plano(*pos[r])[1], 5)} for r in nodos_ids]
    out = []
    for (ra, rb), e in sorted(unicas.items()):
        poly = dp([tuple(p) for p in e["poly"]], 0.0006)
        mid = ((poly[0][0] + poly[-1][0]) / 2, (poly[0][1] + poly[-1][1]) / 2)
        cx, cy = plano(*CENTRO)
        dens = max(0.0, 1.0 - math.hypot(mid[0] - cx, mid[1] - cy) / 0.55)
        rio = any(segmentos_cruzan(poly[i], poly[i + 1], rio_plano[j], rio_plano[j + 1])
                  for i in range(len(poly) - 1) for j in range(len(rio_plano) - 1)) if rio_plano else False
        h = int(hashlib.sha256((ids[ra] + ids[rb]).encode()).hexdigest(), 16)
        out.append({"a": ids[ra], "b": ids[rb], "longitud": round(max(e["largo"], 0.05), 3),
                    "costo_mult": round(1.0 + dens * 0.6 + 0.12 * (e["clase"] - 2 if e["clase"] > 2 else 0) + (0.9 if rio else 0.0), 3),
                    "expropiaciones": round(dens * 14 * max(0.4, e["largo"])) + h % 5, "rio": rio,
                    "poly": [[round(x, 5), round(y, 5)] for x, y in poly]})
    return nodos, out


def contraer(unicas):
    """Fusiona los nodos de grado 2 (puntos intermedios de una misma calle): conserva polilínea y largo acumulados."""
    cambio = True
    while cambio:
        cambio = False
        ady = {}
        for k, e in unicas.items():
            ady.setdefault(e["a"], []).append(k)
            ady.setdefault(e["b"], []).append(k)
        for n, ks in ady.items():
            if len(ks) != 2 or ks[0] == ks[1]:
                continue
            e1, e2 = unicas[ks[0]], unicas[ks[1]]
            otro1 = e1["b"] if e1["a"] == n else e1["a"]
            otro2 = e2["b"] if e2["a"] == n else e2["a"]
            if otro1 == otro2:
                continue
            p1 = e1["poly"] if e1["b"] == n else e1["poly"][::-1]  # termina en n
            p2 = e2["poly"] if e2["a"] == n else e2["poly"][::-1]  # empieza en n
            nuevo = {"a": otro1, "b": otro2, "clase": min(e1["clase"], e2["clase"]), "largo": e1["largo"] + e2["largo"], "poly": p1 + p2[1:]}
            k = tuple(sorted((otro1, otro2)))
            del unicas[ks[0]], unicas[ks[1]]
            if k not in unicas or nuevo["largo"] < unicas[k]["largo"]:
                unicas[k] = nuevo
            cambio = True
            break
    return unicas


def dijkstra(nodos, aristas, a, b):
    ady = {n["id"]: [] for n in nodos}
    for e in aristas:
        w = e["longitud"] * e["costo_mult"] + 0.15 * e["expropiaciones"]
        ady[e["a"]].append((e["b"], w))
        ady[e["b"]].append((e["a"], w))
    dist, prev, cola = {a: 0.0}, {}, [(0.0, a)]
    while cola:
        d, u = heapq.heappop(cola)
        if u == b:
            break
        if d > dist.get(u, 1e18):
            continue
        for v, w in ady[u]:
            if d + w < dist.get(v, 1e18):
                dist[v], prev[v] = d + w, u
                heapq.heappush(cola, (d + w, v))
    ruta, c = [b], b
    while c != a:
        c = prev[c]
        ruta.append(c)
    return ruta[::-1]


def main():
    pbf = sys.argv[1]
    carreteras, metro, rio, parques, estaciones = leer(pbf)
    print(f"vías {len(carreteras)}, líneas de metro {sorted(metro)}, río {len(rio)}, parques {len(parques)}, estaciones {len(estaciones)}")
    rio_p = []
    for pts in rio:
        for tr in recortar(pts):
            rio_p.append([plano(*p) for p in tr])
    rio_union = max(rio_p, key=len) if rio_p else []
    nodos, aristas = construir_grafo(carreteras, rio_union)
    print(f"grafo: {len(nodos)} nodos, {len(aristas)} aristas")
    # --- urbano_real.json
    calles = []
    for c in carreteras:
        for tr in recortar(c["pts"]):
            p = dp([plano(*q) for q in tr], 0.0005)
            if len(p) > 1:
                calles.append({"c": c["c"], "p": [[round(x, 4), round(y, 4)] for x, y in p]})
    lineas = []
    for ref, d in sorted(metro.items()):
        vias = []
        for pts in d["vias"]:
            for tr in recortar(pts):
                p = dp([plano(*q) for q in tr], 0.0004)
                if len(p) > 1:
                    vias.append([[round(x, 4), round(y, 4)] for x, y in p])
        lineas.append({"id": ref, "color": d["color"], "vias": vias})
    pk = []
    for pts in parques:
        if area_km2(pts) > 0.12 and all(dentro(*p) for p in pts[::5]):
            p = dp([plano(*q) for q in pts], 0.0006)
            pk.append([[round(x, 4), round(y, 4)] for x, y in p])
    marcadores = [plano(-70.6080, -33.4180), plano(-70.5800, -33.5100), plano(-70.7200, -33.4900), plano(-70.6300, -33.5500), plano(-70.6900, -33.4000)]
    real = {"atribucion": "© colaboradores de OpenStreetMap (ODbL)", "bbox": [LON0, LAT0, LON1, LAT1],
            "aspecto": round((LON1 - LON0) * math.cos(math.radians(-33.47)) / (LAT1 - LAT0), 3),
            "calles": calles, "rio": [[[round(x, 4), round(y, 4)] for x, y in r] for r in rio_p],
            "parques": pk, "metro": lineas,
            "estaciones": [{"n": e["n"], "p": [round(e["p"][0], 4), round(e["p"][1], 4)]} for e in estaciones],
            "marcadores": [[round(x, 4), round(y, 4)] for x, y in marcadores]}
    (ROOT / "data/geo/urbano_real.json").write_text(json.dumps(real, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    # --- grafo_urbano.json
    grafo = {"nota": "Grafo de calles de Gran Santiago derivado de OpenStreetMap (© colaboradores, ODbL).",
             "parametros": json.loads((ROOT / "data/geo/grafo_urbano.json").read_text())["parametros"],
             "nodos": nodos, "aristas": aristas}
    (ROOT / "data/geo/grafo_urbano.json").write_text(json.dumps(grafo, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    # --- variantes de las propuestas: estaciones (nodos) y trazado (polilínea sobre el grafo)
    def cercano(lon, lat):
        x, y = plano(lon, lat)
        return min(nodos, key=lambda n: (n["x"] - x) ** 2 + (n["y"] - y) ** 2)["id"]
    por_id = {n["id"]: n for n in nodos}
    ari = {}
    for e in aristas:
        ari[(e["a"], e["b"])] = e["poly"]
        ari[(e["b"], e["a"])] = e["poly"][::-1]
    esquemas = {
        "prop_metro_suroriente": {
            "A": [(-70.6506, -33.4372), (-70.6295, -33.4580), (-70.6125, -33.4980), (-70.5985, -33.5290), (-70.5860, -33.5560)],
            "B": [(-70.6506, -33.4372), (-70.6250, -33.4650), (-70.6100, -33.5000), (-70.5900, -33.5300), (-70.5860, -33.5560)],
            "C": [(-70.6506, -33.4372), (-70.6330, -33.4600), (-70.6050, -33.4950), (-70.5950, -33.5250), (-70.5860, -33.5560)]},
        "prop_tren_valparaiso": {
            "A": [(-70.6783, -33.4519), (-70.7100, -33.4600), (-70.7500, -33.4450), (-70.7850, -33.4300)],
            "B": [(-70.6783, -33.4519), (-70.7150, -33.4650), (-70.7500, -33.4500), (-70.7850, -33.4350)],
            "C": [(-70.6783, -33.4519), (-70.7050, -33.4550), (-70.7450, -33.4600), (-70.7850, -33.4450)]}}
    props = json.loads((ROOT / "data/propuestas.json").read_text(encoding="utf-8"))
    for p in props:
        for v in p["variantes"]:
            ests = []
            for lon, lat in esquemas[p["id"]][v["id"]]:
                n = cercano(lon, lat)
                if not ests or ests[-1] != n:
                    ests.append(n)
            trazado, ruta_total = [], []
            for a, b in zip(ests, ests[1:]):
                ruta = dijkstra(nodos, aristas, a, b)
                for u, w in zip(ruta, ruta[1:]):
                    trazado += ari[(u, w)] if not trazado else ari[(u, w)][1:]
            v["estaciones"] = ests
            v["trazado"] = trazado
    (ROOT / "data/propuestas.json").write_text(json.dumps(props, ensure_ascii=False, indent=1), encoding="utf-8")
    for f in ("urbano_real.json", "grafo_urbano.json"):
        print(f, (ROOT / "data/geo" / f).stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main()
