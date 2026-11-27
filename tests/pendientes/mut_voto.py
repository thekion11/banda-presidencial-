import os, shutil, subprocess, sys
W="/tmp/claude-0/wt_nuc"
VR="sim/voto_regional.gd"; MM="sim/motor_mandato.gd"
M=[
 ("V01",VR,"	if r <= 0.0:\n		return 0.0","	if r < 0.0:\n		return 0.0","r = 0 ya no corta (equivalente: eps = x*0)"),
 ("V02",VR,"* 2.0 - 1.0) * r","* 2.0) * r","ruido sesgado a positivo"),
 ("V03",VR,"% 10001) / 10000.0","% 10000) / 10000.0","ruido nunca llega a +r (casi equivalente)"),
 ("V04",VR,"+ desplazamiento + eps, tope_min","+ desplazamiento, tope_min","el ruido no se suma al voto"),
 ("V05",VR,"var gana := voto >= umbral","var gana := voto > umbral","región gana solo si supera el umbral"),
 ("V06",VR,"nacional += peso * voto\n","nacional += peso * voto * 0.99\n","voto nacional mal ponderado"),
 ("V07",VR,"var por_regiones := ganadas * 2 > filas.size()","var por_regiones := ganadas * 2 >= filas.size()","mayoría de regiones con empate"),
 ("V08",VR,"var por_poblacion := nacional_ok >= umbral","var por_poblacion := nacional_ok > umbral","población gana solo si supera el umbral"),
 ("V09",VR,"[semilla, ciclo, ronda, id]","[semilla, ciclo, 1, id]","el ruido no depende de la vuelta"),
 ("V10",VR,"[semilla, ciclo, ronda, id]","[semilla, 1, ronda, id]","el ruido no depende del ciclo"),
 ("V11",VR,"[semilla, ciclo, ronda, id]","[0, ciclo, ronda, id]","el ruido no depende de la semilla"),
 ("V12",MM,"var r_reg := float(camp.get(\"ruido_eleccion_regional\", 0.0))","var r_reg := 0.0","el ruido regional configurado se ignora"),
 ("V13",MM,"		if r_reg > 0.0:\n			voto_final = float(detalle[\"voto_nacional\"])","		if false:\n			voto_final = float(detalle[\"voto_nacional\"])","con ruido el voto final no sale del detalle"),
 ("V14",MM,"umbral, r_reg, _m.estado.semilla, _m.estado.ciclo, _m.estado.ronda_electoral)","umbral, r_reg, _m.estado.semilla, _m.estado.ciclo, 1)","la vuelta no llega al ruido"),
 ("V15",MM,"var ajuste_nacional := _m.estado.ind(\"aprobacion\") - _m.regiones.promedio(_m.estado)","var ajuste_nacional := 0.0","sin ajuste nacional a las regiones"),
]
sel=[x for x in M if not sys.argv[1:] or x[0] in sys.argv[1:]]
for mid,arch,viejo,nuevo,desc in sel:
    d=f"/tmp/claude-0/mut/{mid}"; shutil.rmtree(d,ignore_errors=True)
    shutil.copytree(W,d,ignore=shutil.ignore_patterns(".git"),symlinks=True)
    p=f"{d}/{arch}"; t=open(p,encoding="utf-8").read()
    if t.count(viejo)!=1: print(mid,"NO_APLICA",t.count(viejo)); continue
    open(p,"w",encoding="utf-8").write(t.replace(viejo,nuevo))
    env=dict(os.environ,HOME=d+"/home",XDG_DATA_HOME=d+"/home/.local/share"); os.makedirs(env["HOME"],exist_ok=True)
    subprocess.run(["godot","--headless","--import","--path",d],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=300)
    muerto=""
    for t_args in [["tests/fuzz_ruido_eleccion.gd","--","12","6600"],["tests/test_voto_regional.gd"],["tests/test_voto_regional_bordes.gd"],["tests/fuzz_voto_regional.gd","--","300","16","8800"]]:
        try:
            r=subprocess.run(["godot","--headless","--path",d,"-s"]+t_args,env=env,capture_output=True,text=True,timeout=280); out=r.stdout+r.stderr; rc=r.returncode
        except subprocess.TimeoutExpired: out,rc="TIMEOUT",124
        f=[l for l in out.splitlines() if l.startswith("FALLO") or "SCRIPT ERROR" in l]
        if rc!=0 or f:
            muerto=t_args[0].split("/")[1]+": "+(f[:1] or [""])[0][:110]; break
    print(mid,desc,"->","MUERTO por "+muerto if muerto else "SOBREVIVE",flush=True); shutil.rmtree(d,ignore_errors=True)
