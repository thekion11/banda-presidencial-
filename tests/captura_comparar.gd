extends SceneTree
## Capturas en los mismos estados que la maqueta (día 36, votación del Senado) para comparar fotograma a fotograma.

var _dir: String = "/tmp"


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_dir = a[0]
	_correr.call_deferred()


func _guardar(nombre: String) -> void:
	for i in range(4):
		await process_frame
	await create_timer(0.3).timeout
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
		"votacion": {"voto": {"aprobada": true, "senado": 29, "camara": 90, "min_senado": 26, "min_camara": 78, "en_contra_senado": 14}, "tc": {"recurso": true, "cae": false}, "aprobada": true}}
	dia._capa.add_child(PanelesDia.evento(ev, func() -> void: pass, 50, 36))
	await _guardar("cmp_votacion")
	for h in dia._capa.get_children():
		if h is Control and h != dia._toast:
			h.queue_free()
	await process_frame
	dia._abrir_panel("nacion")
	await _guardar("cmp_nacion")
	quit(0)
