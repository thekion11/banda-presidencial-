# Compilar para Android

Estado: el APK de depuración se exporta y firma (≈ 30 MB, arm64-v8a). **No se ha probado en un teléfono real**: eso es el criterio de salida de la Fase 1 y sigue pendiente.

## Local (Linux)
1. Godot 4.3 con plantillas de exportación (`Godot_v4.3-stable_export_templates.tpz`).
2. JDK 17+ y Android SDK (`platform-tools`, `build-tools;34.0.0`, `platforms;android-34`) y, en Editor Settings, `export/android/android_sdk_path`, `java_sdk_path` y el keystore de depuración.
3. `godot --headless --path . --export-debug "Android" build/presidente-debug.apk`
4. Instalar: `adb install -r build/presidente-debug.apk`

## CI
`.github/workflows/android.yml` (disparo manual) genera el keystore de depuración, exporta el APK y lo publica como artefacto. No contiene secretos.

## Publicación (pendiente, requiere decisiones del dueño)
- Keystore de **release** propio (nunca en el repositorio) y exportación AAB.
- API objetivo vigente de Google Play (verificar antes de publicar; el Documento Maestro menciona 36).
- Prueba cerrada con 12+ testers durante 14 días; declarar contenido político satírico y uso de IA en ilustraciones.
- Regiones pesadas por Play Asset Delivery si el paquete base supera 150 MB (hoy no hace falta).

Guía de firma para la prueba cerrada (keystore, secretos del CI, versión, AAB): `docs/FIRMA_APK_PRUEBA_CERRADA.md`.
