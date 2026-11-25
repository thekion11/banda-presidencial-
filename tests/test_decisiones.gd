extends SceneTree
## PR-07/PR-08: eventos con opciones: la respuesta aplica efectos, no gasta movimientos, no se repite y se reproduce.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var con_ops: Array = datos["eventos"].filter(func(e: Dictionary) -> bool: return e.has("opciones"))
	_check(con_ops.size() >= 10, "hay al menos 10 eventos con opciones (%d)" % con_ops.size())
	for e in con_ops:
		_check(e["opciones"].size() >= 2, "%s: al menos 2 opciones" % e["id"])
	var m := AyudaV2.gobierno(datos, 21)
	var evt: Dictionary = con_ops[0]
	var res := m.eventos.aplicar_evento(evt)
	_check(res.has("opciones") and res["efectos"].is_empty(), "el evento con opciones no aplica efectos por sí solo")
	var antes := m.estado.ind("aprobacion") + m.estado.ind("fiscal") + m.estado.ind("capital")
	var pa := m.estado.pa_actual
	var r := m.eventos.decidir(String(evt["id"]), 0)
	_check(bool(r["ok"]), "decidir la opción 0")
	_check(m.estado.pa_actual == pa, "decidir no gasta movimientos")
	_check(m.estado.ind("aprobacion") + m.estado.ind("fiscal") + m.estado.ind("capital") != antes, "la decisión cambia indicadores")
	_check(not bool(m.eventos.decidir(String(evt["id"]), 1)["ok"]), "no se puede decidir dos veces")
	_check(not bool(m.eventos.decidir("evt_inexistente", 0)["ok"]), "evento inexistente")
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(Datos.huella(datos))))
	_check(g["entradas"].any(func(e: Dictionary) -> bool: return e["tipo"] == "decision"), "la decisión queda en el guardado")
	print("test_decisiones: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
