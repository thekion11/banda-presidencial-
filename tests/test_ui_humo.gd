extends SceneTree
## Humo de UI en modo headless: recorre menú -> test -> campaña -> elección -> gobierno sin errores de script.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO UI: ", msg)


func _init() -> void:
	Movimiento.forzado = 0; _correr.call_deferred()  # sin animaciones: mide posiciones finales también con xvfb


const SEMILLAS := [7, 11, 20260415, 31337, 99991, 123456]


func _correr() -> void:
	## Recorre la UI con varias semillas: el layout no debe depender del contenido de la mano.
	Tutorial.ruta = "user://preferencias_prueba.json"  # no tocar las preferencias reales
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	var idx := 0
	for sem in SEMILLAS:
		print("semilla ", sem)
		await _una(sem, idx)
		idx += 1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ultima_config.json"))
	for f in await AyudaUI.carrera(self):
		_check(false, f)
	await _informe()
	if _fallos == 0:
		print("HUMO DE UI OK (%d semillas)" % SEMILLAS.size())
	quit(0 if _fallos == 0 else 1)


func _una(semilla: int, idx: int = 0) -> void:
	if idx == 1:  # la segunda partida prueba la ruta "saltar tutorial"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	if idx == 0:  # PR-01: la pantalla de afiliación y la lista de partidos existentes
		main.mostrar_afiliacion()
		await process_frame
		var af: Node = main._pantalla
		_check(af.find_children("*", "Button", true, false).size() == 3, "afiliación: tres tarjetas")
		af._elegir("existente")
		await process_frame
		await process_frame
		_check(af.find_children("*", "Button", true, false).size() >= 15, "afiliación: lista de partidos")
	main.mostrar_partido()
	await process_frame
	var pp: Node = main._pantalla
	_check(pp._preguntas().size() == 3, "el test ideológico empieza en modo rápido (3 preguntas)")
	for p in pp._preguntas():
		pp._responder(p["opciones"][1])
	_check(pp._respuestas.size() == 3, "el test rápido se completa en 3 toques")
	for _k in range(4):
		await process_frame
	var r_fundar := Rect2()
	var ir_b: Array = pp.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Iniciar Campaña"))
	_check(ir_b.size() == 1, "la pantalla de fundación debe tener su botón principal")
	if ir_b.size() == 1:
		r_fundar = (ir_b[0] as Button).get_global_rect()
	pp._fundar()
	await process_frame
	_check(main._pantalla is PantallaDia and main.motor.estado.etapa == "campana", "tras fundar el partido se va directo a la campaña (el gabinete se elige al ganar)")
	var partido: Dictionary = main.motor.estado.partido.duplicate(true)
	if idx == 0:  # «Nueva partida como la última vez»
		main.mostrar_menu()
		await process_frame
		var rb: Array = main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Partida rápida"))
		_check(rb.size() == 1, "el menú ofrece la partida rápida")
		main._repetir_ultima()
		await process_frame
		_check(main.motor != null and String(main.motor.estado.partido["nombre"]) == String(partido["nombre"]) and main._pantalla is PantallaDia, "la partida rápida repite el partido y va directo al mapa (1 toque)")
	partido["indicadores_iniciales"]["aprobacion"] = 90.0  # la prueba recorre el gobierno: que la campaña no la pierda al azar
	var campana := Partida.crear(main.datos, semilla, partido)  # semilla fija: la prueba no depende del reloj
	# transición presidencial: recién ganada la elección (turno 1 de gobierno, sin gabinete desde la votación) el día cede al gabinete
	main.motor = Partida.crear(main.datos, semilla, partido)
	main.motor.estado.etapa = "gobierno"
	main.motor.estado.turno_actual = 1
	main.motor.estado.registrar_entrada("eleccion", {})
	main.mostrar_dia()
	await process_frame
	_check(main._pantalla is PantallaGabinete, "tras ganar la elección viene la transición: elegir el gabinete")
	var sel_g: Array = main._pantalla.find_children("*", "Button", true, false)
	var conf: Button = sel_g.filter(func(b: Button) -> bool: return b.text == "Confirmar gabinete y asumir")[0]
	for _k in range(4):
		await process_frame
	_check(conf.get_global_rect().position.y == r_fundar.position.y, "el botón principal del gabinete queda a la altura del de la fundación (%s vs %s)" % [conf.get_global_rect(), r_fundar])
	_check(not conf.disabled, "el gabinete por defecto (los 25 ministerios) debe poder confirmarse")
	var rel: Array = main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text in ["Equilibrado", "Máxima eficacia"])
	_check(rel.size() == 2, "PR-05: dos botones de relleno (equilibrado y máxima eficacia)")
	# tablero (opción A del usuario, 27-nov): 25 puestos; cada uno muestra sus 3 candidatos (75 en total)
	var puestos: Array = main._pantalla.find_children("*", "Puesto", true, false)
	puestos = main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b is TableroGabinete.Puesto)
	_check(puestos.size() == 25, "el tablero tiene los 25 ministerios, hay %d" % puestos.size())
	var vistos := 0
	for p in puestos:
		(p as Button).pressed.emit()
		await process_frame
		vistos += main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b is TableroGabinete.Candidato and not b.is_queued_for_deletion()).size()
	_check(vistos == 75, "deben verse los 75 candidatos (3 por ministerio), se vieron %d" % vistos)
	var tam: int = int(main.datos["leyes"]["gabinete"]["tamano"])
	(puestos[0] as Button).pressed.emit()
	await process_frame
	var otro: Array = main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b is TableroGabinete.Candidato and not b.is_queued_for_deletion() and not main.motor.estado.gabinete.has(b.id))
	if not otro.is_empty():
		var oid: String = otro[0].id
		(otro[0] as Button).pressed.emit()  # primer toque: anticipa el efecto
		await process_frame
		var c2: Array = main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b is TableroGabinete.Candidato and not b.is_queued_for_deletion() and b.id == oid)
		(c2[0] as Button).pressed.emit()  # segundo toque: nombra
		await process_frame
	var contador: Array = main._pantalla.find_children("*", "Label", true, false).filter(func(l: Label) -> bool: return l.text.begins_with("Gabinete: "))
	_check(not contador.is_empty() and contador[0].text == "Gabinete: %d de %d ministros" % [tam, tam], "nombrar reemplaza al del puesto: siguen %d de %d" % [tam, tam])
	_check(not conf.disabled, "con %d ministros se puede confirmar" % tam)
	conf.pressed.emit()
	await process_frame
	_check(main._pantalla is PantallaDia and not PanelGabinete.transicion_pendiente(main.motor), "confirmar el gabinete cierra la transición y abre el primer día de gobierno")
	main.motor = campana  # el resto recorre la campaña completa
	main.mostrar_dia()
	await process_frame
	var dia: Node = main._pantalla
	_check(dia is PantallaDia, "no se llegó a la pantalla de día")
	await _tutorial(dia, idx)
	for sem in range(8):
		dia._cola_eventos.clear()
		dia._on_region("metropolitana")
		for _k in range(4):
			if not main.motor.estado.mano.is_empty():
				dia._jugar()
		dia._terminar_turno()
		await process_frame
	_check(main.motor.estado.eleccion_pendiente(8), "debería haber elección pendiente")
	var regional: Dictionary = main.motor.estado.aprobacion_regional.duplicate()
	dia._resolver_eleccion()
	await process_frame
	await _eleccion(main, dia, regional)
	main.motor.estado.propuestas_abiertas.append("prop_metro_suroriente")
	for panel in ["comite", "congreso", "gabinete", "mapa"]:
		dia._abrir_panel(panel)
		await process_frame
		await process_frame
		_check_tactil(dia, "panel " + panel)
		if panel == "comite":
			var b3: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "3D")
			b3[0].pressed.emit()
			await process_frame
			var m3: Array = dia._zona_panel.find_children("*", "ComiteMapa3D", true, false)
			_check(m3.size() == 1 and m3[0].visible, "la vista 3D del Comité debe mostrarse")
			var bm: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "Modificar trazado")
			if not bm.is_empty():
				bm[0].pressed.emit()
				await process_frame
	main.motor.estado.propuestas_abiertas.erase("prop_metro_suroriente")  # se inyectó solo para recorrer el panel
	var guardado: Dictionary = main.motor.estado.exportar_guardado()
	var rep0: MotorTurno = Partida.reproducir(main.datos, guardado)
	_check(rep0.estado.calcular_huella() == main.motor.estado.calcular_huella(), "guardado no reproduce la partida de la UI")
	await HumoV2.recorrer(self, main, dia)  # pantallas v2 (tests/humo_v2.gd)
	await _fin_y_cartera(main, dia)
	_check(not main.motor.estado.partido.is_empty(), "partido vacío")
	main.queue_free()
	await process_frame


