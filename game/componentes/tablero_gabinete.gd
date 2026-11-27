class_name TableroGabinete
extends RefCounted
## Piezas del gabinete como tablero (opción A elegida por el usuario el 27-nov-2026: «la elección del personal del
## gabinete no es tan entretenida además de qué es solo un formulario»): el puesto de cada ministerio y la carta de cada
## candidato. La carta se nombra tocándola dos veces o arrastrándola a su puesto. Solo datos existentes (ministros.json
## y las salidas del motor: afinidad, efecto semanal).

const CORTOS := {"min_interior": "Interior", "min_exteriores": "Exteriores", "min_defensa": "Defensa", "min_hacienda": "Hacienda",
	"min_segegob": "Segegob", "min_economia": "Economía", "min_social": "Social", "min_educacion": "Educación", "min_justicia": "Justicia",
	"min_trabajo": "Trabajo", "min_obras": "Obras", "min_salud": "Salud", "min_vivienda": "Vivienda", "min_agricultura": "Agricultura",
	"min_mineria": "Minería", "min_transportes": "Transportes", "min_bienes": "Bienes", "min_energia": "Energía", "min_ambiente": "Ambiente",
	"min_segpres": "Segpres", "min_deporte": "Deporte", "min_mujer": "Mujer", "min_cultura": "Culturas", "min_ciencia": "Ciencia",
	"min_seguridad": "Seguridad"}
const ESTILOS := {"tecnico": "Técnico", "politico": "Político", "comunicador": "Comunicador", "negociador": "Negociador"}
const NOMBRES_IND := {"aprobacion": "Aprob.", "capital": "Capital", "cohesion": "Cohes.", "fiscal": "Fiscal", "riesgo_ejecucion": "Riesgo"}


static func corto(slot: String, cartera: String) -> String:
	return String(CORTOS.get(slot, cartera.replace("Ministerio de ", "").replace("Ministerio del ", "")))


static func texto_efecto(ef: Dictionary, sufijo: String = "/sem") -> String:
	## {capital: 0.03, cohesion: -0.01} -> «Capital +0,03/sem · Cohesión −0,01/sem» (vacío si no cambia nada).
	var partes: Array[String] = []
	for k in ef.keys():
		var d := float(ef[k])
		if absf(d) >= 0.005:
			partes.append("%s %s%s%s" % [String(NOMBRES_IND.get(k, k)), "+" if d >= 0.0 else "−", Tema.dec(absf(d), 2), sufijo])
	return " · ".join(partes)


class Puesto extends Button:
	## Puesto de un ministerio en el tablero: dorado si lo elegiste, azul con filo gris si lo llenó el relleno automático, vacío si no.
	## Acepta que le suelten la carta de uno de sus candidatos.
	var slot := ""
	var al_soltar: Callable  # func(id_ministro)
	var _nombre: Label
	var _estado: Label

	func _init(p_slot: String, titulo: String) -> void:
		slot = p_slot
		custom_minimum_size = Vector2(Tema.TACTIL, 52)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_nombre = Tema.etiqueta_corta(titulo, 10, Tema.TEXTO, false, 700)
		_estado = Tema.etiqueta_corta("", 10, Tema.TEXTO_SUAVE)
		for l: Label in [_nombre, _estado]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			v.add_child(l)
		add_child(v)

	func pintar(estado: String, activo: bool) -> void:
		## estado: "elegido" | "auto" | "vacio"
		var fondo := Tema.ORO if estado == "elegido" else Color(Tema.PANEL, 0.6)
		var borde := Tema.ORO if activo else (Color("#8FA6BA") if estado == "auto" else Color("#2A6290"))
		var caja := Tema.caja(fondo, 10, borde, 3 if activo else 1)
		for e in ["normal", "hover", "pressed", "disabled"]:
			add_theme_stylebox_override(e, caja)
		_nombre.add_theme_color_override("font_color", Tema.TINTA if estado == "elegido" else Tema.TEXTO)
		_estado.add_theme_color_override("font_color", Tema.TINTA if estado == "elegido" else Tema.TEXTO_SUAVE)
		_estado.text = {"elegido": "elegido", "auto": "automático", "vacio": "vacío"}[estado]

	func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
		return data is Dictionary and String(data.get("slot", "")) == slot and al_soltar.is_valid()

	func _drop_data(_pos: Vector2, data: Variant) -> void:
		al_soltar.call(String(data["id"]))


class Candidato extends Button:
	## Carta de un candidato: estilo, rasgo, ahorro de movimientos, ejecución, riesgo de escándalo y afinidad con tu
	## partido. Se arrastra a su puesto para nombrarlo.
	var id := ""
	var slot := ""

	func _init(ficha: Dictionary, nombrado: bool, previsto: bool) -> void:
		id = String(ficha["id"])
		slot = String(ficha["ministerio"])
		custom_minimum_size = Vector2(Tema.TACTIL, 176)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var caja := Tema.caja(Tema.CREMA, 12, Tema.ORO if (previsto or nombrado) else Color("#D9D2C2"), 3 if previsto else (2 if nombrado else 1))
		for e in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(e, caja)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 7.0
		v.offset_right = -7.0
		v.offset_top = 6.0
		v.add_theme_constant_override("separation", 3)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(Tema.etiqueta(String(ficha["alias"]), 12, Tema.TINTA, true))
		var estilo := Tema.etiqueta_corta(String(ESTILOS.get(ficha["estilo"], ficha["estilo"])), 10, Color("#1F5C46"), false, 700)
		v.add_child(estilo)
		v.add_child(Tema.etiqueta(String(ficha["rasgo"]), 10, Tema.GRIS_CLARO))
		var ahorro := int(ficha["reduccion_costo_pa"])
		v.add_child(Tema.etiqueta("−%d en %s" % [ahorro, String(ficha["categoria_afin"]).capitalize()] if ahorro > 0 else "Sin ahorro", 10, Tema.bien_tinta() if ahorro > 0 else Tema.GRIS_CLARO, false, 600))
		v.add_child(Tema.etiqueta_corta("Ejecución +%d %%" % roundi(float(ficha["bono_ejecucion"]) * 100.0), 10, Tema.TINTA))
		v.add_child(Tema.etiqueta_corta("Escándalo %d %%" % roundi(float(ficha["riesgo_escandalo"]) * 100.0), 10, Tema.mal_tinta()))
		v.add_child(Tema.etiqueta_corta("Afinidad %d %%" % roundi(float(ficha["afinidad"]) * 100.0), 10, Tema.TINTA))
		for l in v.get_children():
			(l as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(v)

	func _get_drag_data(_pos: Vector2) -> Variant:
		if get_viewport().gui_is_dragging():
			var pc := PanelContainer.new()
			pc.add_theme_stylebox_override("panel", Tema.caja(Tema.ORO, 10))
			pc.add_child(Tema.etiqueta_corta((get_child(0).get_child(0) as Label).text, 12, Tema.TINTA, true))
			set_drag_preview(pc)
		return {"id": id, "slot": slot}
