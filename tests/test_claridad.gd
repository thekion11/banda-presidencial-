extends SceneTree
## Mejoras de claridad del video de prueba (docs/VIDEO_1.md): P4 créditos sin tapar el título, P5/P6 brújula del
## perfil en el test, P9 tutorial con foco, P10 ficha ampliada con pulsación larga (sin jugar la carta) y P11
## eventos sin el título repetido. Solo interfaz: no cambia el motor.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _esperar(seg: float) -> void:
	await create_timer(seg).timeout
	for i in range(2):
		await process_frame


func _raton(pos: Vector2, presionado: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = presionado
	ev.position = pos
	ev.global_position = pos
	root.push_input(ev, true)
	var mv := InputEventMouseMotion.new()  # mantiene la posición del puntero para get_mouse_position()
	mv.position = pos
	mv.global_position = pos
	root.push_input(mv, true)


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	Tutorial.ruta = "user://preferencias_claridad.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	# P11: la descripción no repite el título.
	_check(OverlaysDia.descripcion_limpia("Se publica la Ley N° 21.810", "Se publica la Ley N° 21.810: modifica la Carta Fundamental") == "Modifica la Carta Fundamental",
		"P11: la descripción del evento no debe repetir el título")
	_check(OverlaysDia.descripcion_limpia("Paro portuario", "Los trabajadores paralizan") == "Los trabajadores paralizan", "P11: una descripción sin el título queda igual")
	# Daltonismo: «bien / mal» dejan el par verde-coral por azul-naranja, con contraste ≥ 4,5:1 sobre el océano.
	var previo := Ajustes.daltonico
	Ajustes.daltonico = true
	_check(Tema.bien() != Tema.SUBE and Tema.mal() != Tema.BAJA and absf(Tema.bien().h - Tema.mal().h) > 0.25, "daltonismo: subir y bajar usan azul y naranja")
	for c: Color in [Tema.bien(), Tema.mal()]:  # contraste WCAG: luminancia relativa con el color linealizado
		var l1: float = c.srgb_to_linear().get_luminance()
		var l2: float = Tema.OCEANO.srgb_to_linear().get_luminance()
		_check((l1 + 0.05) / (l2 + 0.05) >= 4.5, "daltonismo: contraste suficiente sobre el océano (%s)" % c)
	Ajustes.daltonico = previo
	_check(Tema.bien() == Tema.SUBE and Tema.mal() == Tema.BAJA, "sin daltonismo se mantiene la paleta congelada")
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var d: Dictionary = main.datos
	# P4: créditos como hoja inferior, el título sigue visible.
	main.mostrar_menu()
	await process_frame
	main._pantalla._mostrar_creditos()
	await process_frame
	var cr: Control = main._pantalla._creditos
	_check(cr != null and cr.get_global_rect().position.y >= 300.0, "P4: los créditos no deben tapar el título (empiezan en y=%s)" % (cr.get_global_rect().position.y if cr != null else -1.0))
	# P5/P6: brújula del perfil bajo las preguntas.
	main.mostrar_partido("propio")
	await process_frame
	var br: Array = main._pantalla.find_children("*", "BrujulaPerfil", true, false)
	_check(br.size() == 1 and (br[0] as BrujulaPerfil).vacio, "P5/P6: la primera pregunta muestra la brújula vacía")
	main._pantalla._responder(d["ideologia"]["preguntas"][0]["opciones"][0])
	await process_frame
	br = main._pantalla.find_children("*", "BrujulaPerfil", true, false).filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())
	_check(br.size() == 1 and not (br[0] as BrujulaPerfil).vacio and (br[0] as BrujulaPerfil).nombre != "", "P5/P6: tras responder, la brújula marca el perfil")
	# P9: el tutorial oscurece todo salvo el elemento explicado.
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Movimiento Cívico Austral", "MCA", "metropolitana", resp, d["ideologia"])
	main.motor = Partida.crear(d, 20260415, partido)
	main.mostrar_dia()
	await _esperar(0.3)
	var dia: Node = main._pantalla
	var tuts: Array = dia._capa.find_children("*", "Tutorial", true, false)
	_check(tuts.size() == 1 and tuts[0]._velo != null and tuts[0]._marco.visible, "P9: el tutorial muestra el foco sobre el elemento")
	if not tuts.is_empty():
		var hueco: Rect2 = tuts[0]._marco.get_global_rect()
		_check(hueco.intersects(dia._mano.get_global_rect()), "P9: el primer paso enfoca la mano")
		tuts[0]._cerrar()
	await _esperar(1.0)  # la mano termina de repartirse
	# Región de nombre largo: la columna de tarjetas sobre el mapa no se sale de la pantalla (hallazgo de «Búsqueda infinita de fallas»).
	for rid in ["magallanes", "aysen", "metropolitana"]:
		dia._on_region(rid)
		await process_frame
		await process_frame
		_check(dia._r["rg_nombre"].get_global_rect().end.x <= 390.5 and dia._r["ev_titulo"].get_global_rect().end.x <= 390.5,
			"región %s: las tarjetas del mapa caben en 390 px (%s)" % [rid, dia._r["rg_nombre"].get_global_rect().end.x])
	# P10: mantener el dedo sobre la carta elegida abre la ficha y al soltar no se juega.
	var est: EstadoSimulacion = main.motor.estado
	var elegida: CartaUI = null
	for c in dia._mano.get_children():
		if c is CartaUI and (c as CartaUI).elegida:
			elegida = c
	_check(elegida != null, "P10: hay una carta elegida en la mano")
	if elegida != null:
		var pos := elegida.get_global_rect().get_center() + Vector2(0, 20)
		var pa0 := est.pa_actual
		var n_mano := est.mano.size()
		var acciones := est.registro_acciones.size()
		_raton(pos, true)
		await _esperar(0.7)
		_check(dia._mano._ficha != null, "P10: mantener el dedo abre la ficha ampliada")
		_raton(pos, false)
		await process_frame
		_check(dia._mano._ficha == null, "P10: soltar cierra la ficha")
		_check(est.pa_actual == pa0 and est.mano.size() == n_mano and est.registro_acciones.size() == acciones, "P10: abrir la ficha no juega la carta")
		# un toque breve sobre la elegida sigue jugándola (doble toque)
		dia._mano_tocada = true
		_raton(pos, true)
		await process_frame
		_raton(pos, false)
		await process_frame
		_check(est.registro_acciones.size() > acciones, "P10: un toque breve sobre la carta elegida la juega")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	if _fallos == 0:
		print("CLARIDAD OK")
	quit(1 if _fallos > 0 else 0)
