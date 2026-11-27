extends SceneTree
## Cargas a mitad de semana con acciones mezcladas: balas de plata, presupuesto extra, presentar leyes por la agenda (urgencia simple, suma, inmediata y basura), jugar la semana
## del bot y terminarla. Dos motores gemelos reciben exactamente las mismas acciones (misma semilla por acción): «ref» no se toca nunca; «m» se recarga desde disco en
## puntos al azar (por reproducción del historial, por instantánea válida o por instantánea con huella o sha equivocados, que debe caer a reproducción). Propiedad: tras cada
## acción y tras cada carga ambos motores tienen la misma huella; el guardado en cada punto es válido; ningún rechazo de entrada cambia el estado.
## Uso: godot --headless --path . -s tests/fuzz_carga_mixta.gd -- [partidas=6] [semilla=5100] [acciones=160]

var _fallos := 0
var _cargas := {"replay": 0, "snap": 0, "snap_mala": 0}
var _acc := {"bala": 0, "presupuesto": 0, "presentar": 0, "inmediata": 0, "semana": 0, "terminar": 0}
var _d: Dictionary
var _h: String
var _ultima := ""
var _modo := ""
var _permitidas: PackedStringArray = []


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO CARGA MIXTA: ", msg)


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var n := int(a[0]) if a.size() > 0 else 6
	var s0 := int(a[1]) if a.size() > 1 else 5100
	var acciones := int(a[2]) if a.size() > 2 else 160
	if a.size() > 3:
		_permitidas = a[3].split(",")  # depuración: solo estas categorías (bala, presupuesto, agenda, inmediata, semana, terminar); semana y terminar siempre
		_permitidas.append_array(["semana", "terminar"])
	_d = Datos.cargar_todo()
	_h = Datos.huella(_d)
	for i in range(n):
		_partida(s0 + i, acciones)
	print("FUZZ CARGA MIXTA %s (%d partidas; cargas %s; acciones %s; %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, str(_cargas), str(_acc), _fallos])
	quit(1 if _fallos > 0 else 0)


func _partido(rng: RandomNumberGenerator) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in _d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][rng.randi_range(0, 2)])
	return GeneradorPartido.construir_partido("CM", "CMX", "metropolitana", resp, _d["ideologia"])


func _cat(t: int) -> String:
	return "bala" if t <= 1 else ("presupuesto" if t <= 3 else ("agenda" if t <= 5 else ("inmediata" if t == 6 else ("semana" if t <= 8 else "terminar"))))


func _accion(mo: MotorTurno, semilla: int, contar: bool) -> void:
	## Determinista dada la semilla y el estado: aplicada a dos motores iguales deja dos estados iguales.
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var e := mo.estado
	var t := rng.randi_range(0, 9)
	if not _permitidas.is_empty() and not _permitidas.has(_cat(t)):
		t = 8
	_ultima = str(t)
	var basura := ["", "xx", "no_existe", "-1"]
	if t <= 1:
		var ids: Array = (mo.catalogo_leyes["balas_plata"]["catalogo"] as Array).map(func(b: Dictionary) -> String: return String(b["id"]))
		var id := String(ids[rng.randi_range(0, ids.size() - 1)]) if rng.randf() < 0.85 else String(basura[rng.randi_range(0, 3)])
		var hu := e.calcular_huella()
		var r := mo.balas.usar(id, rng.randi_range(-2, 6) if rng.randf() < 0.7 else -1, rng.randf() < 0.5)
		if not bool(r.get("ok", false)):
			_check(e.calcular_huella() == hu, "bala %s rechazada (%s) cambió el estado" % [id, r.get("razon", "?")])
		_acc["bala"] += 1 if contar else 0
	elif t == 2 or t == 3:
		var niveles: Array = mo.catalogo_leyes["presupuesto_ministerial"]["niveles"].keys()
		var slots: Array = e.gabinete.map(func(i: String) -> String: return mo.gabinete.slot_de(i))
		var slot := String(slots[rng.randi_range(0, slots.size() - 1)]) if rng.randf() < 0.85 and not slots.is_empty() else String(basura[rng.randi_range(0, 3)])
		var hu2 := e.calcular_huella()
		var r2 := mo.presupuesto.asignar(slot, String(niveles[rng.randi_range(0, niveles.size() - 1)]) if rng.randf() < 0.9 else "xx", [])
		if not bool(r2.get("ok", false)):
			_check(e.calcular_huella() == hu2, "presupuesto rechazado (%s) cambió el estado" % r2.get("razon", "?"))
		_acc["presupuesto"] += 1 if contar else 0
	elif t <= 5:
		var cat := mo.agenda.agenda_catalogo()
		var cid := String(cat[rng.randi_range(0, cat.size() - 1)]["carta_id"]) if not cat.is_empty() and rng.randf() < 0.85 else String(basura[rng.randi_range(0, 3)])
		var urg: String = ["simple", "suma", "inmediata", "xx"][rng.randi_range(0, 3)]
		var hu3 := e.calcular_huella()
		var r3 := mo.agenda.presentar(cid, urg)
		if not bool(r3.get("ok", false)):
			_check(e.calcular_huella() == hu3, "presentar %s (%s) rechazado (%s) cambió el estado" % [cid, urg, r3.get("razon", "?")])
		_acc["presentar"] += 1 if contar else 0
	elif t == 6:
		var cat2 := mo.agenda.agenda_catalogo()
		if not cat2.is_empty():
			mo.agenda.poner_en_discusion_inmediata(String(cat2[rng.randi_range(0, cat2.size() - 1)]["carta_id"]))
		_acc["inmediata"] += 1 if contar else 0
	elif t <= 8:
		Bots.jugar_turno(mo, "codicioso", rng)
		_acc["semana"] += 1 if contar else 0
	else:
		mo.terminar_turno()
		_acc["terminar"] += 1 if contar else 0


