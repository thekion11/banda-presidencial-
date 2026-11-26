extends SceneTree
## Ritmo y tedio: partidas del bot «humano» por afiliación; distribución semanal de los indicadores y semanas «sin nada interesante» (sin evento, sin decisión y con
## la mano casi sin cartas buenas o con recursos saturados). Uso: godot --headless --path . -s tests/analisis_ritmo_decisiones.gd -- [partidas_por_afiliacion=20]

func _pct(v: Array, p: float) -> float:
	if v.is_empty():
		return 0.0
	var s := v.duplicate()
	s.sort()
	return float(s[mini(s.size() - 1, int(float(s.size()) * p))])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 20
	var datos := Datos.cargar_todo()
	var cfg_af: Dictionary = datos["leyes"]["afiliacion"]
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var anios := {}  # año -> {ind -> [valores]}
	var tedio := {"semanas": 0, "sin_evento": 0, "sin_evento_ni_buena": 0, "saturadas": 0, "sin_buena": 0, "con_decision": 0}
	var por_anio_tedio := {}
	var jugadas := 0
	for afil in ["propio", "independiente", "existente"]:
		for i in range(n):
			var sd := 3000 + i
			var base: Dictionary = datos["coalicion"][i % datos["coalicion"].size()] if afil == "existente" else {}
			var partido := GeneradorPartido.construir_partido_afiliado(afil, base, "R", "RRR", "metropolitana", resp.slice(0, 3) if afil == "existente" else resp, datos["ideologia"], cfg_af)
			var m := Partida.crear(datos, sd, partido)
			var rng := RandomNumberGenerator.new()
			rng.seed = sd
			for _s in range(8):
				Bots.jugar_turno(m, "humano", rng)
				m.terminar_turno()
			if not Bots.elegir(m, datos, "humano", rng):
				continue
			jugadas += 1
			var t := 0
			while m.estado.etapa == "gobierno" and t < 208:
				var e := m.estado
				var anio := t / 52 + 1
				anios[anio] = anios.get(anio, {"aprobacion": [], "capital": [], "cohesion": [], "fiscal": []})
				for k in ["aprobacion", "capital", "cohesion", "fiscal"]:
					anios[anio][k].append(e.ind(k))
				var evs := 0
				var dec := 0
				for ev in m.ultimos_eventos:
					if not ev.get("menor", false):
						evs += 1
						if ev.has("opciones"):
							dec += 1
				var buenas := 0
				for c in e.mano:
					if Bots._valor(c, e) >= 0.5 and m.costo_carta(c) <= e.pa_actual:
						buenas += 1
				var sat := e.ind("capital") >= 95.0 or e.ind("fiscal") >= 95.0 or e.ind("cohesion") >= 95.0
				tedio["semanas"] += 1
				por_anio_tedio[anio] = por_anio_tedio.get(anio, [0, 0])
				por_anio_tedio[anio][0] += 1
				if evs == 0:
					tedio["sin_evento"] += 1
				if dec > 0:
					tedio["con_decision"] += 1
				if buenas == 0:
					tedio["sin_buena"] += 1
				if sat:
					tedio["saturadas"] += 1
				if evs == 0 and buenas <= 1:
					tedio["sin_evento_ni_buena"] += 1
					por_anio_tedio[anio][1] += 1
				Bots.jugar_turno(m, "humano", rng)
				m.terminar_turno()
				t += 1
	print("RITMO %d partidas con gobierno (humano, 3 afiliaciones)" % jugadas)
	for a in anios.keys():
		var f := "RITMO año %d:" % a
		for k in ["aprobacion", "capital", "cohesion", "fiscal"]:
			f += "  %s p10 %.0f · mediana %.0f · p90 %.0f" % [k.substr(0, 5), _pct(anios[a][k], 0.1), _pct(anios[a][k], 0.5), _pct(anios[a][k], 0.9)]
		print(f)
	var tot := float(tedio["semanas"])
	print("RITMO semanas sin evento %.0f %% · con decisión %.0f %% · mano sin carta buena %.0f %% · recursos saturados (≥ 95) %.0f %% · sin evento y ≤ 1 carta buena %.0f %%" % [100.0 * tedio["sin_evento"] / tot, 100.0 * tedio["con_decision"] / tot, 100.0 * tedio["sin_buena"] / tot, 100.0 * tedio["saturadas"] / tot, 100.0 * tedio["sin_evento_ni_buena"] / tot])
	for a in por_anio_tedio.keys():
		print("RITMO año %d: semanas «sin nada interesante» %.0f %%" % [a, 100.0 * por_anio_tedio[a][1] / maxf(1.0, float(por_anio_tedio[a][0]))])
	quit()
