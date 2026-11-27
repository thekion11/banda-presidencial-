extends SceneTree
## Fundación del partido (PantallaPartido._fundar): un nombre vacío o de solo espacios recibe el nombre por defecto, una sigla vacía se completa con las tres primeras
## letras del nombre, y la sigla siempre queda en mayúsculas. (Hallazgo del mutation testing: ninguna prueba comprobaba estos valores por defecto.)

var _fallos := 0
var _res: Array = []

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	Tutorial.ruta = "user://preferencias_fundacion.json"
	var casos := [
		{"nombre": "", "sigla": "", "espera_nombre": "Partido Independiente", "espera_sigla": "PAR"},
		{"nombre": "   ", "sigla": " ", "espera_nombre": "Partido Independiente", "espera_sigla": "PAR"},
		{"nombre": "Movimiento Cívico", "sigla": "", "espera_nombre": "Movimiento Cívico", "espera_sigla": "MOV"},
		{"nombre": "x", "sigla": "x", "espera_nombre": "x", "espera_sigla": "X"},
		{"nombre": "Partido Verde", "sigla": "pv", "espera_nombre": "Partido Verde", "espera_sigla": "PV"},
		{"nombre": "  Con espacios  ", "sigla": " cp ", "espera_nombre": "Con espacios", "espera_sigla": "CP"},
	]
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for caso in casos:
		main.mostrar_partido("propio")
		await process_frame
		var pp: Node = main._pantalla
		for p in pp._preguntas():
			pp._responder(p["opciones"][1])
		await process_frame
		pp._nombre.text = String(caso["nombre"])
		pp._sigla.text = String(caso["sigla"])
		pp.fundado.connect(func(p: Dictionary) -> void: _res.append(p))
		pp._fundar()
		await process_frame
		var p: Dictionary = _res.back() if not _res.is_empty() else {}
		_check(not p.is_empty() and p["nombre"] == caso["espera_nombre"], "nombre «%s» dio «%s», se esperaba «%s»" % [caso["nombre"], p.get("nombre", "?"), caso["espera_nombre"]])
		_check(not p.is_empty() and p["sigla"] == caso["espera_sigla"], "sigla «%s» (nombre «%s») dio «%s», se esperaba «%s»" % [caso["sigla"], caso["nombre"], p.get("sigla", "?"), caso["espera_sigla"]])
	_check(_res.size() == casos.size(), "cada fundación debe emitir un partido (%d de %d)" % [_res.size(), casos.size()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	print("test_fundacion: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
