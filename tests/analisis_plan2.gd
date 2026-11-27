extends SceneTree
## Alcanzabilidad y dominancia de las cartas `plan_*` con SEMILLAS DISTINTAS por carta (rompe el artefacto de tiradas compartidas), jugada en una semana de
## gobierno dada y con distintos bots y dificultades. Por carta: % de partidas en que su votación se aprueba, % en que sale mal el riesgo, efecto neto a 52
## semanas frente a la misma partida sin jugarla, y para las leyes con votación los votos a favor medios frente al mínimo exigido (Senado/Cámara).
## Uso: godot --headless --path . -s tests/analisis_plan2.gd -- bot semana [partidas=6] [dificultad=normal] [soloreformas=0] [horizonte=52]
##   bot: azar | codicioso | humano | completo · semana: semana de gobierno en que se juega (0 = la primera)

var _datos: Dictionary
var _bot := "codicioso"
var _dif := "normal"


func _partido() -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in _datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var base := GeneradorPartido.construir_partido("Plan", "PLN", "metropolitana", resp, _datos["ideologia"])
	base["dificultad"] = _dif
	return base


func _gobierno(semilla: int, semana: int) -> MotorTurno:
	var m := Partida.crear(_datos, semilla, _partido())
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for _s in range(int(_datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, _bot, rng)
		m.terminar_turno()
	if not Bots.elegir(m, _datos, _bot, rng):
		return null
	for _w in range(semana):
		if m.estado.etapa != "gobierno":
			return null
		Bots.jugar_turno(m, _bot, rng)
		m.terminar_turno()
	return m if m.estado.etapa == "gobierno" else null


func _voto(m: MotorTurno, id: String) -> Dictionary:
	for a in m.estado.registro_acciones:
		if a["tipo"] == "votacion" and String(a["detalle"].get("carta", "")) == id:
			return a["detalle"]
	return {}


func _correr_semanas(m: MotorTurno, rng: RandomNumberGenerator, n: int) -> void:
	for _s in range(n):
		if m.estado.etapa != "gobierno":
			return
		Bots.jugar_turno(m, _bot, rng)
		m.terminar_turno()


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	_bot = args[0] if args.size() > 0 else "codicioso"
	var semana := int(args[1]) if args.size() > 1 else 0
	var n := int(args[2]) if args.size() > 2 else 6
	_dif = args[3] if args.size() > 3 else "normal"
	var solo_ref := args.size() > 4 and int(args[4]) == 1
	var hor := int(args[5]) if args.size() > 5 else 52
	_datos = Datos.cargar_todo()
	var cartas: Array = _datos["cartas"].filter(func(c: Dictionary) -> bool: return String(c["id"]).begins_with("plan_") and (not solo_ref or String(c["requisitos"]["ley"]) == "reforma_constitucional"))
	for ci in range(cartas.size()):
		var carta: Dictionary = cartas[ci]
		var validas := 0
		var votadas := 0
		var aprobadas := 0
		var mal := 0
		var jugadas := 0
		var sen := 0.0
		var cam := 0.0
		var da := 0.0
		var df := 0.0
		var dc := 0.0
		var min_sen := 0
		var min_cam := 0
		for i in range(n):
			var sd := 7000 + i * 131 + ci * 7919
			var con := _gobierno(sd, semana)
			var sin := _gobierno(sd, semana)
			if con == null or sin == null:
				continue
			validas += 1
			var t: Dictionary = con.legal.tipo(String(carta["requisitos"]["ley"]))
			min_sen = int(t.get("votos_minimos", 0))
			min_cam = int(t.get("votos_minimos_camara", 0))
			con.estado.mano.insert(0, carta.duplicate(true))
			con.estado.pa_actual = maxi(con.estado.pa_actual, 5)
			var r := con.jugar_carta(0)
			if bool(r.get("ok", false)):
				jugadas += 1
				mal += 1 if bool(r.get("salio_mal", false)) else 0
			var r1 := RandomNumberGenerator.new()
			r1.seed = sd + 5 * ci + 1
			var r2 := RandomNumberGenerator.new()
			r2.seed = sd + 5 * ci + 1
			_correr_semanas(con, r1, hor)
			_correr_semanas(sin, r2, hor)
			var v := _voto(con, String(carta["id"]))
			if not v.is_empty():
				votadas += 1
				aprobadas += 1 if bool(v.get("aprobada", false)) else 0
				sen += float(v.get("senado", 0))
				cam += float(v.get("camara", 0))
			da += con.estado.ind("aprobacion") - sin.estado.ind("aprobacion")
			df += con.estado.ind("fiscal") - sin.estado.ind("fiscal")
			dc += con.estado.ind("capital") - sin.estado.ind("capital")
		var nv := float(maxi(1, validas))
		print("R|%s|%s|%s|sem%d|%s|n=%d|vot=%d|pasa=%.0f|mal=%.0f|sen=%.1f/%d|cam=%.1f/%d|da=%+.2f|df=%+.2f|dc=%+.2f" % [carta["id"], _bot, _dif, semana, String(carta["requisitos"]["ley"]).left(5), validas, votadas, 100.0 * aprobadas / maxf(1.0, float(votadas)), 100.0 * mal / maxf(1.0, float(jugadas)), sen / maxf(1.0, float(votadas)), min_sen, cam / maxf(1.0, float(votadas)), min_cam, da / nv, df / nv, dc / nv])
	quit(0)
