extends SceneTree
## Segundo plano (cola 8, batería): con la app pausada por Android no corre nada (ni el mapa vivo, ni tweens, ni la
## música) y al volver todo sigue desde donde estaba. Se prueba con el movimiento encendido (el caso que consume).

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _correr() -> void:
	Movimiento.forzado = 1
	Tutorial.ruta = "user://preferencias_fondo.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(d, 23, GeneradorPartido.construir_partido("F", "F", "metropolitana", resp, d["ideologia"]))
	main.mostrar_dia()
	await create_timer(0.5).timeout
	var mapa: MapaChile = main._pantalla._mapa as MapaChile
	var t0 := mapa._t
	await create_timer(0.3).timeout
	_check(mapa._t > t0, "en primer plano el mapa vivo avanza")
	main.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await _cuadros(1)
	var t1 := mapa._t
	var tw: Tween = main._pantalla.create_tween()
	var valor := [0.0]
	tw.tween_method(func(x: float) -> void: valor[0] = x, 0.0, 1.0, 0.2)
	await create_timer(0.6).timeout
	_check(is_equal_approx(mapa._t, t1), "en segundo plano el mapa vivo no avanza (%.3f -> %.3f)" % [t1, mapa._t])
	_check(valor[0] == 0.0, "en segundo plano los tweens no avanzan (%.2f)" % valor[0])
	_check(paused, "en segundo plano el árbol está en pausa")
	_check(Musica._a == null or Musica._a.stream_paused, "en segundo plano la música queda en pausa")
	_check(FileAccess.file_exists("user://guardado.json"), "al pasar a segundo plano la partida se guarda")
	main.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await create_timer(0.5).timeout
	_check(not paused and mapa._t > t1 and valor[0] > 0.9, "al volver todo sigue (mapa %.3f, tween %.2f)" % [mapa._t, valor[0]])
	_check(Musica._a == null or not Musica._a.stream_paused, "al volver la música sigue")
	# foco perdido sin ir a segundo plano (llamada encima, cortina de notificaciones): la música se atenúa y vuelve
	main.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(Musica.atenuada and not paused, "sin foco la música baja, pero el juego no se pausa")
	main.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(not Musica.atenuada, "al recuperar el foco la música vuelve a su volumen")
	Movimiento.forzado = -1
	main.queue_free()
	for r in [Tutorial.ruta, "user://guardado.json", "user://guardado.bak", "user://guardado.cache"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	if _fallos == 0:
		print("SEGUNDO PLANO OK")
	quit(1 if _fallos > 0 else 0)
