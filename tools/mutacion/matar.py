"""Comprueba que una prueba concreta mata un mutante (copia aislada del repo)."""
import sys, os, shutil, subprocess
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from mutantes import MUTANTES
REPO=os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),"..",".."))
def matar(mid, args):
    m=[x for x in MUTANTES if x[0]==mid][0]
    d=f"/tmp/mutacion/kill_{mid}"
    shutil.rmtree(d,ignore_errors=True)
    shutil.copytree(REPO,d,ignore=shutil.ignore_patterns(".git"),symlinks=True)
    p=f"{d}/{m[1]}"; s=open(p,encoding="utf-8").read(); assert s.count(m[2])==1
    open(p,"w",encoding="utf-8").write(s.replace(m[2],m[3]))
    env=dict(os.environ,HOME=d+"/home",XDG_DATA_HOME=d+"/home/.local/share"); os.makedirs(env["HOME"],exist_ok=True)
    subprocess.run(["godot","--headless","--import","--path",d],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=300)
    try:
        r=subprocess.run(["godot","--headless","--path",d]+args,env=env,capture_output=True,text=True,timeout=200)
        out=r.stdout+r.stderr; rc=r.returncode
    except subprocess.TimeoutExpired:
        out,rc="TIMEOUT",124
    fallos=[l for l in out.splitlines() if l.startswith("FALLO") or "SCRIPT ERROR" in l]
    print(mid,"con",args[1].split('/')[-1],"-> rc=",rc,"MUERTO" if (rc!=0 or fallos) else "SOBREVIVE",fallos[:1])
    shutil.rmtree(d,ignore_errors=True)
if __name__ == "__main__":
    # uso: python3 tools/mutacion/matar.py "test_x -- args" G29 G30 ...   (comprueba que UNA prueba concreta mata cada mutante)
    partes = sys.argv[1].split()
    for mid in sys.argv[2:]:
        matar(mid, ["-s", "tests/" + partes[0] + ".gd"] + partes[1:])
