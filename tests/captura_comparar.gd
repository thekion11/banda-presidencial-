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
	quit(0)
