extends SceneTree
## Imprime la huella de estado de partidas completas para una lista de semillas y políticas (una línea «HUELLA semilla política dificultad hash» por partida).
## Lo usa tools/determinismo_procesos.py: varios procesos de Godot en paralelo, con el mismo y con distinto HOME y directorio de trabajo, deben imprimir
## exactamente las mismas líneas (determinismo entre procesos, no solo dentro de uno).
## Uso: godot --headless --path . -s tests/huella_semillas.gd -- [semillas] [semilla_inicial]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 6
	var s0 := int(args[1]) if args.size() > 1 else 100
	var datos := Datos.cargar_todo()
	print("DATOS huella=", Datos.huella(datos))
	for i in range(n):
		for pol in ["codicioso>completo", "azar", "codicioso>azar"]:
			for dif in ["facil", "normal", "dificil"]:
				var m := Bots.partida_completa(datos, s0 + i, pol, dif)
				print("HUELLA %d %s %s %s etapa=%s turno=%d" % [s0 + i, pol, dif, m.estado.calcular_huella(), m.estado.etapa, m.estado.turno_actual])
	quit()
