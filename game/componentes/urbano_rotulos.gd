class_name UrbanoRotulos
extends RefCounted
## Rótulos del mapa urbano en coordenadas de pantalla (tamaño fijo con cualquier zoom): nombres de estaciones y lugares,
## fichas numeradas en los terminales de Metro y flechas donde una línea continúa fuera del mapa.


static func etiquetas(ci: CanvasItem, tam: Vector2, margen: Vector2, zoom: float, pan: Vector2, reservados: Array[Rect2] = []) -> void:
	## Nombres en coordenadas de pantalla (tamaño fijo con cualquier zoom), sin pisarse ni salir del mapa.
	## Prioridad: combinaciones de Metro (desde zoom 1,5), lugares conocidos y, con mucho zoom, todas las estaciones.
	var c := UrbanoBase.preparar(tam, margen)
	var f := Tema.fuente_texto(700)
	var ocupados: Array[Rect2] = reservados.duplicate()
	var cand: Array = []  # [prioridad, posición local, texto, es_lugar]
	for i in range(c["estaciones"].size()):
		var lineas: Array = c["est_lineas"][i]
		var visibles := 0
		for lid in lineas:
			if not UrbanoBase.ocultas.has(lid):
				visibles += 1
		if visibles == 0:
			continue
		if lineas.size() > 1 and zoom >= 1.5:
			cand.append([0, c["estaciones"][i], c["est_nombres"][i], false])
		elif zoom >= 3.0:
			cand.append([2, c["estaciones"][i], c["est_nombres"][i], false])
	if zoom >= 2.0:  # estaciones de las líneas del jugador, con los nombres que eligió
		for pl in UrbanoBase._propias_px(c):
			for i in range(pl["est"].size()):
				if i < pl["nombres"].size():
					cand.append([1, pl["est"][i], String(pl["nombres"][i]), false])
	var nombres_est := {}
	for i in range(c["estaciones"].size()):
		nombres_est[String(c["est_nombres"][i])] = true
	for l in UrbanoBase.datos().get("lugares", []):
		if nombres_est.has(String(l["n"])) and zoom >= 1.5:
			continue  # ya se rotula como estación
		cand.append([1, UrbanoBase.a_px(l["p"], tam, margen), String(l["n"]).replace("Parque Metropolitano de Santiago", "Parque Metropolitano"), true])
	cand.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	for k in cand:
		var p: Vector2 = k[1] * zoom + pan
		if p.x < 0.0 or p.y < 0.0 or p.x > tam.x or p.y > tam.y:
			continue
		var txt: String = k[2]
		var ancho := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var colocada := false
		for desp in [Vector2(7, 0), Vector2(-7 - ancho, 0), Vector2(-ancho * 0.5, -14), Vector2(-ancho * 0.5, 14)]:
			var caja := Rect2(p.x + desp.x - 2.0, p.y + desp.y - 8.0, ancho + 4.0, 14.0)
			if caja.position.x < 2.0 or caja.end.x > tam.x - 2.0 or caja.position.y < 2.0 or caja.end.y > tam.y - 2.0:
				continue
			var choca := false
			for r in ocupados:
				if r.intersects(caja):
					choca = true
					break
			if choca:
				continue
			ocupados.append(caja)
			if bool(k[3]):
				ci.draw_circle(p, 3.0, Tema.ROJO)
			var o := Vector2(p.x + desp.x, p.y + desp.y + 3.5)
			ci.draw_string_outline(f, o, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 4, Color(0.94, 0.92, 0.87, 0.95))
			ci.draw_string(f, o, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TINTA)
			colocada = true
			break
		if not colocada and bool(k[3]):
			ci.draw_circle(p, 2.5, Tema.ROJO)


static func fichas(ci: CanvasItem, tam: Vector2, margen: Vector2, zoom: float, pan: Vector2) -> Array[Rect2]:
	## Fichas numeradas en los terminales y flechas donde la línea continúa fuera del mapa, en coordenadas de pantalla
	## (tamaño fijo con cualquier zoom). Devuelve los rectángulos ocupados para que las etiquetas no los pisen.
	var usados: Array[Rect2] = []
	var c := UrbanoBase.preparar(tam, margen)
	var f := Tema.fuente_titulo()
	for l in c["metro"]:
		if UrbanoBase.ocultas.has(l["id"]):
			continue
		var tinta: Color = Tema.TINTA if l["id"] == "L2" else Color.WHITE
		for cb in l["cabos"]:
			var p: Vector2 = Vector2(cb["p"]) * zoom + pan
			if p.x < -12.0 or p.y < -12.0 or p.x > tam.x + 12.0 or p.y > tam.y + 12.0:
				continue
			if cb["sigue"]:  # la línea continúa fuera de la ventana del mapa: flecha en el borde
				var d: Vector2 = cb["d"]
				var n := Vector2(-d.y, d.x)
				var pt := p + d * 16.0
				ci.draw_colored_polygon(PackedVector2Array([pt + d * 8.0, pt + n * 6.0, pt - n * 6.0]), Color(1, 1, 1, 0.9))
				ci.draw_colored_polygon(PackedVector2Array([pt + d * 6.0, pt + n * 4.2, pt - n * 4.2]), l["color"])
			else:  # terminal dentro del mapa: ficha con el número de la línea
				ci.draw_circle(p, 10.0, Color.WHITE)
				ci.draw_circle(p, 8.4, l["color"])
				ci.draw_string(f, p + Vector2(-8, 4.2), UrbanoBase.nombre_corto(l["id"]), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, tinta)
				usados.append(Rect2(p - Vector2(11, 11), Vector2(22, 22)))
	for pl in UrbanoBase._propias_px(c):
		var pts2: PackedVector2Array = pl["pts"]
		for q in ([pts2[0], pts2[pts2.size() - 1]] if pts2.size() >= 2 else []):
			var p2: Vector2 = q * zoom + pan
			if p2.x < -12.0 or p2.y < -12.0 or p2.x > tam.x + 12.0 or p2.y > tam.y + 12.0:
				continue
			ci.draw_circle(p2, 10.0, Color.WHITE)
			ci.draw_circle(p2, 8.4, UrbanoBase.COLOR_PROPIA)
			ci.draw_string(f, p2 + Vector2(-8, 4.2), String(pl["id"]), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, Color.WHITE)
			usados.append(Rect2(p2 - Vector2(11, 11), Vector2(22, 22)))
	return usados
