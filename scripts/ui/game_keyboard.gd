extends Control
class_name GameKeyboard
## Bàn phím trong game (kiểu Ninja School): thay bàn phím của hệ điều hành trên điện thoại khi nhập tên nhân vật,
## IP / số phòng đấu. Phím to, vẽ theo màu của game, nằm sát đáy màn hình (trong vùng an toàn), không làm thoát chế
## độ toàn màn hình như bàn phím Android.
##   Mode.TEXT:   chữ (q w e r t y...), ⇧ chữ hoa (bấm 1 lần: một chữ, bấm 2 lần: khoá hoa), 123 sang số và ký hiệu.
##   Mode.NUMBER: số 0–9, dấu chấm (IP), ⌫, OK. Không có phím chữ.
## Dùng: kb.attach(line_edit, GameKeyboard.Mode.TEXT). Chạm vào ô nhập thì bàn phím hiện, OK = text_submitted.
## Máy có bàn phím thật (máy tính) thì không hiện, gõ phím thường (force_show để thử trên máy tính).
## Ô nhập tắt bàn phím hệ thống (LineEdit.virtual_keyboard_enabled = false).

signal shown_changed(visible_now: bool)

enum Mode { TEXT, NUMBER }

const KEY_H := 26.0            ## chiều cao một phím (đơn vị thiết kế)
const GAP := 3.0
const PAD := 5.0
const FONT := 10
const BG := Color(0.04, 0.03, 0.1, 0.94)
const KEY_BG := Color(0.16, 0.14, 0.3)
const KEY_HOT := Color(0.32, 0.26, 0.55)
const SPECIAL_BG := Color(0.1, 0.09, 0.2)
const OK_BG := Color(0.75, 0.2, 0.24)
const GOLD := Color(1, 0.85, 0.3)

