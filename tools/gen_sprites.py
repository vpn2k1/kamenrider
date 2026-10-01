#!/usr/bin/env python3
"""
Sinh sprite pixel vẽ bằng code (bản DỰ PHÒNG) cho nhân vật chính và 5 form Kuuga.
Game hiện dùng hình PixelLab (tools/import_pixellab.py → art/characters/player_frames.tres);
script này chỉ ghi vào art/characters/procedural/, dùng khi cần hình tạm cho Rider chưa có art.

    python3 tools/gen_sprites.py              # ghi vào art/characters/
    python3 tools/gen_sprites.py --preview D  # thêm ảnh xem trước (phóng to) và GIF vào thư mục D

Cách hoạt động: mỗi nhân vật là một "con rối" gồm đầu và thân vẽ bằng chữ (ASCII), tay chân là các đoạn
thẳng nối khớp. Mỗi frame là một bộ góc khớp. Vẽ xong thì tự thêm viền tối kiểu pixel art.
Mọi sprite quay mặt sang phải; Godot tự lật khi nhân vật quay trái.

Đầu ra:
  art/characters/procedural/<tiền tố>.png   sprite sheet: mỗi hàng một animation, ô 64x48, chân chạm đáy ô
  art/characters/procedural/player_frames_procedural.tres (tên animation "<tiền tố>_<hành động>")
Khi có art vẽ tay: thay file PNG (giữ vị trí ô) hoặc tạo SpriteFrames mới với cùng tên animation.
"""
import math
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "art", "characters", "procedural")
RES_DIR = "res://art/characters/procedural"
CW, CH = 64, 48          # kích thước một ô
GROUND = 46              # hàng pixel chân chạm đất
CX = 31                  # tâm ngang của cơ thể
CLEAR = (0, 0, 0, 0)


def rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def shade(c, f):
    return (min(255, int(c[0] * f)), min(255, int(c[1] * f)), min(255, int(c[2] * f)), c[3])


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def vec(angle_deg, length):
    """Góc 0 = chĩa xuống, 90 = chĩa về phía trước (phải), 180 = chĩa lên."""
    r = math.radians(angle_deg)
    return (math.sin(r) * length, math.cos(r) * length)


def add(p, v):
    return (p[0] + v[0], p[1] + v[1])


OUTLINE = rgb("16121e")
WHITE = rgb("ffffff")


# --- Bề mặt vẽ ----------------------------------------------------------------

class Layer:
    def __init__(self):
        self.img = Image.new("RGBA", (CW, CH), CLEAR)
        self.px = self.img.load()

    def set(self, x, y, c):
        x, y = int(x), int(y)
        if c is not None and 0 <= x < CW and 0 <= y < CH:
            self.px[x, y] = c

    def stamp(self, x, y, size, c):
        o = (size - 1) / 2.0
        for dx in range(size):
            for dy in range(size):
                self.set(math.floor(x - o + dx + 0.5), math.floor(y - o + dy + 0.5), c)

    def line(self, p0, p1, size, c):
        steps = max(1, int(math.dist(p0, p1) * 3))
        for i in range(steps + 1):
            p = lerp(p0, p1, i / steps)
            self.stamp(p[0], p[1], size, c)

    def ascii(self, rows, x0, y0, pal):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch != ".":
                    self.set(x0 + i, y0 + j, pal[ch])

    def circle(self, cx, cy, r, c, filled=False):
        if filled:
            for y in range(int(cy - r) - 1, int(cy + r) + 2):
                for x in range(int(cx - r) - 1, int(cx + r) + 2):
                    if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                        self.set(x, y, c)
        else:
            n = max(8, int(r * 8))
            for i in range(n):
                a = 2 * math.pi * i / n
                self.set(round(cx + math.cos(a) * r), round(cy + math.sin(a) * r), c)


def outline(img):
    src = img.load()
    out = img.copy()
    o = out.load()
    for y in range(CH):
        for x in range(CW):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < CW and 0 <= ny < CH and src[nx, ny][3]:
                    o[x, y] = OUTLINE
                    break
    return out


def recolor(img, c):
    px = img.load()
    for y in range(CH):
        for x in range(CW):
            if px[x, y][3]:
                px[x, y] = c


# --- Nhân vật -----------------------------------------------------------------

