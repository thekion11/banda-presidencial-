extends SceneTree
## Fuzz de toques por el camino REAL de entrada (Input.parse_input_event con InputEventScreenTouch/ScreenDrag), con emulate_mouse_from_touch activo (como
## Android) y desactivado. Sobre la pantalla del día y con operaciones al azar (tocar carta, tocar la elegida, doble toque, deslizar hacia arriba, mantener,
## tocar el mapa, tocar «Terminar semana»), comprueba CLAUDE.md §4 y el arreglo del doble manejo toque+clic:
##  - el primer toque sobre una carta no elegida la elige y NUNCA la juega ni gasta movimientos;
##  - un toque sobre la carta elegida la juega como mucho una vez (+1 entrada), nunca dos;
##  - deslizar hacia arriba desde una carta la juega como mucho una vez;
##  - mantener el dedo no juega nada; tocar el mapa no juega nada;
##  - con la emulación de clic desactivada, ningún toque gasta movimientos;
##  - «Terminar semana» avanza como mucho una semana por toque.
## Uso: godot --headless --path . -s tests/fuzz_toque_real.gd -- [operaciones_por_modo] [semilla]

var _fallos := 0
var _ops := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ TOQUE REAL: ", msg)


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


func _cartas(dia: PantallaDia, elegida: bool) -> Array:
	return dia.find_children("*", "CartaUI", true, false).filter(func(c: CartaUI) -> bool: return c.elegida == elegida and not c.is_queued_for_deletion())


func _carta_en(dia: PantallaDia, p: Vector2) -> CartaUI:
	## La carta que recibe el toque en ese punto: la de más arriba (las del abanico se tapan unas a otras).
	var hijos := dia.find_children("*", "CartaUI", true, false)
	hijos.reverse()
	for c in hijos:
		if not c.is_queued_for_deletion() and (c as CartaUI).get_global_rect().has_point(p):
			return c
	return null


func _punto(c: CartaUI) -> Vector2:
	return c.get_global_rect().position + Vector2(c.size.x * 0.7, 40.0)


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 120
	var s0 := int(args[1]) if args.size() > 1 else 9100
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_toque_fuzz.json"
	Tutorial.marcar_visto()
	for emulacion in [true, false]:
		await _modo(emulacion, n, s0 + (0 if emulacion else 1))
	Input.emulate_mouse_from_touch = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	print("FUZZ TOQUE REAL %s (%d operaciones, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", _ops, _fallos])
	quit(1 if _fallos > 0 else 0)


