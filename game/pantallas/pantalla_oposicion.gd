class_name PantallaOposicion
extends Control
## PR-13: Modo Oposición ligero tras perder la elección: cuatro escenas con decisiones (datos en leyes.json «oposicion») y un resultado final.

signal terminada

var datos: Dictionary = {}
var _i: int = 0
var _suma: Dictionary = {"visibilidad": 0, "partido": 0, "alianzas": 0}
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
	_escena()


func _escena() -> void:
	for h in _col.get_children():
		h.queue_free()
	var cfg: Dictionary = datos["leyes"]["oposicion"]
	var escenas: Array = cfg["escenas"]
	if _i >= escenas.size():
		_final(cfg)
		return
	var e: Dictionary = escenas[_i]
	_col.add_child(Tema.etiqueta("OPOSICIÓN · ESCENA %d DE %d" % [_i + 1, escenas.size()], 11, Tema.ORO, true))
	_col.add_child(Tema.etiqueta(String(e["titulo"]), 24, Tema.TEXTO, true))
	var t := Tema.etiqueta(String(e["texto"]), 13, Tema.TEXTO_SUAVE)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_col.add_child(t)
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col.add_child(esp)
	for op in e["opciones"]:
		var b := Tema.boton(String(op["texto"]), Tema.PANEL, Tema.TEXTO, 13, 56)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func() -> void: elegir(op))
		_col.add_child(b)


func elegir(op: Dictionary) -> void:
	for k in _suma.keys():
		_suma[k] = int(_suma[k]) + int(op.get(k, 0))
	_i += 1
	_escena()


func _final(cfg: Dictionary) -> void:
	var total := int(_suma["visibilidad"]) + int(_suma["partido"]) + int(_suma["alianzas"])
	var res: Dictionary = {}
	for r in cfg["resultados"]:
		if total >= int(r["minimo"]):
			res = r
			break
	_col.add_child(Tema.etiqueta("FIN DE LA OPOSICIÓN", 11, Tema.ORO, true))
	_col.add_child(Tema.etiqueta(String(res["titulo"]), 24, Tema.TEXTO, true))
	var t := Tema.etiqueta(String(res["texto"]), 13, Tema.TEXTO_SUAVE)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_col.add_child(t)
	_col.add_child(Tema.etiqueta("Visibilidad %d · Partido %d · Alianzas %d" % [_suma["visibilidad"], _suma["partido"], _suma["alianzas"]], 12, Tema.TEXTO))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col.add_child(esp)
	var b := Tema.boton("Volver al inicio", Tema.ROJO, Tema.TEXTO, 15, 52)
	b.pressed.connect(func() -> void: terminada.emit())
	_col.add_child(b)
