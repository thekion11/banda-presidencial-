extends SceneTree
## Cobertura de cartas por gabinete: ninguna área de ministerio se queda sin cartas en ningún año del mandato (según las ventanas de disponibilidad por año), y la mano
## de un gabinete mínimo (solo las áreas que siempre circulan) tiene de dónde sacar cartas. Las condiciones por evento, meta o fiscal se cubren en test_sin_atascos.

const MINIMO_POR_AREA_Y_ANIO := 10
const MINIMO_SIEMPRE := 3  # «comité» y «estado» son áreas pequeñas por diseño (propuestas del Comité y cartas de Estado)

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var alias: Dictionary = datos["leyes"]["gabinete"]["categorias_alias"]
	var siempre: Array = datos["leyes"]["gabinete"]["categorias_siempre"]
	var anios := int(datos["leyes"]["gabinete"]["anios_mandato"])
	var areas := {}
	for mi in datos["ministros"]:
		areas[String(mi["categoria_afin"])] = true
	_check(areas.size() >= 10, "áreas de ministerio (%d)" % areas.size())
	var cuenta := {}
	for c in datos["cartas"]:
		var cat := String(alias.get(c["categoria"], c["categoria"]))
		var d: Variant = c.get("disponibilidad", null)
		for y in range(1, anios + 1):
			if d != null:
				if d.get("anio_desde", null) != null and y < int(d["anio_desde"]):
					continue
				if d.get("anio_hasta", null) != null and y > int(d["anio_hasta"]):
					continue
			cuenta["%s:%d" % [cat, y]] = int(cuenta.get("%s:%d" % [cat, y], 0)) + 1
	var minimo := 99999
	for area in areas.keys():
		for y in range(1, anios + 1):
			var n := int(cuenta.get("%s:%d" % [area, y], 0))
			minimo = mini(minimo, n)
			_check(n >= MINIMO_POR_AREA_Y_ANIO, "el área %s tiene solo %d cartas en el año %d (mínimo %d)" % [area, n, y, MINIMO_POR_AREA_Y_ANIO])
	for area in siempre:
		for y in range(1, anios + 1):
			_check(int(cuenta.get("%s:%d" % [area, y], 0)) >= MINIMO_SIEMPRE, "el área siempre activa %s tiene pocas cartas en el año %d" % [area, y])
	print("test_cobertura: %d áreas, mínimo de cartas por área y año = %d" % [areas.size(), minimo])
	print("test_cobertura: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
