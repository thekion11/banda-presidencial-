extends SceneTree
## Teclado de Android (cola 8): se superpone a la ventana (no la achica) y ocupa cerca del 45 % de abajo. Al enfocar el
## nombre o la sigla del partido, el campo sube por encima del teclado en 390×693 y 390×844, con letra normal y ×1,5;
## y lo escrito se conserva si la ventana cambia de tamaño (pantalla dividida, plegable).

const TECLADO := 0.45

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
	Movimiento.forzado = 0
	for caso in [[693, 0.0], [693, 1.5], [844, 0.0], [844, 1.5]]:
		var alto: int = caso[0]
		root.content_scale_size = Vector2i(390, alto)
		Ajustes.escala_prueba = caso[1]
		var main: Node = load("res://game/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		main.mostrar_partido("propio")
		await process_frame
		var pp: Node = main._pantalla
		for i in range(3):
			pp._responder(main.datos["ideologia"]["preguntas"][i]["opciones"][0])
			await process_frame
		await _cuadros(3)
		var tag := "[%d, letra ×%s]" % [alto, str(caso[1]) if caso[1] > 0.0 else "1"]
		for campo: LineEdit in [pp._nombre, pp._sigla]:
			campo.grab_focus()
			await _cuadros(6)
			_check(campo.get_global_rect().end.y <= alto * (1.0 - TECLADO), "%s el campo «%s» queda bajo el teclado (termina en %d; el teclado empieza en %d)" % [tag, campo.text, campo.get_global_rect().end.y, alto * (1.0 - TECLADO)])
		pp._sigla.text = "PRUEB"
		root.content_scale_size = Vector2i(390, 910 if alto == 693 else 693)  # la ventana cambia de alto con el formulario abierto
		await _cuadros(3)
		_check(main._pantalla == pp and pp._sigla.text == "PRUEB", "%s lo escrito se conserva al cambiar el tamaño de la ventana" % tag)
		main.queue_free()
		await _cuadros(2)
	Ajustes.escala_prueba = 0.0
	root.content_scale_size = Vector2i(390, 844)
	if _fallos == 0:
		print("TECLADO OK")
	quit(1 if _fallos > 0 else 0)
