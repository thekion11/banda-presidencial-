extends SceneTree
## Costo por cuadro de cada transición y animación (informe, no prueba del CI), con animaciones encendidas.
## Uso: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/medir_transiciones.gd
## Mide mientras corre cada animación: llamadas de dibujo (máx.), CPU de preparación del render (medio, ms) y duración
## del cuadro (media y peor, ms). En escritorio con xvfb el rasterizado es por software: la duración del cuadro exagera
## lo que cuesta pintar superficies grandes; las llamadas y la CPU de render sí se trasladan al teléfono.

var _vp: RID


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _muestrear(nombre: String, segundos: float) -> String:
	var llamadas := 0
	var cpu := 0.0
	var peor := 0.0
	var n := 0
	var t0 := Time.get_ticks_usec()
	var antes := t0
	while float(Time.get_ticks_usec() - t0) / 1e6 < segundos:
		await process_frame
		var ahora := Time.get_ticks_usec()
		peor = maxf(peor, float(ahora - antes) / 1000.0)
		antes = ahora
		llamadas = maxi(llamadas, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(_vp)
		n += 1
	var medio := float(Time.get_ticks_usec() - t0) / 1000.0 / float(maxi(1, n))
	return "| %s | %d | %.2f | %.1f | %.1f |" % [nombre, llamadas, cpu / float(maxi(1, n)), medio, peor]


func _limpiar(dia: PantallaDia) -> void:
	for h in dia._capa.get_children():
		if h != dia._toast:
			h.queue_free()
	await _cuadros(3)


func _correr() -> void:
	Movimiento.forzado = 1
	Tutorial.ruta = "user://preferencias_transiciones.json"
	Tutorial.marcar_visto()
	_vp = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp, true)
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(5)
	var filas: Array[String] = []
	filas.append(await _muestrear("menú (motas de fondo)", 1.5))
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("T", "T", "metropolitana", resp, d["ideologia"])
	main.motor = Partida.crear(d, 20260415, partido)
	main.mostrar_dia()
	filas.append(await _muestrear("entrada de la pantalla del día", 1.2))
	var dia: PantallaDia = main._pantalla
	filas.append(await _muestrear("día en reposo (mapa vivo)", 1.5))
	dia._abrir_urbano()
	filas.append(await _muestrear("mapa urbano de Santiago (en reposo)", 1.5))
	await _limpiar(dia)
	dia._on_region("metropolitana")
	dia._sel = 0
	dia._jugar()
	filas.append(await _muestrear("carta que vuela al mapa y reacción", 1.6))
	await _limpiar(dia)
	dia._terminar_turno()
	filas.append(await _muestrear("telón de fin de semana", 3.0))
	await _limpiar(dia)
	var nombres: Dictionary = main.motor.catalogo_leyes["congreso"]["nombres"]
	var votos := {"aprobada": true, "senado": 27, "camara": 96, "min_senado": 26, "min_camara": 78, "total_senado": 50, "total_camara": 155, "abst_senado": 5, "abst_camara": 21, "contra_senado": 18, "contra_camara": 38}
	dia._capa.add_child(OverlaysDia.evento({"titulo": "Ley", "hora": "16:00", "descripcion": "x", "efectos": [{"ind": "capital", "delta": 4}],
		"votacion": {"origen": "senado", "voto": votos, "tc": {"recurso": false, "cae": false}, "aprobada": true}}, func() -> void: pass, nombres, 36))
	filas.append(await _muestrear("votación: hemiciclo y sello", 3.0))
	await _limpiar(dia)
	dia._capa.add_child(OverlaysDia.evento({"titulo": "Debate", "hora": "22:00", "descripcion": "x", "escena": {"nombre": "Debate presidencial final", "ronda": 1, "rondas": 3},
		"opciones": [{"texto": "Una"}, {"texto": "Otra"}]}, func() -> void: pass, nombres, 1, func(_i: int) -> void: pass))
	filas.append(await _muestrear("debate en TV (focos)", 1.5))
	await _limpiar(dia)
	GolpePrensa.mostrar(dia._capa, {"nombre": "Ministra X", "cargo": "Interior"}, [])
	filas.append(await _muestrear("escándalo (titular y temblor)", 2.0))
	await _limpiar(dia)
	CambioMando.mostrar(dia._capa, "11 mar 2026", "T", func() -> void: pass)
	filas.append(await _muestrear("cambio de mando", 2.5))
	await _limpiar(dia)
	dia._mapa.lanzar_fuegos("metropolitana")
	filas.append(await _muestrear("fuegos artificiales en el mapa", 2.0))
	var el: Control = PantallaEleccion.crear(main.motor, d["regiones"], main.motor.estado.aprobacion_regional.duplicate(), {"electo": true, "balotaje": false, "ronda": 1, "voto_final": 57.4, "umbral": 51.0}, func() -> void: pass)
	dia._capa.add_child(el)
	filas.append(await _muestrear("elección ganada (confeti)", 3.0))
	print("| Animación | Llamadas de dibujo (máx.) | CPU de render (ms, medio) | Cuadro (ms, medio) | Cuadro (ms, peor) |")
	print("|---|---|---|---|---|")
	for f in filas:
		print(f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	quit()
