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
const AREAS := {"economia": "Economía", "educacion": "Educación", "energia": "Energía", "hacienda": "Hacienda", "medioambiente": "Ambiente",
	"obras": "Obras", "politica": "Política", "salud": "Salud", "seguridad": "Seguridad", "social": "Social", "transportes": "Transportes", "vivienda": "Vivienda"}
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


class Retrato extends Control:
	## Retrato ilustrado del candidato (personaje ficticio): busto dibujado, tono y peinado fijos según su id; traje por estilo.
	const PIELES := [Color("#F1C9A5"), Color("#D9A77E"), Color("#B57E57"), Color("#8A5A3C")]
	const PELOS := [Color("#2B1B12"), Color("#5A3A22"), Color("#8C8C8C"), Color("#1A1A1A"), Color("#7A4A1E")]
	const TRAJES := {"tecnico": Color("#1F5C46"), "politico": Color("#7A2A22"), "comunicador": Color("#2A6290"), "negociador": Color("#8A5A12")}  # negociador: oro oscuro
	var semilla := 0
	var estilo := ""
	var femenino := false
	var canas := false

	func _init(id: String, p_estilo: String, alias: String, rasgos: Dictionary = {}) -> void:
		## `rasgos` (ministros.json › retrato, opcional): recreación ilustrada que evoca a la figura del alias; nunca una foto.
		semilla = absi(hash(id))
		estilo = p_estilo
		femenino = alias.begins_with("La ")
		canas = bool(rasgos.get("canas", false))
		custom_minimum_size = Vector2(60, 64)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_style_box(Tema.caja(Color("#0E2A42"), 8, Color("#2A6290"), 1), Rect2(Vector2.ZERO, size))
		var piel: Color = PIELES[semilla % PIELES.size()]
		var pelo: Color = Color("#C9C9C9") if canas else PELOS[(semilla / 7) % PELOS.size()]
		var traje: Color = TRAJES.get(estilo, Tema.PANEL)
		var c := Vector2(w * 0.5, h * 0.40)
		var r := w * 0.19
		if femenino:  # melena detrás de la cara
			draw_circle(c + Vector2(0, r * 0.1), r * 1.22, pelo)
			draw_rect(Rect2(c.x - r * 1.22, c.y + r * 0.1, r * 2.44, r * 1.3), pelo)
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.08, h), Vector2(w * 0.16, h * 0.74), Vector2(w * 0.5, h * 0.64), Vector2(w * 0.84, h * 0.74), Vector2(w * 0.92, h)]), traje)
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.42, h * 0.66), Vector2(w * 0.58, h * 0.66), Vector2(w * 0.5, h * 0.86)]), Tema.CREMA)
		draw_rect(Rect2(c.x - r * 0.35, c.y + r * 0.7, r * 0.7, r * 0.8), piel)
		draw_circle(c, r, piel)
		draw_arc(c, r, PI * 1.05, PI * 1.95, 12, pelo, r * 0.7)  # pelo sobre la frente
		draw_circle(c + Vector2(-r * 0.38, r * 0.05), r * 0.09, Tema.TINTA)
		draw_circle(c + Vector2(r * 0.38, r * 0.05), r * 0.09, Tema.TINTA)
		if semilla % 3 == 0:
			draw_line(c + Vector2(-r * 0.35, r * 0.5), c + Vector2(r * 0.35, r * 0.5), Tema.TINTA, 1.4, true)
		else:
			draw_arc(c + Vector2(0, r * 0.25), r * 0.35, PI * 0.2, PI * 0.8, 8, Tema.TINTA, 1.4, true)
		if (semilla / 3) % 4 == 0:  # corbata o pañuelo dorado en algunos
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.47, h * 0.68), Vector2(w * 0.53, h * 0.68), Vector2(w * 0.5, h * 0.82)]), Tema.ORO)


