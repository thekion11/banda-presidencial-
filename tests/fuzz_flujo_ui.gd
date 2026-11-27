extends SceneTree
## Fuzz del FLUJO COMPLETO de la interfaz: afiliación -> test ideológico -> fundación -> gabinete -> campaña -> elección -> gobierno, con entradas aleatorias
## e inválidas (nombre vacío, muy largo o con caracteres raros, doble toque en «fundar», toque tardío en el test, gabinete manipulado, acciones muy seguidas) y
## pausas de la aplicación (NOTIFICATION_APPLICATION_PAUSED) en puntos aleatorios. Invariantes: nunca queda `main._pantalla` nula o liberada; una pantalla de
## partida siempre tiene `motor`; el botón principal de la pantalla del día existe, mide al menos 44 px y está en la banda baja de la pantalla; tras una pausa
## el guardado y la instantánea en disco se reproducen con la misma huella que el motor en vivo; al final, reproducir(guardado) da la misma huella.
## 3 afiliaciones × 3 dificultades (rotan con la semilla). Respalda y restaura los archivos de usuario (guardado, caché, última configuración, preferencias).
## Uso: godot --headless --path . -s tests/fuzz_flujo_ui.gd -- [partidas] [semilla_inicial]

const ARCHIVOS := ["guardado.json", "guardado.cache", "guardado.bak", "ultima_config.json", "guardado_descartado.json"]
const AFILIACIONES := ["propio", "independiente", "existente"]
const DIFICULTADES := ["facil", "normal", "dificil"]

var _fallos: int = 0
var _pausas: int = 0
var _llegaron_gobierno: int = 0
var _eleccion_vista: int = 0
var _datos: Dictionary
var _huella: String
var _revisar_basura: bool = true  # se apaga en las partidas cuyo nombre de partido (escrito por el jugador) trae marcadores como %s, llaves o corchetes
var _basuras: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ FLUJO UI: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _respaldar() -> void:
	for a in ARCHIVOS:
		if FileAccess.file_exists("user://" + a):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a), ProjectSettings.globalize_path("user://" + a + ".bak_fuzz"))


