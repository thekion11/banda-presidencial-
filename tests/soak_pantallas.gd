extends SceneTree
## Soak de pantallas: recorre N veces todas las pantallas y paneles de la interfaz (RecorridoUI: menú, créditos, ajustes, afiliación, test, gabinete, día,
## paneles del Comité, Congreso y Nación, eventos, votación, elección y fin de partida), libera cada Main al terminar y mide memoria residente (RSS), objetos
## vivos, recursos y nodos huérfanos. Una fuga (señales conectadas a objetos que no se liberan, nodos sin padre, ciclos de referencias) hace crecer esas cifras
## vuelta tras vuelta. Tras un calentamiento exige que el crecimiento sea pequeño. Respalda y restaura los archivos de usuario.
## Uso: godot --headless --path . -s tests/soak_pantallas.gd -- [vueltas]

const ARCHIVOS := ["guardado.json", "guardado.cache", "ultima_config.json", "guardado_descartado.json"]
const CALENTAMIENTO := 5
const TOPE_OBJETOS_POR_VUELTA := 30
const TOPE_RSS_MB_TOTAL := 80.0

var _fallos: int = 0
var _main: Node = null


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO SOAK PANTALLAS: ", msg)


func _rss_mb() -> float:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return 0.0
	while not f.eof_reached():
		var l := f.get_line()
		if l.begins_with("VmRSS:"):
			return float(l.split(" ", false)[1]) / 1024.0
	return 0.0


func _visitar(main: Node, _nombre: String) -> void:
	_main = main  # RecorridoUI no libera el Main que crea: se guarda para liberarlo al terminar la vuelta


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var vueltas := int(args[0]) if args.size() > 0 else 40
	for a in ARCHIVOS:
		if FileAccess.file_exists("user://" + a):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a), ProjectSettings.globalize_path("user://" + a + ".bak_soak"))
	var objetos: Array[int] = []
	var recursos: Array[int] = []
	var rss: Array[float] = []
	var nodos: Array[int] = []
	print("vuelta | RSS (MB) | objetos | recursos | nodos | huérfanos")
	for v in range(vueltas):
		await RecorridoUI.recorrer(self, _visitar)
		if _main != null and is_instance_valid(_main):
			_main.queue_free()
			_main = null
		for _k in range(3):
			await process_frame
		var obj := int(Performance.get_monitor(Performance.OBJECT_COUNT))
		var res := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
		var nod := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var huer := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		var r := _rss_mb()
		objetos.append(obj)
		recursos.append(res)
		nodos.append(nod)
		rss.append(r)
		if v < 4 or v % 5 == 4 or v == vueltas - 1:
			print("%6d | %8.1f | %7d | %8d | %5d | %d" % [v + 1, r, obj, res, nod, huer])
	if vueltas > CALENTAMIENTO + 3:
		var medidas := vueltas - CALENTAMIENTO
		var c_obj := objetos[vueltas - 1] - objetos[CALENTAMIENTO - 1]
		var c_nod := nodos[vueltas - 1] - nodos[CALENTAMIENTO - 1]
		var c_res := recursos[vueltas - 1] - recursos[CALENTAMIENTO - 1]
		var c_rss := rss[vueltas - 1] - rss[CALENTAMIENTO - 1]
		print("crecimiento tras el calentamiento (%d vueltas): %+d objetos, %+d nodos, %+d recursos, %+.1f MB de RSS" % [medidas, c_obj, c_nod, c_res, c_rss])
		_check(c_obj <= TOPE_OBJETOS_POR_VUELTA * medidas, "los objetos crecieron %d en %d vueltas (tope %d por vuelta)" % [c_obj, medidas, TOPE_OBJETOS_POR_VUELTA])
		_check(c_nod <= 5 * medidas, "los nodos crecieron %d en %d vueltas: pantallas que no se liberan" % [c_nod, medidas])
		if rss[0] > 0.0:
			_check(c_rss <= TOPE_RSS_MB_TOTAL, "el RSS creció %.1f MB en %d vueltas (tope %.0f MB)" % [c_rss, medidas, TOPE_RSS_MB_TOTAL])
	for a in ARCHIVOS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + a))
		if FileAccess.file_exists("user://" + a + ".bak_soak"):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a + ".bak_soak"), ProjectSettings.globalize_path("user://" + a))
	Movimiento.forzado = -1
	print("SOAK PANTALLAS %s (%d vueltas, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", vueltas, _fallos])
	quit(1 if _fallos > 0 else 0)
