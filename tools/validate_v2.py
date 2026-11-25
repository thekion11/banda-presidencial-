#!/usr/bin/env python3
"""Validadores de las mecánicas v2 (metas, asesores, coalición, disponibilidad de cartas). Los invoca validate_data.py."""
import re

from validate_data import cargar_json, unicos, validar_efectos, validar_schema, verificar_ref_fuente


def validar_metas(metas: list, cartas: list, ids_fuentes: set) -> None:
    unicos(metas, "metas")
    ids_cartas = {c["id"] for c in cartas}
    cats = {c["categoria"] for c in cartas}
    ids = {m["id"] for m in metas}
    for m in metas:
        ctx = f"meta {m['id']}"
        verificar_ref_fuente(m, ids_fuentes, ctx)
        validar_efectos(m["efectos"], ctx)
        if not m.get("cifras_ilustrativas"):
            raise ValueError(f"{ctx}: debe rotular cifras_ilustrativas")
        if m["sector"] not in cats:
            raise ValueError(f"{ctx}: sector '{m['sector']}' sin cartas")
        if m["requiere"] is not None and m["requiere"] not in ids:
            raise ValueError(f"{ctx}: requiere una meta inexistente")
        for cid in m["desbloquea"]:
            if cid not in ids_cartas:
                raise ValueError(f"{ctx}: desbloquea una carta inexistente '{cid}'")
    for cat in cats - {"oposicion"}:  # las cartas de oposición no tienen sector interno ni metas
        for i in (1, 2, 3):
            if f"meta_{cat}_{i}" not in ids:
                raise ValueError(f"falta la meta meta_{cat}_{i}")
    for c in cartas:
        d = c.get("disponibilidad") or {}
        if d.get("meta") and d["meta"] not in ids:
            raise ValueError(f"carta {c['id']}: disponibilidad.meta inexistente '{d['meta']}'")


def validar_asesores(asesores: list, cartas: list, ids_fuentes: set) -> None:
    unicos(asesores, "asesores")
    cats = {c["categoria"] for c in cartas}
    for a in asesores:
        ctx = f"asesor {a['id']}"
        verificar_ref_fuente(a, ids_fuentes, ctx)
        pos, neg = a["efecto_positivo"], a["efecto_negativo"]
        for ef, signo in ((pos, 1), (neg, -1)):
            if ef["tipo"] == "indicador":
                validar_efectos([ef], ctx)
                val = -ef["delta"] if ef["ind"] == "riesgo_ejecucion" else ef["delta"]  # menos riesgo = bueno
            elif ef["tipo"] == "categoria":
                if ef["categoria"] not in cats:
                    raise ValueError(f"{ctx}: categoría sin cartas '{ef['categoria']}'")
                val = ef["mult"]
            else:
                raise ValueError(f"{ctx}: tipo de efecto desconocido")
            if val * signo <= 0:
                raise ValueError(f"{ctx}: el efecto {'positivo' if signo > 0 else 'negativo'} tiene el signo contrario")


def validar_coalicion(partidos: list, cartas: list, leyes: dict, ids_fuentes: set) -> None:
    unicos(partidos, "coalicion")
    cats = {c["categoria"] for c in cartas}
    mx = leyes["coalicion"]["max_aliados"]
    if not 1 <= mx <= len(partidos):
        raise ValueError("coalicion: max_aliados fuera de rango")
    for p in partidos:
        ctx = f"partido aliado {p['id']}"
        verificar_ref_fuente(p, ids_fuentes, ctx)
        if p["peticion"]["categoria_carta"] not in cats:
            raise ValueError(f"{ctx}: categoria_carta sin cartas")
        if p["peticion"]["ministerios"] < 0 or p["peticion"]["asesores"] < 0:
            raise ValueError(f"{ctx}: petición negativa")
    ministros = {m["id"] for m in cargar_json("ministros.json")}
    for p in partidos:
        ctx = f"partido aliado {p['id']}"
        if p["escanos_senado"] > leyes["hemiciclo"]["total_senadores"] or p["escanos_camara"] > leyes["hemiciclo"]["total_diputados"]:
            raise ValueError(f"{ctx}: más escaños que la cámara")
        for c in p["categorias_pedidas"] + p["categorias_rechazadas"]:
            if c not in cats:
                raise ValueError(f"{ctx}: categoría sin cartas '{c}'")
        for mid in p["ministerios_pedidos"]:
            if mid not in ministros:
                raise ValueError(f"{ctx}: ministerio inexistente '{mid}'")
        if not p.get("cifras_ilustrativas") or not p.get("nota_escanos"):
            raise ValueError(f"{ctx}: escaños deben rotularse como ilustrativos")


def validar_disponibilidad_cartas(cartas: list, ids_eventos: set, categorias: set) -> None:
    """Campo opcional `disponibilidad` (docs/DISENO_V2.md): ventana de años 1-4, evento, fiscal_min (indicador 0-100) y meta interna."""
    n = 0
    for c in cartas:
        d = c.get("disponibilidad")
        if d is None:
            continue
        n += 1
        ctx = f"carta {c['id']}"
        if set(d) != {"anio_desde", "anio_hasta", "evento", "fiscal_min", "meta"}:
            raise ValueError(f"{ctx}: disponibilidad con claves incorrectas")
        if not (1 <= d["anio_desde"] <= d["anio_hasta"] <= 4):
            raise ValueError(f"{ctx}: años de disponibilidad fuera de 1-4 o desde > hasta")
        if d["evento"] is not None and d["evento"] not in ids_eventos:
            raise ValueError(f"{ctx}: evento inexistente '{d['evento']}'")
        if d["fiscal_min"] is not None and not 0 <= d["fiscal_min"] <= 100:
            raise ValueError(f"{ctx}: fiscal_min fuera de 0-100")
        if d["meta"] is not None:
            m = re.fullmatch(r"meta_([a-z]+)_([1-3])", d["meta"])
            if not m or m.group(1) not in categorias:
                raise ValueError(f"{ctx}: meta '{d['meta']}' inválida (meta_<categoria>_<1..3>)")
    print(f"[INFO] Cartas con disponibilidad: {n}")


def validar_v2(datos: dict, ids_fuentes: set) -> None:
    datos["metas"] = cargar_json("metas.json")
    validar_schema("metas.json", datos["metas"])
    validar_metas(datos["metas"], datos["cartas"], ids_fuentes)
    datos["asesores"] = cargar_json("asesores.json")
    validar_schema("asesores.json", datos["asesores"])
    validar_asesores(datos["asesores"], datos["cartas"], ids_fuentes)
    datos["coalicion"] = cargar_json("coalicion.json")
    validar_schema("coalicion.json", datos["coalicion"])
    validar_coalicion(datos["coalicion"], datos["cartas"], datos["leyes"], ids_fuentes)
