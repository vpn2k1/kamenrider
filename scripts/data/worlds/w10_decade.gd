extends RefCounted
## Thế giới 10 · Kamen Rider Decade (2009) — "Kẻ du hành qua các thế giới"
## Mở đầu Hồi 2: {name} và Pen còn chấn động sau Trái Đất Kiva, niềm tin đang được hàn lại.
## Echo Rider: Kadoya Tsukasa (kiêu, chụp ảnh luôn bị méo). Hỗ trợ: Hikari Natsumi (tiệm ảnh Hikari).
## Quái: Dai-Shocker gom quái từ mọi thế giới. Trùm: Apollo Geist. Tsukasa nói Void từng là kẻ du hành,
## và có một dòng thời gian đã bị xóa.

const WORLD := {
	"id": "decade",
	"year": 2009,
	"name": "Thế giới Decade",
	"motto": "Kẻ du hành qua các thế giới",
	"rider": &"decade",
	"rider_name": "Decade",
	"driver_name": "Decadriver",
	"color": Color(0.95, 0.3, 0.65),
	"enemies": {
		"basic": {"name": "Chiến binh Dai-Shocker", "color": Color(0.45, 0.45, 0.55), "sprite": "dai_shocker"},
		"fast": {"name": "Okami Otoko", "color": Color(0.62, 0.52, 0.4), "sprite": "okami_otoko"},
		"armored": {"name": "Kanibubbler", "color": Color(0.85, 0.35, 0.3), "sprite": "kanibubbler"},
	},
	"unlocks": [
		"Decade (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Complete Form: Final Attack x1.5",
	],
	"stages": [
		{"name": "Tiệm ảnh Hikari", "goal": "Hạ lính Dai-Shocker, giành lại Decadriver và xấp thẻ đã mất màu",
			"bg": "decade_1", "bg_theme": "suburb"},
		{"name": "Con phố đang tan biến", "form": &"slash", "form_name": "Attack Ride: Slash",
			"bg": "decade_2", "bg_theme": "city_dusk"},
		{"name": "Căn cứ Dai-Shocker", "form": &"blast", "form_name": "Attack Ride: Blast",
			"bg": "decade_3", "bg_theme": "industrial"},
		{"name": "Bức màn cực quang", "form": &"kabuto", "form_name": "Kamen Ride: Kabuto",
			"bg": "decade_4", "bg_theme": "dreamscape"},
		{"name": "Trùm: Apollo Geist", "bg": "decade_b", "bg_theme": "boss_red",
			"boss": {"name": "Apollo Geist", "hp": 270.0, "damage": 16.0, "poise": 28.0, "speed": 65.0,
				"traits": ["armored"], "color": Color(0.95, 0.9, 0.8)}},
	],
}

