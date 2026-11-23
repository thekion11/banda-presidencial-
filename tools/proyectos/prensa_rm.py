#!/usr/bin/env python3
"""Proyectos de la Región Metropolitana curados desde prensa y fichas oficiales (SECTRA no publica la cartera RM).

Tabla curada: cada fila lleva URL de la fuente y 'verificado': false (cifras de prensa, no contrastadas con documento oficial).
Salida: data/proyectos/metro_santiago.json
Uso   : python3 tools/proyectos/prensa_rm.py   (las URL se consultaron el 2026-11-23; ver notas por fila)
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import *  # noqa

MEGA = "https://www.meganoticias.cl/nacional/525617-metro-prepara-mayores-expansiones-cuatro-nuevas-lineas-y-una-extension-en-camino-26-062026.html"
DINAMO = "https://www.eldinamo.cl/economia/dinero/2025/05/22/metro-anuncia-plan-de-expansion-de-usd-9-300-millones-para-concretar-las-lineas-7-8-y-9/"
LINEA_A = "https://www.meganoticias.cl/nacional/525530-linea-a-metro-aeropuerto-santiago-detalles-inversion-fecha-2032-26-06-2026.html"
T = [
    ("linea-7", "Nueva Línea 7 Metro de Santiago (Renca-Vitacura)", "Renca, Cerro Navia, Quinta Normal, Santiago, Recoleta, Providencia, Las Condes, Vitacura",
     "ejecucion", "ejecucion", 2700, "2022-02", "2028", "26 km y 19 estaciones; obras iniciadas en febrero de 2022; ~40% de avance (prensa jun-2026).",
     "https://www.metro.cl/nuevos-proyectos/linea-7", "inversión 2.700 (El Dínamo 2025); otras fuentes: 2.528 (2022)"),
    ("linea-8", "Nueva Línea 8 Metro de Santiago (Providencia-Puente Alto)", "Providencia, Ñuñoa, Macul, La Florida, Peñalolén, Puente Alto",
     "ejecucion", None, 2000, None, "2033", "19 km; apertura proyectada 2033 (prensa 2025); obras en inicio según la nota.",
     "https://www.metro.cl/nuevos-proyectos/linea-8", "estado y fecha de inicio de obras no contrastados; inversión de prensa 2025"),
    ("linea-9", "Nueva Línea 9 Metro de Santiago (Recoleta-La Pintana/Bajos de Mena)", "Recoleta, Santiago, San Miguel, San Joaquín, La Granja, San Ramón, La Pintana, Puente Alto",
     "diseno", None, 2733, None, "2033", "27 km en 3 tramos con aperturas previstas 2030, 2031 y 2033; RCA favorable reciente (2026).",
     "https://www.metro.cl/nuevos-proyectos/linea-9", "inversión de prensa 2025; estado = diseño/tramitación ambiental"),
    ("linea-a-aeropuerto", "Línea A Metro de Santiago al Aeropuerto AMB", "Cerro Navia, Pudahuel, Lo Prado", "diseno", None, 365, None, "2032",
     "6,5 km subterráneos, trenes ligeros autónomos, 21 coches; en etapa de ingeniería (jun-2026).", "https://www.metro.cl/nuevos-proyectos/linea-a", "inversión de prensa (Meganoticias 26-06-2026)"),
]


def main():
    regs = []
    for clave, nombre, comuna, est, e0311, musd, ini, fin, desc, oficial, notas in T:
        regs.append(registro(
            id=f"metro-{clave}", nombre=nombre, sector="metro", region_ids=["metropolitana"], comuna=comuna, estado=est, estado_2026_03_11=e0311,
            inversion_musd=musd, fecha_inicio=ini, fecha_fin=fin, mandante="Metro S.A.", descripcion=desc, fuente_url=oficial, fuente="fuentes.json#metro_santiago",
            verificado=False, notas=f"{notas}; fuentes de prensa: {MEGA} | {DINAMO}" + (f" | {LINEA_A}" if "linea-a" in clave else "")))
    registrar_fuente("metro_santiago", "Metro de Santiago y prensa (Meganoticias, El Dínamo, Radio Agricultura)",
                     "Nuevas líneas 7, 8, 9 y A: fichas oficiales y cifras de prensa", "https://www.metro.cl/nuevos-proyectos/linea-7", 180)
    guardar("metro_santiago", regs, {"fuente": "metro_santiago", "scraper": "tools/proyectos/prensa_rm.py", "fecha_consulta": HOY,
                                     "nota": "Montos de prensa, sin contraste con documento oficial (verificado=false)."})


if __name__ == "__main__":
    main()
