extends SceneTree
## Fuzz del tablero del gabinete (PanelGabinete, TableroGabinete) con entradas REALES (Input.parse_input_event): tocar puestos, tocar candidatos (1.º anticipa, 2.º nombra),
## arrastrar un candidato a su puesto, a un puesto AJENO (debe rechazarse), a la nada, «Rellenar» (3 modos) y «Deshacer», y confirmar. Invariantes: nunca más de 25 elegidos
## ni más de uno por puesto (el contador coincide con los puestos pintados), arrastrar a un puesto ajeno o soltar fuera no cambia nada, el relleno solo completa vacíos y
## NUNCA pisa un puesto «elegido», «Deshacer» devuelve el estado anterior, el botón de confirmar solo se habilita con 25, confirmar deja un gabinete de 25 únicos en el
## motor, y la misma secuencia de entradas da el mismo gabinete (determinismo).
## Uso: godot --headless --path . -s tests/fuzz_tablero_gabinete.gd -- [partidas=6] [operaciones=40] [semilla=3300]

var _fallos := 0
var _ops := 0
var _confirmaciones := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ TABLERO: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _toque(pos: Vector2, pulsado: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pulsado
	e.position = root.get_final_transform() * pos
	Input.parse_input_event(e)


func _arrastre(a: Vector2, b: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = root.get_final_transform() * b
	e.relative = b - a
	Input.parse_input_event(e)


func _tocar(pos: Vector2) -> void:
	_toque(pos, true)
	await _cuadros(2)
	_toque(pos, false)
	await _cuadros(3)


func _soltar(desde: Vector2, hasta: Vector2) -> void:
	_toque(desde, true)
	await _cuadros(2)
	for k in range(1, 9):
		_arrastre(desde.lerp(hasta, float(k - 1) / 8.0), desde.lerp(hasta, float(k) / 8.0))
		await _cuadros(1)
	await _cuadros(2)
	_toque(hasta, false)
	await _cuadros(4)


func _visible(c: Control) -> Vector2:
	## Lleva el control a la vista (los puestos viven dentro de un scroll) y devuelve su centro.
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			(p as ScrollContainer).ensure_control_visible(c)
			break
		p = p.get_parent()
	return c.get_global_rect().get_center()


func _puestos(panel: Node) -> Array:
	return panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b is TableroGabinete.Puesto)


func _candidatos(panel: Node) -> Array:
	return panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b is TableroGabinete.Candidato and not b.is_queued_for_deletion())


func _estados(panel: Node) -> Dictionary:
	## slot -> «elegido» | «automático» | «vacío», leído de los puestos pintados.
	var r := {}
	for p in _puestos(panel):
		var est := ""
		for l in p.find_children("*", "Label", true, false):
			var t := (l as Label).text
			if t == "elegido" or t == "automático" or t == "vacío":
				est = t
		r[(p as TableroGabinete.Puesto).slot] = est
	return r


func _n(panel: Node) -> int:
	for l in panel.find_children("*", "Label", true, false):
		if (l as Label).text.begins_with("Gabinete: "):
			return int((l as Label).text.get_slice(" ", 1))
	return -1


