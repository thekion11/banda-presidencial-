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
var piso := PisoIdeologico.new(self)  # piso de aprobación y de voto (D-BQ)
var movimientos := MotorMovimientos.new(self)
var agenda := MotorAgenda.new(self)
var balas := MotorBalas.new(self)
var presupuesto := MotorPresupuesto.new(self)
var eventos := MotorEventos.new(self)
var ultimos_eventos: Array[Dictionary] = []
var votaciones_semana: Array[Dictionary] = []  # votaciones de leyes resueltas al cerrar el turno (para la UI)
var _cartas_por_id: Dictionary = {}
var indices: IndicesCartas  # índices del catálogo de cartas (compartidos y de solo lectura)


func inicializar(p_estado: EstadoSimulacion, p_cartas: Array, p_eventos: Array, p_leyes: Dictionary,
		p_ministros: Array, p_extra: Dictionary = {}) -> void:  # Conecta estado y catálogos y crea los módulos del motor.
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
	var ix: Variant = p_extra.get("indices_cartas", null)  # precalculados al cargar los datos; si no coinciden con las cartas, se arman aquí
	indices = ix if (ix is IndicesCartas and (ix as IndicesCartas).n == p_cartas.size()) else IndicesCartas.construir(p_cartas)
	_cartas_por_id = indices.por_id.duplicate()  # copia: algunas pruebas agregan cartas sueltas
	regiones.cargar(p_extra.get("regiones", []))
	regiones.proveedor_pisos = piso.pisos
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


func turnos_mandato() -> int:  # Turnos del mandato (duración en días entre días por turno).
	return int(_h("duracion_mandato_dias")) / estado.dias_por_turno


func aplicar_partido_inicial(datos_partido: Dictionary) -> void:  # Aplica el partido elegido: indicadores, regiones y coalición propia; deja la partida en campaña.
	estado.partido = EstadoSimulacion.normalizar(datos_partido)
	estado.etapa = "campana"
	coalicion.adoptar_partido_propio(String(datos_partido.get("partido_base", "")))  # tu partido es aliado permanente que pide poder (PR-01)
	estado.promesas_campana.clear()
	var ind_ini: Dictionary = estado.partido["indicadores_iniciales"]
	var lim: Dictionary = catalogo_leyes["limites_indicadores"]
	for clave in ind_ini.keys():  # un partido con valores absurdos no arranca fuera de rango
		estado.indicadores[clave] = clampf(float(ind_ini[clave]), float(lim["min"]), float(lim["viviendas_anio_max"]) if clave == "viviendas_anio" else float(lim["max"]))
	estado.indicadores["aprobacion"] = clampf(estado.ind("aprobacion") + float(mandato.nivel()["aprobacion_inicial"]), 0.0, 100.0)  # dificultad (PR-01)
	var camp: Dictionary = catalogo_leyes.get("campana", {})
	regiones.inicializar(estado, estado.ind("aprobacion"), String(datos_partido.get("region_bastion", "")),
			float(camp.get("bono_bastion", 0.0)), float(camp.get("variacion_regional_inicial", 0.0)))


