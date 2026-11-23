class_name EstadoSimulacion
extends RefCounted
## Estado puro de la simulación. Sin nodos. Todo es serializable y determinista.

const IND_DEFECTO := {
	"aprobacion": 90.0, "capital": 65.0, "cohesion": 85.0,
	"fiscal": 67.0, "riesgo_ejecucion": 20.0, "viviendas_anio": 55000.0
}

var semilla: int = 20260415
var ronda_electoral: int = 1  # 1 = primera vuelta, 2 = segunda vuelta (balotaje)
var etapa: String = "campana"  # campana | gobierno | derrota_electoral | fin_mandato | crisis
var turno_actual: int = 1
var dia_actual: int = 1
var dias_por_turno: int = 7
var duracion_mandato_dias: int = 1460

var pa_actual: int = 16
var pa_maximo: int = 16

var indicadores: Dictionary = IND_DEFECTO.duplicate()
var aprobacion_regional: Dictionary = {}
var aprobacion_base: Dictionary = {}  # base regional del partido (ancla de campaña)

var partido: Dictionary = {}
var promesas_campana: Array[Dictionary] = []

var mazo: Array[String] = []
var descarte: Array[String] = []
var mano: Array[Dictionary] = []
var obras_en_curso: Array[Dictionary] = []
var obras_terminadas: Array[Dictionary] = []
var proyectos_ley: Array[Dictionary] = []
var propuestas_abiertas: Array[String] = []
var sectra: Dictionary = {}  # proyectos del Plan Maestro de SECTRA: id -> {etapa, hasta}
var cartas_ejecutadas: Dictionary = {}  # cartas únicas (ley/obra/propuesta) ya usadas
var propuestas_aprobadas: Array[String] = []
var registro_acciones: Array[Dictionary] = []
var entradas: Array[Dictionary] = []  # decisiones del jugador, para reproducir la partida

var semanas_en_crisis: int = 0
var legado_evaluado: Array[int] = []
var resultado_final: Dictionary = {}


func configurar(p_semilla: int, p_dias_turno: int = 7, p_leyes: Dictionary = {}) -> void:
	semilla = p_semilla
	dias_por_turno = p_dias_turno
	turno_actual = 1
	dia_actual = 1
	etapa = "campana"
	ronda_electoral = 1
	partido = {}
	var ini: Dictionary = IND_DEFECTO.duplicate()
	if p_leyes.has("indicadores_iniciales"):
		ini = Dictionary(p_leyes["indicadores_iniciales"]).duplicate()
	indicadores = ini
	if p_leyes.has("hemiciclo"):
		duracion_mandato_dias = int(p_leyes["hemiciclo"].get("duracion_mandato_dias", 1460))
	if p_leyes.has("mano"):
		pa_maximo = int(p_leyes["mano"].get("pa_por_turno", 16))
	pa_actual = pa_maximo
	aprobacion_regional.clear()
	aprobacion_base.clear()
	promesas_campana.clear()
	mazo.clear()
	descarte.clear()
	mano.clear()
	obras_en_curso.clear()
	obras_terminadas.clear()
	proyectos_ley.clear()
	propuestas_abiertas.clear()
	sectra.clear()
	cartas_ejecutadas.clear()
	propuestas_aprobadas.clear()
	registro_acciones.clear()
	entradas.clear()
	semanas_en_crisis = 0
	legado_evaluado.clear()
	resultado_final = {}


func registrar_accion(tipo: String, detalle: Dictionary) -> void:
	registro_acciones.append({
		"turno": turno_actual,
		"dia": dia_actual,
		"etapa": etapa,
		"tipo": tipo,
		"detalle": detalle.duplicate(true)
	})


func registrar_entrada(tipo: String, datos: Dictionary) -> void:
	var e: Dictionary = datos.duplicate(true)
	e["tipo"] = tipo
	entradas.append(e)


func ind(nombre: String) -> float:
	return float(indicadores.get(nombre, 0.0))


func promesas_pendientes() -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for p in promesas_campana:
		if not bool(p.get("cumplida", false)):
			res.append(p)
	return res


func eleccion_pendiente(semanas_campana: int, semanas_balotaje: int = 4) -> bool:
	return etapa == "campana" and turno_actual > semanas_campana + (semanas_balotaje if ronda_electoral == 2 else 0)


func exportar_resumen() -> Dictionary:
	return {
		"semilla": semilla,
		"etapa": etapa,
		"turno_actual": turno_actual,
		"dia_actual": dia_actual,
		"pa_actual": pa_actual,
		"indicadores": indicadores.duplicate(true),
		"aprobacion_regional": aprobacion_regional.duplicate(true),
		"partido": partido.duplicate(true),
		"promesas": promesas_campana.duplicate(true),
		"mano": _ids_mano(),
		"mazo": mazo.size(),
		"obras_en_curso": obras_en_curso.duplicate(true),
		"obras_terminadas": obras_terminadas.size(),
		"proyectos_ley": proyectos_ley.duplicate(true),
		"cartas_ejecutadas": cartas_ejecutadas.keys(),
		"sectra": sectra.duplicate(true),
		"ronda_electoral": ronda_electoral,
		"propuestas_abiertas": propuestas_abiertas.duplicate(),
		"propuestas_aprobadas": propuestas_aprobadas.duplicate(),
		"total_acciones": registro_acciones.size(),
		"registro": registro_acciones.duplicate(true),
		"resultado_final": resultado_final.duplicate(true),
	}


func calcular_huella() -> String:
	return JSON.stringify(exportar_resumen(), "", true, true).sha256_text()


func exportar_guardado() -> Dictionary:
	## Guardado por eventos: solo semilla, datos del partido e historial de entradas.
	return {"version": 1, "semilla": semilla, "partido": partido.duplicate(true), "entradas": entradas.duplicate(true)}


func _ids_mano() -> Array:
	var ids: Array = []
	for c in mano:
		ids.append(c["id"])
	return ids
