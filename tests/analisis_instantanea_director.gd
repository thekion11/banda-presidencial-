extends SceneTree
## La instantánea (caché de carga) debe dejar el director de eventos exactamente como lo dejó jugar en vivo: la memoria incremental (_ult_fam, _ult_dec, _dec_sem, _ultima,
## _n_visto) que Instantanea.restaurar rehace con DirectorEventos.reconstruir tiene que coincidir con la acumulada por registrar() durante la partida, y un motor recargado
## por instantánea debe seguir igual que el vivo semana tras semana (mismo resultado que reproducir el historial). Falla si, por ejemplo, las semanas de la campaña
## (hasta la 8) pisan a las del gobierno (que vuelve a empezar en 1) al reconstruir con «el máximo» en vez de «lo último registrado».
## Uso: godot --headless --path . -s tests/analisis_instantanea_director.gd -- [semillas=12] [semana0=500]

var _fallos := 0
var _vistos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 400:
			print("FALLO: ", msg)


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var n := int(a[0]) if a.size() > 0 else 12
	var s0 := int(a[1]) if a.size() > 1 else 500
	var d := Datos.cargar_todo()
	var h := Datos.huella(d)
	for i in range(n):
		var semilla := s0 + i
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var resp: Array[Dictionary] = []
		for p in d["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rng.randi_range(0, 2)])
		var vivo := Partida.crear(d, semilla, GeneradorPartido.construir_partido("DI", "DIR", "metropolitana", resp, d["ideologia"]))
		for _s in range(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(vivo, "codicioso", rng)
			vivo.terminar_turno()
		if not Bots.elegir(vivo, d, "codicioso", rng):
			continue
		for w in range(24):
			Bots.jugar_turno(vivo, "codicioso", rng)
			vivo.terminar_turno()
			if vivo.estado.etapa != "gobierno":
				break
			var snap := Instantanea.leer(Instantanea.tomar(vivo, h, "sha"))
			var nuevo := Instantanea.restaurar(d, semilla, snap)
			_vistos += 1
			var ctx := "semilla %d semana %d de gobierno" % [semilla, w + 1]
			for campo in ["_ult_fam", "_ult_dec", "_dec_sem", "_ultima", "_n_visto"]:
				_check(str(vivo.eventos.director.get(campo)) == str(nuevo.eventos.director.get(campo)), "%s: el director difiere en %s (vivo %s, restaurado %s)" % [ctx, campo, str(vivo.eventos.director.get(campo)), str(nuevo.eventos.director.get(campo))])
			if w == 0:  # consecuencia: el recargado y el vivo reciben lo mismo y deben dar lo mismo
				for k in range(16):
					var sem := rng.randi()
					var r1 := RandomNumberGenerator.new()
					r1.seed = sem
					var r2 := RandomNumberGenerator.new()
					r2.seed = sem
					Bots.jugar_turno(vivo, "codicioso", r1)
					vivo.terminar_turno()
					Bots.jugar_turno(nuevo, "codicioso", r2)
					nuevo.terminar_turno()
					_check(vivo.estado.calcular_huella() == nuevo.estado.calcular_huella(), "%s: el motor recargado por instantánea divergió del vivo %d semanas después (eventos distintos)" % [ctx, k + 1])
					if vivo.estado.calcular_huella() != nuevo.estado.calcular_huella():
						break
				break
	print("analisis_instantanea_director: %s (%d instantáneas revisadas)" % ["OK" if _fallos == 0 else "CON FALLOS", _vistos])
	quit(1 if _fallos > 0 else 0)
