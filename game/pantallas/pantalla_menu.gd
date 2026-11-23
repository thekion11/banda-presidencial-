class_name PantallaMenu
extends Control

signal nueva
signal continuar

var hay_guardado: bool = false
var _creditos: PanelContainer


func _ready() -> void:
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 120
	col.offset_bottom = -40
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	col.add_child(Tema.etiqueta("SIMULADOR POLÍTICO POR TURNOS", 11, Tema.ORO, true))
	col.add_child(Tema.etiqueta("Presidente\nde Chile", 44, Tema.TEXTO, true))
	col.add_child(Tema.etiqueta("Funda tu partido, gana la elección y gobierna cuatro años, una semana por turno.", 14, Tema.TEXTO_SUAVE))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(esp)
	if hay_guardado:
		var c := Tema.boton("Continuar partida", Tema.PANEL)
		c.pressed.connect(func() -> void: continuar.emit())
		col.add_child(c)
	var n := Tema.boton("Nueva partida", Tema.ROJO)
	n.pressed.connect(func() -> void: nueva.emit())
	col.add_child(n)
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
		+ "Calles y relieve (fases futuras): © colaboradores de OpenStreetMap (ODbL) y Copernicus DEM GLO-30.\n" \
		+ "Tipografías: Space Grotesk e Inter (SIL OFL 1.1).\n" \
		+ "Motor: Godot Engine (MIT).\n" \
		+ "Cifras marcadas como ilustrativas no representan datos oficiales."
	v.add_child(Tema.etiqueta(txt, 12, Tema.TEXTO))
	var cerrar := Tema.boton("Cerrar", Tema.ROJO, Tema.TEXTO, 14, 48)
	cerrar.pressed.connect(_mostrar_creditos)
	v.add_child(cerrar)
