class_name CartaUI
extends Control
## Carta de la mano: ilustración arriba, gema de PA, cinta de categoría, título y chips de efectos.

signal tocada(carta: CartaUI)

const COLORES_CATEGORIA := {  # mezclas de la paleta congelada (tests/test_paleta.gd), distinguibles entre sí (ΔE ≥ 12)
	"vivienda": Color("#3D7EA6"), "comite": Color("#2476B6"), "energia": Color("#D9A441"), "hacienda": Color("#4F8F6B"),
	"salud": Color("#B5544F"), "educacion": Color("#5873A4"), "seguridad": Color("#556B7F"), "transportes": Color("#3F8E91"),
	"economia": Color("#A67C3D"), "social": Color("#945360"), "medioambiente": Color("#5E9A4C"), "politica": Color("#6E678A"),
	"descentralizacion": Color("#4C7FA0"), "obras": Color("#9A7A4C"), "oposicion": Color("#793131"), "estado": Color("#3C4E5E"),
}
const NOMBRES_CAT := {"comite": "COMITÉ", "medioambiente": "AMBIENTE", "descentralizacion": "REGIONES", "transportes": "TRANSP.",
	"energia": "ENERGÍA", "educacion": "EDUCACIÓN", "economia": "ECONOMÍA", "politica": "POLÍTICA", "oposicion": "OPOSICIÓN"}  # con tilde: no basta to_upper()

var carta: Dictionary = {}
var costo: int = 0
var elegida: bool = false
var atenuada: bool = false
static var _shader: Shader
var _arte: TextureRect
var _sup: Control  # capa superior: gema y cinta por encima de la ilustración
static var _texturas: Dictionary = {}

const SHADER_REDONDEADO := """
shader_type canvas_item;
uniform vec2 tam = vec2(100.0, 80.0);
uniform float radio = 9.0;
uniform float atenuar = 0.0;
void fragment() {
	vec2 p = UV * tam;
	vec2 q = abs(p - tam * 0.5) - (tam * 0.5 - vec2(radio));
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radio;
	vec4 c = texture(TEXTURE, UV);
	c.rgb *= (1.0 - atenuar);
	float v = distance(UV, vec2(0.5)) * 0.55;  // viñeta suave
	c.rgb *= 1.0 - v * v;
	COLOR = vec4(c.rgb, c.a * clamp(0.5 - d, 0.0, 1.0));
}
"""


func configurar(p_carta: Dictionary, p_costo: int) -> void:
	carta = p_carta
	costo = p_costo
	mouse_filter = Control.MOUSE_FILTER_STOP
	_preparar_arte()
	queue_redraw()


static func _textura(categoria: String) -> Texture2D:
	if not _texturas.has(categoria):
		var ruta := "res://game/arte/cartas/%s.jpg" % categoria
		_texturas[categoria] = Tema.textura_arte(ruta)
	return _texturas[categoria]


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_ajustar_arte()


func _ajustar_arte() -> void:
	if _arte == null:
		return
	if size.x < 1.0:
		return
	var r := Rect2(5, 5, size.x - 10, size.y * 0.50)
	_arte.position = r.position
	_arte.size = r.size
	var m := _arte.material as ShaderMaterial
	m.set_shader_parameter("tam", r.size)
	m.set_shader_parameter("atenuar", 0.28 if atenuada else 0.0)


func _preparar_arte() -> void:
	var tex := _textura(String(carta.get("arte", carta["categoria"])))
	if tex == null:
		tex = _textura(String(carta["categoria"]))
	if tex == null or _arte != null:
		return
	_arte = TextureRect.new()
	_arte.texture = tex
	_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arte.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # arte de 1024 px reducido a ~100: sin mipmaps se ve dentado
	if _shader == null:  # un solo shader para todas las cartas: uno nuevo por carta obliga a compilar variantes en la GPU del teléfono
		_shader = Shader.new()
		_shader.code = SHADER_REDONDEADO
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	_arte.material = mat
	add_child(_arte)
	_sup = Control.new()
	_sup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sup.draw.connect(_dibujar_sup)
	add_child(_sup)
	_ajustar_arte()