HUMAN = {
    "head": [
        ".hhhhh..",
        "hhhhhhh.",
        "hhhhhhhh",
        "hhhhsssh",
        "hhhsseSs",
        ".hhsssss",
        ".hhssss.",
        "...ss...",
    ],
    "head_off": (0, -7),
    "torso": [
        ".jjjjj..",
        "jjjjjjj.",
        "jjjyjjj.",
        "jjjyjjjj",
        "jjjyjjjj",
        "jjjyjjj.",
        "jjjjjjj.",
        "kkkkkkk.",
        "ppppppp.",
    ],
    "shoulder": (3, 1),
    "hip": (3, 8),
    "arm": (5, 5), "arm_w": 2,
    "leg": (6, 6), "leg_w": 2,
    "pal": {
        "h": rgb("3b2a22"), "s": rgb("f2c29b"), "S": rgb("d49a78"), "e": rgb("1a1422"),
        "j": rgb("2f6fd6"), "y": rgb("f4c542"), "k": rgb("2a2230"), "p": rgb("3c4660"),
        "f": rgb("d94a3a"), "g": rgb("e8283a"), "m": rgb("c8ccd8"),
    },
    "arm_parts": {"upper": "j", "fore": "j", "hand": "s"},
    "leg_parts": {"thigh": "p", "shin": "p", "foot": "f"},
    "accent": rgb("ffe8b0"),
}

KUUGA_HEAD = [
    "......YY..",
    ".....YY...",
    "...bYYbb..",
    "..bbbbRRR.",
    ".bbbbRRRRR",
    ".bbbbRRRWR",
    ".bbbbbRRR.",
    "..bbbbbMM.",
    "...bbbbM..",
]
KUUGA_HEAD_GROWING = [
    "..........",
    "..........",
    "...bbYbb..",
    "..bbbbRRR.",
    ".bbbbRRRRR",
    ".bbbbRRRWR",
    ".bbbbbRRR.",
    "..bbbbbMM.",
    "...bbbbM..",
]
KUUGA_TORSO = [
    "..aaaaaa..",
    ".aaAAaaaa.",
    "aaaAAaaaaa",
    "aaaaaaaaab",
    "baaaaaaab.",
    "bbaaaaabb.",
    ".bbbbbbbb.",
    ".bbbbbbbb.",
    "mmmmmmmgg.",
    "mmmmmmgGGg",
    ".bbbbbbbb.",
    ".bbbbbbbb.",
]
KUUGA_BASE_PAL = {
    "b": rgb("363446"), "m": rgb("c8ccd8"), "M": rgb("aab0c0"), "g": rgb("e8283a"), "G": rgb("ff9aa0"),
    "Y": rgb("f2c230"), "W": WHITE, "k": rgb("2c2a3a"), "y": rgb("f2c230"),
}
KUUGA_FORMS = {
    # tiền tố: (màu giáp, màu giáp sáng, màu mắt, vũ khí, đầu)
    "kuuga_growing": ("e4e4ec", "ffffff", "ff8a2a", None, KUUGA_HEAD_GROWING),
    "kuuga_mighty": ("d8262e", "ff6a6a", "ff2a3a", None, KUUGA_HEAD),
    "kuuga_dragon": ("2f6fe0", "7fb0ff", "3a9cff", "rod", KUUGA_HEAD),
    "kuuga_pegasus": ("2fae4a", "7fe08f", "3adf5a", "bow", KUUGA_HEAD),
    "kuuga_titan": ("7a3fc8", "c8ccd8", "b060ff", "sword", KUUGA_HEAD),
}


def kuuga_char(prefix):
    armor, armor_light, eye, weapon, head = KUUGA_FORMS[prefix]
    pal = dict(KUUGA_BASE_PAL)
    pal.update({"a": rgb(armor), "A": rgb(armor_light), "R": rgb(eye)})
    return {
        "head": head, "head_off": (0, -8),
        "torso": KUUGA_TORSO, "shoulder": (4, 2), "hip": (4, 11),
        "arm": (6, 6), "arm_w": 3,
        "leg": (7, 7), "leg_w": 3,
        "pal": pal,
        "arm_parts": {"upper": "b", "fore": "b", "hand": "k", "pad": "a", "bracer": "a"},
        "leg_parts": {"thigh": "b", "shin": "b", "foot": "k", "anklet": "y"},
        "weapon": weapon,
        "fire": prefix == "kuuga_mighty",
        "accent": rgb(armor_light) if prefix != "kuuga_growing" else rgb("ffe8b0"),
    }


# --- Tư thế -------------------------------------------------------------------

