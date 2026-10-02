#!/usr/bin/env python3
"""
Ghép quái mới từ bộ phận của quái đã có, không tốn credit AI.

    python3 tools/kitbash.py                  # ghi mọi quái trong bảng KITBASH vào art/kitbash/<tên>/
    python3 tools/kitbash.py --only a,b       # chỉ ghép vài con
    python3 tools/kitbash.py --preview D      # thêm ảnh xem trước (phóng to ×3, 12 con một ảnh) vào thư mục D

Mọi quái thường PixelLab trong dự án làm từ cùng mẫu dáng "mannequin", cùng bộ animation (run 6, attack 6,
hurt 6, die 7 frame) nên tư thế từng frame gần giống nhau. Cách ghép:
  1. Thân: animation của một trong 3 quái có sẵn: jaguar_lord lực lưỡng, sheerghost mảnh, grongi_zu có cánh.
  2. Đầu: hoặc cắt từ tư thế đứng của một nhân vật khác ({"img": tên}, chỉ cần hình tĩnh), hoặc vẽ bằng code
     từ các mảnh trong PARTS (đầu tròn + mõm / mỏ / sừng / gạc / râu / mắt kép...). Mỗi frame dò vị trí và
     góc nghiêng của đầu thân so với tư thế đứng (khớp mặt nạ alpha), xoá đầu cũ, dán đầu mới đúng chỗ đó.
     Frame dò không ra (nằm gục ở cuối animation gục) thì giữ đầu cũ, chỉ đổi màu.
  3. Màu: pixel vàng / cam rực của thân (lông Jaguar Lord, trang sức Grongi) lấy màu nhấn "accent", còn lại lấy
     màu nền "tone"; giữ viền tối và độ sáng nên vẫn còn khối và bóng. "glass" thay màu nền bằng các ô màu
     kiểu kính màu (Fangire).
Đầu ra cùng cấu trúc thư mục PixelLab (metadata.json + Idle/...) để import_pixellab.py đọc như thường.
"""
import colorsys
import json
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(ROOT, "art", "pixellab")
OUT_DIR = os.path.join(ROOT, "art", "kitbash")
ANIMS = ("run", "attack", "hurt", "die")
CLEAR = (0, 0, 0, 0)
INK = (30, 28, 36, 255)          # viền
BONE = (232, 226, 208)

# Hàng cổ (hàng cuối của đầu ở tư thế đứng) của các nhân vật dùng làm thân hoặc đầu.
NECK = {"jaguar_lord": 23, "sheerghost": 24, "grongi_zu": 23, "orphnoch": 23, "masquerade": 23, "faiz": 24}
# Khoảng hue của mắt trên hình đầu có sẵn, để đổi sang màu mắt của quái mới (None: không có mắt màu).
EYE_HUE = {"orphnoch": (0.5, 0.7), "jaguar_lord": (0.22, 0.45), "grongi_zu": (0.1, 0.2), "sheerghost": (0.55, 0.75),
           "masquerade": None, "faiz": (0.1, 0.2)}
# Hình đầu có mặt nạ trắng / bạc phải giữ nguyên màu (mặt sọ Masquerade, mặt nạ Faiz), chỉ đổi màu phần còn lại.
KEEP_WHITE = {"masquerade", "faiz"}

