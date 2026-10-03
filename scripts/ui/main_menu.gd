extends Control
## Màn hình chính khi mở game: hai nút xếp dọc, bo tròn cạnh.
##   CHƠI    hành trình qua 27 thế giới (nhập tên → phần mở đầu nếu chưa xem → màn chơi, chọn thế giới / màn)
##   COMBAT  đấu cùng WiFi: 1 VS 1 hoặc ALL COMBAT 2–4 người (nhập tên → sảnh đấu scenes/versus/versus.tscn). Cần ít nhất một Rider đã kích hoạt
##           Driver ở hành trình; chưa có thì bấm vào chỉ hiện thông báo.
## Lần đầu (chưa đặt tên) cả hai qua màn nhập tên (NameEntry.mode cho biết đi tiếp vào đâu); đã đặt tên rồi (lưu trong
## cài đặt, GameState.name_set) thì vào thẳng. Nút "✎ Tên: …" dưới hai nút để đổi tên.
## Nền phủ kín màn hình máy (ảnh nền lặp theo bề ngang), hai nút luôn ở giữa màn hình.
## ▲ ▼ (hoặc W / S, ◀ ▶) chọn, Enter / Space / Đánh (J) / chạm để vào.
## Bản web: nút "?" góc trên phải mở bảng hướng dẫn nút bấm (HelpOverlay).
## Nút "⚙ Cài đặt" góc trên trái: âm lượng, bật / tắt từng nhóm âm thanh (SettingsMenu).

const NAME_SCENE := "res://scenes/ui/name_entry.tscn"
const BG_TEX := preload("res://art/backgrounds/tokyo.png")
const VIEW := Vector2(480, 270)
const CARD := Vector2(210, 46)
const RADIUS := 23                ## nửa chiều cao nút: hai đầu tròn hẳn
const GOLD := Color(1, 0.85, 0.3)

var _cards: Array[Button] = []
var _message: Label
var _help: HelpOverlay
var _settings: SettingsMenu


func _ready() -> void:
	Sound.music("map")
	# Ảnh nền thấp hơn màn hình: phần trời phía trên tô bằng màu điểm trên cùng của ảnh.
	var sky := ColorRect.new()
	sky.color = BG_TEX.get_image().get_pixel(0, 0)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Ảnh nền sát đáy, lặp theo bề ngang (máy 20:9 rộng hơn ảnh).
	var bg := TextureRect.new()
	bg.texture = BG_TEX
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bg.offset_top = -BG_TEX.get_height()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)
	box.add_child(_label("VPN CHRONO", 20, GOLD))
	box.add_child(_label("Kamen Rider fan game", 8, Color(0.75, 0.65, 1)))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	box.add_child(spacer)
	box.add_child(_card("CHƠI", "Hành trình qua 27 thế giới Rider", Color(0.62, 0.14, 0.18), NameEntry.Mode.PLAY))
	box.add_child(_card("COMBAT", "", Color(0.2, 0.22, 0.55), NameEntry.Mode.VERSUS))
	box.add_child(_label("▲ ▼ chọn · Enter / Đánh để vào", 7, Color(0.75, 0.75, 0.85)))
	if GameState.name_set:
		var rename := Button.new()
		rename.text = "✎ Tên: %s · đổi tên" % GameState.player_name
		rename.flat = true
		rename.focus_mode = Control.FOCUS_NONE
		rename.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rename.add_theme_font_size_override("font_size", 8)
		rename.add_theme_color_override("font_color", Color(0.75, 0.65, 1))
		rename.pressed.connect(_rename)
		box.add_child(rename)
	_message = _label("", 8, Color(1, 0.55, 0.45))
	_message.custom_minimum_size = Vector2(0, 12)
	box.add_child(_message)
	_cards[0 if NameEntry.mode == NameEntry.Mode.PLAY else 1].grab_focus()
	# Nút góc: Cài đặt âm thanh (trên trái), Hướng dẫn (trên phải, chỉ bản web)
	var settings_button := _corner_button("⚙ Cài đặt")
	settings_button.position = Vector2(8, 8)
	settings_button.pressed.connect(func() -> void: _settings.open())
	if HelpOverlay.enabled():
		var help_button := _corner_button("? Hướng dẫn")
		help_button.position = Vector2(VIEW.x - help_button.size.x - 8, 8)
		help_button.pressed.connect(func() -> void: _help.open())
		_help = HelpOverlay.new()
		add_child(_help)
	_settings = SettingsMenu.new()
	add_child(_settings)


## Nút nhỏ bo tròn ở góc màn hình.
func _corner_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 8)
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	for state in ["normal", "hover", "pressed"]:
		var sb := _pill(Color(0.12, 0.1, 0.22, 0.9 if state == "normal" else 1.0),
			GOLD if state != "normal" else Color(0.6, 0.55, 0.8), 1, 9)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		b.add_theme_stylebox_override(state, sb)
	add_child(b)
	b.size = b.get_combined_minimum_size()
	return b


func _process(_delta: float) -> void:
	if HelpOverlay.is_showing() or SettingsMenu.is_showing():
		return
	# W / S (A / D cũng được) và phím Đánh (J) dùng được như ở các màn chọn khác.
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_left"):
		_cards[0].grab_focus()
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_right"):
		_cards[1].grab_focus()
	elif Input.is_action_just_pressed("ui_cancel") and OS.has_feature("android"):
		get_tree().quit()   # nút back của Android ở màn hình chính: thoát app
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
	if desc != "":
		var d := _label(desc, 7, Color(0.92, 0.92, 0.98))
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(d)
	_cards.append(b)
	return b


## Nền nút bo tròn hai đầu. Tắt khử răng cưa để mép bo giữ nét pixel như phần còn lại của game.
func _pill(fill: Color, border: Color, width: int, radius := RADIUS) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 12
	sb.anti_aliasing = false
	return sb


func _choose(mode: NameEntry.Mode) -> void:
	if mode == NameEntry.Mode.VERSUS and GameState.selectable_riders().is_empty():
		_message.text = "Chưa có Rider nào! Vào CHƠI, nhặt Driver đầu tiên ở màn 1-1 để mở khoá Rider."
		return
	NameEntry.mode = mode
	NameEntry.renaming = false
	if GameState.name_set:
		NameEntry.proceed(get_tree())   # tên đã lưu trong cài đặt: không hỏi lại
	else:
		get_tree().change_scene_to_file(NAME_SCENE)


func _rename() -> void:
	NameEntry.renaming = true
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
