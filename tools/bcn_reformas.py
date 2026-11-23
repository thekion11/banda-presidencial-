#!/usr/bin/env python3
"""Extrae las reformas constitucionales citadas en las notas al pie del texto oficial de la Constitución.

Uso: python3 tools/bcn_reformas.py --cpr constitucion.pdf
Escribe data/bcn/reformas_constitucionales.json (parte "reformas_en_texto_vigente").
Las propuestas de 2022/2023 y las reformas en trámite viven en data/bcn/reformas_propuestas.json
(curadas a mano, con verificado:true/false según la fuente).
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
SALIDA = ROOT / "data" / "bcn" / "reformas_constitucionales.json"
MESES = {m: i for i, m in enumerate("enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre".split(), 1)}
FECHA = r"(\d{1,2}) de ([a-z]+) de (\d{4})|(\d{2})\.(\d{2})\.(\d{4})"
NOTA = re.compile(r"(?:ley|Ley)(?: de [Rr]eforma [Cc]onstitucional)?\s*N[º°o]?\s?(\d{2}\.?\d{3})([^.]{0,160}?)(?:publicada|Diario Oficial)[^.\d]{0,40}?(?:" + FECHA + ")")


# Artículos afectados confirmados leyendo la nota junto al artículo (el resto sólo tiene ubicación aproximada de la nota)
CONFIRMADOS = {"21.481": [127, 128], "21.654": [42], "21.233": [63]}


def iso(g):
    if g[2]:
        return f"{g[4]}-{MESES[g[3]]:02d}-{int(g[2]):02d}" if g[3] in MESES else None
    return f"{g[7]}-{g[6]}-{g[5]}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cpr", required=True)
    a = ap.parse_args()
    t = subprocess.run(["pdftotext", a.cpr, "-"], capture_output=True, text=True, check=True).stdout
    arts = [(int(m.group(1)), m.start()) for m in re.finditer(r"(?m)^Art[íi]culo (\d+)\s*[º°o]?\s*[\.\-]", t)]
    reformas = {}
    for m in NOTA.finditer(t):
        num = m.group(1) if "." in m.group(1) else f"{m.group(1)[:2]}.{m.group(1)[2:]}"
        g = m.groups()
        # grupos: 0 num,1 resto,2 d,3 mes,4 año | 5 dd,6 mm,7 aaaa  -> reordenar
        grupo = (None, None, g[2], g[3], g[4], g[5], g[6], g[7])
        fecha = iso(grupo)
        art = max([n for n, p in arts if p <= m.start()] or [0])
        r = reformas.setdefault(num, {"ley": num, "fechas_citadas": set(), "articulos_afectados": set()})
        if fecha:
            r["fechas_citadas"].add(fecha)
        if art:
            r["articulos_afectados"].add(art)
    out = []
    for num, r in sorted(reformas.items()):
        fechas = sorted(r["fechas_citadas"])
        out.append({"ley": num, "tipo_reforma": "reforma constitucional (nota al pie del texto oficial)",
                    "fecha_publicacion": fechas[0] if len(fechas) == 1 else None,
                    "fechas_citadas": fechas,
                    "articulos_afectados": CONFIRMADOS.get(num),
                    "articulos_afectados_verificado": num in CONFIRMADOS,
                    "ubicacion_nota_aprox_art": sorted(r["articulos_afectados"]),
                    "quorum_necesario_hoy": "4/7 de los diputados y senadores en ejercicio (CPR art. 127)",
                    "fuente": "fuentes.json#cpr_texto_bcn_2025_10_07",
                    "verificado": len(fechas) == 1,
                    "nota": "" if len(fechas) == 1 else "el texto oficial cita fechas distintas o ninguna: contrastar con LeyChile"})
    doc = {"fecha_corte": time.strftime("%Y-%m-%d"), "texto_base": "Constitución actualizada al 7-oct-2025",
           "reformas_en_texto_vigente": out}
    SALIDA.write_text(json.dumps(doc, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"OK {len(out)} reformas ({sum(1 for r in out if r['verificado'])} con fecha única) -> {SALIDA}")


if __name__ == "__main__":
    main()
