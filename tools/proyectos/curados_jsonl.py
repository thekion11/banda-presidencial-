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


def fuente_id(host, estatal):
    return ("curados_" if estatal else "prensa_") + re.sub(r"[^a-z0-9]+", "_", host.removeprefix("www."))


def main():
    vdip = {}
    rv = ROOT / "data" / "verificacion" / "dipres_siap.json"
    if rv.exists():
        vdip = json.loads(rv.read_text(encoding="utf-8"))
    fuentes_nuevas = {}
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
            rid = f"cur-{r['region_id']}-{slug(r['nombre'], 70)}"
            estado = r["estado"]
            dv = vdip.get("proyectos", {}).get(rid)
            if dv:
                art = dv["articulo"]
                doc = vdip["documentos"][art]
                fid = f"dipres_siap_{art}"
                fuentes_nuevas[fid] = ("Dirección de Presupuestos (Dipres)", f"Informe de identificación y ejecución de inversión pública (SIAP 2.0) a {doc['periodo']}, doc. {art}: "
                                       + "; ".join(doc["programas"])[:140], doc["url"], doc["fecha_informe"])
                if dv["encontrado"]:
                    notas += f" | Dipres {doc['periodo']}: BIP {dv['bip']}, etapa {dv['etapa_pdf']}, presupuesto 2026 identificado ${dv['identificado_miles_clp']:,} miles".replace(",", ".")
                    if dv["estado_coincide"] is False:
                        notas += f" | estado corregido a '{dv['etapa_pdf']}' según el PDF (antes '{estado}')"
                        estado = dv["etapa_pdf"]
                    ofi = estatal and not ("verificar" in notas.lower() or "no verificad" in notas.lower())
                    if dv["identificado_miles_clp"] < 100:
                        notas += " | presupuesto 2026 simbólico (< M$100): el avance real de obra no está confirmado"
                        ofi = False
                else:
                    notas += f" | NO se halló el nombre en el PDF citado (similitud {dv['similitud']}): nombre y estado sin sustento en el documento"
                    ofi = False
                fuente = "fuentes.json#" + fid
            else:
                fid = fuente_id(host, estatal)
                fuentes_nuevas[fid] = ((host if estatal else "Prensa: " + host), ("Sitio institucional del Estado" if estatal else "Medio de prensa") + f" {host}: páginas de proyectos consultadas en 2026",
                                       f"https://{host}/", None)
                fuente = "fuentes.json#" + fid
            regs.append(registro(
                id=rid, nombre=r["nombre"].strip(), sector=r["sector"], region_ids=[r["region_id"]],
                comuna=r.get("comuna") or None, estado=estado, inversion_musd=num(r.get("inversion_musd")), inversion_uf=num(r.get("inversion_uf")),
                inversion_clp=num(r.get("inversion_clp")), fecha_inicio=r.get("fecha_inicio"), fecha_fin=r.get("fecha_fin"), mandante=r.get("mandante"),
                descripcion=(r.get("descripcion") or "")[:300] or None, fuente_url=r["fuente_url"], fuente=fuente, verificado=ofi,
                notas=notas or None))
        print(f"{arch.name}: {len(regs)} válidos, {dup} duplicados, {malos} inválidos")
        if regs:
            guardar(f"curados_{arch.stem}", regs, {"fuente": "curados_*_2026", "scraper": "tools/proyectos/curados_jsonl.py", "fecha_consulta": HOY,
                                                   "nota": "Filas leídas de páginas públicas; verificado=true sólo con dominio oficial del Estado. Montos tal como los publica la fuente."})
    for fid, (inst, tit, url, corte) in sorted(fuentes_nuevas.items()):
        registrar_fuente(fid, inst, tit, url, 365 if fid.startswith("dipres") else 180, corte)
    ruta = ROOT / "data" / "fuentes.json"
    fuentes = [f for f in json.loads(ruta.read_text(encoding="utf-8")) if f["id"] not in ("curados_oficiales_2026", "curados_prensa_2026")]
    ruta.write_text(json.dumps(fuentes, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"oficiales={n_of} prensa={n_pr}")


if __name__ == "__main__":
    main()
