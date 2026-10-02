extends RefCounted
## Thế giới 4 · Kamen Rider Faiz (2003) — "Giấc mơ"
## Rider có script riêng: scripts/riders/faiz.gd (RIDER để trống).

const WORLD := {
	"id": "faiz",
	"year": 2003,
	"name": "Thế giới Faiz",
	"motto": "Giấc mơ",
	"rider": &"faiz",
	"rider_name": "Faiz",
	"driver_name": "Faiz Driver",
	"color": Color(0.95, 0.8, 0.2),
	"enemies": {
		"basic": {"name": "Orphnoch", "color": Color(0.8, 0.8, 0.85), "sprite": "orphnoch_wolf"},
		"fast": {"name": "Orphnoch tốc độ", "color": Color(0.6, 0.35, 0.85), "sprite": "orphnoch_fast"},
		"armored": {"name": "Orphnoch giáp", "color": Color(0.45, 0.45, 0.5), "sprite": "orphnoch_armored"},
	},
	"unlocks": [
		"Faiz (form gốc, bắn bằng Faiz Phone)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"sát thương +40%, máu +32%",
	],
	"stages": [
		{"name": "Tiệm giặt ủi Kikuchi", "goal": "Bảo vệ Takumi, giành lại Faiz Phone từ tay Orphnoch",
			"bg": "laundry", "waves": [["basic", "basic", "basic"], ["basic", "armored", "basic"]]},
		{"name": "Đường cao tốc", "form": &"axel", "form_name": "Axel Form", "bg": "highway", "route": ["left"],
			"waves": [["basic", "basic", "basic"], ["basic", "armored", "basic"]]},
		{"name": "Sảnh Smart Brain", "bg": "smart_brain", "route": ["right", "up", "right"],
			"waves": [["basic", "basic", "basic"], ["basic", "basic", "fast"]]},
		{"name": "Phòng thí nghiệm", "form": &"blaster", "form_name": "Blaster Form", "bg": "lab",
			"route": ["left", "down", "right"], "waves": [["basic", "fast", "basic"], ["fast", "basic", "fast"]]},
		{"name": "Trùm: Dragon Orphnoch", "bg": "boss_faiz", "route": ["left"],
			"boss": {"name": "Dragon Orphnoch", "hp": 220.0, "damage": 14.0, "poise": 20.0, "speed": 85.0,
				"traits": ["fast"], "color": Color(0.85, 0.3, 0.3)},
			"waves": [["basic", "fast"], ["boss"]]},
	],
}

const RIDER := {}

## Giọng đai / tiếng hô (tools/gen_audio.py → audio/voice/<rider>_<khóa>.wav): "henshin" lúc biến thân, khóa = id form
## lúc đổi sang form đó, "final" lúc Final Attack. Mỗi dòng: [kiểu giọng, câu]
## (kiểu giọng: belt / belt_deep / belt_bright / kivat / hero, xem VOICES trong gen_audio.py).
const VOICE := {
	"henshin": ["belt_deep", "Standing by. Complete."],
	"axel": ["belt_deep", "Complete. Start up."],
	"blaster": ["belt_deep", "Awakening."],
	"final": ["belt_deep", "Exceed Charge."],
}

const SPEAKERS := {
	"takumi": {"name": "TAKUMI", "color": Color(0.95, 0.8, 0.2), "portrait": "takumi",
		"look": "hair=5f3e28 jacket=1c1c22 stripe=aaaab4 eyes=463228"},
	"dragon_orphnoch": {"name": "DRAGON ORPHNOCH", "color": Color(0.9, 0.35, 0.3), "portrait": "dragon_orphnoch",
		"look": "base=orphnoch tint=c8463c"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Faiz · Tiệm giặt ủi Kikuchi."],
			["pen", "Lạ thật, Faiz Driver vẫn không phản ứng... Nó thiếu Faiz Phone, thiết bị nhập mã biến thân!"],
			["takumi", "Lũ Orphnoch cướp mất rồi. Tôi là Inui Takumi. Đừng hỏi nhiều, đi theo tôi."],
			["pen", "Cậu vẫn còn các Rider cũ. Hạ Orphnoch cho tới khi Faiz Phone rơi ra!"],
		],
		"goal": [
			["takumi", "Bọn đó đang giữ cái điện thoại. Đánh đi!"],
		],
		"key": [
			["takumi", "Tôi không có ước mơ. Nhưng tôi có thể bảo vệ ước mơ của người khác."],
			["hero", "Tôi thì có. Tôi muốn tìm lại anh trai mình."],
			["takumi", "Vậy thì đừng có chết trước khi tìm được. Mã là 5-5-5."],
			["narrator", "5... 5... 5... ENTER. Tinh thể tím vỡ tan. Sức mạnh của Faiz Driver đã trở về!"],
		],
		"clear": [
			["pen", "Faiz bắn bằng Faiz Phone: giữ nút Bắn. Crimson Smash phóng mũi Pointer ghim quái lại rồi mới đá. Giáp mỏng đấy."],
			["takumi", "Đừng xài phí."],
		],
	},
	"2": {
		"start": [
			["takumi", "Orphnoch tốc độ đang bám theo trên đường cao tốc. Thứ đó nhanh hơn mắt cậu."],
			["pen", "Trong đám đó có sức mạnh Axel Form. Nhưng nộ đầy cũng chỉ đủ cho mười giây thôi!"],
		],
		"key": [
			["takumi", "Start Up. Mười giây. Đừng phí giây nào."],
		],
		"clear": [
			["takumi", "Không tệ. ...Đừng có cười, tôi không khen đâu."],
		],
	},
	"3": {
		"start": [
			["pen", "Sảnh Smart Brain. Không có form mới ở đây, nhưng quái tốc độ rất đông."],
			["takumi", "Tích nộ ở form gốc. Đợi chúng ùa ra rồi hẵng bật Axel."],
		],
		"clear": [
			["pen", "{name}... nếu một ngày cậu biết một chuyện tôi giấu cậu, cậu có giận không?"],
			["hero", "Chuyện gì cơ?"],
			["pen", "...Không có gì. Đi tiếp thôi."],
		],
	},
	"4": {
		"start": [
			["takumi", "Phòng thí nghiệm của Smart Brain. Sức mạnh Faiz Blaster bị giấu ở đây."],
		],
		"key": [
			["takumi", "Blaster Form. Nặng, chậm, nhưng Faiz Blaster bắn đạn xuyên. Giữ nút Bắn."],
		],
		"clear": [
			["takumi", "Dragon Orphnoch ở phía trước. Hắn đổi dạng liên tục. Lúc hắn hóa Long nhân thì bật Axel."],
		],
	},
	"B": {
		"goal": [
			["dragon_orphnoch", "Con người... Các ngươi không nên tồn tại."],
			["pen", "Hắn có hai dạng! Pháp sư bắn từ xa, Long nhân siêu tốc. Để dành nộ!"],
		],
		"clear": [
			["narrator", "Trong lõi tro của Dragon Orphnoch là một chiếc Blay Buckle bị phong ấn, Driver của Blade."],
			["narrator", "Trên nóc tòa nhà phía xa, một bóng áo choàng đứng nhìn."],
			["void", "Đi nhanh hơn ta tưởng đấy... {name}."],
			["narrator", "{name} không nghe thấy. Pen thì nghe thấy, và im lặng."],
			["takumi", "Đi đi. Tìm anh trai cậu. ...Và đừng có chết đấy."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Faiz sáng rồi. Bốn thế giới! Chặng tiếp theo: Trái Đất Blade."],
]
