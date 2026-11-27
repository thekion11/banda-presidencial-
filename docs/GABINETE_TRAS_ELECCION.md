# El gabinete se elige después de la elección (27-nov-2026)

**Petición del usuario (vía la coordinadora, 27-nov-2026):** «la elección del gabinete es después de las elecciones».

## Diseño (mínimo, sin etapa nueva ni cambio de guardado)
1. **Campaña:** el gabinete es el automático de siempre (`por_defecto()`: los 25 ministerios con relleno equilibrado), así que las cartas de campaña no dependen de ninguna elección del jugador. La interfaz deja de ofrecer elegir gabinete en la campaña (el motor lo sigue permitiendo para no invalidar guardados viejos).
2. **Elección:** si pierdes, no hay gabinete (fin de la carrera). Si ganas (1ª o 2ª vuelta), el motor queda en el **turno 1 de gobierno**; quien llama hace `iniciar_turno()` como hoy (amanecer y eventos de esa semana).
3. **Transición:** mientras `motor.gabinete.pendiente_confirmar()` sea verdadero (turno 1 de gobierno y ninguna entrada «gabinete» después de la votación), la pantalla del gabinete va **antes** del día; la regla del motor ya permite nombrar gabinete en la primera semana de gobierno.
4. **Confirmar:** `motor.elegir_gabinete(ids)` con los 25 ids (`motor.gabinete.rellenar(elegidos, modo)` completa los vacíos sin pisar lo elegido). Confirmar el gabinete preseleccionado también cuenta: llámalo con `motor.estado.gabinete` y queda registrado. Tras confirmar, `pendiente_confirmar()` pasa a falso y se muestra el día.
5. **Recarga:** el estado se deduce del historial, así que si la app se cierra en la pantalla del gabinete, al continuar `pendiente_confirmar()` sigue verdadero. El orden de las entradas del guardado (`eleccion`, luego `gabinete`) es el mismo que en vivo: el replay no cambia y **no hay migración ni cambio de versión de guardado**.
6. **Ciclos posteriores (reelección o nueva campaña):** se conserva el gabinete anterior como selección inicial y puede cambiarse en la transición.
7. **Afiliados a un partido existente:** igual que quien funda.
8. **Efectos de ministros, coalición y delegación:** solo desde el gobierno (sin cambios: dependen de `etapa == "gobierno"`). El amanecer del turno 1 usa el gabinete automático (diferencia despreciable: estilo y afinidad de una semana); desde que se confirma, el gabinete elegido.
9. **Tests y oros:** sin cambios (el motor no cambia de comportamiento); `tests/test_transicion_gabinete.gd` fija el contrato.
10. **Qué toca a la interfaz (visual):** la pantalla del gabinete pasa de «antes de la campaña» a «paso de Transición tras ganar»; botón principal «Confirmar gabinete».

## Pruebas
`tests/test_transicion_gabinete.gd`: sin transición en campaña; tras ganar, pendiente; recargar sin confirmar sigue pendiente; confirmar el preseleccionado cuenta; el replay confirmado no está pendiente; en el turno 2 no hay transición.
