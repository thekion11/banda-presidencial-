extends SceneTree
## Pruebas negativas del núcleo: toda acción inválida devuelve una razón y NO cambia el estado ni se registra (misma huella, mismas entradas).

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _rechaza(m: MotorTurno, r: Dictionary, razon: String, huella: String, entradas: int, ctx: String) -> void:
	_check(not bool(r.get("ok", true)) and String(r.get("razon", "")) == razon, "%s: esperaba razón «%s», llegó %s" % [ctx, razon, str(r)])
	_check(m.estado.calcular_huella() == huella, "%s: el rechazo cambió el estado" % ctx)
	_check(m.estado.exportar_guardado()["entradas"].size() == entradas, "%s: el rechazo se registró como entrada" % ctx)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Negativos", "NEG", "metropolitana", resp, datos["ideologia"])
	var m: MotorTurno = null
	var gobierno := false
	for semilla in range(900, 940):  # una partida que llegue al gobierno con campaña jugada
		m = Partida.crear(datos, semilla, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if Bots.elegir(m, datos, "codicioso", rng):
			gobierno = true
			break
	_check(gobierno, "se llegó al gobierno")
	if not gobierno:
		quit(1)
		return
	var est := m.estado
	var h := est.calcular_huella()
	var n: int = est.exportar_guardado()["entradas"].size()
	_rechaza(m, m.jugar_carta(-1), "indice_invalido", h, n, "índice negativo")
	_rechaza(m, m.jugar_carta(est.mano.size()), "indice_invalido", h, n, "índice fuera de la mano")
	_rechaza(m, m.jugar_carta(0, "min_que_no_existe"), "ministro_no_disponible", h, n, "ministro inexistente")
	_rechaza(m, m.jugar_carta(0, "", "region_que_no_existe"), "region_invalida", h, n, "región inexistente")
	var fuera := ""
	for id in m.catalogo_ministros:
		if not est.gabinete.has(id):
			fuera = String(id)
			break
	if fuera != "":
		_rechaza(m, m.jugar_carta(0, fuera), "ministro_fuera_del_gabinete", h, n, "ministro fuera del gabinete")
		_rechaza(m, m.delegar_carta(0, fuera), "ministro_fuera_del_gabinete", h, n, "delegar en ministro fuera del gabinete")
	# sin movimientos no se juega
	est.pa_actual = 0
	var h0 := est.calcular_huella()
	var idx_cara := -1
	for i in range(est.mano.size()):
		if m.costo_carta(est.mano[i]) > 0:
			idx_cara = i
			break
	if idx_cara >= 0:
		_rechaza(m, m.jugar_carta(idx_cara), "pa_insuficiente", h0, n, "sin movimientos")
	# la delegación tiene tope por turno
	est.pa_actual = est.pa_maximo
	var tope := int(m.catalogo_leyes["delegacion"]["max_por_turno"])
	var ministro := String(est.gabinete[0])
	for _i in range(tope):
		m.delegar_carta(0, ministro)
	var h1 := est.calcular_huella()
	var n1: int = est.exportar_guardado()["entradas"].size()
	var r := m.delegar_carta(0, ministro)
	_check(not bool(r["ok"]) and est.calcular_huella() == h1 and est.exportar_guardado()["entradas"].size() == n1, "la delegación sobre el tope se rechaza sin cambiar nada (%s)" % str(r))
	# una carta única ya ejecutada no se repite
	for c in est.mano:
		if m.es_unica(c):
			est.cartas_ejecutadas[String(c["id"])] = true
			var h2 := est.calcular_huella()
			var n2: int = est.exportar_guardado()["entradas"].size()
			var idx := est.mano.find(c)
			_rechaza(m, m.jugar_carta(idx), "ya_ejecutada", h2, n2, "carta única ya ejecutada")
			break
	# partida terminada: ninguna acción vale
	var fin := Bots.partida_completa(datos, 31, "codicioso")
	var hf := fin.estado.calcular_huella()
	var nf: int = fin.estado.exportar_guardado()["entradas"].size()
	if not Motor_ETAPAS(fin):
		_rechaza(fin, fin.jugar_carta(0), "partida_terminada", hf, nf, "partida terminada")
	print("test_rechazos_legales: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)


func Motor_ETAPAS(m: MotorTurno) -> bool:
	return MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa)
