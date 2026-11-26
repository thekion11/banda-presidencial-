# Ficha de Google Play — BORRADOR (no publicada)

Estado: borrador para revisión del dueño del proyecto. Nada de esto se ha subido a Play Console. Los textos respetan los límites de la consola (título 30, descripción corta 80, descripción larga 4.000 caracteres).

## Identidad
- **Nombre (≤30):** Presidente de Chile
- **Paquete:** `cl.presidente.juego` (confirmar antes de la primera subida: no se puede cambiar después)
- **Categoría:** Juegos › Estrategia (alternativa: Simulación)
- **Etiquetas sugeridas:** estrategia por turnos, simulación política, cartas, Chile
- **Idioma principal:** Español (Chile). Contacto de soporte y política de privacidad: *por definir por el dueño*.

## Descripción corta (≤80)
Funda tu partido, gana la elección y gobierna Chile cuatro años, una semana por turno.

## Descripción larga (versión del 26-nov-2026)
¿Cuánto cuesta gobernar un país largo y angosto? En **Presidente de Chile** fundas tu propio partido (o te unes a uno de 15 partidos inventados), ganas una campaña de 8 semanas y gobiernas 208 semanas con el Congreso, los ministros y el Tribunal Constitucional frente a ti.

**Empieza desde cero**
• Elige tu camino: fundar un partido, ir como independiente o entrar a un partido ficticio. Responde un test rápido de 3 preguntas (o el completo de 8) y descubre tu perfil ideológico.
• Tres dificultades: fácil, normal y difícil.
• Cada decisión cambia tus escaños, tu cohesión, tu caja fiscal y tu capital político.

**Una campaña, una elección**
• 8 semanas de campaña sobre el mapa de Chile: cada carta es una promesa que después tendrás que cumplir. Encuestas semanales, debates y entrevistas.
• Si no alcanzas la mayoría, puedes pasar a segunda vuelta… o perder y dar la pelea desde la oposición.
• Las promesas incumplidas pasan la cuenta a mitad y al final del mandato.

**Gobierna con cartas**
• Cada semana tienes 5 movimientos y una mano de cartas de vivienda, salud, educación, seguridad, energía, transporte y más: desliza la carta hacia arriba para jugarla.
• Delega en uno de tus 25 ministros (sin gastar movimientos, con riesgo de escándalo), contrata asesores y arma una coalición con partidos aliados que te piden ministerios y cargos.
• El Corrector de Realismo nunca te dice solo "no": te propone una versión viable o construir por tramos.
• Cientos de cartas están inspiradas en proyectos y leyes reales de Chile, con sus cifras rotuladas como ilustrativas.

**Un Congreso de verdad**
• Cámara de 155 diputados y Senado de 50: las leyes pasan por las dos cámaras, con quórums distintos y posible recurso ante el Tribunal Constitucional.

**Planifica obras sobre el Gran Santiago real**
• Compara tres variantes, mueve las estaciones sobre las calles, ajusta el ritmo y mira la obra en 3D.
• Cada obra avanza en 5 fases: licitación, faena, estructura, terminación e inauguración.

**Partidas cortas, mandato largo**
• Sesiones de unos 20 minutos (unas 30 semanas de gobierno por sesión). Tu partida se guarda sola y puedes continuar cuando quieras. Al terminar, el juego te cuenta cómo te recordará la historia.

Obra de ficción y sátira política. Los partidos aliados y los personajes de pantalla son inventados y las cifras de los efectos son ilustrativas. No está afiliada a ningún partido, candidato ni institución, y no pide votar por nadie. Las encuestas y los resultados electorales del juego son simulados.

Mapas: © colaboradores de OpenStreetMap (ODbL).

## Material gráfico (en `docs/tienda/`)
| Pieza | Archivo | Requisito de Play |
|---|---|---|
| Icono | `icono_512.png` | 512×512 PNG |
| Gráfico de funciones | `grafico_de_funciones_1024x500.png` | 1024×500 |
| Capturas de teléfono (8) | `01_…jpg` a `08_…jpg` (780×1688) | 2 a 8, relación 9:16 aprox. |

Pendiente: capturas de tableta (opcional) y un video corto (YouTube) si se quiere.

## Declaraciones y contenido (verificar en Play Console)
- **Clasificación de contenido (IARC):** sin violencia, sin apuestas, sin compras. Tema: política (sátira). Responder el cuestionario con cuidado en "contenido político".
- **Política de contenido político:** la app no sugiere votar por candidatos reales ni difunde información electoral engañosa. Las menciones a políticos reales, si las hubiera, son con alias satíricos (decisión abierta del Documento Maestro: nombres definitivos).
- **Contenido generado por IA:** las ilustraciones de las cartas se generaron con IA. Declararlo donde Play lo pida (ver `docs/DATOS.md`).
- **Seguridad de los datos** (formulario de Play Console; respuestas propuestas):
  - ¿La app recopila o comparte alguno de los tipos de datos requeridos? **No.**
  - ¿Todos los datos del usuario se cifran en tránsito? **No aplica** (no se transmite nada).
  - ¿Ofrece una forma de solicitar que se borren los datos? **No aplica**: todo queda en el teléfono y se borra al desinstalar.
  - Sin anuncios, sin cuentas, sin análisis, sin permisos de Android (verificado con `tools/auditar_apk.py`; el APK no pide INTERNET). La política de privacidad (`POLITICA_PRIVACIDAD.md`) debe decir lo mismo. Si algún día se agregan métricas que salgan del teléfono, hay que cambiar esta declaración.
- **Público objetivo:** 13+ (evitar «dirigido a niños»).
- **Nota para la revisión sobre contenido político:** es una sátira jugable sobre la política chilena. Los partidos del juego son 15 réplicas ficticias; los ministros usan sobrenombres genéricos y ningún texto que ve el jugador nombra a un político real (lo verifica `tools/validar_textos.py` en cada cambio). Las obras y leyes que inspiran las cartas son públicas y llevan fuente y fecha de corte; las cifras de efectos son ilustrativas. El calendario electoral usa las fechas de 2025-2026, pero los resultados y las encuestas son simulados y el juego no llama a votar por nadie. Dejar esta nota en el campo de explicación de la revisión de contenido político de Play.
- **API objetivo:** el APK de depuración local (24-nov) apuntaba a Android 14 (API 34); ver `RIESGOS_PLAY_STORE.md` §7. **Verificar el nivel exigido por Google Play en la fecha de publicación** (el Documento Maestro menciona 36) y subir si hace falta.
- **Formato:** Play exige AAB. Falta exportar release firmado con el keystore del dueño (ver `docs/ANDROID.md`).

## Prueba cerrada (cuentas personales nuevas)
Requisito vigente al redactar el Documento Maestro: 12 o más testers durante 14 días continuos antes de pasar a producción (**confirmar las reglas actuales en Play Console**). Plan en `docs/PROMOCION.md`.

## Pendientes del dueño
1. Nombre legal del desarrollador, correo de contacto y URL de la política de privacidad (borrador en `docs/POLITICA_PRIVACIDAD.md`).
2. Keystore de release y firma de Play App Signing.
3. Revisar derechos de las ilustraciones IA y de las banderas que aparecen en algunas escenas.
4. Decidir el nombre definitivo y los alias de los políticos (decisión abierta).
5. Probar el juego en un teléfono real (rendimiento y táctil).
