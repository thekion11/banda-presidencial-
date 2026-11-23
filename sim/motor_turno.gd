class_name MotorTurno
extends RefCounted
## Ciclo fijo de 8 pasos por turno semanal. Determinista: misma semilla + mismas entradas = mismo resultado.

var estado: EstadoSimulacion
var rng: RandomNumberGenerator
var catalogo_cartas: Array[Dictionary] = []
var catalogo_eventos: Array[Dictionary] = []
var catalogo_leyes: Dictionary = {}
var catalogo_ministros: Dictionary = {}
var catalogo_propuestas: Dictionary = {}
var legal := MotorLegal.new()
var regiones := Regiones.new()
var obras := MotorObras.new()
var mandato := MotorMandato.new(self)
var fx := MotorEfectos.new()
var grafo := GrafoTrazado.new()
var cartas := MotorCartas.new(self)
var eventos := MotorEventos.new(self)
var ultimos_eventos: Array[Dictionary] = []
var votaciones_semana: Array[Dictionary] = []  # votaciones de leyes resueltas al cerrar el turno (para la UI)
var _cartas_por_id: Dictionary = {}


func inicializar(p_estado: EstadoSimulacion, p_cartas: Array, p_eventos: Array, p_leyes: Dictionary,
		p_ministros: Array, p_extra: Dictionary = {}) -> void:
	estado = p_estado
	rng = RandomNumberGenerator.new()
	rng.seed = estado.semilla
	catalogo_cartas.assign(p_cartas)
	catalogo_eventos.assign(p_eventos)
	catalogo_leyes = p_leyes.duplicate(true)
	catalogo_ministros.clear()
	for m in p_ministros:
		catalogo_ministros[m["id"]] = m
	catalogo_propuestas.clear()
	for pr in p_extra.get("propuestas", []):
		catalogo_propuestas[pr["id"]] = pr
	_cartas_por_id.clear()
	for c in catalogo_cartas:
		_cartas_por_id[c["id"]] = c
	regiones.cargar(p_extra.get("regiones", []))
	legal.configurar(catalogo_leyes, rng)
	obras.configurar(catalogo_leyes, rng, regiones)
	fx.configurar(estado, catalogo_leyes, regiones)
	grafo.cargar(p_extra.get("grafo", {}))
	if estado.indicadores.is_empty():
		estado.indicadores = EstadoSimulacion.IND_DEFECTO.duplicate()


func _h(clave: String) -> Variant:
	return catalogo_leyes["hemiciclo"][clave]


func turnos_mandato() -> int:
	return int(_h("duracion_mandato_dias")) / estado.dias_por_turno


func aplicar_partido_inicial(datos_partido: Dictionary) -> void:
	estado.partido = datos_partido.duplicate(true)
	estado.etapa = "campana"
	estado.promesas_campana.clear()
	var ind_ini: Dictionary = datos_partido["indicadores_iniciales"]
	for clave in ind_ini.keys():
		estado.indicadores[clave] = float(ind_ini[clave])
	var camp: Dictionary = catalogo_leyes.get("campana", {})
	regiones.inicializar(estado, estado.ind("aprobacion"), String(datos_partido.get("region_bastion", "")),
			float(camp.get("bono_bastion", 0.0)), float(camp.get("variacion_regional_inicial", 0.0)))


# ---------------------------------------------------------------- Flujo de alto nivel (UI, bots, replay)
func iniciar_turno() -> Array[Dictionary]:
	ejecutar_amanecer()
	var evs := procesar_eventos_semana()
	robar_mano(int(catalogo_leyes["mano"]["tamano"]))
	ultimos_eventos = evs
	return evs


func terminar_turno() -> Array[Dictionary]:
	## Cierra el turno y, si la partida sigue y no toca elección, inicia el siguiente.
	cerrar_turno()
	if estado.eleccion_pendiente(int(_h("semanas_campana"))):
		return []
	if estado.etapa == "campana" or estado.etapa == "gobierno":
		return iniciar_turno()
	return []


# ---------------------------------------------------------------- Paso 1
func ejecutar_amanecer() -> void:
	estado.pa_actual = estado.pa_maximo
	if estado.etapa == "campana":
		regiones.revertir_a_base(estado, float(catalogo_leyes["campana"]["reversion_semanal"]))
	if estado.etapa != "gobierno":
		return
	var d: Dictionary = catalogo_leyes["dinamica"]
	var ancla := float(d["ancla_base"]) + float(d["ancla_peso_fiscal"]) * (estado.ind("fiscal") - 50.0) \
			+ float(d["ancla_peso_cohesion"]) * (estado.ind("cohesion") - 50.0) \
			+ float(d["ancla_peso_capital"]) * (estado.ind("capital") - 50.0)
	ancla -= maxf(0.0, float(d["fiscal_critico"]) - estado.ind("fiscal")) * float(d["penal_fiscal_critico"])
	if regiones.pesos.is_empty():
		fx.sumar_ind("aprobacion", (ancla - estado.ind("aprobacion")) * float(d["reversion_semanal"]))
	else:
		regiones.revertir(estado, ancla, float(d["reversion_semanal"]), float(d.get("sesgo_regional_persistente", 0.0)))
	fx.delta_aprobacion(-float(d["desgaste_aprobacion_semanal"]), "")
	fx.sumar_ind("fiscal", float(d["regen_fiscal_semanal"]))
	var extra := maxi(0, estado.obras_en_curso.size() - int(d["max_obras_concurrentes"]))
	fx.sumar_ind("riesgo_ejecucion", float(extra) * float(d["riesgo_por_obra_extra"]) - 0.5)
	if estado.ind("riesgo_ejecucion") > float(d["riesgo_umbral"]):
		fx.delta_aprobacion(-float(d["penal_aprobacion_riesgo"]), "")
	fx.sumar_ind("capital", float(d["regen_capital_semanal"]))
	fx.sumar_ind("cohesion", float(d["regen_cohesion_semanal"]))


