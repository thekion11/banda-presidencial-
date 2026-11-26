extends SceneTree
## Perfil de un mandato completo: tiempo de cada turno (cartas + cierre + amanecer + eventos) y de cada carta, para encontrar picos y explicarlos.
## Uso: godot --headless --path . -s tests/perfil_turnos.gd -- [partidas=6] [umbral_ms=3.0]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 6
	var umbral := float(args[1]) if args.size() > 1 else 3.0
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var todos: Array[float] = []
	var picos: Array[Dictionary] = []
	for sd in range(n):
		var m := Partida.crear(datos, 700 + sd, GeneradorPartido.construir_partido("P", "PPP", "metropolitana", resp, datos["ideologia"]))
		var rng := RandomNumberGenerator.new()
		rng.seed = 700 + sd
		for _i in range(8):
			Bots.jugar_turno(m, "completo", rng)
			m.terminar_turno()
		Bots.elegir(m, datos, "completo", rng)
		var t := 0
		while m.estado.etapa == "gobierno" and t < 208:
			Bots.jugar_turno(m, "completo", rng)
			var antes_mazo := m.estado.mazo.size()
			var a := Time.get_ticks_usec()
			m.terminar_turno()
			var ms := float(Time.get_ticks_usec() - a) / 1000.0
			todos.append(ms)
			if ms >= umbral:
				var evs: Array[String] = []
				for ev in m.ultimos_eventos:
					evs.append("%s%s" % [String(ev["id"]), "(votación)" if ev.get("votacion", null) != null else ""])
				picos.append({"semilla": 700 + sd, "turno": t, "ms": ms, "eventos": evs, "mazo_antes": antes_mazo, "mazo_despues": m.estado.mazo.size(), "obras": m.estado.obras_en_curso.size(), "proyectos": m.estado.proyectos_ley.size()})
			t += 1
	todos.sort()
	var suma := 0.0
	for x in todos:
		suma += x
	print("PERFIL %d cierres de turno: media %.2f ms, p50 %.2f, p95 %.2f, p99 %.2f, máximo %.2f; picos ≥ %.1f ms: %d" % [todos.size(), suma / float(todos.size()), todos[todos.size() / 2], todos[int(todos.size() * 0.95)], todos[int(todos.size() * 0.99)], todos[todos.size() - 1], umbral, picos.size()])
	picos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["ms"]) > float(b["ms"]))
	for p in picos.slice(0, 10):
		print("PICO semilla %d turno %d: %.1f ms · eventos %s · mazo %d→%d · obras %d · proyectos %d" % [p["semilla"], p["turno"], p["ms"], str(p["eventos"]), p["mazo_antes"], p["mazo_despues"], p["obras"], p["proyectos"]])
	quit()
