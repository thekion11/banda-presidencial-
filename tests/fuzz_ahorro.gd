extends SceneTree
## Ahorro de movimientos (BL: pa_siguiente = min(max(tope_ahorro, ingreso), sobrante + ingreso), ingreso = base + bono de aprobación + asesores): en partidas con
## gasto y ahorro al azar comprueba, en cada cierre de semana, que los movimientos del amanecer siguiente son EXACTAMENTE esa fórmula (ni se pierden ni se crean),
## que nunca pasan del tope ni bajan de 0, que el cambio de periodo (campaña → gobierno → oposición) y el guardado/replay/restauración conservan el saldo, y que
## con ingreso 0 gastado el saldo crece hasta el tope y se queda ahí.
## Uso: godot --headless --path . -s tests/fuzz_ahorro.gd -- [partidas=12] [semilla=7700] [semanas=80]

var _fallos := 0
var _semanas := 0
var _topes := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ AHORRO: ", msg)


func _partido(d: Dictionary) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return GeneradorPartido.construir_partido("Ahorro", "AHO", "metropolitana", resp, d["ideologia"])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 12
	var s0 := int(args[1]) if args.size() > 1 else 7700
	var semanas := int(args[2]) if args.size() > 2 else 80
	var d := Datos.cargar_todo()
	var h := Datos.huella(d)
	for i in range(n):
		var rng := RandomNumberGenerator.new()
		rng.seed = s0 + i
		var m := Partida.crear(d, s0 + i, _partido(d))
		var tope := int(m.catalogo_leyes["mano"]["tope_ahorro"])
		var ctx := "partida %d" % i
		var gasto_modo := rng.randi_range(0, 2)  # 0 gasta casi todo, 1 ahorra casi todo, 2 mezcla
		var w := 0
		var en_gobierno := false
		while w < semanas + 8 and MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):
			var e := m.estado
			if e.etapa == "campana" and e.eleccion_pendiente(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
				if not Bots.elegir(m, d, "codicioso", rng):
					break
				en_gobierno = true
				_check(m.estado.pa_actual >= 0 and m.estado.pa_actual <= maxi(tope, e.pa_maximo + int(e.bono_mov.get("aprobacion", 0)) + int(e.bono_mov.get("asesores", 0))), "%s: movimientos %d fuera de rango al iniciar el gobierno" % [ctx, m.estado.pa_actual])
				continue
			# gasto de la semana según el modo
			var objetivo := 0
			match gasto_modo:
				0:
					objetivo = e.pa_actual
				1:
					objetivo = rng.randi_range(0, 1)
				_:
					objetivo = rng.randi_range(0, e.pa_actual)
			var gastado := 0
			var guard := 0
			while gastado < objetivo and guard < 12 and not e.mano.is_empty():
				guard += 1
				var antes := e.pa_actual
				m.jugar_carta(rng.randi_range(0, e.mano.size() - 1))
				gastado += antes - e.pa_actual
			var sobrante := e.pa_actual
			m.terminar_turno()
			if not MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):
				break
			if m.estado.etapa == "campana" and m.estado.eleccion_pendiente(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
				_check(m.estado.pa_actual == sobrante, "%s: con la elección pendiente los movimientos cambian (%d → %d): no hay amanecer" % [ctx, sobrante, m.estado.pa_actual])
				continue  # el día de las urnas no tiene amanecer: el saldo queda tal cual
			var ingreso: int = m.estado.pa_maximo + int(m.estado.bono_mov.get("aprobacion", 0)) + int(m.estado.bono_mov.get("asesores", 0))
			var esperado := mini(maxi(tope, ingreso), maxi(0, sobrante) + ingreso)
			_semanas += 1
			_topes += 1 if m.estado.pa_actual == maxi(tope, ingreso) else 0
			_check(m.estado.pa_actual == esperado, "%s semana %d (%s): movimientos %d ≠ min(max(%d, %d), %d + %d) = %d" % [ctx, w, m.estado.etapa, m.estado.pa_actual, tope, ingreso, sobrante, ingreso, esperado])
			if w % 17 == 5:  # replay y restauración conservan el saldo
				var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
				var rep := Partida.reproducir(d, g)
				_check(rep != null and rep.estado.pa_actual == m.estado.pa_actual and rep.estado.calcular_huella() == m.estado.calcular_huella(), "%s semana %d: el replay no conserva los movimientos (%d)" % [ctx, w, m.estado.pa_actual])
			w += 1
		_check(true, "")
	print("FUZZ AHORRO %s (%d partidas, %d semanas comprobadas, %d veces en el tope, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _semanas, _topes, _fallos])
	quit(1 if _fallos > 0 else 0)
