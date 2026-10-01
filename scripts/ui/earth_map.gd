extends RefCounted
class_name EarthMap
## Bản đồ Chuỗi Phong Ấn: các Trái Đất theo năm phát sóng, nối nhau bằng xích tinh thể, từ Tokyo 2026 tới Điểm Không.
## Dùng ở cảnh cuối phần mở đầu và sau trùm mỗi thế giới (DialogueBox backdrop "map").
##   - Hàng trên: Tokyo 2026 · cửa sổ WINDOW Trái Đất quanh chặng đang tới · Điểm Không.
##     Đã giải cứu: sáng màu Rider, đường nối vàng. Đang tới: nhấp nháy, có chân dung nhân vật chính.
##     Chưa tới: xám, khóa tinh thể tím.
##   - Dải dòng thời gian bên dưới: mỗi thế giới một chấm theo năm (2000 → 2025).
## Vẽ bằng lệnh _draw của CanvasItem được truyền vào để giữ nét pixel.

const EARTH_TEX := preload("res://art/story/earth.png")
const VOID_TEX := preload("res://art/story/void.png")
const HERO_TEX := preload("res://art/ui/portraits/hero.png")
const GOLD := Color(1.0, 0.85, 0.35)
const SEAL := Color(0.72, 0.4, 1.0)
const LOCKED := Color(0.32, 0.32, 0.4)
const HOME_COLOR := Color(0.4, 0.65, 1.0)
const ZERO_COLOR := Color(0.7, 0.35, 1.0)
const WINDOW := 7


