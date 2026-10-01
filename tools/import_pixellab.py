#!/usr/bin/env python3
"""
Nhập hình từ PixelLab vào game.

    python3 tools/import_pixellab.py              # dùng các thư mục đã tải trong art/pixellab/
    python3 tools/import_pixellab.py --download   # tải lại từ PixelLab trước (ID trong art/pixellab/characters.json)
    python3 tools/import_pixellab.py --preview D  # thêm GIF xem trước vào thư mục D

Việc script làm:
  1. Đọc animation hướng "east" (quay phải) của từng nhân vật PixelLab. Godot tự lật khi quay trái.
  2. Căn chân chạm cùng một hàng pixel, đặt lại tên animation theo tên code game dùng.
  3. Tạo thêm những gì PixelLab không làm (miễn phí):
       - 4 form Kuuga còn lại: đổi màu từ Mighty (Growing trắng, Dragon xanh, Pegasus lục, Titan tím)
       - Grongi hạng Me (nhanh) và hạng Go (giáp): đổi màu từ Grongi Zu
       - Rider bộ gọn (DATA_RIDERS: Agito, Ryuki, Faiz, Blade, Hibiki, Kabuto): nhảy / cúi / né / tuyệt chiêu từ 5
         animation PixelLab, 3 form còn lại đổi màu hoặc vẽ thêm vũ khí từ form gốc. Blade trở đi làm bằng PixelEngine
         (tools/pixelengine.py pack → art/pixelengine/<tên>/, cùng cấu trúc thư mục PixelLab)
       - quái thế giới sau (EXTRA_ENEMIES): loại nhanh và loại giáp đổi màu từ loại thường
       - cảnh biến hình: ghép frame nhân vật chính → vòng sáng → chớp trắng → Kuuga, mắt lóe sáng
       - né, đổi Rider, vỡ giáp: dùng lại frame của animation gần giống
  4. Ghi sprite sheet + SpriteFrames:
       art/characters/player/*.png   + art/characters/player_frames.tres  (Player/Sprite)
       art/characters/enemies/*.png  + art/characters/enemy_frames.tres   (Enemy/Sprite)
"""
import colorsys
import io
import json
import math
import os
import sys
import urllib.request
import zipfile

from PIL import Image


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(ROOT, "art", "pixellab")
PIXELENGINE_DIR = os.path.join(ROOT, "art", "pixelengine")
OUT_DIR = os.path.join(ROOT, "art", "characters")
RES_DIR = "res://art/characters"
DIRECTION = "east"
WHITE = (255, 255, 255, 255)


# --- Đọc dữ liệu PixelLab -----------------------------------------------------

def download_all():
    ids = json.load(open(os.path.join(SRC_DIR, "characters.json"), encoding="utf-8"))
    for name, cid in ids.items():
        if name.startswith("_"):
            continue
        url = "https://api.pixellab.ai/mcp/characters/%s/download" % cid
        try:
            data = urllib.request.urlopen(url, timeout=60).read()
        except Exception as e:  # nhân vật còn đang tạo animation sẽ trả lỗi 423
            print("  bỏ qua %s: %s" % (name, e))
            continue
        target = os.path.join(SRC_DIR, name)
        os.makedirs(target, exist_ok=True)
        zipfile.ZipFile(io.BytesIO(data)).extractall(target)
        print("  đã tải", name)


class Source:
    """Một nhân vật PixelLab đã giải nén trong art/pixellab/<name>/, hoặc nhân vật PixelEngine trong art/pixelengine/<name>/."""

    def __init__(self, name):
        self.dir = os.path.join(SRC_DIR, name)
        if not os.path.isdir(self.dir):
            self.dir = os.path.join(PIXELENGINE_DIR, name)
        meta = json.load(open(os.path.join(self.dir, "metadata.json"), encoding="utf-8"))
        frames = meta["states"][0]["frames"]
        self.rotation = self._load(frames["rotations"][DIRECTION])
        self.anims = {}
        for anim_name, dirs in frames.get("animations", {}).items():
            if DIRECTION in dirs:
                self.anims[anim_name] = [self._load(p) for p in dirs[DIRECTION]]
        # Hàng pixel chân chạm đất, lấy từ tư thế đứng để mọi animation dùng chung một mốc.
        self.ground = self.rotation.getbbox()[3] - 1
        self.size = self.rotation.size

    def _load(self, rel):
        return Image.open(os.path.join(self.dir, rel)).convert("RGBA")

    def get(self, name, pick=None):
        frames = self.anims.get(name) or [self.rotation]
        return [frames[i] for i in pick] if pick else list(frames)


