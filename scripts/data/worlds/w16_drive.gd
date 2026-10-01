extends RefCounted
## Thế giới 16 · Kamen Rider Drive (2014) — "Chính nghĩa và cộng sự"
## Echo Rider: Tomari Shinnosuke (cảnh sát Tokujoka, "Não tôi vừa vào số cao"). Hỗ trợ: Belt-san (Krim Steinbelt,
## ý thức sống trong Drive Driver, soi gương với Pen). Quái: Roidmude và vùng Don-yori (Heavy Acceleration).
## Trùm: Heart Roidmude. Bài học: chính nghĩa là hành động; cộng sự không cần biết hết quá khứ của nhau.

const WORLD := {
	"id": "drive",
	"year": 2014,
	"name": "Thế giới Drive",
	"motto": "Chính nghĩa và cộng sự",
	"rider": &"drive",
	"rider_name": "Drive",
	"driver_name": "Drive Driver",
	"color": Color(0.95, 0.12, 0.15),
	"enemies": {
		"basic": {"name": "Roidmude Spider", "color": Color(0.6, 0.6, 0.66)},
		"fast": {"name": "Roidmude Bat", "color": Color(0.55, 0.38, 0.8)},
		"armored": {"name": "Roidmude Cobra", "color": Color(0.45, 0.62, 0.5)},
	},
	"unlocks": [
		"Type Speed (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Type Tridoron: Final Attack x1.5",
	],
	"stages": [
		{"name": "Tokujoka, trung tâm sát hạch Kuruma", "goal": "Thoát vùng Don-yori, giành lại Shift Speed cho Drive Driver",
			"bg": "drive_1", "bg_theme": "city_day"},
		{"name": "Khu công nghiệp ven cảng", "form": &"wild", "form_name": "Type Wild",
			"bg": "drive_2", "bg_theme": "industrial"},
		{"name": "Phố đêm Kuruma", "form": &"technic", "form_name": "Type Technic",
			"bg": "drive_3", "bg_theme": "race_city"},
		{"name": "Xa lộ trên cao", "form": &"formula", "form_name": "Type Formula",
			"bg": "drive_4", "bg_theme": "highway"},
		{"name": "Trùm: Heart Roidmude", "bg": "drive_b", "bg_theme": "boss_storm",
			"boss": {"name": "Heart Roidmude", "hp": 290.0, "damage": 19.0, "poise": 30.0, "speed": 70.0,
				"traits": [], "color": Color(0.9, 0.15, 0.2)}},
	],
}

## Drive: đổi Shift Car. Type Wild khỏe như xe tải, chậm, đòn nào cũng phá giáp; Type Technic bắn Door-ju cực chuẩn
## từ xa; Type Formula nhanh tới mức thế giới gần như đứng yên (tăng tốc thời gian, nộ tụt nhanh).
const RIDER := {
	"name": "Kamen Rider Drive",
	"tagline": "Shift Car · xe tải, súng cửa, Formula siêu tốc",
	"base": &"speed",
	"order": [&"speed", &"wild", &"technic", &"formula"],
	"forms": {
		&"speed": {"name": "Type Speed", "style": "brawler", "hp": 155.0, "armor": 22.0, "speed": 140.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "SpeeDrop"},
		&"wild": {"name": "Type Wild", "style": "heavy", "hp": 205.0, "armor": 55.0, "speed": 85.0,
			"jump": 0.85, "atk": 1.4, "poise": 18.0, "final": "Full Throttle: Wild"},
		&"technic": {"name": "Type Technic", "style": "gunner", "hp": 145.0, "armor": 18.0, "speed": 118.0,
			"jump": 1.0, "atk": 0.95, "poise": 5.0, "final": "Full Throttle: Technic",
			"gun": {"damage": 7.5, "speed": 420.0, "cooldown": 0.32, "radius": 3.0,
				"color": Color(0.35, 0.95, 0.45), "life": 0.9}},
		&"formula": {"name": "Type Formula", "style": "lancer", "hp": 130.0, "armor": 10.0, "speed": 180.0,
			"jump": 1.25, "atk": 0.95, "poise": 4.0, "effect": "time", "final": "Formula Drop"},
	},
	"lv5": {"name": "Type Tridoron", "final_mult": 1.5},
}

