class_name MapaVivo
extends RefCounted
## Capa viva del mapa de Chile (se redibuja sola, barata): regiones que suben o bajan laten en verde o coral, el bastión
## tiene un pulso dorado, las obras se mecen, las propuestas laten y los fuegos de obra terminada. Separada de MapaChile
## para no acercarse al tope de 450 líneas; sigue al zoom y a la cámara del mapa.


static func dibujar(m: MapaChile, v: Control) -> void:
	## Mapa vivo (dirección visual v4): regiones con tendencia laten en verde o coral, el bastión tiene un pulso
	## dorado, las obras se mecen y las propuestas laten. Todo sigue al golpe de cámara.
	v.draw_set_transform_matrix(m._cam())
	var pulso := 0.5 + 0.5 * sin(m._t * 3.2)
	var clave := Vector4(m.size.x, m.size.y, m.x_centro_rel, m.estirar_x)
	if clave != m._segs_clave or not is_same(m._segs_de, m._tendencia):  # los segmentos solo cambian con el tamaño o la tendencia, no cada cuadro
		m._segs_clave = clave
		m._segs_de = m._tendencia
		for sg in [1, -1]:
			var acum := PackedVector2Array()
			for id in m._tendencia.keys():
				if int(m._tendencia[id]) == sg:
					for pts in m._contornos(id):
						if pts.size() >= 9:
							acum.append_array(m._segmentos(pts))
			m._segs_tendencia[sg] = acum
	for signo in [1, -1]:  # regiones que suben y que bajan: una llamada de dibujo por color
		var segs: PackedVector2Array = m._segs_tendencia.get(signo, PackedVector2Array())
		if not segs.is_empty():
			v.draw_multiline(segs, Color(Tema.bien() if signo > 0 else Tema.mal(), 0.25 + 0.55 * pulso), 2.0 + 1.5 * pulso, false)
	if m.bastion != "" and m._banda_y.has(m.bastion):
		var cb := m.centro(m.bastion) + Vector2(0.0, 12.0)
		var k := fmod(m._t, 2.2) / 2.2
		v.draw_arc(cb, 5.0 + 16.0 * k, 0.0, TAU, 32, Color(Tema.ORO, 0.8 * (1.0 - k)), 2.0, true)
		v.draw_circle(cb, 3.5 + 0.8 * pulso, Tema.ORO)
		v.draw_arc(cb, 3.5 + 0.8 * pulso, 0.0, TAU, 20, Tema.OCEANO, 1.2, true)
	for id in m.obras.keys():
		if int(m.obras[id]) > 0 and m._banda_y.has(id):
			var c := m.centro(id) + Vector2(10.0, -2.0 * sin(m._t * 2.4 + float(id.length())))
			v.draw_circle(c, 11.0, Tema.OCEANO)
			v.draw_circle(c, 9.5, Tema.ORO)
			v.draw_string(Tema.fuente_titulo(), c + Vector2(-9.5, 4.5), str(int(m.obras[id])), HORIZONTAL_ALIGNMENT_CENTER, 19.0, 13, Tema.TINTA)
	for id in m.propuestas.keys():
		if bool(m.propuestas[id]) and m._banda_y.has(id):
			var c2 := m.centro(id) + Vector2(-12.0, -2.0)
			var e := 1.0 + 0.12 * pulso
			v.draw_circle(c2, 11.0 * e, Tema.CREMA)
			v.draw_circle(c2, 9.5 * e, Tema.ROJO)
			v.draw_colored_polygon(PackedVector2Array([c2 + Vector2(-5, 1), c2 + Vector2(0, -5), c2 + Vector2(5, 1)]), Tema.TEXTO)
			v.draw_rect(Rect2(c2 + Vector2(-3.5, 1), Vector2(7, 5)), Tema.TEXTO)
	m._fuegos = FuegosMapa.dibujar(v, m._fuegos, m._t, m.centro)  # obras terminadas (fuegos_mapa.gd)
	v.draw_set_transform_matrix(Transform2D.IDENTITY)