const ROWS_TEXT := [
	["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
	["a", "s", "d", "f", "g", "h", "j", "k", "l"],
	["⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"],
	["123", " ", "OK"],
]
const ROWS_SYMBOL := [
	["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
	["-", "_", ".", "@", "#", "!", "?", "*", "&"],
	["(", ")", "+", "=", "/", ":", "'", "~", "⌫"],
	["ABC", " ", "OK"],
]
const ROWS_NUMBER := [
	["1", "2", "3", "4", "5"],
	["6", "7", "8", "9", "0"],
	[".", "⌫", "OK"],
]

## Hiện cả trên máy không có màn hình cảm ứng (để thử trên máy tính).
static var force_show := false

var _target: LineEdit = null
var _mode := Mode.TEXT
var _symbols := false
var _shift := 0                ## 0 thường, 1 hoa một chữ, 2 khoá hoa
var _rows: Array = []
var _rects: Array = []         ## [Rect2, key] theo toạ độ của Control này
var _hot := ""                 ## phím đang được giữ (sáng lên)
var _hot_time := 0.0


static func wanted() -> bool:
	return force_show or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 50


## Gắn bàn phím vào ô nhập: tắt bàn phím hệ thống, chạm vào ô thì hiện bàn phím.
func attach(edit: LineEdit, mode := Mode.TEXT) -> void:
	edit.virtual_keyboard_enabled = false
	edit.focus_entered.connect(func() -> void: open(edit, mode))
	edit.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			open(edit, mode))


func open(edit: LineEdit, mode := Mode.TEXT) -> void:
	if not wanted():
		return
	_target = edit
	_target.caret_column = _target.text.length()   # gõ tiếp vào cuối
	_mode = mode
	_symbols = false
	_shift = 0
	_rebuild()
	if not visible:
		visible = true
		shown_changed.emit(true)


func close() -> void:
	if visible:
		visible = false
		shown_changed.emit(false)


## Chiều cao bàn phím (đơn vị thiết kế), để màn hình dời ô nhập lên trên bàn phím. 0 khi đang ẩn.
func panel_height() -> float:
	if not visible:
		return 0.0
	return _rows.size() * (KEY_H + GAP) + PAD * 2.0 + Screen.safe_insets(self).size.y


func _rebuild() -> void:
	if _mode == Mode.NUMBER:
		_rows = ROWS_NUMBER
	else:
		_rows = ROWS_SYMBOL if _symbols else ROWS_TEXT
	_layout_keys()
	queue_redraw()


## Toạ độ từng phím: hàng trải hết bề ngang vùng an toàn; phím đặc biệt (space, OK, ⇧...) rộng hơn.
func _layout_keys() -> void:
	_rects.clear()
	var view := Screen.view(self)
	var safe := Screen.safe_insets(self)
	var left := safe.position.x + PAD
	var width := view.x - safe.position.x - safe.size.x - PAD * 2.0
	var top := view.y - safe.size.y - PAD - _rows.size() * (KEY_H + GAP) + GAP
	# Bàn phím số gọn ở giữa, không trải cả màn hình dài.
	if _mode == Mode.NUMBER:
		var w := minf(width, 300.0)
		left += (width - w) / 2.0
		width = w
	for r in _rows.size():
		var row: Array = _rows[r]
		var weights: Array[float] = []
		var total := 0.0
		for key in row:
			var wgt := _weight(str(key))
			weights.append(wgt)
			total += wgt
		# Hàng thiếu phím (a s d...) co lại theo hàng 10 phím để phím cùng cỡ, căn giữa.
		var unit := (width - GAP * 9.0) / 10.0 if _mode == Mode.TEXT else (width - GAP * (row.size() - 1)) / total
		var row_w := unit * total + GAP * (row.size() - 1)
		if _mode == Mode.TEXT and r == _rows.size() - 1:
			unit = (width - GAP * (row.size() - 1)) / total
			row_w = width
		var x := left + (width - row_w) / 2.0
		var y := top + r * (KEY_H + GAP)
		for i in row.size():
			var w := unit * weights[i]
			_rects.append([Rect2(x, y, w, KEY_H), str(row[i])])
			x += w + GAP


func _weight(key: String) -> float:
	match key:
		" ":
			return 5.0
		"OK", "123", "ABC":
			return 2.0 if _mode == Mode.TEXT else 1.0
		"⇧", "⌫":
			return 1.5 if _mode == Mode.TEXT else 1.0
	return 1.0


func _gui_input(event: InputEvent) -> void:
	# Chạm trên điện thoại được Godot đổi thành chuột (emulate_mouse_from_touch), nên chỉ cần bắt chuột.
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos: Vector2 = event.position
	accept_event()
	for kr in _rects:
		if (kr[0] as Rect2).has_point(pos):
			_press(str(kr[1]))
			return
	# chạm ra ngoài phím (phía trên bàn phím) thì đóng
	var top: float = (_rects[0][0] as Rect2).position.y if not _rects.is_empty() else 0.0
	if pos.y < top - PAD:
		close()


func _has_point(point: Vector2) -> bool:
	# Chỉ chặn chạm ở dải bàn phím; phía trên vẫn chạm được ô nhập / nút của màn hình.
	if _rects.is_empty():
		return false
	return point.y >= (_rects[0][0] as Rect2).position.y - PAD


func _press(key: String) -> void:
	_hot = key
	_hot_time = 0.12
	Sound.sfx("ui_ok" if key == "OK" else "ui_move", 0.0, -6.0)
	match key:
		"OK":
			close()
			if _target:
				_target.text_submitted.emit(_target.text)
		"⌫":
			if _target and _target.text.length() > 0:
				var c := _target.caret_column
				if c > 0:
					_target.text = _target.text.left(c - 1) + _target.text.substr(c)
					_target.caret_column = c - 1
					_target.text_changed.emit(_target.text)
		"⇧":
			_shift = (_shift + 1) % 3
		"123":
			_symbols = true
			_rebuild()
		"ABC":
			_symbols = false
			_rebuild()
		_:
			_type(key.to_upper() if _shift > 0 else key)
			if _shift == 1:
				_shift = 0
	queue_redraw()


func _type(ch: String) -> void:
	if _target == null:
		return
	if _target.max_length > 0 and _target.text.length() >= _target.max_length:
		return
	var c := _target.caret_column
	_target.text = _target.text.left(c) + ch + _target.text.substr(c)
	_target.caret_column = c + ch.length()
	_target.text_changed.emit(_target.text)


func _process(delta: float) -> void:
	if not visible:
		return
	if _hot_time > 0.0:
		_hot_time -= delta
		if _hot_time <= 0.0:
			_hot = ""
			queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and visible:
		_layout_keys()
		queue_redraw()


func _draw() -> void:
	if _rects.is_empty():
		return
	var view := Screen.view(self)
	var top: float = (_rects[0][0] as Rect2).position.y - PAD
	draw_rect(Rect2(0, top, view.x, view.y - top), BG)
	draw_line(Vector2(0, top), Vector2(view.x, top), Color(GOLD, 0.6), 1.0)
	var font := ThemeDB.fallback_font
	for kr in _rects:
		var r: Rect2 = kr[0]
		var key: String = kr[1]
		var fill := KEY_BG
		if key == "OK":
			fill = OK_BG
		elif key in ["⇧", "⌫", "123", "ABC"]:
			fill = SPECIAL_BG
		if key == "⇧" and _shift > 0:
			fill = GOLD.darkened(0.45 if _shift == 1 else 0.2)
		if key == _hot:
			fill = KEY_HOT
		var box := StyleBoxFlat.new()
		box.bg_color = fill
		box.set_corner_radius_all(4)
		box.border_color = Color(1, 1, 1, 0.18)
		box.set_border_width_all(1)
		draw_style_box(box, r)
		var label := key
		if key == " ":
			label = "cách"
		elif _shift > 0 and key.length() == 1 and key != "⇧" and key != "⌫":
			label = key.to_upper()
		var size := FONT if label.length() <= 3 else FONT - 2
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(font, Vector2(r.position.x + (r.size.x - w) / 2.0, r.position.y + r.size.y / 2.0 + size * 0.36),
			label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, GOLD if key == "OK" else Color.WHITE)
