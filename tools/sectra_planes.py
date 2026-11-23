#!/usr/bin/env python3
"""Extrae los planes maestros de transporte urbano que SECTRA publica por ciudad (https://www.sectra.gob.cl/plan-y-proyecto/).

Salida: data/sectra_planes.json  (ciudad, plazo, valor de la cartera en millones de UF y proyectos con inversión en UF, TIR, mandante, estado y descripción)
Uso   : python3 tools/sectra_planes.py
Nota  : la página de la Región Metropolitana de Santiago no publica contenido (solo el título); queda registrada como vacía.
"""
import html
import json
import re
import time
from datetime import date
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
API = "https://www.sectra.gob.cl/wp-json/wp/v2/plan-y-proyecto?per_page=100&_fields=id,slug,link,title,modified"
REGION_ID = {"region-de-arica-y-parinacota": "arica", "region-de-tarapaca": "tarapaca", "region-de-antofagasta": "antofagasta",
             "region-de-atacama": "atacama", "region-de-coquimbo": "coquimbo", "region-de-valparaiso": "valparaiso",
             "region-metropolitana-de-santiago": "metropolitana", "region-del-libertador-general-bernardo-ohiggins": "ohiggins",
             "region-del-maule": "maule", "region-de-nuble": "nuble", "region-del-biobio": "biobio", "region-de-la-araucania": "araucania",
             "region-de-los-rios": "losrios", "region-de-los-lagos": "loslagos",
             "region-de-aysen-del-general-carlos-ibanez-del-campo": "aysen", "region-de-magallanes": "magallanes"}
CAMPOS = ("Inversión:", "TIR:", "Mandante:", "Estado:", "Descripción:")


def get(url):
    req = Request(url, headers={"User-Agent": "Mozilla/5.0 (investigacion de datos abiertos del proyecto)"})
    with urlopen(req, timeout=60) as r:
        return r.read().decode("utf-8", "ignore")


def num(txt):
    txt = txt.strip().replace(".", "").replace(",", ".")
    try:
        return float(txt)
    except ValueError:
        return None


def lineas(pagina):
    t = re.sub(r"(?is)<(script|style|noscript|header|footer|nav)[^>]*>.*?</\1>", " ", pagina)
    t = html.unescape(re.sub(r"(?s)<[^>]+>", "\n", t))
    return [l.strip() for l in t.split("\n") if l.strip()]


def parsear(pagina):
    L = lineas(pagina)
    res = {"plazo": None, "cartera_musd_uf": None, "poblacion": None, "hogares": None, "proyectos": []}
    for k, l in enumerate(L):
        if l == "Población:" and k + 1 < len(L):
            res["poblacion"] = num(L[k + 1])
        if l == "Hogares:" and k + 1 < len(L):
            res["hogares"] = num(L[k + 1])
        if l == "Plazo de Ejecución" and k > 0:
            res["plazo"] = L[k - 1]
        if l.startswith("Valor de la cartera") and k > 0:
            res["cartera_musd_uf"] = num(L[k - 1])
    ini = [k for k, l in enumerate(L) if l.startswith("Proyectos Plan Maestro")]
    if ini:
        k = ini[0]
        while k < len(L):
            if k + 1 < len(L) and L[k + 1] == CAMPOS[0]:
                p = {"nombre": L[k]}
                k += 1
                clave = None
                while k < len(L) and not (k + 1 < len(L) and L[k + 1] == CAMPOS[0]):
                    if L[k] in CAMPOS:
                        clave = L[k][:-1]
                        p[clave] = ""
                    elif clave:
                        p[clave] = (p[clave] + " " + L[k]).strip()
                    k += 1
                res["proyectos"].append({"nombre": p["nombre"], "inversion_uf": num(p.get("Inversión", "")), "tir_pct": num(p.get("TIR", "")),
                                         "mandante": p.get("Mandante", ""), "estado": p.get("Estado", ""), "descripcion": p.get("Descripción", "")})
            else:
                k += 1
    return res


def main():
    items = json.loads(get(API))
    ciudades = []
    for it in sorted(items, key=lambda x: x["slug"]):
        if it["slug"].startswith("region-de") or it["slug"].startswith("region-del") or it["slug"] == "region-metropolitana-de-santiago":
            pass  # las páginas "región" se guardan igual: algunas son agregados o están vacías
        try:
            datos = parsear(get(it["link"]))
        except Exception as e:  # noqa: BLE001
            datos = {"error": str(e), "proyectos": []}
        ciudades.append({"id": it["slug"], "region_id": REGION_ID.get(it["slug"], ""), "titulo": html.unescape(it["title"]["rendered"]), "url": it["link"], "modificado": it["modified"][:10],
                         **datos, "vacia": not datos.get("proyectos") and not datos.get("plazo")})
        time.sleep(0.4)
    salida = {"fuente": "fuentes.json#sectra_planes", "fecha_corte": str(date.today()), "unidad_inversion": "UF",
              "nota": "Datos de SECTRA (Programa de Vialidad y Transporte Urbano, MTT). La Región Metropolitana de Santiago no publica contenido en el sitio.",
              "ciudades": ciudades}
    (ROOT / "data/sectra_planes.json").write_text(json.dumps(salida, ensure_ascii=False, indent=1), encoding="utf-8")
    con = [c for c in ciudades if c["proyectos"]]
    print(f"{len(ciudades)} páginas, {len(con)} con proyectos, {sum(len(c['proyectos']) for c in con)} proyectos")
    for c in ciudades:
        print(f"{c['id']:48s} proyectos={len(c['proyectos']):3d} plazo={c.get('plazo')} cartera={c.get('cartera_musd_uf')} {'(vacía)' if c['vacia'] else ''}")


if __name__ == "__main__":
    main()
