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
const GRIS_CLARO := Color("#566171")  # texto secundario sobre fondos claros (contraste ≥ 5 sobre #F1EDE4, #FBF7EC y blanco)
const SUBE := Color("#4CC38A")
const BAJA := Color("#E8705A")
const ESCALA_APROBACION: Array[Color] = [Color("#E8705A"), Color("#F0A857"), Color("#E8D067"), Color("#8CCB6B"), Color("#4CC38A")]
const ESCALA_DALTONICA: Array[Color] = [Color("#D55E00"), Color("#E69F00"), Color("#F0E442"), Color("#56B4E9"), Color("#2A8BD6")]  # opcional (Ajustes): distinguible con daltonismo

const ANCHO := 390.0
const ALTO := 844.0
const TACTIL := 44.0  # zona táctil mínima
const TAG_WGHT := 2003265652  # etiqueta OpenType "wght"

static var _fuente_titulo: FontVariation
static var _fuentes_texto: Dictionary = {}
static var _shader_imagen: Shader


static func fuente_titulo() -> Font:
	if _fuente_titulo == null:
		var base := load("res://game/fuentes/SpaceGrotesk.ttf") as FontFile
		_fuente_titulo = FontVariation.new()
		_fuente_titulo.base_font = base
		_fuente_titulo.variation_opentype = {TAG_WGHT: 700}
	return _fuente_titulo


static func fuente_texto(peso: int = 400) -> Font:
	if not _fuentes_texto.has(peso):  # una sola fuente por peso: se pide dentro de _draw en cada cuadro
		var f := FontVariation.new()
		f.base_font = load("res://game/fuentes/Inter.ttf") as FontFile
		f.variation_opentype = {TAG_WGHT: peso}
		_fuentes_texto[peso] = f
	return _fuentes_texto[peso]


static func color_aprobacion(v: float) -> Color:
	## Escala de aprobación de mayor a menor: verde -> naranja/rojo.
	var t := clampf((v - 30.0) / 30.0, 0.0, 1.0) * 4.0
	var i := int(floor(t))
	var escala: Array[Color] = ESCALA_DALTONICA if Ajustes.daltonico else ESCALA_APROBACION
	if i >= 4:
		return escala[4]
	return escala[i].lerp(escala[i + 1], t - float(i))


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


const SHADER_IMAGEN := """
shader_type canvas_item;
uniform vec2 tam = vec2(100.0, 80.0);
uniform float radio = 12.0;
uniform float oscurecer = 0.0;
void fragment() {
	vec2 p = UV * tam;
	vec2 q = abs(p - tam * 0.5) - (tam * 0.5 - vec2(radio));
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radio;
	vec4 c = texture(TEXTURE, UV);
	c.rgb *= (1.0 - oscurecer);
	float v = distance(UV, vec2(0.5)) * 0.55;
	c.rgb *= 1.0 - v * v;
	COLOR = vec4(c.rgb, c.a * clamp(0.5 - d, 0.0, 1.0));
}
"""


static var _tex_arte: Dictionary = {}
static var _cache_perilla: Dictionary = {}


static func textura_arte(ruta: String) -> Texture2D:
	## Carga una ilustración y le genera mipmaps en ejecución (los .import no van al repositorio, así que no se puede fijar allí).
	if not _tex_arte.has(ruta):
		var t: Texture2D = load(ruta) if ResourceLoader.exists(ruta) else null
		if t != null:
			var img := t.get_image()
			if img != null and not img.has_mipmaps():
				img.generate_mipmaps()
				t = ImageTexture.create_from_image(img)
		_tex_arte[ruta] = t
	return _tex_arte[ruta]


static func imagen(categoria: String, alto: float, radio: float = 14.0, oscurecer: float = 0.0) -> Control:
	## Ilustración de res://game/arte/cartas con esquinas redondeadas y viñeta. Devuelve un Control vacío si falta la imagen.
	var ruta := "res://game/arte/cartas/%s.jpg" % categoria
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(0, alto)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ResourceLoader.exists(ruta):
		return tr
	tr.texture = textura_arte(ruta)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if _shader_imagen == null:
		_shader_imagen = Shader.new()
		_shader_imagen.code = SHADER_IMAGEN
	var mat := ShaderMaterial.new()
	mat.shader = _shader_imagen
	mat.set_shader_parameter("radio", radio)
	mat.set_shader_parameter("oscurecer", oscurecer)
	tr.material = mat
	tr.resized.connect(func() -> void: mat.set_shader_parameter("tam", tr.size))
	return tr


