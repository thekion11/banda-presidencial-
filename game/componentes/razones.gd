class_name Razones
extends RefCounted
## Motivos de rechazo del motor (campo `razon`) en lenguaje claro para la interfaz.

const TEXTOS := {
	"solo_en_gobierno": "Los movimientos internos solo existen en gobierno.",
	"movimientos_insuficientes": "No te quedan movimientos internos este turno.",
	"sin_efecto": "Ese movimiento no cambiaría nada ahora.",
	"sector_sin_ministro": "Necesitas un ministro de ese sector en tu gabinete.",
	"requiere_meta_previa": "Antes debes cumplir la meta anterior de la cadena.",
	"meta_cumplida": "Esa meta ya está cumplida.",
	"meta_inexistente": "Esa meta no existe.",
	"gabinete_cerrado": "El gabinete solo se cambia en campaña o en la primera semana de gobierno.",
	"tamano_invalido": "Elige exactamente el número de ministros que pide el gabinete.",
	"ministro_invalido": "Ministro inválido o repetido.",
	"limite_delegaciones": "Ya delegaste el máximo de cartas este turno.",
	"ministro_fuera_del_gabinete": "Ese ministro no está en tu gabinete.",
	"ministro_no_disponible": "Delegar solo se puede en gobierno.",
	"pa_insuficiente": "No te alcanzan los movimientos.",
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
}


static func texto(r: Dictionary) -> String:
	return String(TEXTOS.get(String(r.get("razon", "")), "No se pudo realizar la acción."))
