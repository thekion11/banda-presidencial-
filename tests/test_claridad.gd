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


func _iconos() -> void:
	## Íconos (cola 5): cada tipo usado existe y se dibuja, y cada tamaño es uno de los de la guía (Icono.TAMANOS).
	var fuente_icono := FileAccess.get_file_as_string("res://game/componentes/icono.gd")
	for t in Icono.TIPOS:
		_check(fuente_icono.contains("\t\t\"%s\":" % t), "el ícono «%s» tiene dibujo" % t)
	var usos := RegEx.create_from_string("Icono\\.crear\\(([^,]+),[^,]+,\\s*([0-9.]+)")
	var vistos := 0
	for dir in ["res://game/componentes", "res://game/pantallas"]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".gd"):
				continue
			for m in usos.search_all(FileAccess.get_file_as_string(dir + "/" + f)):
				vistos += 1
				_check(Icono.TAMANOS.has(float(m.get_string(2))), "%s: ícono de %s px fuera de los tamaños de la guía %s" % [f, m.get_string(2), Icono.TAMANOS])
				var lit := m.get_string(1).strip_edges()
				if lit.begins_with("\""):
					_check(Icono.TIPOS.has(lit.trim_prefix("\"").trim_suffix("\"")), "%s: el ícono %s no existe" % [f, lit])
	_check(vistos >= 8, "se revisaron los usos de Icono.crear (%d)" % vistos)
	for f in PantallaUrbano.FILTROS:
		_check(Icono.TIPOS.has(String(f[4])), "el filtro «%s» del mapa urbano usa un ícono que existe" % f[0])
	_check(Icono.TIPOS.has("person") and Icono.TIPOS.has("map") and Icono.TIPOS.has("bars") and Icono.TIPOS.has("building") and Icono.TIPOS.has("people"), "existen los íconos de la barra inferior y de delegar")


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
	# cifras con punto de miles, como en la maqueta («+1.200», «US$1.900 M»)
	_check(Tema.miles(1200) == "1.200" and Tema.miles(999) == "999" and Tema.miles(-15400) == "-15.400" and Tema.miles(1234567) == "1.234.567", "Tema.miles pone punto de miles")
	var cats := {}
	for c in Datos.cargar_todo()["cartas"]:
		cats[String(c.get("categoria", ""))] = true
	for cat in cats.keys():  # cada sector de las cartas: color propio, ilustración y cinta con tildes que cabe en 62 px
		_check(CartaUI.COLORES_CATEGORIA.has(cat), "la categoría «%s» tiene color propio" % cat)
		_check(ResourceLoader.exists("res://game/arte/cartas/%s.jpg" % cat), "la categoría «%s» tiene ilustración" % cat)
		var nom: String = CartaUI.NOMBRES_CAT.get(cat, cat.to_upper())
		_check(not RegEx.create_from_string("(EDUCACION|POLITICA|ENERGIA|ECONOMIA|OPOSICION|COMITE)$").search(nom), "la cinta de «%s» lleva tilde (%s)" % [cat, nom])
		_check(Tema.fuente_texto(800).get_string_size(nom, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x <= 62.0, "la cinta de «%s» cabe en la carta" % cat)
	var M = load("res://game/main.gd")  # proporciones: teléfonos con ancho 390; tablet y plegable abierto, 390×844 con bandas
	_check(M.aspecto_para(Vector2i(360, 640)) == Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH and M.aspecto_para(Vector2i(280, 653)) == Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH, "los teléfonos usan ancho lógico 390")
	_check(M.aspecto_para(Vector2i(768, 1024)) == Window.CONTENT_SCALE_ASPECT_KEEP and M.aspecto_para(Vector2i(884, 1104)) == Window.CONTENT_SCALE_ASPECT_KEEP, "tablet y plegable abierto muestran el 390×844 completo")
	# primera ejecución (docs/PRIMERA_EJECUCION.md): el aviso de la promesa dice dónde quedó
	var resp_p: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp_p.append(p["opciones"][1])
	main.motor = Partida.crear(d, 31, GeneradorPartido.construir_partido("C", "C", "metropolitana", resp_p, d["ideologia"]))
	main.mostrar_dia()
	await process_frame
	var dia_p: PantallaDia = main._pantalla
	for reg in ["", "atacama"]:
		main.motor.estado.pa_actual = 9
		dia_p._sel = 0
		dia_p._region = reg
		dia_p._jugar()
		var aviso: String = dia_p._toast.text
		_check(aviso.begins_with("Promesa nacional") and aviso.contains("Toca el mapa") if reg == "" else aviso.begins_with("Promesa en Atacama"), "el aviso de la promesa dice dónde quedó (%s)" % aviso)
	_iconos()
	_check(Razones.texto({"razon": "pa_insuficiente", "costo": 3}).begins_with("Esta carta cuesta 3 movimientos. No te alcanzan"), "el rechazo por movimientos dice cuánto cuesta la carta")
	# votación rechazada en la primera cámara (la página más cargada) en el teléfono bajo con muesca y barra de 48 px
	Tema.inset_prueba = Vector2(48, 48)
	root.content_scale_size = Vector2i(390, 693)
	main.mostrar_dia()
	await process_frame
	var dv: PantallaDia = main._pantalla
	var votos := {"aprobada": false, "senado": 22, "camara": 0, "min_senado": 26, "min_camara": 78, "total_senado": 50, "total_camara": 155, "abst_senado": 6, "abst_camara": 0, "contra_senado": 22, "contra_camara": 0}
	dv._capa.add_child(OverlaysDia.evento({"titulo": "Ley de prueba con un nombre bastante largo", "hora": "16:00", "descripcion": "x", "efectos": [{"ind": "capital", "delta": -4}],
		"votacion": {"origen": "senado", "voto": votos, "tc": {"recurso": false, "cae": false}, "aprobada": false}}, func() -> void: pass, main.motor.catalogo_leyes["congreso"]["nombres"], 36))
	for i in range(3):
		await process_frame
	var lbls: Array = dv._capa.find_children("*", "Label", true, false).filter(func(l: Label) -> bool: return l.text.ends_with("· faltaron 4"))
	_check(lbls.size() == 1, "una votación rechazada dice cuántos votos faltaron")
	var bts: Array = dv._capa.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.is_visible_in_tree() and b.size.x > 300.0)  # el botón principal (el tutorial también está abierto)
	_check(not bts.is_empty() and bts.all(func(b: Button) -> bool: return b.get_global_rect().end.y <= 693.0 - 48.0 + 0.5), "con la barra de gestos el botón de la votación rechazada queda entero (%s)" % str(bts.map(func(b: Button) -> Rect2: return b.get_global_rect())))
	Tema.inset_prueba = Vector2(-1, -1)
	root.content_scale_size = Vector2i(390, 844)
	var con_futuro := {"diferido": {"semanas": 8, "efectos": [{"ind": "cohesion", "delta": 2}, {"ind": "aprobacion", "delta": 1}]}, "riesgo": {"prob": 0.3, "efectos": [{"ind": "aprobacion", "delta": -1}]}}
	var extra := FichaAmpliada._lineas_extra(con_futuro)
	_check(extra == ["En 8 semanas: Cohesión +2 · Aprobación +1", "Puede salir mal (30 %): Aprobación −1"], "la ficha dice cuándo llega el efecto a futuro y cuánto arriesga (%s)" % str(extra))
	_check(Tema.dec(3.5) == "3,5" and Tema.dec(57.44) == "57,4" and Tema.dec(-0.25, 2) == "-0,25", "Tema.dec usa coma decimal")
	if _fallos == 0:
		print("CLARIDAD OK")
	quit(1 if _fallos > 0 else 0)
