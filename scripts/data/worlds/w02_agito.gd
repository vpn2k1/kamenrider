extends RefCounted
## Thế giới 2 · Kamen Rider Agito (2001) — "Sức mạnh thức tỉnh"
## FILE MẪU cho mọi thế giới dùng DataRider: hằng WORLD, RIDER, SPEAKERS, STORY, WORLD_CLEAR.
## Echo Rider: Tsugami Shouichi (mất trí nhớ, mê nấu ăn). Hỗ trợ: Hikawa Makoto (G3, cảnh sát).
## Quái: Lord (Unknown) săn những người mang mầm sức mạnh Agito. Trùm: Overlord of Darkness.

const WORLD := {
	"id": "agito",
	"year": 2001,
	"name": "Thế giới Agito",
	"motto": "Sức mạnh thức tỉnh",
	"rider": &"agito",
	"rider_name": "Agito",
	"driver_name": "Alter Ring",
	"color": Color(1.0, 0.62, 0.15),
	"enemies": {
		"basic": {"name": "Jaguar Lord", "color": Color(0.8, 0.62, 0.3), "sprite": "jaguar_lord"},
		"fast": {"name": "Crow Lord", "color": Color(0.3, 0.3, 0.45), "sprite": "crow_lord"},
		"armored": {"name": "Tortoise Lord", "color": Color(0.45, 0.55, 0.35), "sprite": "tortoise_lord"},
	},
	"unlocks": [
		"Ground Form (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Shining Form: Final Attack x1.5",
	],
	"stages": [
		{"name": "Nhà Misugi", "goal": "Bảo vệ người bị Lord săn, giành lại Alter Ring",
			"bg": "agito_1", "bg_theme": "suburb"},
		{"name": "Bờ biển lúc chiều", "form": &"storm", "form_name": "Storm Form",
			"bg": "agito_2", "bg_theme": "coast"},
		{"name": "Trụ sở G3", "form": &"flame", "form_name": "Flame Form",
			"bg": "agito_3", "bg_theme": "city_night"},
		{"name": "Rừng núi bình minh", "form": &"trinity", "form_name": "Trinity Form",
			"bg": "agito_4", "bg_theme": "mountain_dawn"},
		{"name": "Trùm: Overlord of Darkness", "bg": "agito_b", "bg_theme": "boss_gold",
			"boss": {"name": "Overlord of Darkness", "hp": 250.0, "damage": 15.0, "poise": 28.0, "speed": 60.0,
				"traits": [], "color": Color(0.2, 0.18, 0.28), "sprite": "overlord"}},
	],
}

## Agito: cân bằng, mỗi form một vũ khí. Storm (giáo Storm Halberd) nhanh và nhảy cao; Flame (kiếm Flame Saber)
## chậm nhưng chém nặng phá giáp; Trinity gộp cả hai, mạnh nhất nhưng tốn nộ như mọi form đặc biệt.
const RIDER := {
	"name": "Kamen Rider Agito",
	"tagline": "Cân bằng · form giáo, form kiếm",
	"base": &"ground",
	"order": [&"ground", &"storm", &"flame", &"trinity"],
	"forms": {
		&"ground": {"name": "Ground Form", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "Rider Kick",
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.8, 0.25)}},
		&"storm": {"name": "Storm Form", "style": "lancer", "hp": 135.0, "armor": 10.0, "speed": 170.0,
			"jump": 1.25, "atk": 0.9, "poise": 4.0, "final": "Haldent Tornado",
			"fx": {"hit": "wind", "swing": "wind", "color": Color(0.4, 0.6, 1.0)}},
		&"flame": {"name": "Flame Form", "style": "blade", "hp": 170.0, "armor": 30.0, "speed": 110.0,
			"jump": 0.95, "atk": 1.25, "poise": 12.0, "final": "Saber Slash",
			"fx": {"hit": "fire", "swing": "slash", "color": Color(1.0, 0.35, 0.2)}},
		&"trinity": {"name": "Trinity Form", "style": "blade", "hp": 175.0, "armor": 35.0, "speed": 135.0,
			"jump": 1.1, "atk": 1.3, "poise": 12.0, "final": "Fire Storm Attack",
			"fx": {"hit": "fire", "swing": "slash", "color": Color(1.0, 0.85, 0.5)}},
	},
	"lv5": {"name": "Shining", "final_mult": 1.5},
}

