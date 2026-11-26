extends SceneTree
## Textos con los ajustes de accesibilidad activos: recorre las mismas pantallas y paneles que test_textos (RecorridoUI) con «texto grande» y con
## texto grande + daltonismo + reducir movimiento, y exige que ningún texto visible se salga del ancho de la pantalla (390 px) ni baje de 10 pt.
## (test_textos hace esta auditoría solo con los ajustes por defecto.)

const MINIMO := 10

var _fallos := 0
var _vistos := 0
var _modo := ""


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
		_check(_tam(n) >= MINIMO, "[%s] %s: «%s» mide %d pt (mín. %d)" % [_modo, donde, corto, _tam(n), MINIMO])
		var r := (n as Control).get_global_rect()
		_check(r.position.x >= -0.5 and r.end.x <= Tema.ANCHO + 0.5, "[%s] %s: «%s» se sale de la pantalla (%s)" % [_modo, donde, corto, r])


func _correr() -> void:
	for modo in ["grande", "todo"]:
		_modo = modo
		Ajustes.texto_grande = true
		Ajustes.daltonico = modo == "todo"
		Ajustes.reducir = modo == "todo"
		var antes := _vistos
		await RecorridoUI.recorrer(self, _auditar)
		_check(_vistos - antes > 150, "[%s] la auditoría debe revisar muchos textos (revisó %d)" % [modo, _vistos - antes])
	Ajustes.texto_grande = false
	Ajustes.daltonico = false
	Ajustes.reducir = false
	if _fallos == 0:
		print("TEXTOS CON AJUSTES OK (%d textos)" % _vistos)
	quit(1 if _fallos > 0 else 0)
