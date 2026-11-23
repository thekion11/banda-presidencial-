#!/usr/bin/env python3
"""Genera data/cartas_reales.json a partir de las bases reales (proyectos públicos, proyectos de ley, reformas constitucionales).
Los HECHOS (nombre, región, estado, inversión, boletín, quórum constitucional) son reales y citan su fuente; las MAGNITUDES de los
efectos de juego (aprobación, fiscal, plazos) son ilustrativas y se rotulan con cifras_ilustrativas=true (CLAUDE.md §2).
Reproducible: mismo insumo -> mismo archivo."""
import glob
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

from cartas_efectos import efectos_y_costo
from cartas_util import CATEGORIAS, anonimizar, categoria_proyecto_ley, disp_ley, disp_obra, h, recortar, resumir_titulo, unico

ROOT = Path(__file__).resolve().parents[1]
D = ROOT / "data"
SECTOR_CAT = {"vial": "obras", "aeropuertos": "transportes", "edificacion": "obras", "ferrocarriles": "transportes", "metro": "transportes",
              "transporte": "transportes", "puertos": "economia", "salud": "salud", "agua": "medioambiente", "seguridad": "seguridad",
              "vivienda_urbana": "vivienda", "energia": "energia", "educacion": "educacion", "plan_nacional": "obras", "otros": "obras"}
PRE_EJECUCION = {"idea", "perfil", "prefactibilidad", "diseno", "licitacion"}


def cargar_proyectos() -> list:
    res = []
    for f in sorted(glob.glob(str(D / "proyectos" / "*.json"))):
        res += json.load(open(f, encoding="utf-8"))["proyectos"]
    return sorted(res, key=lambda p: p["id"])


def musd(p: dict):
    if p.get("inversion_musd") is not None:
        return float(p["inversion_musd"])
    if p.get("inversion_uf") is not None:
        return float(p["inversion_uf"]) * 41.0 / 1e6  # UF aproximada (leyes.json › sectra.uf_en_usd)
    return None


ABREV = [(r"^Concesi[óo]n ", ""), (r"Primera Concesi[óo]n", "1.ª Concesión"), (r"Segunda Concesi[óo]n", "2.ª Concesión"), (r"Arturo Merino Benítez", "AMB"),
         (r"^Plan de Inversiones Oncol[óo]gicas 2026-2030: centro o unidad oncol[óo]gica ", "Centro oncológico "),
         (r"^Plan de Inversiones Oncol[óo]gicas 2026-2030: habilitaci[óo]n/equipamiento ", "Equipamiento oncológico "),
         (r"Terminal Intermodal ", ""), (r"Obras Mar[íi]timas Infraestructura Portuaria ", "Obras marítimas, puerto "),
         (r"Ampliaci[óo]n y Mejoramiento ", "Mejoramiento "), (r"Trenes de refuerzo servicio ", "Trenes de refuerzo "), (r"Interconexi[óo]n Vial Santiago.*", "Interconexión Santiago-Valparaíso")]


def corto(nombre: str, n: int) -> str:
    for rx, rep in ABREV:
        nombre = re.sub(rx, rep, nombre)
    return recortar(nombre, n, 12)


def carta_obra(p: dict) -> dict:
    """Una carta por proyecto, según su estado real al arrancar el juego: idea/perfil/diseño/licitación = obra completa;
    en ejecución = acelerar (tramo final); terminado = inauguración (efecto inmediato, sin obra)."""
    inv = musd(p)
    grande = inv is not None and inv >= 500
    est = p["estado"]
    fiscal = -1.0 if inv is None else -round(min(2.0, max(0.5, inv / 600.0)), 1)
    hecho = bool(p.get("verificado")) and FUENTES.get(p["fuente"].split("#")[-1], {}).get("verificado_contra_texto") is not False
    meta = {"tipo": "proyecto_publico", "proyecto_id": p["id"], "region_id": p.get("region_id"), "estado_real": est,
            "inversion_musd": None if inv is None else round(inv, 1), "mandante": p.get("mandante"),
            "verificado_hecho": hecho, "verificado": hecho, "fuente_url": p.get("fuente_url"), "cifras_ilustrativas": True}
    base = {"id": "real_obra_" + p["id"].replace("-", "_").replace(".", "_"), "categoria": SECTOR_CAT.get(p["sector"], "obras"),
            "requisitos": {"ley": None, "quorum": None}, "corrector": None, "abre_propuesta_comite": None, "fuente": p["fuente"], "meta": meta, "disponibilidad": None}
    if est == "terminado":
        meta["modo"] = "inauguracion"
        base["disponibilidad"] = disp_obra(p, inv, "inauguracion")
        return dict(base, costo_pa=1, titulo="Inaugurar: " + corto(p["nombre"], 49), efectos=[{"ind": "aprobacion", "delta": 1.5}, {"ind": "capital", "delta": 0.5}])
    if est == "ejecucion":
        meta["modo"] = "acelerar"
        base["disponibilidad"] = disp_obra(p, inv, "acelerar")
        return dict(base, costo_pa=2, titulo="Acelerar: " + corto(p["nombre"], 50), efectos=[{"ind": "aprobacion", "delta": 2.5}, {"ind": "fiscal", "delta": fiscal}],
                    obra={"nombre": recortar(p["nombre"], 80), "dias_totales": 90})
    meta["modo"] = "obra"
    base["disponibilidad"] = disp_obra(p, inv, "obra")
    dias = 100 if inv is None else int(min(240, 90 + inv * 0.2))
    efectos = [{"ind": "aprobacion", "delta": 4 if grande else 3}, {"ind": "fiscal", "delta": fiscal}]
    if grande:
        efectos.append({"ind": "riesgo_ejecucion", "delta": 1})
    return dict(base, costo_pa=3 if grande else 2, titulo=corto(p["nombre"], 60), efectos=efectos, obra={"nombre": recortar(p["nombre"], 80), "dias_totales": dias})


