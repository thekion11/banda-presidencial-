#!/usr/bin/env python3
"""Genera data/cartas_reales.json a partir de las bases reales (proyectos públicos, proyectos de ley, reformas constitucionales).
Los HECHOS (nombre, región, estado, inversión, boletín, quórum constitucional) son reales y citan su fuente; las MAGNITUDES de los
efectos de juego (aprobación, fiscal, plazos) son ilustrativas y se rotulan con cifras_ilustrativas=true (CLAUDE.md §2).
Reproducible: mismo insumo -> mismo archivo."""
import glob
import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
D = ROOT / "data"
SECTOR_CAT = {"vial": "obras", "aeropuertos": "transportes", "edificacion": "obras", "ferrocarriles": "transportes", "metro": "transportes",
              "transporte": "transportes", "puertos": "economia", "salud": "salud", "agua": "medioambiente", "seguridad": "seguridad",
              "vivienda_urbana": "vivienda", "energia": "energia", "educacion": "educacion", "plan_nacional": "obras", "otros": "obras"}
TEMA_CAT = {"seguridad": "seguridad", "hacienda": "hacienda", "social": "social", "trabajo": "economia", "transporte": "transportes",
            "energia": "energia", "educacion": "educacion", "descentralizacion": "descentralizacion", "pensiones": "social",
            "salud": "salud", "ambiente": "medioambiente", "defensa": "seguridad", "vivienda": "vivienda", "otro": "politica"}
PRE_EJECUCION = {"idea", "perfil", "prefactibilidad", "diseno", "licitacion"}
MAX_EJECUCION = 5
MAX_PRE = 20
MAX_LEYES = 20
MAX_REFORMAS = 6


def recortar(texto: str, n: int = 60) -> str:
    texto = " ".join(texto.split())
    return texto if len(texto) <= n else texto[: n - 1].rstrip(" ,.;:") + "…"


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


def carta_obra(p: dict) -> dict:
    """Una carta por proyecto, según su estado real al arrancar el juego: idea/perfil/diseño/licitación = obra completa;
    en ejecución = acelerar (tramo final); terminado = inauguración (efecto inmediato, sin obra)."""
    inv = musd(p)
    grande = inv is not None and inv >= 500
    est = p["estado"]
    fiscal = -1.0 if inv is None else -round(min(2.0, max(0.5, inv / 600.0)), 1)
    meta = {"tipo": "proyecto_publico", "proyecto_id": p["id"], "region_id": p.get("region_id"), "estado_real": est,
            "inversion_musd": None if inv is None else round(inv, 1), "mandante": p.get("mandante"),
            "verificado": bool(p.get("verificado")), "fuente_url": p.get("fuente_url"), "cifras_ilustrativas": True}
    base = {"id": "real_obra_" + p["id"].replace("-", "_").replace(".", "_"), "categoria": SECTOR_CAT.get(p["sector"], "obras"),
            "requisitos": {"ley": None, "quorum": None}, "corrector": None, "abre_propuesta_comite": None, "fuente": p["fuente"], "meta": meta}
    if est == "terminado":
        meta["modo"] = "inauguracion"
        return dict(base, costo_pa=1, titulo=recortar("Inaugurar: " + p["nombre"]), efectos=[{"ind": "aprobacion", "delta": 1.5}, {"ind": "capital", "delta": 0.5}])
    if est == "ejecucion":
        meta["modo"] = "acelerar"
        return dict(base, costo_pa=2, titulo=recortar("Acelerar: " + p["nombre"]), efectos=[{"ind": "aprobacion", "delta": 2.5}, {"ind": "fiscal", "delta": fiscal}],
                    obra={"nombre": recortar(p["nombre"], 80), "dias_totales": 90})
    meta["modo"] = "obra"
    dias = 100 if inv is None else int(min(240, 90 + inv * 0.2))
    efectos = [{"ind": "aprobacion", "delta": 4 if grande else 3}, {"ind": "fiscal", "delta": fiscal}]
    if grande:
        efectos.append({"ind": "riesgo_ejecucion", "delta": 1})
    return dict(base, costo_pa=3 if grande else 2, titulo=recortar(p["nombre"]), efectos=efectos, obra={"nombre": recortar(p["nombre"], 80), "dias_totales": dias})


def seleccionar_obras(proys: list) -> list:
    return [carta_obra(p) for p in proys]  # TODAS: el mazo limita cuántas circulan a la vez (leyes.json › mano.reales_en_mazo)


