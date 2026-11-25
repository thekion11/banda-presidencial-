extends SceneTree
## Recorrido grabable de la dirección visual v4 (menú, afiliación, test, día con cartas, paneles, votación,
## elección y fin). Pensado para el modo Movie Maker de Godot, que graba cada cuadro a ritmo fijo.
## Movie Maker graba al tamaño de ventana del proyecto (390×844); para 2× crea antes un override.cfg temporal
## en la raíz (no se sube) con [display] window/size/window_width_override=780 y window_height_override=1688:
##   xvfb-run -a -s "-screen 0 1000x1800x24" godot --path . --rendering-method gl_compatibility \
##     --write-movie /tmp/video/cuadro.png --fixed-fps 30 -s tests/grabar_video.gd
##   ffmpeg -framerate 30 -i /tmp/video/cuadro%08d.png -i /tmp/video/cuadro.wav -c:v libx264 -pix_fmt yuv420p video.mp4
## Dibuja un anillo donde «toca el dedo» para que el video se lea como una partida real. No cambia nada del juego.

var _dedo: Control
var _toques: Array[Dictionary] = []  # {pos, t, trazo}


func _init() -> void:
	_correr.call_deferred()


func _esperar(seg: float) -> void:
	await create_timer(seg).timeout


func _poner_dedo() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 120
	root.add_child(capa)
	_dedo = Control.new()
	_dedo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dedo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_dedo)
	_dedo.draw.connect(func() -> void:
		for t in _toques:
			var k := clampf(float(t["t"]) / 0.55, 0.0, 1.0)
			var a := 1.0 - k
			var p: Vector2 = t["pos"]
			if t.has("hasta"):  # deslizar: estela del dedo
				p = (t["pos"] as Vector2).lerp(t["hasta"], clampf(float(t["t"]) / 0.4, 0.0, 1.0))
				_dedo.draw_line(t["pos"], p, Color(Tema.CREMA, 0.35 * a), 6.0, true)
			_dedo.draw_circle(p, 16.0, Color(Tema.CREMA, 0.35 * a))
			_dedo.draw_arc(p, 16.0 + 18.0 * k, 0.0, TAU, 40, Color(Tema.ORO, 0.9 * a), 2.5, true))


func _process_dedo(delta: float) -> void:
	for t in _toques:
		t["t"] = float(t["t"]) + delta
	_toques = _toques.filter(func(t: Dictionary) -> bool: return float(t["t"]) < 0.7)
	_dedo.queue_redraw()


