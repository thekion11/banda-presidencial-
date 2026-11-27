#!/usr/bin/env python3
"""Genera las cartas `plan_*` del Plan Estratégico del usuario (27-nov-2026) dentro de data/cartas_curadas.json.
Idempotente: reemplaza las cartas cuyo id empieza por `plan_`. Diseño: docs/PLAN_ESTRATEGICO_CARTAS.md."""
import json
from pathlib import Path

RUTA = Path(__file__).resolve().parent.parent / "data" / "cartas_curadas.json"
FUENTE = "fuentes.json#plan_usuario_2026"
RC, QC, LS = "reforma_constitucional", "quorum_calificado", "ley_simple"


def e(ind, d):
    return {"ind": ind, "delta": d}


def carta(id_, cat, costo, titulo, efectos, ley, sabor, riesgo, diferido):
    return {"id": id_, "categoria": cat, "costo_pa": costo, "titulo": titulo, "efectos": [e(*x) for x in efectos],
            "requisitos": {"ley": ley, "quorum": ley}, "corrector": None, "abre_propuesta_comite": None, "fuente": FUENTE,
            "curada": True, "cifras_ilustrativas": True, "sabor": sabor, "camara_origen": "camara",
            "riesgo": {"prob": riesgo[0], "efectos": [e(*x) for x in riesgo[1]]},
            "diferido": {"semanas": diferido[0], "texto": diferido[1], "efectos": [e(*x) for x in diferido[2]]}}


