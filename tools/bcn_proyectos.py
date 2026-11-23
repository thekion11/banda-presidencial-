#!/usr/bin/env python3
"""Reúne proyectos de ley (boletines) desde los servicios públicos de la Cámara y el Senado.

Fuentes (API abiertas, sin clave):
  - Cámara: https://opendata.camara.cl/camaradiputados/WServices/WSLegislativo.asmx
  - Senado: https://tramitacion.senado.cl/wspublico/tramitacion.php?boletin=N

Uso: python3 tools/bcn_proyectos.py [--cache DIR] [--desde-mociones AAAA-MM-DD] [--anios-mensajes 2022,...]
Escribe data/bcn/proyectos_ley.json. No inventa datos: lo que el servicio no entrega queda en null.
Reproducible: con --cache reutiliza las respuestas ya descargadas.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import re
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SALIDA = ROOT / "data" / "bcn" / "proyectos_ley.json"
CAMARA = "https://opendata.camara.cl/camaradiputados/WServices/WSLegislativo.asmx/"
SENADO = "https://tramitacion.senado.cl/wspublico/tramitacion.php?boletin="
UA = "banda-presidencial-datos/1.0 (investigacion; datos publicos)"
NS = {"c": "http://opendata.camara.cl/camaradiputados/v1"}
TEMAS = [  # palabra clave en título/materias -> tema (heurística simple, documentada)
    ("pension|previsional|afp", "pensiones"), ("salud|isapre|fonasa|medicament", "salud"),
    ("educaci|escolar|universit|docente|sala cuna", "educacion"), ("vivienda|urban|suelo|campament|arriendo", "vivienda"),
    ("seguridad|delito|penal|policia|carabinero|crimen|armas|narco|migraci|extranjer", "seguridad"),
    ("tribut|impuesto|renta|fiscal|presupuest|hacienda|deuda", "hacienda"),
    ("energ|electric|combustible|hidrogeno|kerosene|gas", "energia"), ("ambient|agua|clima|residuos|biodiversidad|glaciar|sernap", "ambiente"),
    ("trabaj|laboral|sindical|empleo|salario|jornada", "trabajo"), ("transporte|vial|transito|ferrocarril|puerto|aeropuert", "transporte"),
    ("constituc|reforma constitucional|carta fundamental", "constitucional"), ("pesca|acuicultura|agric|forestal|riego", "agro_pesca"),
    ("municipal|regional|gobierno regional|descentraliz", "descentralizacion"), ("defensa|fuerzas armadas|militar", "defensa"),
    ("mujer|genero|nina|ninez|adolescente|familia|discapacidad|indigena|pueblos", "social"),
]


def bajar(url, cache, clave, pausa=0.25):
    ruta = cache / clave if cache else None
    if ruta and ruta.exists():
        return ruta.read_text(encoding="utf-8")
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for intento in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                txt = r.read().decode("utf-8", "replace")
            break
        except Exception as e:  # red inestable: reintentar con espera
            if intento == 3:
                print(f"[AVISO] falló {url}: {e}", file=sys.stderr)
                return ""
            time.sleep(2 * (intento + 1))
    if ruta:
        ruta.parent.mkdir(parents=True, exist_ok=True)
        ruta.write_text(txt, encoding="utf-8")
    time.sleep(pausa)
    return txt


def fecha_iso(dmy):
    m = re.match(r"(\d{2})/(\d{2})/(\d{4})", (dmy or "").strip())
    return f"{m.group(3)}-{m.group(2)}-{m.group(1)}" if m else None


def tema(titulo, materias):
    base = (titulo + " " + " ".join(materias)).lower()
    base = base.translate(str.maketrans("áéíóúñ", "aeioun"))
    return [t for pat, t in TEMAS if re.search(pat, base)] or ["otro"]


def listar_camara(tipo, anio, cache):
    op = "retornarMensajesXAnno" if tipo == "mensaje" else "retornarMocionesXAnno"
    raiz = ET.fromstring(bajar(f"{CAMARA}{op}?prmAnno={anio}", cache, f"camara_{op}_{anio}.xml", 1) or "<x/>")
    for p in raiz.findall("c:ProyectoLey", NS):
        g = lambda k: (p.findtext(f"c:{k}", default="", namespaces=NS) or "").strip()
        yield {"boletin": g("NumeroBoletin"), "nombre": g("Nombre"), "fecha": g("FechaIngreso")[:10],
               "tipo": tipo, "camara_origen": g("CamaraOrigen")}


def detalle_senado(boletin, cache):
    num = boletin.split("-")[0]
    txt = bajar(SENADO + num, cache, f"senado_{boletin}.xml")
    if not txt.strip().startswith("<"):
        return None
    try:
        raiz = ET.fromstring(txt)
    except ET.ParseError:
        return None
    for pr in raiz.findall("proyecto"):
        d = pr.find("descripcion")
        if d is not None and (d.findtext("boletin") or "").strip() == boletin:
            tr = pr.findall("tramitacion/tramite")
            ult = tr[-1] if tr else None
            return {
                "estado": (d.findtext("estado") or "").strip() or None,
                "etapa": (d.findtext("etapa") or "").strip() or None,
                "subetapa": (d.findtext("subetapa") or "").strip() or None,
                "urgencia_actual": (d.findtext("urgencia_actual") or "").strip() or None,
                "ley_numero": (d.findtext("leynro") or "").strip() or None,
                "diario_oficial": fecha_iso(d.findtext("diariooficial")) or ((d.findtext("diariooficial") or "").strip() or None),
                "autores": [a.text.strip() for a in pr.findall("autores/autor/PARLAMENTARIO") if a.text],
                "materias": [m.text.strip() for m in pr.findall("materias/materia/DESCRIPCION") if m.text],
                "ultimo_tramite": {"fecha": fecha_iso(ult.findtext("FECHA")), "descripcion": re.sub(r"\s+", " ", ult.findtext("DESCRIPCIONTRAMITE") or "").strip()[:300]} if ult is not None else None,
                "n_tramites": len(tr),
            }
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=None)
    ap.add_argument("--desde-mociones", default="2025-11-01")
    ap.add_argument("--anios-mensajes", default="2022,2023,2024,2025,2026")
    ap.add_argument("--max", type=int, default=0)
    a = ap.parse_args()
    cache = Path(a.cache) if a.cache else None
    base = {}
    for anio in a.anios_mensajes.split(","):
        for p in listar_camara("mensaje", anio, cache):
            base[p["boletin"]] = p
    for anio in sorted({a.desde_mociones[:4], "2026"}):
        for p in listar_camara("mocion", anio, cache):
            if p["fecha"] >= a.desde_mociones:
                base.setdefault(p["boletin"], p)
    items = sorted(base.values(), key=lambda p: p["fecha"])
    if a.max:
        items = items[: a.max]
    out, sin_detalle = [], 0
    with ThreadPoolExecutor(max_workers=4) as pool:  # 4 hilos: carga moderada sobre el servicio público
        detalles = list(pool.map(lambda q: detalle_senado(q["boletin"], cache), items))
    for i, (p, det) in enumerate(zip(items, detalles), 1):
        sin_detalle += det is None
        b = p["boletin"]
        out.append({
            "boletin": b, "titulo": p["nombre"], "iniciativa": "mensaje" if p["tipo"] == "mensaje" else "mocion",
            "camara_origen": p["camara_origen"], "fecha_ingreso": p["fecha"],
            **(det or {k: None for k in ("estado", "etapa", "subetapa", "urgencia_actual", "ley_numero", "diario_oficial", "autores", "materias", "ultimo_tramite", "n_tramites")}),
            "tema": tema(p["nombre"], (det or {}).get("materias") or []),
            "url_senado": "https://tramitacion.senado.cl/appsenado/templates/tramitacion/index.php?boletin_ini=" + urllib.parse.quote(b),
            "url_camara": "https://www.camara.cl/legislacion/ProyectosDeLey/tramitacion.aspx?prmBOLETIN=" + urllib.parse.quote(b),
            "verificado": det is not None, "fuentes": ["fuentes.json#camara_opendata", "fuentes.json#senado_tramitacion"],
        })
        if i % 50 == 0:
            print(f"{i}/{len(items)}", file=sys.stderr)
    doc = {"fecha_corte": time.strftime("%Y-%m-%d"), "criterio": f"mensajes {a.anios_mensajes}; mociones desde {a.desde_mociones}",
           "nota": "estado/urgencia según el WS del Senado a la fecha de corte; verificado=false si el Senado no devolvió el boletín",
           "total": len(out), "sin_detalle_senado": sin_detalle, "proyectos": out}
    SALIDA.write_text(json.dumps(doc, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"OK {len(out)} proyectos ({sin_detalle} sin detalle del Senado) -> {SALIDA}")


if __name__ == "__main__":
    main()
