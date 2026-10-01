extends RefCounted
## Thế giới 3 · Kamen Rider Ryuki (2002) — "Chiến đấu để sống sót"
## Echo Rider: Kido Shinji (phóng viên tập sự, muốn chấm dứt cuộc chiến Rider). Hỗ trợ: Akiyama Ren (Knight).
## Quái: Mirror Monster từ thế giới gương. Trùm: Kamen Rider Odin, con rối vàng của Kanzaki Shiro.
## Mạch truyện: Void nói vọng ra từ mặt gương, Pen run rẩy rồi lảng đi.

const WORLD := {
	"id": "ryuki",
	"year": 2002,
	"name": "Thế giới Ryuki",
	"motto": "Chiến đấu để sống sót",
	"rider": &"ryuki",
	"rider_name": "Ryuki",
	"driver_name": "Advent Deck",
	"color": Color(1.0, 0.38, 0.3),
	"enemies": {
		"basic": {"name": "Sheerghost", "color": Color(0.62, 0.66, 0.74), "sprite": "sheerghost"},
		"fast": {"name": "Raydragoon", "color": Color(0.35, 0.78, 0.72), "sprite": "raydragoon"},
		"armored": {"name": "Metalgelas", "color": Color(0.55, 0.5, 0.45), "sprite": "metalgelas"},
	},
	"unlocks": [
		"Ryuki (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Ryuki Survive: Final Attack x1.5",
	],
	"stages": [
		{"name": "Phố trước tòa soạn OREJournal", "goal": "Hạ Mirror Monster, giành lại Advent Deck và ký khế ước với Dragreder",
			"bg": "ryuki_1", "bg_theme": "city_day"},
		{"name": "Quán trà Atori", "form": &"sword_vent", "form_name": "Sword Vent",
			"bg": "ryuki_2", "bg_theme": "city_dusk"},
		{"name": "Công viên ven sông lúc đêm", "form": &"strike_vent", "form_name": "Strike Vent",
			"bg": "ryuki_3", "bg_theme": "city_night"},
		{"name": "Thế giới gương", "form": &"guard_vent", "form_name": "Guard Vent",
			"bg": "ryuki_4", "bg_theme": "mirror_city"},
		{"name": "Trùm: Kamen Rider Odin", "bg": "ryuki_b", "bg_theme": "boss_gold",
			"boss": {"name": "Kamen Rider Odin", "hp": 250.0, "damage": 17.0, "poise": 24.0, "speed": 85.0,
				"traits": [], "color": Color(0.95, 0.8, 0.3), "sprite": "odin"}},
	],
}

## Ryuki: form gốc đấm đá, mỗi thẻ Vent một kiểu. Sword Vent (kiếm Drag Saber) chém nặng; Strike Vent (găng Dragclaw)
## phun cầu lửa từ xa; Guard Vent (khiên Dragshield) chậm nhưng lì đòn, đập phá giáp.
const RIDER := {
	"name": "Kamen Rider Ryuki",
	"tagline": "Thẻ Vent · kiếm rồng, cầu lửa, khiên rồng",
	"base": &"ryuki",
	"order": [&"ryuki", &"sword_vent", &"strike_vent", &"guard_vent"],
	"forms": {
		&"ryuki": {"name": "Ryuki", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "Dragon Rider Kick",
			"fx": {"hit": "spark", "final": "fire", "color": Color(1.0, 0.4, 0.25)}},
		&"sword_vent": {"name": "Sword Vent", "style": "blade", "hp": 165.0, "armor": 28.0, "speed": 122.0,
			"jump": 1.0, "atk": 1.25, "poise": 11.0, "final": "Drag Saber Slash",
			"fx": {"hit": "spark", "swing": "slash", "final": "fire", "color": Color(1.0, 0.75, 0.35)}},
		&"strike_vent": {"name": "Strike Vent", "style": "gunner", "hp": 145.0, "armor": 15.0, "speed": 118.0,
			"jump": 1.0, "atk": 1.0, "poise": 5.0, "final": "Dragclaw Fire",
			"fx": {"hit": "fire", "shot": "fire", "final": "fire", "color": Color(1.0, 0.5, 0.15)},
			"gun": {"damage": 9.0, "speed": 320.0, "cooldown": 0.5, "radius": 5.0, "color": Color(1.0, 0.5, 0.15),
				"life": 0.9}},
		&"guard_vent": {"name": "Guard Vent", "style": "heavy", "hp": 205.0, "armor": 58.0, "speed": 82.0,
			"jump": 0.85, "atk": 1.35, "poise": 20.0, "final": "Advent: Dragreder",
			"fx": {"hit": "ring", "final": "fire", "color": Color(0.85, 0.85, 0.95)}},
	},
	"lv5": {"name": "Survive", "final_mult": 1.5},
}

