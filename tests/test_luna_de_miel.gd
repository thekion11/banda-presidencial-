extends SceneTree
## Luna de miel (D-BN): 13 semanas de impulso que se desvanece; efecto en aprobación, Congreso y coalición; ciclos posteriores; guardado y restauración a mitad.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO LUNA: ", msg)
		_fallos += 1


func _partido(datos: Dictionary, dif: String = "") -> Dictionary:
	var r: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		r.append(p["opciones"][1])
	var pa := GeneradorPartido.construir_partido("Luna", "LUN", "metropolitana", r, datos["ideologia"])
	if dif != "":
		pa["dificultad"] = dif
	return pa


func _gobierno(datos: Dictionary, semilla: int, semana: int, dif: String = "") -> MotorTurno:
	var m := Partida.crear(datos, semilla, _partido(datos, dif))
	m.estado.etapa = "gobierno"
	m.estado.turno_actual = semana
	return m


func _hasta_gobierno(datos: Dictionary, semilla: int, rng: RandomNumberGenerator, ciclo: int = 1) -> MotorTurno:
	var m := Partida.crear(datos, semilla, _partido(datos, "facil"))
	m.estado.ciclo = ciclo
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "completo", rng)
		m.terminar_turno()
	Bots.elegir(m, datos, "completo", rng)
	return m


