class_name EstadoSimulacion
extends RefCounted
## Estado puro de la simulación. Sin nodos. Todo es serializable y determinista.

const IND_DEFECTO := {
	"aprobacion": 90.0, "capital": 65.0, "cohesion": 85.0,
	"fiscal": 67.0, "riesgo_ejecucion": 20.0, "viviendas_anio": 55000.0
}

var semilla: int = 20260415
var semanas_balotaje: int = 0  # se carga de leyes.json › hemiciclo.semanas_balotaje en configurar()
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

var gabinete: Array[String] = []  # ids de ministros nombrados (data/ministros.json)
var decisiones: Dictionary = {}  # id de evento con opciones -> índice elegido por el jugador (PR-07/PR-08)
var eventos_ocurridos: Dictionary = {}  # id de evento -> turno en que ocurrió (activa cartas con disponibilidad.evento)
var metas_cumplidas: Dictionary = {}  # id de meta interna -> turno (data/metas.json)
var indices_sector: Dictionary = {}  # categoría -> índice sectorial 0..100 (movimiento interno ajustar_sector)
var asesores: Array[String] = []  # ids de asesores contratados (data/asesores.json)
var bono_mov: Dictionary = {"aprobacion": 0, "asesores": 0}  # movimientos extra del turno por aprobación y asesores
var coalicion: Dictionary = {}  # id de partido aliado -> {satisfaccion, ministros[], asesores[]} (data/coalicion.json)
var apoyo_coalicion: Dictionary = {"senado": 0, "camara": 0}  # escaños aliados que votan con el gobierno
var delegadas_turno: int = 0  # cartas delegadas en el turno (máximo en leyes.json › delegacion)
var internos_actual: int = 0  # movimientos internos disponibles en el turno (solo gobierno)

var mazo: Array[String] = []
var descarte: Array[String] = []
var mano: Array[Dictionary] = []
var obras_en_curso: Array[Dictionary] = []
var obras_terminadas: Array[Dictionary] = []
var lineas_jugador: Array[Dictionary] = []  # líneas de Metro creadas por el jugador (se reconstruyen al reproducir el guardado)
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
		semanas_balotaje = int(p_leyes["hemiciclo"].get("semanas_balotaje", 0))
	if p_leyes.has("mano"):
		pa_maximo = int(p_leyes["mano"].get("pa_por_turno", 16))
	pa_actual = pa_maximo
	gabinete.clear()
	eventos_ocurridos.clear()
	decisiones.clear()
	metas_cumplidas.clear()
	indices_sector.clear()
	asesores.clear()
	bono_mov = {"aprobacion": 0, "asesores": 0}
	coalicion.clear()
	apoyo_coalicion = {"senado": 0, "camara": 0}
	delegadas_turno = 0
	internos_actual = 0
	aprobacion_regional.clear()
	aprobacion_base.clear()
	promesas_campana.clear()
	mazo.clear()
	descarte.clear()
	mano.clear()
	obras_en_curso.clear()
	obras_terminadas.clear()
	lineas_jugador.clear()
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


static func normalizar(v: Variant) -> Variant:
	## Redondea a 6 decimales los números del partido: el guardado en JSON los reproduce exactamente (replay idéntico).
	if v is Dictionary:
		var d := {}
		for k in v.keys():
			d[k] = normalizar(v[k])
		return d
	if v is Array:
		return v.map(normalizar)
	if v is float:
		return roundf(v * 1000000.0) / 1000000.0
	return v


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


func eleccion_pendiente(semanas_campana: int) -> bool:
	return etapa == "campana" and turno_actual > semanas_campana + (semanas_balotaje if ronda_electoral == 2 else 0)


func exportar_resumen() -> Dictionary:
	return {
		"semilla": semilla,
		"etapa": etapa,
		"turno_actual": turno_actual,
		"dia_actual": dia_actual,
		"pa_actual": pa_actual,
		"gabinete": gabinete.duplicate(),
		"eventos_ocurridos": eventos_ocurridos.duplicate(),
		"decisiones": decisiones.duplicate(),
		"metas_cumplidas": metas_cumplidas.duplicate(),
		"indices_sector": indices_sector.duplicate(),
		"asesores": asesores.duplicate(),
		"bono_mov": bono_mov.duplicate(),
		"coalicion": coalicion.duplicate(true),
		"apoyo_coalicion": apoyo_coalicion.duplicate(),
		"delegadas_turno": delegadas_turno,
		"internos_actual": internos_actual,
		"indicadores": indicadores.duplicate(true),
		"aprobacion_regional": aprobacion_regional.duplicate(true),
		"partido": partido.duplicate(true),
		"promesas": promesas_campana.duplicate(true),
		"mano": _ids_mano(),
		"mazo": mazo.size(),
		"obras_en_curso": obras_en_curso.duplicate(true),
		"obras_terminadas": obras_terminadas.size(),
		"lineas_jugador": lineas_jugador.duplicate(true),
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
	return Huella.sha(exportar_resumen())


func exportar_guardado(huella_datos: String = "") -> Dictionary:
	## Guardado por eventos: semilla, partido, historial de entradas y huella de los datos con que se jugó.
	return {"version": 2, "huella_datos": huella_datos, "semilla": semilla, "partido": partido.duplicate(true), "entradas": entradas.duplicate(true)}


func _ids_mano() -> Array:
	var ids: Array = []
	for c in mano:
		ids.append(c["id"])
	return ids