CARTAS = [
    carta("plan_afp_estatal", "hacienda", 3, "AFP estatal autónoma (reforma constitucional)", [("capital", -4), ("cohesion", -2), ("aprobacion", 1)], RC,
          "Una administradora pública con la autonomía del Banco Central: el Congreso la discute con lupa.",
          (0.45, [("capital", -2), ("aprobacion", -2)]), (52, "La nueva administradora empieza a captar afiliados.", [("aprobacion", 2.5), ("fiscal", 1)])),
    carta("plan_afp_comision", "hacienda", 2, "Comisión de 0,1 % para los fondos de pensiones", [("aprobacion", 3), ("capital", -2), ("fiscal", -1)], LS,
          "Cifra ilustrativa: el mercado cobra entre 0,46 y 1,45 %; la rentabilidad, en cambio, no se promete.",
          (0.40, [("aprobacion", -2), ("fiscal", -2)]), (26, "El sueldo líquido sube; la rentabilidad de los fondos sigue a la bolsa.", [("aprobacion", 2)])),
    carta("plan_fondo_soberano", "hacienda", 2, "Fondo soberano público (modelo Noruega)", [("fiscal", -3), ("capital", -1)], LS,
          "Solo se gasta una parte de la rentabilidad real; el capital base no se toca.",
          (0.35, [("fiscal", -3), ("aprobacion", -1)]), (52, "Si la rentabilidad real acompaña, el Estado se financia sin deuda.", [("fiscal", 6), ("aprobacion", 1)])),
    carta("plan_fondo_regla", "hacienda", 3, "Consejo Fiscal Autónomo con poder vinculante", [("capital", -3), ("cohesion", -2), ("fiscal", 2)], RC,
          "Entregar la última palabra fiscal a un consejo técnico: nadie la suelta sin pelea.",
          (0.40, [("capital", -2), ("riesgo_ejecucion", 2)]), (26, "El gasto sigue la regla y baja el riesgo de ejecución.", [("fiscal", 3), ("riesgo_ejecucion", -2)])),
    carta("plan_refinacion_cobre", "economia", 3, "Refinación limpia de cobre con contratos largos", [("fiscal", -4), ("riesgo_ejecucion", 2), ("aprobacion", 1)], LS,
          "Primero el contrato blindado y la transferencia tecnológica; después, la planta.",
          (0.45, [("fiscal", -2), ("aprobacion", -2)]), (78, "La refinería opera y exporta con valor agregado.", [("aprobacion", 2), ("fiscal", 4)])),
    carta("plan_litio_baterias", "energia", 3, "Litio grado batería en alianza con compradores", [("fiscal", -4), ("riesgo_ejecucion", 2), ("aprobacion", 1)], LS,
          "Del carbonato a la batería: nadie compra el sueño sin contrato.",
          (0.45, [("fiscal", -2), ("capital", -1)]), (78, "La planta de cátodos entrega sus primeras partidas.", [("aprobacion", 2), ("fiscal", 4)])),
    carta("plan_hidrogeno_enap", "energia", 3, "Hidrógeno verde y amoníaco en refinerías de ENAP", [("fiscal", -4), ("riesgo_ejecucion", 2), ("aprobacion", 1)], LS,
          "Reconvertir las refinerías en lugar de cerrarlas.",
          (0.50, [("fiscal", -2), ("aprobacion", -2)]), (78, "Los primeros embarques de amoníaco salen con contrato de compra.", [("aprobacion", 2), ("fiscal", 3)])),
    carta("plan_empresa_ia", "economia", 3, "Empresa estatal de tecnología, IA y automatización", [("fiscal", -3), ("cohesion", -1), ("riesgo_ejecucion", 1)], QC,
          "Menos trámites y menos puestos duplicados, pero el Estado no despide con una sonrisa.",
          (0.40, [("cohesion", -3), ("aprobacion", -2)]), (26, "Las plataformas únicas eliminan trámites y ahorran gasto permanente.", [("fiscal", 3), ("riesgo_ejecucion", -2)])),
    carta("plan_construccion_prefab", "obras", 3, "Empresa estatal de construcción industrializada", [("fiscal", -4), ("viviendas_anio", 4000), ("riesgo_ejecucion", 1)], QC,
          "Módulos de acero y madera contralaminada: la meta es construir en la mitad del tiempo; la promesa de la mitad del costo está por verse.",
          (0.40, [("fiscal", -3), ("riesgo_ejecucion", 2)]), (26, "Las primeras obras modulares se entregan antes de lo habitual.", [("aprobacion", 2), ("riesgo_ejecucion", -2)])),
    carta("plan_coeva", "medioambiente", 3, "Reforma de la evaluación ambiental con plazos fijos", [("capital", -4), ("aprobacion", -1), ("riesgo_ejecucion", 1)], RC,
          "Aprobación en 30 a 60 días hábiles a cambio de cero relaves tradicionales y fiscalización digital abierta.",
          (0.45, [("aprobacion", -2), ("capital", -2)]), (26, "Los proyectos que cumplen el estándar se aprueban sin esperar años.", [("aprobacion", 2), ("riesgo_ejecucion", -3)])),
    carta("plan_desaladoras", "obras", 3, "Plantas desaladoras solares en el norte y el centro", [("fiscal", -5), ("riesgo_ejecucion", 2)], LS,
          "Que el agua de las ciudades y del campo deje de salir de los ríos.",
          (0.40, [("fiscal", -2), ("aprobacion", -2)]), (52, "Las plantas entregan agua y alivian las napas.", [("aprobacion", 3), ("cohesion", 1)])),
    carta("plan_carretera_hidrica", "obras", 3, "Carretera hídrica nacional", [("fiscal", -5), ("riesgo_ejecucion", 3)], LS,
          "Un acueducto de punta a punta: ambicioso, caro y lleno de permisos.",
          (0.50, [("fiscal", -3), ("aprobacion", -2)]), (78, "El agua llega a zonas que dependían de camiones aljibe.", [("aprobacion", 3), ("cohesion", 1)])),
    carta("plan_exportar_agua", "economia", 2, "Exportación de agua dulce certificada desde el sur", [("fiscal", -1), ("aprobacion", -1), ("capital", -1)], LS,
          "Vender el excedente del sur, si es que existe y si alguien lo compra.",
          (0.55, [("aprobacion", -3), ("capital", -2)]), (52, "Si los compradores aparecen, el terminal rinde divisas.", [("fiscal", 3), ("aprobacion", 1)])),
    carta("plan_red_ferroviaria", "transportes", 3, "Red ferroviaria nacional de carga y pasajeros", [("fiscal", -4), ("riesgo_ejecucion", 2), ("aprobacion", 1)], LS,
          "Rieles de Arica a Puerto Montt con bonos respaldados por tarifas.",
          (0.40, [("fiscal", -2), ("aprobacion", -2)]), (78, "Los trenes de carga sacan camiones de la ruta 5.", [("aprobacion", 3), ("fiscal", 2)])),
    carta("plan_megapuertos", "transportes", 3, "Megapuertos automatizados", [("fiscal", -4), ("riesgo_ejecucion", 2)], LS,
          "Grúas sin conductor y filas sin camiones.",
          (0.40, [("fiscal", -2), ("cohesion", -2)]), (52, "El puerto mueve más contenedores con menos tiempo de espera.", [("fiscal", 3), ("aprobacion", 1)])),
    carta("plan_metro_regiones", "transportes", 3, "Nuevas líneas de Metro en Santiago y regiones", [("fiscal", -4), ("riesgo_ejecucion", 2), ("aprobacion", 1)], LS,
          "Bonos de infraestructura respaldados por las tarifas de los pasajeros.",
          (0.40, [("fiscal", -2), ("aprobacion", -2)]), (78, "Las nuevas líneas abren y bajan el tiempo de viaje.", [("aprobacion", 3), ("fiscal", 1)])),
]


def main():
    cartas = json.loads(RUTA.read_text(encoding="utf-8"))
    cartas = [c for c in cartas if not c["id"].startswith("plan_")] + CARTAS
    RUTA.write_text(json.dumps(cartas, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(CARTAS)} cartas plan_* en {RUTA.name} (total {len(cartas)})")


if __name__ == "__main__":
    main()
