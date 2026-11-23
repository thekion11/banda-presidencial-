#!/usr/bin/env python3
"""Validador de esquemas e integridad referencial para data/.

Uso: python3 tools/validate_data.py   (código 0 = OK)
Si 'jsonschema' está instalado, además valida contra data/schemas/*.schema.json.
"""
from datetime import date, timedelta
import json
import math
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
INDICADORES = {"aprobacion", "capital", "cohesion", "fiscal", "riesgo_ejecucion", "viviendas_anio"}
MAX_CARTAS_CAMPANA_PA = 16


def fecha_referencia() -> date:
    env = os.environ.get("FECHA_REFERENCIA")
    return date.fromisoformat(env) if env else date.today()


def cargar_json(nombre: str):
    ruta = DATA_DIR / nombre
    if not ruta.exists():
        raise FileNotFoundError(f"Archivo faltante: {ruta}")
    with ruta.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def validar_schema(nombre: str, datos) -> None:
    try:
        import jsonschema
    except ImportError:
        return
    ruta = DATA_DIR / "schemas" / (nombre.replace(".json", "") + ".schema.json")
    if ruta.exists():
        with ruta.open("r", encoding="utf-8") as fh:
            jsonschema.validate(datos, json.load(fh))


def validar_fuentes(fuentes: list) -> set:
    ids = set()
    hoy = fecha_referencia()
    for item in fuentes:
        for campo in ("id", "institucion", "titulo", "url", "fecha_corte"):
            if campo not in item or not item[campo]:
                raise ValueError(f"Fuente inválida sin '{campo}': {item}")
        fid = item["id"]
        if fid in ids:
            raise ValueError(f"ID de fuente duplicado: {fid}")
        ids.add(fid)
        corte = date.fromisoformat(item["fecha_corte"])
        vigencia = int(item.get("vigencia_dias", 365))
        if hoy > corte + timedelta(days=vigencia):
            print(f"[AVISO] Fuente vencida: {fid} (corte {corte})")
        if item.get("verificado_contra_texto") is False:
            print(f"[AVISO] Fuente sin verificar contra el texto oficial: {fid}")
    return ids


def verificar_ref_fuente(obj: dict, ids_fuentes: set, contexto: str) -> None:
    ref = obj.get("fuente", "")
    if not ref.startswith("fuentes.json#"):
        raise ValueError(f"{contexto}: referencia mal formada '{ref}'")
    fid = ref.split("#", 1)[1]
    if fid not in ids_fuentes:
        raise ValueError(f"{contexto}: fuente inexistente '{fid}'")


def unicos(items: list, contexto: str) -> set:
    ids = [i["id"] for i in items]
    if len(ids) != len(set(ids)):
        raise ValueError(f"{contexto}: ids duplicados")
    return set(ids)


def validar_efectos(efectos: list, contexto: str) -> None:
    for ef in efectos:
        if ef["ind"] not in INDICADORES:
            raise ValueError(f"{contexto}: indicador desconocido '{ef['ind']}'")
        if not isinstance(ef["delta"], (int, float)) or math.isnan(ef["delta"]):
            raise ValueError(f"{contexto}: delta inválido")


def validar_leyes(leyes: dict, ids_fuentes: set) -> set:
    h = leyes["hemiciclo"]
    if h["dias_por_turno"] * 208 != h["duracion_mandato_dias"] + 0 and \
            abs(h["dias_por_turno"] * 208 - h["duracion_mandato_dias"]) > h["dias_por_turno"]:
        raise ValueError("hemiciclo: 208 turnos no cubren la duración del mandato")
    if h["total_senadores"] != 50:
        raise ValueError("hemiciclo: el Senado debe tener 50 senadores")
    tipos = unicos(leyes["tipos_ley"], "tipos_ley")
    for t in leyes["tipos_ley"]:
        verificar_ref_fuente(t, ids_fuentes, f"tipo_ley {t['id']}")
        if t["votos_minimos"] > h["total_senadores"]:
            raise ValueError(f"tipo_ley {t['id']}: votos_minimos excede el Senado")
        for p in ("prob_recurso_tc", "prob_exito_tc"):
            if not 0.0 <= t[p] <= 1.0:
                raise ValueError(f"tipo_ley {t['id']}: {p} fuera de [0,1]")
    return tipos


