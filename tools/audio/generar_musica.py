#!/usr/bin/env python3
"""Genera la música ambiente de game/audio/musica_*.ogg (síntesis propia, sin muestras de terceros).

Cuatro bucles sin costura (8 compases cada uno): campaña (mayor, esperanzada), gobierno (solemne),
oposición (dórica, inquieta) y tensión (votaciones: pulso grave y reloj). Requiere numpy y ffmpeg con libvorbis.
Uso: python3 tools/audio/generar_musica.py
"""
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

SR = 22050
SALIDA = Path(__file__).resolve().parents[2] / "game" / "audio"
LA4 = 440.0


def nota(n):
    """Frecuencia de una nota MIDI."""
    return LA4 * 2 ** ((n - 69) / 12)


def paso_bajo(x, corte):
    """Filtro de un polo (suaviza las ondas ricas en armónicos)."""
    a = np.exp(-2 * np.pi * corte / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def colchon(freqs, dur, vol, corte=1400.0, ataque=0.8, caida=1.2):
    """Acorde sostenido: sierras levemente desafinadas y filtradas, con envolvente lenta."""
    t = np.arange(int(SR * (dur + caida))) / SR
    x = np.zeros_like(t)
    for f in freqs:
        for d in (-0.12, 0.0, 0.12):
            fase = 2 * np.pi * f * (1 + d / 100.0) * t
            x += 0.6 * np.sin(fase) + 0.25 * np.sin(2 * fase) + 0.12 * np.sin(3 * fase)
    env = np.minimum(1.0, t / ataque) * np.where(t < dur, 1.0, np.exp(-(t - dur) / (caida / 3)))
    return paso_bajo(x * env, corte) * vol / (len(freqs) * 3)


def pulsado(f, vol, dur=0.9, brillo=2.0):
    """Nota punteada (arpa / celesta): senoidal con armónico y caída exponencial."""
    t = np.arange(int(SR * dur)) / SR
    env = np.exp(-t * 4.5) * np.minimum(1.0, t / 0.004)
    return vol * env * (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * brillo * t))


def golpe(vol, f0=70.0, dur=0.5):
    """Timbal o bombo suave: senoidal que baja de tono."""
    t = np.arange(int(SR * dur)) / SR
    f = f0 * (1 + 1.5 * np.exp(-t * 18))
    return vol * np.exp(-t * 7) * np.sin(2 * np.pi * np.cumsum(f) / SR)


def tic(vol):
    t = np.arange(int(SR * 0.05)) / SR
    rng = np.random.default_rng(3)
    return vol * np.exp(-t * 120) * (np.sin(2 * np.pi * 2600 * t) + 0.3 * rng.standard_normal(len(t)))


def pista(bpm, compases, acordes, arpegio, paso_arp, vol_arp, golpes, extra=None):
    """Arma un bucle: un acorde por compás, arpegio regular y golpes en los tiempos indicados."""
    negra = 60.0 / bpm
    compas = 4 * negra
    largo = int(SR * compas * compases)
    cola = int(SR * 3.0)
    buf = np.zeros(largo + cola)

    def poner(x, seg):
        i = int(seg * SR)
        fin = min(len(buf), i + len(x))
        buf[i:fin] += x[: fin - i]

    for c in range(compases):
        ac = acordes[c % len(acordes)]
        poner(colchon([nota(n) for n in ac], compas * 0.98, 0.55), c * compas)
        poner(colchon([nota(ac[0] - 12)], compas * 0.98, 0.35, corte=500.0), c * compas)  # bajo
        pasos = int(round(compas / paso_arp))
        for k in range(pasos):
            n = ac[arpegio[k % len(arpegio)] % len(ac)] + 12 * (arpegio[k % len(arpegio)] // len(ac))
            poner(pulsado(nota(n + 12), vol_arp * (1.0 if k % 2 == 0 else 0.7)), c * compas + k * paso_arp)
        for g in golpes:
            poner(golpe(0.22), c * compas + g * negra)
        if extra:
            extra(poner, c, compas, negra)
    buf[:cola] += buf[largo:largo + cola]  # la cola del final suena al principio: bucle sin costura
    buf = buf[:largo]
    return buf / (np.max(np.abs(buf)) + 1e-9) * 0.55


def guardar(nombre, x):
    with tempfile.TemporaryDirectory() as d:
        wav = Path(d) / (nombre + ".wav")
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())
        ogg = SALIDA / (nombre + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "3", str(ogg)], check=True)
        print(ogg, ogg.stat().st_size // 1024, "KB")


def main():
    # Campaña: re mayor, I - V - vi - IV, arpegio en corcheas (esperanza, movimiento).
    guardar("musica_campana", pista(88, 8, [[62, 66, 69], [57, 61, 64], [59, 62, 66], [55, 59, 62]],
                                    [0, 1, 2, 3, 2, 1], 60 / 88 / 2, 0.16, [0, 2]))
    # Gobierno: fa mayor con suspensiones, arpegio en negras y timbal en el primer tiempo (solemne).
    guardar("musica_gobierno", pista(72, 8, [[65, 69, 72], [65, 70, 72], [62, 65, 69], [60, 65, 67]],
                                     [0, 2, 1, 3], 60 / 72, 0.14, [0]))
    # Oposición: re dórico, Dm - C - Bb - C, ostinato en semicorcheas suaves (inquietud).
    guardar("musica_oposicion", pista(96, 8, [[62, 65, 69], [60, 64, 67], [58, 62, 65], [60, 64, 67]],
                                      [0, 2, 0, 1, 0, 2, 3, 2], 60 / 96 / 4, 0.09, [0, 1.5, 2]))

    # Tensión: pedal grave con segunda menor, pulso en cada tiempo y reloj (votaciones).
    def reloj(poner, c, compas, negra):
        for k in range(4):
            poner(tic(0.12), c * compas + k * negra)
            poner(tic(0.06), c * compas + k * negra + negra / 2)
    guardar("musica_tension", pista(100, 8, [[50, 51, 57], [50, 51, 57], [50, 53, 58], [49, 52, 57]],
                                    [0, 1], 60 / 100, 0.05, [0, 1, 2, 3], reloj))


if __name__ == "__main__":
    main()
