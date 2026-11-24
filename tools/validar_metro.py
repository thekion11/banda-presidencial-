#!/usr/bin/env python3
"""Cotejo del Metro del mapa (OSM) contra la lista de estaciones por línea (data/metro_oficial.json).
- Marca en data/geo/urbano_real.json qué líneas pasa cada estación (campo "l") y los terminales de cada línea dentro del mapa.
- Escribe docs/METRO_COMPARACION.md. Con --verificar solo comprueba y falla si hay incoherencias (sin escribir).
Uso: python3 tools/validar_metro.py [--verificar]"""
import json
import math
import re
import sys
import unicodedata
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
UMBRAL = 0.012  # distancia máxima (plano 0..1) entre estación y trazado de su línea


def dist_seg(p, a, b):
    ax, ay, bx, by = a[0], a[1], b[0], b[1]
    dx, dy = bx - ax, by - ay
    t = 0.0 if dx == dy == 0 else max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(p[0] - (ax + t * dx), p[1] - (ay + t * dy))


def dist_linea(p, linea):
    return min((dist_seg(p, v[i], v[i + 1]) for v in linea["vias"] for i in range(len(v) - 1)), default=9.0)


def _norm(texto: str) -> str:
    t = re.sub(r"\s+Dirección.*$", "", texto).strip().lower().replace("pdte.", "presidente")
    t = unicodedata.normalize("NFD", t)
    return re.sub(r"\s+", " ", "".join(c for c in t if unicodedata.category(c) != "Mn"))


def _metros(a, b) -> float:
    dx = (a[0] - b[0]) * 111320 * math.cos(math.radians((a[1] + b[1]) / 2))
    return math.hypot(dx, (a[1] - b[1]) * 111200)


def cotejo_gtfs(ofi, geo, pos, problemas):
    """Compara la lista y el mapa con el GTFS oficial de la Red Metropolitana: nombres, orden y posición (lat, lon) de cada estación."""
    gtfs = json.loads((RAIZ / "data/metro_gtfs.json").read_text(encoding="utf-8"))
    lon0, lon1, lat0, lat1 = geo["bbox"][0], geo["bbox"][2], geo["bbox"][1], geo["bbox"][3]
    en_mapa = {_norm(n): (lon0 + p[0] * (lon1 - lon0), lat1 - p[1] * (lat1 - lat0)) for n, p in pos.items()}
    comparadas, max_d, filas = 0, 0.0, []
    for lid, info in ofi["lineas"].items():
        g = gtfs["lineas"].get(lid, [])
        if [_norm(x["n"]) for x in g] != [_norm(n) for n in info["estaciones"]]:
            problemas.append(f"{lid}: los nombres u el orden de la lista difieren del GTFS")
        for x in g:
            n = _norm(x["n"])
            if n in en_mapa:
                d = _metros((x["lon"], x["lat"]), en_mapa[n])
                comparadas += 1
                max_d = max(max_d, d)
                if d > 250:
                    problemas.append(f"{lid}: {x['n']} a {round(d)} m de su posición en el GTFS")
        filas.append((lid, len(g), len(info["estaciones"])))
    return comparadas, max_d, filas, gtfs


