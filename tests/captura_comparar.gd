extends SceneTree
## Capturas en los mismos estados que la maqueta (día 36, votación del Senado) para comparar fotograma a fotograma.

var _dir: String = "/tmp"


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_dir = a[0]
	_correr.call_deferred()


func _guardar(nombre: String, espera: float = 0.3) -> void:
	for i in range(4):
		await process_frame
	await create_timer(espera).timeout
	root.get_texture().get_image().save_png("%s/%s.png" % [_dir, nombre])


func _buscar_mapa(n: Node) -> UrbanoMapa:
	if n is UrbanoMapa:
		return n
	for h in n.get_children():
		var r := _buscar_mapa(h)
		if r != null:
			return r
	return null


func _correr() -> void:
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Movimiento Cívico Austral", "MCA", "metropolitana", resp, d["ideologia"])
	var m := Partida.crear(d, 20260415, partido)
	m.estado.etapa = "gobierno"
	m.estado.turno_actual = 6
	m.estado.dia_actual = 36
	m.estado.mano.clear()
	for id in ["pol_gabinete", "edu_alimentacion", "viv_acelerar", "ene_solar_norte", "com_metro_suroriente"]:
		for c in m.catalogo_cartas:
			if c["id"] == id:
				m.estado.mano.append(c)
	m.ultimos_eventos = []
	main.motor = m
	main.mostrar_dia()
	await process_frame
	var dia: Node = main._pantalla
	dia._sel = 2
	dia._on_region("metropolitana")
	dia._refrescar()
	await _guardar("cmp_dia")
	var ev := {"titulo": "Ley de quórum calificado de energía", "hora": "16:00", "descripcion": "Requiere 26 votos de 50 senadores", "efectos": [{"ind": "capital", "delta": 4}, {"ind": "cohesion", "delta": 2}, {"ind": "fiscal", "delta": -2}],
		"votacion": {"origen": "senado", "voto": {"aprobada": true, "senado": 29, "camara": 96, "min_senado": 26, "min_camara": 78, "total_senado": 50, "total_camara": 155, "abst_senado": 7, "abst_camara": 21, "contra_senado": 14, "contra_camara": 38}, "tc": {"recurso": true, "cae": false}, "aprobada": true}}
	dia._capa.add_child(OverlaysDia.evento(ev, func() -> void: pass, m.catalogo_leyes["congreso"]["nombres"], 36))
	await _guardar("cmp_votacion", 2.0)
	var botones: Array = dia._capa.find_children("*", "Button", true, false)
	botones[botones.size() - 1].pressed.emit()
	await _guardar("cmp_votacion_pag2", 2.0)
	for h in dia._capa.get_children():
		if h is Control and h != dia._toast:
			h.queue_free()
	await process_frame
	dia._abrir_panel("congreso")
	await _guardar("cmp_congreso", 2.0)
	dia._abrir_panel("nacion")
	await _guardar("cmp_nacion")
	dia._abrir_panel("mapa")
	m.estado.propuestas_abiertas.append("prop_metro_suroriente")
	dia._refrescar()
	await _guardar("cmp_dia2")
	dia._abrir_panel("comite")
	await _guardar("cmp_comite_2d")
	for h in dia._zona_panel.get_children():
		pass
	var mc: Node = dia._zona_panel.find_children("*", "ComiteMapa", true, false)[0]
	var b3d: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "3D")
	b3d[0].pressed.emit()
	await create_timer(1.2).timeout
	await _guardar("cmp_comite_3d")
	var b2d: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "2D")
	b2d[0].pressed.emit()
	await create_timer(0.7).timeout
	var btns: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "Modificar trazado")
	btns[0].pressed.emit()
	await process_frame
	mc.agregar_estacion()
	await _guardar("cmp_comite_edicion", 0.6)
	var sc: Array = dia._zona_panel.find_children("*", "ScrollContainer", true, false)
	sc[0].scroll_vertical = 420
	await _guardar("cmp_comite_edicion2", 0.4)
	dia._abrir_panel("mapa")
	var obra := {"nombre": "Estación terminal, nueva línea de Metro", "variante": "A", "dias_totales": 960, "dias_avanzados": 760, "retrasos": 0, "carta_id": "", "propuesta": "prop_metro_suroriente", "region": "metropolitana", "efectos_final": [{"ind": "aprobacion", "delta": 4}]}
	m.estado.obras_en_curso.append(obra)
	m.estado.obras_en_curso.append({"nombre": "Conjunto de vivienda social", "dias_totales": 400, "dias_avanzados": 120, "retrasos": 0, "carta_id": "viv_campamentos", "region": "metropolitana", "efectos_final": []})
	dia._abrir_hito(obra)
	await _guardar("cmp_hito")
	for h in dia._capa.get_children():
		if h is ColorRect:
			h.queue_free()
	dia._abrir_urbano()
	await _guardar("cmp_urbano", 1.3)
	var um: UrbanoMapa = _buscar_mapa(dia._capa)
	if um != null:  # acercamiento al centro (zoom 3) y enfoque: solo L1, L4 y L5 visibles
		um._zoom_en(3.0, Vector2(um.size.x * 0.52, um.size.y * 0.42))
		await _guardar("cmp_urbano_zoom", 0.3)
		for id in ["L2", "L3", "L4A", "L6"]:
			UrbanoBase.alternar_linea(id)
		um.queue_redraw()
		await _guardar("cmp_urbano_foco", 0.3)
		UrbanoBase.ocultas.clear()
		um.zoom = 1.0
		um.pan = Vector2.ZERO
		um.queue_redraw()
	for h in dia._capa.get_children():
		if h != dia._toast:
			h.queue_free()
	await _v2(main, dia, d, partido)
	await _v3(main, d, partido)
	quit(0)


