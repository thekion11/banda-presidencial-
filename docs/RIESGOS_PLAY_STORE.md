# Riesgos para publicar en Google Play (lista del 26-nov-2026, para el usuario)

Publicación en pausa por decisión del usuario. Esta lista no es asesoría legal: sirve para llegar a la revisión sabiendo qué mirar. Lo marcado **Decide el usuario** no lo resolvió ninguna sesión.

## 1. Política de datos y privacidad
- **Estado:** la app no recopila ni envía datos, no pide permisos, no usa anuncios ni análisis (`docs/POLITICA_PRIVACIDAD.md`, borrador). La declaración de «Seguridad de los datos» de Play debe decir «no se recopilan datos» y «no se comparten datos».
- **Riesgo:** Play exige una URL pública con la política, aunque no se recopile nada. El borrador no tiene correo de contacto (**Decide el usuario**). Una revisión legal es recomendable antes de publicar.
- **Si se agregan métricas** (propuesta en `docs/PRUEBA_CERRADA.md` §6) y nunca salen del teléfono, no cambian la declaración; si salieran, sí.
- **Menores:** el borrador dice «no dirigido a menores de 13 años». Si el cuestionario de clasificación da una edad menor, Play aplica la política de familias: hay que mantener coherencia entre ambas.

## 2. Contenido político y alias satíricos
- **Riesgo principal:** Play permite contenido político y sátira, pero rechaza contenido que suplante a personas reales o aparente ser oficial. El juego usa alias satíricos y personajes ficticios (los 15 partidos son ficticios), y los textos que ve el jugador no nombran a políticos reales (`tools/validar_textos.py` lo verifica en el CI; auditoría en `docs/DECISIONES.md` §AH).
- **Excepciones a vigilar:** nombres oficiales de obras y lugares que coinciden con apellidos (por ejemplo «Avenida Ricardo Lagos», «CESFAM Eduardo Frei Montalva», «Escuela Salvador Allende»; 6 cartas): son nombres de lugares reales con fuente, no sátira. **Decide el usuario** si los mantiene.
- **Datos reales:** eventos y proyectos reales vienen de fuentes públicas con fecha de corte (`data/fuentes.json`); las cifras ilustrativas van rotuladas. ~600 cartas de proyectos reales y las fichas MOP siguen sin verificación humana (`docs/PENDIENTES_USUARIO.md`): un dato falso sobre una persona o institución es el riesgo de reclamo más probable. **Decide el usuario** cuánto verificar antes de publicar.
- **Elecciones reales:** el calendario usa las elecciones chilenas de 2025 y el gobierno desde marzo de 2026; las encuestas son simuladas, no reales: hay que dejarlo claro en la ficha («obra de ficción; las encuestas y cifras son del juego»), porque Play prohíbe contenido electoral engañoso.
- **Sin urnas reales ni llamados al voto:** el juego no debe pedir votar por nadie ni afirmar resultados reales; hoy no lo hace.

## 3. Clasificación por edad (IARC)
- Violencia: ninguna gráfica. Apuestas, compras, chat, ubicación: no hay. Contenido político: sí, como sátira y simulación. La respuesta honesta a «contenido político» suele dar una clasificación de 12+ en algunas regiones y 3+/Todos en otras; revisar el resultado antes de aceptar.
- Mencionar las leyes de seguridad, justicia, drogas o aborto en cartas reales (hay cartas de proyectos de ley sobre esos temas) puede subir la clasificación; no se evaluó una por una.

## 4. Propiedad intelectual y licencias (`docs/LICENCIAS.md`)
- **Imágenes con IA (Gemini, Canva, Figma):** el uso comercial no está confirmado. Play pide divulgar contenido generado con IA en algunos casos. **Decide el usuario**.
- **OpenStreetMap (ODbL):** atribución visible en Créditos ya incluida; falta ofrecer la base derivada bajo ODbL.
- **GeoJSON de regiones y datos de SECTRA:** licencia o autorización sin confirmar.
- **Marcas:** el nombre «Presidente de Chile» y las siglas ficticias de los partidos no deben coincidir con marcas registradas reales (`ley_19039_marcas` en `fuentes.json`); no se hizo búsqueda de marcas en INAPI. **Decide el usuario**.

## 5. Requisitos técnicos de la tienda
- Paquete AAB (no APK) para publicar; nivel de API objetivo vigente; soporte de páginas de 16 KB para Android 15+ (hallazgo A1 en `docs/REVISION.md`); tamaño de descarga < 150 MB (hoy ≈ 31 MB de APK de depuración, `tools/check_presupuesto.py`).
- Firma de la app y cuenta de desarrollador (cuenta personal nueva: prueba cerrada con ≥ 12 probadores durante 14 días antes de producción). La clave de firma no debe entrar al repositorio.
- RAM ≤ 800 MB y 30 fps solo están medidos en escritorio con rasterizado por software; hay que medirlos en teléfonos reales y en pantallas bajas (360×640).

