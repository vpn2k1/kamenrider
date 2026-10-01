#!/usr/bin/env python3
"""
Vẽ tile 32×32 cho khối trong màn chơi → art/tiles/<tên>.png

    python3 tools/gen_tiles.py

    crate.png : thùng gỗ (khối để nhảy lên, bậc thang, chỗ nấp đạn)
    wall.png  : vách thép của giếng dọc
"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art", "tiles")
S = 32


def crate() -> Image.Image:
    im = Image.new("RGBA", (S, S))
    px = im.load()
    dark, mid, light, edge = (74, 44, 26, 255), (132, 84, 46, 255), (168, 112, 64, 255), (40, 24, 16, 255)
    for y in range(S):
        for x in range(S):
            c = mid
            if (y // 8) % 2 == 1:           # vân ván gỗ
                c = (122, 78, 42, 255)
            if y % 8 == 0:
                c = dark
            px[x, y] = c
    # khung và thanh chéo
    for i in range(S):
        for t in range(3):
            px[i, t] = light if t else edge
            px[i, S - 1 - t] = dark if t else edge
            px[t, i] = light if t else edge
            px[S - 1 - t, i] = dark if t else edge
    for i in range(3, S - 3):
        for w in (-1, 0, 1):
            j = i + w
            if 3 <= j < S - 3:
                px[i, j] = light if w < 1 else dark
    # đinh ở bốn góc
    for x, y in ((4, 4), (S - 5, 4), (4, S - 5), (S - 5, S - 5)):
        px[x, y] = (220, 200, 160, 255)
    return im


def wall() -> Image.Image:
    im = Image.new("RGBA", (S, S))
    px = im.load()
    base, hi, lo, rivet = (62, 66, 84, 255), (92, 98, 120, 255), (34, 36, 50, 255), (140, 146, 170, 255)
    for y in range(S):
        for x in range(S):
            c = base
            if (x + y * 3) % 11 == 0:        # nhiễu nhẹ
                c = (58, 62, 78, 255)
            px[x, y] = c
    for i in range(S):
        px[i, 0] = hi
        px[0, i] = hi
        px[i, S - 1] = lo
        px[S - 1, i] = lo
        px[i, 16] = lo                       # đường ghép tấm
        px[i, 17] = hi
    for x, y in ((4, 4), (S - 5, 4), (4, 12), (S - 5, 12), (4, 21), (S - 5, 21), (4, S - 5), (S - 5, S - 5)):
        px[x, y] = rivet
        px[x + 1, y + 1] = lo
    return im


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("crate", crate), ("wall", wall)):
        path = os.path.join(OUT, name + ".png")
        fn().save(path)
        print("ghi", path)
