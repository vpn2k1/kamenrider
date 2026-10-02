extends Control
class_name HelpOverlay
## Bảng hướng dẫn nút bấm, chỉ có ở bản web (enabled()): mở bằng nút "?" (menu chính: góc trên phải; trong màn /
## trận: nút cảm ứng "help" dưới nút Menu, action "help").
##   Hai trang: BÀN PHÍM (phím của từng hành động, lấy từ GameState.INPUT_KEYS) và NÚT CẢM ỨNG (biểu tượng các nút ảo).
##   Máy có màn cảm ứng thì mở sẵn trang nút cảm ứng.
##   Đóng: nút ĐÓNG, chạm ra ngoài bảng, Esc / Enter / Đánh (J).
## pause_tree = true (màn chơi): dừng cả màn khi đang mở, đóng thì trả lại trạng thái dừng cũ (hội thoại...).
## Chế độ đấu để false (trận qua mạng không dừng được); versus.gd hỏi is_showing() để Esc không thoát trận.

const GOLD := Color(1, 0.85, 0.3)
const ICON_DIR := "res://art/ui/icons/"
const PANEL := Rect2(14, 12, 452, 246)
const CLOSE := Rect2(190, 230, 100, 22)
const TABS := [Rect2(140, 32, 96, 16), Rect2(244, 32, 96, 16)]
const TAB_NAMES := ["BÀN PHÍM", "NÚT CẢM ỨNG"]

## Trang bàn phím: [các action (phím ghép bằng " / "), ghi chú thêm sau phím, mô tả]. Hai cột.
const KEY_ROWS := [
	[[["move_left", "move_right"], "", "Di chuyển"],
	 [["jump"], "", "Nhảy · trên bệ: S + Space để xuống"],
	 [["move_down"], "giữ", "Cúi / thủ thế: đạn cao bay qua đầu"],
	 [["move_up"], "giữ", "Ngắm lên (form có súng)"],
	 [["attack_light"], "", "Đánh: chuỗi đấm rồi tự ra cú đá"],
	 [["attack_slash"], "", "Chém (có kiếm) · đúng lúc: chém tan / phản đạn"],
	 [["shoot"], "giữ", "Bắn (form có súng)"]],
	[[["dodge"], "", "Né đòn cận chiến (không tránh được đạn)"],
	 [["henshin"], "", "Biến thân (nộ đầy, đã có Driver)"],
	 [["special"], "", "Đổi form (tốn nộ)"],
	 [["final_attack"], "", "Final Attack (≥ 50 nộ, đốt hết nộ)"],
	 [["menu"], "", "Về màn chọn màn · quay lại · về màn hình chính"],
	 [[], "Enter", "Chọn trong menu, qua câu thoại"],
	 [[], "Esc", "Bỏ qua hội thoại"]],
]
## Trang cảm ứng: [biểu tượng, tên nút, mô tả]
const TOUCH_ROWS := [
	["left", "◀ ▶", "Di chuyển"],
	["up", "▲", "Nhảy · giữ để ngắm lên"],
	["down", "▼", "Cúi / thủ thế · bấm đúp trên bệ để xuống"],
	["fist", "Đánh", "Chuỗi đấm rồi tự ra cú đá"],
	["dodge", "Né", "Né đòn cận chiến"],
	["slash", "Chém", "Form có kiếm · đúng lúc thì chém / phản đạn"],
	["shoot", "Bắn", "Giữ để bắn (form có súng)"],
	["skill", "Kỹ năng", "Đổi form (tốn nộ)"],
	["ultimate", "Biến thân", "Nộ đầy: biến thân · đã biến thân: Final Attack"],
	["menu", "Menu", "Về màn chọn màn · quay lại"],
	["help", "?", "Mở bảng hướng dẫn này"],
]

## Bật bảng hướng dẫn ngoài bản web (xem trước trên máy, bot test).
static var force := false
static var _showing := 0
static var _closed_grace := 0   ## số khung hình sau khi đóng vẫn tính là "đang mở" (is_showing)

var pause_tree := false
var _tab := 0
var _was_paused := false
var _restore_pause := 0          ## đóng xong đợi chừng này khung hình mới cho màn chạy lại (phím đóng không lọt xuống)
var _sb := StyleBoxFlat.new()
var _icons := {}


