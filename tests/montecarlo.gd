extends SceneTree
## Uso: godot --headless -s tests/montecarlo.gd -- [partidas=200] [politica=codicioso|azar|pasivo]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 200
	var politicas: Array = [args[1]] if args.size() > 1 else ["pasivo", "azar", "codicioso", "codicioso>pasivo", "codicioso>azar", "codicioso>completo"]
	var datos := Datos.cargar_todo()
	for pol in politicas:
		var electos := 0
		var crisis := 0
		var completos := 0
		var ap_sum := 0.0
		var pts: Array[int] = []
		var legado_sum := 0
		for i in range(n):
			var m := Bots.partida_completa(datos, 1000 + i, String(pol))
			var e := m.estado
			if e.etapa != "derrota_electoral":
				electos += 1
				ap_sum += e.ind("aprobacion")
				legado_sum += e.promesas_pendientes().size()
				if e.etapa == "crisis":
					crisis += 1
				if e.etapa == "fin_mandato":
					completos += 1
					pts.append(int(e.resultado_final["puntaje"]))
		pts.sort()
		var med := pts[pts.size() / 2] if not pts.is_empty() else 0
		print("%-16s n=%d | gana elección %5.1f%% | cae en crisis %5.1f%% | completa mandato %5.1f%% | aprob. final media %5.1f | puntaje mediano %d | promesas pend. media %.1f" % [
			pol, n, 100.0 * electos / n, 100.0 * crisis / n, 100.0 * completos / n,
			ap_sum / maxf(1.0, float(electos)), med, float(legado_sum) / maxf(1.0, float(electos))])
	quit(0)
