extends SceneTree
## Guardia de regresión del balance (Monte Carlo reducido). Falla si el juego se vuelve trivial o imposible.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO DE BALANCE: ", msg)


func _tasas(datos: Dictionary, politica: String, n: int, dificultad: String = "") -> Dictionary:
	var electos := 0
	var crisis := 0
	for i in range(n):
		var e := Bots.partida_completa(datos, 5000 + i, politica, dificultad).estado
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
	_check(pasivo["electos"] < 0.15, "no jugar no debe ganar elecciones")
	_check(azar["electos"] > 0.10 and azar["electos"] < 0.65, "el azar debería ganar a veces, no siempre")
	_check(cod["electos"] > azar["electos"] + 0.15, "jugar bien debe pesar en la campaña")
	_check(cod["electos"] > 0.70, "la campaña bien jugada debe ser ganable")
	_check(cod_pasivo["crisis"] > 0.50, "gobernar sin hacer nada debe terminar en crisis")
	_check(cod["crisis"] < 0.26, "gobernar activamente no debe colapsar")  # techo 0,20 -> 0,26 con el ahorro de movimientos (BL): ya no se pierden movimientos, el codicioso juega ~20 % más y la crisis medida subió de ≈ 11 a ≈ 20 % (n = 80)
	var aho := _tasas(datos, "ahorrador", 40)  # BL: ahorrar (jugar solo semanas alternas y gastar todo de golpe) no debe ser mejor que gastar cada semana
	print("ahorrador=%s" % [aho])
	_check(aho["electos"] <= cod["electos"] + 0.10, "ahorrar movimientos no debe dominar en campaña")
	var leg := _tasas(datos, "legislador", 40)  # BM: presentar leyes por la agenda (extra a las cartas de la mano) no debe volver trivial el gobierno
	print("legislador=%s" % [leg])
	_check(leg["crisis"] < 0.26 and leg["electos"] <= cod["electos"] + 0.10, "legislar por la agenda no debe dominar ni hundir al gobierno")
	# matriz por dificultad (n=40: error típico ≈ 8 puntos, por eso las bandas son anchas): un cambio de datos que rompa la escalera falla aquí
	var f := _tasas(datos, "codicioso", 40, "facil")
	var nor := _tasas(datos, "codicioso", 40, "normal")
	var dif := _tasas(datos, "codicioso", 40, "dificil")
	var comp := _tasas(datos, "completo", 40, "normal")
	var azar_dif := _tasas(datos, "azar", 40, "dificil")
	var pasivo_dif := _tasas(datos, "pasivo", 40, "dificil")
	print("codicioso fácil=%s normal=%s difícil=%s · completo normal=%s · azar difícil=%s · pasivo difícil=%s" % [f, nor, dif, comp, azar_dif, pasivo_dif])
	_check(f["electos"] >= 0.90, "fácil: jugar bien casi siempre gana la elección (%.2f)" % f["electos"])
	_check(nor["electos"] >= 0.80, "normal: jugar bien gana la elección (%.2f)" % nor["electos"])
	_check(dif["electos"] >= 0.30 and dif["electos"] <= 0.75, "difícil: jugar bien gana a veces, no siempre (%.2f)" % dif["electos"])
	_check(nor["electos"] >= dif["electos"] + 0.15, "la escalera de dificultad existe: normal supera a difícil por más de 15 puntos")
	_check(azar_dif["electos"] <= 0.15, "difícil: el azar casi nunca gana (%.2f)" % azar_dif["electos"])
	_check(pasivo_dif["electos"] <= 0.05, "difícil: no jugar no gana (%.2f)" % pasivo_dif["electos"])
	_check(comp["crisis"] <= 0.10, "usar todas las mecánicas casi nunca termina en crisis (%.2f)" % comp["crisis"])
	_check(comp["electos"] >= 0.80, "usar todas las mecánicas gana la elección en normal (%.2f)" % comp["electos"])
	if _fallos == 0:
		print("BALANCE OK")
	quit(0 if _fallos == 0 else 1)
