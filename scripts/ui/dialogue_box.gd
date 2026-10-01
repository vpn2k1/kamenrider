extends Control
class_name DialogueBox
## Khung hội thoại dạng chữ ở cuối màn hình: chân dung người nói, bảng tên, chữ chạy từng ký tự.
##   Đánh / Enter / Space / chạm: hiện hết câu, bấm lần nữa sang câu kế.
##   Esc hoặc chạm "BỎ QUA": bỏ qua cả đoạn (skipped = true).
## play(lines) rồi await finished. Câu thoại theo định dạng StoryData ([người nói, lời]).
## pause_tree = true (mặc định, dùng trong màn chơi): dừng cả game trong lúc thoại; khung này vẫn chạy
## (PROCESS_MODE_ALWAYS). Sau câu cuối đợi 2 khung hình rồi mới chạy lại game, để phím vừa bấm không
## lọt thành cú đấm / cú nhảy.
## backdrop "map": vẽ bản đồ Chuỗi Trái Đất (EarthMap) phía sau khung thoại.

signal finished

const BOX := Rect2(6, 198, 468, 66)
const PORTRAIT := Rect2(12, 204, 56, 56)
const SKIP := Rect2(396, 6, 78, 15)
const CHARS_PER_SEC := 55.0
const FONT_SIZE := 8
const PORTRAIT_DIR := "res://art/ui/portraits/%s.png"

var pause_tree := true
var skipped := false            ## đoạn vừa rồi bị bỏ qua bằng Esc / BỎ QUA
var _lines: Array = []
var _index := 0
var _shown := 0.0
var _t := 0.0
var _open := false
var _backdrop := ""
var _fresh := -1
var _was_paused := false
var _speaker: Dictionary = {}
var _portraits := {}
var _label: Label


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_constant_override("line_spacing", 2)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Giữ nguyên chỗ xuống dòng khi chữ chạy dần (không để từ nhảy dòng giữa chừng).
	_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func is_open() -> bool:
	return _open


## Mở một đoạn hội thoại. fresh: chỉ số thế giới vừa được giải cứu (cho backdrop "map").
func play(lines: Array, backdrop := "", fresh := -1) -> void:
	skipped = false
	if lines.is_empty():
		finished.emit.call_deferred()
		return
	_lines = lines
	_index = 0
	_backdrop = backdrop
	_fresh = fresh
	_t = 0.0
	_open = true
	visible = true
	if pause_tree:
		_was_paused = get_tree().paused
		get_tree().paused = true
	_show_line()


## Hiện hết câu đang chạy; nếu đã hiện hết thì sang câu kế (hết câu thì đóng).
func advance() -> void:
	if not _open:
		return
	var total := _total()
	if _label.visible_characters >= 0 and _label.visible_characters < total:
		_shown = float(total)
		_label.visible_characters = total
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_line()


func skip() -> void:
	if not _open:
		return
	skipped = true
	_close()


func _show_line() -> void:
	var line: Array = _lines[_index]
	_speaker = StoryData.SPEAKERS.get(str(line[0]), StoryData.SPEAKERS["narrator"])
	var area: Rect2
	if _portrait() == null:
		# Người dẫn truyện: không chân dung, chữ căn giữa cả khung.
		area = Rect2(BOX.position.x + 12.0, BOX.position.y + 6.0, BOX.size.x - 24.0, BOX.size.y - 14.0)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.add_theme_color_override("font_color", Color(0.86, 0.86, 0.96))
	else:
		area = Rect2(PORTRAIT.end.x + 8.0, BOX.position.y + 7.0, BOX.end.x - PORTRAIT.end.x - 18.0, BOX.size.y - 14.0)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_label.add_theme_color_override("font_color", Color.WHITE)
	# Đặt khung trước rồi mới gán chữ, sau đó đặt lại cỡ: Label tự xuống dòng mà nhận chữ lúc còn hẹp
	# sẽ tự giãn rất cao (chữ căn giữa bị đẩy ra ngoài màn hình) và không tự co lại.
	_label.position = area.position
	_label.size = area.size
	_label.text = GameState.format_text(str(line[1]))
	_label.size = area.size
	_shown = 0.0
	_label.visible_characters = 0
	queue_redraw()