func _modo(emulacion: bool, n: int, semilla: int) -> void:
	Input.emulate_mouse_from_touch = emulacion
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(d, semilla, GeneradorPartido.construir_partido("Toque", "TOQ", "metropolitana", resp, d["ideologia"]))
	main.mostrar_dia()
	await _cuadros(4)
	var ctx := "emulación %s" % ("activa" if emulacion else "inactiva")
	var capa0: int = (main._pantalla as PantallaDia)._capa.get_child_count()
	for i in range(n):
		if not (main._pantalla is PantallaDia) or not is_instance_valid(main._pantalla):
			break
		var dia: PantallaDia = main._pantalla
		var hijos_capa := dia._capa.get_children()
		for k in range(capa0, hijos_capa.size()):  # hojas u overlays que una operación anterior dejó abiertos (delegar, ficha): taparían la mano
			hijos_capa[k].queue_free()
		await _cuadros(1)
		var est: EstadoSimulacion = main.motor.estado
		var e0 := est.entradas.size()
		var pa0 := est.pa_actual
		var t0 := est.turno_actual
		var op := rng.randi_range(0, 7)
		var otras := _cartas(dia, false)
		var elegidas := _cartas(dia, true)
		_ops += 1
		match op:
			0, 1:  # tocar una carta no elegida: la elige, no la juega
				if otras.is_empty():
					continue
				var c: CartaUI = otras[otras.size() - 1] if rng.randf() < 0.5 else otras[rng.randi_range(0, otras.size() - 1)]
				var sel0: int = dia._sel
				var encima := _carta_en(dia, _punto(c))
				var id_c := str(c.carta.get("id", "?"))
				var id_encima := str(encima.carta.get("id", "?")) if encima != null else "-"
				await _tocar(_punto(c))
				if id_encima == id_c or not emulacion:  # si la elegida (más grande) tapa el punto, el toque cae sobre ella y la juega: es lo esperado
					_check(est.entradas.size() == e0 and est.pa_actual == pa0, "%s op %d: un toque sobre una carta no elegida jugó o gastó movimientos (entradas +%d, pa %d->%d; encima %s, carta %s)" % [ctx, i, est.entradas.size() - e0, pa0, est.pa_actual, id_encima, id_c])
				if emulacion and id_encima == id_c and sel0 == dia._sel and not dia._zona_panel.visible:  # con un panel abierto la mano queda tapada
					_check(false, "%s op %d: el toque no eligió la carta %s (sel %d->%d, mano %d)" % [ctx, i, id_c, sel0, dia._sel, est.mano.size()])
			2:  # tocar la elegida: la juega como mucho una vez
				if elegidas.is_empty():
					continue
				await _tocar(_punto(elegidas[0]))
				_check(est.entradas.size() - e0 <= 1, "%s op %d: un toque sobre la elegida generó %d entradas" % [ctx, i, est.entradas.size() - e0])
				if not emulacion:
					_check(est.entradas.size() == e0 and est.pa_actual == pa0, "%s op %d: sin emulación de clic el toque gastó movimientos" % [ctx, i])
			3:  # doble toque rápido sobre una carta no elegida: a lo sumo una jugada
				if otras.is_empty():
					continue
				var p := _punto(otras[rng.randi_range(0, otras.size() - 1)])
				await _tocar(p)
				var elegida := _cartas(dia, true)
				if not elegida.is_empty():
					await _tocar(_punto(elegida[0]))
				_check(est.entradas.size() - e0 <= 1, "%s op %d: un doble toque generó %d entradas" % [ctx, i, est.entradas.size() - e0])
			4:  # deslizar hacia arriba desde una carta
				var todas := otras + elegidas
				if todas.is_empty():
					continue
				var p0 := _punto(todas[rng.randi_range(0, todas.size() - 1)])
				_toque(p0, true)
				await _cuadros(1)
				for k in range(1, 6):
					_arrastre(p0 + Vector2(0, -24.0 * (k - 1)), p0 + Vector2(0, -24.0 * k))
					await _cuadros(1)
				_toque(p0 + Vector2(0, -120.0), false)
				await _cuadros(4)
				_check(est.entradas.size() - e0 <= 1, "%s op %d: un deslizamiento generó %d entradas" % [ctx, i, est.entradas.size() - e0])
				if not emulacion:
					_check(est.entradas.size() == e0 and est.pa_actual == pa0, "%s op %d: sin emulación de clic el deslizamiento gastó movimientos" % [ctx, i])
			5:  # mantener el dedo (ficha ampliada): no juega
				var cs := otras + elegidas
				if cs.is_empty():
					continue
				var pf := _punto(cs[rng.randi_range(0, cs.size() - 1)])
				_toque(pf, true)
				await create_timer(ManoUI.PULSACION_LARGA_MS / 1000.0 + 0.15).timeout
				await _cuadros(1)
				_toque(pf, false)
				await _cuadros(3)
				_check(est.entradas.size() == e0 and est.pa_actual == pa0, "%s op %d: mantener el dedo jugó o gastó movimientos" % [ctx, i])
			7:  # tocar la tarjeta de la región: abre el mapa urbano o el panel de la nación UNA sola vez (no por el toque y además por el clic emulado)
				if dia._mapa.enlace == null:
					continue
				dia._region = "metropolitana" if rng.randf() < 0.7 else dia._region
				var hijos0: int = dia._capa.get_child_count()
				await _tocar(dia._mapa.enlace.get_global_rect().get_center())
				var nuevos: Array = dia._capa.get_children().slice(hijos0).filter(func(u: Node) -> bool: return not u.is_queued_for_deletion())
				_check(nuevos.size() <= 1, "%s op %d: un toque sobre la tarjeta de la región abrió %d pantallas/paneles a la vez" % [ctx, i, nuevos.size()])
				for u in nuevos:
					u.queue_free()
				await _cuadros(1)
				_check(est.entradas.size() == e0 and est.pa_actual == pa0, "%s op %d: tocar la tarjeta de la región jugó o gastó movimientos" % [ctx, i])
			6:  # tocar el mapa o «Terminar semana»
				if rng.randf() < 0.7 or est.pa_actual > 0:
					await _tocar(dia._mapa.get_global_rect().get_center())
					_check(est.entradas.size() == e0 and est.pa_actual == pa0, "%s op %d: tocar el mapa jugó o gastó movimientos" % [ctx, i])
				else:
					await _tocar(dia._btn_jugar.get_global_rect().get_center())
					await _cuadros(4)
					_check(est.turno_actual - t0 <= 1, "%s op %d: un toque avanzó %d semanas" % [ctx, i, est.turno_actual - t0])
		if is_instance_valid(main._pantalla) and main._pantalla is PantallaDia and main.motor.estado.pa_actual == 0 and rng.randf() < 0.5:
			dia = main._pantalla
			await _tocar(dia._btn_jugar.get_global_rect().get_center())
			await _cuadros(4)
	main.queue_free()
	await _cuadros(2)
