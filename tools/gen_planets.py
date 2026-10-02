#!/usr/bin/env python3
"""
Vẽ các Trái Đất pixel art tự quay cho màn chọn thế giới và bản đồ Chuỗi Phong Ấn:

    python3 tools/gen_planets.py

  art/story/planets_<N>.png   N = 48 · 32 · 24 (đường kính, px). Mỗi hàng một Trái Đất, mỗi cột một khung quay:
      hàng 0..26 = 27 thế giới theo thứ tự WorldData.FILES, hàng 27 = Tokyo 2026 (Trái Đất nhà).
      FRAMES khung = một vòng quay trọn, lặp liền mạch (game chọn khung theo thời gian, xem scripts/ui/planet.gd).

Mỗi Trái Đất một bản đồ lục địa riêng (nhiễu fbm 3D trên mặt cầu, hạt giống theo hàng): biển sâu / nông, bãi cát,
đồng cỏ, rừng, núi, tuyết, băng ở hai cực, mây trôi nhanh gấp đôi mặt đất. Ánh sáng từ trên trái, chia vài bậc
và trộn bằng ma trận Bayer cho ra chất pixel; mặt tối ngả xanh đêm, viền phía sáng có quầng khí quyển.
Hành tinh nhỏ dùng ít tầng nhiễu hơn để không lấm tấm.
"""
import math
import os
from multiprocessing import Pool

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art", "story")
WORLDS = 27
ROWS = WORLDS + 1          # + Tokyo 2026
FRAMES = 64
SIZES = {48: 5, 32: 4, 24: 3}   # đường kính → số tầng nhiễu
LIGHT = (-0.85, -0.38, 0.38)     # hướng sáng: trên trái, hướng về phía người xem

DEEP = (18, 44, 108)
OCEAN = (30, 78, 160)
SHALLOW = (48, 126, 196)
SAND = (214, 196, 128)
GRASS = (86, 164, 70)
FOREST = (44, 112, 58)
HILLS = (126, 120, 72)
MOUNTAIN = (128, 100, 78)
SNOW = (236, 240, 248)
ICE = (214, 232, 248)
CLOUD = (248, 250, 255)
NIGHT = (10, 14, 40)
ATMO = (120, 190, 255)

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


# --- Nhiễu ---------------------------------------------------------------------

def _hash(x, y, z, seed):
    h = (x * 374761393 + y * 668265263 + z * 2147483647 + seed * 144269504) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF) / 65535.0


def _smooth(t):
    return t * t * (3.0 - 2.0 * t)


def value_noise(x, y, z, seed):
    xi, yi, zi = math.floor(x), math.floor(y), math.floor(z)
    xf, yf, zf = _smooth(x - xi), _smooth(y - yi), _smooth(z - zi)

    def lerp(a, b, t):
        return a + (b - a) * t

    c = [_hash(xi + dx, yi + dy, zi + dz, seed) for dz in (0, 1) for dy in (0, 1) for dx in (0, 1)]
    x00 = lerp(c[0], c[1], xf)
    x10 = lerp(c[2], c[3], xf)
    x01 = lerp(c[4], c[5], xf)
    x11 = lerp(c[6], c[7], xf)
    return lerp(lerp(x00, x10, yf), lerp(x01, x11, yf), zf)


def fbm(p, seed, octaves, freq):
    total, amp, norm = 0.0, 1.0, 0.0
    for o in range(octaves):
        total += amp * value_noise(p[0] * freq, p[1] * freq, p[2] * freq, seed + o * 31)
        norm += amp
        amp *= 0.5
        freq *= 2.0
    return total / norm


# --- Bản đồ bề mặt (kinh độ × vĩ độ) -------------------------------------------

def sphere_point(lon, lat):
    return (math.cos(lat) * math.sin(lon), math.sin(lat), math.cos(lat) * math.cos(lon))


