# Parche propuesto: exportar un AAB de release firmado (no activo)

**Estado:** propuesta para que el dueño decida; **no está aplicado y no se probó** (necesita secretos y una exportación con Gradle). Se guarda en `docs/parches/` y no en `.github/workflows/` para que no se ejecute solo.

## Qué cambia respecto de hoy
Hoy el CI exporta un APK de depuración (`android.yml`), que ya cumple `targetSdk 36`, `minSdk 24`, sin permisos y vertical (auditoría de `tools/auditar_apk.py`). Para Google Play falta un **AAB de release firmado**, que exige Gradle.

## Pasos para activarlo
1. **Keystore propio** (lo crea el dueño, ver `docs/FIRMA_APK_PRUEBA_CERRADA.md`; recomendado: Play App Signing y este keystore solo como clave de subida).
2. **Secretos del repositorio** (Settings → Secrets and variables → Actions): `ANDROID_KEYSTORE_BASE64` (el `.jks` en base64: `base64 -w0 presidente-release.jks`), `ANDROID_KEYSTORE_PASSWORD` y `ANDROID_KEY_ALIAS`.
3. **Segundo preset en `export_presets.cfg`** llamado «Android release» con: `gradle_build/use_gradle_build=true`, `gradle_build/export_format=1` (AAB), `package/signed=true`, `architectures/arm64-v8a=true` y el resto igual al preset actual (`version/name` y `version/code` se toman de `tools/check_version.py`, que debe seguir en verde).
4. **Copiar** `docs/parches/android-release.yml` a `.github/workflows/android-release.yml`.
5. Lanzar el flujo a mano («Run workflow»), descargar el artefacto `presidente-release-aab` y subirlo a la prueba cerrada de Play Console.

## Qué hay que revisar al activarlo (todo sin verificar)
- La carpeta `android/build` (plantilla de Gradle) y el archivo `android/.build_version` deben coincidir con la versión de Godot; si la plantilla ya se instalara desde el editor, este paso sobra.
- Las variables `GODOT_ANDROID_KEYSTORE_RELEASE_*` las lee Godot al exportar en modo release; si el nombre cambiara en 4.7.2, la exportación fallaría con un mensaje claro.
- 16 KB de páginas: `tools/auditar_apk.py` ya imprime la alineación de las bibliotecas en el CI de depuración; repetir sobre el AAB.
- Subir `version/code` en cada entrega a Play (debe crecer siempre).
