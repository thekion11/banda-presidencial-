class_name PantallaGabinete
extends Control
## Transición presidencial (pedido del usuario del 27-nov-2026: «la elección del gabinete es después de las elecciones»):
## recién ganada la elección y antes de la primera semana de gobierno, el jugador nombra a sus 25 ministros.

signal listo

var motor: MotorTurno
var _aviso: Label


func _ready() -> void:
	PanelCoalicion.abierto = ""  # estado de pestañas de la partida anterior
	PanelGestion.pestana = "gabinete"
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		m.add_theme_constant_override("margin_" + lado, 16)
	m.add_theme_constant_override("margin_top", roundi(maxf(28.0, Tema.margen_superior())))  # muesca o cámara
	m.add_theme_constant_override("margin_bottom", 53)  # el botón principal queda donde el de la fundación del partido
	add_child(m)
	var v := FilasUI.col(8)
	m.add_child(v)
	v.add_child(Tema.etiqueta("TRANSICIÓN PRESIDENCIAL", 10, Tema.ORO, true))
	v.add_child(Tema.etiqueta("Elige a tu equipo", 24, Tema.TEXTO, true))
	v.add_child(Tema.etiqueta("Ganaste. Antes de asumir, nombra a tus ministros: el de cada área lleva sus cartas. Ya viene completo; puedes confirmarlo así.", 12, Tema.TEXTO_SUAVE))
	_aviso = Tema.etiqueta("", 12, FilasUI.ROJO_TEXTO, true)
	v.add_child(_aviso)
	var sel := PanelGabinete.crear(motor, "Confirmar gabinete y asumir", _foto_y_listo, func(t: String) -> void: _aviso.text = t)
	sel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sel)
	Movimiento.escalonar(v, 0.05, 0.05)


func _foto_y_listo() -> void:
	## «Foto de gabinete» al asumir: los 25 retratos aparecen uno a uno bajo «Tu gabinete jura»; un toque o 2,6 s y sigue.
	if not Movimiento.activo():
		listo.emit()
		return
	var capa := ColorRect.new()
	capa.color = Color(Tema.OCEANO, 0.96)
	capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(capa)
	var v := FilasUI.col(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(v)
	var cab := Tema.etiqueta("TU GABINETE JURA", 11, Tema.ORO, true)
	cab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cab)
	var tit := Tema.etiqueta(String(motor.estado.partido.get("nombre", "Tu gobierno")), 20, Tema.TEXTO, true)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.custom_minimum_size.x = 340.0
	v.add_child(tit)
	var grilla := GridContainer.new()
	grilla.columns = 5
	grilla.add_theme_constant_override("h_separation", 8)
	grilla.add_theme_constant_override("v_separation", 8)
	for id in motor.estado.gabinete:
		var mi: Dictionary = motor.catalogo_ministros[id]
		var r := TableroGabinete.Retrato.new(String(id), String(mi.get("estilo", "")), String(mi["alias"]), mi.get("retrato", {}))
		r.custom_minimum_size = Vector2(56, 60)
		grilla.add_child(r)
	v.add_child(grilla)
	Movimiento.escalonar(grilla, 0.2, 0.05, 25)
	Feedback.sonar("decision")
	var hecho := {"listo": false}
	var seguir := func() -> void:
		if hecho["listo"] or not is_inside_tree():
			return
		hecho["listo"] = true
		listo.emit()
	capa.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and not ev.pressed:
			seguir.call())
	get_tree().create_timer(2.6).timeout.connect(seguir)

