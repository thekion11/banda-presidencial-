extends SceneTree
## Fuzz de la pestaña «Congreso» (PanelAgenda: agenda legislativa del gobierno) con toques REALES (Input.parse_input_event): categorías, proyectos del catálogo, urgencias,
## «Delegar en el ministro», alternativas del Corrector, «Ver más proyectos», cerrar el panel y terminar la semana. Invariantes: nunca un error de script, la cabecera
## «N de M en trámite» coincide con el motor y nunca pasa del máximo, un toque presenta como mucho un proyecto (+1 entrada), un botón de urgencia sin capital está apagado,
## ninguna respuesta del Corrector queda vacía ni con valores sin formatear, y el estado del motor cumple los invariantes (AyudaInvariantes) tras cada operación.
## Uso: godot --headless --path . -s tests/fuzz_congreso_ui.gd -- [partidas=4] [operaciones=40] [semilla=2600]

var _fallos := 0
var _ops := 0
var _presentadas := 0
var _cabeceras_viejas := 0
const CABECERA_ESTRICTA := true  # corregido en main: PantallaDia reconstruye el panel abierto al terminar la semana


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ CONGRESO UI: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _toque(pos: Vector2, pulsado: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pulsado
	e.position = root.get_final_transform() * pos
	Input.parse_input_event(e)


func _tocar(pos: Vector2) -> void:
	_toque(pos, true)
	await _cuadros(2)
	_toque(pos, false)
	await _cuadros(3)


func _visible(c: Control) -> Vector2:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			(p as ScrollContainer).ensure_control_visible(c)
		p = p.get_parent()
	return c.get_global_rect().get_center()


func _botones(raiz: Node) -> Array:
	return raiz.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return (b as Button).is_visible_in_tree() and not b.is_queued_for_deletion() and (b as Button).size.y > 4.0)


