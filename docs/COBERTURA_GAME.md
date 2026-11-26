# Cobertura de funciones de `game/` (26-nov-2026)

Medida con `python3 tools/cobertura_funciones.py godot --game`: copia el proyecto, inserta un contador al inicio de cada función de `game/` y corre 14 pruebas de interfaz bajo `xvfb-run` (`test_ui_humo`, `test_textos`, `test_tactil`, `test_claridad`, `test_escenas`, `test_accesibilidad`, `test_movimiento`, `test_paleta`, `test_estados`, `test_tapa`, `test_mapa_entrada`, `test_metro_lineas`, `test_identidad`, `captura_comparar`). No cuenta las funciones de una sola línea.

**Resultado: 451 funciones, 420 ejecutadas (93,1 %), 31 nunca ejercitadas.**

| Archivo | Funciones sin ejecutar | Qué son |
|---|---|---|
| `componentes/barras.gd` | `texto_decision` | Texto de una decisión en la barra; ninguna prueba abre un evento con decisión en esa barra |
| `componentes/carta_ui.gd` | `_fondo_sin_arte`, `_gema` | Carta sin ilustración y gema de rareza: faltan cartas sin arte en las pruebas |
| `componentes/comite_mapa.gd` | `_vista_toque`, `quitar_estacion`, `terminar_edicion` | Edición táctil de estaciones del Comité 2D |
| `componentes/comite_mapa_3d.gd`, `obra_3d.gd` | `_gui_input`, `ir_a`, `reproducir` | Gestos y reproducción de la obra en 3D |
| `componentes/filas_ui.gd` | `fila_h` | Fila horizontal auxiliar |
| `componentes/golpe_prensa.gd` | `ministro_del_escandalo` | Escándalo de ministro: el golpe de prensa nunca se dispara en las pruebas de UI |
| `componentes/leyenda_metro.gd` | `_alternar_todas`, `refrescar` | «Ocultar/Mostrar todas» de la leyenda del Metro |
| `componentes/mapa_chile.gd` | `_gui_input`, `lanzar_fuegos`, `reaccionar` | Toques en el mapa, fuegos y reacción del mapa a una carta |
| `componentes/mapa_continente.gd` | `_a_pantalla`, `_area`, `_draw`, `_gui_input` | Mapa de Sudamérica: nunca se abre en las pruebas |
| `componentes/musica.gd` | `_detener`, `al_cambiar_ajuste` | Detener la música y reaccionar al ajuste de volumen |
| `componentes/panel_nacion_completo.gd` | `_geo_nombre` | Nombre geográfico en la vista Nación |
| `componentes/urbano_cache.gd` | `invalidar` | Invalidar la caché del mapa urbano |
| `componentes/urbano_vista.gd` | `_vista_mueve`, `_vista_suelta`, `_vista_toque` | Arrastre y zoom del mapa urbano |
| `pantallas/paneles_dia.gd` | `_tarjeta` | Tarjeta de un panel del día |
| `pantallas/pantalla_cartera.gd` | `_sin_tildes` | Búsqueda por título sin tildes en la cartera |
| `pantallas/pantalla_dia.gd` | `_aprobar` | Aprobar una propuesta desde la pantalla del día |

## Lectura
- **Casi todo lo no cubierto son gestos táctiles** (`_gui_input`, arrastre, zoom, toque en el mapa): Godot headless no los simula sin inyectar `InputEvent`; las pruebas existentes miden posiciones y tamaños, no interacción.
- **Tres huecos de contenido**: el mapa del continente (`mapa_continente.gd`) no se abre en ninguna prueba, el golpe de prensa (escándalo de ministro) no se dispara, y no hay una carta sin ilustración. Son los que más valdría cubrir (un test que abra el continente y fuerce un escándalo).
- **Funciones fuera de la lista**: las de una línea (≈ 40) no se instrumentan.
- La sesión «Diseño visual» es dueña de `game/` y de sus pruebas: esta lista es una entrada para su cola, no se tocó código.
