extends SceneTree
## Empates exactos con los umbrales (mata los mutantes T06 y T07): con aprobación igual al piso de segunda vuelta se pasa a balotaje, y con aprobación igual a
## «umbral_gana» / «umbral_renida» la sucesión es «gana» / «renida» (los umbrales son inclusivos). Complementa test_finales_limite (umbral de elección y de crisis).

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _partido(datos: Dictionary) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return GeneradorPartido.construir_partido("Limite", "LIM", "metropolitana", resp, datos["ideologia"])


func _fin_campana(datos: Dictionary, semilla: int) -> MotorTurno:
	var m := Partida.crear(datos, semilla, _partido(datos))
	m.catalogo_leyes["campana"]["ruido_eleccion"] = 0.0
	m.catalogo_leyes["campana"]["penal_sin_promesas"] = 0.0  # el voto es exactamente la aprobación
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		m.terminar_turno()
	return m


func _init() -> void:
	var datos := Datos.cargar_todo()
	# piso de segunda vuelta: aprobación == umbral_pasa_balotaje (por debajo del umbral de victoria)
	var m := _fin_campana(datos, 77)
	var piso := float(m.catalogo_leyes["hemiciclo"]["umbral_pasa_balotaje"])
	var umbral := float(m.catalogo_leyes["hemiciclo"]["umbral_victoria_presidencial"]) + float(m.mandato.nivel()["umbral_delta"])
	_check(piso < umbral, "el piso (%.1f) debe estar bajo el umbral de victoria (%.1f)" % [piso, umbral])
	m.estado.indicadores["aprobacion"] = piso
	var r: Dictionary = m.resolver_eleccion_presidencial()
	_check(bool(r["ok"]) and not bool(r["electo"]) and bool(r["balotaje"]) and int(r["ronda"]) == 1, "con aprobación == piso (%.1f) hay segunda vuelta: %s" % [piso, str(r)])
	var m2 := _fin_campana(datos, 78)
	m2.estado.indicadores["aprobacion"] = piso - 0.1
	var r2: Dictionary = m2.resolver_eleccion_presidencial()
	_check(not bool(r2["electo"]) and not bool(r2["balotaje"]), "con aprobación justo bajo el piso no hay segunda vuelta: %s" % str(r2))
	# sucesión: umbrales inclusivos
	var s: Dictionary = datos["leyes"]["sucesion"]
	for par in [[float(s["umbral_gana"]), "gana"], [float(s["umbral_renida"]), "renida"]]:
		var mm := _fin_campana(datos, 79)
		mm.estado.etapa = "fin_mandato"
		mm.estado.indicadores["aprobacion"] = par[0]
		_check(mm.mandato.sucesion() == String(s["textos"][par[1]]), "con aprobación == %.1f la sucesión es «%s»" % [par[0], par[1]])
		mm.estado.indicadores["aprobacion"] = par[0] - 0.1
		_check(mm.mandato.sucesion() != String(s["textos"][par[1]]), "con aprobación justo bajo %.1f la sucesión ya no es «%s»" % [par[0], par[1]])
	if _fallos == 0:
		print("test_umbrales_exactos: OK")
	quit(1 if _fallos > 0 else 0)