def align(frames, src, cell):
    """Đặt frame vào ô cell×cell, căn giữa ngang, pixel thấp nhất của TỪNG frame chạm hàng cuối của ô.

    PixelLab vẽ một số tư thế (cúi, ngã, nhảy) lệch khỏi mốc chân của tư thế đứng, nên căn theo mốc cố định
    làm nhân vật lơ lửng. Căn từng frame luôn giữ chân (hoặc thân khi nằm) sát mặt đất; độ cao khi nhảy
    do vật lý trong game lo.
    """
    dx = (cell - src.size[0]) // 2
    out = []
    for fr in frames:
        box = fr.getbbox()
        bottom = box[3] - 1 if box else src.ground
        im = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
        im.paste(fr, (dx, (cell - 1) - bottom), fr)
        out.append(im)
    return out


# --- Đổi màu ------------------------------------------------------------------

def recolor(frames, rule, head=0.22):
    """Áp rule(màu, có_nằm_ở_vùng_đầu) lên từng pixel. Vùng đầu = phần `head` phía trên của nhân vật."""
    out = []
    for fr in frames:
        im = fr.copy()
        px = im.load()
        box = fr.getbbox() or (0, 0, fr.width, fr.height)
        head_limit = box[1] + (box[3] - box[1]) * head
        for y in range(im.height):
            for x in range(im.width):
                c = px[x, y]
                if c[3]:
                    px[x, y] = rule(c, y < head_limit)
        out.append(im)
    return out


def _hsv(c):
    return colorsys.rgb_to_hsv(c[0] / 255.0, c[1] / 255.0, c[2] / 255.0)


def _rgb(h, s, v, a=255):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, max(0.0, min(1.0, s)), max(0.0, min(1.0, v)))
    return (int(r * 255), int(g * 255), int(b * 255), a)


def is_red(c):
    h, s, v = _hsv(c)
    return (h < 0.045 or h > 0.94) and s > 0.45 and v > 0.2


def kuuga_rule(target):
    """Giáp và mắt đỏ của Mighty → màu form khác. Giữ độ sáng để bóng đổ còn nguyên."""
    def rule(c, in_head):
        if not is_red(c):
            return c
        h, s, v = _hsv(c)
        if target == "growing":
            if in_head:                          # mắt Growing màu cam
                return _rgb(0.07, 0.85, min(1.0, v * 1.15), c[3])
            return _rgb(0.62, 0.06, 0.45 + v * 0.55, c[3])   # giáp trắng ánh bạc
        if target == "dragon":
            return _rgb(0.60, s * 0.9, min(1.0, v * 1.1), c[3])
        if target == "pegasus":
            return _rgb(0.36, s * 0.85, min(1.0, v * 1.05), c[3])
        if target == "titan":
            if not in_head and v > 0.75:         # mảng giáp sáng → viền bạc của Titan
                return _rgb(0.7, 0.08, 0.85, c[3])
            return _rgb(0.78, s * 0.8, v, c[3])
        return c
    return rule


def grongi_rule(target):
    """Grongi Zu tím → hạng Me (xanh lục, nhanh) hoặc hạng Go (nâu đồng, có giáp)."""
    def rule(c, _in_head):
        h, s, v = _hsv(c)
        if not (0.68 < h < 0.95 and s > 0.2):    # chỉ đổi phần da tím, giữ vàng/đen
            return c
        if target == "me":
            return _rgb(0.40, s * 0.9, min(1.0, v * 1.1), c[3])
        if target == "go":
            return _rgb(0.08, s * 0.7, min(1.0, v * 1.15), c[3])
        return c
    return rule


def _band(fr, lo, hi):
    """Hàng y từ lo đến hi (tỉ lệ chiều cao nhân vật, 0 = đỉnh đầu)."""
    box = fr.getbbox() or (0, 0, fr.width, fr.height)
    h = box[3] - box[1]
    return box, box[1] + h * lo, box[1] + h * hi


def hue_rule(match, target, keep_head=False):
    """Đổi màu các pixel match(h, s, v) sang target(h, s, v) → (h, s, v). keep_head: giữ nguyên vùng đầu."""
    def rule(c, in_head):
        if keep_head and in_head:
            return c
        h, s, v = _hsv(c)
        if not match(h, s, v):
            return c
        return _rgb(*target(h, s, v), c[3])
    return rule


def is_gold(h, s, v):
    return 0.07 < h < 0.19 and s > 0.35 and v > 0.3


def is_red_hsv(h, s, v):
    return (h < 0.045 or h > 0.94) and s > 0.45 and v > 0.2


def is_grey(h, s, v):
    return s < 0.25 and v > 0.18


def is_purple(h, s, v):
    return 0.68 < h < 0.8 and s > 0.4 and v > 0.08


