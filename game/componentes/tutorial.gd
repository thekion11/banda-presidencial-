class_name Tutorial
extends Control
## Tutorial de la primera partida: 5 pasos sobre mano, movimientos, delegación, gabinete y turno. Saltable.
## Y una ayuda breve el primer día de gobierno (delegar, agenda legislativa y ahorro de movimientos).
## Solo se guarda una preferencia local (user://preferencias.json) para no repetirlos.

static var ruta: String = "user://preferencias.json"

const PASOS := [
	["Tu mano", "Cada carta es una acción de gobierno. Toca una para verla; deslízala hacia arriba para jugarla. Al jugarla entra otra."],
	["Movimientos", "Cada carta cuesta de 1 a 3. Tienes {pa} por semana (más bonos) y lo que no gastes se guarda, hasta {tope}."],
	["Delegación", "Hasta {deleg} cartas por turno: suéltalas sobre el ícono izquierdo. No gastan movimientos, pero pueden fallar. Solo en gobierno."],
	["Gabinete", "Tu gabinete de {gab} ministerios se puede rellenar solo. Ahí cambias también asesores, coalición y movimientos internos."],
	["Tu turno", "Cuando termines tus jugadas, toca el botón del centro para cerrar la semana. Eso es todo: ¡a campaña!"],
]
const PASOS_GOBIERNO := [
	["Ya gobiernas", "Ahora puedes delegar: suelta una carta sobre el ícono izquierdo y un ministro la ejecuta sin gastar movimientos (puede fallar)."],
	["Agenda legislativa", "En Congreso presentas proyectos de ley con urgencia simple, suma o discusión inmediata, y sigues los que van en trámite."],
	["Ahorro", "Lo que no gastes se guarda para la semana siguiente, hasta {tope}. El número junto al rayo es lo que tienes hoy."],
]

signal cerrado

var pasos: Array = PASOS  # PASOS o PASOS_GOBIERNO
var clave := "tutorial_visto"  # preferencia que lo marca como visto
var leyes: Dictionary = {}  # data/leyes.json: las cifras del texto salen de ahí (nunca fijas)
var objetivos: Array = []  # un Control por paso, en el mismo orden que PASOS
var _paso: int = 0
var _marco: PanelContainer
var _titulo: Label
var _texto: Label
var _contador: Label
var _siguiente: Button
var _velo: Control  # P9: oscurece todo salvo el elemento explicado (foco con hueco)


static func _prefs() -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return d if d is Dictionary else {}


static func debe_mostrar(p_clave: String = "tutorial_visto") -> bool:
	return not bool(_prefs().get(p_clave, false))


static func marcar_visto(p_clave: String = "") -> void:
	## Sin clave marca todas las ayudas (saltarlas en pruebas o en «Partida rápida»); con clave, solo esa.
	var d := _prefs()
	for k in (["tutorial_visto", "ayuda_gobierno"] if p_clave == "" else [p_clave]):
		d[k] = true
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))


func _ready() -> void:
	set_meta("atras", _cerrar)  # botón Atrás de Android: salta el tutorial
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_velo = Control.new()
	_velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_velo.draw.connect(_dibujar_velo)
	add_child(_velo)
	_marco = PanelContainer.new()
	var sb := Tema.caja(Color(0, 0, 0, 0), 14, Tema.ORO, 3)
	_marco.add_theme_stylebox_override("panel", sb)
	_marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_marco)
	var hoja := PanelContainer.new()
	hoja.add_theme_stylebox_override("panel", Tema.caja(Tema.OCEANO, 22, Color("#4C84AE"), 2))
	hoja.position = Vector2(16, 120)
	hoja.custom_minimum_size = Vector2(358, 250)  # tamaño fijo: los botones no cambian de sitio entre pasos
	hoja.size = Vector2(358, 250)
	add_child(hoja)
	var v := FilasUI.col(8)
	hoja.add_child(v)
	_contador = Tema.etiqueta("", 10, Tema.ORO, true)
	_titulo = Tema.etiqueta("", 20, Tema.TEXTO, true)
	_texto = Tema.etiqueta("", 13, Tema.TEXTO_SUAVE)
	_texto.custom_minimum_size = Vector2(0, 76)
	v.add_child(_contador)
	v.add_child(_titulo)
	v.add_child(_texto)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var saltar := Tema.boton("Saltar tutorial" if clave == "tutorial_visto" else "Saltar ayuda", Tema.PANEL, Tema.TEXTO, 13, 48)
	saltar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saltar.pressed.connect(_cerrar)
	_siguiente = Barras.boton_jugar()
	_siguiente.custom_minimum_size = Vector2(0, 48)
	_siguiente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_siguiente.pressed.connect(_avanzar)
	fila.add_child(saltar)
	fila.add_child(_siguiente)
	v.add_child(fila)
	await get_tree().process_frame  # espera el layout de la pantalla de día para ubicar el marco
	await get_tree().process_frame
	_mostrar()


