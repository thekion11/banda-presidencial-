extends SceneTree
## ¿Es dominante «presentar todo con urgencia máxima»? Compara partidas de gobierno (bot codicioso) en que cada semana se presentan hasta 2 proyectos del catálogo con
## urgencia simple, suma o discusión inmediata (o ninguno), por dificultad. Mide aprobación y capital finales, puntaje, leyes promulgadas y rechazos.
## Uso: godot --headless --path . -s tests/analisis_agenda.gd -- [partidas=10] [semilla=6600] [semanas=104]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 10
	var s0 := int(args[1]) if args.size() > 1 else 6600
	var semanas := int(args[2]) if args.size() > 2 else 104
	var datos := Datos.cargar_todo()
	print("%-8s %-10s %4s %8s %8s %8s %8s %8s" % ["dific", "urgencia", "n", "aprob", "capital", "promulg", "rechaz", "puntaje"])
	for dif in ["facil", "normal", "dificil"]:
		for urg in ["ninguna", "simple", "suma", "inmediata"]:
			var ap := 0.0
			var cap := 0.0
			var pro := 0.0
			var rec := 0.0
			var pts := 0.0
			var ng := 0
			for i in range(n):
				var rng := RandomNumberGenerator.new()
				rng.seed = s0 + i
				var resp: Array[Dictionary] = []
				for p in datos["ideologia"]["preguntas"]:
					resp.append(p["opciones"][1])
				var partido := GeneradorPartido.construir_partido("Ag", "AGE", "metropolitana", resp, datos["ideologia"])
				partido["dificultad"] = dif
				var m := Partida.crear(datos, s0 + i, partido)
				for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
					Bots.jugar_turno(m, "codicioso", rng)
					m.terminar_turno()
				if not Bots.elegir(m, datos, "codicioso", rng):
					continue
				ng += 1
				for _w in range(semanas):
					if m.estado.etapa != "gobierno":
						break
					if urg != "ninguna":
						var cat := m.agenda.agenda_catalogo()
						var hechos := 0
						for c in cat:
							if hechos >= 2:
								break
							if bool(m.agenda.presentar(String(c["carta_id"]), urg).get("ok", false)):
								hechos += 1
					Bots.jugar_turno(m, "codicioso", rng)
					m.terminar_turno()
					for f in m.votaciones_semana:
						if bool(f.get("agenda", false)):
							pro += 1.0 if bool(f["aprobada"]) else 0.0
							rec += 0.0 if bool(f["aprobada"]) else 1.0
				ap += m.estado.ind("aprobacion")
				cap += m.estado.ind("capital")
				pts += float(m.estado.resultado_final.get("puntaje", 0)) if not m.estado.resultado_final.is_empty() else (m.estado.ind("aprobacion") * 10.0)
			var k := float(maxi(1, ng))
			print("%-8s %-10s %4d %8.1f %8.1f %8.1f %8.1f %8.0f" % [dif, urg, ng, ap / k, cap / k, pro / k, rec / k, pts / k])
	quit(0)
