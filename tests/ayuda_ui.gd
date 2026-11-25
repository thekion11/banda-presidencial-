class_name AyudaUI
extends RefCounted
## Utilidades de las pruebas de interfaz (mantiene test_ui_humo.gd bajo el límite de líneas).


static func deslizar_arriba(mano: Control) -> void:
	## Simula pulsar en el centro de la mano y soltar 120 px más arriba (gesto de jugar de PR-02).
	var c0: Vector2 = mano.get_global_rect().get_center()
	for par in [[true, c0], [false, c0 + Vector2(5, -120)]]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = par[0]
		ev.position = par[1]
		mano._input(ev)


static func controles_dia(dia: Control) -> Array[String]:
	## PR-02: tocar dos veces la carta elegida la juega; el botón del medio pide confirmar si sobran movimientos. Devuelve los fallos.
	var fallos: Array[String] = []
	var est: EstadoSimulacion = dia.motor.estado
	if est.pa_actual > 0 and est.mano.size() > 0:
		var pa0: int = est.pa_actual
		dia._mano_tocada = false
		dia._on_carta(0)
		if est.pa_actual != pa0:
			fallos.append("el primer toque solo elige la carta")
		dia._on_carta(0)
		if est.pa_actual >= pa0:
			fallos.append("el segundo toque sobre la carta elegida debe jugarla")
	if est.pa_actual > 0:
		var turno0: int = est.turno_actual
		dia._confirmar_fin = false
		dia._avanzar()
		if est.turno_actual != turno0 or not dia._confirmar_fin:
			fallos.append("con movimientos sin usar, avanzar pide confirmación")
		dia._confirmar_fin = false
	return fallos


static func carrera(arbol: SceneTree) -> Array[String]:
	## Carrera política en la interfaz: tras una derrota el botón «Seguir tu carrera» lleva a la oposición, con su cabecera y su mano.
	var fallos: Array[String] = []
	var main: Node = load("res://game/main.tscn").instantiate()
	arbol.root.add_child(main)
	await arbol.process_frame
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(main.datos, 9, GeneradorPartido.construir_partido("U", "UUU", "metropolitana", resp, main.datos["ideologia"]))
	for _i in range(int(main.datos["leyes"]["hemiciclo"]["semanas_campana"])):
		main.motor.terminar_turno()
	main.motor.resolver_eleccion_presidencial()
	main.mostrar_fin()
	await arbol.process_frame
	var bs: Array = main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Seguir tu carrera"))
	if bs.size() != 1:
		fallos.append("la pantalla de fin ofrece seguir la carrera")
	else:
		bs[0].pressed.emit()
		for _k in range(4):
			await arbol.process_frame
		if not (main._pantalla is PantallaDia) or main.motor.estado.etapa != "oposicion":
			fallos.append("seguir la carrera lleva a la oposición")
		elif not String(main._pantalla._r["dia"].text).begins_with("Oposición"):
			fallos.append("la cabecera dice Oposición")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ultima_config.json"))  # instalación nueva: la partida rápida usa el partido por defecto
	main._repetir_ultima()
	await arbol.process_frame
	if not (main._pantalla is PantallaDia) or main.motor.estado.etapa != "campana":
		fallos.append("la partida rápida sin configuración previa va directo al mapa")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ultima_config.json"))
	# Ajustes: se guardan y se cargan; el menú ofrece el botón
	Ajustes.sonido = false
	Ajustes.guardar()
	Ajustes.sonido = true
	Ajustes.cargar()
	if Ajustes.sonido:
		fallos.append("los ajustes se guardan y se cargan")
	Ajustes.sonido = true
	Ajustes.guardar()
	main.mostrar_menu()
	await arbol.process_frame
	if main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "Ajustes").size() != 1:
		fallos.append("el menú ofrece Ajustes")
	Feedback.sonar("jugar")  # sin dispositivo de audio no debe fallar
	Feedback.vibrar(10)
	main.queue_free()
	return fallos
