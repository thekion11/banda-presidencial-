"""Valida data/partidos/partidos_reales.json y partidos_juego.json (réplicas ficticias).

Reglas: hechos reales con fuente y fecha; cada partido real tiene exactamente una réplica;
el nombre ficticio no coincide ni se parece al real (Ley 18.603 art. 8 como criterio de prudencia);
ejes dentro de [-1, 1] y cifras ilustrativas rotuladas.
"""
from difflib import SequenceMatcher
from datetime import date
import json
from pathlib import Path
import re
import unicodedata

DIR = Path(__file__).resolve().parents[1] / "data" / "partidos"
CATS = {"obras", "transportes", "salud", "seguridad", "medioambiente", "politica", "economia", "vivienda",
        "energia", "hacienda", "educacion", "social", "descentralizacion", "estado", "comite"}
SIGLAS_REALES = {"PS", "PPD", "PDC", "PC", "PCCH", "FA", "RN", "UDI", "EVOP", "REP", "PREP", "PRCH", "PNL", "PL",
                 "PDG", "PR", "FRVS", "FREVS", "PCC", "PSC", "DEM", "AH", "PH"}
MIN_SIMILITUD = 0.6


def norm(txt: str) -> str:
    txt = unicodedata.normalize("NFD", txt.lower())
    return re.sub(r"[^a-z0-9 ]", "", "".join(c for c in txt if unicodedata.category(c) != "Mn")).strip()


def _fecha(valor: str, ctx: str) -> None:
    try:
        date.fromisoformat(valor)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{ctx}: fecha inválida '{valor}'") from exc


def _validar_real(p: dict) -> None:
    ctx = f"partido real {p.get('id')}"
    for campo in ("id", "nombre_oficial", "sigla", "fecha_constitucion", "regiones", "declaracion_principios",
                  "ubicacion_ideologica", "historial", "congreso", "fuente_url", "fecha_consulta", "verificado"):
        if campo not in p:
            raise ValueError(f"{ctx}: falta '{campo}'")
    _fecha(p["fecha_constitucion"], ctx)
    _fecha(p["fecha_consulta"], ctx)
    if not str(p["fuente_url"]).startswith("https://"):
        raise ValueError(f"{ctx}: fuente_url debe ser https")
    if not isinstance(p["verificado"], bool):
        raise ValueError(f"{ctx}: verificado debe ser booleano")
    for h in p["historial"].get("posiciones", []):
        if not h.get("fuente_url") or not h.get("hecho"):
            raise ValueError(f"{ctx}: posición sin hecho o sin fuente_url")
    for k in ("coaliciones", "posiciones"):
        if k not in p["historial"]:
            raise ValueError(f"{ctx}: historial sin '{k}'")
    for per in ("2022_2026", "2026_2030"):
        c = p["congreso"].get(per)
        if not c or "diputados" not in c or "fuente" not in c:
            raise ValueError(f"{ctx}: congreso.{per} requiere diputados y fuente")


def _validar_juego(p: dict, reales: dict, nombres: set, siglas: set) -> None:
    ctx = f"partido de juego {p.get('id')}"
    for campo in ("id", "real_ref", "nombre", "sigla", "alias_bloque", "eje_eco", "eje_inst", "justificacion",
                  "pide", "rechaza", "escanos", "cifras_ilustrativas"):
        if campo not in p:
            raise ValueError(f"{ctx}: falta '{campo}'")
    if p["real_ref"] not in reales:
        raise ValueError(f"{ctx}: real_ref '{p['real_ref']}' no existe")
    if p["cifras_ilustrativas"] is not True:
        raise ValueError(f"{ctx}: cifras_ilustrativas debe ser true")
    for eje in ("eje_eco", "eje_inst"):
        if not -1.0 <= p[eje] <= 1.0:
            raise ValueError(f"{ctx}: {eje} fuera de [-1, 1]")
    for eje in ("eco", "inst"):
        if len(p["justificacion"].get(eje, "")) < 40:
            raise ValueError(f"{ctx}: justificacion.{eje} demasiado corta")
    for k in ("categorias", "temas"):
        if not p["pide"].get(k) or not p["rechaza"].get(k):
            raise ValueError(f"{ctx}: pide/rechaza requieren '{k}'")
    for c in p["pide"]["categorias"] + p["rechaza"]["categorias"]:
        if c not in CATS:
            raise ValueError(f"{ctx}: categoría desconocida '{c}'")
    real = reales[p["real_ref"]]
    ministros = {m["id"] for m in json.loads((DIR.parent / "ministros.json").read_text(encoding="utf-8"))}
    for m in p["pide"].get("ministerios", []):
        if m not in ministros:
            raise ValueError(f"{ctx}: ministerio desconocido '{m}'")
    n_f, n_r = norm(p["nombre"]), norm(real["nombre_oficial"])
    if n_f == n_r or SequenceMatcher(None, n_f, n_r).ratio() >= MIN_SIMILITUD:
        raise ValueError(f"{ctx}: nombre demasiado parecido al real")
    if p["nombre"] in nombres or p["sigla"] in siglas:
        raise ValueError(f"{ctx}: nombre o sigla duplicados")
    nombres.add(p["nombre"])
    siglas.add(p["sigla"])
    if p["sigla"].upper().replace(" ", "") in SIGLAS_REALES:
        raise ValueError(f"{ctx}: sigla coincide con una real")
    nombre_real_sin_sigla = norm(real["sigla"] or "")
    if nombre_real_sin_sigla and norm(p["sigla"]) == nombre_real_sin_sigla:
        raise ValueError(f"{ctx}: sigla igual a la real")


def validar_partidos() -> None:
    if not (DIR / "partidos_reales.json").exists():
        print("[AVISO] data/partidos/ aún no existe; se omite la validación de partidos")
        return
    reales = json.loads((DIR / "partidos_reales.json").read_text(encoding="utf-8"))
    ruta_juego = DIR / "partidos_juego.json"
    juego = json.loads(ruta_juego.read_text(encoding="utf-8")) if ruta_juego.exists() else {"partidos": []}
    ids = {}
    for p in reales["partidos"]:
        _validar_real(p)
        if p["id"] in ids:
            raise ValueError(f"partido real duplicado: {p['id']}")
        ids[p["id"]] = p
    for d in reales.get("disueltos_2026", []):
        if not d.get("nombre") or not d.get("fuente_url"):
            raise ValueError("disueltos_2026: requiere nombre y fuente_url")
    nombres, siglas, vistos = set(), set(), set()
    for p in juego["partidos"]:
        _validar_juego(p, ids, nombres, siglas)
        if p["real_ref"] in vistos:
            raise ValueError(f"réplica duplicada para {p['real_ref']}")
        vistos.add(p["real_ref"])
    faltan = set(ids) - vistos
    if faltan and not juego["partidos"]:
        print("[AVISO] partidos_juego.json aún no existe; solo se validaron los reales")
        return
    if faltan:
        raise ValueError(f"partidos reales sin réplica: {sorted(faltan)}")
    print(f"[INFO] Partidos: {len(ids)} reales, {len(juego['partidos'])} réplicas ficticias válidas")
