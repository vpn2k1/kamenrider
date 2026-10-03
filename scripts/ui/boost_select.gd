extends Control
class_name BoostSelect
## Chọn chỉ số tăng sức mạnh (nhặt vật phẩm "Tăng sức mạnh" khi chơi lại màn đã qua): 6 ô theo GameState.BOOST_STATS,
## mỗi ô ghi % đã cộng cho form đang dùng. Chọn một ô = +1% chỉ số đó cho riêng form này (RiderForm.add_bonus).
##   ◀ ▶ ▲ ▼ đổi ô · Đánh / Enter chọn. Chạm ô để chọn, chạm lần nữa (hoặc nút CỘNG) để xác nhận.
## Màn chơi dừng (get_tree().paused) trong lúc chọn; bảng này chạy PROCESS_MODE_ALWAYS.

signal chosen(stat: String)

const COLS := 3
const BOX := Vector2(118, 46)
const GAP := 10.0
const TOP := 78.0
const BUTTON := Rect2(185, 214, 110, 22)
const GOLD := Color(1, 0.85, 0.3)

var _form: RiderForm
var _stats: Array = []
var _index := 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open(form: RiderForm) -> void:
	_form = form
	_stats = GameState.BOOST_STATS.keys()
	_index = 0
	position = Vector2.ZERO
	size = get_viewport_rect().size
	visible = true
	queue_redraw()


## Chọn thẳng (bot test).
func pick(stat: String) -> void:
	_index = maxi(_stats.find(stat), 0)
	_confirm()


func _process(_delta: float) -> void:
	if not visible:
		return
	var i := _index
	if Input.is_action_just_pressed("move_left"):
		i -= 1
	elif Input.is_action_just_pressed("move_right"):
		i += 1
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump"):
		i -= COLS
	elif Input.is_action_just_pressed("move_down"):
		i += COLS
	elif Input.is_action_just_pressed("attack_light") or Input.is_action_just_pressed("ui_accept"):
		_confirm()
		return
	i = posmod(i, _stats.size())
	if i != _index:
		_index = i
		Sound.sfx("ui_move", 0.0)
		queue_redraw()


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if not visible or touch == null or not touch.pressed:
		return
	get_viewport().set_input_as_handled()
	if BUTTON.has_point(touch.position):
		_confirm()
		return
	for i in _stats.size():
		if _box(i).has_point(touch.position):
			if i == _index:
				_confirm()
			else:
				_index = i
				queue_redraw()
			return


func _confirm() -> void:
	var stat: String = _stats[_index]
	_form.add_bonus(stat)
	Sound.sfx("ui_ok", 0.0)
	visible = false
	chosen.emit(stat)


func _box(i: int) -> Rect2:
	var total := COLS * BOX.x + (COLS - 1) * GAP
	return Rect2((size.x - total) / 2.0 + (i % COLS) * (BOX.x + GAP), TOP + (i / COLS) * (BOX.y + GAP), BOX.x, BOX.y)


func _draw() -> void:
	if _form == null:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.07, 0.85))
	_text(Vector2(0, 30), "TĂNG SỨC MẠNH +%d%%" % int(GameState.BOOST_STEP * 100.0), 12, GOLD)
	var form_name := WorldData.form_name(_form.rider_id, _form.current_form_id())
	if form_name == "":
		form_name = "form gốc"
	_text(Vector2(0, 50), "Chọn một chỉ số cho %s · %s" % [_form.display_name, form_name], 8, Color(0.85, 0.85, 0.95))
	_text(Vector2(0, 62), "(chỉ cộng cho form đang dùng)", 7, Color(0.65, 0.65, 0.75))
	for i in _stats.size():
		var stat: String = _stats[i]
		var r := _box(i)
		var sel := i == _index
		draw_rect(r, Color(0.12, 0.1, 0.2) if sel else Color(0.07, 0.06, 0.12))
		draw_rect(r, GOLD if sel else Color(0.35, 0.33, 0.45), false, 2.0 if sel else 1.0)
		var have := GameState.bonus_value(_form.rider_id, _form.current_form_id(), stat) * 100.0
		_text(Vector2(r.position.x, r.position.y + 20), str(GameState.BOOST_STATS[stat]), 10,
			Color.WHITE if sel else Color(0.8, 0.8, 0.88), r.size.x)
		_text(Vector2(r.position.x, r.position.y + 36), "đã +%.2f%% → +%.2f%%" % [have, have + GameState.BOOST_STEP * 100.0], 7,
			GOLD if sel else Color(0.65, 0.65, 0.75), r.size.x)
	draw_rect(BUTTON, Color(0.85, 0.25, 0.25, 0.95))
	draw_string(font, Vector2(BUTTON.position.x, BUTTON.position.y + 15), "CỘNG", HORIZONTAL_ALIGNMENT_CENTER,
		BUTTON.size.x, 9, Color.WHITE)


func _text(pos: Vector2, text: String, font_size: int, color: Color, width := -1.0) -> void:
	var w := size.x if width < 0.0 else width
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, font_size, color)
