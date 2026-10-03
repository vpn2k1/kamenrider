extends Node2D
## Vẽ màn khởi động (thay logo Godot) theo phong cách màn hình chính: trời sao, phố Tokyo, chữ VPN CHRONO.
## Chạy CÓ cửa sổ (headless không vẽ được), đúng cỡ khung 480×270 rồi phóng ×4 giữ nét pixel:
##   godot --path . --resolution 480x270 res://tools/gen_splash.tscn
##   → art/ui/brand/splash_480.png; tools/gen_splash.py phóng thành art/ui/brand/splash.png (1920×1080) và vẽ icon.
## project.godot: application/boot_splash/* trỏ tới splash.png, application/config/icon tới icon.png.

const OUT := "res://art/ui/brand/splash_480.png"
const CITY := preload("res://art/backgrounds/tokyo.png")
const GOLD := Color(1, 0.85, 0.3)
const VIEW := Vector2(480, 270)

var _frames := 0


func _draw() -> void:
	var sky := CITY.get_image().get_pixel(0, 0)
	draw_rect(Rect2(Vector2.ZERO, VIEW), sky)
	EarthMap.draw_stars(self, Rect2(0, 0, VIEW.x, 150), 0.0, 90)
	draw_texture(CITY, Vector2((VIEW.x - CITY.get_width()) / 2.0, VIEW.y - CITY.get_height()))
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.03, 0.02, 0.08, 0.55))
	var font := ThemeDB.fallback_font
	_title(font, Vector2(0, 168), "VPN CHRONO", 34, GOLD)
	_title(font, Vector2(0, 190), "Kamen Rider fan game", 10, Color(0.75, 0.65, 1))


func _title(font: Font, pos: Vector2, text: String, size: int, color: Color) -> void:
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x, size, 6, Color(0.03, 0.02, 0.08))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, VIEW.x, size, color)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 5:
		var img := get_viewport().get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(OUT))
		print("[gen_splash] %s %s" % [OUT, img.get_size()])
		get_tree().quit()