# --- Mảnh vẽ đầu ----------------------------------------------------------------
# Mỗi mảnh: (dx, dy, lưới). Góc trên trái của lưới đặt tại điểm (giữa cổ, hàng cổ) + (dx, dy); mặt quay sang phải.
# Chữ: a b c = màu nền sáng / vừa / tối, x y = màu nhấn sáng / tối, e = mắt, w = xương trắng, k = đen.
# Viền tối tự thêm quanh hình, trừ 2 hàng sát cổ (để không kẻ vạch ngang cổ).
PARTS = {
    "round": (-5, -12, [
        "...aaaaa....",
        "..aaaaaaa...",
        ".baaaaaaaa..",
        ".baaaaaaaaa.",
        "bbaaaaaaaaa.",
        "bbaaaaaaaaa.",
        "bbbaaaaaaaa.",
        "bbbaaaaaaa..",
        ".bbbaaaaa...",
        "..bbbaaa....",
        "...bbaa.....",
        "...bbaa.....",
        "...bbaa.....",
    ]),
    "muzzle": (5, -7, [
        "aaa..",
        "aaaaa",
        "bbbbb",
        "bbb..",
    ]),
    "long_muzzle": (5, -8, [
        "aaa....",
        "aaaaaa.",
        "aaaaaaa",
        "bbbbbbb",
        "bbbb...",
    ]),
    "beak": (5, -8, [
        "xxx...",
        "xxxxxx",
        "yyyy..",
        "yy....",
    ]),
    "jaw": (4, -4, [
        "w.w.w",
        "kkkk.",
        "w.w..",
    ]),
    "mandibles": (5, -5, [
        "xx.",
        "..x",
        "xx.",
        "..x",
    ]),
    "ears": (-4, -16, [
        "a...a..",
        "aa..aa.",
        "bab.bab",
        "bbb.bbb",
    ]),
    "horn_bull": (-3, -17, [
        "........ww",
        ".......ww.",
        "......ww..",
        ".wwwwww...",
        "ww........",
    ]),
    "horn_unicorn": (3, -19, [
        "......w",
        ".....w.",
        "....ww.",
        "...ww..",
        "..xx...",
        ".xx....",
        "xx.....",
    ]),
    "horn_back": (-6, -17, [
        "w.....",
        "ww....",
        ".ww...",
        "..ccc.",
        "...cc.",
    ]),
    "horn_nose": (7, -11, [
        "...w",
        "..ww",
        ".ww.",
        "ww..",
    ]),
    "antlers": (-5, -19, [
        "w...w.w...",
        "w..w..w.w.",
        ".w.w...ww.",
        "..ww..ww..",
        "...w.ww...",
        "...www....",
    ]),
    "antennae": (-3, -19, [
        "x.......x",
        ".x.....x.",
        "..x...x..",
        "..x..x...",
        "...xx....",
        "...x.....",
    ]),
    "crest": (-4, -15, [
        "..xxxxx..",
        ".xxxxxxx.",
        "xxxyyyy..",
    ]),
    "mane": (-7, -13, [
        "..xx.",
        ".xxx.",
        "xxxy.",
        "xxyy.",
        ".xyy.",
        "..yy.",
        "..yy.",
    ]),
    "spikes": (-5, -15, [
        "x..x..x...",
        "xx.xx.xx..",
        "yyyyyyyy..",
    ]),
    "eyestalks": (2, -17, [
        "e...e",
        "x...x",
        "x..x.",
        ".xx..",
    ]),
    "shell": (-10, -13, [
        "..xxxx..",
        ".xyyyyx.",
        "xyxxxyyx",
        "xyxyyxyx",
        "xyxxyxyx",
        "xyyyxxy.",
        ".xxyyy..",
        "..xxx...",
    ]),
    "hood": (-8, -14, [
        "..aaaaaaaa...",
        ".aaaaaaaaaa..",
        "bbaaaaaaaaaa.",
        "bba..........",
        "bba..........",
        "bbba.........",
        ".bbba........",
        ".bbbba.......",
        "..bbbbbb.....",
        "...bbbbb.....",
    ]),
    "cobra_hood": (-8, -15, [
        "..bbbb.......",
        ".bxxxbb......",
        "bxyyxxb......",
        "bxyyyxb......",
        "bxyyxxb......",
        "bxxxxb.......",
        ".bbbbb.......",
        "..bbbb.......",
    ]),
    "wraps": (-5, -11, [
        "............",
        "..cccc......",
        "........cc..",
        ".ccccc......",
        "......cccc..",
        "............",
        "..ccc.......",
        ".......cc...",
    ]),
    "pawn_top": (-3, -18, [
        "..xxx...",
        ".xxxxx..",
        ".xyyyx..",
        "..yyy...",
        ".xxxxx..",
    ]),
    "crown": (-5, -15, [
        "x.x.x.x.x.",
        "xxxxxxxxx.",
        "yyyyyyyy..",
    ]),
    "fuse": (-1, -18, [
        "..e.",
        ".ex.",
        "..x.",
        ".x..",
        "kk..",
    ]),
    "visor": (-1, -9, [
        "....kkk",
        "eeeeeee",
        ".kkkkk.",
    ]),
    "eye_dot": (3, -9, [
        "ee",
        "ke",
    ]),
    "eye_slit": (2, -9, [
        "keee",
    ]),
    "eye_mono": (1, -10, [
        ".ww.",
        "weew",
        "weew",
        ".ww.",
    ]),
    "eye_compound": (1, -11, [
        ".ee.",
        "eeee",
        "eeee",
        "eeee",
        ".ee.",
    ]),
    "eye_multi": (2, -11, [
        "e.e",
        ".e.",
        "e.e",
        ".e.",
    ]),
    "plate": (-1, -12, [
        "..xxxx",
        ".xxxxxx",
        "xxxx...",
    ]),
}

