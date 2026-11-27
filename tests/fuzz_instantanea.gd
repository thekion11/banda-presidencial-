extends SceneTree
## Fuzz de mutación de la instantánea: a una instantánea válida se le borra una clave o se le cambia el tipo de un valor (en el nivel superior o en
## `estado`). Una instantánea dañada así NO debe aceptarse (Instantanea.vale_para debe dar false): si se acepta, Partida.cargar restauraría un estado
## parcial o mal tipado sin avisar. Muestra cuántas mutaciones se aceptaron indebidamente y las primeras.
## Uso: godot --headless --path . -s tests/fuzz_instantanea.gd -- [mutaciones_por_partida] [semilla]

var _fallos := 0
var _datos: Dictionary
var _huella: String


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		print("FALLO FUZZ INSTANTANEA: ", msg)


static func _numerico(t: int) -> bool:
	return t == TYPE_INT or t == TYPE_FLOAT


static func _otro_tipo(v: Variant, rng: RandomNumberGenerator) -> Variant:
	var cand: Array = ["texto", 7, [], {}, 3.5, true, null]
	cand = cand.filter(func(x: Variant) -> bool: return typeof(x) != typeof(v) and not (_numerico(typeof(x)) and _numerico(typeof(v))))
	return cand[rng.randi_range(0, cand.size() - 1)]


static func _bytes(d: Dictionary) -> PackedByteArray:
	## Mismo formato que Instantanea.tomar: así cada mutación pasa por Instantanea.leer, como un archivo real.
	var crudo := var_to_bytes(d)
	var res := PackedByteArray()
	res.resize(4)
	res.encode_u32(0, crudo.size())
	res.append_array(crudo.compress(FileAccess.COMPRESSION_ZSTD))
	return res


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 200
	var semilla := int(args[1]) if args.size() > 1 else 31
	_datos = Datos.cargar_todo()
	_huella = Datos.huella(_datos)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var resp: Array[Dictionary] = []
	for p in _datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var campana := Partida.crear(_datos, semilla, GeneradorPartido.construir_partido("I", "III", "metropolitana", resp, _datos["ideologia"]))
	for _t in range(3):
		Bots.jugar_turno(campana, "codicioso", rng)
		campana.terminar_turno()
	var gob := Partida.crear(_datos, semilla + 1, GeneradorPartido.construir_partido("I", "III", "metropolitana", resp, _datos["ideologia"]))
	gob.estado.partido["indicadores_iniciales"]["aprobacion"] = 90.0
	for _t in range(8):
		Bots.jugar_turno(gob, "codicioso", rng)
		gob.terminar_turno()
	Bots.elegir(gob, _datos, "codicioso", rng)
	for _t in range(30):
		if gob.estado.etapa != "gobierno":
			break
		Bots.jugar_turno(gob, "codicioso", rng)
		gob.terminar_turno()
	var casos := {"campaña": campana, "gobierno (%s)" % gob.estado.etapa: gob}
	var aceptadas := 0
	var total := 0
	var ejemplos: Array[String] = []
	var por_tipo := {"borrar_estado": 0, "retipar_estado": 0, "borrar_superior": 0, "retipar_superior": 0}
	for nombre in casos:
		var m: MotorTurno = casos[nombre]
		var base := Instantanea.leer(Instantanea.tomar(m, _huella, "sha"))
		var ref: Dictionary = Instantanea.leer(Instantanea.tomar(Partida.armar(_datos, int(m.estado.semilla)), _huella, "sha"))["estado"]
		_check(Instantanea.vale_para(base, _huella, "sha"), nombre + ": la instantánea sin mutar debe valer")
		for _i in range(n):
			var d: Dictionary = base.duplicate(true)
			var destino: Dictionary = d if rng.randf() < 0.35 else d["estado"]
			var claves: Array = destino.keys()
			var k: Variant = claves[rng.randi_range(0, claves.size() - 1)]
			var dañada := false
			var que := ""
			if rng.randf() < 0.5:
				destino.erase(k)
				dañada = true
				que = "borrar %s" % k
			else:
				var nuevo: Variant = _otro_tipo(destino[k], rng)
				# el tipo de referencia es el del estado inicial (los vacíos de un tipo siguen siendo de ese tipo)
				var tipo_ref: int = typeof(destino[k])
				if destino == d["estado"] and ref.has(k):
					tipo_ref = typeof(ref[k])
				destino[k] = nuevo
				dañada = typeof(nuevo) != tipo_ref and not (_numerico(typeof(nuevo)) and _numerico(tipo_ref))
				que = "cambiar %s a %s" % [k, type_string(typeof(nuevo))]
			if not dañada:
				continue
			total += 1
			if Instantanea.vale_para(Instantanea.leer(_bytes(d)), _huella, "sha"):
				aceptadas += 1
				por_tipo[("borrar_" if que.begins_with("borrar") else "retipar_") + ("estado" if destino == d["estado"] else "superior")] += 1
				var etiqueta := "%s: %s%s" % [nombre, "estado." if destino == d["estado"] else "", que]
				if ejemplos.size() < 14 and not ejemplos.has(etiqueta):
					ejemplos.append(etiqueta)
	print("ACEPTADAS POR TIPO: ", por_tipo)
	for e in ejemplos:
		print("ACEPTADA INDEBIDAMENTE: ", e)
	_check(aceptadas == 0, "%d de %d instantáneas dañadas (clave borrada o tipo cambiado) se aceptaron como válidas" % [aceptadas, total])
	print("FUZZ INSTANTANEA %s (%d mutaciones dañadas, %d aceptadas indebidamente)" % ["OK" if _fallos == 0 else "CON FALLOS", total, aceptadas])
	quit(1 if _fallos > 0 else 0)
