extends SceneTree
## Primera ejecución con instalación limpia (informe, no prueba del CI; cola 5 de la coordinadora): sin guardado, sin
## «última configuración» y sin tutorial visto, recorre menú → afiliación → test → fundación → gabinete → día con
## tutorial → primera carta jugada pulsando los botones reales. Cuenta toques, estima segundos (lectura a 4 palabras/s
## más 1 s por toque), avisa de pantallas sin un botón claro y guarda una captura por paso.
## Uso: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/primera_ejecucion.gd -- docs/comparacion

const PALABRAS_POR_S := 4.0
const S_POR_TOQUE := 1.0

var _dir := "docs/comparacion"
var _main: Node
var _filas: Array = []  # [paso, toques, palabras, segundos, nota]
var _n := 0
var _avisos: Array[String] = []


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_dir = a[0]
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


static func _en_vista(c: Control) -> bool:
	return c.is_visible_in_tree() and not c.is_queued_for_deletion()


func _botones() -> Array:
	return _main.find_children("*", "BaseButton", true, false).filter(func(b: BaseButton) -> bool: return _en_vista(b) and not b.disabled)


func _palabras() -> int:
	var n := 0
	var pantalla := Rect2(Vector2.ZERO, Vector2(Tema.ANCHO, root.get_visible_rect().size.y))
	for l in _main.find_children("*", "Control", true, false):
		if (l is Label or l is Button) and _en_vista(l) and pantalla.encloses((l as Control).get_global_rect()):  # lo que se ve entero, no lo que está más abajo en una lista
			n += String(l.get("text")).split(" ", false).size()
	return n


func _captura(nombre: String) -> void:
	await _cuadros(4)
	await create_timer(0.6).timeout
	_n += 1
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("%s/primera_ejecucion_%02d_%s.png" % [_dir, _n, nombre])


func _pulsar(prefijo: String) -> bool:
	for b in _botones():
		var t := String(b.get("text"))
		if t.begins_with(prefijo):
			(b as BaseButton).pressed.emit()
			return true
	_avisos.append("no se encontró «%s» entre: %s" % [prefijo, ", ".join(_botones().map(func(b: BaseButton) -> String: return "«%s»" % String(b.get("text")).replace("\n", " / ").left(40)))])
	return false


func _paso(nombre: String, toques: int, nota: String = "") -> void:
	## Registra el paso ya en pantalla: captura, palabras visibles y segundos estimados.
	await _captura(nombre)
	var pal := _palabras()
	var claro := _botones().any(func(b: BaseButton) -> bool: return b is Button and (b as Button).custom_minimum_size.y >= 48.0)
	if not claro:
		nota += (" · " if nota != "" else "") + "sin botón principal claro"
	_filas.append([nombre, toques, pal, pal / PALABRAS_POR_S + toques * S_POR_TOQUE, nota])


func _correr() -> void:
	Movimiento.forzado = 0
	for r in ["user://guardado.json", "user://guardado.bak", "user://guardado.cache", "user://ultima_config.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	Tutorial.ruta = "user://preferencias_primera.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)
	await _cuadros(2)
	var menu: Control = _main._pantalla
	var extra := _botones().filter(func(b: BaseButton) -> bool: return String(b.get("text")).begins_with("Continuar") or String(b.get("text")).contains("última"))
	await _paso("menu", 0, "instalación limpia: %s" % ("sin «Continuar» ni «como la última vez»" if extra.is_empty() else "aparece un botón de partida previa"))
	_pulsar("Nueva partida")
	await _cuadros(2)
	await _paso("afiliacion", 1)
	_pulsar("Fundar")  # primera tarjeta: partido propio
	await _cuadros(2)
	var preguntas := 0
	var pp: Node = _main._pantalla
	await _paso("test_pregunta_1", 1, "test de %s" % ("3 preguntas (rápido)" if bool(pp.get("_rapido")) else "8 preguntas"))
	for _i in range(12):
		if not (pp.get("_paso") is int) or pp.find_children("*", "LineEdit", true, false).any(func(n: Node) -> bool: return _en_vista(n)):
			break
		var ops: Array = _botones().filter(func(b: BaseButton) -> bool: return (b as Control).custom_minimum_size.y >= 56.0 and not String(b.get("text")).begins_with("Hacer") and not String(b.get("text")).begins_with("Volver"))
		if ops.is_empty():
			break
		(ops[0] as BaseButton).pressed.emit()
		preguntas += 1
		await _cuadros(3)
	await _paso("fundacion", preguntas, "%d respuestas; nombre, sigla y región ya vienen escritos" % preguntas)
	_pulsar("Iniciar Campaña")
	await _cuadros(3)
	var tras: String = "" if _main._pantalla == null else String(_main._pantalla.get_script().get_global_name())
	if tras == "PantallaGabinete":
		await _paso("gabinete", 1)
		_pulsar("Comenzar campaña")
		await _cuadros(4)
	var dia: PantallaDia = _main._pantalla if _main._pantalla is PantallaDia else null
	if dia == null:
		_avisos.append("tras la fundación no llega al día (%s)" % tras)
	else:
		await _paso("dia_tutorial_1", 1, "el tutorial se abre solo")
		var pasos_tut := 0
		for _i in range(12):
			if _pulsar("Siguiente"):
				pasos_tut += 1
				await _cuadros(2)
			else:
				_avisos.pop_back()
				break
		_pulsar("Entendido")
		await _cuadros(3)
		await _paso("dia_sin_tutorial", pasos_tut + 1, "%d pasos de tutorial" % (pasos_tut + 1))
		var antes: int = dia.motor.estado.entradas.size()
		var toques := 0
		for _i in range(3):  # tocar la carta elige; tocar la elegida la juega (la mano se repinta: se vuelve a buscar)
			if dia.motor.estado.entradas.size() > antes:
				break
			var mano := dia.find_children("*", "CartaUI", true, false).filter(func(c: Node) -> bool: return _en_vista(c))
			if mano.is_empty():
				break
			var elegidas := mano.filter(func(c: CartaUI) -> bool: return c.elegida)
			var c: CartaUI = elegidas[0] if not elegidas.is_empty() else mano[0]
			c.tocada.emit(c)
			toques += 1
			await _cuadros(3)
		var jugo: bool = dia.motor.estado.entradas.size() > antes
		await _paso("primera_carta", toques, "carta jugada" if jugo else "LA CARTA NO SE JUGÓ")
		if not jugo:
			_avisos.append("la primera carta no se jugó con %d toques" % toques)
	var total_t := 0
	var total_s := 0.0
	print("| Paso | Toques | Palabras en pantalla | Segundos estimados | Nota |")
	print("|---|---|---|---|---|")
	for f in _filas:
		total_t += int(f[1])
		total_s += float(f[3])
		print("| %s | %d | %d | %.0f | %s |" % f)
	print("| **Total** | **%d** | | **%.0f s (≈ %.1f min)** | |" % [total_t, total_s, total_s / 60.0])
	for a in _avisos:
		print("AVISO: ", a)
	for r in [Tutorial.ruta, "user://guardado.json", "user://guardado.bak", "user://guardado.cache", "user://ultima_config.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	quit()