# --- Bảng quái -----------------------------------------------------------------
# tên → body (thân), head ({"img": tên} hoặc danh sách mảnh), tone (h, s, độ sáng ×) màu nền,
# accent (h, s, độ sáng ×) màu nhấn (thiếu: dùng màu nền), eye (r, g, b), glass (danh sách hue, kiểu kính màu).
J, S, G = "jaguar_lord", "sheerghost", "grongi_zu"
KITBASH = {
    # 4 Faiz: Orphnoch tro trắng như tượng đá, đầu sói của hình tĩnh Orphnoch
    "orphnoch_wolf": {"body": J, "head": {"img": "orphnoch"}, "tone": (0.63, 0.05, 1.15), "eye": (60, 60, 70)},
    "orphnoch_fast": {"body": S, "head": {"img": "orphnoch"}, "tone": (0.75, 0.22, 1.0), "eye": (200, 120, 255)},
    "orphnoch_armored": {"body": J, "head": {"img": "orphnoch"}, "tone": (0.62, 0.06, 0.72), "eye": (230, 230, 240)},
    # 5 Blade: Undead
    "darkroach": {"body": S, "head": ["round", "antennae", "eye_compound", "mandibles"],
                  "tone": (0.06, 0.5, 0.6), "accent": (0.08, 0.6, 0.8), "eye": (200, 40, 40)},
    "jaguar_undead": {"body": S, "head": {"img": "jaguar_lord"}, "tone": (0.11, 0.6, 1.0), "eye": (90, 230, 90)},
    "trilobite_undead": {"body": J, "head": ["round", "spikes", "visor"],
                         "tone": (0.58, 0.22, 0.75), "accent": (0.08, 0.45, 0.8), "eye": (230, 60, 50)},
    # 6 Hibiki: Makamou
    "kappa": {"body": S, "head": ["round", "plate", "beak", "eye_dot"],
              "tone": (0.3, 0.5, 0.85), "accent": (0.14, 0.75, 1.0), "eye": (250, 220, 60)},
    "ittanmomen": {"body": G, "head": ["hood", "round", "eye_mono"],
                   "tone": (0.12, 0.08, 1.15), "accent": (0.0, 0.0, 0.9), "eye": (210, 30, 40)},
    "bakegani": {"body": J, "head": ["round", "eyestalks", "mandibles", "spikes"],
                 "tone": (0.02, 0.65, 0.9), "accent": (0.05, 0.55, 0.75), "eye": (30, 30, 30)},
    # 7 Kabuto: Worm
    "salis_worm": {"body": S, "head": ["round", "antennae", "eye_compound", "mandibles"],
                   "tone": (0.3, 0.55, 0.7), "accent": (0.16, 0.6, 0.9), "eye": (230, 50, 40)},
    "musca_worm": {"body": G, "head": ["round", "eye_compound", "mandibles"],
                   "tone": (0.25, 0.25, 0.55), "accent": (0.3, 0.4, 0.6), "eye": (230, 40, 40)},
    "cochlea_worm": {"body": J, "head": ["round", "shell", "eyestalks"],
                     "tone": (0.09, 0.35, 0.8), "accent": (0.95, 0.35, 0.8), "eye": (250, 220, 60)},
    # 8 Den-O: Imagin
    "mole_imagin": {"body": S, "head": ["round", "ears", "long_muzzle", "eye_dot"],
                    "tone": (0.07, 0.45, 0.65), "accent": (0.1, 0.3, 0.9), "eye": (250, 210, 60)},
    "bat_imagin": {"body": G, "head": {"img": "grongi_zu"}, "tone": (0.65, 0.35, 0.55), "eye": (230, 40, 40)},
    "rhino_imagin": {"body": J, "head": ["round", "muzzle", "horn_nose", "eye_dot"],
                     "tone": (0.1, 0.2, 0.62), "accent": (0.08, 0.35, 0.7), "eye": (250, 210, 60)},
    # 9 Kiva: Fangire kính màu
    "spider_fangire": {"body": S, "head": ["round", "eye_multi", "mandibles"], "tone": (0.6, 0.5, 0.7),
                       "glass": (0.6, 0.85, 0.5), "eye": (250, 230, 80)},
    "horse_fangire": {"body": S, "head": ["round", "ears", "long_muzzle", "mane", "eye_dot"], "tone": (0.0, 0.5, 0.7),
                      "accent": (0.12, 0.6, 1.0), "glass": (0.0, 0.08, 0.6), "eye": (250, 230, 80)},
    "moose_fangire": {"body": J, "head": ["round", "muzzle", "antlers", "eye_dot"], "tone": (0.35, 0.5, 0.7),
                      "accent": (0.12, 0.6, 1.0), "glass": (0.35, 0.5, 0.15), "eye": (250, 230, 80)},
    # 10 Decade: Dai-Shocker
    "dai_shocker": {"body": J, "head": {"img": "masquerade"}, "tone": (0.7, 0.08, 0.3), "accent": (0.1, 0.1, 0.95),
                    "eye": (240, 240, 240)},
    "okami_otoko": {"body": S, "head": {"img": "orphnoch"}, "tone": (0.08, 0.45, 0.62), "eye": (250, 210, 50)},
    "kanibubbler": {"body": J, "head": ["round", "eyestalks", "mandibles", "crest"],
                    "tone": (0.97, 0.5, 0.85), "accent": (0.0, 0.0, 0.35), "eye": (30, 30, 30)},
    # 11 W: Dopant
    "masquerade_dopant": {"body": S, "head": {"img": "masquerade"}, "tone": (0.0, 0.0, 0.3), "eye": (240, 240, 240)},
    "bird_dopant": {"body": G, "head": ["round", "crest", "beak", "eye_slit"],
                    "tone": (0.02, 0.6, 0.75), "accent": (0.12, 0.7, 1.0), "eye": (250, 230, 80)},
    "rhino_dopant": {"body": J, "head": ["round", "horn_bull", "visor"],
                     "tone": (0.1, 0.3, 0.5), "accent": (0.09, 0.5, 0.75), "eye": (250, 120, 40)},
    # 12 OOO: Yummy
    "waste_yummy": {"body": S, "head": ["round", "wraps", "eye_slit"],
                    "tone": (0.1, 0.18, 0.95), "accent": (0.1, 0.1, 0.6), "eye": (40, 40, 40)},
    "neko_yummy": {"body": S, "head": {"img": "jaguar_lord"}, "tone": (0.1, 0.06, 1.15), "eye": (60, 200, 80)},
    "bison_yummy": {"body": J, "head": ["round", "muzzle", "horn_bull", "eye_dot"],
                    "tone": (0.07, 0.5, 0.45), "accent": (0.1, 0.6, 0.7), "eye": (230, 40, 40)},
    # 13 Fourze: Zodiarts
    "dustard": {"body": S, "head": ["round", "visor", "spikes"],
                "tone": (0.0, 0.0, 0.38), "accent": (0.0, 0.75, 0.75), "eye": (230, 40, 40)},
    "unicorn_zodiarts": {"body": S, "head": ["round", "mane", "horn_unicorn", "eye_slit"],
                         "tone": (0.6, 0.08, 1.15), "accent": (0.12, 0.6, 1.0), "eye": (80, 150, 250)},
    "orion_zodiarts": {"body": J, "head": ["round", "crest", "visor"],
                       "tone": (0.62, 0.35, 0.6), "accent": (0.12, 0.6, 1.0), "eye": (250, 220, 60)},
    # 14 Wizard: Phantom
    "ghoul": {"body": S, "head": ["round", "horn_back", "eye_slit"],
              "tone": (0.08, 0.15, 0.6), "accent": (0.0, 0.7, 0.7), "eye": (230, 40, 40)},
    "hellhound": {"body": S, "head": {"img": "orphnoch"}, "tone": (0.0, 0.25, 0.42), "eye": (240, 50, 40)},
    "minotaurus": {"body": J, "head": ["round", "muzzle", "horn_bull", "spikes", "eye_dot"],
                   "tone": (0.0, 0.5, 0.6), "accent": (0.12, 0.6, 0.9), "eye": (250, 220, 60)},
    # 15 Gaim: Inves
    "elementary_inves": {"body": S, "head": {"img": "sheerghost"}, "tone": (0.25, 0.25, 0.65), "eye": (230, 40, 40)},
    "komori_inves": {"body": G, "head": {"img": "grongi_zu"}, "tone": (0.32, 0.5, 0.55), "eye": (230, 40, 40)},
    "shika_inves": {"body": J, "head": ["round", "muzzle", "antlers", "eye_dot"],
                    "tone": (0.33, 0.4, 0.55), "accent": (0.12, 0.45, 0.8), "eye": (230, 40, 40)},
    # 16 Drive: Roidmude kim loại sẫm
    "roidmude_spider": {"body": S, "head": ["round", "spikes", "eye_multi", "mandibles"],
                        "tone": (0.6, 0.12, 0.42), "accent": (0.6, 0.05, 0.9), "eye": (230, 40, 40)},
    "roidmude_bat": {"body": G, "head": {"img": "grongi_zu"}, "tone": (0.6, 0.12, 0.42), "eye": (230, 40, 40)},
    "roidmude_cobra": {"body": J, "head": ["cobra_hood", "round", "eye_slit"],
                       "tone": (0.6, 0.12, 0.42), "accent": (0.6, 0.05, 0.9), "eye": (230, 40, 40)},
    # 17 Ghost: Gamma
    "gamma_command": {"body": S, "head": ["round", "eye_mono"],
                      "tone": (0.7, 0.1, 0.28), "accent": (0.0, 0.0, 0.9), "eye": (230, 230, 240)},
    "katana_gamma": {"body": S, "head": ["round", "crest", "eye_mono"],
                     "tone": (0.95, 0.4, 0.5), "accent": (0.0, 0.0, 0.9), "eye": (230, 230, 240)},
    "gamma_ultima": {"body": J, "head": ["round", "horn_bull", "eye_mono"],
                     "tone": (0.72, 0.3, 0.42), "accent": (0.12, 0.6, 0.9), "eye": (230, 230, 240)},
    # 18 Ex-Aid: Bugster
    "bugster_virus": {"body": S, "head": ["round", "eye_compound"],
                      "tone": (0.08, 0.8, 1.05), "accent": (0.08, 0.3, 0.5), "eye": (40, 40, 50)},
    "charlie_bugster": {"body": S, "head": ["round", "crest", "visor"],
                        "tone": (0.14, 0.7, 1.0), "accent": (0.0, 0.0, 0.3), "eye": (40, 40, 50)},
    "gatton_bugster": {"body": J, "head": ["round", "horn_nose", "visor", "spikes"],
                       "tone": (0.27, 0.4, 0.5), "accent": (0.12, 0.4, 0.7), "eye": (230, 40, 40)},
    # 19 Build: Guardian, Smash
    "guardian": {"body": S, "head": ["round", "crest", "visor"],
                 "tone": (0.6, 0.06, 0.75), "accent": (0.6, 0.5, 0.6), "eye": (80, 170, 250)},
    "flying_smash": {"body": G, "head": ["round", "ears", "eye_compound"],
                     "tone": (0.8, 0.3, 0.5), "accent": (0.3, 0.5, 0.8), "eye": (90, 230, 90)},
    "strong_smash": {"body": J, "head": ["round", "spikes", "visor"],
                     "tone": (0.08, 0.4, 0.55), "accent": (0.1, 0.4, 0.7), "eye": (230, 40, 40)},
    # 20 Zi-O: Kasshine, Another Rider
    "kasshine": {"body": S, "head": ["round", "crest", "visor"],
                 "tone": (0.12, 0.18, 0.9), "accent": (0.12, 0.6, 1.0), "eye": (80, 150, 250)},
    "another_faiz": {"body": S, "head": {"img": "faiz"}, "tone": (0.6, 0.05, 0.4), "eye": (200, 230, 60)},
    "another_build": {"body": J, "head": ["round", "horn_unicorn", "visor"],
                      "tone": (0.0, 0.35, 0.42), "accent": (0.6, 0.5, 0.6), "eye": (230, 40, 40)},
    # 21 Zero-One: Magia
    "trilobite_magia": {"body": S, "head": ["round", "spikes", "eye_mono"],
                        "tone": (0.5, 0.25, 0.5), "accent": (0.1, 0.6, 0.8), "eye": (250, 220, 60)},
    "berotha_magia": {"body": S, "head": ["round", "antennae", "eye_compound"],
                      "tone": (0.12, 0.45, 0.6), "accent": (0.0, 0.0, 0.35), "eye": (230, 40, 40)},
    "dodo_magia": {"body": J, "head": ["round", "crest", "beak", "eye_dot"],
                   "tone": (0.6, 0.22, 0.5), "accent": (0.12, 0.8, 1.0), "eye": (230, 40, 40)},
    # 22 Saber: Megid
    "shimi": {"body": S, "head": ["round", "wraps", "eye_mono"],
              "tone": (0.12, 0.1, 0.85), "accent": (0.0, 0.0, 0.4), "eye": (230, 40, 40)},
    "piranha_megid": {"body": S, "head": ["round", "crest", "muzzle", "jaw", "eye_dot"],
                      "tone": (0.56, 0.4, 0.62), "accent": (0.0, 0.6, 0.8), "eye": (250, 220, 60)},
    "golem_megid": {"body": J, "head": ["round", "spikes", "visor"],
                    "tone": (0.08, 0.22, 0.55), "accent": (0.08, 0.6, 0.9), "eye": (250, 140, 40)},
    # 23 Revice: Giffjunior, Deadman
    "giffjunior": {"body": S, "head": ["round", "horn_bull", "eye_compound"],
                   "tone": (0.76, 0.3, 0.4), "accent": (0.92, 0.5, 0.85), "eye": (230, 40, 40)},
    "deadman": {"body": S, "head": ["round", "visor"],
                "tone": (0.7, 0.1, 0.28), "accent": (0.0, 0.7, 0.75), "eye": (230, 40, 40)},
    "deadman_armored": {"body": J, "head": ["round", "visor", "spikes"],
                        "tone": (0.7, 0.1, 0.36), "accent": (0.0, 0.7, 0.75), "eye": (230, 40, 40)},
    # 24 Geats: Jyamato cây cỏ + quân cờ
    "pawn_jyamato": {"body": S, "head": ["round", "pawn_top", "eye_slit"],
                     "tone": (0.32, 0.5, 0.55), "accent": (0.08, 0.6, 0.85), "eye": (250, 220, 60)},
    "knight_jyamato": {"body": S, "head": ["round", "ears", "long_muzzle", "mane", "eye_dot"],
                       "tone": (0.32, 0.55, 0.45), "accent": (0.08, 0.6, 0.85), "eye": (250, 220, 60)},
    "rook_jyamato": {"body": J, "head": ["round", "crown", "visor"],
                     "tone": (0.32, 0.45, 0.5), "accent": (0.08, 0.6, 0.85), "eye": (250, 220, 60)},
    # 25 Gotchard: Dreadrooper, Malgam
    "dreadrooper": {"body": S, "head": ["round", "crest", "visor"],
                    "tone": (0.75, 0.3, 0.35), "accent": (0.9, 0.7, 0.9), "eye": (240, 60, 200)},
    "malgam": {"body": S, "head": ["round", "antennae", "eye_compound"],
               "tone": (0.45, 0.4, 0.6), "accent": (0.12, 0.6, 0.9), "eye": (250, 220, 60)},
    "malgam_armored": {"body": J, "head": ["round", "horn_bull", "spikes", "eye_slit"],
                       "tone": (0.05, 0.5, 0.6), "accent": (0.12, 0.5, 0.8), "eye": (250, 220, 60)},
    # 26 Gavv: Agent, Granute
    "agent": {"body": S, "head": ["round", "visor"],
              "tone": (0.62, 0.1, 0.3), "accent": (0.0, 0.0, 0.95), "eye": (20, 20, 24)},
    "granute": {"body": S, "head": ["round", "ears", "muzzle", "jaw", "eye_dot"],
                "tone": (0.92, 0.45, 0.75), "accent": (0.5, 0.5, 0.9), "eye": (250, 220, 60)},
    "granute_armored": {"body": J, "head": ["round", "horn_bull", "jaw", "eye_dot"],
                        "tone": (0.08, 0.55, 0.55), "accent": (0.92, 0.45, 0.8), "eye": (250, 220, 60)},
    # 27 Zeztz: Nightmare
    "nightmare": {"body": S, "head": ["round", "spikes", "eye_mono"],
                  "tone": (0.72, 0.4, 0.35), "accent": (0.5, 0.7, 0.9), "eye": (80, 240, 240)},
    "crow_nightmare": {"body": G, "head": ["round", "crest", "beak", "eye_slit"],
                       "tone": (0.7, 0.2, 0.22), "accent": (0.5, 0.7, 0.9), "eye": (230, 40, 40)},
    "bomb_nightmare": {"body": J, "head": ["round", "fuse", "eye_mono"],
                       "tone": (0.0, 0.0, 0.32), "accent": (0.07, 0.8, 1.0), "eye": (250, 140, 40)},
}


