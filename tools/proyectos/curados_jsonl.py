#!/usr/bin/env python3
"""Convierte los listados curados (tools/proyectos/curados/*.jsonl, una fila por proyecto leída de páginas públicas) en data/proyectos/curados_*.json.

Reglas: verificado=true (salvo notas que pidan 'verificar') sólo si la fila se marcó oficial Y la URL es de un dominio del Estado (dominio estatal: ver es_estatal); si no, false (prensa).
Se descartan duplicados (misma región+nombre normalizado, o ya existentes en data/proyectos/) y filas inválidas (se listan en pantalla).
Uso   : python3 tools/proyectos/curados_jsonl.py
"""
import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import *  # noqa

CUR = Path(__file__).resolve().parent / "curados"
SECTORES = {"salud", "educacion", "vivienda_urbana", "vial", "agua", "energia", "seguridad", "edificacion", "transporte", "puertos",
            "aeropuertos", "ferrocarriles", "otros"}
RIDS = {r["id"] for r in json.loads((ROOT / "data" / "regiones.json").read_text(encoding="utf-8"))}


OFICIAL_EXTRA = ("minsal.cl", "mineduc.cl", "junji.cl", "integra.cl", "cne.cl")


def es_estatal(host):
    """Dominio del Estado: .gob.cl/.gov.cl, ministerios con dominio propio o sitios de gobiernos regionales (gore*/gobierno*)."""
    h = host.removeprefix("www.")
    return h.endswith((".gob.cl", ".gov.cl")) or h.endswith(OFICIAL_EXTRA) or h.startswith(("gore", "gobiernoregional"))


def clave(rid, nombre):
    return (rid, slug(nombre, 80))


def num(v):
    return float(v) if isinstance(v, (int, float)) and not isinstance(v, bool) and v >= 0 else None


def main():
    vistos = set()
    for f in SALIDA.glob("*.json"):
        if not f.name.startswith("curados_"):
            vistos |= {clave(p["region_id"], p["nombre"]) for p in json.loads(f.read_text(encoding="utf-8"))["proyectos"]}
    n_of = n_pr = 0
    for arch in sorted(CUR.glob("*.jsonl")):
        regs, malos, dup = [], 0, 0
        for lin in arch.read_text(encoding="utf-8").splitlines():
            if not lin.strip():
                continue
            try:
                r = json.loads(lin)
                assert r["region_id"] in RIDS and r["estado"] in ESTADOS and r["sector"] in SECTORES
                assert r["nombre"].strip() and urlparse(r["fuente_url"]).scheme == "https"
            except Exception:
                malos += 1
                continue
            k = clave(r["region_id"], r["nombre"])
            if k in vistos:
                dup += 1
                continue
            vistos.add(k)
            host = urlparse(r["fuente_url"]).hostname or ""
            estatal = bool(r.get("oficial")) and es_estatal(host)
            notas = (r.get("notas") or "").strip()
            anios = sorted(set(re.findall(r"\b(20(?:18|19|20|21|22|23|24))\b", notas)))
            dudoso = "verificar" in notas.lower() or "no verificad" in notas.lower() or bool(anios)
            if anios and not notas.startswith("[fuente de"):
                notas = f"[fuente de {anios[0]}: estado a 2025-2026 sin confirmar] " + notas
            ofi = estatal and not dudoso
            n_of += ofi
            n_pr += not ofi
            regs.append(registro(
                id=f"cur-{r['region_id']}-{slug(r['nombre'], 70)}", nombre=r["nombre"].strip(), sector=r["sector"], region_ids=[r["region_id"]],
                comuna=r.get("comuna") or None, estado=r["estado"], inversion_musd=num(r.get("inversion_musd")), inversion_uf=num(r.get("inversion_uf")),
                inversion_clp=num(r.get("inversion_clp")), fecha_inicio=r.get("fecha_inicio"), fecha_fin=r.get("fecha_fin"), mandante=r.get("mandante"),
                descripcion=(r.get("descripcion") or "")[:300] or None, fuente_url=r["fuente_url"],
                fuente="fuentes.json#curados_oficiales_2026" if estatal else "fuentes.json#curados_prensa_2026", verificado=ofi,
                notas=notas or None))
        print(f"{arch.name}: {len(regs)} válidos, {dup} duplicados, {malos} inválidos")
        if regs:
            guardar(f"curados_{arch.stem}", regs, {"fuente": "curados_*_2026", "scraper": "tools/proyectos/curados_jsonl.py", "fecha_consulta": HOY,
                                                   "nota": "Filas leídas de páginas públicas; verificado=true sólo con dominio oficial del Estado. Montos tal como los publica la fuente."})
    registrar_fuente("curados_oficiales_2026", "Sitios oficiales del Estado (gobiernos regionales, ministerios, servicios, municipalidades .gob.cl/.gov.cl)",
                     "Proyectos regionales y sectoriales leídos de páginas institucionales (2026)", "https://www.gob.cl/", 180)
    registrar_fuente("curados_prensa_2026", "Prensa regional y nacional", "Proyectos regionales y sectoriales reportados por prensa (2026), no oficiales",
                     "https://www.gob.cl/", 180)
    print(f"oficiales={n_of} prensa={n_pr}")


if __name__ == "__main__":
    main()
