extends SceneTree
## Piso ideológico (D-BQ): la aprobación (regional y nacional) y el voto no bajan del piso; el piso sube con ideología afín y coalición satisfecha;
## el piso nacional es el promedio ponderado de los regionales; todo es determinista.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO PISO: ", msg)
		_fallos += 1


func _respuestas(datos: Dictionary, i: int) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		r.append(p["opciones"][i])
	return r


func _motor(datos: Dictionary, semilla: int, opcion: int = 1) -> MotorTurno:
	return Partida.crear(datos, semilla, GeneradorPartido.construir_partido("Piso", "PIS", "metropolitana", _respuestas(datos, opcion), datos["ideologia"]))


func _suma_ponderada(m: MotorTurno, pisos: Dictionary) -> float:
	var s := 0.0
	for id in pisos.keys():
		s += float(pisos[id]) * float(m.regiones.pesos[id])
	return s


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["piso_ideologico"]
	_check(float(cfg["tope_nacional"]) == 20.0, "tope del piso nacional = 20 % (decisión del usuario del 27-nov-2026)")

	# 1. Forma: pisos acotados, nacional = promedio ponderado por población
	var m := _motor(datos, 11)
	var pisos: Dictionary = m.piso.pisos()
	_check(pisos.size() == m.regiones.pesos.size(), "hay un piso por región")
	for id in pisos.keys():
		_check(float(pisos[id]) >= 0.0 and float(pisos[id]) <= float(cfg["tope_region"]) + 0.0001, "piso de %s dentro de 0..tope_region (%.2f)" % [id, pisos[id]])
	_check(is_equal_approx(m.piso.nacional(), _suma_ponderada(m, pisos)), "piso nacional = promedio ponderado por población de los regionales")
	_check(m.piso.nacional() <= float(cfg["tope_nacional"]) + 0.0001 and m.piso.nacional() > 0.0, "piso nacional entre 0 y su tope (%.2f)" % m.piso.nacional())
	# crisis medida sobre el piso: umbral = max(umbral base, piso + margen)
	var base_cr := float(datos["leyes"]["dinamica"]["umbral_crisis_aprobacion"])
	_check(is_equal_approx(m.piso.umbral_crisis(base_cr), maxf(base_cr, m.piso.nacional() + float(cfg["crisis_margen_sobre_piso"]))), "umbral de crisis = max(base, piso + margen)")
	var cr := _motor(datos, 11)
	cr.estado.etapa = "gobierno"
	cr.estado.turno_actual = 40
	cr.fx.delta_aprobacion(-100.0, "")  # la aprobación queda en el piso
	var sem := 0
	while cr.estado.etapa == "gobierno" and sem < 10:
		cr.mandato.evaluar_crisis()
		sem += 1
	_check(cr.estado.etapa == "crisis" and sem == int(datos["leyes"]["dinamica"]["semanas_crisis_para_caida"]), "sostenerse en el piso semanas_crisis_para_caida semanas hace caer al gobierno (%d semanas)" % sem)
	var res := m.piso.resumen()
	_check(res["por_region"].size() == 16 and is_equal_approx(float(res["nacional"]), m.piso.nacional()) and is_equal_approx(float(res["voto_duro"]), m.piso.nacional()), "resumen para la interfaz: nacional, voto_duro y 16 regiones")
	_check(float(m.regiones.piso_nacional) >= 0.0 and m.regiones.proveedor_pisos.is_valid(), "Regiones conoce su proveedor de pisos")

	# 2. Determinismo: misma semilla y partido -> mismos pisos; otra semilla -> otra afinidad regional
	var m2 := _motor(datos, 11)
	_check(m2.piso.pisos() == pisos, "misma semilla y partido: mismos pisos")
	var m3 := _motor(datos, 12)
	_check(m3.piso.pisos() != pisos, "otra semilla: otra afinidad regional")

	# 3. El piso sube con ideología afín (misma distancia al centro, distinta región afín)
	var region := ""
	var mejor := 0.0
	for id in pisos.keys():
		if absf(m.piso.inclinacion(String(id))) > mejor and String(id) != String(m.estado.partido["region_bastion"]):
			mejor = absf(m.piso.inclinacion(String(id)))
			region = String(id)
	var signo := 1.0 if m.piso.inclinacion(region) > 0.0 else -1.0
	var ma := _motor(datos, 11)
	var mb := _motor(datos, 11)
	ma.estado.partido["eje_eco"] = 0.5 * signo
	mb.estado.partido["eje_eco"] = -0.5 * signo
	_check(ma.piso.afinidad(region) > mb.piso.afinidad(region), "la afinidad es mayor con la inclinación de la región")
	_check(float(ma.piso.pisos()[region]) > float(mb.piso.pisos()[region]), "con ideología afín el piso de la región sube (%.2f > %.2f)" % [ma.piso.pisos()[region], mb.piso.pisos()[region]])

	# 4. El piso sube con la coalición satisfecha y cohesionada
	var mc := _motor(datos, 11)
	mc.unirse_coalicion("laborismo_austral")
	mc.unirse_coalicion("compromiso_civico")
	mc.estado.coalicion["laborismo_austral"]["satisfaccion"] = 20.0
	mc.estado.coalicion["compromiso_civico"]["satisfaccion"] = 20.0
	mc.estado.indicadores["cohesion"] = 90.0
	var bajo := mc.piso.nacional()
	mc.estado.coalicion["laborismo_austral"]["satisfaccion"] = 95.0
	mc.estado.coalicion["compromiso_civico"]["satisfaccion"] = 95.0
	var alto := mc.piso.nacional()
	_check(alto > bajo, "coalición satisfecha sube el piso nacional (%.2f > %.2f)" % [alto, bajo])
	mc.estado.indicadores["cohesion"] = 10.0
	_check(mc.piso.nacional() < alto, "la cohesión baja el piso")
	# más extremo y bancada más grande -> piso mayor que un partido de centro
	var centro := _motor(datos, 11)
	centro.estado.partido["eje_eco"] = 0.0
	centro.estado.partido["eje_inst"] = 0.0
	var extremo := _motor(datos, 11)
	extremo.estado.partido["eje_eco"] = 0.9
	extremo.estado.partido["eje_inst"] = 0.9
	_check(extremo.piso.nacional() != centro.piso.nacional(), "la posición en los ejes cambia el piso")
	# la región bastión tiene bono
	var sin_b := _motor(datos, 11)
	var con_b := _motor(datos, 11)
	sin_b.estado.partido["region_bastion"] = ""
	_check(float(con_b.piso.pisos()["metropolitana"]) >= float(sin_b.piso.pisos()["metropolitana"]), "el bastión no baja su piso")

	# 5. La aprobación nunca baja del piso: cartas, reversión y golpes directos
	var g := _motor(datos, 21)
	g.estado.etapa = "gobierno"
	g.estado.turno_actual = 40  # sin luna de miel
	g.fx.delta_aprobacion(-100.0, "")
	var p := g.piso.pisos()
	var ok_reg := true
	for id in p.keys():
		ok_reg = ok_reg and float(g.estado.aprobacion_regional[id]) >= float(p[id]) - 0.0001
	_check(ok_reg, "una caída brusca no cruza el piso regional")
	_check(g.estado.ind("aprobacion") >= g.piso.nacional() - 0.0001, "la aprobación nacional no baja del piso nacional (%.2f >= %.2f)" % [g.estado.ind("aprobacion"), g.piso.nacional()])
	_check(g.regiones.piso_frenado > 0.0, "el piso registra cuánta caída evitó")
	var motivo_ok := false
	for f in g.motivos_semana():
		motivo_ok = motivo_ok or String(f["causa"]) == String(cfg["texto_motivo"])
	_check(motivo_ok, "motivos_semana explica el piso («%s»)" % cfg["texto_motivo"])
	g.fx.sumar_ind("aprobacion", -100.0)
	_check(g.estado.ind("aprobacion") >= g.piso.nacional() - 0.0001, "sumar_ind tampoco baja del piso nacional")
	g.estado.indicadores["fiscal"] = 0.0
	g.estado.indicadores["cohesion"] = 0.0
	g.estado.indicadores["capital"] = 0.0
	for _i in range(60):
		g.regiones.revertir(g.estado, 0.0, 0.5, 0.0)
		var ps := g.piso.pisos()
		for id in ps.keys():
			ok_reg = ok_reg and float(g.estado.aprobacion_regional[id]) >= float(ps[id]) - 0.0001
	_check(ok_reg and g.estado.ind("aprobacion") >= g.piso.nacional() - 0.0001, "la reversión hacia un ancla en 0 no cruza el piso")
	# un piso que sube levanta a quien quedó debajo en la siguiente operación
	g.estado.coalicion["laborismo_austral"] = {"satisfaccion": 100.0, "ministros": [], "asesores": []}
	g.estado.indicadores["cohesion"] = 100.0
	g.fx.delta_aprobacion(0.0, "")
	var ps2 := g.piso.pisos()
	for id in ps2.keys():
		ok_reg = ok_reg and float(g.estado.aprobacion_regional[id]) >= float(ps2[id]) - 0.0001
	_check(ok_reg, "si el piso sube, la aprobación lo alcanza")
	# partida pasiva completa en gobierno: nunca bajo el piso al cierre de cada semana
	var h := AyudaV2.gobierno(datos, 33)
	h.estado.partido = m.estado.partido.duplicate(true)
	h.estado.turno_actual = 30
	var viola := 0
	for _s in range(40):
		h.fx.delta_aprobacion(-3.0, "")
		h.iniciar_turno()
		var pp := h.piso.pisos()
		for id in pp.keys():
			if float(h.estado.aprobacion_regional[id]) < float(pp[id]) - 0.0001:
				viola += 1
		h.cerrar_turno()
		if h.estado.etapa != "gobierno":
			break
	_check(viola == 0, "40 semanas de golpes: ninguna región cruzó el piso (%d violaciones)" % viola)

	# 6. Elección: voto_i >= piso_i; voto duro + blando = voto
	var e := _motor(datos, 5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(e, "pasivo", rng)
		e.terminar_turno()
	e.fx.delta_aprobacion(-100.0, "")  # una campaña desastrosa
	var pe := e.piso.pisos()
	var r := e.resolver_eleccion_presidencial()
	var det := e.estado.ultima_eleccion
	_check(bool(r["ok"]) and det["regiones"].size() == 16, "la elección entrega el detalle por región")
	for f in det["regiones"]:
		_check(float(f["voto"]) >= float(pe[f["id"]]) - 0.0001, "voto de %s no baja de su piso (%.2f >= %.2f)" % [f["id"], f["voto"], pe[f["id"]]])
		_check(is_equal_approx(float(f["voto_duro"]) + float(f["voto_blando"]), float(f["voto"])), "voto duro + blando = voto en %s" % f["id"])
		_check(float(f["voto_blando"]) >= 0.0 and is_equal_approx(float(f["voto_duro"]), minf(float(pe[f["id"]]), float(f["voto"]))), "el voto duro de %s es su piso" % f["id"])
	_check(float(r["voto_final"]) >= e.piso.nacional() - 0.0001, "el voto nacional no baja del piso nacional")
	_check(is_equal_approx(float(det["voto_duro_nacional"]) + float(det["voto_blando_nacional"]), float(det["voto_final"])), "voto duro + blando nacional = voto final")
	_check(float(det["voto_duro_nacional"]) > 0.0, "hay voto duro nacional")
	print("test_piso_ideologico: piso nacional %.2f (regiones %.1f..%.1f), %s" % [m.piso.nacional(), pisos.values().min(), pisos.values().max(), "OK" if _fallos == 0 else "FALLOS %d" % _fallos])
	quit(1 if _fallos > 0 else 0)
