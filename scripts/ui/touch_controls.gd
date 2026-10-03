extends Node2D
## Bố trí điều khiển cảm ứng (kiểu game di động). Vị trí trong LAYOUT tính theo khung 480×270 rồi bám góc gần nhất của
## màn hình thật, tránh vùng bị che (tai thỏ, góc bo, thanh vuốt: Screen.safe_insets) và phóng to theo cỡ màn hình
## thật (Screen.unit_mm) để nút không quá nhỏ trên máy độ phân giải cao.
##   Góc trái:  pad di chuyển tròn cố định (TouchPad): chạm trong vòng pad, trượt ◀ ▶ đi, ▲ nhảy (giữ để ngắm
##              lên / W đổi nửa Body), ▼ cúi (bấm đúp trên bệ = xuống bệ). Nút Né ở góc dưới phải pad.
##   Góc phải:  nút ĐÁNH to ở góc. Vòng cung trong (sát nút Đánh): Skill 1, Skill 2, Final Attack / Biến thân
##              (docs/SKILLS.md: mờ khi thiếu nộ, vòng hồi chiêu, số nộ cần ở góc nút).
##              Vòng cung ngoài: Bắn (form có súng), Chém (form có kiếm), Kỹ năng (đổi form). Nút chưa dùng được
##              thì tự ẩn (TouchButton), chỗ của nó để trống, các nút không bao giờ đè nhau.
##   Góc trên trái, bên trái thanh máu: Menu (về màn chọn màn), dưới nó nút "?" mở bảng hướng dẫn (chỉ bản web,
##              HelpOverlay). Mỗi màn một Rider nên không có nút Đổi Rider.
## Gán `player` để các nút biết hồi chiêu và điều kiện dùng.

const ICON_DIR := "res://art/ui/icons/"

## Pad di chuyển cố định: tâm, bán kính (TouchPad chỉ nhận chạm trong vòng pad).
const PAD := Vector2(62, 200)
const PAD_R := 40.0

## Cụm nút tấn công kiểu MOBA (Liên Quân...): nút Đánh to ở góc phải, quanh nó hai vòng cung nút to cách đều, từ
## trái (180°) lên trên. Vòng trong bán kính 70, mỗi nút cách 45°: Skill 1 / Skill 2 / Final (hình là icon của skill,
## SkillIcons, không ghi chữ; tên skill hiện ở dải cut-in khi tung). Vòng ngoài bán kính 122, cách 35°: Bắn / Chém /
## Kỹ năng (đổi form). Né nằm bên trái, cạnh pad di chuyển. Toạ độ viết sẵn (GDScript không tính lượng giác trong const).
const ATTACK := Vector2(432, 222)
const ATTACK_R := 32.0
const SKILL_R := 22.0
const SMALL_R := 19.0
const ARC := [Vector2(-70, 0), Vector2(-50, -50), Vector2(0, -70)]                ## 180° · 225° · 270°
const OUTER := [Vector2(-120, -21), Vector2(-86, -86), Vector2(-21, -120)]       ## 190° · 225° · 260°
## Né: góc dưới phải của pad (ngoài vòng nhận chạm của pad, chữ "Né" không chạm mép dưới).
const DODGE := PAD + Vector2(54, 40)
const DODGE_R := 18.0

## Cỡ thật mong muốn của nút Đánh (đường kính, mm): máy có nút nhỏ hơn thì phóng cả cụm lên (tối đa MAX_SCALE).
const ATTACK_MM := 17.0
const MAX_SCALE := 1.5

## [action, biểu tượng, vị trí, bán kính, màu viền, phát sáng khi sẵn sàng, chữ dưới nút, action phụ]
## Chữ của "special", "ultimate", "skill_1", "skill_2" đổi theo form (Player.action_label), ở đây chỉ là mặc định.
const LAYOUT := [
	["attack_light", "fist", ATTACK, ATTACK_R, Color(1, 0.45, 0.4), false, "", ""],
	["skill_1", "skill1", ATTACK + ARC[0], SKILL_R, Color(0.55, 0.9, 1.0), false, "", ""],
	["skill_2", "skill2", ATTACK + ARC[1], SKILL_R, Color(0.75, 0.6, 1.0), false, "", ""],
	["final_attack", "ultimate", ATTACK + ARC[2], SKILL_R, Color(1, 0.85, 0.3), true, "", ""],
	["ultimate", "ultimate", ATTACK + ARC[2], SKILL_R, Color(1, 0.85, 0.3), true, "Biến thân", ""],
	["shoot", "shoot", ATTACK + OUTER[0], SMALL_R, Color(1, 0.85, 0.3), false, "Bắn", ""],
	["attack_slash", "slash", ATTACK + OUTER[1], SMALL_R, Color(1, 0.6, 0.45), false, "Chém", ""],
	["special", "skill", ATTACK + OUTER[2], SMALL_R, Color(1, 0.85, 0.3), false, "Kỹ năng", ""],
	["dodge", "dodge", DODGE, DODGE_R, Color(0.5, 0.85, 1.0), false, "Né", ""],
	["menu", "menu", Vector2(15, 14), 10.0, Color(0.85, 0.85, 0.95), false, "", ""],
	["help", "help", Vector2(15, 38), 9.0, Color(0.85, 0.85, 0.95), false, "", ""],
]

var player: Player:
	set(value):
		player = value
		for b in _buttons:
			b.player = value

var _buttons: Array[TouchButton] = []
var _pad: TouchPad


func _ready() -> void:
	_pad = TouchPad.new()
	add_child(_pad)
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
	visibility_changed.connect(func() -> void:
		if not visible:
			_pad.release())


## Hệ số phóng cụm nút theo cỡ thật của màn hình (máy tính: 1).
func _scale() -> float:
	var mm := Screen.unit_mm(self)
	if mm <= 0.0:
		return 1.0
	return clampf(ATTACK_MM / (ATTACK_R * 2.0 * mm), 1.0, MAX_SCALE)


## Menu / ? bám góc trên trái (giữ cỡ); cụm tấn công bám góc dưới phải, pad góc dưới trái: khoảng cách tới góc và
## bán kính nhân hệ số phóng. Góc = góc của vùng an toàn (bản thiết kế 480×270 đã chừa lề sẵn quanh nút).
func _layout() -> void:
	var view := Screen.view(self)
	var safe := Screen.safe_insets(self)
	var lo := safe.position                       # góc trên trái dùng được
	var hi := view - safe.size                    # góc dưới phải dùng được
	var k := _scale()
	var d := Screen.DESIGN
	for i in _buttons.size():
		var p: Vector2 = LAYOUT[i][2]
		if LAYOUT[i][0] in ["menu", "help"]:
			_buttons[i].position = lo + p
			continue
		if p.x < d.x / 2.0:
			_buttons[i].position = Vector2(lo.x, hi.y) + (p - Vector2(0, d.y)) * k   # nửa trái (Né): neo góc dưới trái
		else:
			_buttons[i].position = hi + (p - d) * k
		_buttons[i].radius = float(LAYOUT[i][3]) * k
	_pad.radius = PAD_R * k
	_pad.rest = Vector2(lo.x, hi.y) + (PAD - Vector2(0, d.y)) * k
	_pad.release()
