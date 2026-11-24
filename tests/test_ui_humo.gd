extends SceneTree
## Humo de UI en modo headless: recorre menú -> test -> campaña -> elección -> gobierno sin errores de script.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO UI: ", msg)


func _init() -> void:
	_correr.call_deferred()


const SEMILLAS := [7, 11, 20260415, 31337, 99991, 123456]


func _correr() -> void:
	## Recorre la UI con varias semillas: el layout no debe depender del contenido de la mano.
	Tutorial.ruta = "user://preferencias_prueba.json"  # no tocar las preferencias reales
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	var idx := 0
	for sem in SEMILLAS:
		print("semilla ", sem)
		await _una(sem, idx)
		idx += 1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	await _informe()
	if _fallos == 0:
		print("HUMO DE UI OK (%d semillas)" % SEMILLAS.size())
	quit(0 if _fallos == 0 else 1)


func _una(semilla: int, idx: int = 0) -> void:
	if idx == 1:  # la segunda partida prueba la ruta "saltar tutorial"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	if idx == 0:  # PR-01: la pantalla de afiliación y la lista de partidos existentes
		main.mostrar_afiliacion()
		await process_frame
		var af: Node = main._pantalla
		_check(af.find_children("*", "Button", true, false).size() == 3, "afiliación: tres tarjetas")
		af._elegir("existente")
		await process_frame
		await process_frame
		_check(af.find_children("*", "Button", true, false).size() >= 15, "afiliación: lista de partidos")
	main.mostrar_partido()
	await process_frame
	var pp: Node = main._pantalla
	for p in main.datos["ideologia"]["preguntas"]:
		pp._responder(p["opciones"][1])
	for _k in range(4):
		await process_frame
	var r_fundar := Rect2()
	var ir_b: Array = pp.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Iniciar Campaña"))
	_check(ir_b.size() == 1, "la pantalla de fundación debe tener su botón principal")
	if ir_b.size() == 1:
		r_fundar = (ir_b[0] as Button).get_global_rect()
	pp._fundar()
	await process_frame
	var partido: Dictionary = main.motor.estado.partido.duplicate(true)
	partido["indicadores_iniciales"]["aprobacion"] = 90.0  # la prueba recorre el gobierno: que la campaña no la pierda al azar
	main.motor = Partida.crear(main.datos, semilla, partido)  # semilla fija: la prueba no depende del reloj
	main.mostrar_gabinete()
	await process_frame
	_check(main._pantalla is PantallaGabinete, "tras fundar el partido debe venir la elección de gabinete")
	var sel_g: Array = main._pantalla.find_children("*", "Button", true, false)
	var conf: Button = sel_g.filter(func(b: Button) -> bool: return b.text.begins_with("Comenzar campaña"))[0]
	for _k in range(4):
		await process_frame
	print("  botón fundación: %s · botón gabinete: %s" % [r_fundar, conf.get_global_rect()])
	_check(conf.get_global_rect() == r_fundar, "el botón principal del gabinete debe estar donde el de la fundación (%s vs %s)" % [conf.get_global_rect(), r_fundar])
	_check(not conf.disabled, "el gabinete por defecto (8 ministros) debe poder confirmarse")
	var rel: Array = main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text in ["Equilibrado", "Máxima eficacia"])
	_check(rel.size() == 2, "PR-05: dos botones de relleno (equilibrado y máxima eficacia)")
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
	await _tutorial(dia, idx)
	for sem in range(8):
		dia._cola_eventos.clear()
		dia._on_region("metropolitana")
		for _k in range(4):
			if not main.motor.estado.mano.is_empty():
				dia._jugar()
		dia._terminar_turno()
		await process_frame
	_check(main.motor.estado.eleccion_pendiente(8), "debería haber elección pendiente")
	var regional: Dictionary = main.motor.estado.aprobacion_regional.duplicate()
	dia._resolver_eleccion()
	await process_frame
	await _eleccion(main, dia, regional)
	main.motor.estado.propuestas_abiertas.append("prop_metro_suroriente")
	for panel in ["comite", "congreso", "gabinete", "mapa"]:
		dia._abrir_panel(panel)
		await process_frame
		await process_frame
		_check_tactil(dia, "panel " + panel)
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
	await _fin_y_cartera(main, dia)
	_check(not main.motor.estado.partido.is_empty(), "partido vacío")
	main.queue_free()
	await process_frame


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
	for _k in range(4):
		await process_frame
	var base: Rect2 = dia._btn_jugar.get_global_rect()
	print("  botón principal (semilla %d): %s, cartas en mano: %d" % [main.motor.estado.semilla, base, est.mano.size()])
	_check(dia._mapa.size.y > dia.size.y / 3.0, "el mapa debe ocupar más de un tercio de la pantalla (%d de %d)" % [dia._mapa.size.y, dia.size.y])
	for i in range(est.mano.size()):  # cualquier carta elegida (título largo, corrector de varias líneas): el botón no se mueve
		dia._sel = i
		dia._refrescar()
		for _k in range(4):
			await process_frame
		_check(dia._btn_jugar.get_global_rect() == base, "el botón principal debe quedar en la misma posición con la carta %d (%s vs %s)" % [i, dia._btn_jugar.get_global_rect(), base])
		_check(dia._mapa.size.y > dia.size.y / 3.0, "el mapa debe seguir ocupando más de un tercio con la carta %d" % i)
	dia._sel = 0
	for pest in ["gabinete", "equipo", "coalicion", "internos"]:
		PanelGestion.pestana = pest
		dia._abrir_panel("gabinete")
		for _k in range(4):
			await process_frame
		_check_tactil(dia, "pestaña " + pest)
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


