class_name PantallaEleccion
extends RefCounted
## Resultado de la elección presidencial (1ª y 2ª vuelta). Mide APROBACIÓN frente al umbral (no son votos),
## con el desglose por región y el aviso de segunda vuelta. Solo lee: no cambia el estado de la partida.


static func _barra_umbral(valor: float, umbral: float, piso: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 34)
	var w := 342.0 - 32.0
	var fondo := ColorRect.new()
	fondo.color = Color("#274A66")
	fondo.position = Vector2(0, 10)
	fondo.size = Vector2(w, 14)
	c.add_child(fondo)
	var relleno := ColorRect.new()
	relleno.color = Tema.color_aprobacion(valor + 12.0)
	relleno.position = Vector2(0, 10)
	relleno.size = Vector2(w * clampf(valor, 0.0, 100.0) / 100.0, 14)
	c.add_child(relleno)
	Movimiento.ancho(relleno, relleno.size.x, 0.25, 1.1)  # la barra se llena; las marcas de umbral quedan fijas
	for par in [[umbral, Tema.ORO, 4.0], [piso, Tema.TEXTO_SUAVE, 2.0]]:
		if float(par[0]) <= 0.0:
			continue
		var m := ColorRect.new()
		m.color = par[1]
		m.position = Vector2(w * float(par[0]) / 100.0 - float(par[2]) * 0.5, 2)
		m.size = Vector2(float(par[2]), 30)
		c.add_child(m)
	return c


static func veredicto(res: Dictionary) -> Array:
	## [título, color, texto del botón]
	if res["electo"]:
		return ["Eres Presidente electo" if int(res["ronda"]) == 1 else "Ganas la segunda vuelta", Tema.bien(), "Asumir el gobierno"]
	if res["balotaje"]:
		return ["Vas a segunda vuelta", Tema.ORO, "Ir a la segunda vuelta"]
	return ["No alcanzaste la presidencia", FilasUI.ROJO_TEXTO, "Ver resultado final"]


static func crear(motor: MotorTurno, regiones: Array, regional: Dictionary, res: Dictionary, al_continuar: Callable) -> Control:
	var h: Dictionary = motor.catalogo_leyes["hemiciclo"]
	var ruido := float(motor.catalogo_leyes["campana"]["ruido_eleccion"])
	var ronda := int(res["ronda"])
	var umbral := float(res["umbral"])
	var piso := float(h["umbral_pasa_balotaje"]) if ronda == 1 else 0.0
	var valor := float(res["voto_final"])
	var ver := veredicto(res)
	var raiz := FilasUI.capa_opaca()
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", roundi(maxf(36.0, Tema.margen_superior())))  # muesca o cámara
	m.add_theme_constant_override("margin_bottom", 113)  # deja libre el botón principal del pie
	raiz.add_child(m)
	var v := FilasUI.col(8)
	m.add_child(v)
	v.add_child(Tema.etiqueta("ELECCIÓN PRESIDENCIAL · %s" % ("PRIMERA VUELTA" if ronda == 1 else "SEGUNDA VUELTA"), 10, Tema.ORO, true))
	v.add_child(Tema.etiqueta(String(ver[0]), 26, ver[1], true))
	var tarjeta := FilasUI.col(4)
	tarjeta.add_child(Tema.etiqueta("Aprobación el día de la elección", 12, Tema.TEXTO_SUAVE))
	var cifra := Tema.etiqueta("", 22, Tema.TEXTO, true)
	Movimiento.contar(cifra, valor, func(x: float) -> String: return "%s %% · umbral %.0f %%" % [Tema.dec(x), umbral], 0.0, 1.1, 0.25)
	tarjeta.add_child(cifra)
	tarjeta.add_child(_barra_umbral(valor, umbral, piso))
	var leyenda := "Marca dorada: umbral de victoria (%.0f %%)." % umbral
	if ronda == 1:
		leyenda += " Marca clara: piso para la segunda vuelta (%.0f %%)." % piso
	tarjeta.add_child(Tema.etiqueta(leyenda, 11, Tema.TEXTO_SUAVE))
	tarjeta.add_child(Tema.etiqueta("Se mide tu aprobación al cierre, con un margen de ±%.0f puntos propio de la jornada." % ruido, 11, Tema.TEXTO_SUAVE))
	v.add_child(FilasUI.tarjeta(tarjeta))
	if res["balotaje"]:
		var av := Tema.etiqueta("Aviso: no llegaste al umbral, pero superaste el piso. Tienes %d semanas más de campaña para subir tu aprobación; en la segunda vuelta necesitas %.0f %%." % [int(h["semanas_balotaje"]), umbral], 12, Tema.TINTA, false, 600)
		v.add_child(FilasUI.tarjeta(av, Tema.ORO))
	elif not res["electo"]:
		v.add_child(Tema.etiqueta("La aprobación quedó bajo %.0f %%%s." % [piso if ronda == 1 else umbral, " (piso de segunda vuelta)" if ronda == 1 else ""], 12, FilasUI.ROJO_TEXTO, false, 600))
	v.add_child(FilasUI.titulo("Aprobación por región"))
	var lista := FilasUI.col(5)
	var filas: Array = []
	for r in regiones:
		filas.append([String(r["nombre"]).replace(" de Santiago", "").replace(" Chilena", ""), float(regional.get(r["id"], 0.0))])
	filas.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	for f in filas:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		var nombre := Tema.etiqueta_corta(String(f[0]), 11, Tema.TEXTO)
		nombre.custom_minimum_size = Vector2(150, 0)
		nombre.clip_text = true
		fila.add_child(nombre)
		var barra := FilasUI.chip_barra(float(f[1]), Tema.color_aprobacion(float(f[1]) + 12.0))
		barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(barra)
		fila.add_child(Tema.etiqueta_corta(Tema.pct(float(f[1])), 11, Tema.TEXTO, false, 600))
		lista.add_child(fila)
	var sc := FilasUI.scroll(lista)
	v.add_child(sc)
	Movimiento.escalonar(v, 0.05, 0.05)
	Movimiento.escalonar(lista, 0.45, 0.035, 18)
	if res["electo"]:
		var conf := Particulas.new()
		conf.modo = "confeti"
		conf.cantidad = 46
		raiz.add_child(conf)  # oro, rojo y crema al ganar
		raiz.move_child(conf, 1)  # sobre el fondo y bajo el contenido: el confeti no tapa el título ni las cifras
	var b := FilasUI.boton_pie(String(ver[2]))
	b.pressed.connect(func() -> void:
		raiz.queue_free()
		al_continuar.call())
	raiz.add_child(b)
	raiz.set_meta("atras", "Toca el botón de abajo para seguir.")  # Atrás no salta el resultado de la elección
	return raiz
