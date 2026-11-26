extends SceneTree
## Cartas muertas: qué cartas aparecen en la mano pero casi nunca se juegan (con la política «humano» y un parámetro de dificultad).
## Uso: godot --headless --path . -s tests/analisis_cartas_muertas.gd -- [partidas=20] [dificultad=dificil] [politica=humano]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 20
	var dif := String(args[1]) if args.size() > 1 else "dificil"
	var pol := String(args[2]) if args.size() > 2 else "humano"
	var datos := Datos.cargar_todo()
	var vistas := {}  # id -> turnos en que estuvo en la mano al empezar
	var jugadas := {}
	var por_id := {}
	for c in datos["cartas"]:
		por_id[String(c["id"])] = c
	var gobierno_turnos := 0
	for sd in range(n):
		var resp: Array[Dictionary] = []
		var rr := RandomNumberGenerator.new()
		rr.seed = sd
		for p in datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rr.randi_range(0, 2)])
		var partido := GeneradorPartido.construir_partido("P", "PPP", "metropolitana", resp, datos["ideologia"])
		partido["dificultad"] = dif
		var m := Partida.crear(datos, 900 + sd, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = 900 + sd
		for _i in range(8):
			Bots.jugar_turno(m, pol, rng)
			m.terminar_turno()
		if not Bots.elegir(m, datos, pol, rng):
			continue
		var t := 0
		while m.estado.etapa == "gobierno" and t < 208:
			gobierno_turnos += 1
			for c in m.estado.mano:
				vistas[String(c["id"])] = int(vistas.get(String(c["id"]), 0)) + 1
			var a0 := m.estado.registro_acciones.size()
			Bots.jugar_turno(m, pol, rng)
			for i in range(a0, m.estado.registro_acciones.size()):
				var r: Dictionary = m.estado.registro_acciones[i]
				if r["tipo"] == "carta":
					jugadas[String(r["detalle"]["id"])] = int(jugadas.get(String(r["detalle"]["id"]), 0)) + 1
			m.terminar_turno()
			t += 1
	# por categoría y por tipo de carta (diseñada / curada / real)
	var cat := {}
	var tipo := {}
	for id in vistas.keys():
		var c: Dictionary = por_id[id]
		var t2 := "real" if IndicesCartas.tipo_real(c) else ("curada" if c.get("curada", false) else "diseñada")
		var k := String(c["categoria"])
		cat[k] = cat.get(k, [0, 0])
		cat[k][0] += int(vistas[id])
		cat[k][1] += int(jugadas.get(id, 0))
		tipo[t2] = tipo.get(t2, [0, 0, 0])
		tipo[t2][0] += int(vistas[id])
		tipo[t2][1] += int(jugadas.get(id, 0))
		tipo[t2][2] += 1
	print("MUERTAS %d partidas (%s, %s), %d turnos de gobierno, %d cartas distintas vistas" % [n, pol, dif, gobierno_turnos, vistas.size()])
	for t3 in tipo.keys():
		print("TIPO %-9s cartas vistas %4d · apariciones %6d · jugadas %6d (%.0f %%)" % [t3, tipo[t3][2], tipo[t3][0], tipo[t3][1], 100.0 * tipo[t3][1] / maxf(1.0, float(tipo[t3][0]))])
	var ks: Array = cat.keys()
	ks.sort_custom(func(a: String, b: String) -> bool: return float(cat[a][1]) / maxf(1.0, float(cat[a][0])) < float(cat[b][1]) / maxf(1.0, float(cat[b][0])))
	for k in ks:
		print("CAT %-16s apariciones %6d · jugadas %6d (%.0f %%)" % [k, cat[k][0], cat[k][1], 100.0 * cat[k][1] / maxf(1.0, float(cat[k][0]))])
	var muertas: Array = []
	for id in vistas.keys():
		var c2: Dictionary = por_id[id]
		if not IndicesCartas.tipo_real(c2) and int(vistas[id]) >= 12 and int(jugadas.get(id, 0)) == 0:
			muertas.append("%s (%s, costo %d, vista %d veces)" % [id, c2["categoria"], int(c2["costo_pa"]), int(vistas[id])])
	print("MUERTAS diseñadas/curadas vistas ≥ 12 veces y nunca jugadas: %d" % muertas.size())
	for x in muertas.slice(0, 25):
		print("  ", x)
	quit()