def load(char, rel):
    return Image.open(os.path.join(SRC_DIR, char, rel)).convert("RGBA")


def frames_of(char, anim):
    meta = json.load(open(os.path.join(SRC_DIR, char, "metadata.json"), encoding="utf-8"))
    return [load(char, p) for p in meta["states"][0]["frames"]["animations"][anim]["east"]]


def solid(im):
    a = im.getchannel("A")
    w, h = im.size
    return {(x, y) for y in range(h) for x in range(w) if a.getpixel((x, y)) > 0}


def head_part(im, neck):
    """Cắt phần đầu (mọi pixel từ hàng cổ trở lên) của tư thế đứng: trả (ảnh đầu, tập pixel đầu)."""
    out = Image.new("RGBA", im.size, CLEAR)
    pts = {(x, y) for (x, y) in solid(im) if y <= neck}
    for p in pts:
        out.putpixel(p, im.getpixel(p))
    return out, pts


def neck_mid(pts, row):
    xs = [x for (x, y) in pts if y == row] or [x for (x, _) in pts]
    return (min(xs) + max(xs)) // 2


def ring_of(pts, neck, r=2):
    """Viền r pixel bao quanh đầu (chỉ phía trên hàng cổ): ở frame đúng chỗ đầu thì viền này phải trống."""
    ring = {(x + i, y + j) for (x, y) in pts for i in range(-r, r + 1) for j in range(-r, r + 1)}
    return {(x, y) for (x, y) in ring - pts if y <= neck}


