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
