#!/usr/bin/env python3
"""Añade a data/cartas.json las cartas de categoría `estado` (Estado empresario, DISENO_V2 §7).

Idempotente: python3 tools/generar_cartas_estado.py. Tres tipos (empresa pública, privatización, expropiación),
3 variantes cada uno. Todas las cifras son ilustrativas y van rotuladas en `meta`.
Base legal: Art. 19 N° 21 inc. 2 CPR (actividad empresarial del Estado: ley de quórum calificado) y
Art. 19 N° 24 CPR (expropiación por ley que autorice). Verificar contra el texto oficial antes de publicar.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUTA = ROOT / "data" / "cartas.json"

# id, tipo, costo, titulo, ley, efectos
CARTAS = [
    ("estado_empresa_litio", "empresa_publica", 3, "Empresa pública del litio", "quorum_calificado",
     [("fiscal", -6), ("capital", -3), ("riesgo_ejecucion", 3), ("aprobacion", 2), ("cohesion", 1)]),
    ("estado_empresa_farmacias", "empresa_publica", 2, "Red estatal de farmacias", "quorum_calificado",
     [("fiscal", -4), ("capital", -2), ("riesgo_ejecucion", 2), ("aprobacion", 3)]),
    ("estado_empresa_conectividad", "empresa_publica", 3, "Empresa estatal de conectividad", "quorum_calificado",
     [("fiscal", -5), ("capital", -2), ("riesgo_ejecucion", 3), ("cohesion", 2), ("aprobacion", 2)]),
    ("estado_priv_sanitarias", "privatizacion", 3, "Venta de participación en sanitarias", "ley_simple",
     [("fiscal", 7), ("cohesion", -3), ("aprobacion", -3), ("capital", -2), ("riesgo_ejecucion", 1)]),
    ("estado_priv_energia", "privatizacion", 3, "Venta de participación en generadora estatal", "ley_simple",
     [("fiscal", 6), ("aprobacion", -2), ("cohesion", -2), ("capital", -2), ("riesgo_ejecucion", 1)]),
    ("estado_priv_terrenos", "privatizacion", 2, "Venta de terrenos fiscales ociosos", "ley_simple",
     [("fiscal", 4), ("cohesion", -1), ("aprobacion", -1), ("capital", -1), ("riesgo_ejecucion", 1)]),
    ("estado_expro_ferrocarril", "expropiacion", 3, "Expropiación para corredor ferroviario", "ley_simple",
     [("fiscal", -3), ("aprobacion", -2), ("capital", -3), ("riesgo_ejecucion", 3), ("cohesion", -1)]),
    ("estado_expro_suelo_vivienda", "expropiacion", 3, "Expropiación de suelo para vivienda social", "ley_simple",
     [("fiscal", -4), ("viviendas_anio", 4000), ("capital", -3), ("cohesion", -2), ("aprobacion", 1), ("riesgo_ejecucion", 2)]),
    ("estado_expro_activos", "expropiacion", 3, "Expropiación de activos estratégicos", "ley_simple",
     [("fiscal", -7), ("aprobacion", 1), ("capital", -4), ("cohesion", -3), ("riesgo_ejecucion", 4)]),
]


def construir() -> list:
    res = []
    for cid, tipo, costo, titulo, ley, efectos in CARTAS:
        res.append({
            "id": cid, "categoria": "estado", "costo_pa": costo, "titulo": titulo,
            "efectos": [{"ind": i, "delta": d} for i, d in efectos],
            "requisitos": {"ley": ley, "quorum": ley},
            "corrector": None, "abre_propuesta_comite": None,
            "fuente": "fuentes.json#cpr_chile_2026",
            "meta": {"tipo": "estado_empresario", "subtipo": tipo, "cifras_ilustrativas": True},
        })
    return res


if __name__ == "__main__":
    cartas = [c for c in json.loads(RUTA.read_text(encoding="utf-8")) if c["categoria"] != "estado"]
    cartas += construir()
    RUTA.write_text(json.dumps(cartas, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"data/cartas.json: {len(cartas)} cartas ({len(CARTAS)} de categoría estado)")
