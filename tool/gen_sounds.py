"""Procedurally generates the 8-bit sound assets in assets/sounds (no numpy required)."""
import math
import os
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")


def note(freq, dur, wave_fn="square", vol=0.5, decay=6.0, duty=0.5):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        ph = (t * freq) % 1.0
        if wave_fn == "square":
            s = 1.0 if ph < duty else -1.0
        elif wave_fn == "tri":
            s = 4 * abs(ph - 0.5) - 1
        else:  # noise
            s = (hash((i * 7919) % 100003) % 2000) / 1000 - 1
        env = math.exp(-decay * t)
        out.append(s * env * vol)
    return out


def sweep(f0, f1, dur, vol=0.5, decay=8.0):
    n = int(SR * dur)
    out, ph = [], 0.0
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (i / n)
        ph = (ph + f / SR) % 1.0
        s = 1.0 if ph < 0.5 else -1.0
        out.append(s * math.exp(-decay * t) * vol)
    return out


def silence(dur):
    return [0.0] * int(SR * dur)


def mix(a, b, offset=0):
    n = max(len(a), offset + len(b))
    r = a + [0.0] * (n - len(a))
    for i, v in enumerate(b):
        r[offset + i] += v
    return r


def save(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = 0.9 / peak if peak > 0.9 else 1.0
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples))


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# --- SFX ---------------------------------------------------------------
save("place_x.wav", sweep(880, 440, 0.12, vol=0.6, decay=14))          # descending blip
save("place_o.wav", sweep(440, 880, 0.12, vol=0.6, decay=14))          # ascending blip

fanfare = []
for n, d in [(60, .12), (64, .12), (67, .12), (72, .3), (67, .12), (72, .45)]:
    fanfare += note(midi(n), d, vol=0.5, decay=4) 
fanfare = mix(fanfare, [x * 0.35 for x in note(midi(48), 1.2, "tri", decay=2)])
save("win.wav", fanfare)

draw = []
for n, d in [(60, .18), (59, .18), (58, .18), (57, .45)]:
    draw += note(midi(n), d, vol=0.5, decay=4, duty=0.25)
save("draw.wav", draw)

# --- BGM loop (8 bars, 140 bpm, A minor chiptune) -----------------------
beat = 60 / 140
lead_seq = [69, 72, 76, 72, 71, 74, 79, 74, 67, 71, 74, 71, 69, 72, 76, 79,
            69, 72, 76, 72, 71, 74, 79, 74, 65, 69, 72, 69, 67, 71, 74, 76]
bass_seq = [45, 45, 43, 43, 41, 41, 43, 43] * 2
lead, bass = [], []
for n in lead_seq:
    lead += note(midi(n), beat / 2, vol=0.35, decay=5, duty=0.25)
for n in bass_seq:
    bass += note(midi(n), beat, "tri", vol=0.5, decay=2)
bgm = mix(lead, bass)
hat = []
for i in range(len(bass_seq) * 2):
    hat += note(0, beat / 2, "noise", vol=0.12, decay=40)
save("bgm.wav", mix(bgm, hat))
print("done")
