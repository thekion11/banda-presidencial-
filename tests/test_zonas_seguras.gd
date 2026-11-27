extends SceneTree
## Zonas seguras de Android (cola 5 de la coordinadora): con una muesca o cámara arriba y la barra de gestos o de
## navegación abajo (0, 24 y 48 px lógicos), ningún botón ni texto queda debajo de esas franjas (salvo en zonas que
## se desplazan), todo botón mide ≥ 44 px y «Terminar semana», el botón de la votación y los chips de abajo del día
## quedan enteros sobre la barra. Recorre todas las pantallas (RecorridoUI) en 390×844 y en el teléfono bajo 390×693.

const INSETS := [Vector2(0, 0), Vector2(24, 24), Vector2(48, 48), Vector2(0, 48), Vector2(48, 0)]
const ALTOS := [844, 693]

var _fallos := 0
var _vistos := 0
var _claves := {}


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


static func _en_scroll(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _auditar(raiz: Node, donde: String, alto: int, inset: Vector2) -> void:
	var piso := float(alto) - inset.y
	for n in raiz.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or _en_scroll(c):
			continue
		var r := c.get_global_rect()
		var texto := String(c.get("text")) if (c is Label or c is Button) else ""
		if c is BaseButton:
			_vistos += 1
			_check(r.end.y <= piso + 0.5 and r.position.y >= inset.x - 0.5, "%s: botón «%s» bajo la franja del sistema (%s)" % [donde, texto.left(30), r])
			_check(r.size.x >= Tema.TACTIL - 0.5 and r.size.y >= Tema.TACTIL - 0.5, "%s: botón «%s» mide %s" % [donde, texto.left(30), r.size])
			for clave in ["Terminar semana", "Siguiente semana", "Continuar", "Pasa a la"]:
				if texto.begins_with(clave):
					_claves[clave] = true
		elif c is Label and texto.strip_edges() != "":
			_check(r.end.y <= piso + 0.5, "%s: «%s» queda bajo la barra de gestos (%s)" % [donde, texto.left(30), r])
			_check(r.position.y >= inset.x - 0.5, "%s: «%s» queda bajo la muesca (%s)" % [donde, texto.left(30), r])
	if donde.begins_with("día"):
		var dia: PantallaDia = raiz._pantalla
		var b := dia._btn_jugar.get_global_rect()
		_check(b.end.y <= piso + 0.5 and b.size.y >= Tema.TACTIL, "%s: «Terminar semana» entero sobre la barra (%s)" % [donde, b])
		var nav := dia.find_children("*", "BaseButton", true, false).filter(func(x: Node) -> bool: return (x as Control).is_visible_in_tree() and (x as Control).get_global_rect().position.y > float(alto) * 0.75)
		_check(nav.size() >= 3, "%s: los chips de abajo están en pantalla (%d)" % [donde, nav.size()])


func _correr() -> void:
	Tema.inset_prueba = Vector2(0, 0)
	_check(is_equal_approx(Tema.margen_inferior(), 0.0) and is_equal_approx(Tema.margen_superior(), 12.0), "sin franjas: abajo 0 y arriba el mínimo")
	Tema.inset_prueba = Vector2(30, 40)
	_check(is_equal_approx(Tema.margen_inferior(), 40.0) and is_equal_approx(Tema.margen_superior(), 34.0), "con franjas: abajo lo que pide el sistema y arriba eso + 4")
	Tema.inset_prueba = Vector2(-1, -1)
	_check(Tema.margen_inferior() >= 0.0, "sin datos del sistema (escritorio) el margen inferior no es negativo")
	for alto in ALTOS:
		for ins in INSETS:
			Tema.inset_prueba = ins
			var tag := "[%d, muesca %d, barra %d]" % [alto, ins.x, ins.y]
			await RecorridoUI.recorrer(self, func(raiz: Node, donde: String) -> void: _auditar(raiz, "%s %s" % [donde, tag], alto, ins), alto)
	Tema.inset_prueba = Vector2(-1, -1)
	_check(_claves.has("Terminar semana") or _claves.has("Siguiente semana"), "la auditoría vio «Terminar semana»")
	_check(_claves.has("Pasa a la"), "la auditoría vio el botón de la votación")
	_check(_vistos > 60 * ALTOS.size() * INSETS.size(), "la auditoría revisó muchos botones (%d)" % _vistos)
	if _fallos == 0:
		print("ZONAS SEGURAS OK")
	quit(1 if _fallos > 0 else 0)