func _botones(dia: Node, texto: String) -> Array:
	return dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with(texto) and not b.disabled)


func _check_tactil(raiz: Node, donde: String) -> void:
	## CLAUDE.md §5: toda zona táctil visible mide al menos 44 px por lado.
	for b in raiz.find_children("*", "BaseButton", true, false):
		var c := b as Control
		if c.is_visible_in_tree() and not (b is BaseButton and (b as BaseButton).disabled) and (c.size.x < 43.5 or c.size.y < 43.5) and c.size.x > 1.0:
			_check(false, "zona táctil menor de 44 px en %s: %s (%s) %s" % [donde, c.name, (b as Button).text if b is Button else "", c.size])


func _textos(nodo: Node) -> String:
	var t: PackedStringArray = []
	for l in nodo.find_children("*", "Label", true, false):
		t.append((l as Label).text)
	return "\n".join(t)


func _boton(nodo: Node, texto: String) -> Button:
	for b in nodo.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(texto):
			return b
	return null


func _tutorial(dia: Node, idx: int) -> void:
	## Tutorial de la primera partida: 5 pasos, saltable y que no se repite (solo preferencia local).
	var tuts: Array = dia._capa.find_children("*", "Tutorial", true, false)
	if idx >= 2:
		_check(tuts.is_empty() and not Tutorial.debe_mostrar(), "el tutorial no debe repetirse una vez visto o saltado")
		return
	_check(tuts.size() == 1, "la primera partida debe mostrar el tutorial")
	if tuts.is_empty():
		return
	for _k in range(4):
		await process_frame
	var t: Node = tuts[0]
	_check_tactil(t, "tutorial")
	var rect_sig := Rect2()
	if idx == 0:
		for paso in range(Tutorial.PASOS.size()):
			var b: Button = _boton(t, "Siguiente") if paso < Tutorial.PASOS.size() - 1 else _boton(t, "Entendido")
			_check(b != null, "el paso %d del tutorial necesita su botón" % (paso + 1))
			if b == null:
				break
			if paso == 0:
				rect_sig = b.get_global_rect()
			_check(b.get_global_rect() == rect_sig, "el botón principal del tutorial debe quedar en el mismo sitio (paso %d)" % (paso + 1))
			_check(_textos(t).contains("PASO %d DE 5" % (paso + 1)), "el tutorial debe indicar el paso %d de 5" % (paso + 1))
			_check(t._marco.visible and t._marco.size.x > 20.0, "el paso %d debe resaltar su elemento" % (paso + 1))
			b.pressed.emit()
			await process_frame
	else:
		_boton(t, "Saltar tutorial").pressed.emit()
		await process_frame
	await process_frame
	_check(dia._capa.find_children("*", "Tutorial", true, false).is_empty(), "el tutorial debe cerrarse")
	_check(not Tutorial.debe_mostrar(), "el tutorial no debe repetirse: se guarda la preferencia")