const SPEAKERS := {
	"shouichi": {"name": "TSUGAMI SHOUICHI", "color": Color(1.0, 0.7, 0.3), "portrait": "shouichi",
		"look": "hair=3c2a1e jacket=d8c8a0 stripe=6a8a4a eyes=4a3222"},
	"hikawa": {"name": "HIKAWA (G3)", "color": Color(0.45, 0.6, 0.95), "portrait": "hikawa",
		"look": "hair=141418 jacket=2a3a5a stripe=e8e8f0 eyes=2a2a34"},
	"overlord": {"name": "OVERLORD", "color": Color(0.55, 0.5, 0.75), "portrait": "overlord",
		"look": "base=orphnoch tint=3a3450"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Agito · Nhà Misugi, một buổi sáng yên bình."],
			["shouichi", "Ô, khách à? Tôi là Tsugami Shouichi. Vừa hái cà chua ngoài vườn, ăn thử không?"],
			["pen", "Không phải lúc! Alter Ring bị phong ấn. Nó cần một người mang sức mạnh thức tỉnh để mở lại."],
			["shouichi", "Lũ Lord đang săn những người như thế. Hàng xóm tôi đang gặp nguy. Đi thôi!"],
		],
		"goal": [
			["shouichi", "Tụi Lord kia đang vây một người! Alter Ring chắc nằm trên người con đầu đàn."],
		],
		"key": [
			["narrator", "Alter Ring hiện ra quanh eo {name}. Ánh sáng vàng như mặt trời mọc."],
			["shouichi", "Cảm giác đó... tôi cũng từng có. Đó là sức mạnh Agito. Nó không hỏi cậu có sẵn sàng chưa đâu."],
			["hero", "Henshin!"],
		],
		"clear": [
			["shouichi", "Tôi không nhớ mình là ai trước khi thành Agito. Nhưng tôi biết mình muốn bảo vệ bữa cơm của mọi người."],
			["pen", "Ground Form là form gốc: cân bằng, không có gì yếu. Các form vũ khí nằm trong tay lũ Lord."],
		],
	},
	"2": {
		"start": [
			["hikawa", "Hikawa Makoto, đơn vị G3. Lord xuất hiện dọc bờ biển, chúng nhanh hơn người thường nhiều."],
			["pen", "Sức mạnh Storm Form đang ở đâu đó trong đám Lord này. Giáo Storm Halberd, nhanh như gió."],
		],
		"key": [
			["shouichi", "Màu xanh! Storm Form nhẹ và nhanh, cầm giáo đánh được xa. Nhảy cũng cao hơn đấy."],
		],
		"clear": [
			["hikawa", "G3 của tôi chỉ là giáp do con người làm ra. Nhìn cậu, tôi thấy mình còn phải cố gắng nhiều."],
			["hero", "Giáp do con người làm ra mà vẫn đứng ra đánh Lord... tôi thấy thế mới đáng nể."],
		],
	},
	"3": {
		"start": [
			["hikawa", "Trụ sở G3 bị tấn công. Tortoise Lord có mai cứng, đạn của tôi không xuyên nổi."],
			["pen", "Cần đòn nặng. Flame Form với kiếm Flame Saber: chậm, nhưng chém một nhát là vỡ mai."],
		],
		"key": [
			["shouichi", "Màu đỏ! Flame Form. Chậm hơn, nhưng mỗi nhát kiếm nặng như búa."],
		],
		"clear": [
			["hikawa", "Cảm ơn. Lần sau tôi sẽ đứng cạnh cậu, không phải đứng sau."],
		],
	},
	"4": {
		"start": [
			["shouichi", "Trên núi này, lũ Lord đang tụ lại quanh một thứ ánh sáng lạ. Tôi nghe nói có người bị bắt lên đó."],
			["pen", "Trinity Form, gộp cả Storm và Flame. Muốn dùng được nó thì phải thạo cả hai trước đã."],
		],
		"key": [
			["shouichi", "Vai trái xanh, vai phải đỏ. Trinity Form! Cậu học nhanh thật đấy."],
		],
		"clear": [
			["pen", "Kẻ đứng sau lũ Lord ở ngay phía trước. Hắn tự xưng là Overlord, kẻ tạo ra loài người."],
			["shouichi", "Hắn muốn xóa sức mạnh Agito khỏi thế giới. Nhưng sức mạnh này là của con người mà."],
		],
	},
	"B": {
		"start": [
			["pen", "Năng lượng Void quấn quanh hắn. Driver tiếp theo bị giấu trong đó."],
		],
		"goal": [
			["overlord", "Loài người không được phép vượt quá giới hạn ta đặt ra. Agito là một sai lầm."],
			["hero", "Vậy thì tôi sẽ sai tới cùng."],
		],
		"clear": [
			["narrator", "Overlord tan vào bóng tối. Ánh sáng còn lại đọng thành một hộp thẻ bọc tinh thể tím: Advent Deck."],
			["narrator", "Sức mạnh Agito trở về trọn vẹn. Shining Form!"],
			["shouichi", "Ai rồi cũng có thể thức tỉnh. Quan trọng là cậu dùng sức mạnh đó để làm gì."],
			["pen", "Advent Deck của Ryuki. Thế giới kế tiếp... nằm sau những tấm gương."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Agito đã sáng lại. Chặng tiếp theo: Trái Đất Ryuki, nơi các Rider đánh nhau trong thế giới gương."],
	["hero", "Rider đánh... Rider? Không vui chút nào."],
]
