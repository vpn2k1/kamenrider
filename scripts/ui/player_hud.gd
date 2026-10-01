extends Control
## Thanh máu / nộ của người chơi (góc trên bên trái), vẽ bằng _draw để giữ nét pixel.
##
##   MÁU : dạng người màu đỏ. Khi biến thân: thanh chính là máu Rider (xanh lá),
##         thêm một vạch mảnh bên dưới cho máu dạng người.
##   NỘ  : cam. Dạng người: đầy thì nhấp nháy (biến thân được).
##         Dạng Rider: vạch trắng đánh dấu mức Final Attack. Ở form đặc biệt thanh chuyển tím,
##         hiện số giây còn lại trước khi về form gốc, dưới 25% thì nhấp nháy đỏ.

const LABEL_W := 22.0
const BAR_W := 90.0
const BAR_H := 5.0
const ROW_H := 9.0
const FONT_SIZE := 8

const COLOR_FRAME := Color(0.05, 0.04, 0.08)
const COLOR_EMPTY := Color(0.18, 0.17, 0.24)
const COLOR_HP_HUMAN := Color(0.9, 0.28, 0.28)
const COLOR_HP_RIDER := Color(0.35, 0.85, 0.45)
const COLOR_RAGE := Color(1.0, 0.5, 0.15)
const COLOR_RAGE_FUEL := Color(0.8, 0.35, 1.0)
const COLOR_RAGE_LOW := Color(1.0, 0.2, 0.25)
const LOW_FUEL := 25.0
const COLOR_TEXT := Color(1, 1, 1)

var player: Player
var form_text := ""        ## tên form + cấp, do màn chơi cập nhật


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var blink := Time.get_ticks_msec() % 300 < 150
	var y := 0.0

	# MÁU
	if player.current_form:
		var max_rider := player.current_form.get_max_hp()
		_bar(y, "MÁU", player.rider_hp / max_rider, COLOR_HP_RIDER,
			"%d/%d" % [ceili(player.rider_hp), ceili(max_rider)])
		y += ROW_H - 2.0
		_thin_bar(y, float(player.hp) / player.max_hp, COLOR_HP_HUMAN)
		y += 4.0
	else:
		_bar(y, "MÁU", float(player.hp) / player.max_hp, COLOR_HP_HUMAN, "%d/%d" % [player.hp, player.max_hp])
		y += ROW_H

	# NỘ
	var rage_ratio := player.rage / Player.GAUGE_MAX
	var rage_color := COLOR_RAGE
	var rage_text := "%d" % int(player.rage)
	if player.in_special_form():
		var low := player.rage < LOW_FUEL
		rage_color = COLOR_RAGE_LOW if low and blink else COLOR_RAGE_FUEL
		rage_text = "%ds" % ceili(player.rage / player.current_form.rage_drain())
	elif player.rage >= Player.GAUGE_MAX:
		rage_color = COLOR_RAGE.lightened(0.45) if blink else COLOR_RAGE
		rage_text = "MAX"
	_bar(y, "NỘ", rage_ratio, rage_color, rage_text)
	if player.current_form:
		var mark_x := LABEL_W + BAR_W * Player.FINAL_MIN_RAGE / Player.GAUGE_MAX
		draw_rect(Rect2(mark_x, y, 1.0, BAR_H + 2.0), Color(1, 1, 1, 0.7))
	y += ROW_H
	if form_text != "":
		draw_string_outline(ThemeDB.fallback_font, Vector2(0, y + 7.0), form_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			FONT_SIZE, 3, Color.BLACK)
		draw_string(ThemeDB.fallback_font, Vector2(0, y + 7.0), form_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			FONT_SIZE, Color(1, 0.9, 0.6))


func _bar(y: float, label: String, ratio: float, color: Color, value_text: String) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, y + 6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_TEXT)
	var x := LABEL_W
	draw_rect(Rect2(x - 1.0, y, BAR_W + 2.0, BAR_H + 2.0), COLOR_FRAME)
	draw_rect(Rect2(x, y + 1.0, BAR_W, BAR_H), COLOR_EMPTY)
	draw_rect(Rect2(x, y + 1.0, BAR_W * clampf(ratio, 0.0, 1.0), BAR_H), color)
	draw_rect(Rect2(x, y + 1.0, BAR_W * clampf(ratio, 0.0, 1.0), 1.0), color.lightened(0.35))
	draw_string(font, Vector2(x + BAR_W + 4.0, y + 6.0), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_TEXT)


func _thin_bar(y: float, ratio: float, color: Color) -> void:
	var x := LABEL_W
	draw_rect(Rect2(x - 1.0, y, BAR_W + 2.0, 3.0), COLOR_FRAME)
	draw_rect(Rect2(x, y + 1.0, BAR_W * clampf(ratio, 0.0, 1.0), 1.0), color)
