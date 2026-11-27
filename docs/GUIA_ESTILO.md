# Guía de estilo de la interfaz (27-nov-2026)

Para quien herede el proyecto: cómo mantener la interfaz coherente sin tener que releer cada pantalla. La regla de oro sigue siendo la de CLAUDE.md, **la maqueta manda**: si esta guía y la maqueta discrepan, se corrige la guía. Todo lo de aquí ya vive en el código (`game/tema.gd`, `game/componentes/`) y casi todo tiene una prueba que falla si se rompe (columna «Lo vigila»).

## 1. Tokens

### Color (`Tema`, paleta congelada)

| Token | Valor | Uso |
|---|---|---|
| `OCEANO` | `#0B2236` | Fondo de todas las pantallas oscuras; color de borrado del render |
| `PANEL` | `#16405F` | Tarjetas, botones secundarios, chips |
| `ORO` | `#F2C14E` | Acento: pestaña activa, botón elegido, rótulos de sección en mayúsculas, halo del botón principal |
| `ROJO` | `#C23B2E` | Botón principal (acción de avanzar), crisis |
| `CREMA` | `#FBF7EC` | Hojas claras (Corrector, ficha ampliada, avisos) |
| `TEXTO` / `TEXTO_SUAVE` | `#FFFFFF` / `#B9C9D8` | Texto sobre oscuro: principal / secundario |
| `TINTA` | `#0B2236` | Texto sobre crema, oro y fondos claros |
| `GRIS_CLARO` | `#566171` | Texto secundario sobre claro (contraste ≥ 5) |
| `FONDO_CLARO` / `BORDE_CLARO` | `#F1EDE4` / `#D9D2C2` | Pantallas claras (hito, mapa urbano) |
| `SUBE` / `BAJA` | `#4CC38A` / `#E8705A` | Lo que sube o baja. **Úsalos con `Tema.bien()` y `Tema.mal()`**, que cambian a azul y naranja con «Colores para daltonismo» |
| `ESCALA_APROBACION` | `#E8705A` → `#4CC38A` (5 pasos) | Mapa y barras de aprobación, con `Tema.color_aprobacion(v)` |

Un color nuevo solo puede ser una mezcla de dos colores de la paleta, o de uno con blanco o negro (`lightened`, `darkened`, `lerp`). Lo vigila `tests/test_paleta.gd` (ΔE ≤ 8 en CIELAB). Las cintas de categoría de las cartas están en `CartaUI.COLORES_CATEGORIA`.

### Tipografía

| Uso | Fuente | Función |
|---|---|---|
| Títulos, cifras, botones | Space Grotesk 700 | `Tema.etiqueta(t, tam, color, true)` y `Tema.boton(...)` |
| Texto | Inter 400–600 (fuente por defecto del proyecto) | `Tema.etiqueta(t, tam, color, false, peso)` |

Escala en uso, en pt: **10–11** para rótulos en mayúsculas y notas, **12–13** para texto de tarjetas, **14–15** para texto destacado y botones, **18–24** para títulos de pantalla y **26–46** para cifras grandes y la portada. **Mínimo 10 pt.**

- `Tema.etiqueta` crece con «Texto grande» (×1,15) y ajusta líneas.
- `Tema.etiqueta_corta` no crece ni ajusta líneas. Úsala solo para cifras y rótulos que deben caber en un ancho fijo (chips, cintas, pastillas), y ponle `clip_text` si el texto viene de los datos.

Lo vigila `tests/test_textos.gd`: tamaño, fuente, glifos que existen en la fuente y nada fuera de pantalla con letra ×1,3 y ×1,5.

### Medidas

| Token | Valor | Notas |
|---|---|---|
| Lienzo lógico | 390 de ancho (`keep_width`); 844 de alto de referencia | Teléfonos bajos: 390×693. Tablet y plegable abierto: 390×844 con bandas (`Main.aspecto_para`) |
| Margen lateral | 16 px (pantallas), 12–14 px (cabeceras) | |
| Zona táctil | `Tema.TACTIL` = 44 px mínimo | `tests/test_tactil.gd` |
| Botón principal | 358 × 52, en (16, 739) | `FilasUI.boton_pie` o `Barras.boton_jugar`; **siempre en el mismo sitio** |
| Botones | 52 (principal), 48 (de hoja o panel), 46 (secundario), 44 (en lista) | `Tema.boton(texto, fondo, color, tam, alto)` |
| Botón-tarjeta | 60–104 de alto | `Tema.estilo_tarjeta(b)` (afiliación, listas) |
| Barra inferior | 56 de alto, 4 pestañas | `Barras.nav` |
| Separaciones | 8 por defecto (`FilasUI.col()`); 4–6 dentro de una tarjeta; 10–12 entre bloques | |
| Radios | 18 en botones, 14 en tarjetas y chips, 10–12 en piezas chicas, 22–27 en cápsulas y botones redondos | `Tema.caja(color, radio, borde, grosor)` |
| Muesca arriba | `Tema.margen_superior()`: zona segura + 4, mínimo 12 | Toda cabecera la usa |
| Barra de gestos abajo | `Tema.margen_inferior()` | La aplica Main a cada pantalla. No la sumes otra vez |
| Alto útil | `Tema.alto_util()` | Pantalla menos las franjas. `Tema.pantalla_baja()` es `alto_util() < 760` y compacta mano, hemiciclo, brújula y mapas |

