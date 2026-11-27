class_name VotoRegional
extends RefCounted
## Voto de una elección presidencial por región (peso = población). Solo cálculo: no toca el estado ni el RNG.
## voto_i = aprobación_i + choque nacional − penalización + efecto rival + eps_i (acotado 0..100); voto nacional = Σ peso_i · voto_i.
## eps_i = ruido regional determinista en [−r, r]: se deriva (FNV) de semilla, ciclo, vuelta e id de región, NO del RNG de la partida (así el resto de la partida no se mueve); r = 0 no agrega ruido.


static func ruido(semilla: int, ciclo: int, ronda: int, id: String, r: float) -> float:
	## eps_i de una región: uniforme en [−r, r] y fijo para esa semilla, ciclo, vuelta y región.
	if r <= 0.0:
		return 0.0
	return (float(Huella.fnv32("%d:%d:%d:eleccion:%s" % [semilla, ciclo, ronda, id]) % 10001) / 10000.0 * 2.0 - 1.0) * r


static func calcular(regiones: Regiones, aprobacion_regional: Dictionary, desplazamiento: float, tope_min: float, tope_max: float, umbral: float, ruido_regional: float = 0.0, semilla: int = 0, ciclo: int = 1, ronda: int = 1, pisos: Dictionary = {}) -> Dictionary:
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
		var eps := ruido(semilla, ciclo, ronda, id, ruido_regional)
		var duro := float(pisos.get(id, 0.0))
		var voto := clampf(maxf(float(aprobacion_regional.get(id, 0.0)) + desplazamiento + eps, duro), tope_min, tope_max)  # el piso va después del ruido
		var gana := voto >= umbral
		var hab := float(r["poblacion_miles"])
		nacional += peso * voto
		habitantes += hab
		votos += hab * voto / tope_max
		ganadas += 1 if gana else 0
		filas.append({"id": id, "habitantes_miles": hab, "peso": peso, "voto": voto, "ruido": eps, "voto_duro": minf(duro, voto), "voto_blando": voto - minf(duro, voto), "gana_gobierno": gana, "votos_estimados_miles": hab * voto / tope_max})
	var duro_nac := 0.0
	for f in filas:
		duro_nac += float(f["peso"]) * float(f["voto_duro"])
	var nacional_ok := clampf(nacional, tope_min, tope_max)
	var por_regiones := ganadas * 2 > filas.size()  # mayoría de las regiones
	var por_poblacion := nacional_ok >= umbral  # mayoría ponderada por habitantes (la que decide)
	var tipo := "ambas" if por_regiones and por_poblacion else ("solo_poblacion" if por_poblacion else ("solo_regiones" if por_regiones else "ninguna"))
	return {"voto_nacional": nacional_ok, "voto_duro_nacional": duro_nac, "voto_blando_nacional": nacional_ok - duro_nac, "gano_por": tipo, "regiones": filas, "total_habitantes_miles": habitantes, "regiones_ganadas": ganadas, "votos_estimados_miles": votos}
