#!/usr/bin/env python3
"""Genera data/bcn/reformas_propuestas.json: propuestas constitucionales 2022/2023 y reformas en trámite.

- Convención 2022 y Consejo 2023: resumen por capítulo/artículo según la página de Wikipedia leída
  (fuente secundaria, verificado=false) + resultado del plebiscito (cifras coherentes con la suma de votos).
- Reformas en trámite: proyectos de data/bcn/proyectos_ley.json cuyo título modifica la Constitución
  (WS del Senado/Cámara, fuente primaria). El quórum es el vigente del art. 127 de la CPR (verificado contra el texto).
Uso: python3 tools/reformas_propuestas_build.py
"""
import json
from pathlib import Path
import re
import time

ROOT = Path(__file__).resolve().parents[1]
WP = "https://es.wikipedia.org/wiki/"
Q127 = "4/7 de los diputados y senadores en ejercicio en cada Cámara (CPR art. 127, texto al 7-oct-2025)"
PROPUESTAS = [
    {"id": "convencion_2022", "tipo_reforma": "reemplazo integral de la Constitución (propuesta de la Convención Constitucional)",
     "resultado": "Rechazada en plebiscito de salida el 2022-09-04: Rechazo 61,89 % (7.891.415) / Apruebo 38,11 % (4.859.103)",
     "normas_clave": [
         {"tema": "forma de Estado", "articulos_propuesta": "1 a 16", "resumen": "Estado social, plurinacional y ecológico; territorio único e indivisible; laicidad; reconocimiento de todas las formas de familia"},
         {"tema": "derechos fundamentales", "articulos_propuesta": "17 a 126", "resumen": "Capítulo más extenso; titulares: personas, naciones indígenas y naturaleza; incluye derechos a salud, seguridad social, vivienda, educación, trabajo, cuidados"},
         {"tema": "Congreso", "articulos_propuesta": "251 a 278", "resumen": "Bicameralismo asimétrico: Cámara de las Regiones y Cámara de Diputadas y Diputados; 4 años; una reelección"},
         {"tema": "Presidente", "articulos_propuesta": "279 a 306", "resumen": "Presidencialismo; 4 años con reelección inmediata una sola vez; segunda vuelta si nadie logra mayoría"},
         {"tema": "Estado regional", "articulos_propuesta": "187 a 250", "resumen": "Entidades territoriales autónomas (comunas, provincias, regiones) y autonomías territoriales indígenas"},
         {"tema": "sistemas de justicia", "articulos_propuesta": "307 a 349", "resumen": "Tribunales y sistemas jurídicos de pueblos y naciones indígenas"},
         {"tema": "reforma constitucional", "articulos_propuesta": "383 a 388", "resumen": "Reforma con 4/7 de ambas cámaras; plebiscito si no alcanza 2/3 en materias estructurales; iniciativa popular con 10 % del padrón"}],
     "quorum_necesario_hoy": "Un reemplazo integral exigiría una reforma constitucional con " + Q127 + " que habilite el procedimiento (como la Ley 21.533 usada en 2023)",
     "fuente": "fuentes.json#wikipedia_es", "url": WP + "Propuesta_de_Constitución_Política_de_la_República_de_Chile_de_2022",
     "verificado": False, "nivel_verificacion": "secundaria"},
    {"id": "consejo_2023", "tipo_reforma": "reemplazo integral de la Constitución (propuesta del Consejo Constitucional con Comisión Experta)",
     "resultado": "Rechazada en plebiscito de salida el 2023-12-17: En contra 55,76 % (6.894.287) / A favor 44,24 % (5.470.025)",
     "normas_clave": [
         {"tema": "proceso", "articulos_propuesta": None, "resumen": "Procedimiento de la Ley 21.533 (cap. XV de la CPR): Consejo de 50 miembros paritario (elegido el 2023-05-07) y Comisión Experta de 24; anteproyecto en 14 capítulos entregado el 2023-06-05; texto final aprobado por el Consejo el 2023-10-30"},
         {"tema": "estructura del texto", "articulos_propuesta": None, "resumen": "15 capítulos aprobados por 3/5 de la Comisión (14 permanentes y 1 transitorio), incluyendo Congreso, Gobierno, Corte Constitucional, Contraloría, Banco Central y protección del medio ambiente"}],
     "hueco": "Normas sustantivas del texto final no extraídas: la fuente leída sólo describe el proceso; pendiente leer el texto oficial (procesoconstitucional.cl).",
     "quorum_necesario_hoy": "Igual que arriba: reforma constitucional con " + Q127,
     "fuente": "fuentes.json#wikipedia_es", "url": WP + "Propuesta_de_Constitución_Política_de_la_República_de_Chile_de_2023",
     "verificado": False, "nivel_verificacion": "secundaria"},
]
TIT = re.compile(r"(modifica|reforma|enmienda|sustituye|reemplaza|deroga|incorpora|agrega)[^.]{0,60}(la )?(constituci[oó]n pol[ií]tica|carta fundamental|constituci[oó]n)", re.I)


def main():
    ps = json.loads((ROOT / "data/bcn/proyectos_ley.json").read_text(encoding="utf-8"))["proyectos"]
    tr = []
    for p in ps:
        if TIT.search(p["titulo"][:140]) and p["estado"] in ("En tramitación", "Archivado", "Retirado", "Publicado"):
            m = re.search(r"art[ií]culos? (\d+)", p["titulo"], re.I)
            tr.append({"boletin": p["boletin"], "titulo": p["titulo"], "iniciativa": p["iniciativa"], "fecha_ingreso": p["fecha_ingreso"],
                       "estado": p["estado"], "etapa": p["etapa"], "urgencia_actual": p["urgencia_actual"],
                       "articulo_afectado": int(m.group(1)) if m else None, "quorum_necesario_hoy": Q127,
                       "url_senado": p["url_senado"], "fuente": "fuentes.json#senado_tramitacion", "verificado": True})
    doc = {"fecha_corte": time.strftime("%Y-%m-%d"), "propuestas": PROPUESTAS,
           "reformas_en_tramite": tr,
           "nota": "articulo_afectado se extrae del título cuando lo menciona (de lo contrario null); filtro por título, puede incluir falsos positivos."}
    (ROOT / "data/bcn/reformas_propuestas.json").write_text(json.dumps(doc, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"OK {len(PROPUESTAS)} propuestas, {len(tr)} reformas por título; en tramitación: {sum(1 for r in tr if r['estado']=='En tramitación')}")


if __name__ == "__main__":
    main()
