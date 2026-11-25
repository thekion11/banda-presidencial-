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
	add_child(Tema.fondo_hero("politica", 0.78, 0.22, "res://game/arte/marca/portada.jpg"))  # portada nueva (vector plano); si falta, usa la de la categoría
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 90
	col.offset_bottom = -40
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	col.add_child(Tema.etiqueta("SIMULADOR POLÍTICO POR TURNOS", 11, Tema.ORO, true))
	col.add_child(Tema.etiqueta("Presidente\nde Chile", 44, Tema.TEXTO, true))
	col.add_child(Tema.etiqueta("Funda tu partido, gana la elección y gobierna cuatro años, una semana por turno.", 14, Tema.TEXTO_SUAVE))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(esp)
	if aviso != "":
		var av := PanelContainer.new()
		av.add_theme_stylebox_override("panel", Tema.caja(Color("#FBEFD2"), 12, Tema.ORO, 2))
		av.add_child(Tema.etiqueta(aviso, 12, Tema.TINTA, false, 600))
		col.add_child(av)
	if hay_guardado:
		var c := Tema.boton("Continuar partida", Tema.PANEL)
		c.add_theme_stylebox_override("normal", Tema.caja_degradada(Color("#1B4F78"), Color("#0F2F4A"), 18, Color("#4C84AE"), 2))
		c.pressed.connect(func() -> void: continuar.emit())
		col.add_child(c)
	var n := Barras.boton_jugar()
	n.text = "Nueva partida"
	n.pressed.connect(func() -> void: nueva.emit())
	col.add_child(n)
	var rp := Tema.boton("Partida rápida (como la última vez)" if hay_ultima else "Partida rápida", Tema.OCEANO.lightened(0.1), Tema.TEXTO, 13, 44)
	rp.pressed.connect(func() -> void: repetir.emit())
	col.add_child(rp)
	var ca := Tema.boton("Cartera de proyectos", Tema.OCEANO.lightened(0.1), Tema.TEXTO, 13, 44)
	ca.pressed.connect(func() -> void: add_child(PantallaCartera.crear(datos)))
	col.add_child(ca)
	var inf := Tema.boton("Informe de prueba", Tema.OCEANO.lightened(0.1), Tema.TEXTO_SUAVE, 13, 44)
	inf.pressed.connect(func() -> void: add_child(PantallaInforme.crear()))
	col.add_child(inf)
	var aj := Tema.boton("Ajustes", Tema.OCEANO.lightened(0.1), Tema.TEXTO_SUAVE, 13, 44)
	aj.pressed.connect(func() -> void: add_child(PantallaAjustes.new()))
	col.add_child(aj)
	var cr := Tema.boton("Créditos", Tema.OCEANO.lightened(0.1), Tema.TEXTO_SUAVE, 13, 44)
	cr.pressed.connect(_mostrar_creditos)
	col.add_child(cr)
	col.add_child(Tema.etiqueta("Obra de ficción satírica. Políticos reales con alias; personajes y cifras ilustrativas rotuladas como tales.", 10, Tema.TEXTO_SUAVE))


func _mostrar_creditos() -> void:
	if _creditos != null:
		_creditos.queue_free()
		_creditos = null
		return
	_creditos = PanelContainer.new()
	_creditos.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, 16))
	_creditos.set_anchors_preset(Control.PRESET_FULL_RECT)
	_creditos.offset_left = 16
	_creditos.offset_right = -16
	_creditos.offset_top = 140
	_creditos.offset_bottom = -140
	add_child(_creditos)
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
