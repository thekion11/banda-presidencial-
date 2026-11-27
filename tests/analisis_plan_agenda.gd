extends SceneTree
## Informe (no CI): las 16 cartas plan_* presentadas por la agenda legislativa en la semana 26 de gobierno. Cada carta se compara con la misma partida sin presentarla
## (mismo guardado repetido, después solo se termina la semana) a las 52 y 78 semanas: aprobación, fiscal, capital, cohesión y riesgo; y cuántas veces se promulga.
## Uso: godot --headless --path . -s tests/analisis_plan_agenda.gd -- [semillas]

const INDS := ["aprobacion", "fiscal", "capital", "cohesion", "riesgo_ejecucion"]


func _guardado(datos: Dictionary, semilla: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla * 31 + 7
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][rng.randi_range(0, 2)])
	var partido := GeneradorPartido.construir_partido("Partido Prueba", "PRU", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, semilla, partido)
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	if not Bots.elegir(m, datos, "codicioso", rng):
		return {}
	for _s in range(26):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	return JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(Datos.huella(datos))))


func _correr(datos: Dictionary, g: Dictionary, carta: String, urg: String) -> Dictionary:
	var m := Partida.reproducir(datos, g)
	m.estado.proyectos_ley.clear()  # las leyes de la mano que siguen en trámite llenan el cupo de 3 de la agenda (hallazgo): se quitan en ambas ramas para aislar la carta
	var r := {"razon": ""}
	if carta != "":
		var p := m.agenda.presentar(carta, urg)
		if not bool(p["ok"]):
			r["razon"] = String(p["razon"])
			return r
	var res := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for sem in range(1, 79):
		if m.estado.etapa == "gobierno":  # tras una crisis los indicadores quedan donde cayeron
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if sem == 52 or sem == 78:
			res[sem] = {}
			for k in INDS:
				res[sem][k] = m.estado.ind(k)
	r["res"] = res
	r["promulgada"] = carta != "" and m.estado.cartas_ejecutadas.has(carta)
	return r


func _init() -> void:
	var n := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 10
	var datos := Datos.cargar_todo()
	var guardados: Array[Dictionary] = []
	for s in range(1, 40):
		if guardados.size() >= n:
			break
		var g := _guardado(datos, s)
		if not g.is_empty():
			guardados.append(g)
	var ids: Array[String] = []
	for c in datos["cartas"]:
		if String(c["id"]).begins_with("plan_"):
			ids.append(String(c["id"]))
	var base: Array[Dictionary] = []
	for g in guardados:
		base.append(_correr(datos, g, "", "simple"))
	print("PLAN partidas=%d cartas=%d (delta contra la misma partida sin presentar; semanas 52 y 78 después de presentar; urgencia simple)" % [guardados.size(), ids.size()])
	for id in ids:
		var acc := {52: {}, 78: {}}
		var vivas := 0
		var prom := 0
		var bloq := {}
		for i in range(guardados.size()):
			var r := _correr(datos, guardados[i], id, "simple")
			if r["razon"] != "":
				bloq[r["razon"]] = int(bloq.get(r["razon"], 0)) + 1
				continue
			if not (r["res"].has(52) and r["res"].has(78) and base[i]["res"].has(78)):
				continue
			vivas += 1
			prom += 1 if bool(r["promulgada"]) else 0
			for sem in [52, 78]:
				for k in INDS:
					acc[sem][k] = float(acc[sem].get(k, 0.0)) + float(r["res"][sem][k]) - float(base[i]["res"][sem][k])
		var linea := "PLAN %-26s presentadas=%d promulgadas=%d" % [id, vivas, prom]
		for sem in [52, 78]:
			linea += " | s%d:" % sem
			for k in INDS:
				linea += " %s %+.1f" % [k.left(4), float(acc[sem].get(k, 0.0)) / maxf(1.0, float(vivas))]
		if not bloq.is_empty():
			linea += " | bloqueadas " + str(bloq)
		print(linea)
	quit()