static func fondo_hero(categoria: String, fraccion: float = 0.62, oscurecer: float = 0.0, ruta_propia: String = "") -> Control:
	## Fondo de pantalla completa: ilustración arriba que se funde con el océano hacia abajo.
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ruta := ruta_propia if ruta_propia != "" else "res://game/arte/cartas/%s.jpg" % categoria
	if ResourceLoader.exists(ruta):
		var hero := TextureRect.new()
		hero.texture = textura_arte(ruta)
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		hero.set_anchors_preset(Control.PRESET_FULL_RECT)
		hero.anchor_bottom = fraccion
		hero.modulate = Color(1.0 - oscurecer, 1.0 - oscurecer, 1.0 - oscurecer)
		hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
		raiz.add_child(hero)
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.04, 0.13, 0.21, 0.30), Color(0.04, 0.13, 0.21, 0.78), Color("#0B2236"), Color("#07182A")])
	g.offsets = PackedFloat32Array([0.0, fraccion * 0.62, fraccion, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 8
	gt.height = 844
	var vel := TextureRect.new()
	vel.texture = gt
	vel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vel.set_anchors_preset(Control.PRESET_FULL_RECT)
	vel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(vel)
	return raiz


static func campo(placeholder: String, maximo: int, texto: String = "") -> LineEdit:
	## Campo de texto para el jugador (tema oscuro, alto táctil de 44 px).
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.max_length = maximo
	le.text = texto
	le.custom_minimum_size = Vector2(0, 44)
	le.add_theme_font_override("font", fuente_texto(500))
	le.add_theme_font_size_override("font_size", 14)
	le.add_theme_color_override("font_color", CREMA)
	le.add_theme_color_override("font_placeholder_color", Color("#8FA6BA"))
	le.add_theme_color_override("caret_color", ORO)
	le.add_theme_stylebox_override("normal", caja(Color("#0F2D46"), 10, Color("#5D7A94"), 1))
	le.add_theme_stylebox_override("focus", caja(Color("#0F2D46"), 10, ORO, 2))
	return le


static func perilla(radio: float, relleno: Color, borde: Color) -> ImageTexture:
	## Círculo con borde para la perilla de un deslizador (se genera una vez por combinación).
	var clave := "%s|%s|%s" % [str(radio), relleno.to_html(), borde.to_html()]
	if not _cache_perilla.has(clave):
		var n := int(ceil(radio * 2.0)) + 2
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var c := Vector2(n, n) * 0.5
		for y in range(n):
			for x in range(n):
				var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
				var a := clampf(radio - d + 0.5, 0.0, 1.0)
				var col := relleno if d < radio - 2.5 else borde
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
		_cache_perilla[clave] = ImageTexture.create_from_image(img)
	return _cache_perilla[clave]


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
	l.add_theme_font_size_override("font_size", roundi(float(tam) * 1.15) if Ajustes.texto_grande else tam)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func etiqueta_corta(texto: String, tam: int = 12, color: Color = TEXTO, titulo: bool = false, peso: int = 400) -> Label:
	var l := etiqueta(texto, tam, color, titulo, peso)
	l.add_theme_font_size_override("font_size", tam)  # sin ajuste de línea: no se agranda para no desbordar
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


static func boton_secundario(texto: String, color_texto: Color = CREMA, alto: float = 46.0) -> Button:
	## Botón secundario de la dirección visual v4: panel translúcido con filo azul (mismo alto táctil en toda pantalla).
	var b := boton(texto, PANEL, color_texto, 13, alto)
	b.add_theme_font_override("font", fuente_texto(600))
	b.add_theme_stylebox_override("normal", caja(Color(PANEL, 0.78), 14, Color("#2A6290"), 1))
	b.add_theme_stylebox_override("hover", caja(Color(PANEL.lightened(0.08), 0.9), 14, Color("#4C84AE"), 1))
	b.add_theme_stylebox_override("pressed", caja(Color(PANEL.darkened(0.2), 0.95), 14, ORO, 1))
	return b


static func estilo_tarjeta(b: Button) -> void:
	## Botón-tarjeta (opciones de afiliación, listas de elección): degradado de panel con filo azul y filo dorado al tocar.
	b.add_theme_stylebox_override("normal", caja_degradada(Color("#1A4C73"), Color("#133C5C"), 16, Color("#2E6490"), 1))
	b.add_theme_stylebox_override("hover", caja_degradada(Color("#1F5885"), Color("#164466"), 16, Color("#4C84AE"), 1))
	b.add_theme_stylebox_override("pressed", caja_degradada(Color("#133C5C"), Color("#0F3150"), 16, ORO, 2))


static func pct(v: float) -> String:
	return "%d %%" % roundi(v)


static func signo(v: float) -> String:
	return ("+%d" % roundi(v)) if v >= 0.0 else ("−%d" % absi(roundi(v)))
