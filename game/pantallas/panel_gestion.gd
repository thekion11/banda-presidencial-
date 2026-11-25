class_name PanelGestion
extends VBoxContainer
## Panel "Gabinete" de la barra inferior: pestañas Gabinete, Equipo (asesores), Coalición e Internos (movimientos internos).
## Solo llama al facade MotorTurno; cada acción queda en el guardado por eventos.

const TABS := [["gabinete", "Gabinete"], ["equipo", "Equipo"], ["coalicion", "Coalición"], ["internos", "Internos"]]
static var pestana: String = "gabinete"

var motor: MotorTurno
var avisar: Callable
var cambio: Callable  # tras una acción: guardar y refrescar la pantalla de día
var _zona: Control


static func crear(p_motor: MotorTurno, p_avisar: Callable, p_cambio: Callable) -> PanelGestion:
	var g := PanelGestion.new()
	g.motor = p_motor
	g.avisar = p_avisar
	g.cambio = p_cambio
	g.add_theme_constant_override("separation", 8)
	g.construir()
	return g


func construir() -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	var tabs: Array = TABS
	if motor.estado.etapa == "oposicion":  # sin gabinete ni movimientos internos: solo alianzas
		tabs = [["coalicion", "Coalición"]]
		pestana = "coalicion"
	for t in tabs:
		var b := Tema.boton(t[1], Tema.ORO if pestana == t[0] else Tema.PANEL, Tema.TINTA if pestana == t[0] else Tema.TEXTO, 12, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			pestana = t[0]
			reconstruir())
		fila.add_child(b)
	add_child(fila)
	_zona = Control.new()
	_zona.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_zona)
	_pintar()


func reconstruir() -> void:
	for h in get_children():
		h.queue_free()
	construir()


func _accion() -> void:
	cambio.call()
	reconstruir()


func _pintar() -> void:
	var c: Control
	match pestana:
		"equipo":
			c = PanelEquipo.crear(motor, avisar, _accion)
		"coalicion":
			c = PanelCoalicion.crear(motor, avisar, _accion)
		"internos":
			c = PanelInternos.crear(motor, avisar, _accion)
		_:
			c = _gabinete()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zona.add_child(c)


func _gabinete() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var sel := PanelGabinete.crear(motor, "Confirmar gabinete", func() -> void:
		avisar.call("Gabinete actualizado: tu mano se ajustó a las nuevas áreas.")
		_accion(), avisar, true)
	sel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sel)
	return col
