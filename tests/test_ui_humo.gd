extends SceneTree
## Humo de UI en modo headless: recorre menú -> test -> campaña -> elección -> gobierno sin errores de script.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO UI: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.mostrar_partido()
	await process_frame
	var pp: Node = main._pantalla
	for p in main.datos["ideologia"]["preguntas"]:
		pp._responder(p["opciones"][1])
	await process_frame
	pp._fundar()
	await process_frame
	main.motor = Partida.crear(main.datos, 11, main.motor.estado.partido)  # semilla fija: la prueba no depende del reloj
	main.mostrar_gabinete()
	await process_frame
	_check(main._pantalla is PantallaGabinete, "tras fundar el partido debe venir la elección de gabinete")
	var sel_g: Array = main._pantalla.find_children("*", "Button", true, false)
	var conf: Button = sel_g.filter(func(b: Button) -> bool: return b.text.begins_with("Comenzar campaña"))[0]
	_check(not conf.disabled, "el gabinete por defecto (8 ministros) debe poder confirmarse")
	var filas: Array = sel_g.filter(func(b: Button) -> bool: return b.text == "" and b.get_child_count() > 0)
	_check(filas.size() == 25, "deben listarse los 25 ministros, hay %d" % filas.size())
	var tam: int = int(main.datos["leyes"]["gabinete"]["tamano"])
	var libre: Button = filas.filter(func(b: Button) -> bool: return not String((b.get_child(0).get_child(0) as Label).text).begins_with("EN EL GABINETE"))[0]
	libre.pressed.emit()  # con tamano+1 no se agrega: sigue habilitado
	_check(not conf.disabled, "no se debe poder pasar del tamaño del gabinete")
	var elegido: Button = filas.filter(func(b: Button) -> bool: return String((b.get_child(0).get_child(0) as Label).text).begins_with("EN EL GABINETE"))[0]
	elegido.pressed.emit()
	_check(conf.disabled, "con menos de %d ministros no se puede confirmar" % tam)
	libre.pressed.emit()
	_check(not conf.disabled, "con %d ministros se puede confirmar" % tam)
	conf.pressed.emit()
	await process_frame
	var dia: Node = main._pantalla
	_check(dia is PantallaDia, "no se llegó a la pantalla de día")
	for sem in range(8):
		dia._cola_eventos.clear()
		dia._on_region("metropolitana")
		for _k in range(4):
			if not main.motor.estado.mano.is_empty():
				dia._jugar()
		dia._terminar_turno()
		await process_frame
	_check(main.motor.estado.eleccion_pendiente(8), "debería haber elección pendiente")
	dia._resolver_eleccion()
	await process_frame
	main.motor.estado.propuestas_abiertas.append("prop_metro_suroriente")
	for panel in ["comite", "congreso", "gabinete", "mapa"]:
		dia._abrir_panel(panel)
		await process_frame
		if panel == "comite":
			var b3: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "3D")
			b3[0].pressed.emit()
			await process_frame
			var m3: Array = dia._zona_panel.find_children("*", "ComiteMapa3D", true, false)
			_check(m3.size() == 1 and m3[0].visible, "la vista 3D del Comité debe mostrarse")
			var bm: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "Modificar trazado")
			if not bm.is_empty():
				bm[0].pressed.emit()
				await process_frame
	main.motor.estado.propuestas_abiertas.erase("prop_metro_suroriente")  # se inyectó solo para recorrer el panel
	var guardado: Dictionary = main.motor.estado.exportar_guardado()
	var rep0: MotorTurno = Partida.reproducir(main.datos, guardado)
	_check(rep0.estado.calcular_huella() == main.motor.estado.calcular_huella(), "guardado no reproduce la partida de la UI")
	await _recorrer_v2(main, dia)
	_check(not main.motor.estado.partido.is_empty(), "partido vacío")
	if _fallos == 0:
		print("HUMO DE UI OK")
	quit(0 if _fallos == 0 else 1)


func _botones(dia: Node, texto: String) -> Array:
	return dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with(texto) and not b.disabled)


