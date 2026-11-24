extends SceneTree
## Validaciones del núcleo: el ministro debe estar en el gabinete, la elección solo se vota cuando corresponde y la campaña no se alarga.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO VALIDACIONES: ", msg)


func _init() -> void:
	var d := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Prueba", "PRU", "metropolitana", resp, d["ideologia"])
	var sem := int(d["leyes"]["hemiciclo"]["semanas_campana"])
	# 1) la elección no se puede votar a mitad de campaña, y terminar turnos no alarga la campaña
	var m := Partida.crear(d, 4242, partido)
	var antes: int = m.estado.exportar_guardado()["entradas"].size()
	var r := m.resolver_eleccion_presidencial()
	_check(not bool(r.get("ok", true)) and not bool(r["electo"]) and not bool(r["balotaje"]), "votar en la semana 1 de campaña no debe valer")
	_check(m.estado.etapa == "campana" and m.estado.exportar_guardado()["entradas"].size() == antes, "una votación inválida no cambia la etapa ni se registra")
	for _i in range(sem + 12):
		m.terminar_turno()
	_check(m.estado.turno_actual == sem + 1 and m.estado.eleccion_pendiente(sem), "la campaña se detiene al terminar sus %d semanas (turno %d)" % [sem, m.estado.turno_actual])
	var rv := m.resolver_eleccion_presidencial()
	_check(bool(rv["ok"]), "con la campaña terminada la votación sí vale")
	if bool(rv["electo"]) or bool(rv["balotaje"]):
		m.iniciar_turno()
	if m.estado.etapa == "gobierno":
		var etapa := m.estado.etapa
		var turno := m.estado.turno_actual
		var r2 := m.resolver_eleccion_presidencial()
		_check(not bool(r2["ok"]) and m.estado.etapa == etapa and m.estado.turno_actual == turno, "votar de nuevo en pleno gobierno no debe reiniciar nada")
		# 2) un ministro fuera del gabinete no se puede usar al jugar una carta
		var fuera := ""
		for id in m.catalogo_ministros:
			if not m.estado.gabinete.has(id):
				fuera = String(id)
				break
		_check(fuera != "", "debe haber ministros fuera del gabinete (el catálogo tiene más que el gabinete)")
		var j := m.cartas.jugar_carta(0, fuera, "", false)
		_check(not bool(j["ok"]) and j["razon"] == "ministro_fuera_del_gabinete", "jugar con un ministro fuera del gabinete debe rechazarse: %s" % [j])
	# 3) la variación territorial usa un hash propio: mismos números en cualquier versión de Godot
	_check(Huella.fnv32("hola") == 0xB2C65197, "FNV-1a de «hola» debe ser b2c65197 (calculado aparte en Python), es %x" % Huella.fnv32("hola"))
	if _fallos == 0:
		print("VALIDACIONES OK (elección y campaña acotadas, ministro del gabinete, hash estable)")
	quit(0 if _fallos == 0 else 1)
