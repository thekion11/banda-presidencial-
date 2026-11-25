class_name Tutorial
extends Control
## Tutorial de la primera partida: 5 pasos sobre mano, movimientos, delegación, gabinete y turno. Saltable.
## Solo se guarda una preferencia local (user://preferencias.json) para no repetirlo.

static var ruta: String = "user://preferencias.json"

const PASOS := [
	["Tu mano", "Cada carta es una acción de gobierno. Toca una para verla; deslízala hacia arriba para jugarla. Al jugarla entra otra."],
	["Movimientos", "Cada carta cuesta de 1 a 3 movimientos. Tienes {pa} por turno, más un bono cuando tu aprobación es alta y +1 por cada asesor."],
	["Delegación", "Hasta {deleg} cartas por turno: suéltalas sobre el ícono izquierdo. No gastan movimientos, pero pueden fallar. Solo en gobierno."],
	["Gabinete", "Tu gabinete de {gab} ministerios se puede rellenar solo. Ahí cambias también asesores, coalición y movimientos internos."],
	["Tu turno", "Cuando termines tus jugadas, toca el botón del centro para cerrar la semana. Eso es todo: ¡a campaña!"],
]

signal cerrado

var leyes: Dictionary = {}  # data/leyes.json: las cifras del texto salen de ahí (nunca fijas)
var objetivos: Array = []  # un Control por paso, en el mismo orden que PASOS
var _paso: int = 0
var _marco: PanelContainer
var _titulo: Label
var _texto: Label
var _contador: Label
var _siguiente: Button


static func debe_mostrar() -> bool:
	if not FileAccess.file_exists(ruta):
		return true
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return not (d is Dictionary and bool(d.get("tutorial_visto", false)))


static func marcar_visto() -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"tutorial_visto": true}))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.5)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
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
	var saltar := Tema.boton("Saltar tutorial", Tema.PANEL, Tema.TEXTO, 13, 48)
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
	var p: Array = PASOS[_paso]
	_contador.text = "PASO %d DE %d" % [_paso + 1, PASOS.size()]
	_titulo.text = String(p[0])
	_texto.text = String(p[1]).format({"pa": int(leyes.get("mano", {}).get("pa_por_turno", 5)), "deleg": int(leyes.get("delegacion", {}).get("max_por_turno", 2)), "gab": int(leyes.get("gabinete", {}).get("tamano", 8))})
	_siguiente.text = "Siguiente" if _paso < PASOS.size() - 1 else "Entendido"
	if _paso < objetivos.size() and objetivos[_paso] is Control and is_instance_valid(objetivos[_paso]):
		var r: Rect2 = (objetivos[_paso] as Control).get_global_rect().grow(6.0)
		_marco.position = r.position
		_marco.size = r.size
		_marco.visible = true
	else:
		_marco.visible = false


func _avanzar() -> void:
	if _paso >= PASOS.size() - 1:
		_cerrar()
		return
	_paso += 1
	_mostrar()


func _cerrar() -> void:
	marcar_visto()
	cerrado.emit()
	queue_free()
