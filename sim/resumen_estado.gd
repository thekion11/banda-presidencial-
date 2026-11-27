class_name ResumenEstado
extends RefCounted
## Resumen canónico del estado de la partida (lo que entra en la huella). Separado de EstadoSimulacion para mantener ese archivo bajo su límite.


static func de(e: EstadoSimulacion) -> Dictionary:
	## Diccionario resumen de un estado para informes y la interfaz.
	var r := {
		"semilla": e.semilla,
		"etapa": e.etapa,
		"turno_actual": e.turno_actual,
		"dia_actual": e.dia_actual,
		"pa_actual": e.pa_actual,
		"gabinete": e.gabinete.duplicate(),
		"eventos_ocurridos": e.eventos_ocurridos.duplicate(),
		"decisiones": e.decisiones.duplicate(),
		"metas_cumplidas": e.metas_cumplidas.duplicate(),
		"indices_sector": e.indices_sector.duplicate(),
		"asesores": e.asesores.duplicate(),
		"bono_mov": e.bono_mov.duplicate(),
		"coalicion": e.coalicion.duplicate(true),
		"apoyo_coalicion": e.apoyo_coalicion.duplicate(),
		"delegadas_turno": e.delegadas_turno,
		"internos_actual": e.internos_actual,
		"balas": e.balas.duplicate(true),
		"presupuesto": e.presupuesto.duplicate(true),
		"indicadores": e.indicadores.duplicate(true),
		"aprobacion_regional": e.aprobacion_regional.duplicate(true),
		"partido": e.partido.duplicate(true),
		"promesas": e.promesas_campana.duplicate(true),
		"mano": e._ids_mano(),
		"mazo": e.mazo.size(),
		"obras_en_curso": e.obras_en_curso.duplicate(true),
		"obras_terminadas": e.obras_terminadas.size(),
		"lineas_jugador": e.lineas_jugador.duplicate(true),
		"proyectos_ley": e.proyectos_ley.duplicate(true),
		"cartas_ejecutadas": e.cartas_ejecutadas.keys(),
		"sectra": e.sectra.duplicate(true),
		"ronda_electoral": e.ronda_electoral,
		"ciclo": e.ciclo,
		"carrera": e.carrera.duplicate(true),
		"dias_carrera": e.dias_carrera,
		"pendientes": e.pendientes.duplicate(true),
		"propuestas_abiertas": e.propuestas_abiertas.duplicate(),
		"propuestas_aprobadas": e.propuestas_aprobadas.duplicate(),
		"total_acciones": e.registro_acciones.size(),
		"registro": e.registro_acciones.duplicate(true),
		"resultado_final": e.resultado_final.duplicate(true),
	}
	if not e.agenda.is_empty() or not e.agenda_rechazos.is_empty():  # solo si se usó la agenda legislativa: las huellas de partidas sin ella no cambian
		r["agenda"] = e.agenda.duplicate(true)
		r["agenda_rechazos"] = e.agenda_rechazos.duplicate()
	return r
