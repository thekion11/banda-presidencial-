#!/usr/bin/env python3
"""Genera el icono del juego (banda presidencial tricolor con estrella dorada sobre océano) y la imagen de arranque.
Salidas: icon.svg, game/arte/marca/{icono_512,icono_fg_432,icono_bg_432,icono_192,splash}.png. Paleta de CLAUDE.md §5."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OCEANO, PANEL, ORO, ROJO, CREMA, AZUL = "#0B2236", "#16405F", "#F2C14E", "#C23B2E", "#FBF7EC", "#1E4F9C"
SS = 4


def fondo(n: int) -> Image.Image:
    im = Image.new("RGB", (n, n), OCEANO)
    px = im.load()
    for y in range(n):
        for x in range(n):
            t = (x + y) / (2 * n)
            c = [int(a + (b - a) * t) for a, b in zip((0x16, 0x40, 0x5F), (0x07, 0x18, 0x2A))]
            px[x, y] = tuple(c)
    return im


def estrella(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float, color: str) -> None:
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.40
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    d.polygon(pts, fill=color)


def banda(n: int, margen: float) -> Image.Image:
    """Banda diagonal tricolor (azul, crema, rojo) con medallón dorado; sobre fondo transparente."""
    N = n * SS
    capa = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)
    ancho = N * 0.50 * (1 - margen)
    cx, cy = N * 0.5, N * 0.5
    ux, uy = math.cos(math.radians(-35)), math.sin(math.radians(-35))  # dirección de la banda
    nx, ny = -uy, ux
    largo = N * 1.4
    for i, color in enumerate((AZUL, CREMA, ROJO)):
        off0, off1 = (i - 1.5) * ancho / 3, (i - 0.5) * ancho / 3
        poly = [(cx + ux * -largo + nx * off0, cy + uy * -largo + ny * off0), (cx + ux * largo + nx * off0, cy + uy * largo + ny * off0),
                (cx + ux * largo + nx * off1, cy + uy * largo + ny * off1), (cx + ux * -largo + nx * off1, cy + uy * -largo + ny * off1)]
        d.polygon(poly, fill=color)
    r = N * 0.19 * (1 - margen * 0.6)
    d.ellipse([cx - r * 1.12, cy - r * 1.12, cx + r * 1.12, cy + r * 1.12], fill=OCEANO)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PANEL, outline=ORO, width=max(2, int(N * 0.012)))
    estrella(d, cx, cy + r * 0.04, r * 0.72, ORO)
    return capa.resize((n, n), Image.LANCZOS)


def main() -> None:
    out = ROOT / "game" / "arte" / "marca"
    out.mkdir(parents=True, exist_ok=True)
    fg = banda(432, 0.34)  # zona segura de los iconos adaptativos (≈ 66 %)
    fg.save(out / "icono_fg_432.png")
    fondo(432).save(out / "icono_bg_432.png")
    icono = fondo(512).convert("RGBA")
    icono.alpha_composite(banda(512, 0.10))
    mascara = Image.new("L", (512 * SS, 512 * SS), 0)
    ImageDraw.Draw(mascara).rounded_rectangle([0, 0, 512 * SS, 512 * SS], radius=112 * SS, fill=255)
    icono.putalpha(mascara.resize((512, 512), Image.LANCZOS))
    icono.save(out / "icono_512.png")
    icono.resize((192, 192), Image.LANCZOS).save(out / "icono_192.png")
    s = Image.new("RGB", (1080, 1920), OCEANO)
    s.paste(fondo(1080).crop((0, 0, 1080, 1080)).resize((1080, 1920)), (0, 0))
    s.paste(icono.resize((420, 420), Image.LANCZOS), (330, 700), icono.resize((420, 420), Image.LANCZOS))
    s.save(out / "splash.png")
    (ROOT / "icon.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><rect width="128" height="128" rx="28" fill="#0B2236"/>'
        '<g transform="rotate(-35 64 64)"><rect x="-20" y="42" width="168" height="15" fill="#1E4F9C"/><rect x="-20" y="57" width="168" height="15" fill="#FBF7EC"/>'
        '<rect x="-20" y="72" width="168" height="15" fill="#C23B2E"/></g><circle cx="64" cy="64" r="22" fill="#16405F" stroke="#F2C14E" stroke-width="2"/>'
        '<path d="M64 47l5 11 12 1-9 8 3 12-11-6-11 6 3-12-9-8 12-1z" fill="#F2C14E"/></svg>\n', encoding="utf-8")


if __name__ == "__main__":
    main()
