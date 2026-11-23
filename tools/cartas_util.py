"""Utilidades de tools/generar_cartas.py: títulos cortos, categoría (ministerio afín) y disponibilidad.
Todo es determinista (crc32 del id, nunca hash() de Python)."""
import re
import zlib

CATEGORIAS = ("vivienda", "energia", "hacienda", "salud", "seguridad", "social", "politica", "educacion", "transportes",
              "economia", "medioambiente", "descentralizacion", "obras")
TEMA_CAT = {"seguridad": "seguridad", "hacienda": "hacienda", "social": "social", "trabajo": "economia", "transporte": "transportes",
            "energia": "energia", "educacion": "educacion", "descentralizacion": "descentralizacion", "pensiones": "social",
            "salud": "salud", "ambiente": "medioambiente", "defensa": "seguridad", "vivienda": "vivienda", "agro_pesca": "economia"}
# Para los boletines con tema "otro": clasificación por palabras del título (la primera regla que calce gana).
REGLAS_TITULO = [
    ("salud", r"\bsalud\b|sanitari|medicament|hospital|enfermedad|pacientes|cáncer|farmac|isapre|fonasa|mental|discapacidad"),
    ("educacion", r"educaci|escolar|estudiantes|universidad|docente|colegio|jard[ií]n infantil|escuela|beca|cultura|patrimonio|deporte|artes"),
    ("vivienda", r"vivienda|urban|barrio|campamento|arriendo|copropiedad|suelo|inmobiliari"),
    ("energia", r"energ|eléctric|electric|hidrocarb|combustible|gas licuado|litio|minería|minero|minera"),
    ("medioambiente", r"ambient|animal|residuo|reciclaj|agua|hídric|forestal|glaciar|humedal|clim|biodiversidad|contamin"),
    ("transportes", r"tr[aá]nsito|transporte|vehícul|conductor|ferrovi|aeron|aeropuert|puerto|maritim|marítim|vial|motocicl|licencia de conducir"),
    ("seguridad", r"delit|penal|pena\b|penas|policía|policia|carabiner|víctima|fiscal[ií]a|cárcel|carcel|gendarmer|crimen|violencia|armas|"
                  r"seguridad|narco|terroris|migraci|extranjer|fronter|ciberseg|infraccion|sanciona|tipifica|arma"),
    ("social", r"familia|niñ|niñez|adolescent|adulto mayor|mujer|género|pension|pensión|jubilaci|previsional|trabajador|laboral|sindic|"
               r"remuneraci|subsidio|ingreso|alimentos|ley indígena|pueblos originarios|indígena|protección social|seguro"),
    ("hacienda", r"tribut|impuesto|presupuest|fiscal\b|deuda|aduaner|renta|iva\b|bancari|financier|mercado de valores|cmf|superintendencia"),
    ("economia", r"empres|comerci|consumidor|emprend|pyme|agrícol|agricol|pesca|pesquer|acuicultura|turismo|propiedad intelectual|"
                 r"mercado|competencia|telecomunicaci|datos personales|comunicaciones|propiedad industrial"),
    ("descentralizacion", r"municipal|regional|gobernador|comuna|alcalde|concejal|territori"),
    ("politica", r"constituci|congreso|diputad|senador|parlament|elector|elecci|partidos pol|tratado|convenio|acuerdo|república|protocolo|presidente|"
                 r"transparencia|probidad|lobby|administración del estado|tribunal"),
]
_RX = [(c, re.compile(p, re.I)) for c, p in REGLAS_TITULO]
_INI_LEY = re.compile(r"^(?:Proyecto de ley que |Proyecto de ley |Proyecto de reforma constitucional que |Proyecto de reforma constitucional )", re.I)
_NORMA = (r"(?P<ley>(?:ley|decreto ley|decreto con fuerza de ley|DFL|DL)\s+N?[°ºo.]?\s*(?P<num>[\d.]+))|"
          r"(?P<cod>C[óo]digo\s+(?:Procesal\s+|Org[áa]nico\s+de\s+|de\s+(?:Procedimiento\s+|Justicia\s+)?|del\s+|Sanitario|Penal|Civil|Tributario|de\s+Aguas)?"
          r"(?:Penal|Civil|Militar|Trabajo|Tribunales|Aguas|Miner[íi]a|Sanitario|Tributario|Comercio|Aeron[áa]utico|Electoral|Justicia Militar)?)|"
          r"(?P<cpr>Carta Fundamental|Constituci[óo]n Pol[íi]tica(?: de la Rep[úu]blica)?|Constituci[óo]n)")