func _centro(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


func _tocar_en(pos: Vector2) -> void:
	_toques.append({"pos": pos, "t": 0.0})
	await _esperar(0.12)


func _tocar(b: BaseButton) -> void:
	## Toque visible + la presión del botón (se hunde y rebota) + su acción.
	if b == null:
		push_warning("grabar_video: botón no encontrado")
		return
	_toques.append({"pos": _centro(b), "t": 0.0})
	b.button_down.emit()
	await _esperar(0.14)
	b.button_up.emit()
	b.pressed.emit()


func _deslizar(desde: Vector2, hasta: Vector2) -> void:
	_toques.append({"pos": desde, "hasta": hasta, "t": 0.0})
	await _esperar(0.4)


func _boton(n: Node, filtro: Callable) -> Button:
	for b in n.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and filtro.call(b):
			return b
	return null


func _correr() -> void:
	Ajustes.animaciones = true
	Ajustes.sonido = true
	Ajustes.vibracion = false
	Tutorial.ruta = "user://preferencias_video.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	_poner_dedo()
	create_timer(100.0).timeout.connect(quit)  # tope de seguridad: el video nunca pasa de 100 s
	process_frame.connect(func() -> void: _process_dedo(1.0 / 30.0))
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var d: Dictionary = main.datos

	# 1) Menú: entrada escalonada, cinta tricolor, motas y halo.
	await _esperar(3.6)
	await _tocar(_boton(main._pantalla, func(b: Button) -> bool: return b.text == "Nueva partida"))
	await _esperar(2.4)

	# 2) Afiliación y test ideológico.
	await _tocar(_boton(main._pantalla, func(b: Button) -> bool: return "\n" in b.text))
	await _esperar(2.2)
	for i in range(2):
		await _tocar(_boton(main._pantalla, func(b: Button) -> bool: return b.text == "" and b.custom_minimum_size.y >= 62.0))  # opción A del test
		await _esperar(1.8)

	# 3) Día: transición, tutorial, cartas, jugar deslizando.
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Movimiento Cívico Austral", "MCA", "metropolitana", resp, d["ideologia"])
	main.motor = Partida.crear(d, 20260415, partido)
	main.mostrar_dia()
	await _esperar(1.8)
	var dia: Node = main._pantalla
	var tuts: Array = dia._capa.find_children("*", "Tutorial", true, false)
	if not tuts.is_empty():
		await _tocar(_boton(tuts[0], func(b: Button) -> bool: return b.text == "Siguiente"))
		await _esperar(1.6)
		tuts[0]._cerrar()
		await _esperar(0.6)
	await _tocar_en(Vector2(120, 290))
	dia._on_region("metropolitana")
	await _esperar(1.0)
	for i in [1, 3, 2]:
		var cartas: Array = dia._mano.get_children()
		await _tocar_en(Vector2(dia._mano.get_global_rect().position.x + 60.0 + 72.0 * i, dia._mano.get_global_rect().position.y + 100.0))
		dia._on_carta(i)
		await _esperar(1.0)
	for vez in range(2):
		var r: Rect2 = dia._mano.get_global_rect()
		await _deslizar(Vector2(r.get_center().x, r.position.y + 110.0), Vector2(r.get_center().x, r.position.y - 120.0))
		dia._jugar()
		await _esperar(2.4)
		if vez == 0:
			await _tocar_en(Vector2(dia._mano.get_global_rect().position.x + 280.0, dia._mano.get_global_rect().position.y + 100.0))
			dia._on_carta(maxi(0, dia.motor.estado.mano.size() - 1))
			await _esperar(1.2)

	# 4) Paneles de la barra inferior.
	var nav: Array = dia._nav.find_children("*", "Button", true, false)
	for idx in [2, 3, 0]:
		nav = dia._nav.find_children("*", "Button", true, false)
		await _tocar(nav[idx])
		await _esperar(2.6 if idx != 0 else 1.2)

	# 5) Terminar la semana: chips que cuentan y mano nueva.
	await _tocar(dia._btn_jugar)
	await _esperar(0.5)
	await _tocar(dia._btn_jugar)
	await _esperar(2.4)
	for h in dia._capa.get_children():  # eventos de la semana nueva fuera, para seguir el recorrido
		if h is Control and h != dia._toast and not (h is Tutorial):
			h.queue_free()
	await _esperar(1.2)

	# 6) Votación en el Senado.
	var ev := {"titulo": "Ley de quórum calificado de energía", "hora": "16:00", "descripcion": "Requiere 26 votos de 50 senadores", "efectos": [{"ind": "capital", "delta": 4}, {"ind": "cohesion", "delta": 2}, {"ind": "fiscal", "delta": -2}],
		"votacion": {"origen": "senado", "voto": {"aprobada": true, "senado": 29, "camara": 96, "min_senado": 26, "min_camara": 78, "total_senado": 50, "total_camara": 155, "abst_senado": 7, "abst_camara": 21, "contra_senado": 14, "contra_camara": 38}, "tc": {"recurso": true, "cae": false}, "aprobada": true}}
	dia._capa.add_child(OverlaysDia.evento(ev, func() -> void: pass, main.motor.catalogo_leyes["congreso"]["nombres"], 36))
	await _esperar(4.2)
	var bs: Array = dia._capa.find_children("*", "Button", true, false)
	await _tocar(bs[bs.size() - 1])
	await _esperar(3.4)
	for h in dia._capa.get_children():
		if h is Control and h != dia._toast:
			h.queue_free()

	# 7) Resultado de la elección: cifra que cuenta, barra que se llena, confeti.
	var regional: Dictionary = main.motor.estado.aprobacion_regional.duplicate()
	var el: Control = PantallaEleccion.crear(main.motor, d["regiones"], regional, {"electo": true, "balotaje": false, "ronda": 1, "voto_final": 57.4, "umbral": 51.0}, func() -> void: pass)
	el.modulate.a = 0.0
	dia._capa.add_child(el)
	el.create_tween().tween_property(el, "modulate:a", 1.0, 0.3)
	await _esperar(5.2)
	await _tocar(_boton(el, func(b: Button) -> bool: return b.text == "Asumir el gobierno"))
	await _esperar(0.3)
	if is_instance_valid(el):
		el.queue_free()

	# 8) Fin del mandato y vuelta al menú.
	var n := 0
	for e in main.motor.catalogo_eventos:
		if e.get("meta", {}).has("fecha_real") and n < 6:
			main.motor.estado.eventos_ocurridos[String(e["id"])] = 2
			n += 1
	main.motor.mandato.finalizar("fin_mandato")
	main.mostrar_fin()
	await _esperar(4.2)
	await _tocar(_boton(main._pantalla, func(b: Button) -> bool: return b.text == "Volver al inicio"))
	await _esperar(3.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	quit()
