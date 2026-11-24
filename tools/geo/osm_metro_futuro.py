#!/usr/bin/env python3
"""Líneas 7, 8 y 9 del Metro de Santiago (en construcción o proyectadas) desde OpenStreetMap.

Entrada : Santiago.osm.pbf (BBBike, © colaboradores de OpenStreetMap, ODbL). Las relaciones de ruta están en OSM con su trazado y sus paradas.
Salida  : data/geo/metro_futuro.json  (por línea: color, estado, trazado en el plano 0..1 de urbano_real.json, estaciones en orden con nombre y posición)
Uso     : python3 tools/geo/osm_metro_futuro.py <Santiago.osm.pbf>
Requiere: pip install osmium
Los colores NO vienen de OSM (los pusieron los mapeadores): ver COLORES (Wikipedia/Wikidata, sin confirmar por Metro S.A.).
"""
import json
import sys
from pathlib import Path

import osmium

RAIZ = Path(__file__).resolve().parents[2]
# id de la relación de ruta en OSM (dos sentidos por línea; se usa el primero para el orden y ambos para el trazado)
RELACIONES = {"L7": [15789478, 17824814], "L8": [15782337, 17824838], "L9": [15809438, 17824839]}
COLORES = {"L7": "#96989A", "L8": "#FF6414", "L9": "#EE7FA9"}  # gris, naranjo, rosado (es.wikipedia / Wikidata; L9: el infobox y el texto dicen rosado, Wikidata trae #FF00FF)
ESTADOS = {"L7": "en construcción", "L8": "en licitación", "L9": "en construcción"}
APERTURA = {"L7": "est. 2028 (segundo semestre)", "L8": "c. 2032", "L9": "c. 2030 (por tramos hasta 2033)"}
APERTURA_FECHA = {"L7": "2028-07-01", "L8": "2032-01-01", "L9": "2030-06-01"}  # estimaciones para marcar la línea como abierta en la partida
NOMBRES = {"Isidora Goyanechea": "Isidora Goyenechea", "Bío-Bío": "Bío Bío"}  # grafías de OSM que difieren de la oficial/usada en el mapa


class Miembros(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.rel = {}

    def relation(self, r):
        for lid, ids in RELACIONES.items():
            if r.id in ids:
                self.rel[r.id] = [(m.type, m.ref, m.role) for m in r.members]


class Geometria(osmium.SimpleHandler):
    def __init__(self, nodos, vias):
        super().__init__()
        self.nodos, self.vias = nodos, vias
        self.n, self.w = {}, {}

    def node(self, n):
        if n.id in self.nodos:
            self.n[n.id] = (n.location.lon, n.location.lat, n.tags.get("name", ""))

    def way(self, w):
        if w.id in self.vias:
            self.w[w.id] = [(p.lon, p.lat) for p in w.nodes if p.location.valid()]


def main():
    pbf = sys.argv[1]
    geo = json.loads((RAIZ / "data/geo/urbano_real.json").read_text(encoding="utf-8"))
    lon0, lat0, lon1, lat1 = geo["bbox"]
    plano = lambda lon, lat: [round((lon - lon0) / (lon1 - lon0), 4), round((lat1 - lat) / (lat1 - lat0), 4)]
    m = Miembros()
    m.apply_file(pbf)
    nodos = {ref for ms in m.rel.values() for t, ref, _ in ms if t == "n"}
    vias = {ref for ms in m.rel.values() for t, ref, _ in ms if t == "w"}
    g = Geometria(nodos, vias)
    g.apply_file(pbf, locations=True)
    salida = {"fuente": "OpenStreetMap contributors (ODbL), extracto BBBike de Gran Santiago", "colores": "es.wikipedia / Wikidata, sin confirmar por Metro S.A.", "lineas": {}}
    for lid, ids in RELACIONES.items():
        paradas, trazos = [], []
        for k, rid in enumerate(ids):
            for t, ref, rol in m.rel.get(rid, []):
                if t == "w" and ref in g.w and k == 0:
                    trazos.append([plano(*p) for p in g.w[ref]])
                if t == "n" and ref in g.n and k == 0:
                    lon, lat, nombre = g.n[ref]
                    paradas.append({"n": NOMBRES.get(nombre, nombre), "p": plano(lon, lat), "ll": [round(lat, 5), round(lon, 5)]})
        salida["lineas"][lid] = {"color": COLORES[lid], "estado": ESTADOS[lid], "apertura": APERTURA[lid], "apertura_fecha": APERTURA_FECHA[lid], "relacion_osm": ids, "vias": trazos, "estaciones": paradas}
        print(lid, "vías", len(trazos), "puntos", sum(len(v) for v in trazos), "estaciones", len(paradas), [p["n"] for p in paradas][:30])
    (RAIZ / "data/geo/metro_futuro.json").write_text(json.dumps(salida, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


if __name__ == "__main__":
    main()
