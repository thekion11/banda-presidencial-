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
	var max_silencio := 0
	var max_dec_anio := 0
	var meses_ok := true
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
		var ult_any := 0
		var decs: Array[int] = []
		while m.estado.etapa == "gobierno":
			Bots.jugar_turno(m, "codicioso", rng)
			var semana := m.estado.turno_actual
			var evs := m.ultimos_eventos
			semanas += 1
			var aleatorios := 0
			for ev in evs:
				if ev.get("menor", false):
					continue  # consecuencia de una carta: aviso breve, no cuenta como evento
				eventos += 1
				ult_any = semana
				vistos[String(ev["id"])] = true
				if not por_id.has(String(ev["id"])):
					continue  # consecuencia diferida de una decisión (pantalla aparte, sin ficha en el catálogo)
				var d: Dictionary = por_id[String(ev["id"])]
				if d["tipo"] != "aleatorio_semilla":
					continue
				aleatorios += 1
				if d.has("opciones"):
					decisiones += 1
					decs.append(semana)
					_check(semana - ultima_dec >= int(cfg["cooldown_decision"]), "decisiones espaciadas (semana %d)" % semana)
					ultima_dec = semana
				_check(not ultimo_ev.has(d["id"]) or semana - int(ultimo_ev[d["id"]]) >= int(cfg["cooldown_evento"]), "%s no se repite antes de %d semanas" % [d["id"], int(cfg["cooldown_evento"])])
				_check(not ultimo_fam.has(d["familia"]) or semana - int(ultimo_fam[d["familia"]]) >= int(cfg["cooldown_familia"]), "familia %s con descanso" % d["familia"])
				ultimo_ev[d["id"]] = semana
				ult_any = semana
				ultimo_fam[d["familia"]] = semana
			max_silencio = maxi(max_silencio, semana - ult_any)
			_check(aleatorios <= 1, "como máximo un evento aleatorio por semana")
			m.terminar_turno()
		for i in range(decs.size()):
			var n := 0
			for j in range(i, decs.size()):
				if decs[j] - decs[i] < 52:
					n += 1
			max_dec_anio = maxi(max_dec_anio, n)
	_check(mandatos >= 3 and semanas > 0, "se midieron suficientes mandatos (%d)" % mandatos)
	var ev_sem := float(eventos) / float(maxi(1, semanas))
	var dec_mand := float(decisiones) / float(maxi(1, semanas)) * 208.0  # por mandato completo (208 semanas)
	print("mandatos %d · eventos por semana %.2f · decisiones por mandato %.0f · eventos distintos %d" % [mandatos, ev_sem, dec_mand, vistos.size()])
	_check(ev_sem <= 1.0, "eventos por semana ≤ 1,0 (%.2f)" % ev_sem)
	_check(dec_mand >= 25.0 and dec_mand <= 70.0, "decisiones por mandato entre 25 y 70 (%.0f)" % dec_mand)
	_check(vistos.size() >= 40, "variedad: al menos 40 eventos distintos (%d)" % vistos.size())
	print("silencio máximo %d semanas · máximo de decisiones en 52 semanas %d" % [max_silencio, max_dec_anio])
	_check(max_silencio <= 12, "sin silencios largos (%d semanas)" % max_silencio)
	_check(max_dec_anio <= int(cfg["decisiones_max_anio"]) + 1, "tope anual de decisiones (%d)" % max_dec_anio)
	print("test_ritmo: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
