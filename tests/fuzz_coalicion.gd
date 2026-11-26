extends SceneTree
## Fuzz de coalición, crisis e indicadores fiscales. Invariantes que nunca deben violarse, con acciones aleatorias e inválidas (unirse, salir, asignar y quitar
## cuotas, contratar y despedir asesores, cambiar el gabinete) a lo largo de carreras completas, con y sin partido existente (aliado «propio»):
##  C1 los aliados existen en el catálogo y los no propios no superan max_aliados;  C2 satisfacción finita en [0, 100];
##  C3 un ministerio o un asesor está asignado a un solo aliado, sin repetirse dentro de una lista;
##  C4 el apoyo en el Congreso no es negativo y no supera los escaños de los aliados no propios;  C5 cumplimiento en [0, 1] y objetivo en [0, 100];
##  C6 el partido propio no se abandona con salir() sin ruptura;  C7 la crisis: semanas_en_crisis >= 0, etapa «crisis» solo si superó el umbral y «gobierno» solo si no;
##  C8 tras el amanecer de gobierno ningún aliado queda bajo el umbral de ruptura;  C9 fiscal, capital y cohesión finitos y en [0, 100].
## Uso: godot --headless --path . -s tests/fuzz_coalicion.gd -- [partidas] [semilla_inicial]

var _fallos: int = 0
var _datos: Dictionary
var _aliados_vistos: int = 0
var _rupturas: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ COALICION: ", msg)


func _invariantes(m: MotorTurno, ctx: String) -> void:
	var e := m.estado
	var cfg: Dictionary = _datos["leyes"]["coalicion"]
	var no_propios := 0
	var min_vistos := {}
	var ase_vistos := {}
	var sen_max := 0.0
	var cam_max := 0.0
	for id in e.coalicion.keys():
		var c: Dictionary = e.coalicion[id]
		_check(m.coalicion.partidos.has(id), "%s: aliado «%s» fuera del catálogo" % [ctx, id])
		if not m.coalicion.partidos.has(id):
			continue
		var sat := float(c["satisfaccion"])
		_check(is_finite(sat) and sat >= -0.001 and sat <= 100.001, "%s: satisfacción de %s fuera de rango (%s)" % [ctx, id, str(sat)])
		if not bool(c.get("propio", false)):
			no_propios += 1
			sen_max += float(m.coalicion.partidos[id]["escanos_senado"])
			cam_max += float(m.coalicion.partidos[id]["escanos_camara"])
		for mi in c["ministros"]:
			_check(not min_vistos.has(mi), "%s: el ministerio %s está asignado a más de un aliado o repetido" % [ctx, str(mi)])
			min_vistos[mi] = true
		for a in c["asesores"]:
			_check(not ase_vistos.has(a), "%s: el asesor %s está asignado a más de un aliado o repetido" % [ctx, str(a)])
			ase_vistos[a] = true
		var cu := m.coalicion.cumplimiento(id)
		var ob := m.coalicion.objetivo(id)
		_check(cu >= 0.0 and cu <= 1.0, "%s: cumplimiento de %s fuera de [0,1] (%s)" % [ctx, id, str(cu)])
		_check(ob >= -0.001 and ob <= 100.001, "%s: objetivo de %s fuera de [0,100] (%s)" % [ctx, id, str(ob)])
	_aliados_vistos = maxi(_aliados_vistos, e.coalicion.size())
	_check(no_propios <= int(cfg["max_aliados"]), "%s: %d aliados no propios (máx. %d)" % [ctx, no_propios, int(cfg["max_aliados"])])
	_check(int(e.apoyo_coalicion["senado"]) >= 0 and float(e.apoyo_coalicion["senado"]) <= sen_max + 0.5, "%s: apoyo en el Senado %s con aliados que suman %s" % [ctx, str(e.apoyo_coalicion["senado"]), str(sen_max)])
	_check(int(e.apoyo_coalicion["camara"]) >= 0 and float(e.apoyo_coalicion["camara"]) <= cam_max + 0.5, "%s: apoyo en la Cámara %s con aliados que suman %s" % [ctx, str(e.apoyo_coalicion["camara"]), str(cam_max)])
	for k in ["fiscal", "capital", "cohesion", "aprobacion"]:
		var v := e.ind(k)
		_check(is_finite(v) and v >= -0.001 and v <= 100.001, "%s: %s fuera de [0,100] (%s)" % [ctx, k, str(v)])
	var d: Dictionary = _datos["leyes"]["dinamica"]
	_check(e.semanas_en_crisis >= 0, "%s: semanas_en_crisis negativas" % ctx)
	if e.etapa == "crisis":
		_check(e.semanas_en_crisis >= int(d["semanas_crisis_para_caida"]), "%s: etapa crisis con solo %d semanas en crisis" % [ctx, e.semanas_en_crisis])
	if e.etapa == "gobierno":
		_check(e.semanas_en_crisis < int(d["semanas_crisis_para_caida"]), "%s: sigue el gobierno con %d semanas en crisis" % [ctx, e.semanas_en_crisis])


