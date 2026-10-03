extends Node2D
class_name TouchPad
## Pad di chuyển tròn CỐ ĐỊNH ở góc trái dưới (kiểu game di động): chạm bắt đầu trong vòng pad (bán kính × START),
## trượt ngón để đổi hướng mà không cần nhấc tay (8 hướng). Pad không trôi theo ngón tay; kéo ra xa tâm quá
## bán kính × LIMIT thì pad nhả (không còn đi), kéo về lại trong vòng thì nhận tiếp.
##   ◀ / ▶   : move_left / move_right khi lệch ngang quá DEAD
##   ▲       : jump + move_up (nhảy; giữ để ngắm lên khi có súng, W đổi nửa Body) khi lệch lên quá UP
##   ▼       : move_down (cúi; bấm đúp trên bệ = xuống bệ) khi lệch xuống quá DOWN
## Vị trí và cỡ do TouchControls đặt (rest, radius) theo vùng an toàn và cỡ màn hình thật.

const DEAD := 0.32           ## tỉ lệ bán kính: lệch ngang ít hơn thì không đi
const UP := 0.55
const DOWN := 0.55
const KNOB := 0.42           ## bán kính núm / bán kính pad
const START := 1.3           ## chạm cách tâm trong chừng này × bán kính mới bắt đầu điều khiển pad
const LIMIT := 2.2           ## ngón kéo xa tâm quá chừng này × bán kính thì thôi điều khiển (nhả hướng)

var radius := 40.0
var rest := Vector2(70, 200)         ## tâm pad lúc không chạm

var _touch := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _held := {}              ## action -> true đang giữ


func _ready() -> void:
	_center = rest
	add_to_group(TouchButton.GROUP)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch == -1 and t.position.distance_to(rest) <= radius * START:
			_touch = t.index
			_center = rest
			_move(t.position)
			get_viewport().set_input_as_handled()
		elif not t.pressed and t.index == _touch:
			release()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch:
			_move(d.position)
			get_viewport().set_input_as_handled()


## Nhả pad (TouchButton.release_all gọi khi dừng màn).
func release() -> void:
	_touch = -1
	_center = rest
	_knob = Vector2.ZERO
	_apply({})
	queue_redraw()


func _move(p: Vector2) -> void:
	var v := p - _center
	if v.length() > radius * LIMIT:
		# Ngón đã trượt ra xa pad: không điều khiển nữa (tránh nhân vật chạy khi ngón đang ở chỗ khác trên màn hình).
		_knob = Vector2.ZERO
		_apply({})
		queue_redraw()
		return
	_knob = v.limit_length(radius)
	var n := _knob / radius
	var want := {}
	if n.x < -DEAD:
		want["move_left"] = true
	elif n.x > DEAD:
		want["move_right"] = true
	if n.y < -UP:
		want["jump"] = true
		want["move_up"] = true
	elif n.y > DOWN:
		want["move_down"] = true
	_apply(want)
	queue_redraw()


func _apply(want: Dictionary) -> void:
	for a in _held.keys():
		if not want.has(a):
			Input.action_release(a)
	for a in want:
		if not _held.has(a):
			Input.action_press(a)
	_held = want


func _exit_tree() -> void:
	_apply({})


func _process(_d: float) -> void:
	if _touch == -1 and _center != rest:
		_center = rest
		queue_redraw()


func _draw() -> void:
	var c := _center - position
	var active := _touch != -1
	draw_circle(c, radius, Color(0, 0, 0, 0.28 if active else 0.18))
	draw_arc(c, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.75 if active else 0.5), 2.0)
	# 4 mũi tên gợi ý hướng, sáng lên khi đang giữ hướng đó
	var dirs := {"move_left": Vector2.LEFT, "move_right": Vector2.RIGHT, "jump": Vector2.UP, "move_down": Vector2.DOWN}
	for a in dirs:
		var dv: Vector2 = dirs[a]
		var on := _held.has(a)
		var tip := c + dv * radius * 0.82
		var side := dv.orthogonal() * radius * 0.13
		var base := tip - dv * radius * 0.2
		draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]),
			Color(1, 0.85, 0.3, 0.95) if on else Color(1, 1, 1, 0.6))
	var k := c + _knob
	draw_circle(k, radius * KNOB, Color(1, 1, 1, 0.55 if active else 0.35))
	draw_arc(k, radius * KNOB, 0.0, TAU, 32, Color(1, 1, 1, 0.9), 1.5)
