extends RefCounted
## Thế giới 25 · Kamen Rider Gotchard (2023) — "Gia đình ta chọn"
## Echo Rider: Ichinose Houtarou (học sinh vui tính, mê nấu ăn, câu cửa miệng "Gotcha!", mơ người và Chemy sống chung).
## Hỗ trợ: Kudou Rinne (Kamen Rider Majade, học viện Giả kim), Hopper1 (Chemy châu chấu). Quái: Malgam, Dreadrooper.
## Trùm: Glion, kẻ muốn phủ vàng mọi thứ. Hồi 3: tình bạn, gia đình không cùng máu.
## Nguồn tra cứu: en/ja.wikipedia "Kamen Rider Gotchard" (form 2 lá Ride Chemy Card, chiêu "<form> Fever").

const WORLD := {
	"id": "gotchard",
	"year": 2023,
	"name": "Thế giới Gotchard",
	"motto": "Gia đình ta chọn",
	"rider": &"gotchard",
	"rider_name": "Gotchard",
	"driver_name": "Gotchard Driver",
	"color": Color(0.2, 0.9, 0.72),
	"enemies": {
		"basic": {"name": "Dreadrooper", "color": Color(0.42, 0.42, 0.52), "sprite": "dreadrooper"},
		"fast": {"name": "Malgam", "color": Color(0.7, 0.35, 0.8), "sprite": "malgam"},
		"armored": {"name": "Malgam giáp", "color": Color(0.5, 0.48, 0.55), "sprite": "malgam_armored"},
	},
	"unlocks": [
		"Steamhopper (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Rainbow Gotchard: Final Attack x1.5",
	],
	"stages": [
		{"name": "Quán Kitchen Ichinose", "goal": "Giải cứu Hopper1 khỏi Malgam, giành lại Gotchard Driver",
			"bg": "gotchard_1", "bg_theme": "suburb"},
		{"name": "Học viện Giả kim", "form": &"appare_skebow", "form_name": "Appare Skebow",
			"bg": "gotchard_2", "bg_theme": "academy"},
		{"name": "Bến tàu lúc hoàng hôn", "form": &"venom_mariner", "form_name": "Venom Mariner",
			"bg": "gotchard_3", "bg_theme": "coast"},
		{"name": "Phố đêm phủ vàng", "form": &"burning_gorilla", "form_name": "Burning Gorilla",
			"bg": "gotchard_4", "bg_theme": "city_night"},
		{"name": "Trùm: Glion", "bg": "gotchard_b", "bg_theme": "boss_gold",
			"boss": {"name": "Glion", "hp": 270.0, "damage": 16.0, "poise": 26.0, "speed": 70.0,
				"traits": [], "color": Color(0.95, 0.8, 0.3)}},
	],
}

## Gotchard: mỗi form ghép hai lá Ride Chemy Card. Steamhopper cân bằng, nhảy hơi cao; Appare Skebow lướt ván,
## chém kiểu samurai, nhanh mà nhẹ; Venom Mariner bắn ngư lôi từ vai (hai quả mỗi loạt); Burning Gorilla đấm lửa, phá giáp.
const RIDER := {
	"name": "Kamen Rider Gotchard",
	"tagline": "Cân bằng · Chemy ghép đôi: lướt ván, ngư lôi, khỉ đột lửa",
	"base": &"steamhopper",
	"order": [&"steamhopper", &"appare_skebow", &"venom_mariner", &"burning_gorilla"],
	"forms": {
		&"steamhopper": {"name": "Steamhopper", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.15, "atk": 1.05, "poise": 7.0, "final": "Steamhopper Fever"},
		&"appare_skebow": {"name": "Appare Skebow", "style": "lancer", "hp": 135.0, "armor": 10.0, "speed": 172.0,
			"jump": 1.25, "atk": 0.92, "poise": 4.0, "final": "Appare Skebow Fever"},
		&"venom_mariner": {"name": "Venom Mariner", "style": "gunner", "hp": 148.0, "armor": 18.0, "speed": 112.0,
			"jump": 1.0, "atk": 0.95, "poise": 6.0, "final": "Venom Mariner Fever",
			"gun": {"damage": 5.5, "speed": 320.0, "cooldown": 0.45, "count": 2, "spread": 0.18,
				"radius": 4.0, "color": Color(0.6, 0.95, 0.5)}},
		&"burning_gorilla": {"name": "Burning Gorilla", "style": "heavy", "hp": 205.0, "armor": 55.0, "speed": 85.0,
			"jump": 0.85, "atk": 1.42, "poise": 19.0, "final": "Burning Gorilla Fever"},
	},
	"lv5": {"name": "Rainbow Gotchard", "final_mult": 1.5},
}

