#!/usr/bin/env python3
"""Generates the pixel-art launcher icon for every platform from a 24x24 design.

Usage: python3 tool/gen_icon.py   (run from the repo root)
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
N = 24

BG = (0x1A, 0x10, 0x33)
PANEL = (0x2E, 0x21, 0x57)
BORDER_LIGHT = (0x4A, 0x3A, 0x85)
BORDER_DARK = (0x12, 0x0B, 0x26)
GRID = (0x6C, 0x5C, 0xB0)
X1, X2 = (0xFF, 0x5D, 0x73), (0xA8, 0x20, 0x3A)
O1, O2 = (0x4F, 0xE3, 0xC1), (0x1B, 0x8C, 0x79)
GOLD, GOLD2 = (0xFF, 0xD4, 0x47), (0xC9, 0x8A, 0x12)

X_SPRITE = [
    "1..1",
    ".11.",
    ".22.",
    "2..2",
]
O_SPRITE = [
    ".11.",
    "1..2",
    "1..2",
    ".22.",
]


def draw(transparent: bool) -> Image.Image:
    img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    px = img.load()

    def put(x, y, c):
        if 0 <= x < N and 0 <= y < N:
            px[x, y] = c + (255,)

    if not transparent:
        for y in range(N):
            for x in range(N):
                corner = (x in (0, N - 1)) and (y in (0, N - 1))
                if corner:
                    continue
                edge = x in (0, N - 1) or y in (0, N - 1)
                if edge:
                    put(x, y, BORDER_DARK if (y == N - 1 or x == N - 1) else BORDER_LIGHT)
                else:
                    put(x, y, PANEL)
        # bevel: dark bottom/right inner line
        for i in range(1, N - 1):
            put(i, N - 2, BORDER_DARK)
            put(N - 2, i, BORDER_DARK)
            put(i, 1, BORDER_LIGHT)
            put(1, i, BORDER_LIGHT)

    # 3x3 board: cells 6px, grid lines 1px, board 20px, offset 2.
    off = 2
    cell = 6
    for k in (1, 2):
        pos = off + k * cell + (k - 1)
        for i in range(off, off + 20):
            put(pos, i, GRID)
            put(i, pos, GRID)

    def sprite(sp, cx, cy, c1, c2):
        ox = off + cx * (cell + 1) + 1
        oy = off + cy * (cell + 1) + 1
        for y, row in enumerate(sp):
            for x, ch in enumerate(row):
                if ch == '1':
                    put(ox + x, oy + y, c1)
                elif ch == '2':
                    put(ox + x, oy + y, c2)

    # Gold winning diagonal drawn under the three X's (1px, with shade below).
    for i in range(off, off + 20):
        put(i, i, GOLD)
        put(i, i + 1, GOLD2)

    sprite(X_SPRITE, 0, 0, X1, X2)
    sprite(X_SPRITE, 1, 1, X1, X2)
    sprite(X_SPRITE, 2, 2, X1, X2)
    sprite(O_SPRITE, 2, 0, O1, O2)
    sprite(O_SPRITE, 0, 2, O1, O2)
    sprite(O_SPRITE, 1, 2, O1, O2)
    return img


def scaled(img: Image.Image, size: int, pad: float = 0.0) -> Image.Image:
    inner = int(round(size * (1 - 2 * pad)))
    inner -= inner % N
    art = img.resize((inner, inner), Image.NEAREST)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    o = (size - inner) // 2
    out.paste(art, (o, o), art)
    return out


def flat(size: int, pad: float = 0.0) -> Image.Image:
    out = Image.new('RGBA', (size, size), BG + (255,))
    art = scaled(draw(False), size, pad)
    out.paste(art, (0, 0), art)
    return out


def main() -> None:
    res = ROOT / 'android/app/src/main/res'
    for dpi, size in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96,
                      'xxhdpi': 144, 'xxxhdpi': 192}.items():
        d = res / f'mipmap-{dpi}'
        d.mkdir(exist_ok=True)
        flat(size).save(d / 'ic_launcher.png')
        # Adaptive foreground: 108dp canvas, 66dp safe zone -> ~20% padding.
        fg = size * 108 // 48
        scaled(draw(True), fg, pad=0.2).save(d / 'ic_launcher_foreground.png')

    web = ROOT / 'web'
    flat(48).save(web / 'favicon.png')
    for s in (192, 512):
        flat(s).save(web / 'icons' / f'Icon-{s}.png')
        flat(s, pad=0.1).save(web / 'icons' / f'Icon-maskable-{s}.png')

    flat(240).save(ROOT / 'docs/media/icon.png')


if __name__ == '__main__':
    main()