def P(ba=(10, 20), fa=(20, 30), bl=(-8, 6), fl=(10, 6), bob=0, lean=0, air=0, wa=None, fx=(),
      silhouette=None, eyes=None, rider=True):
    """ba/fa: tay sau/trước (góc vai, độ gập khuỷu). bl/fl: chân sau/trước (góc hông, độ gập gối).
    wa: góc vũ khí (mặc định vuông góc cẳng tay). fx: hiệu ứng vẽ đè không có viền."""
    return dict(ba=ba, fa=fa, bl=bl, fl=fl, bob=bob, lean=lean, air=air, wa=wa, fx=list(fx),
                silhouette=silhouette, eyes=eyes)


def render(char, p):
    pal = char["pal"]
    back = {k: shade(v, 0.7) for k, v in pal.items()}
    if p["eyes"]:
        pal = dict(pal, R=p["eyes"], W=p["eyes"])

    L1, L2 = char["leg"]

    def leg_geo(hip, a, k):
        knee = add(hip, vec(a, L1))
        ankle = add(knee, vec(a - k, L2))
        return knee, ankle

    lowest = max(leg_geo((0, 0), *p["bl"])[1][1], leg_geo((0, 0), *p["fl"])[1][1])
    hip = (CX, GROUND - 2 - p["air"] - lowest)
    ub = (hip[0] + p["lean"], hip[1] + p["bob"])            # điểm hông của phần thân trên
    tx = ub[0] - char["hip"][0]
    ty = ub[1] - char["hip"][1]
    shoulder = (tx + char["shoulder"][0], ty + char["shoulder"][1])
    anchors = {"belt": (ub[0] + 1, ub[1] - 2), "head": (tx + 6, ty - 4), "chest": (tx + 5, ty + 4)}

    body = Layer()

    def draw_leg(hp, a, k, pl, key):
        parts = char["leg_parts"]
        w = char["leg_w"]
        knee, ankle = leg_geo(hp, a, k)
        body.line(hp, knee, w, pl[parts["thigh"]])
        body.line(knee, ankle, w, pl[parts["shin"]])
        if parts.get("anklet"):
            body.stamp(*lerp(knee, ankle, 0.85), w, pl[parts["anklet"]])
        toe = add(ankle, vec(a - k + 90, 3))
        body.line(add(ankle, vec(a - k, 1)), add(toe, vec(a - k, 1)), 2, pl[parts["foot"]])
        anchors[key] = toe

    def draw_arm(sh, a, e, pl, key, weapon=None):
        parts = char["arm_parts"]
        w = char["arm_w"]
        U, F = char["arm"]
        elbow = add(sh, vec(a, U))
        hand = add(elbow, vec(a + e, F))
        body.line(sh, elbow, w, pl[parts["upper"]])
        if parts.get("bracer"):
            mid = lerp(elbow, hand, 0.4)
            body.line(elbow, mid, w, pl[parts["fore"]])
            body.line(mid, hand, w, pl[parts["bracer"]])
        else:
            body.line(elbow, hand, w, pl[parts["fore"]])
        if parts.get("pad"):
            body.stamp(sh[0], sh[1] + 0.5, w + 1, pl[parts["pad"]])
        if weapon:
            ang = p["wa"] if p["wa"] is not None else a + e + 90
            anchors["tip"] = draw_weapon(body, hand, weapon, ang)
        body.stamp(hand[0], hand[1], w, pl[parts["hand"]])
        anchors[key] = hand

    draw_arm((shoulder[0] - 1, shoulder[1]), *p["ba"], back, "bhand")
    draw_leg((hip[0] - 1, hip[1]), *p["bl"], back, "bfoot")
    draw_leg((hip[0] + 1, hip[1]), *p["fl"], pal, "ffoot")
    body.ascii(char["torso"], tx, ty, pal)
    hx, hy = char["head_off"]
    body.ascii(char["head"], tx + hx, ty + hy, pal)
    draw_arm((shoulder[0] + 1, shoulder[1]), *p["fa"], pal, "fhand", char.get("weapon"))

    if p["silhouette"]:
        recolor(body.img, p["silhouette"])
    img = outline(body.img)

    fx = Layer()
    fx.img = img
    fx.px = img.load()
    for effect in p["fx"]:
        draw_fx(fx, effect, anchors, char)
    return fx.img


