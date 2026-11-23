#!/usr/bin/env python3
"""Aplica parches de monto total (tools/proyectos/curados/parches_montos.jsonl) a los listados curados (*.jsonl) por id.

Cada parche: id, inversion_musd/uf/clp, monto_fuente_url, oficial, fecha_fuente, nota. Sólo sustituye montos que estaban vacíos;
el origen del monto queda en 'notas' (el resto de la fila no cambia). Idempotente.
Uso   : python3 tools/proyectos/aplicar_parches.py && python3 tools/proyectos/curados_jsonl.py
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import slug  # noqa

CUR = Path(__file__).resolve().parent / "curados"


def main():
    ruta = CUR / "parches_montos.jsonl"
    parches = {}
    for lin in ruta.read_text(encoding="utf-8").splitlines():
        if lin.strip():
            p = json.loads(lin)
            parches[p["id"]] = p
    aplicados = 0
    for arch in sorted(CUR.glob("*.jsonl")):
        if arch.name == ruta.name:
            continue
        filas = [json.loads(l) for l in arch.read_text(encoding="utf-8").splitlines() if l.strip()]
        cambio = False
        for r in filas:
            p = parches.get(f"cur-{r['region_id']}-{slug(r['nombre'], 70)}")
            if not p or any(r.get(k) for k in ("inversion_musd", "inversion_uf", "inversion_clp")):
                continue
            vals = {k: p.get(k) for k in ("inversion_musd", "inversion_uf", "inversion_clp") if isinstance(p.get(k), (int, float)) and p[k] > 0}
            if not vals:
                continue
            r.update(vals)
            tipo = "oficial" if p.get("oficial") else "prensa"
            r["notas"] = (f"Monto total: {p.get('monto_fuente_url')} ({tipo}, {p.get('fecha_fuente')}); {p.get('nota') or ''} | " + (r.get("notas") or "")).strip()
            cambio = True
            aplicados += 1
        if cambio:
            arch.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in filas) + "\n", encoding="utf-8")
    print(f"parches aplicados: {aplicados} de {len(parches)}")


if __name__ == "__main__":
    main()
