#!/usr/bin/env python3
"""Valida un archivo de cartas curadas (lista JSON) contra el esquema y las reglas de la Fase B. Uso: python3 tools/validar_curadas.py data/curadas/ARCHIVO.json
Comprueba además que ids y títulos no choquen con las cartas existentes ni con otros archivos de data/curadas/."""
import json
import sys
from collections import Counter
from pathlib import Path

import jsonschema

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
INDICADORES = {"aprobacion", "capital", "cohesion", "fiscal", "riesgo_ejecucion", "viviendas_anio"}
CATEGORIAS = {"politica", "educacion", "energia", "medioambiente", "descentralizacion", "economia", "transportes", "obras", "seguridad", "salud", "vivienda", "hacienda", "social"}
LEYES = {None, "ley_simple", "quorum_calificado", "ley_interpretativa", "ley_organica_constitucional", "reforma_constitucional"}
RANGO = {"aprobacion": (-5, 5), "capital": (-4, 3), "cohesion": (-3, 3), "fiscal": (-6, 5), "riesgo_ejecucion": (-3, 4), "viviendas_anio": (-12000, 12000)}


def efectos_ok(efs: list, ctx: str, errores: list) -> None:
    if not efs:
        errores.append(f"{ctx}: efectos vacíos")
    for e in efs:
        if e.get("ind") not in INDICADORES:
            errores.append(f"{ctx}: indicador inválido {e.get('ind')}")
            continue
        lo, hi = RANGO[e["ind"]]
        if not lo <= e["delta"] <= hi:
            errores.append(f"{ctx}: delta {e['ind']}={e['delta']} fuera de rango {lo}..{hi}")


def main() -> int:
    ruta = Path(sys.argv[1])
    cartas = json.loads(ruta.read_text(encoding="utf-8"))
    errores: list = []
    esquema = json.loads((DATA / "schemas" / "cartas.schema.json").read_text(encoding="utf-8"))
    try:
        jsonschema.validate(cartas, esquema)
    except jsonschema.ValidationError as exc:
        errores.append(f"esquema: {exc.message} en {list(exc.absolute_path)}")
    existentes_ids, existentes_tit = set(), set()
    for f in ("cartas.json", "cartas_reales.json"):
        for c in json.loads((DATA / f).read_text(encoding="utf-8")):
            existentes_ids.add(c["id"])
            existentes_tit.add(c["titulo"].strip().lower())
    for otro in (DATA / "curadas").glob("*.json"):
        if otro.resolve() != ruta.resolve():
            for c in json.loads(otro.read_text(encoding="utf-8")):
                existentes_ids.add(c["id"])
                existentes_tit.add(c["titulo"].strip().lower())
    ids, tit = Counter(c["id"] for c in cartas), Counter(c["titulo"].strip().lower() for c in cartas)
    for c in cartas:
        ctx = c.get("id", "?")
        if ids[c["id"]] > 1 or c["id"] in existentes_ids:
            errores.append(f"{ctx}: id duplicado")
        if tit[c["titulo"].strip().lower()] > 1 or c["titulo"].strip().lower() in existentes_tit:
            errores.append(f"{ctx}: título duplicado «{c['titulo']}»")
        if not c["id"].startswith("cur_"):
            errores.append(f"{ctx}: el id debe empezar con cur_")
        if c["categoria"] not in CATEGORIAS:
            errores.append(f"{ctx}: categoría inválida {c['categoria']}")
        if not (c.get("curada") is True and c.get("cifras_ilustrativas") is True):
            errores.append(f"{ctx}: curada y cifras_ilustrativas deben ser true")
        if c.get("fuente") != "fuentes.json#ficticio_2026":
            errores.append(f"{ctx}: fuente debe ser fuentes.json#ficticio_2026")
        if not 1 <= c["costo_pa"] <= 3 or len(c["titulo"]) > 60:
            errores.append(f"{ctx}: costo 1-3 y título ≤ 60")
        if c["requisitos"]["ley"] not in LEYES or c["requisitos"]["ley"] != c["requisitos"]["quorum"]:
            errores.append(f"{ctx}: requisitos.ley y quorum deben coincidir y ser un tipo válido")
        if c["requisitos"]["ley"] and "camara_origen" not in c:
            errores.append(f"{ctx}: una ley necesita camara_origen (camara|senado)")
        efectos_ok(c["efectos"], ctx, errores)
        if not 2 <= len(c["efectos"]) <= 4:
            errores.append(f"{ctx}: entre 2 y 4 efectos")
        if "riesgo" in c:
            if not 0.1 <= c["riesgo"]["prob"] <= 0.6:
                errores.append(f"{ctx}: riesgo.prob entre 0,1 y 0,6")
            efectos_ok(c["riesgo"]["efectos"], ctx + " riesgo", errores)
        if "diferido" in c:
            if not 2 <= c["diferido"]["semanas"] <= 30 or not c["diferido"].get("texto"):
                errores.append(f"{ctx}: diferido.semanas 2..30 y texto obligatorio")
            efectos_ok(c["diferido"]["efectos"], ctx + " diferido", errores)
        if "sabor" in c and len(c["sabor"]) > 140:
            errores.append(f"{ctx}: sabor ≤ 140 caracteres")
    n = len(cartas)
    riesgosas = sum(1 for c in cartas if "riesgo" in c)
    futuras = sum(1 for c in cartas if "diferido" in c)
    leyes = sum(1 for c in cartas if c["requisitos"]["ley"])
    firmas = len({tuple(sorted((e["ind"], e["delta"]) for e in c["efectos"])) for c in cartas})
    print(f"{n} cartas · con riesgo {riesgosas} · con efecto a futuro {futuras} · leyes {leyes} · firmas de efecto distintas {firmas} · costos {dict(sorted(Counter(c['costo_pa'] for c in cartas).items()))}")
    if firmas < n * 0.9:
        errores.append("poca variedad: al menos el 90 % de las cartas debe tener una firma de efectos distinta")
    if errores:
        print("\n".join(errores[:40]))
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
