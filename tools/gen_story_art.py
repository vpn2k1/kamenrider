#!/usr/bin/env python3
"""
Vẽ hình cho phần truyện (intro và khung hội thoại):

    python3 tools/gen_story_art.py

  art/ui/portraits/<id>.png   chân dung 28×28 trong khung thoại (game vẽ phóng 2 lần)
      - cắt phần đầu từ sprite PixelLab (art/pixellab/<tên>/south.png): hero, daguba...
      - Echo Rider (Godai, Takumi...) đổi màu tóc / áo từ đầu của nhân vật chính, Shotaro thêm mũ phớt
      - Void và Pen vẽ bằng hình khối (chưa có sprite PixelLab)
  art/story/earth.png         hành tinh 40×40 thang xám, game nhuộm màu theo từng Trái Đất
  art/story/void.png          dáng Chronos Void đứng, 40×64

Chân dung người nói của các thế giới vẽ theo trường "look" trong SPEAKERS của file thế giới
(scripts/data/worlds/*.gd):
  "hair=RRGGBB jacket=RRGGBB stripe=RRGGBB eyes=RRGGBB [hat] [glasses] [long]"
      người: đổi màu tóc / áo / viền áo / mắt từ đầu nhân vật chính; hat = mũ phớt, glasses = kính, long = tóc dài
  "base=kuuga|grongi|orphnoch|daguba|hero [tint=RRGGBB] [eternal]"
      quái / Rider: đầu sprite có sẵn, tint = nhuộm màu, eternal = giáp trắng mắt vàng (như Kamen Rider Eternal)

Không tốn lượt PixelLab: chỉ đọc các sprite đã tải về.
"""
import math
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PIXELLAB = os.path.join(ROOT, "art", "pixellab")
PORTRAITS = os.path.join(ROOT, "art", "ui", "portraits")
STORY = os.path.join(ROOT, "art", "story")
SIZE = 28
OUTLINE = (12, 8, 20, 255)

# Vùng cắt đầu (trái, trên, phải, dưới) trên ảnh south.png
CROPS = {
    "hero": ("hero", (20, 4, 48, 32)),
    "kuuga": ("kuuga_mighty_fixed", (20, 4, 48, 32)),
    "daguba": ("daguba", (32, 4, 60, 32)),
    "grongi": ("grongi_zu", (20, 6, 48, 34)),
    "orphnoch": ("orphnoch", (20, 4, 48, 32)),
}

# Màu gốc trên đầu nhân vật chính → đổi màu cho Echo Rider
HAIR = [(42, 41, 42)]
JACKET = [(25, 61, 113), (38, 44, 82)]
STRIPE = [(205, 169, 79), (242, 195, 46), (110, 93, 72)]
EYES = [(53, 121, 181)]

SWAPS = {
    # Godai: áo khoác đỏ gạch, tóc nâu sẫm, mắt nâu
    "godai": {"hair": (70, 45, 30), "jacket": (150, 55, 40), "stripe": (235, 225, 210), "eyes": (110, 70, 40)},
    # Ichijo: vest xám, sơ mi trắng, tóc đen
    "ichijo": {"hair": (22, 22, 28), "jacket": (70, 72, 82), "stripe": (230, 230, 235), "eyes": (40, 40, 50)},
    # Takumi: áo đen cổ bạc, tóc nâu
    "takumi": {"hair": (95, 62, 40), "jacket": (28, 28, 34), "stripe": (170, 170, 180), "eyes": (70, 50, 40)},
    # Shotaro: vest nâu đen, sơ mi kem (mũ phớt vẽ thêm)
    "shotaro": {"hair": (55, 38, 28), "jacket": (48, 40, 36), "stripe": (220, 205, 170), "eyes": (60, 45, 35)},
    # Philip: tóc nâu nhạt, áo sọc xanh lá
    "philip": {"hair": (150, 110, 70), "jacket": (60, 120, 70), "stripe": (230, 230, 200), "eyes": (70, 150, 90)},
}

# Trùm không có sprite riêng: đổi màu từ sprite có sẵn
RECOLORS = {
    # Dragon Orphnoch: Orphnoch xám → đỏ sẫm
    "dragon_orphnoch": ("orphnoch", lambda c, y: _tint(c, (200, 70, 60))),
    # Eternal: giáp trắng, mắt vàng, vạch xanh
    "eternal": ("kuuga", lambda c, y: _eternal(c, y)),
}


