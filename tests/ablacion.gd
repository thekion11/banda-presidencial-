extends SceneTree
## Ablación de las mecánicas v2: cada variante desactiva UNA mecánica (solo con parámetros de data/leyes.json) en la política «completo».
## Uso: godot --headless --path . -s tests/ablacion.gd -- [partidas=100] [variante] [{"seccion.clave": valor} sobrescrituras extra en JSON]
## Salida: tabla Markdown (la copia docs/INFORME_BALANCE.md).

const VARIANTES := {
	"completo": {},
	"sin_asesores": {"asesores.max": 0},
	"sin_coalicion": {"coalicion.max_aliados": 0},
	"sin_delegacion": {"delegacion.max_por_turno": 0},
	"sin_internos": {"movimientos_internos.por_turno": 0},
	"sin_bono_aprobacion": {"bono_movimientos.tramos": []},
	"sin_mano_continua": {"mano.continua": false},
	"sin_nada_v2": {"asesores.max": 0, "coalicion.max_aliados": 0, "delegacion.max_por_turno": 0, "movimientos_internos.por_turno": 0, "bono_movimientos.tramos": [], "mano.continua": false},
}


static func aplicar(datos: Dictionary, cambios: Dictionary) -> Dictionary:
	var d := datos.duplicate(false)
	d["leyes"] = datos["leyes"].duplicate(true)
	for ruta in cambios.keys():
		var partes: PackedStringArray = String(ruta).split(".")
		d["leyes"][partes[0]][partes[1]] = cambios[ruta]
	return d


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 100
	var datos := Datos.cargar_todo()
	var nombres: Array = [args[1]] if args.size() > 1 else VARIANTES.keys()
	print("| variante | n | gana elección | cae en crisis | completa mandato | aprobación final | puntaje medio | puntaje mediano |")
	print("|---|---|---|---|---|---|---|---|")
	for nombre in nombres:
		var cambios: Dictionary = VARIANTES[nombre].duplicate()
		if args.size() > 2:
			cambios.merge(JSON.parse_string(args[2]), true)
		var d := aplicar(datos, cambios)
		var electos := 0
		var crisis := 0
		var completos := 0
		var ap := 0.0
		var pts: Array[int] = []
		for i in range(n):
			var e := Bots.partida_completa(d, 1000 + i, "completo").estado
			if e.etapa == "derrota_electoral":
				continue
			electos += 1
			ap += e.ind("aprobacion")
			crisis += 1 if e.etapa == "crisis" else 0
			completos += 1 if e.etapa == "fin_mandato" else 0
			pts.append(int(e.resultado_final.get("puntaje", 0)))
		pts.sort()
		var media := 0.0
		for p in pts:
			media += float(p)
		media /= maxf(1.0, float(pts.size()))
		print("| %s | %d | %.1f %% | %.1f %% | %.1f %% | %.1f | %d | %d |" % [nombre, n, 100.0 * electos / n, 100.0 * crisis / maxf(1.0, float(electos)), 100.0 * completos / n,
				ap / maxf(1.0, float(electos)), roundi(media), pts[pts.size() / 2] if not pts.is_empty() else 0])
	quit(0)
