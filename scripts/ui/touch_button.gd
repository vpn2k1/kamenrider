extends Node2D
class_name TouchButton
## Một nút ảo trên màn hình. Chạm (hoặc bấm chuột, nhờ emulate_touch_from_mouse) = giữ action
## trong InputMap, thả = nhả, nên Player xử lý y như khi bấm phím.
##
## Vẽ bằng _draw: nền tròn, biểu tượng pixel, chữ ngắn bên dưới, vòng hồi chiêu (quạt tối + số giây),
## mờ đi khi chưa dùng được (thiếu nộ...), viền sáng nhấp nháy khi là tuyệt chiêu sẵn sàng.
## Nút tự ẩn khi Player.is_action_visible() = false (kỹ năng chưa mở khóa).

@export var action := "attack_light"
@export var icon: Texture2D
@export var radius := 18.0
@export var accent := Color(1, 1, 1, 0.9)
@export var glow_when_ready := false
@export var label := ""
## Action phụ nhấn cùng lúc (▲: nhảy + giữ ↑ để ngắm lên / W đổi nửa Body).
@export var extra_action := ""

var player: Player

var _touch_index := -1
var _pressed := false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1 and _hit(touch.position):
			_touch_index = touch.index
			_set_pressed(true)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_set_pressed(false)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		# Kéo ngón tay ra khỏi nút thì nhả nút.
		if drag.index == _touch_index and not _hit(drag.position, 1.8):
			_touch_index = -1
			_set_pressed(false)


func _hit(pos: Vector2, margin := 1.25) -> bool:
	return (pos - global_position).length() <= radius * margin


func _set_pressed(on: bool) -> void:
	_pressed = on
	for a in [action, extra_action]:
		if a == "":
			continue
		if on:
			Input.action_press(a)
		else:
			Input.action_release(a)


func _exit_tree() -> void:
	if _pressed:
		_set_pressed(false)


func _process(_delta: float) -> void:
	var should_show := player == null or player.is_action_visible(action)
	if not should_show and _pressed:
		_touch_index = -1
		_set_pressed(false)
	visible = should_show
	queue_redraw()


func _draw() -> void:
	var usable := player == null or player.is_action_available(action)
	var cd := player.cooldown_of(action) if player else Vector2.ZERO
	var cooling := cd.x > 0.0 and cd.y > 0.0
	var r := radius * (0.92 if _pressed else 1.0)

	draw_circle(Vector2.ZERO, r, Color(0.05, 0.04, 0.1, 0.55 if not _pressed else 0.75))
	var ring := accent if usable and not cooling else Color(0.5, 0.5, 0.55, 0.6)
	var glowing := glow_when_ready and usable and not cooling
	if glowing:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 120.0)
		draw_circle(Vector2.ZERO, r + 2.0 + pulse * 2.0, Color(1.0, 0.8, 0.25, 0.25 + 0.25 * pulse))
		ring = Color(1.0, 0.85, 0.3)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, ring, 1.5)

	if icon:
		var s := icon.get_size() * (2.0 if radius >= 16.0 else 1.5)
		var tint := Color(1, 1, 1) if usable and not cooling else Color(0.55, 0.55, 0.6, 0.8)
		draw_texture_rect(icon, Rect2(-s / 2.0, s), false, tint)

	var text := label
	if player:
		var dynamic := player.action_label(action)
		if dynamic != "":
			text = dynamic
	if text != "":
		var font := ThemeDB.fallback_font
		var col := Color(1, 1, 1, 0.95) if usable and not cooling else Color(0.7, 0.7, 0.75, 0.8)
		draw_string_outline(font, Vector2(-40, radius + 9), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 8, 3, Color.BLACK)
		draw_string(font, Vector2(-40, radius + 9), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 8, col)

	if cooling:
		# Quạt tối phủ phần thời gian còn lại, quét theo chiều kim đồng hồ từ đỉnh.
		var frac := clampf(cd.x / cd.y, 0.0, 1.0)
		var pts := PackedVector2Array([Vector2.ZERO])
		var steps := 24
		for i in steps + 1:
			var a := -PI / 2.0 + TAU * frac * float(i) / steps
			pts.append(Vector2(cos(a), sin(a)) * r)
		if pts.size() >= 3:
			draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
		if cd.x >= 1.0:
			var font := ThemeDB.fallback_font
			var secs := str(ceili(cd.x))
			draw_string_outline(font, Vector2(-r, 4), secs, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 10, 3, Color.BLACK)
			draw_string(font, Vector2(-r, 4), secs, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 10, Color.WHITE)
