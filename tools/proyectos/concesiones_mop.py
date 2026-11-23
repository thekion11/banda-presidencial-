#!/usr/bin/env python3
"""Cartera de concesiones del MOP (Dirección General de Concesiones, concesiones.mop.gob.cl).

Fuente: API REST de WordPress, tipo 'project' (ficha del proyecto con región, comunas, presupuesto oficial, fechas).
Salida: data/proyectos/concesiones_<sector>.json  (vial, hospitalario, penitenciario, aeroportuario, edificacion, hidrico, otros)
Uso   : python3 tools/proyectos/concesiones_mop.py
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import *  # noqa

API = "https://concesiones.mop.gob.cl/wp-json/wp/v2/project?per_page=100&page={p}&_fields=id,slug,link,title,content,class_list,acf,modified"
CORTE = date(2026, 3, 11)
SECTOR = {"infraestructura-vial-interurbana": "vial", "infraestructura-vial-urbana": "vial",
          "infraestructura-hospitalaria": "salud", "infraestructura-penitenciaria": "seguridad",
          "infraestructura-aeroportuaria": "aeropuertos", "edificacion-publica-y-equipamiento-urbano": "edificacion",
          "soluciones-hidricas": "agua"}
ESTADO = [("cartera", "perfil"), ("proceso-de-licitacion", "licitacion"), ("licitacion", "licitacion"),
          ("operacion-y-construccion", "ejecucion"), ("construccion", "ejecucion"), ("operacion", "terminado"),
          ("finalizadas", "terminado")]


def clasificar(clases):
    cats = [c for c in clases if c.startswith("project_category-")]
    est = next((e for k, e in ESTADO for c in cats if k in c), None)
    tipo = next((SECTOR[c[len("tipo-infraestructura-"):]] for c in clases
                 if c.startswith("tipo-infraestructura-") and c[len("tipo-infraestructura-"):] in SECTOR), "otros")
    return est, tipo, cats


def descargar():
    out, p = [], 1
    while True:
        try:
            d = get_json(API.format(p=p))
        except Exception:
            break
        out += d
        if len(d) < 100:
            break
        p += 1
    return out


def main():
    por_sector = defaultdict(list)
    for p in descargar():
        f = (p.get("acf") or {}).get("ficha_del_proyecto") or {}
        est, sector, cats = clasificar(p["class_list"])
        if est is None:
            continue
        nombre = texto_plano(p["title"]["rendered"])
        uf, usd = montos(f.get("presupuesto_oficial", ""))
        reg = regiones_de(f.get("region", ""))
        if not reg and "red-aeroportuaria-sur" in slug(nombre):
            reg = ["loslagos", "losrios"]  # Tepual, Cañal Bajo, Mocopulli (Los Lagos) y Pichoy (Los Ríos); la ficha dice 'Territorio nacional'
        ini = fecha_es(f.get("fecha_de_inicio_concesion", ""))
        if est == "perfil":
            ini = fecha_es(f.get("fecha_de_llamado_a_licitacion", ""))
        plazo = texto_plano(f.get("plazo_total_de_la_concesion", ""))
        fin = None
        m = re.search(r"finaliz[oó] el (\d+ de \w+ de \d{4})", plazo)
        if m:
            fin = fecha_es(m.group(1))
        e0311 = None
        if est in ("ejecucion", "terminado") and ini and re.fullmatch(r"\d{4}-\d\d-\d\d", ini) and ini < CORTE.isoformat():
            e0311 = "ejecucion" if est == "ejecucion" or not fin or fin >= CORTE.isoformat() else "terminado"
            if est == "terminado" and e0311 == "ejecucion":
                e0311 = "terminado"  # en operación (obras ya construidas)
        reg_txt = texto_plano(f.get("region", ""))
        notas = [f"categoria_mop={';'.join(c[len('project_category-'):] for c in cats)}", f"plazo_concesion={plazo or 'n/d'}"]
        if not reg and "nacional" not in norm(reg_txt):
            notas.append(f"region_sin_mapear={reg_txt}")
        if est == "terminado" and "operacion" in "".join(cats):
            notas.append("concesión en operación (obras construidas)")
        por_sector[sector].append(registro(
            id=f"conc-{slug(nombre, 70)}", nombre=nombre, sector=sector, region_ids=reg, comuna=texto_plano(f.get("comuna", "")) or None,
            estado=est, estado_2026_03_11=e0311, inversion_uf=uf, inversion_musd=usd, fecha_inicio=ini, fecha_fin=fin,
            mandante="MOP - Dirección General de Concesiones", descripcion=texto_plano(p["content"]["rendered"])[:400] or None,
            fuente_url=p["link"], fuente="fuentes.json#mop_concesiones", verificado=bool(reg and f.get("presupuesto_oficial")),
            notas="; ".join(notas)))
    meta = {"fuente": "mop_concesiones", "scraper": "tools/proyectos/concesiones_mop.py", "fecha_consulta": HOY,
            "nota": "inversion_uf/usd = 'presupuesto oficial' de la ficha; 'terminado' incluye concesiones en operación. Fechas: hito oficial."}
    registrar_fuente("mop_concesiones", "MOP - Dirección General de Concesiones",
                     "Fichas de proyectos de concesiones (cartera 2026-2030, licitación, construcción, operación, finalizadas)",
                     "https://concesiones.mop.gob.cl/cartera-de-proyectos/")
    for s, regs in por_sector.items():
        guardar(f"concesiones_{s}", regs, meta)


if __name__ == "__main__":
    main()
