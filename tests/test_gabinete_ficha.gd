extends SceneTree
## Salidas del gabinete para la UI (ficha_candidato, efecto_semanal_de, efecto_de_nombrar): no cambian el estado y coinciden con lo que aplica `amanecer`.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		print("FALLO GABINETE FICHA: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var m := AyudaV2.gobierno(datos, 41, [])
	var g := m.gabinete
	var gab: Array = m.estado.gabinete.duplicate()
	_check(gab.size() == int(datos["leyes"]["gabinete"]["tamano"]), "gabinete completo por defecto")
	# 1) coincide con lo que aplica amanecer (tolerancia de coma flotante)
	var antes := m.estado.indicadores.duplicate()
	g.amanecer()
	var esperado := g.efecto_semanal_de(gab)
	for k in esperado.keys():
		_check(absf((float(m.estado.indicadores[k]) - float(antes[k])) - float(esperado[k])) < 1e-6, "amanecer aplica lo mismo que efecto_semanal_de (%s)" % k)
	# 2) efecto_de_nombrar: reemplazar por otro candidato del mismo ministerio
	var firma := m.estado.exportar_json("")
	var cand := ""
	for id in datos["ministros"].map(func(x): return String(x["id"])):
		if g.slot_de(id) == g.slot_de(gab[0]) and id != gab[0]:
			cand = id
			break
	_check(cand != "", "hay otro candidato en el mismo ministerio")
	var dif := g.efecto_de_nombrar(cand)
	var nuevo: Array = gab.duplicate()
	nuevo[0] = cand
	var a := g.efecto_semanal_de(gab)
	var b := g.efecto_semanal_de(nuevo)
	for k in dif.keys():
		_check(absf(float(dif[k]) - (float(b.get(k, 0.0)) - float(a.get(k, 0.0)))) < 1e-9, "diferencia de %s" % k)
	_check(g.efecto_de_nombrar(gab[0]).is_empty(), "nombrar al que ya está no cambia nada")
	# 3) ficha
	var f := g.ficha_candidato(cand)
	for k in ["id", "alias", "cartera", "ministerio", "estilo", "rasgo", "categoria_afin", "afinidad", "reduccion_costo_pa", "bono_ejecucion", "riesgo_escandalo"]:
		_check(f.has(k), "ficha tiene %s" % k)
	_check(float(f["afinidad"]) >= 0.0 and float(f["afinidad"]) <= 1.0, "afinidad entre 0 y 1")
	# 4) solo salida
	_check(m.estado.exportar_json("") == firma, "las consultas no cambian el estado")
	print("test_gabinete_ficha: ", "OK" if _fallos == 0 else "FALLOS %d" % _fallos)
	quit(1 if _fallos > 0 else 0)