## Decade: đổi thẻ. Slash (kiếm Ride Booker, mỗi nhát nhân bóng) chém nặng phá giáp; Blast (Ride Booker dạng súng)
## bắn chùm đạn từ xa. Kamen Ride biến thành chính Rider của 9 thế giới trước (dùng lại hình của Rider đó), đánh theo
## kiểu của Rider ấy: Kuuga cân bằng, đá lửa; Agito nhảy cao; Ryuki khạc lửa Dragclaw; Faiz nhanh, bắn Faiz Phone;
## Blade cầm sẵn Blay Rouzer; Hibiki nặng, trống lửa; Den-O chém DenGasher; Kiva nhanh, choáng; Kabuto Clock Up;
## W đá đôi; OOO đá ba nhịp; Fourze khoan tên lửa; Wizard đá lửa; Gaim đại đao; Drive Handle-Ken; Ghost lượn;
## Ex-Aid búa, nhảy cao; Build đồ thị kẹp quái; Zi-O Zikan Girade.
const RIDER := {
	"name": "Kamen Rider Decade",
	"tagline": "Đổi thẻ · kiếm nhân bóng, súng chùm, Kamen Ride thành các Rider khác (thẻ ở thế giới phụ)",
	"base": &"decade",
	# Slash / Blast / Kabuto rơi ở thế giới này; các Kamen Ride còn lại thắng Rider đó ở thế giới phụ "Hành trình thẻ
	# Kamen Ride" (scripts/data/side_worlds.gd).
	"order": [&"decade", &"slash", &"blast", &"kabuto", &"kuuga", &"agito", &"ryuki", &"faiz", &"blade", &"hibiki",
		&"den_o", &"kiva", &"double", &"ooo", &"fourze", &"wizard", &"gaim", &"drive", &"ghost", &"ex_aid", &"build",
		&"zi_o"],
	"forms": {
		&"decade": {"name": "Decade", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "Dimension Kick", "attacks": {"final": {"hits": 3, "damage": 22.0}},
			"skills": [
				{"name": "Attack Ride: Illusion", "type": "buff", "buff": {"clones": 2, "time": 5.0}, "fx": "cards",
					"color": Color(0.95, 0.3, 0.65)},
				{"name": "Attack Ride: Invisible", "type": "buff", "buff": {"invis": true, "phase": true, "time": 3.0},
					"fx": "feather", "color": Color(0.75, 0.75, 0.95)},
			]},
		&"slash": {"name": "Attack Ride: Slash", "style": "blade", "hp": 165.0, "armor": 28.0, "speed": 120.0,
			"jump": 1.0, "atk": 1.25, "poise": 11.0, "final": "Dimension Slash", "attacks": {"slash": {"hits": 2, "damage": 3.5}},
			"skills": [
				{"name": "Slash", "type": "aim", "hits": 3, "fx": "slash", "anim": "slash", "color": Color(1.0, 0.4, 0.7)},
				{"name": "Dimension Card Wall", "type": "counter", "fx": "cards", "summon": "shield",
					"color": Color(0.9, 0.85, 1.0)},
			]},
		&"blast": {"name": "Attack Ride: Blast", "style": "gunner", "hp": 140.0, "armor": 12.0, "speed": 120.0,
			"jump": 1.0, "atk": 0.9, "poise": 5.0, "final": "Dimension Blast",
			"gun": {"look": "booker_gun", "damage": 3.5, "speed": 380.0, "cooldown": 0.4, "count": 3, "spread": 0.12, "radius": 3.0,
				"color": Color(1.0, 0.4, 0.75), "life": 0.8},
			"skills": [
				{"name": "Blast", "type": "aim", "move": "spread",
					"shot": {"style": "bolt", "count": 5, "spread": 0.16, "speed": 380.0}, "fx": "spark",
					"color": Color(1.0, 0.4, 0.75)},
				{"name": "Blast Homing", "type": "lock_multi", "targets": 3, "range": 260.0, "tags": [&"ranged"], "fx": "cards",
					"color": Color(0.55, 0.85, 1.0)},
			]},
		&"kuuga": {"name": "Kamen Ride: Kuuga", "style": "brawler", "hp": 170.0, "armor": 30.0, "speed": 125.0,
			"jump": 1.0, "atk": 1.05, "poise": 8.0, "final": "Mighty Kick", "attacks": {"final": {"tags": [&"burn"]}},
			"fx": {"hit": "spark", "final": "fire", "color": Color(1.0, 0.45, 0.3)},
			"skills_from": [&"kuuga", &"mighty"]},
		&"agito": {"name": "Kamen Ride: Agito", "style": "brawler", "hp": 150.0, "armor": 22.0, "speed": 138.0,
			"jump": 1.2, "atk": 1.05, "poise": 6.0, "final": "Rider Kick",
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.8, 0.25)},
			"skills_from": [&"agito", &"ground"]},
		&"ryuki": {"name": "Kamen Ride: Ryuki", "style": "gunner", "hp": 145.0, "armor": 15.0, "speed": 118.0,
			"jump": 1.0, "atk": 1.0, "poise": 5.0, "final": "Dragon Rider Kick",
			"fx": {"hit": "fire", "shot": "fire", "final": "fire", "color": Color(1.0, 0.5, 0.15)},
			"gun": {"tags": [&"burn"], "damage": 9.0, "speed": 320.0, "cooldown": 0.5, "radius": 5.0, "color": Color(1.0, 0.5, 0.15),
				"life": 0.9},
			"skills_from": [&"ryuki", &"ryuki"]},
		&"faiz": {"name": "Kamen Ride: Faiz", "style": "brawler", "hp": 125.0, "armor": 15.0, "speed": 155.0,
			"jump": 1.05, "atk": 1.2, "poise": 5.0, "final": "Crimson Smash",
			"gun": {"look": "faiz_phone", "damage": 3.0, "speed": 300.0, "cooldown": 0.45, "count": 3, "spread": 0.1,
				"radius": 2.5, "color": Color(1.0, 0.3, 0.3), "life": 0.8},
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.25, 0.25)},
			"skills_from": [&"faiz", &"faiz"]},
		&"blade": {"name": "Kamen Ride: Blade", "style": "blade", "hp": 160.0, "armor": 28.0, "speed": 128.0,
			"jump": 1.05, "atk": 1.1, "poise": 8.0, "final": "Lightning Blast", "armed": true,
			"attacks": {"final": {"tags": [&"shock"]}}, "fx": {"hit": "spark", "final": "ring", "color": Color(0.45, 0.6, 1.0)},
			"skills_from": [&"blade", &"ace"]},
		&"hibiki": {"name": "Kamen Ride: Hibiki", "style": "heavy", "hp": 195.0, "armor": 48.0, "speed": 92.0,
			"jump": 0.9, "atk": 1.3, "poise": 16.0, "final": "Kaen Renda no Kata", "attacks": {"final": {"hits": 6, "damage": 11.0}},
			"fx": {"hit": "fire", "final": "fire", "color": Color(0.7, 0.45, 1.0)},
			"skills_from": [&"hibiki", &"hibiki"]},
		&"den_o": {"name": "Kamen Ride: Den-O", "style": "blade", "hp": 165.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.15, "poise": 9.0, "final": "Extreme Slash", "blade": {"look": "dengasher_sword"},
			"fx": {"hit": "spark", "swing": "slash", "final": "ring", "color": Color(1.0, 0.3, 0.3)},
			"skills_from": [&"den_o", &"sword"]},
		&"kiva": {"name": "Kamen Ride: Kiva", "style": "lancer", "hp": 140.0, "armor": 15.0, "speed": 165.0,
			"jump": 1.3, "atk": 0.95, "poise": 5.0, "final": "Darkness Moon Break", "attacks": {"final": {"tags": [&"stun"]}},
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.3, 0.4)},
			"skills_from": [&"kiva", &"kiva"]},
		&"double": {"name": "Kamen Ride: W", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.1, "atk": 1.05, "poise": 7.0, "final": "Joker Extreme", "attacks": {"final": {"hits": 2, "damage": 30.0}},
			"fx": {"hit": "spark", "final": "ring", "color": Color(0.4, 0.95, 0.5)},
			"skills_from": [&"double", &"cyclone_joker"]},
		&"ooo": {"name": "Kamen Ride: OOO", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.2, "atk": 1.05, "poise": 7.0, "final": "Tatoba Kick", "attacks": {"final": {"hits": 3, "damage": 24.0}},
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.4, 0.3)},
			"skills_from": [&"ooo", &"tatoba"]},
		&"fourze": {"name": "Kamen Ride: Fourze", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.1, "atk": 1.05, "poise": 7.0, "final": "Rider Rocket Drill Kick",
			"attacks": {"final": {"hits": 4, "damage": 16.0}},
			"skills_from": [&"fourze", &"base_states"]},
		&"wizard": {"name": "Kamen Ride: Wizard", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.1, "atk": 1.05, "poise": 7.0, "final": "Strike Wizard",
			"attacks": {"kick": {"tags": [&"burn"]}, "final": {"tags": [&"burn"]}},
			"fx": {"hit": "fire", "final": "fire", "color": Color(1.0, 0.35, 0.3)},
			"skills_from": [&"wizard", &"flame"]},
		&"gaim": {"name": "Kamen Ride: Gaim", "style": "blade", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.1, "poise": 8.0, "final": "Naginata Musou Slicer", "blade": {"look": "daidaimaru"},
			"attacks": {"final": {"tags": [&"stun"]}},
			"skills_from": [&"gaim", &"orange"]},
		&"drive": {"name": "Kamen Ride: Drive", "style": "brawler", "hp": 155.0, "armor": 22.0, "speed": 140.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "SpeeDrop", "blade": {"look": "handle_ken"},
			"attacks": {"final": {"hits": 3, "damage": 20.0}},
			"skills_from": [&"drive", &"speed"]},
		&"ghost": {"name": "Kamen Ride: Ghost", "style": "brawler", "hp": 158.0, "armor": 24.0, "speed": 132.0,
			"jump": 1.15, "atk": 1.05, "poise": 7.0, "final": "Omega Drive", "blade": {"look": "gangunsaber"},
			"fx": {"hit": "spark", "swing": "slash", "final": "fire", "glide": true, "color": Color(1.0, 0.55, 0.15)},
			"skills_from": [&"ghost", &"ore"]},
		&"ex_aid": {"name": "Kamen Ride: Ex-Aid", "style": "brawler", "hp": 155.0, "armor": 22.0, "speed": 135.0,
			"jump": 1.25, "atk": 1.05, "poise": 7.0, "final": "Mighty Critical Strike", "blade": {"look": "gashacon_breaker"},
			"attacks": {"final": {"hits": 3, "damage": 22.0}},
			"skills_from": [&"ex_aid", &"action_gamer"]},
		&"build": {"name": "Kamen Ride: Build", "style": "brawler", "hp": 160.0, "armor": 28.0, "speed": 132.0,
			"jump": 1.3, "atk": 1.05, "poise": 7.0, "final": "Vortex Finish", "blade": {"look": "drill_crusher"},
			"attacks": {"final": {"tags": [&"stun"]}},
			"skills_from": [&"build", &"rabbit_tank"]},
		&"zi_o": {"name": "Kamen Ride: Zi-O", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "Time Break", "blade": {"look": "zikan_girade"},
			"skills_from": [&"zi_o", &"zi_o"]},
		&"kabuto": {"name": "Kamen Ride: Kabuto", "style": "lancer", "hp": 130.0, "armor": 10.0, "speed": 165.0,
			"jump": 1.2, "atk": 0.95, "poise": 4.0, "effect": "time", "final": "Rider Kick",
			"skills_from": [&"kabuto", &"rider"]},
	},
	"lv5": {"name": "Complete Form", "final_mult": 1.5},
	"final_fx": {"intro": "cards"},
}

