extends RefCounted
## Thế giới 27 · Kamen Rider Zeztz (2025) — "Tỉnh giấc trong mơ" · THẾ GIỚI CUỐI của chuỗi
## Echo Rider: Yorozu Baku (ngoài đời xui xẻo, trong mơ tỉnh táo, là đặc vụ số 7 của CODE). Hỗ trợ: Nem (ngôi sao
## quảng cáo, gặp Baku trong mơ). Quái: Nightmare (biến nỗi sợ trong mơ thành thật). Trùm: Oblivion Gore Nightmare.
## Kết Hồi 3: {name} mơ lại đám cháy 10 năm trước, thấy mặt Rei; trùm rơi Chrono Driver, cổng tới Điểm Không mở.
## Nguồn tra cứu: en/ja.wikipedia "Kamen Rider ZEZTZ" (Zeztz Driver đeo ngực, Capsem, form Physicam / Inazuma /
## Paradigm, chiêu "<tên> Vanish", form cuối Exdream, 4 Gore Nightmare), mynavi 2025-09-06.

const WORLD := {
	"id": "zeztz",
	"year": 2025,
	"name": "Thế giới Zeztz",
	"motto": "Tỉnh giấc trong mơ",
	"rider": &"zeztz",
	"rider_name": "Zeztz",
	"driver_name": "Zeztz Driver",
	"color": Color(0.55, 0.65, 1.0),
	"enemies": {
		"basic": {"name": "Nightmare", "color": Color(0.48, 0.42, 0.62), "sprite": "nightmare"},
		"fast": {"name": "Crow Nightmare", "color": Color(0.32, 0.32, 0.48), "sprite": "crow_nightmare"},
		"armored": {"name": "Bomb Nightmare", "color": Color(0.58, 0.46, 0.36), "sprite": "bomb_nightmare"},
	},
	"unlocks": [
		"Physicam Impact (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Exdream: Final Attack x1.5",
	],
	"stages": [
		{"name": "Thành phố trong mơ", "goal": "Tỉnh táo trong mơ: hạ Nightmare, giành lại Zeztz Driver",
			"bg": "zeztz_1", "bg_theme": "dreamscape"},
		{"name": "Mái nhà giấc mơ đêm", "form": &"wing", "form_name": "Physicam Wing",
			"bg": "zeztz_2", "bg_theme": "city_night"},
		{"name": "Trụ sở CODE trong mơ", "form": &"plasma", "form_name": "Inazuma Plasma",
			"bg": "zeztz_3", "bg_theme": "cyber_city"},
		{"name": "Hành lang cửa lơ lửng", "form": &"gravity", "form_name": "Paradigm Gravity",
			"bg": "zeztz_4", "bg_theme": "dreamscape"},
		{"name": "Trùm: Oblivion Gore Nightmare", "bg": "zeztz_b", "bg_theme": "boss_red",
			"boss": {"name": "Oblivion Gore Nightmare", "hp": 320.0, "damage": 19.0, "poise": 32.0, "speed": 75.0,
				"traits": [], "color": Color(0.42, 0.36, 0.62)}},
	],
}