def carta_ley(b: dict, tipo: str, cat: str, verificado_quorum: bool) -> dict:
    urg = b.get("urgencia_actual", "Sin urgencia") != "Sin urgencia"
    efectos = [{"ind": "aprobacion", "delta": 3 if urg else 2}, {"ind": "capital", "delta": -1}]
    if cat in ("hacienda", "social", "salud", "educacion", "vivienda"):
        efectos.append({"ind": "fiscal", "delta": -1.0})
    return {"id": "real_ley_" + b["boletin"].replace("-", "_"), "categoria": cat, "costo_pa": 3 if tipo != "ley_simple" else 2,
            "titulo": recortar(b["titulo"]), "efectos": efectos, "requisitos": {"ley": tipo, "quorum": tipo}, "corrector": None,
            "abre_propuesta_comite": None, "camara_origen": "senado" if "Senado" in b.get("camara_origen", "") else "camara",
            "fuente": "fuentes.json#senado_tramitacion",
            "meta": {"tipo": "proyecto_de_ley" if tipo == "ley_simple" else "reforma_constitucional", "boletin": b["boletin"],
                     "titulo_completo": b["titulo"], "iniciativa": b.get("iniciativa"), "fecha_ingreso": b.get("fecha_ingreso"),
                     "estado_real": b["estado"], "etapa": b.get("etapa"), "url": b.get("url_senado"),
                     "quorum_verificado": verificado_quorum,
                     "nota_quorum": None if verificado_quorum else "Quórum ilustrativo (mayoría simple): el quórum real depende del contenido del proyecto y no se verificó contra el texto oficial.",
                     "cifras_ilustrativas": True}}


def seleccionar_leyes(bills: list) -> list:
    cand = [b for b in bills if b["estado"] == "En tramitación" and b.get("verificado") and "constitucional" not in b.get("tema", [])
            and b.get("iniciativa") in ("mensaje", "moción")]
    cand.sort(key=lambda b: (b.get("urgencia_actual", "Sin urgencia") == "Sin urgencia", b["fecha_ingreso"], b["boletin"]))
    por_cat = defaultdict(list)
    for b in cand:
        tema = (b.get("tema") or ["otro"])[0]
        por_cat[TEMA_CAT.get(tema, "politica")].append(b)
    elegidas, i = [], 0
    while len(elegidas) < MAX_LEYES and any(por_cat.values()):
        for cat in sorted(por_cat):
            if por_cat[cat] and len(elegidas) < MAX_LEYES:
                elegidas.append((por_cat[cat].pop(0), cat))
        i += 1
    return [carta_ley(b, "ley_simple", cat, False) for b, cat in elegidas]


def seleccionar_reformas(bills: list, rp: dict) -> list:
    res = []
    for pr in rp["propuestas"]:  # plebiscitos 2022 y 2023: se modelan como cartas de reforma constitucional (4/7, CPR art. 127)
        res.append({"id": "real_plebiscito_" + pr["id"], "categoria": "politica", "costo_pa": 4, "titulo": recortar("Nueva Constitución: propuesta " + pr["id"].replace("_", " ")),
                    "efectos": [{"ind": "capital", "delta": -3}, {"ind": "cohesion", "delta": -1}, {"ind": "aprobacion", "delta": 2}],
                    "requisitos": {"ley": "reforma_constitucional", "quorum": "reforma_constitucional"}, "corrector": None, "abre_propuesta_comite": None,
                    "fuente": pr["fuente"] if pr["fuente"].startswith("fuentes.json#") else "fuentes.json#cpr_chile_2026",
                    "meta": {"tipo": "propuesta_constitucional", "resultado": pr["resultado"], "url": pr.get("url"),
                             "quorum_verificado": True, "cifras_ilustrativas": True}})
    vistas, cand = set(), [b for b in rp["reformas_en_tramite"] if b.get("verificado") and b["estado"] == "En tramitación"]
    cand.sort(key=lambda b: (b["fecha_ingreso"], b["boletin"]), reverse=True)
    for b in cand:
        art = b.get("articulo_afectado")
        if art in vistas or len(res) >= MAX_REFORMAS + 2:
            continue
        vistas.add(art)
        c = carta_ley(b, "reforma_constitucional", "politica", True)
        c["meta"]["nota_quorum"] = "4/7 de los miembros en ejercicio de cada Cámara (CPR art. 127, verificado contra el texto oficial)."
        res.append(c)
    return res


def main() -> None:
    bills = json.load(open(D / "bcn" / "proyectos_ley.json", encoding="utf-8"))["proyectos"]
    rp = json.load(open(D / "bcn" / "reformas_propuestas.json", encoding="utf-8"))
    cartas = seleccionar_obras(cargar_proyectos()) + seleccionar_leyes(bills) + seleccionar_reformas(bills, rp)
    ids = [c["id"] for c in cartas]
    assert len(ids) == len(set(ids)), "ids duplicados"
    json.dump(cartas, open(D / "cartas_reales.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"{len(cartas)} cartas reales: obras={sum(1 for c in cartas if c['meta']['tipo']=='proyecto_publico')} "
          f"leyes={sum(1 for c in cartas if c['meta']['tipo']=='proyecto_de_ley')} reformas={sum(1 for c in cartas if 'constitucional' in c['meta']['tipo'])}")


if __name__ == "__main__":
    main()
