# Guía: APK firmado para la prueba cerrada (26-nov-2026)

Para el usuario. **No se generó ningún secreto ni clave**; aquí solo están los pasos y lo que ya existe. Publicación en Google Play sigue en pausa.

## Qué hay hoy
- **CI:** `.github/workflows/android.yml` exporta un **APK de depuración** (arm64-v8a, ≈ 31 MB) en cada push a `main` y lo guarda como artefacto 30 días; comprueba que pese menos de 150 MB. El keystore de depuración se genera en el propio trabajo con la clave pública estándar de Android (`android`), por lo que no es un secreto.
- **Preset de exportación** (`export_presets.cfg`, versionado y sin claves): paquete `cl.presidente.juego`, `version/code=1`, `version/name="0.1.0"`, orientación vertical, sin permisos, `gradle_build/use_gradle_build=false`.
- **Lo que NO se prueba en el CI:** que el APK arranque. El CI exporta pero no lo instala ni lo ejecuta. El arranque y los 30 fps siguen sin medirse en un teléfono real (criterio de salida de la Fase 1). Alternativa barata: `xvfb-run godot ... -s tests/test_ui_humo.gd` ya recorre las pantallas en escritorio.
- Un valor de `data/version.json` («0.9.0-prueba1», commit y fecha) lo escribe `tools/generar_version.py` y se muestra en el informe de prueba.

## Lo que falta para un APK firmado de prueba cerrada
1. **Keystore de release propio** (lo crea el usuario en su máquina, no en el repositorio):
   `keytool -genkeypair -v -keystore presidente-release.jks -alias presidente -keyalg RSA -keysize 2048 -validity 10000`
   Guardar el archivo y las dos contraseñas en un gestor de contraseñas y hacer copia de seguridad: **si se pierde, no se puede actualizar la app** (salvo que se use «Play App Signing», recomendado: Google guarda la clave de firma y el usuario solo conserva una clave de subida).
2. **Cómo entregárselo a Godot sin subirlo al repositorio:**
   - Local: en Ajustes del Editor o con variables de entorno `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` y `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` (Godot las lee al exportar en modo release).
   - CI: guardar el keystore en base64 y las contraseñas como **secretos del repositorio** de GitHub (Settings → Secrets), decodificarlo en un paso del workflow a `$RUNNER_TEMP` y exportar con `--export-release`. Nunca imprimir los valores en el registro.
   - Los patrones `*.keystore`, `*.jks`, `*.p12`, `*.pem`, `*.key`, `key.properties`, `export_credentials.cfg` ya están en `.gitignore`.
3. **Versión:** subir `version/code` (entero que debe crecer en cada subida a Play) y `version/name` en `export_presets.cfg` en cada entrega; hoy es 1 y 0.1.0, mientras `data/version.json` dice 0.9.0-prueba1: unificar el criterio (propuesta: `version/name` = lo que muestra el informe de prueba, y `version/code` = número de ejecución del CI).
4. **Formato AAB** para Play (el APK sirve para instalar directo en los teléfonos de los probadores): exportación Android con «Formato de exportación» = AAB, lo que exige la plantilla de compilación Gradle (`gradle_build/use_gradle_build=true`) e instalarla desde el editor; hoy está en `false`.
5. **Requisitos de Play** que el preset aún no declara (ver `docs/RIESGOS_PLAY_STORE.md`): nivel de API objetivo vigente (`platforms;android-35`/36 ya están en el CI), compatibilidad con páginas de 16 KB y ficha con política de privacidad pública.
6. **Prueba en teléfono real** antes de repartir el APK: instalar, abrir, jugar una semana, cerrar y continuar (instantánea), y medir fps y memoria con el «Informe de prueba».
7. **Probadores:** una cuenta de desarrollador personal nueva exige una prueba cerrada con ≥ 12 probadores durante 14 días antes de pasar a producción (`docs/GOOGLE_PLAY.md`).

## Resumen de decisiones que son del usuario
Crear y custodiar el keystore (o activar Play App Signing), abrir la cuenta de desarrollador, elegir el esquema de versiones y decidir cuándo salir de la pausa de Play.