func _dibujar_sup() -> void:
	## Cinta de categoría y gema de PA, sobre la ilustración.
	var base: Color = COLORES_CATEGORIA.get(String(carta["categoria"]), Tema.PANEL)
	var cat: String = NOMBRES_CAT.get(String(carta["categoria"]), String(carta["categoria"]).to_upper())
	var cinta := Rect2(size.x - 68.0, 9, 62, 16)
	_sup.draw_style_box(Tema.caja_degradada(Tema.ROJO if elegida else base.darkened(0.25), Tema.ROJO.darkened(0.25) if elegida else base.darkened(0.5), 5), cinta)
	_sup.draw_string(Tema.fuente_texto(800), cinta.position + Vector2(0, 11.5), cat, HORIZONTAL_ALIGNMENT_CENTER, 62, 10, Tema.CREMA)
	_gema_en(_sup, Vector2(21, 21), 14.0)


var _t0: int = -1  # pulsación sobre la carta elegida: su «segundo toque» cuenta al soltar (P10: mantener abre la ficha)
var _p0: Vector2 = Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
	var boton: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
	if not (boton or event is InputEventScreenTouch):
		return
	if event.pressed:
		if not elegida:  # elegir otra carta: al presionar (el gesto de deslizar juega la que se presionó)
			tocada.emit(self)
			return
		_t0 = Time.get_ticks_msec()
		_p0 = event.position
	elif elegida and _t0 >= 0:
		if Time.get_ticks_msec() - _t0 < ManoUI.PULSACION_LARGA_MS and event.position.distance_to(_p0) < 14.0:
			tocada.emit(self)  # toque breve sobre la elegida: la juega
		_t0 = -1


func _fondo_sin_arte(arte: Rect2, base: Color) -> void:
	## Respaldo si faltara la ilustración: panel con el color de la categoría y su nombre al centro, para que la carta nunca
	## se vea vacía o rota (todas las categorías tienen arte: tests/test_claridad.gd lo comprueba).
	draw_style_box(Tema.caja_degradada(base.darkened(0.15), base.darkened(0.5), 9), arte)
	var nom: String = NOMBRES_CAT.get(String(carta.get("categoria", "")), String(carta.get("categoria", "")).to_upper())
	draw_string(Tema.fuente_titulo(), Vector2(arte.position.x, arte.get_center().y + 5.0), nom, HORIZONTAL_ALIGNMENT_CENTER, arte.size.x, 13, Color(Tema.CREMA, 0.75))


func _gema(c: Vector2, r: float) -> void:
	_gema_en(self, c, r)


func _gema_en(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, 1.5), r + 2.0, Color(0, 0, 0, 0.35))
	ci.draw_circle(c, r + 2.0, Tema.OCEANO)
	ci.draw_circle(c, r, Color("#C9921F"))
	ci.draw_circle(c + Vector2(0, -0.8), r - 2.0, Tema.ORO)
	ci.draw_arc(c, r - 3.5, PI * 1.1, PI * 1.7, 10, Color(1, 1, 1, 0.55), 2.0)
	ci.draw_string(Tema.fuente_titulo(), c + Vector2(-r, r * 0.42), str(costo), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 1.25), Tema.TINTA)


func _chip_efecto(r: Rect2, delta: float, texto: String) -> void:
	var bueno := delta >= 0.0
	draw_style_box(Tema.caja(Color("#23825A") if bueno else Tema.ROJO, 9), r)
	var cx := r.position.x + 8.0
	var cy := r.position.y + r.size.y * 0.5
	if bueno:
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - 4.5), Vector2(cx + 4.5, cy + 1), Vector2(cx + 1.5, cy + 1), Vector2(cx + 1.5, cy + 4.5), Vector2(cx - 1.5, cy + 4.5), Vector2(cx - 1.5, cy + 1), Vector2(cx - 4.5, cy + 1)]), Tema.TEXTO)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy + 4.5), Vector2(cx + 4.5, cy - 1), Vector2(cx + 1.5, cy - 1), Vector2(cx + 1.5, cy - 4.5), Vector2(cx - 1.5, cy - 4.5), Vector2(cx - 1.5, cy - 1), Vector2(cx - 4.5, cy - 1)]), Tema.TEXTO)
	draw_string(Tema.fuente_texto(700), Vector2(r.position.x + 16.0, r.position.y + r.size.y - 4.5), texto, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 18.0, 10, Tema.TEXTO)


