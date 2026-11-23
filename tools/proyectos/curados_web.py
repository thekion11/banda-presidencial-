#!/usr/bin/env python3
"""Proyectos curados desde páginas oficiales accesibles y prensa (MINSAL, PNIP 2055, gobierno 2026, MTT).

Cada fila apunta a su URL; el script descarga la página oficial y comprueba que el texto citado exista ('cita'); si no, verificado=false.
Las filas de prensa (sin página oficial accesible) quedan siempre verificado=false.
Salida: data/proyectos/minsal_oncologico.json, data/proyectos/planes_y_gobierno_2026.json
Uso   : python3 tools/proyectos/curados_web.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import *  # noqa

ONC = "https://www.minsal.cl/ministerio-de-salud-presenta-proyectos-de-inversion-2026-2030-para-fortalecer-la-atencion-oncologica-en-la-red-publica-del-pais/"
# (ciudad, región, tipo, estado, cita)
SITIOS = [
    ("Arica", "arica", "ejecucion", "Arica, Iquique, Calama"), ("Iquique", "tarapaca", "ejecucion", "Arica, Iquique, Calama"),
    ("Calama", "antofagasta", "ejecucion", "Arica, Iquique, Calama"), ("Copiapó", "atacama", "ejecucion", "Copiapó, Valparaíso"),
    ("Valparaíso", "valparaiso", "ejecucion", "Copiapó, Valparaíso"), ("Puente Alto", "metropolitana", "ejecucion", "Puente Alto y Peñalolén"),
    ("Peñalolén", "metropolitana", "ejecucion", "Puente Alto y Peñalolén"), ("Chillán", "nuble", "ejecucion", "Chillán, Concepción, Temuco, Puerto Montt y Coyhaique"),
    ("Concepción", "biobio", "ejecucion", "Chillán, Concepción, Temuco, Puerto Montt y Coyhaique"), ("Temuco", "araucania", "ejecucion", "Chillán, Concepción, Temuco"),
    ("Puerto Montt", "loslagos", "ejecucion", "Puerto Montt y Coyhaique"), ("Coyhaique", "aysen", "ejecucion", "Puerto Montt y Coyhaique"),
    ("Iquique (habilitación)", "tarapaca", "diseno", "habilitación, se trabajará en las comunas de Iquique, Antofagasta"),
    ("Antofagasta", "antofagasta", "diseno", "Iquique, Antofagasta, Viña del Mar"), ("Viña del Mar", "valparaiso", "diseno", "Viña del Mar, San Felipe"),
    ("San Felipe", "valparaiso", "diseno", "San Felipe, Santiago, Independencia"), ("Santiago", "metropolitana", "diseno", "Santiago, Independencia"),
    ("Independencia", "metropolitana", "diseno", "Santiago, Independencia"), ("Rancagua", "ohiggins", "diseno", "Rancagua, Talca"),
    ("Talca", "maule", "diseno", "Rancagua, Talca"), ("Los Ángeles", "biobio", "diseno", "Los Ángeles y Valdivia"), ("Valdivia", "losrios", "diseno", "Los Ángeles y Valdivia"),
    ("Valparaíso (equipamiento)", "valparaiso", "diseno", "Valparaíso y Punta Arenas"), ("Punta Arenas", "magallanes", "diseno", "Valparaíso y Punta Arenas"),
]
PRENSA = "https://www.minsal.cl/comision-de-salud-del-senado-en-los-rios-ministra-aguilera-confirma-que-hospital-de-panguipulli-y-valdivia-estan-en-la-cartera-de-inversion-del-2026/"


def minsal():
    pag = texto_plano(get(ONC))
    regs = []
    for ciudad, rg, est, cita in SITIOS:
        ok = cita in pag
        hab = est == "diseno"
        regs.append(registro(
            id=f"minsal-onco-{slug(ciudad)}", nombre=f"Plan de Inversiones Oncológicas 2026-2030: {'habilitación/equipamiento' if hab else 'centro o unidad oncológica'} {ciudad}",
            sector="salud", region_ids=[rg], comuna=ciudad.split(" (")[0], estado=est, mandante="Ministerio de Salud (Subsecretaría de Redes Asistenciales)",
            descripcion="Proyecto del Plan Nacional de Cáncer presentado el 31-08-2026; la ciudad figura en la lista oficial de " + ("obras en ejecución." if not hab else "habilitación o modernización."),
            fuente_url=ONC, fuente="fuentes.json#minsal_inversiones", verificado=ok and not hab,
            notas="el MINSAL no publica estado ni monto por ciudad; " + ("estado 'ejecucion' según la lista oficial" if not hab else "estado estimado (habilitación posterior a la obra); monto agregado del plan: US$685 MM según Emol 31-08-2026")))
    regs.append(registro(
        id="minsal-hospital-valdivia", nombre="Nuevo Hospital de Valdivia", sector="salud", region_ids=["losrios"], comuna="Valdivia", estado="diseno",
        mandante="Ministerio de Salud", descripcion="Incluido en la cartera de inversión 2026 (ministra Aguilera, 16-10-2025).", fuente_url=PRENSA,
        fuente="fuentes.json#minsal_inversiones", verificado=False, notas="el comunicado dice 'construcción'; etapa exacta no publicada"))
    regs.append(registro(
        id="minsal-hospital-panguipulli", nombre="Nuevo Hospital de Panguipulli", sector="salud", region_ids=["losrios"], comuna="Panguipulli", estado="diseno",
        mandante="Ministerio de Salud", descripcion="Incluido en la cartera de inversión 2026 (ministra Aguilera, 16-10-2025).", fuente_url=PRENSA,
        fuente="fuentes.json#minsal_inversiones", verificado=False, notas="etapa exacta no publicada"))
    registrar_fuente("minsal_inversiones", "Ministerio de Salud (MINSAL)", "Plan de Inversiones Oncológicas 2026-2030 y cartera de inversión hospitalaria",
                     "https://www.minsal.cl/", 180)
    guardar("minsal_oncologico", regs, {"fuente": "minsal_inversiones", "scraper": "tools/proyectos/curados_web.py", "fecha_consulta": HOY,
                                        "nota": "Lista oficial por ciudad; sin montos por proyecto."})


PLANES = [
    ("pnip-2055", "Plan Nacional de Infraestructura Pública 2025-2055 (MOP)", "plan_nacional", [], None, "ejecucion", 366e12, "2025-09", "2055",
     "Más de 22 mil proyectos y más de $366 billones a 30 años; lanzado el 04-09-2025 (cifra de prensa, resumen ejecutivo del MOP).",
     "https://radio.uchile.cl/2025/09/04/el-chile-para-los-proximos-30-anos-gobierno-presenta-plan-nacional-de-infraestructura-publica-2025-2055/", "MOP",
     "plan marco, no un proyecto; la cartera detallada no está en el resumen ejecutivo"),
    ("pnip-2055-rm", "PNIP 2055: cartera Región Metropolitana", "plan_nacional", ["metropolitana"], None, "idea", 41.45e12, "2025-09", "2055",
     "4.210 proyectos y $41,45 billones en la RM (BioBioChile 11-09-2025).",
     "https://www.biobiochile.cl/noticias/nacional/region-metropolitana/2025/09/11/amp/con-una-inversion-de-mas-de-40-billones-en-la-rm-gobierno-presenta-plan-de-infraestructura-a-30-anos.shtml", "MOP",
     "agregado regional; proyectos individuales sin publicar"),
    ("pnip-2055-ohiggins", "PNIP 2055: cartera Región de O'Higgins", "plan_nacional", ["ohiggins"], None, "idea", None, "2025-09", "2055",
     "1.290 proyectos considerados para O'Higgins (Infraestructura Pública).", "https://www.infraestructurapublica.cl/?p=93272", "MOP", "monto no informado en el extracto consultado"),
    ("plan-carcelario-2030", "Plan carcelario 2026-2030: 20 mil nuevas plazas y modernización de recintos", "seguridad", [], None, "idea", None, "2026-03", "2030",
     "El gobierno de Kast fija meta de 20 mil plazas nuevas al 2030; no priorizará cárcel de máxima seguridad (prensa, jul-2026).",
     "https://eldesconcierto.cl/actualidad/el-plan-carcelario-kast-al-2030-fija-meta-20-mil-plazas-nuevas-y-modernizacion-recintos-2-etapas-n5459686", "Ministerio de Justicia / Gendarmería (por confirmar)",
     "ámbito nacional; sin montos; mandante inferido"),
    ("paseo-bandera-corredor", "Paseo Bandera: retorno del transporte público (corredor de buses eléctricos)", "transporte", ["metropolitana"], "Santiago", "ejecucion", None,
     "2026-03", "2026-05", "Inversión Serviu de unos $1.600 millones; operación entre Tarapacá y Catedral desde marzo 2026 y hasta General Mackenna en mayo (no confirmado).",
     "https://www.latercera.com/nacional/noticia/vuelve-el-transporte-publico-al-paseo-bandera-podran-transitar-solo-buses-de-red-movilidad/", "SERVIU Metropolitano / MTT",
     "monto aproximado de prensa ($1.600 millones = inversion_clp 1.6e9); cumplimiento de fechas no confirmado"),
    ("buses-electricos-regiones-2027", "Meta: 1.254 buses eléctricos en regiones al 2027 (MTT)", "transporte", [], None, "ejecucion", None, None, "2027",
     "Anunciado en la cuenta pública del Ministerio de Transportes (prensa).", "https://www.latercera.com/nacional/noticia/de-grange-promete-seguir-impulsando-la-electromovilidad-en-cuenta-publica-del-mtt-y-expertos-cuestionan-sus-anuncios/", "MTT",
     "nacional (regiones distintas de la RM); sin monto"),
    ("nueva-alameda-providencia", "Nueva Alameda Providencia (recortado por MINVU)", "vivienda_urbana", ["metropolitana"], "Santiago", "diseno", None, None, None,
     "Proyecto Plaza Italia-Av. Pajaritos; el MINVU anunció un recorte del programa; GORE y municipalidad siguen con obras puntuales (prensa).",
     "https://www.theclinic.cl/2026/04/07/el-antes-y-despues-del-centro-de-santiago-con-el-proyecto-nueva-alameda-gore-metropolitano-muestra-como-se-veran-diferentes-puntos-con-nuevas-obras/",
     "MINVU / GORE Metropolitano", "estado incierto tras el recorte; sin monto verificado"),
]


def planes():
    regs = []
    for clave, nombre, sector, rg, comuna, est, clp, ini, fin, desc, url, mand, notas in PLANES:
        regs.append(registro(
            id=f"plan-{clave}", nombre=nombre, sector=sector, region_ids=rg, comuna=comuna, estado=est, inversion_clp=clp,
            fecha_inicio=ini, fecha_fin=fin, mandante=mand, descripcion=desc, fuente_url=url, fuente="fuentes.json#planes_prensa_2026",
            verificado=False, notas=notas))
    registrar_fuente("planes_prensa_2026", "Prensa chilena (Radio UChile, BioBioChile, La Tercera, El Desconcierto, The Clinic)",
                     "Planes nacionales y anuncios del gobierno 2026 (PNIP 2055, plan carcelario, transporte)", "https://www.mop.gob.cl/", 180)
    guardar("planes_y_gobierno_2026", regs, {"fuente": "planes_prensa_2026", "scraper": "tools/proyectos/curados_web.py", "fecha_consulta": HOY,
                                             "nota": "Planes marco y anuncios; todo verificado=false (prensa). inversion_clp en pesos."})


if __name__ == "__main__":
    minsal()
    planes()
