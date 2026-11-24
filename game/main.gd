extends Control
## Enrutador de pantallas + guardado por eventos (semilla + historial de entradas).

const RUTA_GUARDADO := "user://guardado.json"

var datos: Dictionary = {}
var geo: Dictionary = {}
var motor: MotorTurno
var _pantalla: Control


var _huella_datos: String = ""


func _ready() -> void:
	datos = Datos.cargar_todo()
	_huella_datos = Datos.huella(datos)  # una sola vez: calcularla en cada guardado costaría ~1 s en un teléfono modesto
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
	mostrar_menu()


func _cambiar(p: Control) -> void:
	if _pantalla != null:
		_pantalla.queue_free()
	_pantalla = p
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.modulate.a = 0.0
	add_child(p)
	p.create_tween().tween_property(p, "modulate:a", 1.0, 0.22)  # el tween muere con la pantalla (antes: aviso «Target object freed»)


func mostrar_menu(aviso: String = "") -> void:
	var m := PantallaMenu.new()
	m.aviso = aviso
	m.hay_guardado = FileAccess.file_exists(RUTA_GUARDADO)
	m.datos = datos
	m.nueva.connect(mostrar_afiliacion)
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


func _iniciar_campana(partido: Dictionary) -> void:
	var semilla := int(Time.get_unix_time_from_system()) % 2000000000
	motor = Partida.crear(datos, semilla, partido)
	UrbanoBase.reiniciar()  # líneas ocultas y líneas del jugador de la partida anterior no pasan a la nueva
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
	motor = Partida.reproducir(datos, g)
	UrbanoBase.reiniciar()
	mostrar_dia()


func mostrar_dia() -> void:
	if motor.estado.etapa not in ["campana", "gobierno"] and not motor.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		mostrar_fin()
		return
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
	RegistroPrueba.anotar("accion", motor, _huella_datos)
