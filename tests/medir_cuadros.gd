extends SceneTree
## Costo por cuadro de las escenas pesadas (CLAUDE.md §5: 30 fps estables en la escena urbana 3D). Informe, no prueba del CI.
## Uso: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/medir_cuadros.gd
## En escritorio con xvfb el rasterizado es por software, así que el tiempo total por cuadro no vale para el teléfono.
## Lo que sí se traslada: llamadas de dibujo, primitivas y objetos por cuadro.

const CUADROS := 90


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _medir(nombre: String) -> String:
	await _cuadros(10)  # deja asentar la escena
	var llamadas := 0
	var primitivas := 0
	var objetos := 0
	var peor := 0.0
	var t0 := Time.get_ticks_usec()
	var antes := t0
	for i in range(CUADROS):
		await process_frame
		var ahora := Time.get_ticks_usec()
		peor = maxf(peor, float(ahora - antes) / 1000.0)
		antes = ahora
		llamadas = maxi(llamadas, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		primitivas = maxi(primitivas, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		objetos = maxi(objetos, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
	var medio := float(Time.get_ticks_usec() - t0) / 1000.0 / float(CUADROS)
	return "| %s | %d | %d | %d | %.1f | %.1f |" % [nombre, llamadas, primitivas, objetos, medio, peor]


func _correr() -> void:
	Movimiento.forzado = 1  # con animaciones: es el caso más caro
	Tutorial.ruta = "user://preferencias_cuadros.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(main.datos, 5, GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, main.datos["ideologia"]))
	main.motor.estado.etapa = "gobierno"
	main.motor.estado.propuestas_abiertas.append("prop_metro_suroriente")
	var filas: Array[String] = []
	main.mostrar_dia()
	filas.append(await _medir("día (mapa de Chile y mano)"))
	var dia: Node = main._pantalla
	dia._abrir_urbano()
	filas.append(await _medir("mapa urbano de Santiago"))
	main.mostrar_dia()
	await _cuadros(4)
	dia = main._pantalla
	dia._abrir_panel("comite")
	filas.append(await _medir("Comité 2D"))
	var b3d: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "3D")
	if not b3d.is_empty():
		b3d[0].pressed.emit()
		filas.append(await _medir("Comité 3D (giro automático)"))
	main.mostrar_dia()
	await _cuadros(4)
	dia = main._pantalla
	dia._abrir_hito({"nombre": "Obra", "dias_totales": 400, "dias_avanzados": 200, "retrasos": 0, "carta_id": "", "region": "metropolitana", "efectos_final": []})
	filas.append(await _medir("hito de obra 3D"))
	print("| Escena | Llamadas de dibujo | Primitivas | Objetos | Cuadro ms (medio, software) | Cuadro ms (peor) |")
	print("|---|---|---|---|---|---|")
	for f in filas:
		print(f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	quit()
