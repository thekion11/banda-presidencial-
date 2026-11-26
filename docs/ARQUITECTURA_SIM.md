# Mapa de dependencias de `sim/` y tamaño de `data/` (auditoría del 26-nov-2026)

Generado leyendo las referencias a `class_name` entre los 26 archivos de `sim/` (sin comentarios ni textos).

## Dependencias
- **Estrella con centro en `MotorTurno`.** Los 12 módulos del motor (cartas, mazo, eventos, gabinete, mandato, coalición, equipo, movimientos, sectra, obras, legal, efectos) se conocen solo a través de `MotorTurno` (cada uno guarda una referencia débil `m`); entre sí casi no se tocan. Las únicas dependencias directas entre módulos son: `MotorEventos → DirectorEventos`, `MotorMovimientos → Encuestas, MotorObras`, `MotorCartas/MotorMazo → IndicesCartas`, `MotorEfectos/MotorObras → Regiones`, `Encuestas/Regiones/Datos/EstadoSimulacion → Huella`.
- **Quien más depende de otros:** `MotorTurno` (17 clases, es el compositor), `Partida` (4), `MotorMovimientos` (3), `Instantanea` (3). **Más usadas:** `MotorTurno` (13 clases), `EstadoSimulacion` (8), `Huella` y `IndicesCartas` (4 cada una).
- **Hojas sin dependencias:** `Huella`, `IndicesCartas`, `GrafoTrazado`, `ValidarGuardado`, `DirectorEventos`, `MotorCoalicion`, `MotorEquipo`, `MotorGabinete`, `MotorMandato`, `MotorSectra`.
- **Ciclos (3 componentes):**
  1. `MotorTurno` ↔ sus módulos: es el diseño (compositor y módulos con referencia débil), no un acoplamiento accidental. Los módulos no se llaman entre sí en círculo.
  2. `EstadoSimulacion` ↔ `ResumenEstado`: el resumen lee el estado y el estado lo expone. Es un ciclo de tipos, no de datos; no tiene efectos en tiempo de ejecución.
  3. `Instantanea` ↔ `Partida`: `Partida.cargar` usa la instantánea y esta usa `Partida.armar` para reconstruir el motor. Podría romperse moviendo `armar` a una clase propia; no vale la pena hoy.
- **Capas:** `sim/` no importa nada de `game/` ni nodos de Godot (verificado por `tools/check_limits.py`).

## Tamaño de `data/` y tiempos de carga
- `data/` pesa 11 MB en total (incluye relieve, grafo urbano y edificios, que no son JSON de balance).
- Archivos JSON de más de 1 MB: `data/cartas_reales.json` (2,3 MB, **cargado por el juego**, 62 ms de los ~118 ms de `Datos.cargar_todo`) y `data/bcn/proyectos_ley.json` (1,6 MB, solo investigación: el juego no lo carga). Todo lo demás es menor de 1 MB (`geo/urbano_real.json` 0,98 MB lo carga solo la pantalla del mapa).
- Tiempos medidos: cartas_reales 62 ms, grafo_urbano 25 ms, cartas 14 ms, sectra_planes 5 ms, resto menor de 4 ms. La carga del guardado no los paga de nuevo: usa la instantánea (≈ 12 ms) y `Datos.huella_rapida`.
- **Propuesta (no aplicada, sin urgencia):** partir `cartas_reales.json` por categoría de ministerio en archivos de ≈ 500 KB que `Datos.cargar_todo` concatene en el mismo orden. Las huellas no cambian porque el orden del catálogo es el mismo; la ganancia es de revisión en git (diffs legibles) y no de velocidad, ya que el total leído es igual. Si se hace, hay que actualizar `EXTRAS` y `tools/generar_cartas.py`, y correr `test_determinismo` para confirmar las huellas.

## Índice de API
Todas las funciones públicas de `sim/` (210) llevan documentación y se listan, con su firma, en `docs/API_SIM.md` (generado por `tools/generar_api.py`; el CI falla si una función pública queda sin documentar).