def bits(pts):
    """Tập pixel → {hàng: số nguyên, bit x bật nếu có pixel} để đếm trùng nhanh bằng AND."""
    rows = {}
    for (x, y) in pts:
        rows[y] = rows.get(y, 0) | (1 << (x + 16))   # lệch 16 bit để dịch trái âm không mất pixel
    return rows


def count(rows, frame_rows, dx, dy):
    n = 0
    for y, m in rows.items():
        fr = frame_rows.get(y + dy)
        if fr:
            n += (((m << dx) if dx >= 0 else (m >> -dx)) & fr).bit_count()
    return n


def rotate_pts(pts, angle, center, size=68):
    if angle == 0:
        return set(pts)
    m = Image.new("L", (size, size), 0)
    for p in pts:
        if 0 <= p[0] < size and 0 <= p[1] < size:
            m.putpixel(p, 255)
    m = m.rotate(angle, resample=Image.NEAREST, center=center)
    return {(x, y) for y in range(size) for x in range(size) if m.getpixel((x, y))}


# Góc nghiêng thử khi dò đầu: frame bị đánh ngửa ra sau và frame gục nằm có đầu xoay khỏi tư thế đứng.
ANGLES = (0, 15, -15, 30, -30, 50, -50, 75, -75, 90, -90)


