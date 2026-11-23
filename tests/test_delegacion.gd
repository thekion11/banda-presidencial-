extends SceneTree
## Delegación en ministros (DISENO_V2 §5): sin movimientos, tope por turno, falla según riesgo, determinista.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO DELEGACIÓN: ", msg)


func _intentar(datos: Dictionary, semilla: int, riesgo: float) -> Array:
	var m := AyudaV2.gobierno(datos, semilla)
	m.estado.indicadores["riesgo_ejecucion"] = riesgo
	var res: Array = []
	for _i in range(2):
		res.append(m.delegar_carta(0, String(m.estado.gabinete[0])))
	return res


func _init() -> void:
	var datos := Datos.cargar_todo()
	var d: Dictionary = datos["leyes"]["delegacion"]
	var m := AyudaV2.gobierno(datos, 21)
	var est := m.estado
	var fuera := ""
	for mi in datos["ministros"]:
		if not est.gabinete.has(String(mi["id"])):
			fuera = String(mi["id"])
			break
	_check(String(m.delegar_carta(0, fuera)["razon"]) == "ministro_fuera_del_gabinete", "solo ministros del gabinete")
	_check(String(m.delegar_carta(0, "")["razon"]) == "ministro_fuera_del_gabinete", "ministro vacío rechazado")
	var pa := est.pa_actual
	var p := m.prob_fallo_delegacion(0, String(est.gabinete[0]))
	_check(p >= float(d["prob_fallo_min"]) and p <= float(d["prob_fallo_max"]), "probabilidad de fallo dentro de los límites")
	var r1 := m.delegar_carta(0, String(est.gabinete[0]))
	_check(bool(r1["ok"]) and int(r1["costo"]) == 0 and est.pa_actual == pa, "delegar no gasta movimientos")
	_check(est.mano.size() == 5, "la mano se rellena tras delegar")
	_check(bool(m.delegar_carta(0, String(est.gabinete[1]))["ok"]), "segunda delegación permitida")
	_check(String(m.delegar_carta(0, String(est.gabinete[1]))["razon"]) == "limite_delegaciones", "la tercera supera el tope por turno")
	m.terminar_turno()
	_check(est.delegadas_turno == 0, "las delegaciones se renuevan cada turno")
	# la probabilidad de fallo sube con el riesgo de ejecución
	var bajo := AyudaV2.gobierno(datos, 22)
	var alto := AyudaV2.gobierno(datos, 22)
	bajo.estado.indicadores["riesgo_ejecucion"] = 0.0
	alto.estado.indicadores["riesgo_ejecucion"] = 90.0
	var mid := String(bajo.estado.gabinete[0])
	_check(alto.prob_fallo_delegacion(0, mid) > bajo.prob_fallo_delegacion(0, mid), "más riesgo de ejecución, más probabilidad de fallo")
	# frecuencia: con riesgo alto falla a veces pero no siempre; con la misma semilla el resultado es idéntico
	var fallos := 0
	var escandalos := 0
	var total := 0
	for s in range(100, 160):
		var a := _intentar(datos, s, 60.0)
		var b := _intentar(datos, s, 60.0)
		_check(JSON.stringify(a) == JSON.stringify(b), "misma semilla, mismo resultado de delegación")
		for r in a:
			if bool(r["ok"]):
				total += 1
				fallos += 1 if bool(r["fallo"]) else 0
				escandalos += 1 if bool(r["escandalo"]) else 0
	_check(fallos > 0 and fallos < total, "la delegación sale mal a veces (%d de %d)" % [fallos, total])
	_check(escandalos > 0 and escandalos <= fallos, "los escándalos solo ocurren cuando falla (%d)" % escandalos)
	# efecto reducido: una delegación fallida aplica menos efecto que una exitosa de la misma carta
	var carta_ef := {}
	for s in range(100, 160):
		var mm := AyudaV2.gobierno(datos, s, [AyudaV2.carta_sintetica("t_cap", "politica", {})])
		mm.estado.mano.clear()
		mm.estado.mano.append(mm._cartas_por_id["t_cap"])
		mm.estado.indicadores["capital"] = 50.0
		var rr := mm.delegar_carta(0, String(mm.estado.gabinete[0]))
		var clave := "fallo" if bool(rr["fallo"]) else "exito"
		if not carta_ef.has(clave) and not bool(rr["escandalo"]):
			carta_ef[clave] = mm.estado.ind("capital") - 50.0
	_check(carta_ef.has("fallo") and carta_ef.has("exito") and float(carta_ef["fallo"]) < float(carta_ef["exito"]), "efecto reducido al fallar")
	# en campaña no se delega
	var resp: Array[Dictionary] = []
	for q in datos["ideologia"]["preguntas"]:
		resp.append(q["opciones"][1])
	var c := Partida.crear(datos, 3, GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, datos["ideologia"]))
	_check(not bool(c.delegar_carta(0, String(c.estado.gabinete[0]))["ok"]), "no se delega en campaña")
	print("DELEGACIÓN OK (%d/%d fallos, %d escándalos)" % [fallos, total, escandalos] if _fallos == 0 else "DELEGACIÓN FALLÓ")
	quit(1 if _fallos > 0 else 0)
