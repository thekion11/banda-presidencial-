class_name LunaDeMiel
extends RefCounted
## Luna de miel (D-BN): al empezar cada gobierno hay un impulso que se desvanece en `semanas` semanas (data/leyes.json › luna_de_miel).
## Funciones puras sobre el estado: la semana de gobierno es `turno_actual` (vuelve a 1 al ganar cada elección), así que no hay estado nuevo ni cambia el guardado.


static func _cfg(leyes: Dictionary) -> Dictionary:
	return leyes["luna_de_miel"]


static func semana(estado: EstadoSimulacion) -> int:
	## Semana de gobierno (1 = primera); 0 si no se está gobernando.
	return estado.turno_actual if estado.etapa == "gobierno" else 0


static func intensidad(estado: EstadoSimulacion, leyes: Dictionary) -> float:
	## 1,0 en la primera semana, decae hasta 1/semanas en la última y vale 0 después; escalada por la dificultad.
	var s := semana(estado)
	if s < 1 or not leyes.has("luna_de_miel"):
		return 0.0
	var c := _cfg(leyes)
	var n := int(c["semanas"])
	if s > n:
		return 0.0
	var nivel := String(estado.partido.get("dificultad", leyes["dificultad"]["defecto"]))
	var mult := float(c["mult_dificultad"].get(nivel, 1.0))
	return pow(float(n - (s - 1)) / float(n), float(c["exponente"])) * mult


static func valor(leyes: Dictionary, intens: float, clave: String) -> float:
	## Efecto de la clave (bono_ancla, bono_apoyo…) a la intensidad dada.
	return float(_cfg(leyes)[clave]) * intens


static func ajustes(leyes: Dictionary, intens: float) -> Dictionary:
	## Ajustes del amanecer a esa intensidad: {ancla: puntos a sumar al ancla de aprobación, desgaste: factor del desgaste semanal}.
	return {"ancla": valor(leyes, intens, "bono_ancla"), "desgaste": 1.0 - valor(leyes, intens, "reduccion_desgaste")}


static func efecto_aprobacion(leyes: Dictionary, intens: float, actual: float, ancla: float, reversion: float, desgaste: float) -> float:
	## Cuántos puntos de aprobación nacional suma la luna de miel en este amanecer (aproximación para explicarlo en los motivos de la semana; no se aplica).
	var aj := ajustes(leyes, intens)
	var con := (ancla + float(aj["ancla"]) - actual) * reversion - desgaste * float(aj["desgaste"])
	return con - ((ancla - actual) * reversion - desgaste)


static func vista(estado: EstadoSimulacion, leyes: Dictionary) -> Dictionary:
	## Solo lectura para la interfaz: {activa, semana, semanas_restantes, intensidad, termina_ahora}. termina_ahora = es la primera semana sin luna de miel («Se acabó la luna de miel»).
	var s := semana(estado)
	var n := int(_cfg(leyes)["semanas"])
	var activa := s >= 1 and s <= n
	return {"activa": activa, "semana": s, "semanas_restantes": (n - s + 1) if activa else 0, "intensidad": intensidad(estado, leyes), "termina_ahora": s == n + 1}


static func amanecer(estado: EstadoSimulacion, leyes: Dictionary) -> void:
	## Deja constancia en el registro de acciones del inicio y del fin de la luna de miel (solo gobierno).
	var s := semana(estado)
	if s == 1:
		estado.registrar_accion("luna_de_miel_inicio", {"semanas": int(_cfg(leyes)["semanas"])})
	elif s == int(_cfg(leyes)["semanas"]) + 1:
		estado.registrar_accion("luna_de_miel_fin", {})
