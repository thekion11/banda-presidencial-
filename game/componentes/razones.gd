class_name Razones
extends RefCounted
## Motivos de rechazo del motor (campo `razon`) en lenguaje claro para la interfaz.

const TEXTOS := {
	"solo_en_gobierno": "Los movimientos internos solo existen en gobierno.",
	"movimientos_insuficientes": "No te quedan movimientos internos este turno; se renuevan al empezar la próxima semana.",
	"sin_efecto": "Ese movimiento no cambiaría nada ahora.",
	"sector_sin_ministro": "Necesitas un ministro de ese sector en tu gabinete.",
	"requiere_meta_previa": "Antes debes cumplir la meta anterior de la cadena.",
	"meta_cumplida": "Esa meta ya está cumplida.",
	"meta_inexistente": "Esa meta no existe.",
	"gabinete_cerrado": "El gabinete solo se cambia en campaña o en la primera semana de gobierno.",
	"tamano_invalido": "Elige exactamente el número de ministros que pide el gabinete.",
	"ministro_invalido": "Ministro inválido o repetido.",
	"carta_inexistente": "Ese proyecto no existe en el catálogo.",
	"urgencia_invalida": "Esa urgencia no existe: elige simple, suma o discusión inmediata.",
	"agenda_llena": "Ya tienes el máximo de proyectos en trámite; espera a que se resuelva uno o intenta más adelante.",
	"no_es_ley": "Esa carta no es un proyecto de ley.",
	"ya_en_tramite": "Ese proyecto ya está en el Congreso; espera su resultado.",
	"en_espera_tras_rechazo": "El Congreso rechazó este proyecto hace poco: intenta más adelante, cuando pasen unas semanas.",
	"carta_no_habilitada": "Tu gabinete o el año de gobierno aún no habilitan este proyecto: revisa tu gabinete o espera la próxima ventana.",
	"capital_insuficiente": "No tienes el capital político que pide esa urgencia: elige una urgencia más baja o espera a juntar más.",
	"quorum_insuficiente": "Hoy no reúnes el apoyo del Congreso: elige otra urgencia o espera a tener más capital y cohesión.",
	"limite_delegaciones": "Ya delegaste el máximo de cartas este turno; se renueva cada semana.",
	"ministro_fuera_del_gabinete": "Ese ministro no está en tu gabinete.",
	"ministro_no_disponible": "Delegar solo se puede en gobierno.",
	"pa_insuficiente": "No te alcanzan los movimientos: termina la semana, delega la carta o elige una más barata.",
	"ya_ejecutada": "Esa meta ya está en marcha.",
	"region_invalida": "Región inválida.",
	"ya_contratado": "Ese asesor ya trabaja contigo.",
	"limite_asesores": "Ya tienes el máximo de asesores; despide a uno primero.",
	"asesor_inexistente": "Ese asesor no existe.",
	"no_contratado": "Ese asesor no está contratado.",
	"partido_propio": "Tu partido no se abandona: si lo desatiendes, rompe contigo.",
	"ya_aliado": "Ese partido ya es parte de tu coalición.",
	"limite_aliados": "Tu coalición está completa; deja salir a un aliado primero.",
	"no_aliado": "Ese partido no es tu aliado.",
	"ya_asignado": "Esa cuota ya la tiene otro partido aliado.",
	"fuera_del_gabinete": "Ese ministro no está en tu gabinete.",
	"asesor_no_contratado": "Ese asesor no está contratado.",
	"no_asignado": "Esa cuota no estaba asignada.",
	"partida_terminada": "La partida ya terminó.",
	"indice_invalido": "Selección inválida.",
	"limite_simultaneo": "Ya tienes el máximo de proyectos en trámite: espera a que termine uno o impulsa otro más adelante.",
	"en_tramite_o_terminado": "Ese proyecto ya está en trámite o terminado: elige otro de la cartera.",
	"proyecto_no_disponible": "Ese proyecto ya no está disponible: revisa la cartera.",
	"propuesta_no_disponible": "Esa propuesta ya fue decidida o no está abierta: elige otra en el Comité.",
	"periodo_en_curso": "El periodo sigue en curso: termina la semana para avanzar.",
	"variante_invalida": "Elige una de las variantes A, B o C del Comité.",
	"trazado_invalido": "Ese trazado no sirve: une entre 3 y 7 estaciones distintas, sin repetir una seguida.",
	"ya_decidido": "Ya respondiste a este evento.",
	"evento_sin_decision": "Este evento no pide una decisión: sigue adelante.",
	"partido_inexistente": "Ese partido no existe: elige otro de la lista.",
	"direccion_invalida": "Esa opción no es válida; vuelve a intentarlo.",
	"opcion_invalida": "Esa opción no es válida; vuelve a intentarlo.",
	"tipo_desconocido": "Esa opción no es válida; vuelve a intentarlo.",
	"tipo_invalido": "Esa opción no es válida; vuelve a intentarlo.",
}


static func texto(r: Dictionary) -> String:
	var t := String(TEXTOS.get(String(r.get("razon", "")), "No se pudo realizar la acción."))
	if String(r.get("razon", "")) == "pa_insuficiente" and r.has("costo"):  # con la cifra: cuánto pide la carta
		t = "Esta carta cuesta %d %s. %s" % [int(r["costo"]), "movimiento" if int(r["costo"]) == 1 else "movimientos", t]
	return t
