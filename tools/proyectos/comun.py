"""Utilidades comunes de los scrapers de proyectos públicos (data/proyectos/*.json).

Esquema de registro (todas las claves siempre presentes; null si no hay dato, nunca se inventan cifras):
id, nombre, sector, region_id, region_ids, comuna, estado, estado_2026_03_11, inversion_musd, inversion_uf, inversion_clp,
fecha_inicio, fecha_fin, mandante, descripcion, fuente_url, fuente, fecha_consulta, verificado, notas
Fechas: 'YYYY-MM-DD', 'YYYY-MM', 'YYYY', 'YYYY-Qn', 'YYYY-S1/S2' o null (estimadas o hitos oficiales).
"""
import html
import json
import re
import time
import unicodedata
from datetime import date
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[2]
SALIDA = ROOT / "data" / "proyectos"
ESTADOS = ("idea", "perfil", "prefactibilidad", "diseno", "licitacion", "ejecucion", "terminado", "abandonado")
CLAVES = ("id", "nombre", "sector", "region_id", "region_ids", "comuna", "estado", "estado_2026_03_11", "inversion_musd",
          "inversion_uf", "inversion_clp", "fecha_inicio", "fecha_fin", "mandante", "descripcion", "fuente_url", "fuente", "fecha_consulta",
          "verificado", "notas")
HOY = date.today().isoformat()

REGIONES = {  # nombre normalizado -> id de data/regiones.json
    "arica y parinacota": "arica", "arica": "arica", "tarapaca": "tarapaca", "antofagasta": "antofagasta",
    "atacama": "atacama", "coquimbo": "coquimbo", "valparaiso": "valparaiso", "metropolitana": "metropolitana",
    "region metropolitana": "metropolitana", "santiago": "metropolitana",
    "libertador general bernardo o'higgins": "ohiggins", "libertador general bernardo ohiggins": "ohiggins",
    "o'higgins": "ohiggins", "ohiggins": "ohiggins", "maule": "maule", "nuble": "nuble", "biobio": "biobio",
    "la araucania": "araucania", "araucania": "araucania", "los rios": "losrios", "los lagos": "loslagos",
    "aysen": "aysen", "aysen del general carlos ibanez del campo": "aysen",
    "magallanes": "magallanes", "magallanes y antartica chilena": "magallanes", "magallanes y la antartica chilena": "magallanes",
}


