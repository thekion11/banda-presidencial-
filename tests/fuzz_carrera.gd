extends SceneTree
## Fuzz de carrera larga e instantáneas. Cada partida encadena ciclos (campaña -> gobierno u oposición -> derrota/fin -> continuar ...) con
## acciones aleatorias e inválidas y comprueba: (1) replay idéntico de toda la carrera; (2) en puntos aleatorios, que restaurar la instantánea
## (Instantanea.tomar -> leer -> Partida.cargar) dé lo mismo que reproducir el historial y que ambas sigan igual jugando 10 pasos más;
## (3) que una instantánea dañada (truncada, con bytes cambiados o basura) se descarte sin error.
## Uso: godot --headless --path . -s tests/fuzz_carrera.gd -- [partidas] [semilla_inicial]

var _fallos: int = 0
var _datos: Dictionary
var _huella: String
var _snapshots: int = 0
var _danados: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO FUZZ CARRERA: ", msg)


func _paso(m: MotorTurno, rng: RandomNumberGenerator) -> void:
	## Un turno (o el trámite que toque según la etapa) con acciones aleatorias; determinista dado el motor y el rng.
	var e := m.estado
	match e.etapa:
		"fin_mandato", "crisis", "derrota_electoral":
			if bool(m.continuar_carrera().get("ok", false)):
				m.iniciar_turno()
			return
		"campana", "gobierno", "oposicion":
			if rng.randf() < 0.5:
				Bots.jugar_turno(m, "codicioso", rng)
			for _a in range(rng.randi_range(0, 8)):
				AyudaFuzz.accion(m, rng)
			if e.eleccion_pendiente(int(_datos["leyes"]["hemiciclo"]["semanas_campana"])):
				Bots.elegir(m, _datos, "codicioso", rng)
			else:
				m.terminar_turno()
		_:
			e.etapa = "fin_mandato"  # etapa desconocida: la prueba lo detecta más abajo


func _encuestas(m: MotorTurno, ctx: String) -> void:
	## Encuestas (estado.encuestas): historial acotado, forma y rangos fijos, semanas crecientes y del periodo en curso.
	var cfg: Dictionary = _datos["leyes"]["encuestas"]
	var lista: Array = m.estado.encuestas
	_check(lista.size() <= int(cfg["historial_max"]), "%s: historial de encuestas sin acotar (%d)" % [ctx, lista.size()])
	var semana_prev := -1
	for q in lista:
		var claves: Array = q.keys()
		claves.sort()
		_check(claves == ["etapa", "intencion", "margen", "regiones", "rival", "semana", "turno", "umbral"], "%s: claves de la encuesta %s" % [ctx, str(claves)])
		_check(typeof(q["semana"]) == TYPE_INT and int(q["semana"]) > semana_prev, "%s: una encuesta por semana, con semanas crecientes (%s tras %d)" % [ctx, str(q["semana"]), semana_prev])
		semana_prev = int(q["semana"])
		_check(["campana", "oposicion"].has(String(q["etapa"])), "%s: etapa de encuesta «%s»" % [ctx, q["etapa"]])
		_check(is_finite(float(q["intencion"])) and float(q["intencion"]) >= 0.0 and float(q["intencion"]) <= 100.0, "%s: intención fuera de 0..100 (%s)" % [ctx, str(q["intencion"])])
		_check(float(q["margen"]) >= float(cfg["margen_final"]) - 0.06 and float(q["margen"]) <= float(cfg["margen_inicial"]) + 0.06, "%s: margen fuera de límites (%s)" % [ctx, str(q["margen"])])
		_check(q["umbral"] == null or (float(q["umbral"]) > 0.0 and float(q["umbral"]) <= 100.0), "%s: umbral inválido" % ctx)
		_check((q["regiones"] as Array).size() <= int(cfg["regiones_mostradas"]), "%s: demasiadas regiones" % ctx)
		var v_prev := -1.0
		for r in q["regiones"]:
			_check(float(r["valor"]) >= 0.0 and float(r["valor"]) <= 100.0 and float(r["valor"]) >= v_prev, "%s: regiones de la encuesta desordenadas o fuera de rango" % ctx)
			v_prev = float(r["valor"])


func _guardado(m: MotorTurno) -> Dictionary:
	return JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(_huella)))


func _snapshot(m: MotorTurno, ctx: String) -> void:
	_snapshots += 1
	var g := _guardado(m)
	var repro := Partida.reproducir(_datos, g)
	var snap := Instantanea.leer(Instantanea.tomar(m, _huella, "sha"))
	_check(not snap.is_empty(), ctx + ": la instantánea de una partida válida debe leerse")
	var rest := Partida.cargar(_datos, g, snap, _huella, "sha")
	var dif := AyudaFuzz.diferencias(rest, repro)
	_check(dif.is_empty(), "%s: restaurada y reproducida difieren en %s (etapa %s)" % [ctx, str(dif), m.estado.etapa])
	var r1 := RandomNumberGenerator.new()
	var r2 := RandomNumberGenerator.new()
	r1.seed = 4242
	r2.seed = 4242
	for _i in range(10):
		_paso(rest, r1)
		_paso(repro, r2)
	dif = AyudaFuzz.diferencias(rest, repro)
	_check(dif.is_empty(), "%s: tras 10 pasos más difieren en %s" % [ctx, str(dif)])


