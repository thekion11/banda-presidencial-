extends SceneTree
## Partida de punta a punta por la interfaz (informe de la cola 9, no prueba del CI): campaña, urnas, cambio de mando,
## transición del gabinete y semanas de gobierno, todo con los mismos botones que toca un jugador. Mide por semana
## los nodos vivos, la memoria estática y el tiempo de la semana, y avisa si los nodos crecen semana a semana (fuga).
## Uso: godot --headless --path . -s tests/e2e_ui.gd -- [semilla] [semanas_de_gobierno]

var _pantallas := {}  # clase de pantalla -> veces que apareció


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _boton(raiz: Node, texto: String) -> Button:
	for b in raiz.find_children("*", "Button", true, false):
		if (b as Button).text == texto and (b as Button).is_visible_in_tree() and not (b as Button).disabled:
			return b
	return null


func _vaciar_capa(main: Node) -> void:
	## Cierra eventos, votaciones, elección y cambio de mando con su botón principal, como un jugador.
	for _vuelta in range(80):
		await _cuadros(2)
		var p: Node = main._pantalla
		if not (p is PantallaDia):
			return
		var dia: PantallaDia = p
		var abierto: Control = null
		for h in dia._capa.get_children():
			if h is Control and h != dia._toast and not (h is TelonSemana) and not h.is_queued_for_deletion() and (h as Control).visible:
				abierto = h
		var telon := dia._capa.get_children().filter(func(h: Node) -> bool: return h is TelonSemana and not h.is_queued_for_deletion())
		if abierto == null and telon.is_empty():
			return
		if abierto == null:
			(telon[0] as TelonSemana)._salir()
			continue
		var clase := String(abierto.get_script().get_global_name()) if abierto.get_script() != null else abierto.get_class()
		_pantallas[clase] = int(_pantallas.get(clase, 0)) + 1
		var botones: Array = abierto.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.is_visible_in_tree() and not b.disabled)
		if botones.is_empty():
			abierto.queue_free()
			continue
		(botones[botones.size() - 1] as Button).pressed.emit()


func _desglose(n: Node, nivel: int) -> void:
	## Dónde están los nodos: los subárboles de más de 40 nodos, hasta 4 niveles.
	for h in n.get_children():
		var c := h.find_children("*", "", true, false).size() + 1
		if c > 40 and nivel < 9:
			print("NODOS %s%s (%s) %d%s" % ["  ".repeat(nivel), h.name, h.get_script().get_global_name() if h.get_script() != null else h.get_class(), c, "" if (not (h is CanvasItem) or (h as CanvasItem).visible) else " oculto"])
			_desglose(h, nivel + 1)


func _semana(main: Node) -> void:
	var dia: PantallaDia = main._pantalla
	var est: EstadoSimulacion = main.motor.estado
	var jugo := true
	while jugo and est.pa_actual > 0:  # juega lo que alcance: elegir y tocar otra vez, como un jugador
		jugo = false
		for i in range(est.mano.size()):
			var antes := est.pa_actual
			dia._mano_tocada = false
			dia._on_carta(i)
			dia._on_carta(i)
			await _cuadros(1)
			await _vaciar_capa(main)
			if not (main._pantalla is PantallaDia):
				return
			if est.pa_actual < antes:
				jugo = true
				break
	dia._avanzar()
	if dia._confirmar_fin:
		dia._avanzar()
	await _cuadros(2)
	await _vaciar_capa(main)


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_e2e.json"
	Tutorial.marcar_visto()
	var args := OS.get_cmdline_user_args()
	var semilla := int(args[0]) if args.size() > 0 else 7
	var gobierno := int(args[1]) if args.size() > 1 else 26
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Prueba de Punta a Punta", "PPP", "metropolitana", resp, main.datos["ideologia"])
	partido["indicadores_iniciales"]["aprobacion"] = 90.0  # para llegar al gobierno y medirlo también
	main.motor = Partida.crear(main.datos, semilla, partido)
	main.guardar()
	main.mostrar_dia()
	await _cuadros(3)
	var filas: Array[String] = []
	var nodos0 := 0
	var t_max := 0.0
	var t_suma := 0.0
	var semanas := 0
	var transicion := false
	for _w in range(int(main.datos["leyes"]["hemiciclo"]["semanas_campana"]) + 4 + gobierno):
		if main._pantalla is PantallaGabinete:  # transición presidencial: confirmar el equipo preseleccionado
			transicion = true
			_pantallas["PantallaGabinete"] = int(_pantallas.get("PantallaGabinete", 0)) + 1
			var conf := _boton(main._pantalla, "Confirmar gabinete y asumir")
			if conf == null:
				break
			conf.pressed.emit()
			await _cuadros(3)
			await _vaciar_capa(main)
		if not (main._pantalla is PantallaDia):
			break
		var est: EstadoSimulacion = main.motor.estado
		var t0 := Time.get_ticks_usec()
		await _semana(main)
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0
		await _cuadros(2)
		var nodos := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var mem := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
		semanas += 1
		if semanas == 3:
			nodos0 = nodos  # base tras estabilizarse
		t_max = maxf(t_max, ms)
		t_suma += ms
		var pest: String = main._pantalla._panel_actual if main._pantalla is PantallaDia else "-"
		filas.append("CSV,%d,%s,%d,%s,%d,%.1f,%.0f" % [semanas, est.etapa, est.turno_actual, pest, nodos, mem, ms])
	print("CSV,semana,etapa,turno,pestaña,nodos,memoria_estatica_MB,ms_semana")
	for f in filas:
		print(f)
	var nodos_fin := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("Semanas jugadas por la interfaz: %d · etapa final: %s · transición del gabinete: %s" % [semanas, main.motor.estado.etapa, "sí" if transicion else "no"])
	print("Tiempo por semana (con eventos y animaciones en headless): medio %.0f ms · máximo %.0f ms" % [t_suma / maxf(1.0, float(semanas)), t_max])
	print("Nodos: semana 3 = %d · final = %d (%+d)" % [nodos0, nodos_fin, nodos_fin - nodos0])
	print("Pantallas atendidas: ", _pantallas)
	if nodos0 > 0 and nodos_fin > nodos0 * 1.25:
		_desglose(root, 0)  # dónde están los nodos de más (una pestaña abierta no es fuga: ver la columna «pestaña»)
	if nodos0 > 0 and nodos_fin > nodos0 * 1.25:
		print("AVISO: los nodos crecieron más de 25 % desde la semana 3: posible fuga")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	quit()
