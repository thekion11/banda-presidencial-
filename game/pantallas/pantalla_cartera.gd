class_name PantallaCartera
extends Control
## Cartera de proyectos: todas las cartas de proyecto reales (obras públicas, proyectos de ley, reformas) con su fuente y estado.
## Filtrable por tipo, región y sector. SOLO LECTURA: no llama a ninguna acción del motor ni cambia el estado de la partida.

const POR_PAGINA := 20
const TIPOS := [["", "Todos"], ["proyecto_publico", "Obras públicas"], ["proyecto_de_ley", "Proyectos de ley"], ["reforma_constitucional", "Reformas"]]
const NOMBRE_TIPO := {"proyecto_publico": "Obra pública", "proyecto_de_ley": "Proyecto de ley", "reforma_constitucional": "Reforma constitucional", "propuesta_constitucional": "Reforma constitucional"}

signal cerrada

var datos: Dictionary = {}
var motor: MotorTurno = null  # opcional: con partida en curso muestra el estado de cada carta
var f_tipo: String = ""
var f_region: String = ""
var f_sector: String = ""
var f_texto: String = ""  # búsqueda por texto en el título
var pagina: int = 0
var items: Array[Dictionary] = []
var filtrados: Array[Dictionary] = []
var _lista: VBoxContainer
var _conteo: Label
var _lbl_pag: Label
var _chips: Dictionary = {}  # "tipo"/"region"/"sector" -> {valor: Button}
var _scrolls: Dictionary = {}  # clave -> ScrollContainer de la fila de chips


static func crear(p_datos: Dictionary, p_motor: MotorTurno = null) -> PantallaCartera:
	var c := PantallaCartera.new()
	c.datos = p_datos
	c.motor = p_motor
	Tapa.cubrir(c)
	return c


static func _s(v: Variant) -> String:
	return "" if v == null else String(v)


static func _es_real(c: Dictionary) -> bool:
	return NOMBRE_TIPO.has(String(c.get("meta", {}).get("tipo", "")))


func _nombre_region(id: String) -> String:
	for r in datos["regiones"]:
		if String(r["id"]) == id:
			return String(r["nombre"]).replace(" de Santiago", "").replace(" Chilena", "")
	return "Nacional" if id == "" else id


func _fuente(c: Dictionary) -> String:
	var id := String(c.get("fuente", "")).get_slice("#", 1)
	for f in datos.get("fuentes", []):
		if String(f["id"]) == id:
			return "%s · corte %s" % [f["institucion"], f["fecha_corte"]]
	return String(c.get("fuente", "sin fuente"))


func _estado_partida(c: Dictionary) -> Array:
	if motor == null:
		return ["Sin partida abierta: estado real del proyecto", Tema.TEXTO_SUAVE]
	var est := motor.estado
	if est.cartas_ejecutadas.has(String(c["id"])):
		return ["En tu partida: ya ejecutada", Tema.bien()]
	if est.mano.any(func(m: Dictionary) -> bool: return m["id"] == c["id"]):
		return ["En tu mano ahora", Tema.ORO]
	var mot := BloqueoCarta.motivo(motor, c)
	if mot != "":
		return ["Bloqueada · " + mot, FilasUI.ROJO_TEXTO]
	return ["Disponible en tu mazo" if est.mazo.has(String(c["id"])) else "Disponible (aún no sorteada)", Tema.TEXTO]


func aplicar_filtros() -> void:
	filtrados.clear()
	for c in items:
		var m: Dictionary = c["meta"]
		var tipo := String(m["tipo"]).replace("propuesta_constitucional", "reforma_constitucional")
		if f_tipo != "" and tipo != f_tipo:
			continue
		if f_region != "" and _s(m.get("region_id")) != f_region:
			continue
		if f_sector != "" and String(c["categoria"]) != f_sector:
			continue
		if f_texto != "" and not _sin_tildes(String(c["titulo"])).contains(_sin_tildes(f_texto)):
			continue
		filtrados.append(c)
	pagina = clampi(pagina, 0, maxi(0, (filtrados.size() - 1) / POR_PAGINA))
	_pintar()


static func _sin_tildes(t: String) -> String:
	return t.to_lower().replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ü", "u").replace("ñ", "n")


