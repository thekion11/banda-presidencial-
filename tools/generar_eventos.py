#!/usr/bin/env python3
"""Genera data/juego_eventos_reales.json: eventos del juego a partir de los hitos reales VERIFICADOS (data/eventos_reales.json).
Solo se usan hechos con fuente primaria dentro de las ventanas jugables (campaña desde el 21-sep-2025 y gobierno desde el 11-mar-2026);
los resultados electorales reales y la transición dic-2025/mar-2026 no se juegan (la elección la decide el jugador).
Los hechos son reales; los efectos de juego son ilustrativos (cifras_ilustrativas). Sin nombres de políticos: se usan roles."""
import json
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INICIO_CAMPANA = date(2025, 9, 21)
FIN_CAMPANA = date(2025, 11, 15)  # la 1ª vuelta real no se juega: la decide el jugador
INICIO_MANDATO = date(2026, 3, 11)
FUENTE = {"legislativo": "fuentes.json#senado_tramitacion", "institucional": "fuentes.json#cpr_texto_bcn_2025_10_07"}
EFECTOS = {"legislativo": [{"ind": "capital", "delta": 1}], "institucional": [{"ind": "cohesion", "delta": 1}]}


def main() -> None:
    reales = json.load(open(ROOT / "data" / "eventos_reales.json", encoding="utf-8"))["eventos"]
    res = []
    for e in sorted(reales, key=lambda x: (x["fecha"], x["id"])):
        d = date.fromisoformat(e["fecha"])
        if not e.get("verificado") or e["categoria"] not in FUENTE:
            continue
        if INICIO_CAMPANA <= d <= FIN_CAMPANA:
            etapa, dia = "campana", (d - INICIO_CAMPANA).days + 1
        elif d >= INICIO_MANDATO:
            etapa, dia = "gobierno", (d - INICIO_MANDATO).days + 1
        else:
            continue
        texto = " ".join(e["descripcion"].split())
        titulo = texto.split(":")[0][:80] if texto.startswith("Se publica la Ley") else texto[:80]
        res.append({"id": "evt_" + e["id"], "tipo": "programado", "dia_objetivo": dia, "hora_etiqueta": "09:00", "peso_sorteo": 1.0,
                    "titulo": titulo, "descripcion": texto[:240], "votacion": None, "efectos_base": EFECTOS[e["categoria"]],
                    "etapa": etapa, "fuente": FUENTE[e["categoria"]],
                    "meta": {"fecha_real": e["fecha"], "fuentes": e["fuentes"], "categoria": e["categoria"], "cifras_ilustrativas": True}})
    json.dump(res, open(ROOT / "data" / "juego_eventos_reales.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(len(res), "eventos reales jugables;", sum(1 for r in res if r["etapa"] == "campana"), "en campaña")


if __name__ == "__main__":
    main()
