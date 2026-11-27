extends SceneTree
## Límites del índice sectorial (mata T14): en el mínimo no se puede bajar más (sin_efecto) y en el máximo no se puede subir más; a medio paso del límite el
## índice queda exactamente en el límite, nunca más allá.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["movimientos_internos"]["ajustar_sector"]
	var lo := float(cfg["min"])
	var hi := float(cfg["max"])
	var paso := float(cfg["paso"])
	var m := AyudaV2.gobierno(datos, 31)
	var est := m.estado
	est.gabinete.assign(AyudaV2.ministros_de(datos, ["salud", "obras"], 8))
	est.indices_sector["salud"] = lo
	var r: Dictionary = m.ajustar_sector("salud", -1)
	_check(not bool(r["ok"]) and String(r["razon"]) == "sin_efecto", "en el mínimo bajar no tiene efecto: %s" % str(r))
	_check(is_equal_approx(float(est.indices_sector["salud"]), lo), "el índice se queda en el mínimo (%.2f)" % lo)
	est.indices_sector["salud"] = lo + paso * 0.5
	r = m.ajustar_sector("salud", -1)
	_check(bool(r["ok"]) and is_equal_approx(float(est.indices_sector["salud"]), lo), "a medio paso del mínimo, bajar deja el índice en el mínimo (%.2f), no más abajo: %s" % [lo, str(est.indices_sector["salud"])])
	est.indices_sector["obras"] = hi
	r = m.ajustar_sector("obras", 1)
	_check(not bool(r["ok"]) and String(r["razon"]) == "sin_efecto", "en el máximo subir no tiene efecto: %s" % str(r))
	est.indices_sector["obras"] = hi - paso * 0.5
	est.internos_actual = 3
	r = m.ajustar_sector("obras", 1)
	_check(bool(r["ok"]) and is_equal_approx(float(est.indices_sector["obras"]), hi), "a medio paso del máximo, subir deja el índice en el máximo (%.2f)" % hi)
	if _fallos == 0:
		print("test_indice_sector_limites: OK")
	quit(1 if _fallos > 0 else 0)
