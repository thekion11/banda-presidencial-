# Cómo medir fps y memoria en un teléfono real, y comprobar el determinismo (26-nov-2026)

Nada de esto se ha medido en un teléfono: en escritorio hay render por software y los números no valen para la meta (30 fps estables en la escena urbana 3D, ≤ 800 MB de RAM). Esta guía es para quien tenga un Android y un computador.

## 0. Preparación (una vez)
1. En el teléfono: Ajustes → Acerca del teléfono → toca 7 veces «Número de compilación» → Opciones de desarrollador → activa **Depuración por USB**.
2. En el computador: instala `adb` (paquete «Android platform-tools», gratuito de Google). Conecta el teléfono por USB y acepta la huella RSA en pantalla. Comprueba: `adb devices` debe listar el teléfono como `device`.
3. Instala el APK de depuración: `adb install -r presidente-debug.apk`. El paquete se llama `cl.presidente.juego`.

## 1. Memoria (RAM)
```
adb shell dumpsys meminfo cl.presidente.juego
```
Léelo así: **TOTAL PSS** es la memoria que usa el juego (meta ≤ 800 MB = 800.000 KB); **Graphics** y **Native Heap** son lo que más pesa en un juego 3D. Repite en tres momentos: (a) pantalla del día, (b) mapa urbano abierto, (c) Comité 3D abierto, y anota el mayor. Para ver la evolución mientras juegas:
```
adb shell "while true; do dumpsys meminfo cl.presidente.juego | grep 'TOTAL PSS'; sleep 5; done"
```
(Ctrl+C para parar.) Una subida sin freno al abrir y cerrar pantallas sería una fuga.

## 2. Cuadros por segundo (fps)
```
adb shell dumpsys gfxinfo cl.presidente.juego reset
(juega 1 minuto en la pantalla que quieras medir)
adb shell dumpsys gfxinfo cl.presidente.juego
```
En el resultado busca **Janky frames** (porcentaje de cuadros lentos; meta < 10 %) y los percentiles **50th / 90th / 95th / 99th percentile** de tiempo por cuadro: 33 ms equivale a 30 fps, 16 ms a 60 fps. El 90th por encima de 33 ms significa que se baja de 30 fps. Para el detalle cuadro a cuadro: `adb shell dumpsys gfxinfo cl.presidente.juego framestats` (columnas en nanosegundos; el tiempo total del cuadro es `FrameCompleted − IntendedVsync`).
Mide por separado: día, mapa urbano en reposo, mapa urbano arrastrando, Comité 3D, una animación (cambio de mando, telón de la semana).
Dentro del juego, «Informe de prueba → Copiar informe» también trae el mínimo de fps y la memoria máxima observada.

## 3. Registro de errores
```
adb logcat -c
adb logcat -s godot:V GodotApp:V AndroidRuntime:E *:F
```
Juega y copia las líneas con `ERROR`, `SCRIPT ERROR` o `FATAL`. Si el juego se cierra solo, el motivo queda en `AndroidRuntime`. Para guardar en archivo: `adb logcat -d > registro.txt`.

## 4. Calor y batería (opcional)
`adb shell dumpsys battery` antes y después de 20 minutos de juego (nivel y temperatura); una temperatura de la batería sobre 40 °C (valor 400) indica que el juego exige demasiado.

## 5. Comparar el determinismo con el escritorio
`tests/test_determinismo.gd` juega 4 carreras completas (semillas 11, 12, 13, 14) y compara su huella con `tests/oro/huellas.json`. Las mismas semillas y decisiones deben dar **la misma huella en el teléfono**; si difiere, el guardado por eventos no sería portable entre dispositivos.
1. En el escritorio, `godot --headless --path . -s tests/test_determinismo.gd` debe imprimir `test_determinismo: OK` (las huellas esperadas están en `tests/oro/huellas.json`).
2. En el teléfono la prueba no corre sola: hay que exportar un APK de depuración **que incluya `tests/` y `sim/`** (quitar `tests/*` del `exclude_filter` de `export_presets.cfg` en una copia) y lanzarlo con el script de la prueba: `adb shell am start -n cl.presidente.juego/com.godot.game.GodotApp --es command_line "-s res://tests/test_determinismo.gd"`, y leer el resultado con `adb logcat -s godot`. *(Procedimiento no verificado: la opción `command_line` depende de la versión de Godot; si no funciona, alternativa: jugar la misma semilla en el teléfono, copiar el «Informe de prueba» y comparar la aprobación final con la de `tools/informe_partida.gd -- <semilla> codicioso` en el escritorio.)*
3. Dónde puede diferir: operaciones de coma flotante (todas las del motor usan doble precisión IEEE: debería coincidir entre ARM y x86) y funciones del sistema (el motor no usa reloj ni azar global).
Si las huellas difieren, anota la primera carrera que difiere y avisa: se compara semana a semana con `tools/informe_partida.gd` hasta encontrar el primer turno distinto.

## Qué entregar
`dumpsys meminfo` (3 momentos), `dumpsys gfxinfo` (día, urbano, Comité 3D), el «Informe de prueba» copiado, el modelo del teléfono (`adb shell getprop ro.product.model`) y la versión de Android (`adb shell getprop ro.build.version.release`).
