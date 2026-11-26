extends SceneTree
## Pantalla de fin de partida (mata los mutantes G12–G15): fecha corta de los hitos (mes correcto, cualquier mes), botón principal según el fin
## (reelección si se aprobó la reforma, oposición si no; «Intentar de nuevo» solo tras una derrota electoral) y recorte de la lista de leyes a 8.

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


func _hay(raiz: Node, txt: String) -> bool:
	return _textos(raiz).has(txt)


func _fin(datos: Dictionary, etapa: String, reforma: bool, leyes: int) -> Control:
	var m := AyudaV2.gobierno(datos, 11)
	m.estado.etapa = etapa
	var ids: Array = m._cartas_por_id.keys()
	for i in range(leyes):
		m.estado.registro_acciones.append({"turno": 1, "tipo": "votacion", "detalle": {"aprobada": true, "carta": ids[i]}})
	if reforma:
		m.estado.cartas_ejecutadas["reforma_reeleccion"] = 1
	var f := PantallaFin.new()
	f.motor = m
	f.datos = datos
	root.add_child(f)
	return f


func _correr() -> void:
	var meses := ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
	for i in range(12):
		_check(PantallaFin.fecha_corta("2025-%02d-05" % (i + 1)) == "5 %s 2025" % meses[i], "fecha_corta del mes %d da «%s»" % [i + 1, PantallaFin.fecha_corta("2025-%02d-05" % (i + 1))])
	_check(PantallaFin.fecha_corta("sin-formato") == "sin-formato", "una fecha sin formato se devuelve igual")
	var datos := Datos.cargar_todo()
	var f1 := _fin(datos, "fin_mandato", false, 0)
	await process_frame
	_check(_hay(f1, "Seguir tu carrera: pasar a la oposición"), "sin la reforma, el fin de mandato ofrece pasar a la oposición")
	_check(not _hay(f1, "Postularte a la reelección"), "sin la reforma no se ofrece la reelección")
	_check(_hay(f1, "Volver al inicio") and not _hay(f1, "Intentar de nuevo"), "tras terminar el mandato el botón del pie es «Volver al inicio»")
	f1.queue_free()
	var f2 := _fin(datos, "fin_mandato", true, 0)
	await process_frame
	_check(_hay(f2, "Postularte a la reelección"), "con la reforma aprobada se ofrece la reelección")
	_check(not _hay(f2, "Seguir tu carrera: pasar a la oposición"), "con la reforma no se ofrece pasar a la oposición")
	f2.queue_free()
	var f3 := _fin(datos, "derrota_electoral", false, 0)
	await process_frame
	_check(_hay(f3, "Intentar de nuevo") and _hay(f3, "Volver al inicio"), "tras una derrota electoral se ofrece «Intentar de nuevo» y «Volver al inicio»")
	f3.queue_free()
	var f4 := _fin(datos, "fin_mandato", false, 11)
	await process_frame
	_check(_hay(f4, "y 3 más."), "con 11 leyes aprobadas se listan 8 y se avisa «y 3 más.»")
	var mostradas := 0
	for t in f4.leyes_aprobadas():
		if _hay(f4, "· " + t):
			mostradas += 1
	_check(f4.leyes_aprobadas().size() == 11 and mostradas >= 8 and mostradas <= 11, "la lista muestra las leyes aprobadas (%d de 11)" % mostradas)
	var ultima: String = f4.leyes_aprobadas()[10]
	_check(f4.leyes_aprobadas().slice(0, 8).has(ultima) or not _hay(f4, "· " + ultima), "la undécima ley no se lista (solo las 8 primeras)")
	f4.queue_free()
	var f5 := _fin(datos, "fin_mandato", false, 8)
	await process_frame
	_check(not _textos(f5).any(func(t: String) -> bool: return t.ends_with(" más.")), "con exactamente 8 leyes no hay aviso de «más»")
	f5.queue_free()
	if _fallos == 0:
		print("test_pantalla_fin: OK")
	quit(1 if _fallos > 0 else 0)
