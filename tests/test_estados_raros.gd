extends SceneTree
## Estados raros del día: mano vacía, 0 movimientos, delegaciones agotadas, cada indicador en 0 y en 100, y la última semana antes de la elección (campaña)
## o del mandato (gobierno). En cada estado la pantalla del día se redibuja sin errores, el botón principal existe, mide ≥ 44 px y está en la banda baja,
## los textos no muestran valores sin formatear, y terminar la semana lleva a una pantalla válida (sin callejones sin salida) con el estado coherente.
## Respalda y restaura los archivos de usuario.

const ARCHIVOS := ["guardado.json", "guardado.cache", "guardado.bak", "ultima_config.json", "guardado_descartado.json"]
const IND := ["aprobacion", "capital", "cohesion", "fiscal", "riesgo_ejecucion"]

var _fallos := 0
var _casos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _estados(datos: Dictionary) -> Array:
	var casos: Array = []
	casos.append(["mano vacía", func(e: EstadoSimulacion) -> void: e.mano.clear()])
	casos.append(["0 movimientos", func(e: EstadoSimulacion) -> void: e.pa_actual = 0])
	casos.append(["delegaciones agotadas", func(e: EstadoSimulacion) -> void: e.delegadas_turno = int(datos["leyes"]["delegacion"]["max_por_turno"])])
	for ind in IND:
		for v in [0.0, 100.0]:
			casos.append(["%s en %d" % [ind, int(v)], func(e: EstadoSimulacion) -> void: e.indicadores[ind] = v])
	return casos


func _revisar(main: Node, ctx: String) -> void:
	_check(main._pantalla != null and is_instance_valid(main._pantalla), ctx + ": no hay pantalla")
	if main._pantalla == null or not is_instance_valid(main._pantalla):
		return
	for b in AyudaTextos.basura(main._pantalla):
		_check(false, "%s: texto con valores sin formatear: %s" % [ctx, b])
	if main._pantalla is PantallaDia:
		var btn: Button = main._pantalla._btn_jugar
		_check(btn != null and is_instance_valid(btn), ctx + ": falta el botón principal")
		if btn != null and is_instance_valid(btn):
			var r := btn.get_global_rect()
			_check(r.size.y >= 44.0 and r.position.x >= -0.5 and r.end.x <= Tema.ANCHO + 0.5 and r.position.y > 600.0, "%s: botón principal fuera de sitio (%s)" % [ctx, str(r)])
	for k in main.motor.estado.indicadores:
		_check(is_finite(float(main.motor.estado.indicadores[k])), "%s: indicador %s no finito" % [ctx, k])


func _probar(main: Node, ctx: String, aplicar: Callable) -> void:
	_casos += 1
	aplicar.call(main.motor.estado)
	main.mostrar_dia()
	await process_frame
	await process_frame
	_revisar(main, ctx + " [redibujado]")
	if main._pantalla is PantallaDia:
		var dia: Node = main._pantalla
		var turno0: int = main.motor.estado.turno_actual
		var dia0: int = main.motor.estado.dia_actual
		var etapa0: String = main.motor.estado.etapa
		dia._btn_jugar.pressed.emit()
		if is_instance_valid(dia) and dia._confirmar_fin:
			dia._btn_jugar.pressed.emit()
		for _i in range(4):
			await process_frame
		var e: EstadoSimulacion = main.motor.estado
		_check(e.turno_actual != turno0 or e.dia_actual != dia0 or e.etapa != etapa0 or not (main._pantalla is PantallaDia) or main._pantalla != dia, "%s: terminar la semana no avanzó nada (callejón sin salida)" % ctx)
		_revisar(main, ctx + " [tras terminar la semana]")
		var fallos := AyudaInvariantes.revisar(main.motor, ctx)
		for f in fallos:
			_check(false, "%s: invariante: %s" % [ctx, f])


func _correr() -> void:
	for a in ARCHIVOS:
		if FileAccess.file_exists("user://" + a):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a), ProjectSettings.globalize_path("user://" + a + ".bak_raros"))
	Tutorial.ruta = "user://preferencias_raros.json"
	Movimiento.forzado = 1
	var datos := Datos.cargar_todo()
	var sem_camp := int(datos["leyes"]["hemiciclo"]["semanas_campana"])
	for etapa in ["campana", "gobierno"]:
		for caso in _estados(datos):
			var main: Node = load("res://game/main.tscn").instantiate()
			root.add_child(main)
			await process_frame
			if etapa == "campana":
				main._repetir_ultima()
			else:
				main.datos = datos
				main.motor = AyudaV2.gobierno(datos, 21)
				main.motor.elegir_gabinete(main.motor.estado.gabinete.duplicate())  # transición presidencial: con el gabinete confirmado se muestra el día
				main.mostrar_dia()
			await process_frame
			await _probar(main, "%s / %s" % [etapa, caso[0]], caso[1])
			main.queue_free()
			await process_frame
	# última semana antes de la elección (campaña) y del mandato (gobierno)
	var main2: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main2)
	await process_frame
	main2._repetir_ultima()
	await process_frame
	await _probar(main2, "campaña / última semana", func(e: EstadoSimulacion) -> void: e.turno_actual = sem_camp)
	main2.queue_free()
	await process_frame
	var main3: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main3)
	await process_frame
	main3.datos = datos
	main3.motor = AyudaV2.gobierno(datos, 22)
	main3.motor.elegir_gabinete(main3.motor.estado.gabinete.duplicate())  # transición presidencial
	main3.mostrar_dia()
	await process_frame
	var ult := int(datos["leyes"]["hemiciclo"]["turnos_mandato"]) if datos["leyes"]["hemiciclo"].has("turnos_mandato") else 208
	await _probar(main3, "gobierno / última semana", func(e: EstadoSimulacion) -> void:
		e.turno_actual = ult
		e.dia_actual = (ult - 1) * e.dias_por_turno + 1)
	main3.queue_free()
	await process_frame
	Movimiento.forzado = -1
	for a in ARCHIVOS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + a))
		if FileAccess.file_exists("user://" + a + ".bak_raros"):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a + ".bak_raros"), ProjectSettings.globalize_path("user://" + a))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	if _fallos == 0:
		print("test_estados_raros: OK (%d estados)" % _casos)
	quit(1 if _fallos > 0 else 0)
