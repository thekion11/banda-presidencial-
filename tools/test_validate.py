#!/usr/bin/env python3
"""Pruebas negativas del validador de referencias: con los datos reales no hay errores, y cada dato roto a propósito debe ser detectado con un mensaje claro.
Uso: python3 tools/test_validate.py   (se ejecuta en el CI)
"""
import copy
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_referencias import cargar_datos, validar_referencias  # noqa: E402


def con_decision(d):
    return next(e for e in d["eventos"] if e.get("opciones"))


def rotos():
    """(nombre, función que rompe una copia de los datos, fragmento esperado en el mensaje)"""
    def f(nombre, esperado):
        def deco(fn):
            casos.append((nombre, fn, esperado))
            return fn
        return deco
    casos = []

    @f("fuente de carta inexistente", "no existe en fuentes.json")
    def _(d): d["cartas"][0]["fuente"] = "fuentes.json#no_existe"

    @f("propuesta del comité inexistente", "abre_propuesta_comite")
    def _(d): d["cartas"][0]["abre_propuesta_comite"] = "prop_fantasma"

    @f("disponibilidad por evento inexistente", "disponibilidad.evento")
    def _(d): d["cartas"][0]["disponibilidad"] = {"evento": "evt_fantasma"}

    @f("disponibilidad por meta inexistente", "disponibilidad.meta")
    def _(d): d["cartas"][0]["disponibilidad"] = {"meta": "meta_fantasma"}

    @f("región de carta inexistente", "región")
    def _(d): d["cartas"][0]["meta"] = {"region_id": "atlantida"}

    @f("probabilidad de riesgo fuera de rango", "riesgo.prob")
    def _(d): d["cartas"][0]["riesgo"] = {"prob": 1.5, "efectos": []}

    @f("categoría de carta desconocida", "categoría")
    def _(d): d["cartas"][0]["categoria"] = "astrologia"

    @f("evento que requiere una decisión inexistente", "requiere una decisión")
    def _(d): d["eventos"][0]["requiere"] = {"decision": {"evento": "evt_fantasma", "idx": 0}}

    @f("cadena a un evento inexistente", "cadena a un evento inexistente")
    def _(d): con_decision(d)["opciones"][0]["cadena"] = {"evento": "evt_fantasma", "semanas": 3}

    @f("peso de sorteo negativo", "peso_sorteo negativo")
    def _(d): d["eventos"][0]["peso_sorteo"] = -1

    @f("probabilidad de opción fuera de rango", "probabilidad fuera de (0,1)")
    def _(d): con_decision(d)["opciones"][0]["riesgo"] = {"prob": 0, "efectos": []}


    @f("costo de carta negativo", "valor negativo")
    def _(d): d["cartas"][0]["costo_pa"] = -1

    @f("probabilidad de ministro fuera de rango", "riesgo_escandalo")
    def _(d): d["ministros"][0]["riesgo_escandalo"] = 1.7

    @f("ventana de disponibilidad invertida", "ventana con inicio mayor que fin")
    def _(d): d["cartas"][0]["disponibilidad"] = {"anio_desde": 4, "anio_hasta": 2}

    @f("efecto con delta absurdo", "delta absurdo")
    def _(d): d["cartas"][0]["efectos"] = [{"ind": "fiscal", "delta": 5000}]

    @f("valor no finito", "no finito")
    def _(d): d["cartas"][0]["efectos"] = [{"ind": "fiscal", "delta": float("inf")}]

    @f("población regional no positiva", "población no positiva")
    def _(d): d["regiones"][0]["poblacion_miles"] = 0

    @f("evento programado fuera del mandato", "fuera del mandato")
    def _(d): next(e for e in d["eventos"] if e.get("dia_objetivo") is not None).update({"dia_objetivo": 99999})

    @f("diferido sin semanas", "diferido.semanas")
    def _(d): con_decision(d)["opciones"][0]["diferido"] = {"semanas": 0, "efectos": []}

    @f("ronda de escena fuera de rango", "escena")
    def _(d): d["eventos"][0]["escena"] = {"nombre": "x", "ronda": 5, "rondas": 3}

    @f("id de evento repetido", "ids repetidos")
    def _(d): d["eventos"].append(copy.deepcopy(d["eventos"][0]))

    @f("meta que requiere una meta inexistente", "meta inexistente")
    def _(d): d["metas"][0]["requiere"] = "meta_fantasma"

    @f("ministerio con menos de 3 candidatos", "debe tener 3 candidatos")
    def _(d): d["ministros"].pop()

    @f("riesgo de escándalo fuera de rango", "riesgo_escandalo")
    def _(d): d["ministros"][0]["riesgo_escandalo"] = 1.5

    @f("partido que pide un ministerio inexistente", "ministerio inexistente")
    def _(d): d["coalicion"][0]["ministerios_pedidos"] = ["min_fantasma"]

    @f("escaños negativos", "escaños negativos")
    def _(d): d["coalicion"][0]["escanos_senado"] = -3

    return casos