func _draw() -> void:
	if carta.is_empty():
		return
	if _arte != null and _arte.size.x < 1.0:
		_ajustar_arte.call_deferred()  # el tamaño de la carta se fija después de configurar()
	var w := size.x
	var h := size.y
	var base: Color = COLORES_CATEGORIA.get(String(carta["categoria"]), Tema.PANEL)
	if elegida:
		for k in range(4):
			var g := 3.0 + float(k) * 3.0
			draw_style_box(Tema.caja(Color(Tema.ORO, 0.07), 16 + k * 2), Rect2(-g, -g, w + g * 2.0, h + g * 2.0))
	var borde := Tema.ORO if elegida else Color("#7C8EA0")
	var marco := Tema.caja_degradada(Color("#FFE08A"), Color("#B8851A"), 13) if elegida else Tema.caja_degradada(Color("#AEBCCB"), Color("#5D6E80"), 13)
	draw_style_box(marco, Rect2(Vector2.ZERO, size))
	draw_style_box(Tema.caja_degradada(Color("#12395C"), Color("#0A2037"), 11), Rect2(Vector2(2.5, 2.5), size - Vector2(5, 5)))
	var arte := Rect2(5, 5, w - 10, h * 0.50)
	if _arte == null:
		_fondo_sin_arte(arte, base)
	var cat: String = NOMBRES_CAT.get(String(carta["categoria"]), String(carta["categoria"]).to_upper())
	if _arte == null:
		var cinta := Rect2(w - 68.0, 9, 62, 16)
		draw_style_box(Tema.caja(Tema.ROJO if elegida else base.darkened(0.35), 4), cinta)
		draw_string(Tema.fuente_texto(800), cinta.position + Vector2(0, 11.5), cat, HORIZONTAL_ALIGNMENT_CENTER, 62, 10, Tema.CREMA)
		_gema(Vector2(21, 21), 14.0)
	var tam_tit := 12 if elegida else 11
	var tit := _titulo_ajustado(String(carta["titulo"]), w - 14.0, tam_tit)
	draw_multiline_string(Tema.fuente_titulo(), Vector2(8, arte.end.y + 17), tit[0],
			HORIZONTAL_ALIGNMENT_LEFT, w - 14, int(tit[1]), 2, Tema.TEXTO)
	var y := h - 40.0
	var n := 0
	for ef in carta["efectos"]:
		if n >= 2:
			break
		var delta := float(ef["delta"])
		var cifra := ("+%dk" % roundi(delta / 1000.0)) if absf(delta) >= 1000.0 else Tema.signo(delta)
		_chip_efecto(Rect2(6, y + float(n) * 19.0, w - 12, 17), delta, "%s %s" % [cifra, _nombre_ind(String(ef["ind"]))])
		n += 1
	if atenuada:
		draw_style_box(Tema.caja(Color(0.03, 0.09, 0.15, 0.22), 13), Rect2(Vector2.ZERO, size))


static func _titulo_ajustado(texto: String, ancho: float, tam: int) -> Array:
	## Devuelve [texto, tamaño] para que el título quepa en 2 líneas: baja a 10 pt y, si aún no cabe, corta en una palabra y añade "…".
	var f := Tema.fuente_titulo()
	for t in [tam, maxi(10, tam - 1), 10]:
		if _lineas(f, texto, ancho, t) <= 2:
			return [texto, t]
	var palabras := texto.split(" ")
	while palabras.size() > 1:
		palabras.remove_at(palabras.size() - 1)
		var cand := " ".join(palabras) + "…"
		if _lineas(f, cand, ancho, 10) <= 2:
			return [cand, 10]
	return [texto, 10]


static func _lineas(f: Font, texto: String, ancho: float, tam: int) -> int:
	var h := f.get_multiline_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, ancho, tam).y
	return roundi(h / maxf(1.0, f.get_height(tam)))


static func _nombre_ind(ind: String) -> String:
	return {"aprobacion": "Aprob.", "capital": "Capital", "cohesion": "Cohes.", "fiscal": "Fiscal",
			"riesgo_ejecucion": "Riesgo", "viviendas_anio": "viv./año", "rival": "Rival"}.get(ind, ind)