def find_pose(frame_pts, poses, reach=12):
    """Tìm (góc, dx, dy) để đầu ở tư thế đứng (đã xoay) khớp nhất với frame; None nếu không khớp.

    Điểm = tỉ lệ pixel đầu trùng thân frame − tỉ lệ viền quanh đầu bị lấp. Chỉ đếm phần trùng thì
    đầu "khớp" ở bất kỳ chỗ nào nằm gọn trong ngực, nên phải phạt viền. Lệch xa và xoay nhiều bị trừ nhẹ
    để ưu tiên tư thế gần tư thế đứng."""
    frame_rows = bits(frame_pts)
    best, best_score = None, 0.0
    for angle, (head_rows, n_head, ring_rows, n_ring) in poses.items():
        for dy in range(-reach, reach + 1):
            for dx in range(-reach, reach + 1):
                hit = count(head_rows, frame_rows, dx, dy) / n_head
                if hit < 0.6:
                    continue
                fill = count(ring_rows, frame_rows, dx, dy) / n_ring
                score = hit - fill - 0.004 * (abs(dx) + abs(dy)) - 0.0015 * abs(angle)
                if score > best_score:
                    best, best_score = (angle, dx, dy), score
    return best if best_score > 0.5 else None


# --- Màu ------------------------------------------------------------------------

