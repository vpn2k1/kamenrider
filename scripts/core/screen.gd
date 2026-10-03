extends RefCounted
class_name Screen
## Khung thiết kế 480×270 trên màn hình thật của máy.
##
## project.godot: stretch "canvas_items", aspect "expand", scale "integer": khung nhìn luôn phủ kín màn hình và không
## nhỏ hơn 480×270. Máy dài hơn 16:9 (điện thoại 19.5:9, 20:9) thì khung nhìn RỘNG hơn, máy vuông hơn (tablet 16:10,
## 4:3) thì CAO hơn. Vì vậy:
##   - Màn chơi: camera thấy rộng / cao hơn theo máy (StageRun.view_rect dùng kích thước thật).
##   - Giao diện vẽ theo hằng Rect trong khung 480×270 (màn chọn màn, chọn Rider / form, hội thoại, mở đầu):
##     đặt Control vào giữa màn hình (fit), nền vẽ tràn ra cả màn hình (bleed), toạ độ chạm đổi về khung (local).
##   - Nút cảm ứng, HUD: bám mép màn hình thật (extra).

const DESIGN := Vector2(480, 270)


## Kích thước khung nhìn thật (đơn vị thiết kế, đã chia hệ số phóng).
static func view(ci: CanvasItem) -> Vector2:
	return ci.get_viewport_rect().size


## Phần dư so với khung 480×270 (x > 0: máy dài hơn 16:9, y > 0: máy vuông hơn).
static func extra(ci: CanvasItem) -> Vector2:
	return (view(ci) - DESIGN).max(Vector2.ZERO)


## Đặt Control vẽ theo khung 480×270 vào giữa màn hình (bottom = true: sát đáy, như khung hội thoại).
static func fit(c: Control, bottom := false) -> void:
	var e := extra(c)
	c.position = Vector2(e.x / 2.0, e.y if bottom else e.y / 2.0)
	c.size = DESIGN


## Hình chữ nhật phủ kín màn hình, theo toạ độ của Control (để vẽ nền tràn viền).
static func bleed(c: Control) -> Rect2:
	return Rect2(-c.global_position, view(c))


## Phần màn hình bị che (tai thỏ, góc bo, thanh vuốt khi bật edge_to_edge) ở 4 cạnh, theo đơn vị thiết kế:
## Rect2(position = (trái, trên), size = (phải, dưới)). Máy tính / máy không tai thỏ: 0.
static func safe_insets(ci: CanvasItem) -> Rect2:
	var win := Rect2(Vector2(DisplayServer.window_get_position()), Vector2(DisplayServer.window_get_size()))
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if win.size.x <= 0.0 or safe.size.x <= 0.0:
		return Rect2()
	var k := view(ci).y / win.size.y      # px màn hình → đơn vị thiết kế
	var l := maxf(safe.position.x - win.position.x, 0.0) * k
	var t := maxf(safe.position.y - win.position.y, 0.0) * k
	var r := maxf(win.end.x - safe.end.x, 0.0) * k
	var b := maxf(win.end.y - safe.end.y, 0.0) * k
	return Rect2(l, t, r, b)


## Một đơn vị thiết kế dài bao nhiêu mm trên màn hình thật (theo DPI máy). Không đọc được DPI thì 0.
static func unit_mm(ci: CanvasItem) -> float:
	var dpi := DisplayServer.screen_get_dpi()
	var win_h := float(DisplayServer.window_get_size().y)
	if dpi <= 0 or win_h <= 0.0:
		return 0.0
	return win_h / view(ci).y / dpi * 25.4


## Toạ độ chạm (toạ độ khung nhìn) đổi về toạ độ khung 480×270 của Control đã fit.
static func local(c: Control, p: Vector2) -> Vector2:
	return p - c.global_position
