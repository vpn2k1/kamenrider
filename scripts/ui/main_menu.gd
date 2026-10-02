extends Control
## Màn hình chính khi mở game: hai nút xếp dọc, bo tròn cạnh.
##   CHƠI    hành trình qua 27 thế giới (nhập tên → phần mở đầu nếu chưa xem → màn chơi, chọn thế giới / màn)
##   COMBAT  đấu cùng WiFi: 1 VS 1 hoặc ALL COMBAT 2–4 người (nhập tên → sảnh đấu scenes/versus/versus.tscn). Cần ít nhất một Rider đã kích hoạt
##           Driver ở hành trình; chưa có thì bấm vào chỉ hiện thông báo.
## Cả hai đều qua màn nhập tên (NameEntry.mode cho biết đi tiếp vào đâu); tên đã đặt được điền sẵn.
## ▲ ▼ (hoặc W / S, ◀ ▶) chọn, Enter / Space / Đánh (J) / chạm để vào.

const NAME_SCENE := "res://scenes/ui/name_entry.tscn"
const BG_TEX := preload("res://art/backgrounds/tokyo.png")
const VIEW := Vector2(480, 270)
const CARD := Vector2(210, 46)
const RADIUS := 23                ## nửa chiều cao nút: hai đầu tròn hẳn
const GOLD := Color(1, 0.85, 0.3)

var _cards: Array[Button] = []
var _message: Label


func _ready() -> void:
	Sound.music("map")
	# Ảnh nền thấp hơn màn hình: phần trời phía trên tô bằng màu điểm trên cùng của ảnh.
	var sky := ColorRect.new()
	sky.size = VIEW
	sky.color = BG_TEX.get_image().get_pixel(0, 0)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	var bg := TextureRect.new()
	bg.texture = BG_TEX
	bg.position = Vector2((VIEW.x - BG_TEX.get_width()) / 2.0, VIEW.y - BG_TEX.get_height())
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var dim := ColorRect.new()
	dim.size = VIEW
	dim.color = Color(0.03, 0.02, 0.08, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.size = VIEW
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)
	box.add_child(_label("CHRONO HENSHIN", 20, GOLD))
	box.add_child(_label("Kamen Rider fan game", 8, Color(0.75, 0.65, 1)))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	box.add_child(spacer)
	box.add_child(_card("CHƠI", "Hành trình qua 27 thế giới Rider", Color(0.62, 0.14, 0.18), NameEntry.Mode.PLAY))
	var riders := GameState.selectable_riders().size()
	box.add_child(_card("COMBAT", "1 VS 1 · ALL COMBAT 2–4 người cùng WiFi · %s" % ("%d Rider đã mở khoá" % riders if riders > 0
		else "chưa mở: cần 1 Rider"), Color(0.2, 0.22, 0.55), NameEntry.Mode.VERSUS))
	box.add_child(_label("▲ ▼ chọn · Enter / Đánh để vào", 7, Color(0.75, 0.75, 0.85)))
	_message = _label("", 8, Color(1, 0.55, 0.45))
	_message.custom_minimum_size = Vector2(0, 12)
	box.add_child(_message)
	_cards[0 if NameEntry.mode == NameEntry.Mode.PLAY else 1].grab_focus()


func _process(_delta: float) -> void:
	# W / S (A / D cũng được) và phím Đánh (J) dùng được như ở các màn chọn khác.
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_left"):
		_cards[0].grab_focus()
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_right"):
		_cards[1].grab_focus()
	elif Input.is_action_just_pressed("attack_light"):
		for c in _cards:
			if c.has_focus():
				c.pressed.emit()


func _card(title: String, desc: String, accent: Color, mode: NameEntry.Mode) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_choose.bind(mode))
	b.add_theme_stylebox_override("normal", _pill(Color(accent, 0.9), accent.lightened(0.35), 1))
	b.add_theme_stylebox_override("hover", _pill(Color(accent.lightened(0.12), 0.95), accent.lightened(0.5), 1))
	b.add_theme_stylebox_override("pressed", _pill(Color(accent.darkened(0.3), 0.95), GOLD, 2))
	b.add_theme_stylebox_override("disabled", _pill(Color(0.2, 0.2, 0.25, 0.9), Color(0.4, 0.4, 0.5), 1))
	# Ô focus vẽ đè lên ô thường: chỉ viền vàng dày, nền trong suốt
	b.add_theme_stylebox_override("focus", _pill(Color.TRANSPARENT, GOLD, 2))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 1)
	col.size = CARD
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(col)
	var t := _label(title, 14, GOLD)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t)
	var d := _label(desc, 7, Color(0.92, 0.92, 0.98))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(d)
	_cards.append(b)
	return b


## Nền nút bo tròn hai đầu. Tắt khử răng cưa để mép bo giữ nét pixel như phần còn lại của game.
func _pill(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(RADIUS)
	sb.corner_detail = 12
	sb.anti_aliasing = false
	return sb


func _choose(mode: NameEntry.Mode) -> void:
	if mode == NameEntry.Mode.VERSUS and GameState.selectable_riders().is_empty():
		_message.text = "Chưa có Rider nào! Vào CHƠI, nhặt Driver đầu tiên ở màn 1-1 để mở khoá Rider."
		return
	NameEntry.mode = mode
	get_tree().change_scene_to_file(NAME_SCENE)


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l
