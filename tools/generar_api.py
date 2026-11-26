#!/usr/bin/env python3
"""Genera docs/API_SIM.md: índice de las funciones públicas de sim/ (las que no empiezan con «_») con su firma y su primera línea de documentación
(`##` en el cuerpo o comentario al final de la firma). Falla con --verificar si alguna función pública no tiene documentación (el CI lo exige)."""
import glob
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]


def main() -> int:
    out = ["# API de `sim/` (generado)", "", "Índice de las funciones públicas de `sim/` con su documentación. Generado con `python3 tools/generar_api.py`; no editar a mano. Visión de conjunto y dependencias: `docs/ARQUITECTURA_SIM.md`.", ""]
    sin = []
    total = 0
    for f in sorted(glob.glob(str(RAIZ / "sim" / "*.gd"))):
        L = Path(f).read_text(encoding="utf-8").split("\n")
        clase = next((re.match(r"class_name (\w+)", x).group(1) for x in L if x.startswith("class_name ")), Path(f).stem)
        filas = []
        i = 0
        while i < len(L):
            m = re.match(r"^(static )?func ([a-z]\w*)\((.*)$", L[i])
            if not m:
                i += 1
                continue
            j = i
            firma = L[i]
            while not re.search(r"\)\s*(->\s*[\w\[\], .]+)?:", L[j]):
                j += 1
                firma += " " + L[j].strip()
            doc = ""
            t = re.search(r"\)\s*(->\s*[\w\[\], .]+)?:\s*(.*)$", L[j])
            resto = t.group(2).strip() if t else ""
            if "#" in resto:
                doc = resto[resto.index("#"):].lstrip("# ").strip()
            for k in range(j + 1, min(j + 5, len(L))):
                s = L[k].strip()
                if s.startswith("##"):
                    doc = s.lstrip("# ").strip()
                    break
            if not doc:
                doc = next((L[k].strip().lstrip("# ") for k in range(max(0, i - 2), i) if L[k].strip().startswith("##")), "")
            total += 1
            if not doc:
                sin.append(f"{Path(f).name}:{m.group(2)}")
            sig = re.sub(r"\s*:\s*(#.*|return .*)?$", "", firma.split("# ")[0].strip()).replace("static func ", "static ").replace("func ", "")
            filas.append(f"- `{sig}` — {doc or '(sin documentar)'}")
            i = j + 1
        if filas:
            out += [f"## `{clase}` (`sim/{Path(f).name}`)", ""] + filas + [""]
    (RAIZ / "docs" / "API_SIM.md").write_text("\n".join(out), encoding="utf-8")
    print("docs/API_SIM.md: %d funciones públicas, %d sin documentar" % (total, len(sin)))
    if "--verificar" in sys.argv and sin:
        print("ERROR: funciones públicas sin documentar:", ", ".join(sin))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
