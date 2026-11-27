class_name TelonSemana
extends Control
## Telón entre semanas (dirección visual v4): al terminar la semana baja un telón con «Semana 6 → 7» y cada
## indicador contando de su valor anterior al nuevo, con flecha y color. Se va solo (o al tocarlo) y entonces
## siguen los eventos de la semana nueva. Sin animaciones no aparece: `al_terminar` corre al instante.

const IND := [["aprobacion", "Aprobación"], ["capital", "Capital político"], ["cohesion", "Cohesión"], ["fiscal", "Fiscal"]]
const ESPERA := 1.7

var titulo_antes: String = ""
var titulo_despues: String = ""
var subtitulo: String = ""
var antes: Dictionary = {}
var despues: Dictionary = {}
var oposicion: bool = false
var encuesta: Dictionary = {}  # la de esta semana (estado.encuestas, forma fijada en tests/test_encuestas.gd)
var encuesta_previa: Dictionary = {}
var nombres_region: Dictionary = {}
var ultima_de_campana: bool = false  # la encuesta extra al cerrar la última semana de campaña (sim/encuestas.gd)
var al_terminar: Callable
var guardados := 0  # movimientos guardados: un rayo por cada uno, que aparecen uno a uno
var ahorro: String = ""  # «Guardaste 2 movimientos: esta semana tienes 7» (pedido del usuario: los movimientos se guardan)
var motivos: Array = []  # motor.motivos_semana(): hasta 3 cambios con su causa
var _panel: Control
var _saliendo: bool = false


static func lineas_motivos(lista: Array) -> Array[String]:
	## «Cohesión −1,9: desgaste del gobierno» por cada fila de motor.motivos_semana() (ya viene ordenada y con 3 como máximo).
	var nombres := {"cohesion": "Cohesión", "riesgo_ejecucion": "Riesgo de ejecución", "capital": "Capital", "fiscal": "Fiscal", "aprobacion": "Aprobación"}
	var res: Array[String] = []
	for m in lista:
		var d := float(m["delta"])
		res.append("%s %s%s: %s" % [String(nombres.get(m["ind"], m["ind"])), "+" if d >= 0.0 else "−", Tema.dec(absf(d)), String(m["causa"])])
	return res


static func mostrar(capa: Control, p_antes: Array, p_despues: Array, ind_antes: Dictionary, ind_despues: Dictionary, p_oposicion: bool, fin: Callable,
		encuestas: Array = [], regiones: Array = [], semanas_campana: int = 0, p_motivos: Array = [], p_ahorro: String = "", p_guardados: int = 0) -> void:
	## p_antes / p_despues: [título, subtítulo] de la cabecera antes y después de avanzar.
	if not Movimiento.activo():
		fin.call()
		return
	var t := TelonSemana.new()
	t.titulo_antes = String(p_antes[0])
	t.titulo_despues = String(p_despues[0])
	t.subtitulo = String(p_despues[1])
	t.antes = ind_antes
	t.despues = ind_despues
	t.oposicion = p_oposicion
	t.al_terminar = fin
	t.motivos = p_motivos
	t.ahorro = p_ahorro
	t.guardados = p_guardados
	if not encuestas.is_empty():  # solo hay encuestas en campaña y oposición
		t.encuesta = encuestas.back()
		t.encuesta_previa = encuestas[encuestas.size() - 2] if encuestas.size() > 1 else {}
		t.ultima_de_campana = semanas_campana > 0 and String(t.encuesta.get("etapa", "")) == "campana" and int(t.encuesta.get("turno", 0)) > semanas_campana
		for r in regiones:
			t.nombres_region[String(r["id"])] = String(r["nombre"]).replace(" de Santiago", "").replace(" Chilena", "")
	capa.add_child(t)


