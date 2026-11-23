# Estado real de las fases (23 nov 2026)

| Fase | Criterio de salida del plan | Estado | Evidencia |
|---|---|---|---|
| 0 · Prototipo de texto | Una partida de 4 años corre sin pantalla y es reproducible | **Cerrada** | `tests/test_prueba_oro_4_semanas.gd`, `test_prueba_oro_30_dias.gd`, `test_prueba_oro_completa.gd`; `sim/estado_simulacion.gd` 149 líneas y `sim/motor_turno.gd` < 220; `tools/validate_data.py` |
| Enmienda de Cierre | Test de 8 preguntas, partido propio, campaña de 8 turnos, elección con umbral de `leyes.json` | **Cerrada** | `tests/test_enmienda.gd` |
| 1 · Android jugable | Una partida completa se juega en un teléfono real | **Parcial**: APK de depuración (≈ 30 MB) exportable; **sin prueba en teléfono real** | `docs/ANDROID.md` |
| 2 · 3D y animaciones | < 800 MB y 30 fps estables | **Parcial**: Comité y obras en 3D real; **rendimiento en teléfono sin medir** (solo memoria estática en headless) | `tests/test_presupuesto.gd` |
| 3 · Comité cerrado | 3 a 5 corredores completos con 2D y 3D | **Cerrada en código** (5 corredores, trazado propio con Dijkstra) | `tests/test_grafo.gd` |
| 4 · Contenido y prueba cerrada | 12+ testers durante 14 días sin fallos graves | **Contenido listo, prueba cerrada pendiente** (no la puede cumplir un agente) | 58 cartas, 40 eventos, `tests/test_balance.gd`; `docs/GOOGLE_PLAY.md` |

## Pendientes que requieren a una persona
Prueba en teléfono real, keystore de release y cuenta de Play, 12+ testers por 14 días, y verificación de artículos constitucionales y licencias (`docs/DATOS.md`).

## Pull requests
El repositorio no tiene ninguna rama base distinta de `ccr-ec102a3c-giitie`, por lo que no se puede abrir un PR en borrador contra una base. No se creó `main`. Cuando exista una base, abrir el PR desde esta rama con el resumen de `docs/DIFERENCIAS_MAQUETA.md` y de este documento.

## Maqueta en Figma
Las herramientas `mcp__Figma__` están disponibles, así que no es un bloqueo técnico ni humano. El motivo por el que no se comparó contra Figma es que **no existe una maqueta en Figma**: la maqueta de referencia es el PDF del Documento Maestro, y el único archivo de Figma del proyecto ("Presidente de Chile - arte de cartas") contiene solo las ilustraciones de las cartas. No hay clave de maqueta que consultar con `get_design_context` o `get_screenshot`.

Las comparaciones fotograma a fotograma contra el PDF están en `docs/comparacion/` y las diferencias en `docs/DIFERENCIAS_MAQUETA.md`.

**Decisión abierta (cuesta créditos de IA del plan de Figma):** crear una maqueta en Figma a partir del PDF y del juego para poder comparar con esas herramientas. Si se aprueba, se haría con `use_figma` y se compararía pantalla por pantalla.

## Ampliación de alcance (23-nov-2026, autorizada por el usuario en su mensaje directo)

- Alcance: base masiva de proyectos públicos reales, leyes BCN como límites legales, proyectos de ley, reformas constitucionales (plebiscitos 2022/2023), eventos reales, cartas y pantallas nuevas. Inicio del juego: domingo 16-nov-2025; 2ª vuelta 14-dic-2025; cambio de gobierno miércoles 11-mar-2026.
- Sesiones: A `datos/proyectos-publicos`, B `datos/leyes-eventos`, Revisor `revision/auditoria`. Cada mecánica o pantalla nueva debe documentar su fuente.
- Pendiente: subir los datos a `main` (la rama no existe aún; se crea tras la revisión), cartera de la RM (sin cartera oficial publicada por SECTRA; se busca en fuentes oficiales alternativas, citadas), tope de ilustraciones Figma.

