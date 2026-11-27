class_name AyudaTardio
extends RefCounted
## Estado tardío realista y determinista para revisar la interfaz a fin de mandato (textos largos, muchas obras, leyes, coalición y promesas).
## Uso: var m := AyudaTardio.crear(Datos.cargar_todo(), 2026, 170)   # motor en la semana 170 de gobierno, listo para mostrar con Main/PantallaDia
## Misma semilla y mismos parámetros = mismo estado. Prueba semillas consecutivas hasta encontrar una campaña ganada (hasta 60 intentos).


static func crear(datos: Dictionary, semilla: int = 2026, turno_objetivo: int = 170, politica: String = "completo", dificultad: String = "facil") -> MotorTurno:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	for intento in range(60):
		var s := semilla + intento
		var partido := GeneradorPartido.construir_partido("Tardío", "TAR", "metropolitana", resp, datos["ideologia"])
		partido["dificultad"] = dificultad
		var m := Partida.crear(datos, s, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = s * 31 + 7
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(m, politica, rng)
			m.terminar_turno()
		if not Bots.elegir(m, datos, politica, rng):
			continue
		var guard := 0
		while m.estado.etapa == "gobierno" and m.estado.turno_actual < turno_objetivo and guard < 400:
			guard += 1
			Bots.jugar_turno(m, politica, rng)
			m.terminar_turno()
		if m.estado.etapa == "gobierno" and m.estado.turno_actual >= turno_objetivo:
			return m
	return null


static func resumen(m: MotorTurno) -> String:
	## Qué tan cargado está el estado: para elegir una semilla que ejercite la interfaz.
	var e := m.estado
	var mayor := 0
	for o in e.obras_en_curso:
		mayor = maxi(mayor, String(o["nombre"]).length())
	for o in e.obras_terminadas:
		mayor = maxi(mayor, String(o["nombre"]).length())
	var tit := 0
	for p in e.promesas_campana:
		tit = maxi(tit, String(p.get("titulo", "")).length())
	return "semana %d · semilla %d · obras en curso %d, terminadas %d (nombre más largo %d car.) · promesas %d (%d pendientes, título más largo %d) · aliados %d · asesores %d · leyes votadas %d · registro de acciones %d" % [
			e.turno_actual, e.semilla, e.obras_en_curso.size(), e.obras_terminadas.size(), mayor, e.promesas_campana.size(), e.promesas_pendientes().size(), tit,
			e.coalicion.size(), e.asesores.size(), e.registro_acciones.filter(func(a: Dictionary) -> bool: return a["tipo"] == "votacion").size(), e.registro_acciones.size()]
