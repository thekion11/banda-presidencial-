#!/usr/bin/env bash
# Vigilante de main: worktree limpio de origin/main, importación, suite completa (headless) y
# pruebas de interfaz con ventana real (xvfb, gl_compatibility) a 360x640.
# Uso: tools/vigilante_main.sh <godot> [directorio]   Resultado: línea final «VIGILANTE hash duración fallos».
set -u
GODOT="${1:?uso: vigilante_main.sh <godot> [directorio]}"
DIR="${2:-/tmp/vig}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
t0=$(date +%s)
echo "INICIO $(date -u +%H:%M:%S) UTC"
git -C "$REPO" fetch -q origin
git -C "$REPO" worktree remove --force "$DIR" 2>/dev/null
git -C "$REPO" worktree add -q --detach "$DIR" origin/main
cd "$DIR" || exit 2
hash=$(git rev-parse --short HEAD)
"$GODOT" --headless --import --path . >/dev/null 2>&1
fallos=0
tools/run_all_tests.sh "$GODOT" > "$DIR.suite.log" 2>&1 || fallos=$((fallos + 1))
grep -q "TODO EN VERDE" "$DIR.suite.log" || fallos=$((fallos + 1))
for res in 360x640; do  # 390x844 no: esas pruebas simulan alto 693 y chocan con una ventana real de 844 (artefacto de la prueba, no del juego)
  for t in claridad textos tactil; do
    out=$(timeout 280 xvfb-run -a "$GODOT" --path . --rendering-method gl_compatibility --resolution "$res" -s "tests/test_$t.gd" 2>&1)
    if echo "$out" | grep -q "SCRIPT ERROR\|Parse Error\|FALLO" || ! echo "$out" | grep -q " OK"; then
      echo "FALLA UI: $t a $res"; echo "$out" | grep "SCRIPT ERROR\|Parse Error\|FALLO" | head -3
      fallos=$((fallos + 1))
    fi
  done
done
echo "VIGILANTE $hash inicio-fin $(date -u -d @$t0 +%H:%M)-$(date -u +%H:%M) UTC, $(( $(date +%s) - t0 )) s, fallos: $fallos"
echo "$fallos" > "$DIR.exit"
exit $(( fallos > 0 ? 1 : 0 ))