def norm(txt):
    t = unicodedata.normalize("NFD", html.unescape(txt or "")).lower()
    t = "".join(c for c in t if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", t.replace("’", "'")).strip(" .,;")


def regiones_de(texto):
    """'Ñuble, Biobío y La Araucanía' -> ['nuble','biobio','araucania'] (orden de aparición)."""
    partes = re.split(r",|\sy\s(?=[A-ZÁÉÍÓÚÑa-z])|/", html.unescape(texto or ""))
    out = []
    for p in partes:
        p = re.sub(r"^(region|regiones)( de| del)?( la)? ", "", norm(p)).strip()
        p = re.sub(r"^(de|del) ", "", p)
        for cand in (p, "la " + p):
            if cand in REGIONES and REGIONES[cand] not in out:
                out.append(REGIONES[cand])
                break
    return out


def get(url, intentos=3, espera=2.0, binario=False):
    for k in range(intentos):
        try:
            req = Request(url, headers={"User-Agent": "Mozilla/5.0 (investigacion de datos abiertos del proyecto)"})
            with urlopen(req, timeout=60) as r:
                dato = r.read()
                return dato if binario else dato.decode("utf-8", "ignore")
        except Exception:
            if k == intentos - 1:
                raise
            time.sleep(espera * (k + 1))


def get_json(url):
    return json.loads(get(url))


def texto_plano(h):
    h = re.sub(r"(?is)<(script|style)[^>]*>.*?</\1>", " ", h or "")
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", h))).strip()


def registro(**kw):
    r = {k: None for k in CLAVES}
    r["region_ids"] = []
    r["verificado"] = False
    r["fecha_consulta"] = HOY
    r.update(kw)
    if r["region_id"] is None and r["region_ids"]:
        r["region_id"] = r["region_ids"][0]
    if r["region_id"] and r["region_id"] not in r["region_ids"]:
        r["region_ids"] = [r["region_id"]] + list(r["region_ids"])
    extra = set(kw) - set(CLAVES)
    if extra:
        raise KeyError(extra)
    return r


def slug(txt, n=60):
    s = re.sub(r"[^a-z0-9]+", "-", norm(txt)).strip("-")
    return s[:n].strip("-")


def num_es(txt):
    """'14.215.000' -> 14215000.0 ; '79,7' -> 79.7"""
    t = txt.strip()
    if re.fullmatch(r"\d{1,3}(\.\d{3})+(,\d+)?", t):
        t = t.replace(".", "").replace(",", ".")
    else:
        t = t.replace(",", ".")
    try:
        return float(t)
    except ValueError:
        return None


def montos(txt):
    """Extrae (inversion_uf, inversion_musd) de textos como 'UF 14.215.000 (MM USD 596)' o 'MM USD 500'. Solo cifras explícitas."""
    uf = usd = None
    t = html.unescape(txt or "")
    m = re.search(r"UF\s*([\d\.,]+)", t)
    if m:
        uf = num_es(m.group(1).rstrip(".,"))
    m = re.search(r"(?:MM\s*US\$?\s*D?|MMUS\$|MM\s*USD)\s*([\d\.,]+)", t, re.I)
    if m:
        usd = num_es(m.group(1).rstrip(".,"))
    return uf, usd


MESES = {"enero": 1, "febrero": 2, "marzo": 3, "abril": 4, "mayo": 5, "junio": 6, "julio": 7, "agosto": 8,
         "septiembre": 9, "setiembre": 9, "octubre": 10, "noviembre": 11, "diciembre": 12}


def fecha_es(txt):
    """'13 de abril de 2006' -> '2006-04-13'; 'Primer Trimestre 2027' -> '2027-Q1'; '2028' -> '2028'; si no -> None."""
    t = norm(txt)
    m = re.search(r"(\d{1,2}) de (\w+) de (\d{4})", t)
    if m and m.group(2) in MESES:
        return f"{m.group(3)}-{MESES[m.group(2)]:02d}-{int(m.group(1)):02d}"
    m = re.search(r"(primer|segundo|tercer|cuarto|ultimo) trimestre(?: de)? (\d{4})", t)
    if m:
        q = {"primer": 1, "segundo": 2, "tercer": 3, "cuarto": 4, "ultimo": 4}[m.group(1)]
        return f"{m.group(2)}-Q{q}"
    m = re.search(r"(?:^|\D)((?:19|20)\d{2})(?:\D|$)", t)
    return m.group(1) if m and len(t) <= 12 else None


def guardar(nombre, registros, meta):
    SALIDA.mkdir(parents=True, exist_ok=True)
    ids = [r["id"] for r in registros]
    if len(ids) != len(set(ids)):
        raise ValueError(f"{nombre}: ids duplicados")
    for r in registros:
        if r["estado"] not in ESTADOS:
            raise ValueError(f"{r['id']}: estado inválido {r['estado']}")
    registros = sorted(registros, key=lambda r: r["id"])
    ruta = SALIDA / f"{nombre}.json"
    ruta.write_text(json.dumps({"meta": meta, "proyectos": registros}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{ruta.relative_to(ROOT)}: {len(registros)} proyectos")


def registrar_fuente(fid, institucion, titulo, url, vigencia_dias=180, fecha_corte=None):
    """Inserta o actualiza una fuente en data/fuentes.json (formato existente)."""
    ruta = ROOT / "data" / "fuentes.json"
    fuentes = json.loads(ruta.read_text(encoding="utf-8"))
    nueva = {"id": fid, "institucion": institucion, "titulo": titulo, "url": url, "fecha_corte": fecha_corte or HOY,
             "vigencia_dias": vigencia_dias, "es_ilustrativa": False, "verificado_contra_texto": False}
    for i, f in enumerate(fuentes):
        if f["id"] == fid:
            fuentes[i] = nueva
            break
    else:
        fuentes.append(nueva)
    ruta.write_text(json.dumps(fuentes, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