def dark(c):
    return max(c[:3]) < 50


def outline(im, x, y):
    """Pixel tối nằm sát nền trong là viền, giữ nguyên; pixel tối bên trong (bóng, quần đen) vẫn đổi màu."""
    for i, j in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        if not (0 <= x + i < im.width and 0 <= y + j < im.height) or im.getpixel((x + i, y + j))[3] == 0:
            return True
    return False


def shade(rule, lum):
    """Màu (h, s, độ sáng ×) ở độ sáng gốc lum (0..1) → (r, g, b)."""
    h, s, k = rule
    r, g, b = colorsys.hsv_to_rgb(h, s, min(1.0, 0.18 + lum * 0.8 * k))
    return round(r * 255), round(g * 255), round(b * 255)


def is_accent(c):
    """Pixel vàng / cam rực của thân gốc (lông Jaguar Lord, trang sức vàng của Grongi)."""
    h, s, v = colorsys.rgb_to_hsv(*(ch / 255 for ch in c[:3]))
    return 0.05 < h < 0.2 and s > 0.45 and v > 0.4


def glass_hue(spec, x, y):
    """Fangire: mỗi ô 4×4 (hàng so le như ghép kính) lấy một hue trong danh sách."""
    hues = spec["glass"]
    cx, cy = (x + (y // 4) * 2) // 4, y // 4
    return hues[(cx * 7 + cy * 13 + cx * cy) % len(hues)]


def tone(im, spec, shift=(0, 0), keep_white=False):
    """Đổi màu: pixel nhấn → accent, còn lại → tone (hoặc ô kính màu); giữ viền tối và độ sáng.
    shift: độ dịch của thân ở frame này, để ô kính màu đi theo người chứ không đứng yên trên màn hình."""
    out = im.copy()
    px = out.load()
    accent = spec.get("accent", spec["tone"])
    for y in range(im.height):
        for x in range(im.width):
            c = px[x, y]
            if c[3] == 0 or (dark(c) and outline(im, x, y)):
                continue
            if keep_white and min(c[:3]) > 150 and max(c[:3]) - min(c[:3]) < 40:
                continue
            lum = sum(c[:3]) / 765
            rule = accent if is_accent(c) else spec["tone"]
            if "glass" in spec and rule is spec["tone"]:
                rule = (glass_hue(spec, x - shift[0], y - shift[1]), rule[1], rule[2])
            px[x, y] = shade(rule, lum) + (c[3],)
    return out


def recolor_eye(im, hue, eye):
    """Pixel mắt (đúng khoảng hue, bão hoà, sáng) của hình đầu có sẵn → màu mắt mới."""
    if not hue:
        return im
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            c = px[x, y]
            h, s, v = colorsys.rgb_to_hsv(*(ch / 255 for ch in c[:3]))
            if c[3] and hue[0] <= h <= hue[1] and s > 0.45 and v > 0.55:
                px[x, y] = eye + (c[3],)
    return im


# --- Đầu ------------------------------------------------------------------------

def draw_head(parts, spec, anchor, size=68):
    """Vẽ đầu từ các mảnh PARTS, giữa cổ đặt tại anchor; tự thêm viền."""
    accent = spec.get("accent", spec["tone"])
    colors = {"a": shade(spec["tone"], 0.78), "b": shade(spec["tone"], 0.56), "c": shade(spec["tone"], 0.36),
              "x": shade(accent, 0.8), "y": shade(accent, 0.5), "e": spec["eye"], "w": BONE, "k": (34, 30, 40)}
    im = Image.new("RGBA", (size, size), CLEAR)
    for name in parts:
        dx, dy, grid = PARTS[name]
        for j, row in enumerate(grid):
            for i, ch in enumerate(row):
                x, y = anchor[0] + dx + i, anchor[1] + dy + j
                if ch != "." and 0 <= x < size and 0 <= y < size:
                    im.putpixel((x, y), colors[ch] + (255,))
    filled = solid(im)
    for (x, y) in filled:
        for i, j in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p = (x + i, y + j)
            if p not in filled and 0 <= p[0] < size and 0 <= p[1] < size and p[1] < anchor[1] - 1:
                im.putpixel(p, INK)
    return im


def new_head(spec, body_idle):
    """Ảnh 68×68 chứa đầu mới đặt sẵn đúng chỗ đầu thân ở tư thế đứng."""
    neck = NECK[spec["body"]]
    _, body_pts = head_part(body_idle, neck)
    anchor = (neck_mid(body_pts, neck), neck)
    head = spec["head"]
    if isinstance(head, list):
        return draw_head(head, spec, anchor)
    src = head["img"]
    img = recolor_eye(load(src, "Idle/rotations/east.png"), EYE_HUE.get(src), spec["eye"])
    img, pts = head_part(img, NECK[src])
    img = tone(img, spec, keep_white=src in KEEP_WHITE)
    placed = Image.new("RGBA", body_idle.size, CLEAR)
    placed.paste(img, (anchor[0] - neck_mid(pts, NECK[src]), neck - NECK[src]), img)
    return placed


def build(spec):
    body_idle = load(spec["body"], "Idle/rotations/east.png")
    neck = NECK[spec["body"]]
    _, body_head_pts = head_part(body_idle, neck)
    ring = ring_of(body_head_pts, neck)
    placed = new_head(spec, body_idle)
    pivot = (neck_mid(body_head_pts, neck), neck)   # xoay đầu quanh giữa cổ
    poses, heads = {}, {}
    for angle in ANGLES:
        hp, rp = rotate_pts(body_head_pts, angle, pivot), rotate_pts(ring, angle, pivot)
        poses[angle] = (bits(hp), len(hp), bits(rp), len(rp))
        heads[angle] = (hp, placed.rotate(angle, resample=Image.NEAREST, center=pivot))

    def make(frame):
        pose = find_pose(solid(frame), poses)
        if pose is None:
            return tone(frame, spec)
        angle, dx, dy = pose
        out = tone(frame, spec, (dx, dy))
        hp, head_img = heads[angle]
        px = out.load()
        for (x, y) in hp:   # xoá đầu cũ (nới thêm 1 pixel ngang); đầu thẳng thì không xoá dưới hàng cổ
            for ex in (-1, 0, 1):
                x2, y2 = x + dx + ex, y + dy
                if 0 <= x2 < out.width and 0 <= y2 < out.height and (angle or y2 <= neck + dy):
                    px[x2, y2] = CLEAR
        layer = Image.new("RGBA", out.size, CLEAR)
        layer.paste(head_img, (dx, dy), head_img)
        out.alpha_composite(layer)
        return out

    idle = make(body_idle)
    anims = {a: [make(f) for f in frames_of(spec["body"], a)] for a in ANIMS}
    return idle, anims


def save(name, idle, anims):
    root = os.path.join(OUT_DIR, name)
    rot = os.path.join(root, "Idle", "rotations")
    os.makedirs(rot, exist_ok=True)
    open(os.path.join(OUT_DIR, ".gdignore"), "a").close()   # frame gốc, Godot không cần import (như art/pixellab)
    idle.save(os.path.join(rot, "east.png"))
    frames = {"rotations": {"east": "Idle/rotations/east.png"}, "animations": {}}
    for a, frs in anims.items():
        d = os.path.join(root, "Idle", "animations", a, "east")
        os.makedirs(d, exist_ok=True)
        paths = []
        for i, f in enumerate(frs):
            rel = "Idle/animations/%s/east/frame_%03d.png" % (a, i)
            f.save(os.path.join(root, rel))
            paths.append(rel)
        frames["animations"][a] = {"east": paths}
    meta = {"kitbash": KITBASH[name], "states": [{"folder": "Idle", "frames": frames}]}
    with open(os.path.join(root, "metadata.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)


def preview(results, out_dir, per_sheet=12):
    """Mỗi ảnh tối đa per_sheet con, mỗi hàng: đứng + chạy + đánh + bị đánh + gục."""
    os.makedirs(out_dir, exist_ok=True)
    items = list(results.items())
    for start in range(0, len(items), per_sheet):
        chunk = items[start:start + per_sheet]
        cols = 1 + sum(len(f) for f in chunk[0][1][1].values())
        sheet = Image.new("RGBA", (cols * 68, len(chunk) * 68), (60, 60, 70, 255))
        for r, (_, (idle, anims)) in enumerate(chunk):
            for c, f in enumerate([idle] + [f for a in ANIMS for f in anims[a]]):
                sheet.alpha_composite(f, (c * 68, r * 68))
        path = os.path.join(out_dir, "kitbash_preview_%02d.png" % (start // per_sheet + 1))
        sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(path)
        print("Xem trước:", path, "·", ", ".join(n for n, _ in chunk))


def main():
    names = list(KITBASH)
    if "--only" in sys.argv:
        names = sys.argv[sys.argv.index("--only") + 1].split(",")
    results = {}
    for name in names:
        results[name] = build(KITBASH[name])
        save(name, *results[name])
    print("Đã ghép %d quái → %s" % (len(results), os.path.relpath(OUT_DIR, ROOT)))
    if "--preview" in sys.argv:
        preview(results, sys.argv[sys.argv.index("--preview") + 1])


if __name__ == "__main__":
    main()