static func enabled() -> bool:
	return force or OS.has_feature("web")


## Có bảng hướng dẫn nào đang mở (để màn khác bỏ qua phím Esc / Menu / Đánh). Tính cả khung hình vừa đóng:
## phím đóng bảng không được tính thêm là phím của màn bên dưới.
static func is_showing() -> bool:
	return _showing > 0 or _closed_grace > 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sb.anti_aliasing = false
	_sb.corner_detail = 8


func open() -> void:
	if visible or not enabled():
		return
	_tab = 1 if DisplayServer.is_touchscreen_available() else 0
	position = Vector2.ZERO
	size = get_viewport_rect().size
	visible = true
	_showing += 1
	# Nút ảo đang giữ (cả nút "?") sẽ không nhận được lúc nhả tay khi màn đã dừng: nhả hết trước.
	TouchButton.release_all(get_tree())
	if pause_tree:
		_was_paused = get_tree().paused
		get_tree().paused = true
	Sound.sfx("ui_ok", 0.0)
	queue_redraw()


func close() -> void:
	if not visible:
		return
	visible = false
	_showing -= 1
	_closed_grace = 2
	if pause_tree:
		_restore_pause = 2
	Sound.sfx("ui_back", 0.0)


func _exit_tree() -> void:
	if visible:
		_showing -= 1


func _process(_delta: float) -> void:
	if _closed_grace > 0:
		_closed_grace -= 1
	if _restore_pause > 0:
		_restore_pause -= 1
		if _restore_pause == 0:
			get_tree().paused = _was_paused
	if not visible:
		if enabled() and Input.is_action_just_pressed("help"):
			open()
		return


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Phím: xử lý ở đây và chặn lại, để Enter không bấm luôn nút đang chọn ở màn bên dưới.
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		for a in ["ui_cancel", "menu", "ui_accept", "attack_light"]:
			if event.is_action(a):
				get_viewport().set_input_as_handled()
				close()
				return
		for a in ["move_left", "move_right", "ui_left", "ui_right"]:
			if event.is_action(a):
				get_viewport().set_input_as_handled()
				_tab = 1 - _tab
				Sound.sfx("ui_move", 0.0)
				queue_redraw()
				return
	# Chỉ chặn lúc chạm xuống: lúc nhả tay phải tới được nút ảo đang giữ (nút "?"), nếu không action bị kẹt.
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	get_viewport().set_input_as_handled()
	var p := touch.position - position
	if CLOSE.has_point(p) or not PANEL.has_point(p):
		close()
		return
	for i in TABS.size():
		if (TABS[i] as Rect2).has_point(p) and i != _tab:
			_tab = i
			Sound.sfx("ui_move", 0.0)
			queue_redraw()


# --- Vẽ -----------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.0, 0.04, 0.82))
	_round(PANEL, Color(0.07, 0.06, 0.14, 0.98), 12, GOLD, 1)
	_text(Vector2(PANEL.position.x, PANEL.position.y + 15), "HƯỚNG DẪN", 11, GOLD, PANEL.size.x)
	for i in TABS.size():
		var r: Rect2 = TABS[i]
		var on := i == _tab
		_round(r, Color(0.75, 0.2, 0.25, 0.95) if on else Color(0.18, 0.17, 0.28, 0.95), 8,
			GOLD if on else Color(0.4, 0.38, 0.55), 1)
		_text(Vector2(r.position.x, r.position.y + 11), TAB_NAMES[i], 7, Color.WHITE if on else Color(0.7, 0.7, 0.8),
			r.size.x)
	if _tab == 0:
		_draw_keys()
	else:
		_draw_touch()
	_round(CLOSE, Color(0.85, 0.22, 0.25, 0.95), 11, GOLD, 1)
	_text(Vector2(CLOSE.position.x, CLOSE.position.y + 15), "ĐÓNG", 9, Color.WHITE, CLOSE.size.x)


