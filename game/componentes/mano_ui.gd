class_name ManoUI
extends Control
## Abanico de la mano. Solo las cartas que entran animan su llegada (mano continua, DISENO_V2 §3 y §12);
## las que ya estaban se reacomodan. Las que traen el registro `reposicion` entran con un giro dorado.

signal tocada(indice: int)
signal arrastrada(pos: Vector2)  # gesto de jugar la carta elegida: deslizarla hacia arriba, hacia el mapa (PR-02)

const ANCHO := 104.0
const ALTO := 170.0

var _pos_prev: Dictionary = {}  # id de carta -> última posición de reposo
var _sel_prev: int = -1
var _inicio: Vector2 = Vector2.ZERO
var _activo: bool = false


func _input(ev: InputEvent) -> void:
	## Deslizar hacia arriba (≥ 70 px, más vertical que horizontal) desde la mano juega la carta elegida; tocar sigue sirviendo como respaldo.
	if not (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	if ev.pressed:
		var sobre := get_viewport().gui_get_hovered_control()  # si una capa (evento, tutorial) tapa la mano, el gesto no cuenta
		_activo = is_visible_in_tree() and get_global_rect().has_point(ev.position) and (sobre == null or sobre == self or is_ancestor_of(sobre))
		_inicio = ev.position
	elif _activo:
		_activo = false
		var d: Vector2 = ev.position - _inicio
		if d.y < -70.0 and absf(d.x) < absf(d.y) * 0.8 or d.length() > 70.0 and not get_global_rect().has_point(ev.position):
			arrastrada.emit(ev.position)


static func texto_movimientos(est: EstadoSimulacion) -> String:
	## "base 5 · aprob. +1 · asesor +1": origen de los movimientos del turno (el bono de asesores rige desde el siguiente amanecer).
	var ap := int(est.bono_mov.get("aprobacion", 0))
	var ase := int(est.bono_mov.get("asesores", 0))
	var s := "base %d" % est.pa_maximo
	if ap > 0:
		s += " · aprob. +%d" % ap
	if ase > 0:
		s += " · asesor +%d" % ase
	return s


static func texto_pastilla(est: EstadoSimulacion) -> String:
	return "%d/%d mov" % [est.pa_actual, est.pa_maximo + int(est.bono_mov.get("aprobacion", 0)) + int(est.bono_mov.get("asesores", 0))]


func pintar(motor: MotorTurno, sel: int, ministro: String = "", nuevas: Array = []) -> void:
	for h in get_children():
		h.queue_free()
	var est := motor.estado
	var n := est.mano.size()
	if n == 0:
		_pos_prev.clear()
		return
	var paso := 0.0 if n < 2 else minf(ANCHO * 0.8, (Tema.ANCHO - 20.0 - ANCHO) / float(n - 1))
	var x0 := (Tema.ANCHO - (ANCHO + paso * float(n - 1))) * 0.5
	var anima_sel := sel != _sel_prev
	_sel_prev = sel
	var orden: Array[int] = []
	for i in range(n):
		if i != sel:
			orden.append(i)
	orden.append(sel)  # la elegida se dibuja encima
	var previas := _pos_prev
	_pos_prev = {}
	var k := 0
	for i in orden:
		var id := String(est.mano[i]["id"])
		var c := CartaUI.new()
		var costo := motor.costo_carta(est.mano[i], ministro)
		c.configurar(est.mano[i], costo)
		c.elegida = i == sel
		c.atenuada = i != sel or costo > est.pa_actual
		c.size = Vector2(ANCHO, ALTO)
		c.pivot_offset = Vector2(ANCHO * 0.5, ALTO)
		var reposo := Vector2(x0 + paso * float(i), 46.0)
		var rot := float(i - (n - 1) * 0.5) * 5.0
		var esc := Vector2.ONE
		var destino := reposo
		if i == sel:
			esc = Vector2(1.15, 1.15)
			destino.y = 44.0  # sube y crece sin tapar la cabecera "Tu mano"
			rot = 0.0
		_pos_prev[id] = destino
		c.tocada.connect(func(_c: CartaUI) -> void: tocada.emit(i))
		add_child(c)
		var tw := c.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if not previas.has(id):  # carta nueva: entra desde abajo (o con giro dorado si vino por reposición)
			var rep := nuevas.has(id)
			c.position = Vector2(destino.x, 260.0)
			c.rotation_degrees = -18.0 if rep else 0.0
			c.scale = Vector2(0.5, 0.5) if rep else Vector2.ONE
			if rep:
				c.modulate = Tema.ORO
				tw.tween_property(c, "modulate", Color.WHITE, 0.7)
			var demora := 0.07 * float(k)
			k += 1
			tw.tween_property(c, "position", destino, 0.42).set_delay(demora)
			tw.tween_property(c, "rotation_degrees", rot, 0.42).set_delay(demora)
			tw.tween_property(c, "scale", esc, 0.42).set_delay(demora)
		elif i == sel and anima_sel:  # la elegida se levanta con rebote
			c.position = Vector2(destino.x, destino.y + 26.0)
			c.rotation_degrees = rot
			c.scale = Vector2.ONE
			tw.tween_property(c, "position", destino, 0.22)
			tw.tween_property(c, "scale", esc, 0.22)
		else:  # las que ya estaban se deslizan a su nuevo lugar
			c.position = Vector2(float(previas[id].x), destino.y)
			c.rotation_degrees = rot
			c.scale = esc
			tw.tween_property(c, "position", destino, 0.25)
