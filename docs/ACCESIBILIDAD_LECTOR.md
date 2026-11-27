# Lector de pantalla (TalkBack) — evaluación (27-nov-2026)

Encargo de la cola 6: ¿Godot 4.7 soporta AccessKit y TalkBack en Android? Si es así, ¿qué costaría dar nombres accesibles a botones y elementos clave? Esto es solo evaluación: **no se implementó nada**.

## Qué trae Godot 4.7.2 (lo comprobé en el motor instalado)

- `Control` tiene `accessibility_name`, `accessibility_description`, `accessibility_live` y las relaciones `accessibility_labeled_by_nodes`, `accessibility_described_by_nodes`, `accessibility_controls_nodes` y `accessibility_flow_to_nodes`.
- `DisplayServer` trae 76 funciones `accessibility_*`. Entre ellas están `accessibility_screen_reader_active`, `accessibility_should_reduce_animation` y `accessibility_should_increase_contrast`, además de las que crean elementos propios para lo que se dibuja a mano.
- El ajuste `accessibility/general/accessibility_support` vale 0 (automático) en el proyecto, el valor por defecto. Ningún archivo de `game/` usa aún estas propiedades.

## ¿Funciona con TalkBack en Android?

**En 4.7, en la práctica, no.** El soporte de AccessKit llegó en Godot 4.5 para escritorio: Windows, macOS y Linux ([PR #76829](https://github.com/godotengine/godot/pull/76829)). En el foro oficial hay reportes de que funciona en Windows y no con TalkBack en Android, con Godot 4.5 y 4.5.1 ([foro 1](https://forum.godotengine.org/t/question-about-accessibility-on-android/122578), [foro 2](https://forum.godotengine.org/t/european-market-compliance-android-embedded-mode-talkback-on-godot-node-view-is-not-focusable/130058)). Un blog dice que el adaptador nativo para iOS y Android entra en 4.8-dev y que todavía no está a la par del escritorio ([fuente](https://www.gamineai.com/blog/godot-4-8-dev-accesskit-mobile-smoke-first-indie-worksheet-2026)). Es una sola fuente, sin confirmar en las notas oficiales. **Hay que verificarlo en un teléfono con TalkBack** antes de prometer nada; los pasos para instalar el APK están en `docs/MEDICION_TELEFONO.md`.

## Qué habría que hacer el día que funcione (costo)

| Pieza | Hoy | Trabajo | Costo |
|---|---|---|---|
| Botones con texto (la mayoría) | `Button.text` ya sirve de nombre | Nada | 0 |
| Botones solo con ícono: delegar (`Barras.boton_redondo`) y el «▶ Día N» central | Sin nombre | `accessibility_name = "Delegar la carta en un ministro"` y similares | 15 min |
| Carta (`CartaUI`, dibujada a mano) | El lector no ve nada | `accessibility_name` con el título, el costo y los dos efectos, actualizado en `pintar` | 1 h |
| Chips de la cabecera y pastilla de movimientos | Cifras sueltas | Nombre «Aprobación 42» y `accessibility_live` para que se anuncien al cambiar | 30 min |
| Avisos (toast), telón y sello de votación | Visuales | `accessibility_live = POLITE` para que se lean solos | 30 min |
| Mapa de Chile, mapa urbano, Comité y hemiciclo (dibujados) | Un solo bloque | Un elemento accesible por región o estación con `DisplayServer.accessibility_create_sub_element`, o en su lugar una lista equivalente (las regiones ya están listadas en Nación) | 4–6 h |
| Gesto de deslizar para jugar | TalkBack se queda con los gestos | Ya existe el doble toque como respaldo; habría que verificar que TalkBack lo deja pasar | Prueba en teléfono |

**Total aproximado:** 1 día para lo básico (botones de ícono, cartas, chips y avisos) y otro para los mapas. Ninguna de estas piezas exige un ajuste nuevo para el usuario: el lector se activa desde el sistema y Godot lo detecta solo.

## Propuesta

1. **No implementar en 4.7**: no tendría efecto en Android, la única plataforma del juego.
2. **Al pasar a una versión con el adaptador de Android** (4.8 o la que confirmen las notas oficiales), hacer primero lo básico, de 1 día, con una prueba que exija `accessibility_name` no vacío en todo botón sin texto y en cada `CartaUI`.
3. **Mientras tanto ya se respeta** lo que el sistema expone sin lector: «Reducir movimiento», el contraste ≥ 4,5:1, las zonas táctiles ≥ 44 px y la letra grande. Si se quiere, `DisplayServer.accessibility_should_reduce_animation()` podría encender «Reducir movimiento» por defecto. Eso sí cambia un ajuste del jugador, así que queda para que el usuario decida.
