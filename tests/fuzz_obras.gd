extends SceneTree
## Fuzz del ciclo de vida de las obras (5 fases) a lo largo de carreras completas con acciones aleatorias e inválidas (incluidos «acelerar» y cartas de obra).
## Invariantes: (O1) ids únicos entre obras en curso y terminadas; (O2) en curso: 0 <= dias_avanzados < dias_totales y fase = fase_de(obra) en 1..5 (la fase 5, inauguración, empieza en el 80 % de avance); terminadas:
## dias_avanzados >= dias_totales y fase 5; (O3) retrasos entero >= 0; (O4) el avance de una obra nunca retrocede; (O5) una obra terminada no vuelve a estar en curso;
## (O6) una obra «obra_iniciada» en el registro está en curso o terminada, y una «obra_terminada» tiene su obra en terminadas (mientras el registro y las listas del periodo coinciden);
## (O7) dias_totales >= dias_por_turno (una obra dura al menos una semana).
## Uso: godot --headless --path . -s tests/fuzz_obras.gd -- [partidas] [semilla_inicial]

var _fallos: int = 0
var _datos: Dictionary
var _max_en_curso: int = 0
var _terminadas_vistas: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ OBRAS: ", msg)


func _paso(m: MotorTurno, rng: RandomNumberGenerator) -> void:
	var e := m.estado
	match e.etapa:
		"fin_mandato", "crisis", "derrota_electoral":
			if bool(m.continuar_carrera().get("ok", false)):
				m.iniciar_turno()
		"campana", "gobierno", "oposicion":
			if rng.randf() < 0.7:
				Bots.jugar_turno(m, "codicioso", rng)
			for _a in range(rng.randi_range(0, 6)):
				AyudaFuzz.accion(m, rng)
			if e.eleccion_pendiente(int(_datos["leyes"]["hemiciclo"]["semanas_campana"])):
				Bots.elegir(m, _datos, "codicioso", rng)
			else:
				m.terminar_turno()
		_:
			e.etapa = "fin_mandato"


func _invariantes(m: MotorTurno, ctx: String, previo: Dictionary) -> void:
	var e := m.estado
	var vistos := {}
	for obra in e.obras_en_curso:
		var id := String(obra["id"])
		_check(not vistos.has(id), "%s: id de obra repetido «%s»" % [ctx, id])
		vistos[id] = "curso"
		_check(int(obra["dias_totales"]) >= e.dias_por_turno, "%s: %s dura menos de una semana (%s días)" % [ctx, id, str(obra["dias_totales"])])
		_check(int(obra["dias_avanzados"]) >= 0 and int(obra["dias_avanzados"]) < int(obra["dias_totales"]), "%s: %s en curso con avance %s de %s" % [ctx, id, str(obra["dias_avanzados"]), str(obra["dias_totales"])])
		_check(int(obra["fase"]) >= 1 and int(obra["fase"]) <= 5 and int(obra["fase"]) == MotorObras.fase_de(obra), "%s: %s con fase %s, esperada %d" % [ctx, id, str(obra["fase"]), MotorObras.fase_de(obra)])
		_check(typeof(obra["retrasos"]) == TYPE_INT and int(obra["retrasos"]) >= 0, "%s: %s con retrasos inválidos (%s)" % [ctx, id, str(obra["retrasos"])])
		if previo.has(id):
			_check(int(obra["dias_avanzados"]) >= int(previo[id]), "%s: el avance de %s retrocedió (%s -> %s)" % [ctx, id, str(previo[id]), str(obra["dias_avanzados"])])
	for obra in e.obras_terminadas:
		var id := String(obra["id"])
		_check(vistos.get(id, "") != "curso", "%s: %s está terminada y también en curso" % [ctx, id])
		_check(not vistos.has(id) or vistos[id] != "term", "%s: id de obra terminada repetido «%s»" % [ctx, id])
		vistos[id] = "term"
		_check(int(obra["dias_avanzados"]) >= int(obra["dias_totales"]) and int(obra["fase"]) == 5, "%s: %s terminada con avance %s de %s y fase %s" % [ctx, id, str(obra["dias_avanzados"]), str(obra["dias_totales"]), str(obra["fase"])])
	_max_en_curso = maxi(_max_en_curso, e.obras_en_curso.size())
	_terminadas_vistas = maxi(_terminadas_vistas, e.obras_terminadas.size())
	# registro de acciones: lo iniciado está en curso o terminado; lo terminado está en terminadas
	for a in e.registro_acciones:
		var t := String(a["tipo"])
		if t == "obra_iniciada":
			_check(vistos.has(String(a["detalle"]["obra"])), "%s: la obra iniciada %s no está ni en curso ni terminada" % [ctx, a["detalle"]["obra"]])
		elif t == "obra_terminada":
			_check(vistos.get(String(a["detalle"]["obra"]), "") == "term", "%s: la obra %s figura como terminada en el registro pero no en terminadas" % [ctx, a["detalle"]["obra"]])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 8
	var s0 := int(args[1]) if args.size() > 1 else 2600
	_datos = Datos.cargar_todo()
	for i in range(n):
		var semilla := s0 + i
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla * 29 + 3
		var resp: Array[Dictionary] = []
		for p in _datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rng.randi_range(0, 2)])
		var partido := GeneradorPartido.construir_partido("O", "OOO", "metropolitana", resp, _datos["ideologia"])
		partido["indicadores_iniciales"]["aprobacion"] = 90.0
		var m := Partida.crear(_datos, semilla, partido)
		var ctx := "semilla %d" % semilla
		var previo := {}
		var pasos := 0
		var ciclo := m.estado.ciclo
		while pasos < 500 and m.estado.ciclo < 3:
			pasos += 1
			_paso(m, rng)
			if m.estado.ciclo != ciclo:  # nuevo periodo: las obras del anterior no se comparan
				ciclo = m.estado.ciclo
				previo = {}
			_invariantes(m, "%s paso %d" % [ctx, pasos], previo)
			previo = {}
			for obra in m.estado.obras_en_curso:
				previo[String(obra["id"])] = int(obra["dias_avanzados"])
	print("FUZZ OBRAS %s (%d partidas, máx. %d obras a la vez, hasta %d terminadas, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _max_en_curso, _terminadas_vistas, _fallos])
	quit(1 if _fallos > 0 else 0)