const SPEAKERS := {
	"shinnosuke": {"name": "TOMARI SHINNOSUKE", "color": Color(0.95, 0.3, 0.3), "portrait": "shinnosuke",
		"look": "hair=2a1e18 jacket=3a3e4a stripe=c82a2a eyes=3a2a20"},
	"krim": {"name": "BELT-SAN", "color": Color(0.5, 0.85, 1.0), "portrait": "krim",
		"look": "hair=5a4632 jacket=e8e8ec stripe=c82a2a eyes=4a5a6a"},
	"heart": {"name": "HEART", "color": Color(0.9, 0.2, 0.25), "portrait": "heart",
		"look": "base=orphnoch tint=d02838"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Drive · Phòng Tokujoka ở trung tâm sát hạch lái xe Kuruma."],
			["shinnosuke", "Tomari Shinnosuke, cảnh sát. Roidmude vừa tung Don-yori, cả khu phố chậm như bị ngâm trong keo."],
			["krim", "Tôi là Krim Steinbelt, cứ gọi là Belt-san. Drive Driver đã chọn cậu, nhưng Shift Speed bị Roidmude giữ mất."],
			["pen", "Một cái đai biết nói?! ...Khoan, tập trung. Hạ Roidmude, lấy lại Shift Speed là thoát được Don-yori!"],
		],
		"goal": [
			["shinnosuke", "Con Roidmude đầu đàn kia giữ Shift Speed. Cài số thôi."],
		],
		"key": [
			["krim", "Start your engine!"],
			["hero", "Henshin!"],
			["narrator", "DRIVE! TYPE SPEED! Một chiếc lốp đỏ bay tới, cài chéo qua ngực {name}. Vùng Don-yori vỡ tan."],
		],
		"clear": [
			["shinnosuke", "Não tôi vừa vào số cao. Roidmude giấu các Shift Car khác khắp thành phố. Đi thôi!"],
			["pen", "Type Speed là form gốc: nhanh, cân bằng. Mỗi Shift Car giành lại là một Type mới."],
		],
	},
	"2": {
		"start": [
			["shinnosuke", "Roidmude Cobra đang phá khu công nghiệp. Khỏe lắm, đấm thường không lay nổi. Shift Wild đang trong tay nó."],
		],
		"key": [
			["krim", "DRIVE! TYPE WILD! Chậm hơn, nhưng mỗi cú húc như xe tải lao tới. Giáp nào cũng vỡ. Nice drive!"],
		],
		"clear": [
			["krim", "Cô Pen, cô cũng sống trong một thiết bị à? Giống tôi đấy."],
			["pen", "Tôi không nhớ mình từng là gì khác. Chỉ biết bây giờ tôi là cộng sự của {name}."],
			["krim", "Vậy là đủ. Cộng sự không cần biết hết quá khứ của nhau, chỉ cần chạy cùng một hướng."],
		],
	},
	"3": {
		"start": [
			["shinnosuke", "Roidmude Bat bay lượn trên phố đêm, vừa nhanh vừa ở xa. Shift Technic đang trong tay chúng."],
		],
		"key": [
			["krim", "DRIVE! TYPE TECHNIC! Door-ju bắn cực chuẩn từ xa. Đứng xa mà ngắm, đừng để bị áp sát."],
		],
		"clear": [
			["hero", "Shinnosuke, anh làm cảnh sát vì chính nghĩa à?"],
			["shinnosuke", "Vì có người cần giúp. Chính nghĩa không phải thứ để nói ra, mà là thứ để làm."],
		],
	},
	"4": {
		"start": [
			["krim", "Heart đang dựng vùng Don-yori cực mạnh trên xa lộ. Chỉ Type Formula mới xé toạc được nó."],
		],
		"key": [
			["krim", "DRIVE! TYPE FORMULA! Nhanh tới mức thế giới gần như đứng yên. Nhưng nộ tụt rất nhanh đấy!"],
		],
		"clear": [
			["pen", "{name}, cảm ơn vì đã không bỏ tôi lại. Kể cả sau chuyện ở Trái Đất Kiva."],
			["hero", "Cộng sự thì phải thế. Belt-san nói đúng mà."],
		],
	},
	"B": {
		"goal": [
			["heart", "Tim ta đang đập mạnh quá! Rider lạ mặt, cho ta xem cậu có gì!"],
			["hero", "Hitoppashiri tsukiaeyo! Chạy cùng tôi một vòng nào!"],
		],
		"clear": [
			["narrator", "Heart gục xuống, mỉm cười. Lõi của hắn tan ra, để lại một chiếc đai hình con mắt, bọc tinh thể tím: Ghost Driver."],
			["narrator", "Tridoron lao tới, hợp nhất với bộ giáp. DRIVE! TYPE TRIDORON!"],
			["heart", "Trận vừa rồi... vui thật. Ta mừng vì đã gặp các cậu."],
			["krim", "Nice drive, {name}. Cậu và Pen là một đội tuyệt vời."],
			["shinnosuke", "Cộng sự tin nhau, chính nghĩa đi cùng nhau. Chừng nào còn thế, cậu sẽ không lạc đường."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Drive sáng lại. Mười sáu thế giới! Chặng tiếp theo: Trái Đất Ghost, thế giới của những linh hồn."],
	["hero", "Linh hồn à... Pen, cậu có tin người đã mất vẫn có thể quay về không?"],
	["pen", "...Tôi tin cậu sẽ tìm được anh ấy."],
]
