# Video de prueba 1 — desmenuzado por partes

Grabación de pantalla del usuario, 23-nov-2026 22:24, teléfono Android 1080×2388, 3 min 51 s, APK `0.9.0-prueba1` (commit `77c356d`, compilado 00:56 UTC). El video NO está en el repositorio (192 MB); aquí solo hay 19 cuadros clave (`docs/comparacion/video1/tSSS.jpg`, SSS = segundo del video).

Cómo usar este documento: opina por el número de parte (P1, P2…). Cada opinión se convierte en una tarea en la columna «Tu opinión → tarea» y se verá reflejada en `docs/ESTADO_FASES.md` y en el juego. «Lo que veo yo» son detecciones mías (hipótesis a confirmar contigo), no verdades.

| Parte | Tiempo | Qué ocurre | Cuadro | Lo que veo yo | Tu opinión → tarea |
|---|---|---|---|---|---|
| **P1 Arranque y menú** | 0:00–0:15 | Pantalla de inicio del teléfono con el ícono (la estrella antigua), arranque en negro y menú principal | `t012` | El arranque tiene un cuadro negro (esa versión aún no tenía la imagen de arranque nueva). El menú es oscuro: el título está arriba a la izquierda, queda un hueco grande en el centro y los botones abajo. «Continuar partida» no aparece (no había partida guardada) | |
| **P2 Cartera de proyectos** | 0:15–0:20 | Lista de 1.685 proyectos, 85 páginas, filtros por tipo/región/sector | `t017` | Funciona y es de solo lectura. Muchas filas dicen «Fuera de partida» sin explicar qué significa; la lista es larga y no se puede buscar por texto | |
| **P3 Informe de prueba** | 0:20–0:35 | Informe de prueba abierto un rato | `t024` | Con 0 partidas el informe es casi vacío: un 70 % de la pantalla queda sin uso. Dice «pantalla (1080, 2388)» y la memoria/fps en «?» | |
| **P4 Créditos** | 0:35–0:40 | Panel de créditos sobre el menú | `t036` | El panel tapa el título «Presidente de Chile» (se ve cortado detrás) y deja un hueco vacío debajo; es un cuadro pequeño en una pantalla muy alta | |
| **P5 Test ideológico 1-4** | 0:40–1:25 | Preguntas 1 a 4: vivienda, gasto/DIPRES, Senado, pensiones | `t042` `t062` `t072` `t082` | Cada pregunta tiene una ilustración grande y 3 opciones A/B/C; funciona bien. Debajo de las opciones queda ~40 % de pantalla vacía. La franja crema de abajo («Perfil: … Proyección: X de 50 escaños») cambia con tus respuestas pero es pequeña y poco explicada | |
| **P6 Test ideológico 5-8** | 1:25–2:00 | Preguntas 5 a 8: delito, regiones, energía, educación | `t087` `t096` `t107` `t117` | Igual que P5. El perfil pasa de «Socialdemocracia Reformista» a «Frente Transformador» y «Centro Gradualista» sin que se vea por qué | |
| **P7 Identidad del partido** | 2:00–2:07 | Nombre, sigla y región bastión | `t122` | Claro y simple. Pre-llenado con «Movimiento Cívico Austral / MCA». El teclado y el campo funcionan | |
| **P8 Gabinete** | 2:07–2:20 | «Forma tu gabinete»: 8 de 8 ministros, «Habilita 1328 de 1753 cartas» | `t132` | La lista de 25 ministros se desplaza dentro de un cuadro; el texto de cada ministro es denso (cartera, categoría, nº de cartas). Los elegidos en amarillo se ven bien. El botón «Comenzar campaña» está fijo abajo | |
| **P9 Tutorial** | 2:20–2:35 | Paso 1 de 5, «Tu mano»: ventana que tapa casi toda la pantalla con «Saltar tutorial / Siguiente» | `t142` | La ventana cubre el mapa y la mano que explica. Ayuda saltarlo, pero el marco dorado no resalta bien qué elemento se está explicando | |
| **P10 Campaña, semana 1** | 2:35–3:00 | Pantalla de día: mapa, indicadores, mano en abanico, botón «Jugar» | `t152` | La mano se ve llamativa, pero las cartas se tapan entre sí y varios textos quedan cortados. El evento «Se publica la Ley N° 21.770» ocupa mucho espacio y repite texto técnico. «5/5 mov» arriba a la derecha se entiende | |
| **P11 Evento a pantalla completa** | 3:00–3:05 | «Se publica la Ley N° 21.771», +1 capital político, botón Continuar | `t182` | El texto legal es largo y técnico («Incorpora la Fiscalía Supraterritorial…»); el efecto (+1) es lo único relevante | |
| **P12 Semanas 2-3** | 3:05–3:51 | Jugar cartas, «Promesa registrada: +6.3 de aprobación», movimientos que bajan a 0/5, siguiente semana | `t187` `t210` | El banner de promesa es claro. Al llegar a 0/5 mov el botón «Jugar» se apaga sin explicación; no queda claro cuándo conviene terminar la semana. Entre semanas hay poco «feedback» visual de lo logrado | |

## Otras cosas que se ven en el video
- Un globo flotante de otra aplicación (burbuja de chat) tapa la esquina superior derecha en casi todo el video; no es del juego.
- La resolución real es 1080×2388 (proporción ~19,5:9), más alta que la 390×844 de diseño: por eso sobra espacio vertical en varias pantallas.
- El ícono visible (estrella) es el anterior; el nuevo (La Moneda) llega en la compilación `cdbb9b9`.

## Primeras tareas que ya veo (sin esperar tu opinión; se confirman o se descartan contigo)
1. P1/P4: rediseñar el menú de inicio (portada) y el panel de créditos para que no tape el título ni deje huecos.
2. P3: el informe de prueba debe verse bien incluso vacío y explicar qué falta.
3. P5/P6: aprovechar el espacio vacío bajo las preguntas y explicar el «Perfil».
4. P9/P10: tutorial que resalte el elemento sin taparlo; mano más legible.
5. P11: resumir los textos legales de los eventos (título corto + efecto).
6. P12: indicar claramente cuándo se acaban los movimientos y qué pasa al terminar la semana.
