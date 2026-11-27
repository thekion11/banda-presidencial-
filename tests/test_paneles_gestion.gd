extends SceneTree
## Paneles de gestión (mata los mutantes G23–G28): movimientos internos (aviso de «solo en gobierno», plural del costo, porcentaje de avance de la obra),
## asesores (botón contratar/despedir y afinidad en %) y afiliación (solo «existente» abre la lista de partidos).
## G20 (gabinete `<=` tam) es equivalente: hay 75 ministros en 25 cargos y el tamaño es 25, nunca se llega a elegir uno más.

var _fallos := 0
var _elegida: Array = []


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
	var datos := Datos.cargar_todo()
	var m := AyudaV2.gobierno(datos, 11)
	var aviso := "Solo se pueden usar en gobierno"
	# --- movimientos internos
	var p1: Control = PanelInternos.crear(m, func(_t: String) -> void: pass, func() -> void: pass)
	root.add_child(p1)
	await process_frame
	_check(not _hay_con(p1, aviso), "en gobierno no aparece el aviso «solo en gobierno»")
	var vistas := 0
	for meta in m.movimientos.metas_disponibles():
		var costo := int(meta["costo_mov"])
		var esperado := "Costo %d mov. interno%s" % [costo, "" if costo == 1 else "s"]
		_check(_textos(p1).any(func(t: String) -> bool: return t == esperado or t.begins_with(esperado + " ·")), "la meta «%s» muestra «%s»" % [meta["nombre"], esperado])
		vistas += 1
	_check(vistas > 0, "hay metas disponibles para comprobar el plural")
	p1.queue_free()
	m.estado.obras_en_curso.append({"nombre": "Obra de prueba", "dias_avanzados": 50, "dias_totales": 200, "region": "metropolitana", "id": "x", "efectos_final": []})
	var p2: Control = PanelInternos.crear(m, func(_t: String) -> void: pass, func() -> void: pass)
	root.add_child(p2)
	await process_frame
	_check(_hay_con(p2, "Obra de prueba · fase 2 de 5 · 25 %"), "la obra al 25 %% (50 de 200 días) muestra fase 2 de 5 y 25 %% (textos: %s)" % str(_textos(p2).filter(func(t: String) -> bool: return t.contains("Obra"))))
	p2.queue_free()
	m.estado.obras_en_curso.clear()
	var mc := AyudaV2.gobierno(datos, 12)
	mc.estado.etapa = "campana"
	var p3: Control = PanelInternos.crear(mc, func(_t: String) -> void: pass, func() -> void: pass)
	root.add_child(p3)
	await process_frame
	_check(_hay_con(p3, aviso), "en campaña aparece el aviso «solo en gobierno»")
	p3.queue_free()
	# --- asesores
	var ids: Array = m.equipo.asesores.keys()
	var p4: Control = PanelEquipo.crear(m, func(_t: String) -> void: pass, func() -> void: pass)
	root.add_child(p4)
	await process_frame
	var contratar := _textos(p4).filter(func(t: String) -> bool: return t.begins_with("Contratar"))
	_check(contratar.size() == ids.size() and not _textos(p4).has("Despedir"), "sin asesores todos ofrecen «Contratar» (%d de %d) y ninguno «Despedir»" % [contratar.size(), ids.size()])
	var afin := roundi(m.equipo.afinidad(String(ids[0])) * 100.0)
	_check(_hay_con(p4, "Afinidad con tu partido: %d %%" % afin), "la afinidad del primer asesor se muestra como %d %%" % afin)
	p4.queue_free()
	_check(bool(m.contratar_asesor(String(ids[0]))["ok"]), "se contrata el primer asesor")
	var p5: Control = PanelEquipo.crear(m, func(_t: String) -> void: pass, func() -> void: pass)
	root.add_child(p5)
	await process_frame
	_check(_textos(p5).has("Despedir"), "el asesor contratado ofrece «Despedir»")
	_check(_textos(p5).filter(func(t: String) -> bool: return t.begins_with("Contratar")).size() == ids.size() - 1, "los demás siguen ofreciendo «Contratar»")
	p5.queue_free()
	# --- afiliación
	var a := PantallaAfiliacion.new()
	a.datos = datos
	a.elegida.connect(func(k: String, b: Dictionary) -> void: _elegida = [k, b])
	root.add_child(a)
	await process_frame
	a._elegir("propio")
	_check(_elegida.size() == 2 and _elegida[0] == "propio", "elegir «propio» emite la afiliación sin pasar por la lista de partidos")
	_elegida = []
	a._elegir("independiente")
	_check(_elegida.size() == 2 and _elegida[0] == "independiente", "elegir «independiente» emite la afiliación")
	_elegida = []
	a._elegir("existente")
	await process_frame
	_check(_elegida.is_empty(), "elegir «existente» no emite todavía: abre la lista de partidos")
	a.queue_free()
	if _fallos == 0:
		print("test_paneles_gestion: OK")
	quit(1 if _fallos > 0 else 0)
