class_name RecorridoUI
extends RefCounted
## Recorrido de pantallas y paneles para auditorías de interfaz (zonas táctiles, tamaños de letra).
## Llama a `visitar(main, nombre_del_paso)` en cada estado, ya con el diseño asentado. Sin animaciones.


static func recorrer(arbol: SceneTree, visitar: Callable) -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_recorrido.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	arbol.root.add_child(main)
	await arbol.process_frame
	var d: Dictionary = main.datos
	var paso := func(nombre: String) -> void:
		for i in range(3):
			await arbol.process_frame
		visitar.call(main, nombre)
	await paso.call("menú")
	main._pantalla._mostrar_creditos()
	await paso.call("créditos")
	main._pantalla.add_child(PantallaAjustes.new())
	await paso.call("ajustes")
	main.mostrar_afiliacion()
	await paso.call("afiliación")
	main.mostrar_partido("propio")
	await paso.call("test ideológico")
	main._pantalla._responder(d["ideologia"]["preguntas"][0]["opciones"][0])
	await paso.call("test con brújula")
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Movimiento Cívico Austral", "MCA", "metropolitana", resp, d["ideologia"])
	main.motor = Partida.crear(d, 20260415, partido)
	main.mostrar_gabinete()
	await paso.call("gabinete (configuración)")
	main.mostrar_dia()
	await paso.call("día")
	var dia: Node = main._pantalla
	for panel in ["comite", "congreso", "gabinete", "nacion"]:
		dia._abrir_panel(panel)
		await paso.call("panel " + panel)
	dia._abrir_panel("mapa")
	var nombres: Dictionary = main.motor.catalogo_leyes["congreso"]["nombres"]
	dia._capa.add_child(OverlaysDia.evento({"titulo": "Debate", "hora": "22:00", "descripcion": "x", "escena": {"nombre": "Debate presidencial final", "ronda": 1, "rondas": 3},
		"opciones": [{"texto": "Una"}, {"texto": "Otra"}]}, func() -> void: pass, nombres, 1, func(_i: int) -> void: pass))
	await paso.call("evento con decisión")
	for h in dia._capa.get_children():
		if h is Control and h != dia._toast:
			h.queue_free()
	var votos := {"aprobada": true, "senado": 27, "camara": 96, "min_senado": 26, "min_camara": 78, "total_senado": 50, "total_camara": 155, "abst_senado": 5, "abst_camara": 21, "contra_senado": 18, "contra_camara": 38}
	dia._capa.add_child(OverlaysDia.evento({"titulo": "Ley", "hora": "16:00", "descripcion": "x", "efectos": [{"ind": "capital", "delta": 4}],
		"votacion": {"origen": "senado", "voto": votos, "tc": {"recurso": false, "cae": false}, "aprobada": true}}, func() -> void: pass, nombres, 36))
	await paso.call("votación")
	for h in dia._capa.get_children():
		if h is Control and h != dia._toast:
			h.queue_free()
	var el: Control = PantallaEleccion.crear(main.motor, d["regiones"], main.motor.estado.aprobacion_regional.duplicate(), {"electo": true, "balotaje": false, "ronda": 1, "voto_final": 57.4, "umbral": 51.0}, func() -> void: pass)
	dia._capa.add_child(el)
	await paso.call("elección")
	el.queue_free()
	main.motor.mandato.finalizar("fin_mandato")
	main.mostrar_fin()
	await paso.call("fin de partida")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
