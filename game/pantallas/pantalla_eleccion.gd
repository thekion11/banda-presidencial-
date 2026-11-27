class_name PantallaEleccion
extends RefCounted
## Resultado de la elección presidencial (1ª y 2ª vuelta): voto nacional frente al umbral, con cada región pesada por su
## población (pedido del usuario del 27-nov-2026: «Las elecciones deben tomar en cuenta la población»; salida del motor
## en docs/ELECCION_POBLACION.md), mapa de quién gana cada región y aviso de segunda vuelta. Solo lee.


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


static func crear(motor: MotorTurno, regiones: Array, regional: Dictionary, res: Dictionary, al_continuar: Callable, geo: Dictionary = {}) -> Control:
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
	var por_region: Array = res.get("regiones", [])
	tarjeta.add_child(Tema.etiqueta("Voto nacional el día de la elección" if not por_region.is_empty() else "Aprobación el día de la elección", 12, Tema.TEXTO_SUAVE))
	var cifra := Tema.etiqueta("", 22, Tema.TEXTO, true)
	Movimiento.contar(cifra, valor, func(x: float) -> String: return "%s %% · umbral %.0f %%" % [Tema.dec(x), umbral], 0.0, 1.1, 0.25)
	tarjeta.add_child(cifra)
	tarjeta.add_child(_barra_umbral(valor, umbral, piso))
	var leyenda := "Marca dorada: umbral de victoria (%.0f %%)." % umbral
	if ronda == 1:
		leyenda += " Marca clara: piso para la segunda vuelta (%.0f %%)." % piso
	tarjeta.add_child(Tema.etiqueta(leyenda, 11, Tema.TEXTO_SUAVE))
	if por_region.is_empty():
		tarjeta.add_child(Tema.etiqueta("Se mide tu aprobación al cierre, con un margen de ±%.0f puntos propio de la jornada." % ruido, 11, Tema.TEXTO_SUAVE))
	else:
		tarjeta.add_child(Tema.etiqueta(texto_poblacion(res, ruido), 11, Tema.TEXTO_SUAVE))
	var cuerpo := FilasUI.col(8)  # todo lo que sigue al veredicto se desplaza: con letra ×1,5 en 360×640 no cabe entero
	cuerpo.add_child(FilasUI.tarjeta(tarjeta))
	if res["balotaje"]:
		var av := Tema.etiqueta("Aviso: no llegaste al umbral, pero superaste el piso. Tienes %d semanas más de campaña para subir tu aprobación; en la segunda vuelta necesitas %.0f %%." % [int(h["semanas_balotaje"]), umbral], 12, Tema.TINTA, false, 600)
		cuerpo.add_child(FilasUI.tarjeta(av, Tema.ORO))
	elif not res["electo"]:
		cuerpo.add_child(Tema.etiqueta("La aprobación quedó bajo %.0f %%%s." % [piso if ronda == 1 else umbral, " (piso de segunda vuelta)" if ronda == 1 else ""], 12, FilasUI.ROJO_TEXTO, false, 600))
	var lista := FilasUI.col(5)
	if por_region.is_empty():
		cuerpo.add_child(FilasUI.titulo("Aprobación por región"))
		_lista_aprobacion(lista, regiones, regional)
		cuerpo.add_child(lista)
	else:
		cuerpo.add_child(FilasUI.titulo("Voto por región, de la más poblada a la menos"))
		_lista_poblacion(lista, regiones, por_region, umbral)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		fila.custom_minimum_size.y = maxf(300.0, Tema.alto_util() - 480.0)  # mapa y lista con alto propio: con letra grande el resto se desplaza
		if not geo.is_empty():
			fila.add_child(_mapa_ganador(geo, regiones, por_region))
		fila.add_child(FilasUI.scroll(lista))
		cuerpo.add_child(fila)
	v.add_child(FilasUI.scroll(cuerpo))
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


