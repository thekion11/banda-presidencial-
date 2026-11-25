class_name MotorTurno
extends RefCounted
## Ciclo fijo de 8 pasos por turno semanal. Determinista: misma semilla + mismas entradas = mismo resultado.

var estado: EstadoSimulacion
var rng: RandomNumberGenerator
var catalogo_cartas: Array[Dictionary] = []
const ETAPAS_JUEGO := ["campana", "gobierno", "oposicion"]  # etapas con turnos (el resto son fines de periodo)
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
var sectra := MotorSectra.new(self)
var cartas := MotorCartas.new(self)
var gabinete := MotorGabinete.new(self)
var mazo := MotorMazo.new(self)
var equipo := MotorEquipo.new(self)
var coalicion := MotorCoalicion.new(self)
var movimientos := MotorMovimientos.new(self)
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
	sectra.cargar(p_extra.get("sectra", {}))
	movimientos.cargar(p_extra.get("metas", []))
	equipo.cargar(p_extra.get("asesores", []))
	coalicion.cargar(p_extra.get("coalicion", []))
	if estado.gabinete.is_empty():
		estado.gabinete = gabinete.por_defecto()
	if estado.indicadores.is_empty():
		estado.indicadores = EstadoSimulacion.IND_DEFECTO.duplicate()


func _h(clave: String) -> Variant:
	return catalogo_leyes["hemiciclo"][clave]


func turnos_mandato() -> int:
	return int(_h("duracion_mandato_dias")) / estado.dias_por_turno


func aplicar_partido_inicial(datos_partido: Dictionary) -> void:
	estado.partido = EstadoSimulacion.normalizar(datos_partido)
	estado.etapa = "campana"
	coalicion.adoptar_partido_propio(String(datos_partido.get("partido_base", "")))  # tu partido es aliado permanente que pide poder (PR-01)
	estado.promesas_campana.clear()
	var ind_ini: Dictionary = estado.partido["indicadores_iniciales"]
	for clave in ind_ini.keys():
		estado.indicadores[clave] = float(ind_ini[clave])
	estado.indicadores["aprobacion"] = clampf(estado.ind("aprobacion") + float(mandato.nivel()["aprobacion_inicial"]), 0.0, 100.0)  # dificultad (PR-01)
	var camp: Dictionary = catalogo_leyes.get("campana", {})
	regiones.inicializar(estado, estado.ind("aprobacion"), String(datos_partido.get("region_bastion", "")),
			float(camp.get("bono_bastion", 0.0)), float(camp.get("variacion_regional_inicial", 0.0)))


# ---------------------------------------------------------------- Flujo de alto nivel (UI, bots, replay)
func iniciar_turno() -> Array[Dictionary]:
	ejecutar_amanecer()
	var evs := procesar_eventos_semana()
	mazo.refiltrar_mano()  # las cartas cuya ventana (año, evento, dinero) terminó vuelven al descarte y entran otras
	ultimos_eventos = evs
	return evs


func terminar_turno() -> Array[Dictionary]:
	## Cierra el turno y, si la partida sigue y no toca elección, inicia el siguiente.
	cerrar_turno()
	if estado.eleccion_pendiente(int(_h("semanas_campana"))):
		return []
	if ETAPAS_JUEGO.has(estado.etapa):
		return iniciar_turno()
	return []


# ---------------------------------------------------------------- Paso 1
func ejecutar_amanecer() -> void:
	estado.pa_actual = estado.pa_maximo
	movimientos.amanecer()
	if estado.etapa == "campana":
		regiones.revertir_a_base(estado, float(catalogo_leyes["campana"]["reversion_semanal"]))
	if estado.etapa != "gobierno":
		movimientos.fijar_movimientos()
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
	fx.delta_aprobacion(-float(d["desgaste_aprobacion_semanal"]) * float(mandato.nivel()["desgaste"]), "")
	fx.sumar_ind("fiscal", float(d["regen_fiscal_semanal"]))
	var extra := maxi(0, estado.obras_en_curso.size() - int(d["max_obras_concurrentes"]))
	fx.sumar_ind("riesgo_ejecucion", float(extra) * float(d["riesgo_por_obra_extra"]) - float(d["riesgo_regen_semanal"]))
	if estado.ind("riesgo_ejecucion") > float(d["riesgo_umbral"]):
		fx.delta_aprobacion(-float(d["penal_aprobacion_riesgo"]), "")
	fx.sumar_ind("capital", float(d["regen_capital_semanal"]))
	fx.sumar_ind("cohesion", float(d["regen_cohesion_semanal"]))
	gabinete.amanecer()  # estilos y afinidad de los ministros (Fase C)
	movimientos.fijar_movimientos()


