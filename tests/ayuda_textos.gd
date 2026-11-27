class_name AyudaTextos
extends RefCounted
## Busca «basura» en los textos visibles de la interfaz: valores que se filtran sin formatear (null, nan, inf, %s, %d, {}, [], <null>, Object#, «-0», días negativos, la
## palabra Dictionary o Array). `AyudaTextos.basura(raiz)` devuelve «texto -> patrón» de cada texto visible que contiene alguno.

static var _patrones: Array[RegEx] = []
const NOMBRES := ["null", "nan", "inf", "%s/%d", "{}", "[]", "<null>", "Object#", "-0", "día negativo", "Dictionary/Array"]


static func _armar() -> void:
	if not _patrones.is_empty():
		return
	for p in ["(?i)(?<![\\p{L}\\p{N}_])null(?![\\p{L}\\p{N}_…])", "(?i)(?<![\\p{L}\\p{N}_])nan(?![\\p{L}\\p{N}_…])", "(?i)(?<![\\p{L}\\p{N}_])-?inf(?![\\p{L}\\p{N}_…])",
			"%[sdfi]", "\\{\\s*\\}", "\\[\\s*\\]", "<null>", "Object#|<Object|Object:", "(?<![\\p{N}.,])-0(?![\\p{N}.,])", "(?i)\\b(d[ií]as?|semanas?)\\s+-\\d|-\\d+\\s+(d[ií]as?|semanas?)\\b",
			"\\b(Dictionary|Array|PackedStringArray)\\b"]:
		_patrones.append(RegEx.create_from_string(p))


static func texto_de(n: Control) -> String:
	if n is Label:
		return (n as Label).text
	if n is Button:
		return (n as Button).text
	if n is RichTextLabel:
		return (n as RichTextLabel).get_parsed_text()
	return ""


static func basura(raiz: Node) -> Array[String]:
	_armar()
	var res: Array[String] = []
	for n in raiz.find_children("*", "Control", true, false):
		if not (n is Label or n is Button or n is RichTextLabel) or not (n as Control).is_visible_in_tree():
			continue
		var t := texto_de(n)
		if t.strip_edges() == "":
			continue
		for i in range(_patrones.size()):
			if _patrones[i].search(t) != null:
				res.append("«%s» -> %s" % [t.replace("\n", " ").left(60), NOMBRES[i]])
				break
	return res
