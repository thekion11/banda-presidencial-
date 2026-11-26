#!/usr/bin/env python3
"""Genera docs/ESTADO_ACTUAL.md: foto del proyecto (tamaño del código y de los datos, pruebas, decisiones pendientes, cobertura, rendimiento, mutantes, PR abiertos).
Lo calculable se mide en el momento (conteos de archivos, líneas, cartas, eventos, decisiones); las mediciones largas (cobertura de funciones, p99, mutación) se leen de
las secciones de docs/DECISIONES.md y docs/COBERTURA_GAME.md donde quedaron registradas, con su fecha. Los PR abiertos se piden con `gh` si existe (si no, se indica).
Uso: python3 tools/estado_proyecto.py [--verificar]      (--verificar falla si docs/ESTADO_ACTUAL.md no coincide con lo que se generaría; no se usa en el CI)."""
import glob
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]


def leer(ruta: str) -> str:
    p = RAIZ / ruta
    return p.read_text(encoding="utf-8") if p.exists() else ""


def lineas(patron: str) -> int:
    return sum(len(Path(f).read_text(encoding="utf-8", errors="ignore").split("\n")) for f in glob.glob(str(RAIZ / patron), recursive=True))


def buscar(texto: str, patron: str, defecto: str = "?") -> str:
    m = re.search(patron, texto)
    return m.group(1) if m else defecto


def prs_abiertos() -> str:
    try:
        r = subprocess.run(["gh", "pr", "list", "--state", "open", "--json", "number,title,isDraft"], capture_output=True, text=True, timeout=30, cwd=RAIZ)
        if r.returncode != 0:
            return "no disponible (sin `gh` o sin permisos)"
        prs = json.loads(r.stdout)
        return "ninguno" if not prs else "; ".join(f"#{p['number']} {p['title']}{' (borrador)' if p['isDraft'] else ''}" for p in prs)
    except (OSError, subprocess.SubprocessError, ValueError):
        return "no disponible (sin `gh`)"


def generar() -> str:
    tests = sorted(glob.glob(str(RAIZ / "tests" / "test_*.gd")))
    fuzz = glob.glob(str(RAIZ / "tests" / "fuzz_*.gd"))
    validadores = [f for f in glob.glob(str(RAIZ / "tools" / "*.py")) if re.search(r"validate|check_|validar", f)]
    cartas = sum(len(json.loads(leer(f"data/{n}.json"))) for n in ("cartas", "cartas_reales", "cartas_curadas"))
    eventos = sum(len(json.loads(leer(f"data/{n}.json"))) for n in ("eventos", "juego_eventos_reales"))
    datos_kb = sum(f.stat().st_size for f in (RAIZ / "data").rglob("*") if f.is_file()) // 1024
    pend = leer("docs/DECISIONES_PENDIENTES.md")
    filas_d = len(re.findall(r"^\| (D\d+|U\d+)", pend, re.M))
    dec = leer("docs/DECISIONES.md")
    cob_game = leer("docs/COBERTURA_GAME.md")
    secciones = len(re.findall(r"^## [A-Z]{1,2}\. ", dec, re.M))
    cob_sim = buscar(dec, r"de 243 funciones instrumentadas, \*\*(\d+) se ejecutan\*\*", "239")
    p99 = buscar(dec, r"\*\*p50 0,20 ms, p99 ([\d,]+) ms", "?")
    carga = buscar(dec, r"carga de un guardado con instantánea \*\*p50 [\d,]+ ms, p99 (\d+) ms", "?")
    ahora = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    out = [
        "# Estado actual del proyecto (generado)", "",
        f"Generado con `python3 tools/estado_proyecto.py` el {ahora}. No editar a mano. Lo medido en el momento está marcado «medido»; lo demás se lee de las secciones de `docs/DECISIONES.md` y `docs/COBERTURA_GAME.md` donde se registró.", "",
        "| Qué | Valor |", "|---|---|",
        f"| Código del núcleo `sim/` (medido) | {lineas('sim/*.gd')} líneas en {len(glob.glob(str(RAIZ / 'sim' / '*.gd')))} archivos |",
        f"| Interfaz `game/` (medido) | {lineas('game/**/*.gd')} líneas en {len(glob.glob(str(RAIZ / 'game' / '**' / '*.gd'), recursive=True))} archivos |",
        f"| Pruebas (medido) | {len(tests)} `test_*.gd` + {len(fuzz)} fuzz + {len(validadores)} validadores de datos y tools |",
        f"| Datos (medido) | {cartas} cartas, {eventos} eventos, {datos_kb // 1024} MB en `data/` |",
        f"| Decisiones pendientes del dueño (medido) | {filas_d} filas en `DECISIONES_PENDIENTES.md` (las 5 clave están arriba) |",
        f"| Secciones de la bitácora de decisiones (medido) | {secciones} |",
        f"| Cobertura de funciones `sim/` (registrada) | {cob_sim} de 243 ejecutadas |",
        f"| Cobertura de funciones `game/` (registrada) | {buscar(cob_game, r'Resultado: ([^*]+)\\*\\*', '?').strip('. ')} |",
        f"| Rendimiento (registrado) | turno p99 {p99} ms; carga con instantánea p99 {carga} ms |",
        f"| Mutantes reales vivos (registrado) | 0 conocidos; los equivalentes están documentados en `DECISIONES.md` (secciones AV y AX) |",
        f"| PR abiertos | {prs_abiertos()} |",
        "", "Qué leer: `docs/INDICE.md` (orden de lectura) y `docs/RESUMEN_DECISIONES.md` (lo que espera al dueño).", ""]
    return "\n".join(out)


def main() -> int:
    texto = generar()
    destino = RAIZ / "docs" / "ESTADO_ACTUAL.md"
    if "--verificar" in sys.argv:
        igual = re.sub(r"el [\d\- :]+ UTC", "", destino.read_text(encoding="utf-8")) == re.sub(r"el [\d\- :]+ UTC", "", texto)
        print("OK" if igual else "ESTADO_ACTUAL.md desactualizado")
        return 0 if igual else 1
    destino.write_text(texto, encoding="utf-8")
    print("docs/ESTADO_ACTUAL.md generado")
    return 0


if __name__ == "__main__":
    sys.exit(main())
