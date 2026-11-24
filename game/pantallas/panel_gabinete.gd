class_name PanelGabinete
extends RefCounted
## Selector de gabinete (DISENO_V2 §1): se eligen exactamente `leyes.gabinete.tamano` ministros de los 25.
## Cada fila muestra cartera, alias, categoría afín y cuántas cartas habilita. Se usa en la etapa de configuración
## y, editable, en campaña y en la primera semana de gobierno.


static func puede_editar(motor: MotorTurno) -> bool:
	var e := motor.estado
	return e.etapa == "campana" or (e.etapa == "gobierno" and e.turno_actual == 1)


static func crear(motor: MotorTurno, texto_boton: String, al_confirmar: Callable, al_error: Callable = Callable(), con_bloqueadas: bool = false) -> Control:
	var tam := int(motor.catalogo_leyes["gabinete"]["tamano"])
	var editable := puede_editar(motor)
	var elegidos: Array = motor.estado.gabinete.duplicate()
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 8)
	var resumen := Tema.etiqueta("", 12, Tema.TEXTO_SUAVE)
	var contador := Tema.etiqueta("", 15, Tema.ORO, true)
	var boton := Tema.boton(texto_boton, Tema.ROJO, Tema.TEXTO, 15, 52)
	var lista := FilasUI.col(6)
	var botones := {}
	var refrescar := func() -> void:
		contador.text = "Gabinete: %d de %d ministros" % [elegidos.size(), tam]
		resumen.text = "Cada ministro habilita las cartas de su área. Política, Comité y Estado siempre están habilitadas."  # sin conteos de catálogo: son internos
		boton.disabled = elegidos.size() != tam
		boton.visible = editable
		for id in botones.keys():
			var b: Button = botones[id]
			var on := elegidos.has(id)
			var fondo := Tema.ORO if on else Tema.PANEL
			for e in ["normal", "hover", "pressed", "focus"]:
				b.add_theme_stylebox_override(e, Tema.caja(fondo if e != "hover" else fondo.lightened(0.08), 14))
			var v: VBoxContainer = b.get_child(0)
			(v.get_child(0) as Label).add_theme_color_override("font_color", Tema.TINTA if on else Tema.TEXTO)
			(v.get_child(1) as Label).add_theme_color_override("font_color", Tema.TINTA if on else Tema.TEXTO_SUAVE)
			(v.get_child(2) as Label).add_theme_color_override("font_color", Tema.TINTA if on else Tema.ORO)
			(v.get_child(0) as Label).text = ("EN EL GABINETE · " if on else "") + String(motor.catalogo_ministros[id]["alias"])
	for id in motor.catalogo_ministros.keys():
		var m: Dictionary = motor.catalogo_ministros[id]
		var cat := String(m["categoria_afin"])
		var b := FilasUI.fila_boton([[m["alias"], 13, Tema.TEXTO, true], [m["cartera"], 11, Tema.TEXTO_SUAVE],
				["Habilita cartas de %s" % BloqueoCarta.nombre_cat(cat), 11, Tema.ORO]], Tema.PANEL, 66.0)
		botones[id] = b
		b.pressed.connect(func() -> void:
			if not editable:
				return
			if elegidos.has(id):
				elegidos.erase(id)
			elif elegidos.size() < tam:
				elegidos.append(id)
			refrescar.call())
		lista.add_child(b)
	if con_bloqueadas:
		var bloq := BloqueoCarta.bloqueadas(motor)
		lista.add_child(Tema.etiqueta("Cartas bloqueadas con tu gabinete actual", 14, Tema.TEXTO, true))
		for e in bloq.slice(0, 30):
			var v := FilasUI.col(0)
			v.add_child(Tema.etiqueta(String(e["carta"]["titulo"]), 12, Tema.TEXTO, false, 600))
			v.add_child(Tema.etiqueta("Bloqueada: " + String(e["motivo"]), 11, FilasUI.ROJO_TEXTO))
			lista.add_child(FilasUI.tarjeta(v, Tema.OCEANO.lightened(0.06)))
	boton.pressed.connect(func() -> void:
		var r := motor.elegir_gabinete(elegidos)
		if bool(r["ok"]):
			al_confirmar.call()
		elif al_error.is_valid():
			al_error.call(Razones.texto(r)))
	raiz.add_child(contador)
	raiz.add_child(resumen)
	if not editable:
		raiz.add_child(Tema.etiqueta("El gabinete quedó cerrado: solo se cambia en campaña o en la primera semana de gobierno.", 11, Tema.ORO))
	raiz.add_child(FilasUI.scroll(lista))
	raiz.add_child(boton)
	refrescar.call()
	return raiz
