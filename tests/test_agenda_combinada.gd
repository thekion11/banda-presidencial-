extends SceneTree
## Agenda legislativa combinada con delegación, urgencias, ahorro de movimientos y el resto del juego: partidas completas con un bot que presenta leyes (delegando y con
## urgencia al azar) y guardado/replay idéntico a mitad del trámite, a mitad del mandato y al final.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO AGENDA COMBINADA: ", msg)


func _presentar_al_azar(m: MotorTurno, rng: RandomNumberGenerator) -> void:
	var cat := m.agenda.agenda_catalogo()
	if cat.is_empty():
		return
	var e: Dictionary = cat[rng.randi_range(0, cat.size() - 1)]
	var urgs := ["simple", "suma", "inmediata"]
	var delegar := rng.randf() < 0.5
	var ministro := String(m.estado.gabinete[rng.randi_range(0, m.estado.gabinete.size() - 1)]) if delegar else ""
	m.agenda.presentar(String(e["carta_id"]), String(urgs[rng.randi_range(0, 2)]), ministro, delegar)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var h := Datos.huella(datos)
	var tope := int(datos["leyes"]["agenda"]["max_simultaneos"])
	var gobiernos := 0
	var presentadas := 0
	for semilla in range(1, 7):
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla * 31 + 7
		var resp: Array[Dictionary] = []
		for p in datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rng.randi_range(0, 2)])
		var partido := GeneradorPartido.construir_partido("Partido Prueba", "PRU", "metropolitana", resp, datos["ideologia"])
		partido["dificultad"] = "facil"
		var m := Partida.crear(datos, semilla, partido)
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if not Bots.elegir(m, datos, "codicioso", rng):
			continue
		gobiernos += 1
		var tope_ahorro := int(datos["leyes"]["mano"]["tope_ahorro"])
		while m.estado.etapa == "gobierno":
			var t := m.estado.turno_actual
			Bots.jugar_turno(m, "codicioso", rng)
			if t % 2 == 0:
				_presentar_al_azar(m, rng)
			var e := m.estado
			_check(e.agenda.size() <= tope, "semilla %d turno %d: agenda %d sobre el máximo" % [semilla, t, e.agenda.size()])
			var ing := e.pa_maximo + int(e.bono_mov["aprobacion"]) + int(e.bono_mov["asesores"])
			_check(e.pa_actual >= 0 and e.pa_actual <= maxi(tope_ahorro, ing), "semilla %d turno %d: movimientos %d fuera de rango" % [semilla, t, e.pa_actual])
			_check(e.delegadas_turno <= int(datos["leyes"]["delegacion"]["max_por_turno"]), "semilla %d turno %d: más delegaciones que el tope" % [semilla, t])
			presentadas = maxi(presentadas, e.agenda.size())
			if t == 20 or t == 90:  # a mitad de trámite y a mitad del mandato
				var g: Dictionary = JSON.parse_string(JSON.stringify(e.exportar_guardado(h)))
				var rep := Partida.reproducir(datos, g)
				_check(rep != null and rep.estado.calcular_huella() == e.calcular_huella(), "semilla %d turno %d: replay distinto (agenda %d, movimientos %d)" % [semilla, t, e.agenda.size(), e.pa_actual])
			m.terminar_turno()
		var gf: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
		var repf := Partida.reproducir(datos, gf)
		_check(repf != null and repf.estado.calcular_huella() == m.estado.calcular_huella(), "semilla %d: replay del mandato completo distinto" % semilla)
		_check(m.estado.agenda.size() <= tope, "semilla %d: agenda final dentro del máximo" % semilla)
	_check(gobiernos >= 4 and presentadas >= 1, "se jugaron gobiernos con agenda (%d, máx. simultáneos %d)" % [gobiernos, presentadas])
	print("AGENDA COMBINADA OK (%d mandatos)" % gobiernos if _fallos == 0 else "AGENDA COMBINADA FALLÓ")
	quit(1 if _fallos > 0 else 0)
