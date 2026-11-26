#!/usr/bin/env python3
"""Presupuesto de tamaño del APK (CLAUDE.md §5: APK < 150 MB, regiones vía Play Asset Delivery).

Suma lo que entra al paquete según export_presets.cfg (todo lo del proyecto menos exclude_filter) por carpeta, avisa a partir del 60 % del tope y falla al superar el 90 %.
El número es una cota del contenido sin comprimir: el APK real comprime texto y JSON (≈ 4-8×), pero el motor de Godot (≈ 25-40 MB por arquitectura) se suma aparte.
Uso: python3 tools/check_presupuesto.py
"""
import fnmatch
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOPE_MB = 150.0
MOTOR_MB = 40.0  # estimación del motor de Godot y bibliotecas (por arquitectura) que se suman al contenido
AVISO = 0.60
FALLO = 0.90


def filtros() -> tuple:
    cfg = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    exc = re.search(r'^exclude_filter="([^"]*)"', cfg, re.M)
    return [f.strip() for f in (exc.group(1) if exc else "").split(",") if f.strip()]


def excluido(rel: str, excl: list) -> bool:
    return any(fnmatch.fnmatch(rel, f) for f in excl)


def main() -> int:
    excl = filtros()
    por_carpeta: dict = {}
    total = 0
    for f in ROOT.rglob("*"):
        if not f.is_file():
            continue
        rel = f.relative_to(ROOT).as_posix()
        if rel.startswith((".git/", ".godot/", ".github/", "build/")) or rel.endswith((".uid", ".import")) or excluido(rel, excl):
            continue
        carpeta = rel.split("/")[0] if "/" in rel else "(raíz)"
        por_carpeta[carpeta] = por_carpeta.get(carpeta, 0) + f.stat().st_size
        total += f.stat().st_size
    mb = total / 1048576.0
    print("Contenido que entra al paquete (sin comprimir):")
    for c, b in sorted(por_carpeta.items(), key=lambda kv: -kv[1])[:8]:
        print(f"  {c:12s} {b / 1048576.0:7.2f} MB")
    apk = ROOT / "build" / "presidente-debug.apk"
    if apk.exists():
        print(f"Último APK de depuración compilado aquí: {apk.stat().st_size / 1048576.0:.1f} MB (dato real; el tope es 150 MB)")
    estimado = mb + MOTOR_MB
    uso = estimado / TOPE_MB
    print(f"Total: {mb:.1f} MB de contenido + ~{MOTOR_MB:.0f} MB de motor = ~{estimado:.0f} MB de {TOPE_MB:.0f} MB ({uso * 100:.0f} % del tope; cota superior sin compresión)")
    if uso >= FALLO:
        print("ERROR: el paquete se acerca al tope de 150 MB: mover regiones/arte a Play Asset Delivery")
        return 1
    if uso >= AVISO:
        print("[AVISO] más del 60 % del tope: planificar Play Asset Delivery para las regiones antes de agregar arte")
    else:
        print("OK: holgura suficiente bajo el tope de 150 MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
