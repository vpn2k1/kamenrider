extends Control
class_name RiderSelect
## Màn chọn Rider chính, hiện trước mỗi màn khi đã có từ 2 Rider trở lên.
##   ◀ ▶ hoặc chạm vào thẻ để chọn · Đánh / Enter, chạm thẻ đang chọn lần nữa hoặc chạm "VÀO MÀN" để vào.
## Mỗi thẻ: tên, cấp, mô tả lối chơi, 5 thanh chỉ số của form gốc (Máu · Giáp · Tốc độ · Sức đánh · Nhảy),
## số form đã có, sức mạnh thế hệ (Rider thế giới sau mạnh hơn: RiderForm.power), và dấu "★ Rider thế giới"
## (form của màn chỉ rơi cho Rider này). Có tới 27 Rider: hiện 3 thẻ một lúc, ◀ ▶ cuộn, dòng "3 / 27" ở trên.
## Vẽ bằng _draw như HUD để giữ nét pixel.

signal chosen(id: StringName)

const STAT_MAX := {"hp": 220.0, "armor": 60.0, "speed": 180.0, "atk": 1.6, "jump": 1.4}
const STAT_ROWS := [["hp", "Máu"], ["armor", "Giáp"], ["speed", "Tốc độ"], ["atk", "Sức đánh"], ["jump", "Nhảy"]]
const CARD := Vector2(134, 150)
const GAP := 10.0
const TOP := 42.0
const MAX_CARDS := 3
const BUTTON := Rect2(185, 214, 110, 20)
const FONT_SIZE := 8

var _info: Array = []          ## mỗi Rider: {id, name, level, tagline, stats, forms, world, color}
var _index := 0
var _title := ""
var _subtitle := ""


## options: các Rider chọn được; current: Rider chính lần trước (chọn sẵn); colors: màu theo rider_id.
func open(options: Array[StringName], title: String, subtitle: String, current: StringName, colors: Dictionary) -> void:
	_title = title
	_subtitle = subtitle
	_info.clear()
	var world_rider := GameState.world_rider()
	for id in options:
		var form := GameState.create_form(id)
		if form == null:
			continue
		var forms: Array = GameState.drivers[String(id)].get("forms", [])
		_info.append({
			"id": id, "name": form.display_name.replace("Kamen Rider ", "").to_upper(), "level": form.level,
			"tagline": form.tagline, "stats": form.stat_summary(), "forms": 1 + forms.size(),
			"world": id == world_rider, "color": colors.get(id, Color.WHITE), "power": form.power,
		})
		form.free()
	_index = 0
	for i in _info.size():
		if _info[i]["id"] == current:
			_index = i
	position = Vector2.ZERO
	size = get_viewport_rect().size
	visible = true
	queue_redraw()


## Chọn thẳng một Rider (dùng cho bot test).
func pick(id: StringName) -> void:
	for i in _info.size():
		if _info[i]["id"] == id:
			_index = i
			_confirm()
			return


func _process(_delta: float) -> void:
	if not visible or _info.is_empty():
		return
	if Input.is_action_just_pressed("move_left"):
		_index = (_index - 1 + _info.size()) % _info.size()
	elif Input.is_action_just_pressed("move_right"):
		_index = (_index + 1) % _info.size()
	elif Input.is_action_just_pressed("attack_light") or Input.is_action_just_pressed("ui_accept"):
		_confirm()
		return
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Chạm (chuột cũng được giả lập thành chạm trong project.godot).
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	if BUTTON.has_point(touch.position):
		get_viewport().set_input_as_handled()
		_confirm()
		return
	var rects := _card_rects()
	for i in rects.size():
		if (rects[i]["rect"] as Rect2).has_point(touch.position):
			get_viewport().set_input_as_handled()
			if rects[i]["index"] == _index:
				_confirm()
			else:
				_index = rects[i]["index"]
				queue_redraw()
			return


func _confirm() -> void:
	if _info.is_empty():
		return
	visible = false
	chosen.emit(_info[_index]["id"])