func _init() -> void:
	var datos := Datos.cargar_todo()
	var leyes: Dictionary = datos["leyes"]
	var cfg: Dictionary = leyes["luna_de_miel"]
	var n := int(cfg["semanas"])
	_check(n == 13, "13 semanas (~3 meses), decisión del usuario del 27-nov")

	# 1. Curva: 1,0 en la semana 1, decae, 1/13 en la 13 y 0 en la 14
	var m := _gobierno(datos, 7, 1)
	var anterior := 2.0
	for s in range(1, 17):
		m.estado.turno_actual = s
		var i := LunaDeMiel.intensidad(m.estado, leyes)
		if s == 1:
			_check(is_equal_approx(i, 1.0), "semana 1: intensidad 1,0 (%.3f)" % i)
		if s <= n:
			_check(i > 0.0 and i < anterior, "semana %d: intensidad decrece (%.3f)" % [s, i])
		else:
			_check(i == 0.0, "semana %d: sin luna de miel" % s)
		anterior = i
	m.estado.turno_actual = 13
	_check(is_equal_approx(LunaDeMiel.intensidad(m.estado, leyes), 1.0 / 13.0), "semana 13: 1/13")
	m.estado.turno_actual = 14
	_check(LunaDeMiel.intensidad(m.estado, leyes) == 0.0, "semana 14: 0")
	m.estado.turno_actual = 1
	m.estado.etapa = "campana"
	_check(LunaDeMiel.intensidad(m.estado, leyes) == 0.0, "en campaña no hay luna de miel")
	m.estado.etapa = "oposicion"
	_check(LunaDeMiel.intensidad(m.estado, leyes) == 0.0, "en oposición no hay luna de miel del jugador")
	m.estado.etapa = "gobierno"
	# dificultad: más impulso en fácil que en difícil
	var f := _gobierno(datos, 7, 1, "facil")
	var d := _gobierno(datos, 7, 1, "dificil")
	var nm := _gobierno(datos, 7, 1, "normal")
	_check(LunaDeMiel.intensidad(f.estado, leyes) > LunaDeMiel.intensidad(nm.estado, leyes) and LunaDeMiel.intensidad(nm.estado, leyes) > LunaDeMiel.intensidad(d.estado, leyes), "fácil > normal > difícil")

	# 2. Vista para la interfaz
	var v := LunaDeMiel.vista(m.estado, leyes)
	_check(bool(v["activa"]) and int(v["semana"]) == 1 and int(v["semanas_restantes"]) == 13 and not bool(v["termina_ahora"]), "vista de la semana 1: activa, 13 restantes")
	m.estado.turno_actual = 13
	v = LunaDeMiel.vista(m.estado, leyes)
	_check(int(v["semanas_restantes"]) == 1 and bool(v["activa"]), "semana 13: queda 1")
	m.estado.turno_actual = 14
	v = LunaDeMiel.vista(m.estado, leyes)
	_check(not bool(v["activa"]) and bool(v["termina_ahora"]) and int(v["semanas_restantes"]) == 0, "semana 14: terminó (aviso)")
	m.estado.turno_actual = 15
	_check(not bool(LunaDeMiel.vista(m.estado, leyes)["termina_ahora"]), "el aviso es solo de la semana 14")

	# 3. Aprobación: con luna de miel el amanecer deja más aprobación que sin ella; en la semana 14 el bono es 0
	var con := _gobierno(datos, 9, 1)
	var sin := _gobierno(datos, 9, 14)
	for mm in [con, sin]:
		mm.estado.indicadores["aprobacion"] = 20.0
		mm.regiones.inicializar(mm.estado, 20.0, "", 0.0)
		mm.ejecutar_amanecer()
	_check(con.estado.ind("aprobacion") > sin.estado.ind("aprobacion"), "la luna de miel sube la aprobación del amanecer (%.2f > %.2f)" % [con.estado.ind("aprobacion"), sin.estado.ind("aprobacion")])
	var aj14 := LunaDeMiel.ajustes(leyes, 0.0)
	_check(aj14["ancla"] == 0.0 and aj14["desgaste"] == 1.0, "con intensidad 0 no hay ningún ajuste")
	var clave := "aprobacion|" + String(cfg["texto_motivo"])  # motivos_semana muestra solo los 3 mayores; aquí se mira el registro completo
	_check(float(con.fx._motivos.get(clave, 0.0)) > 0.0, "la luna de miel queda anotada como motivo positivo de la semana")
	_check(float(sin.fx._motivos.get(clave, 0.0)) == 0.0, "después de la luna de miel no hay motivo")
	_check(con.estado.registro_acciones.any(func(a): return String(a["tipo"]) == "luna_de_miel_inicio"), "se registra el inicio")
	_check(not con.estado.registro_acciones.any(func(a): return String(a["tipo"]) == "luna_de_miel_fin"), "el fin no se registra en la semana 1")
	var fin := _gobierno(datos, 9, 14)
	fin.ejecutar_amanecer()
	_check(fin.estado.registro_acciones.any(func(a): return String(a["tipo"]) == "luna_de_miel_fin"), "se registra el fin («%s»)" % cfg["texto_fin"])

	# 4. Congreso: más apoyo en las primeras semanas; coalición: aliados más satisfechos
	var a1 := _gobierno(datos, 3, 1)
	var a14 := _gobierno(datos, 3, 14)
	var dif_apoyo := a1.legal.apoyo_base(a1.estado) - a14.legal.apoyo_base(a14.estado)
	_check(absf(dif_apoyo - float(cfg["bono_apoyo"])) < 0.0001 or a1.legal.apoyo_base(a1.estado) >= 1.0, "el apoyo del Congreso sube bono_apoyo en la semana 1 (%.3f)" % dif_apoyo)
	_check(a1.legal.composicion(a1.estado, false)["aliados"] >= a14.legal.composicion(a14.estado, false)["aliados"], "la composición del Senado refleja el mayor apoyo")
	var ok_vot := 0
	var ok_vot14 := 0
	for k in range(300):  # misma semilla de azar: más leyes aprobadas con luna de miel
		a1.legal.rng.seed = 1000 + k
		a14.legal.rng.seed = 1000 + k
		ok_vot += 1 if bool(a1.legal.votar(a1.estado, "ley_simple")["aprobada"]) else 0
		ok_vot14 += 1 if bool(a14.legal.votar(a14.estado, "ley_simple")["aprobada"]) else 0
	_check(ok_vot >= ok_vot14, "con luna de miel se aprueban al menos tantas leyes (%d vs %d de 300)" % [ok_vot, ok_vot14])
	for mm in [a1, a14]:
		mm.unirse_coalicion("laborismo_austral")
	_check(a1.coalicion.objetivo("laborismo_austral") > a14.coalicion.objetivo("laborismo_austral"), "los aliados tienen mayor satisfacción objetivo con luna de miel")
	var tope := float(cfg["bono_satisfaccion"])
	_check(a1.coalicion.objetivo("laborismo_austral") - a14.coalicion.objetivo("laborismo_austral") <= tope + 0.0001, "el bono de satisfacción no pasa de bono_satisfaccion")

	# 5. Ciclos posteriores: cada gobierno nuevo parte con luna de miel completa
	for ciclo in [1, 2]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 40 + ciclo
		var g := _hasta_gobierno(datos, 40 + ciclo, rng, ciclo)
		_check(g.estado.etapa == "gobierno" and g.estado.turno_actual == 1, "ciclo %d: empezó el gobierno" % ciclo)
		_check(is_equal_approx(LunaDeMiel.intensidad(g.estado, leyes), LunaDeMiel.intensidad(_gobierno(datos, 1, 1, "facil").estado, leyes)), "ciclo %d: luna de miel completa en la semana 1" % ciclo)
	# tras un periodo de oposición y una nueva campaña, el gobierno vuelve a tener luna de miel
	var c2 := _gobierno(datos, 77, 5)
	c2.estado.etapa = "fin_mandato"
	c2.estado.resultado_final = {"puntaje": 0}
	c2.continuar_carrera()  # oposición (sin reforma de reelección)
	_check(c2.estado.etapa == "oposicion" and LunaDeMiel.intensidad(c2.estado, leyes) == 0.0, "en la oposición posterior no hay luna de miel")

	# 6. Guardado a mitad de la luna de miel: reproducir el historial y restaurar la instantánea dan lo mismo, y seguir jugando también
	var huella := Datos.huella(datos)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 99
	var g2 := _hasta_gobierno(datos, 99, rng2)
	for _t in range(5):
		Bots.jugar_turno(g2, "completo", rng2)
		g2.terminar_turno()
	_check(g2.estado.etapa == "gobierno" and g2.estado.turno_actual == 6, "a mitad de la luna de miel (semana 6)")
	var guardado := g2.estado.exportar_guardado(huella)
	var rep := Partida.reproducir(datos, guardado)
	_check(rep.estado.calcular_huella() == g2.estado.calcular_huella(), "reproducir el historial da el mismo estado a mitad de la luna de miel")
	var rest := Instantanea.restaurar(datos, g2.estado.semilla, Instantanea.leer(Instantanea.tomar(g2, huella, "sha")))
	_check(rest.estado.calcular_huella() == g2.estado.calcular_huella(), "restaurar la instantánea da el mismo estado")
	_check(LunaDeMiel.vista(rest.estado, leyes) == LunaDeMiel.vista(g2.estado, leyes), "la vista es igual tras restaurar")
	for mm in [g2, rest]:
		var r3 := RandomNumberGenerator.new()
		r3.seed = 5
		for _t in range(10):  # cruza el fin de la luna de miel (semanas 6 a 16)
			Bots.jugar_turno(mm, "completo", r3)
			mm.terminar_turno()
	_check(rest.estado.calcular_huella() == g2.estado.calcular_huella(), "restaurar y reproducir siguen igual al cruzar el fin de la luna de miel")
	_check(g2.estado.registro_acciones.any(func(a): return String(a["tipo"]) == "luna_de_miel_fin"), "se registró el fin de la luna de miel")
	print("test_luna_de_miel: intensidad semana 1 = %.2f, semana 13 = %.3f, %s" % [1.0, 1.0 / 13.0, "OK" if _fallos == 0 else "FALLOS %d" % _fallos])
	quit(1 if _fallos > 0 else 0)