def draw_weapon(layer, hand, kind, ang):
    d = vec(ang, 1)
    if kind == "rod":
        a, b = add(hand, (-d[0] * 8, -d[1] * 8)), add(hand, (d[0] * 15, d[1] * 15))
        layer.line(a, b, 2, rgb("9fd0ff"))
        layer.stamp(*a, 2, rgb("f2c230"))
        layer.stamp(*b, 2, rgb("f2c230"))
        return b
    if kind == "bow":
        tip = add(hand, (d[0] * 7, d[1] * 7))
        layer.line(hand, tip, 2, rgb("2fae4a"))
        side = vec(ang + 90, 3)
        layer.line(add(tip, side), add(tip, (-side[0], -side[1])), 1, rgb("f2c230"))
        return tip
    if kind == "sword":
        side = vec(ang + 90, 2)
        layer.line(add(hand, side), add(hand, (-side[0], -side[1])), 1, rgb("f2c230"))
        tip = add(hand, (d[0] * 14, d[1] * 14))
        layer.line(add(hand, d), tip, 2, rgb("d8d8f0"))
        layer.line(add(hand, (d[0] * 3, d[1] * 3)), tip, 1, rgb("b060ff"))
        return tip
    return hand


def draw_fx(layer, effect, anchors, char):
    kind = effect[0]
    at = anchors.get(effect[1], anchors["belt"]) if len(effect) > 1 and isinstance(effect[1], str) else None
    if kind == "hit":                       # tia va chạm hình ngôi sao
        x, y = at[0] + 2, at[1]
        for i in range(-3, 4):
            layer.set(x + i, y, WHITE)
            layer.set(x, y + i, WHITE)
        for i in (-2, 2):
            layer.set(x + i, y + i, rgb("ffe066"))
            layer.set(x + i, y - i, rgb("ffe066"))
    elif kind == "fire":                    # chân bốc lửa (Mighty Kick)
        size = effect[2]
        x, y = at
        if char.get("fire"):
            layer.circle(x - size * 0.6, y, size * 0.8, rgb("ff5a1f"), filled=True)
            layer.circle(x, y, size, rgb("ff8a2a"), filled=True)
            layer.circle(x, y, size * 0.5, rgb("ffe066"), filled=True)
        else:
            layer.circle(x, y, size * 0.8, char["accent"], filled=True)
            layer.circle(x, y, size * 0.4, WHITE, filled=True)
    elif kind == "glow":
        x, y = at
        layer.circle(x, y, effect[2], effect[3] if len(effect) > 3 else char["accent"], filled=True)
        layer.circle(x, y, max(0.5, effect[2] * 0.45), WHITE, filled=True)
    elif kind == "ring":
        x, y = at
        layer.circle(x, y, effect[2], effect[3] if len(effect) > 3 else char["accent"])
    elif kind == "beam":                    # tia bắn (Pegasus)
        x, y = at
        thick = effect[2]
        layer.line((x + 1, y), (CW - 1, y), thick + 1, char["accent"])
        layer.line((x + 1, y), (CW - 1, y), max(1, thick - 1), WHITE)
        layer.circle(x + 1, y, thick + 1, WHITE, filled=True)
    elif kind == "slash":                   # vệt chém hình cung
        x, y = at
        r = effect[2]
        for i in range(10):
            a = math.radians(-70 + i * 14)
            layer.set(round(x - r * 0.4 + math.cos(a) * r), round(y + math.sin(a) * r), WHITE)
            layer.set(round(x - r * 0.4 + math.cos(a) * (r - 1)), round(y + math.sin(a) * (r - 1)), char["accent"])
    elif kind == "belt":                    # Arcle hiện ra ở eo dạng người
        x, y = at
        layer.line((x - 5, y), (x + 3, y), 2, rgb("c8ccd8"))
        layer.stamp(x + 3, y, 2, rgb("e8283a"))
    elif kind == "sparks":
        x, y = anchors["chest"]
        for dx, dy in ((-6, -4), (5, -6), (7, 2), (-5, 5), (2, 8)):
            layer.set(x + dx, y + dy, WHITE)
            layer.set(x + dx + 1, y + dy, rgb("ffe066"))
    elif kind == "speed":                   # vệt tốc độ phía sau
        x, y = anchors["chest"]
        for dy in (-6, -1, 4, 9):
            layer.line((x - 22, y + dy), (x - 12 + (dy % 3) * 2, y + dy), 1, rgb("e8e8ff"))


# --- Bộ animation -------------------------------------------------------------

