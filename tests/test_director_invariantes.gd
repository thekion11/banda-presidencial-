extends SceneTree
## Invariantes del director de eventos en carreras completas (208 turnos): ningún evento aleatorio se repite antes de cooldown_evento, ninguna familia antes de
## cooldown_familia, ninguna decisión antes de cooldown_decision, a lo sumo un aleatorio por semana y silencio nunca mayor que silencio_max.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1
		if _fallos > 15:
			quit(1)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["director_eventos"]
	var tipo := {}
	var cadena := {}  # eventos en cadena (consecuencia de una decisión): no pasan por el director ni por sus descansos
	for e in datos["eventos"]:
		tipo[String(e["id"])] = e
		for o in e.get("opciones", []):
			if o.has("cadena"):
				cadena[String(o["cadena"]["evento"])] = true
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Director", "DIR", "metropolitana", resp, datos["ideologia"])
	var gobiernos := 0
	var aleatorios := 0
	for semilla in range(700, 724):
		var m := Partida.crear(datos, semilla, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var ult_ev := {}
		var ult_fam := {}
		var ult_dec := -1000
		var ult_alea := 0
		var sem_ant := -1
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if not Bots.elegir(m, datos, "codicioso", rng):
			continue
		gobiernos += 1
		var est := m.estado
		ult_alea = m.eventos.semana_abs()
		while est.etapa == "gobierno":
			var ahora := m.eventos.semana_abs()
			_check(ahora > sem_ant, "semana_abs avanza (%d tras %d)" % [ahora, sem_ant])
			sem_ant = ahora
			var alea := 0
			for ev in m.ultimos_eventos:
				var def: Dictionary = tipo.get(String(ev["id"]), {})
				if not def.is_empty() and String(def["tipo"]) == "programado":
					ult_alea = ahora  # un evento programado también rompe el silencio (el director lo registra y el jugador lo ve)
				if def.is_empty() or String(def["tipo"]) != "aleatorio_semilla" or cadena.has(String(ev["id"])):
					continue
				alea += 1
				aleatorios += 1
				var id := String(ev["id"])
				_check(not ult_ev.has(id) or ahora - int(ult_ev[id]) >= int(cfg["cooldown_evento"]), "semilla %d: %s repetido a %d semanas" % [semilla, id, ahora - int(ult_ev.get(id, 0))])
				ult_ev[id] = ahora
				var fam := String(def.get("familia", "?"))
				if def.has("familia"):
					_check(not ult_fam.has(fam) or ahora - int(ult_fam[fam]) >= int(cfg["cooldown_familia"]), "semilla %d: familia %s repetida a %d semanas" % [semilla, fam, ahora - int(ult_fam.get(fam, 0))])
					ult_fam[fam] = ahora
				if def.has("opciones"):
					_check(ahora - ult_dec >= int(cfg["cooldown_decision"]), "semilla %d: dos decisiones a %d semanas" % [semilla, ahora - ult_dec])
					ult_dec = ahora
			_check(alea <= 1, "semilla %d: %d eventos aleatorios en una semana" % [semilla, alea])
			if alea > 0:
				ult_alea = ahora
			_check(ahora - ult_alea <= int(cfg["silencio_max"]) + 1, "semilla %d: %d semanas sin eventos aleatorios" % [semilla, ahora - ult_alea])
			Bots.jugar_turno(m, "humano", rng)
			m.terminar_turno()
	_check(gobiernos >= 10, "al menos 10 carreras llegaron al gobierno (%d)" % gobiernos)
	_check(aleatorios > 500, "se observaron suficientes eventos aleatorios (%d)" % aleatorios)
	print("test_director_invariantes: ", "OK (%d gobiernos, %d eventos aleatorios)" % [gobiernos, aleatorios] if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