### Movimiento (`Movimiento`)

| Token | Valor | Uso |
|---|---|---|
| `RAPIDO` | 0,12 s | Presión de botón |
| `BASE` | 0,26 s | Entrar a una pantalla, abrir hojas |
| `ENFASIS` | 0,7 s | Cifras que cuentan, barras que se llenan |
| `PASO` | 0,04 s | Separación de una entrada escalonada (`Movimiento.escalonar`) |
| `ALZA` | 16 px | Lo que sube una pantalla al entrar |

Toda animación termina exactamente en su estado final y nada depende de ella para entenderse. Con «Reducir movimiento» se quitan las partículas y los efectos intensos (`Movimiento.intenso()`), y en headless todo queda inmediato. Lo vigilan `tests/test_movimiento.gd` y `tests/test_reglas_ui.gd`.

### Íconos (`Icono`)

- Solo vectoriales dibujados, **sin emojis**. Tipos: `Icono.TIPOS` (estrella, rayo, play, persona, personas, mapa, barras, edificio, flechas, tren, casa, cuadrícula, punto, carta).
- Tamaños: `Icono.TAMANOS` = 12 (punto de leyenda), 16 (junto a texto), 18 (en cápsula), 20 (barra inferior) y 24 (botón redondo).
- Trazo: 2 px por cada 24 de lado (`Icono.TRAZO_POR_LADO`), mínimo 1,3, todo con antialias. Los rellenos (estrella, rayo, flechas, play) no llevan trazo.
- Un ícono nuevo se agrega como un caso más de `Icono._draw` en la grilla de 24 × 24, dentro del margen 3–21, sin triángulos cerrados con esquinas agudas (dejan puntas de inglete). Se revisa en `docs/comparacion/iconos.png` (`tests/hoja_iconos.gd`).
- Lo vigila `tests/test_claridad.gd`: cada tipo usado existe y cada tamaño es de la lista.

## 2. Catálogo de componentes

| Componente | Archivo | Qué es | Reglas |
|---|---|---|---|
| Cabecera | `Barras.cabecera` | Insignia, «Campaña · Sem. N/8» o «Día N», fecha, pastilla de movimientos y 4 chips | Títulos con «…» si no caben; margen superior con `Tema.margen_superior()` |
| Chip de indicador | `Barras.pintar_chips`, `FilasUI.chip_barra` | Nombre, cifra y barra | Cifras con `Tema.dec` (coma decimal) y `Tema.miles` (punto de miles) |
| Pastilla de movimientos | `Barras.pastilla_pa` | Rayo y «5/5 mov» sobre oro | Se apaga cuando quedan 0 (`Movimiento.movimientos`) |
| Carta | `CartaUI` | Costo, cinta de categoría con tilde, arte, título y dos efectos | Tocar elige, tocar la elegida juega, deslizar hacia arriba juega y mantener abre la ficha |
| Ficha ampliada | `FichaAmpliada` | La carta entera sobre crema | Base fija sobre la mano. Con letra grande, la ilustración cede alto (150 → 56) antes que el texto (`tests/test_fichas_largas.gd`) |
| Mano | `ManoUI` | Abanico de 5 cartas | En pantalla baja pierde la fila «Tu mano» |
| Corrector | `cuerpo_dia.gd` | Hoja crema bajo la mano | Nunca dice un «no» seco: propone la versión viable |
| Botón principal | `Barras.boton_jugar`, `FilasUI.boton_pie` | Rojo con halo dorado | Mismo rectángulo en todas las pantallas; «Terminar semana» pide confirmar si sobran movimientos |
| Botón redondo | `Barras.boton_redondo` | Delegar (persona) | Esquina inferior derecha vacía (PR-02) |
| Barra inferior | `Barras.nav` | Mapa, Comité, Congreso, Gabinete | Pestaña activa en oro con raya de 28 × 3 arriba |
| Tarjeta | `FilasUI.tarjeta`, `Tema.caja` | Panel con radio 14 | Contenido largo dentro de `FilasUI.scroll` |
| Fila-botón | `FilasUI.fila_boton` | Botón de 72 de alto con 2–3 líneas | Listas de gabinete, cartera y asesores |
| Aviso (toast) | `Toast` | Franja oro arriba, se va sola | Una frase; dice la consecuencia («Promesa en Atacama: +0,5…») |
| Telón de la semana | `TelonSemana` | Baja entre semanas: fecha, cambios y encuesta | Se va solo y retiene los eventos mientras se ve |
| Evento | `OverlaysDia.evento` | Capa a pantalla completa: cabecera oro, título 24, efecto primero y texto plegado | Atrás no lo salta; las decisiones no gastan movimientos |
| Hemiciclo y sello | `Hemiciclo`, `SelloVoto` | Votos que caen, línea del mínimo y sello APROBADO o RECHAZADO | Más lento si la votación es ajustada; alto 205 (170 o menos en pantalla baja) |
| Mapa de Chile | `MapaChile` | Regiones con la escala de aprobación | Ocupa siempre más de un tercio de la pantalla del día (`tests/test_reglas_ui.gd`) |
| Mapa urbano | `UrbanoMapa`, `UrbanoVista` | Gran Santiago con el Metro | Caché en reposo (`UrbanoCache`) y dibujo en vivo solo al mover |
| Tutorial | `Tutorial` | Velo con foco y tarjeta «PASO N DE 5» | «Saltar tutorial» siempre visible |
| Capa que tapa | `Tapa.cubrir` | Esconde el día debajo de una vista a pantalla completa | Ahorra dibujo; Atrás la cierra |

