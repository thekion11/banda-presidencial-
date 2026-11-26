extends SceneTree
## Diagnóstico de una partida: dada una semilla y una política de bot imprime la serie semanal en CSV (para analizar balance sin jugar).
## Uso: godot --headless --path . -s tools/informe_partida.gd -- <semilla> <politica> [dificultad] [archivo.csv]
##   politica: pasivo | azar | humano | codicioso | completo | experto   ·   dificultad: facil | normal | dificil
## Columnas: semana, ciclo, etapa, turno, aprobacion, capital, cohesion, fiscal, riesgo_ejecucion, eventos, cartas_jugadas, obras_en_curso, leyes_votadas
## Las líneas CSV empiezan con «CSV,» para filtrarlas del ruido de Godot (grep '^CSV,' | cut -c5-).

const ENCABEZADO := "semana,ciclo,etapa,turno,aprobacion,capital,cohesion,fiscal,riesgo_ejecucion,eventos,cartas_jugadas,obras_en_curso,leyes_votadas"


func _fila(m: MotorTurno, semana: int, eventos: int, cartas: int, leyes: int) -> String:
	var e := m.estado
	return "%d,%d,%s,%d,%.1f,%.1f,%.1f,%.1f,%.1f,%d,%d,%d,%d" % [semana, e.ciclo, e.etapa, e.turno_actual, e.ind("aprobacion"), e.ind("capital"),
			e.ind("cohesion"), e.ind("fiscal"), e.ind("riesgo_ejecucion"), eventos, cartas, e.obras_en_curso.size(), leyes]


func _contar(m: MotorTurno, tipo: String, desde: int) -> int:
	var n := 0
	for i in range(desde, m.estado.registro_acciones.size()):
		if String(m.estado.registro_acciones[i]["tipo"]) == tipo:
			n += 1
	return n


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Uso: -s tools/informe_partida.gd -- <semilla> <politica> [dificultad] [archivo.csv]")
		quit(2)
		return
	var semilla := int(args[0])
	var politica := String(args[1])
	var dificultad := String(args[2]) if args.size() > 2 else ""
	var salida := String(args[3]) if args.size() > 3 else ""
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla * 31 + 7
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][rng.randi_range(0, 2)])
	var partido := GeneradorPartido.construir_partido("Informe", "INF", "metropolitana", resp, datos["ideologia"])
	if dificultad != "":
		partido["dificultad"] = dificultad
	var m := Partida.crear(datos, semilla, partido)
	var filas: Array[String] = [ENCABEZADO]
	var semana := 0
	var guard := 0
	while guard < 800:
		guard += 1
		var e := m.estado
		if e.etapa == "campana" and e.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			var gano := Bots.elegir(m, datos, politica, rng)
			filas.append(_fila(m, semana, 0, 0, 0) + "  # elección: " + ("gana" if gano else "pierde o no continúa"))
			if not gano:
				break
			continue
		if not MotorTurno.ETAPAS_JUEGO.has(e.etapa):
			filas.append(_fila(m, semana, 0, 0, 0) + "  # fin: " + e.etapa)
			break
		semana += 1
		var acciones0 := e.registro_acciones.size()
		var eventos := m.ultimos_eventos.size()
		Bots.jugar_turno(m, politica, rng)
		var cartas := _contar(m, "carta", acciones0)
		m.terminar_turno()
		filas.append(_fila(m, semana, eventos, cartas, _contar(m, "votacion", acciones0)))
	var texto := "\n".join(filas)
	for f in filas:
		print("CSV,", f)
	if salida != "":
		var fa := FileAccess.open(salida, FileAccess.WRITE)
		if fa != null:
			fa.store_string(texto.replace("  # ", ",#") + "\n")
	quit()
