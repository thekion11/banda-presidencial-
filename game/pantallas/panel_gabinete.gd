class_name PanelGabinete
extends RefCounted
## Selector de gabinete (DISENO_V2 §1, Fase C): un candidato por ministerio (3 por cargo, cada uno con estilo, ejecución, riesgo y afinidad con tu partido).
## Se usa en la etapa de configuración
## y, editable, en campaña y en la primera semana de gobierno.


static func puede_editar(motor: MotorTurno) -> bool:
	## Solo en la primera semana de gobierno: en campaña gobierna el equipo automático (el gabinete se elige tras ganar).
	var e := motor.estado
	return e.etapa == "gobierno" and e.turno_actual == 1


static func transicion_pendiente(motor: MotorTurno) -> bool:
	## Recién ganada la elección y sin gabinete nombrado desde la votación (docs/GABINETE_TRAS_ELECCION.md). Usa la salida
	## del núcleo si existe; si no, la misma regla sobre el historial de entradas.
	if motor.gabinete.has_method("pendiente_confirmar"):
		return bool(motor.gabinete.call("pendiente_confirmar"))
	var e := motor.estado
	if e.etapa != "gobierno" or e.turno_actual != 1:
		return false
	for i in range(e.entradas.size() - 1, -1, -1):
		var tipo := String(e.entradas[i]["tipo"])
		if tipo == "gabinete":
			return false
		if tipo == "eleccion":
			return true
	return false


static func _agregar_relleno(raiz: VBoxContainer, motor: MotorTurno, elegidos: Array, refrescar: Callable, auto: Dictionary = {}) -> void:
	## PR-05: «Rellenar» completa solo los vacíos (nunca pisa lo escogido), explica por qué y se puede deshacer.
	var previo: Array = []
	var motivos := Tema.etiqueta("", 11, Tema.TEXTO_SUAVE)
	motivos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var modos: Dictionary = motor.catalogo_leyes["gabinete"]["relleno"]["modos"]
	for modo in modos.keys():
		var b := Tema.boton(String(modos[modo]["nombre"]), Tema.PANEL, Tema.TEXTO, 12, 44)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # en el panel del día es más angosto: dos líneas antes que cortar el texto
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.custom_minimum_size.x = 0.0
		b.pressed.connect(func() -> void:
			previo.assign(elegidos)
			var nuevos := motor.gabinete.rellenar(elegidos, String(modo))
			motivos.text = "\n".join(nuevos.map(func(n: Dictionary) -> String: return String(n["motivo"])))
			for n in nuevos:
				elegidos.append(String(n["id"]))
				auto[String(n["id"])] = true  # en el tablero se ven punteados: los puso el relleno, no tú
			refrescar.call())
		fila.add_child(b)
	var deshacer := Tema.boton("Deshacer", Tema.OCEANO.lightened(0.14), Tema.TEXTO, 12, 44)
	deshacer.clip_text = true
	deshacer.custom_minimum_size.x = 84.0
	deshacer.pressed.connect(func() -> void:
		if not previo.is_empty() or not motivos.text.is_empty():
			elegidos.assign(previo)
			previo.clear()
			motivos.text = ""
			refrescar.call())
	fila.add_child(deshacer)
	raiz.add_child(Tema.etiqueta("Rellenar los cargos vacíos (no cambia lo que elegiste):", 11, Tema.TEXTO_SUAVE))
	raiz.add_child(fila)
	raiz.add_child(motivos)


