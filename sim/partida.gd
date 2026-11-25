class_name Partida
extends RefCounted
## Fachada: crea una partida lista para jugar y la reproduce desde un guardado por eventos.


static func crear(datos: Dictionary, semilla: int, partido: Dictionary) -> MotorTurno:
	var estado := EstadoSimulacion.new()
	estado.configurar(semilla, int(datos["leyes"]["hemiciclo"]["dias_por_turno"]), datos["leyes"])
	var motor := MotorTurno.new()
	motor.inicializar(estado, datos["cartas"], datos["eventos"], datos["leyes"], datos["ministros"],
			{"regiones": datos["regiones"], "propuestas": datos["propuestas"], "grafo": datos.get("grafo", {}), "sectra": datos.get("sectra", {}), "metas": datos.get("metas", []), "asesores": datos.get("asesores", []), "coalicion": datos.get("coalicion", [])})
	motor.aplicar_partido_inicial(partido)
	motor.iniciar_turno()
	return motor


static func reproducir(datos: Dictionary, guardado: Dictionary) -> MotorTurno:
	## Reconstruye la partida exacta desde semilla + partido + entradas del jugador.
	var motor := crear(datos, int(guardado["semilla"]), guardado["partido"])
	for e in guardado["entradas"]:
		match String(e["tipo"]):
			"jugar":
				motor.cartas.jugar_carta(int(e["idx"]), String(e["ministro"]), String(e["region"]), bool(e.get("delegada", false)))
			"gabinete":
				motor.elegir_gabinete(e["ids"])
			"asesor":
				if String(e["accion"]) == "contratar":
					motor.contratar_asesor(String(e["id"]))
				else:
					motor.despedir_asesor(String(e["id"]))
			"coalicion":
				if String(e["accion"]) == "unirse":
					motor.unirse_coalicion(String(e["id"]))
				else:
					motor.salir_coalicion(String(e["id"]))
			"cuota":
				if bool(e["quitar"]):
					motor.quitar_cuota(String(e["id"]), String(e["clase"]), String(e["valor"]))
				else:
					motor.asignar_cuota(String(e["id"]), String(e["clase"]), String(e["valor"]))
			"meta":
				motor.buscar_meta(String(e["meta"]))
			"sector":
				motor.ajustar_sector(String(e["sector"]), int(e["dir"]))
			"errores":
				motor.reducir_errores()
			"acelerar":
				motor.acelerar_proyecto(int(e["idx"]))
			"aprobar_propuesta":
				motor.aprobar_propuesta(String(e["prop"]), String(e["variante"]), String(e["region"]), e.get("custom", {}), e.get("nombres", {}))
			"sectra":
				motor.impulsar_proyecto(String(e["pid"]))
			"decision":
				motor.eventos.decidir(String(e["evento"]), int(e["idx"]))
			"cerrar":
				motor.terminar_turno()
			"eleccion":
				var r := motor.resolver_eleccion_presidencial()
				if bool(r["electo"]) or bool(r["balotaje"]):
					motor.iniciar_turno()
	return motor