func _close() -> void:
	_open = false
	visible = false
	_lines = []
	await get_tree().process_frame
	await get_tree().process_frame
	if pause_tree:
		get_tree().paused = _was_paused
	finished.emit()


func _process(delta: float) -> void:
	if not _open:
		return
	_t += delta
	var total := _total()
	if _label.visible_characters >= 0 and _label.visible_characters < total:
		_shown = minf(float(total), _shown + CHARS_PER_SEC * delta)
		_label.visible_characters = int(_shown)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		skip()
	elif event.is_action_pressed("attack_light") or event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()
		advance()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		get_viewport().set_input_as_handled()
		if SKIP.has_point((event as InputEventScreenTouch).position):
			skip()
		else:
			advance()


## Số ký tự của câu đang hiện. Không dùng Label.get_total_character_count(): ngay sau khi đổi chữ nó có thể
## còn trả về 0, bấm lúc đó sẽ nhảy qua mất câu.
func _total() -> int:
	return _label.text.length()


## Câu đang hiện đã chạy hết chữ chưa.
func is_line_done() -> bool:
	return _open and (_label.visible_characters < 0 or _label.visible_characters >= _total())


func _portrait() -> Texture2D:
	var id: String = _speaker.get("portrait", "")
	if id.is_empty():
		return null
	if not _portraits.has(id):
		var path := PORTRAIT_DIR % id
		_portraits[id] = load(path) if ResourceLoader.exists(path) else null
	return _portraits[id]


func _draw() -> void:
	if not _open:
		return
	var font := ThemeDB.fallback_font
	if _backdrop == "map":
		EarthMap.draw(self, Rect2(Vector2.ZERO, size), GameState.worlds_cleared, _t, _fresh)
	var col: Color = _speaker.get("color", Color.WHITE)
	draw_rect(BOX, Color(0.03, 0.02, 0.08, 0.94))
	draw_rect(BOX, col.darkened(0.15), false, 1.0)
	draw_rect(BOX.grow(-2.0), Color(col, 0.22), false, 1.0)

	var tex := _portrait()
	if tex:
		draw_rect(PORTRAIT, col.darkened(0.75))
		draw_rect(Rect2(PORTRAIT.position.x, PORTRAIT.end.y - 18.0, PORTRAIT.size.x, 18.0), col.darkened(0.6))
		draw_texture_rect(tex, PORTRAIT, false)
		draw_rect(PORTRAIT, col, false, 1.0)

	var speaker_name := GameState.format_text(str(_speaker.get("name", "")))
	if not speaker_name.is_empty():
		var w := font.get_string_size(speaker_name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + 12.0
		var plate := Rect2(BOX.position.x + 6.0, BOX.position.y - 11.0, w, 12.0)
		draw_rect(plate, col)
		draw_rect(plate, col.lightened(0.4), false, 1.0)
		draw_string(font, plate.position + Vector2(6, 9), speaker_name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE,
			Color(0.05, 0.04, 0.1))

	# Số câu và mũi tên "bấm để tiếp" khi câu đã hiện hết.
	draw_string(font, Vector2(BOX.end.x - 40.0, BOX.position.y - 2.0), "%d/%d" % [_index + 1, _lines.size()],
		HORIZONTAL_ALIGNMENT_RIGHT, 34.0, 7, Color(col, 0.8))
	var done := _label.visible_characters < 0 or _label.visible_characters >= _total()
	if done and fmod(_t, 0.8) < 0.5:
		var p := Vector2(BOX.end.x - 10.0, BOX.end.y - 8.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -3), p + Vector2(4, -3), p + Vector2(0, 2)]), col.lightened(0.3))

	draw_rect(SKIP, Color(0.02, 0.01, 0.06, 0.75))
	draw_rect(SKIP, Color(0.6, 0.58, 0.75), false, 1.0)
	draw_string(font, SKIP.position + Vector2(0, 11), "BỎ QUA (Esc) »", HORIZONTAL_ALIGNMENT_CENTER, SKIP.size.x, 7,
		Color(0.9, 0.9, 1.0))
