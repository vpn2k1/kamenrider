extends RefCounted
## Thế giới 7 · Kamen Rider Kabuto (2006) — "Con đường của thiên đạo"
## Echo Rider: Tendou Souji (tự tin tuyệt đối, "Bà tôi từng nói..."). Hỗ trợ: Kagami Arata (lính ZECT, sau là Gatack).
## Quái: Worm đội lốt người; Worm đã lột xác thì Clock Up. Trùm: Dark Kabuto, Worm sao chép Tendou.
## Mạch truyện: Void vẫn bước đi trong lúc Clock Up; Pen nói lộ rằng hắn "đứng ngoài dòng thời gian".

const WORLD := {
	"id": "kabuto",
	"year": 2006,
	"name": "Thế giới Kabuto",
	"motto": "Con đường của thiên đạo",
	"rider": &"kabuto",
	"rider_name": "Kabuto",
	"driver_name": "Kabuto Zecter",
	"color": Color(1.0, 0.22, 0.25),
	"enemies": {
		"basic": {"name": "Salis Worm", "color": Color(0.45, 0.72, 0.32), "sprite": "salis_worm"},
		"fast": {"name": "Musca Worm", "color": Color(0.55, 0.4, 0.8), "sprite": "musca_worm"},
		"armored": {"name": "Cochlea Worm", "color": Color(0.62, 0.55, 0.4), "sprite": "cochlea_worm"},
	},
	"unlocks": [
		"Rider Form (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Perfect Zecter: Final Attack x1.5",
	],
	"stages": [
		{"name": "Phố trước Bistro la Salle", "goal": "Hạ Worm đội lốt người, để Kabuto Zecter công nhận cậu",
			"bg": "kabuto_1", "bg_theme": "city_day"},
		{"name": "Trụ sở ZECT", "bg": "kabuto_2", "bg_theme": "lab"},
		{"name": "Shibuya, nơi thiên thạch rơi", "bg": "kabuto_3", "bg_theme": "city_night"},
		{"name": "Xa lộ ven vịnh", "form": &"hyper", "form_name": "Hyper Form",
			"bg": "kabuto_4", "bg_theme": "race_city"},
		{"name": "Trùm: Dark Kabuto", "bg": "kabuto_b", "bg_theme": "boss_dark",
			"boss": {"name": "Dark Kabuto", "hp": 230.0, "damage": 16.0, "poise": 22.0, "speed": 88.0,
				"traits": ["fast"], "color": Color(0.25, 0.25, 0.32)}},
	],
}

## Kabuto chỉ có 2 form: Rider Form nhanh gọn, và Hyper Form (Hyper Zecter, màn 4) với Hyper Clock Up: tăng tốc
## thời gian (quái chậm lại, đánh trúng Worm đã lột xác), nộ cạn thì về Rider Form. Màn 2, 3 không rơi form.
const RIDER := {
	"name": "Kamen Rider Kabuto",
	"tagline": "Thiên đạo · Hyper Form, Hyper Clock Up",
	"base": &"rider",
	"order": [&"rider", &"hyper"],
	"forms": {
		&"rider": {"name": "Rider Form", "style": "brawler", "hp": 155.0, "armor": 22.0, "speed": 138.0,
			"jump": 1.1, "atk": 1.05, "poise": 7.0, "final": "Rider Kick",
			"fx": {"hit": "spark", "final": "tachyon", "color": Color(1.0, 0.35, 0.35)}},
		&"hyper": {"name": "Hyper Form", "style": "brawler", "hp": 175.0, "armor": 30.0, "speed": 160.0,
			"jump": 1.25, "atk": 1.3, "poise": 12.0, "final": "Hyper Kick",
			"fx": {"hit": "spark", "final": "tachyon", "trail": true, "color": Color(0.85, 0.9, 1.0)},
			"time_call": "HYPER CLOCK UP", "effect": "time"},
	},
	"lv5": {"name": "Perfect Zecter", "final_mult": 1.5},
	"final_fx": {"intro": "tachyon"},
}

## Giọng đai / tiếng hô (tools/gen_audio.py → audio/voice/<rider>_<khóa>.wav): "henshin" lúc biến thân, khóa = id form
## lúc đổi sang form đó, "final" lúc Final Attack. Mỗi dòng: [kiểu giọng, câu]
## (kiểu giọng: belt / belt_deep / belt_bright / kivat / hero, xem VOICES trong gen_audio.py).
const VOICE := {
	"henshin": ["belt", "Henshin. Change, Beetle."],
	"hyper": ["belt", "Hyper Cast Off. Change, Hyper Beetle. Hyper Clock Up."],
	"final": ["belt", "One. Two. Three. Rider Kick."],
}

