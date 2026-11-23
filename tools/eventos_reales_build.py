#!/usr/bin/env python3
"""Genera data/eventos_reales.json: línea de tiempo de hechos reales verificables (neutral, sin alias).

Combina (a) eventos derivados de fuentes oficiales ya extraídas (reformas constitucionales del texto oficial,
leyes publicadas según el WS del Senado, resultados del Tricel) y (b) hitos curados a mano, cada uno con la
URL de la página que se leyó. Regla: verificado=true sólo si hay fuente primaria (texto oficial, Tricel, Senado/Cámara);
hitos de una sola fuente secundaria (Wikipedia) quedan verificado=false con nivel_verificacion explícito.
Uso: python3 tools/eventos_reales_build.py
"""
import json
import re
from pathlib import Path
import time

ROOT = Path(__file__).resolve().parents[1]
WP = "https://es.wikipedia.org/wiki/"
ELEC25 = WP + "Elección_presidencial_de_Chile_de_2025"
KAST = WP + "Gobierno_de_José_Antonio_Kast"
BORIC = WP + "Gobierno_de_Gabriel_Boric"
TRICEL = "https://tribunalcalificador.cl/wp-content/uploads/2026/01/Sent-de-proclamacion.pdf"
CPR = "https://www.bcn.cl/leychile/navegar?idNorma=242302"
S = lambda titulo, url: {"titulo": titulo, "url": url}

# (fecha, descripción, categoría, regiones, fuentes, nivel_verificacion)
CURADOS = [
    ("2022-09-04", "Plebiscito de salida sobre la propuesta de la Convención Constitucional: Rechazo 61,89 % (7.891.415 votos) y Apruebo 38,11 % (4.859.103) sobre 12.750.518 votos válidos.", "electoral", ["nacional"], [S("Plebiscito constitucional de Chile de 2022", WP + "Plebiscito_constitucional_de_Chile_de_2022")], "secundaria_coherente"),
    ("2023-12-17", "Plebiscito de salida sobre la propuesta del Consejo Constitucional: En contra 55,76 % (6.894.287 votos) y A favor 44,24 % (5.470.025) sobre 12.364.312 votos válidos.", "electoral", ["nacional"], [S("Plebiscito constitucional de Chile de 2023", WP + "Plebiscito_constitucional_de_Chile_de_2023")], "secundaria_coherente"),
    ("2024-02-09", "Funeral de Estado del expresidente Sebastián Piñera, fallecido en un accidente de helicóptero en el lago Ranco.", "politica", ["nacional", "losrios"], [S("Gobierno de Gabriel Boric", BORIC)], "secundaria"),
    ("2024-02-02", "Incendios forestales en la Región de Valparaíso (febrero de 2024), descritos como el segundo incendio más letal del siglo XXI en Chile. Fecha exacta de inicio sin contrastar.", "desastre_natural", ["valparaiso"], [S("Gobierno de Gabriel Boric (sección incendios)", BORIC)], "secundaria_fecha_aproximada"),
    ("2025-01-29", "La Cámara de Diputados vota el proyecto de reforma de pensiones (boletín 15480-13): 142 a favor, 0 en contra, 5 abstenciones.", "legislativo", ["nacional"], [S("WS Cámara: proyecto 15480-13", "https://opendata.camara.cl/camaradiputados/WServices/WSLegislativo.asmx/retornarProyectoLey?prmNumeroBoletin=15480-13")], "primaria"),
    ("2025-06-29", "Primarias presidenciales: Jeannette Jara se impone con cerca de 60 % de los votos válidos (más de 822 mil) en la primaria oficialista.", "electoral", ["nacional"], [S("Elección presidencial de Chile de 2025", ELEC25)], "secundaria"),
    ("2025-11-16", "Elecciones presidencial y parlamentarias. Primera vuelta: Jara 26,85 %, Kast 23,93 %, Parisi 19,71 %, Kaiser 13,94 %, Matthei 12,47 %; ninguna candidatura supera el 50 %. Se eligen 23 senadores y 155 diputados. Habilitados: 15.779.102 (cifra que también consta en la sentencia del Tricel).", "electoral", ["nacional"], [S("Elección presidencial de Chile de 2025", ELEC25), S("Elecciones parlamentarias de Chile de 2025", WP + "Elecciones_parlamentarias_de_Chile_de_2025"), S("Sentencia de proclamación del Tricel (habilitados)", TRICEL)], "secundaria_coherente"),
    ("2025-12-14", "Segunda votación presidencial: José Antonio Kast 58,17 % (7.263.236 votos) y Jeannette Jara 41,83 % (5.222.558) sobre 12.485.794 votos válidos; votantes 13.434.954. Resultados por región en data/bcn/resultados_2da_vuelta_2025.json.", "electoral", ["nacional"], [S("Sentencia de proclamación del Tricel", TRICEL)], "primaria"),
    ("2025-12-15", "El presidente electo José Antonio Kast se reúne en La Moneda con el presidente Gabriel Boric.", "politica", ["metropolitana"], [S("Gobierno de José Antonio Kast", KAST)], "secundaria"),
    ("2026-01-05", "El Tribunal Calificador de Elecciones proclama oficialmente a José Antonio Kast como presidente electo.", "electoral", ["nacional"], [S("Gobierno de José Antonio Kast", KAST), S("Sentencia de proclamación del Tricel", TRICEL)], "secundaria_coherente"),
    ("2026-03-09", "El ministro de Hacienda Jorge Quiroz anuncia un recorte de 3 % al presupuesto de todos los ministerios, con meta de reducir en USD 6.000 millones el gasto fiscal.", "economia", ["nacional"], [S("Gobierno de José Antonio Kast", KAST)], "secundaria"),
    ("2026-03-11", "Cambio de mando: José Antonio Kast asume la Presidencia en el Salón de Honor del Congreso Nacional (Valparaíso); termina el mandato de Gabriel Boric (2022-2026).", "politica", ["valparaiso", "nacional"], [S("Gobierno de José Antonio Kast", KAST), S("Elección presidencial de Chile de 2025", ELEC25), S("Gobierno de Gabriel Boric", BORIC)], "secundaria_multiple"),
    ("2026-03-23", "Se publica en el Diario Oficial un decreto de Hacienda que modifica el MEPCO (ventana de cálculo del precio de paridad de dos a cuatro semanas), con efecto en precios desde el 26 de marzo; los medios lo llamaron «Bencinazo».", "economia", ["nacional"], [S("Gobierno de José Antonio Kast", KAST)], "secundaria"),
    ("2026-04-17", "El gobierno presenta las principales medidas del «Plan de Reconstrucción Nacional y Desarrollo Económico y Social» (~40 medidas; incluye reducción gradual del impuesto corporativo de 27 % a 23 %). Fecha = día de la referencia citada.", "legislativo", ["nacional"], [S("Gobierno de José Antonio Kast", KAST)], "secundaria_fecha_aproximada"),
    ("2026-04-23", "El Registro Civil precisa el criterio de inscripción de nacimientos de hijos de extranjeros transeúntes o sin residencia legal.", "institucional", ["nacional"], [S("Gobierno de José Antonio Kast", KAST)], "secundaria"),
    ("2026-10-16", "El presidente Kast realiza visita oficial a Bolivia y se reúne con su homólogo Rodrigo Paz, el primer viaje oficial de un mandatario chileno a ese país desde 1955.", "internacional", ["nacional"], [S("Gobierno de José Antonio Kast", KAST)], "secundaria"),
]


