# Presidente de Chile

Simulador político por turnos para Android, hecho con Godot 4 y GDScript. Funda tu partido con un test ideológico, gana la elección en 8 semanas de campaña y gobierna 208 semanas con Congreso bicameral, Tribunal Constitucional, 25 ministros, obras en 5 fases y Corrector de Realismo.

**Estado (23 nov 2026):** Fase 0 completa; Fase 1 jugable de punta a punta (menú, test ideológico, partido propio, campaña de 8 semanas, 208 semanas de gobierno, Congreso bicameral, Gabinete, fin de partida); Fase 2 con el Comité y los hitos de obra en **3D real**; Fase 3 con trazado propio sobre grafo (Dijkstra) y sliders; Fase 4 con 55 cartas, 40 eventos y balance calibrado con bots. APK de depuración de ≈ 30 MB. Cartografía urbana real (OpenStreetMap) en el mapa urbano y el Comité. **Pendiente:** probar en teléfono real (30 fps y RAM), relieve del terreno en el 3D urbano, prueba cerrada en Google Play y verificación de artículos constitucionales y licencias.

## Cómo probarlo
1. Instala [Godot 4.3](https://godotengine.org/download) y abre la carpeta del proyecto (o `godot --path .`).
2. Pruebas: ver comandos en `CLAUDE.md §7`.

## Documentación
- `CLAUDE.md`: reglas del proyecto y flujo de trabajo.
- `docs/AUDITORIA_VIDA_REAL.md`: qué tan fiel es la estructura a Chile real y qué falta.
- `docs/DATOS.md`: fuentes, licencias y datos por verificar.
- `docs/ANDROID.md`: compilar el APK.
- `docs/DIFERENCIAS_MAQUETA.md`: en qué se aparta el juego de la maqueta.

Obra de ficción satírica: políticos reales con alias, personajes y cifras ilustrativas rotuladas como tales.