def fuzz_tipos() -> int:
    """Muta cada dato de leyes.json (borrar, nulo, número por texto, texto por número...) y exige que validate_tipos lo detecte con su ruta."""
    import json
    from validate_tipos import comparar, esqueleto, ESQUELETO
    guardado = json.loads(ESQUELETO.read_text(encoding="utf-8"))
    leyes = cargar_datos()["leyes"]
    rutas = []

    def hojas(o, ruta=""):
        if isinstance(o, dict):
            for k, v in o.items():
                rutas.append((o, k, f"{ruta}/{k}"))
                hojas(v, f"{ruta}/{k}")
    hojas(leyes)
    fallos = 0
    pruebas = 0
    for padre, k, ruta in rutas:
        orig = padre[k]
        for nombre, nuevo in (("borrado", None), ("nulo", None), ("texto", "x"), ("número", 7), ("lista", [])):
            if nombre == "borrado":
                del padre[k]
            else:
                if esqueleto(orig).get("/") == esqueleto(nuevo).get("/"):
                    continue  # mismo tipo: no es un cambio de estructura
                padre[k] = nuevo
            pruebas += 1
            faltan, cambian, _ = comparar(esqueleto(leyes), guardado)
            if not any(m.startswith(ruta + ":") for m in faltan + cambian):
                print(f"FALLO: mutación «{nombre}» en {ruta} no detectada")
                fallos += 1
            padre[k] = orig
    print(f"test_validate (tipos): {pruebas} mutaciones de leyes.json, {fallos} no detectadas")
    return fallos


def rangos_leyes() -> int:
    """Valores de leyes.json que el barrido de «Búsqueda infinita de fallas» mostró que cuelgan o dividen por cero: el validador debe rechazarlos."""
    from validate_data import validar_leyes  # noqa: E402
    import json
    leyes = json.loads((Path(__file__).resolve().parents[1] / "data" / "leyes.json").read_text(encoding="utf-8"))
    fuentes = {x["id"] for x in json.loads((Path(__file__).resolve().parents[1] / "data" / "fuentes.json").read_text(encoding="utf-8"))}
    casos = [("encuestas.historial_max = -1", lambda l: l["encuestas"].__setitem__("historial_max", -1), "historial_max"),
             ("encuestas.historial_max = 0", lambda l: l["encuestas"].__setitem__("historial_max", 0), "historial_max"),
             ("gabinete.anios_mandato = 0", lambda l: l["gabinete"].__setitem__("anios_mandato", 0), "anios_mandato"),
             ("hemiciclo.dias_por_turno = 0", lambda l: l["hemiciclo"].update({"dias_por_turno": 0, "duracion_mandato_dias": 0}), "dias_por_turno"),
             ("hemiciclo.duracion_mandato_dias = -1", lambda l: l["hemiciclo"].__setitem__("duracion_mandato_dias", -1), "duracion_mandato_dias"),
             ("limites_indicadores min >= max", lambda l: l["limites_indicadores"].update({"min": 10, "max": 5}), "limites_indicadores"),
             ("limites_indicadores max > 100", lambda l: l["limites_indicadores"].__setitem__("max", 1000), "limites_indicadores")]
    fallos = 0
    validar_leyes(json.loads(json.dumps(leyes)), fuentes)  # los datos reales pasan
    for nombre, romper, esperado in casos:
        d = json.loads(json.dumps(leyes))
        romper(d)
        try:
            validar_leyes(d, fuentes)
        except (ValueError, KeyError) as exc:
            if esperado not in str(exc):
                print(f"FALLO: «{nombre}»: se detectó con otro mensaje: {exc}")
                fallos += 1
            continue
        print(f"FALLO: «{nombre}»: el valor roto NO fue detectado")
        fallos += 1
    print(f"test_validate (rangos de leyes.json): {len(casos)} valores peligrosos probados, {fallos} fallos")
    return fallos


def version_divergente() -> int:
    """El chequeo de versión debe detectar que las tres copias divergen."""
    from check_version import problemas  # noqa: E402
    ok = {"project": "1.0", "preset": "1.0", "datos": "1.0", "codigo": 2}
    fallos = 0
    if problemas(ok):
        print("FALLO: una versión coherente se rechazó")
        fallos += 1
    for nombre, cambio in (("preset distinto", {"preset": "0.1.0"}), ("version.json distinto", {"datos": "0.9"}), ("código 0", {"codigo": 0}), ("sin versión", {"project": None})):
        if not problemas({**ok, **cambio}):
            print(f"FALLO: «{nombre}» no se detectó")
            fallos += 1
    print(f"test_validate (versión): 4 divergencias probadas, {fallos} fallos")
    return fallos


def main() -> int:
    base = cargar_datos()
    validar_referencias(copy.deepcopy(base))  # con los datos reales no debe fallar
    fallos = 0
    for nombre, romper, esperado in rotos():
        d = copy.deepcopy(base)
        romper(d)
        try:
            validar_referencias(d)
        except (ValueError, KeyError) as exc:
            if esperado.lower() not in str(exc).lower():
                print(f"FALLO: «{nombre}»: se detectó, pero el mensaje no dice «{esperado}»: {exc}")
                fallos += 1
            continue
        print(f"FALLO: «{nombre}»: el dato roto NO fue detectado")
        fallos += 1
    print(f"test_validate: {len(rotos())} datos rotos probados, {fallos} fallos")
    fallos += fuzz_tipos()
    fallos += rangos_leyes()
    fallos += version_divergente()
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
