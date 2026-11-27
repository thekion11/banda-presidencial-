class_name PantallaGabinete
extends Control
## Etapa de configuración, después de fundar el partido y antes de la campaña: el jugador elige su gabinete.

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
	v.add_child(Tema.etiqueta("CONFIGURACIÓN · PASO 3", 10, Tema.ORO, true))
	v.add_child(Tema.etiqueta("Forma tu gabinete", 24, Tema.TEXTO, true))
	v.add_child(Tema.etiqueta("El ministro de cada área lleva sus cartas. Ya viene completo: puedes empezar así y cambiarlo durante la campaña.", 12, Tema.TEXTO_SUAVE))
	_aviso = Tema.etiqueta("", 12, FilasUI.ROJO_TEXTO, true)
	v.add_child(_aviso)
	var sel := PanelGabinete.crear(motor, "Comenzar campaña · %d semanas" % int(motor.catalogo_leyes["hemiciclo"]["semanas_campana"]), listo.emit, func(t: String) -> void: _aviso.text = t)
	sel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sel)
	Movimiento.escalonar(v, 0.05, 0.05)