def run_frames(rider=True):
    fl = [(35, 10), (20, 40), (-5, 65), (-30, 20), (-12, 70), (18, 85)]
    frames = []
    for i in range(6):
        f, b = fl[i], fl[(i + 3) % 6]
        elbow = 90 if rider else 70
        frames.append(P(fa=(-f[0] * 0.9, elbow), ba=(-b[0] * 0.9, elbow), fl=f, bl=b,
                        bob=1 if i in (1, 4) else 0, lean=1))
    return frames


def idle_frames(rider=True, weapon=None):
    frames = []
    for bob in (0, 0, 1, 1):
        if rider:
            fa, wa = (35, 100), None
            if weapon == "rod":
                fa, wa = (45, 60), 130
            elif weapon == "sword":
                fa = (25, 60)
            elif weapon == "bow":
                fa = (20, 50)
            frames.append(P(ba=(25, 95), fa=fa, wa=wa, bl=(-12, 6), fl=(14, 8), bob=bob))
        else:
            frames.append(P(ba=(-5, 15), fa=(8, 15), bl=(-6, 4), fl=(8, 4), bob=bob))
    return frames


def jump_frames():
    return [P(fa=(150, 20), ba=(120, 30), fl=(70, 100), bl=(30, 90)),
            P(fa=(70, 20), ba=(40, 30), fl=(25, 25), bl=(-15, 40))]


STANCE = dict(bl=(-18, 8), fl=(22, 10))


def light_frames(weapon=None):
    if weapon == "rod":
        return [P(fa=(20, 60), wa=100, ba=(40, 90), **STANCE),
                P(fa=(80, 0), wa=90, ba=(-20, 80), lean=2, fx=[("hit", "tip")], **STANCE),
                P(fa=(50, 40), wa=110, ba=(10, 90), lean=1, **STANCE)]
    if weapon == "bow":
        return [P(fa=(80, 0), wa=90, ba=(60, 40), **STANCE),
                P(fa=(85, 0), wa=90, ba=(60, 40), fx=[("beam", "tip", 1)], **STANCE),
                P(fa=(75, 15), wa=105, ba=(50, 50), lean=-1, **STANCE)]
    if weapon == "sword":
        return [P(fa=(150, 20), wa=170, ba=(30, 90), lean=-1, **STANCE),
                P(fa=(80, 10), wa=100, ba=(-10, 80), lean=2, fx=[("slash", "tip", 7)], **STANCE),
                P(fa=(40, 20), wa=60, ba=(10, 90), lean=1, **STANCE)]
    return [P(fa=(-30, 110), ba=(40, 100), **STANCE),
            P(fa=(90, 0), ba=(-20, 80), lean=2, fx=[("hit", "fhand")], **STANCE),
            P(fa=(60, 50), ba=(10, 90), lean=1, **STANCE)]


def heavy_frames(weapon=None):
    if weapon == "rod":
        return [P(fa=(160, 10), wa=200, ba=(30, 90), lean=-1, **STANCE),
                P(fa=(170, 0), wa=240, ba=(30, 90), lean=-1, **STANCE),
                P(fa=(90, 0), wa=80, ba=(-20, 80), lean=3, fx=[("hit", "tip")], **STANCE),
                P(fa=(40, 30), wa=40, ba=(10, 90), lean=1, **STANCE)]
    if weapon == "bow":
        return [P(fa=(80, 0), wa=90, ba=(60, 40), fx=[("glow", "tip", 1)], **STANCE),
                P(fa=(80, 0), wa=90, ba=(60, 40), fx=[("glow", "tip", 2.5)], **STANCE),
                P(fa=(85, 0), wa=90, ba=(60, 40), fx=[("beam", "tip", 3)], **STANCE),
                P(fa=(70, 20), wa=110, ba=(50, 50), lean=-2, **STANCE)]
    if weapon == "sword":
        return [P(fa=(170, 10), wa=180, ba=(150, 20), lean=-1, **STANCE),
                P(fa=(175, 0), wa=195, ba=(160, 10), lean=-2, **STANCE),
                P(fa=(100, 0), wa=110, ba=(90, 10), lean=3, fx=[("slash", "tip", 10), ("hit", "tip")], **STANCE),
                P(fa=(60, 20), wa=70, ba=(50, 30), lean=1, **STANCE)]
    return [P(fa=(20, 100), ba=(30, 100), fl=(40, 90), bl=(-10, 8)),
            P(fa=(10, 110), ba=(40, 100), fl=(65, 100), bl=(-12, 8), lean=-1),
            P(fa=(-20, 100), ba=(60, 80), fl=(95, 0), bl=(-15, 10), lean=-2, fx=[("hit", "ffoot")]),
            P(fa=(20, 90), ba=(30, 90), fl=(40, 40), bl=(-12, 8))]


