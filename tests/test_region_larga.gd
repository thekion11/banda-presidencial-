extends SceneTree
## Regresión: elegir la región de nombre más largo (Magallanes y la Antártica Chilena) no debe ensanchar la columna de tarjetas del mapa
## más allá del borde derecho de la pantalla (390 px), ni con texto grande.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	Tutorial.ruta = "user://preferencias_region_larga.json"
	for grande in [false, true]:
		Ajustes.texto_grande = grande
		var main: Node = load("res://game/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		var datos: Dictionary = main.datos
		var resp: Array[Dictionary] = []
		for p in datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][1])
		main.motor = Partida.crear(datos, 5, GeneradorPartido.construir_partido("R", "RRR", "metropolitana", resp, datos["ideologia"]))
		main.mostrar_dia()  # la pantalla de gabinete ahora es la transición posterior a la elección: la campaña abre directo el día
		await process_frame
		var dia: Node = main._pantalla
		for t in dia._capa.find_children("*", "Tutorial", true, false):
			t.queue_free()
		for r in datos["regiones"]:
			dia._on_region(String(r["id"]))
			for _k in range(3):
				await process_frame
			for lbl_clave in ["rg_nombre", "ev_titulo"]:
				var l: Label = dia._r[lbl_clave]
				var fin := l.get_global_rect().end.x
				_check(fin <= 390.5, "región %s%s: «%s» llega a x=%.0f (> 390)" % [r["id"], " (texto grande)" if grande else "", l.text.left(30), fin])
		main.queue_free()
		await process_frame
	Ajustes.texto_grande = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	print("test_region_larga: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
