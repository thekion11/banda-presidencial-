class_name ManoVuelo
extends RefCounted
## Jugar una carta (dirección visual v4): una copia de la carta elegida sale de la mano, vuela hasta la región
## del mapa girando y encogiéndose, y al llegar el mapa reacciona (MapaChile.reaccionar). Solo presentación:
## la jugada ya se resolvió en el motor antes del vuelo. Sin animaciones, `al_llegar` corre al instante.

const DURACION := 0.42


static func datos(motor: MotorTurno, sel: int, mano: Control) -> Dictionary:
	## La carta elegida y su transformación en pantalla, leídas antes de que el motor la saque de la mano.
	if sel < 0 or sel >= motor.estado.mano.size():
		return {}
	for c in mano.get_children():
		if c is CartaUI and (c as CartaUI).elegida:
			return {"carta": motor.estado.mano[sel], "costo": (c as CartaUI).costo, "transform": (c as CartaUI).get_global_transform()}
	return {}


static func lanzar(capa: Control, d: Dictionary, mapa: MapaChile, region: String, color: Color, al_llegar: Callable) -> void:
	var destino := mapa.posicion_global(region)
	if not Movimiento.activo() or d.is_empty():
		al_llegar.call(destino)
		return
	var c := CartaUI.new()
	c.configurar(d["carta"], int(d["costo"]))
	c.elegida = true
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size = Vector2(ManoUI.ANCHO, ManoUI.ALTO)
	c.pivot_offset = c.size * 0.5
	capa.add_child(c)
	var t: Transform2D = d["transform"]
	var inv := capa.get_global_transform().affine_inverse()
	var esc := t.get_scale().x
	c.scale = Vector2.ONE * esc
	c.rotation = t.get_rotation()
	# mismo lugar en pantalla que la carta de la mano (allí gira desde su base; aquí, desde su centro)
	c.position = inv * t.origin - c.pivot_offset + Transform2D(c.rotation, c.scale, 0.0, Vector2.ZERO) * c.pivot_offset
	var llegada := inv * destino - c.size * 0.5
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "position", llegada, DURACION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(c, "scale", Vector2.ONE * 0.22, DURACION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(c, "rotation", c.rotation + deg_to_rad(16.0), DURACION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(c, "modulate", Color(color.lightened(0.4), 0.0), 0.12).set_delay(DURACION - 0.06)
	tw.chain().tween_callback(func() -> void:
		mapa.reaccionar(region, color)
		al_llegar.call(destino)
		c.queue_free())
