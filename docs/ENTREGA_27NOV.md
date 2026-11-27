# Entrega del 27-nov-2026 (una página)

Estado al volver: `main` y la rama de trabajo están al día; la suite completa (`tools/run_all_tests.sh`) está en verde. Última actualización: 27-nov-2026 (se actualiza hasta las 14:30 UTC).

## Qué se hizo (por sesión)
- **Núcleo (sim, datos, balance, herramientas):** motor determinista con guardado por eventos (40 veces más rápido, con respaldo `.bak`), validadores de datos y de tipos, 214 funciones documentadas, Monte Carlo con intervalos de confianza, pruebas de mutación y de invariantes, y un error real corregido (carta real duplicada en el mazo). Verificado contra fuentes oficiales: fechas y regla de mayoría del Servel, 11-mar-2026, quórum 4/7 de reforma constitucional y 10 fichas del Minsal (`VERIFICACION_CONSTITUCIONAL.md`). Nuevo para la UI: `motor.motivos_semana()`.
- **Diseño visual (game/):** zonas seguras, estados tardíos, fichas que caben con letra ×1,5, claridad (efectos a futuro, riesgo, costo del rechazo, «faltaron N» en votaciones), `GUIA_ESTILO.md` y `CUMPLIMIENTO_UI.md`.
- **Búsqueda de fallas (tests):** fuzz, barridos de valores extremos y supervivientes de mutación; PR #8 con CI en verde.
- **Coordinación:** colas de trabajo y revisión cruzada entre sesiones.

## Decisiones tuyas, en orden de impacto (recomendación)
**Actualización 27-nov:** aceptaste las recomendaciones; aplicadas D19, D20, D17 y el renderizador `gl_compatibility`; bono 45–95 y umbral 52 se quedan (DECISIONES §BJ). Lo que sigue es la lista original; lo no cerrado: Art. 25 y 66, keystore y licencias, métricas con consentimiento (falta diseño).
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

## Cartas del Plan Estratégico (nuevo, 27-nov)
16 cartas `plan_*` (AFP estatal, fondo soberano, industrialización, empresas estatales, COEVA, agua, transporte) hechas con el esquema actual, con riesgo y beneficio diferido (`PLAN_ESTRATEGICO_CARTAS.md`). **D20:** falta tu confirmación aquí para anotarlo en CLAUDE.md §2; mientras tanto se revierte con un commit. Entra antes de congelar `data/`.

## Tu petición del 27-nov: mapa con zoom y gabinete más atractivo
Texto literal: «El mapa del país debe agrandarse un poco para ver todas las regiones, además de poder hacerle zoom, la elección del personal del gabinete no es tan entretenida además de qué es solo un formulario, es poco atractivo». Visual lo implementa en `game/`; el núcleo ya expone las fichas y el efecto de nombrar a cada candidato (`DECISIONES.md` §BK). **D22 (tuya):** frases, biografías y retratos para los 75 candidatos exigirían descongelar `data/`.

## Lo hecho después de la primera versión (27-nov, tarde)
- **Elección con población** (`ELECCION_POBLACION.md`): voto por región con peso por habitantes, resultados por región en la pantalla de elección; no cambió el balance. **Ruido regional** (tu «Sí, ruido regional modesto»): el código está listo; falta escribir la fila `campana.ruido_eleccion_regional` (recomiendo 6) en `data/leyes.json` porque `data/` está congelado: **dime «descongela esa fila»**.
- **Gabinete tras la elección** (`GABINETE_TRAS_ELECCION.md`): se elige al ganar, no antes; sin cambios de guardado.
- **Salidas para la UI:** `motivos_semana`, ficha y efecto de cada candidato, voto por región.
- **Tu primer informe real de teléfono** (`PRUEBA_CERRADA_INFORMES.md`): 34 fps y 128 MB cumplen; el ritmo es ≈ 4 veces más lento que lo estimado (un mandato ≈ 7,6 h): D26. Aprobación 36,8 en la semana 9 es típica del juego casual.
- **Decisiones nuevas tuyas:** D21 (reformas 4/7 muy fáciles), D22 (gabinete atractivo: textos y retratos), D23 (ruido regional: confirmar), D24 (Congreso por geografía), D25 (proyectos de transporte de la RM y Aysén en SECTRA), D26 (ritmo).
- **Pendiente de tu confirmación para llegar a `main`:** el entorno bloqueó mis pushes a `main` hoy; mi trabajo está en la rama `ccr-ec102a3c-giitie`. Dime si autorizas empujarlo.

## Qué probar en un teléfono (`MEDICION_TELEFONO.md`)
30 fps estables en la escena urbana, RAM por pantalla (límite 800 MB), tiempo de carga de un mandato, y que la huella del guardado coincida entre dispositivos; probar también el cambio de apariencia con letra grande y la barra de gestos.

## Riesgos conocidos
- Nada se midió en un teléfono real ni con Vulkan: los números de rendimiento son de un PC.
- En Normal los bots que juegan bien ganan alrededor de 94 %: puede ser fácil.
- 229 proyectos reales siguen sin verificar contra su fuente; la ficha dice «ilustrativo».
- Aprendizaje grave de interfaz (corregido en main ee78972): en un teléfono 16:9 (360×640) el juego se veía al 82 % con bandas laterales y letra bajo 10 pt, y las pruebas headless no lo veían porque simulaban el alto. Ahora la base es 390 × alto de pantalla (`Main.base_para`, con prueba en `test_claridad`). Moraleja: las pruebas headless simulaban lo que no veían; hay que mirar en ventana real y en un teléfono.
- Hallazgos graves de dispositivo real de la sesión visual (todos corregidos en `game/`): un toque elegía y jugaba la carta en Android (contradecía CLAUDE.md §4; ahora `test_toque_real`), el 16:9 se achicaba, en 360×640 con letra ×1,5 se salían el pie del menú y el botón de votación, el Comité 3D salía casi blanco con «Mobile» (lavapipe) y había animaciones con «Animaciones» apagado. Esto refuerza `gl_compatibility` (decidido el 27-nov). Tema común: las pruebas headless simulaban lo que no veían.
- Con `data/` modificado a mano y sin pasar por `validate_data.py`, algunos valores extremos pueden colgar el motor.
