"""Tabla de arte específico por tema/sector (campo `arte` de la carta = nombre de game/arte/cartas/<arte>.jpg).
Si el archivo no existe, el juego usa la ilustración de la categoría (game/componentes/carta_ui.gd). Aquí NO se crean imágenes.
Las reglas se evalúan en orden y gana la primera que calce; sin calce la carta no lleva `arte` (usa el de su categoría).
Cada entrada: (clave de arte, descripción para ilustrar, predicado)."""
import re

TRATADOS = ("tratado", "convenio", "acuerdo entre", "acuerdo sobre", "protocolo", "enmienda al acuerdo")
# Obras: sector del proyecto público -> arte
ARTE_OBRAS = {"vial": "obras_vial", "aeropuertos": "transportes_aeropuertos", "ferrocarriles": "transportes_trenes", "metro": "transportes_trenes",
              "salud": "salud_hospitales", "agua": "medioambiente_agua", "seguridad": "seguridad_carceles", "edificacion": "obras_edificacion",
              "puertos": "economia_puertos"}
# Proyectos de ley: palabras del título legal completo -> arte (primera regla que calce)
ARTE_LEYES = [
    ("seguridad_defensa", "Fuerzas Armadas, defensa e inteligencia", r"fuerzas armadas|defensa nacional|militar|armada de chile|ejército|fuerza aérea|inteligencia|infraestructura crítica|estados? de excepci"),
    ("seguridad_justicia", "justicia penal: tribunales, fiscalía, penas, víctimas", r"penal|delito|\bpena|tribunal|fiscal[ií]a|v[ií]ctima|c[aá]rcel|gendarmer|polic[ií]a|carabiner|crimen|narco|justicia|querella"),
    ("social_pensiones", "pensiones y previsión", r"pensi[oó]n|pensiones|jubilaci|previsional|afp|seguro de cesant[ií]a"),
    ("trabajo", "trabajo y empleo", r"trabaj|laboral|sindic|remuneraci|empleo|cesant[ií]a|sala cuna|jornada"),
    ("social_familia", "infancia, familia, mujeres, personas mayores y discapacidad", r"ni[ñn]|adolescent|familia|mujer|g[ée]nero|persona(?:s)? mayor|adulto mayor|discapacidad|cuidado|violencia intrafamiliar"),
    ("ambiente", "medio ambiente, fauna y recursos naturales", r"ambient|animal|residuo|reciclaj|forestal|glaciar|clim[aá]t|biodiversidad|contamin|humedal|incendio forestal|agua|h[ií]drico|pesc|acuicultura|mar[ií]tim"),
    ("transportes_transito", "tránsito, conductores y vehículos", r"tr[aá]nsito|conductor|veh[ií]culo|motocicl|licencia de conducir|transporte p[uú]blico|transporte de carga|peaje|vial"),
    ("hacienda_tributaria", "impuestos y presupuesto", r"impuesto|tributari|presupuest|aduaner|deuda p[uú]blica|royalty|exenci[oó]n"),
    ("politica_electoral", "sistema electoral y partidos", r"elector|elecci|votaciones populares|partidos pol|servel|sufragio|escrutinio"),
    ("descentralizacion_municipal", "municipios y gobiernos regionales", r"municipal|alcalde|concejal|gobierno regional|gobernador|descentraliz"),
    ("educacion_escuela", "escuelas, universidades y cultura", r"educaci|escolar|universidad|docente|estudiantes|colegio|cultura|patrimonio|deporte"),
    ("economia_consumo", "consumidores, empresas y comercio", r"consumidor|empresa|comercio|emprend|pyme|competencia|telecomunicaci|datos personales|mercado"),
]


def asignar_arte(carta: dict) -> str | None:
    meta = carta["meta"]
    tipo = meta["tipo"]
    if tipo in ("reforma_constitucional", "propuesta_constitucional"):
        return "politica_reforma"
    if tipo == "proyecto_publico":
        return ARTE_OBRAS.get(meta.get("sector"))
    texto = (meta.get("titulo_completo") or carta["titulo"]).lower()
    if any(k in texto for k in TRATADOS):
        return "politica_tratados"
    for clave, _desc, rx in ARTE_LEYES:
        if re.search(rx, texto):
            return clave
    return None


DESCRIPCIONES = {"politica_reforma": "reforma constitucional (hemiciclo, texto constitucional)", "politica_tratados": "tratados y acuerdos internacionales",
                 "obras_vial": "carretera/puente en construcción", "transportes_aeropuertos": "terminal de aeropuerto", "transportes_trenes": "tren o metro",
                 "salud_hospitales": "hospital / centro oncológico", "medioambiente_agua": "obra sanitaria / sistema de agua",
                 "seguridad_carceles": "recinto penitenciario / seguridad", "obras_edificacion": "edificio público", "economia_puertos": "puerto y logística",
                 **{k: d for k, d, _ in ARTE_LEYES}}