# ---------------------------------------------------------------- Paso 2
# ---------------------------------------------------------------- Paso 3
func robar_mano(n: int = 5) -> void:
	while estado.mano.size() < n:
		if estado.mazo.is_empty() and not _reponer_mazo():
			return
		var id: String = estado.mazo.pop_back()
		if estado.cartas_ejecutadas.has(id):
			continue  # carta única ya ejecutada: sale del mazo
		estado.mano.append(_cartas_por_id[id])


func _reponer_mazo() -> bool:
	if not estado.descarte.is_empty():
		estado.mazo.assign(estado.descarte)
		estado.descarte.clear()
	else:
		for c in catalogo_cartas:
			if not estado.mano.any(func(m: Dictionary) -> bool: return m["id"] == c["id"]):
				estado.mazo.append(String(c["id"]))
	for i in range(estado.mazo.size() - 1, 0, -1):  # Fisher-Yates con la semilla de la partida
		var j := rng.randi_range(0, i)
		var tmp: String = estado.mazo[i]
		estado.mazo[i] = estado.mazo[j]
		estado.mazo[j] = tmp
	return not estado.mazo.is_empty()


# ---------------------------------------------------------------- Pasos 4-6
# ---------------------------------------------------------------- Paso 7-8

func cerrar_turno() -> void:
	if estado.etapa != "campana" and estado.etapa != "gobierno":
		return
	var resumen := {}
	votaciones_semana = []
	if estado.etapa == "gobierno":
		votaciones_semana = cartas.resolver_proyectos()
		resumen["leyes"] = votaciones_semana
		resumen["obras_terminadas"] = obras.avanzar(estado, estado.dias_por_turno, fx.aplicar_efecto, fx.marcar_cumplida).size()
		mandato.evaluar_legado()
		mandato.evaluar_crisis()
	estado.registrar_accion("cierre_turno", {"aprobacion": snappedf(estado.ind("aprobacion"), 0.01), "resumen": resumen.size()})
	estado.registrar_entrada("cerrar", {})
	if estado.etapa != "gobierno" and estado.etapa != "campana":
		return
	estado.turno_actual += 1
	estado.dia_actual += estado.dias_por_turno
	if estado.etapa == "gobierno" and estado.turno_actual > turnos_mandato():
		mandato.finalizar("fin_mandato")


func resolver_eleccion_presidencial() -> Dictionary:
	var umbral := float(_h("umbral_victoria_presidencial"))
	var ruido := float(catalogo_leyes["campana"]["ruido_eleccion"])
	var voto_final := clampf(estado.ind("aprobacion") + rng.randf_range(-ruido, ruido), 0.0, 100.0)
	var electo := voto_final >= umbral
	estado.registrar_accion("eleccion_presidencial", {
		"voto_final": voto_final, "umbral": umbral, "electo": electo,
		"promesas_registradas": estado.promesas_campana.size()
	})
	estado.registrar_entrada("eleccion", {})
	if electo:
		estado.etapa = "gobierno"
		estado.turno_actual = 1
		estado.dia_actual = 1
		estado.pa_actual = estado.pa_maximo
	else:
		estado.etapa = "derrota_electoral"
		estado.resultado_final = {"motivo": "derrota_electoral", "voto_final": voto_final, "puntaje": 0}
	return {"electo": electo, "voto_final": voto_final, "umbral": umbral}


# ---------------------------------------------------------------- Utilidades de efectos

# ---------------------------------------------------------------- Fachada (la UI y los tests usan estos nombres)
func procesar_eventos_semana() -> Array[Dictionary]: return eventos.procesar_semana()


func costo_carta(carta: Dictionary, ministro_id: String = "") -> int: return cartas.costo_carta(carta, ministro_id)


func es_unica(carta: Dictionary) -> bool: return cartas.es_unica(carta)


func vista_carta(idx: int, ministro_id: String = "") -> Dictionary: return cartas.vista_carta(idx, ministro_id)


func jugar_carta(idx: int, ministro_id: String = "", region_id: String = "") -> Dictionary: return cartas.jugar_carta(idx, ministro_id, region_id)


func aprobar_propuesta(prop_id: String, variante_id: String, region_id: String = "", custom: Dictionary = {}) -> Dictionary: return cartas.aprobar_propuesta(prop_id, variante_id, region_id, custom)


func calcular_puntaje() -> int: return mandato.calcular_puntaje()
