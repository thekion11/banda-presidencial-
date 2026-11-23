extends SceneTree
## Enmienda de Cierre: 8 preguntas, campaña de 8 turnos, y el umbral de victoria sale de data/leyes.json (turno 8).

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO ENMIENDA: ", msg)


func _elegir(datos: Dictionary, umbral: float) -> Dictionary:
	var d := datos.duplicate(true)
	d["leyes"]["hemiciclo"]["umbral_victoria_presidencial"] = umbral
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Prueba", "PRU", "metropolitana", resp, d["ideologia"])
	var m := Partida.crear(d, 12345, partido)
	var turnos_campana := 0
	while not m.estado.eleccion_pendiente(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
		m.terminar_turno()
		turnos_campana += 1
		if turnos_campana > 40:
			break
	var aprob := m.estado.ind("aprobacion")
	var r := m.resolver_eleccion_presidencial()
	return {"turnos": turnos_campana, "res": r, "aprob": aprob, "etapa": m.estado.etapa}


func _init() -> void:
	var datos := Datos.cargar_todo()
	_check(datos["ideologia"]["preguntas"].size() == 8, "el test ideológico debe tener exactamente 8 preguntas")
	_check(int(datos["leyes"]["hemiciclo"]["semanas_campana"]) == 8, "la campaña debe durar 8 semanas")
	var imposible := _elegir(datos, 101.0)
	var seguro := _elegir(datos, 0.0)
	_check(imposible["turnos"] == 8 and seguro["turnos"] == 8, "la campaña debe tener 8 turnos (tuvo %d)" % imposible["turnos"])
	_check(not bool(imposible["res"]["electo"]) and imposible["etapa"] == "derrota_electoral", "con umbral 101 no se puede ganar: el umbral sale de leyes.json")
	_check(bool(seguro["res"]["electo"]) and seguro["etapa"] == "gobierno", "con umbral 0 siempre se gana: el umbral sale de leyes.json")
	_check(float(seguro["res"]["umbral"]) == 0.0, "la elección debe reportar el umbral leído de los datos")
	if _fallos == 0:
		print("ENMIENDA OK (8 preguntas, 8 turnos de campaña, umbral desde data/leyes.json)")
	quit(0 if _fallos == 0 else 1)