class Candidato extends Button:
	## Fila de un candidato (como una ficha de contratación): retrato, nombre y estilo, y sus atributos con ícono y cifra a
	## la derecha (ahorro de movimientos, ejecución, escándalo y afinidad). Se toca dos veces o se arrastra a su puesto.
	var id := ""
	var slot := ""
	var alias := ""

	static func _atributo(icono: String, nombre: String, valor: String, color: Color) -> HBoxContainer:
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 4)
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := Icono.crear(icono, Tema.TEXTO_SUAVE, 12.0)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		f.add_child(ic)
		var n := Tema.etiqueta_corta(nombre, 10, Tema.TEXTO_SUAVE)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		f.add_child(n)
		f.add_child(Tema.etiqueta_corta(valor, 11, color, false, 700))
		for h in f.get_children():
			(h as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		return f

	func _init(ficha: Dictionary, nombrado: bool, previsto: bool, rasgos: Dictionary = {}) -> void:
		id = String(ficha["id"])
		slot = String(ficha["ministerio"])
		alias = String(ficha["alias"])
		custom_minimum_size = Vector2(Tema.TACTIL, 78)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var caja := Tema.caja(Color("#123552") if not previsto else Tema.PANEL, 10, Tema.ORO if (previsto or nombrado) else Color("#2A6290"), 2 if previsto else 1)
		for e in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(e, caja)
		var fila := HBoxContainer.new()
		fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fila.offset_left = 7.0
		fila.offset_right = -8.0
		fila.offset_top = 7.0
		fila.offset_bottom = -7.0
		fila.add_theme_constant_override("separation", 9)
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(Retrato.new(id, String(ficha["estilo"]), alias, rasgos))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var arriba := HBoxContainer.new()
		arriba.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nombre := Tema.etiqueta_corta(alias, 12, Tema.TEXTO, true)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.clip_text = true
		nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arriba.add_child(nombre)
		var etiqueta_estilo := String(ESTILOS.get(ficha["estilo"], ficha["estilo"])) + (" · en el cargo" if nombrado else "")
		var est := Tema.etiqueta_corta(etiqueta_estilo, 10, Tema.ORO, false, 600)
		est.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arriba.add_child(est)
		v.add_child(arriba)
		var grilla := GridContainer.new()
		grilla.columns = 2
		grilla.add_theme_constant_override("h_separation", 12)
		grilla.add_theme_constant_override("v_separation", 1)
		grilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grilla.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ahorro := int(ficha["reduccion_costo_pa"])
		var afin := float(ficha["afinidad"])
		grilla.add_child(_atributo("building", "Ejecución", "+%d %%" % roundi(float(ficha["bono_ejecucion"]) * 100.0), Tema.bien()))
		grilla.add_child(_atributo("down", "Polémica", "%d %%" % roundi(float(ficha["riesgo_escandalo"]) * 100.0), FilasUI.ROJO_TEXTO))
		grilla.add_child(_atributo("bolt", "Ahorro " + String(AREAS.get(ficha["categoria_afin"], ficha["categoria_afin"])) if ahorro > 0 else "Ahorro", ("−%d" % ahorro) if ahorro > 0 else "—", Tema.bien() if ahorro > 0 else Tema.TEXTO_SUAVE))
		grilla.add_child(_atributo("people", "Afinidad", "%d %%" % roundi(afin * 100.0), Tema.color_aprobacion(30.0 + afin * 30.0)))
		v.add_child(grilla)
		fila.add_child(v)
		add_child(fila)
		tooltip_text = String(ficha["rasgo"])

	func _get_drag_data(_pos: Vector2) -> Variant:
		if get_viewport().gui_is_dragging():
			var pc := PanelContainer.new()
			pc.add_theme_stylebox_override("panel", Tema.caja(Tema.ORO, 10))
			pc.add_child(Tema.etiqueta_corta(alias, 12, Tema.TINTA, true))
			set_drag_preview(pc)
		return {"id": id, "slot": slot}
