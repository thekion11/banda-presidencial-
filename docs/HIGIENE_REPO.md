# Higiene del repositorio (auditoría del 26-nov-2026; nada se borró)

## Datos que ningún archivo nombra
Búsqueda del nombre de cada archivo de `data/` en código, herramientas y documentos:
| Archivo | Tamaño | Veredicto |
|---|---|---|
| `data/proyectos/*.json` (mop_obras_*, concesiones_otros) | 2 a 23 KB c/u | **En uso**: `tools/generar_cartas.py` lee todos con `glob("proyectos/*.json")`; no están huérfanos |
| `data/curadas/grupo_B.json`, `grupo_C.json` | 43 y 44 KB | Fuente de las cartas curadas (`tools/validar_curadas.py`); ningún proceso las vuelve a leer: podrían archivarse tras confirmar que `data/cartas_curadas.json` las contiene |
| `data/schemas/*.schema.json` (9) | 0 a 2 KB | Esquemas descriptivos; ninguna herramienta los carga (la validación vive en `tools/validate_data.py` y `validate_tipos.py`). Dejar como documentación o cargarlos en el validador |
Todo lo demás de `data/` se referencia. `data/verificacion/`, `data/bcn/` y `data/partidos/` son investigación que el juego no carga (ver `docs/DATOS.md`).

## Documentos que nadie enlaza
`docs/CONTRIBUIR.md`, `docs/EQUIDAD_REGIONAL.md`, `docs/RESUMEN_EXPERIMENTO.md` y `docs/ESTADO_SISTEMAS.md` no los cita ningún otro archivo: se agregaron hoy salvo `ESTADO_SISTEMAS.md`. Se enlazan desde `README.md` (sección Documentación).
Documentos con cifras de una foto antigua (no son errores; son informes fechados): `REVISION.md` (23-nov), `ANALISIS_PROFUNDIDAD.md`, `INFORME_BALANCE.md` (secciones por fecha), `ESTADO_FASES.md` (historial). `docs/GUIA_PRUEBA.md` y `docs/PRUEBA_CERRADA.md` son los vigentes para probar.

## Pruebas y scripts fuera del CI
19 archivos de `tests/` no los ejecuta el CI porque no son pruebas: ayudas (`bots.gd`, `ayuda_*.gd`, `recorrido_ui.gd`), análisis (`analisis_*`, `ablacion.gd`, `informe_*.gd`, `montecarlo.gd`, `perfil_turnos.gd`), mediciones con pantalla (`medir_*`) y capturas (`captura*.gd`, `grabar_video.gd`, `humo_v2.gd`). Se corren a mano (lista en `CLAUDE.md §7`).

## Ramas remotas (sin borrar)
| Rama | Estado respecto de `main` | Recomendación |
|---|---|---|
| `datos/cartas-1040`, `datos/leyes-eventos`, `datos/partidos`, `datos/proyectos-publicos`, `feat/mecanicas-v2`, `feat/ui-v2` | Totalmente incluidas en `main` (0 commits propios) | Se pueden borrar |
| `revision/auditoria` | 6 commits que `main` no tiene (informe de la auditoría del 23-nov) | Revisar antes de borrar; sus hallazgos están recogidos en `docs/REVISION.md` |
| `ccr-d93c03f2-ag1f7o` | Igual a `main` | Rama de la sesión visual; puede borrarse al cerrar la sesión |
| `ccr-c6aa6dd1-uuqdjm` | 63 commits por delante: PR #8 de «Búsqueda infinita de fallas» | Fusionar cuando su CI quede en verde |
| `ccr-ec102a3c-giitie` | Rama de esta sesión (se publica también en `main`) | Mantener |
`main` como rama por defecto en GitHub (U8) sigue pendiente de ti.
