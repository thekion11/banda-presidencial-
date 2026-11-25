extends SceneTree
## Ritmo de eventos (Fase A): pocos eventos por semana, decisiones espaciadas y sin repeticiones cercanas. Mide con bots y falla si se rompe.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var por_id := {}
	for e in datos["eventos"]:
		por_id[String(e["id"])] = e
	var cfg: Dictionary = datos["leyes"]["director_eventos"]
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("R", "RRR", "metropolitana", resp, datos["ideologia"])
	var semanas := 0
	var eventos := 0
	var decisiones := 0
	var vistos := {}
	var mandatos := 0
	for s in range(6):
		var m := Partida.crear(datos, 500 + s, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = 500 + s
		for _i in range(8):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if not Bots.elegir(m, datos, "codicioso", rng):
			continue
		mandatos += 1
		var ultimo_ev := {}  # id -> semana
		var ultimo_fam := {}
		var ultima_dec := -99
		while m.estado.etapa == "gobierno":
			Bots.jugar_turno(m, "codicioso", rng)
			var semana := m.estado.turno_actual
			var evs := m.ultimos_eventos
			semanas += 1
			var aleatorios := 0
			for ev in evs:
				var d: Dictionary = por_id[String(ev["id"])]
				eventos += 1
				vistos[String(ev["id"])] = true
				if d["tipo"] != "aleatorio_semilla":
					continue
				aleatorios += 1
				if d.has("opciones"):
					decisiones += 1
					_check(semana - ultima_dec >= int(cfg["cooldown_decision"]), "decisiones espaciadas (semana %d)" % semana)
					ultima_dec = semana
				_check(not ultimo_ev.has(d["id"]) or semana - int(ultimo_ev[d["id"]]) >= int(cfg["cooldown_evento"]), "%s no se repite antes de %d semanas" % [d["id"], int(cfg["cooldown_evento"])])
				_check(not ultimo_fam.has(d["familia"]) or semana - int(ultimo_fam[d["familia"]]) >= int(cfg["cooldown_familia"]), "familia %s con descanso" % d["familia"])
				ultimo_ev[d["id"]] = semana
				ultimo_fam[d["familia"]] = semana
			_check(aleatorios <= 1, "como máximo un evento aleatorio por semana")
			m.terminar_turno()
	_check(mandatos >= 3 and semanas > 0, "se midieron suficientes mandatos (%d)" % mandatos)
	var ev_sem := float(eventos) / float(maxi(1, semanas))
	var dec_mand := float(decisiones) / float(maxi(1, semanas)) * 208.0  # por mandato completo (208 semanas)
	print("mandatos %d · eventos por semana %.2f · decisiones por mandato %.0f · eventos distintos %d" % [mandatos, ev_sem, dec_mand, vistos.size()])
	_check(ev_sem <= 1.0, "eventos por semana ≤ 1,0 (%.2f)" % ev_sem)
	_check(dec_mand >= 25.0 and dec_mand <= 70.0, "decisiones por mandato entre 25 y 70 (%.0f)" % dec_mand)
	_check(vistos.size() >= 40, "variedad: al menos 40 eventos distintos (%d)" % vistos.size())
	print("test_ritmo: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
