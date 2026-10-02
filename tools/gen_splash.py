"""Màn khởi động và icon của game (thay logo Godot).

  godot --path . --resolution 480x270 res://tools/gen_splash.tscn   # vẽ art/ui/brand/splash_480.png
  python3 tools/gen_splash.py                                        # phóng + vẽ icon

splash.png : splash_480.png phóng ×4 (1920×1080, nearest) — application/boot_splash/image (cả bản web lúc tải)
icon.png   : 256×256, Trái Đất nhà (art/story/planets_48.png hàng 27, khung 0) trong khung bo tròn viền vàng
             — application/config/icon
Cần Pillow (python3 của Homebrew trong zsh có sẵn).
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "art/ui/brand"
BG = (8, 5, 20, 255)
GOLD = (255, 217, 77, 255)


def splash() -> None:
    small = Image.open(BRAND / "splash_480.png").convert("RGB")
    small.resize((small.width * 4, small.height * 4), Image.NEAREST).save(BRAND / "splash.png")


def icon() -> None:
    # Vẽ ở 64×64 rồi phóng ×4 để giữ nét pixel như trong game.
    s = 64
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, s - 1, s - 1), radius=12, fill=BG, outline=GOLD, width=2)
    for x, y in [(9, 12), (52, 9), (14, 50), (50, 47), (31, 6), (6, 33)]:
        d.point((x, y), fill=(220, 220, 255, 255))
    sheet = Image.open(ROOT / "art/story/planets_48.png").convert("RGBA")
    earth = sheet.crop((0, 27 * 48, 48, 28 * 48))   # hàng 27 = Tokyo 2026 (tools/gen_planets.py)
    img.alpha_composite(earth, ((s - earth.width) // 2, (s - earth.height) // 2))
    img.resize((s * 4, s * 4), Image.NEAREST).save(BRAND / "icon.png")


if __name__ == "__main__":
    splash()
    icon()
    print("[gen_splash] splash.png, icon.png ->", BRAND)
