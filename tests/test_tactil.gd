extends SceneTree
## Zonas táctiles ≥ 44 px (CLAUDE.md §5): recorre las pantallas y paneles (RecorridoUI) y exige que todo botón visible
## mida al menos Tema.TACTIL de alto y de ancho y quepa en la pantalla, en 390×844 y en otros tamaños de teléfono. Mide el estado final (sin animaciones).

var _fallos := 0
var _vistos := 0
var _alto := 844


static func _en_scroll(n: Node) -> bool:
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


func _auditar(raiz: Node, donde: String) -> void:
	for n in raiz.find_children("*", "BaseButton", true, false):
		var b := n as BaseButton
		if not b.is_visible_in_tree():
			continue
		_vistos += 1
		var t := b.get_global_rect().size
		var nombre: String = (b as Button).text.replace("\n", " ").left(30) if b is Button else String(b.name)
		_check(t.x >= Tema.TACTIL - 0.5 and t.y >= Tema.TACTIL - 0.5, "%s: «%s» mide %s (mín. %d)" % [donde, nombre, t, int(Tema.TACTIL)])
		var r := b.get_global_rect()  # el botón cabe entero en la pantalla (salvo dentro de una zona desplazable)
		_check(_en_scroll(b) or (r.position.y >= -0.5 and r.end.y <= _alto + 0.5 and r.position.x >= -0.5 and r.end.x <= Tema.ANCHO + 0.5),
			"%s: «%s» se sale de la pantalla (%s, alto %d)" % [donde, nombre, r, _alto])


func _correr() -> void:
	for alto in RecorridoUI.alturas():  # 390×844 y otros teléfonos (360×640, 412×915, 480×1000)
		_alto = alto
		await RecorridoUI.recorrer(self, func(raiz: Node, donde: String) -> void: _auditar(raiz, "%s [alto %d]" % [donde, alto]), alto)
	_check(_vistos > 60 * RecorridoUI.alturas().size(), "la auditoría debe revisar muchos botones (revisó %d)" % _vistos)
	if _fallos == 0:
		print("TÁCTIL OK (%d botones)" % _vistos)
	quit(1 if _fallos > 0 else 0)