func _eleccion(main: Node, dia: Node, regional: Dictionary) -> void:
	## Resultado de elección: mide aprobación (no "votos"), con umbral, desglose por región y aviso de 2ª vuelta.
	var motor: MotorTurno = main.motor
	var reales: Array = dia._capa.find_children("*", "Control", false, false).filter(func(c: Node) -> bool: return _boton(c, "Asumir el gobierno") != null or _boton(c, "Ir a la segunda") != null or _boton(c, "Ver resultado") != null)
	_check(reales.size() == 1, "la elección debe mostrar su pantalla de resultado")
	if reales.size() == 1:  # la elección real pesa cada región por su población (pedido del usuario del 27-nov-2026)
		var tr := _textos(reales[0])
		_check(tr.contains("de la más poblada") and tr.contains("pesa ") and tr.contains("Votos estimados"), "la elección muestra el voto por región ordenado por población, con su peso")
		_check(not reales[0].find_children("*", "MapaChile", true, false).is_empty(), "la elección muestra el mapa de quién gana cada región")
	var casos := [
		{"electo": true, "balotaje": false, "ronda": 1, "voto_final": 62.0, "umbral": 51.0, "boton": "Asumir el gobierno", "texto": "Presidente electo"},
		{"electo": false, "balotaje": true, "ronda": 1, "voto_final": 44.0, "umbral": 51.0, "boton": "Ir a la segunda vuelta", "texto": "segunda vuelta"},
		{"electo": true, "balotaje": false, "ronda": 2, "voto_final": 53.0, "umbral": 51.0, "boton": "Asumir el gobierno", "texto": "segunda vuelta"},
		{"electo": false, "balotaje": false, "ronda": 2, "voto_final": 40.0, "umbral": 51.0, "boton": "Ver resultado final", "texto": "No alcanzaste"},
	]
	var rect_btn := Rect2()
	for c in casos:
		var pant: Control = PantallaEleccion.crear(motor, main.datos["regiones"], regional, c, func() -> void: pass)
		dia._capa.add_child(pant)
		for _k in range(3):
			await process_frame
		var txt := _textos(pant)
		_check(not txt.contains("votos"), "el resultado no debe hablar de votos: mide aprobación")
		_check(txt.contains("Aprobación") and txt.contains("umbral") and txt.contains(str(c["texto"])), "falta aprobación/umbral/veredicto (%s)" % c["texto"])
		_check(txt.contains("Aprobación por región"), "falta el desglose por región")
		_check(txt.contains("Sacaste") or txt.contains("Te faltaron"), "la elección dice el porqué en una frase (meta, diferencia)")
		if c["balotaje"]:
			_check(txt.contains("semanas más de campaña"), "falta el aviso de segunda vuelta")
		var b := _boton(pant, String(c["boton"]))
		_check(b != null, "falta el botón " + String(c["boton"]))
		if b != null:
			if rect_btn.size == Vector2.ZERO:
				rect_btn = b.get_global_rect()
			_check(b.get_global_rect() == rect_btn, "el botón principal de la elección debe quedar en el mismo sitio")
		_check_tactil(pant, "resultado de elección")
		pant.queue_free()
		await process_frame


