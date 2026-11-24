#!/usr/bin/env python3
"""Escribe data/version.json (versión de prueba, commit y fecha) que el juego muestra en el informe de prueba."""
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True).strip()
    datos = {"version": "0.9.0-prueba1", "commit": commit, "fecha_utc": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M")}
    (ROOT / "data" / "version.json").write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(datos)


if __name__ == "__main__":
    main()
