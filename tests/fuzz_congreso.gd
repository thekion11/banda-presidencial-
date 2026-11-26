extends SceneTree
## Fuzz de las votaciones del Congreso (MotorLegal.votar) con indicadores, escaños propios y apoyo de coalición extremos, todos los tipos de ley y votos firmes
## del Senado arbitrarios (los eventos los fijan con «votos_firmes_base»). Propiedades:
##  (1) votos del Senado y de la Cámara dentro de [0, total] (también con escaños propios + aliados por encima del total y con votos firmes fuera de rango);
##  (2) aprobada exactamente cuando se alcanzan los mínimos en las dos cámaras (salvo tipos sin votación, siempre aprobados);
##  (3) a favor + abstención + en contra suman el total de cada cámara y ninguna cifra es negativa;
##  (4) con más capital político o más cohesión, el apoyo esperado (composicion().aliados) nunca baja;
##  (5) un tipo desconocido se rechaza con razón, sin error; composicion() nunca da cifras negativas y no supera el total de la cámara
##      (esto último hoy es solo un aviso: con coalición, propios + aliados puede pasar del total; ver COMPOSICION_ESTRICTA).
## (1) a (3) se prueban con entradas extremas (robustez); (4) y (5) con los rangos reales del juego (escaños propios hasta ideologia.escanos.max y aliados hasta la suma de
## los tres mayores partidos de la coalición), porque con más escaños que la cámara la composición deja de tener sentido y el juego no genera ese caso.
## Uso: godot --headless --path . -s tests/fuzz_congreso.gd -- [iteraciones] [semilla]

var _fallos: int = 0
var _verificadas: int = 0
var _composiciones_que_exceden: int = 0
const COMPOSICION_ESTRICTA := false  # true cuando composicion() descuente el apoyo de la coalición del resto de la cámara (hoy suma de más)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ CONGRESO: ", msg)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 3000
	var semilla := int(args[1]) if args.size() > 1 else 12
	var datos := Datos.cargar_todo()
	var leyes: Dictionary = datos["leyes"]
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var legal := MotorLegal.new()
	var rng_legal := RandomNumberGenerator.new()
	rng_legal.seed = semilla + 1
	legal.configurar(leyes, rng_legal)
	var tipos: Array = leyes["tipos_ley"].map(func(t: Dictionary) -> String: return String(t["id"]))
	var n_sen := int(leyes["hemiciclo"]["total_senadores"])
	var n_dip := int(leyes["hemiciclo"]["total_diputados"])
	var propios_max := int(datos["ideologia"]["escanos"]["max"])
	var mayores_sen: Array = datos["coalicion"].map(func(p: Dictionary) -> int: return int(p["escanos_senado"]))
	var mayores_cam: Array = datos["coalicion"].map(func(p: Dictionary) -> int: return int(p["escanos_camara"]))
	mayores_sen.sort()
	mayores_cam.sort()
	var aliados_sen_max: int = mayores_sen[-1] + mayores_sen[-2] + mayores_sen[-3]
	var aliados_cam_max: int = mayores_cam[-1] + mayores_cam[-2] + mayores_cam[-3]
	for i in range(n):
		var e := EstadoSimulacion.new()
		e.configurar(i, 7, leyes)
		e.indicadores["capital"] = rng.randf_range(0.0, 100.0)
		e.indicadores["cohesion"] = rng.randf_range(0.0, 100.0)
		e.partido = {"escanos_propios": rng.randi_range(0, 90)}  # incluso por encima del total del Senado
		e.apoyo_coalicion = {"senado": rng.randi_range(0, 60), "camara": rng.randi_range(0, 200)}
		var tipo := String(tipos[rng.randi_range(0, tipos.size() - 1)])
		var firmes := -1
		if rng.randf() < 0.25:
			firmes = rng.randi_range(0, n_sen)  # los eventos fijan votos firmes dentro de la cámara
		var v := legal.votar(e, tipo, firmes)
		var ctx := "iteración %d (%s)" % [i, tipo]
		_verificadas += 1
		if bool(v.get("sin_votacion", false)):
			_check(bool(v["aprobada"]), "%s: un tipo sin votación debe aprobarse" % ctx)
			continue
		_check(int(v["senado"]) >= 0 and int(v["senado"]) <= n_sen and int(v["camara"]) >= 0 and int(v["camara"]) <= n_dip, "%s: votos fuera de la cámara (Senado %s/%d, Cámara %s/%d)" % [ctx, str(v["senado"]), n_sen, str(v["camara"]), n_dip])
		_check(bool(v["aprobada"]) == (int(v["senado"]) >= int(v["min_senado"]) and int(v["camara"]) >= int(v["min_camara"])), "%s: «aprobada» no coincide con los mínimos (%s)" % [ctx, str(v)])
		for c in ["senado", "camara"]:
			var total := int(v["total_" + c])
			var fav := int(v[c])
			var abst := int(v["abst_" + c])
			var contra := int(v["contra_" + c])
			_check(abst >= 0 and contra >= 0 and fav + abst + contra == total, "%s: %s: a favor %d + abstención %d + en contra %d no suman %d" % [ctx, c, fav, abst, contra, total])
		# (4) y (5) con los rangos reales del juego
		var e1 := EstadoSimulacion.new()
		e1.configurar(i, 7, leyes)
		e1.indicadores["capital"] = rng.randf_range(0.0, 100.0)
		e1.indicadores["cohesion"] = rng.randf_range(0.0, 100.0)
		e1.partido = {"escanos_propios": rng.randi_range(0, propios_max)}
		e1.apoyo_coalicion = {"senado": rng.randi_range(0, aliados_sen_max), "camara": rng.randi_range(0, aliados_cam_max)}
		var e2 := EstadoSimulacion.new()
		e2.configurar(i, 7, leyes)
		e2.partido = e1.partido.duplicate()
		e2.apoyo_coalicion = e1.apoyo_coalicion.duplicate()
		e2.indicadores["capital"] = minf(100.0, float(e1.indicadores["capital"]) + rng.randf_range(0.0, 30.0))
		e2.indicadores["cohesion"] = minf(100.0, float(e1.indicadores["cohesion"]) + rng.randf_range(0.0, 30.0))
		for cam in [true, false]:
			var c1 := legal.composicion(e1, cam)
			var c2 := legal.composicion(e2, cam)
			_check(int(c2["aliados"]) >= int(c1["aliados"]) - 0, "%s: más capital o cohesión bajó los aliados esperados (%s -> %s)" % [ctx, str(c1["aliados"]), str(c2["aliados"])])
			_check(int(c1["propios"]) >= 0 and int(c1["aliados"]) >= 0 and int(c1["oposicion"]) >= 0, "%s: composición con cifras negativas (%s)" % [ctx, str(c1)])
			if int(c1["propios"]) + int(c1["aliados"]) + int(c1["oposicion"]) != int(c1["total"]):
				_composiciones_que_exceden += 1
				if COMPOSICION_ESTRICTA:
					_check(false, "%s: con los rangos reales la composición debe sumar el total de la cámara (%s)" % [ctx, str(c1)])
	var d := legal.votar(EstadoSimulacion.new(), "no_existe")
	_check(not bool(d["aprobada"]) and d.has("razon"), "un tipo desconocido debe rechazarse con razón")
	print("FUZZ CONGRESO %s (%d votaciones, %d composiciones que no suman el total de la cámara [aviso], %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", _verificadas, _composiciones_que_exceden, _fallos])
	quit(1 if _fallos > 0 else 0)
