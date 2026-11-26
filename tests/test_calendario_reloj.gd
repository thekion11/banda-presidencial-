extends SceneTree
## Reloj único desde el ciclo 2: el gobierno empieza en la fecha de la elección (las semanas de campaña ya jugadas cuentan), nunca antes.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Reloj", "REL", "metropolitana", resp, datos["ideologia"])
	var sem := int(datos["leyes"]["hemiciclo"]["semanas_campana"])
	var comprobadas := 0
	for semilla in range(300, 312):
		var m := Partida.crear(datos, semilla, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		for _i in range(sem):  # campaña 1 sin promesas: derrota
			m.terminar_turno()
		m.resolver_eleccion_presidencial()
		if not bool(m.continuar_carrera().get("ok", false)):
			continue
		m.iniciar_turno()
		for _t in range(int(datos["leyes"]["oposicion"]["semanas"])):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		var antes := m.estado.dias_carrera
		for _t in range(sem):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		var dias_periodo := (m.estado.turno_actual - 1) * m.estado.dias_por_turno
		if not Bots.elegir(m, datos, "codicioso", rng) or m.estado.etapa != "gobierno":
			continue
		comprobadas += 1
		var fecha_eleccion := antes + dias_periodo  # días desde el inicio del reloj en el momento de votar
		_check(m.estado.dias_carrera >= fecha_eleccion, "semilla %d: el gobierno parte en %d, antes de la elección (%d)" % [semilla, m.estado.dias_carrera, fecha_eleccion])
		_check(m.estado.dias_carrera == antes + sem * m.estado.dias_por_turno or m.estado.dias_carrera > antes + sem * m.estado.dias_por_turno, "semilla %d: no se sumaron los días de campaña" % semilla)
	_check(comprobadas >= 2, "al menos 2 carreras llegaron al gobierno en ciclo 2 (%d)" % comprobadas)
	print("test_calendario_reloj: ", "OK (%d carreras)" % comprobadas if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