def dodge_frames():
    return [P(fa=(-50, 40), ba=(-70, 30), fl=(70, 110), bl=(-40, 60), lean=3),
            P(fa=(-40, 50), ba=(-60, 40), fl=(50, 90), bl=(-60, 40), lean=2)]


def hurt_frames(extra=()):
    return [P(fa=(-40, 50), ba=(-70, 40), fl=(10, 20), bl=(-20, 10), lean=-2, fx=[("hit", "chest")] + list(extra)),
            P(fa=(-20, 70), ba=(-50, 60), fl=(15, 25), bl=(-15, 15), lean=-3, fx=list(extra))]


def henshin_frames(human, rider, rider_idle):
    """Người → Driver phát sáng → chớp trắng → giáp hiện ra → mắt lóe sáng."""
    h1 = dict(ba=(-5, 15), fa=(8, 15), bl=(-6, 4), fl=(8, 4))
    h2 = dict(ba=(60, 90), fa=(110, 80), bl=(-10, 6), fl=(12, 6))
    h3 = dict(ba=(35, 80), fa=(135, -10), bl=(-14, 8), fl=(16, 8))
    accent = rider["accent"]
    seq = [
        (human, P(**h1)),
        (human, P(**h2, fx=[("belt", "belt")])),
        (human, P(**h2, fx=[("belt", "belt"), ("glow", "belt", 2, rgb("ff6a6a"))])),
        (human, P(**h3, fx=[("belt", "belt"), ("ring", "belt", 4, accent)])),
        (human, P(**h3, fx=[("belt", "belt"), ("ring", "belt", 7, accent), ("ring", "belt", 4, accent)])),
        (human, P(**h3, silhouette=WHITE, fx=[("ring", "belt", 10, accent)])),
        (rider, P(**h3, silhouette=WHITE, fx=[("ring", "belt", 13, accent)])),
        (rider, P(**h3, silhouette=shade(accent, 1.0), fx=[("ring", "belt", 16, shade(accent, 0.8))])),
        (rider, P(**h3)),
        (rider, P(**h3, fx=[("sparks",)])),
    ]
    guard = rider_idle[0]
    for eyes in (None, WHITE, WHITE, None):
        seq.append((rider, dict(guard, eyes=eyes, fx=[("glow", "head", 1.5, WHITE)] if eyes else [])))
    return [render(c, p) for c, p in seq]


