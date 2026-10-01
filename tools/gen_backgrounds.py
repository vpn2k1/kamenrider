#!/usr/bin/env python3
"""
Vẽ nền xa (lớp parallax) cho từng màn → art/backgrounds/<tên>.png, 800×224, nối liền hai mép trái/phải
(game lặp ảnh theo chiều ngang).

    python3 tools/gen_backgrounds.py            # vẽ tất cả
    python3 tools/gen_backgrounds.py harbor lab # chỉ vẽ vài nền

Màn nào dùng nền nào: khóa "bg" của từng màn trong scripts/data/world_data.gd.
Màn 1-1 dùng ảnh có sẵn art/backgrounds/shibuya_night.png.

Quy ước để khớp với game:
  - Hàng trên cùng (y = 0) là màu trời thuần: game lấy màu điểm (0, 0) tô phần trời ngoài ảnh.
  - Chân các công trình ở khoảng y 190–200; phần dưới bị mặt đất trong màn che gần hết.
  - Không vẽ chữ (ảnh có thể bị lật khi dùng ảnh hẹp 400 px).
Không tốn lượt PixelLab: toàn bộ vẽ bằng hình khối, mỗi nền một hạt giống cố định nên vẽ lại vẫn y hệt.
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art", "backgrounds")
W, H = 800, 224
M = 220                 # lề vẽ tràn hai bên, gập lại khi xong để ảnh nối liền
BASE = 196              # chân công trình
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3)) + (255,)


def dark(c, f):
    return mix(c, (0, 0, 0, 255), f)


def light(c, f):
    return mix(c, (255, 255, 255, 255), f)


# --- Nền trời -----------------------------------------------------------------

def gradient(im, y0, y1, colors):
    """Dải màu dọc chia bậc, chuyển bậc bằng chấm Bayer (chất pixel). Hàng y0 là màu đầu thuần."""
    px = im.load()
    n = len(colors) - 1
    for y in range(y0, y1):
        t = (y - y0) / max(1, (y1 - y0 - 1)) * n
        i = min(int(t), n - 1)
        f = t - i
        for x in range(W):
            th = (BAYER[y % 4][x % 4] + 0.5) / 16.0
            px[x, y] = colors[i + 1] if f > th else colors[i]


def stars(im, rng, count, y1, colors=((235, 235, 255), (180, 190, 255), (255, 230, 200))):
    px = im.load()
    for _ in range(count):
        x, y = rng.randrange(W), rng.randrange(4, y1)
        c = rng.choice(colors) + (255,)
        px[x, y] = c
        if rng.random() < 0.08 and 5 <= y < y1 - 1:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                px[(x + dx) % W, y + dy] = mix(c, px[(x + dx) % W, y + dy], 0.5)


def moon(im, x, y, r, color, shadow=None):
    d = ImageDraw.Draw(im)
    for k in range(3, 0, -1):
        d.ellipse((x - r - k * 4, y - r - k * 4, x + r + k * 4, y + r + k * 4),
                  fill=mix(im.getpixel((x, max(4, y - r - 14))), color, 0.07 * (4 - k)))
    d.ellipse((x - r, y - r, x + r, y + r), fill=color)
    d.ellipse((x - r // 2, y - r // 3, x - r // 2 + r // 3, y - r // 3 + r // 3), fill=dark(color, 0.12))
    d.ellipse((x + r // 5, y + r // 4, x + r // 5 + r // 4, y + r // 4 + r // 4), fill=dark(color, 0.12))
    if shadow:
        d.ellipse((x - r + r // 2, y - r - 2, x + r + r // 2, y + r - 2), fill=shadow)


# --- Lớp vẽ tràn mép, gập lại cho ảnh nối liền ---------------------------------------

class Layer:
    def __init__(self):
        self.im = Image.new("RGBA", (W + 2 * M, H), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def rect(self, x0, y0, x1, y1, c):
        if x1 >= x0 and y1 >= y0:
            self.d.rectangle((x0 + M, y0, x1 + M, y1), fill=c)

    def line(self, pts, c, w=1):
        self.d.line([(x + M, y) for x, y in pts], fill=c, width=w)

    def poly(self, pts, c):
        self.d.polygon([(x + M, y) for x, y in pts], fill=c)

    def ellipse(self, x0, y0, x1, y1, c):
        self.d.ellipse((x0 + M, y0, x1 + M, y1), fill=c)

    def px(self, x, y, c):
        if 0 <= y < H and -M <= x < W + M:
            self.im.putpixel((int(x) + M, int(y)), c)

    def fold(self):
        out = self.im.crop((M, 0, M + W, H))
        out.alpha_composite(self.im.crop((M + W, 0, M + W + M, H)), (0, 0))
        out.alpha_composite(self.im.crop((0, 0, M, H)), (W - M, 0))
        return out


def put(im, layer):
    im.alpha_composite(layer.fold())


def periodic(x, rng_seed, ks=(1, 2, 3, 5, 8, 13)):
    """Hàm nhấp nhô tuần hoàn theo W (nối liền mép), giá trị khoảng -1..1."""
    r = random.Random(rng_seed)
    total, norm = 0.0, 0.0
    for k in ks:
        a = 1.0 / k ** 0.8
        total += a * math.sin(2 * math.pi * k * x / W + r.uniform(0, math.tau))
        norm += a
    return total / norm


def mountains(im, seed, base, amp, color, ridge=None, ks=(1, 2, 3, 5, 8, 13)):
    px = im.load()
    for x in range(W):
        top = int(base - amp * (0.5 + 0.5 * periodic(x, seed, ks)))
        for y in range(max(0, top), H):
            px[x, y] = color
        if ridge and 0 <= top < H:
            px[x, top] = ridge


def fog(im, y0, y1, color, strength):
    """Sương dạng chấm Bayer phủ mờ dần lên phía trên."""
    px = im.load()
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0) * strength
        for x in range(W):
            if t > (BAYER[y % 4][x % 4] + 0.5) / 16.0:
                px[x, y] = mix(px[x, y], color, 0.5)


# --- Công trình ----------------------------------------------------------------

def skyline(layer, rng, base, hmin, hmax, wmin, wmax, body, win_on, win_off=None, lit=0.35, gap=(0, 3),
            antenna=0.25, edge=None, win=(2, 2, 4, 5), roofs=True):
    """Dãy nhà hộp: cửa sổ lưới (sáng/tối ngẫu nhiên), cạnh sáng bên trái, ăng-ten và bồn nước trên mái."""
    win_off = win_off or dark(body, 0.25)
    edge = edge or light(body, 0.12)
    ww, wh, sx, sy = win
    x = 0
    while x < W:
        w = rng.randrange(wmin, wmax)
        h = rng.randrange(hmin, hmax)
        top = base - h
        layer.rect(x, top, x + w - 1, H - 1, body)
        layer.rect(x, top, x, H - 1, edge)
        if roofs and rng.random() < 0.35:
            step = rng.randrange(3, 7)
            layer.rect(x + 2, top - step, x + w - 3, top - 1, body)
            layer.rect(x + 2, top - step, x + 2, top - 1, edge)
        cols = max(1, (w - 4) // sx)
        off = (w - cols * sx) // 2 + 1
        row_lit = rng.random()
        for yy in range(top + 4, base - 3, sy):
            for c in range(cols):
                xx = x + off + c * sx
                on = rng.random() < lit * (1.4 if row_lit < 0.3 else 1.0)
                layer.rect(xx, yy, xx + ww - 1, yy + wh - 1, win_on if on else win_off)
        if rng.random() < antenna:
            ax = x + rng.randrange(2, max(3, w - 2))
            ah = rng.randrange(5, 14)
            layer.rect(ax, top - ah, ax, top - 1, dark(body, 0.2))
            layer.px(ax, top - ah - 1, (255, 70, 70, 255))
        elif roofs and rng.random() < 0.2 and w > 14:
            tx = x + rng.randrange(2, w - 10)
            layer.rect(tx, top - 6, tx + 7, top - 2, dark(body, 0.15))
            layer.rect(tx + 1, top - 2, tx + 1, top - 1, dark(body, 0.3))
            layer.rect(tx + 6, top - 2, tx + 6, top - 1, dark(body, 0.3))
        x += w + rng.randrange(gap[0], gap[1] + 1)


def jagged_ruins(layer, rng, base, hmin, hmax, body, glow=None):
    """Nhà đổ nát: mái răng cưa, lỗ thủng, cửa sổ đỏ lửa."""
    x = 0
    while x < W:
        w = rng.randrange(18, 46)
        h = rng.randrange(hmin, hmax)
        top = base - h
        pts = [(x, H), (x, top + rng.randrange(0, 10))]
        cx = x
        while cx < x + w:
            cx = min(x + w, cx + rng.randrange(3, 8))
            pts.append((cx, top + rng.randrange(0, 14)))
        pts.append((x + w, H))
        layer.poly(pts, body)
        if glow:
            for _ in range(rng.randrange(1, 5)):
                gx, gy = x + rng.randrange(2, max(3, w - 4)), top + rng.randrange(16, max(17, h - 6))
                layer.rect(gx, gy, gx + 2, gy + 2, glow)
        x += w + rng.randrange(0, 6)


def tokyo_tower(layer, x, base, h, red, white, light_c):
    """Tháp kiểu Tokyo Tower: khung lưới thu nhỏ dần, sọc đỏ trắng, hai đài quan sát."""
    for y in range(base - h, base):
        t = (base - y) / h
        half = int(2 + 26 * (1 - t) ** 2.2)
        band = int(t * 10) % 2
        c = red if band == 0 else white
        layer.px(x - half, y, c)
        layer.px(x + half, y, c)
        if y % 6 == 0:
            layer.rect(x - half, y, x + half, y, dark(c, 0.3))
        if (y // 3) % 2 == 0 and half > 3:
            k = (y % 6) / 6.0
            layer.px(int(x - half + k * half), y, dark(c, 0.2))
            layer.px(int(x + half - k * half), y, dark(c, 0.2))
    for frac, w in ((0.36, 12), (0.62, 6)):
        dy = base - int(h * frac)
        layer.rect(x - w, dy - 4, x + w, dy, white)
        layer.rect(x - w, dy - 4, x + w, dy - 4, light_c)
        for k in range(-w + 2, w - 1, 3):
            layer.px(x + k, dy - 2, light_c)
    layer.rect(x, base - h - 10, x, base - h, white)
    layer.px(x, base - h - 11, (255, 80, 80, 255))


def crane(layer, x, base, h, boom, body, accent):
    """Cần cẩu cảng: tháp khung, cần ngang vươn ra biển, dây cáp."""
    top = base - h
    layer.rect(x - 8, top, x - 6, base, body)
    layer.rect(x + 6, top, x + 8, base, body)
    for y in range(top, base, 8):
        layer.line([(x - 7, y), (x + 7, y + 8)], body)
        layer.line([(x + 7, y), (x - 7, y + 8)], body)
    layer.rect(x - 14, top - 6, x + boom, top - 3, body)
    layer.rect(x - 14, top - 6, x + boom, top - 6, accent)
    layer.rect(x - 6, top - 16, x + 6, top - 7, body)
    layer.line([(x, top - 16), (x + boom, top - 6)], body)
    layer.line([(x, top - 16), (x - 14, top - 6)], body)
    hx = x + boom - 20
    layer.rect(hx, top - 3, hx, top + 30, dark(body, 0.2))
    layer.rect(hx - 3, top + 30, hx + 3, top + 33, accent)
    layer.px(x, top - 17, (255, 80, 80, 255))


def containers(layer, rng, x, base, cols, rows, palette):
    for r in range(rows):
        for c in range(cols):
            if r > 0 and rng.random() < 0.25:
                continue
            col = rng.choice(palette)
            x0, y0 = x + c * 26 + (r % 2) * 6, base - (r + 1) * 11
            layer.rect(x0, y0, x0 + 24, y0 + 10, col)
            for k in range(x0 + 2, x0 + 24, 3):
                layer.rect(k, y0 + 2, k, y0 + 8, dark(col, 0.25))
            layer.rect(x0, y0, x0 + 24, y0, light(col, 0.2))


def pine_row(layer, rng, base, hmin, hmax, color, spacing=(5, 11)):
    x = 0
    while x < W:
        h = rng.randrange(hmin, hmax)
        for i in range(h):
            half = int((i / h) * h * 0.32) + 1
            y = base - h + i
            layer.rect(x - half, y, x + half, y, color)
        layer.rect(x, base - 2, x, base + 6, dark(color, 0.3))
        x += rng.randrange(*spacing)


def pillar(layer, x, base, h, w, stone, shade, broken_rng=None):
    top = base - h
    layer.rect(x, top, x + w, base, stone)
    layer.rect(x + w - 2, top, x + w, base, shade)
    layer.rect(x - 2, base - 4, x + w + 2, base, shade)
    if broken_rng:
        for k in range(0, w + 1):
            cut = broken_rng.randrange(0, 7)
            layer.rect(x + k, top - 1, x + k, top + cut, (0, 0, 0, 0))
    else:
        layer.rect(x - 3, top - 4, x + w + 3, top, stone)
        layer.rect(x - 3, top, x + w + 3, top, shade)
    for y in range(top + 8, base - 4, 9):
        layer.rect(x, y, x + w, y, shade)


def turbine(layer, x, base, h, r, angle, body, blade):
    layer.rect(x - 1, base - h, x, base, body)
    cx, cy = x, base - h
    for k in range(3):
        a = angle + k * 2 * math.pi / 3
        layer.line([(cx, cy), (cx + math.cos(a) * r, cy + math.sin(a) * r)], blade, 2)
    layer.rect(cx - 1, cy - 1, cx + 1, cy + 1, light(body, 0.3))


def fuuto_tower(layer, x, base, h, body, trim, blade, angle, blade_r=46):
    """Tháp gió Fuuto: thân thon cao, vành đai quan sát, cối xay gió lớn trên đỉnh."""
    top = base - h
    for y in range(top, base):
        t = (y - top) / h
        half = int(5 + 10 * t ** 1.6)
        layer.rect(x - half, y, x + half, y, body)
        layer.px(x - half, y, light(body, 0.15))
    for frac in (0.22, 0.5, 0.78):
        yy = top + int(h * frac)
        layer.rect(x - 14, yy, x + 14, yy + 3, trim)
        for k in range(-12, 13, 4):
            layer.px(x + k, yy + 1, (255, 220, 150, 255))
    cy = top + 6
    for k in range(4):
        a = angle + k * math.pi / 2
        ex, ey = x + math.cos(a) * blade_r, cy + math.sin(a) * blade_r
        layer.line([(x, cy), (ex, ey)], blade, 4)
        layer.line([(x, cy), (ex, ey)], light(blade, 0.25), 1)
    layer.ellipse(x - 5, cy - 5, x + 5, cy + 5, trim)


def smokestack(layer, x, base, h, w, body, stripe, smoke, rng):
    top = base - h
    layer.rect(x, top, x + w, base, body)
    for y in (top + 3, top + 10):
        layer.rect(x, y, x + w, y + 3, stripe)
    layer.rect(x - 1, top - 2, x + w + 1, top, dark(body, 0.2))
    # Khói: các cụm tròn bay chếch theo gió, nhạt dần (lớp vẽ đè nên độ trong suốt đều trong một cụm).
    sx, sy = x + w / 2, top - 4
    for i in range(12):
        r = 2 + i * 1.2
        sx += rng.uniform(3, 7)
        sy -= rng.uniform(1, 4)
        a = int(200 - i * 13)
        layer.ellipse(sx - r, sy - r * 0.7, sx + r, sy + r * 0.7, smoke[:3] + (a,))


def particles(im, rng, count, colors, y0=4, y1=BASE, size=(1, 2)):
    d = ImageDraw.Draw(im)
    for _ in range(count):
        x, y = rng.randrange(W), rng.randrange(y0, y1)
        s = rng.randrange(size[0], size[1] + 1)
        d.rectangle((x, y, x + s - 1, y + s - 1), fill=rng.choice(colors))


def ground(im, color, y=BASE):
    ImageDraw.Draw(im).rectangle((0, y, W - 1, H - 1), fill=color)


# --- Các nền -------------------------------------------------------------------

def bg_ruins(im, rng):
    """1-2 Di tích Kuuga ở Nagano: hoàng hôn trên núi, cột đá cổ, rừng thông."""
    gradient(im, 0, BASE, [rgb("2a1e4a"), rgb("4a2d63"), rgb("7a3f6e"), rgb("c0606a"), rgb("e8946a"), rgb("f2c27a")])
    stars(im, rng, 40, 50)
    ImageDraw.Draw(im).ellipse((560, 120, 600, 160), fill=rgb("ffe2a0"))
    mountains(im, 11, 150, 70, rgb("6b4a7a"), rgb("8a6292"))
    mountains(im, 12, 176, 50, rgb("4a3560"), rgb("5e4478"))
    L = Layer()
    stone, shade = rgb("5a5068"), rgb("3e3650")
    for x in range(20, W, 150):
        # Mỗi cụm: hàng cột cùng chiều cao, còn nguyên thì có xà đá ngang, đổ nát thì cột gãy lởm chởm.
        n = rng.randrange(2, 5)
        h = rng.randrange(46, 80)
        intact = rng.random() < 0.55
        for k in range(n):
            ph = h if intact else h - rng.randrange(0, 30)
            pillar(L, x + k * 22, BASE, ph, 9, stone, shade, None if intact else rng)
        if intact:
            L.rect(x - 4, BASE - h - 11, x + (n - 1) * 22 + 13, BASE - h - 5, stone)
            L.rect(x - 4, BASE - h - 5, x + (n - 1) * 22 + 13, BASE - h - 5, shade)
    put(im, L)
    L = Layer()
    pine_row(L, rng, BASE + 2, 22, 44, rgb("22183a"))
    put(im, L)
    fog(im, 170, BASE, rgb("8a5a7a"), 0.2)
    ground(im, rgb("1a1230"))


def bg_tokyo(im, rng):
    """1-3 Tokyo về đêm: trăng tròn, tháp Tokyo, nhà cao tầng lấp lánh."""
    gradient(im, 0, BASE, [rgb("070b24"), rgb("0c1538"), rgb("16224e"), rgb("233266"), rgb("3a3f7a")])
    stars(im, rng, 110, 110)
    moon(im, 640, 46, 18, rgb("f4f0d8"))
    L = Layer()
    skyline(L, rng, BASE - 6, 40, 90, 14, 30, rgb("1b2448"), rgb("8aa0e0"), lit=0.25, antenna=0.15)
    put(im, L)
    L = Layer()
    tokyo_tower(L, 300, BASE, 150, rgb("ff5a3a"), rgb("f2ece0"), rgb("ffd27a"))
    put(im, L)
    L = Layer()
    skyline(L, rng, BASE, 30, 110, 16, 38, rgb("121a38"), rgb("ffd67a"), lit=0.3, antenna=0.3)
    put(im, L)
    ground(im, rgb("0a0f24"))


def bg_harbor(im, rng):
    """1-4 Kho hàng bến cảng: biển đêm, cần cẩu, container nhiều màu, sương."""
    gradient(im, 0, 150, [rgb("0b1a2a"), rgb("12283c"), rgb("1c3a50"), rgb("2c5064")])
    stars(im, rng, 60, 80)
    moon(im, 150, 40, 12, rgb("e8f0f0"))
    px = im.load()
    for y in range(150, H):
        for x in range(W):
            c = rgb("0e2233") if (y + (x // 12)) % 5 else rgb("1b3a4e")
            px[x, y] = c
    for k in range(40):
        x, y = rng.randrange(W), rng.randrange(152, 190)
        ImageDraw.Draw(im).line((x, y, x + rng.randrange(4, 12), y), fill=rgb("5a8aa0"))
    L = Layer()
    for x in range(40, W, 200):
        crane(L, x, 172, rng.randrange(90, 120), rng.randrange(60, 90), rgb("22323e"), rgb("e0a040"))
    put(im, L)
    L = Layer()
    pal = [rgb("b04a3a"), rgb("3a7ab0"), rgb("d0a040"), rgb("3a9070"), rgb("8a4a90")]
    x = 0
    while x < W:
        containers(L, rng, x, BASE, rng.randrange(2, 4), rng.randrange(1, 4), pal)
        x += rng.randrange(90, 140)
    L.rect(0, BASE - 2, W - 1, BASE, rgb("2a2a30"))
    for x in range(30, W, 110):
        L.rect(x, BASE - 44, x, BASE, rgb("30343c"))
        L.rect(x - 3, BASE - 46, x + 3, BASE - 44, rgb("ffd27a"))
    put(im, L)
    fog(im, 120, 175, rgb("6a8a9a"), 0.3)
    ground(im, rgb("12161e"))


def bg_boss_kuuga(im, rng):
    """1-B Trùm Daguba: trời đỏ máu, trăng đen, thành phố cháy, tàn lửa."""
    gradient(im, 0, BASE, [rgb("1a0508"), rgb("3a0a10"), rgb("6a1414"), rgb("a02818"), rgb("d85020"), rgb("f09030")])
    d = ImageDraw.Draw(im)
    d.ellipse((380, 20, 460, 100), fill=rgb("2a0608"))
    d.ellipse((384, 24, 456, 96), fill=rgb("12020a"))
    mountains(im, 31, 160, 40, rgb("4a0e10"))
    L = Layer()
    jagged_ruins(L, rng, BASE, 40, 110, rgb("1e0608"), glow=rgb("ff8a30"))
    put(im, L)
    particles(im, rng, 160, [rgb("ffb040"), rgb("ff6a20"), rgb("ffe080")], 20, BASE)
    ground(im, rgb("12020a"))


def bg_laundry(im, rng):
    """2-1 Tiệm giặt ủi Kikuchi: phố nhỏ lúc chiều tà, cột điện và dây điện."""
    gradient(im, 0, BASE, [rgb("3a2a5a"), rgb("6a3a6a"), rgb("b05a6a"), rgb("e8845a"), rgb("f8b060"), rgb("fcd890")])
    ImageDraw.Draw(im).ellipse((470, 130, 530, 190), fill=rgb("fff0b0"))
    L = Layer()
    skyline(L, rng, BASE - 8, 50, 90, 20, 40, rgb("7a4a70"), rgb("ffd8a0"), lit=0.2, antenna=0.1, roofs=False)
    put(im, L)
    L = Layer()
    x = 0
    shop_cols = [rgb("5a3050"), rgb("4a2a48"), rgb("603858")]
    while x < W:
        w = rng.randrange(40, 70)
        h = rng.randrange(34, 60)
        c = rng.choice(shop_cols)
        top = BASE - h
        L.poly([(x - 2, top), (x + w // 2, top - 10), (x + w + 2, top)], dark(c, 0.2))
        L.rect(x, top, x + w, BASE, c)
        L.rect(x, top, x, BASE, light(c, 0.1))
        aw = rng.choice([rgb("e0e0f0"), rgb("80c0e0"), rgb("f0a0a0")])
        for k in range(x + 2, x + w - 2, 6):
            L.rect(k, BASE - 22, k + 2, BASE - 18, aw)
            L.rect(k + 3, BASE - 22, k + 5, BASE - 18, dark(aw, 0.3))
        L.rect(x + 4, BASE - 16, x + w - 4, BASE - 2, rgb("ffe0a0"))
        for k in range(x + 8, x + w - 8, 10):
            L.rect(k, top + 8, k + 5, top + 14, rgb("ffe0a0") if rng.random() < 0.5 else dark(c, 0.3))
        x += w + rng.randrange(2, 8)
    put(im, L)
    L = Layer()
    pole = rgb("2a1a30")
    poles = list(range(0, W, 160))
    for p in poles:
        L.rect(p, BASE - 110, p + 2, BASE, pole)
        L.rect(p - 10, BASE - 104, p + 12, BASE - 102, pole)
        L.rect(p - 6, BASE - 92, p + 8, BASE - 90, pole)
    for p in poles:
        for sag, yy in ((10, BASE - 103), (8, BASE - 91)):
            pts = [(p + t, yy + sag * math.sin(math.pi * t / 160)) for t in range(0, 161, 4)]
            L.line(pts, pole)
    put(im, L)
    ground(im, rgb("2a1a30"))


def bg_highway(im, rng):
    """2-2 Đường cao tốc: cầu cạn trên cao, đèn đường, vệt đèn xe, thành phố xa."""
    gradient(im, 0, BASE, [rgb("0a0a20"), rgb("141436"), rgb("22204c"), rgb("3a2a5e"), rgb("5a3a6e")])
    stars(im, rng, 70, 90)
    L = Layer()
    skyline(L, rng, 170, 30, 80, 12, 26, rgb("24234a"), rgb("a0a0e0"), lit=0.25, antenna=0.2)
    put(im, L)
    L = Layer()
    deck = rgb("3a3a52")
    L.rect(0, 128, W - 1, 138, deck)
    L.rect(0, 128, W - 1, 128, rgb("8a8aa8"))
    L.rect(0, 139, W - 1, 141, dark(deck, 0.4))
    for x in range(0, W, 100):
        L.rect(x + 40, 142, x + 56, H - 1, rgb("2a2a40"))
        L.rect(x + 40, 142, x + 42, H - 1, rgb("3e3e58"))
    for x in range(10, W, 50):
        L.rect(x, 104, x, 128, rgb("50506a"))
        L.rect(x, 104, x + 6, 105, rgb("50506a"))
        L.rect(x + 5, 106, x + 7, 107, rgb("fff0b0"))
    for k in range(34):
        x = rng.randrange(W)
        c = rng.choice([rgb("ff5050"), rgb("fff0d0"), rgb("ffd070")])
        L.rect(x, 132 + rng.randrange(0, 4), x + rng.randrange(8, 26), 132 + rng.randrange(0, 4), c)
    put(im, L)
    L = Layer()
    skyline(L, rng, BASE, 20, 50, 20, 44, rgb("16162e"), rgb("ffd67a"), lit=0.2, antenna=0.05, roofs=False)
    put(im, L)
    ground(im, rgb("0c0c1e"))


def bg_smart_brain(im, rng):
    """2-3 Sảnh Smart Brain: trời thép lạnh, cao ốc kính, một tòa tháp tập đoàn lớn."""
    gradient(im, 0, BASE, [rgb("0a1a26"), rgb("123040"), rgb("1c4858"), rgb("2c6a78"), rgb("4a8e98")])
    stars(im, rng, 40, 60)
    L = Layer()
    skyline(L, rng, BASE, 60, 120, 16, 30, rgb("1a3440"), rgb("7ad0e0"), lit=0.3, antenna=0.2, win=(1, 2, 3, 4))
    put(im, L)
    L = Layer()
    x0, x1, top = 360, 440, 18
    glass = [rgb("1e3a4c"), rgb("24485a"), rgb("2c5668")]
    for x in range(x0, x1 + 1):
        L.rect(x, top + (0 if x0 + 10 < x < x1 - 10 else 12), x, BASE, glass[(x // 6) % 3])
    for y in range(top + 16, BASE, 6):
        L.rect(x0, y, x1, y, rgb("163040"))
    for x in range(x0 + 6, x1, 12):
        L.rect(x, top + 16, x, BASE, rgb("5ab0c8"))
    L.rect(x0 + 24, top + 30, x1 - 24, top + 58, rgb("0e2230"))
    L.poly([(400, top + 34), (412, top + 44), (400, top + 54), (388, top + 44)], rgb("ff4a4a"))
    L.poly([(400, top + 38), (408, top + 44), (400, top + 50), (392, top + 44)], rgb("ffb0b0"))
    L.rect(398, top - 22, 402, top, rgb("24485a"))
    L.px(400, top - 23, (255, 80, 80, 255))
    put(im, L)
    L = Layer()
    skyline(L, rng, BASE, 20, 60, 24, 50, rgb("0e1e28"), rgb("a0f0ff"), lit=0.18, antenna=0.1, roofs=False)
    put(im, L)
    ground(im, rgb("08141c"))


def bg_lab(im, rng):
    """2-4 Phòng thí nghiệm: vách kim loại, ống dẫn, bể kính chất lỏng xanh, màn hình."""
    gradient(im, 0, H, [rgb("0c1418"), rgb("121e24"), rgb("18262e"), rgb("1e2e36")])
    L = Layer()
    for y in range(0, H, 28):
        L.rect(0, y, W - 1, y, rgb("0a1014"))
        L.rect(0, y + 1, W - 1, y + 1, rgb("2a3a44"))
    for x in range(0, W, 64):
        L.rect(x, 0, x, H - 1, rgb("0a1014"))
        for y in range(6, H, 28):
            L.px(x + 3, y, rgb("3a4a54"))
            L.px(x + 60, y, rgb("3a4a54"))
    for y, c in ((20, rgb("3a4650")), (34, rgb("5a3a2a"))):
        L.rect(0, y, W - 1, y + 5, c)
        L.rect(0, y, W - 1, y, light(c, 0.2))
        for x in range(0, W, 80):
            L.rect(x, y - 1, x + 5, y + 6, dark(c, 0.3))
    put(im, L)
    L = Layer()
    for x in range(30, W, 160):
        top = 70
        L.rect(x - 2, top - 8, x + 34, top - 2, rgb("40505a"))
        L.rect(x, top, x + 32, BASE - 12, rgb("0e3a30"))
        for y in range(top + 10, BASE - 12):
            f = (y - top) / (BASE - 12 - top)
            L.rect(x + 1, y, x + 31, y, mix(rgb("1aa070"), rgb("0a6a48"), f))
        for _ in range(10):
            bx, by = x + rng.randrange(4, 28), rng.randrange(top + 14, BASE - 16)
            L.px(bx, by, rgb("a0ffd0"))
        L.rect(x + 3, top + 2, x + 4, BASE - 14, rgb("6ad0b0"))
        L.rect(x - 2, BASE - 12, x + 34, BASE, rgb("40505a"))
        L.ellipse(x + 8, top + 40, x + 24, top + 70, rgb("0a2a22"))
        mx = x + 70
        L.rect(mx, 90, mx + 40, 120, rgb("2a3640"))
        L.rect(mx + 2, 92, mx + 38, 116, rgb("0a1a20"))
        for k in range(4):
            wy = 96 + k * 5
            L.rect(mx + 4, wy, mx + 4 + rng.randrange(8, 30), wy + 1, rgb("4ae0ff") if k % 2 == 0 else rgb("ff6a6a"))
        L.rect(mx + 18, 120, mx + 22, 150, rgb("2a3640"))
    put(im, L)
    L = Layer()
    for x in range(0, W, 16):
        L.poly([(x, BASE - 8), (x + 8, BASE - 8), (x + 16, BASE), (x + 8, BASE)], rgb("e0b030"))
    L.rect(0, BASE - 9, W - 1, BASE - 9, rgb("2a2a2a"))
    put(im, L)
    ground(im, rgb("0a0e10"))


def bg_boss_faiz(im, rng):
    """2-B Trùm Dragon Orphnoch: trời tro xám tím, tàn tro trắng rơi, nhà đổ nát ánh đỏ."""
    gradient(im, 0, BASE, [rgb("16141c"), rgb("24202c"), rgb("38303e"), rgb("54444e"), rgb("7a5a58")])
    ImageDraw.Draw(im).ellipse((120, 30, 176, 86), fill=rgb("c8c0c0"))
    ImageDraw.Draw(im).ellipse((132, 26, 188, 82), fill=rgb("24202c"))
    mountains(im, 41, 150, 36, rgb("3a3040"))
    L = Layer()
    jagged_ruins(L, rng, BASE, 50, 120, rgb("1a1620"), glow=rgb("ff4a3a"))
    put(im, L)
    particles(im, rng, 220, [rgb("d8d4d8"), rgb("a8a0a8"), rgb("f0ecec")], 4, BASE)
    ground(im, rgb("100e14"))


def bg_fuuto(im, rng, day=False):
    """3-1 Thành phố gió Fuuto lúc chiều: tháp gió Fuuto, turbine nhỏ trên mái."""
    if day:
        gradient(im, 0, BASE, [rgb("3a78c8"), rgb("5a92d8"), rgb("7aaee0"), rgb("a0c8e8"), rgb("c8e0f0")])
    else:
        gradient(im, 0, BASE, [rgb("1a2450"), rgb("2a3a6a"), rgb("4a4a7a"), rgb("9a5a78"), rgb("e08a6a"), rgb("f4b87a")])
        stars(im, rng, 50, 60)
    if day:
        clouds(im, rng, 10)
    L = Layer()
    fuuto_tower(L, 520, BASE, 170, rgb("5a6a8a") if not day else rgb("8a9ab8"), rgb("3a4a6a"), rgb("e8e8f0"), 0.35)
    put(im, L)
    L = Layer()
    body = rgb("3a3a62") if not day else rgb("6a88a8")
    skyline(L, rng, BASE, 30, 80, 16, 34, body, rgb("ffd890") if not day else rgb("c0e0f8"),
            lit=0.3 if not day else 0.5, antenna=0.05)
    for x in range(20, W, 70):
        turbine(L, x + rng.randrange(0, 30), BASE - rng.randrange(40, 80), 14, 8, rng.uniform(0, 6.28),
                dark(body, 0.2), light(body, 0.5))
    put(im, L)
    ground(im, rgb("1a1a34") if not day else rgb("3a4a64"))


def clouds(im, rng, count, color=None, shade=None, y1=110):
    d = ImageDraw.Draw(im)
    color = color or rgb("f4f8ff")
    shade = shade or rgb("c8d8ec")
    for _ in range(count):
        x, y = rng.randrange(W), rng.randrange(14, y1)
        w = rng.randrange(40, 90)
        for k in range(5):
            cx = x + rng.randrange(-w // 2, w // 2)
            r = rng.randrange(8, 16)
            for ox in (0, -W, W):
                d.ellipse((cx + ox - r, y - r, cx + ox + r, y + r // 2), fill=shade)
                d.ellipse((cx + ox - r, y - r - 2, cx + ox + r, y + r // 2 - 3), fill=color)


def bg_fuuto_street(im, rng):
    """3-2 Phố gió Fuuto: trời chiều quang mây, nhà thấp màu pastel, turbine nhỏ khắp nơi."""
    bg_fuuto(im, rng, day=True)


def bg_wind_tower(im, rng):
    """3-3 Tháp gió: cận cảnh tháp gió Fuuto với cánh quạt lớn, mây trôi."""
    gradient(im, 0, BASE, [rgb("2a4a8a"), rgb("3a62a0"), rgb("5a80b8"), rgb("8aa6cc"), rgb("c0d0e0")])
    clouds(im, rng, 12, rgb("e8eef8"), rgb("aebcd4"), y1=160)
    L = Layer()
    skyline(L, rng, BASE, 20, 50, 18, 34, rgb("4a6488"), rgb("d0e8ff"), lit=0.4, antenna=0.05)
    put(im, L)
    L = Layer()
    for x in (200, 600):
        fuuto_tower(L, x, BASE + 40, 180, rgb("6a7898"), rgb("3a4868"), rgb("f0f0f8"), 0.2 if x == 200 else 1.0,
                    blade_r=62)
    put(im, L)
    ground(im, rgb("2a3a54"))


def bg_industrial(im, rng):
    """3-4 Khu công nghiệp: trời khói bụi cam nâu, ống khói sọc, mái răng cưa, bồn chứa."""
    gradient(im, 0, BASE, [rgb("1e1418"), rgb("3a2420"), rgb("5a3624"), rgb("8a5028"), rgb("b87438")])
    L = Layer()
    for x in range(40, W, 130):
        smokestack(L, x, BASE - 30, rng.randrange(90, 130), 8, rgb("3a2e2c"), rgb("c04a3a"), rgb("6a5a52"), rng)
    put(im, L)
    L = Layer()
    x = 0
    while x < W:
        w = rng.randrange(60, 110)
        h = rng.randrange(30, 55)
        top = BASE - h
        L.rect(x, top, x + w, BASE, rgb("2a2024"))
        for k in range(x, x + w, 12):
            L.poly([(k, top), (k + 12, top), (k + 12, top - 8)], rgb("34282a"))
            L.rect(k + 10, top - 7, k + 11, top, rgb("ffb060"))
        for k in range(x + 6, x + w - 6, 9):
            L.rect(k, top + 10, k + 4, top + 14, rgb("ffb060") if rng.random() < 0.4 else rgb("1a1418"))
        x += w + rng.randrange(20, 50)
    for x in range(10, W, 190):
        L.ellipse(x, BASE - 44, x + 40, BASE - 4, rgb("4a3a36"))
        L.ellipse(x + 4, BASE - 42, x + 18, BASE - 28, rgb("5e4a44"))
        L.rect(x + 18, BASE - 4, x + 22, BASE, rgb("2a2024"))
    L.rect(0, BASE - 60, W - 1, BASE - 57, rgb("3a2e2c"))
    for x in range(0, W, 40):
        L.rect(x, BASE - 57, x + 1, BASE, rgb("3a2e2c"))
    put(im, L)
    fog(im, 100, BASE, rgb("a07048"), 0.3)
    ground(im, rgb("140e10"))


def bg_boss_w(im, rng):
    """3-B Trùm Eternal: đêm bão, mây xoáy, sét, bóng tháp gió Fuuto, mưa."""
    gradient(im, 0, BASE, [rgb("08100e"), rgb("10201c"), rgb("1a2e2a"), rgb("2a3a40"), rgb("3e3a52")])
    clouds(im, rng, 16, rgb("24323a"), rgb("18222a"), y1=90)
    d = ImageDraw.Draw(im)
    x, y = 250, 0
    pts = [(x, y)]
    while y < 150:
        x += rng.randrange(-10, 11)
        y += rng.randrange(8, 16)
        pts.append((x, y))
    d.line(pts, fill=rgb("a0f0ff"), width=3)
    d.line(pts, fill=rgb("ffffff"), width=1)
    L = Layer()
    fuuto_tower(L, 560, BASE, 170, rgb("141c20"), rgb("0e1418"), rgb("1c2830"), 0.9)
    put(im, L)
    L = Layer()
    skyline(L, rng, BASE, 30, 90, 16, 34, rgb("0e1618"), rgb("7affc0"), lit=0.12, antenna=0.2)
    put(im, L)
    for _ in range(420):
        rx, ry = rng.randrange(W), rng.randrange(4, BASE)
        d.line((rx, ry, rx - 2, ry + 5), fill=rgb("5a7a8a"))
    ground(im, rgb("060a0a"))


# Danh mục kiểu nền. File thế giới chọn bằng "bg_theme" (xem docs/WORLD_FILES.md); tools/validate_worlds.gd
# đọc danh sách tên ở đây để kiểm tra. Mỗi ảnh nền dùng hạt giống theo tên ảnh, nên hai màn cùng kiểu vẫn khác nhau.
THEMES = {
    # --- Nền riêng của Kuuga / Faiz / W (dùng lại được) ---
    "ruins": bg_ruins,                  # di tích đá cổ, núi hoàng hôn, rừng thông
    "tokyo": bg_tokyo,                  # Tokyo đêm, trăng tròn, tháp Tokyo
    "harbor": bg_harbor,                # bến cảng đêm, cần cẩu, container
    "boss_kuuga": bg_boss_kuuga,        # trời đỏ máu, trăng đen, thành phố cháy
    "laundry": bg_laundry,              # phố nhỏ chiều tà, cột điện
    "highway": bg_highway,              # cầu cạn cao tốc đêm, vệt đèn xe
    "smart_brain": bg_smart_brain,      # cao ốc kính, tháp tập đoàn
    "lab": bg_lab,                      # phòng thí nghiệm: bể kính, màn hình (trong nhà)
    "boss_faiz": bg_boss_faiz,          # trời tro xám, tàn tro rơi
    "fuuto": bg_fuuto,                  # thành phố chiều, tháp gió
    "fuuto_street": bg_fuuto_street,    # thành phố ban ngày, turbine nhỏ
    "wind_tower": bg_wind_tower,        # cận cảnh tháp gió, mây
    "industrial": bg_industrial,        # khu công nghiệp, ống khói, khói bụi
    "boss_w": bg_boss_w,                # đêm bão, sét, mưa
    # --- Kiểu chung cho các thế giới khác ---
    "city_day": lambda im, rng: themed(im, rng, "city_day"),          # phố ban ngày, cao ốc, trời xanh mây trắng
    "city_dusk": lambda im, rng: themed(im, rng, "city_dusk"),        # phố hoàng hôn, trời cam tím
    "city_night": lambda im, rng: themed(im, rng, "city_night"),      # phố đêm, cửa sổ sáng, trăng
    "suburb": lambda im, rng: themed(im, rng, "suburb"),              # khu dân cư nhà thấp, cây, cột điện, chiều
    "coast": lambda im, rng: themed(im, rng, "coast"),                # biển, bãi đá, hoàng hôn
    "mountain_dawn": lambda im, rng: themed(im, rng, "mountain_dawn"),  # núi nhiều lớp, bình minh, sương
    "forest_day": lambda im, rng: themed(im, rng, "forest_day"),      # rừng cây lá rộng ban ngày
    "forest_night": lambda im, rng: themed(im, rng, "forest_night"),  # rừng đêm, đom đóm, trăng
    "shrine": lambda im, rng: themed(im, rng, "shrine"),              # đền Nhật, cổng torii, đèn lồng, núi
    "snow_mountain": lambda im, rng: themed(im, rng, "snow_mountain"),  # núi tuyết, tuyết rơi
    "mirror_city": lambda im, rng: themed(im, rng, "mirror_city"),    # thế giới gương: phố phản chiếu, mảnh gương vỡ
    "castle_night": lambda im, rng: themed(im, rng, "castle_night"),  # lâu đài gothic, trăng lớn, dơi
    "desert_rails": lambda im, rng: themed(im, rng, "desert_rails"),  # sa mạc cát thời gian, đường ray, trời tím
    "space_moon": lambda im, rng: themed(im, rng, "space_moon"),      # mặt trăng, Trái Đất trên trời, căn cứ
    "school": lambda im, rng: themed(im, rng, "school"),              # trường học, hoa anh đào, sân
    "underworld": lambda im, rng: themed(im, rng, "underworld"),      # không gian phép tím, đá lơ lửng, vòng phép
    "helheim": lambda im, rng: themed(im, rng, "helheim"),            # rừng Helheim: dây leo, trái lạ phát sáng
    "race_city": lambda im, rng: themed(im, rng, "race_city"),        # thành phố đêm, vệt đèn tốc độ, đường đua
    "temple_ghost": lambda im, rng: themed(im, rng, "temple_ghost"),  # chùa, bia mộ, đốm linh hồn
    "game_world": lambda im, rng: themed(im, rng, "game_world"),      # thế giới game 8-bit: khối, đồng xu, mây vuông
    "hospital": lambda im, rng: themed(im, rng, "hospital"),          # bệnh viện, cây xanh, trực thăng
    "sky_wall": lambda im, rng: themed(im, rng, "sky_wall"),          # bức tường khổng lồ chia thành phố, tháp cao
    "clock_tower": lambda im, rng: themed(im, rng, "clock_tower"),    # tháp đồng hồ, bánh răng lơ lửng
    "cyber_city": lambda im, rng: themed(im, rng, "cyber_city"),      # thành phố tương lai, lưới hologram, vệ tinh
    "library": lambda im, rng: themed(im, rng, "library"),            # thư viện: kệ sách, sách bay (trong nhà)
    "book_world": lambda im, rng: themed(im, rng, "book_world"),      # thế giới trong sách: trang giấy, lâu đài cổ tích
    "arena": lambda im, rng: themed(im, rng, "arena"),                # đấu trường: đèn chiếu, khán đài, màn hình lớn
    "academy": lambda im, rng: themed(im, rng, "academy"),            # học viện giả kim: tháp cổ, vòng giả kim
    "candy_factory": lambda im, rng: themed(im, rng, "candy_factory"),  # nhà máy kẹo: băng chuyền, kẹo, ống màu
    "dreamscape": lambda im, rng: themed(im, rng, "dreamscape"),      # giấc mơ: cửa lơ lửng, đảo nổi, trời pastel
    "boss_red": lambda im, rng: themed(im, rng, "boss_red"),          # trùm: trời đỏ, đổ nát cháy
    "boss_purple": lambda im, rng: themed(im, rng, "boss_purple"),    # trùm: trời tím, khe nứt không gian
    "boss_dark": lambda im, rng: themed(im, rng, "boss_dark"),        # trùm: đêm đen, trăng nhạt, sương
    "boss_storm": lambda im, rng: themed(im, rng, "boss_storm"),      # trùm: bão, sét, mưa
    "boss_gold": lambda im, rng: themed(im, rng, "boss_gold"),        # trùm: trời vàng kim, ánh sáng thần thánh
    "boss_ice": lambda im, rng: themed(im, rng, "boss_ice"),          # trùm: băng giá, trời xanh lạnh
}


def themed(im, rng, name):
    """Kiểu nền chung cho các thế giới (danh mục THEMES)."""
    THEMED[name](im, rng)


# --- Thành phần dùng chung cho các kiểu nền mới -------------------------------------------

def houses(layer, rng, base, walls, roofs, win):
    x = 0
    while x < W:
        w = rng.randrange(28, 52)
        h = rng.randrange(20, 34)
        c = rng.choice(walls)
        r = rng.choice(roofs)
        top = base - h
        layer.rect(x, top, x + w, base, c)
        layer.poly([(x - 3, top), (x + w // 2, top - rng.randrange(10, 16)), (x + w + 3, top)], r)
        for k in range(x + 5, x + w - 6, 11):
            layer.rect(k, top + 6, k + 5, top + 11, win if rng.random() < 0.5 else dark(c, 0.3))
        x += w + rng.randrange(4, 22)


def round_trees(layer, rng, base, hmin, hmax, leaf, trunk, spacing=(18, 40), shade=None):
    shade = shade or dark(leaf, 0.25)
    x = rng.randrange(0, 20)
    while x < W + 20:
        h = rng.randrange(hmin, hmax)
        r = rng.randrange(10, 18)
        layer.rect(x - 1, base - h, x + 1, base, trunk)
        for k in range(4):
            ox, oy = rng.randrange(-r, r), rng.randrange(-r // 2, r // 2)
            layer.ellipse(x + ox - r, base - h + oy - r, x + ox + r, base - h + oy + r, shade)
        for k in range(3):
            ox, oy = rng.randrange(-r // 2, r // 2), rng.randrange(-r // 2, 0)
            layer.ellipse(x + ox - r + 3, base - h + oy - r + 3, x + ox + r - 3, base - h + oy + r - 3, leaf)
        x += rng.randrange(*spacing)


def sea(im, y0, colors, sparkle):
    px = im.load()
    d = ImageDraw.Draw(im)
    for y in range(y0, H):
        for x in range(W):
            px[x, y] = colors[(y + (x // 16) + (y * 3 // 7)) % len(colors)]
    rng = random.Random(y0)
    for _ in range(60):
        x, y = rng.randrange(W), rng.randrange(y0 + 2, H)
        d.line((x, y, x + rng.randrange(3, 10), y), fill=sparkle)


def torii(layer, x, base, h, red, dark_c):
    w = h * 0.9
    layer.rect(x - w / 2 + 6, base - h, x - w / 2 + 10, base, red)
    layer.rect(x + w / 2 - 10, base - h, x + w / 2 - 6, base, red)
    layer.rect(x - w / 2 - 4, base - h - 6, x + w / 2 + 4, base - h - 1, dark_c)
    layer.rect(x - w / 2, base - h + 8, x + w / 2, base - h + 11, red)
    layer.rect(x - 2, base - h, x + 2, base - h + 8, red)


def lanterns(layer, rng, y, color, count=14):
    for _ in range(count):
        x = rng.randrange(W)
        layer.rect(x, y - 6, x, y, rgb("2a1a1a"))
        layer.ellipse(x - 3, y, x + 3, y + 8, color)
        layer.px(x, y + 3, light(color, 0.5))


def gear(layer, cx, cy, r, color, teeth=10, angle=0.0):
    for k in range(teeth):
        a = angle + k * math.tau / teeth
        x0, y0 = cx + math.cos(a) * r, cy + math.sin(a) * r
        layer.ellipse(x0 - 2.5, y0 - 2.5, x0 + 2.5, y0 + 2.5, color)
    layer.ellipse(cx - r, cy - r, cx + r, cy + r, color)
    layer.ellipse(cx - r * 0.4, cy - r * 0.4, cx + r * 0.4, cy + r * 0.4, dark(color, 0.5))


def magic_circle(im, cx, cy, r, color):
    d = ImageDraw.Draw(im)
    for rr in (r, r * 0.8):
        d.ellipse((cx - rr, cy - rr * 0.35, cx + rr, cy + rr * 0.35), outline=color)
    for k in range(12):
        a = k * math.tau / 12
        d.point((cx + math.cos(a) * r * 0.9, cy + math.sin(a) * r * 0.9 * 0.35), fill=light(color, 0.4))


def floating_rocks(layer, rng, count, color, top_c, y_range=(40, 150)):
    for _ in range(count):
        x, y = rng.randrange(W), rng.randrange(*y_range)
        w = rng.randrange(14, 40)
        pts = [(x - w, y), (x + w, y)]
        for k in range(4):
            pts.insert(1, (x + w - (k + 1) * w * 2 // 5, y + rng.randrange(6, 16 + w // 3)))
        layer.poly([(x - w, y), (x + w, y), (x + w // 2, y + w // 2 + 8), (x, y + w // 1.5 + 6), (x - w // 2, y + w // 2 + 4)], color)
        layer.rect(x - w, y - 2, x + w, y, top_c)


def dunes(im, seed, base, amp, colors):
    for i, c in enumerate(colors):
        mountains(im, seed + i, base + i * 14, amp - i * 8, c, light(c, 0.12), ks=(1, 2, 3))


def spotlights(im, rng, count, color):
    over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    for _ in range(count):
        x = rng.randrange(W)
        tx = x + rng.randrange(-120, 120)
        d.polygon([(x - 4, BASE - 40), (x + 4, BASE - 40), (tx + 30, 0), (tx - 30, 0)], fill=color[:3] + (60,))
    im.alpha_composite(over)


def bats(im, rng, count, color):
    d = ImageDraw.Draw(im)
    for _ in range(count):
        x, y = rng.randrange(W), rng.randrange(20, 120)
        d.line((x - 4, y - 2, x, y, x + 4, y - 2), fill=color)


def rays(im, cx, cy, color, count=14):
    over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    for k in range(count):
        a = k * math.pi / count + math.pi
        a2 = a + math.pi / count / 2
        d.polygon([(cx, cy), (cx + math.cos(a) * 900, cy + math.sin(a) * 900),
                   (cx + math.cos(a2) * 900, cy + math.sin(a2) * 900)], fill=color[:3] + (38,))
    im.alpha_composite(over)


# --- Các kiểu nền mới ------------------------------------------------------------------

def t_city(im, rng, sky, body, win, lit, moon_c=None, star=0, cloud=None, far=None):
    gradient(im, 0, BASE, sky)
    if star:
        stars(im, rng, star, 100)
    if moon_c:
        moon(im, rng.randrange(80, W - 80), rng.randrange(28, 60), rng.randrange(10, 16), moon_c)
    if cloud:
        clouds(im, rng, 9, cloud[0], cloud[1])
    L = Layer()
    skyline(L, rng, BASE - 8, 40, 110, 12, 26, far or light(body, 0.1), mix(win, far or body, 0.5), lit=lit * 0.7, antenna=0.2)
    put(im, L)
    L = Layer()
    skyline(L, rng, BASE, 30, 95, 16, 36, body, win, lit=lit, antenna=0.3)
    put(im, L)
    ground(im, dark(body, 0.4))


def t_city_day(im, rng):
    t_city(im, rng, [rgb("3a7ad0"), rgb("5a96e0"), rgb("8ab8ec"), rgb("c0dcf4")], rgb("5a7898"), rgb("d8ecff"), 0.5,
           cloud=(rgb("f4f8ff"), rgb("c8d8ec")), far=rgb("7a98b8"))


def t_city_dusk(im, rng):
    t_city(im, rng, [rgb("2a2250"), rgb("5a3a6a"), rgb("a85a6a"), rgb("e8905a"), rgb("f8c070")], rgb("3a2a4a"),
           rgb("ffd890"), 0.3, star=20, far=rgb("6a4a6a"))


def t_city_night(im, rng):
    t_city(im, rng, [rgb("060a20"), rgb("0e1636"), rgb("1a2450"), rgb("2a3464")], rgb("141c38"), rgb("ffd67a"), 0.32,
           moon_c=rgb("f0ecd8"), star=100, far=rgb("1e2a50"))


def t_suburb(im, rng):
    gradient(im, 0, BASE, [rgb("3a5a9a"), rgb("6a86b8"), rgb("d8a080"), rgb("f4c890")])
    ImageDraw.Draw(im).ellipse((560, 120, 604, 164), fill=rgb("fff0c0"))
    mountains(im, rng.randrange(999), 168, 40, rgb("6a7aa0"), rgb("8a9ab8"))
    L = Layer()
    round_trees(L, rng, BASE, 30, 50, rgb("3a6a4a"), rgb("3a2a22"), (40, 90))
    put(im, L)
    L = Layer()
    houses(L, rng, BASE, [rgb("c8b8a0"), rgb("a8b8c8"), rgb("d8c8b0"), rgb("b0a098")],
           [rgb("7a3a32"), rgb("3a4a6a"), rgb("5a5a60")], rgb("ffe0a0"))
    for p in range(0, W, 170):
        L.rect(p, BASE - 90, p + 2, BASE, rgb("3a3030"))
        L.rect(p - 8, BASE - 84, p + 10, BASE - 82, rgb("3a3030"))
    put(im, L)
    L = Layer()
    for p in range(0, W, 170):
        pts = [(p + t, BASE - 83 + 8 * math.sin(math.pi * t / 170)) for t in range(0, 171, 5)]
        L.line(pts, rgb("3a3030"))
    put(im, L)
    ground(im, rgb("3a3a42"))


def t_coast(im, rng):
    gradient(im, 0, 140, [rgb("2a2a5a"), rgb("6a4a7a"), rgb("d0707a"), rgb("f8a870"), rgb("fcd890")])
    ImageDraw.Draw(im).ellipse((380, 112, 440, 172), fill=rgb("fff0b0"))
    sea(im, 140, [rgb("3a4a7a"), rgb("4a5a8a"), rgb("5a6a98")], rgb("ffd8a0"))
    L = Layer()
    x = 0
    while x < W:
        w = rng.randrange(30, 80)
        h = rng.randrange(20, 60)
        L.poly([(x, BASE), (x + w * 0.3, BASE - h), (x + w * 0.7, BASE - h + 10), (x + w, BASE)], rgb("3a2a3a"))
        L.poly([(x + w * 0.3, BASE - h), (x + w * 0.45, BASE - h + 4), (x + w * 0.2, BASE - h + 20)], rgb("5a4050"))
        x += w + rng.randrange(60, 180)
    put(im, L)
    ground(im, rgb("c8a878"))


def t_mountain_dawn(im, rng):
    gradient(im, 0, BASE, [rgb("2a3a6a"), rgb("5a6a9a"), rgb("c89aa0"), rgb("f8d0a0"), rgb("fce8c0")])
    ImageDraw.Draw(im).ellipse((300, 140, 350, 190), fill=rgb("fff4d0"))
    mountains(im, rng.randrange(999), 120, 90, rgb("7a8ab0"), rgb("a8b8d0"))
    fog(im, 110, 160, rgb("e8d8e0"), 0.3)
    mountains(im, rng.randrange(999), 165, 60, rgb("4a5a7a"), rgb("6a7a98"))
    L = Layer()
    pine_row(L, rng, BASE + 2, 26, 46, rgb("1e2a38"))
    put(im, L)
    ground(im, rgb("141c28"))


def t_forest(im, rng, night):
    if night:
        gradient(im, 0, BASE, [rgb("050a14"), rgb("0a1424"), rgb("122034"), rgb("1a2c40")])
        stars(im, rng, 80, 80)
        moon(im, rng.randrange(80, W - 80), 40, 13, rgb("e8f0e0"))
        leaves = [rgb("0e2a24"), rgb("143a30"), rgb("1a4a3a")]
    else:
        gradient(im, 0, BASE, [rgb("4a8ad0"), rgb("7aaade"), rgb("b0d4ea"), rgb("d8ecd8")])
        clouds(im, rng, 7)
        leaves = [rgb("3a7a4a"), rgb("2e6a3e"), rgb("4a8a58")]
    for i, leaf in enumerate(leaves):
        L = Layer()
        round_trees(L, rng, BASE + 4 - i * 2, 60 - i * 12, 110 - i * 20, leaf, dark(leaf, 0.5), (14, 30))
        put(im, L)
    if night:
        particles(im, rng, 40, [rgb("e8ff80"), rgb("c0ff60")], 80, BASE)
    ground(im, dark(leaves[0], 0.5))


def t_shrine(im, rng):
    gradient(im, 0, BASE, [rgb("1a1a3a"), rgb("3a2a5a"), rgb("8a4a6a"), rgb("e08a6a")])
    stars(im, rng, 40, 60)
    mountains(im, rng.randrange(999), 150, 70, rgb("4a3a5a"), rgb("6a5070"))
    L = Layer()
    pine_row(L, rng, BASE, 40, 70, rgb("1e1a2e"), (8, 16))
    put(im, L)
    L = Layer()
    for x in range(60, W, 260):
        torii(L, x, BASE, rng.randrange(60, 80), rgb("d8402e"), rgb("2a1a1a"))
    x = 190
    L.rect(x, BASE - 50, x + 90, BASE, rgb("5a3a2e"))
    L.poly([(x - 16, BASE - 50), (x + 45, BASE - 78), (x + 106, BASE - 50)], rgb("2a2a34"))
    L.rect(x + 10, BASE - 40, x + 80, BASE - 30, rgb("ffd08a"))
    lanterns(L, rng, BASE - 60, rgb("ff9a4a"))
    put(im, L)
    ground(im, rgb("2a1e24"))


def t_snow(im, rng):
    gradient(im, 0, BASE, [rgb("6a88b8"), rgb("8aa6cc"), rgb("b8cce0"), rgb("dae4ee")])
    mountains(im, rng.randrange(999), 110, 90, rgb("e8eef8"), rgb("ffffff"))
    mountains(im, rng.randrange(999), 150, 60, rgb("9ab0cc"), rgb("c8d8ea"))
    L = Layer()
    pine_row(L, rng, BASE + 2, 26, 50, rgb("2a4a5a"))
    put(im, L)
    particles(im, rng, 260, [rgb("ffffff"), rgb("e0ecff")], 4, BASE)
    ground(im, rgb("e0e8f0"))


def t_mirror_city(im, rng):
    gradient(im, 0, BASE, [rgb("0a1a2a"), rgb("12304a"), rgb("1a4a6a"), rgb("2a6a8a")])
    L = Layer()
    skyline(L, rng, BASE, 40, 110, 14, 30, rgb("12344a"), rgb("8ae8ff"), lit=0.3)
    put(im, L)
    # thành phố lộn ngược phía trên, như ảnh phản chiếu
    top = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    L = Layer()
    skyline(L, rng, BASE, 30, 90, 14, 30, rgb("1a4a60"), rgb("c0f4ff"), lit=0.25, antenna=0)
    flipped = L.fold().transpose(Image.FLIP_TOP_BOTTOM)
    top.alpha_composite(flipped, (0, -14))
    px = top.load()
    for y in range(H):
        for x in range(W):
            if px[x, y][3]:
                px[x, y] = px[x, y][:3] + (120,)
    im.alpha_composite(top)
    d = ImageDraw.Draw(im)
    for _ in range(26):
        x, y, r = rng.randrange(W), rng.randrange(10, 170), rng.randrange(5, 14)
        pts = [(x, y - r), (x + r * 0.8, y + r * 0.2), (x - r * 0.3, y + r)]
        d.polygon(pts, fill=rgb("a8e8f8") if rng.random() < 0.5 else rgb("5ab0d0"))
        d.line(pts + [pts[0]], fill=rgb("ffffff"))
    ground(im, rgb("08202c"))


def t_castle_night(im, rng):
    gradient(im, 0, BASE, [rgb("0a0614"), rgb("1a0a24"), rgb("2a1030"), rgb("4a1a3a")])
    stars(im, rng, 90, 90)
    moon(im, 560, 60, 26, rgb("f4e8d0"))
    bats(im, rng, 18, rgb("0a0610"))
    L = Layer()
    for cx in (240, 640):
        body = rgb("1a1224")
        L.rect(cx - 90, BASE - 70, cx + 90, BASE, body)
        for tx, th in ((-90, 120), (-40, 150), (10, 170), (60, 130), (90, 110)):
            L.rect(cx + tx - 10, BASE - th, cx + tx + 10, BASE, body)
            L.poly([(cx + tx - 13, BASE - th), (cx + tx, BASE - th - 26), (cx + tx + 13, BASE - th)], rgb("2a1a34"))
            for wy in range(BASE - th + 10, BASE - 20, 16):
                L.rect(cx + tx - 2, wy, cx + tx + 2, wy + 6, rgb("ff5a6a") if rng.random() < 0.4 else rgb("ffd08a"))
        L.ellipse(cx - 8, BASE - 110, cx + 8, BASE - 94, rgb("c04aa0"))
    put(im, L)
    L = Layer()
    pine_row(L, rng, BASE + 2, 20, 40, rgb("0a0812"))
    put(im, L)
    ground(im, rgb("08040c"))


def t_desert_rails(im, rng):
    gradient(im, 0, BASE, [rgb("2a1a4a"), rgb("5a2a6a"), rgb("a84a6a"), rgb("e8905a"), rgb("f8c870")])
    stars(im, rng, 50, 70)
    ImageDraw.Draw(im).ellipse((120, 30, 170, 80), fill=rgb("ffe8b0"))
    dunes(im, rng.randrange(999), 150, 50, [rgb("c88a5a"), rgb("a86a4a"), rgb("885040")])
    L = Layer()
    y = BASE - 22
    L.rect(0, y, W - 1, y + 1, rgb("3a2a2a"))
    L.rect(0, y + 5, W - 1, y + 6, rgb("3a2a2a"))
    for x in range(0, W, 8):
        L.rect(x, y - 1, x + 3, y + 7, rgb("5a3a2a"))
    tx = rng.randrange(W)
    for k in range(4):
        cx = tx + k * 48
        L.rect(cx, y - 20, cx + 44, y - 2, rgb("e04a4a") if k == 0 else rgb("d8d8e0"))
        L.rect(cx + 4, y - 16, cx + 40, y - 11, rgb("3a5a9a"))
    particles(im, rng, 80, [rgb("ffe0a0"), rgb("f0c080")], 30, BASE)
    put(im, L)
    ground(im, rgb("5a3a30"))


def t_space_moon(im, rng):
    gradient(im, 0, BASE, [rgb("020208"), rgb("06061a"), rgb("0c0c28")])
    stars(im, rng, 220, BASE)
    d = ImageDraw.Draw(im)
    cx, cy, r = rng.randrange(120, W - 120), 60, 34
    d.ellipse((cx - r - 4, cy - r - 4, cx + r + 4, cy + r + 4), fill=rgb("1a3a6a"))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgb("3a7ad0"))
    for _ in range(6):
        bx, by, br = cx + rng.randrange(-20, 20), cy + rng.randrange(-20, 20), rng.randrange(6, 12)
        d.ellipse((bx - br, by - br, bx + br, by + br), fill=rgb("4a9a5a"))
    d.chord((cx - r, cy - r, cx + r, cy + r), 290, 70, fill=rgb("12284a"))   # nửa tối của Trái Đất
    mountains(im, rng.randrange(999), 176, 30, rgb("7a7a88"), rgb("a0a0ac"), ks=(1, 2, 4))
    L = Layer()
    for x in range(40, W, 230):
        L.ellipse(x, BASE - 46, x + 60, BASE + 10, rgb("c8ccd8"))
        L.rect(x + 26, BASE - 70, x + 30, BASE - 40, rgb("9aa0b0"))
        L.px(x + 28, BASE - 71, (255, 80, 80, 255))
        L.rect(x + 12, BASE - 30, x + 48, BASE - 26, rgb("7ad0ff"))
    put(im, L)
    d2 = ImageDraw.Draw(im)
    for _ in range(14):
        x, y, r2 = rng.randrange(W), rng.randrange(178, BASE), rng.randrange(3, 8)
        d2.ellipse((x - r2, y - r2 // 2, x + r2, y + r2 // 2), fill=rgb("6a6a78"))
    ground(im, rgb("5a5a66"))


def t_school(im, rng):
    gradient(im, 0, BASE, [rgb("4a88d8"), rgb("7aa8e4"), rgb("b0cfee"), rgb("e0ecf4")])
    clouds(im, rng, 8)
    L = Layer()
    for sx in range(60, W, 400):
        L.rect(sx, BASE - 80, sx + 260, BASE, rgb("e8e0d0"))
        L.rect(sx, BASE - 82, sx + 260, BASE - 80, rgb("a89880"))
        for fx in range(sx + 8, sx + 252, 16):
            for fy in (BASE - 70, BASE - 48, BASE - 26):
                L.rect(fx, fy, fx + 10, fy + 12, rgb("8ab8e0"))
        L.rect(sx + 110, BASE - 110, sx + 150, BASE - 80, rgb("e8e0d0"))
        L.ellipse(sx + 118, BASE - 104, sx + 142, BASE - 86, rgb("ffffff"))
        L.line([(sx + 130, BASE - 95), (sx + 130, BASE - 101)], rgb("2a2a2a"))
        L.line([(sx + 130, BASE - 95), (sx + 135, BASE - 95)], rgb("2a2a2a"))
    put(im, L)
    L = Layer()
    round_trees(L, rng, BASE + 2, 26, 44, rgb("f4b0c8"), rgb("5a3a30"), (50, 110), shade=rgb("e890b0"))
    put(im, L)
    particles(im, rng, 70, [rgb("ffc8dc"), rgb("fff0f4")], 40, BASE)
    ground(im, rgb("b89a78"))


def t_underworld(im, rng):
    gradient(im, 0, BASE, [rgb("0a0418"), rgb("1a0a34"), rgb("2e1250"), rgb("4a1a6a")])
    stars(im, rng, 60, BASE, colors=((200, 150, 255), (255, 200, 255), (150, 200, 255)))
    for _ in range(4):
        magic_circle(im, rng.randrange(W), rng.randrange(40, 150), rng.randrange(30, 60), rgb("c080ff"))
    L = Layer()
    floating_rocks(L, rng, 14, rgb("2a1a3a"), rgb("6a4a8a"))
    put(im, L)
    mountains(im, rng.randrange(999), 178, 26, rgb("1a0e28"), rgb("5a3a7a"))
    ground(im, rgb("100818"))


def t_helheim(im, rng):
    gradient(im, 0, BASE, [rgb("0e1a14"), rgb("1a2e20"), rgb("2a4a2c"), rgb("3a5a30")])
    L = Layer()
    for _ in range(40):
        x = rng.randrange(W)
        pts = [(x + 8 * math.sin(k * 0.6 + x), k * 10) for k in range(0, 22)]
        L.line(pts, rgb("2a5a2a"), 2)
    for _ in range(26):
        x, y = rng.randrange(W), rng.randrange(20, 180)
        L.ellipse(x - 6, y - 6, x + 6, y + 6, rgb("6a2a8a"))
        L.px(x - 2, y - 2, rgb("e0a0ff"))
        L.rect(x, y - 10, x, y - 6, rgb("3a6a2a"))
    put(im, L)
    L = Layer()
    round_trees(L, rng, BASE + 4, 50, 90, rgb("2e5a2a"), rgb("1a2a1a"), (16, 30), shade=rgb("244a22"))
    put(im, L)
    particles(im, rng, 50, [rgb("c0ff80"), rgb("a0e060")], 40, BASE)
    ground(im, rgb("10180e"))


def t_race_city(im, rng):
    gradient(im, 0, BASE, [rgb("08061a"), rgb("140e30"), rgb("24164a"), rgb("3a1e5a")])
    stars(im, rng, 50, 70)
    L = Layer()
    skyline(L, rng, BASE - 20, 40, 110, 14, 30, rgb("1a1434"), rgb("ff7a9a"), lit=0.25)
    put(im, L)
    d = ImageDraw.Draw(im)
    for _ in range(40):
        y = rng.randrange(150, BASE)
        x = rng.randrange(W)
        c = rng.choice([rgb("ff3a4a"), rgb("ffe070"), rgb("5af0ff")])
        d.line((x, y, x + rng.randrange(40, 140), y), fill=c)
    L = Layer()
    L.rect(0, BASE - 16, W - 1, BASE - 14, rgb("e8e8f0"))
    for x in range(0, W, 20):
        L.rect(x, BASE - 16, x + 9, BASE - 14, rgb("e03a3a"))
    put(im, L)
    ground(im, rgb("0c0a18"))


def t_temple_ghost(im, rng):
    gradient(im, 0, BASE, [rgb("06080e"), rgb("0e1420"), rgb("182234"), rgb("243044")])
    stars(im, rng, 50, 80)
    moon(im, rng.randrange(80, W - 80), 44, 16, rgb("e0f0ff"))
    L = Layer()
    pine_row(L, rng, BASE - 10, 30, 60, rgb("0c1018"), (10, 20))
    put(im, L)
    L = Layer()
    for x in range(100, W, 330):
        for k, (w, y) in enumerate(((120, BASE - 40), (90, BASE - 72), (60, BASE - 98))):
            L.rect(x - w // 2 + 10, y, x + w // 2 - 10, y + 32 if k == 0 else y + 26, rgb("2a1e1e"))
            L.poly([(x - w // 2 - 6, y), (x, y - 16), (x + w // 2 + 6, y)], rgb("1a1a22"))
        L.rect(x - 1, BASE - 128, x + 1, BASE - 108, rgb("6a5a3a"))
    for _ in range(30):
        x = rng.randrange(W)
        h = rng.randrange(10, 20)
        L.rect(x, BASE - h, x + 7, BASE, rgb("5a5a66"))
        L.rect(x, BASE - h, x + 7, BASE - h, rgb("8a8a96"))
    put(im, L)
    d = ImageDraw.Draw(im)
    for _ in range(18):
        x, y = rng.randrange(W), rng.randrange(60, 180)
        d.ellipse((x - 5, y - 5, x + 5, y + 5), fill=rgb("3a8aa0"))
        d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=rgb("a0f0ff"))
        d.line((x, y + 5, x - 2, y + 12), fill=rgb("3a8aa0"))
    ground(im, rgb("0a0c12"))


def t_game_world(im, rng):
    gradient(im, 0, BASE, [rgb("4a7ae8"), rgb("5a8af0"), rgb("7aa4f4")])
    d = ImageDraw.Draw(im)
    for _ in range(9):
        x, y = rng.randrange(W), rng.randrange(14, 90)
        for k in range(3):
            d.rectangle((x + k * 10, y - (6 if k == 1 else 0), x + k * 10 + 14, y + 8), fill=rgb("ffffff"))
    L = Layer()
    x = 0
    while x < W:
        h = rng.randrange(2, 7) * 12
        w = rng.randrange(2, 5) * 12
        for yy in range(BASE - h, BASE, 12):
            for xx in range(x, x + w, 12):
                L.rect(xx, yy, xx + 11, yy + 11, rgb("c8602a"))
                L.rect(xx, yy, xx + 11, yy, rgb("f0a060"))
                L.rect(xx + 5, yy + 1, xx + 5, yy + 5, rgb("7a3a18"))
        if rng.random() < 0.5:
            qy = BASE - h - 40
            L.rect(x + 12, qy, x + 23, qy + 11, rgb("f8c030"))
            L.rect(x + 17, qy + 3, x + 18, qy + 8, rgb("7a4a10"))
        x += w + rng.randrange(20, 70)
    for x in range(40, W, 180):
        L.rect(x, BASE - 34, x + 22, BASE, rgb("2aa84a"))
        L.rect(x - 3, BASE - 40, x + 25, BASE - 34, rgb("3ac85a"))
    for _ in range(14):
        cx, cy = rng.randrange(W), rng.randrange(90, 170)
        L.ellipse(cx - 3, cy - 4, cx + 3, cy + 4, rgb("ffd84a"))
    put(im, L)
    ground(im, rgb("6a3a1a"))


def t_hospital(im, rng):
    gradient(im, 0, BASE, [rgb("4a88d0"), rgb("7aa8de"), rgb("b8d4ec"), rgb("e4eef4")])
    clouds(im, rng, 8)
    L = Layer()
    skyline(L, rng, BASE - 4, 30, 80, 16, 30, rgb("8aa0b8"), rgb("d8ecff"), lit=0.4)
    put(im, L)
    L = Layer()
    for hx in range(120, W, 420):
        L.rect(hx, BASE - 130, hx + 170, BASE, rgb("f0f2f4"))
        L.rect(hx + 170, BASE - 90, hx + 240, BASE, rgb("e0e4e8"))
        for fy in range(BASE - 122, BASE - 8, 14):
            for fx in range(hx + 8, hx + 164, 14):
                L.rect(fx, fy, fx + 8, fy + 7, rgb("8ac0e0"))
        L.rect(hx + 72, BASE - 160, hx + 98, BASE - 130, rgb("f0f2f4"))
        L.rect(hx + 81, BASE - 156, hx + 89, BASE - 136, rgb("2ab04a"))
        L.rect(hx + 75, BASE - 150, hx + 95, BASE - 142, rgb("2ab04a"))
    put(im, L)
    L = Layer()
    round_trees(L, rng, BASE + 2, 22, 36, rgb("3a8a4a"), rgb("4a3a2a"), (40, 80))
    put(im, L)
    ground(im, rgb("6a7a80"))


def t_sky_wall(im, rng):
    gradient(im, 0, BASE, [rgb("1a2a4a"), rgb("3a4a6a"), rgb("7a7a8a"), rgb("c8a888")])
    L = Layer()
    skyline(L, rng, BASE, 30, 90, 14, 30, rgb("3a4458"), rgb("ffd890"), lit=0.3)
    put(im, L)
    L = Layer()
    wx = rng.randrange(W)
    for x in range(wx, wx + 60):
        top = 20 + int(6 * math.sin(x * 0.3))
        L.rect(x, top, x, BASE, rgb("5a5a68") if (x - wx) % 12 else rgb("4a4a58"))
    L.rect(wx, 20, wx + 60, 24, rgb("8a8a98"))
    tx = (wx + 400) % W
    L.rect(tx - 6, 30, tx + 6, BASE, rgb("2a3448"))
    L.poly([(tx - 14, 40), (tx, 10), (tx + 14, 40)], rgb("3a4460"))
    L.rect(tx - 10, 60, tx + 10, 64, rgb("7ad0ff"))
    put(im, L)
    ground(im, rgb("1a1e28"))


def t_clock_tower(im, rng):
    gradient(im, 0, BASE, [rgb("1a1030"), rgb("3a2050"), rgb("7a3a6a"), rgb("d87a6a")])
    stars(im, rng, 40, 60)
    L = Layer()
    for _ in range(7):
        gear(L, rng.randrange(W), rng.randrange(30, 150), rng.randrange(10, 26), rgb("8a6a3a"), angle=rng.random())
    put(im, L)
    L = Layer()
    skyline(L, rng, BASE, 30, 80, 14, 30, rgb("2a1e34"), rgb("ffd890"), lit=0.3)
    cx = rng.randrange(150, W - 150)
    L.rect(cx - 22, BASE - 170, cx + 22, BASE, rgb("3a2a3a"))
    L.poly([(cx - 28, BASE - 170), (cx, BASE - 205), (cx + 28, BASE - 170)], rgb("2a1e2a"))
    L.ellipse(cx - 18, BASE - 160, cx + 18, BASE - 124, rgb("f4e8c8"))
    L.line([(cx, BASE - 142), (cx, BASE - 156)], rgb("2a1a1a"), 2)
    L.line([(cx, BASE - 142), (cx + 10, BASE - 138)], rgb("2a1a1a"), 2)
    put(im, L)
    ground(im, rgb("140c18"))


def t_cyber_city(im, rng):
    gradient(im, 0, BASE, [rgb("020a14"), rgb("061a2a"), rgb("0a2a3a"), rgb("104050")])
    d = ImageDraw.Draw(im)
    for k in range(0, W, 40):
        d.line((k, 0, k + (k - W / 2) * 0.3, BASE), fill=rgb("0e3a4a"))
    for y in range(10, BASE, 18):
        d.line((0, y, W, y), fill=rgb("0c3040"))
    d.ellipse((600, 30, 624, 54), fill=rgb("e0f0ff"))
    d.line((580, 42, 644, 42), fill=rgb("7ad0ff"))
    L = Layer()
    skyline(L, rng, BASE, 60, 150, 14, 28, rgb("0a1c28"), rgb("5affd8"), lit=0.3, win=(1, 3, 3, 5))
    put(im, L)
    for _ in range(10):
        x, y = rng.randrange(W), rng.randrange(40, 150)
        w, h = rng.randrange(20, 50), rng.randrange(12, 26)
        over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(over).rectangle((x, y, x + w, y + h), fill=(90, 255, 220, 50), outline=(150, 255, 230, 160))
        im.alpha_composite(over)
    ground(im, rgb("041018"))


def t_library(im, rng):
    gradient(im, 0, H, [rgb("1a100c"), rgb("2a1a12"), rgb("3a2418")])
    L = Layer()
    spines = [rgb("8a2a2a"), rgb("2a4a8a"), rgb("2a6a3a"), rgb("8a6a2a"), rgb("5a2a6a"), rgb("a88a5a")]
    for sx in range(0, W, 120):
        L.rect(sx, 10, sx + 110, BASE, rgb("4a2e1e"))
        for sy in range(20, BASE - 10, 30):
            L.rect(sx + 4, sy + 24, sx + 106, sy + 27, rgb("2a1a10"))
            x = sx + 6
            while x < sx + 104:
                w = rng.randrange(4, 8)
                h = rng.randrange(16, 24)
                L.rect(x, sy + 24 - h, x + w - 1, sy + 23, rng.choice(spines))
                x += w + (1 if rng.random() < 0.3 else 0)
        L.rect(sx + 110, 0, sx + 119, H, rgb("2a1a10"))
    put(im, L)
    d = ImageDraw.Draw(im)
    for _ in range(10):
        x, y = rng.randrange(W), rng.randrange(20, 150)
        d.polygon([(x, y), (x + 10, y - 4), (x + 20, y), (x + 10, y + 3)], fill=rgb("f0e8d0"))
        d.line((x + 10, y - 4, x + 10, y + 3), fill=rgb("a89878"))
    particles(im, rng, 60, [rgb("ffe8a0"), rgb("fff4d0")], 10, BASE)
    ground(im, rgb("1a100a"))


def t_book_world(im, rng):
    gradient(im, 0, BASE, [rgb("f0d8a8"), rgb("f4e4c0"), rgb("f8f0dc")])
    d = ImageDraw.Draw(im)
    for _ in range(40):
        y = rng.randrange(10, 150)
        x = rng.randrange(W)
        d.line((x, y, x + rng.randrange(30, 80), y), fill=rgb("c8b890"))
    L = Layer()
    for x in range(0, W, 200):
        L.poly([(x, BASE), (x + 100, BASE - 60), (x + 200, BASE)], rgb("e8dcc0"))
        L.line([(x + 100, BASE - 60), (x + 100, BASE)], rgb("a89878"))
    cx = rng.randrange(100, W - 100)
    for tx, th in ((-30, 70), (0, 100), (30, 70)):
        L.rect(cx + tx - 10, BASE - th, cx + tx + 10, BASE - 40, rgb("b8a8d8"))
        L.poly([(cx + tx - 13, BASE - th), (cx + tx, BASE - th - 22), (cx + tx + 13, BASE - th)], rgb("7a5aa8"))
    put(im, L)
    for _ in range(8):
        x, y = rng.randrange(W), rng.randrange(20, 120)
        d.polygon([(x, y), (x + 8, y + 3), (x + 16, y)], fill=rgb("ffffff"))
    ground(im, rgb("c8b890"))


def t_arena(im, rng):
    gradient(im, 0, BASE, [rgb("0a0818"), rgb("181030"), rgb("2a1848")])
    spotlights(im, rng, 8, rgb("fff0c0"))
    L = Layer()
    for row in range(6):
        y = 80 + row * 16
        L.rect(0, y, W - 1, y + 12, rgb("241a38") if row % 2 else rgb("2c2044"))
        for x in range(rng.randrange(0, 6), W, 6):
            if rng.random() < 0.7:
                L.rect(x, y + 3, x + 2, y + 6, rng.choice([rgb("ff6a8a"), rgb("6ad0ff"), rgb("ffe06a"), rgb("e0e0f0")]))
    for sx in range(80, W, 400):
        L.rect(sx, 14, sx + 120, 66, rgb("101018"))
        L.rect(sx + 4, 18, sx + 116, 62, rgb("e84a4a"))
        L.ellipse(sx + 44, 24, sx + 76, 56, rgb("ffffff"))
    put(im, L)
    ground(im, rgb("100a1a"))


def t_academy(im, rng):
    gradient(im, 0, BASE, [rgb("101a3a"), rgb("1e2a5a"), rgb("3a3a7a"), rgb("6a4a8a")])
    stars(im, rng, 80, 90)
    for _ in range(3):
        magic_circle(im, rng.randrange(W), rng.randrange(40, 120), rng.randrange(26, 44), rgb("ffd070"))
    L = Layer()
    for cx in range(100, W, 300):
        L.rect(cx - 70, BASE - 70, cx + 70, BASE, rgb("3a3048"))
        for tx, th in ((-70, 120), (0, 150), (70, 110)):
            L.rect(cx + tx - 12, BASE - th, cx + tx + 12, BASE, rgb("3a3048"))
            L.poly([(cx + tx - 15, BASE - th), (cx + tx, BASE - th - 30), (cx + tx + 15, BASE - th)], rgb("5a3a6a"))
            for wy in range(BASE - th + 12, BASE - 10, 18):
                L.rect(cx + tx - 3, wy, cx + tx + 3, wy + 8, rgb("ffd88a"))
    put(im, L)
    L = Layer()
    round_trees(L, rng, BASE + 2, 20, 34, rgb("1e2a3a"), rgb("141a24"), (30, 60))
    put(im, L)
    ground(im, rgb("141020"))


def t_candy_factory(im, rng):
    gradient(im, 0, BASE, [rgb("f8b0d0"), rgb("fcc8dc"), rgb("fde0ec"), rgb("fff0f6")])
    L = Layer()
    for x in range(20, W, 110):
        L.rect(x, BASE - 150, x + 16, BASE, rgb("f0f0f8"))
        for y in range(BASE - 150, BASE, 12):
            L.poly([(x, y), (x + 16, y + 6), (x + 16, y + 10), (x, y + 4)], rgb("e84a6a"))
        L.ellipse(x - 12, BASE - 170, x + 28, BASE - 140, rng.choice([rgb("ff7ab0"), rgb("7ad0ff"), rgb("ffe07a")]))
    put(im, L)
    L = Layer()
    x = 0
    while x < W:
        w = rng.randrange(60, 110)
        h = rng.randrange(40, 70)
        L.rect(x, BASE - h, x + w, BASE, rgb("c86a8a"))
        L.rect(x, BASE - h, x + w, BASE - h + 6, rgb("f8f0e8"))
        for k in range(x + 6, x + w - 6, 10):
            L.ellipse(k, BASE - h - 3, k + 8, BASE - h + 5, rgb("f8f0e8"))
        x += w + rng.randrange(20, 50)
    L.rect(0, BASE - 24, W - 1, BASE - 18, rgb("5a5a6a"))
    for x in range(0, W, 14):
        L.ellipse(x, BASE - 32, x + 8, BASE - 24, rng.choice([rgb("ff5a8a"), rgb("5ad0ff"), rgb("ffd05a"), rgb("8af07a")]))
    put(im, L)
    ground(im, rgb("8a4a6a"))


def t_dreamscape(im, rng):
    gradient(im, 0, BASE, [rgb("2a2a6a"), rgb("5a4a9a"), rgb("a07ac0"), rgb("f0b0d0"), rgb("fce0e0")])
    stars(im, rng, 90, 120, colors=((255, 240, 255), (220, 220, 255), (255, 220, 240)))
    d = ImageDraw.Draw(im)
    for _ in range(3):
        cx, cy = rng.randrange(W), rng.randrange(40, 120)
        for k in range(30):
            a = k * 0.4
            r = 2 + k * 0.9
            d.point((cx + math.cos(a) * r, cy + math.sin(a) * r * 0.6), fill=rgb("fff0ff"))
    L = Layer()
    floating_rocks(L, rng, 9, rgb("6a5a9a"), rgb("a0e0a0"), (50, 150))
    for _ in range(6):
        x, y = rng.randrange(W), rng.randrange(40, 150)
        L.rect(x, y - 22, x + 12, y, rgb("f4e0b0"))
        L.rect(x + 2, y - 20, x + 10, y, rgb("8a5a3a"))
        L.px(x + 8, y - 10, rgb("ffe070"))
    put(im, L)
    for _ in range(5):
        cx, cy = rng.randrange(W), rng.randrange(20, 160)
        d.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), outline=rgb("ffffff"))
        d.line((cx, cy, cx, cy - 6), fill=rgb("ffffff"))
        d.line((cx, cy, cx + 4, cy), fill=rgb("ffffff"))
    ground(im, rgb("4a3a6a"))


def t_boss(im, rng, sky, ruins, glow, parts, extra=None, after=None):
    gradient(im, 0, BASE, sky)
    if extra:
        extra(im, rng)
    mountains(im, rng.randrange(999), 160, 36, dark(sky[-1], 0.4))
    L = Layer()
    jagged_ruins(L, rng, BASE, 40, 110, ruins, glow=glow)
    put(im, L)
    if after:
        after(im, rng)
    particles(im, rng, 160, parts, 10, BASE)
    ground(im, dark(ruins, 0.3))


def _rift(im, rng):
    d = ImageDraw.Draw(im)
    x, y = rng.randrange(200, 600), 0
    pts = [(x, y)]
    while y < 160:
        x += rng.randrange(-14, 15)
        y += rng.randrange(10, 18)
        pts.append((x, y))
    d.line(pts, fill=rgb("ff80ff"), width=5)
    d.line(pts, fill=rgb("ffffff"), width=1)


def _storm(im, rng):
    clouds(im, rng, 14, rgb("2a3040"), rgb("1a2030"), y1=90)
    d = ImageDraw.Draw(im)
    x, y = rng.randrange(100, 700), 0
    pts = [(x, y)]
    while y < 150:
        x += rng.randrange(-10, 11)
        y += rng.randrange(8, 16)
        pts.append((x, y))
    d.line(pts, fill=rgb("c0e0ff"), width=3)
    d.line(pts, fill=rgb("ffffff"), width=1)
    for _ in range(360):
        rx, ry = rng.randrange(W), rng.randrange(4, BASE)
        d.line((rx, ry, rx - 2, ry + 5), fill=rgb("5a6a80"))


def _gold(im, rng):
    rays(im, 400, 40, rgb("fff0a0"))
    ImageDraw.Draw(im).ellipse((370, 10, 430, 70), fill=rgb("fff8d0"))


def _ice(im, rng):
    d = ImageDraw.Draw(im)
    for _ in range(20):
        x = rng.randrange(W)
        h = rng.randrange(30, 90)
        d.polygon([(x - 8, BASE), (x, BASE - h), (x + 8, BASE)], fill=rgb("a8e0f8"))
        d.line((x, BASE - h, x - 3, BASE), fill=rgb("ffffff"))


def _dark_moon(im, rng):
    moon(im, rng.randrange(100, W - 100), 50, 20, rgb("c8c8d8"))
    fog(im, 60, 180, rgb("3a3a4a"), 0.35)


THEMED = {
    "city_day": t_city_day, "city_dusk": t_city_dusk, "city_night": t_city_night, "suburb": t_suburb,
    "coast": t_coast, "mountain_dawn": t_mountain_dawn,
    "forest_day": lambda im, rng: t_forest(im, rng, False), "forest_night": lambda im, rng: t_forest(im, rng, True),
    "shrine": t_shrine, "snow_mountain": t_snow, "mirror_city": t_mirror_city, "castle_night": t_castle_night,
    "desert_rails": t_desert_rails, "space_moon": t_space_moon, "school": t_school, "underworld": t_underworld,
    "helheim": t_helheim, "race_city": t_race_city, "temple_ghost": t_temple_ghost, "game_world": t_game_world,
    "hospital": t_hospital, "sky_wall": t_sky_wall, "clock_tower": t_clock_tower, "cyber_city": t_cyber_city,
    "library": t_library, "book_world": t_book_world, "arena": t_arena, "academy": t_academy,
    "candy_factory": t_candy_factory, "dreamscape": t_dreamscape,
    "boss_red": lambda im, rng: t_boss(im, rng, [rgb("1a0406"), rgb("400a0e"), rgb("7a1812"), rgb("c04018")],
                                       rgb("1e0606"), rgb("ff8a30"), [rgb("ffb040"), rgb("ff6a20")]),
    "boss_purple": lambda im, rng: t_boss(im, rng, [rgb("0a0418"), rgb("200a3a"), rgb("3a1260"), rgb("6a2a8a")],
                                          rgb("12081e"), rgb("d080ff"), [rgb("e0a0ff"), rgb("a060ff")], _rift),
    "boss_dark": lambda im, rng: t_boss(im, rng, [rgb("040408"), rgb("0a0a12"), rgb("14141e"), rgb("1e1e2a")],
                                        rgb("08080e"), rgb("8a8aa0"), [rgb("5a5a6a")], _dark_moon),
    "boss_storm": lambda im, rng: t_boss(im, rng, [rgb("0a1014"), rgb("141e26"), rgb("1e2c36"), rgb("2a3a44")],
                                         rgb("0c1216"), rgb("7affc0"), [rgb("4a5a6a")], _storm),
    "boss_gold": lambda im, rng: t_boss(im, rng, [rgb("3a2a10"), rgb("7a5a1a"), rgb("c89a3a"), rgb("f0d08a")],
                                        rgb("2a1e10"), rgb("fff0a0"), [rgb("fff0b0"), rgb("ffe070")], _gold),
    "boss_ice": lambda im, rng: t_boss(im, rng, [rgb("0a1a2a"), rgb("1a3a5a"), rgb("3a6a8a"), rgb("8ab8d0")],
                                       rgb("1a2a3a"), rgb("a0f0ff"), [rgb("ffffff"), rgb("c0e8ff")], None, _ice),
}


WORLDS_DIR = os.path.join(ROOT, "scripts", "data", "worlds")


def world_backgrounds():
    """Các cặp (tên ảnh, kiểu nền) khai báo trong file thế giới: "bg": "agito_1", "bg_theme": "suburb"."""
    import re
    out = {}
    for f in sorted(os.listdir(WORLDS_DIR)):
        if f.endswith(".gd"):
            text = open(os.path.join(WORLDS_DIR, f), encoding="utf-8").read()
            for name, theme in re.findall(r'"bg":\s*"(\w+)",\s*"bg_theme":\s*"(\w+)"', text):
                out[name] = theme
    return out


def seed_of(name):
    return sum((i + 1) * ord(ch) for i, ch in enumerate(name))


def main():
    os.makedirs(OUT, exist_ok=True)
    jobs = {name: name for name in list(THEMES)[:14]}   # nền riêng: tên ảnh = tên kiểu
    jobs.update(world_backgrounds())
    want = sys.argv[1:]
    if want:
        jobs = {k: v for k, v in jobs.items() if k in want or v in want}
    bad = [f"{k} ({v})" for k, v in jobs.items() if v not in THEMES]
    if bad:
        sys.exit("Kiểu nền không có trong THEMES: " + ", ".join(bad))
    for name, theme in jobs.items():
        im = Image.new("RGBA", (W, H), (0, 0, 0, 255))
        legacy = list(THEMES)[:14]
        seed = 1000 + legacy.index(name) if name in legacy else seed_of(name)   # nền cũ giữ nguyên hình
        THEMES[theme](im, random.Random(seed))
        im.save(os.path.join(OUT, name + ".png"))
    print("Đã vẽ %d nền vào %s" % (len(jobs), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
