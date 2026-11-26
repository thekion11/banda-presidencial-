# Registro de cambios (generado)

Commits sin fusiones desde 2026-11-26: 84. Generado con `tools/generar_changelog.py`; cada commit está en el área donde toca más archivos.

## Núcleo de simulación (`sim/`) (7)

- `faeaf9f` 26-11 20:53 — Cobertura de funciones (tools/cobertura_funciones.py), codigo muerto eliminado y docs AN
- `e1842f0` 26-11 20:49 — Fix: al caer por crisis la semana del ultimo turno cuenta en el reloj
- `380ba5b` 26-11 20:03 — Refactor: el director de eventos pasa a sim/director_eventos.gd (motor_eventos baja de 444 a 280 lineas); secuencia de eventos identica
- `41a79f5` 26-11 19:35 — Instantanea: esquema del estado (campos y tipos de esta version) y tipos de huella y sha; pruebas de cache de version anterior
- `030fa22` 26-11 19:18 — Instantanea: validacion de tipos y de estado no vacio (casos fabricados)
- `863a9fc` 26-11 19:07 — Encuestas semanales de campana y oposicion en sim (estado.encuestas), deterministas y sin usar el azar de la partida
- `64b63e2` 26-11 00:29 — Rendimiento: turno 0,8 ms y carga de guardado 15 ms (instantanea de carga), indices precalculados, grafo y SECTRA perezosos, director y rell

## Interfaz y presentación (`game/`) (18)

- `13a24cf` 26-11 21:07 — Letra grande de Android: la interfaz aguanta ×1,3 y ×1,5 con prueba
- `d05e314` 26-11 21:03 — Teléfonos bajos: todo cabe en 360×640 y las auditorías prueban 4 altos
- `e436169` 26-11 20:55 — Paleta congelada con prueba: tests/test_paleta.gd y cinco colores corregidos
- `04b393a` 26-11 20:46 — Mapa urbano: estaciones y líneas discontinuas en una llamada de dibujo por capa
- `a472235` 26-11 20:41 — uid de cuerpo_dia y humo_v2
- `2777e56` 26-11 20:41 — Divide pantalla_dia (449 -> 351) y test_ui_humo (450 -> 337)
- `9bd9604` 26-11 20:37 — Piezas para dividir pantalla_dia y test_ui_humo (aún sin conectar)
- `a8aeae3` 26-11 20:36 — Rendimiento: lo tapado no se dibuja
- `ef62fac` 26-11 20:13 — Maqueta v4: línea región-tarjeta, hemiciclo en anillos y rótulos del día
- `e414123` 26-11 19:57 — Día: la cabecera ya no ensancha la pantalla a 403 px
- `725b045` 26-11 19:51 — Razones: texto claro para los 41 motivos de rechazo del motor
- `5464f09` 26-11 19:40 — perf(animación): capas suaves a 30 Hz (mapa vivo, motas, escena de TV) y velo del tutorial solo al moverse el foco
- `7fdcb1c` 26-11 19:37 — fix(interfaz): «Prefactibilidad» ya no se parte en el Comité y «Máxima eficacia» no se corta en el panel de Gabinete
- `5b544ce` 26-11 19:33 — perf(mapa): contornos y centros de región en caché por tamaño y encuadre
- `978c4c4` 26-11 19:29 — fix(interfaz): Magallanes ya no saca las tarjetas del mapa fuera de pantalla; última encuesta antes de la elección
- `a202d4c` 26-11 19:25 — feat(accesibilidad): daltonismo en todo lo que sube o baja (Tema.bien/mal) y título del telón con texto grande
- `40a628e` 26-11 16:47 — fix: reacciones del mapa encadenadas sin error; Ajustes a pantalla completa y opaco
- `6e2977b` 26-11 16:41 — feat(claridad): créditos, brújula del perfil, tutorial con foco, ficha ampliada y eventos sin título repetido

## Datos (`data/`) (1)

- `b1c8677` 26-11 20:08 — Datos y pruebas: numeros de balance fuera del codigo (escanos y titular), check_constantes en el CI, test_cobertura y test_replay_intermedio

## Pruebas (`tests/`) (23)