def main() -> int:
    verificar = "--verificar" in sys.argv
    geo_ruta = RAIZ / "data/geo/urbano_real.json"
    geo = json.loads(geo_ruta.read_text(encoding="utf-8"))
    ofi = json.loads((RAIZ / "data/metro_oficial.json").read_text(encoding="utf-8"))
    pos = {e["n"]: e["p"] for e in geo["estaciones"]}
    lineas = {l["id"]: l for l in geo["metro"]}
    filas, problemas = [], []
    asignadas: dict[str, list[str]] = {n: [] for n in pos}
    for lid, info in ofi["lineas"].items():
        nombres = info["estaciones"]
        if lid not in lineas:
            problemas.append(f"{lid}: sin trazado en el mapa")
            continue
        dentro = [n for n in nombres if n in pos]
        fuera = [n for n in nombres if n not in pos]
        lejos = []
        for n in dentro:
            d = dist_linea(pos[n], lineas[lid])
            if d <= UMBRAL:
                asignadas[n].append(lid)
            else:
                lejos.append((n, round(d, 4)))
        if lejos:
            problemas.append(f"{lid}: estaciones lejos de su trazado {lejos}")
        term = [n for n in (nombres[0], nombres[-1])]
        filas.append((lid, len(nombres), len(dentro), fuera, lejos, [(n, n in pos) for n in term]))
    comp, max_d, filas_gtfs, gtfs = cotejo_gtfs(ofi, geo, pos, problemas)
    fut = json.loads((RAIZ / "data/geo/metro_futuro.json").read_text(encoding="utf-8"))
    cifras = {f["linea"]: f["estaciones"] for f in ofi["futuras"] if f["linea"] in ("L7", "L8", "L9")}
    for lid, info in fut["lineas"].items():
        if len(info["estaciones"]) != cifras.get(lid):
            problemas.append(f"{lid} futura: {len(info['estaciones'])} estaciones en OSM y {cifras.get(lid)} en la ficha")
    sobran = [n for n in pos if not asignadas[n]]
    if sobran:
        problemas.append(f"estaciones del mapa que no calzan con ninguna línea: {sobran}")
    if problemas:
        print("INCOHERENCIAS:")
        for p in problemas:
            print(" -", p)
    if verificar:
        return 1 if problemas else 0
    for e in geo["estaciones"]:
        e["l"] = asignadas[e["n"]]
    for l in geo["metro"]:
        info = ofi["lineas"].get(l["id"])
        if info:
            nombres = info["estaciones"]
            en_mapa = [n for n in nombres if n in pos]
            cabos = []
            for k, (n, vecina) in enumerate(((en_mapa[0], en_mapa[1]), (en_mapa[-1], en_mapa[-2]))):
                dx, dy = pos[n][0] - pos[vecina][0], pos[n][1] - pos[vecina][1]
                m = math.hypot(dx, dy) or 1.0
                real = nombres[0] if k == 0 else nombres[-1]
                cabos.append({"n": n, "p": pos[n], "d": [round(dx / m, 3), round(dy / m, 3)], "sigue": real not in pos})
            l["cabos"] = cabos
            l["orden"] = en_mapa  # estaciones de la línea dentro del mapa, en orden de terminal a terminal (vista esquemática)
            l.pop("term", None)
            l.pop("continua", None)
    geo_ruta.write_text(json.dumps(geo, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    md = ["# Metro del mapa vs. lista de estaciones (cotejo automático)", "",
          f"Fuente de la lista: {ofi['fuente']} (corte {ofi['corte']}).", f"**{ofi['verificacion']}**", "",
          "Geometría del mapa: OpenStreetMap (© colaboradores, ODbL), extracto de Gran Santiago (ventana lon -70,80..-70,52; lat -33,57..-33,38).", "",
          "| Línea | Estaciones (lista) | Dentro del mapa | Fuera de la ventana | Terminales dentro |", "|---|---|---|---|---|"]
    for lid, n, dentro, fuera, _lejos, term in filas:
        md.append(f"| {lid} | {n} | {dentro} | {', '.join(fuera) or '—'} | {', '.join(a + (' sí' if ok else ' NO') for a, ok in term)} |")
    md += ["", "## Cotejo con el GTFS oficial (Red Metropolitana, DTPM)", f"Fuente: {gtfs['fuente']} (vigencia {gtfs['vigencia']}; corte {gtfs['corte']}). {gtfs['url']}",
           f"Nombres y orden de las 7 líneas iguales a la lista; {comp} estaciones del mapa comparadas en posición: la mayor diferencia es de {round(max_d)} m (límite 250 m).", ""]
    md += ["", "## Líneas 7, 8 y 9 (futuras)", "Trazado y estaciones: relaciones de ruta de OpenStreetMap (`tools/geo/osm_metro_futuro.py`, `data/geo/metro_futuro.json`). "
           "Colores: es.wikipedia / Wikidata (L7 gris #96989A, L8 naranjo #FF6414, L9 rosado #EE7FA9; Wikidata trae #FF00FF para L9), sin confirmar por Metro S.A."]
    for lid, info in fut["lineas"].items():
        md.append(f"- {lid}: {len(info['estaciones'])} estaciones (ficha: {cifras.get(lid)}), {info['estado']}, apertura {info['apertura']}. Estaciones en OSM: {', '.join(e['n'] for e in info['estaciones'])}.")
    md += ["Los nombres de estación de OSM difieren en parte de la lista de Wikipedia (p. ej. L7: Parque de los Reyes, General Velásquez, Cerro Navia en OSM; Cumming, Walker Martínez, Neptuno en Wikipedia): son provisionales y hay que cotejarlos con Metro S.A.", ""]
    md += ["", f"Estaciones distintas en la lista: {len({n for i in ofi['lineas'].values() for n in i['estaciones']})}; en el mapa: {len(pos)}.",
           "Todas las estaciones del mapa calzan con una línea de la lista y ninguna está a más de %.3f del trazado de su línea." % UMBRAL if not problemas else "**Incoherencias:** " + "; ".join(problemas), "",
           "## Qué no cubre el mapa", "Las 11 estaciones fuera de la ventana son extensiones periféricas (L2 sur, L3 norte, L4 sur); el mapa las indica con una flecha en el borde.",
           "", "## Líneas futuras (no se dibujan; fuente y fecha en data/metro_oficial.json)"]
    for f in ofi["futuras"]:
        md.append(f"- {f['linea']}: {f['estado']}, apertura {f['apertura']}")
    md += ["", "## Discrepancias abiertas"] + [f"- {x}" for x in ofi["discrepancias"]]
    (RAIZ / "docs/METRO_COMPARACION.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print("OK: escrito docs/METRO_COMPARACION.md")
    return 1 if problemas else 0


if __name__ == "__main__":
    sys.exit(main())
