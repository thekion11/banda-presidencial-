extends SceneTree
## Entrada del mapa urbano: toque sobre una línea, arrastre, rueda y límites de zoom, solo una línea, burbuja de estación y pulsación larga en la leyenda.
var fallos := 0
func chk(c: bool, m: String) -> void:
	if not c:
		fallos += 1
		print("FALLO MAPA: ", m)
func _mouse(btn: bool, pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	return e
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	UrbanoBase.ocultas.clear()
	UrbanoBase.propias = []
	var tam := Vector2(358, 300)
	var c := UrbanoBase.preparar(tam, UrbanoMapa.MARGEN)
	var m := UrbanoMapa.new()
	m.size = tam
	root.add_child(m)
	m.datos = UrbanoBase.datos()
	m.trazo = 1.0
	await process_frame
	# toque sobre L5
	var l5: Dictionary = {}
	for l in c["metro"]:
		if l["id"] == "L5":
			l5 = l
	var q: Vector2 = l5["seg"][60]
	m._gui_input(_mouse(true, q, true))
	m._gui_input(_mouse(true, q, false))
	chk(UrbanoBase.ocultas.has("L5"), "un toque sobre la línea L5 debe ocultarla (sin zoom)")
	UrbanoBase.ocultas.clear()
	# arrastre: no debe ocultar nada y debe mover el mapa con zoom
	m._zoom_en(2.0, tam * 0.5)
	chk(absf(m.zoom - 2.0) < 0.001, "zoom 2")
	var p0 := m.pan
	m._gui_input(_mouse(true, q, true))
	var mv := InputEventMouseMotion.new()
	mv.position = q + Vector2(40, 10)
	mv.relative = Vector2(40, 10)
	m._gui_input(mv)
	m._gui_input(_mouse(true, q + Vector2(40, 10), false))
	chk(m.pan != p0, "arrastrar debe mover el mapa")
	chk(UrbanoBase.ocultas.is_empty(), "arrastrar no debe ocultar líneas")
	chk(m.pan.x <= 0.0 and m.pan.y <= 0.0 and m.pan.x >= tam.x - tam.x * 2.0 - 0.01, "el desplazamiento se mantiene dentro del mapa")
	# rueda y límites
	for _i in range(30):
		var w := InputEventMouseButton.new()
		w.button_index = MOUSE_BUTTON_WHEEL_UP
		w.pressed = true
		w.position = tam * 0.5
		m._gui_input(w)
	chk(m.zoom <= UrbanoMapa.ZOOM_MAX + 0.001, "el zoom respeta el máximo")
	for _i in range(60):
		var w2 := InputEventMouseButton.new()
		w2.button_index = MOUSE_BUTTON_WHEEL_DOWN
		w2.pressed = true
		w2.position = tam * 0.5
		m._gui_input(w2)
	chk(m.zoom >= 1.0 - 0.001 and m.pan == Vector2.ZERO, "al alejar del todo vuelve a la vista completa sin desplazamiento")
	# solo una línea
	UrbanoBase.solo_linea("L2")
	chk(UrbanoBase.ocultas.size() == 6 and not UrbanoBase.ocultas.has("L2"), "solo_linea deja una sola línea")
	UrbanoBase.ocultas.clear()
	# estación (con zoom)
	var est := UrbanoBase.estacion_en(c["estaciones"][10], tam, UrbanoMapa.MARGEN, 15.0)
	chk(not est.is_empty() and est["n"] == c["est_nombres"][10], "tocar una estación devuelve su nombre")
	# leyenda: pulsación larga
	var ley := LeyendaMetro.new()
	root.add_child(ley)
	await process_frame
	var b: Button = ley._fichas["L3"]
	b.button_down.emit()
	await create_timer(0.6).timeout
	chk(UrbanoBase.ocultas.size() == 6 and not UrbanoBase.ocultas.has("L3"), "la pulsación larga deja solo L3")
	b.button_up.emit()
	b.pressed.emit()
	chk(UrbanoBase.ocultas.size() == 6, "soltar tras la pulsación larga no debe alternar otra vez")
	UrbanoBase.ocultas.clear()
	await _comite_con_zoom()
	print("MAPA ENTRADA ", "OK" if fallos == 0 else "CON FALLOS")
	quit(0 if fallos == 0 else 1)


func _comite_con_zoom() -> void:
	## Mapa del Comité con zoom: arrastrar una estación la mueve (no el mapa); arrastrar en otro sitio mueve el mapa; el zoom se mantiene.
	var datos := Datos.cargar_todo()
	var g := GrafoTrazado.new()
	g.cargar(datos["grafo"])
	var v: Dictionary = datos["propuestas"][0]["variantes"][0]
	var ests: Array = g.estaciones_base(v)
	var m := ComiteMapa.new()
	m.size = Vector2(358, 270)
	root.add_child(m)
	await process_frame
	m.poner_variante(v["trazado"], bool(v["elevada"]))
	m.iniciar_edicion(g, ests)
	m._zoom_en(2.0, m.size * 0.5)
	chk(absf(m.zoom - 2.0) < 0.001, "el mapa del Comité acepta zoom")
	var punto: Vector2 = m._px(g.pos[ests[1]])
	var antes: String = ests[1]
	var pan0 := m.pan
	m._gui_input(_mouse(true, punto, true))
	chk(m.seleccion == 1, "pulsar sobre una estación (con zoom) la selecciona")
	var mv := InputEventMouseMotion.new()
	mv.position = punto + Vector2(50, 0)
	mv.relative = Vector2(50, 0)
	m._gui_input(mv)
	m._gui_input(_mouse(true, punto + Vector2(50, 0), false))
	chk(m.estaciones[1] != antes, "arrastrar la estación debe moverla a otro cruce")
	chk(m.pan == pan0, "arrastrar una estación no debe mover el mapa")
	var vacio := Vector2(m.size.x - 20, m.size.y - 20)
	var lejos := true
	for id in m.estaciones:
		if m._px(g.pos[id]).distance_to(vacio) < 40.0:
			lejos = false
	if lejos:
		m._gui_input(_mouse(true, vacio, true))
		var mv2 := InputEventMouseMotion.new()
		mv2.position = vacio + Vector2(-30, -20)
		mv2.relative = Vector2(-30, -20)
		m._gui_input(mv2)
		m._gui_input(_mouse(true, vacio + Vector2(-30, -20), false))
		chk(m.pan != pan0, "arrastrar en un sitio vacío debe mover el mapa")