func _check_tactil(raiz: Node, donde: String) -> void:
	## CLAUDE.md §5: toda zona táctil visible mide al menos 44 px por lado.
	for b in raiz.find_children("*", "BaseButton", true, false):
		var c := b as Control
		if c.is_visible_in_tree() and not (b is BaseButton and (b as BaseButton).disabled) and (c.size.x < 43.5 or c.size.y < 43.5) and c.size.x > 1.0:
			_check(false, "zona táctil menor de 44 px en %s: %s (%s) %s" % [donde, c.name, (b as Button).text if b is Button else "", c.size])


func _textos(nodo: Node) -> String:
	var t: PackedStringArray = []
	for l in nodo.find_children("*", "Label", true, false):
		t.append((l as Label).text)
	return "\n".join(t)


func _boton(nodo: Node, texto: String) -> Button:
	for b in nodo.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(texto):
			return b
	return null


func _tutorial(dia: Node, idx: int) -> void:
	## Tutorial de la primera partida: 5 pasos, saltable y que no se repite (solo preferencia local).
	var tuts: Array = dia._capa.find_children("*", "Tutorial", true, false)
	if idx >= 2:
		_check(tuts.is_empty() and not Tutorial.debe_mostrar(), "el tutorial no debe repetirse una vez visto o saltado")
		return
	_check(tuts.size() == 1, "la primera partida debe mostrar el tutorial")
	if tuts.is_empty():
		return
	for _k in range(4):
		await process_frame
	var t: Node = tuts[0]
	_check_tactil(t, "tutorial")
	var rect_sig := Rect2()
	if idx == 0:
		for paso in range(Tutorial.PASOS.size()):
			var b: Button = _boton(t, "Siguiente") if paso < Tutorial.PASOS.size() - 1 else _boton(t, "Entendido")
			_check(b != null, "el paso %d del tutorial necesita su botón" % (paso + 1))
			if b == null:
				break
			if paso == 0:
				rect_sig = b.get_global_rect()
			_check(b.get_global_rect() == rect_sig, "el botón principal del tutorial debe quedar en el mismo sitio (paso %d)" % (paso + 1))
			_check(_textos(t).contains("PASO %d DE 5" % (paso + 1)), "el tutorial debe indicar el paso %d de 5" % (paso + 1))
			_check(t._marco.visible and t._marco.size.x > 20.0, "el paso %d debe resaltar su elemento" % (paso + 1))
			b.pressed.emit()
			await process_frame
	else:
		_boton(t, "Saltar tutorial").pressed.emit()
		await process_frame
	await process_frame
	_check(dia._capa.find_children("*", "Tutorial", true, false).is_empty(), "el tutorial debe cerrarse")
	_check(not Tutorial.debe_mostrar(), "el tutorial no debe repetirse: se guarda la preferencia")