const SPEAKERS := {
	"tendou": {"name": "TENDOU SOUJI", "color": Color(1.0, 0.35, 0.35), "portrait": "tendou",
		"look": "hair=1e1a18 jacket=3a3a44 stripe=b8b8c8 eyes=2a2222"},
	"arata": {"name": "KAGAMI ARATA", "color": Color(0.4, 0.6, 1.0), "portrait": "arata",
		"look": "hair=2a1e16 jacket=2a4a8a stripe=d8d8e0 eyes=3a2a20"},
	"dark_kabuto": {"name": "DARK KABUTO", "color": Color(0.85, 0.8, 0.35), "portrait": "dark_kabuto",
		"look": "base=kuuga tint=3a3a48"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Kabuto · Con phố trước nhà hàng Bistro la Salle."],
			["tendou", "(chỉ tay lên trời) Tôi là Tendou Souji. Người bước trên con đường của thiên đạo, nắm giữ tất cả."],
			["pen", "Kabuto Zecter bị phong ấn. Zecter tự bay đến người mà nó công nhận. Hạ lũ Worm đội lốt người ngay trước mặt nó đi!"],
		],
		"goal": [
			["tendou", "Con Worm kia đang giữ Zecter. Thiên đạo chỉ có một hướng: tiến lên."],
		],
		"key": [
			["narrator", "Tinh thể tím vỡ tung. Kabuto Zecter vút qua không trung như một con bọ cánh cứng, đáp gọn vào tay {name}."],
			["hero", "Henshin!"],
		],
		"clear": [
			["tendou", "Bà tôi từng nói: đã đi con đường của mình thì đừng ngoái lại."],
			["pen", "Rider Form: nhanh, gọn, đấm đá cân bằng. Còn Hyper Zecter thì đang nằm trong tay lũ Worm."],
		],
	},
	"2": {
		"start": [
			["arata", "Kagami Arata, lính ZECT! Trụ sở bị Worm chiếm rồi. Tôi sẽ không để ai phải chết nữa!"],
		],
		"clear": [
			["arata", "Cậu với Tendou... sao ai cũng tự tin dữ vậy chứ."],
			["tendou", "Vì chúng tôi đúng."],
		],
	},
	"3": {
		"start": [
			["arata", "Shibuya, nơi thiên thạch rơi bảy năm trước. Worm lẫn trong đám đông, đừng để chúng vây quanh."],
		],
		"clear": [
			["tendou", "Bà tôi từng nói: em gái là báu vật của cả thế giới. Tôi có một đứa, nên tôi không được thua."],
			["hero", "Tôi thì có một người anh. Mất tích mười năm rồi."],
			["tendou", "Vậy thì anh ta vẫn đang bảo vệ cậu, theo cách nào đó. Anh trai là vậy."],
		],
	},
	"4": {
		"start": [
			["arata", "Musca Worm đã lột xác. Chúng Clock Up, nhanh tới mức mắt thường không theo kịp. Đòn thường sẽ trượt hết!"],
		],
		"key": [
			["narrator", "Hyper Zecter vút xuống tay {name}. Hyper Cast Off! Bộ giáp đỏ dày lên, chiếc sừng vươn cao: Hyper Form."],
			["tendou", "Hyper Clock Up. Mọi thứ quanh cậu chậm lại, đòn của cậu trúng cả Worm đã lột xác. Nộ cạn thì về Rider Form, đừng phí."],
		],
		"clear": [
			["narrator", "Trong Clock Up, cả thế giới đứng yên. Vậy mà ở cuối xa lộ, một bóng áo choàng vẫn thong thả bước đi."],
			["void", "Nhanh hơn rồi đấy. Nhưng chưa đủ."],
			["pen", "Hắn không cần Clock Up. Hắn đứng ngoài dòng thời gian... lâu lắm rồi."],
			["hero", "Pen, sao cô biết?"],
			["tendou", "Bà tôi từng nói: kẻ nói nhiều nhất thường là kẻ giấu chuyện giỏi nhất."],
		],
	},
	"B": {
		"start": [
			["pen", "Năng lượng Void nằm trong bộ giáp đen kia. Nó... giống hệt Kabuto!"],
		],
		"goal": [
			["dark_kabuto", "Ta là Tendou Souji. Con đường thiên đạo chỉ cần một người bước đi."],
			["tendou", "Một con Worm đã sao chép tôi. Đồ giả thì mãi là đồ giả. Cho hắn thấy đi, {name}."],
		],
		"clear": [
			["narrator", "Dark Kabuto vỡ thành từng mảnh giáp đen. Giữa đó là một chiếc đai bốn nút màu bọc tinh thể tím: Den-O Belt."],
			["narrator", "Sức mạnh Kabuto trở về trọn vẹn. Perfect Zecter hiện ra trong tay {name}!"],
			["tendou", "Bà tôi từng nói: thiên đạo không chỉ có một. Ai cũng có con đường của riêng mình. Đi đường của cậu đi, {name}."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Kabuto đã sáng lại. Chặng tiếp theo: Trái Đất Den-O, nơi người ta đi tàu hỏa xuyên thời gian."],
	["hero", "Tàu xuyên thời gian... Có cần mua vé không nhỉ?"],
	["pen", "Tôi chính là vé đây! Chrono Pass mà, hehe."],
]
