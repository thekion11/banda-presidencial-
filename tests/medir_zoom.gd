extends SceneTree
## Costo por cuadro mientras se pellizca el mapa de Chile y con el Comité 3D girando (informe de rendimiento, no prueba
## del CI). El informe real del teléfono (V2248, 1080×2388) dio un mínimo de 34 fps; esto mide antes y después de cada
## cambio. En xvfb el rasterizado es por software: valen las diferencias, no los milisegundos absolutos.
## Uso: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/medir_zoom.gd

const CUADROS := 90


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _medir(nombre: String, cada_cuadro: Callable) -> String:
	await _cuadros(10)
	var tiempos: Array[float] = []
	var cpu := 0.0
	var antes := Time.get_ticks_usec()
	for i in range(CUADROS):
		cada_cuadro.call(i)
		await process_frame
		var ahora := Time.get_ticks_usec()
		tiempos.append(float(ahora - antes) / 1000.0)
		antes = ahora
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
	tiempos.sort()
	var suma := 0.0
	for t in tiempos:
		suma += t
	return "| %s | %.1f | %.1f | %.2f |" % [nombre, suma / float(CUADROS), tiempos[int(CUADROS * 0.95)], cpu / float(CUADROS)]


func _correr() -> void:
	Movimiento.forzado = 1
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	Tutorial.ruta = "user://preferencias_zoom.json"
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
	main.mostrar_dia()
	await _cuadros(4)
	var dia: Node = main._pantalla
	for h in dia._capa.get_children():
		if h is Control and h != dia._toast:
			h.queue_free()
	var mapa: MapaChile = dia._mapa
	var filas: Array[String] = []
	filas.append(await _medir("mapa quieto", func(_i: int) -> void: pass))
	var c := mapa.size * 0.5
	filas.append(await _medir("mapa con pellizco (zoom 1 a 3 y vuelta)", func(i: int) -> void:
		mapa._zoom.moviendo = true
		mapa._zoom.acercar_en(1.025 if i < CUADROS / 2 else 1.0 / 1.025, c + Vector2(sin(float(i) * 0.2) * 20.0, 0.0), mapa.size)
		mapa._al_cambiar_vista()))
	mapa._zoom.moviendo = false
	filas.append(await _medir("mapa con arrastre (zoom 3)", func(i: int) -> void:
		mapa._zoom.moviendo = true
		mapa._zoom.pan += Vector2(0.0, 3.0 if (i / 20) % 2 == 0 else -3.0)
		mapa._zoom.limitar(mapa.size)
		mapa._al_cambiar_vista()))
	mapa._zoom.moviendo = false
	dia._abrir_panel("comite")
	await _cuadros(4)
	var b3d: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "3D")
	if not b3d.is_empty():
		b3d[0].pressed.emit()
		await _cuadros(6)
		var c3d: Array = dia._zona_panel.find_children("*", "ComiteMapa3D", true, false)
		filas.append(await _medir("Comité 3D girando (primeros cuadros: MSAA 2×; el vigía lo apaga a los 2 s bajo 45 fps)", func(_i: int) -> void: pass))
		filas.append(await _medir("Comité 3D girando, después del vigía (MSAA %s)" % ("apagado" if VigiaCalidad.sin_msaa else "encendido"), func(_i: int) -> void: pass))
		if not c3d.is_empty():
			var vp: SubViewport = c3d[0]._vp
			var msaa := vp.msaa_3d
			vp.msaa_3d = Viewport.MSAA_DISABLED
			filas.append(await _medir("Comité 3D girando, sin MSAA", func(_i: int) -> void: pass))
			vp.msaa_3d = msaa
	print("| Escena | Cuadro ms (medio) | Cuadro ms (p95) | CPU de render ms |")
	print("|---|---|---|---|")
	for f in filas:
		print(f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	quit()
