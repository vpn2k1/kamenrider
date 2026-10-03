extends Control
class_name SettingsMenu
## Bảng Cài đặt âm thanh (mở từ nút "⚙ Cài đặt" ở màn hình chính): âm lượng chung và bật / tắt từng nhóm âm thanh
## (Sound.CATEGORIES: nhạc nền, đánh, kỹ năng, biến thân, quái, di chuyển, giao diện). Đổi là có tác dụng ngay và lưu
## luôn (Sound.save_settings). Bật lại một nhóm thì phát thử một tiếng của nhóm đó.
##   ▲ ▼ chọn dòng · ◀ ▶ chỉnh âm lượng / bật tắt · Enter / Đánh: bật tắt · Esc: đóng.
##   Chạm: chạm dòng để bật tắt, nút − / + cho âm lượng, nút ĐÓNG hoặc chạm ra ngoài bảng để đóng.

const GOLD := Color(1, 0.85, 0.3)
const PANEL := Rect2(40, 10, 400, 250)
const ROW_H := 22.0
const ROW_TOP := 48.0
const CLOSE := Rect2(190, 230, 100, 22)
const VOL_STEP := 0.1

static var _showing := 0
static var _closed_grace := 0

var _index := 0                  ## 0 = âm lượng chung, 1.. = các nhóm
var _sb := StyleBoxFlat.new()


## Có bảng Cài đặt đang mở (màn bên dưới bỏ qua phím, như HelpOverlay.is_showing).
static func is_showing() -> bool:
	return _showing > 0 or _closed_grace > 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sb.anti_aliasing = false
	_sb.corner_detail = 8


func open() -> void:
	if visible:
		return
	_index = 0
	position = Vector2.ZERO
	size = get_viewport_rect().size
	visible = true
	_showing += 1
	Sound.sfx("ui_ok", 0.0)
	queue_redraw()


func close() -> void:
	if not visible:
		return
	visible = false
	_showing -= 1
	_closed_grace = 2
	Sound.save_settings()
	Sound.sfx("ui_back", 0.0)


func _exit_tree() -> void:
	if visible:
		_showing -= 1
		Sound.save_settings()


func _process(_delta: float) -> void:
	if _closed_grace > 0:
		_closed_grace -= 1


func _rows() -> int:
	return 1 + Sound.CATEGORIES.size()


func _row_rect(i: int) -> Rect2:
	return Rect2(PANEL.position.x + 14.0, ROW_TOP + i * ROW_H, PANEL.size.x - 28.0, ROW_H - 3.0)


func _minus_rect() -> Rect2:
	var r := _row_rect(0)
	return Rect2(r.end.x - 150.0, r.position.y + 2.0, 20.0, r.size.y - 4.0)


func _plus_rect() -> Rect2:
	var r := _row_rect(0)
	return Rect2(r.end.x - 24.0, r.position.y + 2.0, 20.0, r.size.y - 4.0)


func _change_volume(step: float) -> void:
	Sound.set_master_volume(snappedf(Sound.master_volume + step, VOL_STEP))
	Sound.sfx("ui_move", 0.0)
	queue_redraw()


