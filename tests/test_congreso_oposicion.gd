extends SceneTree
## Congreso en oposición: las votaciones del gobierno rival dependen de tu bancada, tus aliados y tu cohesión; se reproducen exactas.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("C", "CCC", "metropolitana", resp, datos["ideologia"])
	var m: MotorTurno
	for semilla in range(31, 80):  # una semilla en que una campaña sin jugar termina en derrota (no depende del azar de una sola semilla)
		m = Partida.crear(datos, semilla, partido)
		for _i in range(8):
			m.terminar_turno()
		m.resolver_eleccion_presidencial()
		if m.estado.etapa == "derrota_electoral":
			break
	m.continuar_carrera()
	m.iniciar_turno()
	_check(m.estado.etapa == "oposicion", "la derrota lleva a la oposición (%s)" % m.estado.etapa)
	var votaciones: Array = datos["eventos"].filter(func(e: Dictionary) -> bool: return String(e["id"]).begins_with("evt_opo_congreso_") and e.has("opciones") and e["opciones"][0].has("congreso"))
	_check(votaciones.size() == 4, "hay 4 votaciones del gobierno rival")
	# jugar semanas hasta la primera votación y decidir
	var hechas := 0
	var tope := 40
	while hechas < 1 and tope > 0:
		tope -= 1
		for ev in m.ultimos_eventos:
			if String(ev["id"]) == "evt_opo_congreso_presupuesto":
				_check(String(ev["descripcion"]).contains("probabilidad"), "la descripción muestra la probabilidad")
				var r := m.eventos.decidir(String(ev["id"]), 0)
				_check(bool(r["ok"]) and bool(r["congreso"]), "decidir el bloqueo")
				hechas += 1
		if hechas == 0:
			m.terminar_turno()
	_check(hechas == 1, "la votación llega en la oposición")
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(Datos.huella(datos))))
	_check(Partida.reproducir(datos, g).estado.calcular_huella() == m.estado.calcular_huella(), "se reproduce exacto")
	var p0 := m.eventos.prob_bloqueo()
	_check(p0 > 0.1 and p0 < 0.85, "probabilidad base razonable (%.2f)" % p0)
	m.coalicion.unirse("laborismo_austral")
	_check(m.eventos.prob_bloqueo() > p0, "un aliado en el Senado sube la probabilidad")
	m.estado.indicadores["cohesion"] = 90.0
	var alta := m.eventos.prob_bloqueo()
	m.estado.indicadores["cohesion"] = 10.0
	_check(m.eventos.prob_bloqueo() < alta, "la cohesión baja o sube la probabilidad")
	print("test_congreso_oposicion: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
