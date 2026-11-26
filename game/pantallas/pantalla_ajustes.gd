class_name PantallaAjustes
extends Control
## Ajustes: sonido, vibración y animaciones. Se abre como capa sobre el menú y guarda al cambiar.

signal cerrada


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # antes quedaba en tamaño 0: sin fondo, el menú se veía detrás
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.09, 0.15, 1.0)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		mc.add_theme_constant_override("margin_" + lado, 20)
	mc.add_theme_constant_override("margin_top", 56)
	mc.add_theme_constant_override("margin_bottom", 28)
	add_child(mc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	mc.add_child(col)
	col.add_child(Tema.etiqueta("Ajustes", 24, Tema.TEXTO, true))
	for fila in [["Sonido", "sonido"], ["Música", "musica"], ["Vibración", "vibracion"], ["Animaciones y movimiento", "animaciones"], ["Reducir movimiento", "reducir"], ["Texto grande", "texto_grande"], ["Colores para daltonismo", "daltonico"]]:
		var cb := CheckButton.new()
		cb.text = fila[0]
		cb.custom_minimum_size = Vector2(0, 52)
		cb.button_pressed = Ajustes.leer(fila[1])
		cb.add_theme_font_size_override("font_size", 14)
		cb.toggled.connect(func(on: bool) -> void:
			Ajustes.poner(fila[1], on)
			Ajustes.guardar()
			Feedback.sonar("toque"))
		col.add_child(cb)
	col.add_child(Tema.etiqueta("El texto grande se aplica al abrir cada pantalla; los colores para daltonismo pasan a azul y naranja la escala de aprobación y todo lo que sube o baja (votos, cambios, mapa).", 11, Tema.TEXTO_SUAVE))
	Movimiento.escalonar(col, 0.0, 0.05)
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(esp)
	var b := Tema.boton("Cerrar", Tema.ROJO, Tema.TEXTO, 15, 52)
	b.pressed.connect(func() -> void:
		cerrada.emit()
		queue_free())
	col.add_child(b)