func _toggle(i: int) -> void:
	var c: Array = Sound.CATEGORIES[i - 1]
	var on := not Sound.is_enabled(c[0])
	Sound.set_enabled(c[0], on)
	Sound.sfx("ui_move", 0.0)
	if on and str(c[2]) != "":
		Sound.sfx(str(c[2]), 0.0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		if event.is_action("ui_cancel") or event.is_action("menu"):
			close()
		elif event.is_action("ui_up") or event.is_action("move_up"):
			_index = (_index - 1 + _rows()) % _rows()
			Sound.sfx("ui_move", 0.0)
		elif event.is_action("ui_down") or event.is_action("move_down"):
			_index = (_index + 1) % _rows()
			Sound.sfx("ui_move", 0.0)
		elif event.is_action("ui_left") or event.is_action("move_left"):
			if _index == 0:
				_change_volume(-VOL_STEP)
			else:
				_toggle(_index)
		elif event.is_action("ui_right") or event.is_action("move_right"):
			if _index == 0:
				_change_volume(VOL_STEP)
			else:
				_toggle(_index)
		elif (event.is_action("ui_accept") or event.is_action("attack_light")) and _index > 0:
			_toggle(_index)
		queue_redraw()
		return
	# Chỉ chặn lúc chạm xuống (như HelpOverlay): lúc nhả tay vẫn tới được nút ảo đang giữ.
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	get_viewport().set_input_as_handled()
	var p := touch.position - position
	if CLOSE.has_point(p) or not PANEL.has_point(p):
		close()
		return
	if _minus_rect().grow(4.0).has_point(p):
		_index = 0
		_change_volume(-VOL_STEP)
		return
	if _plus_rect().grow(4.0).has_point(p):
		_index = 0
		_change_volume(VOL_STEP)
		return
	for i in range(1, _rows()):
		if _row_rect(i).has_point(p):
			_index = i
			_toggle(i)
			return


# --- Vẽ -----------------------------------------------------------------------

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.0, 0.04, 0.82))
	_round(PANEL, Color(0.07, 0.06, 0.14, 0.98), 12, GOLD, 1)
	_text(Vector2(PANEL.position.x, PANEL.position.y + 18), "CÀI ĐẶT ÂM THANH", 11, GOLD, PANEL.size.x)
	_text(Vector2(PANEL.position.x, PANEL.position.y + 31), "▲ ▼ chọn · ◀ ▶ chỉnh / bật tắt · chạm để bật tắt", 6,
		Color(0.7, 0.7, 0.8), PANEL.size.x)
	for i in _rows():
		var r := _row_rect(i)
		var sel := i == _index
		_round(r, Color(0.16, 0.14, 0.26, 0.95) if sel else Color(0.1, 0.09, 0.18, 0.9), 6,
			GOLD if sel else Color(0.3, 0.28, 0.42), 1)
		if i == 0:
			draw_string(font, r.position + Vector2(8, 13), "Âm lượng chung", HORIZONTAL_ALIGNMENT_LEFT, 150, 8, Color.WHITE)
			_round(_minus_rect(), Color(0.25, 0.25, 0.35), 4, Color(0.6, 0.57, 0.8), 1)
			_text(_minus_rect().position + Vector2(0, 12), "−", 9, Color.WHITE, _minus_rect().size.x)
			_round(_plus_rect(), Color(0.25, 0.25, 0.35), 4, Color(0.6, 0.57, 0.8), 1)
			_text(_plus_rect().position + Vector2(0, 12), "+", 9, Color.WHITE, _plus_rect().size.x)
			var bar := Rect2(_minus_rect().end.x + 6.0, r.position.y + 7.0, _plus_rect().position.x - _minus_rect().end.x - 40.0, 6.0)
			_round(bar, Color(0.18, 0.17, 0.24), 3)
			if Sound.master_volume > 0.0:
				_round(Rect2(bar.position, Vector2(maxf(bar.size.x * Sound.master_volume, 6.0), bar.size.y)), GOLD, 3)
			draw_string(font, Vector2(bar.end.x + 4.0, r.position.y + 13.0), "%d%%" % roundi(Sound.master_volume * 100.0),
				HORIZONTAL_ALIGNMENT_LEFT, 30, 7, GOLD)
			continue
		var c: Array = Sound.CATEGORIES[i - 1]
		var on := Sound.is_enabled(c[0])
		draw_string(font, r.position + Vector2(8, 13), str(c[1]), HORIZONTAL_ALIGNMENT_LEFT, 280, 8,
			Color.WHITE if on else Color(0.6, 0.6, 0.68))
		# Công tắc bo tròn
		var sw := Rect2(r.end.x - 44.0, r.position.y + 3.0, 38.0, r.size.y - 6.0)
		_round(sw, Color(0.2, 0.6, 0.3) if on else Color(0.3, 0.3, 0.38), int(sw.size.y / 2.0))
		var knob := Vector2(sw.end.x - sw.size.y / 2.0 if on else sw.position.x + sw.size.y / 2.0, sw.get_center().y)
		draw_circle(knob, sw.size.y / 2.0 - 2.0, Color.WHITE)
		draw_string(font, Vector2(sw.position.x - 30.0, r.position.y + 13.0), "BẬT" if on else "TẮT",
			HORIZONTAL_ALIGNMENT_RIGHT, 26, 7, Color(0.6, 1.0, 0.65) if on else Color(0.7, 0.7, 0.78))
	_round(CLOSE, Color(0.85, 0.22, 0.25, 0.95), 11, GOLD, 1)
	_text(Vector2(CLOSE.position.x, CLOSE.position.y + 15), "ĐÓNG", 9, Color.WHITE, CLOSE.size.x)


func _round(r: Rect2, fill: Color, radius: int, border := Color.TRANSPARENT, border_width := 0) -> void:
	_sb.bg_color = fill
	_sb.set_corner_radius_all(radius)
	_sb.border_color = border
	_sb.set_border_width_all(border_width)
	draw_style_box(_sb, r)


func _text(pos: Vector2, text: String, font_size: int, color: Color, width: float) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 3, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
