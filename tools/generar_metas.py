#!/usr/bin/env python3
"""Genera data/metas.json: 3 metas internas por categoría de carta (DISENO_V2 §6).

Reproducible: python3 tools/generar_metas.py. Las cifras de efecto son ilustrativas (rotuladas en cada meta).
`desbloquea` se completa con las cartas que declaran `disponibilidad.meta` == id de la meta.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# categoría -> (sector legible, fuente, [(nombre, descripcion, costo_mov, efectos)])
METAS = {
    "vivienda": ("Vivienda", "minvu_2026", [
        ("Catastro de suelo fiscal", "Inventariar terrenos del Estado aptos para vivienda social.", 1, [("capital", 1.0)]),
        ("Mesa de campamentos", "Coordinar a municipios y organizaciones para abordar campamentos.", 2, [("cohesion", 2.0), ("aprobacion", 0.5)]),
        ("Plan de ciudades compactas", "Acuerdo de densificación con gobiernos regionales.", 3, [("viviendas_anio", 3000.0), ("riesgo_ejecucion", 1.0)]),
    ]),
    "energia": ("Energía", "ficticio_2026", [
        ("Hoja de ruta de transmisión", "Cerrar el trazado prioritario de líneas de transmisión.", 1, [("capital", 1.0)]),
        ("Acuerdo con generadoras", "Alinear inversión privada con la meta de descarbonización.", 2, [("fiscal", 1.0), ("riesgo_ejecucion", -1.0)]),
        ("Pacto de almacenamiento", "Marco para baterías y respaldo del sistema eléctrico.", 3, [("aprobacion", 1.0), ("fiscal", 1.5)]),
    ]),
    "hacienda": ("Hacienda", "dipres_2026", [
        ("Revisión del gasto", "Auditoría rápida de programas con baja ejecución.", 1, [("fiscal", 1.5)]),
        ("Regla fiscal reforzada", "Ordenar la trayectoria de deuda con el Consejo Fiscal.", 2, [("fiscal", 2.5), ("capital", -0.5)]),
        ("Acuerdo tributario marco", "Mesa técnica con oposición para ampliar la base.", 3, [("fiscal", 3.0), ("cohesion", -1.0)]),
    ]),
    "salud": ("Salud", "minsal_inversiones", [
        ("Diagnóstico de listas de espera", "Levantar la lista de espera por hospital y especialidad.", 1, [("capital", 1.0)]),
        ("Red integrada de urgencias", "Coordinar SAPU, SAR y hospitales de cada servicio.", 2, [("aprobacion", 1.0), ("riesgo_ejecucion", 1.0)]),
        ("Plan de especialistas", "Convenios de formación y retención de médicos especialistas.", 3, [("aprobacion", 1.5), ("fiscal", -1.0)]),
    ]),
    "seguridad": ("Seguridad", "ficticio_2026", [
        ("Mapa del delito", "Cruzar datos de Carabineros, PDI y Fiscalía por comuna.", 1, [("riesgo_ejecucion", -1.0)]),
        ("Coordinación policial", "Protocolo único entre policías y municipios.", 2, [("aprobacion", 1.0), ("cohesion", 0.5)]),
        ("Plan de control fronterizo", "Despliegue conjunto en pasos no habilitados.", 3, [("aprobacion", 1.5), ("capital", -1.0)]),
    ]),
    "social": ("Desarrollo social", "ficticio_2026", [
        ("Registro social actualizado", "Depurar el Registro Social de Hogares.", 1, [("riesgo_ejecucion", -1.0)]),
        ("Alianza con organizaciones", "Convenio con ONG y juntas de vecinos para entrega de beneficios.", 2, [("cohesion", 2.0)]),
        ("Pacto por la infancia", "Acuerdo transversal de protección de la niñez.", 3, [("aprobacion", 1.5), ("cohesion", 1.5)]),
    ]),
    "politica": ("Política", "ficticio_2026", [
        ("Mesa con los presidentes de partido", "Reunión de coordinación semanal de la coalición.", 1, [("capital", 1.5)]),
        ("Protocolo legislativo", "Acuerdo de prioridades con Senado y Cámara.", 2, [("capital", 1.0), ("cohesion", 1.0)]),
        ("Pacto de gobernabilidad", "Compromiso formal de la coalición ampliada.", 3, [("cohesion", 2.5), ("capital", 1.0)]),
    ]),
    "comite": ("Comité de Planificación", "sectra_planes", [
        ("Cartera priorizada", "Ordenar los proyectos del Plan Maestro por retorno.", 1, [("riesgo_ejecucion", -1.0)]),
        ("Evaluación social de proyectos", "Fortalecer la evaluación previa de obras de transporte.", 2, [("fiscal", 1.0)]),
        ("Banco integrado de proyectos", "Un solo banco de proyectos entre ministerios.", 3, [("riesgo_ejecucion", -2.0), ("capital", 0.5)]),
    ]),
    "educacion": ("Educación", "ficticio_2026", [
        ("Diagnóstico de aprendizajes", "Medición común de aprendizajes por región.", 1, [("capital", 1.0)]),
        ("Plan de asistencia", "Programa contra el ausentismo escolar crónico.", 2, [("aprobacion", 1.0), ("cohesion", 0.5)]),
        ("Carrera docente ampliada", "Acuerdo con gremios sobre carrera y evaluación.", 3, [("cohesion", 1.5), ("fiscal", -1.5)]),
    ]),
    "transportes": ("Transportes", "sectra_planes", [
        ("Catastro de proyectos viales", "Actualizar el catastro de proyectos con SECTRA.", 1, [("capital", 1.0)]),
        ("Plan de buses eléctricos", "Convenio de renovación de flota con operadores.", 2, [("aprobacion", 1.0), ("fiscal", -1.0)]),
        ("Integración tarifaria", "Integrar modos de transporte público en una tarifa.", 3, [("aprobacion", 1.5), ("riesgo_ejecucion", 1.0)]),
    ]),
    "economia": ("Economía", "ficticio_2026", [
        ("Mesa de productividad", "Diálogo con gremios para destrabar inversión.", 1, [("capital", 1.0)]),
        ("Ventanilla única", "Simplificar permisos para pymes.", 2, [("aprobacion", 1.0), ("riesgo_ejecucion", -1.0)]),
        ("Plan de empleo", "Subsidios focalizados al empleo formal.", 3, [("aprobacion", 1.5), ("fiscal", -1.5)]),
    ]),
    "medioambiente": ("Medio ambiente", "ficticio_2026", [
        ("Línea base ambiental", "Levantar información ambiental de zonas prioritarias.", 1, [("capital", 1.0)]),
        ("Agilización de evaluación", "Ordenar los plazos del sistema de evaluación ambiental.", 2, [("riesgo_ejecucion", -1.5)]),
        ("Pacto por la biodiversidad", "Acuerdo de protección de áreas silvestres.", 3, [("aprobacion", 1.0), ("cohesion", 1.0)]),
    ]),
    "descentralizacion": ("Descentralización", "ficticio_2026", [
        ("Convenios con gobernadores", "Convenios de programación con gobiernos regionales.", 1, [("capital", 1.0)]),
        ("Traspaso de competencias", "Cronograma de traspaso de competencias.", 2, [("cohesion", 1.5)]),
        ("Fondo regional de convergencia", "Reglas para el reparto del fondo entre regiones.", 3, [("cohesion", 2.0), ("fiscal", -1.0)]),
    ]),
    "obras": ("Obras públicas", "mop_obras", [
        ("Cartera de obras priorizada", "Ordenar licitaciones por impacto y plazos.", 1, [("riesgo_ejecucion", -1.0)]),
        ("Mesa de inspección fiscal", "Reforzar la inspección de obras en ejecución.", 2, [("riesgo_ejecucion", -2.0)]),
        ("Plan de concesiones", "Calendario de concesiones con participación privada.", 3, [("fiscal", 2.0), ("aprobacion", 0.5)]),
    ]),
    "estado": ("Estado empresario", "cpr_chile_2026", [
        ("Catastro de empresas públicas", "Inventario del patrimonio empresarial del Estado.", 1, [("capital", 1.0)]),
        ("Gobierno corporativo", "Directorios profesionales para empresas estatales.", 2, [("riesgo_ejecucion", -1.5)]),
        ("Política de propiedad estatal", "Criterios públicos para crear, vender o expropiar.", 3, [("capital", 1.5), ("cohesion", 0.5)]),
    ]),
}


def construir() -> list:
    cartas = json.loads((ROOT / "data/cartas.json").read_text(encoding="utf-8"))
    cartas += json.loads((ROOT / "data/cartas_reales.json").read_text(encoding="utf-8"))
    por_meta: dict = {}
    for c in cartas:
        m = (c.get("disponibilidad") or {}).get("meta")
        if m:
            por_meta.setdefault(m, []).append(c["id"])
    metas = []
    for cat, (sector, fuente, items) in METAS.items():
        for i, (nombre, desc, costo, efectos) in enumerate(items, 1):
            mid = f"meta_{cat}_{i}"
            metas.append({
                "id": mid, "nombre": nombre, "sector": cat, "sector_nombre": sector, "descripcion": desc,
                "costo_mov": costo, "requiere": f"meta_{cat}_{i - 1}" if i > 1 else None,
                "desbloquea": sorted(por_meta.get(mid, [])),
                "efectos": [{"ind": k, "delta": v} for k, v in efectos],
                "fuente": f"fuentes.json#{fuente}", "cifras_ilustrativas": True,
            })
    return metas


if __name__ == "__main__":
    metas = construir()
    (ROOT / "data/metas.json").write_text(json.dumps(metas, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"data/metas.json: {len(metas)} metas")
