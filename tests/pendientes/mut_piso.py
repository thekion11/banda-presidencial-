import os, shutil, subprocess, sys
W="/tmp/claude-0/wt_piso"; S="/tmp/claude-0/-home-user-banda-presidencial-/b59a5904-8e72-5a44-821c-3f0ff6c587af/scratchpad"
M=[
 ("P01","sim/regiones.gd","		if v < _p[i]:  # el piso ideológico frena la caída (y sube a quien ya estaba debajo)","		if false:","aplicar_delta ignora el piso ideológico"),
 ("P02","sim/luna_de_miel.gd","	if s > n:\n		return 0.0","	if s >= n:\n		return 0.0","la luna de miel termina una semana antes (13 en vez de 14)"),
 ("P03","sim/voto_regional.gd","clampf(maxf(float(aprobacion_regional.get(id, 0.0)) + desplazamiento + eps, duro), tope_min, tope_max)","clampf(float(aprobacion_regional.get(id, 0.0)) + desplazamiento + eps, tope_min, tope_max)","el voto de una región puede bajar de su piso"),
 ("P04","sim/luna_de_miel.gd","	return pow(float(n - (s - 1)) / float(n), float(c[\"exponente\"])) * mult","	return pow(float(n - (s - 1)) / float(n), float(c[\"exponente\"]))","la luna de miel ignora la dificultad"),
 ("P05","sim/regiones.gd","estado.aprobacion_regional[id] = clampf(maxf(a + (b - a) * tasa, piso_de(String(id))), 0.0, 100.0)","estado.aprobacion_regional[id] = clampf(a + (b - a) * tasa, 0.0, 100.0)","la reversión a la base ignora el piso"),
 ("P06","sim/luna_de_miel.gd","	return pow(float(n - (s - 1)) / float(n)","	return pow(float(n - s) / float(n)","la luna de miel parte un paso más abajo (no vale 1 en la semana 1)"),
]
for mid,arch,viejo,nuevo,desc in [x for x in M if x[0] in sys.argv[1:] or not sys.argv[1:]]:
    d=f"/tmp/claude-0/mut/{mid}"; shutil.rmtree(d,ignore_errors=True)
    shutil.copytree(W,d,ignore=shutil.ignore_patterns(".git"),symlinks=True)
    p=f"{d}/{arch}"; t=open(p,encoding="utf-8").read()
    if t.count(viejo)!=1: print(mid,"NO_APLICA",t.count(viejo)); continue
    open(p,"w",encoding="utf-8").write(t.replace(viejo,nuevo))
    env=dict(os.environ,HOME=d+"/home",XDG_DATA_HOME=d+"/home/.local/share"); os.makedirs(env["HOME"],exist_ok=True)
    subprocess.run(["godot","--headless","--import","--path",d],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=300)
    try:
        r=subprocess.run(["godot","--headless","--path",d,"-s","tests/fuzz_piso_luna.gd","--","9","4400","40"],env=env,capture_output=True,text=True,timeout=250); out=r.stdout+r.stderr; rc=r.returncode
    except subprocess.TimeoutExpired: out,rc="TIMEOUT",124
    f=[l for l in out.splitlines() if l.startswith("FALLO") or "SCRIPT ERROR" in l]
    print(mid,desc,"->","MUERTO" if (rc!=0 or f) else "SOBREVIVE",(f[:1] or [""])[0][:150]); shutil.rmtree(d,ignore_errors=True)