- `23156be` 26-11 21:09 — Test: finales limite (empate de umbral, umbral de crisis, crisis en la ultima semana, fin exacto)
- `bb093a5` 26-11 21:08 — Docs: estimacion de duracion de sesion y de mandato (DURACION_SESION)
- `09791a4` 26-11 20:55 — Test: invariantes del director de eventos en 24 carreras (cooldowns, un aleatorio por semana, silencio maximo)
- `d118d7b` 26-11 20:52 — Test de balance: matriz por dificultad y techos (regresion de la escalera)
- `9720625` 26-11 20:51 — Test: fuzz de composicion del gabinete de 25 ministerios
- `a50b2e8` 26-11 20:50 — Test: unidades directas de Regiones, MotorEfectos, IndicesCartas, descartar_mano y resolver_proyectos
- `be588a6` 26-11 20:43 — Guardado: validacion estructural previa a reproducir (ValidarGuardado) y descarte en continuar_guardado
- `3284f5d` 26-11 20:38 — Test: calcular_puntaje, resolver_tc y corregir (pruebas unitarias directas)
- `45dd1eb` 26-11 20:38 — Fix: reloj unico del ciclo 2 al ganar la eleccion; CI falla ante errores de script y cuelgues; test_calendario_reloj
- `88e2d03` 26-11 20:36 — uid de dos scripts de prueba que llegaron sin él (analisis_ritmo_decisiones, test_determinismo)
- `7629b35` 26-11 20:36 — uid de los scripts nuevos (tapa, test_tapa, medir_cuadros, medir_memoria)
- `81b6467` 26-11 20:29 — Balance: la cohesion deja de estar saturada (desgaste semanal -1,85); analisis de ritmo y cobertura del Corrector; oros regenerados
- `107b6cc` 26-11 20:19 — tools/run_all_tests.sh (todo lo del CI en un comando) y lista de comandos de CLAUDE.md al dia
- `942d956` 26-11 20:15 — Pruebas y analisis: invariantes del Congreso, cartas muertas, perfil de turnos; documenta validadores, migracion y calendario de eventos
- `4f00caf` 26-11 20:04 — Tests: replay con guardados intermedios en partidas de 208 turnos; sin atascos en 3 dificultades x 3 afiliaciones
- `7656a74` 26-11 19:51 — test_razones: toda razon del motor tiene texto propio y los alcanzables dicen que hacer
- `3098afb` 26-11 19:46 — tests: auditoría de textos (mínimo 10 pt, sin emojis, tildes) y recorrido de UI compartido; atribuciones OSM a 10 pt
- `e98d39c` 26-11 19:45 — Instantanea.leer: version solo como entero; CI recorre todas las pruebas tests/test_*.gd y falla si el import tiene errores de script
- `c45e508` 26-11 19:42 — tests: auditoría de zonas táctiles ≥ 44 px en 12 pantallas y paneles (264 botones)
- `2420ee1` 26-11 19:42 — Datos: retira tres duplicados (eventos de cobre e incendios informativos, carta de zonas extremas) y regenera oros
- `5da9cb2` 26-11 19:38 — Encuestas: una por semana con segunda vuelta; prueba de que nunca hay atascos (mano vacia o sin cartas jugables)
- `3164c06` 26-11 19:10 — Instantanea: validacion de estructura; pruebas de forma de encuestas, tipos tras restaurar y rendimiento con mejor de dos pasadas
- `d186f34` 26-11 19:06 — tests: test_ui_humo sin animaciones para medir posiciones finales también con xvfb

## Herramientas y CI (`tools/`, `.github/`) (3)

- `84ad0a8` 26-11 21:10 — tools: check_entradas (tabla de ValidarGuardado completa) en el CI
- `52fa5da` 26-11 20:20 — tools: presupuesto del APK y validador de textos de data/ (tildes, emojis, largos) en el CI; correcciones de tres nombres y tres titulos; pr
- `3dc62bb` 26-11 20:11 — Validadores: referencias cruzadas y rangos, esqueleto de tipos de leyes.json y pruebas negativas (19 datos rotos, 1.514 mutaciones) en el CI

## Documentos (`docs/`) (31)