### C3 resuelto (calendario real y segunda vuelta)
- Campaña desde el 21-sep-2025 (8 semanas) hasta la 1ª vuelta del 16-nov-2025; si no se supera el umbral pero sí `umbral_pasa_balotaje`, 4 semanas más hasta la 2ª vuelta del 14-dic-2025; el mandato arranca el 11-mar-2026 (la transición no se juega por turnos). Parámetros en `data/leyes.json` (`calendario`, `hemiciclo.semanas_balotaje`, `umbral_pasa_balotaje` — este último ilustrativo).
- `sim/motor_mandato.gd#resolver_eleccion`; `estado.ronda_electoral`; replay y pruebas actualizados (`Bots.elegir`). Mecánica nueva: segunda vuelta. Fuente: Servel (`fuentes.json#servel_calendario_2025`).

### Cartas reales (fase de ampliación)
- `tools/generar_cartas.py` genera `data/cartas_reales.json` (53 cartas) desde las bases reales: 25 obras (proyectos públicos en idea/perfil/diseño/licitación + 5 en ejecución, por inversión), 20 proyectos de ley en tramitación (Senado) y 8 reformas constitucionales (4/7, CPR art. 127: quórum verificado). Se cargan junto a `cartas.json` (`Datos.cargar_todo`).
- Los hechos (nombre, región, estado, inversión, boletín) son reales y citan fuente; las magnitudes de efectos son ilustrativas (`meta.cifras_ilustrativas`). Quórum de leyes ordinarias: ilustrativo (mayoría simple) con `nota_quorum`; no se verificó el quórum real de cada boletín.
- Pendiente: las 177 obras restantes y ~1.250 boletines quedan en la base de datos, no como cartas (con >110 cartas el balance se rompía: ver `test_balance`). Opción: desbloquearlas por fecha/temporada.
- Balance: umbral de victoria 51 y `umbral_pasa_balotaje` 38; descarte de 2 cartas por turno (`mano.descartes_por_turno`) para que la mano no se atasque; bots no saturan la capacidad de ejecución.
- Revisado el merge de `fuentes.json` y `validate_data.py`: unión por id (24 fuentes), todas las validaciones de ambas ramas activas.

### Una carta por proyecto público (actualiza la sección anterior)
- `tools/generar_cartas.py` genera ahora UNA carta por cada uno de los 230 proyectos públicos, según su estado real al arrancar: idea/perfil/diseño/licitación = obra completa; en ejecución = "Acelerar" (tramo final, 90 días); terminado = "Inaugurar" (efecto inmediato). Más 20 proyectos de ley y 8 reformas constitucionales. Total 258 cartas reales.
- Para no romper el balance, cada mazo incluye solo `mano.reales_en_mazo` (15) proyectos sorteados con la semilla; todos terminan circulando. Las cartas de proyecto son únicas (se ejecutan una vez por partida).
- Pendiente: cartas por proyecto de ley (1.044 en tramitación) y filtrado por región/ministerio de cada proyecto; ilustraciones con Canva por sector.

### Eventos reales en el juego
- `tools/generar_eventos.py` -> `data/juego_eventos_reales.json` (38 eventos): hitos verificados con fuente primaria (leyes publicadas, reformas constitucionales) ubicados por fecha real: 6 en campaña (desde el 21-sep-2025) y 32 en gobierno (desde el 11-mar-2026; día = fecha − 11-mar-2026 + 1). No se juegan los resultados electorales reales (la elección la decide el jugador) ni la transición dic-2025/mar-2026. Sin nombres de políticos (roles). Efectos ilustrativos (`meta.cifras_ilustrativas`).
- Quórum 4/7 (art. 127 CPR): Ley 21.481 (2022) lo estableció; consta en el texto actualizado de la Constitución (BCN, 7-oct-2025), verificado por la sesión de datos. Pendiente: contraste contra el texto consolidado de LeyChile y la historia de la ley (BCN responde 401 a clientes automáticos): no se declara "verificado contra el texto oficial completo".
- Revisión de las 230 cartas de proyecto: todas citan un id de `fuentes.json` (con fecha de corte) y rotulan cifras ilustrativas.

