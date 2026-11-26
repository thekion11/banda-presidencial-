extends SceneTree
## Fuzz de composición del gabinete de 25 ministerios: elecciones parciales, repetidas, inválidas o con dos candidatos del mismo ministerio.
## Invariantes: el relleno nunca pisa lo escogido, deja un candidato por ministerio, es determinista y completa los 25 cargos; elegir rechaza lo inválido sin cambiar nada.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1
		if _fallos > 20:
			quit(1)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Gabinete", "GAB", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, 3, partido)
	var g: MotorGabinete = m.gabinete
	var tam := int(datos["leyes"]["gabinete"]["tamano"])
	var ids: Array = m.catalogo_ministros.keys()
	ids.sort()
	var slots := {}
	for id in ids:
		slots[g.slot_de(String(id))] = true
	_check(slots.size() >= tam, "el catálogo cubre al menos %d ministerios (%d)" % [tam, slots.size()])
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var modos: Array = datos["leyes"]["gabinete"]["relleno"]["modos"].keys()
	var rellenos := 0
	for _n in range(400):
		var k := rng.randi_range(0, tam + 6)
		var elegidos: Array = []
		for _i in range(k):
			var r := rng.randi_range(0, 9)
			if r == 0:
				elegidos.append("no_existe_%d" % rng.randi_range(0, 5))  # inválido
			elif r == 1 and not elegidos.is_empty():
				elegidos.append(elegidos[rng.randi_range(0, elegidos.size() - 1)])  # repetido
			else:
				elegidos.append(ids[rng.randi_range(0, ids.size() - 1)])
		var modo := String(modos[rng.randi_range(0, modos.size() - 1)])
		var res: Array[Dictionary] = g.rellenar(elegidos, modo)
		var res2: Array[Dictionary] = g.rellenar(elegidos, modo)
		_check(res == res2, "el relleno es determinista")
		# lo escogido válido (primer candidato por ministerio) se conserva y el resto lo completa
		var final: Array[String] = []
		var usados := {}
		for id in elegidos:
			if m.catalogo_ministros.has(String(id)) and not usados.has(g.slot_de(String(id))):
				final.append(String(id))
				usados[g.slot_de(String(id))] = true
		var base := final.size()
		for a in res:
			var id := String(a["id"])
			_check(m.catalogo_ministros.has(id), "relleno con id existente")
			_check(not usados.has(g.slot_de(id)), "el relleno no pisa un ministerio ya escogido (%s)" % id)
			_check(String(a["motivo"]) != "", "el relleno explica su motivo")
			usados[g.slot_de(id)] = true
			final.append(id)
		_check(final.size() == tam, "el gabinete completo tiene %d cargos (tiene %d, escogidos válidos %d)" % [tam, final.size(), base])
		_check(res.size() == tam - base, "se añaden solo los cargos vacíos")
		rellenos += 1
		# si la lista completa es válida, elegir la acepta y la guarda tal cual
		var h0 := m.estado.calcular_huella()
		var r2 := g.elegir(final)
		if m.estado.turno_actual == 1:
			_check(bool(r2["ok"]) and m.estado.gabinete == final, "elegir acepta un gabinete completo y válido")
		# una lista inválida se rechaza sin cambiar el estado
		var h1 := m.estado.calcular_huella()
		var mala := final.duplicate()
		mala[0] = mala[mala.size() - 1]  # repetido
		var rm := g.elegir(mala)
		_check(not bool(rm["ok"]) and m.estado.calcular_huella() == h1, "elegir rechaza un candidato repetido sin cambiar el estado")
		var corta := final.slice(0, tam - 1)
		_check(not bool(g.elegir(corta)["ok"]), "elegir rechaza un gabinete de tamaño distinto")
		_check(h0 != "", "huella calculada")
	print("test_gabinete_fuzz: ", "OK (%d composiciones)" % rellenos if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
