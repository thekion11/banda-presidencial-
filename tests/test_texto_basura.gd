extends SceneTree
## Fuga de valores sin formatear en los textos visibles: recorre las mismas pantallas y paneles que test_textos (RecorridoUI), con los ajustes por defecto y con texto
## grande + daltonismo, y falla si algún texto muestra «null», «nan», «inf», «%s», «{}», «<null>», «Object#», «-0» o días negativos (AyudaTextos).
## También revisa el ayudante contra textos que SÍ deben marcarse y textos normales que NO.

var _fallos := 0
var _vistos := 0
var _modo := ""

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _auditar(raiz: Node, donde: String) -> void:
	for n in raiz.find_children("*", "Control", true, false):
		if (n is Label or n is Button or n is RichTextLabel) and (n as Control).is_visible_in_tree() and AyudaTextos.texto_de(n).strip_edges() != "":
			_vistos += 1
	for b in AyudaTextos.basura(raiz):
		_check(false, "[%s] %s: %s" % [_modo, donde, b])


func _init() -> void:
	_correr.call_deferred()


func _autoprueba() -> void:
	# el detector debe marcar lo malo...
	var l := Label.new()
	root.add_child(l)
	for malo in ["Día null", "Aprobación: nan %", "Costo: inf", "Gasto %s M", "Total %d", "{}", "Obras: []", "<null>", "Object#123", "-0 %", "hace -3 días", "Dictionary"]:
		l.text = malo
		_check(not AyudaTextos.basura(l.get_parent()).is_empty(), "el detector no marcó «%s»" % malo)
	# ...y dejar pasar el texto normal (con palabras que contienen «inf», «nan» o «null» dentro)
	for bueno in ["Información financiera", "Finanzas y energía", "Nacional", "Aprobación 53 %", "Día 36 · Mié 15 abr 2026", "-3 puntos", "Infraestructura", "Inaugurar: Jardín Inf…", "Nan…", "1.250 viviendas", "−2 Capital", "Nulidad"]:
		l.text = bueno
		_check(AyudaTextos.basura(l.get_parent()).is_empty(), "el detector marcó un texto normal: «%s» (%s)" % [bueno, str(AyudaTextos.basura(l.get_parent()))])
	l.queue_free()


func _correr() -> void:
	_autoprueba()
	for modo in ["normal", "grande"]:
		_modo = modo
		Ajustes.texto_grande = modo == "grande"
		Ajustes.daltonico = modo == "grande"
		await RecorridoUI.recorrer(self, _auditar)
	Ajustes.texto_grande = false
	Ajustes.daltonico = false
	_check(_vistos > 300, "la auditoría debe revisar muchos textos (revisó %d)" % _vistos)
	if _fallos == 0:
		print("TEXTO BASURA OK (%d textos revisados)" % _vistos)
	quit(1 if _fallos > 0 else 0)
