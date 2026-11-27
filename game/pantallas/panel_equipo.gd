class_name PanelEquipo
extends RefCounted
## Asesores (DISENO_V2 §9): hasta 3. Cada uno da +1 movimiento desde el siguiente amanecer, un efecto positivo y uno negativo.

const IND := {"aprobacion": "Aprobación", "capital": "Capital político", "cohesion": "Cohesión", "fiscal": "Caja fiscal", "riesgo_ejecucion": "Riesgo de ejecución"}


static func _num(v: float) -> String:
	return ("%+.2f" % v).replace(".", ",").replace("-", "−")


static func texto_efecto(ef: Dictionary, factor: float = 1.0) -> String:
	if String(ef["tipo"]) == "categoria":
		var pct := roundi(float(ef["mult"]) * 100.0 * factor)
		return "%s %d %% en cartas de %s" % ["+" if pct >= 0 else "−", absi(pct), BloqueoCarta.nombre_cat(String(ef["categoria"]))]
	return "%s %s por turno" % [IND.get(String(ef["ind"]), String(ef["ind"])), _num(float(ef["delta"]) * factor)]


static func crear(motor: MotorTurno, avisar: Callable, cambio: Callable) -> Control:
	var est := motor.estado
	var cfg: Dictionary = motor.catalogo_leyes["asesores"]
	var col := FilasUI.col(8)
	col.add_child(Tema.etiqueta("ASESORES · %d DE %d" % [est.asesores.size(), int(cfg["max"])], 10, Tema.ORO, true))
	var aporte := est.asesores.size() * int(cfg["movimientos_extra"])
	col.add_child(Tema.etiqueta("Cada asesor suma +%d movimiento por turno, desde el siguiente amanecer. Vigente hoy: +%d. Con tu equipo actual: +%d." % [
			int(cfg["movimientos_extra"]), int(est.bono_mov.get("asesores", 0)), aporte], 12, Tema.TEXTO_SUAVE))
	for id in motor.equipo.asesores.keys():
		var a: Dictionary = motor.equipo.asesores[id]
		var contratado := est.asesores.has(id)
		var afin := motor.equipo.afinidad(id)
		var atenuacion := 1.0 - float(cfg["mitigacion_afin"]) * afin
		var v := FilasUI.col(3)
		v.add_child(Tema.etiqueta(String(a["nombre"]) + (" · CONTRATADO" if contratado else ""), 13, Tema.ORO if contratado else Tema.TEXTO, true))
		v.add_child(Tema.etiqueta(String(a["perfil"]), 11, Tema.TEXTO_SUAVE))
		v.add_child(Tema.etiqueta("A favor: " + texto_efecto(a["efecto_positivo"]), 11, Tema.bien(), false, 600))
		v.add_child(Tema.etiqueta("En contra: " + texto_efecto(a["efecto_negativo"], atenuacion), 11, FilasUI.ROJO_TEXTO, false, 600))
		v.add_child(Tema.etiqueta("Afinidad con tu partido: %d %% (atenúa lo negativo)" % roundi(afin * 100.0), 11, Tema.TEXTO_SUAVE))
		var b := Tema.boton("Despedir" if contratado else "Contratar · +%d por semana" % int(cfg["movimientos_extra"]), Tema.PANEL.lightened(0.12) if contratado else Tema.ROJO, Tema.TEXTO, 13, 44)
		b.pressed.connect(func() -> void:
			var r := motor.despedir_asesor(id) if contratado else motor.contratar_asesor(id)
			avisar.call(("Asesor despedido." if contratado else "Asesor contratado: +1 movimiento desde el próximo turno.") if bool(r["ok"]) else Razones.texto(r))
			cambio.call())
		v.add_child(b)
		col.add_child(FilasUI.tarjeta(v, Tema.PANEL, Tema.ORO if contratado else Color(0, 0, 0, 0)))
	return FilasUI.scroll(col)
