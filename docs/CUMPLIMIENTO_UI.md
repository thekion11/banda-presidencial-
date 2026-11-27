# Cumplimiento de las reglas de interfaz (CLAUDE.md §5) — 27-nov-2026

Cada regla de presupuesto e interfaz de CLAUDE.md §5, la prueba que la vigila y su estado. Las pruebas `tests/test_*.gd` corren en el CI (`tools/run_all_tests.sh`). Los «informes» miden, pero no fallan.

| Regla (§5) | Prueba | Qué comprueba | Estado |
|---|---|---|---|
| Paleta congelada (océano, panel, oro, rojo, crema, escala de aprobación) | `tests/test_paleta.gd` | Todo color escrito en `game/` es de la paleta (más las tintas Okabe-Ito del modo daltónico) o una mezcla de dos de ellos o con negro o blanco (ΔE ≤ 8) | Cumple |
| Tipografías: Space Grotesk (títulos) e Inter (texto) | `tests/test_textos.gd` | Todo texto visible usa uno de los dos archivos; Inter es la fuente por defecto del proyecto | Cumple (los pesos 700 y 400–600 no se miden) |
| Mínimo 10 pt | `tests/test_textos.gd` | Todo texto visible mide ≥ 10 pt, y ningún `draw_string` de `game/` usa menos de 10 | Cumple |
| Zonas táctiles ≥ 44 px | `tests/test_tactil.gd` | Todo botón visible mide ≥ 44 × 44 y cabe en la pantalla, en 5 altos de teléfono | Cumple |
| Contraste ≥ 4,5:1 | `tests/test_claridad.gd` | Pares de color clave (modo daltónico, tintas sobre crema, cintas de categoría) | Parcial: no recorre cada texto contra su fondo real |
| Sin emojis, ni glifos que la fuente no tenga | `tests/test_textos.gd` | Ningún carácter ≥ U+1F300 y cada carácter existe en la fuente embebida que lo dibuja («●» y «✕» se cambiaron por «•» y «×») | Cumple |
| El mapa ocupa siempre más de un tercio | `tests/test_reglas_ui.gd`, `tests/humo_v2.gd` | Mapa del día > 1/3 en los altos 693, 812, 844, 866 y 910, con cualquier carta elegida | Cumple (en 390×693 se quita la fila «Tu mano») |
| El botón principal está siempre en la misma posición | `tests/humo_v2.gd` | Mismo rectángulo con cada carta elegida y con cada pestaña del Gabinete | Cumple |
| «Terminar semana» es el botón del medio y pide confirmar si sobran movimientos (PR-02) | `tests/test_reglas_ui.gd`, `tests/ayuda_ui.gd` | Botón centrado con ese texto; con movimientos sin usar pide un segundo toque | Cumple |
| La esquina inferior derecha queda vacía (PR-02) | `tests/test_reglas_ui.gd` | Ningún botón visible en esa esquina de la fila de botones | Cumple |
| Cartas: deslizar hacia arriba o doble toque; soltar sobre el ícono izquierdo delega | `tests/humo_v2.gd`, `tests/test_claridad.gd`, `tests/test_delegacion.gd` | Deslizar juega, el segundo toque juega y la delegación se hace desde la hoja | Cumple; soltar sobre el ícono no tiene prueba propia |
| 390 × 844 y otros teléfonos | `tests/test_textos.gd`, `tests/test_tactil.gd`, `tests/test_claridad.gd` | Ningún texto ni botón se sale de la pantalla en 5 altos ni con letra ×1,3 y ×1,5; tablet y plegable abierto muestran el 390×844 con bandas (`Main.aspecto_para`) | Cumple |
| Reducir movimiento | `tests/test_reglas_ui.gd`, `tests/test_movimiento.gd` | Con animaciones encendidas y «Reducir movimiento», ni partículas ni efectos intensos. Las auditorías recorren todo sin animaciones, así que nada depende de ellas para entenderse | Cumple |
| Estado tardío (semanas 150–208) | `tests/test_estado_tardio.gd` | Un bot llega a la semana 170 (obras, 22 promesas, coalición, mano llena); en 390×693 y con letra ×1,5 nada se sale de la pantalla, los botones miden ≥ 44 y cada panel abre en menos de 1,5 s | Cumple |
| Zonas seguras de Android (muesca y barra de gestos) | `tests/test_zonas_seguras.gd` | Con franjas simuladas de 0, 24 y 48 px arriba y abajo, en 390×844 y 390×693: ningún botón ni texto fijo queda bajo ellas, todo botón mide ≥ 44 y «Terminar semana», la votación y los chips de abajo quedan enteros. Main sube el borde inferior de cada pantalla en `Tema.margen_inferior()` y las pantallas compactan según `Tema.alto_util()` | Cumple (simulado; falta verlo en un teléfono con barra de gestos) |
| Texto largo en fichas y eventos | `tests/test_fichas_largas.gd` | La ficha ampliada de las 1.964 cartas y la pantalla de los 175 eventos sin votación, con «Texto grande» (×1,15) y ×1,5, en 390×844 y 390×693: nada desborda ni sale de la pantalla. Con ×1,5 la ilustración de la ficha cede alto (150 → mín. 56 px) antes que el texto | Cumple |
| Botón Atrás de Android (navegación) | `tests/test_atras.gd` | Nunca sale al primer toque, cierra lo de encima, no salta eventos y guarda | Cumple |
| APK < 150 MB | `tools/check_presupuesto.py`, `tools/auditar_apk.py` (sesión del motor) | Tamaño de datos y arte | Cumple en escritorio; falta medir el APK firmado |
| RAM ≤ 800 MB | `tests/medir_memoria.gd` (informe) | RSS por pantalla en escritorio: pico de 578 MB | Sin medir en teléfono (docs/MEDICION_TELEFONO.md) |
| 30 fps estables en la escena urbana 3D | `tests/medir_cuadros.gd`, `tests/medir_transiciones.gd` (informes) | Llamadas de dibujo y CPU de render por escena y animación | Sin medir en teléfono (el escritorio rasteriza por software) |

**Sin prueba automática:** el contraste de cada texto contra su fondo real, los pesos tipográficos exactos, el gesto de soltar la carta sobre el ícono de delegar, y la RAM y los fps en un teléfono real. Lo último solo se puede medir con el APK; los pasos están en `docs/MEDICION_TELEFONO.md`.
