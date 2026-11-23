#!/usr/bin/env python3
"""Contrasta los proyectos curados que citan PDFs de Dipres (informes SIAP de identificación y ejecución de inversión pública) con el texto del PDF.

Para cada PDF citado: lo descarga (dipres.gob.cl/597/articles-<n>_doc_pdf.pdf), lee título/fecha (cabecera 'INFORME DE IDENTIFICACION Y EJECUCION DE INVERSION PUBLICA', 'A MARZO|AGOSTO DE 2026')
y sus líneas '<BIP> -ETAPA <X>- <NOMBRE>  <identificado>  <ejecutado>  <%>' (miles de pesos, presupuesto 2026 anual). Cada fila curada se busca por nombre (similitud >= 0.80)
dentro de su propio PDF; el resultado queda en data/verificacion/dipres_siap.json y lo usa curados_jsonl.py.
Uso   : python3 tools/proyectos/verificar_dipres.py <carpeta_vacia_para_pdfs>   (requiere pdftotext)
"""
import difflib
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import *  # noqa

CUR = Path(__file__).resolve().parent / "curados"
ETAPA = {"EJECUCION": "ejecucion", "DISENO": "diseno", "PREFACTIBILIDAD": "prefactibilidad", "FACTIBILIDAD": "prefactibilidad",
         "PERFIL": "perfil", "IDEA": "idea", "TERMINADO": "terminado", "OPERACION": "terminado"}
LIN = re.compile(r"^\s*(\d{7,8}-\d)\s+-ETAPA\s+([^-]+?)-\s+(.+?)\s{2,}([\d\.]+)\s+([\d\.]+)\s+[\d,]+\s*%\s*$")


def n(t):
    return norm(re.sub(r"\s+", " ", t))


def leer(pdf):
    txt = subprocess.run(["pdftotext", "-layout", str(pdf), "-"], capture_output=True, text=True, check=True).stdout
    m = re.search(r"A\s+(\w+)\s+DE\s+(\d{4})\s+-\s+LEY DE PRESUPUESTOS", txt)
    f = re.search(r"Fecha\s*:\s*(\d\d)/(\d\d)/(\d{4})", txt)
    prog = re.findall(r"PROGRAMA:\s*(\d+\s+[^\n]+?)\s*\n", txt)
    ent = []
    for lin in txt.splitlines():
        g = LIN.match(lin)
        if g:
            ent.append({"bip": g.group(1), "etapa": ETAPA.get(n(g.group(2)).upper(), n(g.group(2))), "nombre": g.group(3).strip(),
                        "ident_miles": int(g.group(4).replace(".", "")), "ejec_miles": int(g.group(5).replace(".", ""))})
    return {"periodo": f"{m.group(1).title()} de {m.group(2)}" if m else None, "fecha_informe": f"{f.group(3)}-{f.group(2)}-{f.group(1)}" if f else None,
            "programas": sorted(set(p.strip() for p in prog)), "entradas": ent}


def main(dest):
    dest = Path(dest)
    dest.mkdir(parents=True, exist_ok=True)
    filas = []
    for arch in sorted(CUR.glob("*.jsonl")):
        if arch.name.startswith("parches"):
            continue
        for lin in arch.read_text(encoding="utf-8").splitlines():
            if lin.strip():
                r = json.loads(lin)
                m = re.search(r"dipres\.gob\.cl/597/articles-(\d+)_doc_pdf\.pdf", r["fuente_url"])
                if m:
                    filas.append((m.group(1), r))
    docs, res = {}, {}
    for art in sorted({a for a, _ in filas}):
        pdf = dest / f"articles-{art}.pdf"
        if not pdf.exists():
            pdf.write_bytes(get(f"https://www.dipres.gob.cl/597/articles-{art}_doc_pdf.pdf", binario=True))
        docs[art] = leer(pdf)
    for art, r in filas:
        best, score = None, 0.0
        for e in docs[art]["entradas"]:
            s = difflib.SequenceMatcher(None, n(r["nombre"]), n(e["nombre"])).ratio()
            if s > score:
                best, score = e, s
        rid = f"cur-{r['region_id']}-{slug(r['nombre'], 70)}"
        ok = best is not None and score >= 0.80
        res[rid] = {"articulo": art, "encontrado": ok, "similitud": round(score, 2),
                    "bip": best["bip"] if ok else None, "etapa_pdf": best["etapa"] if ok else None, "nombre_pdf": best["nombre"] if ok else None,
                    "identificado_miles_clp": best["ident_miles"] if ok else None,
                    "estado_coincide": (best["etapa"] == r["estado"]) if ok else None}
    meta = {a: {"titulo": "Informe de identificación y ejecución de inversión pública (SIAP 2.0)", "periodo": d["periodo"],
                "fecha_informe": d["fecha_informe"], "programas": d["programas"],
                "url": f"https://www.dipres.gob.cl/597/articles-{a}_doc_pdf.pdf"} for a, d in docs.items()}
    salida = ROOT / "data" / "verificacion" / "dipres_siap.json"
    salida.write_text(json.dumps({"documentos": meta, "proyectos": res}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    ok = sum(v["encontrado"] for v in res.values())
    print(f"{len(docs)} PDF, {len(res)} filas, {ok} halladas en su PDF, {sum(1 for v in res.values() if v['encontrado'] and v['estado_coincide'] is False)} con estado distinto")


if __name__ == "__main__":
    main(sys.argv[1])