func _partido(d: Dictionary) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return GeneradorPartido.construir_partido("Cong", "CON", "metropolitana", resp, d["ideologia"])


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 4
	var nops := int(args[1]) if args.size() > 1 else 40
	var s0 := int(args[2]) if args.size() > 2 else 2600
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_congreso_fuzz.json"
	Tutorial.marcar_visto()
	var d := Datos.cargar_todo()
	for i in range(n):
		await _partida(d, s0 + i, nops)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	print("FUZZ CONGRESO UI %s (%d partidas, %d operaciones, %d proyectos presentados por la interfaz, %d veces la cabecera quedó vieja tras terminar la semana, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _ops, _presentadas, _cabeceras_viejas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _partida(d: Dictionary, semilla: int, nops: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var m := Partida.crear(d, semilla, _partido(d))
	for _s in range(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	if not Bots.elegir(m, d, "codicioso", rng):
		return
	m.elegir_gabinete(m.estado.gabinete.duplicate())  # transición presidencial: el gabinete se confirma antes del día (si no, mostrar_dia abre la pantalla de transición)
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	main.motor = m
	main.mostrar_dia()
	await _cuadros(3)
	var ctx := "semilla %d" % semilla
	var capa0: int = (main._pantalla as PantallaDia)._capa.get_child_count()
	for k in range(nops):
		if not is_instance_valid(main._pantalla) or not (main._pantalla is PantallaDia):
			main.mostrar_dia()
			await _cuadros(3)
		var dia: PantallaDia = main._pantalla
		var e := m.estado
		if e.etapa != "gobierno":
			break
		var hijos := dia._capa.get_children()
		for j in range(capa0, hijos.size()):
			if not (hijos[j] is Label):
				hijos[j].queue_free()
		await _cuadros(1)
		if not dia._zona_panel.visible or rng.randf() < 0.1:
			dia._abrir_panel("congreso")
			await _cuadros(3)
		if rng.randf() < 0.4:  # a veces se libera cupo y capital (estado tocado a mano: esta prueba no compara con un replay)
			e.proyectos_ley.clear()
			e.indicadores["capital"] = 90.0
			e.pa_actual = maxi(e.pa_actual, 6)
			dia._abrir_panel("congreso")  # el estado cambió fuera de la interfaz: se reconstruye el panel (la interfaz solo se refresca por sus propias acciones)
			await _cuadros(3)
		var e0 := e.entradas.size()
		var n_ag0 := e.agenda.size()
		var bs := _botones(dia._zona_panel)
		_ops += 1
		var op := rng.randi_range(0, 9)
		if bs.is_empty():
			dia._abrir_panel("congreso")
			await _cuadros(3)
			continue
		if op == 7:  # flujo completo: abrir un proyecto y presentarlo con una urgencia al azar (con o sin delegar)
			var cabs2 := bs.filter(func(x: Button) -> bool: return x.text == "" and x.size.y >= 40.0 and x.size.x > 200.0)
			if not cabs2.is_empty():
				await _tocar(_visible(cabs2[rng.randi_range(0, cabs2.size() - 1)]))
				var bs2 := _botones(dia._zona_panel)
				var urg2 := bs2.filter(func(x: Button) -> bool: return x.text.contains(" días · capital "))
				var deleg := bs2.filter(func(x: Button) -> bool: return x is CheckButton and not (x as Button).disabled)
				if not deleg.is_empty() and rng.randf() < 0.4:
					await _tocar(_visible(deleg[0]))
				if not urg2.is_empty():
					var u: Button = urg2[rng.randi_range(0, urg2.size() - 1)]
					var antes_tap := e.entradas.size()
					var estaba_apagado := u.disabled
					await _tocar(_visible(u))
					if estaba_apagado:
						_check(e.entradas.size() == antes_tap, "%s op %d: una urgencia apagada presentó un proyecto" % [ctx, k])
					elif e.entradas.size() > antes_tap:
						_check(e.entradas.size() - antes_tap == 1 and String(e.entradas.back()["tipo"]) == "presentar", "%s op %d: presentar generó %d entradas (%s)" % [ctx, k, e.entradas.size() - antes_tap, String(e.entradas.back()["tipo"])])
						_presentadas += 1
		elif op <= 6:  # tocar un botón del panel (categoría, proyecto, urgencia, corrector, ver más); la mitad de las veces, guiado hacia presentar
			var b: Button = bs[rng.randi_range(0, bs.size() - 1)]
			if rng.randf() < 0.5:
				var urg := bs.filter(func(x: Button) -> bool: return x.text.contains(" días · capital "))
				var cabs := bs.filter(func(x: Button) -> bool: return x.text == "" and x.size.y >= 40.0 and x.size.x > 200.0)
				if not urg.is_empty():
					b = urg[rng.randi_range(0, urg.size() - 1)]
				elif not cabs.is_empty():
					b = cabs[rng.randi_range(0, cabs.size() - 1)]
			var apagado := b.disabled
			var texto := b.text
			if apagado:
				await _tocar(_visible(b))
				_check(e.entradas.size() == e0, "%s op %d: un botón apagado («%s») generó una entrada" % [ctx, k, texto.left(30)])
			else:
				await _tocar(_visible(b))
				_check(e.entradas.size() - e0 <= 1, "%s op %d: un toque en «%s» generó %d entradas" % [ctx, k, texto.left(30), e.entradas.size() - e0])
				if e.entradas.size() - e0 == 1 and String(e.entradas.back()["tipo"]) == "presentar":
					_presentadas += 1
		elif op == 8:  # terminar la semana: el trámite avanza
			dia._btn_jugar.pressed.emit()
			if is_instance_valid(dia) and dia._confirmar_fin:
				dia._btn_jugar.pressed.emit()
			await _cuadros(5)
		else:  # una semana del bot (juego normal) para que haya capital, cartas y proyectos de la mano
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
			main.mostrar_dia()
			await _cuadros(3)
		if not is_instance_valid(main._pantalla) or not (main._pantalla is PantallaDia):
			continue
		dia = main._pantalla
		_check(e.agenda.size() <= int(m.catalogo_leyes["agenda"]["max_simultaneos"]), "%s op %d: la agenda pasó del máximo (%d)" % [ctx, k, e.agenda.size()])
		for etq in dia._zona_panel.find_children("*", "Label", true, false):
			var t := (etq as Label).text
			if t.begins_with("Agenda del gobierno · "):
				var ea := m.agenda.estado_agenda()
				if t != "Agenda del gobierno · %d de %d en trámite" % [int(ea["en_tramite"]), int(ea["maximo"])]:
					_cabeceras_viejas += 1
					if CABECERA_ESTRICTA:
						_check(false, "%s op %d: la cabecera dice «%s» y el motor %d de %d" % [ctx, k, t, int(ea["en_tramite"]), int(ea["maximo"])])
		for b in AyudaTextos.basura(dia._zona_panel):
			_check(false, "%s op %d: texto con valores sin formatear en el panel: %s" % [ctx, k, b])
		for f in AyudaInvariantes.revisar(m, "%s op %d" % [ctx, k]):
			_check(false, "%s op %d: invariante: %s" % [ctx, k, f])
	main.queue_free()
	await _cuadros(2)
