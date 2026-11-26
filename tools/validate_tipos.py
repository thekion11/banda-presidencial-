#!/usr/bin/env python3
"""Esqueleto de tipos de data/leyes.json: el motor lee decenas de claves de ahí por nombre y un dato borrado, nulo o de otro tipo se vería como un error de script
en plena partida. Este validador compara la estructura actual con la guardada en tools/esqueleto_leyes.json (ruta de cada dato -> tipo) y falla con la ruta exacta
si falta una clave o cambió de tipo. Las claves nuevas se avisan: regenerar el esqueleto con --regenerar tras revisar el diff.
Uso: python3 tools/validate_tipos.py [--regenerar]
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ESQUELETO = ROOT / "tools" / "esqueleto_leyes.json"


def tipo(v) -> str:
    if v is None:
        return "nulo"
    if isinstance(v, bool):
        return "bool"
    if isinstance(v, (int, float)):
        return "num"
    if isinstance(v, str):
        return "texto"
    if isinstance(v, list):
        return "lista"
    return "dic"


def esqueleto(obj, ruta: str = "") -> dict:
    res = {ruta or "/": tipo(obj)}
    if isinstance(obj, dict):
        for k, v in obj.items():
            res.update(esqueleto(v, f"{ruta}/{k}"))
    elif isinstance(obj, list) and len(obj) <= 40:  # listas de configuración; las grandes (catálogos) se validan por esquema JSON
        for i, v in enumerate(obj):
            res.update(esqueleto(v, f"{ruta}[{i}]"))
    return res


def comparar(actual: dict, guardado: dict) -> tuple:
    faltan = [f"{r}: falta (era {t})" for r, t in guardado.items() if r not in actual]
    cambian = [f"{r}: era {t} y ahora es {actual[r]}" for r, t in guardado.items() if r in actual and actual[r] != t]
    nuevas = [r for r in actual if r not in guardado]
    return faltan, cambian, nuevas


def main() -> int:
    leyes = json.loads((ROOT / "data" / "leyes.json").read_text(encoding="utf-8"))
    actual = esqueleto(leyes)
    if "--regenerar" in sys.argv:
        ESQUELETO.write_text(json.dumps(actual, ensure_ascii=False, indent=0, sort_keys=True) + "\n", encoding="utf-8")
        print("Esqueleto regenerado:", len(actual), "rutas")
        return 0
    guardado = json.loads(ESQUELETO.read_text(encoding="utf-8"))
    faltan, cambian, nuevas = comparar(actual, guardado)
    for m in faltan + cambian:
        print("ERROR: data/leyes.json", m)
    if nuevas:
        print(f"[AVISO] {len(nuevas)} rutas nuevas en data/leyes.json respecto del esqueleto (regenera con --regenerar tras revisarlas): {', '.join(nuevas[:4])}...")
    if not (faltan or cambian):
        print(f"OK: data/leyes.json conserva su estructura y tipos ({len(guardado)} rutas)")
    return 1 if (faltan or cambian) else 0


if __name__ == "__main__":
    sys.exit(main())
