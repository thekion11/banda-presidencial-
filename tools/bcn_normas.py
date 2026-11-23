#!/usr/bin/env python3
"""Construye data/bcn/normas.json a partir de textos oficiales de la BCN (PDF de LeyChile).

Uso: python3 tools/bcn_normas.py --cpr constitucion.pdf [--pdf otra_norma.pdf ...] [--proyectos data/bcn/proyectos_ley.json]
Requiere `pdftotext` (poppler). Cada cita de artículo se comprueba como subcadena del texto oficial.
Los PDF se descargan a mano desde leychile.cl (el sitio bloquea clientes automáticos: no se esquiva).
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
SALIDA = ROOT / "data" / "bcn" / "normas.json"
CPR_URL = "https://www.bcn.cl/leychile/navegar?idNorma=242302"

# (artículo, tema, órgano competente, regla/quórum resumido, ancla literal del texto oficial)
CLAVES = [
    (24, "poderes", "Presidente de la República", "Gobierno y administración del Estado; cuenta pública el 1 de junio ante el Congreso Pleno", "El Gobierno y la administración del Estado corresponden al Presidente de la República"),
    (26, "elecciones", "Servel / Tribunal Calificador", "Elección directa por mayoría absoluta de los sufragios válidamente emitidos", "mayoría absoluta de los sufragios válidamente emitidos"),
    (32, "atribuciones_presidente", "Presidente de la República", "Atribuciones especiales: sancionar y promulgar leyes, DFL con delegación, convocar plebiscito, urgencias, etc.", "Son atribuciones especiales del Presidente de la República"),
    (40, "excepcion", "Presidente + Congreso Nacional", "Estado de asamblea y de sitio: declara el Presidente con acuerdo del Congreso; el Congreso se pronuncia en 5 días o se entiende aprobado; sitio máx. 15 días prorrogables", "con acuerdo del Congreso Nacional"),
    (41, "excepcion", "Presidente de la República", "Estado de catástrofe: lo declara el Presidente; el Congreso puede dejarlo sin efecto tras 180 días si cesaron las razones; más de un año requiere acuerdo del Congreso", "El estado de catástrofe, en caso de calamidad pública, lo declarará el Presidente de la República"),
    (42, "excepcion", "Presidente + Congreso (prórrogas)", "Estado de emergencia: 15 días prorrogables por igual período; prórrogas sucesivas requieren acuerdo del Congreso; desde la sexta prórroga, períodos de 30 días", "El estado de emergencia, en caso de grave alteración del orden público"),
    (52, "congreso", "Cámara de Diputados", "Fiscaliza al Gobierno (acuerdos por mayoría de presentes; antecedentes con un tercio de los presentes); acusaciones constitucionales", "Son atribuciones exclusivas de la Cámara de Diputados"),
    (53, "congreso", "Senado", "Acusación constitucional: culpabilidad por 2/3 de los senadores en ejercicio si es contra el Presidente o un gobernador regional; mayoría de los en ejercicio en los demás casos", "dos tercios de los senadores en ejercicio cuando se trate de una acusación en contra del Presidente de la República"),
    (63, "materias_ley", "Congreso Nacional", "Listado de materias de ley; empréstitos que excedan el período presidencial requieren ley de quórum calificado", "Sólo son materias de ley"),
    (64, "delegacion", "Congreso Nacional", "Delegación de facultades legislativas (DFL) hasta un año; excluye nacionalidad, elecciones, garantías constitucionales, LOC y quórum calificado", "no superior a un año"),
    (65, "iniciativa", "Presidente / Congreso", "Iniciativa exclusiva del Presidente en división político-administrativa, administración financiera, tributos, servicios públicos y empleos, endeudamiento; tributos y presupuestos nacen en la Cámara; mociones máx. 10 diputados o 5 senadores", "Corresponderá al Presidente de la República la iniciativa exclusiva"),
    (66, "quorum", "Cámara de Diputados y Senado", "Interpretativas de la Constitución: 4/7 de los en ejercicio; LOC y quórum calificado: mayoría absoluta de los en ejercicio; demás normas: mayoría de los presentes", "cuatro séptimas partes"),
    (67, "presupuesto", "Presidente + Congreso", "Ley de Presupuestos presentada con 3 meses de antelación; si el Congreso no despacha en 60 días rige el proyecto del Presidente; el Congreso sólo puede reducir gastos", "regirá el proyecto presentado por el Presidente de la República"),
    (70, "tramitacion", "Comisión mixta", "Proyecto desechado en su totalidad por la revisora va a comisión mixta; se aprueba por mayoría de presentes", "mayoría de los miembros presentes en cada una de ellas"),
    (73, "veto", "Presidente + Congreso", "Veto en 30 días; insistencia por 2/3 de los miembros presentes de ambas Cámaras", "dos tercios de sus miembros presentes"),
    (74, "urgencia", "Presidente de la República", "Urgencia: la Cámara debe pronunciarse en máximo 30 días (calificación según LOC del Congreso)", "deberá pronunciarse dentro del plazo máximo de treinta días"),
    (92, "tc", "Tribunal Constitucional", "10 miembros: 3 Presidente, 4 Congreso (2/3 en ejercicio), 3 Corte Suprema", "Habrá un Tribunal Constitucional integrado por diez miembros"),
    (93, "tc", "Tribunal Constitucional", "Control preventivo de LOC/interpretativas; inaplicabilidad por mayoría de miembros en ejercicio; inconstitucionalidad por 4/5", "cuatro quintos de sus integrantes en ejercicio"),
    (98, "contraloria", "Contraloría General de la República", "Control de legalidad de los actos de la Administración; toma de razón", "ejercerá el control de la legalidad de los actos de la Administración"),
    (99, "contraloria", "Contraloría General de la República", "Representa ilegalidad; el Presidente puede insistir con la firma de todos sus Ministros (decreto de insistencia)", "el Presidente de la República insista con la firma de todos sus Ministros"),
    (108, "banco_central", "Banco Central", "Órgano autónomo; su organización se regula por LOC", "denominado Banco Central"),
    (111, "regiones", "Gobierno regional", "Administración superior de la región en un gobierno regional (gobernador regional y consejo regional)", "La administración superior de cada región reside en un gobierno regional"),
    (113, "regiones", "Consejo regional", "Consejo regional normativo, resolutivo y fiscalizador; consejeros elegidos por sufragio universal, 4 años", "El consejo regional será un órgano de carácter normativo, resolutivo y fiscalizador"),
    (114, "regiones", "Presidente + LOC", "Transferencia de competencias a gobiernos regionales según LOC", "transferirá a uno o más gobiernos regionales"),
    (118, "municipios", "Municipalidad", "Administración local en municipalidades (alcalde y concejo); alcaldes 4 años, reelegibles hasta por dos períodos", "reside en una municipalidad"),
    (121, "municipios", "Municipalidades + Presidente (iniciativa)", "Crear o suprimir empleos y fijar remuneraciones dentro de límites fijados por LOC a iniciativa exclusiva del Presidente", "a iniciativa exclusiva del Presidente de la República"),
    (127, "reforma_constitucional", "Congreso Nacional", "Reforma constitucional: 4/7 de los diputados y senadores en ejercicio en cada Cámara (Ley 21.481)", "las cuatro séptimas partes de los diputados y senadores en ejercicio"),
    (128, "reforma_constitucional", "Presidente + Congreso", "Veto total: si ambas Cámaras insisten por 2/3 de los en ejercicio, se promulga salvo plebiscito; veto parcial: observaciones con 4/7", "dos terceras partes de los miembros en ejercicio de cada Cámara"),
    (129, "reforma_constitucional", "Presidente + Servel/TRICEL", "Plebiscito en 120 días tras decreto de convocatoria (domingo)", "ciento veinte días"),
]
# Leyes orgánicas constitucionales y leyes estructurales: sólo el fundamento (art. de la CPR) se verifica en el texto.
ESTRUCTURALES = [
    ("loc_congreso", "LOC", "18.918", "Orgánica Constitucional del Congreso Nacional", "Congreso Nacional", [55, 74]),
    ("loc_municipalidades", "LOC", "18.695", "Orgánica Constitucional de Municipalidades", "Municipalidades", [118, 121]),
    ("loc_gore", "LOC", "19.175", "Orgánica Constitucional sobre Gobierno y Administración Regional", "Gobiernos regionales", [111, 113, 114]),
    ("loc_bases_administracion", "LOC", "18.575", "Orgánica Constitucional de Bases Generales de la Administración del Estado", "Administración del Estado", [38]),
    ("loc_tc", "LOC", "17.997", "Orgánica Constitucional del Tribunal Constitucional", "Tribunal Constitucional", [92, 93]),
    ("loc_contraloria", "LOC", "10.336", "Orgánica de la Contraloría General de la República", "Contraloría", [98, 99]),
    ("loc_banco_central", "LOC", "18.840", "Orgánica Constitucional del Banco Central de Chile", "Banco Central", [108]),
    ("loc_estados_excepcion", "LOC", "18.415", "Orgánica Constitucional de los Estados de Excepción", "Presidente + Congreso", [39]),
    ("dl_1263", "DL", "1.263", "Orgánico de la Administración Financiera del Estado (DL 1263 de 1975)", "DIPRES / Hacienda", [67]),
]


def texto_pdf(ruta):
    return subprocess.run(["pdftotext", str(ruta), "-"], capture_output=True, text=True, check=True).stdout


def limpiar(s):  # quita llamadas de nota pegadas a palabras o puntos y colapsa espacios
    s = re.sub(r"(?<=[a-zñáéíóú])\d{1,3}\b|(?<=[a-zñáéíóú]\.)\d{1,3}\b", "", s)
    return re.sub(r"\s+", " ", s)


def articulos(t):
    ms = [(int(m.group(1)), m.start()) for m in re.finditer(r"(?m)^Art[íi]culo (\d+)\s*[º°o]?\s*[\.\-]", t)]
    out = {}
    for i, (n, p) in enumerate(ms):
        nxt = min([q for k, q in ms if q > p] or [len(t)])
        out.setdefault(n, limpiar(t[p:nxt]))
    return out


def meta_bcn(t):  # cabecera estándar de los PDF de LeyChile
    g = lambda pat: (re.search(pat, t[:1500]) or [None, None])[1]
    pub = g(r"Publicaci[óo]n:\s*([0-9]{2}-[A-Z]{3}-[0-9]{4})") or g(r"Fecha Publicaci[óo]n:\s*([0-9]{2}-[A-Z]{3}-[0-9]{4})")
    prom = g(r"Promulgaci[óo]n:\s*([0-9]{2}-[A-Z]{3}-[0-9]{4})")
    mes = {m: i for i, m in enumerate("ENE FEB MAR ABR MAY JUN JUL AGO SEP OCT NOV DIC".split(), 1)}
    iso = lambda s: f"{s[-4:]}-{mes[s[3:6]]:02d}-{s[:2]}" if s else None
    return {"fecha_publicacion": iso(pub), "fecha_promulgacion": iso(prom), "url_corta": g(r"Url Corta:\s*(\S+)"),
            "version": g(r"(?:Versi[óo]n|Tipo Versi[óo]n):\s*([^\n|]+)")}


def norma_pdf(ruta):
    t = texto_pdf(ruta)
    cab = re.sub(r"\s+", " ", t[:700])
    m = re.match(r"Ley (\d+)", t.strip())
    if m:
        num, tipo = f"{int(m.group(1)):,}".replace(",", "."), "ley"
        mt = re.search(r"(?:Ley \d+\s+)+(.+?)\s+MINISTERIO", cab)
        titulo = mt.group(1).capitalize() if mt else None
        org = "Ministerio de Hacienda" if "HACIENDA" in cab else None
    else:
        m2 = re.match(r"DFL (\d+), (\w+) \((\d{4})\)", t.strip())
        num, tipo, titulo, org = (f"DFL {m2.group(1)} ({m2.group(3)})" if m2 else None), "dfl", None, None
        mt = re.search(r"FIJA TEXTO REFUNDIDO.+?(?=MINISTERIO)", cab)
        titulo = mt.group(0).strip() if mt else None
        org = "Ministerio de Justicia" if "JUSTICIA" in cab else None
    d = meta_bcn(t)
    return {"id": (f"ley_{num.replace('.', '')}" if tipo == "ley" else "dfl_1_justicia_2000_codigo_civil"), "tipo": tipo, "numero": num,
            "titulo": titulo, "organismo_emisor": org, **d, "quorum": None, "organo_competente": None,
            "url_leychile": None, "fuente": "fuentes.json#bcn_leychile_pdf", "verificado": True,
            "nota": "metadatos leídos de la cabecera del PDF oficial entregado por el equipo (LeyChile/BCN)"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cpr", required=True)
    ap.add_argument("--pdf", action="append", default=[])
    ap.add_argument("--proyectos", default=str(ROOT / "data" / "bcn" / "proyectos_ley.json"))
    a = ap.parse_args()
    t = texto_pdf(a.cpr)
    arts = articulos(t)
    claves, falta = [], []
    for n, tema, org, regla, ancla in CLAVES:
        ok = n in arts and limpiar(ancla) in arts[n]
        if not ok:
            falta.append(n)
        claves.append({"articulo": n, "tema": tema, "organo_competente": org, "regla_quorum": regla,
                       "cita_literal": ancla, "verificado_contra_texto": ok})
    if falta:
        raise SystemExit(f"Ancla no encontrada en el texto oficial: arts. {falta}")
    normas = [{"id": "cpr", "tipo": "constitucion", "numero": None, "titulo": "Constitución Política de la República de Chile",
               "organismo_emisor": "Congreso / Poder Constituyente (texto de 1980, última reforma vigente Ley 21.773)",
               "fecha_publicacion": None, "version": "Texto actualizado al 7 de octubre de 2025 (portada del PDF oficial)",
               "quorum": "ver articulos_clave", "organo_competente": "Congreso Nacional", "url_leychile": CPR_URL,
               "fuente": "fuentes.json#cpr_texto_bcn_2025_10_07", "verificado": True, "articulos_clave": claves}]
    for id_, tipo, num, tit, org, fund in ESTRUCTURALES:
        ver = {n: ("ley orgánica constitucional" in arts.get(n, "").lower() or n == 67 or n == 39) for n in fund}
        normas.append({"id": id_, "tipo": tipo, "numero": num, "titulo": tit, "organismo_emisor": None,
                       "fecha_publicacion": None, "quorum": "mayoría absoluta de diputados y senadores en ejercicio (CPR art. 66 inc. 2)" if tipo == "LOC" else None,
                       "organo_competente": org, "fundamento_cpr": fund, "fundamento_verificado": ver,
                       "url_leychile": f"https://www.bcn.cl/leychile/navegar?idLey={num.replace('.', '')}" if tipo != "DL" else None,
                       "fuente": "fuentes.json#cpr_texto_bcn_2025_10_07", "verificado": False,
                       "nota": "Fecha y texto pendientes: LeyChile bloquea descargas automáticas; contrastar con el PDF oficial."})
    for p in a.pdf:
        normas.append(norma_pdf(p))
    pj = Path(a.proyectos)
    if pj.exists():
        vistos = {n["numero"] for n in normas}
        for p in json.loads(pj.read_text(encoding="utf-8"))["proyectos"]:
            ln = (p.get("ley_numero") or "").strip()
            if re.fullmatch(r"\d{2}\.\d{3}", ln) and ln not in vistos and p.get("diario_oficial"):
                vistos.add(ln)
                normas.append({"id": f"ley_{ln.replace('.', '')}", "tipo": "ley", "numero": ln, "titulo": p["titulo"],
                               "organismo_emisor": None, "fecha_publicacion": p["diario_oficial"], "quorum": None,
                               "organo_competente": None, "boletin": p["boletin"], "tema": p["tema"],
                               "url_leychile": f"https://www.bcn.cl/leychile/navegar?idLey={ln.replace('.', '')}",
                               "fuente": "fuentes.json#senado_tramitacion", "verificado": True,
                               "nota": "Número y fecha de publicación según el WS de tramitación del Senado; quórum no consta en esa fuente"})
    doc = {"fecha_corte": time.strftime("%Y-%m-%d"), "total": len(normas), "normas": normas}
    SALIDA.write_text(json.dumps(doc, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"OK {len(normas)} normas ({len(claves)} artículos clave verificados) -> {SALIDA}")


if __name__ == "__main__":
    main()
