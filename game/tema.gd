class_name Tema
extends RefCounted
## Sistema de diseño congelado de la maqueta (paleta, tipografía, medidas). No cambiar sin cambiar la maqueta.

const OCEANO := Color("#0B2236")
const PANEL := Color("#16405F")
const ORO := Color("#F2C14E")
const ROJO := Color("#C23B2E")
const CREMA := Color("#FBF7EC")
const TEXTO := Color("#FFFFFF")
const TEXTO_SUAVE := Color("#B9C9D8")
const TINTA := Color("#0B2236")
const FONDO_CLARO := Color("#F1EDE4")  # pantallas claras de la maqueta (hito, mapa urbano)
const BORDE_CLARO := Color("#D9D2C2")
const SUBE := Color("#4CC38A")
const BAJA := Color("#E8705A")
const ESCALA_APROBACION: Array[Color] = [Color("#E8705A"), Color("#F0A857"), Color("#E8D067"), Color("#8CCB6B"), Color("#4CC38A")]

const ANCHO := 390.0
const ALTO := 844.0
const TACTIL := 44.0  # zona táctil mínima
const TAG_WGHT := 2003265652  # etiqueta OpenType "wght"

static var _fuente_titulo: FontVariation
static var _fuente_texto: FontVariation


static func fuente_titulo() -> Font:
	if _fuente_titulo == null:
		var base := load("res://game/fuentes/SpaceGrotesk.ttf") as FontFile
		_fuente_titulo = FontVariation.new()
		_fuente_titulo.base_font = base
		_fuente_titulo.variation_opentype = {TAG_WGHT: 700}
	return _fuente_titulo


static func fuente_texto(peso: int = 400) -> Font:
	var base := load("res://game/fuentes/Inter.ttf") as FontFile
	var f := FontVariation.new()
	f.base_font = base
	f.variation_opentype = {TAG_WGHT: peso}
	return f


static func color_aprobacion(v: float) -> Color:
	## Escala de aprobación de mayor a menor: verde -> naranja/rojo.
	var t := clampf((v - 30.0) / 30.0, 0.0, 1.0) * 4.0
	var i := int(floor(t))
	if i >= 4:
		return ESCALA_APROBACION[4]
	return ESCALA_APROBACION[i].lerp(ESCALA_APROBACION[i + 1], t - float(i))


static var _cache_grad: Dictionary = {}


static func caja_degradada(arriba: Color, abajo: Color, radio: int = 27, borde: Color = Color(0, 0, 0, 0), grosor: int = 0) -> StyleBoxTexture:
	## Caja redondeada con degradado vertical suave y borde opcional (9-slice generado una sola vez por combinación).
	var clave := "%s|%s|%d|%s|%d" % [arriba.to_html(), abajo.to_html(), radio, borde.to_html(), grosor]
	if not _cache_grad.has(clave):
		var n := 96
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in range(n):
			var c := arriba.lerp(abajo, float(y) / float(n - 1))
			for x in range(n):
				var dx := maxf(maxf(float(radio) - float(x) - 0.5, float(x) + 0.5 - float(n - radio)), 0.0)
				var dy := maxf(maxf(float(radio) - float(y) - 0.5, float(y) + 0.5 - float(n - radio)), 0.0)
				var d := sqrt(dx * dx + dy * dy)
				var a := clampf(float(radio) - d + 0.5, 0.0, 1.0)  # antialias en el borde
				var col := c
				if grosor > 0:
					var entrada := float(mini(mini(x, n - 1 - x), mini(y, n - 1 - y)))
					var en_borde := d > float(radio - grosor) or entrada < float(grosor)
					if en_borde:
						col = borde
				col.a *= a
				img.set_pixel(x, y, col)
		_cache_grad[clave] = ImageTexture.create_from_image(img)
	var sb := StyleBoxTexture.new()
	sb.texture = _cache_grad[clave]
	sb.texture_margin_left = radio
	sb.texture_margin_right = radio
	sb.texture_margin_top = radio
	sb.texture_margin_bottom = radio
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func caja(color: Color, radio: int = 14, borde: Color = Color(0, 0, 0, 0), grosor: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radio)
	if grosor > 0:
		s.border_color = borde
		s.set_border_width_all(grosor)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func etiqueta(texto: String, tam: int = 12, color: Color = TEXTO, titulo: bool = false, peso: int = 400) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", fuente_titulo() if titulo else fuente_texto(peso))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func etiqueta_corta(texto: String, tam: int = 12, color: Color = TEXTO, titulo: bool = false, peso: int = 400) -> Label:
	var l := etiqueta(texto, tam, color, titulo, peso)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


static func boton(texto: String, fondo: Color, color_texto: Color = TEXTO, tam: int = 15, alto: float = 52.0) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(TACTIL, maxf(alto, TACTIL))
	b.add_theme_font_override("font", fuente_titulo())
	b.add_theme_font_size_override("font_size", tam)
	for est in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(est, color_texto)
	b.add_theme_stylebox_override("normal", caja(fondo, 18))
	b.add_theme_stylebox_override("hover", caja(fondo.lightened(0.08), 18))
	b.add_theme_stylebox_override("pressed", caja(fondo.darkened(0.15), 18))
	b.add_theme_stylebox_override("disabled", caja(fondo.darkened(0.5), 18))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


static func pct(v: float) -> String:
	return "%d %%" % roundi(v)


static func signo(v: float) -> String:
	return ("+%d" % roundi(v)) if v >= 0.0 else ("−%d" % absi(roundi(v)))
