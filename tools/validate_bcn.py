"""Validación de data/bcn/*.json y data/eventos_reales*.json (los llama validate_data.py)."""
from datetime import date
import json
from pathlib import Path
import re

DATA = Path(__file__).resolve().parents[1] / "data"
CATEGORIAS = {"politica", "electoral", "legislativo", "economia", "desastre_natural", "conflicto_social", "seguridad", "internacional", "institucional", "salud", "otro"}


def _cargar(ruta: Path):
    return json.loads(ruta.read_text(encoding="utf-8"))


def _fecha(s, ctx):
    if not isinstance(s, str) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", s):
        raise ValueError(f"{ctx}: fecha ISO inválida '{s}'")
    date.fromisoformat(s)


def _ref(ref: str, ids: set, ctx: str):
    if not ref.startswith("fuentes.json#") or ref.split("#", 1)[1] not in ids:
        raise ValueError(f"{ctx}: fuente inexistente '{ref}'")


def _unicos(items, clave, ctx):
    vistos = set()
    for i in items:
        if i[clave] in vistos:
            raise ValueError(f"{ctx}: {clave} duplicado '{i[clave]}'")
        vistos.add(i[clave])


def validar_bcn(ids_fuentes: set, regiones: set) -> None:
    d = DATA / "bcn"
    if (d / "normas.json").exists():
        normas = _cargar(d / "normas.json")["normas"]
        _unicos(normas, "id", "normas")
        for n in normas:
            ctx = f"norma {n['id']}"
            _ref(n["fuente"], ids_fuentes, ctx)
            if not isinstance(n.get("verificado"), bool):
                raise ValueError(f"{ctx}: 'verificado' debe ser booleano")
            if n.get("fecha_publicacion"):
                _fecha(n["fecha_publicacion"], ctx)
            for a in n.get("articulos_clave", []):
                if not a.get("verificado_contra_texto"):
                    raise ValueError(f"{ctx}: art. {a['articulo']} sin verificar contra el texto")
    if (d / "proyectos_ley.json").exists():
        ps = _cargar(d / "proyectos_ley.json")["proyectos"]
        _unicos(ps, "boletin", "proyectos")
        for p in ps:
            ctx = f"proyecto {p['boletin']}"
            if not re.fullmatch(r"\d+-\d{2}", p["boletin"]):
                raise ValueError(f"{ctx}: boletín mal formado")
            _fecha(p["fecha_ingreso"], ctx)
            if p["iniciativa"] not in ("mensaje", "mocion") or not p["titulo"]:
                raise ValueError(f"{ctx}: iniciativa/título inválidos")
            for r in p["fuentes"]:
                _ref(r, ids_fuentes, ctx)
    for nombre, clave in (("reformas_constitucionales.json", "reformas_en_texto_vigente"), ("reformas_propuestas.json", "propuestas"),
                          ("reformas_propuestas.json", "reformas_en_tramite")):
        if (d / nombre).exists():
            for r in _cargar(d / nombre)[clave]:
                _ref(r["fuente"], ids_fuentes, f"{nombre}:{r.get('ley') or r.get('id') or r.get('boletin')}")
                if not isinstance(r.get("verificado"), bool):
                    raise ValueError(f"{nombre}: 'verificado' debe ser booleano")
    rp = d / "resultados_2da_vuelta_2025.json"
    if rp.exists():  # cada fila cuadra y el total regional + extranjero se acerca al oficial
        r = _cargar(rp)
        for x in r["regiones"] + [r["extranjero"]]:
            if x["validos"] + x["nulos"] + x["blancos"] != x["total_votacion"] or x["jara"] + x["kast"] != x["validos"]:
                raise ValueError(f"resultados 2da vuelta: fila inconsistente {x.get('region_id', 'extranjero')}")
        if r["regiones"] and {x["region_id"] for x in r["regiones"]} != regiones:
            raise ValueError("resultados 2da vuelta: regiones no coinciden con data/regiones.json")
    ids = set()
    for f in sorted(DATA.glob("eventos_reales*.json")):
        for e in _cargar(f)["eventos"]:
            ctx = f"evento_real {e['id']}"
            if e["id"] in ids:
                raise ValueError(f"{ctx}: id duplicado")
            ids.add(e["id"])
            _fecha(e["fecha"], ctx)
            if e["categoria"] not in CATEGORIAS or not e["descripcion"]:
                raise ValueError(f"{ctx}: categoría/descripción inválida")
            if not isinstance(e["verificado"], bool) or not e["fuentes"]:
                raise ValueError(f"{ctx}: requiere 'verificado' booleano y al menos una fuente")
            for rid in e["regiones"]:
                if rid not in regiones and rid != "nacional":
                    raise ValueError(f"{ctx}: región desconocida '{rid}'")
            for s in e["fuentes"]:
                if not s.get("url", "").startswith("http"):
                    raise ValueError(f"{ctx}: fuente sin URL")