func _ready() -> void:
	set_meta("atras", _salir)  # botón Atrás de Android: el telón se cierra como al tocarlo
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # ya está en el árbol: hay que fijar también los offsets
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_salir())
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("#154F7A"), Tema.OCEANO, Color("#07182A")])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.3)
	gt.fill_to = Vector2(0.5, 1.1)
	var fondo := TextureRect.new()
	fondo.texture = gt
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(fondo)
	var filo := ColorRect.new()  # borde dorado inferior del telón
	filo.color = Tema.ORO
	filo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	filo.offset_top = -4
	filo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(filo)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 28
	col.offset_right = -28
	col.offset_top = maxf(Tema.margen_superior() + 40.0, 210.0 - maxf(0.0, 760.0 - Tema.alto_util()))  # en teléfono bajo sube: caben encuesta y motivos
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(col)
	col.add_child(Tema.etiqueta("FIN DE LA SEMANA", 12, Tema.ORO, true))
	var tit := Tema.etiqueta(titulo_antes, 22, Tema.TEXTO_SUAVE, true)  # con texto grande (+15 %) cabe en una línea
	col.add_child(tit)
	col.add_child(Tema.etiqueta(subtitulo, 13, Tema.TEXTO_SUAVE))
	if ahorro != "":
		col.add_child(Tema.etiqueta(ahorro, 12, Tema.ORO, false, 600))
		if guardados > 0:
			var rayos := HBoxContainer.new()
			rayos.add_theme_constant_override("separation", 2)
			rayos.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for i in range(mini(guardados, 10)):
				rayos.add_child(Icono.crear("bolt", Tema.ORO, 16.0, true))
			col.add_child(rayos)
			Movimiento.escalonar(rayos, 0.5, 0.08, 10)  # se guardan de a uno
	var sep := ColorRect.new()
	sep.color = Color(Tema.ORO, 0.5)
	sep.custom_minimum_size = Vector2(0, 2)
	col.add_child(sep)
	var filas := VBoxContainer.new()
	filas.add_theme_constant_override("separation", 10)
	col.add_child(filas)
	for par in IND:
		var k: String = "rival" if oposicion and par[0] == "fiscal" else String(par[0])
		filas.add_child(_fila("Rival" if k == "rival" else String(par[1]), float(antes.get(k, 0.0)), float(despues.get(k, 0.0)), k == "rival"))
	var porque := lineas_motivos(motivos)
	if not porque.is_empty():  # la causa de cada cambio, en una línea («Cohesión −1,9: desgaste del gobierno»)
		var pv := VBoxContainer.new()
		pv.add_theme_constant_override("separation", 2)
		pv.add_child(Tema.etiqueta_corta("POR QUÉ CAMBIÓ", 10, Tema.ORO, true))
		for l in porque:
			pv.add_child(Tema.etiqueta(l, 11, Tema.TEXTO_SUAVE, false, 600))
		col.add_child(pv)
	if not encuesta.is_empty():
		col.add_child(_bloque_encuesta())
	elif porque.is_empty() and float(despues.get("cohesion", 0.0)) < float(antes.get("cohesion", 0.0)) - 0.5:  # el desgaste semanal (leyes.json › dinamica) no se explicaba
		col.add_child(Tema.etiqueta("La cohesión se desgasta cada semana y pesa en los votos del Congreso: la sostienen un gabinete afín a tu partido y aliados conformes.", 11, Tema.TEXTO_SUAVE))
	col.add_child(Tema.etiqueta("Toca para continuar", 11, Tema.TEXTO_SUAVE))
	_panel.position.y = -Tema.ALTO
	var tw := create_tween()
	tw.tween_property(_panel, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:  # el título cambia a la semana nueva con un latido
		tit.text = titulo_despues
		tit.add_theme_color_override("font_color", Tema.TEXTO)
		Movimiento.latido(tit, 1.08))
	Movimiento.escalonar(filas, 0.4, 0.08)
	tw.tween_interval(ESPERA + (1.0 if not encuesta.is_empty() else 0.0))  # con encuesta hay más que leer
	tw.tween_callback(_salir)


func _fila(nombre: String, a: float, d: float, invertido: bool) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var n := Tema.etiqueta_corta(nombre, 14, Tema.TEXTO, false, 600)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	var v := Tema.etiqueta_corta("", 20, Tema.TEXTO, true)
	Movimiento.contar(v, roundf(d), func(x: float) -> String: return str(roundi(x)), roundf(a), 0.9, 0.45)
	h.add_child(v)
	var delta := roundi(d) - roundi(a)
	var bueno := (delta > 0) != invertido
	var txt := "= 0" if delta == 0 else Tema.signo(float(delta))
	var dl := Tema.etiqueta_corta(txt, 14, Tema.TEXTO_SUAVE if delta == 0 else (Tema.bien() if bueno else Tema.mal()), true)
	dl.custom_minimum_size = Vector2(58, 0)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(dl)
	return h


