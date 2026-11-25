extends SceneTree
## Rendimiento de la simulación (equivale a la vara «30 fps»: el motor no debe pesar en un teléfono): un mandato entero y su replay con topes generosos
## (el equipo de CI es lento y variable); las cachés no deben dar resultados viejos al cambiar el gabinete.

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
	var partido := GeneradorPartido.construir_partido("R", "RRR", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, 5, partido)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for _i in range(8):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	Bots.elegir(m, datos, "codicioso", rng)
	var t0 := Time.get_ticks_usec()
	var turnos := 0
	while m.estado.etapa == "gobierno" and turnos < 208:
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
		turnos += 1
	var ms_turno := float(Time.get_ticks_usec() - t0) / 1000.0 / float(maxi(1, turnos))
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(Datos.huella(datos))))
	var t1 := Time.get_ticks_usec()
	var re := Partida.reproducir(datos, g)
	var ms_replay := float(Time.get_ticks_usec() - t1) / 1000.0
	print("%d turnos · %.1f ms por turno · replay %.0f ms" % [turnos, ms_turno, ms_replay])
	_check(re.estado.calcular_huella() == m.estado.calcular_huella(), "el replay con cachés es idéntico")
	_check(ms_turno < 40.0, "un turno de gobierno (con bot) tarda menos de 40 ms (%.1f)" % ms_turno)
	_check(ms_replay < 8000.0, "reproducir un mandato completo tarda menos de 8 s (%.0f)" % ms_replay)
	# caché de categorías activas: cambiar el gabinete debe cambiar el resultado
	var m2 := AyudaV2.gobierno(datos, 9)
	var antes: Array = m2.gabinete.categorias_activas().keys()
	var sin_cambios: Array = m2.gabinete.categorias_activas().keys()
	_check(antes == sin_cambios, "la caché devuelve lo mismo si el gabinete no cambia")
	m2.estado.gabinete.clear()
	var vacio: Array = m2.gabinete.categorias_activas().keys()
	_check(vacio.size() < antes.size(), "al vaciar el gabinete la caché se invalida (%d → %d)" % [antes.size(), vacio.size()])
	print("test_rendimiento: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
