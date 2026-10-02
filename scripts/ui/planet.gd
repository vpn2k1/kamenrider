extends RefCounted
class_name Planet
## Trái Đất pixel art tự quay (tools/gen_planets.py): mỗi thế giới một bản đồ lục địa riêng.
## Ảnh art/story/planets_<N>.png: hàng = Trái Đất (0..26 theo WorldData.FILES, HOME = Tokyo 2026), cột = khung quay.
## Ba cỡ đường kính 48 · 32 · 24: chọn cỡ nhỏ nhất đủ lớn rồi vẽ đúng kích thước yêu cầu.

const SHEETS := {
	24: preload("res://art/story/planets_24.png"),
	32: preload("res://art/story/planets_32.png"),
	48: preload("res://art/story/planets_48.png"),
}
const FRAMES := 64
const HOME := 27            ## hàng của Tokyo 2026
const SPIN := 6.0           ## khung / giây: một vòng quay ~10 giây


## Vẽ Trái Đất `row` tâm `center`, bán kính `radius`, khung theo thời gian `t`. modulate nhuộm màu (xám = bị phong ấn).
static func draw(ci: CanvasItem, center: Vector2, radius: float, row: int, t: float, modulate := Color.WHITE) -> void:
	var d := radius * 2.0
	var px := 48
	for s in [24, 32]:
		if d <= s:
			px = s
			break
	var tex: Texture2D = SHEETS[px]
	# Lệch khung theo hàng để các Trái Đất không quay cùng một nhịp
	var frame := (int(t * SPIN) + row * 11) % FRAMES
	var dst := Rect2((center - Vector2(radius, radius)).round(), Vector2(d, d))
	ci.draw_texture_rect_region(tex, dst, Rect2(frame * px, row * px, px, px), modulate)