## Giọng đai / tiếng hô (tools/gen_audio.py → audio/voice/<rider>_<khóa>.wav): "henshin" lúc biến thân, khóa = id form
## lúc đổi sang form đó, "final" lúc Final Attack. Mỗi dòng: [kiểu giọng, câu]
## (kiểu giọng: belt / belt_deep / belt_bright / kivat / hero, xem VOICES trong gen_audio.py).
const VOICE := {
	"henshin": ["belt", "Kamen Ride. Decade!"],
	"slash": ["belt", "Attack Ride. Slash!"],
	"blast": ["belt", "Attack Ride. Blast!"],
	"kuuga": ["belt", "Kamen Ride. Kuuga!"],
	"agito": ["belt", "Kamen Ride. Agito!"],
	"ryuki": ["belt", "Kamen Ride. Ryuki! Attack Ride. Strike Vent!"],
	"faiz": ["belt", "Kamen Ride. Faiz!"],
	"blade": ["belt", "Kamen Ride. Blade!"],
	"hibiki": ["belt", "Kamen Ride. Hibiki!"],
	"den_o": ["belt", "Kamen Ride. Den-O!"],
	"kiva": ["belt", "Kamen Ride. Kiva!"],
	"double": ["belt", "Kamen Ride. Double!"],
	"ooo": ["belt", "Kamen Ride. OOO!"],
	"fourze": ["belt", "Kamen Ride. Fourze!"],
	"wizard": ["belt", "Kamen Ride. Wizard!"],
	"gaim": ["belt", "Kamen Ride. Gaim!"],
	"drive": ["belt", "Kamen Ride. Drive!"],
	"ghost": ["belt", "Kamen Ride. Ghost!"],
	"ex_aid": ["belt", "Kamen Ride. Ex-Aid!"],
	"build": ["belt", "Kamen Ride. Build!"],
	"zi_o": ["belt", "Kamen Ride. Zi-O!"],
	"kabuto": ["belt", "Kamen Ride. Kabuto! Attack Ride. Clock Up!"],
	"final": ["belt", "Final Attack Ride. De. De. De. Decade!"],
}

