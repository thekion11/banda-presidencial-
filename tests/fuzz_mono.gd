extends SceneTree
## Mono: entradas aleatorias REALES (toques, arrastres, doble toque, rueda, tecla Escape, botón atrás de Android, pausa y reanudación) sobre TODAS las pantallas
## del juego, en tres tamaños de ventana (360x640, 390x844, 480x1000) y con texto grande. Mitad de los toques caen en coordenadas al azar y mitad en el centro de un
## control visible (para avanzar por el flujo). Invariantes tras cada paso: la pantalla actual existe y es válida; si hay partida, el motor existe y sus
## indicadores son finitos; tras cada pausa el guardado en disco es válido y reproduce el motor en vivo. Los errores de script los detecta quien lanza el test
## (la salida no debe traer «SCRIPT ERROR»). Respalda y restaura los archivos de usuario.
## No se debe correr en paralelo con otras pruebas que escriban en user:// (guardado.json): comparten archivo y darían falsos fallos.
## Uso: godot --headless --path . -s tests/fuzz_mono.gd -- [entradas_por_tamaño] [semilla]

const ARCHIVOS := ["guardado.json", "guardado.cache", "ultima_config.json", "guardado_descartado.json"]
const TAMANOS := [Vector2i(360, 640), Vector2i(390, 844), Vector2i(480, 1000)]

var _fallos: int = 0
var _entradas: int = 0
var _pausas: int = 0
var _pantallas: Dictionary = {}
var _datos: Dictionary
var _huella: String


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO MONO: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _respaldar() -> void:
	for a in ARCHIVOS:
		if FileAccess.file_exists("user://" + a):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a), ProjectSettings.globalize_path("user://" + a + ".bak_mono"))


func _restaurar() -> void:
	for a in ARCHIVOS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + a))
		if FileAccess.file_exists("user://" + a + ".bak_mono"):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a + ".bak_mono"), ProjectSettings.globalize_path("user://" + a))


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 700
	var s0 := int(args[1]) if args.size() > 1 else 4100
	_datos = Datos.cargar_todo()
	_huella = Datos.huella(_datos)
	_respaldar()
	Tutorial.ruta = "user://preferencias_mono.json"
	Ajustes.texto_grande = true
	Movimiento.forzado = 1
	for i in range(TAMANOS.size()):
		await _tamano(TAMANOS[i], n, s0 + i)
	Ajustes.texto_grande = false
	Movimiento.forzado = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	_restaurar()
	print("FUZZ MONO %s (%d entradas, %d pausas, %d pantallas distintas: %s, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", _entradas, _pausas, _pantallas.size(), ", ".join(_pantallas.keys()), _fallos])
	quit(1 if _fallos > 0 else 0)


