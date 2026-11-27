extends SceneTree
## Bordes de VotoRegional.calcular que el azar no alcanza: empate exacto de regiones (la mitad no es mayoría), voto nacional exactamente en el umbral (gana), cada región
## suma desplazamiento y ruido (acotado a los topes), el ruido depende de semilla, ciclo, vuelta y región, y r ≤ 0 no mueve nada.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		print("FALLO VOTO REGIONAL BORDES: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var m := AyudaV2.gobierno(datos, 52, [])
	var reg := m.regiones
	var n := reg.catalogo.size()
	# empate de regiones: la mitad exacta gana por región pero NO es mayoría
	var apr := {}
	var i := 0
	for x in reg.catalogo:
		apr[x["id"]] = 60.0 if i < n / 2 else 40.0
		i += 1
	var det := VotoRegional.calcular(reg, apr, 0.0, 0.0, 100.0, 50.0)
	_check(int(det["regiones_ganadas"]) * 2 == n, "preparación: ganadas = mitad exacta (%d de %d)" % [int(det["regiones_ganadas"]), n])
	_check(String(det["gano_por"]) in ["solo_poblacion", "ninguna"], "la mitad de las regiones no es mayoría de regiones (%s)" % det["gano_por"])
	# voto nacional exactamente en el umbral: gana por población
	var nac := float(det["voto_nacional"])
	var det2 := VotoRegional.calcular(reg, apr, 0.0, 0.0, 100.0, nac)
	_check(String(det2["gano_por"]) in ["solo_poblacion", "ambas"], "con el voto nacional exactamente en el umbral gana por población (%s)" % det2["gano_por"])
	var det3 := VotoRegional.calcular(reg, apr, 0.0, 0.0, 100.0, nac + 1e-6)
	_check(String(det3["gano_por"]) in ["solo_regiones", "ninguna"], "un poco bajo el umbral no gana por población (%s)" % det3["gano_por"])
	# cada región: aprobación + desplazamiento + ruido, acotada
	var base := {}
	for x in reg.catalogo:
		base[x["id"]] = 50.0
	var d0 := VotoRegional.calcular(reg, base, 3.0, 0.0, 100.0, 50.0, 0.0, 77, 1, 1)
	var d6 := VotoRegional.calcular(reg, base, 3.0, 0.0, 100.0, 50.0, 6.0, 77, 1, 1)
	for k in range(n):
		var f0: Dictionary = d0["regiones"][k]
		var f6: Dictionary = d6["regiones"][k]
		_check(absf(float(f0["voto"]) - 53.0) < 1e-9, "r = 0: voto = aprobación + desplazamiento (%s: %.3f)" % [f0["id"], float(f0["voto"])])
		_check(absf(float(f6["voto"]) - (53.0 + float(f6["ruido"]))) < 1e-9, "con ruido: voto = aprobación + desplazamiento + ruido (%s)" % f6["id"])
	var alto := VotoRegional.calcular(reg, base, 60.0, 0.0, 100.0, 50.0, 6.0, 77, 1, 1)
	for f in alto["regiones"]:
		_check(float(f["voto"]) <= 100.0 and float(f["voto"]) >= 0.0, "el voto respeta los topes")
	# el ruido depende de cada argumento
	var ref_r := VotoRegional.ruido(77, 1, 1, "metropolitana", 6.0)
	var distintos := 0
	for otra in [VotoRegional.ruido(78, 1, 1, "metropolitana", 6.0), VotoRegional.ruido(77, 2, 1, "metropolitana", 6.0), VotoRegional.ruido(77, 1, 2, "metropolitana", 6.0), VotoRegional.ruido(77, 1, 1, "biobio", 6.0)]:
		distintos += 1 if absf(float(otra) - ref_r) > 1e-12 else 0
	_check(distintos == 4, "el ruido cambia con semilla, ciclo, vuelta y región (%d de 4 distintos)" % distintos)
	_check(VotoRegional.ruido(77, 1, 1, "metropolitana", 0.0) == 0.0 and VotoRegional.ruido(77, 1, 1, "metropolitana", -3.0) == 0.0, "r ≤ 0 no agrega ruido")
	if _fallos == 0:
		print("test_voto_regional_bordes: OK")
	quit(1 if _fallos > 0 else 0)
