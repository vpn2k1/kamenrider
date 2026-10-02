extends Node2D
## Bố trí các nút ảo trên màn hình (vị trí LAYOUT theo khung 480×270; máy dài / vuông hơn 16:9 thì nút nửa phải
## dời theo mép phải, nút nửa dưới dời theo mép dưới của màn hình thật, xem Screen).
##   Góc trái:  D-pad ◀ ▶ ▲ ▼ (4 nút giống hệt nhau). ▲ = nhảy (giữ ▲ còn để ngắm lên khi có súng / W đổi nửa Body).
##              ▼ = cúi; bấm đúp ▼ trên bệ = xuống khỏi bệ.
##   Góc phải:  nút ĐÁNH to (đấm theo chuỗi rồi tự đá), Né.
##              Chỉ hiện khi dùng được: Bắn (form có súng), Chém (form có kiếm), Kỹ năng (đổi form),
##              Biến thân / Tuyệt chiêu.
##   Góc trên trái, bên trái thanh máu: Menu (về màn chọn màn), dưới nó nút "?" mở bảng hướng dẫn (chỉ bản web,
##              HelpOverlay). Mỗi màn một Rider nên không có nút Đổi Rider.
## Gán `player` để các nút biết hồi chiêu và điều kiện dùng.

const ICON_DIR := "res://art/ui/icons/"
const DPAD := Vector2(58, 220)
const DPAD_STEP := 33.0
const DPAD_R := 15.0
const DPAD_COLOR := Color(1, 1, 1, 0.85)

## [action, biểu tượng, vị trí, bán kính, màu viền, phát sáng khi sẵn sàng, chữ dưới nút, action phụ]
## Chữ của "special" và "ultimate" đổi theo form (Player.action_label), ở đây chỉ là mặc định.
const LAYOUT := [
	# D-pad: 4 nút cùng cỡ, cùng kiểu, xếp chữ thập đều nhau quanh tâm DPAD.
	["move_left", "left", DPAD + Vector2(-DPAD_STEP, 0), DPAD_R, DPAD_COLOR, false, "", ""],
	["move_right", "right", DPAD + Vector2(DPAD_STEP, 0), DPAD_R, DPAD_COLOR, false, "", ""],
	["jump", "up", DPAD + Vector2(0, -DPAD_STEP), DPAD_R, DPAD_COLOR, false, "", "move_up"],
	["move_down", "down", DPAD + Vector2(0, DPAD_STEP), DPAD_R, DPAD_COLOR, false, "", ""],
	["attack_light", "fist", Vector2(428, 226), 24.0, Color(1, 0.45, 0.4), false, "Đánh", ""],
	["dodge", "dodge", Vector2(366, 248), 12.0, Color(0.5, 0.85, 1.0), false, "Né", ""],
	["shoot", "shoot", Vector2(372, 198), 15.0, Color(1, 0.85, 0.3), false, "Bắn", ""],
	["attack_slash", "slash", Vector2(382, 156), 15.0, Color(1, 0.6, 0.45), false, "Chém", ""],
	["special", "skill", Vector2(430, 170), 15.0, Color(1, 0.85, 0.3), false, "Kỹ năng", ""],
	["menu", "menu", Vector2(15, 14), 10.0, Color(0.85, 0.85, 0.95), false, "", ""],
	["help", "help", Vector2(15, 38), 9.0, Color(0.85, 0.85, 0.95), false, "", ""],
	["ultimate", "ultimate", Vector2(430, 122), 17.0, Color(1, 0.85, 0.3), true, "Biến thân", ""],
]

var player: Player:
	set(value):
		player = value
		for b in _buttons:
			b.player = value

var _buttons: Array[TouchButton] = []


func _ready() -> void:
	for spec in LAYOUT:
		var b := TouchButton.new()
		b.action = spec[0]
		b.icon = load(ICON_DIR + spec[1] + ".png")
		b.position = spec[2]
		b.radius = spec[3]
		b.accent = spec[4]
		b.glow_when_ready = spec[5]
		b.label = spec[6]
		b.extra_action = spec[7]
		b.player = player
		add_child(b)
		_buttons.append(b)
	_layout()
	get_viewport().size_changed.connect(_layout)


## Nút bám mép gần nhất của màn hình thật.
func _layout() -> void:
	var e := Screen.extra(self)
	for i in _buttons.size():
		var p: Vector2 = LAYOUT[i][2]
		_buttons[i].position = p + Vector2(e.x if p.x > Screen.DESIGN.x / 2.0 else 0.0,
			e.y if p.y > Screen.DESIGN.y / 2.0 else 0.0)