## Zeztz: mỗi Capsem một năng lực. Physicam Impact sức mạnh thuần; Physicam Wing cánh dơi, nhảy cao, phóng lưỡi
## năng lượng xuyên thấu; Inazuma Plasma điện và siêu tốc, nhanh nhất; Paradigm Gravity găng trọng lực, chậm mà phá giáp.
const RIDER := {
	"name": "Kamen Rider Zeztz",
	"tagline": "Đặc vụ trong mơ · form cánh dơi, form tia sét, form trọng lực",
	"base": &"impact",
	"order": [&"impact", &"wing", &"plasma", &"gravity"],
	"forms": {
		&"impact": {"name": "Physicam Impact", "style": "brawler", "hp": 165.0, "armor": 25.0, "speed": 128.0,
			"jump": 1.05, "atk": 1.1, "poise": 8.0, "final": "Impact Vanish",
			"skills": [
				{"name": "Impact Fist", "type": "aim", "move": "dash", "tags": [&"stun"], "fx": "crack",
					"color": Color(0.4, 0.65, 1.0)},
				{"name": "Dream Dive", "type": "buff", "buff": {"behind": true, "time": 2.0}, "fx": "eye",
					"color": Color(0.75, 0.4, 1.0)},
			]},
		&"wing": {"name": "Physicam Wing", "style": "gunner", "hp": 140.0, "armor": 12.0, "speed": 125.0,
			"jump": 1.4, "atk": 0.95, "poise": 5.0, "final": "Wing Vanish",
			"gun": {"damage": 6.5, "speed": 400.0, "cooldown": 0.38, "count": 2, "spread": 0.12,
				"color": Color(0.8, 0.55, 1.0), "pierce": true, "life": 0.7},
			"skills": [
				{"name": "Wing Shot", "type": "aim", "move": "spread", "shot": {"pierce": true, "style": "arrow"},
					"fx": "feather", "color": Color(0.85, 0.6, 1.0)},
				{"name": "Wing Flight", "type": "buff", "buff": {"fly": true, "time": 5.0}, "fx": "wings",
					"color": Color(0.4, 0.85, 1.0)},
			],
			"final_type": "lock"},
		&"plasma": {"name": "Inazuma Plasma", "style": "lancer", "hp": 130.0, "armor": 10.0, "speed": 182.0,
			"jump": 1.3, "atk": 0.92, "poise": 4.0, "final": "Plasma Vanish",
			"skills": [
				{"name": "Plasma Bolt", "type": "aim", "move": "shot", "tags": [&"shock"], "shot": {"style": "bolt", "speed": 420.0},
					"fx": "bulb", "color": Color(1.0, 0.95, 0.4)},
				{"name": "Plasma Field", "type": "area", "tags": [&"shock"], "fx": "lightning", "radius": 80.0,
					"color": Color(0.55, 0.7, 1.0), "icon": "shockwave"},
			],
			"final_type": "area"},
		&"gravity": {"name": "Paradigm Gravity", "style": "heavy", "hp": 205.0, "armor": 55.0, "speed": 85.0,
			"jump": 0.82, "atk": 1.42, "poise": 19.0, "final": "Gravity Vanish",
			"skills": [
				{"name": "Gravity Press", "type": "area", "tags": [&"crush"], "fx": "stamp", "anim": "heavy",
					"color": Color(0.55, 0.35, 0.85)},
				{"name": "Gravity Well", "type": "bind", "via": "area", "radius": 90.0, "knockback": Vector2(-120, -10),
					"fx": "gravity", "anim": "heavy", "color": Color(0.3, 0.75, 1.0), "icon": "aura"},
			],
			"final_type": "bind"},
	},
	"lv5": {"name": "Exdream", "final_mult": 1.5},
}

