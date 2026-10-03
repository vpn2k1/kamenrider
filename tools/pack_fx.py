#!/usr/bin/env python3
"""
Ghép khung hoạt hình hiệu ứng PixelLab thành dải ngang art/fx/<kiểu>.png (khung 64×64) cho scripts/combat/fx.gd.

    python3 tools/pack_fx.py <thư mục khung> spark slash ...   # khung: <kiểu>_0.png, <kiểu>_1.png, ...

Khung 0 là ảnh gốc gửi lên animate_image. Bỏ các khung gần như trống ở cuối (hiệu ứng đã tan).
Trừ lửa, ảnh được chuyển sang trắng-xám (giữ độ sáng) để game tô theo màu form.
"""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art", "fx")
# Dấu hiệu tuyệt chiêu giữ màu nguyên tác (fx.gd SPRITES tint 1); seal / cards / circle tô theo màu form nên chuyển trắng.
KEEP_COLOR = {"fire", "crest", "dragon", "pointer", "phi", "taiko", "moon", "rings3", "crack", "fruit", "eye"}
REVERSE = {"sound"}       # PixelLab vẽ vòng co lại; đảo thứ tự để sóng nở ra
FLIP = {"slash"}          # ảnh gốc quay sang trái; game coi khung hướng phải rồi tự lật theo dir


def frames(src, kind):
    paths = glob.glob(os.path.join(src, "%s_[0-9]*.png" % kind))
    paths.sort(key=lambda p: int(p.rsplit("_", 1)[1][:-4]))
    ims = [Image.open(p).convert("RGBA") for p in paths]
    solid = [sum(1 for a in im.getchannel("A").getdata() if a > 40) for im in ims]
    end = len(ims)
    for i in range(1, len(ims)):
        if solid[i] < max(12, solid[0] * 0.03):
            end = i
            break
    return ims[:end]


def whiten(im):
    lum = im.convert("L").point(lambda v: min(255, int(v * 1.15 + 20)))
    out = Image.merge("RGBA", (lum, lum, lum, im.getchannel("A")))
    return out


def main():
    src, kinds = sys.argv[1], sys.argv[2:]
    os.makedirs(OUT, exist_ok=True)
    for kind in kinds:
        ims = frames(src, kind)
        if kind in REVERSE:
            ims.reverse()
        sheet = Image.new("RGBA", (64 * len(ims), 64), (0, 0, 0, 0))
        for i, im in enumerate(ims):
            im = im if kind in KEEP_COLOR else whiten(im)
            sheet.paste(im.transpose(Image.FLIP_LEFT_RIGHT) if kind in FLIP else im, (64 * i, 0))
        sheet.save(os.path.join(OUT, kind + ".png"))
        print("%s: %d khung" % (kind, len(ims)))


if __name__ == "__main__":
    main()