## cleared: số thế giới đã qua (GameState.worlds_cleared). fresh: chỉ số thế giới vừa được giải cứu (-1 = không có),
## chạy hiệu ứng sáng lại trong 1.6 giây đầu. t: thời gian (giây) cho hiệu ứng.
static func draw(ci: CanvasItem, rect: Rect2, cleared: int, t: float, fresh := -1) -> void:
	var worlds: Array = WorldData.WORLDS
	var total := worlds.size()
	ci.draw_rect(rect, Color(0.03, 0.02, 0.08))
	draw_stars(ci, rect, t, 90)
	_text(ci, Vector2(rect.position.x, rect.position.y + 20), "CHUỖI PHONG ẤN", 12, GOLD, rect.size.x)
	var year := ""
	if cleared < total:
		year = " · chặng tới: %s (%d)" % [worlds[cleared]["rider_name"], worlds[cleared]["year"]]
	_text(ci, Vector2(rect.position.x, rect.position.y + 33),
		"Trái Đất đã giải cứu: %d / %d%s" % [cleared, total, year], 8, Color(0.8, 0.8, 0.92), rect.size.x)

	# Hàng trên: nhà · cửa sổ WINDOW thế giới · Điểm Không
	var first := clampi(cleared - WINDOW / 2, 0, maxi(total - WINDOW, 0))
	var shown := mini(WINDOW, total)
	var slots := shown + 2
	var points: Array[Vector2] = []
	for k in slots:
		var x := rect.position.x + 30.0 + (rect.size.x - 60.0) * float(k) / float(slots - 1)
		points.append(Vector2(x, rect.position.y + 88.0 + sin(float(k + first) * 1.3) * 14.0))
	var reached := cleared - first + 1     # vị trí slot của Trái Đất đang tới
	for k in slots - 1:
		var a := points[k]
		var b := points[k + 1]
		var gap := (k == 0 and first > 0) or (k == slots - 2 and first + shown < total)
		if k < reached:
			ci.draw_line(a, b, GOLD.darkened(0.2), 2.0)
		else:
			var links := int(a.distance_to(b) / 7.0)
			for j in range(1, links):
				var p := a.lerp(b, float(j) / float(links))
				_diamond(ci, p, 2.5, SEAL * Color(1, 1, 1, 0.6 + 0.4 * sin(t * 3.0 + float(j + k * 3))))
		if gap:
			for j in 3:
				ci.draw_circle(a.lerp(b, 0.4 + 0.1 * j) + Vector2(0, -8), 1.5, Color(0.85, 0.85, 1.0, 0.8))
	var r := 12.0
	_node(ci, points[0], r, HOME_COLOR, "Tokyo 2026", "", t, "cleared", false)
	for k in shown:
		var i := first + k
		var w: Dictionary = worlds[i]
		var state := "cleared" if i < cleared else ("next" if i == cleared else "locked")
		_node(ci, points[k + 1], r, w.get("color", Color.WHITE), str(w["rider_name"]), str(w["year"]), t, state, i == fresh)
	var zp := points[slots - 1]
	ci.draw_circle(zp, r + 6.0 + (0.5 + 0.5 * sin(t * 2.2)) * 3.0, Color(SEAL, 0.18))
	_earth(ci, zp, r, ZERO_COLOR.darkened(0.25))
	ci.draw_texture_rect(VOID_TEX, Rect2(zp + Vector2(-8, -r - 30), Vector2(16, 26)), false)
	_label(ci, zp, r, "Điểm Không", "", Color(0.85, 0.6, 1.0))

	# Dải dòng thời gian: một chấm mỗi thế giới
	var y := rect.position.y + 162.0
	var x0 := rect.position.x + 40.0
	var x1 := rect.end.x - 40.0
	ci.draw_line(Vector2(x0, y), Vector2(x1, y), Color(0.35, 0.33, 0.5), 1.0)
	var font := ThemeDB.fallback_font
	for i in total:
		var px := x0 + (x1 - x0) * float(i) / float(maxi(total - 1, 1))
		var col: Color = worlds[i].get("color", Color.WHITE) if i < cleared else LOCKED
		if i == cleared:
			ci.draw_circle(Vector2(px, y), 4.0 + sin(t * 4.0), Color(GOLD, 0.6))
		ci.draw_rect(Rect2(px - 2.0, y - 2.0, 4.0, 4.0), col)
	ci.draw_string(font, Vector2(x0 - 30.0, y + 3.0), "2000", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7, 0.7, 0.85))
	ci.draw_string(font, Vector2(x1 + 6.0, y + 3.0), str(worlds[total - 1]["year"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
		Color(0.7, 0.7, 0.85))


static func _node(ci: CanvasItem, p: Vector2, r: float, col: Color, name: String, year: String, t: float,
		state: String, fresh: bool) -> void:
	var shown := col
	if state == "locked":
		shown = LOCKED
	elif fresh and t < 1.6:
		shown = LOCKED.lerp(col, clampf(t / 1.2, 0.0, 1.0))
	if state == "next":
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		ci.draw_arc(p, r + 4.0 + pulse * 2.0, 0.0, TAU, 32, Color(GOLD, 0.5 + 0.5 * pulse), 1.5)
	elif state != "locked":
		ci.draw_circle(p, r + 4.0, Color(col, 0.18))
	if fresh and t < 1.6:
		ci.draw_arc(p, r + t * 30.0, 0.0, TAU, 40, Color(col, maxf(0.0, 1.0 - t / 1.6)), 2.0)
	_earth(ci, p, r, shown)
	if state == "locked":
		_diamond(ci, p + Vector2(0, 2), 5.0, SEAL)
		_diamond(ci, p + Vector2(0, 2), 2.5, Color(0.95, 0.8, 1.0))
	if state == "next":
		var hp := p + Vector2(-10, -r - 26 + sin(t * 3.0) * 2.0)
		ci.draw_rect(Rect2(hp - Vector2(1, 1), Vector2(22, 22)), GOLD)
		ci.draw_texture_rect(HERO_TEX, Rect2(hp, Vector2(20, 20)), false)
	_label(ci, p, r, name, year, Color(0.92, 0.92, 1.0) if state != "locked" else Color(0.55, 0.55, 0.65))


static func _label(ci: CanvasItem, p: Vector2, r: float, name: String, year: String, col: Color) -> void:
	var font := ThemeDB.fallback_font
	ci.draw_string(font, Vector2(p.x - 36.0, p.y + r + 12.0), name, HORIZONTAL_ALIGNMENT_CENTER, 72.0, 7, col)
	if not year.is_empty():
		ci.draw_string(font, Vector2(p.x - 36.0, p.y + r + 21.0), year, HORIZONTAL_ALIGNMENT_CENTER, 72.0, 6, Color(col, 0.7))


static func _earth(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var size := Vector2(radius, radius) * 2.0
	ci.draw_texture_rect(EARTH_TEX, Rect2(center - size / 2.0, size), false, color.lightened(0.15))


static func _diamond(ci: CanvasItem, p: Vector2, r: float, color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.7, 0), p + Vector2(0, r), p + Vector2(-r * 0.7, 0)]), color)


## Sao lấp lánh, vị trí cố định theo hạt giống để không nhảy lung tung giữa các khung hình.
static func draw_stars(ci: CanvasItem, rect: Rect2, t: float, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in count:
		var p := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		var tw := 0.45 + 0.55 * absf(sin(t * rng.randf_range(0.6, 2.2) + rng.randf() * TAU))
		var big := rng.randf() < 0.12
		ci.draw_rect(Rect2(p.floor(), Vector2(2, 2) if big else Vector2(1, 1)), Color(0.85, 0.85, 1.0, tw))


static func _text(ci: CanvasItem, pos: Vector2, text: String, font_size: int, color: Color, width: float) -> void:
	var font := ThemeDB.fallback_font
	ci.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 3, Color.BLACK)
	ci.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