- `f094c87` 26-11 21:16 — Docs: escaneo de secretos limpio, .gitignore ampliado y guia de APK firmado para la prueba cerrada
- `1c8909d` 26-11 21:15 — Balance: Monte Carlo de 200 partidas por politica y dificultad con intervalos de confianza (INFORME_BALANCE) y tests/informe_dificultad.gd
- `613ed58` 26-11 21:10 — Docs: DECISIONES AQ
- `d43449e` 26-11 21:09 — Docs: propuesta de metricas opt-in (PRUEBA_CERRADA §6, sin implementar) y riesgos de Play Store
- `98794c2` 26-11 21:08 — Docs: coherencia (Google Play, DISENO_V2, ESTADO_FASES), lint y duracion de sesion (DECISIONES AP)
- `149c458` 26-11 21:05 — Fix: composicion del Congreso no suma mas escanos que la camara con coalicion; invariante en test_congreso_invariantes
- `0be3904` 26-11 20:54 — Docs: RESUMEN_EXPERIMENTO (que hizo cada sesion, hallazgos, arreglos y pendientes del usuario)
- `2e4827a` 26-11 20:53 — Docs: mapa de dependencias de sim/ y tamano/tiempos de data/
- `81e8391` 26-11 20:52 — Docs: trazabilidad de mecanicas (CLAUDE.md §2) y test_calendario_fechas
- `cb40856` 26-11 20:52 — Lados a lados v4 del día y Nación con los bordes de región nuevos
- `2d9919a` 26-11 20:52 — Mapa de Chile: contornos en una llamada por color (día 612 -> 268 llamadas)
- `ff0fac4` 26-11 20:43 — Docs: D16 dificultad solo afecta la campana (datos Monte Carlo)
- `20c731b` 26-11 20:39 — Refactor: DirectorEventos._elegir en funciones de menos de 60 lineas (huellas intactas)
- `ae4549d` 26-11 20:39 — Tests: rechazos legales sin efectos y unitarias de puntaje/TC/corrector
- `c9c40cf` 26-11 20:36 — Mapa de Chile: fondo en 3 llamadas de dibujo en vez de ~385
- `34ed212` 26-11 20:32 — Validador: textos del jugador no pueden nombrar politicos reales; auditoria de alias (DECISIONES AH)
- `e973d17` 26-11 20:31 — Docs: auditoria de fuentes y licencias (docs/LICENCIAS.md, DECISIONES AG)
- `7b6da93` 26-11 20:25 — RAM: informe por pantalla y suavizado solo en avenidas del mapa urbano
- `f7a0484` 26-11 20:23 — Oro de huellas de carreras completas (tests/oro/huellas.json) y tabla de decisiones pendientes con recomendacion y costo; indice de DECISION
- `f468984` 26-11 20:21 — test_determinismo, docs de arranque, ciclo de vida, determinismo y presupuesto
- `2769e2a` 26-11 20:20 — docs: analisis de las cartas del area Estado con opciones de ajuste (sin aplicar)
- `3d6b297` 26-11 20:12 — docs: PRUEBA_CERRADA (que observar y registrar en la prueba con personas); guia de prueba actualizada; perfil de turnos y prueba de migracio
- `5beac4f` 26-11 20:09 — docs: revision de las fichas MOP sin verificar (terminadas sin cartas; una requiere JavaScript)
- `bf74afe` 26-11 20:08 — docs: estado vigente del bono y del umbral frente a DISENO_V2/ESTADO_FASES; informe de balance con la medicion por dificultad
- `958dd5d` 26-11 19:53 — docs: medicion de dificultad con bots (escalon entre normal y dificil) y remedios probados sin aplicar
- `c98ef4d` 26-11 19:42 — docs: estado actual de cada sistema
- `0fa1fe9` 26-11 19:16 — feat(visual v4): encuesta de la semana en el telón (intención, margen, umbral o rival, cambio y regiones débiles)
- `99dfc60` 26-11 19:13 — docs: lista priorizada de cartas de proyectos reales sin verificar
- `cdc4245` 26-11 19:13 — Encuestas: ultima encuesta al cerrar la campana y prueba de que anticipa la eleccion
- `0e7f825` 26-11 19:10 — tests: captura_comparar cubre los estados v4 (créditos, brújula, foco del tutorial, ficha, escándalo, telón, rechazada, evento, debates, cam
- `2e1ed57` 26-11 16:51 — docs: lienzo de Claude Design con todas las pantallas y correcciones halladas al capturar

## Otros (raíz, CI) (1)

- `aabb570` 26-11 19:46 — ci: comillas en el nombre del paso (el YAML era invalido)
