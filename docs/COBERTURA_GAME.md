# Cobertura de funciones de `game/` (27-nov-2026)

Medida con `python3 tools/cobertura_funciones.py godot --game`: copia el proyecto, inserta un contador al inicio de cada función de `game/` y corre bajo `xvfb-run` las pruebas de interfaz de la lista `UI` del script (23 pruebas más `captura_comparar`). No cuenta las funciones de una sola línea.

**Resultado del 27-nov: 467 funciones, 463 ejecutadas (99,1 %), 4 sin ejecutar** (el 26-nov eran 420 de 451, 93,1 %).

Qué se hizo con las 31 del 26-nov (cola 6 de la coordinadora):
- **Código muerto, borrado:** `FilasUI.fila_h` y `UrbanoCache.invalidar`. Ninguna tenía usos.
- **Caminos reales, ahora con prueba:** `tests/test_gestos.gd` cubre los toques y arrastres en los mapas de Chile, del continente, del Comité (2D y 3D) y urbano; la obra 3D (arrastre, fases y reproducir); «Ocultar todas» de la leyenda del Metro; los fuegos de obra terminada; el escándalo ministerial; la carta sin ilustración; la música apagada y encendida; aprobar una propuesta y el texto de una decisión. Las demás funciones de la lista ya las ejecutan las pruebas nuevas de la cola 5 (`test_zonas_seguras`, `test_veracidad`, `test_animaciones_completas`, `test_fichas_largas`, `test_reglas_ui`, `test_atras`, `test_estado_tardio`).
- **Arreglo que salió de cubrirlas:** aprobar una propuesta que no se puede respondía «No se pudo aprobar la propuesta.» y ahora dice el motivo (`Razones`).

Las 4 que quedan:

| Función | Por qué no se ejecuta | Decisión |
|---|---|---|
| `urbano_vista.gd`: `_vista_mueve`, `_vista_suelta`, `_vista_toque` | Son ganchos virtuales vacíos. `ComiteMapa` los reemplaza todos y `UrbanoMapa` reemplaza `_vista_toque`. El arrastre de `UrbanoMapa` nunca se captura (`_vista_empieza` devuelve false), así que la versión base no se llama | Se quedan: `_gui_input` los llama y una subclase sin ellos fallaría |
| `comite_mapa_3d.gd`: `_gui_input` | La cubre `test_gestos` con el botón «3D»; la medición se corrió antes de ese último ajuste | Cubierta |

## Medición anterior (26-nov-2026)

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
