"""Efectos ilustrativos y costo de las cartas de proyectos de ley, derivados del tema (ministerio), la iniciativa (mensaje/moción), la
urgencia, la etapa y palabras clave del título legal. Deterministas (crc32 del boletín); todas las magnitudes son ilustrativas
(meta.cifras_ilustrativas)."""
import re

from cartas_util import ETAPA_AVANZADA, h

# (indicador principal, base) y secundario posible por ministerio; el boletín decide cuál secundario entra.
PRINCIPAL = {"seguridad": ("aprobacion", 2.5), "hacienda": ("fiscal", 1.0), "social": ("aprobacion", 2.5), "salud": ("aprobacion", 3.0),
             "educacion": ("aprobacion", 2.5), "vivienda": ("aprobacion", 3.0), "energia": ("aprobacion", 1.5), "economia": ("aprobacion", 1.5),
             "transportes": ("aprobacion", 2.0), "medioambiente": ("aprobacion", 2.0), "descentralizacion": ("cohesion", 1.5),
             "politica": ("capital", 1.0), "obras": ("aprobacion", 2.0)}
SECUNDARIOS = {"seguridad": [("cohesion", -0.5), ("capital", 0.5), ("riesgo_ejecucion", 1.0)], "hacienda": [("aprobacion", -1.0), ("capital", 0.5), ("cohesion", -0.5)],
               "social": [("cohesion", 1.0), ("capital", 0.5)], "salud": [("cohesion", 0.5), ("riesgo_ejecucion", 1.0)],
               "educacion": [("cohesion", 0.5), ("capital", 0.5), ("riesgo_ejecucion", 1.0)], "vivienda": [("cohesion", 0.5), ("riesgo_ejecucion", 1.0)],
               "energia": [("cohesion", -0.5), ("capital", 0.5)], "economia": [("fiscal", 0.5), ("cohesion", -0.5), ("capital", 0.5)],
               "transportes": [("cohesion", 0.5), ("riesgo_ejecucion", 0.5)], "medioambiente": [("cohesion", 0.5), ("capital", -0.5)],
               "descentralizacion": [("aprobacion", 1.0), ("capital", 0.5)], "politica": [("cohesion", -0.5), ("aprobacion", 1.0)],
               "obras": [("fiscal", -0.5), ("cohesion", 0.5)]}
BAJO_IMPACTO = re.compile(r"nacionalidad|ciudadan[ií]a por gracia|especial gracia|monumento|homenaje|feriado|d[ií]a nacional|conmemor|"
                          r"^aprueba (?:el |la |los |las )?(?:acuerdo|convenio|tratado|protocolo|enmienda|memor[aá]ndum)|"
                          r"^implementa el protocolo|^aprueba las enmiendas|denomina|declara", re.I)
GASTO = re.compile(r"subsidio|bono\b|beneficio|gratuid|pensi[oó]n|garant[ií]a|reajuste|financiamiento|crea (?:el |la |un |una )?(?:servicio|agencia|fondo|programa|sistema|instituto|subsecretar|superintendencia|defensor)|"
                   r"fondo|aporte|transfer|plan\b|cobertura|subvenci", re.I)
INSTITUCION = re.compile(r"crea (?:el |la |un |una )?(?:servicio|agencia|instituto|subsecretar|superintendencia|defensor|consejo|sistema)|reorganiza|fusiona|institucional", re.I)
IMPUESTO = re.compile(r"impuesto|tributari|royalty|arancel|exenci[oó]n|cotizaci[oó]n|contribuciones", re.I)
ALIVIO = re.compile(r"rebaja|exime|elimina|suprime|disminuy|reduc|deroga|rebajar|eximir|exenci[oó]n", re.I)
PENAL = re.compile(r"\bpena|delito|penal|agrava|tipific|c[aá]rcel|prisi[oó]n|sanciona|prohíbe|prohibe", re.I)


def es_bajo_impacto(titulo: str) -> bool:
    return BAJO_IMPACTO.search(titulo) is not None


def _r(x: float) -> float:
    return round(x * 2) / 2


def efectos_y_costo(b: dict, tipo: str, cat: str) -> tuple:
    """(efectos, costo 1-3). Mensaje (Ejecutivo): más aprobación y menos capital político; moción: más cohesión pero cuesta más capital.
    Urgencia amplifica; trámite avanzado abarata el capital. Palabras clave del título añaden fiscal / riesgo / aprobación."""
    k, titulo, urg = b["boletin"], b["titulo"], b.get("urgencia_actual", "Sin urgencia")
    mensaje, avanzado = b.get("iniciativa") == "mensaje", ETAPA_AVANZADA.search(b.get("etapa", "")) is not None
    if es_bajo_impacto(titulo):
        fx = {"aprobacion": 0.5 + (h(k + "a") % 2) * 0.5, "capital": -0.5}
        if h(k) % 2:
            fx["cohesion"] = 0.5  # gestos simbólicos: sin costo fiscal, impacto mínimo
        return _lista(fx), 1
    ind, base = PRINCIPAL.get(cat, PRINCIPAL["politica"])
    mult = {"Discusión inmediata": 1.6, "Suma": 1.4, "Simple": 1.2}.get(urg, 1.0) * (1.15 if avanzado else 1.0) * (1.15 if mensaje else 0.9)
    jitter = ((h(k) % 5) - 2) * 0.25
    fx = {ind: base * mult + jitter}
    sec, dsec = SECUNDARIOS.get(cat, SECUNDARIOS["politica"])[h(k + "s") % len(SECUNDARIOS.get(cat, SECUNDARIOS["politica"]))]
    fx[sec] = fx.get(sec, 0.0) + dsec * (1.0 + (h(k + "m") % 3) * 0.25)
    cap = -(1.0 if mensaje else 1.5) * (0.6 if avanzado else 1.0) * (1.3 if urg in ("Discusión inmediata", "Suma") else 1.0)
    fx["capital"] = fx.get("capital", 0.0) + cap
    fx["cohesion"] = fx.get("cohesion", 0.0) + (-0.5 if mensaje else 0.5)
    if IMPUESTO.search(titulo):
        fx["fiscal"] = fx.get("fiscal", 0.0) + (-1.0 if ALIVIO.search(titulo) else 1.0 + (h(k + "i") % 2) * 0.5)
        fx["aprobacion"] = fx.get("aprobacion", 0.0) + (1.0 if ALIVIO.search(titulo) else -1.0)
    elif GASTO.search(titulo):
        fx["fiscal"] = fx.get("fiscal", 0.0) - (0.5 + (h(k + "g") % 4) * 0.5)
    if INSTITUCION.search(titulo):
        fx["riesgo_ejecucion"] = fx.get("riesgo_ejecucion", 0.0) + 1.0
    if PENAL.search(titulo) and cat in ("seguridad", "politica"):
        fx["aprobacion"] = fx.get("aprobacion", 0.0) + 0.5
    if tipo != "ley_simple":
        fx["capital"] = fx.get("capital", 0.0) - 1.0  # reformas y LOC exigen quórum reforzado
    costo = 3 if tipo != "ley_simple" else 1 if urg in ("Discusión inmediata", "Suma") else 3 if (GASTO.search(titulo) and INSTITUCION.search(titulo)) else 2
    return _lista(fx), costo


def _lista(fx: dict) -> list:
    res = [{"ind": i, "delta": max(-5.0, min(5.0, _r(d)))} for i, d in sorted(fx.items()) if _r(d) != 0]
    return res or [{"ind": "capital", "delta": -0.5}]
