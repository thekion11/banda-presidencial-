# Guía para quien herede el proyecto (1 página, 26-nov-2026)

**Presidente de Chile**: simulador político por turnos para Android (Godot 4.7, GDScript). Empieza por `CLAUDE.md` (reglas obligatorias), `docs/RESUMEN_DECISIONES.md` (qué espera al dueño) y `docs/DECISIONES.md` (por qué cada cosa es como es).

## Estructura
| Carpeta | Qué hay | Regla |
|---|---|---|
| `sim/` | Núcleo determinista (sin nodos): estado, motores de turno, cartas, eventos, Congreso, gabinete, coalición, guardado | Sin `game/`; máx. 450 líneas por archivo (`motor_turno.gd` y `estado_simulacion.gd` bajo 220); ningún número de balance (`tools/check_constantes.py`); toda función pública documentada (`tools/generar_api.py`; índice en `docs/API_SIM.md`) |
| `game/` | Pantallas, componentes, tema, audio | La maqueta manda; paleta congelada; ≥ 10 pt y zonas táctiles ≥ 44 px |
| `data/` | JSON del juego (cartas, eventos, leyes, ministros, regiones, fuentes…) | Todo dato real lleva fuente y fecha de corte en `data/fuentes.json` |
| `tools/` | Validadores, generadores de datos, análisis | Se ejecutan en el CI |
| `tests/` | Pruebas (`test_*.gd`), fuzz, oros y análisis | Una tarea = una prueba |
| `docs/` | Decisiones, diseño, informes | Cada decisión del dueño se anota el mismo día en `DECISIONES.md` |

## Cómo probar
```
godot --headless --import --path .        # tras agregar clases nuevas
tools/run_all_tests.sh godot               # TODO lo del CI (≈ 4 min): validadores, test_*.gd y fuzz
godot --headless --path . -s tests/test_xxx.gd
```
Una prueba que no compila **no falla sola**: el CI y `run_all_tests.sh` buscan «SCRIPT ERROR» y aplican 300 s de límite. Antes de subir: fetch, merge de `origin/main`, suite en verde. Las pruebas de oro (`test_prueba_oro_*`, `tests/oro/huellas.json`) se regeneran solo si el cambio de resultado es intencional, **con el motivo explicado en el commit y tras correr `test_mutantes*` y `test_invariantes_estado`**: `test_determinismo` mata la mitad de los mutantes de `sim/`, y si se regenera sin mirar, esa red queda ciega. Al tocar `ValidarGuardado` o el formato del guardado, corre TODOS los `test_*.gd` (`tools/run_all_tests.sh`), no una lista corta.

### Regresión visual (capturas de referencia)
`tests/golden/<tamaño>/<pantalla>.png` guarda 11 pantallas clave (menú, afiliación, test, gabinete, día, Congreso, Nación, mapa urbano, votación, elección y fin), capturadas con **ventana real** (1×) en 360×640, 390×844 y 412×915, en 256 colores para que pesen poco (≈ 1,6 MB en total).
```
python3 tools/regresion_visual.py               # captura de nuevo y compara; tabla y diferencias en /tmp/regresion_visual/diferencias
python3 tools/regresion_visual.py --generar     # regenera tests/golden
```
- Necesita `xvfb-run` y Pillow. En el CI es un paso **no bloqueante**: la tabla y las imágenes de diferencias (referencia | nueva | píxeles distintos en rojo) quedan en el artefacto `regresion-visual`.
- Tolerancia: un píxel cuenta como distinto si algún canal difiere en más de 24, tras llevar la captura nueva a la paleta de la referencia. Una pantalla falla si más del 1,5 % de sus píxeles cambia. Un margen así absorbe el antialias de otra versión de Mesa, no un cambio de diseño.
- **Regenera las referencias solo cuando el cambio visual es a propósito.** Primero mira las diferencias, después corre `--generar` y explica en el commit qué cambió y por qué (por ejemplo: «hemiciclo: la marca del mínimo ya no tapa el texto»). Si una pantalla cambia sin que la hayas tocado, es una regresión: no la regeneres.
- Agregar o quitar cartas de `data/` cambia el mazo y por lo tanto **la mano del día** en la captura: es esperado. Mira que la diferencia sea solo la mano y regenera.
- Las capturas tienen que ser deterministas: `tests/golden_capturar.gd` borra el guardado antes de empezar (el menú cambia si hay partida), esconde los avisos que se van solos y corre sin animaciones. Si agregas algo que se mueve aunque «Animaciones» esté apagado, la comparación lo marcará. Eso pasó con la mano, que volaba igual: ahora `tests/test_reglas_ui.gd` lo prueba.

## Convenciones
- Identificadores en español sin tildes (`snake_case`); comentarios y textos en español con tildes; sin emojis.
- Guardado por eventos: solo semilla, partido e historial. Si cambias las claves del guardado, sube `ValidarGuardado.VERSION` (`tests/test_formato_guardado.gd` lo exige) y mira `docs/FORMATO_GUARDADO.md`.
- Determinismo: todo azar sale del RNG de la partida; no uses `randf()` global ni reloj en `sim/`.
- Commits pequeños; nada de secretos (el `.gitignore` cubre keystores, `.env` y claves).

## Alcance congelado
Hasta cerrar la Fase 4 y la prueba cerrada **no se agregan mecánicas ni pantallas** fuera de las autorizadas por el dueño (lista en `CLAUDE.md §2`). Una idea nueva va como propuesta (`docs/PROPUESTAS.md`) o fila en `docs/DECISIONES_PENDIENTES.md`, con costo y recomendación; no se implementa sin autorización. Toda mecánica nueva autorizada cita su fuente y su commit (`docs/TRAZABILIDAD_MECANICAS.md`).

## Agregar contenido (sin tocar código)
1. **Fuente**: agregar la entrada en `data/fuentes.json` (`id`, `institucion`, `titulo`, `url` https, `fecha_corte`, `vigencia_dias`, `es_ilustrativa`). Cifras inventadas: `es_ilustrativa: true` y rótulo «ilustrativo».
2. **Carta** (`data/cartas.json`): `id` único, `categoria` (área de ministerio), `costo_pa` 1 a 3, `titulo` ≤ 60 caracteres, `efectos` [{ind, delta}], `requisitos` {ley, quorum} (`ley` = un tipo de `leyes.json › tipos_ley`, o null), `fuente: "fuentes.json#id"`; opcionales: `corrector` (versión viable o por tramos), `disponibilidad` (año, evento, meta), `riesgo`, `diferido`. Cartas de proyectos reales: se generan con `tools/generar_cartas.py` desde `data/proyectos/` y `data/bcn/`; no se editan a mano.
3. **Evento** (`data/eventos.json`): `id`, `tipo` (`programado` con `dia_objetivo`, o `aleatorio_semilla` con `peso_sorteo`), `etapa`, `familia`, `titulo`, `descripcion`, `efectos_base`, `fuente`; con decisión: `opciones` [{texto, efectos, riesgo?, diferido?, cadena?, relacion?}]. Eventos reales: `tools/generar_eventos.py`.
4. **Ley / tipo de ley**: `data/leyes.json › tipos_ley` con su `articulo_constitucional`, regla y cita; verificar el artículo contra el texto oficial (BCN) antes de publicar.
5. **Validar**: `python3 tools/validate_data.py && python3 tools/validar_textos.py && python3 tools/validate_tipos.py`; luego `tools/run_all_tests.sh godot` (un dato nuevo cambia la huella de datos: los guardados viejos se descartan y los oros pueden cambiar).