## 6. Texto de la ficha
- Corregido el 26-nov: ya no dice «un turno por sesión de 3 a 8 minutos» (`docs/GOOGLE_PLAY.md`). Revisar que no prometa funciones que no estén (por ejemplo «cinco corredores» frente a lo que hoy se juega) y que declare «ficción y sátira».
- Capturas: deben mostrar la app real (reglas de metadatos de Play); las de `docs/tienda/` son de la maqueta y hay que regenerarlas desde el juego.

## 7. Auditoría de `export_presets.cfg` y del APK (26-nov-2026)
Hecha con `tools/auditar_apk.py` sobre el APK de depuración local del 24-nov (plantilla anterior a la actual del CI: **repetirla sobre el APK que genere el CI**, ahora automática y no bloqueante en `android.yml`; el resultado queda en el registro del trabajo).
| Aspecto | Hallado | Veredicto |
|---|---|---|
| Orientación | `screenOrientation = 1` (vertical bloqueada) y `window/handheld/orientation=1` | Bien |
| Permisos | Ninguno solicitado (no pide INTERNET, ubicación ni almacenamiento); `allowBackup = false` | Bien: coincide con la política de privacidad y con la declaración «no se recopilan datos» |
| Paquete y versión | `cl.presidente.juego`, `versionCode 1`, `versionName 0.1.0` (el informe de prueba muestra otra, `0.9.0-prueba1`) | Unificar el criterio antes de publicar; subir `versionCode` en cada entrega |
| SDK | `minSdk 21`, `targetSdk 34`, `compileSdk 34` en ese APK | **Riesgo:** Play exige apuntar a Android 15 (API 35) o más para apps nuevas; el CI ya instala las plataformas 35 y 36, pero hay que confirmar el valor del APK actual y fijarlo en el preset |
| ABI | Solo `arm64-v8a` (cumple el requisito de 64 bits; deja fuera los teléfonos de 32 bits, pocos) | Bien |
| Vulkan | El manifiesto declara `android.hardware.vulkan.version` como **requerido** (el motor usa el renderizador «mobile») | **Riesgo:** los teléfonos sin Vulkan 1.0 no verán la app en Play. Decisión del dueño: mantener o pasar al renderizador de compatibilidad (OpenGL ES 3), que llega a más teléfonos, pero cambia el aspecto del suavizado y hay que volver a medir fps |
| Tamaño | APK de depuración 30 MB comprimido (≈ 20 MB de bibliotecas nativas arm64) | Bien (límite 150 MB) |
| Íconos y pantalla de inicio | Ícono de 192 px y adaptativo (primer plano y fondo de 432 px) en `game/arte/marca/`; splash a pantalla completa con el color de la paleta | Bien; revisar el ícono en teléfonos reales |
| Firma | `package/signed=true`; el APK de depuración usa el keystore de depuración del CI | Falta el keystore de release (ver `FIRMA_APK_PRUEBA_CERRADA.md`) |
| Formato | `gradle_build/use_gradle_build=false`: solo se puede exportar APK | Para el AAB de Play hay que activar la compilación con Gradle |
| 16 KB de página | No verificable con el APK local | Verificar con la plantilla de Godot 4.7.2 antes de publicar (requisito de Android 15) |
| Depuración | El APK de depuración es `debuggable` | Normal; el de Play se exporta en modo release |
**Lista corta para publicar:** fijar `targetSdk ≥ 35`, decidir el renderizador (Vulkan requerido o compatibilidad), activar Gradle y exportar AAB, crear el keystore o activar Play App Signing, unificar versión, verificar 16 KB y repetir esta auditoría sobre el binario final.

### 7b. Corrección con el APK que genera el CI (Godot 4.7.2, 26-nov-2026, ejecución 340)
El primer análisis usó un APK local del 24-nov hecho con una plantilla antigua. El APK que **genera hoy el CI** (`tools/auditar_apk.py` en `android.yml`) dice: `compileSdk 36`, **`minSdk 24`, `targetSdk 36`**, sin permisos, vertical, `allowBackup` desactivado, solo `arm64-v8a` (24 MB comprimidos de bibliotecas, 40 MB el APK) y **Vulkan declarado como NO requerido** (`required="false"`). Por lo tanto:
- **`targetSdk` ya cumple** (36 ≥ 35); no hay que cambiar nada en `export_presets.cfg` para eso.
- **Vulkan ya no excluye teléfonos** en Play: el motor cae al renderizador compatible si el teléfono no tiene Vulkan (el filtro de tienda no lo exige). Decisión de renderizador: ver `docs/RENDERIZADORES.md` (recomendación: pasar a `gl_compatibility`, que es lo que ya se prueba; no se cambió `project.godot`).
- Quedan abiertos: 16 KB de páginas (el auditor ahora lee la alineación de cada biblioteca `.so` y la imprime en el CI), keystore de release, AAB con Gradle y la versión.
