# Entrega del 27-nov-2026 (una página)

Estado al volver: `main` y la rama de trabajo están al día; la suite completa (`tools/run_all_tests.sh`) está en verde. Última actualización: 27-nov-2026 (se actualiza hasta las 14:30 UTC).

## Qué se hizo (por sesión)
- **Núcleo (sim, datos, balance, herramientas):** motor determinista con guardado por eventos (40 veces más rápido, con respaldo `.bak`), validadores de datos y de tipos, 214 funciones documentadas, Monte Carlo con intervalos de confianza, pruebas de mutación y de invariantes, y un error real corregido (carta real duplicada en el mazo). Verificado contra fuentes oficiales: fechas y regla de mayoría del Servel, 11-mar-2026, quórum 4/7 de reforma constitucional y 10 fichas del Minsal (`VERIFICACION_CONSTITUCIONAL.md`). Nuevo para la UI: `motor.motivos_semana()`.
- **Diseño visual (game/):** zonas seguras, estados tardíos, fichas que caben con letra ×1,5, claridad (efectos a futuro, riesgo, costo del rechazo, «faltaron N» en votaciones), `GUIA_ESTILO.md` y `CUMPLIMIENTO_UI.md`.
- **Búsqueda de fallas (tests):** fuzz, barridos de valores extremos y supervivientes de mutación; PR #8 con CI en verde.
- **Coordinación:** colas de trabajo y revisión cruzada entre sesiones.

## Decisiones tuyas, en orden de impacto (recomendación)
1. **D1 Duración** de la partida (hoy unas 6 sesiones de 20 min por mandato): mantener 208 semanas y medirlo en la prueba cerrada.
2. **D2 / D4 / D16 Dificultad y umbral 51 vs 52:** esperar datos de personas; dejar 52.
3. **D17 Congelar `data/` durante la prueba:** sí (cualquier cambio de datos descarta los guardados de los testers).
4. **D18 Regenerar `cartas_reales.json`:** no hasta después de la prueba (movería 102 cartas y los oros).
5. **D19 Test rápido de 3 preguntas por defecto** frente a las 8 de CLAUDE.md §2: dejarlo y enmendar CLAUDE.md.
6. **D14 Corrector de leyes rechazadas** (mecánica nueva): esperar la prueba.
7. **D15 Cohesión con desgaste** (−1,85/semana): mantener.
8. **Bono por aprobación 45–95 (hoy) vs 60–100:** mantener 45–95.
9. **Renderizador:** pasar a `gl_compatibility` (todo lo medido es con él; Vulkan no se pudo medir).
10. **Métricas locales con consentimiento** en la prueba cerrada: sí.
11. **Art. 25 y 66 de la Constitución** sin verificar (bcn.cl bloquea desde el entorno): aportar el PDF vigente.
12. **Firma y publicación:** keystore, licencias del arte con IA, Google Play en pausa.
13. **PR #8:** pasar a Ready y fusionar; **`main` como rama por defecto** en GitHub.

## Qué probar en un teléfono (`MEDICION_TELEFONO.md`)
30 fps estables en la escena urbana, RAM por pantalla (límite 800 MB), tiempo de carga de un mandato, y que la huella del guardado coincida entre dispositivos; probar también el cambio de apariencia con letra grande y la barra de gestos.

## Riesgos conocidos
- Nada se midió en un teléfono real ni con Vulkan: los números de rendimiento son de un PC.
- En Normal los bots que juegan bien ganan alrededor de 94 %: puede ser fácil.
- 229 proyectos reales siguen sin verificar contra su fuente; la ficha dice «ilustrativo».
- Con `data/` modificado a mano y sin pasar por `validate_data.py`, algunos valores extremos pueden colgar el motor.