func _recargar(ref: MotorTurno, rng: RandomNumberGenerator, ctx: String) -> MotorTurno:
	var g: Dictionary = JSON.parse_string(JSON.stringify(ref.estado.exportar_guardado(_h)))
	_check(ValidarGuardado.guardado_valido(g), ctx + ": guardado inválido")
	var modo := rng.randi_range(0, 2)
	_modo = ["replay", "snap", "snap_mala"][modo]
	var m: MotorTurno
	if modo == 0:
		_cargas["replay"] += 1
		m = Partida.cargar(_d, g)
	else:
		var snap := Instantanea.leer(Instantanea.tomar(ref, _h, "sha_ok"))
		if modo == 1:
			_cargas["snap"] += 1
			m = Partida.cargar(_d, g, snap, _h, "sha_ok")
		else:
			_cargas["snap_mala"] += 1
			m = Partida.cargar(_d, g, snap, _h, "otro_sha")  # no vale: debe reproducir el historial
	_check(m != null, ctx + ": la carga devolvió null")
	return m


func _partida(semilla: int, acciones: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var ref := Partida.crear(_d, semilla, _partido(rng))
	for _s in range(int(_d["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(ref, "codicioso", rng)
		ref.terminar_turno()
	if not Bots.elegir(ref, _d, "codicioso", rng):
		return
	var m := _recargar(ref, rng, "semilla %d tras la elección" % semilla)
	if m == null:
		return
	for i in range(acciones):
		if ref.estado.etapa != "gobierno":
			break
		var s := rng.randi()
		_accion(ref, s, true)
		_accion(m, s, false)
		var ctx := "semilla %d acción %d (turno %d)" % [semilla, i, ref.estado.turno_actual]
		_check(ref.estado.calcular_huella() == m.estado.calcular_huella(), ctx + ": los gemelos divergen tras la misma acción (acción %s, última carga %s%s)" % [_ultima, _modo, "" if ref.estado.calcular_huella() == m.estado.calcular_huella() else "; dif " + str(AyudaFuzz.diferencias(m, ref))])
		for f in AyudaInvariantes.revisar(m, ctx):
			_check(false, ctx + ": invariante: " + f)
		if rng.randf() < 0.3:
			var m2 := _recargar(ref, rng, ctx)
			if m2 == null:
				return
			_check(m2.estado.calcular_huella() == ref.estado.calcular_huella(), ctx + ": el motor recargado no coincide con el de referencia")
			var d_ref: Object = ref.eventos.director
			var d_m2: Object = m2.eventos.director
			for campo in ([] if OS.get_environment("CM_ARREGLAR") == "1" else ["_ult_fam", "_ult_dec", "_dec_sem", "_ultima", "_n_visto"]):
				_check(str(d_ref.get(campo)) == str(d_m2.get(campo)), "%s: el director de eventos recargado (modo %s) difiere en %s: vivo %s, recargado %s" % [ctx, _modo, campo, str(d_ref.get(campo)), str(d_m2.get(campo))])
			if OS.get_environment("CM_ARREGLAR") == "1":  # experimento: igualar la memoria del director a la del vivo para ver si explica la divergencia
				for campo2 in ["_ult_fam", "_ult_dec", "_dec_sem", "_ultima", "_n_visto"]:
					d_m2.set(campo2, d_ref.get(campo2).duplicate() if d_ref.get(campo2) is Dictionary else d_ref.get(campo2))
			var dd := AyudaFuzz.diferencias(m2, ref)
			_check(dd.is_empty(), ctx + ": el motor recargado (modo %s) difiere en propiedades fuera de la huella: %s" % [_modo, str(dd)])
			m = m2