func _ev_mouse(pos: Vector2, presionado: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = pos
	e.global_position = pos
	e.pressed = presionado
	return e


func _push(e: InputEvent) -> void:
	root.push_input(e, false)


func _controles(main: Node) -> Array[Control]:
	var r: Array[Control] = []
	for c in main.find_children("*", "Control", true, false):
		if (c as Control).is_visible_in_tree() and (c is BaseButton or c is LineEdit or c is OptionButton):
			var rc := (c as Control).get_global_rect()
			if rc.size.x > 2.0 and rc.size.y > 2.0:
				r.append(c)
	return r


func _centro(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


func _toque(p: Vector2) -> void:
	_push(_ev_mouse(p, true))
	_push(_ev_mouse(p, false))


func _arrastre(a: Vector2, b: Vector2, pasos: int) -> void:
	_push(_ev_mouse(a, true))
	for k in range(1, pasos + 1):
		var m := InputEventMouseMotion.new()
		m.position = a.lerp(b, float(k) / pasos)
		m.global_position = m.position
		m.relative = (b - a) / pasos
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		_push(m)
	_push(_ev_mouse(b, false))


func _inv(main: Node, ctx: String) -> void:
	_check(main._pantalla != null and is_instance_valid(main._pantalla), "%s: main._pantalla nula o liberada" % ctx)
	if main._pantalla == null or not is_instance_valid(main._pantalla):
		return
	_pantallas[main._pantalla.get_script().get_global_name() if main._pantalla.get_script() != null else main._pantalla.get_class()] = true
	if main.motor != null:
		for k in main.motor.estado.indicadores:
			var v: float = float(main.motor.estado.indicadores[k])
			_check(is_finite(v), "%s: indicador %s no finito" % [ctx, k])


func _pausar(main: Node, ctx: String) -> void:
	if main.motor == null:
		main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		main._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		return
	_pausas += 1
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var g: Variant = Datos.leer_json("user://guardado.json")
	_check(g is Dictionary and ValidarGuardado.guardado_valido(g), "%s: tras la pausa el guardado no es válido (pantalla %s, etapa %s, existe=%s)" % [ctx, str(main._pantalla.get_script().get_global_name()), main.motor.estado.etapa, str(FileAccess.file_exists("user://guardado.json"))])
	if g is Dictionary and ValidarGuardado.guardado_valido(g):
		var rep := Partida.reproducir(_datos, g)
		_check(rep != null and rep.estado.calcular_huella() == main.motor.estado.calcular_huella(), "%s: tras la pausa el guardado no reproduce el motor en vivo (pantalla %s, etapa %s, turno %d, entradas %d/%d, dif %s, sem_disco %s, sem_vivo %s, tmp=%s)" % [ctx, str(main._pantalla.get_script().get_global_name()), main.motor.estado.etapa, main.motor.estado.turno_actual, (g["entradas"] as Array).size(), main.motor.estado.entradas.size(), str(AyudaFuzz.diferencias(rep, main.motor)) if rep != null else "rep nulo", str(g.get("semilla")), str(main.motor.estado.semilla), str(FileAccess.file_exists("user://guardado.json.tmp"))])
	main._notification(Node.NOTIFICATION_APPLICATION_RESUMED)


func _paso(main: Node, rng: RandomNumberGenerator, tam: Vector2i, ctx: String) -> void:
	var t := rng.randf()
	var cs := _controles(main)
	if t < 0.35 and not cs.is_empty():
		_toque(_centro(cs[rng.randi_range(0, cs.size() - 1)]))
	elif t < 0.5:
		_toque(Vector2(rng.randf() * tam.x, rng.randf() * tam.y))
	elif t < 0.6 and not cs.is_empty():
		var p := _centro(cs[rng.randi_range(0, cs.size() - 1)])
		_toque(p)
		_toque(p)  # doble toque
	elif t < 0.75:
		var a := Vector2(rng.randf() * tam.x, rng.randf() * tam.y)
		_arrastre(a, Vector2(rng.randf() * tam.x, rng.randf() * tam.y), rng.randi_range(2, 8))
	elif t < 0.82 and not cs.is_empty():  # arrastre hacia arriba desde una carta o botón (jugar carta)
		var p2 := _centro(cs[rng.randi_range(0, cs.size() - 1)])
		_arrastre(p2, p2 + Vector2(0, -rng.randf_range(80.0, 300.0)), 6)
	elif t < 0.87:
		var w := InputEventMouseButton.new()
		w.button_index = MOUSE_BUTTON_WHEEL_UP if rng.randf() < 0.5 else MOUSE_BUTTON_WHEEL_DOWN
		w.position = Vector2(rng.randf() * tam.x, rng.randf() * tam.y)
		w.pressed = true
		_push(w)
	elif t < 0.91:
		var k := InputEventKey.new()
		k.keycode = KEY_ESCAPE
		k.pressed = true
		_push(k)
		k = InputEventKey.new()
		k.keycode = KEY_ESCAPE
		k.pressed = false
		_push(k)
	elif t < 0.95:
		if not (main._pantalla is PantallaMenu):  # en el menú el segundo Atrás sale del juego (get_tree().quit()): es lo esperado, pero cortaría la prueba
			root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)  # botón atrás de Android, como lo manda el motor: a todo el árbol
	else:
		_pausar(main, ctx)
	_entradas += 1


func _tamano(tam: Vector2i, n: int, semilla: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	root.size = tam
	var ctx := "tamaño %dx%d semilla %d" % [tam.x, tam.y, semilla]
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in range(n):
		await _paso_seguro(main, rng, tam, "%s paso %d" % [ctx, i])
		if i % 3 == 0:
			await process_frame
		_inv(main, "%s paso %d" % [ctx, i])
		if main._pantalla == null or not is_instance_valid(main._pantalla):
			break
		if i % 150 == 149 and main.motor == null:  # el mono se quedó en los menús: se le abre una partida rápida para que recorra el juego
			main._repetir_ultima()
			await process_frame
	_pausar(main, ctx + " [final]")
	main.queue_free()
	await process_frame


func _paso_seguro(main: Node, rng: RandomNumberGenerator, tam: Vector2i, ctx: String) -> void:
	_paso(main, rng, tam, ctx)
