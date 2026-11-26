extends SceneTree
## Un partido con números válidos pero absurdos (hallazgo de «Búsqueda infinita de fallas»): ValidarGuardado lo rechaza y el motor, si le llega igual, arranca con los indicadores recortados.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var base := GeneradorPartido.construir_partido("Absurdo", "ABS", "metropolitana", resp, datos["ideologia"])
	_check(ValidarGuardado.partido_valido(JSON.parse_string(JSON.stringify(base))), "un partido real es válido")
	for ind in ["aprobacion", "capital", "cohesion", "fiscal", "riesgo_ejecucion"]:
		for v in [1000000.0, -1000000.0, -1.0, 100.5]:
			var p: Dictionary = JSON.parse_string(JSON.stringify(base))
			p["indicadores_iniciales"][ind] = v
			_check(not ValidarGuardado.partido_valido(p), "%s = %s debe rechazarse" % [ind, v])
	var q: Dictionary = JSON.parse_string(JSON.stringify(base))
	q["indicadores_iniciales"]["viviendas_anio"] = -5.0
	_check(not ValidarGuardado.partido_valido(q), "viviendas_anio negativas se rechazan")
	for k in ["eje_eco", "eje_inst"]:
		var e: Dictionary = JSON.parse_string(JSON.stringify(base))
		e[k] = 7.0
		_check(not ValidarGuardado.partido_valido(e), "%s = 7 se rechaza" % k)
	var n: Dictionary = JSON.parse_string(JSON.stringify(base))
	n["escanos_propios"] = -3
	_check(not ValidarGuardado.partido_valido(n), "escaños negativos se rechazan")
	# el motor se protege aunque la validación se salte
	var abs_p: Dictionary = JSON.parse_string(JSON.stringify(base))
	abs_p["indicadores_iniciales"]["fiscal"] = 1000000.0
	abs_p["indicadores_iniciales"]["capital"] = -1000000.0
	abs_p["indicadores_iniciales"]["riesgo_ejecucion"] = -1.0
	var m := Partida.crear(datos, 4, abs_p)
	var lim: Dictionary = datos["leyes"]["limites_indicadores"]
	_check(m.estado.ind("fiscal") <= float(lim["max"]) + 3.0 and m.estado.ind("capital") >= float(lim["min"]) - 3.0 and m.estado.ind("riesgo_ejecucion") >= float(lim["min"]) - 3.0, "los indicadores arrancan recortados (fiscal %f, capital %f)" % [m.estado.ind("fiscal"), m.estado.ind("capital")])
	print("test_partido_absurdo: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
