#!/usr/bin/env python3
"""Añade a data/cartas.json una carta ILUSTRATIVA que exige el tipo `ley_interpretativa` (ley interpretativa de la Constitución).

Ninguna de las 1.276 cartas reales la requiere (data/cartas_reales.json usa ley_simple, LOC y reforma), por lo que se crea una
carta de diseño, rotulada como ilustrativa. Idempotente: python3 tools/generar_carta_interpretativa.py.
Regla de quórum: CPR art. 66 (cita en data/bcn/normas.json): interpretativas de la Constitución, 4/7 de los en ejercicio.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUTA = ROOT / "data" / "cartas.json"
ID = "pol_ley_interpretativa"

CARTA = {
    "id": ID, "categoria": "politica", "costo_pa": 3, "titulo": "Ley interpretativa de la Constitución",
    "efectos": [{"ind": "cohesion", "delta": 2}, {"ind": "capital", "delta": -3}, {"ind": "riesgo_ejecucion", "delta": 1}],
    "requisitos": {"ley": "ley_interpretativa", "quorum": "ley_interpretativa"},
    "corrector": None, "abre_propuesta_comite": None,
    "fuente": "fuentes.json#cpr_chile_2026",
    "meta": {"tipo": "ilustrativa", "cifras_ilustrativas": True,
             "nota": "Carta de diseño (ninguna carta real exige este tipo). Quórum 4/7 de los en ejercicio según la cita de normas.json; sin verificar contra el texto consolidado."},
}

if __name__ == "__main__":
    cartas = [c for c in json.loads(RUTA.read_text(encoding="utf-8")) if c["id"] != ID] + [CARTA]
    RUTA.write_text(json.dumps(cartas, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"data/cartas.json: {len(cartas)} cartas")