func _dañar(m: MotorTurno, rng: RandomNumberGenerator, ctx: String) -> void:
	var bytes := Instantanea.tomar(m, _huella, "sha")
	var casos: Array[PackedByteArray] = []
	casos.append(PackedByteArray())
	casos.append(bytes.slice(0, rng.randi_range(0, bytes.size() - 1)))  # truncada
	casos.append(bytes.slice(0, 4))
	var flip := bytes.duplicate()
	for _k in range(rng.randi_range(1, 8)):
		flip[rng.randi_range(0, flip.size() - 1)] = rng.randi_range(0, 255)
	casos.append(flip)
	var tam := bytes.duplicate()
	tam.encode_u32(0, rng.randi_range(0, 4000000))  # tamaño declarado falso
	casos.append(tam)
	var basura := PackedByteArray()
	basura.resize(rng.randi_range(8, 600))
	for i in range(basura.size()):
		basura[i] = rng.randi_range(0, 255)
	casos.append(basura)
	for c in casos:
		_danados += 1
		var d := Instantanea.leer(c)
		_check(d.is_empty() or int(d.get("v", 0)) == Instantanea.VERSION, ctx + ": leer devolvió algo que no es una instantánea")
		_check(not Instantanea.vale_para(d, _huella, "otro_guardado"), ctx + ": una instantánea no puede valer para otro guardado")
		_check(not Instantanea.vale_para(d, "otra_huella", "sha"), ctx + ": una instantánea no puede valer para otros datos")
		if d.is_empty():  # descartada: cargar debe reproducir el historial sin error y dar lo mismo que reproducir
			var g := _guardado(m)
			_check(Partida.cargar(_datos, g, d, _huella, "sha").estado.calcular_huella() == Partida.reproducir(_datos, g).estado.calcular_huella(), ctx + ": con instantánea descartada, cargar debe reproducir")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 6
	var s0 := int(args[1]) if args.size() > 1 else 700
	_datos = Datos.cargar_todo()
	_huella = Datos.huella(_datos)
	var etapas_vistas := {}
	var ciclos_max := 0
	for i in range(n):
		var semilla := s0 + i
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla * 13 + 5
		var resp: Array[Dictionary] = []
		for p in _datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rng.randi_range(0, 2)])
		var m := Partida.crear(_datos, semilla, GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, _datos["ideologia"]))
		var ctx := "semilla %d" % semilla
		var pasos := 0
		var ciclo_prev: int = m.estado.ciclo
		var dias_prev: int = m.estado.dias_carrera
		while pasos < 700 and m.estado.ciclo < 4:
			pasos += 1
			etapas_vistas[m.estado.etapa] = true
			_paso(m, rng)
			if rng.randf() < 0.012 and MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):
				_snapshot(m, "%s paso %d (%s)" % [ctx, pasos, m.estado.etapa])
				_dañar(m, rng, ctx)
			_check(["campana", "gobierno", "oposicion", "fin_mandato", "crisis", "derrota_electoral"].has(m.estado.etapa), "%s: etapa inesperada «%s»" % [ctx, m.estado.etapa])
			_check(m.estado.ciclo >= ciclo_prev and m.estado.dias_carrera >= dias_prev, "%s: ciclo o dias_carrera retrocedieron (ciclo %d -> %d, días %d -> %d)" % [ctx, ciclo_prev, m.estado.ciclo, dias_prev, m.estado.dias_carrera])
			ciclo_prev = m.estado.ciclo
			_encuestas(m, ctx)
			dias_prev = m.estado.dias_carrera
			for k in m.estado.indicadores:
				_check(is_finite(float(m.estado.indicadores[k])), "%s: indicador %s no finito" % [ctx, k])
		ciclos_max = maxi(ciclos_max, m.estado.ciclo)
		var rep := Partida.reproducir(_datos, _guardado(m))
		_check(Huella.texto(rep.estado.encuestas) == Huella.texto(m.estado.encuestas), "%s: las encuestas del replay no coinciden con las de la partida en vivo" % ctx)
		_check(rep.estado.calcular_huella() == m.estado.calcular_huella(), "%s: el replay de la carrera (ciclo %d, etapa %s) no es idéntico" % [ctx, m.estado.ciclo, m.estado.etapa])
	print("FUZZ CARRERA %s (%d partidas, ciclo máx. %d, etapas %s, %d instantáneas, %d dañadas, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, ciclos_max, str(etapas_vistas.keys()), _snapshots, _danados, _fallos])
	quit(1 if _fallos > 0 else 0)
