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
       - Rider bộ gọn (DATA_RIDERS: Agito, Ryuki, Faiz, Blade, Hibiki, Kabuto, Den-O, Kiva, Decade, W, OOO, Fourze, Wizard, Gaim, Drive, Ghost, Ex-Aid, Build): nhảy / cúi / né / tuyệt chiêu từ 5
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
import random
import os
import sys
import urllib.request
import zipfile

from PIL import Image


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(ROOT, "art", "pixellab")
PIXELENGINE_DIR = os.path.join(ROOT, "art", "pixelengine")
KITBASH_DIR = os.path.join(ROOT, "art", "kitbash")
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
    """Một nhân vật PixelLab đã giải nén trong art/pixellab/<name>/, nhân vật PixelEngine trong art/pixelengine/<name>/,
    hoặc quái ghép bằng tools/kitbash.py trong art/kitbash/<name>/ (cùng cấu trúc thư mục)."""

    def __init__(self, name):
        self.dir = os.path.join(SRC_DIR, name)
        for alt in (PIXELENGINE_DIR, KITBASH_DIR):
            if not os.path.isdir(self.dir):
                self.dir = os.path.join(alt, name)
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


def kiva_rule(hue):
    """Kiva Form → form Arms Monster: mắt vàng và giáp đỏ ở nửa trên (recolor head=0.55) sang màu `hue`."""
    def rule(c, upper):
        if not upper:
            return c
        h, s, v = _hsv(c)
        if not (is_red_hsv(h, s, v) or is_gold(h, s, v)):
            return c
        return _rgb(hue, max(s, 0.6), min(1.0, v * 1.05), c[3])
    return rule


W_SOULS = {"cyclone": None, "heat": 0.0, "luna": 0.14}          # nửa Soul xanh lá → đỏ / vàng
W_BODIES = {"joker": None, "metal": (0.58, 0.08), "trigger": (0.6, 0.75)}   # nửa Body đen → bạc / lam
W_ACCENT = {"cyclone": (90, 230, 110, 255), "heat": (255, 80, 60, 255), "luna": (255, 220, 70, 255)}


def FOURZE_TO(hue, sat, dim):
    """Fourze: giáp trắng (giữ mũ trắng) sang màu States."""
    return hue_rule(lambda h, s, v: s < 0.12 and v > 0.6, lambda h, s, v: (hue, sat, v * dim), keep_head=True)


def WIZARD_TO(hue, bright, sat=0.9):
    """Wizard: đá quý ruby đỏ ở mặt / áo sang màu Style."""
    return hue_rule(is_red_hsv, lambda h, s, v: (hue, s * sat, min(1.0, v * bright)))


def BUILD_TO(red, blue):
    """Build: nửa đỏ (thỏ) và nửa xanh lam (xe tăng) của RabbitTank sang hai màu Best Match khác. red / blue =
    (hue, sat, bright) đích cho từng nửa."""
    def rule(c, _in_head):
        h, s, v = _hsv(c)
        if s < 0.4 or v < 0.2:
            return c
        if h < 0.04 or h > 0.93:
            t = red
        elif 0.53 < h < 0.7:
            t = blue
        else:
            return c
        return _rgb(t[0], t[1], min(1.0, v * t[2]), c[3])
    return rule


def exaid_armor(frames, hue, sat, bright):
    """Ex-Aid Level 3 / 5: giáp Gashat lắp lên thân hồng → các pixel hồng ở dải thân (vai, ngực, eo; dưới mũ, trên
    chân) đổi sang màu giáp. Mũ hồng, mắt và chân giữ nguyên như Level 2."""
    out = []
    for fr in frames:
        im = fr.copy()
        px = im.load()
        box, y0, y1 = _band(fr, 0.3, 0.6)
        for y in range(int(y0), int(y1) + 1):
            for x in range(im.width):
                c = px[x, y]
                if c[3]:
                    h, s, v = _hsv(c)
                    if (h > 0.83 or h < 0.02) and s > 0.35 and v > 0.25:
                        px[x, y] = _rgb(hue, sat, min(1.0, v * bright), c[3])
        out.append(im)
    return out


def GHOST_TO(hue, sat, bright):
    """Ghost: mảng cam của Ore Damashii (mặt, sừng, đường vân, viền áo choàng) sang màu Damashii khác."""
    return hue_rule(lambda h, s, v: 0.02 < h < 0.12 and s > 0.5 and v > 0.3,
                    lambda h, s, v: (hue, sat, min(1.0, v * bright)))


def DRIVE_TO(hue, sat, bright):
    """Drive: thân đỏ Type Speed (kể cả mũ, giữ mắt đèn pha vàng) sang màu Type khác."""
    return hue_rule(is_red_hsv, lambda h, s, v: (hue, sat, min(1.0, v * bright)))


def GAIM_TO(hue, sat, bright):
    """Gaim: giáp cam Orange Arms (vai, ngực) sang màu Arms khác. Giữ vùng đầu (mắt cam, sừng vàng) nguyên."""
    return hue_rule(lambda h, s, v: 0.03 < h < 0.11 and s > 0.5 and v > 0.3,
                    lambda h, s, v: (hue, sat, min(1.0, v * bright)), keep_head=True)


def double_rule(soul, body, xtreme=False):
    """W CycloneJoker → tổ hợp khác. Nửa Soul là pixel xanh lá, nửa Body là pixel xám đen (trừ viền gần đen).
    Xtreme: đường may và khăn bạc thành pha lê trắng lam, nửa xanh sáng hơn."""
    hue = W_SOULS[soul]
    tone = W_BODIES[body]

    def rule(c, _upper):
        h, s, v = _hsv(c)
        if 0.22 < h < 0.45 and s > 0.35:
            if xtreme:
                return _rgb(h, s, min(1.0, v * 1.12), c[3])
            if hue is None:
                return c
            # Heat tối hơn một chút để mắt đỏ còn nổi trên nửa đỏ.
            return _rgb(hue, max(s, 0.7), v * (0.85 if soul == "heat" else 1.08), c[3])
        if tone and s < 0.2 and 0.1 < v < 0.5:
            return _rgb(tone[0], tone[1], 0.42 + v * 1.2 if body == "metal" else 0.25 + v * 1.2, c[3])
        if xtreme and s < 0.12 and v > 0.65:
            return _rgb(0.52, 0.18, min(1.0, v * 1.1), c[3])
        return c
    return rule


def ooo_rule(target):
    """OOO TaToBa → combo một màu: giáp đỏ (đầu), vàng (tay), xanh lá (chân) sang `target` = (hue, độ bão hoà
    [, độ sáng]) hoặc None là bạc xám (SaGohZo). Giữ mắt xanh lá ở vùng đầu (GataKiriBa tối giáp đi để mắt còn nổi)."""
    def rule(c, upper):
        h, s, v = _hsv(c)
        if s < 0.35 or v < 0.15:
            return c
        red, gold, green = h < 0.05 or h > 0.93, 0.08 < h < 0.2, 0.3 < h < 0.47
        if not (red or gold or green) or (upper and green):
            return c
        if target is None:
            return _rgb(0.6, 0.06, 0.3 + v * 0.65, c[3])
        # Chân xanh lá vốn tối hơn đầu / tay: sáng lên để combo đều màu.
        dim = target[2] if len(target) > 2 else 1.0
        return _rgb(target[0], s * target[1], min(1.0, (v * 1.3 if green else v) * dim), c[3])
    return rule


PRISM = [(240, 252, 255, 255), (170, 230, 255, 255), (255, 238, 170, 255), (215, 195, 255, 255)]


def xtreme_stripe(frames):
    """CycloneJokerXtreme: dải pha lê 3 px dọc đường ráp hai nửa, từ mặt tới thắt lưng. Đường ráp là chỗ pixel
    xanh lá liền kề (trong 2 px bên phải) pixel xám đen nửa Joker hoặc đường may bạc."""
    def green(c):
        h, s, v = _hsv(c)
        return c[3] and 0.22 < h < 0.45 and s > 0.35

    def seam(c):
        h, s, v = _hsv(c)
        return c[3] and s < 0.2 and v > 0.1

    out = []
    for fr in frames:
        im = fr.copy()
        px = im.load()
        box = fr.getbbox()
        if not box:
            out.append(im)
            continue
        hgt = box[3] - box[1]
        for y in range(box[1] + int(hgt * 0.1), box[1] + int(hgt * 0.55)):
            xs = [x for x in range(box[0], box[2] - 2)
                  if green(fr.getpixel((x, y))) and any(seam(fr.getpixel((x + d, y))) for d in (1, 2))]
            if not xs:
                continue
            x = xs[-1] + 1
            for dx in (-1, 0, 1):
                if fr.getpixel((x + dx, y))[3]:
                    px[x + dx, y] = PRISM[(y + dx) % len(PRISM)]
        out.append(im)
    return out


def double_form(soul, body, xtreme=False):
    """Biến đổi một tổ hợp W: đổi màu hai nửa; Metal Shaft chỉ vẽ vào animation "slash"."""
    def conv(frames):
        frames = recolor(frames, double_rule(soul, body, xtreme))
        if xtreme:
            frames = xtreme_stripe(frames)
        return frames

    def slash(frames):     # Metal Shaft chỉ hiện khi chém (nút Chém); Trigger Magnum là weapons/magnum.png lúc bắn
        frames = conv(frames)
        return swing_weapon(frames, "shaft", HAND_BAND) if body == "metal" and not xtreme else frames
    return {"*": conv, "slash": slash}


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


