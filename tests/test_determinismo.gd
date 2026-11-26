extends SceneTree
## Determinismo: la misma semilla y las mismas entradas dan la misma huella, en partidas completas de carrera (campaña, gobierno, oposición y reelección), y el orden
## en que se cargan los datos no cambia el resultado. Para comparar con un teléfono, el informe imprime las huellas de 4 semillas: en el dispositivo (misma versión de los
## datos) deben ser idénticas. El motor evita las operaciones que difieren entre plataformas: no usa seno, coseno, potencias ni exponenciales (solo raíz cuadrada, que es exacta
## en IEEE 754), cada operación de GDScript se evalúa por separado (sin multiplicar-y-sumar fusionado) y el azar es el generador PCG de Godot, igual en todas partes.

const RUTA_ORO := "res://tests/oro/huellas.json"
var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _jugar(datos: Dictionary, semilla: int) -> String:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][semilla % 3])
	var m := Partida.crear(datos, semilla, GeneradorPartido.construir_partido("D", "DDD", "metropolitana", resp, datos["ideologia"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var tope := 900
	while tope > 0 and m.estado.ciclo <= 3 and MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):
		tope -= 1
		if m.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			var r := m.resolver_eleccion_presidencial()
			if bool(r["electo"]) or bool(r["balotaje"]):
				m.iniciar_turno()
			continue
		Bots.jugar_turno(m, "completo", rng)
		for ev in m.ultimos_eventos:
			if ev.has("opciones"):
				m.eventos.decidir(String(ev["id"]), tope % 3)
		m.terminar_turno()
		if not MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa) and m.estado.etapa != "campana":
			if bool(m.continuar_carrera().get("ok", false)):
				m.iniciar_turno()
	return m.estado.calcular_huella()


func _init() -> void:
	var datos := Datos.cargar_todo()
	var datos2 := Datos.cargar_todo()  # segunda carga: mismos archivos, nuevos objetos
	var regenerar := OS.get_cmdline_user_args().has("--regenerar")
	var oro: Dictionary = Datos.leer_json(RUTA_ORO) if FileAccess.file_exists(RUTA_ORO) else {}
	var nuevo := {}
	for sd in [11, 12, 13, 14]:
		var a := _jugar(datos, sd)
		var b := _jugar(datos2, sd)
		_check(a == b, "semilla %d: dos ejecuciones dan huellas distintas" % sd)
		print("HUELLA semilla %d: %s" % [sd, a.substr(0, 16)])
		nuevo[str(sd)] = a
		if not regenerar:
			_check(String(oro.get(str(sd), "")) == a, "semilla %d: la huella de una carrera completa cambió (oro %s, ahora %s). Si el cambio de simulación o de datos es intencional, regenera con: godot --headless --path . -s tests/test_determinismo.gd -- --regenerar y deja el motivo en el commit; si no, es una regresión (o una diferencia entre plataformas)" % [sd, String(oro.get(str(sd), "—")).substr(0, 16), a.substr(0, 16)])
	if regenerar:
		var f := FileAccess.open(RUTA_ORO, FileAccess.WRITE)
		f.store_string(JSON.stringify(nuevo, "\t", true) + "\n")
		f.close()
		print("Oro regenerado en ", RUTA_ORO)
	# el orden de las claves de un diccionario no debe cambiar la huella
	var x := {"a": 1.5, "b": [1, 2, {"z": 0.25, "y": -0.0}], "c": "texto"}
	var y := {"c": "texto", "b": [1, 2, {"y": 0.0, "z": 0.25}], "a": 1.5}
	_check(Huella.sha(x) == Huella.sha(y), "la huella no depende del orden de las claves ni del signo del cero")
	_check(Huella.sha({"n": 1}) == Huella.sha({"n": 1.0}), "la huella trata igual 1 y 1.0 (tras un ciclo JSON los enteros vuelven como decimales)")
	print("test_determinismo: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