const SPEAKERS := {
	"tsukasa": {"name": "KADOYA TSUKASA", "color": Color(0.95, 0.35, 0.65), "portrait": "tsukasa",
		"look": "hair=2a2020 jacket=26262e stripe=e0409a eyes=3a2a22"},
	"natsumi": {"name": "HIKARI NATSUMI", "color": Color(1.0, 0.75, 0.82), "portrait": "natsumi",
		"look": "hair=3a2418 jacket=f0e6dc stripe=c85a78 eyes=4a3222 long"},
	"apollo_geist": {"name": "APOLLO GEIST", "color": Color(0.95, 0.85, 0.6), "portrait": "apollo_geist",
		"look": "base=daguba tint=e8dcc4"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Decade · Tiệm ảnh Hikari, nơi tấm phông nền đổi theo từng thế giới."],
			["hero", "Pen... Void biết tên tôi. Còn cậu từng là Chrono Pass của hắn. Giờ tôi nên tin cậu tới đâu?"],
			["pen", "Tôi không xin cậu tin ngay. Chỉ xin đi tiếp. Decadriver bị phong ấn, thẻ Rider trong đó mất hết màu."],
			["tsukasa", "Kadoya Tsukasa, một Kamen Rider đi ngang qua. Thẻ chỉ có màu lại khi cậu hiểu thế giới này. Đánh đi, rồi nhìn cho kỹ."],
		],
		"goal": [
			["tsukasa", "Tên cầm đầu đám Dai-Shocker kia đeo Decadriver như chiến lợi phẩm. Chướng mắt thật."],
		],
		"key": [
			["hero", "Henshin!"],
			["narrator", "KAMEN RIDE: DECADE! Những tấm bảng ảo cắm vào mặt nạ, bộ giáp xám bừng lên màu hồng đỏ."],
		],
		"clear": [
			["tsukasa", "Cái thẻ biết nói của cậu mở được cổng sang thế giới khác, đúng không? Giống hệt sức mạnh của tôi."],
			["pen", "...Decade là form gốc: tay không, cân bằng. Dimension Kick xuyên qua hàng thẻ. Thẻ Attack Ride còn nằm trong tay lũ Dai-Shocker."],
		],
	},
	"2": {
		"start": [
			["natsumi", "Hikari Natsumi, cháu ông chủ tiệm ảnh. Các thế giới đang nhập vào nhau, con phố này sắp biến mất! Thẻ Slash ở trong đám lính kia."],
		],
		"key": [
			["tsukasa", "ATTACK RIDE: SLASH! Bấm Chém, Ride Booker một nhát thành hai. Nhát cuối phá được giáp."],
		],
		"clear": [
			["natsumi", "Cậu với cô bạn trong thẻ giận nhau à? Tsukasa từng bị gọi là kẻ hủy diệt thế giới, tôi vẫn đi cùng cậu ta đấy thôi."],
		],
	},
	"3": {
		"start": [
			["tsukasa", "Dai-Shocker gom quái vật từ mọi thế giới. Tôi từng ngồi ghế thủ lĩnh của chúng. Chuyện dài, đừng hỏi."],
			["pen", "Kaijin rải khắp căn cứ, đánh gần không xuể. Thẻ Attack Ride Blast đang ở đâu đó quanh đây!"],
		],
		"key": [
			["tsukasa", "ATTACK RIDE: BLAST! Giữ nút Bắn, Ride Booker hóa súng bắn cả chùm đạn. Giáp mỏng đi, đừng để chúng áp sát."],
		],
		"clear": [
			["pen", "{name}... tôi xin lỗi. Tôi không nhớ hết chuyện hồi ở với Void. Có những mảng ký ức trống trơn."],
			["hero", "Vậy thì mình cùng tìm. Nhưng lần sau có chuyện gì, nói với tôi trước. Hứa nhé?"],
		],
	},
	"4": {
		"start": [
			["tsukasa", "Tôi vừa chụp một kẻ áo choàng đi qua bức màn này. Ảnh méo y như ảnh của tôi. Void từng là kẻ du hành, như tôi, như cậu."],
			["pen", "Trong đám quái có thẻ Kamen Ride của Kabuto. Cậu đi qua thế giới đó rồi, thẻ sẽ nhận cậu!"],
		],
		"key": [
			["tsukasa", "KAMEN RIDE: KABUTO! ATTACK RIDE: CLOCK UP! Mọi thứ chậm lại quanh cậu, nhưng nộ tụt rất nhanh."],
		],
		"clear": [
			["hero", "Void từng là kẻ du hành... Vậy thế giới của hắn ở đâu?"],
			["tsukasa", "Không còn nữa. Có một dòng thời gian đã bị xóa. Không phải bị phá hủy, mà như chưa từng tồn tại."],
			["pen", "......Tôi hứa sẽ nói, {name}. Khi nào tôi nhớ ra."],
		],
	},
	"B": {
		"goal": [
			["apollo_geist", "Ta là Apollo Geist của Dai-Shocker. Sinh mạng một Rider đi mượn đai sẽ cho ta sống thêm một ngày."],
			["hero", "Tôi chỉ là một Kamen Rider đi ngang qua. Nhớ lấy!"],
			["tsukasa", "Này. Câu đó là của tôi."],
		],
		"clear": [
			["narrator", "Apollo Geist nổ tung. Giữa khói lửa là một chiếc đai hai khe cắm, bọc trong tinh thể tím: Double Driver."],
			["narrator", "Mọi thẻ trong Decadriver sáng lại cùng lúc. Complete Form!"],
			["tsukasa", "Tôi đi qua các thế giới để tìm chỗ của mình. Cậu đi để tìm một người. Đừng để lạc nhau đấy."],
			["pen", "Double Driver. Thế giới kế tiếp có một thám tử... và một thư viện biết mọi thứ trên Trái Đất."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Decade sáng lại. Mười thế giới! Chặng tiếp theo: Trái Đất W, thành phố gió Fuuto."],
	["hero", "Một dòng thời gian bị xóa... Pen, nếu ở Fuuto có câu trả lời, mình cùng nghe nhé."],
	["pen", "...Ừ. Cùng nghe."],
]