func _boton_texto(panel: Node, t: String) -> Button:
	for b in panel.find_children("*", "Button", true, false):
		if (b as Button).text == t and (b as Button).is_visible_in_tree():
			return b
	return null


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 6
	var nops := int(args[1]) if args.size() > 1 else 40
	var s0 := int(args[2]) if args.size() > 2 else 3300
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_tablero_fuzz.json"
	Tutorial.marcar_visto()
	var datos := Datos.cargar_todo()
	for i in range(n):
		var g1 := await _partida(datos, s0 + i, nops)
		var g2 := await _partida(datos, s0 + i, nops)
		_check(g1 == g2, "partida %d: la misma secuencia de entradas dio gabinetes distintos (%s / %s)" % [i, str(g1), str(g2)])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	print("FUZZ TABLERO GABINETE %s (%d partidas ×2, %d operaciones, %d confirmaciones, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _ops, _confirmaciones, _fallos])
	quit(1 if _fallos > 0 else 0)


func _partida(datos: Dictionary, semilla: int, nops: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var m := Partida.crear(datos, semilla, GeneradorPartido.construir_partido("Tab", "TAB", "metropolitana", resp, datos["ideologia"]))
	m.estado.gabinete.clear()  # parte con el tablero vacío: lo que haya lo pone el jugador o el relleno
	var confirmado := [false]
	var panel: Control = PanelGabinete.crear(m, "Comenzar campaña", func() -> void: confirmado[0] = true, func(_t: String) -> void: pass)
	panel.size = Vector2(390, 844)
	root.add_child(panel)
	await _cuadros(4)
	var modos: Dictionary = m.catalogo_leyes["gabinete"]["relleno"]["modos"]
	var ctx := "semilla %d" % semilla
	# prefacio determinista: nombrar 24 de 25 puestos con dos toques cada uno; con 24 el botón sigue apagado y con el 25.º se enciende
	var bc0 := _boton_texto(panel, "Comenzar campaña")
	_check(bc0 != null and bc0.disabled, ctx + ": con el tablero vacío el botón de confirmar debe estar apagado")
	var slots: Array = _puestos(panel).map(func(p: TableroGabinete.Puesto) -> String: return p.slot)
	for idx in range(slots.size()):
		var pu: Array = _puestos(panel).filter(func(p: TableroGabinete.Puesto) -> bool: return p.slot == slots[idx])
		await _tocar(_visible(pu[0]))
		var cs := _candidatos(panel)
		if cs.is_empty():
			continue
		await _tocar(_visible(cs[0]))
		var cs2 := _candidatos(panel)
		if not cs2.is_empty():
			await _tocar(_visible(cs2[0]))
		var nn := _n(panel)
		var bb := _boton_texto(panel, "Comenzar campaña")
		_check(nn == idx + 1, "%s: tras nombrar %d puestos el contador marca %d" % [ctx, idx + 1, nn])
		if bb != null:
			_check(bb.disabled == (nn != 25), "%s: con %d de 25 el botón de confirmar debe estar %s" % [ctx, nn, "apagado" if nn != 25 else "encendido"])
		if idx == 23:  # se deja de nombrar con 24 y se sigue con el resto en la fase aleatoria
			break
	for k in range(nops):
		var puestos := _puestos(panel)
		var cands := _candidatos(panel)
		var antes := _estados(panel)
		var n0 := _n(panel)
		_ops += 1
		match rng.randi_range(0, 6):
			0, 1:  # tocar un puesto
				if puestos.is_empty():
					continue
				await _tocar(_visible(puestos[rng.randi_range(0, puestos.size() - 1)]))
			2:  # tocar un candidato (1.º anticipa, 2.º nombra)
				if cands.is_empty():
					continue
				var c: Button = cands[rng.randi_range(0, cands.size() - 1)]
				await _tocar(_visible(c))
				if rng.randf() < 0.6:
					var c2 := _candidatos(panel)
					if not c2.is_empty():
						await _tocar(_visible(c2[rng.randi_range(0, c2.size() - 1)]))
			3:  # arrastrar un candidato a su propio puesto
				if cands.is_empty():
					continue
				var cd: TableroGabinete.Candidato = cands[rng.randi_range(0, cands.size() - 1)]
				var dest: Array = puestos.filter(func(p: TableroGabinete.Puesto) -> bool: return p.slot == cd.slot)
				if dest.is_empty():
					continue
				await _soltar(_visible(cd), _visible(dest[0]))
			4:  # arrastrar a un puesto AJENO o a la nada: no cambia nada
				if cands.is_empty():
					continue
				var cd2: TableroGabinete.Candidato = cands[rng.randi_range(0, cands.size() - 1)]
				var ajenos: Array = puestos.filter(func(p: TableroGabinete.Puesto) -> bool: return p.slot != cd2.slot)
				var destino := Vector2(rng.randf_range(0.0, 390.0), rng.randf_range(0.0, 844.0))
				if not ajenos.is_empty() and rng.randf() < 0.7:
					destino = _visible(ajenos[rng.randi_range(0, ajenos.size() - 1)])
				var origen := _visible(cd2)
				var antes2 := _estados(panel)
				await _soltar(origen, destino)
				var puesto_propio: Array = puestos.filter(func(p: TableroGabinete.Puesto) -> bool: return p.slot == cd2.slot)
				var cae_en_propio: bool = not puesto_propio.is_empty() and puesto_propio[0].get_global_rect().has_point(destino)
				if not cae_en_propio:
					_check(_estados(panel) == antes2 and _n(panel) == n0, "%s op %d: soltar fuera de su puesto cambió el gabinete" % [ctx, k])
			5:  # rellenar (nunca pisa lo elegido) y a veces deshacer
				var modo: String = modos.keys()[rng.randi_range(0, modos.size() - 1)]
				var b := _boton_texto(panel, String(modos[modo]["nombre"]))
				if b == null:
					continue
				await _tocar(_visible(b))
				var despues := _estados(panel)
				for slot in antes.keys():
					if antes[slot] == "elegido":
						_check(despues[slot] == "elegido", "%s op %d: el relleno pisó el puesto elegido %s (%s)" % [ctx, k, slot, despues[slot]])
					if antes[slot] != "vacío":
						_check(despues[slot] != "vacío", "%s op %d: el relleno vació el puesto %s" % [ctx, k, slot])
					if antes[slot] == "vacío":
						_check(despues[slot] == "automático", "%s op %d: el puesto %s lo llenó el relleno y no se ve como automático (%s)" % [ctx, k, slot, despues[slot]])
				_check(_n(panel) == 25, "%s op %d: tras rellenar hay %d de 25" % [ctx, k, _n(panel)])
				if rng.randf() < 0.4:
					var d := _boton_texto(panel, "Deshacer")
					if d != null:
						await _tocar(_visible(d))
						_check(_estados(panel) == antes, "%s op %d: «Deshacer» no devolvió el estado anterior" % [ctx, k])
			6:  # confirmar: solo habilitado con 25
				var bc := _boton_texto(panel, "Comenzar campaña")
				if bc != null:
					_check(bc.disabled == (_n(panel) != 25), "%s op %d: botón de confirmar %s con %d de 25" % [ctx, k, "habilitado" if not bc.disabled else "deshabilitado", _n(panel)])
					if not bc.disabled:
						await _tocar(_visible(bc))
						_confirmaciones += 1
						_check(confirmado[0], "%s op %d: confirmar con 25 no confirmó" % [ctx, k])
						_check(m.estado.gabinete.size() == 25 and m.estado.gabinete.size() == _unicos(m.estado.gabinete), "%s op %d: gabinete confirmado inválido (%d, %d únicos)" % [ctx, k, m.estado.gabinete.size(), _unicos(m.estado.gabinete)])
						break
		# invariantes de cada paso
		var est := _estados(panel)
		var llenos := 0
		for slot in est.keys():
			llenos += 0 if est[slot] == "vacío" else 1
		_check(_n(panel) == llenos and llenos <= 25, "%s op %d: contador %d ≠ puestos llenos %d" % [ctx, k, _n(panel), llenos])
	var final: Array = m.estado.gabinete.duplicate()
	final.sort()
	panel.queue_free()
	await _cuadros(2)
	return final


func _unicos(a: Array) -> int:
	var d := {}
	for x in a:
		d[x] = true
	return d.size()
