class_name EstadoSimulacion
extends RefCounted
## Estado puro de la simulación. Sin nodos. Todo es serializable y determinista.

const IND_DEFECTO := {
	"aprobacion": 90.0, "capital": 65.0, "cohesion": 85.0,
	"fiscal": 67.0, "riesgo_ejecucion": 20.0, "viviendas_anio": 55000.0,
	"rival": 45.0  # aprobación del gobierno rival (solo cuenta en oposición)
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
var encuestas: Array[Dictionary] = []  # encuestas semanales de campaña y oposición (sim/encuestas.gd): lo más reciente al final
var apoyo_coalicion: Dictionary = {"senado": 0, "camara": 0}  # escaños aliados que votan con el gobierno
var delegadas_turno: int = 0  # cartas delegadas en el turno (máximo en leyes.json › delegacion)
var internos_actual: int = 0  # movimientos internos disponibles en el turno (solo gobierno)
var balas: Dictionary = {}  # balas de plata usadas: {usadas: {id: [ciclo, turno]}} (sim/motor_balas.gd)

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
var ciclo: int = 1  # periodo de la carrera política (1 = primera campaña; sube cada vez que continúas tras un gobierno o una derrota)
var carrera: Array[Dictionary] = []  # periodos ya cerrados: {ciclo, resultado, puntaje, aprobacion, turnos}
var pendientes: Array[Dictionary] = []  # consecuencias programadas por decisiones: {tipo: efecto|evento, semana, origen, ...}
var ultima_eleccion: Dictionary = {}  # detalle de la última votación presidencial (por región); solo salida, se recalcula al reproducir
var dias_carrera: int = 0  # días jugados en periodos cerrados desde el inicio del mandato (reloj del calendario desde el ciclo 2)


func configurar(p_semilla: int, p_dias_turno: int = 7, p_leyes: Dictionary = {}) -> void:
	## Deja el estado en blanco para una partida nueva con su semilla, días por turno y leyes.
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
	pa_actual = 0  # sin ahorro al empezar: el primer amanecer suma el ingreso de la semana
	gabinete.clear()
	eventos_ocurridos.clear()
	decisiones.clear()
	metas_cumplidas.clear()
	indices_sector.clear()
	asesores.clear()
	bono_mov = {"aprobacion": 0, "asesores": 0}
	coalicion.clear()
	apoyo_coalicion = {"senado": 0, "camara": 0}
	encuestas.clear()
	delegadas_turno = 0
	internos_actual = 0
	balas = {}
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
	if has_meta("json_entradas"):
		remove_meta("json_entradas")
	semanas_en_crisis = 0
	legado_evaluado.clear()
	resultado_final = {}
	ciclo = 1
	carrera.clear()
	dias_carrera = 0
	pendientes.clear()


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
	## Agrega al registro de acciones (para la interfaz y los resúmenes) una acción ya ocurrida; no entra al guardado.
	registro_acciones.append({
		"turno": turno_actual,
		"dia": dia_actual,
		"etapa": etapa,
		"tipo": tipo,
		"detalle": detalle.duplicate(true)
	})


func registrar_entrada(tipo: String, datos: Dictionary) -> void:
	## Agrega al historial del guardado una decisión del jugador (tipo + datos); es lo único que se reproduce al cargar.
	var e: Dictionary = datos.duplicate(true)
	e["tipo"] = tipo
	entradas.append(e)


func ind(nombre: String) -> float:
	## Valor actual de un indicador (aprobación, capital, cohesión, fiscal…); 0 si no existe.
	return float(indicadores.get(nombre, 0.0))


func promesas_pendientes() -> Array[Dictionary]:
	## Promesas de campaña que aún no se cumplen (la meta de legado del gobierno).
	var res: Array[Dictionary] = []
	for p in promesas_campana:
		if not bool(p.get("cumplida", false)):
			res.append(p)
	return res


func eleccion_pendiente(semanas_campana: int) -> bool:
	## true si terminó la campaña (o la segunda vuelta) y toca votar la elección presidencial.
	return etapa == "campana" and turno_actual > semanas_campana + (semanas_balotaje if ronda_electoral == 2 else 0)


func exportar_resumen() -> Dictionary:
	## Resumen legible del estado para la interfaz y los informes (ver ResumenEstado).
	return ResumenEstado.de(self)  # el detalle vive en sim/resumen_estado.gd (este archivo está al límite de líneas)


func calcular_huella() -> String:
	## Huella SHA del estado completo: dos partidas iguales dan la misma huella (pruebas de oro y replay).
	return Huella.sha(exportar_resumen())


func exportar_guardado(huella_datos: String = "") -> Dictionary:
	## Guardado por eventos: semilla, partido, historial de entradas y huella de los datos con que se jugó.
	return {"version": ValidarGuardado.VERSION, "huella_datos": huella_datos, "semilla": semilla, "partido": partido.duplicate(true), "entradas": entradas.duplicate(true)}


func exportar_json(huella_datos: String = "") -> String:
	## Igual que JSON.stringify(exportar_guardado()), pero cada entrada se serializa una sola vez (el juego guarda en cada acción: reescribir ~2.000 entradas costaba ~6 ms).
	var partes: PackedStringArray = get_meta("json_entradas", PackedStringArray())
	if partes.size() > entradas.size():
		partes = PackedStringArray()  # el historial se reinició (periodo nuevo): se rehace
	for i in range(partes.size(), entradas.size()):
		partes.append(JSON.stringify(entradas[i]))
	set_meta("json_entradas", partes)  # en un meta y no en una variable: la instantánea solo guarda variables del script
	return "{\"version\":%d,\"huella_datos\":%s,\"semilla\":%d,\"partido\":%s,\"entradas\":[%s]}" % [ValidarGuardado.VERSION, JSON.stringify(huella_datos), semilla, JSON.stringify(partido), ",".join(partes)]


func _ids_mano() -> Array:
	var ids: Array = []
	for c in mano:
		ids.append(c["id"])
	return ids
