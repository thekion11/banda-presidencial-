extends SceneTree
## Bono de movimientos por aprobación (§11), reposición de cartas (§12) y asesores (§9).

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO EQUIPO: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var m := AyudaV2.gobierno(datos, 41)
	var est := m.estado
	# bono por aprobación: +1 por cada umbral superado (45, 55, 65, 75, 85, 95)
	var esperado := {40.0: 0, 44.9: 0, 45.0: 1, 54.0: 1, 55.0: 2, 64.9: 2, 65.0: 3, 75.0: 4, 85.0: 5, 95.0: 6, 100.0: 6}
	for apr in esperado.keys():
		est.indicadores["aprobacion"] = apr
		_check(m.movimientos.bono_aprobacion() == int(esperado[apr]), "bono a %.1f%% = %d (da %d)" % [apr, esperado[apr], m.movimientos.bono_aprobacion()])
	est.indicadores["aprobacion"] = 70.0
	m.ejecutar_amanecer()
	_check(est.pa_actual == est.pa_maximo + int(est.bono_mov["aprobacion"]) + int(est.bono_mov["asesores"]), "el amanecer fija los movimientos (base + bono + asesores)")
	_check(int(est.bono_mov["aprobacion"]) > 0, "con aprobación alta hay bono de movimientos")
	# asesores
	_check(String(m.contratar_asesor("no_existe")["razon"]) == "asesor_inexistente", "asesor inexistente")
	var ids: Array = datos["asesores"].map(func(a: Dictionary) -> String: return String(a["id"]))
	_check(ids.size() >= 10, "catálogo de ~10 asesores")
	for i in range(3):
		_check(bool(m.contratar_asesor(ids[i])["ok"]), "contrata asesor %d" % i)
	_check(String(m.contratar_asesor(ids[3])["razon"]) == "limite_asesores", "máximo 3 asesores")
	_check(String(m.contratar_asesor(ids[0])["razon"]) == "ya_contratado", "no se repite")
	_check(bool(m.despedir_asesor(ids[2])["ok"]) and est.asesores.size() == 2, "despedir libera un cupo")
	_check(String(m.despedir_asesor(ids[2])["razon"]) == "no_contratado", "despedir a quien no está")
	var antes := est.pa_actual
	est.indicadores["aprobacion"] = 50.0
	m.ejecutar_amanecer()
	_check(int(est.bono_mov["asesores"]) == 2 and est.pa_actual == est.pa_maximo + 2 + int(est.bono_mov["aprobacion"]), "cada asesor da +1 movimiento por turno (%d -> %d)" % [antes, est.pa_actual])
	# efectos: multiplicador de categoría (asesor economista -> hacienda) e indicadores por turno
	var m2 := AyudaV2.gobierno(datos, 42)
	m2.contratar_asesor("as_economista")
	_check(m2.equipo.mult_categoria("hacienda") > 1.0 and is_equal_approx(m2.equipo.mult_categoria("salud"), 1.0), "el asesor mejora su sector")
	var m3 := AyudaV2.gobierno(datos, 43)
	m3.contratar_asesor("as_legislativo")
	var cap := m3.estado.ind("capital")
	var apr := m3.estado.ind("aprobacion")
	var m3b := AyudaV2.gobierno(datos, 43)
	m3b.ejecutar_amanecer()
	m3.ejecutar_amanecer()
	_check(m3.estado.ind("capital") > m3b.estado.ind("capital") and m3.estado.ind("aprobacion") < m3b.estado.ind("aprobacion"), "efecto positivo (capital) y negativo (aprobación) por turno")
	_check(cap >= 0.0 and apr >= 0.0, "indicadores válidos")
	# la afinidad ideológica atenúa el efecto negativo
	m3.estado.partido = {"eje_eco": 0.0, "eje_inst": 0.4}
	var af_cerca := m3.equipo.afinidad("as_legislativo")
	m3.estado.partido = {"eje_eco": -1.0, "eje_inst": -1.0}
	_check(af_cerca > m3.equipo.afinidad("as_legislativo") and is_equal_approx(af_cerca, 1.0), "afinidad ideológica por distancia en ejes")
	# reposición: mano vacía con movimientos -> entran cartas disponibles y se registra la acción
	var d2 := datos.duplicate(true)
	d2["leyes"]["mano"]["reales_en_mazo"] = 0
	var reales: Array = []
	for i in range(4):
		var c := AyudaV2.carta_sintetica("t_real_%d" % i, "politica", {})
		c.erase("disponibilidad")
		c["meta"] = {"tipo": "proyecto_publico"}
		reales.append(c)
	d2["cartas"] = reales
	var m4 := AyudaV2.gobierno(d2, 44)
	m4.estado.mano.append(m4._cartas_por_id["t_real_0"])
	_check(m4.estado.mano.size() == 1, "mano preparada con una carta")
	_check(bool(m4.jugar_carta(0)["ok"]), "se juega la última carta")
	var rep := m4.estado.registro_acciones.filter(func(a: Dictionary) -> bool: return a["tipo"] == "reposicion")
	_check(rep.size() == 1 and rep[0]["detalle"]["ids"].size() == 3 and m4.estado.mano.size() == 3, "reposición: entran %d cartas y se registra" % m4.estado.mano.size())
	var g: Dictionary = JSON.parse_string(JSON.stringify(est.exportar_guardado("")))
	_check(g["entradas"].any(func(e: Dictionary) -> bool: return e["tipo"] == "asesor"), "el guardado registra la entrada asesor")
	# replay con asesores
	var h := Datos.huella(datos)
	var resp: Array[Dictionary] = []
	for q in datos["ideologia"]["preguntas"]:
		resp.append(q["opciones"][1])
	var mp := Partida.crear(datos, 45, GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, datos["ideologia"]))
	mp.contratar_asesor("as_comunicador")
	mp.contratar_asesor("as_jurista")
	mp.despedir_asesor("as_jurista")
	var rng := RandomNumberGenerator.new()
	rng.seed = 45
	for _i in range(3):
		Bots.jugar_turno(mp, "codicioso", rng)
		mp.terminar_turno()
	var gp: Dictionary = JSON.parse_string(JSON.stringify(mp.estado.exportar_guardado(h)))
	var rp := Partida.reproducir(datos, gp)
	_check(rp.estado.asesores == mp.estado.asesores and rp.estado.calcular_huella() == mp.estado.calcular_huella(), "replay idéntico con asesores")
	print("EQUIPO OK" if _fallos == 0 else "EQUIPO FALLÓ")
	quit(1 if _fallos > 0 else 0)
