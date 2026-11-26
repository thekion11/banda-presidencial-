class_name PantallaMenu
extends Control

signal nueva
signal continuar
signal repetir

var hay_guardado: bool = false
var hay_ultima: bool = false  # hay una configuración previa (partido, afiliación y dificultad) para repetir
var aviso: String = ""  # mensaje para el jugador (p. ej. guardado descartado)
var datos: Dictionary = {}
var _creditos: PanelContainer


func _ready() -> void:
	## Dirección visual v4 (lienzo de Claude Design, artboard «Menú principal»): insignia, cinta tricolor,
	## motas de ambiente, botón principal con halo y secundarios en grilla. Mismos textos y acciones que antes.
	add_child(Tema.fondo_hero("politica", 0.78, 0.22, "res://game/arte/marca/portada.jpg"))  # portada nueva (vector plano); si falta, usa la de la categoría
	add_child(Particulas.new())
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 84
	col.offset_bottom = -40
	col.add_theme_constant_override("separation", 12)
	add_child(col)
	var marca := HBoxContainer.new()
	marca.add_theme_constant_override("separation", 10)
	marca.add_child(Barras.insignia())
	var sup := Tema.etiqueta_corta("SIMULADOR POLÍTICO POR TURNOS", 11, Tema.ORO, true)
	sup.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marca.add_child(sup)
	col.add_child(marca)
	col.add_child(Tema.etiqueta("Presidente\nde Chile", 46, Tema.TEXTO, true))
	col.add_child(_cinta())
	col.add_child(Tema.etiqueta("Funda tu partido, gana la elección y gobierna cuatro años, una semana por turno.", 14, Tema.TEXTO_SUAVE))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(esp)
	if aviso != "":
		var av := PanelContainer.new()
		av.add_theme_stylebox_override("panel", Tema.caja(Color("#FBEFD2"), 12, Tema.ORO, 2))
		av.add_child(Tema.etiqueta(aviso, 12, Tema.TINTA, false, 600))
		col.add_child(av)
	var n := Barras.boton_jugar()
	n.text = "Nueva partida"
	n.pressed.connect(func() -> void: nueva.emit())
	col.add_child(n)
	if hay_guardado:
		var c := Tema.boton("Continuar partida", Tema.PANEL, Tema.CREMA, 15, 50)
		for e in ["normal", "hover"]:
			c.add_theme_stylebox_override(e, Tema.caja_degradada(Color("#1B4F78") if e == "normal" else Color("#22608F"), Color("#0F2F4A"), 25, Color("#4C84AE"), 2))
		c.pressed.connect(func() -> void: continuar.emit())
		col.add_child(c)
	var rp := Tema.boton_secundario("Partida rápida (como la última vez)" if hay_ultima else "Partida rápida")
	rp.pressed.connect(func() -> void: repetir.emit())
	col.add_child(rp)
	var grilla := GridContainer.new()
	grilla.columns = 2
	grilla.add_theme_constant_override("h_separation", 8)
	grilla.add_theme_constant_override("v_separation", 8)
	var acciones := [
		["Cartera de proyectos", Tema.CREMA, func() -> void: add_child(PantallaCartera.crear(datos))],
		["Informe de prueba", Tema.TEXTO_SUAVE, func() -> void: add_child(PantallaInforme.crear())],
		["Ajustes", Tema.TEXTO_SUAVE, func() -> void: add_child(PantallaAjustes.new())],
		["Créditos", Tema.TEXTO_SUAVE, _mostrar_creditos],
	]
	for a in acciones:
		var b := Tema.boton_secundario(String(a[0]), a[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(a[2])
		grilla.add_child(b)
	col.add_child(grilla)
	col.add_child(Tema.etiqueta("Obra de ficción satírica. Políticos reales con alias; personajes y cifras ilustrativas rotuladas como tales.", 10, Tema.TEXTO_SUAVE))
	Movimiento.escalonar(col, 0.05, 0.045)
	Movimiento.halo(n)


func _cinta() -> Control:
	## Cinta tricolor bajo el título (rojo, crema y panel, con filo dorado): la banda presidencial en la paleta congelada.
	var c := Control.new()
	c.custom_minimum_size = Vector2(150, 6)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.set_meta("avance", 0.0 if Movimiento.activo() else 1.0)
	c.draw.connect(func() -> void:
		var w := 150.0 * float(c.get_meta("avance"))
		c.draw_rect(Rect2(-1, -1, w + 2, 8), Tema.ORO)
		for i in range(3):
			var x0 := 50.0 * i
			if x0 < w:
				c.draw_rect(Rect2(x0, 0, minf(50.0, w - x0), 6), [Tema.ROJO, Tema.CREMA, Tema.PANEL][i]))
	if Movimiento.activo():
		c.create_tween().tween_method(func(t: float) -> void:
			c.set_meta("avance", t)
			c.queue_redraw(), 0.0, 1.0, 0.6).set_delay(0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return c


func _mostrar_creditos() -> void:
	if _creditos != null:
		_creditos.queue_free()
		_creditos = null
		return
	_creditos = PanelContainer.new()  # P4: hoja inferior que deja visible el título del juego
	var sb := Tema.caja(Tema.PANEL, 20, Color("#2A6290"), 1)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 18
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	_creditos.add_theme_stylebox_override("panel", sb)
	_creditos.set_anchors_preset(Control.PRESET_FULL_RECT)
	_creditos.offset_left = 12
	_creditos.offset_right = -12
	_creditos.offset_top = 330
	_creditos.offset_bottom = -12
	add_child(_creditos)
	if Movimiento.activo():
		_creditos.position.y += 520.0
		_creditos.create_tween().tween_property(_creditos, "position:y", 330.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_creditos.add_child(v)
	v.add_child(Tema.etiqueta("Créditos y atribuciones", 18, Tema.ORO, true))
	var txt := "Mapa de regiones: GeoJSON público simplificado (ver docs/DATOS.md).\n" \
		+ "Calles, Metro, río y parques de Gran Santiago: © colaboradores de OpenStreetMap (ODbL), extracto de BBBike. Relieve: teselas públicas de elevación (Terrarium).\n" \
		+ "Líneas 7, 8 y 9 del Metro: trazado de OpenStreetMap; colores de es.wikipedia y Wikidata (sin confirmar por Metro S.A.). Estaciones de las líneas en operación cotejadas con el GTFS de la Red Metropolitana (DTPM).\n" \
		+ "Mapa de Sudamérica: Natural Earth (dominio público), simplificado; mapa ilustrativo que no define límites ni reclamos. Relaciones entre países: cifras ilustrativas.\n" \
		+ "Ilustraciones de cartas generadas con IA (Gemini y Canva) para este proyecto.\n" \
		+ "Tipografías: Space Grotesk e Inter (SIL OFL 1.1).\n" \
		+ "Música y efectos de sonido: sintetizados para este proyecto (tools/audio), sin muestras de terceros.\n" \
		+ "Motor: Godot Engine (MIT).\n" \
		+ "Cifras marcadas como ilustrativas no representan datos oficiales."
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var lbl := Tema.etiqueta(txt, 12, Tema.TEXTO)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(lbl)
	v.add_child(sc)
	var cerrar := Tema.boton("Cerrar", Tema.ROJO, Tema.TEXTO, 14, 48)
	cerrar.pressed.connect(_mostrar_creditos)
	v.add_child(cerrar)
