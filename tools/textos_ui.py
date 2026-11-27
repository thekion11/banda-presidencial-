#!/usr/bin/env python3
"""Lista de textos de la interfaz para localización (cola 9).

Recorre game/**/*.gd y extrae los literales de texto que llegan a la pantalla: los que se pasan a
Tema.etiqueta / etiqueta_corta / boton, se asignan a .text o a tooltip_text, o van en _avisar(...).
Escribe un CSV (archivo, línea, texto) para entregar a quien traduzca, y resume cuántos hay por archivo.
Los textos de data/ (cartas, eventos, ministros…) no entran: ya están en JSON y se traducen ahí.

Uso: python3 tools/textos_ui.py [salida.csv]   (por defecto /tmp/textos_ui.csv)
"""
import csv
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
LLAMADAS = re.compile(r'(?:etiqueta_corta|etiqueta|boton|_avisar|mostrar|titulo|Label\.new)\(\s*"((?:[^"\\]|\\.)*)"')
ASIGNA = re.compile(r'(?:\.text|tooltip_text|placeholder_text)\s*=\s*"((?:[^"\\]|\\.)*)"')
FORMATO = re.compile(r'"((?:[^"\\]|\\.)*[a-záéíóúñ]{3,}(?:[^"\\]|\\.)*)"\s*%')


def es_texto(t: str) -> bool:
    ## Descarta rutas, ids, colores y claves: un texto de pantalla tiene letras y algún espacio o mayúscula inicial.
    if not t or t.startswith(("res://", "user://", "#", "]", ")")) or ".text" in t or re.fullmatch(r"[a-z_0-9.]+", t):
        return False
    return bool(re.search(r"[A-Za-zÁÉÍÓÚÑáéíóúñ]{2,}", t))


def extraer() -> list[tuple[str, int, str]]:
    filas = []
    for ruta in sorted((RAIZ / "game").rglob("*.gd")):
        rel = str(ruta.relative_to(RAIZ))
        for n, linea in enumerate(ruta.read_text(encoding="utf-8").splitlines(), 1):
            if linea.strip().startswith("#"):
                continue
            vistos = set()
            for patron in (LLAMADAS, ASIGNA, FORMATO):
                for m in patron.finditer(linea):
                    t = m.group(1)
                    if t not in vistos and es_texto(t):
                        vistos.add(t)
                        filas.append((rel, n, t))
    return filas


def main() -> None:
    salida = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/textos_ui.csv")
    filas = extraer()
    with salida.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["archivo", "linea", "texto"])
        w.writerows(filas)
    por_archivo: dict[str, int] = {}
    for a, _, _ in filas:
        por_archivo[a] = por_archivo.get(a, 0) + 1
    unicos = len({t for _, _, t in filas})
    print(f"{len(filas)} textos ({unicos} distintos) en {len(por_archivo)} archivos -> {salida}")
    for a, c in sorted(por_archivo.items(), key=lambda x: -x[1])[:10]:
        print(f"  {c:4d}  {a}")


if __name__ == "__main__":
    main()
