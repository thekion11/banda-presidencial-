# Auditoría: estructura del juego vs. la vida real (solo Chile)

Estado al 23 nov 2026. Marcado: **Hecho** (modelado), **Simplificado** (aproximación consciente), **Pendiente** (no modelado todavía), **Verificar** (dato citado de memoria o de los documentos, sin contrastar con el texto oficial).

## Estructura institucional

| Elemento real | Estado en el juego | Notas |
|---|---|---|
| Mandato presidencial de 4 años, sin reelección inmediata | **Hecho** | 1 mandato = 208 turnos semanales. No hay reelección. |
| Senado de 50 miembros | **Hecho** | `leyes.json › hemiciclo.total_senadores`. Verificar vigencia legal. |
| Congreso **bicameral** (Cámara de 155 diputados + Senado) | **Hecho (extensión)** | Los documentos modelaban solo el Senado. Se añadió la Cámara: una ley necesita ambas (`votos_minimos_camara`). En pantalla: dos hemiciclos con bancada propia, aliados y oposición; las votaciones se muestran cámara de origen → cámara revisora → Tribunal Constitucional; los proyectos en tramitación indican en qué cámara están. Prueba: `tests/test_congreso.gd`. |
| Quórums por tipo de norma | **Hecho / Verificar** | Los umbrales se leen de `leyes.json` con cita de artículo, **marcada como sin verificar** (`fuentes.json › verificado_contra_texto: false`). El validador avisa en cada ejecución. |
| Tribunal Constitucional | **Simplificado** | Recurso con probabilidad por tipo de norma; si el TC acoge, se pierde el efecto y capital político. No se modelan composición ni plazos. |
| Potestad reglamentaria (decretos) | **Simplificado** | Decreto supremo: 7 días, sin votación, con riesgo TC. No se modela toma de razón de la Contraloría. |
| Elección presidencial con **segunda vuelta** | **Simplificado** | Los documentos usan una sola votación con umbral 50 % sobre la aprobación. Real: si nadie supera el 50 % de los votos válidos hay balotaje entre las dos primeras mayorías. **Pendiente** (propuesta para Fase 4: segunda vuelta con 1 turno extra y candidatos rivales). |
| 25 ministerios | **Hecho** | Lista de 25 carteras (con Seguridad Pública). Alias ficticios. Verificar nombres oficiales vigentes. |
| 16 regiones | **Hecho** | Mapa con límites reales simplificados; población del Censo 2017 (cifras de memoria, **verificar** con INE; ya existe Censo 2024). |
| Cuenta Pública anual y Ley de Presupuestos | **Hecho (calendario)** | Eventos programados en los días ~82 y ~204 de cada año del mandato (1 de junio y 30 de septiembre contados desde el 11 de marzo). |
| Ley de Presupuestos con plazo de 60 días en el Congreso | **Pendiente** | Hoy es solo un evento con efectos. |

## Pendientes de realismo (candidatos para después de la Fase 4)

Veto presidencial, urgencias legislativas (suma urgencia, discusión inmediata), acusación constitucional, estados de excepción, Contraloría, elecciones parlamentarias a mitad de período, comisiones mixtas, reforma constitucional con quórum reforzado, plebiscitos.

## Inconsistencias detectadas en los documentos originales

1. El árbol de aceptación de la Guía pide `motor_turno.gd` bajo 220 líneas, pero la misma Guía fija 450 líneas como máximo. Se respetó 450 y el motor se partió en `motor_legal`, `motor_obras` y `motor_mandato`.
2. El test del documento llama `jugar_carta(0, "min_vivienda")` en un estado de campaña, donde no hay gabinete. Se definió: **en campaña no se delega**; el test de Fase 0 fuerza `etapa = "gobierno"`.
3. `resolver_eleccion_presidencial()` del documento deja `turno_actual = 1` pero no regenera PA ni roba mano; se añadió `iniciar_turno()` para que reproducir un guardado dé el mismo resultado que jugar en vivo.
4. El documento lista 3 preguntas de ideología pero exige 8; se redactaron 8 (las 3 originales intactas, con una errata corregida: "Plebisicitar" → "Plebiscitar").
5. La suma de 8 respuestas satura fácilmente ±1.0; las 5 preguntas nuevas usan deltas menores (±0.10 a ±0.30) para no aplastar el rango.
6. `aprobacion` empieza en 90 en la maqueta (cifra ilustrativa) pero la fórmula del partido la fija entre 32 y 46; se usa la de la fórmula.


> **Actualización 23-nov-2026:** la segunda vuelta presidencial YA está modelada (4 semanas de campaña adicionales; ver `docs/ESTADO_FASES.md` y `docs/DISENO_V2.md`).
