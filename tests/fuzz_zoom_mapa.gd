extends SceneTree
## Fuzz del zoom del mapa de Chile con entradas reales (Input.parse_input_event): pellizco (MagnifyGesture), rueda, doble toque, arrastre con un dedo (también hacia
## fuera de los límites del control), «Ver todo», tocar una región, jugar una carta con zoom, cambio de tamaño/orientación de la ventana con zoom activo y pausa con zoom.
## Invariantes: el zoom queda en [1, 4]; el desplazamiento nunca deja ver fuera del mapa (pan en [tam·(1−zoom), 0], tras un gesto y tras cambiar de tamaño);
## nada es NaN/infinito; tocar o arrastrar el mapa NUNCA juega una carta ni gasta movimientos; un arrastre no elige región; «Ver todo» deja zoom 1 y pan 0;
## el guardado tras una pausa con zoom es válido.
## Uso: godot --headless --path . -s tests/fuzz_zoom_mapa.gd -- [operaciones=150] [semilla=9500]

var _fallos := 0
var _ops := 0
var _resize_fuera := 0
const RESIZE_ESTRICTO := true
var _zoom_max := 1.0
var _acercadas := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ ZOOM: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _toque(pos: Vector2, pulsado: bool, dedo: int = 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = dedo
	e.pressed = pulsado
	e.position = root.get_final_transform() * pos
	Input.parse_input_event(e)


func _arrastre(desde: Vector2, hasta: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = root.get_final_transform() * hasta
	e.relative = hasta - desde
	Input.parse_input_event(e)


func _pellizco(pos: Vector2, factor: float) -> void:
	var e := InputEventMagnifyGesture.new()
	e.position = root.get_final_transform() * pos
	e.factor = factor
	Input.parse_input_event(e)


func _rueda(pos: Vector2, arriba: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_WHEEL_UP if arriba else MOUSE_BUTTON_WHEEL_DOWN
	e.position = root.get_final_transform() * pos
	e.pressed = true
	Input.parse_input_event(e)


func _vista_ok(mapa: MapaChile, ctx: String) -> void:
	var z: MapaZoom = mapa._zoom
	_check(is_finite(z.zoom) and is_finite(z.pan.x) and is_finite(z.pan.y), "%s: zoom o pan no finito (%s, %s)" % [ctx, str(z.zoom), str(z.pan)])
	_check(z.zoom >= 0.999 and z.zoom <= MapaZoom.MAX + 0.001, "%s: zoom %.3f fuera de [1, %.0f]" % [ctx, z.zoom, MapaZoom.MAX])
	var tam: Vector2 = mapa.size
	_check(z.pan.x <= 0.5 and z.pan.y <= 0.5 and z.pan.x >= tam.x * (1.0 - z.zoom) - 0.5 and z.pan.y >= tam.y * (1.0 - z.zoom) - 0.5, "%s: el desplazamiento %s deja ver fuera del mapa (zoom %.2f, tamaño %s)" % [ctx, str(z.pan), z.zoom, str(tam)])


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 150
	var semilla := int(args[1]) if args.size() > 1 else 9500
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_zoom_fuzz.json"
	Tutorial.marcar_visto()
	Input.emulate_mouse_from_touch = true
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(d, semilla, GeneradorPartido.construir_partido("Zoom", "ZOO", "metropolitana", resp, d["ideologia"]))
	main.mostrar_dia()
	await _cuadros(4)
	for i in range(n):
		if not is_instance_valid(main._pantalla) or not (main._pantalla is PantallaDia):
			main.mostrar_dia()
			await _cuadros(3)
		var dia: PantallaDia = main._pantalla
		var mapa: MapaChile = dia._mapa
		var est: EstadoSimulacion = main.motor.estado
		var hijos := dia._capa.get_children()
		for k in range(1, hijos.size()):  # overlays que dejó una operación anterior
			if not (hijos[k] is Label):
				hijos[k].queue_free()
		var e0 := est.entradas.size()
		var pa0 := est.pa_actual
		var r := mapa.get_global_rect()
		var ctx := "op %d" % i
		_ops += 1
		var op := rng.randi_range(0, 9)
		var pt := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		match op:
			0:
				_pellizco(pt, rng.randf_range(0.2, 3.0))
				await _cuadros(2)
			1:
				for _k in range(rng.randi_range(1, 6)):
					_rueda(pt, rng.randf() < 0.6)
				await _cuadros(2)
			2:  # doble toque
				var sel0: String = dia._region
				_toque(pt, true)
				_toque(pt, false)
				await _cuadros(1)
				_toque(pt, true)
				_toque(pt, false)
				await _cuadros(6)
			3:  # arrastre con un dedo, a veces hacia fuera de los límites del control
				var hasta := pt + Vector2(rng.randf_range(-600.0, 600.0), rng.randf_range(-800.0, 800.0))
				var region0: String = dia._region
				_toque(pt, true)
				await _cuadros(1)
				for k in range(1, 7):
					_arrastre(pt.lerp(hasta, float(k - 1) / 6.0), pt.lerp(hasta, float(k) / 6.0))
					await _cuadros(1)
				_toque(hasta, false)
				await _cuadros(4)
				if pt.distance_to(hasta) > MapaZoom.UMBRAL_ARRASTRE * 2.0:
					_check(dia._region == region0 or dia._region == "", "%s: un arrastre cambió la región seleccionada (%s -> %s)" % [ctx, region0, dia._region])
			4:  # tocar una región
				_toque(pt, true)
				_toque(pt, false)
				await _cuadros(5)
			5:  # «Ver todo»
				if mapa._ver_todo != null and mapa._ver_todo.is_visible_in_tree():
					await _tocar_boton(mapa._ver_todo)
					await _cuadros(30)
					_check(mapa._zoom.zoom <= 1.01 and mapa._zoom.pan.length() < 1.0, "%s: «Ver todo» no devolvió la vista completa (zoom %.2f, pan %s)" % [ctx, mapa._zoom.zoom, str(mapa._zoom.pan)])
			6:  # jugar una carta con zoom activo: el toque en la mano no debe confundirse con el mapa
				var cartas := dia.find_children("*", "CartaUI", true, false).filter(func(c: CartaUI) -> bool: return c.elegida and not c.is_queued_for_deletion())
				if not cartas.is_empty():
					var pc: Vector2 = (cartas[0] as CartaUI).get_global_rect().position + Vector2(40.0, 40.0)
					await _tocar(pc)
					_check(est.entradas.size() - e0 <= 1, "%s: tocar la carta con zoom generó %d entradas" % [ctx, est.entradas.size() - e0])
				e0 = est.entradas.size()
				pa0 = est.pa_actual
			7:  # el control del mapa se encoge con zoom activo (rotación, pantalla dividida, teclado) y luego recupera su tamaño
				#     (cambiar el tamaño de la ventana en headless no entrega bien las entradas siguientes; solo se encoge: agrandar lo taparía el resto de la pantalla)
				var antes_tam: Vector2 = mapa.size
				mapa.size = Vector2(maxf(120.0, antes_tam.x * rng.randf_range(0.5, 1.0)), maxf(120.0, antes_tam.y * rng.randf_range(0.5, 1.0)))
				await _cuadros(3)
				_vista_tras_resize(mapa, ctx)
				mapa.size = antes_tam
				await _cuadros(2)
			8:  # pausa con zoom: el guardado en disco es válido
				main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
				var g: Variant = Datos.leer_json("user://guardado.json")
				_check(g is Dictionary and ValidarGuardado.guardado_valido(g), "%s: tras la pausa con zoom el guardado no es válido" % ctx)
				main._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
				await _cuadros(2)
			9:  # dos dedos: pellizco con ScreenTouch de dos índices
				_toque(pt, true, 0)
				_toque(pt + Vector2(60.0, 0.0), true, 1)
				await _cuadros(1)
				_pellizco(pt, rng.randf_range(0.5, 2.0))
				await _cuadros(2)
				_toque(pt + Vector2(60.0, 0.0), false, 1)
				_toque(pt, false, 0)
				await _cuadros(4)
		if op != 6:
			_check(est.entradas.size() == e0 and est.pa_actual == pa0, "%s (op %d): un gesto sobre el mapa jugó una carta o gastó movimientos (entradas +%d, pa %d->%d; última entrada %s)" % [ctx, op, est.entradas.size() - e0, pa0, est.pa_actual, str(est.entradas.back()) if not est.entradas.is_empty() else "-"])
		if is_instance_valid(mapa):
			_vista_ok(mapa, "%s (op %d)" % [ctx, op])
			_zoom_max = maxf(_zoom_max, mapa._zoom.zoom)
			_acercadas += 1 if mapa._zoom.acercado() else 0
	Input.emulate_mouse_from_touch = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	print("FUZZ ZOOM MAPA %s (%d operaciones, %d con zoom activo, zoom máximo %.2f, %d veces el desplazamiento quedó fuera tras encoger, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", _ops, _acercadas, _zoom_max, _resize_fuera, _fallos])
	quit(1 if _fallos > 0 else 0)


func _tocar(pos: Vector2) -> void:
	_toque(pos, true)
	await _cuadros(2)
	_toque(pos, false)
	await _cuadros(4)


func _tocar_boton(b: Control) -> void:
	await _tocar(b.get_global_rect().get_center())


func _vista_tras_resize(mapa: MapaChile, ctx: String) -> void:
	## Tras encoger el control con zoom activo la vista debe seguir dentro de los límites del NUEVO tamaño (sin esperar a otro gesto).
	## Corregido en main (MapaChile limita la vista con NOTIFICATION_RESIZED): RESIZE_ESTRICTO = true.
	var z: MapaZoom = mapa._zoom
	var tam: Vector2 = mapa.size
	var fuera := z.pan.x < tam.x * (1.0 - z.zoom) - 0.5 or z.pan.y < tam.y * (1.0 - z.zoom) - 0.5
	if fuera:
		_resize_fuera += 1
		if RESIZE_ESTRICTO:
			_check(false, "%s: tras encoger el mapa a %s el desplazamiento %s deja ver fuera del mapa (zoom %.2f)" % [ctx, str(tam), str(z.pan), z.zoom])
