extends SceneTree
## ¿Es dominante «ahorrar movimientos»? Compara, por dificultad, partidas completas con el bot que gasta (codicioso), el que ahorra (ahorrador: juega solo
## las semanas pares y gasta todo de golpe) y el casual (humano), en campaña igual y distinta política de gobierno. Mide aprobación final, puntaje, % que llega
## al fin del mandato y cartas jugadas. Uso: godot --headless --path . -s tests/analisis_ahorro.gd -- [partidas=16] [semilla=4200]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 16
	var s0 := int(args[1]) if args.size() > 1 else 4200
	var datos := Datos.cargar_todo()
	print("%-8s %-22s %5s %8s %8s %7s %7s" % ["dific", "política", "n_gob", "aprob", "puntaje", "fin%", "cartas"])
	for dif in ["facil", "normal", "dificil"]:
		for pol in ["codicioso>codicioso", "codicioso>ahorrador", "codicioso>humano", "experto>experto"]:
			var ap := 0.0
			var pt := 0.0
			var fin := 0
			var car := 0.0
			var ng := 0
			for i in range(n):
				var m := Bots.partida_completa(datos, s0 + i, pol, dif)
				var e := m.estado
				if e.resultado_final.is_empty() and e.etapa == "gobierno":
					continue
				if e.etapa == "derrota_electoral":
					continue
				ng += 1
				ap += e.ind("aprobacion")
				pt += float(e.resultado_final.get("puntaje", 0))
				fin += 1 if e.etapa == "fin_mandato" else 0
				for a in e.registro_acciones:
					car += 1.0 if a["tipo"] == "carta" else 0.0
			var k := float(maxi(1, ng))
			print("%-8s %-22s %5d %8.1f %8.1f %6.0f%% %7.0f" % [dif, pol, ng, ap / k, pt / k, 100.0 * fin / k, car / k])
	quit(0)
