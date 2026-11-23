class_name PanelNacion
extends Control
## "Chile por regiones": mapa con aprobación por región y lista con líneas guía, como en la maqueta.

var _mapa: MapaChile
var _lista: Control
var _filas: Array[Dictionary] = []


func configurar(geo: Dictionary, regiones: Array, aprobacion: Dictionary, obras: Dictionary) -> void:
	_mapa = MapaChile.new()
	_mapa.leyenda = false
	_mapa.ciudades_visibles = false
	_mapa.estirar_x = 1.8
	_mapa.x_centro_rel = 0.27
	_mapa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mapa.cargar_geo(geo)
	_mapa.actualizar(aprobacion, obras)
	add_child(_mapa)
	_lista = Control.new()
	_lista.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lista.draw.connect(_dibujar)
	add_child(_lista)
	_filas.clear()
	for r in regiones:
		_filas.append({"id": r["id"], "nombre": String(r["nombre"]).replace(" de Santiago", "").replace(" y la Antártica Chilena", ""), "valor": float(aprobacion.get(r["id"], 0.0))})
	resized.connect(_lista.queue_redraw)
	_lista.queue_redraw()


func _dibujar() -> void:
	if _mapa == null:
		return
	var n := _filas.size()
	var size := _lista.size
	var y0 := 14.0
	var paso := (size.y - 28.0) / float(n)
	var x_lista := size.x * 0.56
	var fuente := Tema.fuente_texto(600)
	var chico := Tema.fuente_texto(400)
	for i in range(n):
		var f: Dictionary = _filas[i]
		var y := y0 + paso * (float(i) + 0.5)
		var c := _mapa.centro(String(f["id"]))
		var col := Tema.color_aprobacion(float(f["valor"]))
		_lista.draw_polyline(PackedVector2Array([c, Vector2(x_lista - 16.0, y)]), Color(1, 1, 1, 0.35), 1.0, true)
		_lista.draw_circle(c, 2.4, Tema.CREMA)
		_lista.draw_rect(Rect2(x_lista - 12.0, y - 9.0, 10.0, 18.0), col)
		_lista.draw_string(fuente, Vector2(x_lista + 6.0, y - 1.0), String(f["nombre"]), HORIZONTAL_ALIGNMENT_LEFT, size.x - x_lista - 8.0, 12, Tema.TEXTO)
		_lista.draw_string(chico, Vector2(x_lista + 6.0, y + 11.0), "Aprobación %d %%" % roundi(float(f["valor"])), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TEXTO_SUAVE)