const SPEAKERS := {
	"shinji": {"name": "KIDO SHINJI", "color": Color(1.0, 0.45, 0.35), "portrait": "shinji",
		"look": "hair=3a2a1e jacket=7a2a2a stripe=e0e0e0 eyes=3a2a20"},
	"ren": {"name": "AKIYAMA REN", "color": Color(0.55, 0.58, 0.75), "portrait": "ren",
		"look": "hair=16161a jacket=1e1e24 stripe=5a5a66 eyes=26262e"},
	"odin": {"name": "ODIN", "color": Color(1.0, 0.85, 0.3), "portrait": "odin", "look": "base=kuuga tint=e8c040"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Ryuki · Phố trước tòa soạn OREJournal."],
			["shinji", "Nghe tiếng ù ù không? Quái trong gương sắp lao ra! Tôi là Kido Shinji, từng là Ryuki. Tôi chỉ muốn cuộc chiến Rider dừng lại."],
			["pen", "Advent Deck bị phong ấn. Hộp thẻ này chỉ sống lại khi ký khế ước với một quái vật gương: rồng đỏ Dragreder."],
		],
		"goal": [
			["shinji", "Lũ Sheerghost kia đang giữ hộp thẻ! Đừng để chúng kéo cậu vào trong gương."],
		],
		"key": [
			["narrator", "Advent Deck bay về tay {name}. Trong mặt kính, rồng đỏ Dragreder gầm lên: khế ước đã thành. Đai hiện ra quanh eo."],
			["hero", "Henshin!"],
		],
		"clear": [
			["shinji", "Khế ước nghĩa là phải cho Dragreder ăn quái vật cậu hạ được. Nó không phải thú cưng đâu nhé."],
			["pen", "Ryuki là form gốc, đấm đá cân bằng. Các thẻ Vent khác đang nằm trong người lũ quái gương."],
		],
	},
	"2": {
		"start": [
			["ren", "Akiyama Ren. Knight. Lũ quái quanh quán Atori là con mồi của tôi. Đừng cản đường."],
			["pen", "Thẻ Sword Vent đang ở trong đám quái này. Có nó là có kiếm Drag Saber."],
		],
		"key": [
			["shinji", "Sword Vent! Drag Saber làm từ đuôi của Dragreder đấy. Chém ba nhát, nhát cuối phá được giáp."],
		],
		"clear": [
			["ren", "Cậu giống hệt Kido. Ngây thơ tới mức ngốc nghếch. ...Nhưng đánh không tệ."],
		],
	},
	"3": {
		"start": [
			["shinji", "Raydragoon bay lượn trên mặt sông. Đánh tay không thì không với tới đâu."],
			["pen", "Cần thẻ Strike Vent: găng đầu rồng Dragclaw, phun cầu lửa từ xa."],
		],
		"key": [
			["shinji", "Strike Vent! Đấm Dragclaw ra là Dragreder phun lửa cùng cậu. Bắn xa, nhưng đừng để bị áp sát."],
		],
		"clear": [
			["narrator", "Mặt sông gợn sóng. Bóng phản chiếu trong đó không phải của {name}."],
			["void", "Không chiến đấu thì không sống sót. Thế giới này nói đúng một điều."],
			["hero", "Pen? Cô đang run à?"],
			["pen", "Tôi? Đâu có! Chỉ là... nhiễu sóng từ thế giới gương thôi. Đi tiếp đi."],
		],
	},
	"4": {
		"start": [
			["ren", "Muốn tới chỗ kẻ đứng sau thì phải vào sâu trong gương. Metalgelas ở đó cứng như xe tăng."],
			["pen", "Ở lâu trong gương là cơ thể tan thành hạt đấy! Thẻ Guard Vent cho cậu khiên Dragshield, chịu đòn cực tốt."],
		],
		"key": [
			["shinji", "Guard Vent! Khiên Dragshield trên vai. Chậm thì chậm, cứ đứng vững mà đập, giáp dày cỡ nào cũng vỡ."],
		],
		"clear": [
			["shinji", "Đừng đánh để thắng, {name}. Đánh để mọi người không phải đánh nhau nữa."],
		],
	},
	"B": {
		"start": [
			["pen", "Odin, con rối vàng của Kanzaki Shiro. Hắn dịch chuyển tức thời được. Năng lượng Void phát sáng trong bộ giáp đó!"],
		],
		"goal": [
			["odin", "Kẻ ngoại lai. Rider cuối cùng sống sót sẽ có được điều ước. Ngươi không có tư cách đó."],
			["hero", "Tôi không cần điều ước. Tôi đến để kết thúc chuyện này."],
		],
		"clear": [
			["narrator", "Odin vỡ thành lông vũ vàng. Giữa đám lông vũ là một chiếc đai bạc bọc tinh thể tím: Faiz Driver."],
			["narrator", "Sức mạnh Ryuki trở về trọn vẹn. Thẻ Survive bùng lửa: Ryuki Survive!"],
			["shinji", "Tôi vẫn không biết đánh nhau là đúng hay sai. Nhưng muốn bảo vệ ai đó thì không bao giờ sai cả."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Ryuki đã sáng lại. Chặng tiếp theo: Trái Đất Faiz, nơi người chết đi rồi đứng dậy thành Orphnoch."],
	["hero", "Mong là ở đó Rider không phải đánh nhau với Rider nữa."],
]