func _chip_fila(clave: String, titulo: String, opciones: Array) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(Tema.etiqueta_corta(titulo, 10, Tema.TEXTO_SUAVE, true))
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 48)
	sc.get_h_scroll_bar().modulate.a = 0.0  # se desliza con el dedo; sin barra que ensucie
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	sc.add_child(h)
	_chips[clave] = {}
	_scrolls[clave] = sc
	for op in opciones:
		var b := Tema.boton(String(op[1]), Tema.PANEL, Tema.TEXTO, 12, 44)
		b.pressed.connect(func() -> void:
			set("f_" + clave, String(op[0]))
			pagina = 0
			aplicar_filtros())
		h.add_child(b)
		_chips[clave][String(op[0])] = b
	v.add_child(sc)
	return v


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in datos["cartas"]:
		if _es_real(c):
			items.append(c)
	var raiz := FilasUI.capa_opaca()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 172)  # pie: paginación y botón Volver
	add_child(m)
	var v := FilasUI.col(6)
	m.add_child(v)
	v.add_child(Tema.etiqueta("CARTERA DE PROYECTOS · SOLO LECTURA", 10, Tema.ORO, true))
	v.add_child(Tema.etiqueta("Proyectos reales con su fuente y estado. Mirar la cartera no cambia tu partida.", 11, Tema.TEXTO_SUAVE))
	var regiones: Array = [["", "Todas"]]
	for r in datos["regiones"]:
		regiones.append([String(r["id"]), _nombre_region(String(r["id"]))])
	var sectores := {}
	for c in items:
		sectores[String(c["categoria"])] = true
	var sec: Array = [["", "Todos"]]
	var claves: Array = sectores.keys()
	claves.sort()
	for k in claves:
		sec.append([k, BloqueoCarta.nombre_cat(String(k))])
	var buscar := Tema.campo("Buscar por título (ej. metro, salud mental, pensiones)", 40, f_texto)
	buscar.text_changed.connect(func(t: String) -> void:
		f_texto = t.strip_edges()
		pagina = 0
		aplicar_filtros())
	v.add_child(buscar)
	v.add_child(_chip_fila("tipo", "TIPO", TIPOS))
	v.add_child(_chip_fila("region", "REGIÓN", regiones))
	v.add_child(_chip_fila("sector", "SECTOR", sec))
	_conteo = Tema.etiqueta("", 11, Tema.TEXTO, false, 600)
	v.add_child(_conteo)
	_lista = FilasUI.col(6)
	v.add_child(FilasUI.scroll(_lista))
	var pie := HBoxContainer.new()
	pie.anchor_top = 1.0
	pie.anchor_bottom = 1.0
	pie.anchor_right = 1.0
	pie.offset_left = 16.0
	pie.offset_right = -16.0
	pie.offset_top = -161.0
	pie.offset_bottom = -113.0
	pie.add_theme_constant_override("separation", 8)
	var ant := Tema.boton("Anterior", Tema.PANEL, Tema.TEXTO, 13, 48)
	ant.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ant.pressed.connect(func() -> void:
		pagina = maxi(0, pagina - 1)
		_pintar())
	var sig := Tema.boton("Siguiente", Tema.PANEL, Tema.TEXTO, 13, 48)
	sig.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sig.pressed.connect(func() -> void:
		pagina = mini(maxi(0, (filtrados.size() - 1) / POR_PAGINA), pagina + 1)
		_pintar())
	_lbl_pag = Tema.etiqueta_corta("", 11, Tema.TEXTO_SUAVE)
	_lbl_pag.custom_minimum_size = Vector2(70, 0)
	_lbl_pag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pie.add_child(ant)
	pie.add_child(_lbl_pag)
	pie.add_child(sig)
	add_child(pie)
	var volver := FilasUI.boton_pie("Volver")
	volver.pressed.connect(func() -> void:
		cerrada.emit()
		queue_free())
	add_child(volver)
	aplicar_filtros()


func _pintar() -> void:
	for clave in _chips.keys():
		var actual := String(get("f_" + clave))
		for val in _chips[clave].keys():
			var b: Button = _chips[clave][val]
			var on: bool = val == actual
			var fondo := Tema.ORO if on else Tema.PANEL
			for e in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(e, Tema.caja(fondo, 18))
			for e in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(e, Tema.TINTA if on else Tema.TEXTO)
			if on and _scrolls.has(clave):
				_scrolls[clave].ensure_control_visible.call_deferred(b)  # el chip activo nunca queda fuera de pantalla
	for h in _lista.get_children():
		h.queue_free()
	var total := filtrados.size()
	var ini := pagina * POR_PAGINA
	var fin := mini(total, ini + POR_PAGINA)
	_conteo.visible = false  # los conteos y números de página son internos: el jugador no los ve
	_lbl_pag.text = ""
	if total == 0:
		_lista.add_child(Tema.etiqueta("Ningún proyecto coincide con esos filtros.", 12, Tema.TEXTO_SUAVE))
	for i in range(ini, fin):
		var c: Dictionary = filtrados[i]
		var m: Dictionary = c["meta"]
		var v := FilasUI.col(1)
		v.add_child(Tema.etiqueta(String(c["titulo"]), 13, Tema.TEXTO, true))
		v.add_child(Tema.etiqueta("%s · %s · %s" % [NOMBRE_TIPO[String(m["tipo"])], _nombre_region(_s(m.get("region_id"))), BloqueoCarta.nombre_cat(String(c["categoria"]))], 11, Tema.TEXTO_SUAVE))
		var real := "Estado real: %s" % (_s(m.get("estado_real")) if m.get("estado_real") != null else "sin dato")
		if m.get("inversion_musd") != null:  # el número de boletín es interno: no se muestra al jugador
			real += " · inversión US$ %s millones (cifra ilustrativa)" % Tema.miles(roundi(float(m["inversion_musd"])))
		v.add_child(Tema.etiqueta(real, 11, Tema.TEXTO))
		var ep := _estado_partida(c)
		v.add_child(Tema.etiqueta(String(ep[0]), 11, ep[1], false, 600))
		v.add_child(Tema.etiqueta("Fuente: " + _fuente(c), 10, Tema.TEXTO_SUAVE))
		_lista.add_child(FilasUI.tarjeta(v))
