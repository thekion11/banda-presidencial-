class_name MotorObras
extends RefCounted
## Obras públicas: 5 fases (licitación, faena, estructura, terminación, inauguración).

const FASES: Array[String] = ["licitacion", "faena", "estructura", "terminacion", "inauguracion"]

var leyes: Dictionary = {}
var rng: RandomNumberGenerator
var regiones: Regiones


func configurar(p_leyes: Dictionary, p_rng: RandomNumberGenerator, p_regiones: Regiones) -> void:
	leyes = p_leyes
	rng = p_rng
	regiones = p_regiones


static func fase_de(obra: Dictionary) -> int:
	var total := maxf(1.0, float(obra["dias_totales"]))
	return clampi(int(5.0 * float(obra["dias_avanzados"]) / total) + 1, 1, 5)


func iniciar(estado: EstadoSimulacion, nombre: String, dias_totales: int, region: String,
		carta_id: String, efectos_final: Array, extra: Dictionary = {}) -> Dictionary:
	var obra := {
		"id": "obra_%d_%d" % [estado.turno_actual, estado.obras_en_curso.size() + estado.obras_terminadas.size()],
		"nombre": nombre,
		"carta_id": carta_id,
		"region": region,
		"dias_totales": maxi(dias_totales, estado.dias_por_turno),
		"dias_avanzados": 0,
		"fase": 1,
		"retrasos": 0,
		"efectos_final": efectos_final.duplicate(true),
	}
	obra.merge(extra, true)
	estado.obras_en_curso.append(obra)
	estado.registrar_accion("obra_iniciada", {"obra": obra["id"], "nombre": nombre, "dias": obra["dias_totales"]})
	return obra


func avanzar(estado: EstadoSimulacion, dias: int, aplicar_efecto: Callable, marcar_cumplida: Callable) -> Array[Dictionary]:
	var terminadas: Array[Dictionary] = []
	var p_retraso := clampf(estado.ind("riesgo_ejecucion") * float(leyes["obras"]["prob_retraso_por_riesgo"]), 0.0, float(leyes["obras"]["tope_prob_retraso"]))
	var restantes: Array[Dictionary] = []
	for obra in estado.obras_en_curso:
		if rng.randf() < p_retraso:
			obra["retrasos"] = int(obra["retrasos"]) + 1
		else:
			obra["dias_avanzados"] = int(obra["dias_avanzados"]) + dias
		obra["fase"] = fase_de(obra)
		if int(obra["dias_avanzados"]) >= int(obra["dias_totales"]):
			obra["fase"] = 5
			terminadas.append(obra)
			estado.obras_terminadas.append(obra)
			for ef in obra["efectos_final"]:
				aplicar_efecto.call(ef, 1.0, String(obra["region"]))
			if String(obra["carta_id"]) != "":
				marcar_cumplida.call(String(obra["carta_id"]))
			for ln in estado.lineas_jugador:  # la línea de Metro del jugador pasa a operativa al terminar su obra
				if String(obra.get("propuesta", "")) != "" and ln["prop"] == obra["propuesta"] and ln["estado"] == "en_construccion":
					ln["estado"] = "operativa"
					ln["dia_apertura"] = estado.dia_actual
			estado.registrar_accion("obra_terminada", {"obra": obra["id"], "nombre": obra["nombre"], "retrasos": obra["retrasos"]})
		else:
			restantes.append(obra)
	estado.obras_en_curso = restantes
	return terminadas
