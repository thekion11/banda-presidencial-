#!/usr/bin/env python3
"""Relieve de Gran Santiago: sombreado (PNG) y malla de elevaciones (binario) alineados con urbano_real.json.

Fuente: AWS Terrain Tiles (Terrarium; derivados de SRTM y otros modelos públicos).
Salidas: data/geo/relieve_santiago.png  (RGBA para superponer en los mapas 2D)
         data/geo/elevacion_santiago.bin (uint16 big-endian: ancho, alto, luego alto*ancho metros)
Uso    : python3 tools/geo/relieve_urbano.py
"""
import io
import json
import math
import struct
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.request import urlopen

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
URL = "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"
Z = 12
SALIDA_PX = (1024, 833)
GRILLA = (128, 104)


def tile_xy(lon, lat, z):
    n = 2 ** z
    return (lon + 180.0) / 360.0 * n, (1.0 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2.0 * n


def bajar(a):
    z, x, y = a
    for _ in range(3):
        try:
            with urlopen(URL.format(z=z, x=x, y=y), timeout=40) as r:
                return (x, y), np.array(Image.open(io.BytesIO(r.read())).convert("RGB"), dtype=np.float64)
        except Exception:
            pass
    raise RuntimeError(f"tesela {z}/{x}/{y}")


def main():
    lon0, lat0, lon1, lat1 = json.loads((ROOT / "data/geo/urbano_real.json").read_text())["bbox"]
    xa, ya = tile_xy(lon0, lat1, Z)
    xb, yb = tile_xy(lon1, lat0, Z)
    xs, ys = range(int(xa), int(xb) + 1), range(int(ya), int(yb) + 1)
    with ThreadPoolExecutor(8) as ex:
        res = dict(ex.map(bajar, [(Z, x, y) for x in xs for y in ys]))
    mos = np.zeros((len(ys) * 256, len(xs) * 256))
    for (x, y), rgb in res.items():
        mos[(y - ys[0]) * 256:(y - ys[0] + 1) * 256, (x - xs[0]) * 256:(x - xs[0] + 1) * 256] = rgb[..., 0] * 256 + rgb[..., 1] + rgb[..., 2] / 256 - 32768

    def muestrear(w, h):
        u = (np.arange(w) + 0.5) / w
        v = (np.arange(h) + 0.5) / h
        lon = lon0 + u[None, :] * (lon1 - lon0) + 0 * v[:, None]
        lat = lat1 - v[:, None] * (lat1 - lat0) + 0 * u[None, :]
        n = 2 ** Z
        tx = (lon + 180.0) / 360.0 * n
        ty = (1.0 - np.arcsinh(np.tan(np.radians(lat))) / math.pi) / 2.0 * n
        px = np.clip((tx - xs[0]) * 256.0, 0, mos.shape[1] - 1.001)
        py = np.clip((ty - ys[0]) * 256.0, 0, mos.shape[0] - 1.001)
        x0, y0 = px.astype(int), py.astype(int)
        fx, fy = px - x0, py - y0
        return (mos[y0, x0] * (1 - fx) * (1 - fy) + mos[y0, x0 + 1] * fx * (1 - fy) + mos[y0 + 1, x0] * (1 - fx) * fy + mos[y0 + 1, x0 + 1] * fx * fy)

    w, h = SALIDA_PX
    el = np.maximum(muestrear(w, h), 0.0)
    celda_x = (lon1 - lon0) * 111320.0 * math.cos(math.radians((lat0 + lat1) / 2)) / w
    celda_y = (lat1 - lat0) * 111200.0 / h
    dy, dx = np.gradient(el * 2.2, celda_y, celda_x)
    pend = np.arctan(np.hypot(dx, dy))
    asp = np.arctan2(-dy, dx)
    az, alt = math.radians(315), math.radians(42)
    delta = (np.sin(alt) * np.cos(pend) + np.cos(alt) * np.sin(pend) * np.cos(az - asp)) - math.sin(alt)
    rgba = np.zeros((h, w, 4))
    osc = np.clip(-delta * 2.0, 0, 0.55)
    luz = np.clip(delta * 1.6, 0, 0.45)
    rgba[..., 3] = osc
    m = luz > osc
    rgba[m, :3] = 1.0
    rgba[m, 3] = luz[m]
    Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").save(ROOT / "data/geo/relieve_santiago.png", optimize=True)
    gw, gh = GRILLA
    g = np.clip(np.round(muestrear(gw, gh)), 0, 65535).astype(">u2")
    (ROOT / "data/geo/elevacion_santiago.bin").write_bytes(struct.pack(">HH", gw, gh) + g.tobytes())
    print(f"OK: relieve {w}x{h}, rejilla {gw}x{gh}, elevación {el.min():.0f}-{el.max():.0f} m")


if __name__ == "__main__":
    main()
