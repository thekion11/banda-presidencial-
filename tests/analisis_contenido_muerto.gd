extends SceneTree
## Contenido que nunca se usa: eventos que nunca se disparan, cartas que nunca llegan a la mano o nunca se juegan y leyes que nunca se votan, en N mandatos completos (facil/normal)
## más algunas carreras con derrota para ver la oposición. Imprime líneas «MUERTO» con el motivo probable (condición, ventana, etapa).
## Uso: godot --headless --path . -s tests/analisis_contenido_muerto.gd -- [partidas=45]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 45
	var datos := Datos.cargar_todo()
	var eventos_vistos := {}
	var cartas_vistas := {}
	var cartas_jugadas := {}
	var leyes_votadas := {}
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partidas_gob := 0
	var politicas := ["humano", "completo", "codicioso"]
	for i in range(n):
		var partido := GeneradorPartido.construir_partido("Muerto", "MUE", "metropolitana", resp, datos["ideologia"])
		partido["dificultad"] = "facil" if i % 2 == 0 else "normal"
		var pol: String = politicas[i % 3]
		var m := Partida.crear(datos, 13000 + i, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = 13000 + i
		var est := m.estado
		var derrota_a_proposito := i % 9 == 8  # algunas carreras pierden la campaña para recorrer la oposición y el ciclo siguiente
		var guard := 0
		while guard < 700:
			guard += 1
			if est.etapa == "campana" and est.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
				if not Bots.elegir(m, datos, pol, rng):
					if est.etapa == "derrota_electoral" and est.ciclo < 3 and bool(m.continuar_carrera().get("ok", false)):
						m.iniciar_turno()
						continue
					break
				partidas_gob += 1
				continue
			if not MotorTurno.ETAPAS_JUEGO.has(est.etapa):
				break
			for c in est.mano:
				cartas_vistas[String(c["id"])] = true
			for ev in m.ultimos_eventos:
				eventos_vistos[String(ev["id"])] = true
			if derrota_a_proposito and est.etapa == "campana":
				m.terminar_turno()
				continue
			Bots.jugar_turno(m, pol, rng)
			for c in est.mano:
				cartas_vistas[String(c["id"])] = true
			m.terminar_turno()
		for a in est.registro_acciones:
			if a["tipo"] == "carta":
				cartas_jugadas[String(a["detalle"]["id"])] = true
			elif a["tipo"] == "votacion":
				leyes_votadas[String(a["detalle"]["carta"])] = true
		for id in est.eventos_ocurridos.keys():
			eventos_vistos[String(id)] = true
	print("MUERTO resumen: %d partidas con gobierno de %d; eventos vistos %d de %d; cartas vistas %d, jugadas %d de %d; leyes votadas %d" % [partidas_gob, n, eventos_vistos.size(), datos["eventos"].size(), cartas_vistas.size(), cartas_jugadas.size(), datos["cartas"].size(), leyes_votadas.size()])
	var nunca_ev := []
	for e in datos["eventos"]:
		if not eventos_vistos.has(String(e["id"])):
			var motivo := "etapa %s" % String(e.get("etapa", "?"))
			if e.has("requiere"):
				motivo += " · requiere " + JSON.stringify(e["requiere"])
			if e.has("meses"):
				motivo += " · meses " + str(e["meses"])
			if e["tipo"] == "programado":
				motivo += " · programado día %s" % str(e.get("dia_objetivo"))
			nunca_ev.append("%s (%s)" % [e["id"], motivo])
	print("MUERTO eventos nunca disparados: %d" % nunca_ev.size())
	for x in nunca_ev:
		print("MUERTO evento ", x)
	var idx := IndicesCartas.construir(datos["cartas"])
	var sin_ver := {"diseniadas": [], "curadas": 0, "reales": 0}
	var sin_jugar_dis := []
	var por_disp := {}
	var reales_sin_ver_por_disp := {}
	for c in datos["cartas"]:
		var id := String(c["id"])
		var real: bool = idx.es_real[id]
		var disp := JSON.stringify(c.get("disponibilidad", null))
		if not cartas_vistas.has(id):
			if real:
				sin_ver["reales"] += 1
				var clave := "sin condición" if c.get("disponibilidad", null) == null else String((c["disponibilidad"] as Dictionary).keys()[0])
				reales_sin_ver_por_disp[clave] = int(reales_sin_ver_por_disp.get(clave, 0)) + 1
			elif id.begins_with("cur_"):
				sin_ver["curadas"] += 1
				print("MUERTO carta curada nunca en mano: %s · %s · %s" % [id, c["categoria"], disp])
			else:
				(sin_ver["diseniadas"] as Array).append("%s (%s · %s)" % [id, c["categoria"], disp])
		elif not cartas_jugadas.has(id) and not real:
			sin_jugar_dis.append(id)
	print("MUERTO cartas diseñadas nunca en mano: %d" % (sin_ver["diseniadas"] as Array).size())
	for x in sin_ver["diseniadas"]:
		print("MUERTO carta ", x)
	print("MUERTO cartas curadas nunca en mano: %d; reales nunca en mano: %d (por condición: %s)" % [sin_ver["curadas"], sin_ver["reales"], JSON.stringify(reales_sin_ver_por_disp)])
	print("MUERTO cartas diseñadas o curadas vistas pero nunca jugadas: %d %s" % [sin_jugar_dis.size(), str(sin_jugar_dis.slice(0, 40))])
	quit()