def split_recolor(frames, back_rule, front_rule):
    """Nửa sau thân (bên trái ô, nhân vật quay phải) dùng back_rule, nửa trước dùng front_rule (Agito Trinity)."""
    out = []
    for fr in frames:
        im = fr.copy()
        px = im.load()
        box = fr.getbbox() or (0, 0, fr.width, fr.height)
        mid = (box[0] + box[2]) / 2.0
        head_limit = box[1] + (box[3] - box[1]) * 0.22
        for y in range(im.height):
            for x in range(im.width):
                c = px[x, y]
                if c[3]:
                    px[x, y] = (back_rule if x < mid else front_rule)(c, y < head_limit)
        out.append(im)
    return out


def squat(fr, amount):
    """Tư thế cúi từ tư thế đứng: nén phần chân (45% dưới) lại, thân trên giữ nguyên rồi hạ xuống theo."""
    box = fr.getbbox()
    if not box:
        return fr.copy()
    cut = box[1] + int((box[3] - box[1]) * 0.55)
    legs = box[3] - cut
    new_legs = max(2, int(round(legs * (1.0 - amount))))
    im = Image.new("RGBA", fr.size, (0, 0, 0, 0))
    upper = fr.crop((0, box[1], fr.width, cut))
    im.paste(upper, (0, box[1] + legs - new_legs))
    for i in range(new_legs):   # lấy hàng gần nhất, giữ nét pixel
        src_y = cut + min(legs - 1, int(i * legs / new_legs))
        im.paste(fr.crop((0, src_y, fr.width, src_y + 1)), (0, box[3] - new_legs + i))
    return im


