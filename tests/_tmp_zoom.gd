extends SceneTree
func _init() -> void:
	_c.call_deferred()
func _clic(pos: Vector2, p: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = p
	e.position = pos
	return e
func _c() -> void:
	Tutorial.ruta = "user://pref_zoom.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(d, 23, GeneradorPartido.construir_partido("Z", "Z", "metropolitana", resp, d["ideologia"]))
	main.mostrar_dia()
	for i in range(6):
		await process_frame
	var dia: PantallaDia = main._pantalla
	for t in dia._capa.get_children():
		pass
	dia._toast.visible = false
	var m: MapaChile = dia._mapa
	await process_frame
	root.get_texture().get_image().save_png("/tmp/claude-0/pe/z0.png")
	var c := m.centro("metropolitana")
	for k in range(2):
		m._gui_input(_clic(c, true))
		m._gui_input(_clic(c, false))
		await process_frame
	for i in range(30):
		await process_frame
	print("zoom ", m._zoom.zoom, " pan ", m._zoom.pan, " sel ", m.seleccion)
	root.get_texture().get_image().save_png("/tmp/claude-0/pe/z1.png")
	quit()
