extends SceneTree
## Cambio de tamaño en caliente (informe, bajo xvfb): plegable que se abre y se cierra, o pantalla dividida de Android, con
## la partida abierta. Asigna root.size (en xvfb sin gestor de ventanas DisplayServer.window_set_size no avisa a Godot)
## y comprueba lienzo, aspecto, mapa > 1/3 y «Terminar semana» dentro. Imprime una línea «PLEG …» por tamaño.
## Uso: xvfb-run -a -s "-screen 0 1400x1400x24" godot --path . --rendering-method gl_compatibility --resolution 280x653 -s tests/ventana_cambio.gd
func _init() -> void:
	_c.call_deferred()
func _c() -> void:
	Tutorial.ruta = "user://pref_pleg.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(d, 23, GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, d["ideologia"]))
	main.mostrar_dia()
	for tam in [Vector2i(280, 653), Vector2i(884, 1104), Vector2i(280, 653), Vector2i(360, 640)]:
		root.size = tam
		for i in range(8):
			await process_frame
		var dia: PantallaDia = main._pantalla
		var vis := root.get_visible_rect().size
		print("PLEG ventana %s -> lienzo %s · aspecto %d · mapa %d (> 1/3: %s) · botón dentro: %s" % [tam, vis, root.content_scale_aspect, dia._mapa.size.y, dia._mapa.size.y > vis.y / 3.0, dia._btn_jugar.get_global_rect().end.y <= vis.y + 0.5])
	quit()
