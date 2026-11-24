extends SceneTree
## Líneas de Metro del mapa: datos coherentes con la lista de estaciones, ocultar/mostrar líneas y toque sobre una línea.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO METRO: ", msg)


func _init() -> void:
	var d := UrbanoBase.datos()
	_check(not d.is_empty(), "faltan los datos urbanos")
	var ids := UrbanoBase.ids_lineas()
	_check(ids.size() == 7, "deben existir 7 líneas (L1, L2, L3, L4, L4A, L5, L6); hay %d" % ids.size())
	var con_lineas := 0
	var combinaciones := 0
	for e in d["estaciones"]:
		var l: Array = e.get("l", [])
		if not l.is_empty():
			con_lineas += 1
		if l.size() > 1:
			combinaciones += 1
	_check(con_lineas == d["estaciones"].size(), "toda estación debe pertenecer a alguna línea (%d de %d)" % [con_lineas, d["estaciones"].size()])
	_check(combinaciones == 17, "deben ser 17 estaciones de combinación; hay %d" % combinaciones)
	for l in d["metro"]:
		_check(l.get("cabos", []).size() == 2, "la línea %s debe tener dos cabos" % l["id"])
	UrbanoBase.ocultas.clear()
	var tam := Vector2(370, 400)
	var mar := Vector2(8, 8)
	var c := UrbanoBase.preparar(tam, mar)
	var l5: Dictionary = {}
	for l in c["metro"]:
		if l["id"] == "L5":
			l5 = l
	var punto: Vector2 = l5["seg"][40]
	_check(UrbanoBase.linea_en(punto, tam, mar) != "", "tocar sobre una línea debe encontrarla")
	_check(UrbanoBase.linea_en(Vector2(-500, -500), tam, mar) == "", "tocar lejos de toda línea no debe encontrar nada")
	UrbanoBase.alternar_linea("L5")
	_check(UrbanoBase.ocultas.has("L5"), "alternar debe ocultar la línea")
	_check(UrbanoBase.linea_en(punto, tam, mar) != "L5", "una línea oculta no debe responder al toque")
	UrbanoBase.alternar_linea("L5")
	_check(not UrbanoBase.ocultas.has("L5"), "alternar de nuevo debe mostrarla")
	UrbanoBase.ocultas.clear()
	_sugerencias()
	_lineas_del_jugador()
	if _fallos == 0:
		print("METRO OK (7 líneas, %d estaciones, 17 combinaciones; ocultar y tocar línea)" % d["estaciones"].size())
	quit(0 if _fallos == 0 else 1)



