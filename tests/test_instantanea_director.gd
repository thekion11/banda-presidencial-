extends SceneTree
## La memoria del director de eventos sobrevive a la instantánea: un motor restaurado en plena partida (con semanas de campaña y de gobierno mezcladas
## en lo ocurrido) sigue idéntico a su gemelo jugado en vivo (indicadores, eventos y RNG). Hallazgo de «Búsqueda»: antes la memoria se inferia del máximo de semanas.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		print("FALLO INSTANTANEA DIRECTOR: ", msg)


func _ganar(datos: Dictionary, semilla: int, rng: RandomNumberGenerator) -> MotorTurno:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Prueba", "PRU", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, semilla, partido)
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "completo", rng)
		m.terminar_turno()
	if not Bots.elegir(m, datos, "completo", rng):
		return null
	return m


func _init() -> void:
	var datos := Datos.cargar_todo()
	var probadas := 0
	for semilla in [500, 9211, 2026, 2027, 2028]:
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var vivo := _ganar(datos, semilla, rng)
		if vivo == null:
			continue
		for _s in range(3):
			Bots.jugar_turno(vivo, "completo", rng)
			vivo.terminar_turno()
		# gemelo restaurado desde la instantánea (con el mismo estado del bot)
		var bytes := Instantanea.tomar(vivo, "h", "s")
		var d := Instantanea.leer(bytes)
		_check(Instantanea.vale_para(d, "h", "s"), "la instantánea es válida (semilla %d)" % semilla)
		var gemelo := Instantanea.restaurar(datos, semilla, d)
		var rng_a := RandomNumberGenerator.new()
		var rng_b := RandomNumberGenerator.new()
		rng_a.seed = semilla * 7 + 1
		rng_b.seed = semilla * 7 + 1
		for sem in range(30):
			if vivo.estado.etapa != "gobierno" or gemelo.estado.etapa != "gobierno":
				break
			Bots.jugar_turno(vivo, "completo", rng_a)
			vivo.terminar_turno()
			Bots.jugar_turno(gemelo, "completo", rng_b)
			gemelo.terminar_turno()
			if JSON.stringify(vivo.estado.indicadores) != JSON.stringify(gemelo.estado.indicadores) or vivo.rng.state != gemelo.rng.state or vivo.estado.eventos_ocurridos.size() != gemelo.estado.eventos_ocurridos.size():
				_check(false, "divergen en la semana %d de gobierno tras restaurar (semilla %d)" % [sem + 1, semilla])
				break
		_check(JSON.stringify(vivo.eventos.director.exportar_memoria()) == JSON.stringify(gemelo.eventos.director.exportar_memoria()) or vivo.estado.etapa != "gobierno", "misma memoria del director (semilla %d)" % semilla)
		probadas += 1
	_check(probadas >= 2, "al menos 2 semillas llegaron a gobierno (%d)" % probadas)
	print("test_instantanea_director: ", "OK (%d semillas)" % probadas if _fallos == 0 else "FALLOS %d" % _fallos)
	quit(1 if _fallos > 0 else 0)