def final_frames(weapon=None):
    if weapon == "rod":        # Splash Dragon
        return [P(fa=(160, 10), wa=150, ba=(30, 90), **STANCE),
                P(fa=(170, 0), wa=240, ba=(30, 90), **STANCE),
                P(fa=(120, 20), wa=170, ba=(-30, 60), fl=(40, 80), bl=(-35, 70)),
                P(fa=(160, 0), wa=175, ba=(120, 20), fl=(70, 100), bl=(30, 90), air=10),
                P(fa=(90, 0), wa=90, ba=(-40, 40), fl=(30, 20), bl=(-40, 30), air=6, lean=3,
                  fx=[("glow", "tip", 3), ("speed",)]),
                P(fa=(90, 0), wa=90, ba=(-40, 40), fl=(30, 20), bl=(-40, 30), air=3, lean=3,
                  fx=[("hit", "tip"), ("glow", "tip", 2)]),
                P(fa=(70, 20), wa=100, ba=(-20, 60), fl=(30, 60), bl=(-30, 50)),
                P(fa=(40, 40), wa=110, ba=(10, 80), **STANCE),
                P(fa=(30, 80), ba=(25, 95), bl=(-12, 6), fl=(14, 8))]
    if weapon == "bow":        # Blast Pegasus
        aim = dict(fa=(85, 0), wa=90, ba=(60, 40), **STANCE)
        return [P(**aim, fx=[("glow", "tip", 1)]),
                P(**aim, fx=[("glow", "tip", 2)]),
                P(**aim, fx=[("glow", "tip", 3)]),
                P(**aim, fx=[("glow", "tip", 4), ("ring", "tip", 6)]),
                P(**aim, fx=[("beam", "tip", 4)]),
                P(**aim, fx=[("beam", "tip", 3)]),
                P(fa=(75, 15), wa=105, ba=(50, 50), lean=-2, **STANCE),
                P(fa=(60, 30), wa=110, ba=(40, 60), lean=-1, **STANCE),
                P(fa=(20, 50), ba=(25, 95), bl=(-12, 6), fl=(14, 8))]
    if weapon == "sword":      # Calamity Titan
        return [P(fa=(170, 0), wa=180, ba=(150, 10), **STANCE),
                P(fa=(170, 0), wa=180, ba=(150, 10), fx=[("glow", "tip", 2, rgb("b060ff"))], **STANCE),
                P(fa=(120, 10), wa=120, ba=(100, 20), lean=1, fx=[("glow", "tip", 3, rgb("b060ff"))], **STANCE),
                P(fa=(90, 0), wa=90, ba=(-30, 60), lean=3, fl=(40, 20), bl=(-40, 20)),
                P(fa=(90, 0), wa=90, ba=(-30, 60), lean=4, fl=(40, 20), bl=(-40, 20),
                  fx=[("hit", "tip"), ("ring", "tip", 5, rgb("b060ff"))]),
                P(fa=(90, 0), wa=90, ba=(-30, 60), lean=4, fl=(40, 20), bl=(-40, 20), fx=[("ring", "tip", 8, rgb("b060ff"))]),
                P(fa=(60, 20), wa=70, ba=(10, 80), lean=1, **STANCE),
                P(fa=(40, 30), wa=60, ba=(20, 90), **STANCE),
                P(fa=(25, 60), ba=(25, 95), bl=(-12, 6), fl=(14, 8))]
    # Mighty Kick / Growing Kick
    kick = dict(fl=(95, 0), bl=(20, 100), lean=-2, fa=(-30, 60), ba=(40, 80))
    return [P(fl=(30, 70), bl=(-30, 60), fa=(60, 40), ba=(-40, 40), fx=[("fire", "ffoot", 1.5)]),
            P(fl=(40, 90), bl=(-35, 80), fa=(100, 10), ba=(-80, 10), fx=[("fire", "ffoot", 2.5)]),
            P(fl=(80, 120), bl=(40, 110), fa=(140, 40), ba=(100, 40), air=8, fx=[("fire", "ffoot", 2)]),
            P(fl=(85, 125), bl=(45, 115), fa=(150, 40), ba=(110, 40), air=12, fx=[("fire", "ffoot", 2.5)]),
            P(**kick, air=8, fx=[("fire", "ffoot", 3.5), ("speed",)]),
            P(**kick, air=5, fx=[("fire", "ffoot", 4.5), ("speed",)]),
            P(**kick, air=2, fx=[("fire", "ffoot", 3), ("hit", "ffoot")]),
            P(fl=(30, 70), bl=(-30, 60), fa=(60, 40), ba=(-40, 40)),
            P(ba=(25, 95), fa=(35, 100), bl=(-12, 6), fl=(14, 8))]


