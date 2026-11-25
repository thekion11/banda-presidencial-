class_name AyudaV2
extends RefCounted
## Utilidades de pruebas para las mecánicas v2 (gabinete, mano continua, delegación y movimientos internos).


static func gobierno(datos: Dictionary, semilla: int, cartas_extra: Array = []) -> MotorTurno:
	## Motor directamente en gobierno (sin campaña), con turno 1 iniciado.
	var estado := EstadoSimulacion.new()
	estado.configurar(semilla, int(datos["leyes"]["hemiciclo"]["dias_por_turno"]), datos["leyes"])
	estado.etapa = "gobierno"
	var motor := MotorTurno.new()
	motor.inicializar(estado, Array(datos["cartas"]) + cartas_extra, datos["eventos"], datos["leyes"], datos["ministros"],
			{"regiones": datos["regiones"], "propuestas": datos["propuestas"], "metas": datos["metas"], "asesores": datos["asesores"], "coalicion": datos["coalicion"]})
	motor.regiones.inicializar(estado, estado.ind("aprobacion"), "", 0.0)
	motor.iniciar_turno()
	return motor


static func carta_sintetica(id: String, categoria: String, disp: Dictionary) -> Dictionary:
	return {"id": id, "categoria": categoria, "costo_pa": 1, "titulo": id, "efectos": [{"ind": "capital", "delta": 1.0}],
			"requisitos": {"ley": null, "quorum": null}, "corrector": null, "abre_propuesta_comite": null,
			"fuente": "fuentes.json#ficticio_2026", "disponibilidad": disp}


static func ministros_de(datos: Dictionary, categorias: Array, tamano: int) -> Array:
	## Gabinete con los primeros ministros de las categorías pedidas, completado con otros hasta `tamano`.
	var ids: Array = []
	var slots := {}
	for cat in categorias:
		for mi in datos["ministros"]:
			if mi["categoria_afin"] == cat and not ids.has(mi["id"]) and not slots.has(mi["ministerio"]):
				ids.append(mi["id"])
				slots[mi["ministerio"]] = true
				break
	for mi in datos["ministros"]:  # un candidato por ministerio
		if ids.size() < tamano and not slots.has(mi["ministerio"]):
			ids.append(mi["id"])
			slots[mi["ministerio"]] = true
	return ids
