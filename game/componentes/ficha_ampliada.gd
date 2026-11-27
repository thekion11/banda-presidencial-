class_name FichaAmpliada
extends Control
## Ficha ampliada de una carta (P10 del video de prueba): al mantener el dedo sobre una carta de la mano aparece
## grande y completa (título entero, costo, todos los efectos con su nombre, impacto y exigencia legal);
## al soltar se cierra. Solo lectura: no juega ni cambia nada.

var carta: Dictionary = {}
var costo: int = 0
var leyes: Dictionary = {}
var _arte: Control
var _sabor: Label

const ALTO_ARTE := 150.0
const ALTO_ARTE_MIN := 56.0  # con letra grande la ilustración cede alto antes que el texto

const NOMBRES := {"aprobacion": "Aprobación", "capital": "Capital político", "cohesion": "Cohesión", "fiscal": "Fiscal",
	"riesgo_ejecucion": "Riesgo de ejecución", "viviendas_anio": "Viviendas al año", "rival": "Rival"}


static func crear(p_carta: Dictionary, p_costo: int, p_leyes: Dictionary) -> FichaAmpliada:
	var f := FichaAmpliada.new()
	f.set_meta("atras", f.queue_free)  # botón Atrás de Android
	f.carta = p_carta
	f.costo = p_costo
	f.leyes = p_leyes
	return f


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # el dedo sigue sobre la mano: soltarlo la cierra
	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.07, 0.12, 0.72)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	var marco := Control.new()  # soporte fijo fuera de contenedores para escalar sin reacomodos
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.size = Vector2(310, 470)
	marco.position = Vector2((Tema.ANCHO - marco.size.x) * 0.5, 110.0)  # base fija sobre la mano
	marco.pivot_offset = Vector2(marco.size.x * 0.5, marco.size.y)
	add_child(marco)
	var hoja := PanelContainer.new()
	var sb := Tema.caja(Tema.CREMA, 18, Tema.ORO, 3)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 18
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	hoja.add_theme_stylebox_override("panel", sb)
	hoja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hoja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marco.add_child(hoja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hoja.add_child(v)
	_arte = Tema.imagen(String(carta.get("arte", carta.get("categoria", "politica"))), ALTO_ARTE, 12.0)
	v.add_child(_arte)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	var cat := Tema.etiqueta_corta(String(CartaUI.NOMBRES_CAT.get(carta.get("categoria", ""), String(carta.get("categoria", "")).to_upper())), 11,
		CartaUI.COLORES_CATEGORIA.get(carta.get("categoria", ""), Tema.PANEL).darkened(0.25), true)
	cat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(cat)
	cab.add_child(Icono.crear("bolt", Tema.TINTA, 16.0))  # el mismo símbolo de la cabecera: movimientos que cuesta
	cab.add_child(Tema.etiqueta_corta(str(costo), 14, Tema.TINTA, true))
	v.add_child(cab)
	v.add_child(Tema.etiqueta(String(carta.get("titulo", "")), 22, Tema.TINTA, true))
	if String(carta.get("sabor", "")) != "":  # texto propio de las cartas curadas (antes no se mostraba en ninguna parte)
		_sabor = Tema.etiqueta(String(carta["sabor"]), 12, Tema.TINTA)
		v.add_child(_sabor)
	if not leyes.is_empty():
		v.add_child(Tema.etiqueta(FichaCarta.linea(carta, leyes), 12, Tema.GRIS_CLARO, false, 600))
	var efectos := VBoxContainer.new()
	efectos.add_theme_constant_override("separation", 4)
	for ef in carta.get("efectos", []):
		var d := float(ef["delta"])
		var bueno := d >= 0.0 if String(ef["ind"]) != "riesgo_ejecucion" else d <= 0.0
		var txt := "%s  %s" % [String(NOMBRES.get(ef["ind"], ef["ind"])), _cifra(d)]
		efectos.add_child(Tema.etiqueta(txt, 14, Tema.bien_tinta() if bueno else Tema.mal_tinta(), false, 600))
	v.add_child(efectos)
	for extra in _lineas_extra(carta):  # efecto a futuro y riesgo: lo que la carta hará después, con cifras
		v.add_child(Tema.etiqueta(extra, 12, Tema.GRIS_CLARO, false, 600))
	v.add_child(Tema.etiqueta(("Cifras ilustrativas · " if bool(carta.get("cifras_ilustrativas", false)) else "") + "Suelta para cerrar", 11, Tema.GRIS_CLARO))  # CLAUDE.md: cifras ilustrativas rotuladas
	_ajustar_alto.call_deferred(marco, hoja)
	if Movimiento.activo():
		marco.scale = Vector2.ONE * 0.6
		marco.modulate.a = 0.0
		velo.modulate.a = 0.0
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(marco, "scale", Vector2.ONE, 0.24)
		tw.tween_property(marco, "modulate:a", 1.0, 0.14)
		tw.tween_property(velo, "modulate:a", 1.0, 0.18)


func _ajustar_alto(marco: Control, hoja: Control) -> void:
	## El alto sigue al contenido (títulos de una o dos líneas, dos a cuatro efectos), con la base fija. Si con letra
	## grande no cabe bajo la muesca, primero se achica la ilustración y después la base baja sobre la mano.
	var tope := Tema.margen_superior()
	var base := marco.position.y + marco.size.y
	var necesita := hoja.get_combined_minimum_size().y
	if necesita > base - tope and _arte != null:
		_arte.custom_minimum_size.y = maxf(ALTO_ARTE_MIN, ALTO_ARTE - (necesita - (base - tope)))
		necesita = hoja.get_combined_minimum_size().y
	var piso := get_viewport_rect().size.y - 8.0  # la ficha puede bajar sobre la mano, nunca salir de la pantalla
	if necesita > piso - tope and _arte != null:  # ni así cabe (texto propio largo con letra ×1,5 en un teléfono bajo): sin ilustración
		_arte.visible = false
		necesita = hoja.get_combined_minimum_size().y
	if necesita > piso - tope and _sabor != null:  # último recurso: se va el texto de ambientación, nunca un efecto ni el riesgo
		_sabor.visible = false
		necesita = hoja.get_combined_minimum_size().y
	var alto := maxf(necesita, 300.0)
	marco.position.y = minf(maxf(tope, base - alto), maxf(tope, piso - alto))
	marco.size.y = alto
	marco.pivot_offset = Vector2(marco.size.x * 0.5, alto)


static func _lineas_extra(c: Dictionary) -> Array[String]:
	## «En 8 semanas: Cohesión +2 · Aprobación +1» y «Puede salir mal (30 %): Aprobación −1», desde los datos de la carta.
	var res: Array[String] = []
	var lista := func(efs: Array) -> String: return " · ".join(efs.map(func(ef: Dictionary) -> String: return "%s %s" % [String(NOMBRES.get(ef["ind"], ef["ind"])), _cifra(float(ef["delta"]))]))
	if c.has("diferido"):
		res.append("En %d semanas: %s" % [int(c["diferido"]["semanas"]), lista.call(c["diferido"]["efectos"])])
	if c.has("riesgo"):
		res.append("Puede salir mal (%d %%): %s" % [roundi(float(c["riesgo"]["prob"]) * 100.0), lista.call(c["riesgo"]["efectos"])])
	return res


static func _cifra(d: float) -> String:
	## «+8.000» / «−3»: miles con punto, como en Chile.
	var n := absi(roundi(d))
	var s := str(n)
	if n >= 1000:
		s = "%d.%03d" % [n / 1000, n % 1000]
	return ("+" if d >= 0.0 else "−") + s
