extends SceneTree
## Textos (CLAUDE.md §5): todo texto visible mide al menos 10 pt y no lleva emojis; los rótulos de la interfaz
## llevan sus tildes y ningún texto se sale del ancho de la pantalla. Recorre las pantallas y paneles (RecorridoUI). Los textos dibujados a mano se revisan
## leyendo el código (draw_string con tamaño < 10).

const MINIMO := 10
## Palabras de interfaz que se escriben con tilde: si aparecen sin ella en un texto visible, es un error.
const SIN_TILDE := ["Comite", "Camara", "votacion", "aprobacion", "Aprobacion", "region", "Region", "Mas", "dia", "Dia", "Gestion", "Cohesion", "Afiliacion", "Eleccion", "eleccion", "Musica", "Vibracion", "Republica", "Constitucion", "Politica", "politica", "economia", "Economia", "energia", "Energia", "Credito", "Mision", "decision", "Decision"]

var _fallos := 0
var _vistos := 0
var _alto := 844


static func _en_scroll(n: Node) -> bool:
	## Dentro de una zona desplazable el contenido puede quedar fuera de la vista: se alcanza deslizando.
	var p := n.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _texto(n: Control) -> String:
	if n is Label:
		return (n as Label).text
	if n is Button:
		return (n as Button).text
	if n is RichTextLabel:
		return (n as RichTextLabel).get_parsed_text()
	return ""


func _tam(n: Control) -> int:
	if n is RichTextLabel:
		return n.get_theme_font_size("normal_font_size")
	return n.get_theme_font_size("font_size")


func _auditar(raiz: Node, donde: String) -> void:
	for n in raiz.find_children("*", "Control", true, false):
		if not (n is Label or n is Button or n is RichTextLabel) or not (n as Control).is_visible_in_tree():
			continue
		var t := _texto(n)
		if t.strip_edges() == "":
			continue
		_vistos += 1
		var corto := t.replace("\n", " ").left(40)
		_check(_tam(n) >= MINIMO, "%s: «%s» mide %d pt (mín. %d)" % [donde, corto, _tam(n), MINIMO])
		var r := (n as Control).get_global_rect()  # nada se sale de la pantalla: ancho 390 y el alto del teléfono emulado
		_check(_en_scroll(n) or (r.position.x >= -0.5 and r.end.x <= Tema.ANCHO + 0.5), "%s: «%s» se sale de la pantalla (%s)" % [donde, corto, r])
		_check(_en_scroll(n) or r.end.y <= _alto + 0.5, "%s: «%s» queda bajo el borde inferior (%s, alto %d)" % [donde, corto, r, _alto])
		for ch in t:
			if ch.unicode_at(0) >= 0x1F300:
				_check(false, "%s: «%s» tiene un emoji" % [donde, corto])
				break
		var fuente: Font = n.get_theme_font("normal_font") if n is RichTextLabel else n.get_theme_font("font")
		for ch in t:  # cada carácter existe en la fuente embebida que lo dibuja (si no, en Android sale de otra fuente o como cuadro)
			var cp := ch.unicode_at(0)
			if cp > 127 and ch != "\u00a0" and not _tiene_glifo(fuente, cp):
				_check(false, "%s: «%s» usa «%s» (U+%04X), que su fuente no tiene" % [donde, corto, ch, cp])
				break
		var m := _sin_tilde().search(t)  # palabra completa: «Constitucional» no es «Constitucion»
		if m != null:
			_check(false, "%s: «%s» parece sin tilde («%s»)" % [donde, corto, m.get_string(1)])


static func _tiene_glifo(f: Font, cp: int) -> bool:
	var base: Font = f
	while base is FontVariation:
		base = (base as FontVariation).base_font
	return not (base is FontFile) or (base as FontFile).has_char(cp)


var _re_tilde: RegEx


func _sin_tilde() -> RegEx:
	if _re_tilde == null:
		_re_tilde = RegEx.create_from_string("(?<![\\p{L}])(" + "|".join(SIN_TILDE) + ")(?![\\p{L}])")
	return _re_tilde


func _dibujados() -> void:
	## draw_string(..., tamaño, color): ningún texto dibujado a mano bajo 10 pt.
	var re := RegEx.create_from_string("draw_string\\(.*,\\s*([0-9]+),\\s*(Tema\\.|Color|col|c\\b)")
	for ruta in _archivos("res://game"):
		var f := FileAccess.open(ruta, FileAccess.READ)
		var linea := 0
		while not f.eof_reached():
			var l := f.get_line()
			linea += 1
			var m := re.search(l)
			if m != null and int(m.get_string(1)) < MINIMO:
				_check(false, "%s:%d dibuja texto a %s pt" % [ruta, linea, m.get_string(1)])


func _archivos(dir: String) -> Array[String]:
	var res: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		res.append_array(_archivos(dir + "/" + sub))
	for a in DirAccess.get_files_at(dir):
		if a.ends_with(".gd"):
			res.append(dir + "/" + a)
	return res


func _correr() -> void:
	_dibujados()
	for alto in RecorridoUI.ALTURAS:  # 390×844 y otros teléfonos (360×640, 412×915, 480×1000)
		_alto = alto
		await RecorridoUI.recorrer(self, func(raiz: Node, donde: String) -> void: _auditar(raiz, "%s [alto %d]" % [donde, alto]), alto)
	_alto = 844
	for escala in [1.3, 1.5]:  # letra grande de Android (1,3 y 1,5) en las etiquetas con ajuste de línea
		Ajustes.escala_prueba = escala
		await RecorridoUI.recorrer(self, func(raiz: Node, donde: String) -> void: _auditar(raiz, "%s [letra ×%.1f]" % [donde, escala]))
	Ajustes.escala_prueba = 0.0
	_check(_vistos > 150 * (RecorridoUI.ALTURAS.size() + 2), "la auditoría debe revisar muchos textos (revisó %d)" % _vistos)
	if _fallos == 0:
		print("TEXTOS OK (%d textos)" % _vistos)
	quit(1 if _fallos > 0 else 0)
