extends SceneTree
## Toques por el camino real del motor de entrada (Input.parse_input_event con InputEventScreenTouch/ScreenDrag, como
## en Android, donde además cada toque se emula como clic). Las demás pruebas emiten señales o llaman a _gui_input, y no
## veían que un único toque llegaba dos veces a la carta: la elegía y en seguida la jugaba (cola 7, docs/QA_VISUAL.md).

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


func _toque(pos: Vector2, pulsado: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pulsado
	e.position = root.get_final_transform() * pos
	Input.parse_input_event(e)


func _arrastre(desde: Vector2, hasta: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = root.get_final_transform() * hasta
	e.relative = hasta - desde
	Input.parse_input_event(e)


func _tocar(pos: Vector2, espera_s: float = 0.0) -> void:
	_toque(pos, true)
	if espera_s > 0.0:
		await create_timer(espera_s).timeout
	await _cuadros(2)
	_toque(pos, false)
	await _cuadros(4)


func _carta(dia: PantallaDia, elegida: bool) -> CartaUI:
	var cs: Array = dia.find_children("*", "CartaUI", true, false).filter(func(c: CartaUI) -> bool: return c.elegida == elegida and not c.is_queued_for_deletion())
	return cs.back() if not cs.is_empty() else null


func _punto(c: CartaUI) -> Vector2:
	return c.get_global_rect().position + Vector2(c.size.x * 0.7, 40.0)  # parte visible de la carta (el abanico se tapa a la izquierda)


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_toque.json"
	Tutorial.marcar_visto()
	_check(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true), "el proyecto emula el clic desde el toque (las cartas y botones lo esperan)")
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(d, 23, GeneradorPartido.construir_partido("Toque", "TOQ", "metropolitana", resp, d["ideologia"]))
	main.mostrar_dia()
	await _cuadros(4)
	var dia: PantallaDia = main._pantalla
	var est: EstadoSimulacion = main.motor.estado
	# 1) un toque en otra carta la elige y NO la juega
	var n0 := est.entradas.size()
	var otra := _carta(dia, false)
	var sel0: int = dia._sel
	await _tocar(_punto(otra))
	_check(dia._sel != sel0, "un toque elige la carta tocada (sel %d -> %d)" % [sel0, dia._sel])
	_check(est.entradas.size() == n0, "un solo toque no juega la carta (entradas +%d)" % (est.entradas.size() - n0))
	# 2) tocar la elegida la juega
	await _tocar(_punto(_carta(dia, true)))
	_check(est.entradas.size() == n0 + 1, "el segundo toque, sobre la elegida, la juega (entradas +%d)" % (est.entradas.size() - n0))
	# 3) deslizar la elegida hacia arriba la juega
	await _cuadros(2)
	var n1 := est.entradas.size()
	var p0 := _punto(_carta(dia, true))
	_toque(p0, true)
	await _cuadros(1)
	for k in range(1, 6):
		_arrastre(p0 + Vector2(0, -24.0 * (k - 1)), p0 + Vector2(0, -24.0 * k))
		await _cuadros(1)
	_toque(p0 + Vector2(0, -120.0), false)
	await _cuadros(4)
	_check(est.entradas.size() == n1 + 1, "deslizar la carta hacia arriba la juega (entradas +%d)" % (est.entradas.size() - n1))
	# 4) mantener el dedo abre la ficha ampliada; soltar la cierra y no juega
	var n2 := est.entradas.size()
	var pf := _punto(_carta(dia, true))
	_toque(pf, true)
	await create_timer(ManoUI.PULSACION_LARGA_MS / 1000.0 + 0.2).timeout
	await _cuadros(1)
	_check(not root.find_children("*", "FichaAmpliada", true, false).is_empty(), "mantener el dedo abre la ficha ampliada")
	_toque(pf, false)
	await _cuadros(3)
	_check(root.find_children("*", "FichaAmpliada", true, false).filter(func(f: Node) -> bool: return not f.is_queued_for_deletion()).is_empty(), "soltar cierra la ficha")
	_check(est.entradas.size() == n2, "mantener y soltar no juega la carta")
	# 5) tocar el mapa elige una región
	dia._region = ""
	await _tocar(dia._mapa.get_global_rect().get_center())
	_check(dia._region != "", "un toque en el mapa elige una región")
	# 6) «Terminar semana» con movimientos sin usar pide confirmar: un toque no avanza la semana
	var t0 := est.turno_actual
	if est.pa_actual > 0:
		await _tocar(dia._btn_jugar.get_global_rect().get_center())
		_check(est.turno_actual == t0 and dia._btn_jugar.text.contains("?") or dia._confirmar_fin, "con movimientos sin usar, un toque en «Terminar semana» pide confirmar (%s)" % dia._btn_jugar.text)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	if _fallos == 0:
		print("TOQUE REAL OK")
	quit(1 if _fallos > 0 else 0)
