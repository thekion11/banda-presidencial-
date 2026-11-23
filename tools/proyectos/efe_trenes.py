#!/usr/bin/env python3
"""Proyectos ferroviarios de EFE Trenes de Chile (Plan Trenes para Chile / Otros proyectos en desarrollo).

Método: tabla curada (estado, regiones, fechas leídas de las fichas) + verificación automática: cada monto lleva una 'cita' literal que debe
aparecer en la página oficial descargada (API WordPress de efe.cl); si no aparece, el registro queda verificado=false.
Salida: data/proyectos/efe_trenes.json
Uso   : python3 tools/proyectos/efe_trenes.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import *  # noqa

U = "https://www.efe.cl/wp-json/wp/v2/pages/{}?_fields=content"
LINK = "https://www.efe.cl/proyectos/"
OTROS = 71611
# (clave, página, nombre, regiones, comuna, estado, estado_2026_03_11, musd, cita, inicio, fin, descripcion, notas)
T = [
    ("limache-la-calera", 5616, "Extensión Tren Limache-Puerto a Quillota y La Calera", ["valparaiso"], "Limache, Quillota, La Cruz, La Calera",
     "diseno", "diseno", 811, "inversión estimada de 811 millones de dólares", None, None,
     "26 km de vías, 7 estaciones y 15 trenes nuevos; RCA favorable en mayo de 2026, ingeniería de detalle desde fines de 2024.",
     "la ficha 'Otros proyectos' indica US$ 880 MM; se usa 811 (ficha del proyecto); licitación de obras proyectada 2S 2026"),
    ("chillan-estacion-central", 5611, "Nuevo servicio Tren Chillán-Estación Central", ["metropolitana", "ohiggins", "maule", "nuble"],
     "Estación Central a Chillán (12 comunas)", "ejecucion", "ejecucion", 160, "Inversión: US$ 160 millones", None, "2026-S2",
     "6 trenes bimodales, centro de mantenimiento en Chillán; obras civiles 85% a junio de 2026.",
     "la misma ficha cita también 'MMUSD 130'; se usa el valor rotulado 'Inversión'"),
    ("talca-constitucion", 8291, "Mejoramiento ramal Talca-Constitución", ["maule"], "Talca, Constitución", "ejecucion", "ejecucion", 40,
     "inversión que alcanza los 40 millones de dólares", None, None,
     "Buscarriles nuevos, centro de mantenimiento, rehabilitación de vía y estaciones; marcha blanca desde marzo de 2026.", None),
    ("puente-bio-bio", 8293, "Nuevo puente ferroviario Bío-Bío", ["biobio"], "Concepción, San Pedro de la Paz", "terminado", "terminado", None,
     None, "2022-12", "2025-11", "Viaducto de 1,8 km y túnel de 325 m; segunda fase de puesta en operación en noviembre de 2025.",
     "monto del puente no informado; el Plan Maestro Biobío de EFE suma US$ 3.000 millones (no es el costo del puente)"),
    ("santiago-batuco", 8295, "Tren Santiago-Batuco", ["metropolitana"], "Santiago, Quinta Normal, Renca, Quilicura, Lampa", "ejecucion",
     "ejecucion", 950, "inversión estimada de 950 millones de dólares", None, None,
     "26 km, 8 estaciones, 10 trenes eléctricos; obras superficiales adjudicadas a consorcio CRCC (US$ 470 MM, prensa EFE).", None),
    ("alameda-melipilla", 8297, "Tren Alameda-Melipilla", ["metropolitana"], "Estación Central a Melipilla (8 comunas)", "ejecucion", "ejecucion",
     1877, "inversión estimada de 1.877 millones de dólares", None, "2029-S2",
     "61 km, 11 estaciones; servicio Talagante-Lo Errázuriz en 2028 y hasta Melipilla desde 2S 2029.", None),
    ("puerto-montt-llanquihue", 60132, "Tren Llanquihue-Puerto Montt (30/30)", ["loslagos"], "Llanquihue, Puerto Varas, Puerto Montt",
     "terminado", "terminado", None, None, "2025-04-29", None, "Servicio piloto de 27 km con infraestructura existente, inaugurado el 29-04-2025.", "monto no informado"),
    ("csv-senalizacion", 71667, "Control por Señalización Virtual (CSV) red EFE", ["metropolitana", "biobio", "araucania"], None, "ejecucion",
     "ejecucion", 61, "monto cercano a los US$ 61 MM", "2024-09", "2027-Q2", "Sistema ATP de 1.965 km adjudicado a Alstom; piloto Victoria-Temuco.",
     "alcance nacional; regiones = hitos citados (RM, Biobío, Araucanía)"),
    ("plataforma-ferroportuaria", OTROS, "Plataforma Logística Ferroportuaria / Terminal Intermodal Barrancas", ["valparaiso"], "San Antonio",
     "ejecucion", "ejecucion", 79, "Plataforma Logística Ferroportuaria (US$ 79 MM)", "2024-08", "2026-Q1", "Modernización del Patio Barrancas y desvíos de 600 m.", None),
    ("medio-de-pago", OTROS, "Nuevo medio de pago EFE (tarjeta Conecta)", ["metropolitana", "valparaiso", "biobio"], None, "ejecucion", "ejecucion", 8,
     "Nuevo medio de pago (US$ 8 MM)", None, None, "Modernización del cobro en EFE Valparaíso, Central y Sur.", None),
    ("estacion-valencia", OTROS, "Estación Valencia (Quilpué)", ["valparaiso"], "Quilpué", "terminado", "terminado", 22.6, "Estación Valencia (US$ 22,6 MM)",
     "2023-11", "2026-01", "Inaugurada en enero de 2026.", None),
    ("trenes-rancagua", OTROS, "Trenes de refuerzo servicio Rancagua-Estación Central", ["ohiggins", "metropolitana"], None, "terminado", "terminado", 17.6,
     "Rancagua-Estación Central (US$ 17,6 MM)", "2022-12", "2024-11", "Compra de 3 trenes; en servicio hasta San Fernando desde nov. 2024.", None),
    ("biotren-lota", OTROS, "Extensión Biotren Coronel-Lota", ["biobio"], "Coronel, Lota", "diseno", "diseno", 155, "Extensión de Biotren Coronel-Lota (US$ 155 MM)",
     None, None, "5 nuevas estaciones y 6 trenes; ingeniería de detalle y EIA en curso.", None),
    ("biotren-ampliacion", OTROS, "Ampliación de capacidad Biotren L2 (trenes dobles)", ["biobio"], "Concepción-Coronel", "ejecucion", "ejecucion", 276,
     "Ampliación de Capacidad de Biotren (US$ 276 MM)", "2024-12", "2028", "10 trenes nuevos, andenes y taller en Escuadrón; fase modular 1T 2027.", None),
    ("biotren-trenes-respaldo", OTROS, "Dos trenes de respaldo Biotren", ["biobio"], None, "ejecucion", "ejecucion", 12, "(US$ 12 MM)", "2023", "2025-07",
     "Puesta en servicio prevista julio de 2025.", "puesta en servicio prevista julio de 2025 en la ficha; no se confirmó que ocurriera"),
    ("valparaiso-5-trenes", OTROS, "Ampliación de capacidad EFE Valparaíso (5 trenes)", ["valparaiso"], None, "ejecucion", "ejecucion", 35,
     "Ampliación de capacidad de operaciones EFE Valparaíso (US$ 35 MM)", "2024-12", "2026-S1", "5 trenes nuevos para Limache-Puerto.", None),
    ("locomotoras", OTROS, "Adquisición de 8 locomotoras de mantenimiento", ["metropolitana"], None, "licitacion", "licitacion", 32,
     "Adquisición de 8 locomotoras para tareas de mantenimiento (US$ 32 MM)", None, None, "Licitación de compra desde 08/2024.", "región no informada; se asigna RM por sede de EFE (inferida)"),
    ("temuco-gorbea", OTROS, "Servicio Temuco-Gorbea", ["araucania"], "Temuco, Freire, Gorbea", "ejecucion", "ejecucion", 212, "Servicio Temuco – Gorbea (US$ 212 MM)",
     "2025-12", None, "Rehabilitación de vía, 4 trenes nuevos y 3 paraderos.", None),
    ("biotren-penco", OTROS, "Extensión Biotren a Penco-Lirquén", ["biobio"], "Concepción, Penco", "prefactibilidad", "prefactibilidad", None, None, None, "2037",
     "19,5 km, 7 estaciones; licitación de factibilidad 2S 2026, obras 2035-2037 sujetas a RCA.", "monto no informado; la ficha escribe '2035-3037' (se interpreta 2037)"),
]


def main():
    cache, regs = {}, []
    for clave, pag, nombre, rg, comuna, est, e0311, musd, cita, ini, fin, desc, notas in T:
        if pag not in cache:
            cache[pag] = texto_plano(get_json(U.format(pag))["content"]["rendered"])
        ok = cita is None or cita in cache[pag]
        if cita and not ok:
            print(f"[AVISO] cita no encontrada en {pag}: {cita}")
        regs.append(registro(
            id=f"efe-{clave}", nombre=nombre, sector="ferrocarriles", region_ids=rg, comuna=comuna, estado=est, estado_2026_03_11=e0311,
            inversion_musd=musd if ok else None, fecha_inicio=ini, fecha_fin=fin, mandante="EFE Trenes de Chile", descripcion=desc,
            fuente_url=f"https://www.efe.cl/?page_id={pag}" if pag != OTROS else "https://www.efe.cl/proyectos/otros-desarrollos/",
            fuente="fuentes.json#efe_proyectos", verificado=bool(ok and (musd is not None or cita is None)), notas=notas))
    registrar_fuente("efe_proyectos", "Empresa de los Ferrocarriles del Estado (EFE Trenes de Chile)", "Proyectos del Plan Trenes para Chile y otros desarrollos",
                     "https://www.efe.cl/proyectos/", 180)
    guardar("efe_trenes", regs, {"fuente": "efe_proyectos", "scraper": "tools/proyectos/efe_trenes.py", "fecha_consulta": HOY,
                                 "nota": "Montos en MM US$ citados literalmente en las fichas. Fechas: hitos publicados por EFE."})


if __name__ == "__main__":
    main()
