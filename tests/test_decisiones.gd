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
	# PR-17: «balas de plata»: cartas únicas, caras en capital político
	var balas: Array = datos["cartas"].filter(func(c: Dictionary) -> bool: return String(c["id"]).begins_with("bala_"))
	_check(balas.size() == 5, "hay 5 balas de plata")
	var m2 := AyudaV2.gobierno(datos, 22)
	m2.estado.mano[0] = balas[0]
	_check(m2.cartas.es_unica(balas[0]), "una bala de plata es de un solo uso")
	var cap := m2.estado.ind("capital")
	_check(bool(m2.jugar_carta(0)["ok"]) and m2.estado.cartas_ejecutadas.has(String(balas[0]["id"])) and m2.estado.ind("capital") < cap, "usarla cuesta capital y no se repite")
	print("test_decisiones: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