func _recorrer_v2(main: Node, dia: Node) -> void:
	## Pantallas v2: movimientos, reposición, delegación, gabinete editable, asesores, coalición y movimientos internos.
	var est: EstadoSimulacion = main.motor.estado
	_check(est.etapa == "gobierno", "debe estar en gobierno")
	dia._refrescar()
	_check(dia._r["pa"].text.begins_with("%d/" % est.pa_actual), "el indicador de movimientos debe mostrarse")
	dia._sel = 0
	dia._refrescar()
	await process_frame
	await process_frame
	# maqueta: el mapa ocupa más de un tercio y el botón principal no se mueve (mapa, otra carta, panel Gabinete)
	var base: Rect2 = dia._btn_jugar.get_global_rect()
	_check(dia._mapa.size.y > dia.size.y / 3.0, "el mapa debe ocupar más de un tercio de la pantalla (%d de %d)" % [dia._mapa.size.y, dia.size.y])
	dia._sel = 3
	dia._refrescar()
	await process_frame
	_check(dia._btn_jugar.get_global_rect() == base, "el botón principal debe quedar en la misma posición al cambiar de carta")
	dia._sel = 0
	for pest in ["gabinete", "equipo", "coalicion", "internos"]:
		PanelGestion.pestana = pest
		dia._abrir_panel("gabinete")
		await process_frame
		await process_frame
		_check(dia._btn_jugar.get_global_rect() == base, "el botón principal debe quedar en el mismo sitio con la pestaña " + pest)
		_check(dia._zona_panel.get_global_rect().end.y <= base.position.y + 1.0, "el panel no debe tapar el botón principal (" + pest + ")")
	dia._abrir_panel("mapa")
	await process_frame
	_check(est.mano.size() == 5, "la mano debe tener 5 cartas")
	var antes: int = est.pa_actual
	dia._jugar()
	_check(est.pa_actual < antes or est.mano.size() == 5, "jugar debe gastar movimientos")
	_check(est.mano.size() == 5, "tras jugar entra otra carta (mano continua)")
	await process_frame
	# delegación
	dia._sel = 0
	dia._delegar()
	await process_frame
	var ov: Array = dia._capa.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Delegar con"))
	_check(ov.size() == 1 and "%" in ov[0].text, "la hoja de delegación debe mostrar la probabilidad de fallo")
	ov[0].pressed.emit()
	await process_frame
	_check(est.delegadas_turno == 1, "debe contar una delegación")
	# gabinete editable en la semana 1 de gobierno
	for pest in ["gabinete", "equipo", "coalicion", "internos"]:
		PanelGestion.pestana = pest
		dia._abrir_panel("gabinete")
		await process_frame
	PanelGestion.pestana = "equipo"
	dia._abrir_panel("gabinete")
	await process_frame
	_botones(dia, "Contratar")[0].pressed.emit()
	await process_frame
	_check(est.asesores.size() == 1, "debe contratar un asesor")
	PanelGestion.pestana = "coalicion"
	dia._abrir_panel("gabinete")
	await process_frame
	_botones(dia, "Unirse")[0].pressed.emit()
	await process_frame
	_check(est.coalicion.size() == 1, "debe unirse a la coalición")
	_botones(dia, "Cuotas")[0].pressed.emit()
	await process_frame
	var cuota: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.get_child_count() > 0 and not b.disabled and b.text == "")
	if not cuota.is_empty():
		cuota[0].pressed.emit()
		await process_frame
	PanelGestion.pestana = "internos"
	dia._abrir_panel("gabinete")
	await process_frame
	est.internos_actual = 3
	var metas: Array = _botones(dia, "Buscar meta")
	if not metas.is_empty():
		metas[0].pressed.emit()
		await process_frame
	_check(est.internos_actual < 3 or metas.is_empty(), "buscar una meta debe gastar movimientos internos")
	_botones(dia, "Reducir errores")[0].pressed.emit()
	await process_frame
	var mas: Array = _botones(dia, "+")
	if not mas.is_empty():
		mas[0].pressed.emit()
		await process_frame
	PanelGestion.pestana = "gabinete"
	dia._abrir_panel("mapa")
	est.internos_actual = 0  # sin movimientos: el rechazo se explica en lenguaje claro
	_check(Razones.texto(main.motor.reducir_errores()).length() > 10, "los rechazos deben tener texto claro")
	var rep: MotorTurno = Partida.reproducir(main.datos, est.exportar_guardado())
	_check(rep.estado.calcular_huella() == est.calcular_huella(), "las acciones v2 de la UI deben reproducirse desde el guardado")
	# reposición animada: se fuerza una mano vacía con movimientos y se repone
	est.mano.clear()
	est.pa_actual = 3
	var n_reg := est.registro_acciones.size()
	var nuevas: Array[String] = main.motor.mazo.reposicion()
	dia._leer_reposicion(n_reg)
	_check(not nuevas.is_empty() and dia._nuevas == nuevas, "la reposición debe quedar registrada para animarse")
	dia._refrescar()
	await create_timer(0.8).timeout
	_check(dia._mano.get_child_count() == est.mano.size(), "la mano repuesta debe pintarse")
