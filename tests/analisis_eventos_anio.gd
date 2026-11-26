extends SceneTree
## Ritmo de eventos por año de gobierno con el bot «humano»: semanas sin ningún evento, silencio máximo, eventos y decisiones por año, para distintos parámetros del director.
## Uso: godot --headless --path . -s tests/analisis_eventos_anio.gd -- [partidas=20] ['{"prob_semana":0.55,"silencio_max":6}']   (el JSON reemplaza claves de leyes.json › director_eventos)

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 20
	var over: Dictionary = JSON.parse_string(String(args[1])) if args.size() > 1 else {}
	var datos := Datos.cargar_todo()
	for k in over:
		datos["leyes"]["director_eventos"][k] = over[k]
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Ritmo", "RIT", "metropolitana", resp, datos["ideologia"])
	var sin_evento := [0, 0, 0, 0]
	var semanas := [0, 0, 0, 0]
	var eventos := [0, 0, 0, 0]
	var decisiones := [0, 0, 0, 0]
	var silencio_max := 0
	var partidas := 0
	for i in range(n):
		var m := Partida.crear(datos, 11000 + i, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = 11000 + i
		for _s in range(8):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if not Bots.elegir(m, datos, "codicioso", rng):
			continue
		partidas += 1
		var racha := 0
		var guard := 0
		while m.estado.etapa == "gobierno" and guard < 260:
			guard += 1
			var y := mini(3, (m.estado.turno_actual - 1) / 52)
			semanas[y] += 1
			var evs := m.ultimos_eventos.size()
			eventos[y] += evs
			for ev in m.ultimos_eventos:
				if ev.has("opciones"):
					decisiones[y] += 1
			if evs == 0:
				sin_evento[y] += 1
				racha += 1
				silencio_max = maxi(silencio_max, racha)
			else:
				racha = 0
			Bots.jugar_turno(m, "humano", rng)
			m.terminar_turno()
	var linea := "RITMO %s partidas=%d silencio_max=%d" % [JSON.stringify(over), partidas, silencio_max]
	for y in range(4):
		linea += " | a%d: sin_evento %.0f %% ev/sem %.2f dec/año %.1f" % [y + 1, 100.0 * float(sin_evento[y]) / maxf(1.0, float(semanas[y])), float(eventos[y]) / maxf(1.0, float(semanas[y])), float(decisiones[y]) / maxf(1.0, float(partidas))]
	print(linea)
	quit()