const SPEAKERS := {
	"houtarou": {"name": "ICHINOSE HOUTAROU", "color": Color(1.0, 0.7, 0.3), "portrait": "houtarou",
		"look": "hair=2a1c14 jacket=e8a040 stripe=2a8a5a eyes=3a2a1e"},
	"rinne": {"name": "KUDOU RINNE", "color": Color(0.85, 0.75, 0.45), "portrait": "rinne",
		"look": "hair=1a1418 jacket=2a2a3a stripe=d8c070 eyes=3a2a3a long"},
	"hopper1": {"name": "HOPPER1", "color": Color(0.5, 0.9, 0.4), "portrait": "hopper1",
		"look": "base=kuuga tint=7ad05a"},
	"glion": {"name": "GLION", "color": Color(1.0, 0.85, 0.35), "portrait": "glion",
		"look": "base=daguba tint=d8b040"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Gotchard · Quán ăn Kitchen Ichinose."],
			["houtarou", "Ichinose Houtarou đây! Void cướp Gotchard Driver, còn đám Malgam bắt mất Hopper1 với Steamliner, hai Chemy bạn tôi."],
			["pen", "Gotchard Driver không nghe lệnh ai cả. Chemy phải tin cậu thì nó mới chạy. Cứu tụi nó trước đã!"],
		],
		"goal": [
			["houtarou", "Đám Dreadrooper kia đang nhốt Hopper1! Driver chắc cũng ở chỗ tụi nó."],
		],
		"key": [
			["hopper1", "Hopper! Hoppaa!"],
			["narrator", "Hopper1 nhảy vào tay {name}, hóa thành thẻ bài. Cùng Steamliner, hai lá Ride Chemy Card cắm vào Gotchard Driver."],
			["houtarou", "Tụi nó chọn cậu rồi! Cái cảm giác tim đập rộn ràng này đó... gọi là Gotcha!"],
			["hero", "Henshin!"],
		],
		"clear": [
			["pen", "Steamhopper là form gốc, nhảy cao hơn chút nhờ Hopper1. Chemy khác đang bị Malgam giữ, cứu con nào là thêm form con đó."],
		],
	},
	"2": {
		"start": [
			["rinne", "Kudou Rinne, học viện Giả kim. Malgam lẻn vào khuôn viên, học viên bị kẹt bên trong."],
			["houtarou", "Rinne là người giỏi nhất học viện. Còn tôi là người học chậm nhất. Hì hì."],
		],
		"key": [
			["houtarou", "Appare Skebow! Lướt ván, chém như samurai. Nhanh lắm, nhưng nhẹ ký nên đừng đứng chịu đòn."],
		],
		"clear": [
			["rinne", "Giả kim là biến đổi. Nhưng có những thứ không được phép đổi: bạn bè, gia đình."],
			["hero", "Gia đình tôi chỉ còn anh Rei. Mà giờ anh ấy lại đứng ở phía bên kia."],
		],
	},
	"3": {
		"start": [
			["pen", "Malgam dưới nước, Dreadrooper trên bến. Đứng gần là ăn đòn, phải có thứ bắn được từ xa."],
		],
		"key": [
			["houtarou", "Venom Mariner! Vai phóng ngư lôi, mỗi loạt hai quả. Chậm một chút, nhưng đứng xa mà nã thì khỏi lo."],
		],
		"clear": [
			["houtarou", "Chemy từng bị coi là công cụ. Giờ tụi nó là gia đình tôi, ồn ào lắm. Gia đình cứ thế to ra thôi."],
			["hero", "Vậy tính cả Pen nữa. Với mấy Echo Rider tôi gặp dọc đường."],
			["pen", "Ồ? Tôi được tính là gia đình à? Cậu nói rồi đấy nhé, cấm rút lại!"],
		],
	},
	"4": {
		"start": [
			["rinne", "Malgam giáp đang phá phố, cái gì chạm vào cũng hóa vàng. Glion đứng sau tất cả."],
		],
		"key": [
			["houtarou", "Burning Gorilla! Nắm đấm khỉ đột bốc lửa. Chậm, nhưng đấm đâu vỡ đó, giáp nào cũng nát."],
		],
		"clear": [
			["houtarou", "Kẻ địch hôm nay có thể thành bạn ngày mai. Anh cậu cũng vậy. Đừng coi anh ấy là thứ phải hạ gục."],
		],
	},
	"B": {
		"goal": [
			["glion", "Ồ, một viên đá thô. Để ta biến ngươi thành vàng, thứ duy nhất đẹp mãi không phai."],
			["hero", "Vàng thì không biết cười. Tôi thà làm đá thô."],
		],
		"clear": [
			["narrator", "Glion vỡ thành bụi vàng. Giữa làn bụi, một chiếc đai có cái miệng lớn bọc tinh thể tím: Henshin Belt Gavv."],
			["narrator", "Sức mạnh Gotchard trở về trọn vẹn. Rainbow Gotchard!"],
			["houtarou", "Gia đình không cần cùng máu, cũng chẳng cần cùng phe. Chỉ cần mình không buông tay. Gotcha!"],
			["hopper1", "Hopper!"],
			["pen", "Henshin Belt Gavv. Một cái đai biết ăn? Chắc thế giới tới toàn đồ ngọt quá!"],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Gotchard sáng rồi. Chặng tiếp theo: Trái Đất Gavv, nơi kẹo bánh cũng là vũ khí."],
	["hero", "Kẹo à... Hồi nhỏ anh Rei hay chia kẹo cho tôi. Lúc nào cũng chia phần to hơn."],
]
