# CLAUDE.md — Reglas del Proyecto: Presidente de Chile

## 1. Regla de Oro
La maqueta manda. Si el código y la maqueta discrepan en colores, proporciones, textos o jerarquía visual, se corrige el código.
Ninguna tarea cierra sin pruebas en verde y captura comparada (`tests/captura.gd`).

## 2. Identidad y Alcance
- Simulador político estratégico casual por turnos, exclusivo para Android (sesiones de unos 20 minutos; decisión del usuario del 24-nov-2026, antes 3 a 8).
- Escala temporal: mandato de 4 años (1.460 días internos) jugado a razón de 1 turno = 1 semana (7 días): 208 turnos.
  El salto de 7 días se lee desde `data/leyes.json` (nunca fijo).
- Comité de Planificación (3D intacto): variantes A/B/C (Fase 1), sliders y estaciones sobre grafo Dijkstra (Fase 3), obras en 5 fases.
- Prohibido: dibujo libre de trazados o simulación de agentes.
- Contenido político: políticos reales con alias satíricos; personajes de pantalla ficticios; cifras ilustrativas rotuladas.

### Enmienda de Cierre de Diseño (Modo Único)
- Antes del Turno 1 de gobierno existe una etapa única de configuración: Test Ideológico (8 preguntas) + Creación de Partido Propio.
- La partida comienza con 8 turnos semanales de Campaña Electoral (56 días internos) con la misma UI de mapa, mano y PA.
- En campaña, jugar cartas genera aprobación regional y registra la carta como Meta de Legado obligatoria para el gobierno.
- En el Turno 8 de campaña se vota la elección presidencial. Si el jugador no supera el umbral de `data/leyes.json`, pierde.
  Si gana, inicia el Turno 1 de Gobierno (208 semanas).
- ALCANCE CONGELADO: prohibido agregar nuevas mecánicas o pantallas fuera de los documentos hasta completar la Fase 4 y la prueba cerrada.
- **AMPLIACIÓN AUTORIZADA POR EL USUARIO (23-nov-2026)**, documentada en `docs/DISENO_V2.md` y `docs/ESTADO_FASES.md`: calendario real (campaña desde el 21-sep-2025, 1ª vuelta 16-nov-2025, 2ª vuelta 14-dic-2025 si se supera `umbral_pasa_balotaje`, mandato desde el 11-mar-2026: en el Turno 8 se vota; si no se alcanza el umbral se pasa a segunda vuelta o se pierde), gabinete elegido por el jugador (**decisión del usuario del 25-nov-2026: el gabinete es el de la vida real, los 25 ministerios, con relleno automático** de los cargos vacíos que nunca pisa lo escogido; PR-04 y PR-05), 5 movimientos por turno con mano continua, delegación, movimientos internos, asesores, coalición con 15 partidos ficticios, cartas por proyecto real y eventos reales. Toda mecánica o pantalla nueva debe citar su fuente y su commit.
- **AMPLIACIÓN AUTORIZADA POR EL USUARIO (24-nov-2026, PR-01 en `docs/PROPUESTAS.md`)**: pantalla de afiliación (fundar partido propio, candidatura independiente o entrar a uno de los 15 partidos ficticios) y dificultad (fácil, normal, difícil) con presets en `data/leyes.json`; el test ideológico completo es para fundadores e independientes, y quien entra a un partido solo confirma 3 posturas.

## 3. Arquitectura y Separación de Capas
- Motor: Godot 4 con GDScript. C++ solo vía GDExtension en bucles con cuello de botella comprobado.
- `sim/`: núcleo determinista puro (RefCounted, sin nodos de Godot), ejecutable en modo headless.
- `game/`: escenas, interfaz y presentación visual.
- `data/`: JSON validados (cartas, eventos, leyes, ministros, regiones, propuestas, ideología, fuentes). Ningún número de balance vive en el código.
- `tools/`: validador de datos (`validate_data.py`), pipeline geoespacial offline (`tools/geo/`), verificador de límites.
- `tests/`: pruebas de oro, bots Monte Carlo y regresión de balance.
- Guardado por eventos: misma semilla + mismas entradas = mismo resultado exacto. Solo se guarda semilla, partido e historial.
- Máximo 450 líneas por archivo; `sim/estado_simulacion.gd` y `sim/motor_turno.gd` bajo 220 (Guía Técnica Fase 0). Verificado con `python3 tools/check_limits.py`.

