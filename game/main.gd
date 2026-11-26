extends Control
## Enrutador de pantallas + guardado por eventos (semilla + historial de entradas).

const RUTA_GUARDADO := "user://guardado.json"
const RUTA_CACHE := "user://guardado.cache"  # instantánea de carga (ver sim/instantanea.gd): solo acelera continuar, el guardado sigue siendo el historial
const RUTA_ULTIMA := "user://ultima_config.json"  # último partido fundado: «Nueva partida como la última vez»

var datos: Dictionary = {}
var geo: Dictionary = {}
var motor: MotorTurno
var _pantalla: Control


var _huella_datos: String = ""


func _ready() -> void:
	Ajustes.cargar()
	var faltan := Datos.ARCHIVOS.filter(func(n: String) -> bool: return not FileAccess.file_exists("res://data/%s.json" % n))
	if not faltan.is_empty():  # instalación dañada: un mensaje claro en vez de un error de script
		mostrar_error_datos(faltan)
		return
	datos = Datos.cargar_todo()
	_huella_datos = Datos.huella_rapida(datos)  # una sola vez por arranque, y en disco por versión de datos: calcularla cada vez costaría ~1-2 s en un teléfono modesto
	geo = Datos.leer_json("res://data/geo/regiones_mapa.json")
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("#154F7A"), Color("#0B2236"), Color("#07182A")])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.18)
	gt.fill_to = Vector2(0.5, 1.05)
	gt.width = 390
	gt.height = 844
	var fondo := TextureRect.new()
	fondo.texture = gt
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	Feedback.iniciar(self)
	Musica.iniciar(self)
	get_tree().node_added.connect(_al_agregar)  # todo botón del juego se hunde y rebota al tocarlo (Movimiento.presion)
	mostrar_menu()


func _al_agregar(n: Node) -> void:
	if n is BaseButton:
		Movimiento.presion(n)


func _cambiar(p: Control) -> void:
	if _pantalla != null:
		_pantalla.queue_free()
	_pantalla = p
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(p)
	Movimiento.entrar_pantalla(p)  # se funde y sube; el tween muere con la pantalla


func mostrar_error_datos(faltan: Array) -> void:
	## Sin datos del juego no hay partida posible: se dice qué falta y la acción viable (reinstalar).
	var fondo := ColorRect.new()
	fondo.color = Tema.OCEANO
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24.0
	col.offset_right = -24.0
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	fondo.add_child(col)
	col.add_child(Tema.etiqueta("No se pudieron cargar los datos del juego", 20, Tema.TEXTO, true))
	col.add_child(Tema.etiqueta("Faltan archivos de la instalación (%s). Actualiza o reinstala Presidente de Chile desde Google Play." % ", ".join(faltan.map(func(n: String) -> String: return n + ".json")), 13, Tema.TEXTO_SUAVE))
	var b := Barras.boton_jugar()
	b.text = "Cerrar el juego"
	b.pressed.connect(func() -> void: get_tree().quit())
	col.add_child(b)


func mostrar_menu(aviso: String = "") -> void:
	Musica.etapa("gobierno")  # el menú suena solemne
	var m := PantallaMenu.new()
	m.aviso = aviso
	m.hay_guardado = FileAccess.file_exists(RUTA_GUARDADO)
	m.datos = datos
	m.nueva.connect(mostrar_afiliacion)
	m.hay_ultima = FileAccess.file_exists(RUTA_ULTIMA)
	m.repetir.connect(_repetir_ultima)
	m.continuar.connect(continuar_guardado)
	_cambiar(m)


func mostrar_afiliacion() -> void:
	var a := PantallaAfiliacion.new()
	a.datos = datos
	a.elegida.connect(mostrar_partido)
	_cambiar(a)


func mostrar_partido(afiliacion: String = "propio", base: Dictionary = {}) -> void:
	var p := PantallaPartido.new()
	p.datos = datos
	p.afiliacion = afiliacion
	p.base = base
	p.fundado.connect(_iniciar_campana)
	_cambiar(p)