func _lineas_del_jugador() -> void:
	## La línea aprobada (predeterminada A/B/C o a gusto) queda guardada: se registra, pasa a operativa al terminar su obra y se reproduce igual.
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = [datos["ideologia"]["preguntas"][0]["opciones"][1]]
	var partido := GeneradorPartido.construir_partido("Test", "TST", "metropolitana", resp, datos["ideologia"])
	var huellas: Array[String] = []
	for vuelta in range(2):
		var m := Partida.crear(datos, 99, partido)
		m.estado.etapa = "gobierno"
		m.estado.pa_actual = 8
		var prop: Dictionary = datos["propuestas"][0]
		m.estado.propuestas_abiertas.append(String(prop["id"]))
		var r := m.aprobar_propuesta(String(prop["id"]), "B", "", {}, {"linea": "  Línea\tdel  Sur\n" + "x".repeat(40), "estaciones": ["Plaza Nueva", "", "Hospital\nBase"]})
		_check(bool(r["ok"]), "no se pudo aprobar la variante predeterminada")
		_check(m.estado.lineas_jugador.size() == 1, "aprobar una variante debe crear una línea del jugador")
		var ln: Dictionary = m.estado.lineas_jugador[0]
		_check(ln["id"] == "P1" and ln["estado"] == "en_construccion" and ln["variante"] == "B", "la línea nace en construcción, con id P1 y la variante elegida")
		_check(String(ln["nombre"]).begins_with("Línea del Sur x") and String(ln["nombre"]).length() <= 30 and not ("\t" in String(ln["nombre"])), "el nombre de la línea se limpia (espacios, tabuladores) y se recorta a 30 caracteres: %s" % ln["nombre"])
		_check(ln["nombres_estaciones"][0] == "Plaza Nueva" and ln["nombres_estaciones"][1] == "Estación 2" and ln["nombres_estaciones"][2] == "Hospital Base", "los nombres de estaciones se guardan; los vacíos toman «Estación N»: %s" % [ln["nombres_estaciones"]])
		_check(String(m.estado.obras_en_curso[0]["nombre"]).begins_with("Línea del Sur x") and m.estado.obras_en_curso[0]["linea"] == "P1", "la obra usa el nombre de la línea y apunta a ella")
		_check((ln["trazado"] as Array).size() >= 2 and (ln["estaciones"] as Array).size() >= 3, "la línea debe guardar su trazado y sus estaciones")
		# línea a gusto: otra propuesta, estaciones propias
		var ests: Array = m.grafo.estaciones_base(prop["variantes"][0])
		var prop2: Dictionary = datos["propuestas"][1] if datos["propuestas"].size() > 1 else prop
		if prop2["id"] != prop["id"]:
			m.estado.propuestas_abiertas.append(String(prop2["id"]))
			var custom := {"base": String(prop2["variantes"][0]["id"]), "estaciones": ests, "ritmo": 0.3, "cobertura": 0.2}
			var c: Dictionary = custom if vuelta == 0 else JSON.parse_string(JSON.stringify(custom))
			var r2 := m.aprobar_propuesta(String(prop2["id"]), "A", "", c)
			_check(bool(r2["ok"]) and m.estado.lineas_jugador.size() == 2 and m.estado.lineas_jugador[1]["id"] == "P2" and m.estado.lineas_jugador[1]["variante"] == "M", "una línea a gusto debe guardarse como P2 (variante M)")
		_check(m.estado.exportar_guardado("h")["entradas"].size() > 0, "el guardado debe traer los eventos que reconstruyen la línea")
		m.obras.avanzar(m.estado, 100000, m.fx.aplicar_efecto, m.fx.marcar_cumplida)
		for l in m.estado.lineas_jugador:
			_check(l["estado"] == "operativa", "al terminar la obra la línea debe quedar operativa")
		huellas.append(m.estado.calcular_huella())
	_check(huellas[0] == huellas[1], "las líneas del jugador deben ser reproducibles (misma huella, incluso pasando por JSON)")


func _sugerencias() -> void:
	## Sugerencias de nombre para estaciones nuevas: según lo cercano, sin repetirse ni coincidir con una estación real.
	var d := UrbanoBase.datos()
	var plaza: Array = []
	var bicentenario: Array = []
	for l in d["lugares"]:
		if l["n"] == "Plaza de Armas":
			plaza = l["p"]
		if l["n"] == "Parque Bicentenario":
			bicentenario = l["p"]
	var s := NombresEstacion.sugerir([bicentenario, plaza, plaza, [0.0, 0.0]])
	_check(s.size() == 4 and s[0] == "Parque Bicentenario", "una posición sobre un lugar conocido toma su nombre: %s" % [s])
	_check(s[1] != "" and s[1] != s[2], "los nombres de una línea no se repiten: %s" % [s])
	_check(s[3] == "Estación 4", "sin nada cerca toma «Estación N»: %s" % s[3])
	var reales := {}
	for e in d["estaciones"]:
		reales[String(e["n"])] = true
	for n in s:
		_check(not reales.has(n), "una sugerencia no debe coincidir con una estación real: %s" % n)
	_check(NombresEstacion.sugerir([bicentenario, plaza]) == NombresEstacion.sugerir([bicentenario, plaza]), "las sugerencias son deterministas")
