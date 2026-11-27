extends SceneTree
## EstadoSimulacion.exportar_json produce el mismo guardado que JSON.stringify(exportar_guardado()) (al parsearlo es idéntico), también al guardar muchas veces seguidas
## mientras el historial crece, y es mucho más barato (se guarda en cada acción del jugador).

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
	var partido := GeneradorPartido.construir_partido("Json", "JSO", "metropolitana", resp, datos["ideologia"])
	var comparadas := 0
	for semilla in range(6):
		var m := Partida.crear(datos, 16000 + semilla, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var e := m.estado
		var guard := 0
		while MotorTurno.ETAPAS_JUEGO.has(e.etapa) and guard < 260:
			guard += 1
			if e.etapa == "campana" and e.eleccion_pendiente(8):
				if not Bots.elegir(m, datos, "completo", rng):
					break
				continue
			Bots.jugar_turno(m, "completo", rng)
			if guard % 7 == 0:  # se guarda cada pocas semanas mientras el historial crece (el cache incremental debe seguir al día)
				var a: Dictionary = JSON.parse_string(e.exportar_json("h%d" % semilla))
				var b: Dictionary = JSON.parse_string(JSON.stringify(e.exportar_guardado("h%d" % semilla)))
				_check(a == b, "semilla %d turno %d: exportar_json difiere de exportar_guardado" % [semilla, e.turno_actual])
				comparadas += 1
			m.terminar_turno()
		var fin: Dictionary = JSON.parse_string(e.exportar_json("final"))
		_check(fin == JSON.parse_string(JSON.stringify(e.exportar_guardado("final"))), "semilla %d: el guardado final coincide" % semilla)
		_check(ValidarGuardado.guardado_valido(fin), "semilla %d: el guardado nuevo pasa la validación" % semilla)
		# un guardado reproducido desde el JSON nuevo da el mismo estado
		var r := Partida.reproducir(datos, fin)
		_check(r != null and r.estado.calcular_huella() == e.calcular_huella(), "semilla %d: reproducir desde exportar_json da la misma huella" % semilla)
	# velocidad: guardar 100 veces con un historial de ~2.000 entradas
	var largo := AyudaTardio.crear(datos, 2026, 170)  # semana 170 con «completo»: ~2.000 entradas
	var t0 := Time.get_ticks_usec()
	for _i in range(100):
		largo.estado.exportar_json("h")
	var nuevo := (Time.get_ticks_usec() - t0) / 100.0 / 1000.0
	var t1 := Time.get_ticks_usec()
	for _i in range(100):
		JSON.stringify(largo.estado.exportar_guardado("h"))
	var viejo := (Time.get_ticks_usec() - t1) / 100.0 / 1000.0
	print("guardar con %d entradas: exportar_json %.2f ms · exportar_guardado + stringify %.2f ms" % [largo.estado.entradas.size(), nuevo, viejo])
	_check(nuevo < viejo / 2.0 and nuevo < 2.0, "exportar_json es al menos 2 veces más rápido y bajo 2 ms (%.2f contra %.2f)" % [nuevo, viejo])
	_check(comparadas >= 20, "se compararon suficientes guardados (%d)" % comparadas)
	print("test_guardado_json: ", "OK (%d comparaciones)" % comparadas if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