func _repetir_ultima() -> void:
	## Partida rápida (1 toque): la última configuración o, si no hay, un partido por defecto; sin pasar por afiliación, test ni gabinete.
	var p: Variant = Datos.leer_json(RUTA_ULTIMA) if FileAccess.file_exists(RUTA_ULTIMA) else null
	if p is Dictionary and ValidarGuardado.partido_valido(p):  # un archivo dañado o de otra versión no llega a Partida.crear
		_iniciar_campana(p, true)
		return
	if FileAccess.file_exists(RUTA_ULTIMA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_ULTIMA))  # archivo dañado: se descarta
	var resp: Array[Dictionary] = []
	for q in datos["ideologia"]["preguntas"]:
		resp.append(q["opciones"][1])
	var base := GeneradorPartido.construir_partido_afiliado("propio", {}, "Movimiento Cívico Austral", "MCA", "metropolitana", resp, datos["ideologia"], datos["leyes"]["afiliacion"])
	GeneradorPartido.aplicar_habilidad(base, String(datos["leyes"]["habilidades"]["defecto"]), String(datos["leyes"]["habilidades"]["colores"][0]), datos["leyes"]["habilidades"])
	_iniciar_campana(base, true)


func _iniciar_campana(partido: Dictionary, directo: bool = false) -> void:
	var tmp := RUTA_ULTIMA + ".tmp"  # como el guardado: se escribe aparte y se renombra, un corte no deja el archivo a medias
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(partido))
		f.close()
		DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(RUTA_ULTIMA))
	var semilla := int(Time.get_unix_time_from_system()) % 2000000000
	motor = Partida.crear(datos, semilla, partido)
	UrbanoBase.reiniciar()  # líneas ocultas y líneas del jugador de la partida anterior no pasan a la nueva
	if directo:  # el gabinete real (25) ya viene relleno; se puede cambiar después desde la pestaña Gabinete
		guardar()
		mostrar_dia()
		return
	mostrar_gabinete()


func mostrar_gabinete() -> void:
	## Etapa de configuración: elección del gabinete antes de la campaña.
	var g := PantallaGabinete.new()
	g.motor = motor
	g.listo.connect(func() -> void:
		guardar()
		mostrar_dia())
	_cambiar(g)


func continuar_guardado() -> void:
	var g: Variant = Datos.leer_json(RUTA_GUARDADO)
	if not (g is Dictionary) or not g.has("semilla") or not g.has("entradas") or String(g.get("huella_datos", "")) != _huella_datos:
		push_warning("Guardado dañado o incompatible con esta versión de los datos.")
		# se conserva una copia (por si sirve para diagnosticar) y se quita el original: así el botón no reaparece fallando otra vez
		DirAccess.rename_absolute(ProjectSettings.globalize_path(RUTA_GUARDADO), ProjectSettings.globalize_path("user://guardado_descartado.json"))
		mostrar_menu("No se pudo continuar: el guardado estaba dañado o es de otra versión del juego. Empieza una partida nueva.")
		return
	if not ValidarGuardado.guardado_valido(g):  # misma huella de datos pero otra forma de las entradas: se descarta igual que un guardado dañado
		push_warning("Guardado con estructura inválida.")
		DirAccess.rename_absolute(ProjectSettings.globalize_path(RUTA_GUARDADO), ProjectSettings.globalize_path("user://guardado_descartado.json"))
		mostrar_menu("No se pudo continuar: el guardado estaba dañado o es de otra versión del juego. Empieza una partida nueva.")
		return
	var sha := FileAccess.get_sha256(RUTA_GUARDADO)
	var snap := Instantanea.leer(FileAccess.get_file_as_bytes(RUTA_CACHE)) if FileAccess.file_exists(RUTA_CACHE) else {}
	var rapida := Instantanea.vale_para(snap, _huella_datos, sha)
	motor = Partida.cargar(datos, g, snap, _huella_datos, sha)
	if not rapida:
		guardar_instantanea()  # el próximo arranque ya no tendrá que simular el historial
	UrbanoBase.reiniciar()
	mostrar_dia()


func mostrar_dia() -> void:
	if not MotorTurno.ETAPAS_JUEGO.has(motor.estado.etapa) and not motor.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		mostrar_fin()
		return
	Musica.etapa(motor.estado.etapa)
	var d := PantallaDia.new()
	d.motor = motor
	d.datos = datos
	d.geo = geo
	d.accion_hecha.connect(guardar)
	d.terminado.connect(mostrar_fin)
	_cambiar(d)


