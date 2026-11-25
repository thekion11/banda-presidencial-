extends SceneTree
## Accesibilidad (Fase F): texto grande y escala de aprobación para daltonismo; ambas opcionales y desactivadas por defecto.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_check(not Ajustes.texto_grande and not Ajustes.daltonico, "por defecto están desactivadas")
	var normal := Tema.etiqueta("x", 12)
	var verde := Tema.color_aprobacion(60.0)
	var rojo := Tema.color_aprobacion(30.0)
	Ajustes.poner("texto_grande", true)
	Ajustes.poner("daltonico", true)
	_check(Ajustes.leer("texto_grande") and Ajustes.leer("daltonico"), "leer y poner")
	var grande := Tema.etiqueta("x", 12)
	_check(grande.get_theme_font_size("font_size") > normal.get_theme_font_size("font_size"), "el texto grande agranda las etiquetas")
	_check(Tema.etiqueta_corta("x", 12).get_theme_font_size("font_size") == 12, "las etiquetas cortas no se agrandan")
	_check(Tema.color_aprobacion(60.0) != verde and Tema.color_aprobacion(30.0) != rojo, "la escala daltónica cambia los colores")
	_check(Tema.color_aprobacion(60.0).b > Tema.color_aprobacion(60.0).r and Tema.color_aprobacion(30.0).r > Tema.color_aprobacion(30.0).b, "alto = azul, bajo = naranja")
	Ajustes.poner("texto_grande", false)
	Ajustes.poner("daltonico", false)
	_check(Tema.color_aprobacion(60.0) == verde, "al desactivar vuelve la paleta congelada")
	print("test_accesibilidad: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
