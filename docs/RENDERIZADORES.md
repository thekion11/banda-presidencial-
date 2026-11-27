# Renderizador: «mobile» (Vulkan) frente a «gl_compatibility» (OpenGL ES) — análisis del 26-nov-2026

**No se cambió `project.godot` (el proyecto usa `renderer/rendering_method="mobile"`): la decisión es del usuario.** Esta página dice qué se pudo medir y qué no, y recomienda.

> **Adenda del 27-nov-2026 (sesión visual): «mobile» ya se puede medir aquí.** Con Vulkan por software (`apt-get install -y mesa-vulkan-drivers`, que trae lavapipe) Godot arranca con «Forward Mobile» bajo xvfb: `xvfb-run -a godot --path . --rendering-method mobile --resolution 390x844 -s tests/captura_comparar.gd -- /tmp/capm`. Comparadas con las de `gl_compatibility`, **54 de 55 capturas son iguales o casi** (≤ 1,4 % de píxeles distintos; 33 idénticas). La excepción era el **Comité 3D**: con «mobile» el terreno salía casi blanco (mediana 255,249,222 frente a 240,223,184), porque ilumina más fuerte con la misma luz. Se compensó con `ComiteMapa3D.FACTOR_LUZ_MOBILE = 0,78`, que solo se aplica fuera de Compatibility: ahora da 235,223,198. La obra 3D del hito sale igual en los dos. Detalle en `docs/QA_VISUAL.md`. La recomendación de abajo sigue en pie (la decisión es del usuario), pero el riesgo de «aspecto distinto al probado» ya está medido y es pequeño. Rendimiento y RAM con «mobile» siguen sin medir: lavapipe no representa un teléfono.

## Qué se pudo y qué no se pudo comparar
- **No se pudo medir «mobile» aquí:** el entorno de desarrollo y el CI no tienen un controlador Vulkan (ni siquiera uno por software), así que ninguna captura ni medición del proyecto corre con «mobile». **Todo lo que se ha medido y comparado con la maqueta hasta hoy se hizo con `gl_compatibility`:** las capturas de `tests/captura_comparar.gd`, `diferencia_maqueta.py`, los 578 MB de pico de RAM, las llamadas de dibujo (`medir_cuadros`: día 268, Comité 3D 90) y los costos de animación (`medir_transiciones`). Por lo tanto no hay una diferencia visual (ΔE, píxeles) ni de rendimiento «mobile» frente a «compatibility» que reportar: no existe el segundo término de la comparación.
- **Lo que sí es verificable por el código:** el 3D del juego es simple. El Comité 3D y la obra usan un `Environment` de fondo de color con luz ambiente, `MultiMesh` y suavizado MSAA 2× (compatible con ambos renderizadores desde Godot 4.2); no usan sombras, brillo (glow), SSAO, niebla, mapeo de tonos ni sombreadores de 3D propios. Los sombreadores propios son de interfaz 2D (`tema.gd`, `carta_ui.gd`), que funcionan igual en los dos. Por eso es esperable que la diferencia visual sea pequeña, pero **no está medida**.
- **Alcance de dispositivos (APK que genera hoy el CI, Godot 4.7.2):** el manifiesto declara Vulkan como **no requerido** (`required="false"`), es decir Play no filtra teléfonos sin Vulkan. Con «mobile», un teléfono sin Vulkan 1.0 depende de que el motor caiga a OpenGL por su cuenta; con «gl_compatibility» todos los teléfonos con OpenGL ES 3.0 usan el mismo camino que se probó.

## Comparación cualitativa
| | «mobile» (hoy) | «gl_compatibility» |
|---|---|---|
| Lo probado en este proyecto | Nada (sin Vulkan en el CI) | **Todo** (capturas, tests de interfaz, RAM, llamadas de dibujo) |
| Teléfonos que alcanza | Los con Vulkan; el resto, si el motor cae a OpenGL | Todos los con OpenGL ES 3.0 (el rango más amplio) |
| Efectos que el juego usa | MSAA 2×, `MultiMesh`, luz ambiente | Los mismos |
| Costo en teléfonos de gama baja | No medido | No medido en teléfono; menor uso de memoria de video suele ser mejor en gama baja |
| Riesgo | Que el aspecto o el rendimiento en teléfono difieran de lo probado en el CI | Perder funciones avanzadas de Vulkan que el juego no usa |

## Recomendación
Pasar a `gl_compatibility` **antes de la prueba cerrada**: lo que se ha probado y comparado con la maqueta es exactamente lo que correrían los testers, cubre el rango más amplio de teléfonos y el juego no usa nada que solo «mobile» ofrezca. El cambio es de dos líneas en `project.godot` (`renderer/rendering_method="gl_compatibility"` y `renderer/rendering_method.mobile="gl_compatibility"`) más cambiar la etiqueta `Mobile` de `config/features` a `GL Compatibility`; después hay que volver a correr `captura_comparar` (para confirmar que las capturas no cambian) y medir fps y RAM en un teléfono real con `docs/MEDICION_TELEFONO.md`.
Si el dueño prefiere mantener «mobile», la medición en un teléfono con Vulkan y otro sin él pasa a ser obligatoria antes de la prueba.
