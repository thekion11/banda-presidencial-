extends SceneTree
## Soak test de memoria del núcleo: juega N mandatos completos (campaña, gobierno de hasta 208 turnos) seguidos en un solo proceso, soltando cada partida al terminar,
## y mide la memoria residente del proceso (RSS), la memoria estática de Godot, el número de objetos y los nodos huérfanos. Una fuga (por ejemplo un ciclo de
## referencias entre objetos RefCounted que nunca se libera) hace crecer esas cifras ciclo tras ciclo. Tras un calentamiento (los primeros ciclos llenan cachés
## legítimas), exige que el crecimiento sea pequeño. Imprime una tabla por ciclo.
## Uso: godot --headless --path . -s tests/soak_memoria.gd -- [ciclos] [semilla_inicial]

const CALENTAMIENTO := 4
const TOPE_OBJETOS_POR_CICLO := 20  # objetos que pueden quedar de más por ciclo (cachés estáticas, etc.)
const TOPE_RSS_MB_TOTAL := 60.0  # crecimiento de RSS permitido entre el final del calentamiento y el último ciclo

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO SOAK: ", msg)


func _rss_mb() -> float:
	## Memoria residente del proceso (VmRSS de /proc/self/status); 0 si no está disponible (otra plataforma).
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return 0.0
	while not f.eof_reached():
		var l := f.get_line()
		if l.begins_with("VmRSS:"):
			return float(l.split(" ", false)[1]) / 1024.0
	return 0.0


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var ciclos := int(args[0]) if args.size() > 0 else 20
	var s0 := int(args[1]) if args.size() > 1 else 8000
	var datos := Datos.cargar_todo()
	var objetos: Array[int] = []
	var rss: Array[float] = []
	var turnos_total := 0
	print("ciclo | turnos | RSS (MB) | memoria estática (MB) | objetos | huérfanos")
	for c in range(ciclos):
		var m := Bots.partida_completa(datos, s0 + c, "codicioso>completo")
		turnos_total += m.estado.turno_actual
		var turnos := m.estado.turno_actual
		var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado()))
		var rep := Partida.reproducir(datos, g)  # el replay también crea y suelta un motor completo
		_check(rep != null, "el replay del ciclo %d devolvió null" % c)
		m = null
		rep = null
		g = {}
		await process_frame
		await process_frame
		var obj := int(Performance.get_monitor(Performance.OBJECT_COUNT))
		var huer := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		var r := _rss_mb()
		objetos.append(obj)
		rss.append(r)
		print("%5d | %6d | %8.1f | %21.1f | %7d | %d" % [c + 1, turnos, r, float(OS.get_static_memory_usage()) / 1048576.0, obj, huer])
		_check(huer == 0, "ciclo %d: %d nodos huérfanos" % [c + 1, huer])
	if ciclos > CALENTAMIENTO + 2:
		var crec_obj := objetos[ciclos - 1] - objetos[CALENTAMIENTO - 1]
		var ciclos_medidos := ciclos - CALENTAMIENTO
		_check(crec_obj <= TOPE_OBJETOS_POR_CICLO * ciclos_medidos, "los objetos crecieron %d en %d ciclos (tope %d por ciclo): posible fuga de referencias" % [crec_obj, ciclos_medidos, TOPE_OBJETOS_POR_CICLO])
		if rss[0] > 0.0:
			var crec_rss := rss[ciclos - 1] - rss[CALENTAMIENTO - 1]
			_check(crec_rss <= TOPE_RSS_MB_TOTAL, "el RSS creció %.1f MB en %d ciclos (tope %.0f MB): posible fuga de memoria" % [crec_rss, ciclos_medidos, TOPE_RSS_MB_TOTAL])
			print("crecimiento tras el calentamiento: %+.1f MB de RSS y %+d objetos en %d ciclos (%d turnos en total)" % [crec_rss, crec_obj, ciclos_medidos, turnos_total])
	print("SOAK MEMORIA %s (%d ciclos, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", ciclos, _fallos])
	quit(1 if _fallos > 0 else 0)