func _eleccion(main: Node, dia: Node, regional: Dictionary) -> void:
	## Resultado de elección: mide aprobación (no "votos"), con umbral, desglose por región y aviso de 2ª vuelta.
	var motor: MotorTurno = main.motor
	var reales: Array = dia._capa.find_children("*", "Control", false, false).filter(func(c: Node) -> bool: return _boton(c, "Asumir el gobierno") != null or _boton(c, "Ir a la segunda") != null or _boton(c, "Ver resultado") != null)
	_check(reales.size() == 1, "la elección debe mostrar su pantalla de resultado")
	var casos := [
		{"electo": true, "balotaje": false, "ronda": 1, "voto_final": 62.0, "umbral": 51.0, "boton": "Asumir el gobierno", "texto": "Presidente electo"},
		{"electo": false, "balotaje": true, "ronda": 1, "voto_final": 44.0, "umbral": 51.0, "boton": "Ir a la segunda vuelta", "texto": "segunda vuelta"},
		{"electo": true, "balotaje": false, "ronda": 2, "voto_final": 53.0, "umbral": 51.0, "boton": "Asumir el gobierno", "texto": "segunda vuelta"},
		{"electo": false, "balotaje": false, "ronda": 2, "voto_final": 40.0, "umbral": 51.0, "boton": "Ver resultado final", "texto": "No alcanzaste"},
	]
	var rect_btn := Rect2()
	for c in casos:
		var pant: Control = PantallaEleccion.crear(motor, main.datos["regiones"], regional, c, func() -> void: pass)
		dia._capa.add_child(pant)
		for _k in range(3):
			await process_frame
		var txt := _textos(pant)
		_check(not txt.contains("votos"), "el resultado no debe hablar de votos: mide aprobación")
		_check(txt.contains("Aprobación") and txt.contains("umbral") and txt.contains(str(c["texto"])), "falta aprobación/umbral/veredicto (%s)" % c["texto"])
		_check(txt.contains("Aprobación por región"), "falta el desglose por región")
		if c["balotaje"]:
			_check(txt.contains("semanas más de campaña"), "falta el aviso de segunda vuelta")
		var b := _boton(pant, String(c["boton"]))
		_check(b != null, "falta el botón " + String(c["boton"]))
		if b != null:
			if rect_btn.size == Vector2.ZERO:
				rect_btn = b.get_global_rect()
			_check(b.get_global_rect() == rect_btn, "el botón principal de la elección debe quedar en el mismo sitio")
		_check_tactil(pant, "resultado de elección")
		pant.queue_free()
		await process_frame


