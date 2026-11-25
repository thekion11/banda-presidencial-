#!/usr/bin/env python3
"""Genera los efectos de sonido de game/audio/*.wav (síntesis propia: senoidales con envolvente y ruido filtrado; sin muestras de terceros).
Uso: python3 tools/audio/generar_sonidos.py"""
import math
import random
import struct
import wave
from pathlib import Path

SR = 22050
SALIDA = Path(__file__).resolve().parents[2] / "game" / "audio"


def tono(f, dur, vol=0.4, decay=6.0, arm=None):
    out = []
    for i in range(int(SR * dur)):
        t = i / SR
        env = math.exp(-decay * t) * min(1.0, i / (SR * 0.004))
        v = math.sin(2 * math.pi * f * t) + (0.4 * math.sin(2 * math.pi * f * arm * t) if arm else 0.0)
        out.append(vol * env * v)
    return out


def mezcla(*seqs):
    r = [0.0] * max(len(s) for s in seqs)
    for s in seqs:
        for i, x in enumerate(s):
            r[i] += x
    return r


def secuencia(partes):
    out = []
    for s, pausa in partes:
        out += s + [0.0] * int(SR * pausa)
    return out


def ruido(dur, vol=0.3, decay=20.0, lp=0.3):
    random.seed(7)
    y, out = 0.0, []
    for i in range(int(SR * dur)):
        y += (random.uniform(-1, 1) - y) * lp
        out.append(vol * y * math.exp(-decay * i / SR))
    return out


def guardar(nombre, datos):
    m = max(0.001, max(abs(x) for x in datos))
    with wave.open(str(SALIDA / f"{nombre}.wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x / m * 0.8)) * 32000)) for x in datos))


def main() -> None:
    SALIDA.mkdir(parents=True, exist_ok=True)
    guardar("toque", tono(660, 0.07, decay=40))
    guardar("jugar", mezcla(ruido(0.22, 0.5, decay=14, lp=0.15), tono(220, 0.22, 0.25, decay=12, arm=2)))
    guardar("exito", secuencia([(tono(523, 0.12, decay=10), 0.0), (tono(659, 0.12, decay=10), 0.0), (tono(784, 0.3, decay=7), 0.0)]))
    guardar("alerta", secuencia([(tono(330, 0.14, 0.5, decay=9), 0.02), (tono(247, 0.28, 0.5, decay=6), 0.0)]))
    guardar("evento", mezcla(tono(880, 0.5, 0.4, decay=5, arm=2.0), tono(1320, 0.5, 0.15, decay=6)))
    guardar("decision", secuencia([(tono(440, 0.09, decay=14), 0.0), (tono(587, 0.14, decay=10), 0.0)]))
    guardar("turno", secuencia([(tono(392, 0.1, decay=9), 0.0), (tono(494, 0.1, decay=9), 0.0), (tono(392, 0.2, decay=6), 0.0)]))
    guardar("error", tono(180, 0.18, 0.5, decay=14, arm=1.5))


if __name__ == "__main__":
    main()
