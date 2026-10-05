#!/usr/bin/env python3
"""
Quái thú / đồng đội được skill gọi tới (scripts/combat/summon.gd), vẽ bằng PixelLab theo nguyên tác:
create_image_pixflux (1 lượt) rồi animate_image 8 khung (1 lượt mỗi 64×64, 2 lượt khung 128×64).

    python3 tools/gen_summons.py [tên ...]     # mặc định: mọi con trong CREATURES chưa có art/summons/<tên>.png

Khung lưu ở art/summons/src/<tên>_<i>.png (0 = ảnh gốc), dải ngang art/summons/<tên>.png. Nhìn sang phải.
Hết lượt miễn phí tạm thời ("long queues") thì chờ rồi thử lại.
"""
import os
import re
import sys
import time

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixellab  # noqa: E402

ROOT = pixellab.ROOT
OUT = os.path.join(ROOT, "art", "summons")
STYLE = {"no_background": True, "view": "side", "direction": "east", "outline": "single color black outline",
         "shading": "medium shading", "detail": "highly detailed"}
SERPENT = "flying forward, long body undulating in a smooth wave from head to tail, mouth opening"
WINGS = "flying forward, wings flapping up and down strongly"

CREATURES = {
    "dragreder": (128, 64, "Dragreder, the red mirror dragon of Kamen Rider Ryuki: long serpentine crimson eastern "
                  "dragon, armored head with golden horns and silver jaw, segmented red armored body, small claws, "
                  "flying horizontally, whole body visible, no wings", SERPENT),
    "dragranzer": (128, 64, "Dragranzer of Kamen Rider Ryuki Survive: crimson armored mechanical eastern dragon with "
                   "black armor plates, golden trim, glowing yellow eyes, flying horizontally, whole body visible",
                   SERPENT),
    "brave_dragon": (128, 64, "Brave Dragon of Kamen Rider Saber: red western dragon with golden armor plates on "
                     "head and chest, big red wings spread, long tail, flying horizontally, whole body visible", WINGS),
    "kivat": (64, 64, "Kivat-bat the 3rd of Kamen Rider Kiva: small black mechanical bat with big round orange "
              "eyes, golden fangs, red accents, wings spread wide, flying", WINGS),
    "kabuto_zecter": (64, 64, "Kabuto Zecter: shiny red mechanical rhinoceros beetle with one big upward horn, silver "
                      "legs, translucent wings open, flying", "flying forward, wings buzzing fast"),
    "parka_ghost": (64, 64, "Ore Parka Ghost of Kamen Rider Ghost: floating empty black hooded parka with orange "
                    "trim lines, glowing orange eyes inside the dark hood, floating sleeves, no legs",
                    "floating forward, sleeves and hem waving like cloth in the wind"),
    "vice": (64, 64, "Vice of Kamen Rider Revice: playful pink and black demon wearing a T-rex dinosaur head hood, "
             "round body, little claws, big grin", "hopping forward with a big bounce"),
}


def job_id(text):
    m = re.search(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", text)
    return m.group(0) if m else None


def submit(tool, args):
    while True:
        try:
            text = pixellab.call(tool, dict(args))
        except OSError as e:          # mạng chập chờn / máy chủ quá tải: thử lại
            print(tool, "->", e, flush=True)
            time.sleep(60)
            continue
        jid = job_id(text)
        if jid:
            return jid
        print(tool, "->", text.strip()[:160], flush=True)
        if "queue" in text or "concurrent" in text or "rate" in text or "heavy load" in text:
            time.sleep(90)
            continue
        sys.exit(1)


def make(name):
    w, h, desc, action = CREATURES[name]
    src = os.path.join(OUT, "src")
    base = os.path.join(src, name + "_key.png")
    if not os.path.exists(base):
        jid = submit("create_image_pixflux", dict(STYLE, description=desc, width=w, height=h))
        print(name, "create", jid, flush=True)
        if not pixellab.download(jid, base):
            sys.exit("hết giờ chờ " + jid)
    jid = submit("animate_image", {"first_frame_base64": "@" + base, "action": action, "frame_count": 8})
    print(name, "animate", jid, flush=True)
    for i in range(9):
        if not pixellab.download(jid, os.path.join(src, "%s_%d.png" % (name, i)), i):
            sys.exit("hết giờ chờ %s khung %d" % (jid, i))
    pack(name)


def pack(name):
    src = os.path.join(OUT, "src")
    ims = [Image.open(os.path.join(src, "%s_%d.png" % (name, i))).convert("RGBA") for i in range(1, 9)]
    w, h = ims[0].size
    sheet = Image.new("RGBA", (w * len(ims), h), (0, 0, 0, 0))
    for i, im in enumerate(ims):
        sheet.paste(im, (w * i, 0))
    sheet.save(os.path.join(OUT, name + ".png"))
    print(name, "xong", sheet.size, flush=True)


def main():
    names = sys.argv[1:] or [n for n in CREATURES if not os.path.exists(os.path.join(OUT, n + ".png"))]
    for n in names:
        make(n)


if __name__ == "__main__":
    main()
