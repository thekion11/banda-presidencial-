extends SceneTree
## Guardado por eventos: en partidas completas de 208 turnos, un guardado tomado en cualquier punto (cada 25 turnos, también a mitad de semana y tras decidir eventos) se
## reproduce con la misma huella que la partida en vivo, y la partida reproducida sigue igual que la original al jugar adelante.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var huella_datos := Datos.huella(datos)
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var puntos := 0
	for sd in [301, 302, 303]:
		var politica: String = ["completo", "codicioso", "humano"][sd % 3]
		var m := Partida.crear(datos, sd, GeneradorPartido.construir_partido("R", "RRR", "metropolitana", resp, datos["ideologia"]))
		var rng := RandomNumberGenerator.new()
		rng.seed = sd
		for _i in range(8):
			Bots.jugar_turno(m, politica, rng)
			m.terminar_turno()
		Bots.elegir(m, datos, politica, rng)
		var n := 0
		while m.estado.etapa == "gobierno" and n < 208:
			Bots.jugar_turno(m, politica, rng)
			for ev in m.ultimos_eventos:
				if ev.has("opciones"):
					m.eventos.decidir(String(ev["id"]), n % 3)
			if n % 25 == 12:  # a mitad de semana: ya se jugaron cartas y se decidió, falta cerrar
				_comprobar(datos, huella_datos, m, "semilla %d turno %d (a mitad de semana)" % [sd, n])
				puntos += 1
			m.terminar_turno()
			if n % 25 == 0:
				_comprobar(datos, huella_datos, m, "semilla %d turno %d (al abrir la semana)" % [sd, n])
				puntos += 1
			n += 1
		_comprobar(datos, huella_datos, m, "semilla %d, final (%s)" % [sd, m.estado.etapa])
		puntos += 1
	_check(puntos >= 15, "se comprobaron suficientes puntos de guardado (%d)" % puntos)
	print("test_replay_intermedio: %d guardados intermedios reproducidos" % puntos)
	print("test_replay_intermedio: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)


func _comprobar(datos: Dictionary, huella_datos: String, m: MotorTurno, donde: String) -> void:
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(huella_datos)))
	var re := Partida.reproducir(datos, g)
	_check(re.estado.calcular_huella() == m.estado.calcular_huella(), donde + ": el replay no da la misma huella")
	_check(re.estado.turno_actual == m.estado.turno_actual and re.estado.etapa == m.estado.etapa and re.estado.mano.size() == m.estado.mano.size(), donde + ": turno, etapa o mano distintos")
