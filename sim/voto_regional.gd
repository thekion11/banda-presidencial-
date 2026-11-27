class_name VotoRegional
extends RefCounted
## Voto de una elección presidencial por región (peso = población). Solo cálculo: no toca el estado ni el RNG.
## voto_i = aprobación_i + choque nacional − penalización − efecto rival (acotado 0..100); voto nacional = Σ peso_i · voto_i.


static func calcular(regiones: Regiones, aprobacion_regional: Dictionary, desplazamiento: float, tope_min: float, tope_max: float, umbral: float, pisos: Dictionary = {}) -> Dictionary:
	## `desplazamiento` = choque nacional − penalización + efecto rival (el mismo para todas las regiones). Devuelve el voto nacional ponderado y el detalle por región.
	## `pisos` (PisoIdeologico.pisos): el voto duro de cada región; el voto nunca baja de su piso (voto_duro) y lo que lo supera es el voto blando.
	var filas: Array[Dictionary] = []
	var nacional := 0.0
	var habitantes := 0.0
	var votos := 0.0
	var ganadas := 0
	for r in regiones.catalogo:
		var id := String(r["id"])
		var peso := float(regiones.pesos[id])
		var duro := float(pisos.get(id, 0.0))
		var voto := clampf(maxf(float(aprobacion_regional.get(id, 0.0)) + desplazamiento, duro), tope_min, tope_max)
		var gana := voto >= umbral
		var hab := float(r["poblacion_miles"])
		nacional += peso * voto
		habitantes += hab
		votos += hab * voto / tope_max
		ganadas += 1 if gana else 0
		filas.append({"id": id, "habitantes_miles": hab, "peso": peso, "voto": voto, "voto_duro": minf(duro, voto), "voto_blando": voto - minf(duro, voto), "gana_gobierno": gana, "votos_estimados_miles": hab * voto / tope_max})
	var duro_nac := 0.0
	for f in filas:
		duro_nac += float(f["peso"]) * float(f["voto_duro"])
	return {"voto_nacional": clampf(nacional, tope_min, tope_max), "voto_duro_nacional": duro_nac, "voto_blando_nacional": clampf(nacional, tope_min, tope_max) - duro_nac, "regiones": filas, "total_habitantes_miles": habitantes, "regiones_ganadas": ganadas, "votos_estimados_miles": votos}
