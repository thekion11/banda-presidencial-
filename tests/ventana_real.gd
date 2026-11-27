extends SceneTree
## Ventana real (informe de QA, bajo xvfb): lo que las pruebas headless simulan cambiando la base lógica, aquí se crea de
## verdad con el tamaño de ventana que se pase (--resolution y el tercer argumento). Recorre todas las pantallas
## (RecorridoUI) y comprueba: tamaño lógico = Main.base_para (o 390×844 con bandas), nada fijo se sale de lo visible,
## botones ≥ 44 lógicos, mapa del día > 1/3 y «Terminar semana» entero. Imprime una línea «VENTANA,…» por tamaño.
## Uso: xvfb-run -a -s "-screen 0 1400x1400x24" godot --path . --rendering-method gl_compatibility --resolution 360x640 -s tests/ventana_real.gd -- 360x640 [escala_letra]

var _ventana := Vector2i(390, 844)
var _fallos: Array[String] = []
var _botones := 0
var _lienzo := Vector2.ZERO  # el del día (el recorrido restaura la base al terminar)


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		var wh := a[0].split("x")
		_ventana = Vector2i(int(wh[0]), int(wh[1]))
	if a.size() > 1:
		Ajustes.escala_prueba = float(a[1])
	DisplayServer.window_set_size(_ventana)
	_correr.call_deferred()


static func _en_scroll(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _fallo(msg: String) -> void:
	if _fallos.size() < 12:
		_fallos.append(msg)


func _auditar(main: Node, paso: String) -> void:
	var vis := root.get_visible_rect().size
	var esperado := Vector2(main.base_para(_ventana))
	if not vis.is_equal_approx(esperado):
		_fallo("%s: lienzo %s, se esperaba %s" % [paso, vis, esperado])
	for n in main.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or _en_scroll(c):
			continue
		var r := c.get_global_rect()
		if (c is Label or c is Button) and String(c.get("text")).strip_edges() != "":
			if r.position.x < -0.5 or r.end.x > vis.x + 0.5 or r.end.y > vis.y + 0.5:
				_fallo("%s: «%s» se sale (%s)" % [paso, String(c.get("text")).left(24), r])
		if c is BaseButton:
			_botones += 1
			if r.size.x < Tema.TACTIL - 0.5 or r.size.y < Tema.TACTIL - 0.5:
				_fallo("%s: botón «%s» mide %s" % [paso, String(c.get("text")).left(24), r.size])
	if paso == "día":
		_lienzo = vis
		var dia: PantallaDia = main._pantalla
		if dia._mapa.size.y <= vis.y / 3.0:
			_fallo("día: el mapa mide %d de %d" % [dia._mapa.size.y, vis.y])
		if dia._btn_jugar.get_global_rect().end.y > vis.y + 0.5:
			_fallo("día: «Terminar semana» cortado")


func _correr() -> void:
	for i in range(3):
		await process_frame
	var real := DisplayServer.window_get_size()
	await RecorridoUI.recorrer(self, func(main: Node, paso: String) -> void: _auditar(main, paso))
	var vis := _lienzo
	print("VENTANA,%dx%d,real %dx%d,letra %s,lienzo %dx%d,botones %d,fallos %d" % [_ventana.x, _ventana.y, real.x, real.y, str(Ajustes.escala_prueba), vis.x, vis.y, _botones, _fallos.size()])
	for f in _fallos:
		print("  FALLO: ", f)
	quit()
