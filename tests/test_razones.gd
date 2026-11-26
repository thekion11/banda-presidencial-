extends SceneTree
## Corrector de realismo (CLAUDE.md §4.6): ningún rechazo del motor llega al jugador como un «no» seco. Toda `razon` que devuelve sim/ tiene texto propio en
## game/componentes/razones.gd, y los que el jugador puede provocar dicen qué hacer después.

const SIN_PISTA := ["sin_efecto", "asesor_inexistente", "meta_inexistente", "region_invalida", "indice_invalido", "direccion_invalida", "opcion_invalida", "evento_sin_decision", "tipo_desconocido", "tipo_invalido", "partido_inexistente", "ministro_invalido", "partida_terminada", "ya_decidido", "ya_asignado", "ya_aliado", "ya_contratado", "no_aliado", "no_asignado", "no_contratado", "fuera_del_gabinete", "ministro_fuera_del_gabinete", "asesor_no_contratado", "ya_ejecutada", "meta_cumplida", "partido_propio"]  # estados o datos inválidos: informan, no hay otra salida
const PISTAS := ["une ", "termina", "espera", "elige", "usa", "vuelve", "revisa", "despide", "deja", "delega", "se renuevan", "se renueva", "antes", "primero", "necesitas", "solo ", "máximo", "intenta", "más adelante", "próxima"]

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var razones := {}
	var dir := DirAccess.open("res://sim")
	for f in dir.get_files():
		if not f.ends_with(".gd"):
			continue
		var txt := FileAccess.get_file_as_string("res://sim/" + f)
		var rx := RegEx.new()
		rx.compile("\"razon\":\\s*\"([a-z_]+)\"")
		for m in rx.search_all(txt):
			razones[m.get_string(1)] = f
	_check(razones.size() >= 30, "se encontraron las razones del motor (%d)" % razones.size())
	var sin_texto: Array[String] = []
	var secos: Array[String] = []
	for r in razones.keys():
		if not Razones.TEXTOS.has(r):
			sin_texto.append(r)
			continue
		var t := String(Razones.TEXTOS[r]).to_lower()
		if not SIN_PISTA.has(r) and not PISTAS.any(func(p: String) -> bool: return t.contains(p)):
			secos.append(r)
	_check(sin_texto.is_empty(), "razones sin texto propio (caen en «No se pudo realizar la acción»): %s" % str(sin_texto))
	_check(secos.is_empty(), "razones alcanzables sin indicación de qué hacer: %s" % str(secos))
	print("test_razones: %d razones del motor" % razones.size())
	print("test_razones: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