def ko_frame(human):
    stand = render(human, P(ba=(-10, 10), fa=(10, 10), bl=(-4, 2), fl=(4, 2)))
    lying = stand.rotate(90, resample=Image.NEAREST)
    out = Image.new("RGBA", (CW, CH), CLEAR)
    bbox = lying.getbbox()
    piece = lying.crop(bbox)
    out.paste(piece, (CX - piece.width // 2, GROUND + 1 - piece.height), piece)
    return out


def build_human():
    h = HUMAN
    r = lambda poses: [render(h, p) for p in poses]
    return [
        ("idle", r(idle_frames(rider=False)), 5, True),
        ("run", r(run_frames(rider=False)), 12, True),
        ("jump", r(jump_frames()), 8, True),
        ("light", r(light_frames()), 11, False),
        ("heavy", r(heavy_frames()), 7, False),
        ("dodge", r(dodge_frames()), 8, False),
        ("hurt", r(hurt_frames()), 7, False),
        ("break", r(hurt_frames(extra=[("sparks",)])), 4, True),
        ("ko", [ko_frame(h)], 1, False),
    ]


# fps đánh nhẹ / đánh mạnh khớp với thời gian đòn trong code (startup + active + recovery)
KUUGA_FPS = {
    "kuuga_growing": (11, 7), "kuuga_mighty": (12, 7), "kuuga_dragon": (12, 8),
    "kuuga_pegasus": (6, 4.5), "kuuga_titan": (6, 4.5),
}


def build_kuuga(prefix):
    c = kuuga_char(prefix)
    w = c["weapon"]
    r = lambda poses: [render(c, p) for p in poses]
    idle = idle_frames(rider=True, weapon=w)
    light_fps, heavy_fps = KUUGA_FPS[prefix]
    heavy = r(heavy_frames(w))
    return [
        ("idle", r(idle), 5, True),
        ("run", r(run_frames()), 12, True),
        ("jump", r(jump_frames()), 8, True),
        ("light", r(light_frames(w)), light_fps, False),
        ("heavy", heavy, heavy_fps, False),
        ("swap_in", heavy, 16, False),
        ("dodge", r(dodge_frames()), 8, False),
        ("hurt", r(hurt_frames()), 7, False),
        ("henshin", henshin_frames(HUMAN, c, idle), 12, False),
        ("final", r(final_frames(w)), 8, False),
    ]


# --- Xuất file ----------------------------------------------------------------

def save_sheet(prefix, anims):
    cols = max(len(frames) for _, frames, _, _ in anims)
    sheet = Image.new("RGBA", (cols * CW, len(anims) * CH), CLEAR)
    regions = []
    for row, (name, frames, fps, loop) in enumerate(anims):
        rects = []
        for col, frame in enumerate(frames):
            sheet.paste(frame, (col * CW, row * CH))
            rects.append((col * CW, row * CH))
        regions.append((name, rects, fps, loop))
    sheet.save(os.path.join(OUT_DIR, prefix + ".png"))
    return sheet, regions


def write_sprite_frames(sheets):
    ext, subs, anims = [], [], []
    for i, (prefix, regions) in enumerate(sheets):
        tex_id = "tex_%d" % i
        ext.append('[ext_resource type="Texture2D" path="%s/%s.png" id="%s"]' % (RES_DIR, prefix, tex_id))
        for name, rects, fps, loop in regions:
            frame_refs = []
            for j, (x, y) in enumerate(rects):
                sid = "at_%s_%s_%d" % (prefix, name, j)
                subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("%s")\n'
                            'region = Rect2(%d, %d, %d, %d)\nfilter_clip = true' % (sid, tex_id, x, y, CW, CH))
                frame_refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sid)
            anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s_%s",\n"speed": %s\n}'
                         % (", ".join(frame_refs), "true" if loop else "false", prefix, name, float(fps)))
    text = '[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n' % (len(ext) + len(subs) + 1)
    text += "\n".join(ext) + "\n\n" + "\n\n".join(subs) + "\n\n[resource]\nanimations = [" + ", ".join(anims) + "]\n"
    with open(os.path.join(OUT_DIR, "player_frames_procedural.tres"), "w", encoding="utf-8") as f:
        f.write(text)


def write_previews(out_dir, built):
    os.makedirs(out_dir, exist_ok=True)
    scale = 4
    bg = (92, 110, 148, 255)
    for prefix, anims, sheet in built:
        big = Image.new("RGBA", sheet.size, bg)
        big.alpha_composite(sheet)
        big.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST).save(
            os.path.join(out_dir, "sheet_%s.png" % prefix))
        for name, frames, fps, _ in anims:
            if name not in ("idle", "run", "henshin", "final", "light", "heavy"):
                continue
            imgs = []
            for fr in frames:
                im = Image.new("RGBA", (CW, CH), bg)
                im.alpha_composite(fr)
                imgs.append(im.resize((CW * scale, CH * scale), Image.NEAREST).convert("P", palette=Image.ADAPTIVE))
            imgs[0].save(os.path.join(out_dir, "%s_%s.gif" % (prefix, name)), save_all=True,
                         append_images=imgs[1:], duration=int(1000 / fps), loop=0, disposal=2)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    built = [("human", build_human())] + [(p, build_kuuga(p)) for p in KUUGA_FORMS]
    sheets, previews = [], []
    for prefix, anims in built:
        sheet, regions = save_sheet(prefix, anims)
        sheets.append((prefix, regions))
        previews.append((prefix, anims, sheet))
    write_sprite_frames(sheets)
    if "--preview" in sys.argv:
        write_previews(sys.argv[sys.argv.index("--preview") + 1], previews)
    total = sum(len(fr) for _, anims in built for _, fr, _, _ in anims)
    print("Đã tạo %d frame cho %d bộ sprite → %s" % (total, len(built), OUT_DIR))


if __name__ == "__main__":
    main()
