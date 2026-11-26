extends SceneTree
## Botón Atrás de Android (Main.atras): nunca sale al primer toque, cierra primero lo que está encima, no salta un evento
## y deja siempre una pantalla válida con el guardado al día. Hallazgo de «Búsqueda infinita de fallas»; comportamiento
## propuesto por la sesión del motor (cierra el nivel de arriba; en el día pide confirmar antes de ir al menú).

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


func _capas(dia: PantallaDia) -> Array:
	return dia._capa.get_children().filter(func(h: Node) -> bool: return h != dia._toast and not h.is_queued_for_deletion())


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_atras.json"
	Tutorial.marcar_visto()
	_check(not ProjectSettings.get_setting("application/config/quit_on_go_back", true), "project.godot desactiva quit_on_go_back")
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	# menú: Ajustes y créditos se cierran con Atrás; el menú pide un segundo Atrás para salir
	main._pantalla.add_child(PantallaAjustes.new())
	await _cuadros(2)
	main.atras()
	await _cuadros(2)
	_check(main._pantalla is PantallaMenu and main._pantalla.find_children("*", "PantallaAjustes", true, false).filter(func(n: Node) -> bool: return not n.is_queued_for_deletion()).is_empty(), "Atrás cierra Ajustes")
	main._pantalla._mostrar_creditos()
	await _cuadros(1)
	main.atras()
	await _cuadros(2)
	_check(main._pantalla._creditos == null, "Atrás cierra los créditos")
	main.atras()
	await _cuadros(1)
	_check(main._pantalla is PantallaMenu and main._aviso_atras.visible, "en el menú el primer Atrás solo avisa (no sale)")
	main._atras_ms = -100000
	# afiliación -> menú
	main.mostrar_afiliacion()
	await _cuadros(1)
	main.atras()
	await _cuadros(1)
	_check(main._pantalla is PantallaMenu, "desde la afiliación Atrás vuelve al menú")
	# pantalla del día
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(main.datos, 17, GeneradorPartido.construir_partido("A", "A", "metropolitana", resp, main.datos["ideologia"]))
	main.mostrar_dia()
	await _cuadros(2)
	var dia: PantallaDia = main._pantalla
	dia._abrir_panel("comite")
	await _cuadros(1)
	main.atras()
	await _cuadros(1)
	_check(not dia._zona_panel.visible and main._pantalla == dia, "con un panel abierto Atrás vuelve al mapa")
	dia._abrir_urbano()
	await _cuadros(2)
	main.atras()
	await _cuadros(2)
	_check(_capas(dia).is_empty() and dia._raiz.visible, "Atrás cierra el mapa urbano y vuelve el día")
	main.motor.estado.etapa = "gobierno"
	dia._refrescar()
	dia._delegar()
	await _cuadros(1)
	main.atras()
	await _cuadros(2)
	_check(_capas(dia).is_empty(), "Atrás cierra la hoja de delegación")
	var nombres: Dictionary = main.motor.catalogo_leyes["congreso"]["nombres"]
	dia._capa.add_child(OverlaysDia.evento({"titulo": "Debate", "hora": "22:00", "descripcion": "x", "opciones": [{"texto": "Una"}, {"texto": "Otra"}]}, func() -> void: pass, nombres, 1, func(_i: int) -> void: pass))
	await _cuadros(1)
	main.atras()
	await _cuadros(1)
	_check(_capas(dia).size() == 1 and main._aviso_atras.visible and main._aviso_atras.text.contains("Responde"), "Atrás no salta un evento con decisión")
	for h in _capas(dia):
		h.queue_free()
	await _cuadros(1)
	main.atras()
	await _cuadros(1)
	_check(main._pantalla == dia, "en el día el primer Atrás solo avisa")
	main.atras()
	await _cuadros(2)
	_check(main._pantalla is PantallaMenu, "el segundo Atrás seguido va al menú")
	var g: Variant = Datos.leer_json(main.RUTA_GUARDADO)
	_check(g is Dictionary and ValidarGuardado.guardado_valido(g), "al ir al menú la partida queda guardada y válida")
	# el aviso real de Android: llega a Main y el juego no se cierra
	main.mostrar_dia()
	await _cuadros(2)
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _cuadros(2)
	_check(main._pantalla is PantallaDia and main._aviso_atras.visible, "la notificación de Atrás de Android llega a Main y no cierra el juego")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	if _fallos == 0:
		print("ATRÁS OK")
	quit(1 if _fallos > 0 else 0)
