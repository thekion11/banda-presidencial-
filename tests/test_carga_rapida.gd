extends SceneTree
## Continuar una partida en la interfaz: con instantánea válida se restaura sin simular; si el guardado cambió después, se reproduce el historial
## (y la instantánea se renueva). En ambos casos el resultado es el mismo estado.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var respaldos := {}
	for n in ["guardado.json", "guardado.cache"]:  # si quien prueba tiene una partida guardada, se respeta
		if FileAccess.file_exists("user://" + n):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + n), ProjectSettings.globalize_path("user://respaldo_prueba_" + n))
			respaldos[n] = true
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var m := Partida.crear(d, 21, GeneradorPartido.construir_partido("C", "CCC", "metropolitana", resp, d["ideologia"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	main.motor = m
	for _i in range(5):
		Bots.jugar_turno(m, "completo", rng)
		m.terminar_turno()
		main.guardar()  # como al cerrar la semana en la interfaz
	_check(FileAccess.file_exists("user://guardado.cache"), "al cerrar la semana se deja la instantánea")
	var huella := m.estado.calcular_huella()
	main.motor = null
	main.continuar_guardado()
	await process_frame
	_check(main.motor != null and main.motor.estado.calcular_huella() == huella, "continuar con instantánea da el mismo estado")
	# jugar después del cierre: el guardado cambia, la instantánea queda vieja y se cae al historial
	Bots.jugar_turno(main.motor, "completo", rng)
	main.guardar()
	var huella2: String = main.motor.estado.calcular_huella()
	main.motor = null
	var cache_vieja := FileAccess.get_sha256("user://guardado.cache")
	main.continuar_guardado()
	await process_frame
	_check(main.motor != null and main.motor.estado.calcular_huella() == huella2, "con la instantánea vieja se reproduce el historial y da el mismo estado")
	_check(FileAccess.get_sha256("user://guardado.cache") != cache_vieja, "tras reproducir se renueva la instantánea")
	# instantánea dañada: se ignora
	var f := FileAccess.open("user://guardado.cache", FileAccess.WRITE)
	f.store_string("basura")
	f.close()
	main.motor = null
	main.continuar_guardado()
	await process_frame
	_check(main.motor != null and main.motor.estado.calcular_huella() == huella2, "una instantánea dañada se ignora")
	# ciclo de vida de Android: pausa a mitad de semana, cierre abrupto y archivo a medio escribir
	main.motor = main.motor if main.motor != null else m
	Bots.jugar_turno(main.motor, "completo", rng)  # cartas jugadas, semana sin cerrar
	main.guardar()
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)  # la app pasa a segundo plano: guardado + instantánea al día
	var huella_pausa: String = main.motor.estado.calcular_huella()
	_check(FileAccess.get_sha256("user://guardado.json") != "", "la pausa deja el guardado")
	main.motor = null  # el sistema mata la app en segundo plano
	main.continuar_guardado()
	await process_frame
	_check(main.motor != null and main.motor.estado.calcular_huella() == huella_pausa, "pausa a mitad de semana y reanudación: mismo estado")
	Bots.jugar_turno(main.motor, "completo", rng)  # sigue jugando y la app se cierra de golpe (sin pausa): solo está el guardado de la última acción
	main.guardar()
	var huella_abrupta: String = main.motor.estado.calcular_huella()
	main.motor = null
	main.continuar_guardado()
	await process_frame
	_check(main.motor != null and main.motor.estado.calcular_huella() == huella_abrupta, "cierre abrupto tras acciones: se recupera hasta la última acción guardada")
	var tmp := FileAccess.open("user://guardado.json.tmp", FileAccess.WRITE)  # escritura interrumpida: queda un .tmp a medias y el guardado anterior intacto
	tmp.store_string("{\"semilla\": 1, \"entradas\": [")
	tmp.close()
	main.motor = null
	main.continuar_guardado()
	await process_frame
	_check(main.motor != null and main.motor.estado.calcular_huella() == huella_abrupta, "un guardado a medio escribir (.tmp) no daña el guardado anterior")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://guardado.json.tmp"))
	for n in ["guardado.json", "guardado.cache"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + n))
		if respaldos.has(n):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://respaldo_prueba_" + n), ProjectSettings.globalize_path("user://" + n))
	print("test_carga_rapida: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
