#!/usr/bin/env python3
"""Referencias cruzadas y rangos de los datos del juego (se suma a tools/validate_data.py): ids huérfanos, probabilidades, pesos y ministerios.

Cada comprobación lanza ValueError con un mensaje que dice qué dato y qué referencia falla. `validar_referencias(datos)` recibe el diccionario que arma
`cargar_datos()` (cartas, eventos, ministros, metas, coalicion, propuestas, regiones, fuentes, leyes) y se prueba con datos rotos en tools/test_validate.py.
"""
import json
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "data"


def cargar_datos() -> dict:
    def j(n):
        return json.loads((DATA / n).read_text(encoding="utf-8"))
    return {"cartas": j("cartas.json") + j("cartas_reales.json") + j("cartas_curadas.json"), "eventos": j("eventos.json") + j("juego_eventos_reales.json"),
            "ministros": j("ministros.json"), "metas": j("metas.json"), "coalicion": j("coalicion.json"), "propuestas": j("propuestas.json"),
            "regiones": j("regiones.json"), "fuentes": j("fuentes.json"), "leyes": j("leyes.json"), "asesores": j("asesores.json")}


def _ids(lista: list, ctx: str) -> set:
    ids = [x["id"] for x in lista]
    if len(set(ids)) != len(ids):
        raise ValueError(f"{ctx}: hay ids repetidos")
    return set(ids)


def _opciones(e: dict):
    return e.get("opciones", []) or []


