extends SceneTree
## Una instantánea con versión, huella de datos y sha válidos pero con la estructura incompleta o mal tipada (fabricada, de otra versión del juego o
## escrita a medias) no debe romper la carga: Instantanea.leer debe descartarla ({}), y Partida.cargar debe reproducir el historial.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _bytes(d: Dictionary) -> PackedByteArray:
	var crudo := var_to_bytes(d)
	var res := PackedByteArray()
	res.resize(4)
	res.encode_u32(0, crudo.size())
	res.append_array(crudo.compress(FileAccess.COMPRESSION_ZSTD))
	return res


func _init() -> void:
	var datos := Datos.cargar_todo()
	var h := Datos.huella(datos)
	var resp: Array[Dictionary] = []
	for pr in datos["ideologia"]["preguntas"]:
		resp.append(pr["opciones"][1])
	var m := Partida.crear(datos, 8, GeneradorPartido.construir_partido("F", "FFF", "metropolitana", resp, datos["ideologia"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	for _t in range(3):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
	var ok := {"v": 1, "huella_datos": h, "sha_guardado": "sha", "estado": {"semilla": 1}, "rng_seed": 1, "rng_state": 1, "ultimos_eventos": [], "votaciones": []}
	var casos := {
		"sin_estado": ok.duplicate(),
		"sin_rng": ok.duplicate(),
		"estado_no_dict": ok.duplicate(),
		"estado_vacio": ok.duplicate(),
		"eventos_no_lista": ok.duplicate(),
	}
	casos["sin_estado"].erase("estado")
	casos["sin_rng"].erase("rng_seed")
	casos["estado_no_dict"]["estado"] = 5
	casos["estado_vacio"]["estado"] = {}
	casos["eventos_no_lista"]["ultimos_eventos"] = "x"
	var esperado := Partida.reproducir(datos, g).estado.calcular_huella()
	for k in casos:
		var d := Instantanea.leer(_bytes(casos[k]))
		_check(d.is_empty() or not Instantanea.vale_para(d, h, "sha"), "%s: una instantánea incompleta debe descartarse" % k)
		if d.is_empty() or not Instantanea.vale_para(d, h, "sha"):
			_check(Partida.cargar(datos, g, d, h, "sha").estado.calcular_huella() == esperado, "%s: cargar debe reproducir el historial" % k)
	print("test_instantanea_fabricada: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
