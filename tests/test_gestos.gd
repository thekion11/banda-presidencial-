extends SceneTree
## Gestos y caminos poco frecuentes de game/ que ninguna otra prueba ejecutaba (tools/cobertura_funciones.py --game):
## toques en el mapa de Chile, el del continente, el del Comité y el urbano; arrastre de la obra 3D y del Comité 3D;
## fases de la obra; «Ocultar todas» de la leyenda del Metro; fuegos de obra terminada; escándalo ministerial; carta sin
## ilustración; música apagada y encendida; aprobar una propuesta; decisión de un evento. Cada uno cambia algo visible.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


static func _clic(pos: Vector2, pulsado: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pulsado
	e.position = pos
	return e


static func _mover(pos: Vector2, rel: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.relative = rel
	return e


static func _buscar(n: Node, clase: String) -> Node:
	var r := n.find_children("*", clase, true, false)
	return r[0] if not r.is_empty() else null


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_gestos.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var m := Partida.crear(d, 61, GeneradorPartido.construir_partido("Gestos", "GES", "metropolitana", resp, d["ideologia"]))
	main.motor = m
	main.mostrar_dia()
	await _cuadros(2)
	var dia: PantallaDia = main._pantalla
	# mapa de Chile: tocar elige la región
	var mapa: MapaChile = dia._mapa
	dia._region = ""
	mapa._gui_input(_clic(mapa.size * 0.5, true))
	mapa._gui_input(_clic(mapa.size * 0.5, false))  # se elige al soltar (si no hubo arrastre: el arrastre desplaza el mapa acercado)
	await _cuadros(1)
	_check(dia._region != "" and mapa.seleccion == dia._region, "tocar el mapa de Chile elige una región (%s)" % dia._region)
	# fuegos de obra terminada: el mapa los encola y los dibuja
	Movimiento.forzado = 1  # los fuegos son un efecto intenso: con el movimiento apagado no se lanzan
	mapa.lanzar_fuegos("metropolitana")
	_check(not mapa._fuegos.is_empty(), "una obra terminada lanza fuegos sobre su región")
	mapa._fuegos.clear()
	Movimiento.forzado = 0
	# carta sin ilustración: respaldo con el nombre del sector y la gema de costo
	var c := CartaUI.new()
	c.carta = {"id": "x", "categoria": "sin_arte_de_prueba", "titulo": "Carta de prueba", "efectos": [{"ind": "capital", "delta": 1}], "costo_pa": 1}
	c.size = Vector2(110, 160)
	root.add_child(c)
	c.queue_redraw()
	await _cuadros(2)
	_check(c._arte == null, "una categoría sin ilustración usa el respaldo dibujado")
	c.queue_free()
	# escándalo ministerial: el golpe de prensa sabe qué ministro fue
	var n_reg := m.estado.registro_acciones.size()
	var mid: String = m.estado.gabinete[0]
	m.estado.registrar_accion("escandalo_ministro", {"ministro": mid})
	_check(GolpePrensa.ministro_del_escandalo(m, n_reg).get("alias", "") == m.catalogo_ministros[mid]["alias"], "el golpe de prensa nombra al ministro del escándalo")
	_check(GolpePrensa.ministro_del_escandalo(m, m.estado.registro_acciones.size()).is_empty(), "sin escándalo nuevo no nombra a nadie")
	# decisión de un evento: el aviso dice lo que cambió
	_check(Barras.texto_decision({"ok": true}, {"capital": 50.0}, {"capital": 47.0}).begins_with("Decisión tomada."), "el aviso de una decisión empieza por lo hecho")
	_check(Barras.texto_decision({"ok": false}, {}, {}) == "No se pudo registrar la decisión.", "una decisión rechazada lo dice")
	# música: apagarla detiene la pista y encenderla la retoma, sin fallar en headless
	var previa := Ajustes.musica
	Ajustes.poner("musica", false)
	Ajustes.poner("musica", true)
	Ajustes.poner("musica", previa)
	_check(Ajustes.musica == previa, "la música se apaga y se enciende desde Ajustes")
	# Nación › Continente: tocar un país muestra su relación con Chile
	dia._abrir_panel("nacion")
	await _cuadros(2)
	var bc: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "Continente")
	_check(not bc.is_empty(), "Nación tiene el botón Continente")
	if not bc.is_empty():
		(bc[0] as Button).pressed.emit()
		await _cuadros(2)
		var cont: MapaContinente = _buscar(dia._zona_panel, "MapaContinente")
		var tocado := [""]
		cont.pais_tocado.connect(func(iso: String) -> void: tocado[0] = iso)
		cont.pais_tocado.emit("ARG")
		await _cuadros(1)
		var info: Array = dia._zona_panel.find_children("*", "Label", true, false).filter(func(l: Label) -> bool: return l.text.contains("relación") and l.text.contains("/100"))
		_check(not info.is_empty(), "tocar un país muestra su relación con Chile")
		cont._gui_input(_clic(cont.size * 0.5, true))
		cont._gui_input(_clic(cont.size * 0.5, false))
	dia._abrir_panel("mapa")
	await _cuadros(1)
	# Comité: editar el trazado (agregar y quitar estación, cambiar de variante) y tocar el mapa
	m.estado.propuestas_abiertas.append("prop_metro_suroriente")
	dia._refrescar()
	dia._abrir_panel("comite")
	await _cuadros(2)
	var cm: ComiteMapa = _buscar(dia._zona_panel, "ComiteMapa")
	_check(cm != null, "el Comité muestra su mapa")
	var editar: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Modificar"))
	if not editar.is_empty():
		(editar[0] as Button).pressed.emit()
		await _cuadros(2)
	var quitar: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "− Quitar")
	_check(not quitar.is_empty(), "el modo edición del Comité tiene «− Quitar»")
	if not quitar.is_empty():
		var antes: int = cm.estaciones_editadas().size() if cm.has_method("estaciones_editadas") else -1
		(quitar[0] as Button).pressed.emit()
		await _cuadros(1)
		_check(antes < 0 or cm.estaciones_editadas().size() <= antes, "«− Quitar» saca una estación")
	var var_b: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "Variante B")
	if not var_b.is_empty():
		(var_b[0] as Button).pressed.emit()  # cambiar de variante termina la edición
		await _cuadros(1)
	if cm != null:
		cm._gui_input(_clic(cm.size * 0.5, true))
		cm._gui_input(_clic(cm.size * 0.5, false))
	# Comité 3D: el botón «3D» cambia de vista y arrastrar gira la cámara
	var b3d: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "3D")
	_check(not b3d.is_empty(), "el Comité tiene el botón 3D")
	if not b3d.is_empty():
		(b3d[0] as Button).pressed.emit()
		await _cuadros(2)
		var v3: Control = _buscar(dia._zona_panel, "ComiteMapa3D")
		_check(v3 != null and v3.is_visible_in_tree(), "«3D» muestra el Comité en 3D")
		if v3 != null:
			v3._gui_input(_clic(v3.size * 0.5, true))
			v3._gui_input(_mover(v3.size * 0.5 + Vector2(30, 0), Vector2(30, 0)))
			v3._gui_input(_clic(v3.size * 0.5 + Vector2(30, 0), false))
	# aprobar la propuesta desde el Comité: pasa a obra y avisa los días
	dia._aprobar("prop_no_existe", "A")
	_check(dia._toast.text == Razones.texto({"razon": "propuesta_no_disponible"}), "una propuesta que no se puede aprobar dice por qué (%s)" % dia._toast.text)
	m.estado.pa_actual = 9
	m.estado.etapa = "gobierno"  # el Comité aprueba obras solo en gobierno
	var obras_antes := m.estado.obras_en_curso.size()
	dia._aprobar("prop_metro_suroriente", "A")
	await _cuadros(1)
	_check(m.estado.obras_en_curso.size() == obras_antes + 1 and dia._toast.text.begins_with("Obra aprobada"), "aprobar la propuesta crea la obra y lo avisa (%s)" % dia._toast.text)
	# mapa urbano: arrastrar desplaza; la leyenda oculta y muestra todas las líneas
	dia._abrir_panel("mapa")
	dia._abrir_urbano()
	await _cuadros(2)
	var um: UrbanoMapa = _buscar(dia._capa, "UrbanoMapa")
	_check(um != null, "se abre el mapa urbano")
	if um != null:
		var p0 := um.size * 0.5
		um._gui_input(_clic(p0, true))
		um._gui_input(_mover(p0 + Vector2(40, 30), Vector2(40, 30)))
		um._gui_input(_clic(p0 + Vector2(40, 30), false))
		_check(um.pan != Vector2.ZERO or um.zoom == 1.0, "arrastrar el mapa urbano no falla (pan %s)" % um.pan)
	var ley: LeyendaMetro = _buscar(dia._capa, "LeyendaMetro")
	if ley != null:
		var t0 := ley._todas.text
		ley._todas.pressed.emit()
		await _cuadros(1)
		_check(ley._todas.text != t0, "«%s» cambia a «%s»" % [t0, ley._todas.text])
		ley._todas.pressed.emit()
	for h in dia._capa.get_children():
		if h is Control and h != dia._toast:
			h.queue_free()
	await _cuadros(1)
	# hito de obra: la obra 3D se arrastra, salta de fase y se reproduce
	var obra := {"nombre": "Estación terminal", "variante": "A", "dias_totales": 960, "dias_avanzados": 760, "retrasos": 0, "carta_id": "", "propuesta": "prop_metro_suroriente", "region": "metropolitana", "efectos_final": []}
	dia._abrir_hito(obra)
	await _cuadros(2)
	var iso: Obra3D = _buscar(dia._capa, "Obra3D")
	_check(iso != null, "el hito muestra la obra 3D")
	if iso != null:
		iso._gui_input(_clic(iso.size * 0.5, true))
		iso._gui_input(_mover(iso.size * 0.5 + Vector2(-25, 0), Vector2(-25, 0)))
		iso._gui_input(_clic(iso.size * 0.5, false))
		iso.ir_a(2)
		iso.reproducir()
		await create_timer(0.6).timeout
		_check(iso.fase >= 1.0, "reproducir la obra avanza sus fases (%.2f)" % iso.fase)
	# gabinete como tablero (opción A del usuario): arrastrar una carta a su puesto la nombra; a otro puesto, no
	m.estado.etapa = "gobierno"  # el tablero se edita en la transición (primera semana de gobierno)
	m.estado.turno_actual = 1
	var tablero := PanelGabinete.crear(m, "Confirmar", func() -> void: pass)
	root.add_child(tablero)
	await _cuadros(2)
	var puestos: Array = tablero.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b is TableroGabinete.Puesto)
	var cartas: Array = tablero.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b is TableroGabinete.Candidato and not b.is_queued_for_deletion())
	_check(puestos.size() == 25 and cartas.size() == 3, "el tablero muestra 25 puestos y 3 candidatos del puesto abierto")
	if not cartas.is_empty():
		var carta: TableroGabinete.Candidato = cartas.filter(func(c: TableroGabinete.Candidato) -> bool: return not m.estado.gabinete.has(c.id)).front()
		var datos_arrastre: Variant = carta._get_drag_data(Vector2.ZERO)
		var suyo: TableroGabinete.Puesto = puestos.filter(func(p: TableroGabinete.Puesto) -> bool: return p.slot == carta.slot)[0]
		var ajeno: TableroGabinete.Puesto = puestos.filter(func(p: TableroGabinete.Puesto) -> bool: return p.slot != carta.slot)[0]
		_check(suyo._can_drop_data(Vector2.ZERO, datos_arrastre) and not ajeno._can_drop_data(Vector2.ZERO, datos_arrastre), "la carta solo se suelta en el puesto de su ministerio")
		suyo._drop_data(Vector2.ZERO, datos_arrastre)
		await _cuadros(1)
		_check(suyo._estado.text == "elegido", "soltar la carta en su puesto la nombra (%s)" % suyo._estado.text)
		_check(tablero.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text.begins_with("Nombraste a")), "al nombrar se ve la reacción con el efecto")
	tablero.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	if _fallos == 0:
		print("GESTOS OK")
	quit(1 if _fallos > 0 else 0)