def seleccionar_obras(proys: list) -> list:
    return [carta_obra(p) for p in proys]  # TODAS: el mazo limita cuántas circulan a la vez (leyes.json › mano.reales_en_mazo)


TIPO_LOC = "ley_organica_constitucional"
_TC = D / "bcn" / "titulos_cortos.json"  # resúmenes editoriales (≤ 55 car.) de los títulos legales; insumo curado
TITULOS = json.load(open(_TC, encoding="utf-8"))["titulos"] if _TC.exists() else {}
FUENTES = {f["id"]: f for f in json.load(open(D / "fuentes.json", encoding="utf-8"))}


def carta_ley(b: dict, tipo: str, cat: str, fecha_corte: str, q: float, art=None) -> dict:
    reforma = tipo == "reforma_constitucional"
    efectos, costo = efectos_y_costo(b, tipo, cat)
    if reforma:
        nota = "4/7 de los miembros en ejercicio de cada Cámara (CPR art. 127, verificado contra el texto oficial)."
    else:
        nota = ("Quórum ilustrativo (mayoría absoluta de los miembros en ejercicio, CPR art. 66, sin verificar el contenido del boletín)." if tipo == TIPO_LOC
                else "Quórum ilustrativo (mayoría simple): el quórum real depende del contenido del proyecto y no se verificó contra el texto oficial.")
    return {"id": "real_ley_" + b["boletin"].replace("-", "_"), "categoria": cat, "costo_pa": costo,
            "titulo": TITULOS.get(b["boletin"]) or resumir_titulo(b["titulo"]), "efectos": efectos,
            "requisitos": {"ley": tipo, "quorum": tipo}, "corrector": None, "abre_propuesta_comite": None,
            "camara_origen": "senado" if "Senado" in b.get("camara_origen", "") else "camara",
            "fuente": "fuentes.json#senado_tramitacion", "disponibilidad": disp_ley(b, tipo, q),
            "meta": {"tipo": "reforma_constitucional" if reforma else "proyecto_de_ley", "boletin": b["boletin"],
                     "titulo_completo": anonimizar(b["titulo"]), "iniciativa": b.get("iniciativa"), "fecha_ingreso": b.get("fecha_ingreso"),
                     "estado_real": b["estado"], "etapa": b.get("etapa"), "urgencia": b.get("urgencia_actual"), "url": b.get("url_senado"),
                     "articulo_afectado": art, "fecha_corte": fecha_corte, "verificado_hecho": bool(b.get("verificado")), "verificado": bool(b.get("verificado")),
                     "quorum_verificado": reforma, "nota_quorum": nota, "cifras_ilustrativas": True}}


def cartas_leyes(bills: list, rp: dict) -> list:
    """UNA carta por cada proyecto en tramitación. Reforma constitucional (4/7) solo si el boletín está en reformas_propuestas
    (modifica la Constitución, art. 127); 'orgánica constitucional' en el título -> LOC; el resto, ley simple ilustrativa."""
    refs = {b["boletin"]: b.get("articulo_afectado") for b in rp["reformas_en_tramite"] if b.get("verificado")}
    corte = json.load(open(D / "bcn" / "proyectos_ley.json", encoding="utf-8"))["fecha_corte"]
    res = []
    tram = [b for b in bills if b["estado"] == "En tramitación"]
    rango = {b["boletin"]: i / len(tram) for i, b in enumerate(sorted(tram, key=lambda b: (b["fecha_ingreso"], b["boletin"]), reverse=True))}
    for b in sorted(tram, key=lambda b: b["boletin"]):
        reforma = b["boletin"] in refs
        loc = not reforma and re.search(r"org[áa]nic[ao]s? constitucional", b["titulo"], re.I) is not None
        tipo = "reforma_constitucional" if reforma else TIPO_LOC if loc else "ley_simple"
        res.append(carta_ley(b, tipo, categoria_proyecto_ley(b, reforma), corte, rango[b["boletin"]], refs.get(b["boletin"])))
    return res