func _accion(m: MotorTurno, rng: RandomNumberGenerator, ctx: String) -> void:
	var e := m.estado
	var basura := ["", "no_existe"]
	var ids: Array = m.coalicion.partidos.keys() + basura
	var id := String(ids[rng.randi_range(0, ids.size() - 1)])
	match rng.randi_range(0, 6):
		0, 1:
			m.unirse_coalicion(id)
		2:
			var propio := e.coalicion.has(id) and bool(e.coalicion[id].get("propio", false))
			var r := m.salir_coalicion(id)
			if propio:
				_check(not bool(r["ok"]), "%s: se abandonó el partido propio %s con salir() sin ruptura" % [ctx, id])
		3, 4:
			var tipos := ["ministerio", "asesor"]
			var t := String(tipos[rng.randi_range(0, 1)])
			var vals: Array = (e.gabinete.duplicate() if t == "ministerio" else e.asesores.duplicate()) + basura
			var v := String(vals[rng.randi_range(0, vals.size() - 1)])
			if rng.randf() < 0.6:
				m.asignar_cuota(id, t, v)
			else:
				m.quitar_cuota(id, t, v)
		5:
			var aids: Array = m.equipo.asesores.keys() + basura
			var a := String(aids[rng.randi_range(0, aids.size() - 1)])
			if rng.randf() < 0.6:
				m.contratar_asesor(a)
			else:
				m.despedir_asesor(a)
		6:
			if e.etapa == "campana" and rng.randf() < 0.3:
				m.elegir_gabinete(AyudaV2.ministros_de(_datos, ["salud", "transportes", "vivienda"], int(_datos["leyes"]["gabinete"]["tamano"])))
	_invariantes(m, ctx)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 8
	var s0 := int(args[1]) if args.size() > 1 else 1700
	_datos = Datos.cargar_todo()
	var cfg_af: Dictionary = _datos["leyes"]["afiliacion"]
	var umbral_ruptura := float(_datos["leyes"]["coalicion"]["umbral_ruptura"])
	for i in range(n):
		var semilla := s0 + i
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla * 23 + 11
		var resp: Array[Dictionary] = []
		for p in _datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rng.randi_range(0, 2)])
		var partido: Dictionary
		if i % 2 == 1:  # partido existente: trae un aliado «propio»
			var base: Dictionary = _datos["coalicion"][semilla % _datos["coalicion"].size()]
			partido = GeneradorPartido.construir_partido_afiliado("existente", base, String(base["nombre"]), String(base["sigla"]), "metropolitana", resp.slice(0, 3), _datos["ideologia"], cfg_af)
		else:
			partido = GeneradorPartido.construir_partido("C", "CCC", "metropolitana", resp, _datos["ideologia"])
		partido["indicadores_iniciales"]["aprobacion"] = 90.0
		var m := Partida.crear(_datos, semilla, partido)
		var ctx := "semilla %d%s" % [semilla, " (existente)" if i % 2 == 1 else ""]
		var pasos := 0
		var sem_camp := int(_datos["leyes"]["hemiciclo"]["semanas_campana"])
		while MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa) and pasos < 260:
			pasos += 1
			for _a in range(rng.randi_range(2, 10)):
				_accion(m, rng, ctx)
			if rng.randf() < 0.7:
				Bots.jugar_turno(m, "codicioso", rng)
			var antes := m.estado.coalicion.size()
			if m.estado.eleccion_pendiente(sem_camp):
				Bots.elegir(m, _datos, "codicioso", rng)
			else:
				m.terminar_turno()
			if m.estado.etapa == "gobierno":
				if m.estado.coalicion.size() < antes:
					_rupturas += 1
				for id in m.estado.coalicion.keys():
					_check(float(m.estado.coalicion[id]["satisfaccion"]) >= umbral_ruptura, "%s: el aliado %s sigue en la coalición con satisfacción %s bajo el umbral de ruptura (%s) tras el amanecer" % [ctx, id, str(m.estado.coalicion[id]["satisfaccion"]), str(umbral_ruptura)])
			_invariantes(m, ctx)
	print("FUZZ COALICION %s (%d partidas, máx. %d aliados a la vez, %d turnos con salidas de aliados, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _aliados_vistos, _rupturas, _fallos])
	quit(1 if _fallos > 0 else 0)
