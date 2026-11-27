extends SceneTree
## Monte Carlo grande por política y dificultad: imprime una línea por celda con conteos (para intervalos de confianza en docs/INFORME_BALANCE.md).
## Uso: godot --headless --path . -s tests/informe_dificultad.gd -- 200 [ruido_regional]

func _init() -> void:
	var n := 200
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	var datos := Datos.cargar_todo()
	if args.size() > 1:  # segundo argumento: ruido regional de la elección (se prueba en una copia de los datos; data/ no se toca)
		datos["leyes"]["campana"]["ruido_eleccion_regional"] = float(args[1])
	for pol in ["pasivo", "azar", "humano", "codicioso", "completo"]:
		for dif in ["facil", "normal", "dificil"]:
			var electos := 0
			var crisis := 0
			var completas := 0
			var puntajes: Array[int] = []
			var aprob := 0.0
			for i in range(n):
				var e := Bots.partida_completa(datos, 20000 + i, pol, dif).estado
				if e.etapa == "derrota_electoral":
					continue
				electos += 1
				if e.etapa == "crisis":
					crisis += 1
				if e.etapa == "fin_mandato":
					completas += 1
					puntajes.append(int(e.resultado_final.get("puntaje", 0)))
				aprob += e.ind("aprobacion")
			puntajes.sort()
			var med := puntajes[puntajes.size() / 2] if not puntajes.is_empty() else 0
			print("CELDA %s %s n=%d electos=%d crisis=%d completas=%d puntaje_mediano=%d aprob_media=%.1f" % [pol, dif, n, electos, crisis, completas, med, aprob / maxf(1.0, float(electos))])
	quit()