const SPEAKERS := {
	"baku": {"name": "YOROZU BAKU", "color": Color(0.6, 0.75, 1.0), "portrait": "baku",
		"look": "hair=2a2020 jacket=3a3a4a stripe=e0c050 eyes=3a2a2a"},
	"nem": {"name": "NEM", "color": Color(1.0, 0.75, 0.9), "portrait": "nem",
		"look": "hair=f0c8d8 jacket=f8f0ff stripe=a080e0 eyes=5a4a8a long"},
	"oblivion": {"name": "OBLIVION", "color": Color(0.65, 0.6, 0.85), "portrait": "oblivion",
		"look": "base=daguba tint=504a70"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Zeztz · Một thành phố trong mơ, nơi những cánh cửa lơ lửng giữa trời."],
			["baku", "Yorozu Baku. Ngoài đời tôi xui tận mạng, nhưng trong mơ tôi là đặc vụ số 7 của CODE. Có điều, Void lấy mất Zeztz Driver rồi."],
			["pen", "Nightmare đang tràn vào giấc mơ mọi người, biến nỗi sợ thành thật. Muốn dùng Driver thì phải tỉnh táo ngay trong mơ."],
		],
		"goal": [
			["baku", "Nightmare kia đang ôm Driver của tôi. Nhớ: đây là giấc mơ, cậu tin mình mạnh cỡ nào thì mạnh cỡ đó!"],
		],
		"key": [
			["narrator", "Zeztz Driver quấn chéo qua ngực {name}, không phải ngang eo. Viên Impact Capsem xoay tít rồi lóe sáng."],
			["hero", "Henshin!"],
		],
		"clear": [
			["pen", "Physicam Impact là form gốc: sức mạnh thuần túy, đấm là nổ. Capsem khác đang nằm trong tay Nightmare."],
			["baku", "Lạ thật, giấc mơ này không phải của tôi. Có mùi khói. Cậu từng mơ thấy lửa à, {name}?"],
			["hero", "...Mười năm nay, đêm nào cũng thế."],
		],
	},
	"2": {
		"start": [
			["nem", "Chào cậu, tôi là Nem! Ngoài kia tôi là ngôi sao quảng cáo, còn ở đây... tôi chỉ gặp được mọi người trong mơ."],
		],
		"key": [
			["baku", "Physicam Wing! Cánh dơi, nhảy cao, lượn xa, phóng lưỡi năng lượng xuyên qua cả hàng Nightmare."],
		],
		"clear": [
			["nem", "Nightmare lớn lên từ nỗi sợ. Nỗi sợ của cậu có hình một ngôi nhà đang cháy."],
			["hero", "Tôi không nhớ mặt anh ấy. Mười năm rồi, trong mơ anh Rei lúc nào cũng quay lưng lại."],
		],
	},
	"3": {
		"start": [
			["baku", "Trụ sở CODE, bản trong mơ. Nightmare ở đây chạy nhanh như chớp. Tìm Capsem màu vàng đang tóe điện ấy!"],
		],
		"key": [
			["baku", "Inazuma Plasma! Điện chạy khắp người, nhanh như tia sét. Đòn nhẹ nhưng liên hoàn, máu thì mỏng."],
		],
		"clear": [
			["baku", "Tôi từng mơ thấy tương lai tệ nhất của mình. Tỉnh dậy, tôi thề phải đổi nó bằng được."],
			["baku", "Giấc mơ không phải chỗ để trốn, {name}. Là chỗ để nhìn thẳng vào thứ mình sợ."],
		],
	},
	"4": {
		"start": [
			["nem", "Mỗi cánh cửa ở đây là một ký ức. Cửa cuối cùng dẫn về đêm hôm đó, nhưng Bomb Nightmare giáp dày đang chặn."],
		],
		"key": [
			["baku", "Paradigm Gravity! Găng tay trọng lực, chậm mà nặng. Đấm một phát là kẻ thù dính chặt xuống đất."],
		],
		"clear": [
			["pen", "Sau cánh cửa kia là giấc mơ đám cháy. Kẻ canh nó tên Oblivion, nghĩa là lãng quên."],
			["hero", "Vậy là nó đang giữ khuôn mặt anh Rei. Tôi vào đây."],
		],
	},
	"B": {
		"start": [
			["narrator", "Mười năm trước. Khói đen. Một căn nhà đang cháy, và một cậu bé chín tuổi không tìm được lối ra."],
		],
		"goal": [
			["oblivion", "Quên đi. Quên khuôn mặt ấy, quên cả tiếng gọi ấy. Lãng quên rồi thì không còn đau."],
			["hero", "Tôi đã quên đủ lâu rồi. Trả anh ấy lại cho tôi!"],
		],
		"clear": [
			["narrator", "Oblivion vỡ tan. Ngọn lửa dịu lại, và ký ức hiện ra rõ như ban ngày: một thiếu niên mặt lấm tro bế {name} ra khỏi đám cháy."],
			["hero", "Anh Rei... Là anh đã cứu em. Anh còn cười với em, trước khi vết nứt tím nuốt mất anh."],
			["narrator", "Sức mạnh Zeztz trở về trọn vẹn. Exdream! Rồi từ mọi Driver trong chuỗi, một chiếc đai mới thành hình, bọc tinh thể tím đang nứt dần."],
			["pen", "Chrono Driver. Nó không thuộc về Rider nào cả. Hai mươi bảy Driver hợp lại làm một... Nó là của cậu, {name}."],
			["void", "Nhớ ra rồi à, {name}. Vậy thì đến Điểm Không. Mọi thứ bắt đầu ở đó, và sẽ kết thúc ở đó."],
			["baku", "Tỉnh dậy đi, rồi sống cho trọn giấc mơ của cậu. Chào buổi sáng, Rider!"],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Zeztz sáng lại. Hai mươi bảy thế giới, tất cả đều sáng. Và cổng tới Điểm Không... đã mở."],
	["hero", "Chrono Driver, của riêng tôi. Anh Rei, lần này em sẽ là người kéo anh ra."],
	["pen", "Tôi đi cùng cậu tới cuối. Lần trước tôi không giữ được anh ấy. Lần này, tôi không buông tay ai cả."],
]