## 4. Ciclo Fijo del Turno Semanal (8 pasos)
1. Amanecer: actualiza indicadores (aprobación, capital, cohesión, fiscal, riesgo de ejecución) y regenera PA.
2. Eventos: programados en la ventana de 7 días y sorteados con la semilla.
3. Mano: 5 cartas con costo de 1 a 3 movimientos (los PA pasan a llamarse movimientos); al jugar una carta entra otra al instante. Solo circulan las cartas habilitadas por el gabinete y su ventana (docs/DISENO_V2.md). Las cartas se juegan deslizándolas o tocándolas dos veces.
4. Jugar cartas: con movimientos, delegando hasta 2 por turno en un ministro del gabinete (sin gastar movimientos, con riesgo de fallo), o con los 3 movimientos internos de la coalición.
5. Validación legal: competencia, ley, quórum (Senado y Cámara), plazos y Tribunal Constitucional.
6. Corrector de realismo: nunca responde con un "no" seco; ofrece versión viable o por tramos.
7. Resolución: votaciones, efectos y avance de +7 días en las obras.
8. Cierre del turno: registra acciones y avanza el calendario.

Orden de cálculo dentro de cada efecto: Legal -> Presupuesto -> Capacidad de ejecución -> Opinión pública -> Azar con semilla.
Si un paso falla, entra el Corrector antes.

## 5. Presupuesto Técnico y Reglas de Interfaz (390×844)
- Paleta congelada: océano `#0B2236`, panel `#16405F`, oro `#F2C14E`, rojo `#C23B2E`, crema `#FBF7EC`, escala de aprobación `#4CC38A` a `#E8705A`.
- Tipografías: Space Grotesk 700 (títulos) e Inter 400–600 (texto). Mínimo 10 pt. Zonas táctiles ≥ 44 px. Contraste ≥ 4.5:1. Sin emojis.
- APK < 150 MB (regiones vía Play Asset Delivery). RAM ≤ 800 MB. 30 fps estables en la escena urbana 3D.
- El mapa ocupa siempre más de un tercio de la pantalla. El botón principal está siempre en la misma posición. **Decisión del usuario del 25-nov-2026 (PR-02):** en la pantalla del día el botón del medio es «Terminar semana» (pide confirmar si sobran movimientos), la esquina inferior derecha queda vacía y las cartas se juegan deslizándolas hacia arriba o tocándolas dos veces; soltar sobre el ícono izquierdo delega.

## 6. Flujo de trabajo con IA
- Una tarea pequeña por vez, con su prueba. Commits pequeños y descriptivos; un pull request por tarea.
- Nada de secretos ni claves en el repositorio.
- Todo dato real lleva fuente y fecha de corte en `data/fuentes.json`. Los artículos constitucionales se verifican contra el texto oficial antes de publicar.