func _fin_y_cartera(main: Node, dia: Node) -> void:
	var motor: MotorTurno = main.motor
	var est: EstadoSimulacion = motor.estado
	# Cartera de proyectos: solo lectura, con y sin partida
	var huella0 := est.calcular_huella()
	var n_reg := est.registro_acciones.size()
	var cart: PantallaCartera = PantallaCartera.crear(main.datos, motor)
	dia._capa.add_child(cart)
	for _k in range(3):
		await process_frame
	var n_reales := 0
	for c in main.datos["cartas"]:
		n_reales += 1 if PantallaCartera._es_real(c) else 0
	_check(cart.filtrados.size() == n_reales and n_reales > 1000, "la cartera debe listar todos los proyectos reales (%d)" % cart.filtrados.size())
	var volver := _boton(cart, "Volver")
	var rect_v := volver.get_global_rect()
	_check_tactil(cart, "cartera")
	var tipos := ["Obras públicas", "Proyectos de ley", "Reformas", "Todos"]
	for t in tipos:
		_boton(cart, t).pressed.emit()
		await process_frame
		var ok := true
		for c in cart.filtrados:
			ok = ok and (t == "Todos" or String(c["meta"]["tipo"]).replace("propuesta_constitucional", "reforma_constitucional") == cart.f_tipo)
		_check(ok and not cart.filtrados.is_empty(), "el filtro de tipo %s debe filtrar" % t)
		_check(volver.get_global_rect() == rect_v, "el botón Volver debe quedar en el mismo sitio con el filtro " + t)
	_boton(cart, "Obras públicas").pressed.emit()
	_boton(cart, "Metropolitana").pressed.emit()
	await process_frame
	_check(not cart.filtrados.is_empty() and cart.filtrados.all(func(c: Dictionary) -> bool: return String(c["meta"].get("region_id", "")) == "metropolitana"), "el filtro de región debe filtrar")
	_boton(cart, "Todas").pressed.emit()
	_boton(cart, "Todos").pressed.emit()
	await process_frame
	cart.f_sector = ""
	_boton(cart, "Siguiente").pressed.emit()
	await process_frame
	_check(cart.pagina == 1, "la paginación debe avanzar")
	var txt := _textos(cart)
	_check(txt.contains("Fuente:") and txt.contains("Estado real:"), "cada proyecto debe mostrar su fuente y su estado")
	_check(est.calcular_huella() == huella0 and est.registro_acciones.size() == n_reg, "mirar la cartera no debe alterar la partida")
	cart.queue_free()
	var libre: PantallaCartera = PantallaCartera.crear(main.datos)
	dia._capa.add_child(libre)
	for _k in range(3):
		await process_frame
	_check(_textos(libre).contains("Sin partida abierta"), "la cartera sin partida debe decirlo")
	libre.queue_free()
	await process_frame
	# Fin de partida con resumen (se cierra la partida: va al final)
	var ev_real := ""
	for e in motor.catalogo_eventos:
		if e.get("meta", {}).has("fecha_real"):
			ev_real = String(e["id"])
			break
	est.eventos_ocurridos[ev_real] = 3
	for fin in ["fin_mandato", "crisis"]:
		motor.mandato.finalizar(fin)
		main.mostrar_fin()
		for _k in range(4):
			await process_frame
		var pf: Node = main._pantalla
		var t := _textos(pf)
		for clave in ["Puntaje final", "Promesas cumplidas", "Leyes aprobadas", "Obras terminadas", "Línea de tiempo"]:
			_check(t.contains(clave), "el fin de partida debe mostrar: " + clave)
		_check(not t.contains("votos"), "el fin de partida no debe hablar de votos")
		var vb := _boton(pf, "Volver al inicio")
		_check(vb != null and vb.get_global_rect() == Rect2(16, 739, 358, 52), "el botón principal del fin debe estar en la posición fija (%s)" % (vb.get_global_rect() if vb != null else Rect2()))
		_check_tactil(pf, "fin de partida")
	est.etapa = "derrota_electoral"
	est.resultado_final = {"motivo": "derrota_electoral", "voto_final": 40.0, "puntaje": 0}
	main.mostrar_fin()
	for _k in range(3):
		await process_frame
	_check(_textos(main._pantalla).contains("aprobación"), "la derrota debe hablar de aprobación, no de votos")


func _informe() -> void:
	## Informe de prueba: se abre desde el menú, resume el registro local y es táctil.
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.mostrar_menu()
	await process_frame
	var menu: Node = main._pantalla
	var b: Array = menu.find_children("*", "Button", true, false).filter(func(x: Button) -> bool: return x.text == "Informe de prueba")
	_check(b.size() == 1, "el menú debe tener el botón «Informe de prueba»")
	if b.size() == 1:
		(b[0] as Button).pressed.emit()
		for _k in range(3):
			await process_frame
		var inf: Array = menu.get_children().filter(func(x: Node) -> bool: return x is PantallaInforme)
		_check(inf.size() == 1, "el informe de prueba debe abrirse")
		if inf.size() == 1:
			_check_tactil(inf[0], "informe de prueba")
	var t := RegistroPrueba.informe()
	_check(t.contains("informe de prueba") and t.contains("versión") and t.contains("partidas registradas"), "el informe debe traer versión y resumen")
