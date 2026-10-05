extends Control
class_name ConfirmDialog
## Hộp hỏi xác nhận Có / Không (ví dụ bấm Menu giữa màn: "Quay lại màn chọn màn?"). Màn chơi dừng
## (get_tree().paused) trong lúc hỏi; hộp này chạy PROCESS_MODE_ALWAYS.
##   ◀ ▶ đổi nút · Enter / Đánh chọn · Esc / Menu / nút back Android = Không. Chạm nút để chọn.
## Mặc định chọn sẵn nút Không (nút an toàn), để bấm nhầm Enter không mất tiến trình.

signal answered(yes: bool)

const PANEL := Vector2(300, 118)
const BUTTON := Vector2(112, 26)
const GOLD := Color(1, 0.85, 0.3)

static var _showing := 0

var _title := ""
var _message := ""
var _yes_text := "CÓ"
var _no_text := "KHÔNG"
var _index := 1                  ## 0 = Có, 1 = Không
var _opened_frame := -1


## Đang có hộp xác nhận mở (màn bên dưới bỏ qua phím, như SettingsMenu.is_showing).
static func is_showing() -> bool:
	return _showing > 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	z_index = 60


func open(title: String, message: String, yes_text := "CÓ", no_text := "KHÔNG") -> void:
	_title = title
	_message = message
	_yes_text = yes_text
	_no_text = no_text
	_index = 1
	_opened_frame = Engine.get_process_frames()
	position = Vector2.ZERO
	size = get_viewport_rect().size
	if not visible:
		_showing += 1
	visible = true
	queue_redraw()


func _exit_tree() -> void:
	if visible:
		_showing -= 1


func _process(_delta: float) -> void:
	# Phím vừa mở hộp (Menu / Esc) còn "just pressed" trong khung đó: bỏ qua để hộp không tự đóng ngay.
	if not visible or Engine.get_process_frames() == _opened_frame:
		return
	if Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("ui_cancel"):
		_answer(false)
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right") \
			or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		_index = 1 - _index
		Sound.sfx("ui_move", 0.0)
		queue_redraw()
	elif Input.is_action_just_pressed("attack_light") or Input.is_action_just_pressed("ui_accept"):
		_answer(_index == 0)


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if not visible or touch == null or not touch.pressed:
		return
	get_viewport().set_input_as_handled()
	for i in 2:
		if _button(i).has_point(touch.position):
			_answer(i == 0)
			return


func _answer(yes: bool) -> void:
	visible = false
	_showing -= 1
	Sound.sfx("ui_ok" if yes else "ui_move", 0.0)
	answered.emit(yes)


func _panel() -> Rect2:
	return Rect2((size - PANEL) / 2.0, PANEL)


func _button(i: int) -> Rect2:
	var p := _panel()
	var gap := 16.0
	var x0 := p.position.x + (PANEL.x - BUTTON.x * 2.0 - gap) / 2.0
	return Rect2(Vector2(x0 + i * (BUTTON.x + gap), p.end.y - BUTTON.y - 14.0), BUTTON)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.07, 0.7))
	var p := _panel()
	draw_rect(p, Color(0.07, 0.06, 0.14, 0.97))
	draw_rect(p, GOLD, false, 2.0)
	draw_string(font, Vector2(p.position.x, p.position.y + 26.0), _title, HORIZONTAL_ALIGNMENT_CENTER, p.size.x, 12,
		GOLD)
	draw_multiline_string(font, Vector2(p.position.x + 14.0, p.position.y + 46.0), _message,
		HORIZONTAL_ALIGNMENT_CENTER, p.size.x - 28.0, 8, -1, Color(0.85, 0.85, 0.95))
	for i in 2:
		var r := _button(i)
		var sel := i == _index
		var fill := Color(0.75, 0.2, 0.24) if i == 0 else Color(0.16, 0.14, 0.3)
		draw_rect(r, fill.lightened(0.15) if sel else fill.darkened(0.25))
		draw_rect(r, GOLD if sel else Color(0.4, 0.38, 0.55), false, 2.0 if sel else 1.0)
		draw_string(font, Vector2(r.position.x, r.position.y + 17.0), _yes_text if i == 0 else _no_text,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, Color.WHITE)