func _v2(main: Node, dia: Node, d: Dictionary, partido: Dictionary) -> void:
	## Pantallas de las mecánicas v2 (DISENO_V2): gabinete, movimientos, delegación, asesores, coalición e internos.
	var m: MotorTurno = main.motor
	var est: EstadoSimulacion = m.estado
	est.mano.clear()
	m.robar_mano(5)
	est.pa_actual = 4
	est.bono_mov = {"aprobacion": 2, "asesores": 1}
	m.contratar_asesor("as_economista")
	var pids: Array = m.coalicion.partidos.keys()
	m.unirse_coalicion(pids[0])
	m.unirse_coalicion(pids[1])
	est.coalicion[pids[1]]["satisfaccion"] = 22.0
	est.internos_actual = 3
	dia._abrir_panel("mapa")
	dia._sel = 1
	dia._refrescar()
	await _guardar("v2_dia_movimientos", 0.9)
	dia._delegar()
	await _guardar("v2_delegar", 0.6)
	for h in dia._capa.get_children():
		if h != dia._toast:
			h.queue_free()
	for par in [["gabinete", "v2_gabinete_cerrado"], ["equipo", "v2_asesores"], ["coalicion", "v2_coalicion"], ["internos", "v2_internos"]]:
		PanelGestion.pestana = par[0]
		dia._abrir_panel("gabinete")
		await _guardar(par[1], 0.5)
	PanelCoalicion.abierto = pids[0]
	PanelGestion.pestana = "coalicion"
	dia._abrir_panel("gabinete")
	await _guardar("v2_coalicion_cuotas", 0.5)
	dia._abrir_panel("mapa")
	est.mano.clear()
	est.pa_actual = 3
	var n_reg := est.registro_acciones.size()
	m.mazo.reposicion()
	dia._leer_reposicion(n_reg)
	dia._refrescar()
	await _guardar("v2_reposicion", 0.12)
	# etapa de configuración: elección de gabinete antes de la campaña
	main.motor = Partida.crear(d, 20260415, partido)
	main.mostrar_gabinete()
	await _guardar("v2_gabinete_config", 0.5)


func _v3(main: Node, d: Dictionary, partido: Dictionary) -> void:
	## Pantallas de primeras pruebas: tutorial, resultado de elección, cartera de proyectos, fin de partida y menú.
	Tutorial.ruta = "user://preferencias_captura.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	main.motor = Partida.crear(d, 20260415, partido)
	main.mostrar_dia()
	await _guardar("v3_tutorial_1", 0.6)
	var dia: Node = main._pantalla
	var t: Node = dia._capa.find_children("*", "Tutorial", true, false)[0]
	for _i in range(3):
		t._avanzar()
	await _guardar("v3_tutorial_4", 0.4)
	t._cerrar()
	var m: MotorTurno = main.motor
	m.estado.mano.clear()
	m.robar_mano(5)
	for _i in range(3):
		m.jugar_carta(0, "", "metropolitana")
	var regional: Dictionary = m.estado.aprobacion_regional.duplicate()
	var casos := [
		["v3_eleccion_victoria", {"electo": true, "balotaje": false, "ronda": 1, "voto_final": 57.4, "umbral": 51.0}],
		["v3_eleccion_balotaje", {"electo": false, "balotaje": true, "ronda": 1, "voto_final": 44.2, "umbral": 51.0}],
		["v3_eleccion_derrota", {"electo": false, "balotaje": false, "ronda": 2, "voto_final": 40.1, "umbral": 51.0}],
	]
	for c in casos:
		var pant: Control = PantallaEleccion.crear(m, d["regiones"], regional, c[1], func() -> void: pass)
		dia._capa.add_child(pant)
		await _guardar(c[0], 0.3)
		pant.queue_free()
	var cart: PantallaCartera = PantallaCartera.crear(d, m)
	dia._capa.add_child(cart)
	await _guardar("v3_cartera", 0.8)
	cart.f_tipo = "proyecto_de_ley"
	cart.f_sector = "salud"
	cart.aplicar_filtros()
	await _guardar("v3_cartera_filtrada", 0.5)
	cart.queue_free()
	var n := 0
	for e in m.catalogo_eventos:
		if e.get("meta", {}).has("fecha_real") and n < 6:
			m.estado.eventos_ocurridos[String(e["id"])] = 2
			n += 1
	m.mandato.finalizar("fin_mandato")
	main.mostrar_fin()
	await _guardar("v3_fin", 0.6)
	main.mostrar_menu()
	await _guardar("v3_menu", 0.6)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
