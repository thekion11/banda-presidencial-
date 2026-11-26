extends SceneTree
## Propiedad: misma semilla + mismas entradas = mismo resultado exacto, en las 3 dificultades × 3 afiliaciones (propio, independiente, existente).
## Para cada combinación y cada semilla: (1) dos partidas idénticas dan la misma huella y el mismo resultado final; (2) el guardado (tras un ciclo JSON)
## se reproduce idéntico; (3) el guardado conserva dificultad y afiliación; (4) la carrera llega a una etapa válida con indicadores acotados.
## Imprime una tabla informativa de cómo terminan las partidas por combinación (para buscar estrategias dominantes).
## Uso: godot --headless --path . -s tests/fuzz_propiedades.gd -- [semillas_por_combinacion] [semilla_inicial]

var _fallos: int = 0
var _datos: Dictionary
const DIFICULTADES := ["facil", "normal", "dificil"]
const AFILIACIONES := ["propio", "independiente", "existente"]


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO PROPIEDADES: ", msg)


func _partido(afiliacion: String, dificultad: String, semilla: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla * 7 + 1
	var resp: Array[Dictionary] = []
	for p in _datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][rng.randi_range(0, 2)])
	var cfg: Dictionary = _datos["leyes"]["afiliacion"]
	var base: Dictionary = {}
	if afiliacion == "existente":
		base = _datos["coalicion"][semilla % _datos["coalicion"].size()]
		resp = resp.slice(0, 3)
	var nombre := String(base["nombre"]) if afiliacion == "existente" else "Partido Prueba"
	var sigla := String(base["sigla"]) if afiliacion == "existente" else "PRU"
	var partido := GeneradorPartido.construir_partido_afiliado(afiliacion, base, nombre, sigla, "metropolitana", resp, _datos["ideologia"], cfg)
	partido["dificultad"] = dificultad
	return partido


func _jugar(semilla: int, partido: Dictionary) -> MotorTurno:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla * 31 + 7
	var m := Partida.crear(_datos, semilla, partido.duplicate(true))
	var est := m.estado
	for _s in range(int(_datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	if Bots.elegir(m, _datos, "codicioso", rng):
		var guard := 0
		while est.etapa == "gobierno" and guard < 260:
			guard += 1
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
	return m


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 3
	var s0 := int(args[1]) if args.size() > 1 else 800
	_datos = Datos.cargar_todo()
	var huella := Datos.huella(_datos)
	var tabla := {}
	for dif in DIFICULTADES:
		for af in AFILIACIONES:
			var finales := {}
			for i in range(n):
				var semilla := s0 + i
				var ctx := "%s/%s/semilla %d" % [dif, af, semilla]
				var partido := _partido(af, dif, semilla)
				var a := _jugar(semilla, partido)
				var b := _jugar(semilla, partido)
				_check(a.estado.calcular_huella() == b.estado.calcular_huella(), ctx + ": dos partidas idénticas dieron huellas distintas")
				_check(Huella.texto(a.estado.resultado_final) == Huella.texto(b.estado.resultado_final), ctx + ": el resultado final difiere entre dos partidas idénticas")
				var g: Dictionary = JSON.parse_string(JSON.stringify(a.estado.exportar_guardado(huella)))
				_check(String(g["partido"].get("dificultad", "")) == dif, ctx + ": el guardado perdió la dificultad")
				_check(String(g["partido"].get("afiliacion", "propio")) == af or af == "propio", ctx + ": el guardado perdió la afiliación")
				var rep := Partida.reproducir(_datos, g)
				_check(rep.estado.calcular_huella() == a.estado.calcular_huella(), ctx + ": el replay no es idéntico (etapa %s)" % a.estado.etapa)
				_check(["gobierno", "fin_mandato", "crisis", "derrota_electoral"].has(a.estado.etapa), ctx + ": etapa final inesperada «%s»" % a.estado.etapa)
				for k in a.estado.indicadores:
					var v := float(a.estado.indicadores[k])
					_check(is_finite(v) and (k == "viviendas_anio" or (v >= -0.001 and v <= 100.001)), "%s: indicador %s fuera de rango (%s)" % [ctx, k, str(v)])
				finales[a.estado.etapa] = int(finales.get(a.estado.etapa, 0)) + 1
			tabla["%s/%s" % [dif, af]] = finales
	for k in tabla:
		print("  ", k, " -> ", tabla[k])
	print("FUZZ PROPIEDADES %s (%d combinaciones × %d semillas, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", DIFICULTADES.size() * AFILIACIONES.size(), n, _fallos])
	quit(1 if _fallos > 0 else 0)
