extends SceneTree
## Formato numérico y de fechas chileno en los textos visibles: decimales con coma («3,5 %», no «3.5 %»), miles con punto («12.500», no «12500» ni «12,500»),
## fechas en español (sin ISO «2025-09-21» ni meses en inglés). Recorre las mismas pantallas y paneles que test_textos (RecorridoUI).
## Exime lo que no es una cifra del juego: años (4 dígitos), cadenas hexadecimales (huella) y los créditos de fuentes de datos.

var _fallos := 0
var _vistos := 0
var _re_decimal := RegEx.new()
var _re_miles_sin := RegEx.new()
var _re_miles_coma := RegEx.new()
var _re_iso := RegEx.new()
var _re_ingles := RegEx.new()
var _re_hex := RegEx.new()


func _init() -> void:
	_re_decimal.compile("(?<![\\d.,])\\d+\\.\\d{1,2}(?![\\d.])")  # 3.5, 57.4, 0.25 (no 1.200 ni 1.234.567: son miles)
	_re_miles_sin.compile("(?<![\\d.,/-])\\d{5,}(?![\\d])")  # 12500 (los años de 4 dígitos no cuentan)
	_re_miles_coma.compile("\\d{1,3}(,\\d{3})+(?!\\d)")  # 12,500
	_re_iso.compile("\\b\\d{4}-\\d{2}-\\d{2}\\b")
	_re_ingles.compile("\\b(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\b")
	_re_hex.compile("[0-9a-f]{16,}")
	_correr.call_deferred()


func _texto(n: Control) -> String:
	if n is Label:
		return (n as Label).text
	if n is Button:
		return (n as Button).text
	if n is RichTextLabel:
		return (n as RichTextLabel).get_parsed_text()
	return ""


func _exento(t: String) -> bool:
	return _re_hex.search(t) != null or t.contains("GeoJSON") or t.contains("OpenStreetMap") or t.contains("Fuente")


func _auditar(raiz: Node, donde: String) -> void:
	for n in raiz.find_children("*", "Control", true, false):
		if not (n is Label or n is Button or n is RichTextLabel) or not (n as Control).is_visible_in_tree():
			continue
		var t := _texto(n)
		if t.strip_edges() == "" or _exento(t):
			continue
		_vistos += 1
		var corto := t.replace("\n", " ").left(60)
		var h := _re_decimal.search(t)
		if h != null:
			_fallos += 1
			print("FALLO: [%s] decimal con punto «%s» en «%s» (usa coma)" % [donde, h.get_string(), corto])
		h = _re_miles_sin.search(t)
		if h != null:
			_fallos += 1
			print("FALLO: [%s] miles sin separador «%s» en «%s» (usa punto)" % [donde, h.get_string(), corto])
		h = _re_miles_coma.search(t)
		if h != null:
			_fallos += 1
			print("FALLO: [%s] miles con coma «%s» en «%s» (usa punto)" % [donde, h.get_string(), corto])
		h = _re_iso.search(t)
		if h != null:
			_fallos += 1
			print("FALLO: [%s] fecha ISO «%s» en «%s» (usa «21 sep 2025»)" % [donde, h.get_string(), corto])
		h = _re_ingles.search(t)
		if h != null:
			_fallos += 1
			print("FALLO: [%s] mes en inglés «%s» en «%s»" % [donde, h.get_string(), corto])


func _correr() -> void:
	await RecorridoUI.recorrer(self, _auditar)
	if _vistos < 150:
		print("FALLO: la auditoría debe revisar muchos textos (revisó %d)" % _vistos)
		_fallos += 1
	if _fallos == 0:
		print("FORMATO CHILENO OK (%d textos)" % _vistos)
	quit(1 if _fallos > 0 else 0)
