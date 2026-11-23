#!/usr/bin/env python3
"""Fichas de obras del MOP publicadas en www.mop.gob.cl, doh.mop.gob.cl y dop.mop.gob.cl (tipo WordPress 'project').

Los textos traen 'Región/Ubicación/Servicio/Estado/Monto/Fecha de Inicio/Fecha de Término/Código Bip' (monto en CLP salvo que diga UF/USD).
Salida: data/proyectos/mop_obras_<sector>.json
Uso   : python3 tools/proyectos/mop_obras.py
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import *  # noqa

SITIOS = {"www": "MOP", "doh": "MOP - Dirección de Obras Hidráulicas", "dop": "MOP - Dirección de Obras Portuarias"}
ESTADO = {"ejecucion": "ejecucion", "construccion": "ejecucion", "diseno": "diseno", "prefactibilidad": "prefactibilidad",
          "perfil": "perfil", "licitacion": "licitacion", "terminado": "terminado", "finalizado": "terminado"}
SECTOR = [("vialidad", "vial"), ("rutas-interurbanas", "vial"), ("aeropuerto", "aeropuertos"), ("portuaria", "puertos"),
          ("bordes-costeros", "puertos"), ("hidraulicas", "agua"), ("embalses", "agua"), ("agua-potable", "agua"),
          ("antialuvionales", "agua"), ("arquitec", "edificacion"), ("edificacion", "edificacion"), ("concesiones", "vial")]
CAMPO = re.compile(r"(Región|Ubicación|Servicio|Estado|Monto|Fecha de Inicio|Fecha de Término|Código Bip|Descripción del Proyecto):")


def campos(txt):
    partes = CAMPO.split(txt)
    return {partes[i].strip(): partes[i + 1].strip() for i in range(1, len(partes) - 1, 2)}


def fecha_dmy(t):
    m = re.search(r"(\d{2})/(\d{2})/(\d{4})", t or "")
    return f"{m.group(3)}-{m.group(2)}-{m.group(1)}" if m else fecha_es(t or "")


def main():
    por_sector = defaultdict(list)
    for sitio, mandante in SITIOS.items():
        for p in get_json(f"https://{sitio}.mop.gob.cl/wp-json/wp/v2/project?per_page=100&_fields=id,link,title,content,class_list,acf"):
            nombre = texto_plano(p["title"]["rendered"])
            cuerpo = texto_plano(p["content"]["rendered"])
            if not cuerpo and isinstance(p.get("acf"), dict):
                cuerpo = texto_plano(p["acf"].get("descripcion", ""))
            f = campos(cuerpo)
            clases = " ".join(p["class_list"])
            sector = next((s for k, s in SECTOR if k in clases), "otros")
            reg = regiones_de(f.get("Región", ""))
            cat = [r for c in p["class_list"] if c.startswith("project_category-")
                   for r in regiones_de(c[len("project_category-"):].replace("-", " "))]
            conflicto = bool(cat and reg and cat[0] != reg[0])
            if cat and (not reg or conflicto):
                reg = cat[:1]  # la categoría coincide con la ubicación; el campo 'Región' del texto es inconsistente
            monto = f.get("Monto", "")
            uf, usd = montos(monto)
            clp = None
            if uf is None and usd is None:
                m = re.match(r"\$?\s*([\d\.]+)", monto)
                clp = num_es(m.group(1)) if m else None
            est_txt = norm(f.get("Estado", ""))
            estado = ESTADO.get(est_txt)
            if estado is None:
                continue
            por_sector[sector].append(registro(
                id=f"mop-{sitio}-{p['id']}-{slug(nombre, 50)}", nombre=nombre, sector=sector, region_ids=reg,
                comuna=f.get("Ubicación") or None, estado=estado, inversion_uf=uf, inversion_musd=usd, inversion_clp=clp,
                fecha_inicio=fecha_dmy(f.get("Fecha de Inicio")), fecha_fin=fecha_dmy(f.get("Fecha de Término")),
                mandante=f.get("Servicio") or mandante,
                descripcion=(f.get("Descripción del Proyecto") or cuerpo)[:400] or None, fuente_url=p["link"],
                fuente="fuentes.json#mop_obras", verificado=bool(reg and monto),
                notas=("región corregida por categoría (el texto de la ficha discrepa); " if conflicto else "") + f"estado según la ficha (fecha de consulta); código BIP: {f.get('Código Bip', 'n/d')}; monto en CLP salvo que indique UF/USD"))
    meta = {"fuente": "mop_obras", "scraper": "tools/proyectos/mop_obras.py", "fecha_consulta": HOY,
            "nota": "Fichas de obras destacadas; muchas con fechas de 2021-2024 (el estado puede estar desactualizado)."}
    registrar_fuente("mop_obras", "Ministerio de Obras Públicas (MOP) y sus direcciones", "Fichas de obras: Vialidad, DOH, DOP, Arquitectura, Aeropuertos",
                     "https://www.mop.gob.cl/", 365)
    for s, regs in por_sector.items():
        guardar(f"mop_obras_{s}", regs, meta)


if __name__ == "__main__":
    main()
