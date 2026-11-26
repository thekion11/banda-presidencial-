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
	var b0 := Barras.boton_jugar()
	root.add_child(b0)
	ManoVuelo.lanzar(c0, {}, mapa, "", Tema.bien(), func(_p: Vector2) -> void: llego[0] = true)
	_check(llego[0], "sin animaciones el vuelo de la carta avisa la llegada al instante (el número flotante no se pierde)")

	var siguio := [false]
	TelonSemana.mostrar(c0, ["Día 36", ""], ["Día 43", ""], {"aprobacion": 40.0}, {"aprobacion": 43.0}, false, func() -> void: siguio[0] = true)
	_check(siguio[0] and c0.get_children().filter(func(n: Node) -> bool: return n is TelonSemana).is_empty(), "sin animaciones el telón no aparece y los eventos siguen al instante")
	var hem := Hemiciclo.new()
	hem.size = Vector2(358, 230)
	hem.configurar_votos(50, 27, 5, 18)
	root.add_child(hem)
	_check(is_equal_approx(hem.animar_votacion(26, 27), 0.0) and is_equal_approx(hem.progreso, 1.0) and hem._contados() == 27, "sin animaciones el hemiciclo queda lleno y el contador en 27")
	var pas := Control.new()
	root.add_child(pas)
	Movimiento.movimientos(pas, b0, 0, true)
	_check(pas.modulate == Color.WHITE, "sin animaciones la pastilla agotada no cambia de color")

	var asumio := [false]
	CambioMando.mostrar(c0, "11 mar 2026", "MCA", func() -> void: asumio[0] = true)
	_check(asumio[0], "sin animaciones el cambio de mando no retiene el primer día de gobierno")
	var tv := EscenaTV.crear({"nombre": "Debate en radio", "ronda": 2, "rondas": 2})
	c0.add_child(tv)
	_check(not tv.is_processing(), "sin animaciones la escenografía de TV no se anima")
	Musica.etapa("campana")
	Musica.tension(true)
	Musica.tension(false)
	_check(true, "la música no falla en headless")

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
	var hem2 := Hemiciclo.new()
	hem2.size = Vector2(358, 230)
	hem2.configurar_votos(50, 27, 5, 18)
	root.add_child(hem2)
	var dur := hem2.animar_votacion(26, 27)
	_check(dur > 2.0, "una votación ajustada dura más (suspenso): %s s" % dur)
	await _esperar(0.3)
	_check(hem2._contados() < 26, "al empezar, el contador aún no llega al mínimo (%d)" % hem2._contados())
	await _esperar(dur)
	_check(hem2._contados() == 27 and hem2._cruzado, "termina con 27 votos y la línea del mínimo encendida")
	var b1 := Barras.boton_jugar()
	root.add_child(b1)
	Movimiento.halo(b1)
	var pas2 := Control.new()
	root.add_child(pas2)
	Movimiento.movimientos(pas2, b1, 2, false)
	Movimiento.movimientos(pas2, b1, 0, true)
	_check(bool(b1.get_meta("_intenso", false)), "sin movimientos el botón principal se realza")
	await _esperar(0.6)
	_check(pas2.modulate.r < 0.8, "la pastilla agotada se apaga")
	Movimiento.movimientos(pas2, b1, 5, true)
	_check(not bool(b1.get_meta("_intenso", true)), "con movimientos nuevos el realce se apaga")
	var tel := [false]
	TelonSemana.mostrar(c0, ["Día 36", ""], ["Día 43", "Mié 22 abr"], {"aprobacion": 40.0, "capital": 60.0}, {"aprobacion": 43.0, "capital": 58.0}, false, func() -> void: tel[0] = true,
		[{"intencion": 40.0, "margen": 3.0}, {"etapa": "campana", "intencion": 41.5, "margen": 2.8, "umbral": 51.0, "rival": null, "regiones": [{"id": "aysen", "valor": 31.0}]}],
		[{"id": "aysen", "nombre": "Aysén"}])
	await _esperar(0.2)
	var textos: Array = c0.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	_check(textos.any(func(t: String) -> bool: return t.begins_with("ENCUESTA DE LA SEMANA")) and textos.any(func(t: String) -> bool: return "Aysén 31" in t) \
		and textos.any(func(t: String) -> bool: return "umbral 51" in t and "+1,5" in t), "el telón muestra la encuesta: umbral, cambio semanal y región débil (%s)" % str(textos))
	_check(not tel[0] and c0.get_children().any(func(n: Node) -> bool: return n is TelonSemana), "el telón baja y retiene los eventos")
	await _esperar(3.8)  # con encuesta el telón se queda 1 s más
	var c9 := Control.new()
	root.add_child(c9)
	TelonSemana.mostrar(c9, ["Semana 8", ""], ["Semana 9", ""], {}, {}, false, func() -> void: pass,
		[{"etapa": "campana", "turno": 9, "intencion": 50.0, "margen": 1.5, "umbral": 51.0, "rival": null, "regiones": []}], [], 8)
	await _esperar(0.2)
	_check(c9.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text.begins_with("ÚLTIMA ENCUESTA ANTES DE LA ELECCIÓN")), "al cerrar la campaña el telón rotula la última encuesta antes de votar")
	_check(tel[0] and not c0.get_children().any(func(n: Node) -> bool: return n is TelonSemana and not n.is_queued_for_deletion()), "el telón se va solo y deja seguir los eventos")
	var conf := Particulas.new()
	conf.modo = "confeti"
	conf.duracion = 0.2
	conf.cantidad = 10
	root.add_child(conf)
	await _esperar(0.1)
	_check(conf.is_processing(), "el confeti se anima con el movimiento encendido")
	await _esperar(7.8)  # caída máxima ≈ (844 + 253 + 20) / 160 s
	_check(not is_instance_valid(conf), "el confeti se libera solo al terminar")
	var previo := Ajustes.reducir
	Ajustes.reducir = true
	_check(Movimiento.activo() and not Movimiento.intenso(), "«Reducir movimiento» deja las animaciones suaves y quita las intensas")
	var pt2 := Particulas.new()
	root.add_child(pt2)
	_check(not pt2.visible, "con «Reducir movimiento» no hay partículas")
	Ajustes.reducir = previo
	_check(Ajustes.leer("reducir") == previo and Ajustes.leer("musica") == Ajustes.musica, "Ajustes lee música y reducir movimiento")
	var cm := [false]
	CambioMando.mostrar(c0, "11 mar 2026", "MCA", func() -> void: cm[0] = true)
	await _esperar(0.5)
	_check(not cm[0], "el cambio de mando retiene el primer día mientras se ve")
	await _esperar(4.0)
	_check(cm[0], "el cambio de mando se va solo")
	Movimiento.forzado = 0
	_check(not Movimiento.activo(), "forzado apagado desactiva el movimiento")
	Movimiento.forzado = -1
	if _fallos == 0:
		print("MOVIMIENTO OK")
	quit(1 if _fallos > 0 else 0)
