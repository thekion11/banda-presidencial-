extends SceneTree
## Coalición (DISENO_V2 §10): aliados ficticios, cuotas de poder, cohesión, votos y movimientos internos.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO COALICIÓN: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["coalicion"]
	var m := AyudaV2.gobierno(datos, 51)
	var est := m.estado
	est.partido = {"eje_eco": -0.6, "eje_inst": 0.1}
	_check(String(m.unirse_coalicion("nadie")["razon"]) == "partido_inexistente", "partido inexistente")
	_check(bool(m.unirse_coalicion("laborismo_austral")["ok"]) and String(m.unirse_coalicion("laborismo_austral")["razon"]) == "ya_aliado", "unirse y no repetir")
	m.unirse_coalicion("compromiso_civico")
	m.unirse_coalicion("liga_libertad")
	_check(String(m.unirse_coalicion("frente_tradicion")["razon"]) == "limite_aliados", "máximo de aliados")
	_check(m.coalicion.afinidad("laborismo_austral") > m.coalicion.afinidad("liga_libertad"), "la afinidad depende de la ideología")
	# votos: los aliados suman escaños según su satisfacción
	var sin := AyudaV2.gobierno(datos, 51)
	_check(datos["coalicion"].size() == 15, "coalición con los 15 partidos replicados")
	_check(est.apoyo_coalicion["senado"] > 0 and est.apoyo_coalicion["camara"] > 0, "los aliados aportan escaños")
	_check(int(m.legal.composicion(est, false)["aliados"]) > int(sin.legal.composicion(sin.estado, false)["aliados"]), "la composición del Senado incluye a los aliados")
	# cuotas
	var ministros: Array = est.gabinete.slice(0, 2)
	_check(bool(m.asignar_cuota("laborismo_austral", "ministerio", ministros[0])["ok"]), "asignar un ministerio")
	_check(String(m.asignar_cuota("compromiso_civico", "ministerio", ministros[0])["razon"]) == "ya_asignado", "un ministro no se entrega dos veces")
	_check(is_equal_approx(m.coalicion.cumplimiento("laborismo_austral"), 1.0 / 3.0), "un tercio de la petición (2 ministerios y 1 asesor)")
	m.asignar_cuota("laborismo_austral", "ministerio", ministros[1])
	_check(String(m.asignar_cuota("laborismo_austral", "asesor", "as_sindicalista")["razon"]) == "asesor_no_contratado", "la cuota de asesor exige tenerlo contratado")
	m.contratar_asesor("as_sindicalista")
	m.asignar_cuota("laborismo_austral", "asesor", "as_sindicalista")
	_check(is_equal_approx(m.coalicion.cumplimiento("laborismo_austral"), 1.0), "petición cumplida")
	# satisfacción: con cuota cumplida sube; sin cuota baja; la cohesión y los movimientos internos reaccionan
	for _i in range(3):
		m.ejecutar_amanecer()
	var sat_ok := float(est.coalicion["laborismo_austral"]["satisfaccion"])
	var sat_mal := float(est.coalicion["liga_libertad"]["satisfaccion"])
	_check(sat_ok > float(cfg["satisfaccion_inicial"]) and sat_mal < float(cfg["satisfaccion_inicial"]), "satisfecho sube, desatendido baja (%.0f / %.0f)" % [sat_ok, sat_mal])
	_check(est.internos_actual == int(datos["leyes"]["movimientos_internos"]["por_turno"]) - int(cfg["penal_internos_malestar"]) or sat_mal >= float(cfg["umbral_malestar"]), "el malestar de un aliado resta movimientos internos")
	# cartas de la categoría que pide el aliado mejoran su satisfacción
	var antes := float(est.coalicion["laborismo_austral"]["satisfaccion"])
	est.mano.clear()
	est.mano.append(AyudaV2.carta_sintetica("t_social", "social", {}))
	est.mano.append(AyudaV2.carta_sintetica("t_seg", "seguridad", {}))
	m._cartas_por_id["t_social"] = est.mano[0]
	m._cartas_por_id["t_seg"] = est.mano[1]
	m.jugar_carta(0)
	_check(float(est.coalicion["laborismo_austral"]["satisfaccion"]) > antes, "jugar una carta de lo que pide el aliado sube la satisfacción")
	var antes2 := float(est.coalicion["laborismo_austral"]["satisfaccion"])
	m.jugar_carta(0)
	_check(float(est.coalicion["laborismo_austral"]["satisfaccion"]) < antes2, "jugar una carta de lo que rechaza la baja")
	# ruptura: un aliado desatendido se va y cuesta cohesión
	for _i in range(60):
		if not est.coalicion.has("liga_libertad"):
			break
		m.ejecutar_amanecer()
	_check(not est.coalicion.has("liga_libertad"), "el aliado desatendido rompe la coalición")
	_check(est.registro_acciones.any(func(a: Dictionary) -> bool: return a["tipo"] == "coalicion_ruptura"), "la ruptura queda registrada")
	_check(bool(m.quitar_cuota("laborismo_austral", "ministerio", ministros[1])["ok"]) and is_equal_approx(m.coalicion.cumplimiento("laborismo_austral"), 2.0 / 3.0), "quitar una cuota")
	_check(bool(m.salir_coalicion("laborismo_austral")["ok"]), "salir de la coalición")
	# replay exacto
	var h := Datos.huella(datos)
	var resp: Array[Dictionary] = []
	for q in datos["ideologia"]["preguntas"]:
		resp.append(q["opciones"][1])
	var mp := Partida.crear(datos, 52, GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, datos["ideologia"]))
	mp.unirse_coalicion("laborismo_austral")
	mp.asignar_cuota("laborismo_austral", "ministerio", String(mp.estado.gabinete[0]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 52
	for _i in range(4):
		Bots.jugar_turno(mp, "codicioso", rng)
		mp.terminar_turno()
	var gp: Dictionary = JSON.parse_string(JSON.stringify(mp.estado.exportar_guardado(h)))
	_check(Partida.reproducir(datos, gp).estado.calcular_huella() == mp.estado.calcular_huella(), "replay idéntico con coalición")
	print("COALICIÓN OK" if _fallos == 0 else "COALICIÓN FALLÓ")
	quit(1 if _fallos > 0 else 0)
