#!/usr/bin/env python3
"""Genera data/geo/grafo_urbano.json: grafo de calles esquemático (8x8 cruces) para el Comité de Planificación.

Es determinista e ilustrativo. En la Fase 3 final se reemplaza por el grafo real hornado desde OpenStreetMap (tools/geo/).
Cada arista lleva longitud, multiplicador de costo (centro más caro, cruce de río), expropiaciones y bandera de río.
"""
import hashlib
import json
from pathlib import Path

N = 8
C = 1.0 / 9.0  # separación entre calles (coincide con las manzanas de ComiteMapa)
RIO_Y = (0.58, 0.67)


def h(texto: str, mod: int) -> int:
    return int(hashlib.sha256(texto.encode()).hexdigest(), 16) % mod


def nid(i: int, j: int) -> str:
    return f"n{i}{j}"


def main() -> int:
    nodos = [{"id": nid(i, j), "x": round((i + 1) * C, 4), "y": round((j + 1) * C, 4)} for j in range(N) for i in range(N)]
    aristas = []
    for j in range(N):
        for i in range(N):
            for di, dj in ((1, 0), (0, 1)):
                a, b = (i, j), (i + di, j + dj)
                if b[0] >= N or b[1] >= N:
                    continue
                cx = (a[0] + b[0]) / 2.0 + 1 - 4.5
                cy = (a[1] + b[1]) / 2.0 + 1 - 4.5
                dens = max(0.0, 1.0 - (cx * cx + cy * cy) ** 0.5 / 5.0)  # centro urbano denso
                y0, y1 = (a[1] + 1) * C, (b[1] + 1) * C
                rio = (dj == 1) and (y0 <= RIO_Y[0] + 0.01 and y1 >= RIO_Y[1] - 0.01)
                aristas.append({
                    "a": nid(*a), "b": nid(*b), "longitud": 1.2,
                    "costo_mult": round(1.0 + dens * 0.6 + (0.9 if rio else 0.0), 3),
                    "expropiaciones": round(dens * 14) + h(nid(*a) + nid(*b), 5),
                    "rio": rio})
    datos = {
        "nota": "Grafo esquemático ilustrativo (no es cartografía real).",
        "parametros": {
            "peso_expropiacion": 0.15,
            "sliders": {
                "ritmo": {"costo_max": 0.30, "plazo_max": -0.35},
                "cobertura": {"poblacion_max": 0.20, "expropiaciones_max": 0.25},
                "estacion_extra": {"costo": 0.06, "poblacion": 0.04}},
            "rechazo": {"medio": 120, "alto": 200},
            "min_estaciones": 3, "max_estaciones": 7},
        "nodos": nodos, "aristas": aristas}
    destino = Path(__file__).resolve().parents[2] / "data" / "geo" / "grafo_urbano.json"
    destino.write_text(json.dumps(datos, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"OK: {destino} ({destino.stat().st_size // 1024} KB, {len(nodos)} nodos, {len(aristas)} aristas)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