_MOD = re.compile(r"^Modifica(?:n)?\s+(?:la\s+|el\s+|los\s+|las\s+)?(?:" + _NORMA + r")(?P<resto>.*)$", re.I)
_CONECT = re.compile(r"(?:^|[,\s])(?:para|con el objeto de|con el objetivo de|a fin de|con el prop[óo]sito de|con el fin de|en materia de|en cuanto a|"
                     r"en lo relativo a|en lo tocante a|en relaci[óo]n con|con la finalidad de|respecto de)\s+(?P<fin>.+)$", re.I)
_VACIAS = {"de", "la", "el", "en", "y", "para", "que", "a", "los", "las", "del", "al", "por", "con", "un", "una", "o", "e", "su", "sus", "lo", "se"}


def h(clave: str) -> int:
    return zlib.crc32(clave.encode("utf-8"))


_FUERTES = [" – ", " - ", " (", " Tramo ", ", ", " y ", " e ", " que ", " para ", " con el objeto", " con el fin", " a fin de", " en materia", " respecto", " cuando ", " sin "]
_DEBILES = [" de la ", " del ", " de los ", " de las ", " de ", " en la ", " en el ", " en ", " con ", " por ", " sobre ", " a la ", " al ", " a "]


def recortar(texto: str, n: int = 60, minimo: int = 24) -> str:
    """Recorta a ≤ n caracteres en el último límite de frase (coma, 'y', 'que', 'para'…) o de sintagma ('de', 'en'…); no añade '…' salvo
    como último recurso (sin ningún límite posible). Nunca corta a mitad de palabra ni termina en artículo/preposición."""
    texto = " ".join(texto.split())
    if len(texto) <= n:
        return texto
    ventana = texto[: n + 1]
    for delims in (_FUERTES, _DEBILES):
        pos = max((ventana.rfind(d, minimo) for d in delims), default=-1)
        if pos >= minimo:
            corte = texto[:pos].rstrip(" ,.;:()-")
            palabras = corte.split(" ")
            while len(palabras) > 1 and palabras[-1].lower() in _VACIAS:
                palabras.pop()
            corte = " ".join(palabras)
            if len(corte) >= minimo:
                return corte
    palabras = texto[: n - 1].split(" ")
    if not texto[n - 1].isspace():
        palabras = palabras[:-1]
    while len(palabras) > 1 and palabras[-1].lower().strip(",.;:") in _VACIAS:
        palabras.pop()
    return " ".join(palabras).rstrip(" ,.;:()-") + "…"


def unico(titulo: str, usados: set, sufijo: str, n: int = 60) -> str:
    """Garantiza títulos únicos: si ya existe, recorta el original para dejar sitio a ' (sufijo)' (boletín corto o comuna)."""
    if titulo not in usados:
        usados.add(titulo)
        return titulo
    suf = f" ({sufijo})"
    nuevo = recortar(titulo, n - len(suf)) + suf
    k = 2
    while nuevo in usados:
        nuevo = recortar(titulo, n - len(suf) - 2) + f" {k}" + suf
        k += 1
    usados.add(nuevo)
    return nuevo


_PERSONA = re.compile(r"(?:\b(?:a la|al|a)\s+)?\b(?:señora|señor|señorita|doña|don)\s+[A-ZÁÉÍÓÚÑ].*$", re.U)
_INICIADO = re.compile(r"^Iniciado en moci[óo]n de .*?proyecto de ley,?\s*(?:que\s+)?", re.I)


def anonimizar(titulo: str) -> str:
    """Los títulos que nombran a una persona natural (gracia de nacionalidad, homenajes) se publican sin el nombre; los nombres de
    legisladores autores ('Iniciado en moción de…') también se omiten."""
    t = " ".join(titulo.split())
    t = _INICIADO.sub("", t)
    t = t[:1].upper() + t[1:]
    return _PERSONA.sub(lambda m: ("a " if m.group(0).lower().startswith(("a ", "al ")) else "") + "persona natural (nombre omitido)", t)


def resumir_titulo(titulo: str) -> str:
    """Título legal largo -> ≤60 caracteres con el sentido ('Ley 18.700: reducir plazos…'); el completo va en meta.titulo_completo."""
    t = anonimizar(" ".join(titulo.split()).rstrip("."))
    if len(t) <= 60:
        return t
    t = _INI_LEY.sub("", t)
    m = _MOD.match(t)
    if m:
        if m.group("ley"):
            pref = ("DL " if m.group("ley").lower().startswith(("decreto ley", "dl")) else "DFL " if m.group("ley").lower().startswith(("decreto con", "dfl")) else "Ley ") + m.group("num").rstrip(".")
        elif m.group("cod"):
            pref = m.group("cod").strip()
        else:
            pref = "Constitución"
        fin = _CONECT.search(m.group("resto"))
        if fin:
            cuerpo = fin.group("fin").strip()
            return recortar(f"{pref}: {cuerpo[0].lower() + cuerpo[1:]}")
        return recortar(f"Modifica {pref}" + (f": {m.group('resto').strip(' ,')}" if m.group("resto").strip(" ,") else ""))
    return recortar(t[0].upper() + t[1:])


