class_name UrbanoCache
extends SubViewport
## Capa base del mapa urbano (relieve, parques, río, ~23.000 tramos de calle y el Metro) pintada una sola vez en una
## textura del tamaño de la vista. Sin esto, el renderizador 2D rearmaba cada cuadro unos 160.000 vértices de una
## cartografía que no cambia (tests/medir_transiciones.gd). La vista se pinta a la escala real de la pantalla (en el
## teléfono, canvas_items dibuja ~2,75× la resolución lógica) para que la textura no se vea borrosa. Se repinta solo
## cuando cambia algo de la clave: tamaño, zoom, desplazamiento, líneas ocultas o propias, fecha o modo.

var pintar: Callable  # pintar(ci: CanvasItem): dibuja la capa base en coordenadas de la vista ya escaladas
var _clave: String = ""
var _lienzo: Node2D


func _init() -> void:
	disable_3d = true
	transparent_bg = false
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	_lienzo = Node2D.new()
	_lienzo.draw.connect(func() -> void:
		if pintar.is_valid():
			pintar.call(_lienzo))
	add_child(_lienzo)


func preparar(tam: Vector2, escala: float, clave: String) -> void:
	## Repinta la textura si cambió la clave; si no, la deja como está (cero trabajo por cuadro).
	var px := Vector2i(maxi(1, ceili(tam.x * escala)), maxi(1, ceili(tam.y * escala)))
	var c := "%s|%d|%d" % [clave, px.x, px.y]
	if c == _clave:
		return
	_clave = c
	size = px
	_lienzo.queue_redraw()
	render_target_update_mode = SubViewport.UPDATE_ONCE


func invalidar() -> void:
	_clave = ""
