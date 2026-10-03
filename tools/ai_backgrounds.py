#!/usr/bin/env python3
"""
Nền riêng cho các màn từng dùng chung kiểu "city_night" / "city_day" (trông y hệt nhau), vẽ bằng PixelLab.

    python3 tools/ai_backgrounds.py              # vẽ các nền chưa có (1 lượt PixelLab mỗi nền)
    python3 tools/ai_backgrounds.py ryuki_3      # vẽ lại vài nền
    python3 tools/ai_backgrounds.py --build      # chỉ dựng lại ảnh game từ ảnh gốc, không tốn lượt

Ảnh gốc 400×224 (create_image_pixflux, img2img từ nửa trái nền vẽ bằng code để giữ đường chân trời) lưu ở
art/backgrounds/ai/<tên>.png (có .gdignore). Ảnh game art/backgrounds/<tên>.png = gốc + bản lật, rộng 800 px nên
nối liền khi lặp; hàng trên cùng tô một màu (game lấy điểm (0, 0) làm màu trời). gen_backgrounds.py bỏ qua các nền này.
"""
import json
import os
import re
import subprocess
import sys
import time

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = os.path.join(ROOT, "art", "backgrounds")
AI = os.path.join(BG, "ai")
STYLE = ("side view pixel art parallax background for a 2D platformer, distant scenery, buildings standing on a "
         "flat horizon line near the bottom, wide sky above, no people, no text, ")
PROMPTS = {
    "agito_3": "police headquarters tower at night with blue searchlights sweeping the sky, city skyline",
    "ryuki_1": "busy Tokyo shopping street in daytime, newspaper office building, signboards, blue sky with clouds",
    "ryuki_3": "riverside park at night, calm river reflecting city lights, arched bridge, trees, full moon",
    "kabuto_1": "quiet street with a small french bistro and flower shops, sunny afternoon, blue sky",
    "kabuto_3": "dense Shibuya skyline at night filling the lower half, tall damaged buildings with lit windows, a glowing meteor crater, fiery meteor streak across the starry sky",
    "kiva_1": "night street with an old cafe and gothic stone buildings, huge full moon, bats",
    "den_o_1": "cozy cafe on a quiet hill street at noon, star shaped decorations, bright blue sky",
    "ooo_1": "colourful street with a themed restaurant and shop fronts, sunny day, puffy clouds",
    "ooo_6": "giant corporate skyscraper at night with glowing red yellow green ring lights, city skyline",
    "gaim_1": "outdoor dance stage in a city park, colourful banners, huge white corporate tower far away, sunny day",
    "gaim_4": "enormous futuristic white corporate tower at night, alien jungle vines creeping over the city",
    "drive_1": "driving test centre with a race track, garages and traffic lights, city in the distance, daytime",
    "build_4": "fortified military base at night, watchtowers, searchlights, giant wall splitting the city, red glow",
    "zi_o_4": "post-apocalyptic ruined city in the year 2068, broken skyscrapers, dark red sky, giant stone statues",
    "zero_one_2": "futuristic amusement park, ferris wheel, roller coaster, sleek high-tech city, bright daytime",
    "revice_2": "high-tech military headquarters building with a rooftop helipad and antennas, empty, city skyline, daytime blue sky with clouds",
    "revice_3": "old japanese neighbourhood at night, traditional bathhouse with a tall chimney, paper lanterns",
    "geats_1": "city plaza in daytime with colourful futuristic game arena barriers and a giant screen",
    "gotchard_4": "city street at night where buildings are turning into shining gold, golden sparkles",
    "gavv_4": "night sweets festival street with food stalls, lanterns and giant candy decorations",
    "zeztz_2": "dreamlike rooftops at night, floating glowing shapes, surreal purple sky over the city",
}


def call(tool, args):
    for _ in range(40):
        out = subprocess.run(["python3", os.path.join(ROOT, "tools", "pixellab.py"),
                              "call", tool, json.dumps(args)], capture_output=True, text=True).stdout
        m = re.search(r"job_id: ([0-9a-f-]{36})", out)
        if m:
            return m.group(1)
        print("  thử lại:", out.strip()[:160], flush=True)
        time.sleep(15)
    return None


def build(name):
    """Ảnh gốc 400 px → ảnh game 800 px (gốc + bản lật), sửa hàng trên cùng thành một màu."""
    src = Image.open(os.path.join(AI, name + ".png")).convert("RGBA")
    if src.size != (400, 224):
        src = src.resize((400, 224), Image.NEAREST)
    out = Image.new("RGBA", (800, 224))
    out.paste(src, (0, 0))
    out.paste(src.transpose(Image.FLIP_LEFT_RIGHT), (400, 0))
    row = [out.getpixel((x, 0)) for x in range(0, 800, 8)]
    top = tuple(sorted(c[i] for c in row)[len(row) // 2] for i in range(3)) + (255,)
    ImageDraw.Draw(out).rectangle((0, 0, 799, 1), fill=top)
    out.save(os.path.join(BG, name + ".png"))


def main():
    args = sys.argv[1:]
    os.makedirs(AI, exist_ok=True)
    if args[:1] == ["--build"]:
        for f in sorted(os.listdir(AI)):
            if f.endswith(".png"):
                build(f[:-4])
        return
    names = args or [n for n in PROMPTS if not os.path.exists(os.path.join(AI, n + ".png"))]
    for name in names:
        init = os.path.join(AI, name + "_init.png")
        Image.open(os.path.join(BG, name + ".png")).convert("RGB").crop((0, 0, 400, 224)).save(init)
        job = call("create_image_pixflux", {"description": STYLE + PROMPTS[name], "width": 400, "height": 224,
                                            "init_image_base64": "@" + init, "init_image_strength": 60,
                                            "view": "side", "no_background": False})
        os.remove(init)
        if not job:
            continue
        subprocess.run(["python3", os.path.join(ROOT, "tools", "pixellab.py"), "download", job,
                        os.path.join(AI, name + ".png")])
        build(name)
        print("xong", name, flush=True)


if __name__ == "__main__":
    main()