func _salir() -> void:
	if _saliendo:
		return
	_saliendo = true
	var tw := create_tween()
	tw.tween_property(_panel, "position:y", -Tema.ALTO, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		var fin := al_terminar
		queue_free()
		if fin.is_valid():
			fin.call())


func _bloque_encuesta() -> Control:
	## Encuesta de la semana: intención con su margen de error, umbral (campaña) o gobierno rival (oposición),
	## cambio respecto de la anterior y las regiones donde más cuesta. Cifras ilustrativas (data/leyes.json › encuestas).
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sep := ColorRect.new()
	sep.color = Color(Tema.ORO, 0.5)
	sep.custom_minimum_size = Vector2(0, 2)
	v.add_child(sep)
	v.add_child(Tema.etiqueta(("ÚLTIMA ENCUESTA ANTES DE LA ELECCIÓN" if ultima_de_campana else "ENCUESTA DE LA SEMANA") + " · ILUSTRATIVA", 11, Tema.ORO, true))
	var intencion := float(encuesta.get("intencion", 0.0))
	var margen := float(encuesta.get("margen", 0.0))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var cifra := Tema.etiqueta_corta("", 26, Tema.TEXTO, true)
	Movimiento.contar(cifra, intencion, func(x: float) -> String: return "%s %%" % Tema.dec(x), 0.0, 0.9, 0.5)
	fila.add_child(cifra)
	var lado := Tema.etiqueta_corta("± %s · %s" % [Tema.dec(margen), "intención de voto" if not oposicion else "tu aprobación"], 12, Tema.TEXTO_SUAVE)
	lado.size_flags_vertical = Control.SIZE_SHRINK_END
	fila.add_child(lado)
	v.add_child(fila)
	var umbral: Variant = encuesta.get("umbral", null)
	var rival: Variant = encuesta.get("rival", null)
	v.add_child(_barra(intencion, margen, float(umbral) if umbral != null else -1.0, float(rival) if rival != null else -1.0))
	var partes: Array[String] = []
	if umbral != null:
		partes.append("umbral %.0f %%" % float(umbral))
	if rival != null:
		partes.append("gobierno rival %s %%" % Tema.dec(float(rival)))
	if not encuesta_previa.is_empty():
		var d := intencion - float(encuesta_previa.get("intencion", intencion))
		partes.append(("%+.1f" % d).replace(".", ",").replace("-", "−") + " desde la semana pasada")
	if not partes.is_empty():
		v.add_child(Tema.etiqueta(" · ".join(partes), 12, Tema.TEXTO_SUAVE))
	var debiles: Array[String] = []
	for r in encuesta.get("regiones", []):
		debiles.append("%s %.0f %%" % [String(nombres_region.get(String(r["id"]), String(r["id"]))), float(r["valor"])])
	if not debiles.is_empty():
		v.add_child(Tema.etiqueta("Donde más te cuesta: " + ", ".join(debiles), 12, Tema.TEXTO))
	return v


func _barra(valor: float, margen: float, umbral: float, rival: float) -> Control:
	## Barra 0–100: relleno hasta la intención, franja clara del margen de error, marca dorada del umbral y marca del rival.
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 20)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_meta("t", 0.0 if Movimiento.activo() else 1.0)
	c.draw.connect(func() -> void:
		var w := c.size.x
		var y := 6.0
		var t := float(c.get_meta("t"))
		c.draw_rect(Rect2(0, y, w, 8), Color("#274A66"))
		c.draw_rect(Rect2(w * (valor - margen) / 100.0, y - 2.0, w * margen * 2.0 / 100.0, 12), Color(Tema.CREMA, 0.18 * t))
		c.draw_rect(Rect2(0, y, w * clampf(valor, 0.0, 100.0) / 100.0 * t, 8), Tema.color_aprobacion(valor + 12.0))
		if umbral > 0.0:
			c.draw_rect(Rect2(w * umbral / 100.0 - 1.5, 0, 3, 20), Tema.ORO)
		if rival > 0.0:
			c.draw_rect(Rect2(w * rival / 100.0 - 1.0, 2, 2, 16), Tema.mal()))
	if Movimiento.activo():
		c.create_tween().tween_method(func(x: float) -> void:
			c.set_meta("t", x)
			c.queue_redraw(), 0.0, 1.0, 0.9).set_delay(0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return c
