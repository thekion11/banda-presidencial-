# Diferencia numérica con la maqueta

Generado por `tools/diferencia_maqueta.py` a partir de `tests/captura_comparar.gd`. Para cada pantalla con maqueta:
porcentaje de píxeles con diferencia de color visible (ΔE CIE76 > 20), ΔE medio y la zona de unos 32 px que más difiere.
La maqueta usa cifras ilustrativas y el juego datos reales de la partida, así que nunca da cero: sirve para
comparar pantallas entre sí y ver si un cambio acerca o aleja. Imágenes: `dif_<pantalla>.jpg` (maqueta | juego | calor).

| Pantalla | Píxeles distintos | ΔE medio | Zona que más difiere | ΔE de esa zona |
|---|---|---|---|---|
| dia | 43.1 % | 30.8 | inferior derecha (y ≈ 640–672 px) | 79 |
| nacion | 28.6 % | 24.4 | superior centro (y ≈ 128–160 px) | 104 |
| urbano | 23.0 % | 18.5 | superior centro (y ≈ 192–224 px) | 83 |
| votacion | 22.5 % | 19.4 | inferior izquierda (y ≈ 736–768 px) | 68 |
| hito | 19.1 % | 15.1 | media derecha (y ≈ 512–544 px) | 83 |