## 7. Comandos
```
python3 tools/validate_data.py
python3 tools/check_limits.py
python3 tools/check_constantes.py      # ningún número de balance nuevo en sim/
python3 tools/validate_tipos.py        # estructura y tipos de data/leyes.json
python3 tools/test_validate.py         # pruebas negativas de los validadores
python3 tools/check_entradas.py        # cada tipo de entrada del guardado está en ValidarGuardado
python3 tools/generar_api.py --verificar  # toda función pública de sim/ está documentada (regenera docs/API_SIM.md)
python3 tools/mutar.py godot 24 1      # mutación acotada de sim/ (lista mutantes que ninguna prueba mata; ≈ 15 min)
python3 tools/cobertura_funciones.py godot  # funciones de sim/ que ninguna prueba ejecuta (≈ 15 min)
tools/run_all_tests.sh                 # TODO lo del CI en un solo comando (validadores, tests/test_*.gd y fuzz)
godot --headless --import --path .
godot --headless --path . -s tests/test_prueba_oro_4_semanas.gd
godot --headless --path . -s tests/test_prueba_oro_30_dias.gd
godot --headless --path . -s tests/test_prueba_oro_completa.gd
godot --headless --path . -s tests/test_enmienda.gd
godot --headless --path . -s tests/test_congreso.gd
godot --headless --path . -s tests/test_grafo.gd
godot --headless --path . -s tests/test_metro_lineas.gd
godot --headless --path . -s tests/test_mapa_entrada.gd
godot --headless --path . -s tests/test_lineas_guardado.gd
godot --headless --path . -s tests/test_validaciones.gd
godot --headless --path . -s tests/test_guardado_danado.gd
godot --headless --path . -s tests/test_cartera.gd
godot --headless --path . -s tests/fuzz_acciones.gd -- 60 7000     # fuzzing: acciones aleatorias e inválidas, invariantes y replay idéntico
godot --headless --path . -s tests/test_sectra.gd
godot --headless --path . -s tests/test_guardado.gd
godot --headless --path . -s tests/test_gabinete.gd
godot --headless --path . -s tests/test_delegacion.gd
godot --headless --path . -s tests/test_movimientos.gd
godot --headless --path . -s tests/test_equipo.gd
godot --headless --path . -s tests/test_coalicion.gd
godot --headless --path . -s tests/test_presupuesto.gd
godot --headless --path . -s tests/test_dificultad.gd
godot --headless --path . -s tests/test_afiliacion.gd
godot --headless --path . -s tests/test_finales.gd
godot --headless --path . -s tests/test_decisiones.gd
godot --headless --path . -s tests/test_carrera.gd
godot --headless --path . -s tests/test_ritmo.gd
godot --headless --path . -s tests/test_identidad.gd
godot --headless --path . -s tests/test_balance.gd
godot --headless --path . -s tests/test_ui_humo.gd
godot --headless --path . -s tests/test_movimiento.gd
godot --headless --path . -s tests/test_claridad.gd
godot --headless --path . -s tests/test_tactil.gd
godot --headless --path . -s tests/test_textos.gd
godot --headless --path . -s tests/test_tapa.gd
godot --headless --path . -s tests/test_paleta.gd
godot --headless --path . -s tests/test_estados.gd
godot --headless --path . -s tests/test_razones.gd             # toda razón de rechazo del motor tiene texto
godot --headless --path . -s tests/test_sin_atascos.gd         # siempre hay mano y carta jugable (3 dificultades x 3 afiliaciones)
godot --headless --path . -s tests/test_cobertura.gd           # cartas por área de ministerio y año
godot --headless --path . -s tests/test_replay_intermedio.gd   # guardados intermedios de partidas de 208 turnos
godot --headless --path . -s tests/test_congreso_invariantes.gd
godot --headless --path . -s tests/test_congreso_oposicion.gd
godot --headless --path . -s tests/test_encuestas.gd
godot --headless --path . -s tests/test_escenas.gd
godot --headless --path . -s tests/test_accesibilidad.gd
godot --headless --path . -s tests/test_instantanea.gd         # caché de carga válida, vieja o dañada
godot --headless --path . -s tests/test_carga_rapida.gd
godot --headless --path . -s tests/test_rendimiento.gd         # turno < 1 ms y carga < 100 ms
godot --headless --path . -s tests/montecarlo.gd -- 200        # informe de balance
xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/medir_memoria.gd   # informe de RAM por pantalla
xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/medir_cuadros.gd   # llamadas de dibujo por escena
xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/medir_transiciones.gd   # costo por cuadro de cada animación
godot --headless --path . -s tests/medir_toques.gd -- 3 30        # informe de toques por acción y por semana
godot --headless --path . -s tools/informe_partida.gd -- 7 humano normal   # serie semanal de una partida en CSV (líneas «CSV,»)
python3 tools/diferencia_maqueta.py /tmp/capturas                 # diferencia numérica con la maqueta (tras captura_comparar)
xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/captura_comparar.gd -- /tmp/capturas   # estados de la maqueta
```