def validar_referencias(d: dict) -> None:
    fuentes = {f["id"] for f in d["fuentes"]}
    eventos = _ids(d["eventos"], "eventos")
    cartas = _ids(d["cartas"], "cartas")
    metas = _ids(d["metas"], "metas")
    props = _ids(d["propuestas"], "propuestas")
    regiones = _ids(d["regiones"], "regiones")
    ministros = _ids(d["ministros"], "ministros")
    slots = {m.get("ministerio", m["id"]) for m in d["ministros"]}
    g = d["leyes"]["gabinete"]
    categorias_leyes = set(g["categorias_alias"].keys()) | set(g["categorias_alias"].values()) | set(g["categorias_siempre"]) | {"oposicion"}
    asesores = _ids(d["asesores"], "asesores")
    # fuentes citadas por cartas, eventos y metas
    for tipo, lista in (("carta", d["cartas"]), ("evento", d["eventos"]), ("meta", d["metas"])):
        for x in lista:
            f = x.get("fuente")
            if f and f.split("#")[-1] not in fuentes:
                raise ValueError(f"{tipo} {x['id']}: la fuente '{f}' no existe en fuentes.json")
    # cartas
    for c in d["cartas"]:
        ab = c.get("abre_propuesta_comite")
        if ab and ab not in props:
            raise ValueError(f"carta {c['id']}: abre_propuesta_comite '{ab}' no existe en propuestas.json")
        disp = c.get("disponibilidad") or {}
        if disp.get("evento") and disp["evento"] not in eventos:
            raise ValueError(f"carta {c['id']}: disponibilidad.evento '{disp['evento']}' no existe")
        if disp.get("meta") and disp["meta"] not in metas:
            raise ValueError(f"carta {c['id']}: disponibilidad.meta '{disp['meta']}' no existe")
        r = (c.get("meta") or {}).get("region_id")
        if r and r not in regiones:
            raise ValueError(f"carta {c['id']}: región '{r}' no existe")
        ri = c.get("riesgo")
        if ri is not None and not 0.0 < float(ri["prob"]) < 1.0:
            raise ValueError(f"carta {c['id']}: riesgo.prob fuera de (0,1)")
        if c["categoria"] not in categorias_leyes and c["categoria"] not in {m["categoria_afin"] for m in d["ministros"]}:
            raise ValueError(f"carta {c['id']}: categoría '{c['categoria']}' sin área de ministerio ni alias")
    # eventos
    for e in d["eventos"]:
        if float(e.get("peso_sorteo", 0.0)) < 0.0:
            raise ValueError(f"evento {e['id']}: peso_sorteo negativo")
        rq = e.get("requiere") or {}
        if rq.get("decision") and rq["decision"]["evento"] not in eventos:
            raise ValueError(f"evento {e['id']}: requiere una decisión de un evento inexistente '{rq['decision']['evento']}'")
        for i, op in enumerate(_opciones(e)):
            ca = op.get("cadena")
            if ca and ca["evento"] not in eventos:
                raise ValueError(f"evento {e['id']} opción {i}: cadena a un evento inexistente '{ca['evento']}'")
            for blq in (op.get("riesgo"), op.get("congreso")):
                if blq is None:
                    continue
                if "prob" in blq and not 0.0 < float(blq["prob"]) < 1.0:
                    raise ValueError(f"evento {e['id']} opción {i}: probabilidad fuera de (0,1)")
            if "diferido" in op and int(op["diferido"]["semanas"]) <= 0:
                raise ValueError(f"evento {e['id']} opción {i}: diferido.semanas debe ser positivo")
        if e.get("escena"):
            esc = e["escena"]
            if not 1 <= int(esc["ronda"]) <= int(esc["rondas"]):
                raise ValueError(f"evento {e['id']}: escena con ronda fuera de rango")
    # metas, ministros, coalición
    for m in d["metas"]:
        for k in [m.get("requiere")] + list(m.get("desbloquea", [])):
            if k and k not in metas:
                raise ValueError(f"meta {m['id']}: referencia a la meta inexistente '{k}'")
    por_slot: dict = {}
    for m in d["ministros"]:
        por_slot.setdefault(m.get("ministerio", m["id"]), []).append(m["id"])
        if not 0.0 <= float(m["riesgo_escandalo"]) <= 1.0:
            raise ValueError(f"ministro {m['id']}: riesgo_escandalo fuera de [0,1]")
        if m["categoria_afin"] not in categorias_leyes and m["categoria_afin"] not in {c["categoria"] for c in d["cartas"]}:
            raise ValueError(f"ministro {m['id']}: categoria_afin '{m['categoria_afin']}' desconocida")
    for s, lista in por_slot.items():
        if len(lista) != 3:
            raise ValueError(f"ministerio {s}: debe tener 3 candidatos y tiene {len(lista)}")
    for p in d["coalicion"]:
        for s in p.get("ministerios_pedidos", []):
            if s not in slots:
                raise ValueError(f"partido {p['id']}: pide el ministerio inexistente '{s}'")
        if p["escanos_senado"] < 0 or p["escanos_camara"] < 0:
            raise ValueError(f"partido {p['id']}: escaños negativos")
    if sum(p["escanos_senado"] for p in d["coalicion"]) > 2 * int(d["leyes"]["hemiciclo"]["total_senadores"]):
        raise ValueError("coalición: los escaños de los 15 partidos ficticios superan el doble del Senado (revisa las cifras)")
    if len(ministros) != len(d["ministros"]):
        raise ValueError("ministros: ids repetidos")
    validar_balas(d, eventos)
    validar_numeros(d)
    print(f"[INFO] Referencias cruzadas: {len(cartas)} cartas, {len(eventos)} eventos, {len(metas)} metas, {len(ministros)} ministros, {len(asesores)} asesores")


def validar_balas(d: dict, eventos: set) -> None:
    """leyes.json › balas_plata (PR-17): ids únicos, condiciones y acciones conocidas, eventos y tipos de ley existentes, probabilidades y costos válidos."""
    b = d["leyes"]["balas_plata"]
    if not (1 <= b["usos_iniciales"] <= b["usos_max"] <= len(b["catalogo"])):
        raise ValueError("balas_plata: usos_iniciales/usos_max inválidos para el catálogo")
    if not 0 < b["ratio_reducida_min"] <= 1:
        raise ValueError("balas_plata: ratio_reducida_min debe estar entre 0 y 1")
    tipos_ley = {t["id"] for t in d["leyes"]["tipos_ley"]}
    ids = set()
    for x in b["catalogo"]:
        ctx = f"balas_plata[{x['id']}]"
        if x["id"] in ids:
            raise ValueError(f"{ctx}: id repetido")
        ids.add(x["id"])
        if x["accion"] not in ("nada", "adelantar_votacion", "saltar_congreso", "anular_pendiente_negativo"):
            raise ValueError(f"{ctx}: acción desconocida '{x['accion']}'")
        if x["costo_capital"] <= 0:
            raise ValueError(f"{ctx}: costo_capital debe ser positivo")
        for t in x.get("tipos_vedados", []):
            if t not in tipos_ley:
                raise ValueError(f"{ctx}: tipo de ley vedado desconocido '{t}'")
        r = x["riesgo"]
        if not (0 < r["min"] <= r["max"] < 1) or not 0 < r["prob_base"] < 1:
            raise ValueError(f"{ctx}: probabilidades de riesgo fuera de (0, 1)")
        for ef in x["efectos"] + r["efectos"]:
            if ef["ind"] not in ("aprobacion", "capital", "cohesion", "fiscal", "riesgo_ejecucion", "viviendas_anio"):
                raise ValueError(f"{ctx}: indicador desconocido '{ef['ind']}'")

        def revisar(cond: dict) -> None:
            if cond["tipo"] not in ("proyecto_en_tramite", "anio_min", "indicador_min", "indicador_max", "evento_reciente", "oposicion_mayoritaria", "ministros_firman", "alguna"):
                raise ValueError(f"{ctx}: condición desconocida '{cond['tipo']}'")
            for e in cond.get("ids", []):
                if e not in eventos:
                    raise ValueError(f"{ctx}: evento inexistente '{e}'")
            for c2 in cond.get("condiciones", []):
                revisar(c2)
        for cond in x["requiere"]:
            revisar(cond)
            if not cond.get("falla") or not cond.get("alternativa"):
                raise ValueError(f"{ctx}: toda condición debe explicar la falla y ofrecer una alternativa (nunca un «no» seco)")


