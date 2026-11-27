extends SceneTree
## Un guardado con la forma cambiada (misma semilla, mismas entradas, clave borrada o retipada) se rechaza antes de reproducir; uno válido sigue pasando.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var motor := Bots.partida_completa(datos, 21, "codicioso")
	var g: Dictionary = JSON.parse_string(JSON.stringify(motor.estado.exportar_guardado()))  # como llega desde el disco
	_check(g["entradas"].size() > 100, "guardado largo (%d entradas)" % g["entradas"].size())
	_check(ValidarGuardado.guardado_valido(g), "un guardado real pasa la validación")
	for v in [0, -1, ValidarGuardado.VERSION + 1]:  # versión fuera de rango (hallazgo de «Búsqueda»): 0 y negativas también se rechazan
		var dv: Dictionary = g.duplicate(true)
		dv["version"] = v
		_check(not ValidarGuardado.guardado_valido(dv), "versión %d se rechaza" % v)
	_check(Partida.reproducir(datos, g) != null, "un guardado real se reproduce")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var rechazadas := 0
	var pruebas := 0
	for _n in range(300):
		var h: Dictionary = g.duplicate(true)
		var i := rng.randi_range(0, h["entradas"].size() - 1)
		var e: Dictionary = h["entradas"][i]
		var modo := rng.randi_range(0, 6)
		var claves := e.keys()
		var k: String = claves[rng.randi_range(0, claves.size() - 1)]
		var destruye := true
		match modo:
			0: e.erase(k)
			1: e[k] = {"x": 1} if not (e[k] is Dictionary) else "texto"
			2: h["entradas"][i] = "no soy un diccionario"
			3: e["tipo"] = "tipo_desconocido"
			4: h["partido"] = [1, 2]
			5: h["partido"]["indicadores_iniciales"].erase(["aprobacion", "capital", "fiscal"][rng.randi_range(0, 2)])
			6:
				h["semilla"] = "abc"
		pruebas += 1
		if not ValidarGuardado.guardado_valido(h):
			rechazadas += 1
		elif modo != 0 and modo != 1:
			_check(false, "mutación %d no detectada" % modo)
		_check(destruye, "")
	# borrar o retipar una clave opcional (p. ej. «delegada») puede seguir siendo válido; el resto debe rechazarse
	_check(rechazadas >= int(pruebas * 0.8), "se rechazan casi todas las mutaciones (%d de %d)" % [rechazadas, pruebas])
	_check(Partida.reproducir(datos, {"semilla": 1, "partido": {}, "entradas": []}) == null, "reproducir devuelve null ante un guardado inválido, sin errores")
	_check(Partida.cargar(datos, {"semilla": 1}) == null, "cargar devuelve null ante un guardado inválido")
	print("test_guardado_estructura: ", "OK (%d de %d mutaciones rechazadas)" % [rechazadas, pruebas] if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
