extends SceneTree
## Aprobación media al llegar a la semana 9 de gobierno (y lo que queda desde el inicio) por política y dificultad. Informe, no prueba.
## Uso: godot --headless --path . -s tests/analisis_aprobacion_semana9.gd -- 30

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 30
	var datos := Datos.cargar_todo()
	for pol in ["pasivo", "azar", "humano", "codicioso", "completo"]:
		for dif in ["facil", "normal", "dificil"]:
			var ini: Array[float] = []
			var s9: Array[float] = []
			for i in range(n):
				var semilla := 30000 + i
				var rng := RandomNumberGenerator.new()
				rng.seed = semilla * 31 + 7
				var resp: Array[Dictionary] = []
				for p in datos["ideologia"]["preguntas"]:
					resp.append(p["opciones"][rng.randi_range(0, 2)])
				var partido := GeneradorPartido.construir_partido("Partido Prueba", "PRU", "metropolitana", resp, datos["ideologia"])
				partido["dificultad"] = dif
				var m := Partida.crear(datos, semilla, partido)
				for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
					Bots.jugar_turno(m, pol, rng)
					m.terminar_turno()
				if not Bots.elegir(m, datos, pol, rng):
					continue
				ini.append(m.estado.ind("aprobacion"))
				while m.estado.etapa == "gobierno" and m.estado.turno_actual < 9:
					Bots.jugar_turno(m, pol, rng)
					m.terminar_turno()
				if m.estado.etapa == "gobierno":
					s9.append(m.estado.ind("aprobacion"))
			ini.sort()
			s9.sort()
			print("APROB %s %s: llegan a gobierno=%d, aprob inicial mediana=%.1f, a la semana 9 mediana=%.1f (p10=%.1f p90=%.1f)" % [pol, dif, ini.size(), _med(ini), _med(s9), _pc(s9, 0.1), _pc(s9, 0.9)])
	quit(0)


func _med(a: Array[float]) -> float:
	return _pc(a, 0.5)


func _pc(a: Array[float], q: float) -> float:
	return a[int(float(a.size() - 1) * q)] if not a.is_empty() else -1.0
