extends SceneTree
## Compara el voto nacional ponderado por región con el antiguo (aprobación nacional + choque) en N campañas: diferencia máxima, regiones ganadas y votos estimados.
## Uso: godot --headless --path . -s tests/analisis_voto_regional.gd -- 100

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 100
	var datos := Datos.cargar_todo()
	var dif_max := 0.0
	var cambian := 0
	var ganadas := 0
	var electos := 0
	for s in range(n):
		var resp: Array[Dictionary] = []
		for p in datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][s % 3 if p["opciones"].size() > 2 else 0])
		var partido := GeneradorPartido.construir_partido("Prueba", "PRU", "metropolitana", resp, datos["ideologia"])
		var m := Partida.crear(datos, 1000 + s, partido)
		while not m.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			m.terminar_turno()
		var apr := m.estado.ind("aprobacion")
		var res := m.resolver_eleccion_presidencial()
		var d := m.estado.ultima_eleccion
		# el voto antiguo = aprobación nacional + desplazamiento; el desplazamiento se recupera de cualquier región sin tope
		var viejo := clampf(apr + (float(d["regiones"][0]["voto"]) - float(m.estado.aprobacion_regional[d["regiones"][0]["id"]])), 0.0, 100.0)
		var dif := absf(float(res["voto_final"]) - viejo)
		dif_max = maxf(dif_max, dif)
		cambian += 1 if dif > 1e-6 else 0
		ganadas += int(res["regiones_ganadas"])
		electos += 1 if res["electo"] else 0
	print("analisis_voto_regional: n=%d, dif_max=%.6f, elecciones con diferencia>1e-6=%d, regiones ganadas media=%.1f, electos=%d" % [n, dif_max, cambian, float(ganadas) / float(n), electos])
	quit(0)