def cartas_plebiscitos(rp: dict) -> list:
    res = []
    for pr in rp["propuestas"]:  # plebiscitos 2022 y 2023: reforma constitucional (4/7, CPR art. 127)
        res.append({"id": "real_plebiscito_" + pr["id"], "categoria": "politica", "costo_pa": 3, "titulo": recortar("Nueva Constitución: propuesta " + pr["id"].replace("_", " ")),
                    "efectos": [{"ind": "capital", "delta": -3}, {"ind": "cohesion", "delta": -1}, {"ind": "aprobacion", "delta": 2}],
                    "requisitos": {"ley": "reforma_constitucional", "quorum": "reforma_constitucional"}, "corrector": None, "abre_propuesta_comite": None,
                    "fuente": pr["fuente"] if pr["fuente"].startswith("fuentes.json#") else "fuentes.json#cpr_chile_2026",
                    "disponibilidad": {"anio_desde": 2, "anio_hasta": 4, "evento": None, "fiscal_min": None, "meta": None},
                    "meta": {"tipo": "propuesta_constitucional", "resultado": pr["resultado"], "url": pr.get("url"),
                             "quorum_verificado": True, "verificado_hecho": False, "cifras_ilustrativas": True}})
    return res


def asignar_eventos_y_metas(cartas: list) -> None:
    """Vincula ~2 cartas por evento real de gobierno (misma categoría) y ~6 % de cartas a una meta interna meta_<cat>_<1..3>.
    Las ligadas a un evento se desbloquean tras él: anio_desde = año de gobierno en que cae su día."""
    eventos = json.load(open(D / "juego_eventos_reales.json", encoding="utf-8")) + json.load(open(D / "eventos.json", encoding="utf-8"))
    from cartas_util import categoria_titulo
    libres = defaultdict(list)
    for c in cartas:
        if c["meta"]["tipo"] in ("proyecto_de_ley", "proyecto_publico") and c["disponibilidad"]["anio_desde"] <= 2 \
                and c["disponibilidad"]["fiscal_min"] is None and c["meta"].get("urgencia", "Sin urgencia") == "Sin urgencia":
            libres[c["categoria"]].append(c)
    for v in libres.values():
        v.sort(key=lambda c: h("ev" + c["id"]))
    for e in sorted((e for e in eventos if e.get("etapa", "gobierno") == "gobierno" and e.get("dia_objetivo")), key=lambda e: e["id"]):
        cat, anio = categoria_titulo(e["titulo"] + " " + e.get("descripcion", "")), min(4, (e["dia_objetivo"] - 1) // 365 + 1)
        for c in [libres[cat].pop(0) for _ in range(min(2, len(libres[cat])))]:
            c["disponibilidad"].update(evento=e["id"], anio_desde=anio, anio_hasta=min(4, max(anio + 1, c["disponibilidad"]["anio_hasta"])))
    for c in cartas:
        d = c["disponibilidad"]
        if d["evento"] is None and h("meta" + c["id"]) % 100 < 6 and c["categoria"] in CATEGORIAS:
            d["meta"] = f"meta_{c['categoria']}_{1 + h('m2' + c['id']) % 3}"


def main() -> None:
    bills = json.load(open(D / "bcn" / "proyectos_ley.json", encoding="utf-8"))["proyectos"]
    rp = json.load(open(D / "bcn" / "reformas_propuestas.json", encoding="utf-8"))
    cartas = seleccionar_obras(cargar_proyectos()) + cartas_leyes(bills, rp) + cartas_plebiscitos(rp)
    asignar_eventos_y_metas(cartas)
    usados = set()
    for c in cartas:
        suf = c["meta"].get("boletin", "").split("-")[0] or (c["meta"].get("region_id") or c["id"][-6:])
        c["titulo"] = unico(c["titulo"], usados, suf)
    ids = [c["id"] for c in cartas]
    assert len(ids) == len(set(ids)), "ids duplicados"
    assert all(len(c["titulo"]) <= 60 for c in cartas), "título > 60"
    json.dump(cartas, open(D / "cartas_reales.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    por = Counter(c["meta"]["tipo"] for c in cartas)
    print(f"{len(cartas)} cartas reales: {dict(por)}")
    print("por categoría:", dict(sorted(Counter(c["categoria"] for c in cartas).items())))
    print("por año (desde):", dict(sorted(Counter(c["disponibilidad"]["anio_desde"] for c in cartas).items())),
          "disponibles por año:", {a: sum(1 for c in cartas if c["disponibilidad"]["anio_desde"] <= a <= c["disponibilidad"]["anio_hasta"]) for a in (1, 2, 3, 4)})
    print("con evento:", sum(1 for c in cartas if c["disponibilidad"]["evento"]), "fiscal_min:", sum(1 for c in cartas if c["disponibilidad"]["fiscal_min"]),
          "meta:", sum(1 for c in cartas if c["disponibilidad"]["meta"]), "costo:", dict(sorted(Counter(c["costo_pa"] for c in cartas).items())))


if __name__ == "__main__":
    main()
