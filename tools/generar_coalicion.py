#!/usr/bin/env python3
"""Genera data/coalicion.json a partir de data/partidos/partidos_juego.json (15 réplicas ficticias de los partidos vigentes).

Reproducible: python3 tools/generar_coalicion.py. Campos que usa el sim:
  ideologia {eco, inst}  <- eje_eco / eje_inst (mismos ejes que data/ideologia.json)
  escanos_senado/camara  <- escanos.senadores / escanos.diputados (ilustrativos: ver meta del origen)
  peticion               <- nº de ministerios y de asesores que piden + categoría de carta principal
Los asesores del origen son perfiles en texto libre; el sim solo cuenta cuántos asesores entrega el jugador.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def construir() -> list:
    origen = json.loads((ROOT / "data/partidos/partidos_juego.json").read_text(encoding="utf-8"))
    res = []
    for p in origen["partidos"]:
        res.append({
            "id": p["id"], "nombre": p["nombre"], "sigla": p["sigla"], "alias_bloque": p["alias_bloque"],
            "real_ref": p["real_ref"],
            "ideologia": {"eco": p["eje_eco"], "inst": p["eje_inst"]},
            "escanos_senado": p["escanos"]["senadores"], "escanos_camara": p["escanos"]["diputados"],
            "peticion": {"ministerios": len(p["pide"]["ministerios"]), "asesores": len(p["pide"]["asesores"]),
                         "categoria_carta": p["pide"]["categorias"][0]},
            "ministerios_pedidos": p["pide"]["ministerios"],
            "categorias_pedidas": p["pide"]["categorias"],
            "categorias_rechazadas": p["rechaza"]["categorias"],
            "fuente": "fuentes.json#servel",
            "cifras_ilustrativas": True,
            "nota_escanos": "Escaños ilustrativos (peso de juego, redondeados a partir de la elección 2025); partido ficticio, réplica de un partido real (docs/PARTIDOS.md).",
        })
    return res


if __name__ == "__main__":
    lista = construir()
    (ROOT / "data/coalicion.json").write_text(json.dumps(lista, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"data/coalicion.json: {len(lista)} partidos")