func _mostrar() -> void:
	var p: Array = pasos[_paso]
	_contador.text = "PASO %d DE %d" % [_paso + 1, pasos.size()]
	_titulo.text = String(p[0])
	_texto.text = String(p[1]).format({"pa": int(leyes.get("mano", {}).get("pa_por_turno", 5)), "deleg": int(leyes.get("delegacion", {}).get("max_por_turno", 2)), "gab": int(leyes.get("gabinete", {}).get("tamano", 8)), "tope": int(leyes.get("mano", {}).get("tope_ahorro", 10))})
	_siguiente.text = "Siguiente" if _paso < pasos.size() - 1 else "Entendido"
	if _paso < objetivos.size() and objetivos[_paso] is Control and is_instance_valid(objetivos[_paso]):
		var r: Rect2 = (objetivos[_paso] as Control).get_global_rect().grow(6.0)
		if Movimiento.activo() and _marco.visible and _marco.size.x > 0.0:  # el foco viaja al siguiente elemento
			var tw := _marco.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(_marco, "global_position", r.position, 0.32)
			tw.tween_property(_marco, "size", r.size, 0.32)
		else:
			_marco.size = r.size
			_marco.global_position = r.position  # global: sigue alineado aunque la pantalla esté entrando (Movimiento.entrar_pantalla)
		_marco.visible = true
	else:
		_marco.visible = false


func _avanzar() -> void:
	if _paso >= pasos.size() - 1:
		_cerrar()
		return
	_paso += 1
	_mostrar()


func _cerrar() -> void:
	marcar_visto(clave)
	cerrado.emit()
	queue_free()


var _hueco_previo: Rect2 = Rect2()


func _process(_delta: float) -> void:
	if _velo != null and _marco != null:  # el velo solo cambia cuando el foco se mueve
		var r := Rect2(_marco.global_position, _marco.size) if _marco.visible else Rect2()
		if r != _hueco_previo:
			_hueco_previo = r
			_velo.queue_redraw()
	if _marco != null and Movimiento.activo():  # el marco dorado late
		_marco.modulate.a = 0.7 + 0.3 * sin(float(Time.get_ticks_msec()) / 180.0)


func _dibujar_velo() -> void:
	## Velo oscuro con un hueco en el elemento explicado: se ve nítido y todo lo demás queda atenuado.
	var oscuro := Color(0, 0, 0, 0.62)
	var full := Rect2(Vector2.ZERO, _velo.size)
	if _marco == null or not _marco.visible:
		_velo.draw_rect(full, oscuro)
		return
	var h := Rect2(_marco.global_position - _velo.global_position, _marco.size).intersection(full)
	_velo.draw_rect(Rect2(0, 0, full.size.x, h.position.y), oscuro)
	_velo.draw_rect(Rect2(0, h.end.y, full.size.x, full.size.y - h.end.y), oscuro)
	_velo.draw_rect(Rect2(0, h.position.y, h.position.x, h.size.y), oscuro)
	_velo.draw_rect(Rect2(h.end.x, h.position.y, full.size.x - h.end.x, h.size.y), oscuro)
