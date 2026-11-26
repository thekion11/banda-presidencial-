extends SceneTree
## Zonas táctiles ≥ 44 px (CLAUDE.md §5): recorre las pantallas y paneles (RecorridoUI) y exige que todo botón visible
## mida al menos Tema.TACTIL de alto y de ancho. Mide el estado final (sin animaciones).

var _fallos := 0
var _vistos := 0


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


func _correr() -> void:
	await RecorridoUI.recorrer(self, _auditar)
	_check(_vistos > 60, "la auditoría debe revisar muchos botones (revisó %d)" % _vistos)
	if _fallos == 0:
		print("TÁCTIL OK (%d botones)" % _vistos)
	quit(1 if _fallos > 0 else 0)
