extends SceneTree
## Conteo de toques (informe, no prueba del CI). Juega semanas reales en la interfaz del día y cuenta cuántos toques
## pide cada acción: jugar una carta, delegar y terminar la semana (incluidos los eventos y votaciones que aparecen
## después). El telón entre semanas se cierra solo y no cuenta como toque.
## Uso: godot --headless --path . -s tests/medir_toques.gd -- [semillas] [semanas]

var _toques_eventos: Array[int] = []
var _paginas := 0
var _por_tipo := {}  # toques por clase de pantalla: votación (página), decisión, aviso, elección


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _vaciar_capa(dia: PantallaDia) -> int:
	## Pulsa el botón principal de cada evento hasta que no quede ninguno; devuelve cuántos toques hicieron falta.
	var toques := 0
	for _vuelta in range(60):
		await _cuadros(2)
		var abierto: Control = null
		for h in dia._capa.get_children():
			if h is Control and h != dia._toast and not (h is TelonSemana) and not h.is_queued_for_deletion() and (h as Control).visible:
				abierto = h
		var telon := dia._capa.get_children().filter(func(h: Node) -> bool: return h is TelonSemana and not h.is_queued_for_deletion())
		if abierto == null and telon.is_empty():
			return toques
		if abierto == null:
			(telon[0] as TelonSemana)._salir()  # se cerraría solo; no es un toque
			continue
		var botones: Array = abierto.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.is_visible_in_tree() and not b.disabled)
		if botones.is_empty():
			abierto.queue_free()
			continue
		var tipo := "votación" if not abierto.find_children("*", "Hemiciclo", true, false).is_empty() else ("decisión" if botones.size() > 1 else "aviso")
		if (abierto as Node).get_script() == PantallaEleccion:
			tipo = "elección"
		_por_tipo[tipo] = int(_por_tipo.get(tipo, 0)) + 1
		(botones[botones.size() - 1] as Button).pressed.emit()  # el último es el principal (o la última opción de una decisión)
		toques += 1
	return toques


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_toques.json"
	Tutorial.marcar_visto()
	var args := OS.get_cmdline_user_args()
	var semillas := int(args[0]) if args.size() > 0 else 3
	var semanas := int(args[1]) if args.size() > 1 else 30
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var conf := 0
	var sobran_sin_uso := 0
	var fines := 0
	for s in range(semillas):
		main.motor = Partida.crear(main.datos, 1000 + s, GeneradorPartido.construir_partido("T", "T", "metropolitana", resp, main.datos["ideologia"]))
		main.mostrar_dia()
		await _cuadros(2)
		for w in range(semanas):
			var dia: PantallaDia = main._pantalla
			if not (dia is PantallaDia) or not MotorTurno.ETAPAS_JUEGO.has(main.motor.estado.etapa):
				break
			await _vaciar_capa(dia)
			var est: EstadoSimulacion = main.motor.estado
			var jugo := true
			while jugo and est.pa_actual > 0:  # juega lo que alcance, como un jugador (2 toques por carta): prueba cada carta
				jugo = false
				for i in range(est.mano.size()):
					var antes := est.pa_actual
					dia._sel = i
					dia._jugar()
					await _cuadros(1)
					await _vaciar_capa(dia)
					if est.pa_actual < antes:
						jugo = true
						break
			if est.pa_actual > 0:
				var alcanza := est.mano.any(func(c: Dictionary) -> bool: return main.motor.costo_carta(c, "") <= est.pa_actual)
				sobran_sin_uso += 0 if alcanza else 1
			dia._avanzar()  # 1 toque; si quedan movimientos o promesas, pide un segundo
			fines += 1
			if dia._confirmar_fin:
				conf += 1
				dia._avanzar()
			await _cuadros(2)
			if main._pantalla != dia:
				break
			_toques_eventos.append(await _vaciar_capa(dia))
	_toques_eventos.sort()
	var suma := 0
	for t in _toques_eventos:
		suma += t
	var n := maxi(1, _toques_eventos.size())
	print("Semanas medidas: %d (semillas %d)" % [_toques_eventos.size(), semillas])
	print("Jugar una carta: 2 toques (elegir y tocarla otra vez) o 1 gesto (deslizar hacia arriba)")
	print("Delegar: 2 (soltar la carta sobre el ícono y confirmar) o 3 (elegir, ícono, confirmar)")
	print("Terminar la semana: 1 toque, 2 si quedan movimientos (pidió confirmación %d de %d veces; en %d no alcanzaba para ninguna carta)" % [conf, fines, sobran_sin_uso])
	print("Después de terminar la semana, toques en eventos y votaciones: medio %.2f, mediana %d, máximo %d" % [float(suma) / float(n), _toques_eventos[n / 2] if not _toques_eventos.is_empty() else 0, _toques_eventos.back() if not _toques_eventos.is_empty() else 0])
	var hist := {}
	for t in _toques_eventos:
		hist[t] = int(hist.get(t, 0)) + 1
	print("Distribución (toques: semanas): ", hist)
	print("Toques por clase de pantalla: ", _por_tipo)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	quit()