### Decisiones abiertas (para confirmar con el usuario)
- **Fecha de inicio 21-sep-2025:** NO viene de una fuente. Es derivada por mí de dos datos: el usuario pidió empezar "antes del domingo 16-nov-2025" (1ª vuelta) y la Enmienda de Cierre fija 8 semanas de campaña (56 días): 16-nov-2025 − 56 días = 21-sep-2025. Parámetro en `data/leyes.json › calendario.fecha_inicio_campana`; se cambia ahí sin tocar código (los eventos reales de campaña se regeneran con `python3 tools/generar_eventos.py`, que hoy tiene la misma constante).
- **Nombres de políticos:** los eventos y cartas usan roles, sin nombres propios (criterio más estricto que CLAUDE.md, que permite políticos reales con alias satíricos). Falta decidir si se usan alias y cuáles.
- **"1.040 proyectos":** interpretado como los ~1.044 proyectos de ley en tramitación + los 230 proyectos públicos.
- Las ramas `feat/mecanicas-v2` y `datos/cartas-1040` (sesiones delegadas) se revisan contra la Enmienda, validate_data y pruebas de oro antes de integrarlas; nada va a `main` sin confirmación.


### Mecánicas v2 en `sim/` (DISENO_V2, rama `feat/mecanicas-v2`)
- **Gabinete** (`sim/motor_gabinete.gd`): `estado.gabinete` (8 ministros, `leyes.gabinete.tamano`). Se elige con `MotorTurno.elegir_gabinete(ids)` en campaña o en la semana 1 de gobierno; entrada de guardado `gabinete`, soportada en `Partida.reproducir`. Si no se elige, hay un gabinete por defecto determinista (primer ministro de cada categoría). Una carta está disponible si su categoría coincide con la `categoria_afin` de algún ministro; `politica`, `comite` y `estado` siempre lo están; `descentralizacion` se asimila a `politica` (alias en `leyes.gabinete.categorias_alias`, porque no existe ministro afín).
- **Disponibilidad** por carta (`disponibilidad`: `anio_desde`/`anio_hasta` = año de gobierno 1–4, `evento` (se guarda en `estado.eventos_ocurridos`), `fiscal_min` (valor vigente del indicador), `meta` (`estado.metas_cumplidas`)). El mazo solo reparte cartas disponibles (`sim/motor_mazo.gd`); desbloqueos por meta, evento o inicio de año suben al tope del mazo.
- **Mano continua**: inicial de 5; al jugar o delegar una carta entra otra al instante. Movimientos por turno: 5 (`mano.pa_por_turno`; el campo sigue llamándose `pa_actual`/`pa_maximo` para no romper la UI). `costo_carta` se acota a 1–3 (`mano.costo_min/costo_max`): las 17 cartas reales de costo 4 quedan en 3 sin tocar `data/`.
- **Delegación**: `MotorTurno.delegar_carta(idx, ministro, region)`; hasta 2 por turno, sin gastar movimientos; probabilidad de fallo = base + riesgo_escandalo·peso + riesgo_ejecucion/100·peso − bono_ejecucion·peso (+ recargo si la carta es de otra cartera), acotada; si falla: efecto ×0,5 y 50 % de escándalo. Todo en `leyes.delegacion` (cifras ilustrativas). `prob_fallo_delegacion(idx, ministro)` sirve para mostrarla en la UI. `jugar_carta` con `ministro_id` (camino antiguo con descuento de costo) se mantiene por compatibilidad.
- **Movimientos internos** (`sim/motor_movimientos.gd`, solo gobierno, 3 por turno, aparte de los movimientos de cartas): `buscar_meta`, `ajustar_sector`, `reducir_errores`, `acelerar_proyecto`. `data/metas.json` (45 metas `meta_<categoria>_1..3`, generadas por `tools/generar_metas.py`, con fuente y cifras ilustrativas rotuladas; la meta N exige la N−1 y un ministro del sector).
- **Estado empresario**: 9 cartas `estado` (empresa pública, privatización, expropiación; 3 variantes cada una) en `data/cartas.json`, generadas por `tools/generar_cartas_estado.py`. Base legal: CPR art. 19 N°21 inc. 2 (actividad empresarial: quórum calificado) y N°24 (expropiación por ley); sin verificar contra el texto oficial completo. Efectos ilustrativos.
- **Guardado**: el partido se redondea a 6 decimales al iniciar (`EstadoSimulacion.normalizar`); sin eso el replay desde JSON difería en el último dígito de la aprobación regional (defecto previo expuesto al cambiar los datos).
- **Balance** (con 5 movimientos en lugar de 8): `test_balance` pasa sin relajar aserciones; el bot codicioso gana la elección en ~80 % (antes ~97 %), el azar ~20 %. Margen sobre la aserción (>70 %) estrecho: si el reparto de cartas cambia, ajustar `campana.*` en `leyes.json`, no las aserciones.
- Pruebas nuevas: `test_gabinete`, `test_delegacion`, `test_movimientos`; `test_guardado` amplía el replay (gabinete, delegación, metas).


