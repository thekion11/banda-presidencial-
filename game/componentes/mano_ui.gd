class_name ManoUI
extends Control
## Abanico de la mano. Solo las cartas que entran animan su llegada (mano continua, DISENO_V2 §3 y §12);
## las que ya estaban se reacomodan. Las que traen el registro `reposicion` entran con un giro dorado.

signal tocada(indice: int)
signal arrastrada(pos: Vector2)  # gesto de jugar la carta elegida: deslizarla hacia arriba, hacia el mapa (PR-02)

const ANCHO := 104.0
const ALTO := 170.0
const PULSACION_LARGA_MS := 450  # mantener el dedo sobre una carta abre su ficha ampliada (P10)

var _pos_prev: Dictionary = {}  # id de carta -> última posición de reposo
var _sel_prev: int = -1
var _inicio: Vector2 = Vector2.ZERO
var _activo: bool = false
var _motor: MotorTurno
var _ministro: String = ""
var _ficha: FichaAmpliada
var _toque: int = 0  # contador de pulsaciones: invalida el temporizador de una pulsación ya soltada
var _dedo: Vector2 = Vector2.ZERO  # última posición del dedo (de los propios eventos: fiable en teléfono y en pruebas)


func _input(ev: InputEvent) -> void:
	## Deslizar hacia arriba (≥ 70 px, más vertical que horizontal) desde la mano juega la carta elegida; tocar sigue sirviendo como respaldo.
	if ev is InputEventMouseMotion or ev is InputEventScreenDrag:
		_dedo = ev.position
		return
	if not (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	if ev.pressed:
		var sobre := get_viewport().gui_get_hovered_control()  # si una capa (evento, tutorial) tapa la mano, el gesto no cuenta
		_activo = is_visible_in_tree() and get_global_rect().has_point(ev.position) and (sobre == null or sobre == self or is_ancestor_of(sobre))
		_inicio = ev.position
		_dedo = ev.position
		_toque += 1
		if _activo:
			var n := _toque
			get_tree().create_timer(PULSACION_LARGA_MS / 1000.0).timeout.connect(func() -> void: _pulsacion_larga(n))
	elif _ficha != null:  # soltar cierra la ficha; no juega ni desliza
		_ficha.queue_free()
		_ficha = null
		_activo = false
		_toque += 1
	elif _activo:
		_toque += 1
		_activo = false
		var d: Vector2 = ev.position - _inicio
		if d.y < -70.0 and absf(d.x) < absf(d.y) * 0.8 or d.length() > 70.0 and not get_global_rect().has_point(ev.position):
			arrastrada.emit(ev.position)


func _pulsacion_larga(n: int) -> void:
	## Sigue presionado sobre la misma carta sin moverse: abre su ficha ampliada.
	if n != _toque or not _activo or _motor == null or not is_inside_tree():
		return
	var pos := _dedo
	if pos.distance_to(_inicio) > 14.0:
		return
	var hijos := get_children()
	hijos.reverse()  # la de encima primero (la elegida se dibuja al final)
	for c in hijos:
		if c is CartaUI and not c.is_queued_for_deletion() and (c as CartaUI).get_global_rect().has_point(pos):
			_ficha = FichaAmpliada.crear((c as CartaUI).carta, (c as CartaUI).costo, _motor.catalogo_leyes)
			get_tree().root.add_child(_ficha)
			Feedback.vibrar(15)
			return


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
	_motor = motor
	_ministro = ministro
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
		if i == sel:
			Movimiento.mecer(c, destino.y, 3.0, 0.8)  # la elegida se mece suave tras posarse; el resto queda quieta
