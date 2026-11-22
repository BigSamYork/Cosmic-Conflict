"""Render the original mono canopy-parasite loop with NumPy."""

import wave
from pathlib import Path

import numpy as np


def render():
    rate = 22050
    duration = 5.6
    t = np.arange(round(rate * duration)) / rate
    rng = np.random.default_rng(3974)
    air = rng.normal(0, 1, t.size)
    sound = np.zeros_like(t)
    for start, length, pitch, formant in [
        (0.06, 1.26, 57, 540),
        (1.49, 0.49, 83, 780),
        (2.13, 1.83, 49, 395),
        (4.14, 0.52, 71, 660),
        (4.86, 0.62, 61, 510),
    ]:
        u = np.clip((t - start) / length, 0, 1)
        envelope = np.sin(np.pi * u) ** 0.75
        f0 = pitch * (
            0.7
            + 0.46 * np.sin(np.pi * u)
            + 0.043 * np.sin(2 * np.pi * (23 * t + u * u))
        )
        phase = 2 * np.pi * np.cumsum(f0) / rate
        voice = np.zeros_like(t)
        for n in range(1, 47):
            hz = n * f0
            throat = np.exp(
                -(((hz - (formant + 160 * np.sin(2 * np.pi * u))) / 141) ** 2)
            )
            rasp = np.exp(-(((hz - 1380 + 380 * u) / 215) ** 2))
            voice += np.sin(n * phase + 0.26 * np.sin(0.5 * phase)) * (
                0.4 / n + throat * 0.18 + rasp * 0.064
            )
        flutter = 0.70 + 0.30 * np.sin(phase * 0.52 + 0.63 * np.sin(phase * 0.25))
        sound += envelope * (np.tanh(voice) * flutter + 0.052 * air)
    for start in [0.22, 0.27, 1.30, 1.44, 2.09, 2.61, 3.87, 4.01, 4.76, 5.13]:
        elapsed = np.maximum(0, t - start)
        click = (t > start) * np.exp(-elapsed * 48) * np.minimum(elapsed * 750, 1)
        sound += (
            click
            * 0.30
            * np.sin(2 * np.pi * (112 * elapsed + 5 * (1 - np.exp(-elapsed * 75))))
        )
    pcm = np.round(0.84 * 32767 * sound / max(abs(sound))).astype("<i2")
    path = (
        Path(__file__).resolve().parents[1]
        / "current_dev/assets/sfx/canopy_parasite.wav"
    )
    path.parent.mkdir(exist_ok=True)
    with wave.open(str(path), "wb") as stream:
        stream.setparams((1, 2, rate, len(pcm), "NONE", "not compressed"))
        stream.writeframes(pcm.tobytes())


if __name__ == "__main__":
    render()
