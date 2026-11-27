extends SceneTree
## Medición de balance de las balas de plata (PR-17): mismas partidas con el bot «completo» sin y con uso de balas «siempre que puede».
## Uso: godot --headless --path . -s tests/informe_balas.gd -- 100   → líneas «CELDA» por dificultad y modo (para los intervalos de docs/INFORME_BALANCE.md).

func _init() -> void:
	var n := 100
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	var datos := Datos.cargar_todo()
	for dif in ["facil", "normal", "dificil"]:
		for con in [false, true]:
			Bots.usar_balas = con
			var electos := 0
			var crisis := 0
			var completas := 0
			var suma_punt := 0
			var usos := 0
			var malas := 0
			var por_tipo := {}
			for i in range(n):
				var m := Bots.partida_completa(datos, 20000 + i, "completo", dif)
				var e := m.estado
				if e.etapa == "derrota_electoral":
					continue
				electos += 1
				if e.etapa == "crisis":
					crisis += 1
				if e.etapa == "fin_mandato":
					completas += 1
					suma_punt += int(e.resultado_final.get("puntaje", 0))
				for a in e.registro_acciones:
					if a["tipo"] == "bala":
						usos += 1
						malas += 1 if bool(a["detalle"]["mal"]) else 0
						por_tipo[String(a["detalle"]["id"])] = int(por_tipo.get(String(a["detalle"]["id"]), 0)) + 1
			print("CELDA %s balas=%s n=%d electos=%d crisis=%d completas=%d puntaje_medio=%.1f usos=%d malas=%d tipos=%s" % [dif, str(con), n, electos, crisis, completas, float(suma_punt) / maxf(1.0, float(completas)), usos, malas, JSON.stringify(por_tipo)])
	Bots.usar_balas = false
	quit()