- **Bono por aprobación** (§11; `leyes.bono_movimientos.tramos`): al final del amanecer de gobierno, movimientos = base 5 + 1 por cada umbral 60/65/70/75/80 superado + 2 por cada umbral 85/90/95/100. Interpretación literal de la especificación: con aprobación 90 son 5+5+4 = 14 movimientos y el máximo es 18; no se aplica en campaña. `estado.bono_mov` expone el desglose. Si el usuario quería un tope menor, basta cambiar los tramos en `leyes.json`.
- **Reposición** (§12; `MotorMazo.reposicion`, `leyes.mano.reposicion_cartas`=3): si tras jugar la mano queda vacía y quedan movimientos (o delegaciones), entran cartas disponibles aunque el sorteo del mazo las hubiera dejado fuera; acción `reposicion` {ids} en `registro_acciones`. Con mano continua solo ocurre cuando el mazo se agota.
- **Asesores** (§9; `sim/motor_equipo.gd`, `data/asesores.json` con 10 ficticios, `leyes.asesores`): hasta 3 distintos, +1 movimiento por turno desde el siguiente amanecer (no inmediato, para evitar contratar/despedir en bucle), un efecto positivo y uno negativo (por turno sobre un indicador, o multiplicador de efectos de las cartas de una categoría). La afinidad ideológica (distancia en ejes eco/inst entre asesor y partido) atenúa hasta 50 % el efecto negativo. Entrada de guardado `asesor`. Cifras ilustrativas.

- **Coalición** (§10; `sim/motor_coalicion.gd`, `data/coalicion.json` con 5 partidos ficticios, `leyes.coalicion`): hasta 3 aliados, cada uno con ideología (ejes eco/inst), escaños y una petición de poder (ministerios, asesores y una categoría de carta). `asignar_cuota(partido, "ministerio"|"asesor", id)` entrega cuotas; la satisfacción (0–100) converge cada turno a `cumplimiento × (1 − peso_ideologia × (1 − afinidad))`, sube al jugar cartas de su categoría y determina: cohesión por turno, escaños que votan con el gobierno (`estado.apoyo_coalicion`, usado por `MotorLegal.votar/composicion`), movimientos internos (−1 si algún aliado está en malestar, +1 si todos están satisfechos) y la ruptura del pacto bajo el umbral (costo en cohesión y capital). Sin aliados no cambia nada (el balance de los bots, que no usan coalición, queda igual). Entradas de guardado: `coalicion` y `cuota`. Cifras ilustrativas; partidos ficticios.

### Decisiones abiertas (para confirmar con el usuario)
- **Fecha de inicio 21-sep-2025:** NO viene de una fuente. Es derivada por mí de dos datos: el usuario pidió empezar "antes del domingo 16-nov-2025" (1ª vuelta) y la Enmienda de Cierre fija 8 semanas de campaña (56 días): 16-nov-2025 − 56 días = 21-sep-2025. Parámetro en `data/leyes.json › calendario.fecha_inicio_campana`; se cambia ahí sin tocar código (los eventos reales de campaña se regeneran con `python3 tools/generar_eventos.py`, que hoy tiene la misma constante).
- **Nombres de políticos:** los eventos y cartas usan roles, sin nombres propios (criterio más estricto que CLAUDE.md, que permite políticos reales con alias satíricos). Falta decidir si se usan alias y cuáles.
- **"1.040 proyectos":** interpretado como los ~1.044 proyectos de ley en tramitación + los 230 proyectos públicos.
- Las ramas `feat/mecanicas-v2` y `datos/cartas-1040` (sesiones delegadas) se revisan contra la Enmienda, validate_data y pruebas de oro antes de integrarlas; nada va a `main` sin confirmación.
