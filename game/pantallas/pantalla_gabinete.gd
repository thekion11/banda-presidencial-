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
	var sel := PanelGabinete.crear(motor, "Confirmar gabinete y asumir", listo.emit, func(t: String) -> void: _aviso.text = t)
	sel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sel)
	Movimiento.escalonar(v, 0.05, 0.05)