def categoria_titulo(titulo: str) -> str:
    for c, rx in _RX:
        if rx.search(titulo):
            return c
    return "politica"


def categoria_proyecto_ley(b: dict, es_reforma: bool) -> str:
    """Ministerio afín: primer tema real; 'otro' -> palabras del título; reformas constitucionales sin tema sectorial -> politica."""
    for tema in b.get("tema") or []:
        if tema in TEMA_CAT:
            return TEMA_CAT[tema]
    if es_reforma or "constitucional" in (b.get("tema") or []):
        c = categoria_titulo(b["titulo"])
        return c if c in ("descentralizacion", "hacienda", "educacion", "salud", "seguridad") else "politica"
    return categoria_titulo(b["titulo"])


def _rango(clave: str, opciones: list) -> tuple:
    return opciones[h(clave) % len(opciones)]


ETAPA_AVANZADA = re.compile(r"Segundo trámite|Tercer trámite|Comisión Mixta|Insistencia|insistencia|Tribunal Constitucional|aprobacion presidencial|finalización|C\.Mixta", re.I)


def disp_ley(b: dict, tipo: str, q: float) -> dict:
    """Años de gobierno (1-4) en que la carta de un proyecto de ley circula. q = antigüedad relativa del boletín dentro de los
    proyectos en tramitación (0 = el más reciente, 1 = el más antiguo; casi todos ingresaron en 2026, por eso es relativa).
    Discusión inmediata -> 1; suma -> 1-2; simple o trámite avanzado -> 1-3; recientes (q<0,35) -> 1-2;
    intermedios -> 2-4; antiguos (q>0,65) -> 3-4; reformas constitucionales (largo aliento) -> 2-4."""
    urg, etapa, k = b.get("urgencia_actual", "Sin urgencia"), b.get("etapa", ""), b["boletin"]
    if urg == "Discusión inmediata":
        d, a = 1, 1
    elif urg == "Suma":
        d, a = _rango(k, [(1, 1), (1, 2)])
    elif urg == "Simple" or ETAPA_AVANZADA.search(etapa):
        d, a = _rango(k, [(1, 2), (1, 2), (1, 3), (2, 2)])
    elif tipo == "reforma_constitucional":
        d, a = _rango(k, [(2, 4), (2, 3), (3, 4), (2, 2), (3, 3)])
    elif q < 0.35:
        d, a = _rango(k, [(1, 2), (1, 2), (1, 3), (2, 2), (1, 1)])
    elif q < 0.65:
        d, a = _rango(k, [(2, 3), (2, 4), (2, 3), (3, 3), (1, 3)])
    else:
        d, a = _rango(k, [(3, 4), (3, 4), (4, 4), (3, 3), (2, 4)])
    return {"anio_desde": d, "anio_hasta": a, "evento": None, "fiscal_min": None, "meta": None}


def disp_obra(p: dict, inv, modo: str) -> dict:
    """Obras: licitación/diseño -> años 1-3; perfil/idea -> años 2-4 y 3-4; en ejecución ('acelerar') -> hasta el año de término
    real (fecha_fin) o ventana 1-3; terminadas ('inaugurar') -> 1-2 (ya no tiene sentido tarde). Megaproyectos (>= 500 MUSD) con fiscal_min."""
    k, est = p["id"], p["estado"]
    if modo == "inauguracion":
        fin = (p.get("fecha_fin") or "0000")[:4]
        d, a = (1, 1) if fin >= "2025" else _rango(k, [(1, 2), (1, 2), (2, 2), (2, 3)])
    elif modo == "acelerar":
        fin = p.get("fecha_fin")
        if fin and fin[:4].isdigit():
            a = max(1, min(4, int(fin[:4]) - 2026 + 1))
            d = 1 if a <= 2 else _rango(k, [(1, a), (2, a)])[0]
        else:
            d, a = _rango(k, [(1, 3), (1, 2), (2, 4), (1, 4)])
    elif est == "licitacion":
        d, a = _rango(k, [(1, 2), (1, 3)])
    elif est == "diseno":
        d, a = _rango(k, [(1, 3), (2, 4), (1, 4), (2, 3)])
    elif est in ("perfil", "prefactibilidad"):
        d, a = _rango(k, [(2, 4), (3, 4), (2, 3)])
    else:  # idea
        d, a = _rango(k, [(3, 4), (4, 4)])
    fiscal = None
    if inv is not None and inv >= 500 and modo != "inauguracion":
        fiscal = 55 if inv < 1000 else 60 if inv < 2000 else 65  # indicador fiscal 0-100 (inicial 67)
    return {"anio_desde": d, "anio_hasta": max(a, d), "evento": None, "fiscal_min": fiscal, "meta": None}