func _restaurar() -> void:
	for a in ARCHIVOS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + a))
		if FileAccess.file_exists("user://" + a + ".bak_fuzz"):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a + ".bak_fuzz"), ProjectSettings.globalize_path("user://" + a))


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 9
	var s0 := int(args[1]) if args.size() > 1 else 2100
	_datos = Datos.cargar_todo()
	_huella = Datos.huella(_datos)
	_respaldar()
	Tutorial.ruta = "user://preferencias_fuzz_flujo.json"
	Movimiento.forzado = 1
	for i in range(n):
		await _una(s0 + i, i)
	Movimiento.forzado = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	_restaurar()
	print("FUZZ FLUJO UI %s (%d partidas, %d pausas comprobadas, %d elecciones vistas, %d llegaron a gobernar, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _pausas, _eleccion_vista, _llegaron_gobierno, _fallos])
	quit(1 if _fallos > 0 else 0)


func _boton(raiz: Node, empieza: String) -> Button:
	for b in raiz.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(empieza) and not (b as Button).disabled and (b as Button).is_visible_in_tree():
			return b
	return null


func _nombre_raro(rng: RandomNumberGenerator) -> String:
	var casos := ["", "   ", "Partido de Prueba", "A", "ñandú éxito ü", "x".repeat(300), "[b]negrita[/b]", "línea\nnueva", "\t\t", "%s %d", "🙂🙂🙂", "'; DROP TABLE;--", "ÁÉÍÓÚ ÑÑ"]
	return String(casos[rng.randi_range(0, casos.size() - 1)])


func _inv(main: Node, ctx: String, donde: String) -> void:
	if _revisar_basura and is_instance_valid(main._pantalla):
		for b in AyudaTextos.basura(main._pantalla):
			_basuras += 1
			_check(false, "%s (%s): texto con valores sin formatear: %s" % [ctx, donde, b])
	_check(main._pantalla != null and is_instance_valid(main._pantalla), "%s (%s): main._pantalla nula o liberada" % [ctx, donde])
	if main._pantalla == null or not is_instance_valid(main._pantalla):
		return
	if main._pantalla is PantallaDia or main._pantalla is PantallaGabinete or main._pantalla is PantallaFin:
		_check(main.motor != null, "%s (%s): pantalla de partida sin motor" % [ctx, donde])
	if main._pantalla is PantallaDia and main.motor != null:
		var b: Button = main._pantalla._btn_jugar
		_check(b != null and is_instance_valid(b), "%s (%s): falta el botón principal" % [ctx, donde])
		if b != null and is_instance_valid(b):
			var r := b.get_global_rect()
			_check(r.size.y >= 44.0 and r.position.x >= -0.5 and r.end.x <= 390.5 and r.position.y > 600.0 and r.end.y <= 844.5, "%s (%s): botón principal fuera de sitio (%s)" % [ctx, donde, str(r)])


func _pulsar_avanzar(dia: Node) -> void:
	## Pulsa el botón principal de la pantalla del día; si pidió confirmar (movimientos que sobran o pocas promesas), lo pulsa de nuevo.
	dia._btn_jugar.pressed.emit()
	if dia._confirmar_fin:
		dia._btn_jugar.pressed.emit()


func _huella_motor(m: MotorTurno) -> String:
	return m.estado.calcular_huella()


func _pausar_y_comprobar(main: Node, ctx: String) -> void:
	if main.motor == null:
		return
	_pausas += 1
	main._notification(NOTIFICATION_APPLICATION_PAUSED)
	var g: Variant = Datos.leer_json("user://guardado.json")
	_check(g is Dictionary and g.has("semilla") and g.has("entradas") and String(g.get("huella_datos", "")) == _huella, "%s: tras la pausa el guardado no es válido" % ctx)
	if g is Dictionary and g.has("entradas"):
		var rep := Partida.reproducir(_datos, g)
		_check(rep != null and rep.estado.calcular_huella() == _huella_motor(main.motor), "%s: tras la pausa, el guardado en disco no reproduce el motor en vivo" % ctx)
		if FileAccess.file_exists("user://guardado.cache"):
			var snap := Instantanea.leer(FileAccess.get_file_as_bytes("user://guardado.cache"))
			var sha := FileAccess.get_sha256("user://guardado.json")
			if Instantanea.vale_para(snap, _huella, sha):
				var rest := Partida.cargar(_datos, g, snap, _huella, sha)
				var dif := AyudaFuzz.diferencias(rest, main.motor)
				_check(dif.is_empty(), "%s: tras la pausa, la instantánea en disco difiere del motor en %s" % [ctx, str(dif)])


func _una(semilla: int, idx: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var afil: String = AFILIACIONES[idx % 3]
	var dif: String = DIFICULTADES[(idx / 3) % 3]
	var ctx := "semilla %d (%s, %s)" % [semilla, afil, dif]
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# 1) afiliación
	main.mostrar_afiliacion()
	await process_frame
	_check(main._pantalla is PantallaAfiliacion, ctx + ": no se muestra la afiliación")
	_inv(main, ctx, "afiliación")
	var base: Dictionary = {}
	if afil == "existente":
		main._pantalla._elegir("existente")  # la lista de partidos
		await process_frame
		base = _datos["coalicion"][rng.randi_range(0, _datos["coalicion"].size() - 1)]
	main.mostrar_partido(afil, base)
	await process_frame
	# 2) test ideológico
	var pp: Node = main._pantalla
	_check(pp is PantallaPartido, ctx + ": no se muestra el test/fundación")
	if not (pp is PantallaPartido):
		main.queue_free()
		return
	if afil != "existente" and rng.randf() < 0.4:
		pp._rapido = false  # el test completo (8 preguntas)
	for p in pp._preguntas():
		pp._responder(p["opciones"][rng.randi_range(0, 2)])
		if rng.randf() < 0.3:
			await process_frame
	await process_frame
	_inv(main, ctx, "test")
	if rng.randf() < 0.2:  # toque tardío sobre una opción cuando el test ya terminó
		pp._responder(_datos["ideologia"]["preguntas"][0]["opciones"][0])
		await process_frame
	# 3) fundación con entradas raras
	pp._nombre.text = _nombre_raro(rng)
	_revisar_basura = not (pp._nombre.text.contains("%") or pp._nombre.text.contains("{") or pp._nombre.text.contains("[") or pp._nombre.text.to_lower().contains("null"))
	pp._sigla.text = _nombre_raro(rng).left(rng.randi_range(0, 6))
	for ob in [pp._region, pp._dificultad, pp._habilidad]:
		ob.select(rng.randi_range(0, ob.item_count - 1))
	for k in range(pp._dificultad.item_count):  # la dificultad que toca en esta partida
		if String(pp._dificultad.get_item_metadata(k)) == dif:
			pp._dificultad.select(k)
	pp._fundar()
	if rng.randf() < 0.2:
		pp._fundar()  # doble toque
	await process_frame
	await process_frame
	_check(main.motor != null, ctx + ": tras fundar no hay motor")
	_inv(main, ctx, "fundación")
	if rng.randf() < 0.3:
		_pausar_y_comprobar(main, ctx + " [pausa tras fundar]")
	# 4) gabinete
	if main._pantalla is PantallaGabinete:
		var filas: Array = main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "" and b.get_child_count() > 0)
		for _t in range(rng.randi_range(0, 12)):
			if not filas.is_empty():
				(filas[rng.randi_range(0, filas.size() - 1)] as Button).pressed.emit()
		for txt in ["Equilibrado", "Máxima eficacia"]:
			var rb := _boton(main._pantalla, txt)
			if rb != null and rng.randf() < 0.5:
				rb.pressed.emit()
		var conf := _boton(main._pantalla, "Comenzar campaña")
		if conf == null:  # con menos ministros de los necesarios no se puede confirmar: se rellena
			var rel := _boton(main._pantalla, "Equilibrado")
			if rel != null:
				rel.pressed.emit()
			conf = _boton(main._pantalla, "Comenzar campaña")
		_check(conf != null, ctx + ": el gabinete no se puede confirmar")
		if conf != null:
			conf.pressed.emit()
		await process_frame
	_inv(main, ctx, "tras el gabinete")
	var dia: Node = main._pantalla
	_check(dia is PantallaDia, ctx + ": no se llegó a la pantalla del día")
	if not (dia is PantallaDia):
		main.queue_free()
		return
	for t in dia._capa.find_children("*", "Tutorial", true, false):
		t.queue_free()
	await process_frame
	# 5) campaña, elección y gobierno
	var regiones: Array = _datos["regiones"].map(func(r: Dictionary) -> String: return String(r["id"]))
	var paneles := ["comite", "congreso", "gabinete", "mapa"]
	var sem_camp := int(_datos["leyes"]["hemiciclo"]["semanas_campana"])
	var turnos := 0
	var gobierno_visto := false
	while turnos < 26 and is_instance_valid(main._pantalla) and main._pantalla is PantallaDia:
		turnos += 1
		dia = main._pantalla
		var est: EstadoSimulacion = main.motor.estado
		var permanentes: Array = dia._capa.get_children()  # lo que ya estaba: toast, capas y demás piezas fijas de la pantalla
		for _a in range(rng.randi_range(2, 10)):
			if not is_instance_valid(main._pantalla) or main._pantalla != dia:
				break
			match rng.randi_range(0, 6):
				0:
					dia._on_region(regiones[rng.randi_range(0, regiones.size() - 1)])
				1, 2:
					dia._on_carta(rng.randi_range(0, 4))
					dia._on_carta(dia._sel)
				3:
					dia._jugar()
				4:
					dia._delegar()
				5:
					dia._abrir_panel(paneles[rng.randi_range(0, 3)])
				6:
					dia._cola_eventos.clear()
			for _k in range(rng.randi_range(0, 2)):
				await process_frame
		if not is_instance_valid(main._pantalla) or main._pantalla != dia:
			break
		_inv(main, ctx, "turno %d" % turnos)
		if rng.randf() < 0.15:
			_pausar_y_comprobar(main, ctx + " [pausa en el turno %d]" % turnos)
		dia._cola_eventos.clear()
		if est.eleccion_pendiente(sem_camp):
			_eleccion_vista += 1
			_pulsar_avanzar(dia)  # el botón real del medio: pide confirmar con pocas promesas y lleva a las urnas
			for _k in range(3):
				await process_frame
			var abierta := false
			for texto in ["Asumir el gobierno", "Ir a la segunda", "Ver resultado final"]:
				var b := _boton(dia._capa, texto)
				if b != null:
					abierta = true
					b.pressed.emit()
					break
			_check(abierta, "%s: con la elección pendiente, el botón de avanzar no abrió la pantalla de resultado" % ctx)
			for _k in range(3):
				await process_frame
		else:
			_pulsar_avanzar(dia)
			for _k in range(rng.randi_range(0, 3)):
				await process_frame
		for ov in (dia._capa.get_children() if is_instance_valid(dia) else []):  # cierra solo los telones y avisos nuevos de este turno (no las piezas fijas de la pantalla)
			if is_instance_valid(ov) and ov is Control and not permanentes.has(ov):
				ov.queue_free()
		await process_frame
		if main.motor != null and main.motor.estado.etapa == "gobierno":
			gobierno_visto = true
		_inv(main, ctx, "tras el turno %d" % turnos)
	_llegaron_gobierno += 1 if gobierno_visto else 0
	_inv(main, ctx, "final")
	# 6) lo guardado se reproduce idéntico
	if main.motor != null:
		var g: Dictionary = JSON.parse_string(JSON.stringify(main.motor.estado.exportar_guardado(_huella)))
		_check(Partida.reproducir(_datos, g).estado.calcular_huella() == _huella_motor(main.motor), ctx + ": al final, reproducir(guardado) no da la misma huella que el motor de la interfaz")
		_pausar_y_comprobar(main, ctx + " [pausa final]")
	main.queue_free()
	await process_frame
