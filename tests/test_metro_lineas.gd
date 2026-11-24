extends SceneTree
## Líneas de Metro del mapa: datos coherentes con la lista de estaciones, ocultar/mostrar líneas y toque sobre una línea.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO METRO: ", msg)


func _init() -> void:
	var d := UrbanoBase.datos()
	_check(not d.is_empty(), "faltan los datos urbanos")
	var ids := UrbanoBase.ids_lineas()
	_check(ids.size() == 7, "deben existir 7 líneas (L1, L2, L3, L4, L4A, L5, L6); hay %d" % ids.size())
	var con_lineas := 0
	var combinaciones := 0
	for e in d["estaciones"]:
		var l: Array = e.get("l", [])
		if not l.is_empty():
			con_lineas += 1
		if l.size() > 1:
			combinaciones += 1
	_check(con_lineas == d["estaciones"].size(), "toda estación debe pertenecer a alguna línea (%d de %d)" % [con_lineas, d["estaciones"].size()])
	_check(combinaciones == 17, "deben ser 17 estaciones de combinación; hay %d" % combinaciones)
	for l in d["metro"]:
		_check(l.get("cabos", []).size() == 2, "la línea %s debe tener dos cabos" % l["id"])
	UrbanoBase.ocultas.clear()
	var tam := Vector2(370, 400)
	var mar := Vector2(8, 8)
	var c := UrbanoBase.preparar(tam, mar)
	var l5: Dictionary = {}
	for l in c["metro"]:
		if l["id"] == "L5":
			l5 = l
	var punto: Vector2 = l5["seg"][40]
	_check(UrbanoBase.linea_en(punto, tam, mar) != "", "tocar sobre una línea debe encontrarla")
	_check(UrbanoBase.linea_en(Vector2(-500, -500), tam, mar) == "", "tocar lejos de toda línea no debe encontrar nada")
	UrbanoBase.alternar_linea("L5")
	_check(UrbanoBase.ocultas.has("L5"), "alternar debe ocultar la línea")
	_check(UrbanoBase.linea_en(punto, tam, mar) != "L5", "una línea oculta no debe responder al toque")
	UrbanoBase.alternar_linea("L5")
	_check(not UrbanoBase.ocultas.has("L5"), "alternar de nuevo debe mostrarla")
	UrbanoBase.ocultas.clear()
	if _fallos == 0:
		print("METRO OK (7 líneas, %d estaciones, 17 combinaciones; ocultar y tocar línea)" % d["estaciones"].size())
	quit(0 if _fallos == 0 else 1)
