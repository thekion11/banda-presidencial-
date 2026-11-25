class_name PantallaAfiliacion
extends Control
## PR-01: cómo entras a la política. Tres tarjetas de un toque; si eliges un partido existente, una lista de partidos ficticios.

signal elegida(afiliacion: String, base: Dictionary)

var datos: Dictionary = {}
var _col: VBoxContainer


func _ready() -> void:
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		mc.add_theme_constant_override("margin_" + lado, 20)
	mc.add_theme_constant_override("margin_top", 56)
	mc.add_theme_constant_override("margin_bottom", 28)
	add_child(mc)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 12)
	mc.add_child(_col)
	_tarjetas()


func _tarjetas() -> void:
	for h in _col.get_children():
		h.queue_free()
	_col.add_child(Tema.etiqueta("¿Cómo entras a la política?", 22, Tema.TEXTO, true))
	var ops: Dictionary = datos["leyes"]["afiliacion"]["opciones"]
	for k in ["propio", "independiente", "existente"]:
		var b := Tema.boton("%s\n%s" % [ops[k]["nombre"], ops[k]["descripcion"]], Tema.PANEL, Tema.TEXTO, 14, 104)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_elegir.bind(k))
		_col.add_child(b)


func _elegir(k: String) -> void:
	if k == "existente":
		_lista_partidos()
	else:
		elegida.emit(k, {})


func _lista_partidos() -> void:
	for h in _col.get_children():
		h.queue_free()
	_col.add_child(Tema.etiqueta("Elige tu partido", 22, Tema.TEXTO, true))
	_col.add_child(Tema.etiqueta("Partidos ficticios, con cifras ilustrativas.", 11, Tema.TEXTO_SUAVE))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 8)
	sc.add_child(lista)
	_col.add_child(sc)
	for p in datos["coalicion"]:
		var b := Tema.boton("%s · %s\n%s" % [p["sigla"], p["nombre"], p["alias_bloque"]], Tema.PANEL, Tema.TEXTO, 13, 60)
		b.pressed.connect(func() -> void: elegida.emit("existente", p))
		lista.add_child(b)
	var volver := Tema.boton("Volver", Tema.OCEANO.lightened(0.14), Tema.TEXTO, 14, 48)
	volver.pressed.connect(_tarjetas)
	_col.add_child(volver)
