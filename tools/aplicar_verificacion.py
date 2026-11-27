#!/usr/bin/env python3
"""Aplica de golpe las verificaciones de fichas de docs/VERIFICACION_PROYECTOS.json a data/proyectos/*.json.
data/ está CONGELADO (CLAUDE.md §2, D17): por eso este script no hace nada sin --descongelado, que solo se pasa
cuando el usuario autoriza descongelar. Cambiar data/ cambia la huella: después hay que regenerar los oros
(`tests/test_determinismo.gd -- --regenerar` y las constantes ORO) y documentar el motivo.
Acciones: «marcar» (verificado=true + nota_verificacion + fuente_verificacion) y «corregir» (además cambia `campos`).
Uso: python3 tools/aplicar_verificacion.py [--descongelado] [--simular]"""
import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
LISTA = RAIZ / "docs" / "VERIFICACION_PROYECTOS.json"


def main() -> int:
    if "--descongelado" not in sys.argv and "--simular" not in sys.argv:
        print("data/ está congelado: usa --simular para ver qué cambiaría o --descongelado con autorización del usuario.")
        return 2
    simular = "--simular" in sys.argv
    entradas = json.loads(LISTA.read_text(encoding="utf-8"))
    por_archivo: dict[str, list[dict]] = {}
    for e in entradas:
        por_archivo.setdefault(e["archivo"], []).append(e)
    total = 0
    for archivo, lista in por_archivo.items():
        ruta = RAIZ / "data" / "proyectos" / f"{archivo}.json"
        datos = json.loads(ruta.read_text(encoding="utf-8"))
        fichas = datos if isinstance(datos, list) else datos.get("proyectos", [])
        indice = {f["id"]: f for f in fichas if isinstance(f, dict)}
        for e in lista:
            f = indice.get(e["id"])
            if f is None:
                print(f"NO ENCONTRADA: {e['id']} en {archivo}")
                return 1
            if e["accion"] not in ("marcar", "corregir"):
                print(f"acción inválida en {e['id']}")
                return 1
            f.update(e.get("campos", {}) if e["accion"] == "corregir" else {})
            f["verificado"] = True
            f["nota_verificacion"] = f"{e['nota']} (fuente: {e['fuente_url']}, {e['fecha_fuente']})"
            total += 1
        if not simular:
            ruta.write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{'Simulado' if simular else 'Aplicado'}: {total} fichas")
    return 0


if __name__ == "__main__":
    sys.exit(main())
