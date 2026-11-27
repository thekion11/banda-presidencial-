# Pruebas pendientes de fusión

Escritas sobre ramas que aún no están en `main`; no corren en el CI (están fuera de `tests/test_*.gd`). Al fusionarse su rama, mover a `tests/` y añadir la línea de CI con `fz`.

- `fuzz_piso_luna.gd`, `mut_piso.py` — PR #10 (piso ideológico y luna de miel; mutantes P01–P06 todos muertos).
- `fuzz_transicion.gd` — PR #12 (gabinete tras la elección; mutantes Q01–Q03 muertos).
- `fuzz_ruido_eleccion.gd`, `test_voto_regional_bordes.gd`, `mut_voto.py` — PR #12 (`VotoRegional` y ruido regional; 13 de 15 mutantes muertos, 2 equivalentes).
- `fuzz_carga_mixta.gd` — cargas a mitad de semana con balas, presupuesto y agenda; necesita el arreglo de la instantánea de PR #12 (con `CM_ARREGLAR=1` pasa).
- `tests/analisis_instantanea_director.gd` (ya en `tests/`) pasa a `test_instantanea_director.gd` cuando entre #12.
- Falta la fixture de guardado v4 y el caso de migrar v3 a v4 de `test_guardados_antiguos.gd`, y los casos de versión 0 y −1.
