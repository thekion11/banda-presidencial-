class_name HumoV2
extends RefCounted
## Parte del humo de UI (tests/test_ui_humo.gd): pantallas v2 (movimientos, reposición, delegación, gabinete editable,
## asesores, coalición y movimientos internos). Separada para mantener la prueba bajo 450 líneas (CLAUDE.md §3).
## `t` es la prueba en curso: aporta _check, _botones, _check_tactil y los cuadros.


static func recorrer(t: Variant, main: Node, dia: Node) -> void:  # Variant: llama a los métodos de la prueba
	## Pantallas v2: movimientos, reposición, delegación, gabinete editable, asesores, coalición y movimientos internos.
	var est: EstadoSimulacion = main.motor.estado
	t._check(est.etapa == "gobierno", "debe estar en gobierno")
	dia._refrescar()
	t._check(dia._r["pa"].text.begins_with("%d/" % est.pa_actual), "el indicador de movimientos debe mostrarse")
	dia._sel = 0
	dia._refrescar()
	await t.process_frame
	await t.process_frame
	# maqueta: el mapa ocupa más de un tercio y el botón principal no se mueve (mapa, otra carta, panel Gabinete)
	for _k in range(4):
		await t.process_frame
	var base: Rect2 = dia._btn_jugar.get_global_rect()
	print("  botón principal (semilla %d): %s, cartas en mano: %d" % [main.motor.estado.semilla, base, est.mano.size()])
	t._check(dia._mapa.size.y > dia.size.y / 3.0, "el mapa debe ocupar más de un tercio de la pantalla (%d de %d)" % [dia._mapa.size.y, dia.size.y])
	for i in range(est.mano.size()):  # cualquier carta elegida (título largo, corrector de varias líneas): el botón no se mueve
		dia._sel = i
		dia._refrescar()
		for _k in range(4):
			await t.process_frame
		t._check(dia._btn_jugar.get_global_rect() == base, "el botón principal debe quedar en la misma posición con la carta %d (%s vs %s)" % [i, dia._btn_jugar.get_global_rect(), base])
		t._check(dia._mapa.size.y > dia.size.y / 3.0, "el mapa debe seguir ocupando más de un tercio con la carta %d" % i)
	dia._sel = 0
	for pest in ["gabinete", "equipo", "coalicion", "internos"]:
		PanelGestion.pestana = pest
		dia._abrir_panel("gabinete")
		for _k in range(4):
			await t.process_frame
		t._check_tactil(dia, "pestaña " + pest)
		t._check(dia._btn_jugar.get_global_rect() == base, "el botón principal debe quedar en el mismo sitio con la pestaña " + pest)
		t._check(dia._zona_panel.get_global_rect().end.y <= base.position.y + 1.0, "el panel no debe tapar el botón principal (" + pest + ")")
	dia._abrir_panel("mapa")
	await t.process_frame
	t._check(est.mano.size() == 5, "la mano debe tener 5 cartas")
	var antes: int = est.pa_actual
	dia._jugar()
	t._check(est.pa_actual < antes or est.mano.size() == 5, "jugar debe gastar movimientos")
	t._check(est.mano.size() == 5, "tras jugar entra otra carta (mano continua)")
	await t.process_frame
	# PR-02: deslizar hacia arriba desde la mano juega la carta elegida
	if est.pa_actual > 0:
		var pa_antes: int = est.pa_actual
		AyudaUI.deslizar_arriba(dia._mano)
		await t.process_frame
		t._check(est.pa_actual < pa_antes, "deslizar la carta hacia arriba debe jugarla")
	for f in AyudaUI.controles_dia(dia):
		t._check(false, f)
	# delegación
	dia._sel = 0
	dia._delegar()
	await t.process_frame
	var ov: Array = dia._capa.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Delegar con"))
	t._check(ov.size() == 1 and "%" in ov[0].text, "la hoja de delegación debe mostrar la probabilidad de fallo")
	ov[0].pressed.emit()
	await t.process_frame
	t._check(est.delegadas_turno == 1, "debe contar una delegación")
	# gabinete editable en la semana 1 de gobierno
	for pest in ["gabinete", "equipo", "coalicion", "internos"]:
		PanelGestion.pestana = pest
		dia._abrir_panel("gabinete")
		await t.process_frame
	PanelGestion.pestana = "equipo"
	dia._abrir_panel("gabinete")
	await t.process_frame
	t._botones(dia, "Contratar")[0].pressed.emit()
	await t.process_frame
	t._check(est.asesores.size() == 1, "debe contratar un asesor")
	PanelGestion.pestana = "coalicion"
	dia._abrir_panel("gabinete")
	await t.process_frame
	t._botones(dia, "Unirse")[0].pressed.emit()
	await t.process_frame
	t._check(est.coalicion.size() == 1, "debe unirse a la coalición")
	t._botones(dia, "Cuotas")[0].pressed.emit()
	await t.process_frame
	var cuota: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.get_child_count() > 0 and not b.disabled and b.text == "")
	if not cuota.is_empty():
		cuota[0].pressed.emit()
		await t.process_frame
	PanelGestion.pestana = "internos"
	dia._abrir_panel("gabinete")
	await t.process_frame
	est.internos_actual = 3
	var metas: Array = t._botones(dia, "Buscar meta")
	if not metas.is_empty():
		metas[0].pressed.emit()
		await t.process_frame
	t._check(est.internos_actual < 3 or metas.is_empty(), "buscar una meta debe gastar movimientos internos")
	t._botones(dia, "Reducir errores")[0].pressed.emit()
	await t.process_frame
	var mas: Array = t._botones(dia, "+")
	if not mas.is_empty():
		mas[0].pressed.emit()
		await t.process_frame
	PanelGestion.pestana = "gabinete"
	dia._abrir_panel("mapa")
	est.internos_actual = 0  # sin movimientos: el rechazo se explica en lenguaje claro
	t._check(Razones.texto(main.motor.reducir_errores()).length() > 10, "los rechazos deben tener texto claro")
	var rep: MotorTurno = Partida.reproducir(main.datos, est.exportar_guardado())
	t._check(rep.estado.calcular_huella() == est.calcular_huella(), "las acciones v2 de la UI deben reproducirse desde el guardado")
	# reposición animada: se fuerza una mano vacía con movimientos y se repone
	est.mano.clear()
	est.pa_actual = 3
	var n_reg := est.registro_acciones.size()
	var nuevas: Array[String] = main.motor.mazo.reposicion()
	dia._leer_reposicion(n_reg)
	t._check(not nuevas.is_empty() and dia._nuevas == nuevas, "la reposición debe quedar registrada para animarse")
	dia._refrescar()
	await t.create_timer(0.8).timeout
	t._check(dia._mano.get_child_count() == est.mano.size(), "la mano repuesta debe pintarse")