def front_point(fr, lo, hi):
    """Pixel xa nhất về phía trước (bên phải) trong dải chiều cao lo..hi: bàn tay đang vung / chân đang đá."""
    box, y0, y1 = _band(fr, lo, hi)
    px = fr.load()
    pts = [(x, y) for y in range(int(y0), int(y1) + 1) for x in range(box[0], box[2]) if px[x, y][3]]
    return max(pts, key=lambda p: p[0]) if pts else ((box[0] + box[2]) // 2, int(y0))


def draw_line(im, x0, y0, x1, y1, color, width=1):
    px = im.load()
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(n + 1):
        x = round(x0 + (x1 - x0) * i / n)
        y = round(y0 + (y1 - y0) * i / n)
        for dx in range(width):
            if 0 <= x + dx < im.width and 0 <= y < im.height:
                px[x + dx, y] = color


def add_weapon(frames, kind, band=(0.3, 0.62)):
    """Vẽ vũ khí lên bàn tay trước (Ryuki: thẻ Vent): điểm xa nhất phía trước trong dải chiều cao band.
    Dáng người giữ nguyên, chỉ thêm món đồ."""
    out = []
    for fr in frames:
        im = fr.copy()
        x, y = front_point(fr, *band)
        if kind == "sword":        # Drag Saber: lưỡi bạc chếch lên, chuôi vàng
            draw_line(im, x + 1, y + 1, x + 13, y - 11, (225, 230, 240, 255), 2)
            draw_line(im, x + 13, y - 11, x + 15, y - 13, (255, 255, 255, 255))
            draw_circle(im, x, y, 1.6, (230, 180, 50, 255), filled=True)
        elif kind == "claw":       # Dragclaw: đầu rồng đỏ trùm nắm tay
            draw_circle(im, x + 1, y, 3.6, (40, 10, 10, 255), filled=True)
            draw_circle(im, x + 1, y, 2.8, (220, 40, 40, 255), filled=True)
            im.load()[min(im.width - 1, x + 2), max(0, y - 2)] = (255, 220, 80, 255)
        elif kind == "shield":     # Dragshield: tấm khiên đỏ viền bạc trước ngực
            for yy in range(y - 7, y + 8):
                for xx in range(x - 3, x + 2):
                    if 0 <= xx < im.width and 0 <= yy < im.height:
                        edge = xx in (x - 3, x + 1) or yy in (y - 7, y + 7)
                        im.load()[xx, yy] = (210, 215, 225, 255) if edge else (200, 40, 40, 255)
        elif kind == "gun":        # Kabuto Kunai Gun (Gun Mode): thân bạc chĩa ra trước, báng đen, nòng đỏ
            draw_line(im, x + 1, y - 1, x + 7, y - 1, (20, 18, 22, 255))
            draw_line(im, x + 1, y, x + 7, y, (205, 210, 220, 255))
            draw_line(im, x + 1, y + 1, x + 7, y + 1, (20, 18, 22, 255))
            draw_line(im, x + 1, y + 1, x + 1, y + 3, (20, 18, 22, 255))
            im.load()[min(im.width - 1, x + 8), y] = (230, 40, 45, 255)
        elif kind == "drumstick":  # Ongekibou Rekka: dùi trống đỏ chếch lên, đầu dùi lửa cam
            draw_line(im, x + 1, y, x + 6, y - 5, (150, 20, 25, 255))
            draw_circle(im, x + 7, y - 6, 1.6, (255, 150, 40, 255), filled=True)
            im.load()[min(im.width - 1, x + 7), max(0, y - 7)] = (255, 230, 120, 255)
        elif kind == "drum":       # Ongekiko Kaentsuzumi: trống tròn đỏ viền vàng, tâm hoa văn vàng
            draw_circle(im, x + 4, y, 4.2, (40, 10, 10, 255), filled=True)
            draw_circle(im, x + 4, y, 3.4, (230, 180, 60, 255), filled=True)
            draw_circle(im, x + 4, y, 2.6, (190, 30, 35, 255), filled=True)
            draw_circle(im, x + 4, y, 1.0, (255, 210, 90, 255), filled=True)
        out.append(im)
    return out


def silhouette(frames, color):
    out = []
    for fr in frames:
        im = fr.copy()
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                if px[x, y][3]:
                    px[x, y] = color
        out.append(im)
    return out


# --- Hiệu ứng -----------------------------------------------------------------

def draw_circle(im, cx, cy, r, color, filled=False):
    px = im.load()
    if filled:
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                if 0 <= x < im.width and 0 <= y < im.height and (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    px[x, y] = color
        return
    n = max(12, int(r * 8))
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = round(cx + math.cos(a) * r), round(cy + math.sin(a) * r)
        if 0 <= x < im.width and 0 <= y < im.height:
            px[x, y] = color


def belt_point(frame):
    box = frame.getbbox()
    return ((box[0] + box[2]) / 2.0, box[3] - (box[3] - box[1]) * 0.47)


def head_point(frame):
    box = frame.getbbox()
    return ((box[0] + box[2]) / 2.0 + 2, box[1] + (box[3] - box[1]) * 0.12)


def henshin(human_idle, rider_idle, accent):
    """14 frame (12 fps ≈ 1.17 giây, khớp HENSHIN_TIME = 1.2 trong player.gd)."""
    h, r = human_idle, rider_idle
    frames = []

    def fx(img, rings=(), glow=0, eye=False):
        im = img.copy()
        bx, by = belt_point(img)
        if glow:
            draw_circle(im, bx, by, glow, accent, filled=True)
            draw_circle(im, bx, by, max(1, glow * 0.45), WHITE, filled=True)
        for radius in rings:
            draw_circle(im, bx, by, radius, accent)
        if eye:
            hx, hy = head_point(img)
            draw_circle(im, hx, hy, 1.5, WHITE, filled=True)
        return im

    frames.append(h[0])
    frames.append(fx(h[1 % len(h)], glow=2))
    frames.append(fx(h[2 % len(h)], glow=3, rings=[5]))
    frames.append(fx(h[3 % len(h)], glow=3, rings=[9, 5]))
    frames.append(fx(silhouette([h[0]], WHITE)[0], rings=[13]))
    frames.append(fx(silhouette([r[0]], WHITE)[0], rings=[17]))
    frames.append(fx(silhouette([r[0]], accent)[0], rings=[21]))
    for i in range(7):
        frames.append(fx(r[i % len(r)], eye=i in (3, 4)))
    return frames


def fire_trail(frames, color_core=(255, 224, 102, 255), color_outer=(255, 110, 40, 255)):
    """Thêm lửa ở chân trước cho Mighty Kick (frame giữa của flying-kick)."""
    out = []
    for i, fr in enumerate(frames):
        im = fr.copy()
        if 2 <= i <= 4:
            # bàn chân đá = pixel xa nhất về phía trước, tính ở nửa dưới cơ thể
            box = fr.getbbox()
            px = fr.load()
            mid = box[1] + (box[3] - box[1]) // 3
            x, y = max(((xx, yy) for yy in range(mid, box[3]) for xx in range(box[0], box[2]) if px[xx, yy][3]),
                       key=lambda p: p[0])
            draw_circle(im, x, y, 4.5, color_outer, filled=True)
            draw_circle(im, x, y, 2.2, color_core, filled=True)
        out.append(im)
    return out


# --- Cấu hình nhân vật --------------------------------------------------------

FORM_ACCENT = {
    "kuuga_growing": (255, 230, 180, 255), "kuuga_mighty": (255, 90, 90, 255), "kuuga_dragon": (110, 170, 255, 255),
    "kuuga_pegasus": (120, 230, 140, 255), "kuuga_titan": (190, 120, 255, 255),
}
# fps đánh nhẹ / đánh mạnh theo thời gian đòn trong code (Pegasus, Titan ra đòn chậm hơn)
FORM_FPS = {"kuuga_growing": (12, 12), "kuuga_mighty": (12, 12), "kuuga_dragon": (13, 14),
            "kuuga_pegasus": (6, 8), "kuuga_titan": (6, 8)}


def build_player():
    hero = Source("hero")
    kuuga = Source("kuuga_mighty_fixed")
    cell = max(hero.size[0], kuuga.size[0])
    H = lambda name, pick=None: align(hero.get(name, pick), hero, cell)
    K = lambda name, pick=None: align(kuuga.get(name, pick), kuuga, cell)

    sets = {}
    sets["human"] = [
        ("idle", H("idle"), 8, True),
        ("run", H("run"), 12, True),
        ("jump", H("jump", [4, 5]) if "jump" in hero.anims else H("run", [1]), 6, True),
        ("crouch", H("crouch"), 14, False),
        ("light", H("light"), 12, False),
        ("heavy", H("heavy"), 12, False),
        ("dodge", H("run", [2, 3]), 8, False),
        ("hurt", H("hurt"), 18, False),
        ("break", H("hurt"), 8, True),
        ("ko", H("ko"), 8, False),
    ]

    human_idle = H("idle")
    mighty = {
        "idle": K("idle"), "run": K("run"), "jump": K("jump", [4, 5]), "light": K("light"),
        "heavy": K("heavy"), "hurt": K("hurt"), "final": K("final"), "dodge": K("run", [1, 2]),
        "crouch": K("crouch"),
    }
    for prefix, rule_name in (("kuuga_mighty", None), ("kuuga_growing", "growing"), ("kuuga_dragon", "dragon"),
                              ("kuuga_pegasus", "pegasus"), ("kuuga_titan", "titan")):
        conv = (lambda fr: fr) if rule_name is None else (lambda fr, rn=rule_name: recolor(fr, kuuga_rule(rn)))
        a = {k: conv(v) for k, v in mighty.items()}
        light_fps, heavy_fps = FORM_FPS[prefix]
        final = fire_trail(a["final"]) if prefix == "kuuga_mighty" else a["final"]
        sets[prefix] = [
            ("idle", a["idle"], 8, True),
            ("run", a["run"], 12, True),
            ("jump", a["jump"], 6, True),
            ("light", a["light"], light_fps, False),
            ("heavy", a["heavy"], heavy_fps, False),
            ("swap_in", a["heavy"], 28, False),
            ("dodge", a["dodge"], 8, False),
            ("crouch", a["crouch"], 14, False),
            ("hurt", a["hurt"], 18, False),
            ("henshin", henshin(human_idle, a["idle"], FORM_ACCENT[prefix]), 12, False),
            ("final", final, 5.5, False),
        ]
    sets.update(build_data_riders(human_idle, cell))
    return sets, cell


# --- Rider bộ gọn -------------------------------------------------------------
# PixelLab chỉ làm 5 animation (idle, run, light, heavy, hurt). Nhảy, cúi, né, tuyệt chiêu lấy từ frame có sẵn;
# các form còn lại đổi màu (Agito, Faiz) hoặc vẽ thêm vũ khí (Ryuki) từ form gốc. Không tốn lượt PixelLab.

# thời gian đòn (giây) nhẹ / đá / tuyệt chiêu theo kiểu đòn, cộng startup + active + recovery trong data_rider.gd
STYLE_TIME = {"brawler": (0.25, 0.52, 1.15), "lancer": (0.22, 0.47, 1.05), "blade": (0.29, 0.54, 1.17),
              "heavy": (0.54, 0.81, 1.25), "gunner": (0.51, 0.78, 1.1)}

GOLD_TO = lambda hue: (lambda h, s, v: (hue, min(1.0, s * 1.05), v))

# Dải chiều cao của bàn tay: dưới mặt, trên đầu gối (frame đá không vướng chân).
HAND_BAND = (0.36, 0.58)


def apply_conv(conv, anim, frames):
    """Biến đổi của một form trong DATA_RIDERS: None, một hàm cho mọi animation, hoặc dict {animation: hàm hoặc
    None} với "*" cho các animation còn lại (ví dụ vũ khí chỉ hiện khi ra đòn)."""
    if isinstance(conv, dict):
        conv = conv.get(anim, conv.get("*"))
    return conv(frames) if conv else frames


# prefix animation → (thư mục PixelLab, file thế giới lấy kiểu đòn hoặc None,
#                     {form: (biến đổi, màu vòng biến hình[, thư mục hình riêng của form])})
DATA_RIDERS = {
    "agito": ("agito", "w02_agito", {
        "ground": (None, (255, 200, 60, 255)),
        "storm": (lambda fr: recolor(fr, hue_rule(is_gold, GOLD_TO(0.6), keep_head=True)), (90, 150, 255, 255)),
        "flame": (lambda fr: recolor(fr, hue_rule(is_gold, GOLD_TO(0.99), keep_head=True)), (255, 80, 60, 255)),
        "trinity": (lambda fr: split_recolor(fr, hue_rule(is_gold, GOLD_TO(0.6), keep_head=True),
                                             hue_rule(is_gold, GOLD_TO(0.99), keep_head=True)), (255, 230, 150, 255)),
    }),
    "ryuki": ("ryuki", "w03_ryuki", {
        "ryuki": (None, (255, 80, 70, 255)),
        "sword_vent": (lambda fr: add_weapon(fr, "sword"), (255, 200, 90, 255)),
        "strike_vent": (lambda fr: add_weapon(fr, "claw"), (255, 120, 40, 255)),
        "guard_vent": (lambda fr: add_weapon(fr, "shield"), (220, 225, 235, 255)),
    }),
    # Faiz có script riêng (faiz.gd): tiền tố "faiz" cho form gốc, "faiz_axel", "faiz_blaster".
    "faiz": ("faiz", None, {
        "": (None, (255, 60, 60, 255)),
        # Axel: vạch đỏ thành bạc, mắt vàng thành đỏ
        "axel": (lambda fr: recolor(recolor(fr, hue_rule(is_red_hsv, lambda h, s, v: (0.6, 0.06, min(1.0, v * 1.3)))),
                                    hue_rule(lambda h, s, v: 0.1 < h < 0.2 and s > 0.4,
                                             lambda h, s, v: (0.99, s, v))), (230, 230, 240, 255)),
        # Blaster: giáp ngực bạc thành đỏ sẫm, giữ nguyên mũ (mũ Faiz to, chiếm ~1/3 chiều cao)
        "blaster": (lambda fr: recolor(fr, hue_rule(is_grey, lambda h, s, v: (0.99, 0.75, v * 0.8), keep_head=True),
                                       head=0.33),
                    (255, 40, 40, 255)),
    }),
    # Blade, Hibiki, Kabuto làm bằng PixelEngine (art/pixelengine/<tên>/). Form theo nguyên tác: form chỉ là lá bài /
    # đòn / khả năng thì giữ nguyên ngoại hình; form là vũ khí thì vẽ vũ khí vào tay như Ryuki; form đổi ngoại hình
    # thật thì đổi màu hoặc vẽ thêm theo phim. Biến đổi có thể là dict {animation: hàm} (xem apply_conv).
    # Blade: Mach Jaguar, Thunder Deer là lá bài (giữ nguyên); Jack Form giáp bạc thành vàng (giữ mũ).
    "blade": ("blade", "w05_blade", {
        "ace": (None, (110, 150, 255, 255)),
        "mach": (None, (90, 230, 200, 255)),
        "thunder": (None, (255, 240, 110, 255)),
        "jack": (lambda fr: recolor(fr, hue_rule(is_grey, lambda h, s, v: (0.12, 0.65, v), keep_head=True), head=0.3),
                 (255, 200, 60, 255)),
    }),
    # Hibiki: dùi trống đeo sau lưng, chỉ rút ra khi ra đòn: Onibi bắn lửa từ dùi Ongekibou Rekka, Kaentsuzumi đánh
    # bằng trống Ongekiko. Vũ khí gắn vào nắm đấm của đòn đấm. Hibiki Kurenai toàn thân đỏ thẫm.
    "hibiki": ("hibiki", "w06_hibiki", {
        "hibiki": (None, (180, 120, 255, 255)),
        "onibi": ({"light": lambda fr: add_weapon(fr, "drumstick", HAND_BAND)}, (255, 140, 50, 255)),
        "kaentsuzumi": ({"light": lambda fr: add_weapon(fr, "drum", HAND_BAND)}, (255, 190, 70, 255)),
        "kurenai": (lambda fr: recolor(fr, hue_rule(is_purple, lambda h, s, v: (0.985, s, min(1.0, v * 1.2)))),
                    (255, 60, 60, 255)),
    }),
    # Kabuto: Rider Form và Hyper Form (hình riêng làm bằng PixelEngine, art/pixelengine/kabuto_hyper/).
    "kabuto": ("kabuto", "w07_kabuto", {
        "rider": (None, (255, 70, 70, 255)),
        "hyper": (None, (235, 235, 255, 255), "kabuto_hyper"),
    }),
}


def world_styles(world_file):
    """{form: kiểu đòn} đọc từ hằng RIDER trong scripts/data/worlds/<world_file>.gd."""
    import re
    if not world_file:
        return {}
    text = open(os.path.join(ROOT, "scripts", "data", "worlds", world_file + ".gd"), encoding="utf-8").read()
    return dict(re.findall(r'&"(\w+)": \{"name": "[^"]*", "style": "(\w+)"', text))


def load_rider_frames(folder, cell):
    """5 animation của một thư mục nhân vật, căn vào ô, cộng nhảy / né / cúi lấy từ frame có sẵn. None nếu thiếu."""
    try:
        src = Source(folder)
    except (FileNotFoundError, KeyError) as e:
        print("  chưa có %s (%s), bỏ qua" % (folder, e))
        return None
    missing = [a for a in ("idle", "run", "light", "heavy", "hurt") if a not in src.anims]
    if missing:
        print("  %s còn thiếu animation %s, bỏ qua" % (folder, ", ".join(missing)))
        return None
    A = lambda name, pick=None: align(src.get(name, pick), src, cell)
    idle = A("idle")
    return {
        "idle": idle, "run": A("run"), "jump": A("run", [1]), "light": A("light"), "heavy": A("heavy"),
        "hurt": A("hurt"), "dodge": A("run", [2, 3]),
        "crouch": [squat(idle[0], a) for a in (0.15, 0.3, 0.42)],
    }


def build_data_riders(human_idle, cell):
    sets = {}
    for prefix, (folder, world_file, forms) in DATA_RIDERS.items():
        frames = {}
        styles = world_styles(world_file)
        for form, spec in forms.items():
            conv, accent = spec[:2]
            form_folder = spec[2] if len(spec) > 2 else folder  # form có hình riêng (Kabuto Hyper Form)
            if form_folder not in frames:
                frames[form_folder] = load_rider_frames(form_folder, cell)
            base = frames[form_folder]
            if base is None:
                continue
            a = {k: apply_conv(conv, k, v) for k, v in base.items()}
            light_t, kick_t, final_t = STYLE_TIME[styles.get(form, "brawler")]
            final = fire_trail(a["heavy"], color_outer=accent)
            name = prefix + ("_" + form if form else "")
            sets[name] = [
                ("idle", a["idle"], 8, True),
                ("run", a["run"], 12, True),
                ("jump", a["jump"], 6, True),
                ("light", a["light"], len(a["light"]) / light_t, False),
                ("heavy", a["heavy"], len(a["heavy"]) / kick_t, False),
                ("swap_in", a["heavy"], 28, False),
                ("dodge", a["dodge"], 8, False),
                ("crouch", a["crouch"], 14, False),
                ("hurt", a["hurt"], 18, False),
                ("henshin", henshin(human_idle, a["idle"], accent), 12, False),
                ("final", final, len(final) / final_t, False),
            ]
    return sets


def build_enemies():
    sets, cells = {}, {}
    zu = Source("grongi_zu")
    cell = zu.size[0]

    def enemy_set(src, conv=lambda f: f):
        A = lambda name, pick=None: conv(align(src.get(name, pick), src, src.size[0]))
        attack = A("attack")
        return [
            ("idle", conv(align([src.rotation], src, src.size[0])), 1, True),
            ("run", A("run"), 10, True),
            ("windup", attack[:1], 1, True),
            ("attack", attack, 12, False),
            ("hurt", A("hurt"), 18, False),
            ("die", A("die"), 8, False),
        ]

    sets["grongi_zu"] = enemy_set(zu)
    sets["grongi_me"] = enemy_set(zu, lambda fr: recolor(fr, grongi_rule("me")))
    sets["grongi_go"] = enemy_set(zu, lambda fr: recolor(fr, grongi_rule("go")))
    for name in ("grongi_zu", "grongi_me", "grongi_go"):
        cells[name] = cell
    try:
        dag = Source("daguba")
        sets["daguba"] = enemy_set(dag)
        cells["daguba"] = dag.size[0]
    except (FileNotFoundError, KeyError) as e:
        print("  chưa có đủ dữ liệu Daguba (%s), bỏ qua" % e)

    # Quái thế giới sau: một loại quái thường làm bằng PixelLab, loại nhanh và loại giáp đổi màu từ nó.
    # Trùm không có animation gục: dùng lại bị đánh.
    for folder, variants in EXTRA_ENEMIES.items():
        try:
            src = Source(folder)
        except (FileNotFoundError, KeyError) as e:
            print("  chưa có %s (%s), bỏ qua" % (folder, e))
            continue
        need = ("run", "attack", "hurt") + (("die",) if variants else ())
        missing = [a for a in need if a not in src.anims]
        if missing:
            print("  %s còn thiếu animation %s, bỏ qua" % (folder, ", ".join(missing)))
            continue
        if not variants:
            src.anims.setdefault("die", src.anims["hurt"])
        sets[folder] = enemy_set(src)
        cells[folder] = src.size[0]
        for name, rule in variants.items():
            sets[name] = enemy_set(src, lambda fr, r=rule: recolor(fr, r))
            cells[name] = src.size[0]
    return sets, cells


# thư mục PixelLab → {tên sprite đổi màu: rule}. Rỗng = trùm.
EXTRA_ENEMIES = {
    "jaguar_lord": {   # lông vàng và da thân → Crow Lord xanh đen, Tortoise Lord xanh rêu (giữ mắt xanh lá)
        "crow_lord": hue_rule(lambda h, s, v: 0.02 < h < 0.19 and s > 0.15 and v > 0.25,
                              lambda h, s, v: (0.66, max(0.25, s * 0.5), v * 0.55)),
        "tortoise_lord": hue_rule(lambda h, s, v: 0.02 < h < 0.19 and s > 0.15 and v > 0.25,
                                  lambda h, s, v: (0.27, max(0.35, s * 0.75), v * 0.85)),
    },
    "sheerghost": {    # vỏ xám bạc → Raydragoon xanh ngọc, Metalgelas nâu đồng
        "raydragoon": hue_rule(is_grey, lambda h, s, v: (0.48, 0.45, v)),
        "metalgelas": hue_rule(is_grey, lambda h, s, v: (0.08, 0.45, v * 0.9)),
    },
    "overlord": {},
    "odin": {},
}


# --- Xuất file ----------------------------------------------------------------

def save_sets(sets, cells, sub, tres_name):
    os.makedirs(os.path.join(OUT_DIR, sub), exist_ok=True)
    ext, subs, anims = [], [], []
    for i, (prefix, anim_list) in enumerate(sets.items()):
        cell = cells[prefix] if isinstance(cells, dict) else cells
        cols = max(len(frames) for _, frames, _, _ in anim_list)
        sheet = Image.new("RGBA", (cols * cell, len(anim_list) * cell), (0, 0, 0, 0))
        tex_id = "tex_%d" % i
        ext.append('[ext_resource type="Texture2D" path="%s/%s/%s.png" id="%s"]' % (RES_DIR, sub, prefix, tex_id))
        for row, (name, frames, fps, loop) in enumerate(anim_list):
            refs = []
            for col, fr in enumerate(frames):
                sheet.paste(fr, (col * cell, row * cell))
                sid = "at_%s_%s_%d" % (prefix, name, col)
                subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("%s")\n'
                            'region = Rect2(%d, %d, %d, %d)\nfilter_clip = true'
                            % (sid, tex_id, col * cell, row * cell, cell, cell))
                refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sid)
            anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s_%s",\n"speed": %s\n}'
                         % (", ".join(refs), "true" if loop else "false", prefix, name, float(fps)))
        sheet.save(os.path.join(OUT_DIR, sub, prefix + ".png"))
    text = '[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n' % (len(ext) + len(subs) + 1)
    text += "\n".join(ext) + "\n\n" + "\n\n".join(subs) + "\n\n[resource]\nanimations = [" + ", ".join(anims) + "]\n"
    with open(os.path.join(OUT_DIR, tres_name), "w", encoding="utf-8") as f:
        f.write(text)
    return sum(len(fr) for al in sets.values() for _, fr, _, _ in al)


