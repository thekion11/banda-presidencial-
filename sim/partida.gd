class_name Partida
extends RefCounted
## Fachada: crea una partida lista para jugar y la reproduce desde un guardado por eventos.


static func armar(datos: Dictionary, semilla: int) -> MotorTurno:
	## Motor con los catálogos cargados y el estado vacío (sin partido ni primer turno).
	var estado := EstadoSimulacion.new()
	estado.configurar(semilla, int(datos["leyes"]["hemiciclo"]["dias_por_turno"]), datos["leyes"])
	var motor := MotorTurno.new()
	motor.inicializar(estado, datos["cartas"], datos["eventos"], datos["leyes"], datos["ministros"],
			{"regiones": datos["regiones"], "propuestas": datos["propuestas"], "grafo": datos.get("grafo", {}), "sectra": datos.get("sectra", {}), "metas": datos.get("metas", []), "asesores": datos.get("asesores", []), "coalicion": datos.get("coalicion", []), "indices_cartas": datos.get("indices_cartas", null)})
	return motor


static func crear(datos: Dictionary, semilla: int, partido: Dictionary) -> MotorTurno:
	## Crea una partida lista para jugar: motor armado, partido aplicado y primer turno iniciado.
	var motor := armar(datos, semilla)
	motor.aplicar_partido_inicial(partido)
	motor.iniciar_turno()
	return motor


static func cargar(datos: Dictionary, guardado: Dictionary, instantanea: Dictionary = {}, huella_datos: String = "", sha_guardado: String = "") -> MotorTurno:
	## Continúa un guardado: con una instantánea válida (ver Instantanea) restaura el estado directamente; si no, reproduce el historial.
	if not ValidarGuardado.guardado_valido(guardado):
		return null
	if Instantanea.vale_para(instantanea, huella_datos, sha_guardado):
		return Instantanea.restaurar(datos, int(guardado["semilla"]), instantanea)
	return reproducir(datos, guardado)


static func reproducir(datos: Dictionary, guardado: Dictionary) -> MotorTurno:
	## Reconstruye la partida exacta desde semilla + partido + entradas del jugador.
	if not ValidarGuardado.guardado_valido(guardado):
		return null  # guardado con otra forma: se descarta antes de tocar el motor
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
			"continuar":
				if bool(motor.continuar_carrera()["ok"]):
					motor.iniciar_turno()
			"decision":
				motor.eventos.decidir(String(e["evento"]), int(e["idx"]))
			"bala":
				motor.balas.usar(String(e["id"]), int(e["objetivo"]), bool(e["reducida"]))
			"cerrar":
				motor.terminar_turno()
			"eleccion":
				var r := motor.resolver_eleccion_presidencial()
				if bool(r["electo"]) or bool(r["balotaje"]):
					motor.iniciar_turno()
	return motor