static func texto_poblacion(res: Dictionary, ruido: float) -> String:
	## «Cada región pesa según sus habitantes: ganas en 9 de 16 regiones, donde vive el 62 % del país. Votos estimados: 6,1 millones…»
	var filas: Array = res.get("regiones", [])
	var total := maxf(1.0, float(res.get("total_habitantes_miles", 0.0)))
	var hab := 0.0
	for r in filas:
		if bool(r["gana_gobierno"]):
			hab += float(r["habitantes_miles"])
	return "Cada región pesa según sus habitantes: ganas en %d de %d regiones, donde vive el %d %% del país. Votos estimados: %s millones (cifras ilustrativas; margen de ±%.0f puntos propio de la jornada)." % [
		int(res.get("regiones_ganadas", 0)), filas.size(), roundi(hab / total * 100.0), Tema.dec(float(res.get("votos_estimados_miles", 0.0)) / 1000.0), ruido]


static func _nombre(regiones: Array, id: String) -> String:
	for r in regiones:
		if String(r["id"]) == id:
			return String(r["nombre"]).replace(" de Santiago", "").replace(" y la Antártica Chilena", "").replace(" Chilena", "")
	return id


static func _lista_poblacion(lista: VBoxContainer, regiones: Array, por_region: Array, umbral: float) -> void:
	## Una fila por región, de la más poblada a la menos: voto (con la marca del umbral), peso y habitantes.
	var filas := por_region.duplicate()
	filas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["habitantes_miles"]) > float(b["habitantes_miles"]))
	for r: Dictionary in filas:
		var voto := float(r["voto"])
		var gana := bool(r["gana_gobierno"])
		var caja := FilasUI.col(2)
		var arriba := HBoxContainer.new()
		var nombre := Tema.etiqueta_corta(_nombre(regiones, String(r["id"])), 11, Tema.TEXTO, false, 600)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.clip_text = true
		nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		arriba.add_child(nombre)
		arriba.add_child(Tema.etiqueta_corta(Tema.pct(voto), 11, Tema.bien() if gana else FilasUI.ROJO_TEXTO, true))
		caja.add_child(arriba)
		var barra := FilasUI.chip_barra(voto, Tema.color_aprobacion(70.0 if gana else 25.0))
		var marca := ColorRect.new()  # umbral de victoria sobre la barra
		marca.color = Tema.ORO
		marca.size = Vector2(2, 12)
		marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
		barra.add_child(marca)
		barra.resized.connect(func() -> void: marca.position = Vector2(barra.size.x * umbral / 100.0 - 1.0, -2.0))
		caja.add_child(barra)
		caja.add_child(Tema.etiqueta_corta("pesa %d %% · %s mil hab." % [roundi(float(r["peso"]) * 100.0), Tema.miles(roundi(float(r["habitantes_miles"])))], 10, Tema.TEXTO_SUAVE))
		lista.add_child(caja)


static func _lista_aprobacion(lista: VBoxContainer, regiones: Array, regional: Dictionary) -> void:
	## Respaldo sin desglose del motor: aprobación por región, de mayor a menor.
	var filas: Array = []
	for r in regiones:
		filas.append([_nombre(regiones, String(r["id"])), float(regional.get(r["id"], 0.0))])
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


static func _mapa_ganador(geo: Dictionary, regiones: Array, por_region: Array) -> Control:
	## Chile coloreado por quién gana cada región (verde: tú; rojo: el rival). Solo se mira: no recibe toques.
	var mapa := MapaChile.new()
	mapa.leyenda = false
	mapa.ciudades_visibles = false
	mapa.animar = false
	mapa.estirar_x = 2.2
	mapa.custom_minimum_size = Vector2(96, 0)
	mapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mapa.cargar_geo(geo)
	var valores := {}
	for r in por_region:
		valores[String(r["id"])] = 70.0 if bool(r["gana_gobierno"]) else 25.0
	for r in regiones:
		valores.get_or_add(String(r["id"]), 25.0)
	mapa.actualizar(valores)
	return mapa


static func con_poblacion(motor: MotorTurno, res: Dictionary) -> Dictionary:
	## Para vistas previas y capturas: completa un resultado armado a mano con el desglose por región del motor (sin votar).
	var lim: Dictionary = motor.catalogo_leyes["limites_indicadores"]
	var desplaza := float(res["voto_final"]) - motor.estado.ind("aprobacion")
	var r := res.duplicate()
	r.merge(VotoRegional.calcular(motor.regiones, motor.estado.aprobacion_regional, desplaza, float(lim["min"]), float(lim["max"]), float(res["umbral"])))
	return r