func _fin_y_cartera(main: Node, dia: Node) -> void:
	var motor: MotorTurno = main.motor
	var est: EstadoSimulacion = motor.estado
	# Cartera de proyectos: solo lectura, con y sin partida
	var huella0 := est.calcular_huella()
	var n_reg := est.registro_acciones.size()
	var cart: PantallaCartera = PantallaCartera.crear(main.datos, motor)
	dia._capa.add_child(cart)
	for _k in range(3):
		await process_frame
	var n_reales := 0
	for c in main.datos["cartas"]:
		n_reales += 1 if PantallaCartera._es_real(c) else 0
	_check(cart.filtrados.size() == n_reales and n_reales > 1000, "la cartera debe listar todos los proyectos reales (%d)" % cart.filtrados.size())
	var volver := _boton(cart, "Volver")
	var rect_v := volver.get_global_rect()
	_check_tactil(cart, "cartera")
	var tipos := ["Obras públicas", "Proyectos de ley", "Reformas", "Todos"]
	for t in tipos:
		_boton(cart, t).pressed.emit()
		await process_frame
		var ok := true
		for c in cart.filtrados:
			ok = ok and (t == "Todos" or String(c["meta"]["tipo"]).replace("propuesta_constitucional", "reforma_constitucional") == cart.f_tipo)
		_check(ok and not cart.filtrados.is_empty(), "el filtro de tipo %s debe filtrar" % t)
		_check(volver.get_global_rect() == rect_v, "el botón Volver debe quedar en el mismo sitio con el filtro " + t)
	_boton(cart, "Obras públicas").pressed.emit()
	_boton(cart, "Metropolitana").pressed.emit()
	await process_frame
	_check(not cart.filtrados.is_empty() and cart.filtrados.all(func(c: Dictionary) -> bool: return String(c["meta"].get("region_id", "")) == "metropolitana"), "el filtro de región debe filtrar")
	_boton(cart, "Todas").pressed.emit()
	_boton(cart, "Todos").pressed.emit()
	await process_frame
	cart.f_sector = ""
	_boton(cart, "Siguiente").pressed.emit()
	await process_frame
	_check(cart.pagina == 1, "la paginación debe avanzar")
	var txt := _textos(cart)
	_check(txt.contains("Fuente:") and txt.contains("Estado real:"), "cada proyecto debe mostrar su fuente y su estado")
	_check(est.calcular_huella() == huella0 and est.registro_acciones.size() == n_reg, "mirar la cartera no debe alterar la partida")
	cart.queue_free()
	var libre: PantallaCartera = PantallaCartera.crear(main.datos)
	dia._capa.add_child(libre)
	for _k in range(3):
		await process_frame
	_check(_textos(libre).contains("Sin partida abierta"), "la cartera sin partida debe decirlo")
	libre.queue_free()
	await process_frame
	# Fin de partida con resumen (se cierra la partida: va al final)
	var ev_real := ""
	for e in motor.catalogo_eventos:
		if e.get("meta", {}).has("fecha_real"):
			ev_real = String(e["id"])
			break
	est.eventos_ocurridos[ev_real] = 3
	for fin in ["fin_mandato", "crisis"]:
		motor.mandato.finalizar(fin)
		main.mostrar_fin()
		for _k in range(4):
			await process_frame
		var pf: Node = main._pantalla
		var t := _textos(pf)
		for clave in ["Puntaje final", "Promesas cumplidas", "Leyes aprobadas", "Obras terminadas", "Línea de tiempo"]:
			_check(t.contains(clave), "el fin de partida debe mostrar: " + clave)
		_check(not t.contains("votos"), "el fin de partida no debe hablar de votos")
		var vb := _boton(pf, "Volver al inicio")
		_check(vb != null and vb.get_global_rect() == Rect2(16, 739, 358, 52), "el botón principal del fin debe estar en la posición fija (%s)" % (vb.get_global_rect() if vb != null else Rect2()))
		_check_tactil(pf, "fin de partida")
	est.etapa = "derrota_electoral"
	est.resultado_final = {"motivo": "derrota_electoral", "voto_final": 40.0, "puntaje": 0}
	main.mostrar_fin()
	for _k in range(3):
		await process_frame
	_check(_textos(main._pantalla).contains("aprobación"), "la derrota debe hablar de aprobación, no de votos")


func _informe() -> void:
	## Informe de prueba: se abre desde el menú, resume el registro local y es táctil.
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.mostrar_menu()
	await process_frame
	var menu: Node = main._pantalla
	var b: Array = menu.find_children("*", "Button", true, false).filter(func(x: Button) -> bool: return x.text == "Informe de prueba")
	_check(b.size() == 1, "el menú debe tener el botón «Informe de prueba»")
	if b.size() == 1:
		(b[0] as Button).pressed.emit()
		for _k in range(3):
			await process_frame
		var inf: Array = menu.get_children().filter(func(x: Node) -> bool: return x is PantallaInforme)
		_check(inf.size() == 1, "el informe de prueba debe abrirse")
		if inf.size() == 1:
			_check_tactil(inf[0], "informe de prueba")
	var t := RegistroPrueba.informe()
	_check(t.contains("informe de prueba") and t.contains("versión") and t.contains("partidas registradas"), "el informe debe traer versión y resumen")
