extends SceneTree
## Reglas congeladas de la interfaz (CLAUDE.md §5) con sus valores LITERALES, para que cambiar una constante de game/tema.gd rompa una prueba aunque las demás
## pruebas usen esa misma constante como umbral (test_tactil mide contra Tema.TACTIL: si alguien baja la constante, sus botones se achican y el test sigue en verde).
## Cubre: zona táctil mínima 44 px, ancho de pantalla 390 px, paleta congelada y extremos de la escala de aprobación (con y sin daltonismo).

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_check(Tema.TACTIL >= 44.0, "la zona táctil mínima no puede bajar de 44 px (Tema.TACTIL = %s)" % str(Tema.TACTIL))
	_check(Tema.ANCHO == 390.0, "el ancho de diseño es 390 px (Tema.ANCHO = %s)" % str(Tema.ANCHO))
	var paleta := {"OCEANO": [Tema.OCEANO, "#0B2236"], "PANEL": [Tema.PANEL, "#16405F"], "ORO": [Tema.ORO, "#F2C14E"], "ROJO": [Tema.ROJO, "#C23B2E"], "CREMA": [Tema.CREMA, "#FBF7EC"]}
	for nombre in paleta:
		_check((paleta[nombre][0] as Color).to_html(false).to_upper() == String(paleta[nombre][1]).trim_prefix("#"), "la paleta congelada cambió: %s = #%s, debe ser %s" % [nombre, (paleta[nombre][0] as Color).to_html(false).to_upper(), paleta[nombre][1]])
	Ajustes.daltonico = false
	_check(Tema.color_aprobacion(60.0).to_html(false).to_upper() == "4CC38A", "aprobación alta (60 o más) debe ser #4CC38A, es #%s" % Tema.color_aprobacion(60.0).to_html(false).to_upper())
	_check(Tema.color_aprobacion(30.0).to_html(false).to_upper() == "E8705A", "aprobación baja (30 o menos) debe ser #E8705A, es #%s" % Tema.color_aprobacion(30.0).to_html(false).to_upper())
	_check(Tema.color_aprobacion(95.0) == Tema.color_aprobacion(60.0) and Tema.color_aprobacion(0.0) == Tema.color_aprobacion(30.0), "la escala se satura fuera de 30 a 60")
	Ajustes.daltonico = true
	_check(Tema.color_aprobacion(60.0) != Tema.color_aprobacion(30.0), "con daltonismo los extremos siguen siendo distintos")
	Ajustes.daltonico = false
	print("test_reglas_interfaz: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
