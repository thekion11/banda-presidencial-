#!/usr/bin/env python3
"""Informe de alcanzabilidad de cartas (N6): cuántas cartas pueden aparecer en el mazo bajo `disponibilidad` y gabinete.
Réplica en Python de sim/motor_gabinete.gd#disponible, sobre TODOS los gabinetes posibles (cada categoría con ministro está
alcanzable; el gabinete mide `gabinete.tamano`), años 1-4, eventos que ocurren de verdad, metas existentes y fiscal 0-100.
Una carta es INALCANZABLE si ninguna combinación de gabinete/año/evento/meta/fiscal la habilita. Código 1 si hay alguna.
Uso: python3 tools/informe_alcanzabilidad.py [--detalle]"""
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

D = Path(__file__).resolve().parents[1] / "data"


def cargar(nombre):
    return json.loads((D / nombre).read_text(encoding="utf-8"))


def anio_de_dia(dia: int, dias_mandato: int, anios: int) -> int:
    return max(1, min(anios, 1 + (dia - 1) // (dias_mandato // anios)))


def main() -> int:
    leyes, ministros = cargar("leyes.json"), cargar("ministros.json")
    cartas = cargar("cartas.json") + cargar("cartas_reales.json")
    gab, dias = leyes["gabinete"], leyes["hemiciclo"]["duracion_mandato_dias"]
    anios = int(gab["anios_mandato"])
    siempre, alias = set(gab["categorias_siempre"]), gab.get("categorias_alias", {})
    eventos = cargar("eventos.json") + cargar("juego_eventos_reales.json")
    ev_anio = {e["id"]: anio_de_dia(e["dia_objetivo"], dias, anios) for e in eventos
               if e.get("etapa", "gobierno") == "gobierno" and e.get("dia_objetivo")}
    metas = {m["id"] for m in cargar("metas.json")}
    cats_min = Counter(m["categoria_afin"] for m in ministros)
    posibles = siempre | set(cats_min)
    fiscal_max = float(leyes["limites_indicadores"]["max"])
    tam = int(gab["tamano"])

    def razon(c):
        cat = alias.get(c["categoria"], c["categoria"])
        if cat not in posibles:
            return "categoria_sin_ministro"
        d = c.get("disponibilidad")
        if d is None:
            return None
        desde, hasta = d.get("anio_desde") or 1, d.get("anio_hasta") or anios
        if desde > hasta:
            return "ventana_vacia"
        if d.get("evento"):
            a = ev_anio.get(d["evento"])
            if a is None:
                return "evento_inexistente_o_no_de_gobierno"
            if a > hasta:
                return "evento_posterior_a_la_ventana"
        if d.get("meta") and d["meta"] not in metas:
            return "meta_inexistente"
        if d.get("fiscal_min") is not None and d["fiscal_min"] > fiscal_max:
            return "fiscal_min_imposible"
        return None

    malas = [(c, razon(c)) for c in cartas if razon(c)]
    print(f"Cartas: {len(cartas)}; alcanzables: {len(cartas) - len(malas)}; inalcanzables: {len(malas)}")
    for r, n in Counter(r for _, r in malas).most_common():
        print(f"  {r}: {n}")
    if "--detalle" in sys.argv:
        for c, r in malas:
            print("  -", c["id"], r)
    # Cobertura por año con el mejor gabinete de `tam` ministros (voraz): cuántas cartas puede ver un jugador como máximo.
    print(f"\nCobertura por año con un gabinete de {tam} ministros (selección voraz de categorías):")
    for a in range(1, anios + 1):
        por_cat = defaultdict(int)
        for c in cartas:
            d = c.get("disponibilidad") or {}
            if (d.get("anio_desde") or 1) <= a <= (d.get("anio_hasta") or anios) and not razon(c):
                por_cat[alias.get(c["categoria"], c["categoria"])] += 1
        libres = sorted((k for k in por_cat if k not in siempre), key=lambda k: -por_cat[k])
        elegidas = libres[:tam]  # las categorías "siempre" no ocupan puesto en el gabinete
        total = sum(por_cat[k] for k in siempre) + sum(por_cat[k] for k in elegidas)
        print(f"  año {a}: disponibles sin gabinete {sum(por_cat.values())}; con gabinete voraz {total} ({', '.join(elegidas)})")
    print("\nAlcanzables por categoría y año (ventana, sin contar gabinete):")
    for cat in sorted({c["categoria"] for c in cartas}):
        fila = [sum(1 for c in cartas if c["categoria"] == cat and not razon(c) and (c.get("disponibilidad") or {}).get("anio_desde", 1) <= a
                    <= (c.get("disponibilidad") or {}).get("anio_hasta", anios)) for a in range(1, anios + 1)]
        print(f"  {cat:18s} {fila}")
    return 1 if malas else 0


if __name__ == "__main__":
    sys.exit(main())