def validar_numeros(d: dict) -> None:
    """Coherencia numérica general (lo que las comprobaciones puntuales no cubren): NaN o infinitos, costos y plazos negativos, probabilidades fuera de [0,1],
    ventanas con inicio > fin, población no positiva, efectos con delta absurdo y eventos programados fuera del mandato."""
    prob = ("prob", "prob_recurso_tc", "prob_exito_tc", "prob_fallo_min", "prob_fallo_max", "riesgo_escandalo")
    no_neg = ("costo_pa", "costo_mov", "semanas", "dias_totales", "dia_objetivo", "peso_sorteo")
    ventanas = (("anio_desde", "anio_hasta"), ("desde", "hasta"))

    def recorrer(o, ctx: str):
        if isinstance(o, dict):
            for k, v in o.items():
                if isinstance(v, float) and (v != v or v in (float("inf"), float("-inf"))):
                    raise ValueError(f"{ctx}/{k}: valor no finito")
                if isinstance(v, (int, float)) and not isinstance(v, bool):
                    if k in prob and not 0 <= v <= 1:
                        raise ValueError(f"{ctx}/{k}: probabilidad fuera de [0,1] ({v})")
                    if k in no_neg and v < 0:
                        raise ValueError(f"{ctx}/{k}: valor negativo ({v})")
                recorrer(v, f"{ctx}/{k}")
            for a, b in ventanas:
                if isinstance(o.get(a), (int, float)) and isinstance(o.get(b), (int, float)) and o[a] > o[b]:
                    raise ValueError(f"{ctx}: ventana con inicio mayor que fin ({a}={o[a]} > {b}={o[b]})")
            if "ind" in o and "delta" in o and isinstance(o["delta"], (int, float)) and o["ind"] != "viviendas_anio" and abs(o["delta"]) > 100:
                raise ValueError(f"{ctx}: efecto con delta absurdo ({o['ind']} {o['delta']})")
        elif isinstance(o, list):
            for i, v in enumerate(o):
                recorrer(v, f"{ctx}[{i}]")

    for nombre in ("cartas", "eventos", "ministros", "metas", "coalicion", "propuestas", "asesores"):
        for x in d[nombre]:
            recorrer(x, f"{nombre} {x.get('id', '?')}")
    for r in d["regiones"]:
        if r["poblacion_miles"] <= 0:
            raise ValueError(f"región {r['id']}: población no positiva")
    duracion = d["leyes"]["hemiciclo"]["duracion_mandato_dias"]
    for e in d["eventos"]:
        if e.get("dia_objetivo") is not None and e["dia_objetivo"] > duracion:
            raise ValueError(f"evento {e['id']}: dia_objetivo {e['dia_objetivo']} fuera del mandato ({duracion} días)")


if __name__ == "__main__":
    import sys
    try:
        validar_referencias(cargar_datos())
        print("OK: referencias cruzadas y rangos")
    except (ValueError, KeyError) as exc:
        print("ERROR:", exc)
        sys.exit(1)
