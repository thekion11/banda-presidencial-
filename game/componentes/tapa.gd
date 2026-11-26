class_name Tapa
extends RefCounted
## Las vistas opacas a pantalla completa (mapa urbano, hito de obra, cartera) tapan la pantalla del día. Mientras están
## abiertas, la pantalla de abajo se oculta para no dibujarla en cada cuadro: su mapa y su mano cuestan unas 970 llamadas
## de dibujo (tests/medir_cuadros.gd). Al cerrarse la vista, todo vuelve a verse. Fuera de la pantalla del día no hace nada.


static func cubrir(vista: Control) -> Control:
	vista.tree_entered.connect(_ocultar.bind(vista), CONNECT_ONE_SHOT)
	return vista


static func _ocultar(vista: Control) -> void:
	var capa := vista.get_parent()
	var pantalla := capa.get_parent() if capa != null else null
	if not (pantalla is PantallaDia):
		return
	var debajo: Array[CanvasItem] = []
	for h in pantalla.get_children():
		if h != capa and h is CanvasItem and (h as CanvasItem).visible:
			(h as CanvasItem).visible = false
			debajo.append(h)
	vista.tree_exiting.connect(func() -> void:
		for h in debajo:
			if is_instance_valid(h):
				h.visible = true, CONNECT_ONE_SHOT)