func _draw_keys() -> void:
	var font := ThemeDB.fallback_font
	for c in KEY_ROWS.size():
		var x := PANEL.position.x + 10.0 + c * 222.0
		var rows: Array = KEY_ROWS[c]
		for i in rows.size():
			var row: Array = rows[i]
			var y := PANEL.position.y + 56.0 + i * 23.0
			var keys := _keys_text(row[0])
			var note := str(row[1])
			if keys == "":
				keys = note
			elif note != "":
				keys += " (%s)" % note
			var chip_w := clampf(font.get_string_size(keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10.0, 30.0, 84.0)
			_round(Rect2(x, y - 9.0, chip_w, 14.0), Color(0.2, 0.19, 0.32), 4, Color(0.5, 0.47, 0.7), 1)
			draw_string(font, Vector2(x + 5.0, y + 1.0), keys, HORIZONTAL_ALIGNMENT_LEFT, chip_w - 6.0, 7, GOLD)
			draw_string(font, Vector2(x + chip_w + 6.0, y + 1.0), str(row[2]), HORIZONTAL_ALIGNMENT_LEFT,
				212.0 - chip_w - 6.0, 7, Color(0.9, 0.9, 0.96))
	draw_string(font, Vector2(PANEL.position.x + 10.0, CLOSE.position.y - 6.0),
		"Mẹo: đạn đỏ ngang ngực thì cúi, đạn xanh sát đất thì nhảy · nộ đầy mới biến thân được",
		HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 20.0, 7, Color(0.75, 0.75, 0.85))


func _draw_touch() -> void:
	var font := ThemeDB.fallback_font
	var half := ceili(TOUCH_ROWS.size() / 2.0)
	for i in TOUCH_ROWS.size():
		var row: Array = TOUCH_ROWS[i]
		var x := PANEL.position.x + 10.0 + (i / half) * 222.0
		var y := PANEL.position.y + 60.0 + (i % half) * 32.0
		var c := Vector2(x + 12.0, y)
		draw_circle(c, 12.0, Color(0.2, 0.19, 0.32))
		draw_arc(c, 12.0, 0.0, TAU, 32, Color(0.6, 0.57, 0.8), 1.0)
		var tex := _icon(str(row[0]))
		if tex:
			draw_texture_rect(tex, Rect2(c - Vector2(8, 8), Vector2(16, 16)), false)
		draw_string(font, Vector2(x + 30.0, y - 2.0), str(row[1]), HORIZONTAL_ALIGNMENT_LEFT, 180, 8, GOLD)
		draw_string(font, Vector2(x + 30.0, y + 9.0), str(row[2]), HORIZONTAL_ALIGNMENT_LEFT, 180, 7,
			Color(0.88, 0.88, 0.95))
	draw_string(font, Vector2(PANEL.position.x + 10.0, CLOSE.position.y - 6.0),
		"Nút chỉ hiện khi dùng được (Bắn khi có súng, Chém khi có kiếm...) · vòng tối = đang hồi chiêu",
		HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 20.0, 7, Color(0.75, 0.75, 0.85))


## "A / D / ← / →" từ phím của các action trong GameState.INPUT_KEYS.
func _keys_text(actions: Array) -> String:
	var parts: Array[String] = []
	for a in actions:
		for k in GameState.INPUT_KEYS.get(a, []):
			var name := _key_name(int(k))
			if not parts.has(name):
				parts.append(name)
	# Phím chữ trước, phím mũi tên sau
	var letters := parts.filter(func(n: String) -> bool: return not n in ["←", "→", "↑", "↓"])
	var arrows := parts.filter(func(n: String) -> bool: return n in ["←", "→", "↑", "↓"])
	return " / ".join(PackedStringArray(letters + arrows))


static func _key_name(key: int) -> String:
	match key:
		KEY_LEFT:
			return "←"
		KEY_RIGHT:
			return "→"
		KEY_UP:
			return "↑"
		KEY_DOWN:
			return "↓"
		KEY_ESCAPE:
			return "Esc"
	return OS.get_keycode_string(key)


func _icon(name: String) -> Texture2D:
	if not _icons.has(name):
		var path := ICON_DIR + name + ".png"
		_icons[name] = load(path) if ResourceLoader.exists(path) else null
	return _icons[name]


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
