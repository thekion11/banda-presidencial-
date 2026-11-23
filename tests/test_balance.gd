extends SceneTree
## Guardia de regresión del balance (Monte Carlo reducido). Falla si el juego se vuelve trivial o imposible.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO DE BALANCE: ", msg)


func _tasas(datos: Dictionary, politica: String, n: int) -> Dictionary:
	var electos := 0
	var crisis := 0
	for i in range(n):
		var e := Bots.partida_completa(datos, 5000 + i, politica).estado
		if e.etapa != "derrota_electoral":
			electos += 1
		if e.etapa == "crisis":
			crisis += 1
	return {"electos": float(electos) / n, "crisis": float(crisis) / maxf(1.0, float(electos))}


func _init() -> void:
	var datos := Datos.cargar_todo()
	var n := 60
	var pasivo := _tasas(datos, "pasivo", n)
	var azar := _tasas(datos, "azar", n)
	var cod := _tasas(datos, "codicioso", n)
	var cod_pasivo := _tasas(datos, "codicioso>pasivo", n)
	print("pasivo=%s azar=%s codicioso=%s cod>pasivo=%s" % [pasivo, azar, cod, cod_pasivo])
	_check(pasivo["electos"] < 0.10, "no jugar no debe ganar elecciones")
	_check(azar["electos"] > 0.10 and azar["electos"] < 0.65, "el azar debería ganar a veces, no siempre")
	_check(cod["electos"] > azar["electos"] + 0.15, "jugar bien debe pesar en la campaña")
	_check(cod["electos"] > 0.70, "la campaña bien jugada debe ser ganable")
	_check(cod_pasivo["crisis"] > 0.50, "gobernar sin hacer nada debe terminar en crisis")
	_check(cod["crisis"] < 0.20, "gobernar activamente no debe colapsar")
	if _fallos == 0:
		print("BALANCE OK")
	quit(0 if _fallos == 0 else 1)
