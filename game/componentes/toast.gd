class_name Toast
extends Label
## Aviso breve sobre la pantalla (un mensaje a la vez; uno nuevo reemplaza al anterior).

var _tween: Tween


func _init() -> void:
	add_theme_font_override("font", Tema.fuente_titulo())
	add_theme_font_size_override("font_size", 12)
	add_theme_color_override("font_color", Tema.TINTA)
	add_theme_stylebox_override("normal", Tema.caja(Tema.ORO, 12))
	position = Vector2(20, 112)
	size = Vector2(350, 30)
	custom_minimum_size = Vector2(350, 0)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # con consecuencias el aviso puede ocupar dos líneas
	visible = false


func mostrar(txt: String) -> void:
	text = txt
	size = Vector2(350, 30)  # se reajusta al alto del texto
	visible = true
	if _tween != null and _tween.is_valid():
		_tween.kill()  # un aviso nuevo no debe ser ocultado por el temporizador del anterior
	_tween = create_tween()
	_tween.tween_interval(2.6)
	_tween.tween_callback(func() -> void: visible = false)
