extends SceneTree
## Capturas de pantalla para comparar con la maqueta. Requiere ventana (xvfb) y renderer GL.
## Uso: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/captura.gd -- <carpeta>

var _dir: String = "/tmp"


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_dir = a[0]
	_correr.call_deferred()


func _guardar(nombre: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	root.get_texture().get_image().save_png("%s/%s.png" % [_dir, nombre])
	print("captura ", nombre)


func _correr() -> void:
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await _guardar("01_menu")
	main.mostrar_partido()
	await _guardar("02_test")
	var pp: Node = main._pantalla
	pp._responder(main.datos["ideologia"]["preguntas"][0]["opciones"][1])
	pp._responder(main.datos["ideologia"]["preguntas"][1]["opciones"][0])
	await _guardar("03_test_pregunta3")
	for i in range(2, 8):
		pp._responder(main.datos["ideologia"]["preguntas"][i]["opciones"][1])
	await _guardar("04_fundacion")
	pp._fundar()
	await process_frame
	await _guardar("05_dia_campana")
	var dia: Node = main._pantalla
	dia._on_region("valparaiso")
	dia._jugar()
	await _guardar("06_dia_campana_jugada")
	for s in range(8):
		while not main.motor.estado.mano.is_empty() and main.motor.costo_carta(main.motor.estado.mano[0]) <= main.motor.estado.pa_actual:
			main.motor.jugar_carta(0, "", "metropolitana")
		main.motor.terminar_turno()
	main.motor.resolver_eleccion_presidencial()
	main.motor.iniciar_turno()
	main.mostrar_dia()
	await _guardar("07_dia_gobierno")
	main._pantalla._cola_eventos.clear()
	for c in main._pantalla._capa.get_children():
		if c is ColorRect:
			c.queue_free()
	await _guardar("08_dia_gobierno_limpio")
	main._pantalla._abrir_panel("comite")
	main.motor.estado.propuestas_abiertas.append("prop_metro_suroriente")
	main._pantalla._abrir_panel("comite")
	await _guardar("09_comite")
	main._pantalla._abrir_panel("congreso")
	await _guardar("10_congreso")
	main._pantalla._abrir_panel("gabinete")
	await _guardar("11_gabinete")
	quit(0)
