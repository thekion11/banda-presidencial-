extends SceneTree
## Informe de bots (no es parte de la suite): compara políticas en primera campaña, gobierno y carrera política.
## Uso: godot --headless --path . -s tests/informe_bots.gd -- [partidas=30] [--escribir]   (con --escribir guarda docs/INFORME_BOTS.md)

const POLITICAS := ["pasivo", "azar", "humano", "codicioso", "completo", "experto"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 and args[0].is_valid_int() else 30
	var datos := Datos.cargar_todo()
	var filas: Array[String] = []
	for pol in POLITICAS:
		var gana := 0
		var crisis := 0
		var completo := 0
		var ap := 0.0
		var pts: Array[int] = []
		var decisiones := 0
		var segunda := 0
		var segunda_n := 0
		for i in range(n):
			var m := Bots.partida_completa(datos, 9000 + i, pol)
			var e := m.estado
			for a in e.registro_acciones:
				if a["tipo"] == "decision":
					decisiones += 1
			if e.etapa != "derrota_electoral":
				gana += 1
				ap += e.ind("aprobacion")
				if e.etapa == "crisis":
					crisis += 1
				if e.etapa == "fin_mandato":
					completo += 1
					pts.append(int(e.resultado_final["puntaje"]))
			# carrera: tras el primer periodo, oposición jugada y segunda elección
			if e.etapa in ["fin_mandato", "crisis", "derrota_electoral"]:
				var rng := RandomNumberGenerator.new()
				rng.seed = 9000 + i
				if bool(m.continuar_carrera()["ok"]):
					m.iniciar_turno()
					var guardia := 0
					while m.estado.etapa == "oposicion" and guardia < 40:
						Bots.jugar_turno(m, pol, rng)
						m.terminar_turno()
						guardia += 1
					if m.estado.etapa == "campana":
						for _t in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
							Bots.jugar_turno(m, pol, rng)
							m.terminar_turno()
						segunda_n += 1
						if Bots.elegir(m, datos, pol, rng):
							segunda += 1
		pts.sort()
		filas.append("| %s | %.0f %% | %.0f %% | %.0f %% | %.1f | %d | %.0f | %.0f %% |" % [pol, 100.0 * gana / n, 100.0 * crisis / maxf(1.0, float(gana)), 100.0 * completo / n,
				ap / maxf(1.0, float(gana)), pts[pts.size() / 2] if not pts.is_empty() else 0, float(decisiones) / n, 100.0 * segunda / maxf(1.0, float(segunda_n))])
		print(filas[filas.size() - 1])
	var tabla := "| política | gana 1.ª elección | cae en crisis (de los electos) | completa mandato | aprobación final | puntaje mediano | decisiones por partida | gana la 2.ª elección (tras oposición) |\n|---|---|---|---|---|---|---|---|\n" + "\n".join(filas)
	if args.has("--escribir"):
		var f := FileAccess.open("res://docs/INFORME_BOTS.md", FileAccess.WRITE)
		f.store_string("# Informe de bots\n\nGenerado por `tests/informe_bots.gd` (n = %d partidas por política, semillas 9000+). Políticas: pasivo (no juega), azar, humano (casual: ~80 %% de las semanas, hasta 3 cartas, decide bien el 70 %% de las veces), codicioso (valor inmediato), completo (suma asesores, coalición, delegación e internos), experto (completo con decisiones óptimas).\n\n%s\n" % [n, tabla])
	quit()
