class_name FilasUI
extends RefCounted

const ROJO_TEXTO := Color("#F59A87")  # rojo de la paleta aclarado: contraste ≥ 4.5:1 sobre panel para texto pequeño
## Piezas comunes de los paneles de gestión: scroll, tarjetas, títulos y filas táctiles de varias líneas.


static func scroll(contenido: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(contenido)
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sc


static func tarjeta(hijo: Control, color: Color = Tema.PANEL, borde: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caja(color, 14, borde, 2 if borde.a > 0.0 else 0))
	p.add_child(hijo)
	return p


static func titulo(texto: String) -> Label:
	return Tema.etiqueta(texto, 15, Tema.TEXTO, true)


static func col(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func fila_boton(lineas: Array, fondo: Color, alto: float = 72.0) -> Button:
	## `lineas`: [[texto, tamaño, color, título?], ...]. Botón táctil con varias líneas sin cortar.
	var b := Button.new()
	b.custom_minimum_size = Vector2(Tema.TACTIL, alto)
	for e in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(e, Tema.caja(fondo if e != "hover" else fondo.lightened(0.08), 14))
	b.add_theme_stylebox_override("disabled", Tema.caja(fondo.darkened(0.25), 14))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12.0
	v.offset_right = -12.0
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for l in lineas:
		var et := Tema.etiqueta_corta(String(l[0]), int(l[1]), l[2], l.size() > 3 and bool(l[3]))
		et.clip_text = true
		v.add_child(et)
	b.add_child(v)
	return b


static func chip_barra(valor: float, color: Color) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 8)
	barra.value = clampf(valor, 0.0, 100.0)
	barra.add_theme_stylebox_override("background", Tema.caja(Color("#274A66"), 4))
	barra.add_theme_stylebox_override("fill", Tema.caja(color, 4))
	return barra


static func fila_h(izq: Control, der: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(izq)
	h.add_child(der)
	return h


static func capa_opaca() -> Control:
	## Raíz de pantalla completa con fondo océano (cubre la pantalla de día).
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Tema.OCEANO
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(fondo)
	return raiz


static func boton_pie(texto: String) -> Button:
	## Botón principal de las pantallas a pantalla completa: mismo rectángulo que el de fundación y gabinete (16, 739, 358 × 52).
	var b := Barras.boton_jugar()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 52)
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.anchor_right = 1.0
	b.offset_left = 16.0
	b.offset_right = -16.0
	b.offset_top = -105.0
	b.offset_bottom = -53.0
	Movimiento.halo(b, Tema.ORO, 26)  # halo del botón principal (no cambia su rectángulo)
	return b
