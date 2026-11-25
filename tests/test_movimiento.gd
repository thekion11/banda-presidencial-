extends SceneTree
## Sistema de movimiento (dirección visual v4): las animaciones siempre terminan en el estado final exacto, el halo y la
## presión no mueven el botón principal en reposo, y en headless (o con Animaciones apagado) todo queda inmediato.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _esperar(seg: float) -> void:
	await create_timer(seg).timeout
	for i in range(3):
		await process_frame


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	# 1) Modo automático en headless: apagado, y cada pieza deja el valor final al instante.
	_check(not Movimiento.activo(), "en headless el movimiento debe estar apagado (las pruebas miden el estado final)")
	var l := Label.new()
	root.add_child(l)
	Movimiento.contar(l, 57.4, func(x: float) -> String: return "%.1f" % x)
	_check(l.text == "57.4", "contar sin animación debe poner el valor final (%s)" % l.text)
	var pb := ProgressBar.new()
	root.add_child(pb)
	Movimiento.barra(pb, 53.0, 0.0)
	_check(is_equal_approx(pb.value, 53.0), "la barra sin animación debe quedar en su valor")
	var pt := Particulas.new()
	root.add_child(pt)
	_check(not pt.visible and not pt.is_processing(), "las partículas no deben procesar sin animaciones")

	var sello := SelloVoto.crear(false)
	sello.size = Vector2(358, 70)
	root.add_child(sello)
	await process_frame
	var caja: Control = sello.get_child(0)
	_check(is_equal_approx(caja.modulate.a, 1.0) and caja.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(caja.rotation_degrees, SelloVoto.GIRO), "sin animaciones el sello queda visible, a escala 1 y girado")
	var llego := [false]
	var mapa := MapaChile.new()
	root.add_child(mapa)
	var c0 := Control.new()
	root.add_child(c0)
	ManoVuelo.lanzar(c0, {}, mapa, "", Tema.SUBE, func(_p: Vector2) -> void: llego[0] = true)
	_check(llego[0], "sin animaciones el vuelo de la carta avisa la llegada al instante (el número flotante no se pierde)")

	# 2) Forzado encendido: las animaciones corren y terminan exactas.
	Movimiento.forzado = 1
	var b := Barras.boton_jugar()
	b.position = Vector2(74, 710)
	b.size = Vector2(242, 54)
	root.add_child(b)
	var r0 := b.get_global_rect()
	Movimiento.halo(b)
	Movimiento.halo(b)  # idempotente
	_check(b.get_children().filter(func(n: Node) -> bool: return n is Panel).size() == 1, "el halo se agrega una sola vez")
	Movimiento.presion(b)
	b.button_down.emit()
	await _esperar(0.05)
	_check(b.scale.x < 1.0, "al tocar, el botón se hunde (%s)" % b.scale)
	b.button_up.emit()
	await _esperar(0.5)
	_check(b.scale.is_equal_approx(Vector2.ONE), "al soltar, el botón vuelve a escala 1 (%s)" % b.scale)
	_check(b.get_global_rect() == r0, "halo y presión no deben mover el botón principal en reposo (%s vs %s)" % [b.get_global_rect(), r0])
	var l2 := Label.new()
	root.add_child(l2)
	Movimiento.contar(l2, 390.0, func(x: float) -> String: return str(roundi(x)), 0.0, 0.3)
	_check(l2.text == "0", "al empezar a contar muestra el valor inicial (%s)" % l2.text)
	await _esperar(0.5)
	_check(l2.text == "390", "la cifra termina exacta en su valor (%s)" % l2.text)
	var c := Control.new()
	c.size = Vector2(100, 40)
	root.add_child(c)
	Movimiento.aparecer(c, 0.0, 0.2)
	_check(c.modulate.a < 0.5, "aparecer parte transparente")
	await _esperar(0.4)
	_check(is_equal_approx(c.modulate.a, 1.0) and c.scale.is_equal_approx(Vector2.ONE), "aparecer termina opaco y a escala 1 (%s, %s)" % [c.modulate.a, c.scale])
	var sello2 := SelloVoto.crear(true, 0.1)
	sello2.size = Vector2(358, 70)
	root.add_child(sello2)
	await _esperar(0.05)
	var caja2: Control = sello2.get_child(0)
	_check(caja2.scale.x > 1.5, "el sello parte grande antes de caer (%s)" % caja2.scale)
	await _esperar(1.0)
	_check(caja2.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(caja2.rotation_degrees, SelloVoto.GIRO) and is_equal_approx(caja2.modulate.a, 1.0), "el sello termina asentado (%s, %s)" % [caja2.scale, caja2.rotation_degrees])
	var conf := Particulas.new()
	conf.modo = "confeti"
	conf.duracion = 0.2
	conf.cantidad = 10
	root.add_child(conf)
	await _esperar(0.1)
	_check(conf.is_processing(), "el confeti se anima con el movimiento encendido")
	await _esperar(7.8)  # caída máxima ≈ (844 + 253 + 20) / 160 s
	_check(not is_instance_valid(conf), "el confeti se libera solo al terminar")
	Movimiento.forzado = 0
	_check(not Movimiento.activo(), "forzado apagado desactiva el movimiento")
	Movimiento.forzado = -1
	if _fallos == 0:
		print("MOVIMIENTO OK")
	quit(1 if _fallos > 0 else 0)