func cerrar_turno() -> void:
	if not ETAPAS_JUEGO.has(estado.etapa):
		return
	if estado.eleccion_pendiente(int(_h("semanas_campana"))):
		return  # terminada la campaña toca votar: no se pueden seguir cerrando turnos
	var resumen := {}
	votaciones_semana = []
	if estado.etapa == "gobierno":
		votaciones_semana = cartas.resolver_proyectos()
		sectra.avanzar()
		resumen["leyes"] = votaciones_semana
		resumen["obras_terminadas"] = obras.avanzar(estado, estado.dias_por_turno, fx.aplicar_efecto, fx.marcar_cumplida).size()
		mandato.evaluar_legado()
		mandato.evaluar_crisis()
	estado.registrar_accion("cierre_turno", {"aprobacion": snappedf(estado.ind("aprobacion"), 0.01), "resumen": resumen.size()})
	estado.registrar_entrada("cerrar", {})
	cartas.descartar_mano()
	if not ETAPAS_JUEGO.has(estado.etapa):
		return
	estado.turno_actual += 1
	estado.dia_actual += estado.dias_por_turno
	if estado.etapa == "oposicion" and estado.turno_actual > int(catalogo_leyes["oposicion"]["semanas"]):
		mandato.cerrar_oposicion()
	if estado.etapa == "gobierno" and estado.turno_actual > turnos_mandato():
		mandato.finalizar("fin_mandato")


func resolver_eleccion_presidencial() -> Dictionary: return mandato.resolver_eleccion()


func continuar_carrera() -> Dictionary: return mandato.continuar_carrera()


# ---------------------------------------------------------------- Fachada (la UI y los tests usan estos nombres)
func procesar_eventos_semana() -> Array[Dictionary]: return eventos.procesar_semana()

func costo_carta(carta: Dictionary, ministro_id: String = "") -> int: return cartas.costo_carta(carta, ministro_id)

func es_unica(carta: Dictionary) -> bool: return cartas.es_unica(carta)

func vista_carta(idx: int, ministro_id: String = "") -> Dictionary: return cartas.vista_carta(idx, ministro_id)

func jugar_carta(idx: int, ministro_id: String = "", region_id: String = "") -> Dictionary: return cartas.jugar_carta(idx, ministro_id, region_id)

func aprobar_propuesta(prop_id: String, variante_id: String, region_id: String = "", custom: Dictionary = {}, nombres: Dictionary = {}) -> Dictionary: return cartas.aprobar_propuesta(prop_id, variante_id, region_id, custom, nombres)

func impulsar_proyecto(pid: String) -> Dictionary: return sectra.impulsar(pid)

func calcular_puntaje() -> int: return mandato.calcular_puntaje()


func robar_mano(n: int = 5) -> void: mazo.robar(n)

func carta_disponible(carta: Dictionary) -> bool: return gabinete.disponible(carta)

func elegir_gabinete(ids: Array) -> Dictionary: return gabinete.elegir(ids)

func delegar_carta(idx: int, ministro_id: String, region_id: String = "") -> Dictionary: return cartas.jugar_carta(idx, ministro_id, region_id, true)

func prob_fallo_delegacion(idx: int, ministro_id: String) -> float: return gabinete.prob_fallo(estado.mano[idx], ministro_id)

func buscar_meta(meta_id: String) -> Dictionary: return movimientos.buscar_meta(meta_id)

func ajustar_sector(sector: String, direccion: int) -> Dictionary: return movimientos.ajustar_sector(sector, direccion)

func reducir_errores() -> Dictionary: return movimientos.reducir_errores()

func acelerar_proyecto(idx: int) -> Dictionary: return movimientos.acelerar_proyecto(idx)

func contratar_asesor(id: String) -> Dictionary: return equipo.contratar(id)

func despedir_asesor(id: String) -> Dictionary: return equipo.despedir(id)
func unirse_coalicion(id: String) -> Dictionary: return coalicion.unirse(id)
func salir_coalicion(id: String) -> Dictionary: return coalicion.salir(id)
func asignar_cuota(id: String, tipo: String, valor: String) -> Dictionary: return coalicion.asignar_cuota(id, tipo, valor)
func quitar_cuota(id: String, tipo: String, valor: String) -> Dictionary: return coalicion.asignar_cuota(id, tipo, valor, true)
