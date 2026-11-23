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

## Descripción larga
¿Cuánto cuesta gobernar un país largo y angosto? En **Presidente de Chile** fundas tu propio partido, ganas una campaña de 8 semanas y gobiernas 208 semanas con el Congreso, los ministros y el Tribunal Constitucional frente a ti.

**Empieza desde cero**
• Responde un test de 8 dilemas políticos y descubre tu perfil ideológico.
• Dale nombre y sigla a tu partido y elige tu región bastión.
• Cada decisión cambia tus escaños, tu cohesión, tu caja fiscal y tu capital político.

**Una campaña, una elección**
• 8 semanas de campaña sobre el mapa de Chile: cada carta es una promesa que después tendrás que cumplir.
• Las promesas incumplidas pasan la cuenta a mitad y al final del mandato.

**Gobierna con cartas**
• Cada semana robas cartas de vivienda, salud, educación, seguridad, energía, transporte y más.
• Juega con tus puntos de acción o delega en uno de los 25 ministros… y corre el riesgo de un escándalo.
• El Corrector de Realismo nunca te dice solo "no": te propone una versión viable o construir por tramos.

**Un Congreso de verdad**
• Cámara de 155 diputados y Senado de 50: las leyes pasan por las dos cámaras, con quórums distintos y posible recurso ante el Tribunal Constitucional.

**Planifica obras sobre el Gran Santiago real**
• Cinco corredores (Metro, tren, buses, tranvía) sobre calles, cerros y edificios reales de Santiago.
• Compara tres variantes, mueve las estaciones sobre las calles, ajusta el ritmo y mira la obra en 3D.
• Cada obra avanza en 5 fases: licitación, faena, estructura, terminación e inauguración.

**Pensado para partidas cortas**
• Un turno por sesión, de 3 a 8 minutos. Tu partida se guarda sola y se puede reproducir exactamente.

Obra de ficción y sátira política. Los personajes son ficticios y las cifras están rotuladas como ilustrativas. No está afiliada a ningún partido, candidato ni institución.

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
- **Seguridad de los datos:** la app **no recopila ni comparte datos**; el guardado es local (`user://guardado.json`). Sin anuncios, sin cuentas, sin análisis. Sin permisos de Android solicitados (verificado con `aapt2 dump badging`).
- **Público objetivo:** 13+ (evitar "dirigido a niños").
- **API objetivo:** el APK actual apunta a Android 14 (API 34). **Verificar el nivel exigido por Google Play en la fecha de publicación** (el Documento Maestro menciona 36) y subir si hace falta.
- **Formato:** Play exige AAB. Falta exportar release firmado con el keystore del dueño (ver `docs/ANDROID.md`).

## Prueba cerrada (cuentas personales nuevas)
Requisito vigente al redactar el Documento Maestro: 12 o más testers durante 14 días continuos antes de pasar a producción (**confirmar las reglas actuales en Play Console**). Plan en `docs/PROMOCION.md`.

## Pendientes del dueño
1. Nombre legal del desarrollador, correo de contacto y URL de la política de privacidad (borrador en `docs/POLITICA_PRIVACIDAD.md`).
2. Keystore de release y firma de Play App Signing.
3. Revisar derechos de las ilustraciones IA y de las banderas que aparecen en algunas escenas.
4. Decidir el nombre definitivo y los alias de los políticos (decisión abierta).
5. Probar el juego en un teléfono real (rendimiento y táctil).
