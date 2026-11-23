class_name PantallaUrbano
extends RefCounted
## Mapa urbano de Gran Santiago (tema claro): filtros por tipo, líneas, propuesta punteada y hoja inferior "Obras en curso".

const FILTROS := [["Metro", ["transportes", "comite"], Color("#1F7A5C"), Color("#DDEFE6"), "train"], ["Vivienda", ["vivienda"], Color("#B7791F"), Color("#F7E7C4"), "home"],
		["Cárceles", ["seguridad", "justicia"], Color("#3B5BA9"), Color("#DEE5F5"), "grid"], ["Energía", ["energia"], Color("#C9A100"), Color("#FBF0B8"), "bolt"]]


static func _categoria_de(motor: MotorTurno, obra: Dictionary) -> String:
	if String(obra.get("propuesta", "")) != "":
		return "transportes"
	var id := String(obra["carta_id"])
	return String(motor._cartas_por_id[id]["categoria"]) if motor._cartas_por_id.has(id) else ""


static func _trazado_propuesta(motor: MotorTurno) -> Array:
	for o in motor.estado.obras_en_curso:
		var pid := String(o.get("propuesta", ""))
		if pid != "" and motor.catalogo_propuestas.has(pid):
			for v in motor.catalogo_propuestas[pid]["variantes"]:
				if v["id"] == o.get("variante", "A"):
					return v["trazado"]
	for pid in motor.estado.propuestas_abiertas:
		return motor.catalogo_propuestas[pid]["variantes"][0]["trazado"]
	return []


static func crear(motor: MotorTurno, urbano: Dictionary, al_volver: Callable, al_abrir_obra: Callable) -> Control:
	var capa := ColorRect.new()
	capa.color = Tema.FONDO_CLARO
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 16
	col.offset_right = -16
	col.offset_top = 40
	col.offset_bottom = 0
	col.add_theme_constant_override("separation", 10)
	capa.add_child(col)
	var cab := HBoxContainer.new()
	var tit := VBoxContainer.new()
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.add_theme_constant_override("separation", -2)
	tit.add_child(Tema.etiqueta_corta("MAPA NACIONAL › REGIÓN METROPOLITANA", 10, Color("#6A7684"), false, 700))
	tit.add_child(Tema.etiqueta_corta("Gran Santiago", 26, Tema.TINTA, true))
	cab.add_child(tit)
	var atras := Tema.boton("2D", Color.WHITE, Tema.TINTA, 13, 44)
	for e in ["normal", "hover", "pressed"]:
		atras.add_theme_stylebox_override(e, Tema.caja(Color.WHITE, 12, Tema.TINTA, 2))
	atras.custom_minimum_size = Vector2(54, 44)
	atras.pressed.connect(func() -> void:
		capa.queue_free()
		al_volver.call())
	cab.add_child(atras)
	col.add_child(cab)
	var mapa := UrbanoMapa.new()
	mapa.custom_minimum_size = Vector2(0, 300)
	var hoja := VBoxContainer.new()
	hoja.add_theme_constant_override("separation", 8)
	var estado := {"filtro": 0}
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	var botones: Array[Button] = []
	var refrescar := Callable()
	var refs := {"f": refrescar}
	for i in range(FILTROS.size()):
		var b := Tema.boton(String(FILTROS[i][0]), Color.WHITE, Tema.TINTA, 13, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			estado["filtro"] = i
			refs["f"].call())
		botones.append(b)
		chips.add_child(b)
	col.add_child(chips)
	col.add_child(mapa)
	var panel := PanelContainer.new()
	var sb := Tema.caja(Color.WHITE, 22, Tema.BORDE_CLARO, 1)
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(hoja)
	col.add_child(panel)
	mapa.cargar(urbano)
	refs["f"] = func() -> void:
		var f: Array = FILTROS[int(estado["filtro"])]
		for i in range(botones.size()):
			var sel := i == int(estado["filtro"])
			for e in ["normal", "hover", "pressed"]:
				botones[i].add_theme_stylebox_override(e, Tema.caja(Tema.TINTA if sel else Color.WHITE, 22, Tema.TINTA, 2))
			for e in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				botones[i].add_theme_color_override(e, Tema.TEXTO if sel else Tema.TINTA)
		mapa.mostrar_metro = int(estado["filtro"]) == 0
		mapa.propuesta = _trazado_propuesta(motor) if int(estado["filtro"]) == 0 else []
		mapa.queue_redraw()
		for h in hoja.get_children():
			h.queue_free()
		var lista: Array[Dictionary] = []
		for o in motor.estado.obras_en_curso:
			if _categoria_de(motor, o) in f[1]:
				lista.append(o)
		var mk: Array = []
		for o in lista:
			mk.append({"pct": roundi(100.0 * float(o["dias_avanzados"]) / float(o["dias_totales"])), "color": Tema.ROJO if int(estado["filtro"]) == 0 else f[2]})
		mapa.marcadores = mk
		var cab2 := HBoxContainer.new()
		cab2.add_child(Tema.etiqueta_corta("Obras en curso", 16, Tema.TINTA, true))
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cab2.add_child(sp)
		cab2.add_child(Tema.etiqueta_corta("%d de %d" % [mini(lista.size(), 3), lista.size()], 11, Color("#6A7684")))
		hoja.add_child(cab2)
		if lista.is_empty():
			hoja.add_child(Tema.etiqueta("No hay obras de este tipo en curso. Juega cartas de esta categoría o aprueba una propuesta del Comité.", 12, Color("#6A7684")))
		for o in lista.slice(0, 3):
			var fila := Button.new()
			fila.flat = true
			fila.custom_minimum_size = Vector2(0, 52)
			for e in ["normal", "hover", "pressed", "focus"]:
				fila.add_theme_stylebox_override(e, StyleBoxEmpty.new())
			var h := HBoxContainer.new()
			h.set_anchors_preset(Control.PRESET_FULL_RECT)
			h.add_theme_constant_override("separation", 10)
			h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ic := PanelContainer.new()
			ic.add_theme_stylebox_override("panel", Tema.caja(f[3], 10))
			ic.custom_minimum_size = Vector2(36, 36)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ic.add_child(Icono.crear(String(f[4]), f[2], 18.0))
			h.add_child(ic)
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(Tema.etiqueta_corta(String(o["nombre"]) if String(o["nombre"]).length() <= 30 else String(o["nombre"]).left(29) + "…", 13, Tema.TINTA, false, 700))
			var barra := ProgressBar.new()
			barra.show_percentage = false
			barra.custom_minimum_size = Vector2(0, 6)
			barra.value = 100.0 * float(o["dias_avanzados"]) / float(o["dias_totales"])
			barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
			barra.add_theme_stylebox_override("background", Tema.caja(Color("#E7E1D3"), 3))
			barra.add_theme_stylebox_override("fill", Tema.caja(f[2], 3))
			v.add_child(barra)
			h.add_child(v)
			h.add_child(Tema.etiqueta_corta(PantallaHito.CORTAS[MotorObras.fase_de(o) - 1], 11, Color("#6A7684")))
			fila.add_child(h)
			fila.pressed.connect(func() -> void: al_abrir_obra.call(o))
			hoja.add_child(fila)
	refs["f"].call()
	return capa