# ---------------------------------------------------------------- Flujo de alto nivel (UI, bots, replay)
func iniciar_turno() -> Array[Dictionary]:  # Pasos 1 y 2 del turno: amanecer y eventos; devuelve los eventos de la semana.
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
func ejecutar_amanecer() -> void:  # Paso 1: regenera movimientos y aplica la dinámica semanal de los indicadores (ancla de aprobación, desgaste, regeneraciones).
	movimientos.amanecer()  # el ahorro de la semana anterior queda en pa_actual; fijar_movimientos le suma el ingreso
	if estado.etapa == "campana":
		regiones.revertir_a_base(estado, float(catalogo_leyes["campana"]["reversion_semanal"]))
	if estado.etapa != "gobierno":
		if estado.etapa == "oposicion":
			mandato.amanecer_oposicion()
		movimientos.fijar_movimientos()
		return
	var d: Dictionary = catalogo_leyes["dinamica"]
	var ancla := float(d["ancla_base"]) + float(d["ancla_peso_fiscal"]) * (estado.ind("fiscal") - 50.0) \
			+ float(d["ancla_peso_cohesion"]) * (estado.ind("cohesion") - 50.0) \
			+ float(d["ancla_peso_capital"]) * (estado.ind("capital") - 50.0)
	ancla -= maxf(0.0, float(d["fiscal_critico"]) - estado.ind("fiscal")) * float(d["penal_fiscal_critico"])
	var desg := float(d["desgaste_aprobacion_semanal"]) * float(mandato.nivel()["desgaste"])
	var li := LunaDeMiel.intensidad(estado, catalogo_leyes)  # luna de miel: el impulso del inicio del gobierno se desvanece (leyes.json › luna_de_miel)
	fx.anotar("aprobacion", String(catalogo_leyes["luna_de_miel"]["texto_motivo"]), LunaDeMiel.efecto_aprobacion(catalogo_leyes, li, estado.ind("aprobacion"), ancla, float(d["reversion_semanal"]), desg))
	var lm := LunaDeMiel.ajustes(catalogo_leyes, li)
	var rev := float(d["reversion_semanal"])
	ancla += float(lm["ancla"])
	LunaDeMiel.amanecer(estado, catalogo_leyes)
	if regiones.pesos.is_empty():
		fx.sumar_ind("aprobacion", (ancla - estado.ind("aprobacion")) * rev)
	else:
		regiones.revertir(estado, ancla, rev, float(d.get("sesgo_regional_persistente", 0.0)))
	fx.delta_aprobacion(-desg * float(lm["desgaste"]), "")
	fx.sumar_ind("fiscal", float(d["regen_fiscal_semanal"]), "recuperación fiscal de la semana")
	var extra := maxi(0, estado.obras_en_curso.size() - int(d["max_obras_concurrentes"]))
	fx.sumar_ind("riesgo_ejecucion", float(extra) * float(d["riesgo_por_obra_extra"]) - float(d["riesgo_regen_semanal"]), "obras en curso y equipos que corrigen errores")
	if estado.ind("riesgo_ejecucion") > float(d["riesgo_umbral"]):
		fx.delta_aprobacion(-float(d["penal_aprobacion_riesgo"]), "")
	fx.sumar_ind("capital", float(d["regen_capital_semanal"]), "capital político que se recupera")
	fx.sumar_ind("cohesion", float(d["regen_cohesion_semanal"]), "desgaste semanal del gobierno")
	gabinete.amanecer()  # estilos y afinidad de los ministros (Fase C)
	presupuesto.amanecer()  # presupuesto extra a ministerios: aceleran sus proyectos y a veces se desvían
	movimientos.fijar_movimientos()


func cerrar_turno() -> void:  # Pasos 7 y 8: votaciones, obras, crisis y avance del calendario; registra la entrada «cerrar».
	if not ETAPAS_JUEGO.has(estado.etapa):
		return
	if estado.eleccion_pendiente(int(_h("semanas_campana"))):
		return  # terminada la campaña toca votar: no se pueden seguir cerrando turnos
	var resumen := {}
	fx.reiniciar_motivos()
	votaciones_semana = []
	if estado.etapa == "gobierno":
		votaciones_semana = cartas.resolver_proyectos() + agenda.avanzar()  # leyes de la mano y de la agenda legislativa
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
	if estado.eleccion_pendiente(int(_h("semanas_campana"))):
		Encuestas.registrar(self)  # la última encuesta antes de votar refleja la campaña ya terminada


func motivos_semana() -> Array[Dictionary]: return fx.motivos_semana()  # Cambios de la semana con su causa (solo salida para la UI).

func resolver_eleccion_presidencial() -> Dictionary: return mandato.resolver_eleccion()  # Vota la elección presidencial (puede dar segunda vuelta).
func continuar_carrera() -> Dictionary: return mandato.continuar_carrera()  # Tras un fin de periodo abre la oposición o la campaña de reelección.


