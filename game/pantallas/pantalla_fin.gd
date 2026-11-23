class_name PantallaFin
extends Control

signal otra_vez

var motor: MotorTurno


func _ready() -> void:
	var est := motor.estado
	var r := est.resultado_final
	add_child(Tema.fondo_hero("politica" if est.etapa == "fin_mandato" else "seguridad", 0.5, 0.0 if est.etapa == "fin_mandato" else 0.35))
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 330
	col.offset_bottom = -40
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	var titulos := {"fin_mandato": "Fin del mandato", "crisis": "Caída del gobierno", "derrota_electoral": "Derrota electoral"}
	col.add_child(Tema.etiqueta(String(titulos.get(est.etapa, "Fin")).to_upper(), 11, Tema.ORO, true))
	col.add_child(Tema.etiqueta(String(titulos.get(est.etapa, "Fin")), 34, Tema.TEXTO, true))
	var detalle := ""
	match est.etapa:
		"derrota_electoral":
			detalle = "Obtuviste %.1f %% frente a un umbral de %.0f %%. No alcanzaste la presidencia." % [float(r.get("voto_final", 0.0)), float(motor.catalogo_leyes["hemiciclo"]["umbral_victoria_presidencial"])]
		"crisis":
			detalle = "Tu aprobación se desplomó y el gobierno no resistió la crisis política en el turno %d." % est.turno_actual
		_:
			detalle = "Completaste los 4 años con %.1f %% de aprobación, %d obras terminadas y %d metas de legado pendientes." % [float(r.get("aprobacion", 0.0)), int(r.get("obras", 0)), int(r.get("promesas_pendientes", 0))]
	col.add_child(Tema.etiqueta(detalle, 15, Tema.TEXTO_SUAVE))
	if r.has("puntaje"):
		col.add_child(Tema.etiqueta("Puntaje final: %d" % int(r["puntaje"]), 22, Tema.ORO, true))
	col.add_child(Tema.etiqueta("Huella de la partida (para reproducirla): " + est.calcular_huella().substr(0, 16), 10, Tema.TEXTO_SUAVE))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(esp)
	var b := Barras.boton_jugar()
	b.text = "Volver al inicio"
	b.pressed.connect(func() -> void: otra_vez.emit())
	col.add_child(b)