def draw_gun(im, x, y, body, light, barrel, length):
    """Súng dày 3 px chĩa ra trước từ bàn tay (x, y): viền đen, mặt trên sáng, báng đen chĩa xuống, nòng ngắn."""
    px = im.load()
    put = lambda xx, yy, c: px.__setitem__((xx, yy), c) if 0 <= xx < im.width and 0 <= yy < im.height else None
    for xx in range(x, x + length + 1):
        put(xx, y - 2, (20, 18, 22, 255))
        put(xx, y + 2, (20, 18, 22, 255))
    for xx in range(x + 1, x + length):
        put(xx, y - 1, light)
        put(xx, y, body)
        put(xx, y + 1, body)
    put(x + length, y - 1, (20, 18, 22, 255)); put(x + length, y + 1, (20, 18, 22, 255))
    put(x + length, y, barrel); put(x + length + 1, y, barrel); put(x + length + 2, y, (20, 18, 22, 255))
    for yy in range(y + 2, y + 6):        # báng cầm
        put(x, yy, (20, 18, 22, 255)); put(x + 1, yy, (50, 50, 58, 255)); put(x + 2, yy, (20, 18, 22, 255))


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
        elif kind == "booker_sword":  # Ride Booker (Sword Mode): lưỡi bạc dài chếch lên, thân hộp đen viền hồng
            draw_line(im, x + 2, y - 1, x + 15, y - 12, (225, 230, 240, 255), 2)
            draw_line(im, x + 15, y - 12, x + 17, y - 14, (255, 255, 255, 255))
            draw_line(im, x - 1, y + 1, x + 2, y - 2, (20, 18, 22, 255), 2)
            im.load()[min(im.width - 1, x + 1), y] = (235, 60, 150, 255)
        elif kind == "booker_gun":  # Ride Booker (Gun Mode): hộp súng đen dày, viền hồng, nòng bạc
            draw_gun(im, x, y, (40, 38, 46, 255), (235, 60, 150, 255), (205, 210, 220, 255), 8)
        elif kind == "shaft":      # Metal Shaft (W Metal): gậy bạc dài chéo qua nắm tay, hai đầu đen
            draw_line(im, x - 6, y + 9, x + 9, y - 12, (200, 205, 215, 255))
            draw_line(im, x - 5, y + 9, x + 10, y - 12, (150, 155, 170, 255))
            draw_line(im, x - 6, y + 9, x - 5, y + 7, (20, 18, 22, 255), 2)
            draw_line(im, x + 9, y - 12, x + 10, y - 10, (20, 18, 22, 255), 2)
        elif kind == "magnum":     # Trigger Magnum (W Trigger): súng lam dày, nòng bạc dài
            draw_gun(im, x, y, (50, 90, 210, 255), (130, 170, 255, 255), (205, 210, 220, 255), 9)
        elif kind == "tora":       # Tora Claws (OOO LaTorarTar): ba vuốt vàng chĩa ra trước nắm tay
            for dy, ey in ((-2, -4), (0, 0), (2, 4)):
                draw_line(im, x + 1, y + dy, x + 6, y + ey, (255, 215, 60, 255))
            im.load()[min(im.width - 1, x + 6), y] = (255, 250, 200, 255)
        elif kind == "whip":       # Denki Unagi Whip (OOO ShaUTa): roi lam uốn lượn, đầu roi tia điện vàng
            pts = [(x + 1 + i, y + round(2 * math.sin(i / 1.6))) for i in range(12)]
            for (ax, ay), (bx, by) in zip(pts, pts[1:]):
                draw_line(im, ax, ay, bx, by, (60, 140, 255, 255))
            ex, ey = pts[-1]
            for dx, dy in ((1, -1), (1, 1), (2, 0)):
                if 0 <= ex + dx < im.width and 0 <= ey + dy < im.height:
                    im.load()[ex + dx, ey + dy] = (255, 240, 120, 255)
        elif kind == "gorilla":    # Gorilla Bagootcha (OOO SaGohZo): găng bạc to trùm nắm tay
            draw_circle(im, x + 1, y, 3.8, (20, 18, 22, 255), filled=True)
            draw_circle(im, x + 1, y, 3.0, (175, 180, 190, 255), filled=True)
            draw_line(im, x, y - 1, x + 3, y - 1, (230, 232, 238, 255))
        elif kind == "rocket":     # Rocket Module (Fourze Rocket): ống tên lửa cam bọc nắm tay, mũi trắng, lửa xả phía sau
            for xx in range(x - 2, x + 8):
                for yy in range(y - 3, y + 4):
                    if 0 <= xx < im.width and 0 <= yy < im.height:
                        edge = xx in (x - 2, x + 7) or yy in (y - 3, y + 3)
                        im.load()[xx, yy] = (20, 18, 22, 255) if edge else (240, 110, 30, 255)
            draw_line(im, x + 8, y - 1, x + 9, y, (245, 245, 250, 255))
            draw_line(im, x + 8, y + 1, x + 9, y, (245, 245, 250, 255))
            draw_line(im, x - 4, y, x - 3, y, (255, 220, 80, 255))
        elif kind == "billy":      # Billy the Rod (Fourze Elek): kiếm điện bạc chếch lên, đầu kiếm tia điện vàng
            draw_line(im, x + 1, y + 1, x + 12, y - 10, (210, 215, 225, 255), 2)
            draw_circle(im, x, y, 1.6, (40, 40, 45, 255), filled=True)
            for dx, dy in ((13, -12), (14, -10), (11, -13)):
                if 0 <= x + dx < im.width and 0 <= y + dy < im.height:
                    im.load()[x + dx, y + dy] = (255, 235, 70, 255)
        elif kind == "hackgun":    # Hee-Hackgun (Fourze Fire): súng bình cứu hỏa đỏ dày, vòi bạc
            draw_gun(im, x, y, (200, 40, 35, 255), (255, 120, 90, 255), (205, 210, 220, 255), 7)
        elif kind == "kamakiri":   # Kamakiri Sword (OOO GataKiriBa): lưỡi xanh lá chếch lên từ cẳng tay
            draw_line(im, x - 1, y + 1, x + 10, y - 8, (70, 220, 90, 255), 2)
            draw_line(im, x + 10, y - 8, x + 12, y - 10, (210, 255, 200, 255))
        elif kind == "spinner":    # Taja Spinner (OOO TaJaDor): khiên tròn đỏ viền vàng trên cẳng tay
            draw_circle(im, x, y, 3.6, (20, 18, 22, 255), filled=True)
            draw_circle(im, x, y, 2.8, (240, 190, 60, 255), filled=True)
            draw_circle(im, x, y, 1.8, (220, 50, 40, 255), filled=True)
        elif kind == "medagabryu":  # Medagabryu (OOO PuToTyra): rìu tím, cán đen, lưỡi bạc
            draw_line(im, x - 3, y + 4, x + 7, y - 6, (30, 25, 35, 255), 2)
            for dy in range(-3, 4):
                draw_line(im, x + 6, y - 7 + dy, x + 10 - abs(dy), y - 7 + dy, (150, 90, 220, 255))
            draw_line(im, x + 10, y - 9, x + 10, y - 5, (220, 225, 235, 255))
        elif kind == "kame":       # Kame Gauntlet (OOO BuraKaWani): khiên mai rùa xanh rêu viền cam trên cẳng tay
            for dy in range(-4, 5):
                half = 3 - abs(dy) // 2
                for dx in range(-half, half + 1):
                    if 0 <= x + dx < im.width and 0 <= y + dy < im.height:
                        edge = abs(dx) == half or abs(dy) == 4
                        im.load()[x + dx, y + dy] = (230, 120, 40, 255) if edge else (110, 130, 60, 255)
        elif kind == "wizargun":   # WizarSwordGun (Gun Mode): thân súng bạc dày 3 px, báng đen chĩa xuống, nòng ngắn đầu lam
            px = im.load()
            put = lambda xx, yy, c: px.__setitem__((xx, yy), c) if 0 <= xx < im.width and 0 <= yy < im.height else None
            for xx in range(x, x + 9):
                put(xx, y - 2, (20, 18, 22, 255))
                put(xx, y + 2, (20, 18, 22, 255))
            for xx in range(x + 1, x + 8):
                put(xx, y - 1, (230, 232, 240, 255))
                put(xx, y, (170, 175, 190, 255))
                put(xx, y + 1, (120, 125, 140, 255))
            put(x + 8, y - 1, (20, 18, 22, 255)); put(x + 8, y + 1, (20, 18, 22, 255))
            put(x + 8, y, (205, 210, 220, 255)); put(x + 9, y, (205, 210, 220, 255)); put(x + 10, y, (90, 150, 255, 255))
            for yy in range(y + 2, y + 6):        # báng cầm
                put(x, yy, (20, 18, 22, 255)); put(x + 1, yy, (50, 50, 58, 255)); put(x + 2, yy, (20, 18, 22, 255))
        elif kind == "wizarsword":  # WizarSwordGun (Sword Mode): lưỡi bạc dài chếch lên, chuôi đen
            draw_line(im, x + 1, y, x + 13, y - 10, (220, 225, 235, 255), 2)
            draw_line(im, x + 13, y - 10, x + 15, y - 12, (255, 255, 255, 255))
            draw_line(im, x - 1, y + 2, x + 1, y, (20, 18, 22, 255), 2)
        elif kind == "ichigo_kunai":  # Ichigo Kunai (Gaim Ichigo): hai kunai đỏ hình quả dâu, cán đen, cầm ngang
            for dy in (-2, 1):
                draw_line(im, x, y + dy, x + 2, y + dy, (20, 18, 22, 255))
                draw_line(im, x + 3, y + dy, x + 7, y + dy, (220, 40, 55, 255))
                im.load()[min(im.width - 1, x + 8), y + dy] = (255, 200, 200, 255)
            im.load()[min(im.width - 1, x + 4), y - 3] = (80, 200, 90, 255)
        elif kind == "sonic_arrow":   # Sonic Arrow (Gaim Jimber Lemon): cung bạc dựng đứng, dây cung, mũi tên vàng
            draw_line(im, x + 3, y - 6, x + 5, y, (210, 215, 225, 255))
            draw_line(im, x + 5, y, x + 3, y + 6, (210, 215, 225, 255))
            draw_line(im, x + 2, y - 6, x + 2, y + 6, (240, 240, 245, 140))
            draw_line(im, x, y, x + 10, y, (255, 220, 60, 255))
            im.load()[min(im.width - 1, x + 11), y] = (255, 250, 200, 255)
        elif kind == "door_ju":     # Door-Ju (Drive Technic): súng hình cửa xe đỏ, cửa sổ đen, nòng bạc
            draw_gun(im, x, y, (200, 35, 40, 255), (255, 110, 110, 255), (205, 210, 220, 255), 8)
            draw_line(im, x + 3, y - 1, x + 5, y - 1, (30, 30, 40, 255))
        elif kind == "gangun":      # Gan Gun Saber Gun Mode (Ghost Edison): súng đen viền vàng, nòng bạc
            draw_gun(im, x, y, (35, 35, 42, 255), (255, 220, 70, 255), (205, 210, 220, 255), 8)
        elif kind == "tricker":     # Tricker (Ex-Aid Sports): bánh xe đạp đen vành lam cầm trên tay, sắp ném
            draw_circle(im, x + 4, y, 4.0, (20, 18, 22, 255))
            draw_circle(im, x + 4, y, 3.0, (80, 220, 210, 255))
            draw_line(im, x + 1, y, x + 7, y, (200, 205, 215, 255))
            draw_line(im, x + 4, y - 3, x + 4, y + 3, (200, 205, 215, 255))
        elif kind == "drago_gun":   # Drago Knight Hunter Z (Ex-Aid Hunter): súng đầu rồng xanh lá, miệng cam
            draw_gun(im, x, y, (50, 160, 60, 255), (140, 230, 120, 255), (255, 140, 40, 255), 9)
            im.load()[min(im.width - 1, x + 6), max(0, y - 3)] = (240, 200, 60, 255)
        elif kind == "robot_arm":   # Gekitotsu Robots (Ex-Aid Robot): nắm đấm robot đỏ to viền đen trùm bàn tay
            draw_circle(im, x + 2, y, 4.6, (20, 18, 22, 255), filled=True)
            draw_circle(im, x + 2, y, 3.8, (210, 50, 50, 255), filled=True)
            draw_line(im, x + 1, y - 2, x + 4, y - 2, (250, 200, 80, 255))
        elif kind == "hawk_gatlinger":  # Hawk Gatlinger (Build HawkGatling): súng máy cam, ổ đạn tròn, nòng bạc chùm
            draw_gun(im, x, y, (220, 120, 40, 255), (255, 190, 110, 255), (205, 210, 220, 255), 9)
            draw_circle(im, x + 3, y + 3, 2.2, (60, 60, 70, 255), filled=True)
        # --- Vũ khí cận chiến (vẽ vào animation "slash"): lưỡi / cán chếch lên từ nắm tay
        elif kind == "drill_crusher":  # Drill Crusher (Build RabbitTank): mũi khoan xanh lam xoắn bạc, chuôi đen
            draw_line(im, x - 1, y + 2, x + 1, y, (20, 18, 22, 255), 2)
            for i in range(12):
                half = max(0, 2 - i // 4)
                draw_line(im, x + 1 + i, y - 1 - i - half, x + 1 + i + half, y - 1 - i + half,
                          (220, 225, 235, 255) if i % 3 == 1 else (60, 120, 230, 255))
        elif kind == "ninpoutou":   # Yonkoma Ninpoutou (Build NinninComic): kiếm ninja thẳng tím, chuôi vàng
            draw_line(im, x + 1, y, x + 13, y - 11, (150, 80, 220, 255), 2)
            draw_line(im, x + 2, y - 2, x + 13, y - 12, (230, 220, 255, 255))
            draw_line(im, x - 1, y + 2, x + 1, y, (240, 200, 60, 255), 2)
        elif kind == "gashacon_breaker":  # Gashacon Breaker Hammer (Ex-Aid): cán đen, đầu búa hồng có nút A / B
            draw_line(im, x - 2, y + 3, x + 7, y - 6, (30, 30, 36, 255), 2)
            for dy in range(-4, 3):
                draw_line(im, x + 6, y - 7 + dy, x + 11, y - 7 + dy, (230, 70, 160, 255))
            im.load()[min(im.width - 1, x + 8), max(0, y - 9)] = (255, 230, 60, 255)
            im.load()[min(im.width - 1, x + 10), max(0, y - 6)] = (80, 200, 255, 255)
        elif kind == "drago_blade":  # lưỡi kiếm rồng (Ex-Aid Hunter): lưỡi xanh lá rộng, sống vàng
            draw_line(im, x + 1, y, x + 12, y - 10, (60, 190, 70, 255), 3)
            draw_line(im, x + 2, y - 3, x + 12, y - 12, (240, 210, 70, 255))
        elif kind == "gangunsaber":  # Gan Gun Saber Blade Mode (Ghost Ore): lưỡi đen sống cam, chuôi đen
            draw_line(im, x + 1, y, x + 13, y - 10, (40, 40, 48, 255), 2)
            draw_line(im, x + 2, y - 2, x + 13, y - 12, (255, 140, 40, 255))
            draw_line(im, x - 1, y + 2, x + 1, y, (20, 18, 22, 255), 2)
        elif kind == "nito":        # Gan Gun Saber Nitoryu (Ghost Musashi): hai thanh kiếm đỏ bắt chéo
            draw_line(im, x + 1, y, x + 12, y - 10, (210, 45, 40, 255), 2)
            draw_line(im, x + 1, y - 2, x + 11, y + 4, (210, 45, 40, 255), 2)
            draw_line(im, x + 12, y - 10, x + 14, y - 12, (240, 240, 245, 255))
            draw_line(im, x + 11, y + 4, x + 13, y + 5, (240, 240, 245, 255))
        elif kind == "handle_ken":  # Handle-Ken (Drive Speed): lưỡi bạc dài, chuôi là vô lăng đỏ tròn
            draw_line(im, x + 2, y - 2, x + 14, y - 12, (220, 225, 235, 255), 2)
            draw_line(im, x + 14, y - 12, x + 16, y - 14, (255, 255, 255, 255))
            draw_circle(im, x + 1, y - 1, 3.0, (200, 30, 35, 255))
            draw_circle(im, x + 1, y - 1, 1.0, (30, 30, 36, 255), filled=True)
        elif kind == "rumble_dump":  # Rumble Dump (Drive Wild): mũi khoan cam vàng chĩa ra trước, xoắn đen
            for i in range(10):
                half = max(0, 3 - i // 3)
                draw_line(im, x + 1 + i, y - 1 - i - half, x + 1 + i + half, y - 1 - i + half,
                          (20, 18, 22, 255) if i % 3 == 2 else (240, 170, 40, 255))
        elif kind == "daidaimaru":  # Daidaimaru (Gaim Orange): đại đao lưỡi cong như múi cam, sống bạc, chuôi đen
            draw_line(im, x - 1, y + 2, x + 1, y, (20, 18, 22, 255), 2)
            draw_line(im, x + 1, y, x + 7, y - 6, (240, 140, 30, 255), 2)
            draw_line(im, x + 7, y - 6, x + 13, y - 9, (255, 170, 50, 255), 2)
            draw_line(im, x + 2, y - 2, x + 12, y - 11, (235, 235, 240, 255))
        elif kind == "pine_iron":   # Pine Iron (Gaim Pine): quả chùy hình dứa vàng nâu treo xích bạc
            draw_line(im, x, y, x + 6, y - 6, (200, 205, 215, 255))
            draw_circle(im, x + 9, y - 9, 4.0, (20, 18, 22, 255), filled=True)
            draw_circle(im, x + 9, y - 9, 3.2, (225, 175, 50, 255), filled=True)
            for dx, dy in ((-1, -1), (1, 1), (1, -1), (-1, 1)):
                im.load()[min(im.width - 1, x + 9 + dx), max(0, y - 9 + dy)] = (150, 100, 30, 255)
            draw_line(im, x + 10, y - 13, x + 12, y - 15, (60, 160, 70, 255))
        elif kind == "halberd":    # Storm Halberd (Agito Storm): cán bạc dài hai đầu, lưỡi lam
            draw_line(im, x - 5, y + 5, x + 12, y - 12, (200, 205, 215, 255))
            draw_line(im, x + 10, y - 10, x + 14, y - 14, (80, 140, 255, 255), 2)
            draw_line(im, x - 7, y + 7, x - 5, y + 5, (80, 140, 255, 255), 2)
        elif kind == "flame_saber":  # Flame Saber (Agito Flame / Trinity): lưỡi đỏ viền vàng, chuôi vàng
            draw_line(im, x + 1, y, x + 12, y - 10, (230, 60, 40, 255), 2)
            draw_line(im, x + 2, y - 2, x + 12, y - 11, (255, 200, 80, 255))
            draw_circle(im, x, y, 1.6, (230, 180, 50, 255), filled=True)
        elif kind == "rekka":      # Ongekibou Rekka (Hibiki Kurenai): dùi đỏ, lưỡi lửa cam dài
            draw_line(im, x, y + 1, x + 4, y - 3, (150, 20, 25, 255), 2)
            draw_line(im, x + 4, y - 3, x + 12, y - 11, (255, 140, 40, 255), 2)
            draw_line(im, x + 6, y - 6, x + 13, y - 13, (255, 230, 120, 255))
        elif kind == "dengasher_sword":  # DenGasher Sword Mode (Den-O Sword): lưỡi đỏ dày, sống bạc
            draw_line(im, x + 1, y, x + 13, y - 10, (220, 40, 45, 255), 2)
            draw_line(im, x + 2, y - 2, x + 13, y - 12, (220, 225, 235, 255))
            draw_line(im, x - 1, y + 2, x + 1, y, (30, 30, 36, 255), 2)
        elif kind == "dengasher_rod":    # DenGasher Rod Mode (Den-O Rod): cần dài lam, đầu bạc
            draw_line(im, x - 4, y + 4, x + 15, y - 12, (60, 110, 230, 255))
            draw_line(im, x + 14, y - 11, x + 16, y - 13, (220, 225, 235, 255), 2)
        elif kind == "dengasher_axe":    # DenGasher Ax Mode (Den-O Ax): cán đen, lưỡi rìu vàng
            draw_line(im, x - 3, y + 4, x + 7, y - 7, (30, 30, 36, 255), 2)
            for dy in range(-4, 3):
                draw_line(im, x + 6, y - 7 + dy, x + 11 - abs(dy + 1), y - 7 + dy, (240, 200, 60, 255))
        elif kind == "garulu_saber":     # Garulu Saber (Kiva Garulu): lưỡi lam cong, chuôi đầu sói bạc
            draw_line(im, x + 1, y, x + 7, y - 7, (70, 110, 230, 255), 2)
            draw_line(im, x + 7, y - 7, x + 13, y - 10, (120, 160, 255, 255), 2)
            draw_circle(im, x, y, 1.8, (200, 205, 215, 255), filled=True)
        elif kind == "dogga_hammer":     # Dogga Hammer (Kiva Dogga): cán tím, đầu búa nắm tay khổng lồ
            draw_line(im, x - 2, y + 3, x + 6, y - 6, (60, 40, 80, 255), 2)
            draw_circle(im, x + 8, y - 8, 4.2, (20, 18, 22, 255), filled=True)
            draw_circle(im, x + 8, y - 8, 3.4, (150, 90, 210, 255), filled=True)
            im.load()[min(im.width - 1, x + 9), max(0, y - 9)] = (230, 60, 60, 255)
        elif kind == "dragon_rod":       # Dragon Rod (Kuuga Dragon): gậy dài lam, hai đầu vàng
            draw_line(im, x - 5, y + 5, x + 13, y - 13, (70, 120, 230, 255))
            draw_line(im, x + 12, y - 12, x + 14, y - 14, (240, 200, 70, 255), 2)
            draw_line(im, x - 6, y + 6, x - 5, y + 5, (240, 200, 70, 255), 2)
        elif kind == "titan_sword":      # Titan Sword (Kuuga Titan): lưỡi bạc rộng, chuôi tím
            draw_line(im, x + 1, y, x + 12, y - 11, (215, 220, 230, 255), 3)
            draw_line(im, x - 1, y + 2, x + 1, y, (140, 70, 200, 255), 2)
        # --- Súng (art/characters/weapons/<tên>.png, hiện ở tay lúc bắn)
        elif kind == "onibi":      # dùi trống Ongekibou Rekka cầm ngang, đầu dùi phun lửa
            draw_line(im, x, y, x + 8, y, (150, 20, 25, 255), 2)
            draw_circle(im, x + 10, y, 2.0, (255, 150, 40, 255), filled=True)
            im.load()[min(im.width - 1, x + 11), y] = (255, 230, 120, 255)
        elif kind == "dengasher_gun":    # DenGasher Gun Mode (Den-O Gun): súng tím
            draw_gun(im, x, y, (120, 60, 200, 255), (190, 140, 255, 255), (205, 210, 220, 255), 8)
        elif kind == "basshaa_magnum":   # Basshaa Magnum (Kiva Basshaa): súng lục, vây cá
            draw_gun(im, x, y, (40, 170, 130, 255), (120, 240, 200, 255), (205, 210, 220, 255), 8)
            im.load()[x + 4, max(0, y - 3)] = (40, 170, 130, 255)
        elif kind == "pegasus_bowgun":   # Pegasus Bowgun (Kuuga Pegasus): súng nỏ lục, cánh cung vàng
            draw_gun(im, x, y, (50, 170, 80, 255), (140, 240, 150, 255), (240, 200, 70, 255), 8)
            draw_line(im, x + 6, y - 4, x + 6, y + 4, (240, 200, 70, 255))
        elif kind == "faiz_phone":       # Faiz Phone (Phone Blaster): điện thoại bạc gập ngang, vạch đỏ
            draw_gun(im, x, y, (170, 175, 190, 255), (230, 232, 240, 255), (230, 40, 40, 255), 6)
        elif kind == "faiz_blaster":     # Faiz Blaster: súng to bạc, nòng đỏ
            draw_gun(im, x, y, (150, 155, 170, 255), (230, 232, 240, 255), (230, 40, 40, 255), 11)
            draw_line(im, x + 2, y - 3, x + 9, y - 3, (20, 18, 22, 255))
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


SWING_FROM, SWING_TO = 75.0, -65.0     # độ, ngược chiều kim đồng hồ so với dáng vũ khí vẽ sẵn (chếch lên phía trước)


def swing_weapon(frames, kind, band=(0.3, 0.62), trail=(255, 255, 255)):
    """Động tác chém: vũ khí xoay quanh bàn tay từ giơ cao phía sau (SWING_FROM) xuống chém về trước (SWING_TO) qua
    các khung (nhanh dần về cuối), kèm vệt chém cong: cung tròn đầu lưỡi quét qua từ khung trước tới khung này."""
    base = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    base.putpixel((32, 32), (1, 1, 1, 255))                      # "bàn tay" cho add_weapon bám vào
    base = add_weapon([base], kind, (0.0, 1.0))[0]
    if base.getpixel((32, 32)) == (1, 1, 1, 255):
        base.putpixel((32, 32), (0, 0, 0, 0))
    pts = [(cx - 32, cy - 32) for cy in range(64) for cx in range(64) if base.getpixel((cx, cy))[3]]
    tip = max(pts, key=lambda q: q[0] ** 2 + q[1] ** 2) if pts else (8, -8)

    def at(ang, scale=1.0):                                     # đầu lưỡi sau khi xoay `ang` độ ngược chiều kim đồng hồ
        a = math.radians(ang)
        return (round((tip[0] * math.cos(a) + tip[1] * math.sin(a)) * scale),
                round((-tip[0] * math.sin(a) + tip[1] * math.cos(a)) * scale))

    out = []
    n = len(frames)
    prev = None
    for i, fr in enumerate(frames):
        im = fr.copy()
        x, y = front_point(fr, *band)
        ang = SWING_FROM + (SWING_TO - SWING_FROM) * (i / max(1, n - 1)) ** 1.6
        if prev is not None:
            px = im.load()
            steps = max(2, int(abs(prev - ang) / 3))
            for k in range(steps + 1):
                a = prev + (ang - prev) * k / steps
                for sc, alpha in ((1.0, 170), (0.85, 90)):            # hai lớp: mép ngoài sáng, trong mờ
                    dx, dy = at(a, sc)
                    tx, ty = x + dx, y + dy
                    if 0 <= tx < im.width and 0 <= ty < im.height and not px[tx, ty][3]:
                        px[tx, ty] = trail + (alpha,)
        im.alpha_composite(base.rotate(ang, resample=Image.NEAREST, center=(32, 32)), (x - 32, y - 32))
        prev = ang
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


# Cảnh biến thân riêng từng Rider theo phim (14 frame như henshin()). Rider không có trong bảng dùng henshin() chung.
HENSHIN_STYLE = {"kuuga": "arcle", "agito": "agito", "ryuki": "mirror", "faiz": "photon", "blade": "card",
                 "hibiki": "onsa", "kabuto": "castoff", "den_o": "armor_in", "kiva": "chains", "decade": "decade",
                 "double": "wind", "ooo": "medals", "fourze": "steam", "wizard": "circle",
                 "gaim": "arms", "drive": "tire", "ghost": "parka",
                 "ex_aid": "game", "build": "snap"}


def _reveal(human, rider, mask):
    """Ghép hai hình: pixel của rider ở chỗ mask(x, y) đúng, còn lại của human."""
    out = Image.new("RGBA", rider.size, (0, 0, 0, 0))
    ph, pr, po = human.load(), rider.load(), out.load()
    for y in range(rider.height):
        for x in range(rider.width):
            c = pr[x, y] if mask(x, y) else ph[x, y]
            if c[3]:
                po[x, y] = c
    return out


def _put(im, x, y, c):
    x, y = int(round(x)), int(round(y))
    if 0 <= x < im.width and 0 <= y < im.height:
        im.load()[x, y] = c


def _ghost(base, img, dx, dy, color, alpha):
    """Vẽ viền bóng một màu của img lệch (dx, dy) lên base (chỉ ô trống): bóng gương / bóng Rider hội tụ."""
    pb, pi = base.load(), img.load()
    w, h = img.size
    opaque = lambda x, y: 0 <= x < w and 0 <= y < h and pi[x, y][3]
    for y in range(img.height):
        for x in range(img.width):
            if pi[x, y][3] and not all(opaque(x + ex, y + ey) for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                tx, ty = x + dx, y + dy
                if 0 <= tx < base.width and 0 <= ty < base.height and pb[tx, ty][3] < 200:
                    pb[tx, ty] = color[:3] + (alpha,)


def _edge(img, color, cond):
    """Tô màu các pixel có hình của img thoả cond(x, y) (vạch Photon Stream, viền...)."""
    out = img.copy()
    po = out.load()
    for y in range(img.height):
        for x in range(img.width):
            if po[x, y][3] and cond(x, y):
                po[x, y] = color
    return out


def henshin_styled(style, human_idle, rider_idle, accent):
    """14 frame (12 fps) biến thân theo kiểu `style` (HENSHIN_STYLE). 4 frame đầu dạng người lấy đà, giữa là hiệu ứng
    riêng, cuối là Rider đứng với mắt lóe sáng."""
    H = lambda i: human_idle[i % len(human_idle)]
    R = lambda i: rider_idle[i % len(rider_idle)]
    r0 = R(0)
    box = r0.getbbox()
    top, bot, left, right = box[1], box[3], box[0], box[2]
    bx, by = belt_point(r0)
    hx, hy = head_point(r0)
    mid = (left + right) / 2.0
    acc = tuple(accent[:3]) + (255,)
    rnd = random.Random(style)
    frames = []

    def eye(img, on=True):
        im = img.copy()
        if on:
            draw_circle(im, hx, hy, 1.5, WHITE, filled=True)
        return im

    def tail(start=10):                                         # Rider đứng, mắt lóe ở frame 11–12
        for i in range(start, 14):
            frames.append(eye(R(i), i in (11, 12)))

    if style == "arcle":            # Kuuga: Arcle sáng đỏ, giáp lan ra từ đai
        for i in range(3):
            im = H(i).copy()
            draw_circle(im, bx, by, 2 + i, acc, filled=True)
            draw_circle(im, bx, by, 1 + i * 0.5, WHITE, filled=True)
            frames.append(im)
        for i, rad in enumerate((4, 8, 13, 18, 24, 31, 40)):
            im = _reveal(H(3 + i), R(i), lambda x, y, rr=rad: (x - bx) ** 2 + ((y - by) * 0.8) ** 2 < rr * rr)
            draw_circle(im, bx, by, rad * 0.9, acc)
            draw_circle(im, bx, by, 2, WHITE, filled=True)
            frames.append(im)
        tail()
    elif style == "agito":          # Agito: hào quang vàng trên đầu, giáp hiện từ trên xuống
        for i in range(4):
            im = H(i).copy()
            for k in range(-5, 6):
                _put(im, hx + k, hy - 9 - abs(k) // 3, acc)
            draw_circle(im, bx, by, 1 + i, (255, 240, 170, 255), filled=True)
            frames.append(im)
        for i in range(6):
            cut = top + (bot - top) * (i + 1) / 6.0
            im = _reveal(H(4 + i), R(i), lambda x, y, c=cut: y < c)
            for x in range(left - 2, right + 2):
                _put(im, x, cut, (255, 230, 120, 255))
            frames.append(im)
        tail()
    elif style == "mirror":         # Ryuki: bóng gương của Ryuki hội tụ từ hai bên
        for i in range(3):
            frames.append(H(i))
        for i, off in enumerate((26, 20, 14, 9, 5, 2)):
            im = H(3 + i).copy() if i < 4 else R(i).copy()
            _ghost(im, r0, -off, 0, acc, 150)
            _ghost(im, r0, off, 0, (200, 220, 255), 150)
            frames.append(im)
        frames.append(silhouette([r0], WHITE)[0])
        tail(10)
    elif style == "photon":         # Faiz: vạch đỏ Photon Stream chạy từ đai lên xuống, giáp hiện theo
        for i in range(3):
            im = H(i).copy()
            draw_circle(im, bx, by, 1.5 + i * 0.7, (255, 40, 40, 255), filled=True)
            frames.append(im)
        span = max(by - top, bot - by)
        for i in range(7):
            d = span * (i + 1) / 7.0
            im = _reveal(H(3 + i), R(i), lambda x, y, dd=d: abs(y - by) < dd)
            im = _edge(im, (255, 50, 50, 255), lambda x, y, dd=d: abs(abs(y - by) - dd) < 1.5 or abs(x - mid) < 0.8)
            frames.append(im)
        tail()
    elif style == "card":           # Blade: tấm bài Orichalcum lam quét qua người từ trước ra sau
        for i in range(3):
            frames.append(H(i))
        for i in range(7):
            px_ = right + 6 - (right - left + 14) * i / 6.0
            im = _reveal(H(3 + i), R(i), lambda x, y, p=px_: x > p)
            for y in range(top - 3, bot + 2):
                for w in range(3):
                    _put(im, px_ + w, y, (90, 140, 255, 200) if w else (230, 240, 255, 255))
            draw_circle(im, px_ + 1, (top + bot) / 2.0, 2, (255, 210, 80, 255), filled=True)
            frames.append(im)
        tail()
    elif style == "onsa":           # Hibiki: lửa tím bao quanh, rồi bùng ra
        flame = [(170, 90, 255, 255), (255, 140, 60, 255), (255, 220, 120, 255)]
        for i in range(3):
            im = H(i).copy()
            for _ in range(6 + 4 * i):
                _put(im, rnd.uniform(left, right), rnd.uniform(by, bot), rnd.choice(flame))
            frames.append(im)
        for i in range(6):
            im = silhouette([R(i) if i > 2 else H(3 + i)], flame[i % 2])[0]
            for _ in range(30):
                _put(im, rnd.uniform(left - 3, right + 3), rnd.uniform(top - 4, bot), rnd.choice(flame))
            frames.append(im)
        im = R(9).copy()
        for k in range(16):                                     # bùng lửa
            a_ = k * math.pi / 8
            draw_circle(im, mid + math.cos(a_) * 20, (top + bot) / 2 + math.sin(a_) * 24, 1.5, rnd.choice(flame), filled=True)
        frames.append(im)
        tail()
    elif style == "castoff":        # Kabuto: Masked Form (giáp bạc dày) rồi Cast Off, mảnh giáp văng ra
        for i in range(3):
            frames.append(H(i))
        for i in range(3):
            frames.append(silhouette([r0], (150, 155, 170, 255))[0])
        pieces = [(rnd.uniform(left, right), rnd.uniform(top, by), rnd.uniform(0, 2 * math.pi)) for _ in range(10)]
        for i in range(5):
            im = R(i).copy()
            for x0, y0, a_ in pieces:
                d = 4 + i * 6
                draw_circle(im, x0 + math.cos(a_) * d, y0 + math.sin(a_) * d * 0.7 - i, 1.4, (170, 175, 190, 255), filled=True)
            frames.append(im)
        tail(11)
    elif style == "armor_in":       # Den-O: mảnh giáp bay vào từ hai bên ráp lại, mặt nạ trượt xuống ray
        for i in range(3):
            frames.append(H(i))
        for i in range(5):
            im = H(3 + i).copy() if i < 3 else R(i).copy()
            d = 30 - i * 7
            for k, (yy, side) in enumerate(((hy + 4, -1), (by - 6, 1), (by - 2, -1), (hy + 10, 1))):
                for w in range(4):
                    for hgt in range(3):
                        _put(im, mid + side * (d + w), yy + hgt, acc if k % 2 else (220, 225, 235, 255))
            frames.append(im)
        for i in range(2):                                      # mặt nạ trượt xuống
            im = R(i).copy()
            for w in range(-2, 3):
                _put(im, hx + w, hy - 4 + i * 3, acc)
            frames.append(im)
        tail()
    elif style == "chains":         # Kiva: xích bạc quấn quanh rồi vỡ vụn
        for i in range(3):
            frames.append(H(i))
        for i in range(6):
            im = H(3 + i).copy() if i < 2 else R(i).copy()
            n = min(4, i + 1)
            for k in range(n):
                y0 = top + 8 + k * (bot - top - 12) / 4.0
                for x in range(left - 3, right + 4, 2):
                    _put(im, x, y0 + (x - left) * 0.35, (200, 205, 215, 255))
            frames.append(im)
        im = R(9).copy()
        for _ in range(14):                                     # xích vỡ
            _put(im, rnd.uniform(left - 8, right + 8), rnd.uniform(top, bot), (200, 205, 215, 255))
        frames.append(im)
        tail()
    elif style == "decade":         # Decade: bóng các Rider hội tụ từ nhiều phía, rồi tấm barcode cắm vào mũ
        for i in range(3):
            frames.append(H(i))
        for i, rad in enumerate((30, 22, 15, 9, 4)):
            im = H(3 + i).copy() if i < 3 else R(i).copy()
            for k in range(9):
                a_ = k * 2 * math.pi / 9 + i * 0.2
                _ghost(im, r0, int(math.cos(a_) * rad), int(math.sin(a_) * rad * 0.5), acc, 110)
            frames.append(im)
        for i in range(2):                                      # 3 tấm barcode cắm vào mũ
            im = R(i).copy()
            for k in (-2, 0, 2):
                for y in range(int(hy - 10 + i * 5), int(hy - 4 + i * 5)):
                    _put(im, hx + k, y, (20, 18, 22, 255) if k else acc)
            frames.append(im)
        tail()
    elif style == "wind":           # W: gió xoáy, nửa Soul hiện trước rồi tới nửa Body
        swirl = [(90, 230, 110, 255), (160, 90, 220, 255)]
        for i in range(3):
            im = H(i).copy()
            for k in range(8):
                a_ = k * math.pi / 4 + i * 0.6
                _put(im, mid + math.cos(a_) * 14, by + math.sin(a_) * 20, swirl[k % 2])
            frames.append(im)
        for i in range(7):
            half = (lambda x, y: x < mid) if i < 3 else (lambda x, y: True)
            im = _reveal(H(3 + i), R(i), half) if i >= 1 else H(3).copy()
            for k in range(10):
                a_ = k * math.pi / 5 + i * 0.7
                _put(im, mid + math.cos(a_) * (16 - i), by + math.sin(a_) * (24 - i * 2), swirl[k % 2])
            frames.append(im)
        tail()
    elif style == "medals":         # OOO: ba vòng Medal (đỏ / vàng / lục) quét qua đầu, thân, chân rồi ráp lại
        bands = [((255, 70, 60, 255), top, top + (bot - top) * 0.25), ((255, 210, 60, 255), top + (bot - top) * 0.25, by + 4),
                 ((80, 220, 100, 255), by + 4, bot)]
        for i in range(3):
            frames.append(H(i))
        for i in range(6):
            k = min(2, i // 2)
            shown = [bands[j] for j in range(k + 1)] if i % 2 else [bands[j] for j in range(k)]
            im = _reveal(H(3 + i), R(i), lambda x, y, s=shown: any(y0 <= y < y1 for _, y0, y1 in s))
            col, y0, y1 = bands[k]
            for x in range(left - 6, right + 7):
                _put(im, x, (y0 + y1) / 2 + (x - mid) * 0.15, col)
            frames.append(im)
        im = R(9).copy()                                        # vòng tròn ba Medal trên ngực
        draw_circle(im, bx, by - 8, 4, (255, 70, 60, 255))
        draw_circle(im, bx, by - 8, 3, (255, 210, 60, 255))
        draw_circle(im, bx, by - 8, 2, (80, 220, 100, 255))
        frames.append(im)
        tail()
    elif style == "steam":          # Fourze: khói phóng tên lửa bốc lên từ chân, tan ra để lộ Fourze
        for i in range(3):
            frames.append(H(i))
        for i in range(7):
            im = H(3 + i).copy() if i < 3 else R(i).copy()
            puffs = 6 + i * 3 if i < 4 else 18 - (i - 4) * 5
            for _ in range(max(0, puffs)):
                draw_circle(im, rnd.uniform(left - 6, right + 6), rnd.uniform(bot - (bot - top) * min(1.0, 0.3 + i * 0.18), bot),
                            rnd.uniform(1.5, 3.2), (235, 238, 245, 230), filled=True)
            frames.append(im)
        tail()
    elif style == "circle":         # Wizard: vòng phép đỏ (đứng) quét ngang qua người từ trước ra sau
        for i in range(3):
            frames.append(H(i))
        for i in range(7):
            px_ = right + 8 - (right - left + 16) * i / 6.0
            im = _reveal(H(3 + i), R(i), lambda x, y, p=px_: x > p)
            cy, ry = (top + bot) / 2.0, (bot - top) / 2.0 + 4
            for k in range(48):
                a_ = k * 2 * math.pi / 48
                _put(im, px_ + math.cos(a_) * 4, cy + math.sin(a_) * ry, acc)
                if k % 6 == 0:
                    _put(im, px_ + math.cos(a_) * 2, cy + math.sin(a_) * (ry - 4), (255, 220, 120, 255))
            frames.append(im)
        tail()
    elif style == "snap":           # Build: ống Snap Ride Builder dựng quanh người, hai nửa giáp đỏ / lam ép từ hai bên vào
        red_half, blue_half = silhouette([r0], (230, 60, 60, 255))[0], silhouette([r0], (60, 110, 230, 255))[0]
        mid_i = int(mid)
        red_half = red_half.crop((mid_i, 0, red_half.width, red_half.height))
        blue_half = blue_half.crop((0, 0, mid_i, blue_half.height))
        for i in range(3):                                      # quay tay quay: ống dẫn hiện dần quanh người
            im = H(i).copy()
            for y in range(int(top), int(bot), 3):
                if (y // 3) % 3 <= i:
                    _put(im, left - 6, y, (200, 205, 215, 255))
                    _put(im, right + 5, y, (200, 205, 215, 255))
            frames.append(im)
        for i in range(4):                                      # hai nửa giáp trượt từ hai bên ép vào
            im = H(3 + i).copy()
            off = int(16 * (1 - i / 3.0))
            im.alpha_composite(blue_half, (-off, 0))
            im.alpha_composite(red_half, (mid_i + off, 0))
            frames.append(im)
        for i in range(3):                                      # ép xong: Rider hiện ra, vạch sáng giữa hai nửa tắt dần
            im = R(i).copy()
            if i < 2:
                for y in range(int(top), int(bot)):
                    _put(im, mid, y, (255, 240, 150, 255))
            frames.append(im)
        tail()
    elif style == "game":           # Ex-Aid: màn hình chọn nhân vật dựng trước mặt, ô pixel lóe, tấm panel quét qua lộ Rider
        for i in range(3):
            im = H(i).copy()
            for k in range(4 + i * 3):                          # ô pixel game (khối vuông) bay quanh người
                sx, sy = rnd.uniform(left - 8, right + 8), rnd.uniform(top, bot)
                for dx in range(2):
                    for dy in range(2):
                        _put(im, sx + dx, sy + dy, (255, 220, 60, 255) if k % 2 else acc)
            frames.append(im)
        for i in range(7):                                      # panel chọn nhân vật hồng quét từ trước ra sau
            px_ = right + 6 - (right - left + 12) * i / 6.0
            im = _reveal(H(3 + i), R(i), lambda x, y, p=px_: x > p)
            for y in range(int(top) - 2, int(bot) + 2):
                _put(im, px_, y, acc)
                _put(im, px_ + 1, y, (255, 255, 255, 255) if (y // 3) % 2 else acc)
            frames.append(im)
        tail()
    elif style == "parka":          # Ghost: con mắt sáng ở đai, áo choàng hồn ma bay tới trùm lên người rồi Rider hiện ra
        ghost_parka = silhouette([r0], acc)[0]
        for i in range(3):
            im = H(i).copy()
            draw_circle(im, bx, by, 1.5 + i * 0.7, acc, filled=True)
            draw_circle(im, bx, by, 0.8, WHITE, filled=True)
            frames.append(im)
        for i in range(4):                                      # áo choàng mờ bay từ trên sau lưng xuống, chập vào người
            im = H(3 + i).copy()
            t = i / 3.0
            ghost = ghost_parka.copy()
            ghost.putalpha(ghost.getchannel("A").point(lambda a, al=int(90 + 110 * t): min(a, al)))
            im.alpha_composite(ghost, (int(-10 * (1 - t)), int(-12 * (1 - t))))
            frames.append(im)
        for i in range(3):                                      # Rider hiện từ trên xuống sau làn áo
            cut = top + (bot - top) * (i + 1) / 3.0
            im = _reveal(H(7 + i), R(i), lambda x, y, c=cut: y < c)
            for x in range(left - 2, right + 2):
                _put(im, x, cut, acc)
            frames.append(im)
        tail()
    elif style == "tire":           # Drive: lốp xe lăn từ phía trước tới, cài chéo lên ngực rồi giáp hiện từ ngực ra
        tire = lambda im, x, y: (draw_circle(im, x, y, 5, (20, 18, 22, 255), filled=True),
                                 draw_circle(im, x, y, 3, (200, 205, 215, 255)),
                                 draw_circle(im, x, y, 1, acc, filled=True))
        for i in range(3):                                      # vặn Shift Car: đai lóe đỏ
            im = H(i).copy()
            draw_circle(im, bx, by, 1 + i, acc, filled=True)
            frames.append(im)
        for i in range(4):                                      # lốp lăn tới, bật lên ngực
            im = H(3 + i).copy()
            t = (i + 1) / 4.0
            tire(im, right + 14 - (right + 14 - mid) * t, bot - 6 - (bot - 6 - (by - 8)) * t)
            frames.append(im)
        for i, rad in enumerate((8, 16, 30)):                   # giáp lan ra từ lốp trên ngực
            im = _reveal(H(7 + i), R(i), lambda x, y, rr=rad: (x - mid) ** 2 + (y - by + 8) ** 2 < rr * rr)
            if i < 2:
                tire(im, mid, by - 8)
            frames.append(im)
        tail()
    elif style == "arms":           # Gaim: khe nứt mở trên đầu, quả trái cây khổng lồ rơi chụp xuống rồi bung thành giáp
        cx, ry = mid, (bot - top) * 0.15
        cy0 = max(3, top - 6)                                   # độ cao khe nứt (trong khung hình)
        for i in range(4):                                      # khe nứt khóa kéo mở dần, quả cam lộ ra
            im = H(i).copy()
            w_ = 3 + i * 3
            for x in range(int(cx - w_), int(cx + w_) + 1):
                _put(im, x, cy0, (230, 230, 240, 255))
                if (x - int(cx)) % 2 == 0:
                    _put(im, x, cy0 - 1 + ((x // 2) % 2) * 2, (230, 230, 240, 255))
            if i >= 2:
                draw_circle(im, cx, cy0, 1 + i, acc, filled=True)
            frames.append(im)
        for i, cy in enumerate((cy0 + 3, (cy0 + hy) / 2.0, hy)):         # quả rơi xuống trùm lên đầu
            im = H(4 + i).copy()
            draw_circle(im, cx, cy, ry, (20, 18, 22, 255), filled=True)
            draw_circle(im, cx, cy, ry - 1, acc, filled=True)
            _put(im, cx, cy - ry - 1, (70, 170, 70, 255))
            frames.append(im)
        for i in range(3):                                      # giáp bung ra: các múi tách xuống vai, lộ Rider
            im = R(i).copy()
            spread = 3 + i * 4
            for k in (-1, 1):
                draw_circle(im, cx + k * spread, hy + 2 + spread * 0.8, ry * (0.75 - i * 0.2), acc, filled=True)
            frames.append(im)
        tail()
    else:
        return henshin(human_idle, rider_idle, accent)
    return frames[:14]


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


KUUGA_WEAPON = {"kuuga_dragon": "dragon_rod", "kuuga_titan": "titan_sword"}


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
        # Vũ khí Kuuga chỉ hiện khi chém (nút Chém): Dragon Rod, Titan Sword. Pegasus Bowgun là weapons/ lúc bắn.
        weapon = KUUGA_WEAPON.get(prefix)
        slash = swing_weapon(a["light"], weapon, HAND_BAND) if weapon else a["light"]
        sets[prefix] = [
            ("idle", a["idle"], 8, True),
            ("run", a["run"], 12, True),
            ("jump", a["jump"], 6, True),
            ("light", a["light"], light_fps, False),
            ("slash", slash, len(slash) / STYLE_TIME["blade"][0], False),
            ("heavy", a["heavy"], heavy_fps, False),
            ("swap_in", a["heavy"], 28, False),
            ("dodge", a["dodge"], 8, False),
            ("crouch", a["crouch"], 14, False),
            ("hurt", a["hurt"], 18, False),
            ("henshin", henshin_styled("arcle", human_idle, a["idle"], FORM_ACCENT[prefix]), 12, False),
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


def with_slash(conv, weapon):
    """Biến đổi form có vũ khí cận chiến: conv (hoặc None) cho mọi animation, thêm vũ khí vào animation "slash"."""
    base = conv or (lambda fr: fr)
    return {"*": base, "slash": lambda fr: swing_weapon(base(fr), weapon, HAND_BAND)}


def apply_conv(conv, anim, frames):
    """Biến đổi của một form trong DATA_RIDERS: None, một hàm cho mọi animation, hoặc dict {animation: hàm hoặc
    None} với "*" cho các animation còn lại (ví dụ vũ khí chỉ hiện khi ra đòn)."""
    if isinstance(conv, dict):
        conv = conv.get(anim, conv.get("*"))
    return conv(frames) if conv else frames


# prefix animation → (thư mục PixelLab, file thế giới lấy kiểu đòn hoặc None,
#                     {form: (biến đổi, màu vòng biến hình[, thư mục hình riêng của form])})
DATA_RIDERS = {
    # Agito: ảnh gốc Ground Form vẽ lại theo nguyên tác (mũ / ngực vàng, sừng Crossed Horn) bằng PixelLab Pro Flash edit,
    # 5 animation bằng PixelLab animate_image (art/pixelengine/agito_canon/). Các form bất đối xứng như phim: Storm lam ở
    # vai / tay / ngực TRÁI, Flame đỏ ở bên PHẢI, Trinity cả hai. Nhân vật quay phải nên bên trái là nửa trước (gần người
    # xem), bên phải là nửa sau. Vũ khí chỉ vẽ vào animation "slash": Storm Halberd, Flame Saber.
    "agito": ("agito_canon", "w02_agito", {
        "ground": (None, (255, 200, 60, 255)),
        "storm": (with_slash(lambda fr: split_recolor(fr, lambda c, up: c, hue_rule(is_gold, GOLD_TO(0.6), keep_head=True)),
                             "halberd"), (90, 150, 255, 255)),
        "flame": (with_slash(lambda fr: split_recolor(fr, hue_rule(is_gold, GOLD_TO(0.99), keep_head=True), lambda c, up: c),
                             "flame_saber"), (255, 80, 60, 255)),
        "trinity": (with_slash(lambda fr: split_recolor(fr, hue_rule(is_gold, GOLD_TO(0.99), keep_head=True),
                                                        hue_rule(is_gold, GOLD_TO(0.6), keep_head=True)), "flame_saber"),
                    (255, 230, 150, 255)),
    }),
    "ryuki": ("ryuki_canon", "w03_ryuki", {   # hình nguyên tác: art/pixelengine/ryuki_canon (PixelEngine + PixelLab)
        "ryuki": (None, (255, 80, 70, 255)),
        "sword_vent": ({"slash": lambda fr: swing_weapon(fr, "sword", HAND_BAND)}, (255, 200, 90, 255)),
        "strike_vent": (lambda fr: add_weapon(fr, "claw", HAND_BAND), (255, 120, 40, 255)),
        "guard_vent": (lambda fr: add_weapon(fr, "shield", HAND_BAND), (220, 225, 235, 255)),
        # Final form Survive (mở ở Lv5): giáp bạc thành vàng, đỏ đậm hơn; chém bằng lưỡi Dragvisor-Zwei
        "survive": (with_slash(lambda fr: recolor(recolor(fr, hue_rule(lambda h, s, v: s < 0.25 and v > 0.5,
                                                                          lambda h, s, v: (0.12, 0.72, min(1.0, v * 1.02)))),
                                                  hue_rule(is_red_hsv, lambda h, s, v: (0.985, min(1.0, s * 1.1), v * 0.88))),
                               "sword"), (255, 170, 40, 255)),
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
    # Hibiki: dùi trống đeo sau lưng, chỉ rút ra khi dùng: Onibi phun lửa từ dùi Ongekibou Rekka (weapons/onibi.png lúc
    # bắn), Kaentsuzumi đánh bằng trống Ongekiko (vẽ vào cú đấm, nút Đánh dùng trống). Hibiki Kurenai toàn thân đỏ thẫm,
    # chém bằng dùi Rekka lửa (animation "slash").
    "hibiki": ("hibiki", "w06_hibiki", {
        "hibiki": (None, (180, 120, 255, 255)),
        "onibi": (None, (255, 140, 50, 255)),
        "kaentsuzumi": ({"light": lambda fr: add_weapon(fr, "drum", HAND_BAND)}, (255, 190, 70, 255)),
        "kurenai": (with_slash(lambda fr: recolor(fr, hue_rule(is_purple, lambda h, s, v: (0.985, s, min(1.0, v * 1.2)))),
                               "rekka"), (255, 60, 60, 255)),
    }),
    # Kabuto: Rider Form và Hyper Form (hình riêng làm bằng PixelEngine, art/pixelengine/kabuto_hyper/).
    "kabuto": ("kabuto", "w07_kabuto", {
        "rider": (None, (255, 70, 70, 255)),
        "hyper": (None, (235, 235, 255, 255), "kabuto_hyper"),
    }),
    # Den-O: mỗi form là một Imagin nhập vào, đổi cả mặt nạ lẫn giáp ngực. Sword Form ảnh gốc PixelEngine, 3 form
    # còn lại sửa từ ảnh đó bằng PixelLab Pro Flash edit; 5 animation mỗi form bằng PixelLab animate_image.
    # DenGasher ráp theo Imagin, chỉ hiện khi dùng: kiếm / cần / rìu ở animation "slash", súng là weapons/dengasher_gun.png.
    "den_o": ("den_o", "w08_den_o", {
        "sword": (with_slash(None, "dengasher_sword"), (255, 70, 70, 255)),
        "rod": (with_slash(None, "dengasher_rod"), (80, 140, 255, 255), "den_o_rod"),
        "ax": (with_slash(None, "dengasher_axe"), (255, 210, 70, 255), "den_o_ax"),
        "gun": (None, (180, 100, 255, 255), "den_o_gun"),
    }),
    # Kiva: Arms Monster nhập vào đổi màu mắt và giáp ngực / tay (Garulu lam, Basshaa lục, Dogga tím), chân giữ nguyên.
    "kiva": ("kiva", "w09_kiva", {
        "kiva": (None, (255, 70, 90, 255)),
        # Vũ khí Arms Monster chỉ hiện khi dùng: Garulu Saber / Dogga Hammer (slash), Basshaa Magnum lúc bắn.
        "garulu": (with_slash(lambda fr: recolor(fr, kiva_rule(0.62), head=0.55), "garulu_saber"), (100, 140, 255, 255)),
        "basshaa": (lambda fr: recolor(fr, kiva_rule(0.42), head=0.55), (80, 230, 180, 255)),
        "dogga": (with_slash(lambda fr: recolor(fr, kiva_rule(0.76), head=0.55), "dogga_hammer"), (170, 100, 230, 255)),
    }),
    # Decade: ảnh gốc sửa từ Kiva bằng PixelLab Pro Flash edit, 5 animation bằng PixelLab animate_image. Attack Ride
    # Slash / Blast là lá bài: giữ ngoại hình, cầm Ride Booker (kiếm / súng). Kamen Ride: Kabuto biến thành Kabuto thật
    # nên dùng lại hình Kabuto Rider Form (art/pixelengine/kabuto/).
    "decade": ("decade", "w10_decade", {
        "decade": (None, (235, 60, 150, 255)),
        "slash": ({"slash": lambda fr: swing_weapon(fr, "booker_sword", HAND_BAND)}, (255, 120, 200, 255)),
        "blast": (None, (255, 90, 190, 255)),     # súng Ride Booker: weapons/booker_gun.png, hiện lúc bắn
        "kabuto": (None, (255, 70, 70, 255), "kabuto"),
    }),
    # OOO: ảnh gốc TaToBa sửa từ Decade bằng PixelLab Pro Flash edit, 5 animation bằng PixelLab animate_image (khung
    # trúng đòn đã xoá tia sáng AI vẽ đè). 7 combo cùng hệ đổi màu toàn thân (ooo_rule) và cầm vũ khí của combo.
    "ooo": ("ooo", "w12_ooo", {
        "tatoba": (None, (255, 70, 70, 255)),
        "latorartar": (lambda fr: add_weapon(recolor(fr, ooo_rule((0.13, 1.0))), "tora", HAND_BAND),
                       (255, 210, 60, 255)),
        "shauta": ({"*": lambda fr: recolor(fr, ooo_rule((0.6, 0.9))),
                    "slash": lambda fr: swing_weapon(recolor(fr, ooo_rule((0.6, 0.9))), "whip", HAND_BAND)},
                   (70, 140, 255, 255)),
        "sagohzo": (lambda fr: add_weapon(recolor(fr, ooo_rule(None)), "gorilla", HAND_BAND), (200, 200, 210, 255)),
        "gatakiriba": ({"*": lambda fr: recolor(fr, ooo_rule((0.36, 1.0, 0.72))),
                        "slash": lambda fr: swing_weapon(recolor(fr, ooo_rule((0.36, 1.0, 0.72))), "kamakiri", HAND_BAND)},
                       (90, 230, 100, 255)),
        "tajador": (lambda fr: add_weapon(recolor(fr, ooo_rule((0.99, 1.0))), "spinner", HAND_BAND), (255, 90, 50, 255)),
        "putotyra": ({"*": lambda fr: recolor(fr, ooo_rule((0.76, 0.85))),
                      "slash": lambda fr: swing_weapon(recolor(fr, ooo_rule((0.76, 0.85))), "medagabryu", HAND_BAND)},
                     (170, 100, 240, 255)),
        "burakawani": (lambda fr: add_weapon(recolor(fr, ooo_rule((0.07, 0.95))), "kame", HAND_BAND),
                       (240, 130, 50, 255)),
    }),
    # Fourze: ảnh gốc Base States sửa từ Decade bằng PixelLab Pro Flash edit, 5 animation bằng PixelLab animate_image
    # (khung trúng đòn đã xoá tia lửa AI vẽ đè). Rocket gắn Rocket Module; Elek / Fire giáp trắng thành vàng / đỏ (giữ
    # mũ trắng) và cầm Billy the Rod / Hee-Hackgun.
    "fourze": ("fourze", "w13_fourze", {
        "base_states": (None, (245, 245, 250, 255)),
        "rocket": (lambda fr: add_weapon(fr, "rocket", HAND_BAND), (255, 130, 40, 255)),
        "elek": ({"*": lambda fr: recolor(fr, FOURZE_TO(0.13, 0.75, 0.95)),
                  "slash": lambda fr: swing_weapon(recolor(fr, FOURZE_TO(0.13, 0.75, 0.95)), "billy", HAND_BAND)},
                 (255, 225, 60, 255)),
        "fire": (lambda fr: recolor(fr, FOURZE_TO(0.0, 0.8, 0.9)), (255, 70, 50, 255)),   # Hee-Hackgun lúc bắn
    }),
    # Wizard: ảnh gốc Flame Style sửa từ Decade bằng PixelLab Pro Flash edit, 5 animation bằng PixelLab animate_image
    # (gọi API trực tiếp; khung trúng đòn đã xoá chớp sáng AI vẽ đè, khung đầu thay bằng ảnh gốc). Mỗi Style đổi màu đá
    # quý ở mặt và áo (ruby đỏ → sapphire lam / emerald lục / topaz vàng). Vũ khí chỉ hiện khi dùng: Hurricane chém bằng
    # WizarSwordGun dạng kiếm (animation "slash"), Water bắn bằng dạng súng (weapons/wizargun.png).
    "wizard": ("wizard", "w14_wizard", {
        "flame": (None, (255, 70, 60, 255)),
        "water": (lambda fr: recolor(fr, WIZARD_TO(0.6, 1.1)), (80, 140, 255, 255)),   # WizarSwordGun súng lúc bắn
        "hurricane": ({"*": lambda fr: recolor(fr, WIZARD_TO(0.38, 1.1)),
                       "slash": lambda fr: swing_weapon(recolor(fr, WIZARD_TO(0.38, 1.1)), "wizarsword", HAND_BAND)},
                      (90, 230, 120, 255)),
        "land": (lambda fr: recolor(fr, WIZARD_TO(0.13, 1.25, 0.95)),
                 (255, 210, 60, 255)),
    }),
    # Gaim: ảnh gốc Orange Arms sửa từ Decade bằng PixelLab Pro Flash edit, 5 animation bằng PixelLab animate_image.
    # Mỗi Arms đổi màu giáp vai / ngực (giữ mũ): Pine nâu vàng dứa, Ichigo đỏ dâu, Jimber Lemon vàng chanh. Vũ khí chỉ hiện
    # khi dùng: Daidaimaru / Pine Iron ở animation "slash", Ichigo Kunai / Sonic Arrow là weapons/<tên>.png lúc bắn.
    "gaim": ("gaim", "w15_gaim", {
        "orange": (with_slash(None, "daidaimaru"), (255, 140, 30, 255)),
        "pine": (with_slash(lambda fr: recolor(fr, GAIM_TO(0.1, 0.85, 0.72)), "pine_iron"), (220, 170, 50, 255)),
        "ichigo": (lambda fr: recolor(fr, GAIM_TO(0.98, 0.85, 0.95)), (255, 70, 80, 255)),
        "jimber_lemon": (lambda fr: recolor(fr, GAIM_TO(0.15, 0.8, 1.15)), (255, 230, 80, 255)),
    }),
    # Drive: ảnh gốc Type Speed sửa từ Decade bằng PixelLab Pro Flash edit, 5 animation bằng PixelLab animate_image.
    # Mỗi Type đổi màu thân đỏ (giữ mắt đèn pha vàng): Wild đen bạc, Technic xanh lá, Formula xanh lam. Vũ khí chỉ hiện
    # khi dùng: Handle-Ken / Rumble Dump ở animation "slash", Door-Ju là weapons/door_ju.png lúc bắn.
    "drive": ("drive", "w16_drive", {
        "speed": (with_slash(None, "handle_ken"), (255, 60, 60, 255)),
        "wild": (with_slash(lambda fr: recolor(fr, DRIVE_TO(0.6, 0.12, 0.55)), "rumble_dump"), (210, 210, 225, 255)),
        "technic": (lambda fr: recolor(fr, DRIVE_TO(0.36, 0.8, 1.0)), (90, 240, 110, 255)),
        "formula": (lambda fr: recolor(fr, DRIVE_TO(0.6, 0.85, 1.05)), (80, 140, 255, 255)),
    }),
    # Ghost: ảnh gốc Ore Damashii sửa từ Decade bằng PixelLab Pro Flash edit (gọi API trực tiếp bằng key mới), 5 animation
    # bằng PixelLab animate_image. Mỗi Damashii đổi màu mảng cam (mặt, vân, viền áo): Musashi đỏ, Edison vàng, Newton
    # lam. Vũ khí chỉ hiện khi dùng: Gan Gun Saber (Ore) / song kiếm (Musashi) ở "slash", súng là weapons/gangun.png.
    "ghost": ("ghost", "w17_ghost", {
        "ore": (with_slash(None, "gangunsaber"), (255, 140, 40, 255)),
        "musashi": (with_slash(lambda fr: recolor(fr, GHOST_TO(0.99, 0.85, 1.0)), "nito"), (255, 70, 60, 255)),
        "edison": (lambda fr: recolor(fr, GHOST_TO(0.14, 0.8, 1.15)), (255, 230, 80, 255)),
        "newton": (lambda fr: recolor(fr, GHOST_TO(0.6, 0.8, 1.05)), (90, 140, 255, 255)),
    }),
    # Ex-Aid: ảnh gốc Level 2 sửa từ Decade bằng PixelLab Pro Flash edit, 5 animation bằng PixelLab animate_image. Level 3 /
    # 5 giữ thân hồng, chỉ đổi màu dải giáp vai-ngực (exaid_armor): Sports lam ngọc, Robot đỏ (tay robot luôn trên tay
    # trước), Hunter xanh lá. Gashacon Breaker / kiếm rồng ở "slash"; bánh xe Tricker / súng rồng là weapons/<tên>.png.
    "ex_aid": ("ex_aid", "w18_ex_aid", {
        "action_gamer": (with_slash(None, "gashacon_breaker"), (255, 90, 190, 255)),
        "sports": (lambda fr: exaid_armor(fr, 0.48, 0.75, 1.05), (80, 230, 215, 255)),
        "robot": (lambda fr: add_weapon(exaid_armor(fr, 0.0, 0.8, 0.95), "robot_arm", HAND_BAND), (240, 80, 80, 255)),
        "hunter": (with_slash(lambda fr: exaid_armor(fr, 0.33, 0.75, 0.95), "drago_blade"), (110, 230, 90, 255)),
    }),
    # Build: ảnh gốc RabbitTank sửa từ Decade bằng PixelLab Pro Flash edit, 5 animation bằng PixelLab animate_image. Mỗi Best
    # Match đổi màu hai nửa (BUILD_TO): GorillaMond nâu / kim cương lam nhạt, HawkGatling cam / xám bạc, NinninComic tím /
    # vàng. Drill Crusher / Ninpoutou ở "slash", Hawk Gatlinger là weapons/hawk_gatlinger.png lúc bắn.
    "build": ("build", "w19_build", {
        "rabbit_tank": (with_slash(None, "drill_crusher"), (255, 80, 80, 255)),
        "gorilla_mond": (lambda fr: recolor(fr, BUILD_TO((0.07, 0.65, 0.7), (0.52, 0.35, 1.3))), (140, 220, 255, 255)),
        "hawk_gatling": (lambda fr: recolor(fr, BUILD_TO((0.07, 0.85, 1.05), (0.6, 0.08, 1.1))), (255, 150, 60, 255)),
        "ninnin_comic": (with_slash(lambda fr: recolor(fr, BUILD_TO((0.78, 0.65, 1.0), (0.14, 0.85, 1.25))), "ninpoutou"),
                         (190, 110, 255, 255)),
    }),
    # W có script riêng (double.gd): tiền tố "double_<soul><body>[xtreme]", 9 tổ hợp + CycloneJokerXtreme. Ảnh gốc
    # CycloneJoker sửa từ Decade bằng PixelLab Pro Flash edit; 9 tổ hợp còn lại đổi màu hai nửa (double_rule).
    "double": ("double", None, dict(
        [(s + b, (double_form(s, b), W_ACCENT[s])) for s in W_SOULS for b in W_BODIES]
        + [("cyclonejokerxtreme", (double_form("cyclone", "joker", True), (200, 255, 230, 255)))])),
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
        "idle": idle, "run": A("run"), "jump": A("run", [1]), "light": A("light"), "slash": A("light"), "heavy": A("heavy"),
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
            if isinstance(conv, dict) and "final" in conv:     # biến đổi riêng cho cảnh Final (sừng Agito bung ra)
                final = conv["final"](final)
            name = prefix + ("_" + form if form else "")
            sets[name] = [
                ("idle", a["idle"], 8, True),
                ("run", a["run"], 12, True),
                ("jump", a["jump"], 6, True),
                ("light", a["light"], len(a["light"]) / light_t, False),
                ("slash", a["slash"], len(a["slash"]) / STYLE_TIME["blade"][0], False),   # nút Chém, có vũ khí
                ("heavy", a["heavy"], len(a["heavy"]) / kick_t, False),
                ("swap_in", a["heavy"], 28, False),
                ("dodge", a["dodge"], 8, False),
                ("crouch", a["crouch"], 14, False),
                ("hurt", a["hurt"], 18, False),
                ("henshin", henshin_styled(HENSHIN_STYLE.get(prefix, ""), human_idle, a["idle"], accent), 12, False),
                ("final", final, len(final) / final_t, False),
            ]
    return sets


GUN_LOOKS = ["hawk_gatlinger", "tricker", "drago_gun", "gangun", "door_ju", "ichigo_kunai", "sonic_arrow", "wizargun", "booker_gun", "magnum", "hackgun", "gun", "onibi", "dengasher_gun", "basshaa_magnum",
             "pegasus_bowgun", "faiz_phone", "faiz_blaster"]   # súng hiện ở tay lúc bắn (RiderForm.gun_look)


def export_weapons():
    """Súng → art/characters/weapons/<tên>.png: vẽ bằng add_weapon quanh một "bàn tay" ở (2, giữa), báng ở mép trái,
    nòng ở mép phải. Player xoay theo hướng bắn."""
    out_dir = os.path.join(OUT_DIR, "weapons")
    os.makedirs(out_dir, exist_ok=True)
    for kind in GUN_LOOKS:
        im = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
        im.putpixel((2, 8), (1, 1, 1, 255))                 # điểm bàn tay để add_weapon bám vào
        im = add_weapon([im], kind, (0.0, 1.0))[0]
        if im.getpixel((2, 8)) == (1, 1, 1, 255):
            im.putpixel((2, 8), (0, 0, 0, 0))
        box = im.getbbox()
        im.crop((0, box[1], box[2], box[3])).save(os.path.join(out_dir, kind + ".png"))


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


# thư mục PixelLab → {tên sprite đổi màu: rule}. Rỗng = trùm, hoặc quái ghép đã tự có màu riêng.
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
    # thế giới 4–27: quái ghép bằng tools/kitbash.py (bảng KITBASH), mỗi dòng một thế giới: thường, nhanh, giáp
    "orphnoch_wolf": {}, "orphnoch_fast": {}, "orphnoch_armored": {},
    "darkroach": {}, "jaguar_undead": {}, "trilobite_undead": {},
    "kappa": {}, "ittanmomen": {}, "bakegani": {},
    "salis_worm": {}, "musca_worm": {}, "cochlea_worm": {},
    "mole_imagin": {}, "bat_imagin": {}, "rhino_imagin": {},
    "spider_fangire": {}, "horse_fangire": {}, "moose_fangire": {},
    "dai_shocker": {}, "okami_otoko": {}, "kanibubbler": {},
    "masquerade_dopant": {}, "bird_dopant": {}, "rhino_dopant": {},
    "waste_yummy": {}, "neko_yummy": {}, "bison_yummy": {},
    "dustard": {}, "unicorn_zodiarts": {}, "orion_zodiarts": {},
    "ghoul": {}, "hellhound": {}, "minotaurus": {},
    "elementary_inves": {}, "komori_inves": {}, "shika_inves": {},
    "roidmude_spider": {}, "roidmude_bat": {}, "roidmude_cobra": {},
    "gamma_command": {}, "katana_gamma": {}, "gamma_ultima": {},
    "bugster_virus": {}, "charlie_bugster": {}, "gatton_bugster": {},
    "guardian": {}, "flying_smash": {}, "strong_smash": {},
    "kasshine": {}, "another_faiz": {}, "another_build": {},
    "trilobite_magia": {}, "berotha_magia": {}, "dodo_magia": {},
    "shimi": {}, "piranha_megid": {}, "golem_megid": {},
    "giffjunior": {}, "deadman": {}, "deadman_armored": {},
    "pawn_jyamato": {}, "knight_jyamato": {}, "rook_jyamato": {},
    "dreadrooper": {}, "malgam": {}, "malgam_armored": {},
    "agent": {}, "granute": {}, "granute_armored": {},
    "nightmare": {}, "crow_nightmare": {}, "bomb_nightmare": {},
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
    export_weapons()
    enemies, cells = build_enemies()
    n1 = save_sets(player, cell, "player", "player_frames.tres")
    n2 = save_sets(enemies, cells, "enemies", "enemy_frames.tres")
    if "--preview" in sys.argv:
        write_previews(sys.argv[sys.argv.index("--preview") + 1], [player, enemies])
    print("Người chơi: %d frame (%d bộ) · Quái: %d frame (%d bộ) → %s" % (n1, len(player), n2, len(enemies), OUT_DIR))


if __name__ == "__main__":
    main()
