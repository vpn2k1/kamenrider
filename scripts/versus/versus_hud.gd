extends Control
class_name VersusHud
## HUD chế độ đấu: thanh máu / nộ của từng người chơi, số hiệp thắng, dòng chữ lớn giữa màn hình (đếm ngược, KO,
## kết quả). Vẽ bằng _draw như PlayerHud để giữ nét pixel.
##   1 vs 1: P1 bên trái, P2 bên phải.  ALL COMBAT (3–4 người): các ô xếp đều một hàng trên cùng, hẹp lại cho vừa.
##
## sides (do versus.gd cập nhật mỗi khung hình, theo thứ tự slot; người chơi trên máy này hay đối thủ qua mạng đều
## cùng dạng): {"slot", "name", "hp", "max_hp", "rider_hp", "rider_max" (0 = dạng người), "rage", "special", "drain",
##   "status", "wins", "you" (true = người chơi trên máy này), "ko" (đã gục trong hiệp này)}

const SLOT_COLORS := [Color(1.0, 0.45, 0.4), Color(0.45, 0.7, 1.0), Color(0.5, 0.95, 0.5), Color(1.0, 0.85, 0.35)]
const BAR_W := 110.0
const BAR_H := 5.0
const GAP := 6.0
const MARGIN_LEFT := 32.0       ## chừa chỗ nút ≡ Menu ở góc trái
const MARGIN_RIGHT := 8.0
const FONT_SIZE := 8

const COLOR_FRAME := Color(0.05, 0.04, 0.08)
const COLOR_EMPTY := Color(0.18, 0.17, 0.24)
const COLOR_HP_HUMAN := Color(0.9, 0.28, 0.28)
const COLOR_HP_RIDER := Color(0.35, 0.85, 0.45)
const COLOR_RAGE := Color(1.0, 0.5, 0.15)
const COLOR_RAGE_FUEL := Color(0.8, 0.35, 1.0)
const COLOR_WIN := Color(1, 0.85, 0.3)

var sides: Array = []
var wins_needed := 2
var round_text := ""
var banner := ""
var banner_small := ""

var _bw := BAR_W                ## bề rộng thanh của ô đang vẽ


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var n := sides.size()
	if n > 0:
		_bw = minf(BAR_W, (size.x - MARGIN_LEFT - MARGIN_RIGHT - (n - 1) * GAP) / n)
		for i in n:
			var x := MARGIN_LEFT + i * (_bw + GAP)
			if n == 2 and i == 1:
				x = size.x - MARGIN_RIGHT - _bw
			_side(x, sides[i])
	if round_text != "":
		# 1 vs 1: giữa hai ô; nhiều người: các ô chiếm hết hàng trên nên ghi xuống dưới.
		_text(Vector2(0, 12 if n <= 2 else 56), round_text, FONT_SIZE, Color(0.9, 0.9, 1.0), size.x)
	if banner != "":
		_text(Vector2(0, 112), banner, 20, COLOR_WIN, size.x, 5)
	if banner_small != "":
		_text(Vector2(0, 130), banner_small, 9, Color.WHITE, size.x)


func _side(x: float, s: Dictionary) -> void:
	var y := 4.0
	var font := ThemeDB.fallback_font
	var slot := int(s.get("slot", 0))
	var tag := "P%d %s%s" % [slot + 1, s.get("name", ""), " (bạn)" if s.get("you", false) else ""]
	_outlined(Vector2(x, y + 7.0), tag, SLOT_COLORS[slot % SLOT_COLORS.size()])
	# Hiệp thắng: chấm vàng ở cuối dòng tên.
	for k in wins_needed:
		var cx := x + _bw - 4.0 - k * 9.0
		var won: bool = k < int(s.get("wins", 0))
		draw_circle(Vector2(cx, y + 4.0), 3.5, COLOR_FRAME)
		draw_circle(Vector2(cx, y + 4.0), 2.5, COLOR_WIN if won else COLOR_EMPTY)
	y += 11.0

	var rider_max := float(s.get("rider_max", 0.0))
	if rider_max > 0.0:
		_bar(x, y, float(s["rider_hp"]) / rider_max, COLOR_HP_RIDER)
		y += BAR_H + 2.0
		_bar(x, y, float(s["hp"]) / maxf(float(s["max_hp"]), 1.0), COLOR_HP_HUMAN, 2.0)
		y += 5.0
	else:
		_bar(x, y, float(s.get("hp", 0)) / maxf(float(s.get("max_hp", 1)), 1.0), COLOR_HP_HUMAN)
		y += BAR_H + 4.0

	var rage := float(s.get("rage", 0.0))
	var special: bool = s.get("special", false)
	_bar(x, y, rage / Player.GAUGE_MAX, COLOR_RAGE_FUEL if special else COLOR_RAGE, 3.0)
	if rider_max > 0.0:
		draw_rect(Rect2(x + _bw * Player.FINAL_MIN_RAGE / Player.GAUGE_MAX, y, 1.0, 5.0), Color(1, 1, 1, 0.7))
	y += 6.0
	var status := "K.O." if s.get("ko", false) else str(s.get("status", ""))
	if special and not s.get("ko", false):
		status += "  %ds" % ceili(rage / maxf(float(s.get("drain", 1.0)), 0.01))
	var width := _bw + (40.0 if sides.size() <= 2 else 0.0)
	draw_string_outline(font, Vector2(x, y + 7.0), status, HORIZONTAL_ALIGNMENT_LEFT, width, 7, 3, Color.BLACK)
	draw_string(font, Vector2(x, y + 7.0), status, HORIZONTAL_ALIGNMENT_LEFT, width, 7,
		Color(1, 0.4, 0.35) if s.get("ko", false) else Color(1, 0.9, 0.6))


func _bar(x: float, y: float, ratio: float, color: Color, h := BAR_H) -> void:
	draw_rect(Rect2(x - 1.0, y - 1.0, _bw + 2.0, h + 2.0), COLOR_FRAME)
	draw_rect(Rect2(x, y, _bw, h), COLOR_EMPTY)
	draw_rect(Rect2(x, y, _bw * clampf(ratio, 0.0, 1.0), h), color)


func _outlined(pos: Vector2, text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var w := _bw - 6.0 - wins_needed * 9.0
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, w, FONT_SIZE, 3, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, w, FONT_SIZE, color)


func _text(pos: Vector2, text: String, font_size: int, color: Color, width: float, outline := 3) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, outline, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
