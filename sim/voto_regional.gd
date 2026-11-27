class_name VotoRegional
extends RefCounted
## Voto de una elección presidencial por región (peso = población). Solo cálculo: no toca el estado ni el RNG.
## voto_i = aprobación_i + choque nacional − penalización − efecto rival (acotado 0..100); voto nacional = Σ peso_i · voto_i.


static func calcular(regiones: Regiones, aprobacion_regional: Dictionary, desplazamiento: float, tope_min: float, tope_max: float, umbral: float) -> Dictionary:
	## `desplazamiento` = choque nacional − penalización + efecto rival (el mismo para todas las regiones). Devuelve el voto nacional ponderado y el detalle por región.
	var filas: Array[Dictionary] = []
	var nacional := 0.0
	var habitantes := 0.0
	var votos := 0.0
	var ganadas := 0
	for r in regiones.catalogo:
		var id := String(r["id"])
		var peso := float(regiones.pesos[id])
		var voto := clampf(float(aprobacion_regional.get(id, 0.0)) + desplazamiento, tope_min, tope_max)
		var gana := voto >= umbral
		var hab := float(r["poblacion_miles"])
		nacional += peso * voto
		habitantes += hab
		votos += hab * voto / tope_max
		ganadas += 1 if gana else 0
		filas.append({"id": id, "habitantes_miles": hab, "peso": peso, "voto": voto, "gana_gobierno": gana, "votos_estimados_miles": hab * voto / tope_max})
	return {"voto_nacional": clampf(nacional, tope_min, tope_max), "regiones": filas, "total_habitantes_miles": habitantes, "regiones_ganadas": ganadas, "votos_estimados_miles": votos}
