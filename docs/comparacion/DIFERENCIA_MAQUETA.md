# Diferencia numérica con la maqueta

Generado por `tools/diferencia_maqueta.py` a partir de `tests/captura_comparar.gd`. Para cada pantalla con maqueta:
porcentaje de píxeles con diferencia de color visible (ΔE CIE76 > 20), ΔE medio y la zona de unos 32 px que más difiere.
La maqueta usa cifras ilustrativas y el juego datos reales de la partida, así que nunca da cero: sirve para
comparar pantallas entre sí y ver si un cambio acerca o aleja. Imágenes: `dif_<pantalla>.jpg` (maqueta | juego | calor).

| Pantalla | Píxeles distintos | ΔE medio | Zona que más difiere | ΔE de esa zona |
|---|---|---|---|---|
| dia | 39.2 % | 27.7 | inferior centro (y ≈ 640–672 px) | 76 |
| nacion | 29.2 % | 25.0 | superior centro (y ≈ 96–128 px) | 104 |
| votacion | 22.0 % | 19.0 | inferior izquierda (y ≈ 736–768 px) | 68 |
| urbano | 21.3 % | 16.7 | superior centro (y ≈ 192–224 px) | 88 |
| hito | 17.8 % | 13.9 | media derecha (y ≈ 448–480 px) | 75 |
