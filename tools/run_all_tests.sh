#!/usr/bin/env bash
# Ejecuta TODO lo que ejecuta el CI (.github/workflows/ci.yml), en el mismo orden: validadores de datos, todas las tests/test_*.gd y el fuzz del núcleo.
# Uso: tools/run_all_tests.sh [ruta_godot]    (por defecto `godot`; con GODOT=/ruta/godot también sirve)
# Termina con código distinto de 0 si algo falla y lista al final lo que falló.
cd "$(dirname "$0")/.." || exit 1
GODOT="${1:-${GODOT:-godot}}"
fallos=()
paso() { echo "== $1"; shift; "$@" || fallos+=("$1 $2 $3"); }
paso "validate_data" python3 tools/validate_data.py
paso "check_limits" python3 tools/check_limits.py
paso "check_constantes" python3 tools/check_constantes.py
paso "validate_tipos" python3 tools/validate_tipos.py
paso "check_presupuesto" python3 tools/check_presupuesto.py
paso "validar_textos" python3 tools/validar_textos.py
paso "check_entradas" python3 tools/check_entradas.py
paso "api_documentada" python3 tools/generar_api.py --verificar
paso "test_validate" python3 tools/test_validate.py
paso "validar_metro" python3 tools/validar_metro.py --verificar
paso "informe_alcanzabilidad" python3 tools/informe_alcanzabilidad.py
"$GODOT" --headless --import --path . > /tmp/import.log 2>&1
grep -q "SCRIPT ERROR" /tmp/import.log && fallos+=("import con errores de script")
for f in tests/test_*.gd; do
  t=$(basename "$f" .gd)
  echo "== $t"
  timeout 300 "$GODOT" --headless --path . -s "$f" 2>&1 | tee "/tmp/$t.log"
  if [ "${PIPESTATUS[0]}" -ne 0 ] || grep -qE "SCRIPT ERROR|Parse Error|Could not find type" "/tmp/$t.log"; then fallos+=("$t"); fi
done
echo "== fuzz_acciones"
"$GODOT" --headless --path . -s tests/fuzz_acciones.gd -- 60 7000 || fallos+=("fuzz_acciones")
if [ ${#fallos[@]} -gt 0 ]; then
  echo "FALLARON: ${fallos[*]}"
  exit 1
fi
echo "TODO EN VERDE"
