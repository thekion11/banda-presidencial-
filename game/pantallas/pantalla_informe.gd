class_name PantallaInforme
extends Control
## Informe de prueba: resume el registro local y permite copiarlo al portapapeles para pegarlo en un mensaje.


static func crear() -> Control:
	var raiz := PantallaInforme.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Tema.OCEANO
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(fondo)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 44)
	m.add_theme_constant_override("margin_bottom", 53)
	raiz.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	v.add_child(Tema.etiqueta("INFORME DE PRUEBA", 10, Tema.ORO, true))
	v.add_child(Tema.etiqueta("Copia este informe y envíalo", 20, Tema.TEXTO, true))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var texto := RegistroPrueba.informe()
	var l := Tema.etiqueta(texto, 12, Tema.TEXTO_SUAVE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(l)
	var aviso := Tema.etiqueta("El registro vive solo en tu teléfono; no se envía nada automáticamente.", 10, Tema.TEXTO_SUAVE)
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(aviso)
	var copiar := Tema.boton("Copiar informe", Tema.PANEL, Tema.TEXTO, 14, 44)
	copiar.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(texto)
		copiar.text = "Copiado")
	v.add_child(copiar)
	var volver := FilasUI.boton_pie("Volver")
	volver.pressed.connect(raiz.queue_free)
	v.add_child(volver)
	return raiz
