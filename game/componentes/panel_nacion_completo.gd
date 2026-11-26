class_name PanelNacionCompleto
extends RefCounted
## Pantalla "Chile por regiones" completa: mapa con lista, banner del evento y botón central para avanzar el turno.


static func crear(motor: MotorTurno, geo: Dictionary, regiones: Array, texto_evento: String, al_avanzar: Callable) -> Control:
	var pn := PanelNacion.new()
	pn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pn.custom_minimum_size = Vector2(0, 470)
	var vn := VBoxContainer.new()
	vn.add_theme_constant_override("separation", 8)
	vn.add_child(_selector(pn, motor))
	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", Tema.caja(Color("#12395A"), 12, Color("#2B5D86"), 1))
	banner.add_child(Tema.etiqueta(texto_evento, 12, Tema.TEXTO))
	var mb := MarginContainer.new()
	mb.add_theme_constant_override("margin_left", 12)
	mb.add_theme_constant_override("margin_right", 12)
	mb.add_child(banner)
	vn.add_child(mb)
	var obras_n: Dictionary = {}
	for o in motor.estado.obras_en_curso:
		obras_n[o["region"]] = int(obras_n.get(o["region"], 0)) + 1
	pn.configurar(geo, regiones, motor.estado.aprobacion_regional, obras_n)
	return vn


static func _selector(pn: PanelNacion, motor: MotorTurno) -> Control:
	## PR-06c: «Chile» (regiones) o «Continente» (Sudamérica con relaciones). Un solo mapa con dos niveles.
	var caja := VBoxContainer.new()
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var b_chile := Tema.boton("Chile", Tema.ORO, Tema.TINTA, 13, 44)
	var b_cont := Tema.boton("Continente", Tema.PANEL, Tema.TEXTO, 13, 44)
	for b in [b_chile, b_cont]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(b)
	var cont := MapaContinente.new()
	cont.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cont.custom_minimum_size = Vector2(0, 400 if Tema.pantalla_baja() else 470)  # en teléfono bajo deja sitio a la línea del país y al evento
	cont.visible = false
	var vec: Dictionary = Datos.leer_json("res://data/vecinos.json")
	for iso in vec["paises"].keys():
		cont.relaciones[iso] = motor.eventos.relacion_exterior(String(iso), float(vec["paises"][iso]["relacion"]))
	cont.cargar(Datos.leer_json("res://data/geo/sudamerica.json"), vec)
	var info := Tema.etiqueta("Toca un país para ver su relación con Chile (cifras ilustrativas · mapa ilustrativo).", 11, Tema.TEXTO_SUAVE)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.visible = false
	cont.pais_tocado.connect(func(iso: String) -> void:
		var d: Dictionary = vec["paises"].get(iso, {})
		info.text = "%s · relación %d/100 · %s" % [_geo_nombre(cont, iso), roundi(float(cont.relaciones.get(iso, d.get("relacion", 0)))), String(d.get("tema", ""))])
	var mostrar := func(continente: bool) -> void:
		pn.visible = not continente
		cont.visible = continente
		info.visible = continente
		b_chile.add_theme_stylebox_override("normal", Tema.caja(Tema.PANEL if continente else Tema.ORO, 14))
		b_cont.add_theme_stylebox_override("normal", Tema.caja(Tema.ORO if continente else Tema.PANEL, 14))
		b_chile.add_theme_color_override("font_color", Tema.TEXTO if continente else Tema.TINTA)
		b_cont.add_theme_color_override("font_color", Tema.TINTA if continente else Tema.TEXTO)
	b_chile.pressed.connect(mostrar.bind(false))
	b_cont.pressed.connect(mostrar.bind(true))
	caja.add_child(fila)
	caja.add_child(pn)
	caja.add_child(cont)
	caja.add_child(info)
	return caja


static func _geo_nombre(cont: MapaContinente, iso: String) -> String:
	return String(cont._geo["paises"][iso]["nombre"])