def _near(c, targets, tol=10):
    return any(sum(abs(a - b) for a, b in zip(c[:3], t)) <= tol for t in targets)


def _tint(c, color):
    lum = (0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]) / 255.0
    return tuple(int(min(255, color[i] * lum * 1.3)) for i in range(3)) + (c[3],)


def _eternal(c, y):
    r, g, b, a = c
    if y < 14 and r > 150 and g < 90 and b < 90:   # mắt đỏ (phần đầu) → vàng
        return (255, 220, 70, a)
    if r > 120 and g < 90 and b < 90:        # giáp đỏ → trắng
        v = min(255, 150 + r // 3)
        return (v, v, min(255, v + 10), a)
    if r > 150 and g > 100 and b < 90:       # sừng vàng → bạc xanh
        return (170, 200, 235, a)
    return c


def crop(name, box):
    im = Image.open(os.path.join(PIXELLAB, name, "south.png")).convert("RGBA")
    return im.crop(box)


def swap(im, spec):
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            c = px[x, y]
            if c[3] == 0:
                continue
            for key, targets in (("hair", HAIR), ("jacket", JACKET), ("stripe", STRIPE), ("eyes", EYES)):
                if _near(c, targets, 14):
                    px[x, y] = spec[key] + (255,)
                    break
    return out


def recolor(im, fn):
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if px[x, y][3] > 0:
                px[x, y] = fn(px[x, y], y)
    return out


def add_glasses(im):
    d = ImageDraw.Draw(im)
    frame = (20, 20, 26, 255)
    d.rectangle((10, 11, 13, 13), outline=frame)
    d.rectangle((15, 11, 18, 13), outline=frame)
    d.point([(14, 12)], fill=frame)
    return im


def add_long_hair(im, color):
    """Tóc dài phủ xuống hai bên vai."""
    d = ImageDraw.Draw(im)
    for x0 in (6, 19):
        d.rectangle((x0, 9, x0 + 2, 22), fill=color)
    return outline(im)


def from_look(look, heads):
    parts = look.split()
    opts = {}
    flags = set()
    for p in parts:
        if "=" in p:
            k, v = p.split("=", 1)
            opts[k] = v
        else:
            flags.add(p)
    hexc = lambda h: tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    if "base" in opts:
        base = opts["base"]
        im = heads[base].copy()
        if "eternal" in flags:
            im = recolor(im, lambda c, y: _eternal(c, y))
        if "tint" in opts:
            col = hexc(opts["tint"])
            im = recolor(im, lambda c, y: _tint(c, col))
        return im
    spec = {k: hexc(opts[k]) for k in ("hair", "jacket", "stripe", "eyes")}
    im = swap(heads["hero"], spec)
    if "long" in flags:
        im = add_long_hair(im, spec["hair"] + (255,))
    if "hat" in flags:
        im = add_hat(im)
    if "glasses" in flags:
        im = add_glasses(im)
    return im


def world_looks():
    import re
    out = {}
    wdir = os.path.join(ROOT, "scripts", "data", "worlds")
    for f in sorted(os.listdir(wdir)):
        if f.endswith(".gd"):
            text = open(os.path.join(wdir, f), encoding="utf-8").read()
            for pid, look in re.findall(r'"portrait":\s*"(\w+)",\s*"look":\s*"([^"]+)"', text):
                out[pid] = look
    return out


def add_hat(im):
    """Mũ phớt của Shotaro đội lên đầu."""
    d = ImageDraw.Draw(im)
    felt, band, hi = (40, 36, 40, 255), (150, 40, 40, 255), (75, 70, 78, 255)
    d.rectangle((10, 2, 18, 6), fill=felt)
    d.rectangle((11, 1, 17, 1), fill=felt)
    d.rectangle((7, 7, 21, 8), fill=felt)
    d.rectangle((10, 6, 18, 6), fill=band)
    d.point([(11, 3), (12, 2)], fill=hi)
    return outline(im)


def outline(im):
    """Thêm viền tối quanh các điểm ảnh (4 hướng)."""
    out = im.copy()
    src = im.load()
    dst = out.load()
    for y in range(im.height):
        for x in range(im.width):
            if src[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < im.width and 0 <= ny < im.height and src[nx, ny][3] > 0 and src[nx, ny] != OUTLINE:
                    dst[x, y] = OUTLINE
                    break
    return out


def draw_void_head():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cloak, hood, hood_hi, rim = (30, 22, 48, 255), (48, 32, 78, 255), (92, 60, 146, 255), (170, 90, 255, 255)
    # vai áo choàng
    d.polygon([(2, 27), (25, 27), (21, 19), (6, 19)], fill=cloak)
    d.line([(6, 19), (2, 27)], fill=rim)
    d.line([(21, 19), (25, 27)], fill=rim)
    # mũ trùm
    d.ellipse((6, 2, 21, 23), fill=hood)
    d.arc((6, 2, 21, 23), 150, 250, fill=hood_hi)
    d.arc((7, 3, 20, 22), 160, 230, fill=hood_hi)
    # khoảng tối trong mũ + mặt nạ
    d.ellipse((9, 7, 18, 21), fill=(8, 5, 14, 255))
    d.ellipse((10, 8, 17, 19), fill=(215, 215, 230, 255))
    d.rectangle((14, 13, 17, 19), fill=(160, 158, 185, 255))
    d.ellipse((10, 8, 17, 19), outline=(120, 118, 150, 255))
    # vết nứt
    d.point([(14, 8), (13, 9), (14, 10), (15, 11)], fill=(70, 40, 110, 255))
    # mắt tím phát sáng
    for x0 in (11, 15):
        d.rectangle((x0, 12, x0 + 1, 13), fill=(40, 12, 60, 255))
        d.point([(x0 + (1 if x0 == 11 else 0), 12)], fill=(220, 110, 255, 255))
    d.point([(12, 12), (15, 12)], fill=(255, 220, 255, 255))
    # đồng hồ trên ngực
    d.ellipse((11, 21, 16, 26), fill=(40, 30, 60, 255), outline=(225, 185, 80, 255))
    d.point([(13, 22), (13, 23), (14, 23), (15, 23)], fill=(225, 185, 80, 255))
    return outline(im)


def draw_pen():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    teal, teal_dk, paper, paper_sh = (40, 190, 185, 255), (20, 110, 120, 255), (248, 242, 218, 255), (215, 205, 175, 255)
    # vé tàu hơi nghiêng: vẽ thẳng rồi xoay
    card = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    c = ImageDraw.Draw(card)
    c.rectangle((5, 6, 22, 22), fill=paper)
    c.rectangle((5, 18, 22, 22), fill=paper_sh)
    c.rectangle((5, 6, 22, 9), fill=teal)
    c.line([(7, 8), (12, 8)], fill=(210, 255, 250, 255))
    c.point([(18, 7), (20, 7)], fill=(255, 230, 120, 255))
    # khấc hai bên
    for x in (5, 22):
        c.rectangle((x, 13, x, 15), fill=(0, 0, 0, 0))
    # mặt
    for x in (10, 16):
        c.rectangle((x, 12, x + 1, 14), fill=(25, 25, 40, 255))
        c.point([(x, 12)], fill=(255, 255, 255, 255))
    c.line([(12, 17), (15, 17)], fill=(200, 80, 90, 255))
    c.point([(11, 16), (16, 16)], fill=(200, 80, 90, 255))
    c.point([(8, 15), (19, 15)], fill=(245, 170, 170, 255))
    c.rectangle((5, 6, 22, 22), outline=teal_dk)
    for x in (5, 22):
        c.rectangle((x, 13, x, 15), fill=(0, 0, 0, 0))
    card = card.rotate(-8, resample=Image.NEAREST, center=(14, 14))
    # quầng sáng
    glow = (120, 255, 240, 110)
    for (x, y) in ((3, 3), (24, 4), (25, 23), (2, 22)):
        d.point([(x, y), (x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)], fill=glow)
        d.point([(x, y)], fill=(255, 255, 220, 255))
    im.alpha_composite(card)
    return outline(im)


def draw_earth():
    """Hành tinh thang xám: biển tối, lục địa sáng, đổ bóng từ trên trái. Game nhuộm màu bằng modulate."""
    n = 40
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = im.load()
    rnd = random.Random(7)
    blobs = [(rnd.uniform(-0.8, 0.8), rnd.uniform(-0.8, 0.8), rnd.uniform(0.18, 0.4)) for _ in range(9)]
    r = n / 2 - 1
    for y in range(n):
        for x in range(n):
            dx, dy = (x + 0.5 - n / 2) / r, (y + 0.5 - n / 2) / r
            d2 = dx * dx + dy * dy
            if d2 > 1.0:
                continue
            land = any((dx - bx) ** 2 + (dy - by) ** 2 < br * br for bx, by, br in blobs)
            z = math.sqrt(1.0 - d2)
            light = max(0.0, (-dx * 0.55 - dy * 0.45 + z * 0.7))
            base = 0.72 if land else 0.42
            v = base * (0.35 + 0.75 * light)
            # dải băng ở cực
            if abs(dy) > 0.82:
                v = 0.9 * (0.4 + 0.6 * light)
            v = round(v * 6) / 6      # giảm số tông cho ra chất pixel
            g = int(min(255, v * 255))
            px[x, y] = (g, g, g, 255)
    # viền sáng mép khí quyển
    d = ImageDraw.Draw(im)
    d.arc((0, 0, n - 1, n - 1), 160, 290, fill=(235, 235, 235, 255))
    return im


def draw_void_body():
    w, h = 40, 64
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cloak, cloak_hi, rim = (30, 22, 48, 255), (62, 42, 98, 255), (170, 90, 255, 255)
    # áo choàng xòe
    d.polygon([(20, 8), (33, 22), (37, 62), (3, 62), (7, 22)], fill=cloak)
    d.polygon([(20, 10), (10, 24), (8, 62), (14, 62), (16, 26)], fill=cloak_hi)
    d.line([(33, 22), (37, 62)], fill=rim)
    d.line([(7, 22), (3, 62)], fill=rim)
    d.line([(3, 62), (37, 62)], fill=rim)
    # mũ trùm và mặt nạ
    d.ellipse((12, 2, 28, 20), fill=(48, 32, 78, 255))
    d.ellipse((15, 6, 25, 19), fill=(8, 5, 14, 255))
    d.ellipse((16, 7, 24, 18), fill=(215, 215, 230, 255))
    d.rectangle((20, 12, 24, 18), fill=(160, 158, 185, 255))
    d.rectangle((17, 11, 18, 12), fill=(40, 12, 60, 255))
    d.rectangle((22, 11, 23, 12), fill=(40, 12, 60, 255))
    d.point([(18, 11), (22, 11)], fill=(235, 150, 255, 255))
    d.point([(20, 7), (19, 8), (20, 9)], fill=(70, 40, 110, 255))
    # đồng hồ và xích tinh thể
    d.ellipse((16, 26, 24, 34), fill=(40, 30, 60, 255), outline=(225, 185, 80, 255))
    d.line([(20, 30), (20, 27)], fill=(225, 185, 80, 255))
    d.line([(20, 30), (23, 30)], fill=(225, 185, 80, 255))
    for i in range(5):
        y = 38 + i * 5
        d.polygon([(26 + i % 2, y), (28 + i % 2, y + 2), (26 + i % 2, y + 4), (24 + i % 2, y + 2)], fill=(190, 110, 255, 255))
    return outline(im)


def main():
    os.makedirs(PORTRAITS, exist_ok=True)
    os.makedirs(STORY, exist_ok=True)
    heads = {}
    for pid, (name, box) in CROPS.items():
        heads[pid] = crop(name, box)
        heads[pid].save(os.path.join(PORTRAITS, pid + ".png"))
    looks = world_looks()
    for pid, look in looks.items():
        from_look(look, heads).save(os.path.join(PORTRAITS, pid + ".png"))
    draw_void_head().save(os.path.join(PORTRAITS, "void.png"))
    draw_pen().save(os.path.join(PORTRAITS, "pen.png"))
    draw_earth().save(os.path.join(STORY, "earth.png"))
    draw_void_body().save(os.path.join(STORY, "void.png"))
    print("Đã ghi %d chân dung vào %s và hình truyện vào %s" % (
        len(os.listdir(PORTRAITS)), os.path.relpath(PORTRAITS, ROOT), os.path.relpath(STORY, ROOT)))


if __name__ == "__main__":
    main()
