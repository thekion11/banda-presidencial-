class_name VigiaCalidad
extends Node
## Calidad adaptativa del 3D (Comité y obras). Arranca con MSAA 2× y, si el teléfono pasa 2 s seguidos bajo 45 fps con
## la vista 3D en pantalla, lo apaga en esa vista y en las siguientes de la sesión. El informe real del teléfono
## (V2248, 1080×2388) dio un mínimo de 34 fps; en escritorio, sin MSAA el Comité 3D baja de 60 a 44 ms por cuadro
## (tests/medir_zoom.gd). Los teléfonos rápidos no cambian nada.

const FPS_MIN := 45.0
const SEGUNDOS := 2.0
static var sin_msaa := false  # ya se bajó una vez en esta sesión: las vistas nuevas arrancan sin MSAA

var vp: SubViewport
var _lento := 0.0


static func poner(contenedor: Node, p_vp: SubViewport) -> void:
	if sin_msaa:
		p_vp.msaa_3d = Viewport.MSAA_DISABLED
	var v := VigiaCalidad.new()
	v.vp = p_vp
	contenedor.add_child(v)


func _process(delta: float) -> void:
	if vp == null or vp.msaa_3d == Viewport.MSAA_DISABLED or not (get_parent() as CanvasItem).is_visible_in_tree():
		return
	_lento = _lento + delta if Engine.get_frames_per_second() < FPS_MIN else 0.0
	if _lento >= SEGUNDOS:
		vp.msaa_3d = Viewport.MSAA_DISABLED
		sin_msaa = true
