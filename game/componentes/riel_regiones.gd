class_name RielRegiones
extends ScrollContainer
## Riel de regiones sobre el mapa del día (pedido del usuario del 27-nov-2026, opción elegida «Mapa A + riel»): las 16
## regiones de norte a sur con su aprobación, deslizable. Tocar una la elige y acerca el mapa sobre ella; tocar la ya
## elegida abre su detalle (Nación, o el mapa urbano para la Metropolitana).

signal elegida(id: String)
signal detalle(id: String)

var _botones: Dictionary = {}  # id -> Button
var _valores: Dictionary = {}  # id -> Label del porcentaje
var _seleccion := ""
var _previos: Dictionary = {}  # id -> aprobación mostrada: al cambiar, la cifra cuenta y aparece una flecha
var _flechas: Dictionary = {}  # id -> Icono «up» / «down»


func construir(regiones: Array) -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(col)
	for r in regiones:
		var id := String(r["id"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(Tema.TACTIL, Tema.TACTIL)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var fila := HBoxContainer.new()
		fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fila.offset_left = 10.0
		fila.offset_right = -10.0
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nombre := Tema.etiqueta_corta(PanelSectra.nombre_corto(String(r["nombre"])), 12, Tema.TEXTO, false, 600)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.clip_text = true
		nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var valor := Tema.etiqueta_corta("", 12, Tema.TEXTO, true)
		valor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var flecha := Icono.crear("up", Tema.TEXTO, 12.0)
		flecha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		flecha.visible = false
		fila.add_child(nombre)
		fila.add_child(flecha)
		fila.add_child(valor)
		_flechas[id] = flecha
		b.add_child(fila)
		b.pressed.connect(func() -> void:
			if id == _seleccion:
				detalle.emit(id)
			else:
				elegida.emit(id))
		col.add_child(b)
		_botones[id] = b
		_valores[id] = valor


func pintar(aprobacion: Dictionary, seleccion: String) -> void:
	## Porcentaje y color de cada región; la elegida con borde dorado y siempre a la vista en el riel.
	var cambio := seleccion != _seleccion
	_seleccion = seleccion
	for id in _botones.keys():
		var v := float(aprobacion.get(id, 0.0))
		var antes: float = _previos.get(id, v)
		_previos[id] = v
		var flecha: Icono = _flechas[id]
		if roundi(antes) != roundi(v):  # cambió: flecha hacia donde se movió y la cifra cuenta
			flecha.tipo = "up" if v > antes else "down"
			flecha.color = Tema.bien() if v > antes else FilasUI.ROJO_TEXTO
			flecha.visible = true
			flecha.queue_redraw()
			if Movimiento.activo():
				Movimiento.contar(_valores[id], v, func(x: float) -> String: return Tema.pct(x), antes)
			else:
				(_valores[id] as Label).text = Tema.pct(v)
		else:
			(_valores[id] as Label).text = Tema.pct(v)
		(_valores[id] as Label).add_theme_color_override("font_color", Tema.color_aprobacion(v + 12.0))
		var on: bool = id == seleccion
		var caja := Tema.caja(Color(0.07, 0.2, 0.32, 0.92) if not on else Tema.PANEL, 12, Tema.ORO if on else Color("#2B5D86"), 2 if on else 1)
		for e in ["normal", "hover", "pressed"]:
			(_botones[id] as Button).add_theme_stylebox_override(e, caja)
	if cambio and _botones.has(seleccion):
		ensure_control_visible.call_deferred(_botones[seleccion])


func boton(id: String) -> Control:
	return _botones.get(id, null)
