#!/usr/bin/env python3
"""Textos de data/ que ve el jugador (cartas, eventos, opciones, ministros, metas, asesores, partidos): sin emojis (CLAUDE.md §5), sin espacios dobles ni puntos suspensivos
de tres puntos, con tildes en las palabras más comunes y con una longitud que cabe en la ficha de 390 px (límites por tipo de texto).
Uso: python3 tools/validar_textos.py [--listar]    (sale con error si hay problemas; el CI lo ejecuta)
"""
import json
import re
import sys
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "data"
EMOJI = re.compile("[\U0001F300-\U0001FAFF☀-➿\U0001F000-\U0001F2FF️‍]")
# límites en caracteres: la ficha de 390 px muestra ~34 caracteres por línea a 12 pt; las descripciones largas se parten en líneas
LIMITES = {"titulo": 60, "descripcion": 260, "texto": 80, "rasgo": 80, "alias": 40, "nombre": 70, "descripcion_larga": 600}
# formas sin tilde que casi siempre son errores en textos de este juego (palabra completa, en minúsculas)
SIN_TILDE = {"accion": "acción", "politica": "política", "economia": "economía", "region": "región", "educacion": "educación", "eleccion": "elección", "camara": "cámara",
             "pais": "país", "gobierno ": None, "proyecto de ley ": None, "aprobacion": "aprobación", "reforma tributaria ": None, "seguridad ": None, "salud ": None,
             "decision": "decisión", "votacion": "votación", "comision": "comisión", "inversion": "inversión", "constitucion": "constitución", "coalicion": "coalición",
             "informacion": "información", "situacion": "situación", "tambien": "también", "mas": None, "ademas": "además", "unico": "único", 
             "ultimo": "último", "ultima": "última", "dia": None, "dias": "días", "anio": "año", "años": None, "habitos": "hábitos", "energia": "energía", "tecnologia": "tecnología"}
PALABRAS = {k: v for k, v in SIN_TILDE.items() if v}
CAMPOS = ("titulo", "descripcion", "texto", "rasgo", "alias", "nombre", "descripcion_larga")


def textos(obj, ruta=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, str) and k in CAMPOS:
                yield f"{ruta}/{k}", k, v
            elif isinstance(v, (dict, list)):
                yield from textos(v, f"{ruta}/{k}")
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from textos(v, f"{ruta}[{i}]")


def revisar(nombre: str, datos) -> list:
    errores = []
    for i, d in enumerate(datos if isinstance(datos, list) else [datos]):
        ident = d.get("id", i) if isinstance(d, dict) else i
        for ruta, campo, t in textos(d):
            ctx = f"{nombre} {ident}{ruta}"
            if EMOJI.search(t):
                errores.append(f"{ctx}: contiene un emoji")
            if "  " in t or t != t.strip():
                errores.append(f"{ctx}: espacios dobles o sobrantes")
            if "..." in t:
                errores.append(f"{ctx}: usa «...» en vez de «…»")
            lim = LIMITES.get(campo, 260)
            if len(t) > lim:
                errores.append(f"{ctx}: {len(t)} caracteres (máx {lim})")
            for pal in re.findall(r"[a-záéíóúñü]+", t.lower()):
                if pal in PALABRAS:
                    errores.append(f"{ctx}: «{pal}» sin tilde (¿{PALABRAS[pal]}?)")
    return errores


def main() -> int:
    errores = []
    for arch in ("cartas.json", "cartas_curadas.json", "eventos.json", "juego_eventos_reales.json", "ministros.json", "metas.json", "asesores.json", "coalicion.json"):
        errores += revisar(arch, json.loads((DATA / arch).read_text(encoding="utf-8")))
    razones = (Path(__file__).resolve().parents[1] / "game" / "componentes" / "razones.gd").read_text(encoding="utf-8")
    for clave, texto in re.findall(r'"([a-z_]+)":\s*"([^"]*)"', razones):
        if len(texto) > 140:
            errores.append(f"razones.gd {clave}: {len(texto)} caracteres (máx 140)")
        if EMOJI.search(texto):
            errores.append(f"razones.gd {clave}: contiene un emoji")
    for e in errores[:40]:
        print("ERROR:", e)
    if len(errores) > 40:
        print(f"... y {len(errores) - 40} más")
    if not errores:
        print("OK: textos de data/ sin emojis, con tildes y de largo razonable")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main())
