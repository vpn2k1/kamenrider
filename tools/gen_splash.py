"""Màn khởi động và icon của game (thay logo Godot).

  godot --path . --resolution 480x270 res://tools/gen_splash.tscn   # vẽ art/ui/brand/splash_480.png
  python3 tools/gen_splash.py                                        # phóng + vẽ icon

splash.png : splash_480.png phóng ×4 (1920×1080, nearest) — application/boot_splash/image (cả bản web lúc tải)
icon.png   : 256×256, Trái Đất nhà (art/story/planets_48.png hàng 27, khung 0) trong khung bo tròn viền vàng
             — application/config/icon
android_*.png : icon Android (export_presets.cfg launcher_icons/*): main 192×192, adaptive 432×432 gồm nền (trời sao),
             hình (Trái Đất, trong vùng an toàn 66% giữa vì launcher cắt tròn / vuông tuỳ máy) và bản đơn sắc (Android 13+)
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


def _earth() -> Image.Image:
    sheet = Image.open(ROOT / "art/story/planets_48.png").convert("RGBA")
    return sheet.crop((0, 27 * 48, 48, 28 * 48))


def android() -> None:
    Image.open(BRAND / "icon.png").resize((192, 192), Image.NEAREST).save(BRAND / "android_main.png")
    # Adaptive: vẽ ở 108×108 (đúng lưới dp của Android) rồi phóng ×4 = 432.
    s = 108
    bg = Image.new("RGBA", (s, s), BG)
    d = ImageDraw.Draw(bg)
    for x, y in [(14, 20), (90, 16), (22, 86), (86, 80), (52, 10), (10, 54), (96, 50), (60, 98)]:
        d.point((x, y), fill=(220, 220, 255, 255))
    bg.resize((s * 4, s * 4), Image.NEAREST).save(BRAND / "android_background.png")
    fg = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    earth = _earth()
    fg.alpha_composite(earth, ((s - earth.width) // 2, (s - earth.height) // 2))
    fg.resize((s * 4, s * 4), Image.NEAREST).save(BRAND / "android_foreground.png")
    mono = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    alpha = earth.getchannel("A").point(lambda a: 255 if a > 0 else 0)
    mono.paste(Image.new("RGBA", earth.size, (255, 255, 255, 255)), ((s - earth.width) // 2, (s - earth.height) // 2), alpha)
    mono.resize((s * 4, s * 4), Image.NEAREST).save(BRAND / "android_monochrome.png")


if __name__ == "__main__":
    splash()
    icon()
    android()
    print("[gen_splash] splash.png, icon.png ->", BRAND)
