extends SceneTree
## Pantalla de la elección y hoja de delegación (mata los mutantes G17–G19): la leyenda y la marca del piso de segunda vuelta en la 1ª vuelta
## (y no en la 2ª), los colores del riesgo de delegar en sus umbrales (0,25 y 0,45) y el aviso de límite de delegaciones exactamente al llegar al máximo.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _textos(raiz: Node) -> Array[String]:
	var r: Array[String] = []
	for n in raiz.find_children("*", "Control", true, false):
		if n is Label:
			r.append((n as Label).text)
		elif n is Button:
			r.append((n as Button).text)
	return r


func _hay_con(raiz: Node, trozo: String) -> bool:
	return _textos(raiz).any(func(t: String) -> bool: return t.contains(trozo))


func _correr() -> void:
	# colores del riesgo de delegar
	_check(PanelDelegar.color_riesgo(0.20) == Tema.bien(), "riesgo 0,20 es bajo")
	_check(PanelDelegar.color_riesgo(0.25) == Tema.bien(), "riesgo 0,25 sigue siendo bajo")
	_check(PanelDelegar.color_riesgo(0.30) == Tema.ORO, "riesgo 0,30 es medio")
	_check(PanelDelegar.color_riesgo(0.45) == Tema.ORO, "riesgo 0,45 sigue siendo medio")
	_check(PanelDelegar.color_riesgo(0.50) == FilasUI.ROJO_TEXTO, "riesgo 0,50 es alto")
	var datos := Datos.cargar_todo()
	var m := AyudaV2.gobierno(datos, 11)
	var piso := int(round(float(m.catalogo_leyes["hemiciclo"]["umbral_pasa_balotaje"])))
	# elección: el piso aparece en la 1ª vuelta y no en la 2ª
	var regional: Dictionary = m.estado.aprobacion_regional.duplicate()
	var e1: Control = PantallaEleccion.crear(m, datos["regiones"], regional, {"electo": false, "balotaje": true, "ronda": 1, "voto_final": 40.0, "umbral": 51.0}, func() -> void: pass)
	root.add_child(e1)
	await process_frame
	_check(_hay_con(e1, "piso para la segunda vuelta (%d %%)" % piso), "la 1ª vuelta explica el piso de segunda vuelta (%d %%)" % piso)
	e1.queue_free()
	var e2: Control = PantallaEleccion.crear(m, datos["regiones"], regional, {"electo": false, "balotaje": false, "ronda": 2, "voto_final": 40.0, "umbral": 51.0}, func() -> void: pass)
	root.add_child(e2)
	await process_frame
	_check(not _hay_con(e2, "piso para la segunda vuelta"), "la 2ª vuelta no menciona un piso")
	e2.queue_free()
	# hoja de delegación: el aviso de límite aparece justo al llegar al máximo, no antes
	var maximo := int(m.catalogo_leyes["delegacion"]["max_por_turno"])
	var aviso := Razones.texto({"razon": "limite_delegaciones"})
	m.estado.delegadas_turno = maximo - 1
	var h1: Control = PanelDelegar.crear(m, 0, "metropolitana", func(_r: Dictionary) -> void: pass)
	root.add_child(h1)
	await process_frame
	_check(not _textos(h1).has(aviso), "con %d delegadas de %d aún se puede delegar (no hay aviso de límite)" % [maximo - 1, maximo])
	h1.queue_free()
	m.estado.delegadas_turno = maximo
	var h2: Control = PanelDelegar.crear(m, 0, "metropolitana", func(_r: Dictionary) -> void: pass)
	root.add_child(h2)
	await process_frame
	_check(_textos(h2).has(aviso), "con %d delegadas de %d se avisa el límite" % [maximo, maximo])
	h2.queue_free()
	if _fallos == 0:
		print("test_eleccion_delegar: OK")
	quit(1 if _fallos > 0 else 0)
