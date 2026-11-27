"""Corre un mutante contra TODA la suite en una copia aislada del repo (HOME propio): MUERTO si alguna prueba o fuzz falla; SOBREVIVE si ninguna lo detecta.
Uso: python3 tools/mutacion/run_mutante.py M01 G12 T05 ...  (resultados en $MUTACION_DIR/resultados.jsonl; ≈ 2 a 7 min por mutante)."""
import sys, os, shutil, subprocess, glob, json, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mutantes import MUTANTES
REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
RAIZ = os.environ.get("MUTACION_DIR", "/tmp/mutacion")
SALIDA = RAIZ + "/resultados.jsonl"
SALIDA_EXTRA = RAIZ + "/resultados_extra.jsonl"

EXTRA = [
    ("fuzz_congreso", ["-s", "tests/fuzz_congreso.gd", "--", "1500", "12"]),
    ("fuzz_rechazos", ["-s", "tests/fuzz_rechazos.gd", "--", "4", "1200"]),
    ("fuzz_coalicion", ["-s", "tests/fuzz_coalicion.gd", "--", "5", "1700"]),
    ("fuzz_obras", ["-s", "tests/fuzz_obras.gd", "--", "6", "2600"]),
    ("fuzz_decisiones", ["-s", "tests/fuzz_decisiones.gd", "--", "2", "3100"]),
    ("fuzz_calendario", ["-s", "tests/fuzz_calendario.gd", "--", "12", "1500"]),
    ("fuzz_guardado", ["-s", "tests/fuzz_guardado.gd", "--", "300", "77"]),
    ("fuzz_ui", ["-s", "tests/fuzz_ui.gd", "--", "2", "400"]),
]


os.makedirs(RAIZ, exist_ok=True)


def correr(mid, solo_extra=False):
    m = [x for x in MUTANTES if x[0] == mid][0]
    _, archivo, viejo, nuevo, desc = m
    d = f"{RAIZ}/{mid}"
    shutil.rmtree(d, ignore_errors=True)
    shutil.copytree(REPO, d, ignore=shutil.ignore_patterns(".git"), symlinks=True)
    p = f"{d}/{archivo}"
    s = open(p, encoding="utf-8").read()
    n = s.count(viejo)
    if n != 1:
        res = {"id": mid, "estado": "NO_APLICA", "detalle": f"el texto original aparece {n} veces", "desc": desc}
        open(SALIDA, "a").write(json.dumps(res, ensure_ascii=False) + "\n")
        return
    open(p, "w", encoding="utf-8").write(s.replace(viejo, nuevo))
    env = dict(os.environ, HOME=f"{d}/home", XDG_DATA_HOME=f"{d}/home/.local/share", XDG_CONFIG_HOME=f"{d}/home/.config")
    os.makedirs(env["HOME"], exist_ok=True)
    t0 = time.time()
    subprocess.run(["godot", "--headless", "--import", "--path", d], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=300)
    pruebas = sorted(glob.glob(f"{d}/tests/test_*.gd"))
    pasos = [] if solo_extra else [(os.path.basename(x)[:-3], ["-s", f"tests/{os.path.basename(x)}"]) for x in pruebas]
    pasos += [] if solo_extra else [("fuzz_acciones", ["-s", "tests/fuzz_acciones.gd", "--", "60", "7000"]),
              ("fuzz_carrera", ["-s", "tests/fuzz_carrera.gd", "--", "4", "700"]),
              ("fuzz_instantanea", ["-s", "tests/fuzz_instantanea.gd", "--", "100", "31"]),
              ("fuzz_propiedades", ["-s", "tests/fuzz_propiedades.gd", "--", "1", "800"]),
              ("fuzz_flujo_ui", ["-s", "tests/fuzz_flujo_ui.gd", "--", "9", "2100"])]
    if solo_extra:
        pasos = EXTRA
    muertos = []
    for nombre, args in pasos:
        try:
            r = subprocess.run(["godot", "--headless", "--path", d] + args, env=env, capture_output=True, text=True, timeout=300)
            salida = r.stdout + r.stderr
            rc = r.returncode
        except subprocess.TimeoutExpired:
            salida, rc = "TIMEOUT", 124
        mal = rc != 0 or any(k in salida for k in ("SCRIPT ERROR", "Parse Error", "Could not find type"))
        if mal:
            muertos.append(nombre)
            break  # detectado: no hace falta seguir
    estado = "MUERTO" if muertos else "SOBREVIVE"
    if solo_extra:
        res = {"id": mid, "estado_extra": estado, "detectado_por": muertos[0] if muertos else None, "segundos": round(time.time() - t0), "desc": desc}
        open(SALIDA_EXTRA, "a").write(json.dumps(res, ensure_ascii=False) + "\n")
        shutil.rmtree(d, ignore_errors=True)
        return
    res = {"id": mid, "estado": estado, "detectado_por": muertos[0] if muertos else None, "segundos": round(time.time() - t0), "desc": desc}
    open(SALIDA, "a").write(json.dumps(res, ensure_ascii=False) + "\n")
    shutil.rmtree(d, ignore_errors=True)

if __name__ == "__main__":
    extra = "--extra" in sys.argv
    for mid in [a for a in sys.argv[1:] if not a.startswith("--")]:
        correr(mid, extra)
