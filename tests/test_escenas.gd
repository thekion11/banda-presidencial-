extends SceneTree
## Escenas de varias rondas (PR-10): el debate final se juega en tres rondas el mismo día, todas con decisión, y se reproduce exacto.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var escenas := {}
	for e in datos["eventos"]:
		if e.has("escena"):
			var n := String(e["escena"]["nombre"])
			escenas[n] = int(escenas.get(n, 0)) + 1
			_check(e.has("opciones") and e["opciones"].size() == 3 or e["opciones"].size() == 2 or e["opciones"].size() == 3, "%s con opciones" % e["id"])
	for n in escenas.keys():
		_check(escenas[n] >= 2, "la escena %s tiene al menos 2 rondas" % n)
	_check(escenas.has("Debate presidencial final") and int(escenas["Debate presidencial final"]) == 3, "debate final en 3 rondas")
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("E", "EEE", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, 77, partido)
	var rondas := 0
	var vistos := {}
	for _t in range(8):
		for ev in m.ultimos_eventos:
			if ev.has("escena") and ev["escena"]["nombre"] == "Debate presidencial final":
				rondas += 1
				_check(int(ev["escena"]["ronda"]) == rondas, "las rondas llegan en orden")
				_check(bool(m.eventos.decidir(String(ev["id"]), rondas % 3)["ok"]), "decidir la ronda %d" % rondas)
				vistos[ev["id"]] = true
		m.terminar_turno()
	_check(rondas == 3, "se juegan las 3 rondas del debate final (%d)" % rondas)
	var g := Partida.reproducir(datos, m.estado.exportar_guardado(Datos.huella(datos)))
	_check(g != null and Huella.sha(ResumenEstado.de(g.estado)) == Huella.sha(ResumenEstado.de(m.estado)), "la escena se reproduce exacta")
	print("test_escenas: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
