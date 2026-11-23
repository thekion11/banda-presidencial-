#!/usr/bin/env python3
"""Genera data/geo/relieve.png: sombreado de relieve de Chile alineado con regiones_mapa.json.

Fuente: AWS Terrain Tiles (Mapzen, formato terrarium; derivados de SRTM y otros modelos públicos).
Salida: PNG RGBA (negro/blanco con alfa) para superponer sobre el color de cada región.
Uso   : python3 tools/geo/relieve.py [zoom=7]
"""
import io
import json
import math
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.request import urlopen

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
URL = "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"
LON0, LON1, LAT0, LAT1 = -76.9, -65.9, -17.3, -56.7  # caja de Chile continental
H, W = 1200, 560


def tile_xy(lon, lat, z):
    n = 2 ** z
    x = (lon + 180.0) / 360.0 * n
    y = (1.0 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2.0 * n
    return x, y


def bajar(args):
    z, x, y = args
    for _ in range(3):
        try:
            with urlopen(URL.format(z=z, x=x, y=y), timeout=40) as r:
                return (x, y), np.array(Image.open(io.BytesIO(r.read())).convert("RGB"), dtype=np.float64)
        except Exception:
            pass
    raise RuntimeError(f"No se pudo bajar la tesela {z}/{x}/{y}")


def main() -> int:
    z = int(sys.argv[1]) if len(sys.argv) > 1 else 7
    xa, ya = tile_xy(LON0, LAT0, z)
    xb, yb = tile_xy(LON1, LAT1, z)
    xs = range(int(xa), int(xb) + 1)
    ys = range(int(ya), int(yb) + 1)
    print(f"{len(xs) * len(ys)} teselas (z={z})")
    with ThreadPoolExecutor(12) as ex:
        res = dict(ex.map(bajar, [(z, x, y) for x in xs for y in ys]))
    mosaico = np.zeros((len(ys) * 256, len(xs) * 256))
    for (x, y), rgb in res.items():
        elev = rgb[..., 0] * 256.0 + rgb[..., 1] + rgb[..., 2] / 256.0 - 32768.0
        mosaico[(y - ys[0]) * 256:(y - ys[0] + 1) * 256, (x - xs[0]) * 256:(x - xs[0] + 1) * 256] = elev
    geo = json.loads((ROOT / "data/geo/regiones_mapa.json").read_text(encoding="utf-8"))
    pr, ancho_rel = geo["proy"], geo["ancho_rel"]
    # coordenadas de cada píxel de salida -> lon/lat -> píxel del mosaico
    u = (np.arange(W) + 0.5) / W * ancho_rel
    v = (np.arange(H) + 0.5) / H
    lon = (u[None, :] * pr["alto"] + pr["x0"]) / pr["coslat"] + 0.0 * v[:, None]
    lat = pr["y1"] - v[:, None] * pr["alto"] + 0.0 * u[None, :]
    n = 2 ** z
    tx = (lon + 180.0) / 360.0 * n
    ty = (1.0 - np.arcsinh(np.tan(np.radians(lat))) / math.pi) / 2.0 * n
    px = np.clip((tx - xs[0]) * 256.0, 0, mosaico.shape[1] - 1.001)
    py = np.clip((ty - ys[0]) * 256.0, 0, mosaico.shape[0] - 1.001)
    x0i, y0i = px.astype(int), py.astype(int)
    fx, fy = px - x0i, py - y0i
    el = (mosaico[y0i, x0i] * (1 - fx) * (1 - fy) + mosaico[y0i, x0i + 1] * fx * (1 - fy)
          + mosaico[y0i + 1, x0i] * (1 - fx) * fy + mosaico[y0i + 1, x0i + 1] * fx * fy)
    el = np.maximum(el, 0.0)
    # sombreado (luz desde el noroeste), con exageración vertical
    celda_m = (pr["alto"] * 111_320.0) / H
    exag = 5.0
    celda_x = (pr["alto"] * 111_320.0) * ancho_rel / W  # el plano ya incluye cos(lat): metros por píxel horizontal
    dy, dx = np.gradient(el * exag, celda_m, celda_x)
    pend = np.arctan(np.hypot(dx, dy))
    asp = np.arctan2(-dy, dx)
    az, alt = math.radians(315.0), math.radians(42.0)
    sombra = np.sin(alt) * np.cos(pend) + np.cos(alt) * np.sin(pend) * np.cos(az - asp)
    plano = math.sin(alt)
    delta = sombra - plano
    alfa_osc = np.clip(-delta * 1.9, 0, 0.62)
    alfa_luz = np.clip(delta * 1.4, 0, 0.38)
    nieve = np.clip((el - 3300.0) / 2600.0, 0, 0.5)
    rgba = np.zeros((H, W, 4))
    rgba[..., :3] = 0.0
    rgba[..., 3] = alfa_osc
    luz = alfa_luz > alfa_osc
    rgba[luz, :3] = 1.0
    rgba[luz, 3] = alfa_luz[luz]
    nv = (nieve > rgba[..., 3]) & (el > 3300)
    rgba[nv, :3] = 0.95
    rgba[nv, 3] = nieve[nv]
    rgba[el <= 1.0, 3] = 0.0
    img = Image.fromarray((rgba * 255).astype(np.uint8), "RGBA")
    destino = ROOT / "data/geo/relieve.png"
    img.save(destino, optimize=True)
    print(f"OK: {destino} ({destino.stat().st_size // 1024} KB, {W}x{H})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
