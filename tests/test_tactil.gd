extends SceneTree
## Zonas táctiles ≥ 44 px (CLAUDE.md §5): recorre las pantallas y paneles y exige que todo botón visible mida al menos
## Tema.TACTIL de alto y de ancho. Mide el estado final (sin animaciones).

var _fallos := 0
var _vistos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	Movimiento.forzado = 0
	_correr.call_deferred()


func _auditar(raiz: Node, donde: String) -> void:
	for n in raiz.find_children("*", "BaseButton", true, false):
		var b := n as BaseButton
		if not b.is_visible_in_tree():
			continue
		_vistos += 1
		var t := b.get_global_rect().size
		var nombre: String = (b as Button).text.replace("\n", " ").left(30) if b is Button else String(b.name)
		_check(t.x >= Tema.TACTIL - 0.5 and t.y >= Tema.TACTIL - 0.5, "%s: «%s» mide %s (mín. %d)" % [donde, nombre, t, int(Tema.TACTIL)])


func _paso(main: Node, donde: String) -> void:
	for i in range(3):
		await process_frame
	_auditar(main, donde)


func _correr() -> void:
	Tutorial.ruta = "user://preferencias_tactil.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var d: Dictionary = main.datos
	await _paso(main, "menú")
	main._pantalla._mostrar_creditos()
	await _paso(main, "créditos")
	main._pantalla.add_child(PantallaAjustes.new())
	await _paso(main, "ajustes")
	main.mostrar_afiliacion()
	await _paso(main, "afiliación")
	main.mostrar_partido("propio")
	await _paso(main, "test ideológico")
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Movimiento Cívico Austral", "MCA", "metropolitana", resp, d["ideologia"])
	main.motor = Partida.crear(d, 20260415, partido)
	main.mostrar_gabinete()
	await _paso(main, "gabinete (configuración)")
	main.mostrar_dia()
	await _paso(main, "día")
	var dia: Node = main._pantalla
	for panel in ["comite", "congreso", "gabinete", "nacion"]:
		dia._abrir_panel(panel)
		await _paso(main, "panel " + panel)
	dia._abrir_panel("mapa")
	var nombres: Dictionary = main.motor.catalogo_leyes["congreso"]["nombres"]
	dia._capa.add_child(OverlaysDia.evento({"titulo": "Debate", "hora": "22:00", "descripcion": "x", "escena": {"nombre": "Debate presidencial final", "ronda": 1, "rondas": 3},
		"opciones": [{"texto": "Una"}, {"texto": "Otra"}]}, func() -> void: pass, nombres, 1, func(_i: int) -> void: pass))
	await _paso(main, "evento con decisión")
	for h in dia._capa.get_children():
		if h is Control and h != dia._toast:
			h.queue_free()
	var el: Control = PantallaEleccion.crear(main.motor, d["regiones"], main.motor.estado.aprobacion_regional.duplicate(), {"electo": true, "balotaje": false, "ronda": 1, "voto_final": 57.4, "umbral": 51.0}, func() -> void: pass)
	dia._capa.add_child(el)
	await _paso(main, "elección")
	el.queue_free()
	main.motor.mandato.finalizar("fin_mandato")
	main.mostrar_fin()
	await _paso(main, "fin de partida")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	_check(_vistos > 60, "la auditoría debe revisar muchos botones (revisó %d)" % _vistos)
	if _fallos == 0:
		print("TÁCTIL OK (%d botones)" % _vistos)
	quit(1 if _fallos > 0 else 0)