func mostrar_fin() -> void:
	guardar()
	var rf: Dictionary = motor.estado.resultado_final
	RegistroPrueba.anotar("fin", motor, _huella_datos, {"motivo": str(rf.get("motivo", motor.estado.etapa)), "puntaje": int(rf.get("puntaje", 0))})
	var f := PantallaFin.new()
	f.motor = motor
	f.datos = datos
	f.otra_vez.connect(func() -> void:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_GUARDADO))
		mostrar_menu())
	f.continuar.connect(func() -> void:  # carrera política: oposición o reelección, y vuelta a jugar
		if bool(motor.continuar_carrera()["ok"]):
			motor.iniciar_turno()
			UrbanoBase.reiniciar()
			guardar()
			mostrar_dia())
	f.reintentar.connect(func() -> void:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_GUARDADO))
		mostrar_partido())
	_cambiar(f)


func guardar() -> void:
	if motor == null:
		return
	var tmp := RUTA_GUARDADO + ".tmp"  # se escribe aparte y se renombra: un corte a mitad de la escritura no deja el guardado truncado
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(motor.estado.exportar_guardado(_huella_datos)))
		f.close()
		DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(RUTA_GUARDADO))
		var ult: Array[Dictionary] = motor.estado.entradas
		if not ult.is_empty() and ["cerrar", "eleccion", "continuar"].has(String(ult.back()["tipo"])):
			guardar_instantanea()  # al cerrar la semana (~10 ms): continuar después no simula el historial
	RegistroPrueba.anotar("accion", motor, _huella_datos)


func guardar_instantanea() -> void:
	if motor == null or not FileAccess.file_exists(RUTA_GUARDADO):
		return
	var f := FileAccess.open(RUTA_CACHE, FileAccess.WRITE)
	if f != null:
		f.store_buffer(Instantanea.tomar(motor, _huella_datos, FileAccess.get_sha256(RUTA_GUARDADO)))


var _atras_ms: int = -100000  # hora del último Atrás que pidió confirmar
var _aviso_atras: Toast


func atras() -> void:
	## Botón o gesto Atrás de Android (project.godot › quit_on_go_back = false: nunca sale al primer toque).
	## Cierra lo que esté encima (vista, hoja, ficha, ajustes, créditos, tutorial, telón); un evento o una votación
	## no se salta. Con un panel del día abierto vuelve al mapa. En el día pide un segundo Atrás para ir al menú
	## (la partida se guarda), y en el menú un segundo Atrás para salir. El resto de las pantallas vuelve al menú.
	var arriba: Control = null
	for n in get_tree().root.find_children("*", "Control", true, false):
		if n.has_meta("atras") and (n as Control).is_visible_in_tree() and not n.is_queued_for_deletion():
			arriba = n  # el último en el árbol es el que se dibuja encima
	if arriba != null:
		var accion: Variant = arriba.get_meta("atras")
		if accion is Callable:
			(accion as Callable).call()
		else:
			_avisar_atras(String(accion))
		return
	if _pantalla is PantallaDia:
		var dia := _pantalla as PantallaDia
		if dia._zona_panel.visible:
			dia._abrir_panel("mapa")
		elif _confirmar_atras("Pulsa Atrás otra vez para ir al menú. Tu partida se guarda sola."):
			guardar()
			mostrar_menu()
	elif _pantalla is PantallaMenu:
		if _confirmar_atras("Pulsa Atrás otra vez para salir del juego."):
			get_tree().quit()
	elif _pantalla != null:
		mostrar_menu()


func _confirmar_atras(aviso: String) -> bool:
	var ahora := Time.get_ticks_msec()
	if ahora - _atras_ms < 2500:
		_atras_ms = -100000
		return true
	_atras_ms = ahora
	_avisar_atras(aviso)
	return false


func _avisar_atras(txt: String) -> void:
	if _aviso_atras == null:
		_aviso_atras = Toast.new()
		add_child(_aviso_atras)
	move_child(_aviso_atras, get_child_count() - 1)  # encima de la pantalla actual
	_aviso_atras.mostrar(txt)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		atras()
		return
	if (what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST) and motor != null:
		guardar()  # al pasar a segundo plano (o salir) se deja también la instantánea al día
		guardar_instantanea()
