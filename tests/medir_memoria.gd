extends SceneTree
## Memoria por pantalla (CLAUDE.md §5: RAM ≤ 800 MB). No es una prueba del CI: es un informe.
## Uso: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/medir_memoria.gd
## Mide, en cada paso del recorrido de la interfaz (RecorridoUI) y en las escenas pesadas (urbana, Comité 3D,
## hito de obra): la memoria estática de Godot, la memoria de video que lleva el renderizador (texturas,
## buffers) y el RSS del proceso (/proc). En escritorio es una estimación: el teléfono real sigue pendiente.

var _filas: Array[String] = []
var _max_rss := 0.0


func _init() -> void:
	_correr.call_deferred()


func _rss_mb() -> float:
	var f := FileAccess.open("/proc/%d/status" % OS.get_process_id(), FileAccess.READ)
	if f == null:
		return -1.0
	while not f.eof_reached():  # /proc informa tamaño 0: se lee línea a línea
		var l := f.get_line()
		if l.begins_with("VmRSS:"):
			return float(l.split(":")[1].strip_edges().split(" ")[0]) / 1024.0
	return -1.0


func _medir(_raiz: Node, paso: String) -> void:
	var estatica := OS.get_static_memory_usage() / 1048576.0
	var video := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var texturas := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
	var rss := _rss_mb()
	_max_rss = maxf(_max_rss, rss)
	_filas.append("| %s | %.0f | %.0f | %.0f | %.0f |" % [paso, estatica, video, texturas, rss])


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _correr() -> void:
	await RecorridoUI.recorrer(self, _medir)
	for n in root.get_children():
		if n.name == "Main":
			n.queue_free()
	await _cuadros(3)
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(main.datos, 5, GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, main.datos["ideologia"]))
	main.motor.estado.etapa = "gobierno"
	main.motor.estado.propuestas_abiertas.append("prop_metro_suroriente")
	main.mostrar_dia()
	await _cuadros(4)
	var dia: Node = main._pantalla
	dia._abrir_urbano()
	await _cuadros(8)
	_medir(main, "mapa urbano de Santiago")
	main.mostrar_dia()
	await _cuadros(6)
	_medir(main, "día, tras volver del mapa urbano")
	dia = main._pantalla
	dia._abrir_panel("comite")
	await _cuadros(4)
	var b3d: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "3D")
	if not b3d.is_empty():
		b3d[0].pressed.emit()
		await _cuadros(8)
		_medir(main, "Comité 3D")
	dia._abrir_hito({"nombre": "Obra", "dias_totales": 400, "dias_avanzados": 200, "retrasos": 0, "carta_id": "", "region": "metropolitana", "efectos_final": []})
	await _cuadros(8)
	_medir(main, "hito de obra 3D (con el Comité abierto)")
	main.mostrar_dia()
	await _cuadros(6)
	_medir(main, "día, tras cerrar el Comité 3D y el hito")
	for vuelta in range(2):  # repetir: si la memoria no sigue subiendo, lo retenido es el conjunto de buffers del renderizador (se reutiliza), no una fuga
		dia = main._pantalla
		dia._abrir_urbano()
		await _cuadros(8)
		main.mostrar_dia()
		await _cuadros(4)
		dia = main._pantalla
		dia._abrir_panel("comite")
		await _cuadros(4)
		b3d = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "3D")
		if not b3d.is_empty():
			b3d[0].pressed.emit()
			await _cuadros(8)
		main.mostrar_dia()
		await _cuadros(6)
		_medir(main, "día, tras repetir urbano + Comité 3D (vuelta %d)" % (vuelta + 2))
	print("| Paso | Estática MB | Video MB | Texturas MB | RSS MB |")
	print("|---|---|---|---|---|")
	for f in _filas:
		print(f)
	print("RSS máximo: %.0f MB (límite 800 MB)" % _max_rss)
	quit()