def validar_cartas(cartas: list, ids_fuentes: set, tipos: set, props: set) -> None:
    unicos(cartas, "cartas")
    for c in cartas:
        ctx = f"carta {c['id']}"
        verificar_ref_fuente(c, ids_fuentes, ctx)
        validar_efectos(c["efectos"], ctx)
        for k in ("ley", "quorum"):
            if c["requisitos"][k] is not None and c["requisitos"][k] not in tipos:
                raise ValueError(f"{ctx}: requisito {k} desconocido '{c['requisitos'][k]}'")
        if c["abre_propuesta_comite"] and c["abre_propuesta_comite"] not in props:
            raise ValueError(f"{ctx}: propuesta inexistente")
        corr = c["corrector"]
        if corr and corr["meta"] <= 0:
            raise ValueError(f"{ctx}: meta del corrector debe ser positiva")


def validar_eventos(eventos: list, ids_fuentes: set, tipos: set, dias_mandato: int) -> None:
    unicos(eventos, "eventos")
    for e in eventos:
        ctx = f"evento {e['id']}"
        verificar_ref_fuente(e, ids_fuentes, ctx)
        validar_efectos(e["efectos_base"], ctx)
        if e["tipo"] == "programado":
            d = e["dia_objetivo"]
            limite = dias_mandato if e.get("etapa", "gobierno") == "gobierno" else 56
            if d is None or not 1 <= d <= limite:
                raise ValueError(f"{ctx}: dia_objetivo fuera del período")
        if e["votacion"] and e["votacion"]["tipo_ley"] not in tipos:
            raise ValueError(f"{ctx}: tipo_ley desconocido")


def validar_ideologia(ide: dict) -> None:
    unicos(ide["preguntas"], "preguntas")
    for p in ide["preguntas"]:
        if len(p["opciones"]) != 3:
            raise ValueError(f"pregunta {p['id']}: debe tener 3 opciones")
        for o in p["opciones"]:
            for k in ("delta_eco", "delta_inst"):
                if not -1.0 <= o[k] <= 1.0:
                    raise ValueError(f"pregunta {p['id']}: {k} fuera de [-1,1]")
    arqs = sorted(ide["arquetipos"], key=lambda a: a["eco_min"])
    if arqs[0]["eco_min"] != -1.0 or arqs[-1]["eco_max"] != 1.0:
        raise ValueError("arquetipos: no cubren [-1, 1]")
    for a, b in zip(arqs, arqs[1:]):
        if a["eco_max"] != b["eco_min"]:
            raise ValueError("arquetipos: hueco o solape en eje económico")


def validar_ministros(ministros: list, cartas: list) -> None:
    unicos(ministros, "ministros")
    cats = {c["categoria"] for c in cartas}
    for m in ministros:
        if m["categoria_afin"] not in cats:
            print(f"[AVISO] Ministro {m['id']}: ninguna carta de categoría '{m['categoria_afin']}'")


def validar_regiones(regs: list, ids_fuentes: set) -> None:
    unicos(regs, "regiones")
    total = sum(r["pob_pct"] for r in regs)
    if abs(total - 100.0) > 0.2:
        raise ValueError(f"regiones: pob_pct suma {total}")
    for r in regs:
        verificar_ref_fuente(r, ids_fuentes, f"region {r['id']}")


def validar_propuestas(props: list, ids_fuentes: set, regiones: set) -> None:
    unicos(props, "propuestas")
    for p in props:
        verificar_ref_fuente(p, ids_fuentes, f"propuesta {p['id']}")
        if p["region"] not in regiones:
            raise ValueError(f"propuesta {p['id']}: región inexistente")
        unicos(p["variantes"], f"variantes de {p['id']}")
        for v in p["variantes"]:
            validar_efectos(v["efectos"], f"variante {p['id']}/{v['id']}")


def main() -> int:
    nombres = ("fuentes", "leyes", "ministros", "cartas", "eventos", "ideologia", "regiones", "propuestas")
    datos = {n: cargar_json(f"{n}.json") for n in nombres}
    for n, d in datos.items():
        validar_schema(f"{n}.json", d)
    ids_fuentes = validar_fuentes(datos["fuentes"])
    tipos = validar_leyes(datos["leyes"], ids_fuentes)
    props = unicos(datos["propuestas"], "propuestas")
    validar_cartas(datos["cartas"], ids_fuentes, tipos, props)
    validar_eventos(datos["eventos"], ids_fuentes, tipos, datos["leyes"]["hemiciclo"]["duracion_mandato_dias"])
    validar_ideologia(datos["ideologia"])
    validar_ministros(datos["ministros"], datos["cartas"])
    validar_regiones(datos["regiones"], ids_fuentes)
    validar_propuestas(datos["propuestas"], ids_fuentes, {r["id"] for r in datos["regiones"]})
    print("OK: Todos los JSON de Fase 0 superaron la validación")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, FileNotFoundError, KeyError) as exc:
        print(f"ERROR: {exc}")
        sys.exit(1)
