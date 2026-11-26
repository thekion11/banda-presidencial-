extends SceneTree
## El calendario real de data/leyes.json cuadra con las semanas del juego: 21-sep-2025 + 8 semanas = 1ª vuelta (16-nov), + 4 semanas = 2ª vuelta (14-dic), mandato el 11-mar-2026.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _dia(iso: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(iso + "T00:00:00") / 86400)


func _init() -> void:
	var l: Dictionary = Datos.cargar_todo()["leyes"]
	var cal: Dictionary = l["calendario"]
	var h: Dictionary = l["hemiciclo"]
	var dpt := int(h["dias_por_turno"])
	_check(String(cal["fecha_inicio_campana"]) == "2025-09-21", "la campaña parte el 21-sep-2025")
	_check(String(cal["fecha_primera_vuelta"]) == "2025-11-16" and String(cal["fecha_segunda_vuelta"]) == "2025-12-14" and String(cal["fecha_inicio_mandato"]) == "2026-03-11", "fechas de 1ª vuelta, 2ª vuelta y mandato")
	_check(_dia(cal["fecha_inicio_campana"]) + int(h["semanas_campana"]) * dpt == _dia(cal["fecha_primera_vuelta"]), "las semanas de campaña terminan en la 1ª vuelta")
	_check(_dia(cal["fecha_primera_vuelta"]) + int(h["semanas_balotaje"]) * dpt == _dia(cal["fecha_segunda_vuelta"]), "las semanas de balotaje terminan en la 2ª vuelta")
	_check(_dia(cal["fecha_inicio_mandato"]) > _dia(cal["fecha_segunda_vuelta"]), "el mandato empieza después de la 2ª vuelta")
	_check(Time.get_date_dict_from_unix_time(_dia(cal["fecha_primera_vuelta"]) * 86400)["weekday"] == 0, "la 1ª vuelta cae domingo")
	_check(Time.get_date_dict_from_unix_time(_dia(cal["fecha_segunda_vuelta"]) * 86400)["weekday"] == 0, "la 2ª vuelta cae domingo")
	print("test_calendario_fechas: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