def write_previews(out_dir, groups):
    os.makedirs(out_dir, exist_ok=True)
    bg = (92, 110, 148, 255)
    for sets in groups:
        for prefix, anim_list in sets.items():
            for name, frames, fps, _ in anim_list:
                if len(frames) < 2:
                    continue
                imgs = []
                for fr in frames:
                    im = Image.new("RGBA", fr.size, bg)
                    im.alpha_composite(fr)
                    imgs.append(im.resize((fr.width * 4, fr.height * 4), Image.NEAREST).convert("P", palette=Image.ADAPTIVE))
                imgs[0].save(os.path.join(out_dir, "%s_%s.gif" % (prefix, name)), save_all=True,
                             append_images=imgs[1:], duration=int(1000 / fps), loop=0, disposal=2)


def main():
    if "--download" in sys.argv:
        download_all()
    player, cell = build_player()
    enemies, cells = build_enemies()
    n1 = save_sets(player, cell, "player", "player_frames.tres")
    n2 = save_sets(enemies, cells, "enemies", "enemy_frames.tres")
    if "--preview" in sys.argv:
        write_previews(sys.argv[sys.argv.index("--preview") + 1], [player, enemies])
    print("Người chơi: %d frame (%d bộ) · Quái: %d frame (%d bộ) → %s" % (n1, len(player), n2, len(enemies), OUT_DIR))


if __name__ == "__main__":
    main()