def main():
    ev = []
    for fecha, desc, cat, regs, fuentes, nivel in CURADOS:
        ev.append({"fecha": fecha, "descripcion": desc, "categoria": cat, "regiones": regs, "fuentes": fuentes,
                   "nivel_verificacion": nivel, "verificado": nivel == "primaria"})
    refs = json.loads((ROOT / "data/bcn/reformas_constitucionales.json").read_text(encoding="utf-8"))["reformas_en_texto_vigente"]
    for r in refs:
        if r["fecha_publicacion"] and r["fecha_publicacion"] >= "2022-01-01":
            ev.append({"fecha": r["fecha_publicacion"], "categoria": "institucional", "regiones": ["nacional"],
                       "descripcion": f"Se publica la ley de reforma constitucional N° {r['ley']} (consta en las notas del texto oficial de la Constitución).",
                       "fuentes": [S("Constitución, texto actualizado al 7-oct-2025 (BCN)", CPR)], "nivel_verificacion": "primaria", "verificado": True})
    pj = ROOT / "data/bcn/proyectos_ley.json"
    if pj.exists():
        for p in json.loads(pj.read_text(encoding="utf-8"))["proyectos"]:
            mley = re.fullmatch(r"(?:Ley\s*(?:N[º°o]?\s*)?)?(\d{2}\.\d{3})", (p.get("ley_numero") or "").strip())
            ley = mley.group(1) if mley else ""
            if ley and (p.get("diario_oficial") or "") >= "2025-01-01":
                ev.append({"fecha": p["diario_oficial"], "categoria": "legislativo", "regiones": ["nacional"],
                           "descripcion": f"Se publica la Ley N° {ley}: {p['titulo']} (boletín {p['boletin']}).",
                           "fuentes": [S(f"Tramitación Senado, boletín {p['boletin']}", p["url_senado"])],
                           "nivel_verificacion": "primaria", "verificado": True})
    ev.sort(key=lambda e: (e["fecha"], e["descripcion"]))
    for i, e in enumerate(ev, 1):
        e["id"] = f"real_{e['fecha'].replace('-', '')}_{i:03d}"
    doc = {"fecha_corte": time.strftime("%Y-%m-%d"), "aviso": "Hechos públicos, sin alias ni opinión: el juego aplica alias satíricos después. verificado=true sólo con fuente primaria.",
           "huecos": ["IPC, dólar, cobre y TPM: mindicador.cl y las APIs del Banco Central no son accesibles desde el entorno; sin series no se inventan eventos económicos.",
                      "Resultados de primera vuelta por región: no hay fuente primaria transcrita (la tabla secundaria no cuadra).",
                      "Conflictos sociales y desastres naturales 2025-2026: sin fuente consultada."],
           "eventos": ev}
    (ROOT / "data/eventos_reales.json").write_text(json.dumps(doc, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"OK {len(ev)} eventos ({sum(e['verificado'] for e in ev)} verificados con fuente primaria)")


if __name__ == "__main__":
    main()