def surface_map(row, size, octaves):
    """Trả về (W, H, màu mặt đất [H][W], độ phủ mây [H][W])."""
    w, h = int(size * 2.75), int(size * 1.4)
    seed = 1000 + row * 97
    points = []
    heights = []
    for j in range(h):
        lat = (0.5 - (j + 0.5) / h) * math.pi
        for i in range(w):
            p = sphere_point((i + 0.5) / w * math.tau, lat)
            points.append((lat, p))
            heights.append(fbm(p, seed, octaves, 1.6))
    # Ngưỡng địa hình theo phân vị để mọi Trái Đất cùng tỉ lệ biển / đất; lượng đất hơi khác nhau theo hàng
    ranked = sorted(heights)
    sea_q = 0.58 + ((row * 37) % 7 - 3) * 0.02

    def q(frac):
        return ranked[min(len(ranked) - 1, int(frac * len(ranked)))]

    deep, ocean, sea = q(sea_q * 0.55), q(sea_q * 0.85), q(sea_q)
    land = 1.0 - sea_q
    sand, grass, hills, mountain = (q(sea_q + land * k) for k in (0.06, 0.78, 0.9, 0.97))
    colors = [[None] * w for _ in range(h)]
    clouds = [[0.0] * w for _ in range(h)]
    for k, ((lat, p), e) in enumerate(zip(points, heights)):
        j, i = divmod(k, w)
        # Hai cực: băng có mép răng cưa theo nhiễu
        polar = abs(math.sin(lat)) + (fbm(p, seed + 7, 2, 4.0) - 0.5) * 0.2
        if polar > 0.9:
            c = ICE
        elif e < deep:
            c = DEEP
        elif e < ocean:
            c = OCEAN
        elif e < sea:
            c = SHALLOW
        elif e < sand:
            c = SAND
        elif e < grass:
            c = GRASS if fbm(p, seed + 3, 2, 4.0) > 0.47 else FOREST
        elif e < hills:
            c = HILLS
        elif e < mountain:
            c = MOUNTAIN
        else:
            c = SNOW
        colors[j][i] = c
        # Mây kéo dài theo vĩ tuyến: nén trục dọc của nhiễu cho ra các dải mảnh
        cl = fbm((p[0], p[1] * 2.0, p[2]), seed + 500, max(2, octaves - 1), 2.4)
        clouds[j][i] = max(0.0, (cl - 0.57) / 0.13)
    return w, h, colors, clouds


# --- Vẽ khung -------------------------------------------------------------------

def mix(a, b, t):
    return tuple(round(a[k] + (b[k] - a[k]) * t) for k in range(3))


def render_row(args):
    row, size, octaves = args
    w, h, colors, clouds = surface_map(row, size, octaves)
    strip = Image.new("RGBA", (size * FRAMES, size), (0, 0, 0, 0))
    px = strip.load()
    r = size / 2.0
    ll = math.sqrt(sum(c * c for c in LIGHT))
    light = tuple(c / ll for c in LIGHT)
    # Hình học mặt cầu không đổi giữa các khung: tính một lần
    geo = []
    for y in range(size):
        for x in range(size):
            dx, dy = (x + 0.5 - r) / r, (y + 0.5 - r) / r
            d2 = dx * dx + dy * dy
            if d2 > 1.0:
                continue
            z = math.sqrt(1.0 - d2)
            lon = math.atan2(dx, z)
            lat = math.asin(-dy)
            lam = dx * light[0] + dy * light[1] + z * light[2]
            # Bậc sáng có trộn Bayer: 0 = đêm … 4 = chỗ sáng nhất
            v = max(0.0, lam + 0.05) * 4.4 + (BAYER[y % 4][x % 4] / 16.0 - 0.5) * 0.7
            band = max(0, min(4, int(v + 0.3)))
            rim = d2 > (1.0 - 2.2 / size) ** 2 and lam > 0.05
            j = min(h - 1, int((0.5 - lat / math.pi) * h))
            geo.append((x, y, lon, j, band, rim))
    shade = [0.0, 0.38, 0.62, 0.85, 1.0]
    for f in range(FRAMES):
        rot = f / FRAMES * math.tau
        for x, y, lon, j, band, rim in geo:
            i = int(((lon + rot) / math.tau) % 1.0 * w) % w
            c = colors[j][i]
            ci = int(((lon + rot * 2.0) / math.tau) % 1.0 * w) % w
            cl = clouds[j][ci]
            if cl > 0.0:
                # Mây: lớp dày trắng đặc, mép mỏng trộn Bayer cho ra đốm thưa
                if cl > 0.75:
                    c = CLOUD
                elif cl > BAYER[y % 4][x % 4] / 16.0 + 0.2:
                    c = mix(c, CLOUD, 0.6)
            if band == 0:
                out = mix(c, NIGHT, 0.86)
            else:
                out = mix(NIGHT, c, shade[band])
                if band == 4:
                    out = mix(out, (255, 255, 255), 0.12)
            if rim:
                out = mix(out, ATMO, 0.55)
            px[f * size + x, y] = out + (255,)
    return row, strip


def main():
    jobs = [(row, size, oct_) for size, oct_ in SIZES.items() for row in range(ROWS)]
    sheets = {size: Image.new("RGBA", (size * FRAMES, size * ROWS), (0, 0, 0, 0)) for size in SIZES}
    with Pool() as pool:
        for (row, size, _), (_, strip) in zip(jobs, pool.imap(render_row, jobs)):
            sheets[size].paste(strip, (0, row * size))
    for size, im in sheets.items():
        path = os.path.join(OUT, "planets_%d.png" % size)
        im.save(path, optimize=True)
        print("đã ghi", os.path.relpath(path, ROOT), im.size)


if __name__ == "__main__":
    main()