## Các thẻ đang hiện (tối đa MAX_CARDS, cuộn theo Rider đang chọn), căn giữa màn hình.
func _card_rects() -> Array:
	var n := mini(_info.size(), MAX_CARDS)
	var first := clampi(_index - n / 2, 0, _info.size() - n)
	var total := n * CARD.x + (n - 1) * GAP
	var x0 := (size.x - total) / 2.0
	var out: Array = []
	for k in n:
		out.append({"index": first + k, "rect": Rect2(x0 + k * (CARD.x + GAP), TOP, CARD.x, CARD.y)})
	return out


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.07, 0.82))
	_text(Vector2(0, 16), _title, 10, Color(1, 0.9, 0.5), size.x)
	_text(Vector2(0, 30), _subtitle, FONT_SIZE, Color(0.85, 0.85, 0.95), size.x)
	if _info.size() > MAX_CARDS:
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 60.0, 16), "%d / %d" % [_index + 1, _info.size()],
			HORIZONTAL_ALIGNMENT_RIGHT, 50.0, 8, Color(1, 0.9, 0.5))

	for c in _card_rects():
		var info: Dictionary = _info[c["index"]]
		var r: Rect2 = c["rect"]
		var selected: bool = c["index"] == _index
		var col: Color = info["color"]
		draw_rect(r, Color(0.08, 0.07, 0.14, 0.95) if selected else Color(0.06, 0.05, 0.1, 0.8))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 16)), col.darkened(0.2) if selected else col.darkened(0.55))
		draw_string(font, r.position + Vector2(6, 12), "%s  Lv%d" % [info["name"], info["level"]],
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 8, 9, Color.WHITE)
		draw_string(font, r.position + Vector2(6, 28), info["tagline"], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10,
			7, Color(0.85, 0.85, 0.9) if selected else Color(0.6, 0.6, 0.68))
		var stats: Dictionary = info["stats"]
		for i in STAT_ROWS.size():
			var key: String = STAT_ROWS[i][0]
			var y := r.position.y + 42.0 + i * 16.0
			draw_string(font, Vector2(r.position.x + 6, y + 6), STAT_ROWS[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
				Color(0.9, 0.9, 0.95))
			var bx := r.position.x + 50.0
			var bw := r.size.x - 58.0
			var ratio := clampf(float(stats[key]) / float(STAT_MAX[key]), 0.0, 1.0)
			draw_rect(Rect2(bx, y, bw, 6), Color(0.18, 0.17, 0.24))
			draw_rect(Rect2(bx, y, bw * ratio, 6), col if selected else col.darkened(0.35))
			draw_rect(Rect2(bx, y, bw * ratio, 1), col.lightened(0.4))
		var foot := "Form: %d · Sức mạnh ×%.2f" % [info["forms"], info["power"]]
		draw_string(font, r.position + Vector2(6, r.size.y - 16), foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.9, 0.9, 0.95))
		if info["world"]:
			draw_string(font, r.position + Vector2(6, r.size.y - 5), "★ Rider thế giới: form rơi cho Rider này",
				HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 8, 6, Color(1, 0.85, 0.3))
		var border := Color(1, 0.85, 0.3) if selected else Color(0.35, 0.33, 0.45)
		draw_rect(r, border, false, 2.0 if selected else 1.0)

	# Đội hình sẽ mang vào màn và nút vào màn.
	var main_name: String = _info[_index]["name"]
	var team := "Đội hình trong màn: %s" % main_name
	for info in _info:
		if info["world"] and info["id"] != _info[_index]["id"]:
			team += "  ⇄  %s (nút Đổi Rider)" % info["name"]
	_text(Vector2(0, 205), team, FONT_SIZE, Color(0.9, 0.95, 1.0), size.x)
	draw_rect(BUTTON, Color(0.9, 0.25, 0.25, 0.9))
	draw_rect(BUTTON, Color(1, 0.85, 0.3), false, 1.5)
	_text(Vector2(BUTTON.position.x, BUTTON.position.y + 14), "VÀO MÀN", 9, Color.WHITE, BUTTON.size.x)
	_text(Vector2(0, 248), "◀ ▶ chọn · Đánh / Enter: vào màn", 7, Color(0.75, 0.75, 0.85), size.x)


func _text(pos: Vector2, text: String, font_size: int, color: Color, width: float) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 3, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