## 3. Reglas de uso

1. **Una acción principal por pantalla**, en el botón rojo de abajo y siempre en el mismo sitio. Lo secundario va en `Tema.boton_secundario` o en tarjetas.
2. **Oro marca lo elegido o lo activo**, no decora. Rojo es avanzar o alarma. Verde y coral se usan solo para subir o bajar, siempre con `Tema.bien()` y `Tema.mal()`.
3. **Cifras a la chilena:** coma decimal (`Tema.dec`) y punto de miles (`Tema.miles`). Las cifras ilustrativas van rotuladas como tales.
4. **Rótulos de sección** en mayúsculas, Space Grotesk 10–11 y color oro («EVENTO · 22:00», «CONFIGURACIÓN · PASO 3»).
5. **Texto que viene de los datos** se ajusta en líneas (`Tema.etiqueta`) o se recorta con «…» (`clip_text`); nunca empuja el ancho más allá de 390. Si es largo, va dentro de un scroll.
6. **Nada bajo las franjas del sistema:** cabeceras con `margen_superior()`; las alturas fijas se compactan con `pantalla_baja()` o `alto_util()`. Lo vigila `tests/test_zonas_seguras.gd`.
7. **Toda vista que se cierra** se registra para el Atrás de Android con `set_meta("atras", callable)`. Si no se puede cerrar, como un evento con decisión, se le da un texto que explica por qué (`tests/test_atras.gd`).
8. **Cada mensaje dice la consecuencia y la salida.** Nunca «no se puede» a secas: los rechazos usan `Razones.texto` (`tests/test_razones.gd`) y el Corrector ofrece la versión viable.
9. **El dibujo es caro en el teléfono.** Lo estático va a caché (`UrbanoCache`, textura base del mapa), lo tapado se esconde (`Tapa`) y se prefieren trazos sin antialias en mallas grandes. Los informes `tests/medir_cuadros.gd` y `tests/medir_transiciones.gd` miden el costo.
10. **Antes de cerrar un cambio visual:** pruebas en verde (`tools/run_all_tests.sh`), captura comparada (`tests/captura_comparar.gd` y `tools/diferencia_maqueta.py`) y, si te apartas de la maqueta, una línea en `docs/DIFERENCIAS_MAQUETA.md` con el porqué.

## 4. Dónde mirar

- Cumplimiento de cada regla de CLAUDE.md §5: `docs/CUMPLIMIENTO_UI.md`.
- Diferencias con la maqueta y su porqué: `docs/DIFERENCIAS_MAQUETA.md`; cifras en `docs/comparacion/DIFERENCIA_MAQUETA.md`.
- Recorrido de una persona nueva: `docs/PRIMERA_EJECUCION.md`.
- Lienzo con todas las pantallas (Claude Design): https://claude.ai/artifact/JqjCmTAZGf5NkCRPEjbv8N