# ---------------------------------------------------------------- Fachada (la UI y los tests usan estos nombres)
func procesar_eventos_semana() -> Array[Dictionary]: return eventos.procesar_semana()  # Atajo de MotorEventos.procesar_semana.
func costo_carta(carta: Dictionary, ministro_id: String = "") -> int: return cartas.costo_carta(carta, ministro_id)  # Atajo de MotorCartas.costo_carta.
func es_unica(carta: Dictionary) -> bool: return cartas.es_unica(carta)  # Atajo de MotorCartas.es_unica.
func vista_carta(idx: int, ministro_id: String = "") -> Dictionary: return cartas.vista_carta(idx, ministro_id)  # Atajo de MotorCartas.vista_carta.
func jugar_carta(idx: int, ministro_id: String = "", region_id: String = "") -> Dictionary: return cartas.jugar_carta(idx, ministro_id, region_id)  # Juega una carta de la mano (con movimientos).
func aprobar_propuesta(prop_id: String, variante_id: String, region_id: String = "", custom: Dictionary = {}, nombres: Dictionary = {}) -> Dictionary: return cartas.aprobar_propuesta(prop_id, variante_id, region_id, custom, nombres)  # Atajo de MotorCartas.aprobar_propuesta.
func impulsar_proyecto(pid: String) -> Dictionary: return sectra.impulsar(pid)  # Atajo de MotorSectra.impulsar.
func calcular_puntaje() -> int: return mandato.calcular_puntaje()  # Atajo de MotorMandato.calcular_puntaje.

func robar_mano(n: int = 5) -> void: mazo.robar(n)  # Atajo de MotorMazo.robar.
func carta_disponible(carta: Dictionary) -> bool: return gabinete.disponible(carta)  # true si el gabinete y las condiciones permiten que la carta circule.
func elegir_gabinete(ids: Array) -> Dictionary: return gabinete.elegir(ids)  # Nombra el gabinete (solo en campaña o en la primera semana de gobierno).
func delegar_carta(idx: int, ministro_id: String, region_id: String = "") -> Dictionary: return cartas.jugar_carta(idx, ministro_id, region_id, true)  # Juega una carta delegándola en un ministro (sin gastar movimientos, con riesgo de fallo).
func prob_fallo_delegacion(idx: int, ministro_id: String) -> float: return gabinete.prob_fallo(estado.mano[idx], ministro_id)  # Probabilidad de fallo de delegar la carta de la mano en ese ministro.
func buscar_meta(meta_id: String) -> Dictionary: return movimientos.buscar_meta(meta_id)  # Atajo de MotorMovimientos.buscar_meta.
func ajustar_sector(sector: String, direccion: int) -> Dictionary: return movimientos.ajustar_sector(sector, direccion)  # Atajo de MotorMovimientos.ajustar_sector.
func reducir_errores() -> Dictionary: return movimientos.reducir_errores()  # Atajo de MotorMovimientos.reducir_errores.
func acelerar_proyecto(idx: int) -> Dictionary: return movimientos.acelerar_proyecto(idx)  # Atajo de MotorMovimientos.acelerar_proyecto.
func contratar_asesor(id: String) -> Dictionary: return equipo.contratar(id)  # Atajo de MotorEquipo.contratar.
func despedir_asesor(id: String) -> Dictionary: return equipo.despedir(id)  # Atajo de MotorEquipo.despedir.
func unirse_coalicion(id: String) -> Dictionary: return coalicion.unirse(id)  # Atajo de MotorCoalicion.unirse.
func salir_coalicion(id: String) -> Dictionary: return coalicion.salir(id)  # Atajo de MotorCoalicion.salir.
func asignar_cuota(id: String, tipo: String, valor: String) -> Dictionary: return coalicion.asignar_cuota(id, tipo, valor)  # Entrega a un aliado un ministerio o asesor que pide.
func quitar_cuota(id: String, tipo: String, valor: String) -> Dictionary: return coalicion.asignar_cuota(id, tipo, valor, true)  # Retira esa cuota a un aliado.