static func crear(motor: MotorTurno, texto_boton: String, al_confirmar: Callable, al_error: Callable = Callable(), con_bloqueadas: bool = false) -> Control:
	## Tablero de los 25 ministerios y baraja de candidatos (opción A elegida por el usuario el 27-nov-2026). Tocar un
	## puesto muestra sus 3 candidatos lado a lado; tocar una carta anticipa su efecto y tocarla otra vez (o arrastrarla
	## al puesto) la nombra. El relleno automático completa los vacíos sin pisar lo elegido y se ve punteado.
	var tam := int(motor.catalogo_leyes["gabinete"]["tamano"])
	var editable := puede_editar(motor)
	var elegidos: Array = motor.estado.gabinete.duplicate()
	var auto := {}  # candidatos puestos por el relleno automático (el gabinete inicial lo arma el relleno)
	if editable:
		for id in elegidos:
			auto[String(id)] = true
	var estado := {"slot": "", "previsto": ""}
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 8)
	var contador := Tema.etiqueta("", 15, Tema.ORO, true)
	var barra := FilasUI.chip_barra(0.0, Tema.ORO)
	var resumen := Tema.etiqueta("", 11, Tema.TEXTO_SUAVE)
	var reaccion := Tema.etiqueta("", 12, Tema.TEXTO, false, 600)  # lo que pasó al nombrar (queda a la vista bajo el resumen)
	var previa := Tema.etiqueta("", 11, Tema.TEXTO_SUAVE)  # pie de la ficha: rasgo y efecto si lo nombras
	var boton := Tema.boton(texto_boton, Tema.ROJO, Tema.TEXTO, 15, 52)
	var por_cargo := {}  # ministerio -> candidatos (en el orden del catálogo)
	for id in motor.catalogo_ministros.keys():
		var slot := motor.gabinete.slot_de(String(id))
		if not por_cargo.has(slot):
			por_cargo[slot] = []
		por_cargo[slot].append(String(id))
	var del_cargo := func(slot: String) -> String:
		for id in elegidos:
			if motor.gabinete.slot_de(String(id)) == slot:
				return String(id)
		return ""
	var grilla := GridContainer.new()
	grilla.columns = 5
	grilla.add_theme_constant_override("h_separation", 6)
	grilla.add_theme_constant_override("v_separation", 6)
	var titulo_baraja := Tema.etiqueta("", 11, Tema.ORO, false, 600)
	var baraja := VBoxContainer.new()  # filas de candidatos, como una ficha de contratación (ejemplo del usuario, 27-nov-2026)
	baraja.add_theme_constant_override("separation", 5)
	var puestos := {}
	var acciones := {}  # el diccionario se captura por referencia: las lambdas se llaman entre sí a través de él
	acciones["nombrar"] = func(id: String) -> void:
		if not editable:
			return
		var slot := motor.gabinete.slot_de(id)
		var origen := Rect2()  # la ficha del candidato, para que vuele a su puesto
		for c in baraja.get_children():
			if c is TableroGabinete.Candidato and (c as TableroGabinete.Candidato).id == id and (c as Control).is_visible_in_tree():
				origen = (c as Control).get_global_rect()
		var antes := motor.gabinete.efecto_semanal_de(elegidos)
		var actual: String = del_cargo.call(slot)
		if actual != "":
			elegidos.erase(actual)
		elegidos.append(id)
		auto.erase(id)
		var despues := motor.gabinete.efecto_semanal_de(elegidos)
		var dif := {}
		for k in despues.keys() + antes.keys():
			dif[k] = float(despues.get(k, 0.0)) - float(antes.get(k, 0.0))
		var ef := TableroGabinete.texto_efecto(dif)
		reaccion.text = "Nombraste a %s. %s" % [motor.catalogo_ministros[id]["alias"], ef if ef != "" else "El efecto semanal no cambia."]
		estado["previsto"] = ""
		Feedback.sonar("decision")
		acciones["refrescar"].call()
		if acciones.has("cerrar_ficha"):
			acciones["cerrar_ficha"].call()  # nombrado: la ficha se cierra y se ve el tablero
		if Movimiento.activo() and puestos.has(slot):
			TableroGabinete.volar(raiz, origen, puestos[slot], String(motor.catalogo_ministros[id]["alias"]))  # la ficha vuela al puesto y este late
	acciones["refrescar"] = func() -> void:
		contador.text = "Gabinete: %d de %d ministros" % [elegidos.size(), tam]
		barra.value = 100.0 * float(elegidos.size()) / float(tam)
		reaccion.visible = reaccion.text != ""
		previa.visible = previa.text != ""
		var ef := TableroGabinete.texto_efecto(motor.gabinete.efecto_semanal_de(elegidos))
		resumen.text = "Efecto semanal del equipo: %s" % (ef if ef != "" else "neutro")
		boton.disabled = elegidos.size() != tam
		boton.visible = editable
		for slot in puestos.keys():
			var actual: String = del_cargo.call(slot)
			(puestos[slot] as TableroGabinete.Puesto).pintar("vacio" if actual == "" else ("auto" if auto.has(actual) else "elegido"), slot == estado["slot"])
		for h in baraja.get_children():
			h.queue_free()
		var s_slot := String(estado["slot"])
		titulo_baraja.text = String(motor.catalogo_ministros[por_cargo[s_slot][0]]["cartera"]).replace("Ministerio de ", "").replace("Ministerio del ", "") if por_cargo.has(s_slot) else ""
		for id in por_cargo.get(s_slot, []):
			var c := TableroGabinete.Candidato.new(motor.gabinete.ficha_candidato(id), elegidos.has(id), estado["previsto"] == id, motor.catalogo_ministros[id].get("retrato", {}))
			c.pressed.connect(func() -> void:
				if not editable:
					return
				if estado["previsto"] == id:
					acciones["nombrar"].call(id)  # segundo toque: nombra
					return
				estado["previsto"] = id
				var prueba: Array = elegidos.filter(func(x: String) -> bool: return motor.gabinete.slot_de(x) != s_slot)
				prueba.append(id)
				var a0 := motor.gabinete.efecto_semanal_de(elegidos)
				var a1 := motor.gabinete.efecto_semanal_de(prueba)
				var dif := {}
				for k in a1.keys() + a0.keys():
					dif[k] = float(a1.get(k, 0.0)) - float(a0.get(k, 0.0))
				var ef2 := TableroGabinete.texto_efecto(dif)
				previa.text = "«%s». Si lo nombras: %s. Tócalo otra vez para nombrarlo." % [motor.catalogo_ministros[id]["rasgo"], ef2 if ef2 != "" else "el efecto semanal no cambia"]
				acciones["refrescar"].call())
			baraja.add_child(c)
	for slot in por_cargo.keys():
		var p := TableroGabinete.Puesto.new(String(slot), TableroGabinete.corto(String(slot), String(motor.catalogo_ministros[por_cargo[slot][0]]["cartera"])))
		p.al_soltar = acciones["nombrar"]
		p.pressed.connect(func() -> void:
			estado["slot"] = String(slot)
			estado["previsto"] = ""
			previa.text = ""
			acciones["refrescar"].call()
			if acciones.has("abrir_ficha"):
				acciones["abrir_ficha"].call())
		grilla.add_child(p)
		puestos[slot] = p
	for slot in por_cargo.keys():  # abre en el primer puesto vacío (o el primero)
		if del_cargo.call(slot) == "":
			estado["slot"] = String(slot)
			break
	if estado["slot"] == "" and not por_cargo.is_empty():
		estado["slot"] = String(por_cargo.keys()[0])
	boton.pressed.connect(func() -> void:
		var r := motor.elegir_gabinete(elegidos)
		if bool(r["ok"]):
			al_confirmar.call()
		elif al_error.is_valid():
			al_error.call(Razones.texto(r)))
	raiz.add_child(contador)
	raiz.add_child(barra)
	raiz.add_child(resumen)
	reaccion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(reaccion)
	var marco := FilasUI.col(6)  # ficha de contratación (ejemplo del usuario): título y cartera, 3 candidatos y el efecto al pie
	var cab := HBoxContainer.new()
	var sub := FilasUI.col(0)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.add_child(Tema.etiqueta_corta("Elige a tu ministro", 14, Tema.TEXTO, true))
	sub.add_child(titulo_baraja)  # la cartera bajo el título
	cab.add_child(sub)
	var cerrar := Tema.boton("×", Color(0, 0, 0, 0), Tema.TEXTO, 22, Tema.TACTIL)
	cerrar.custom_minimum_size = Vector2(Tema.TACTIL, Tema.TACTIL)
	cab.add_child(cerrar)
	marco.add_child(cab)
	marco.add_child(baraja)
	previa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	marco.add_child(previa)
	var ficha := FilasUI.tarjeta(marco, Color("#0F2D46"), Tema.ORO)
	var velo := Control.new()  # la ficha se despliega encima del tablero al tocar un puesto (pedido del usuario del 27-nov-2026)
	velo.top_level = true
	velo.visible = false
	velo.z_index = 5
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.62)
	sombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.add_child(sombra)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(ficha)
	velo.add_child(centro)
	acciones["cerrar_ficha"] = func() -> void:
		velo.visible = false
		estado["previsto"] = ""
		previa.text = ""
	acciones["abrir_ficha"] = func() -> void:
		var vp := raiz.get_viewport_rect().size
		velo.position = Vector2.ZERO
		velo.size = vp
		ficha.custom_minimum_size.x = minf(vp.x - 24.0, 380.0)
		velo.visible = true
		if Movimiento.activo():
			Movimiento.aparecer(ficha)
	cerrar.pressed.connect(acciones["cerrar_ficha"])
	sombra.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and not ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			acciones["cerrar_ficha"].call())  # tocar fuera de la ficha la cierra
	var contenido := FilasUI.col(8)
	contenido.add_child(grilla)
	contenido.add_child(Tema.etiqueta("Dorado: lo elegiste tú · azul: relleno automático. Toca un puesto para abrir su ficha con 3 candidatos.", 11, Tema.TEXTO_SUAVE))
	if editable:
		_agregar_relleno(contenido, motor, elegidos, acciones["refrescar"], auto)
	else:
		contenido.add_child(Tema.etiqueta("En campaña trabaja el equipo automático. Eliges tu gabinete al ganar la elección y puedes cambiarlo en tu primera semana de gobierno." if motor.estado.etapa == "campana" else "El gabinete quedó cerrado: solo se cambia en la primera semana de gobierno.", 11, Tema.ORO))
	if con_bloqueadas:
		var bloq := BloqueoCarta.bloqueadas(motor)
		contenido.add_child(Tema.etiqueta("Cartas bloqueadas con tu gabinete actual", 14, Tema.TEXTO, true))
		for e in bloq.slice(0, 30):
			var v := FilasUI.col(0)
			v.add_child(Tema.etiqueta(String(e["carta"]["titulo"]), 12, Tema.TEXTO, false, 600))
			v.add_child(Tema.etiqueta("Bloqueada: " + String(e["motivo"]), 11, FilasUI.ROJO_TEXTO))
			contenido.add_child(FilasUI.tarjeta(v, Tema.OCEANO.lightened(0.06)))
	var sc := FilasUI.scroll(contenido)
	raiz.add_child(sc)
	raiz.add_child(boton)
	raiz.add_child(velo)  # al final: encima de todo, también del botón principal
	acciones["refrescar"].call()
	return raiz
