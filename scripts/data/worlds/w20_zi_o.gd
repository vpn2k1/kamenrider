extends RefCounted
## Thế giới 20 · Kamen Rider Zi-O (2018) — "Vua của thời gian" · KẾT HỒI 2
## Echo Rider: Tokiwa Sougo (muốn thành một vị vua tốt). Hỗ trợ: Woz (người hầu từ năm 2068, cầm cuốn sách
## biết trước lịch sử, "Iwae!"). Quái: Kasshine, Another Rider của Time Jacker. Trùm: Another Zi-O.
## Màn B `clear`: Woz đọc sách, tiết lộ tên thật của Void là Rei, anh trai {name}. Pen xác nhận.

const WORLD := {
	"id": "zi_o",
	"year": 2018,
	"name": "Thế giới Zi-O",
	"motto": "Vua của thời gian",
	"rider": &"zi_o",
	"rider_name": "Zi-O",
	"driver_name": "Ziku Driver",
	"color": Color(1.0, 0.82, 0.3),
	"enemies": {
		"basic": {"name": "Kasshine", "color": Color(0.72, 0.68, 0.58), "sprite": "kasshine"},
		"fast": {"name": "Another Faiz", "color": Color(0.8, 0.32, 0.32), "sprite": "another_faiz"},
		"armored": {"name": "Another Build", "color": Color(0.38, 0.48, 0.65), "sprite": "another_build"},
	},
	"unlocks": [
		"Zi-O (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Grand Zi-O: Final Attack x1.5",
	],
	"stages": [
		{"name": "Tiệm đồng hồ Kujigoji", "goal": "Hộ tống: bảo vệ Sougo khỏi Kasshine của Time Jacker, giành lại Ziku Driver",
			"bg": "zi_o_1", "bg_theme": "clock_tower"},
		{"name": "Năm 2017 · Phố Touto", "form": &"build_armor", "form_name": "Build Armor",
			"bg": "zi_o_2", "bg_theme": "sky_wall"},
		{"name": "Năm 2016 · Bệnh viện Seito", "form": &"ex_aid_armor", "form_name": "Ex-Aid Armor",
			"bg": "zi_o_3", "bg_theme": "hospital"},
		{"name": "Năm 2068 · Tàn tích Ma Vương", "form": &"decade_armor", "form_name": "Decade Armor",
			"bg": "zi_o_4", "bg_theme": "city_night"},
		{"name": "Trùm: Another Zi-O", "bg": "zi_o_b", "bg_theme": "boss_purple",
			"boss": {"name": "Another Zi-O", "hp": 290.0, "damage": 17.0, "poise": 26.0, "speed": 78.0,
				"traits": ["fast"], "color": Color(0.82, 0.62, 0.3)}},
	],
}

## Zi-O: kế thừa sức mạnh Rider bằng Ride Watch. Build Armor (mũi khoan Drill Crusher Crusher) đâm nhanh và xa;
## Ex-Aid Armor (hai búa Gashacon Breaker Breaker) chậm, nện vỡ giáp; Ghost Armor nhẹ, lơ lửng lượn; Drive Armor tăng tốc
## thời gian; Gaim Armor song kiếm Daidaimaru; Wizard Armor bắn lửa; OOO Armor vuốt Tora, đòn kết làm choáng;
## Decade Armor (kiếm Ride Heisaber) chém mạnh. Armor của Rider Heisei đời đầu: Kuuga cân bằng đá lửa; Agito kiếm Flame
## Saber; Ryuki khạc lửa; Faiz nhanh, bắn Faiz Phone; Blade kiếm, đòn kết giật điện; Hibiki nặng, dùi trống; Kabuto nhanh;
## Den-O kiếm DenGasher; Kiva nhanh, choáng; W đá đôi; Fourze đấm tên lửa.
## Build / Ex-Aid / Decade Armor rơi ở thế giới này; các Armor còn lại thắng Rider đó ở thế giới phụ "Kho Ride Watch"
## (scripts/data/side_worlds.gd).
const RIDER := {
	"name": "Kamen Rider Zi-O",
	"tagline": "Kế thừa · khoác Armor của các Rider (Ride Watch ở thế giới phụ)",
	"base": &"zi_o",
	"order": [&"zi_o", &"build_armor", &"ex_aid_armor", &"decade_armor", &"kuuga_armor", &"agito_armor", &"ryuki_armor",
		&"faiz_armor", &"blade_armor", &"hibiki_armor", &"kabuto_armor", &"den_o_armor", &"kiva_armor", &"double_armor",
		&"ooo_armor", &"fourze_armor", &"wizard_armor", &"gaim_armor", &"drive_armor", &"ghost_armor"],
	"forms": {
		&"zi_o": {"name": "Zi-O", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "Time Break", "blade": {"look": "zikan_girade"},
			"skills": [
				{"name": "Zikan Girade", "type": "aim", "move": "dash", "anim": "slash", "fx": "ken_text",
					"color": Color(1.0, 0.35, 0.55)},
				{"name": "Zikan Jacorder", "type": "lock", "range": 260.0, "tags": [&"ranged"], "fx": "pointer",
					"summon": "clock", "color": Color(0.55, 0.85, 1.0)},
			]},
		&"build_armor": {"name": "Build Armor", "style": "lancer", "hp": 140.0, "armor": 15.0, "speed": 165.0,
			"jump": 1.25, "atk": 0.95, "poise": 5.0, "final": "Vortex Time Break", "blade": {"look": "drill_crusher", "style": "lancer"},
			"skills_from": [&"build", &"rabbit_tank"]},
		&"ex_aid_armor": {"name": "Ex-Aid Armor", "style": "heavy", "hp": 200.0, "armor": 52.0, "speed": 85.0,
			"jump": 0.9, "atk": 1.4, "poise": 18.0, "final": "Critical Time Break", "blade": {"look": "gashacon_breaker", "style": "heavy"},
			"skills_from": [&"ex_aid", &"action_gamer"]},
		&"ghost_armor": {"name": "Ghost Armor", "style": "lancer", "hp": 140.0, "armor": 15.0, "speed": 172.0,
			"jump": 1.3, "atk": 0.95, "poise": 5.0, "final": "Omega Time Break", "blade": {"look": "gangunsaber", "style": "lancer"},
			"fx": {"hit": "spark", "final": "ring", "glide": true, "color": Color(1.0, 0.55, 0.15)},
			"skills_from": [&"ghost", &"ore"]},
		&"drive_armor": {"name": "Drive Armor", "style": "brawler", "hp": 150.0, "armor": 20.0, "speed": 150.0,
			"jump": 1.1, "atk": 1.0, "poise": 6.0, "effect": "time", "time_call": "HISSATSU! FULL THROTTLE", "final": "Hissatsu Time Break",
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.25, 0.25)},
			"skills_from": [&"drive", &"speed"]},
		&"gaim_armor": {"name": "Gaim Armor", "style": "blade", "hp": 165.0, "armor": 30.0, "speed": 122.0,
			"jump": 1.0, "atk": 1.2, "poise": 11.0, "final": "Burai Time Break", "blade": {"look": "daidaimaru"},
			"attacks": {"slash": {"hits": 2, "damage": 3.5}},
			"fx": {"hit": "spark", "swing": "slash", "final": "ring", "color": Color(1.0, 0.55, 0.12)},
			"skills_from": [&"gaim", &"orange"]},
		&"wizard_armor": {"name": "Wizard Armor", "style": "gunner", "hp": 140.0, "armor": 14.0, "speed": 120.0,
			"jump": 1.15, "atk": 0.9, "poise": 4.0, "final": "Strike Time Break",
			"gun": {"look": "wizargun", "tags": [&"burn"], "damage": 6.0, "speed": 400.0, "cooldown": 0.35, "radius": 3.0,
				"color": Color(1.0, 0.35, 0.25), "life": 0.8},
			"fx": {"hit": "fire", "shot": "fire", "final": "fire", "color": Color(1.0, 0.3, 0.25)},
			"skills_from": [&"wizard", &"flame"]},
		&"ooo_armor": {"name": "OOO Armor", "style": "brawler", "hp": 168.0, "armor": 30.0, "speed": 126.0,
			"jump": 1.1, "atk": 1.1, "poise": 8.0, "final": "Scanning Time Break", "blade": {"look": "tora", "style": "lancer"},
			"attacks": {"final": {"hits": 3, "damage": 22.0, "tags": [&"stun"]}},
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.8, 0.25)},
			"skills_from": [&"ooo", &"tatoba"]},
		&"kuuga_armor": {"name": "Kuuga Armor", "style": "brawler", "hp": 170.0, "armor": 30.0, "speed": 125.0,
			"jump": 1.0, "atk": 1.05, "poise": 8.0, "final": "Mighty Time Break", "attacks": {"final": {"tags": [&"burn"]}},
			"fx": {"hit": "spark", "final": "fire", "color": Color(1.0, 0.45, 0.3)},
			"skills_from": [&"kuuga", &"mighty"]},
		&"agito_armor": {"name": "Agito Armor", "style": "blade", "hp": 155.0, "armor": 24.0, "speed": 134.0,
			"jump": 1.15, "atk": 1.15, "poise": 8.0, "final": "Rider Time Break", "blade": {"look": "flame_saber"},
			"fx": {"hit": "spark", "swing": "slash", "final": "ring", "color": Color(1.0, 0.8, 0.25)},
			"skills_from": [&"agito", &"ground"]},
		&"ryuki_armor": {"name": "Ryuki Armor", "style": "gunner", "hp": 145.0, "armor": 15.0, "speed": 118.0,
			"jump": 1.0, "atk": 1.0, "poise": 5.0, "final": "Dragon Time Break",
			"fx": {"hit": "fire", "shot": "fire", "final": "fire", "color": Color(1.0, 0.5, 0.15)},
			"gun": {"tags": [&"burn"], "damage": 9.0, "speed": 320.0, "cooldown": 0.5, "radius": 5.0, "color": Color(1.0, 0.5, 0.15),
				"life": 0.9},
			"skills_from": [&"ryuki", &"ryuki"]},
		&"faiz_armor": {"name": "Faiz Armor", "style": "brawler", "hp": 125.0, "armor": 15.0, "speed": 155.0,
			"jump": 1.05, "atk": 1.2, "poise": 5.0, "final": "Exceed Time Break",
			"gun": {"look": "faiz_phone", "damage": 3.0, "speed": 300.0, "cooldown": 0.45, "count": 3, "spread": 0.1,
				"radius": 2.5, "color": Color(1.0, 0.3, 0.3), "life": 0.8},
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.25, 0.25)},
			"skills_from": [&"faiz", &"faiz"]},
		&"blade_armor": {"name": "Blade Armor", "style": "blade", "hp": 160.0, "armor": 28.0, "speed": 128.0,
			"jump": 1.05, "atk": 1.15, "poise": 9.0, "final": "Lightning Time Break", "blade": {"look": "wizarsword"},
			"attacks": {"final": {"tags": [&"shock"]}}, "fx": {"hit": "spark", "swing": "slash", "final": "ring", "color": Color(0.45, 0.6, 1.0)},
			"skills_from": [&"blade", &"ace"]},
		&"hibiki_armor": {"name": "Hibiki Armor", "style": "heavy", "hp": 195.0, "armor": 48.0, "speed": 92.0,
			"jump": 0.9, "atk": 1.3, "poise": 16.0, "final": "Ongeki Time Break", "blade": {"look": "drumstick", "style": "heavy"},
			"attacks": {"final": {"hits": 6, "damage": 11.0}}, "fx": {"hit": "fire", "final": "fire", "color": Color(0.7, 0.45, 1.0)},
			"skills_from": [&"hibiki", &"hibiki"]},
		&"kabuto_armor": {"name": "Kabuto Armor", "style": "lancer", "hp": 140.0, "armor": 15.0, "speed": 170.0,
			"jump": 1.2, "atk": 0.95, "poise": 4.0, "final": "Rider Kick Time Break",
			"fx": {"hit": "spark", "final": "tachyon", "color": Color(1.0, 0.35, 0.35)},
			"skills_from": [&"kabuto", &"rider"]},
		&"den_o_armor": {"name": "Den-O Armor", "style": "blade", "hp": 165.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.15, "poise": 9.0, "final": "Full Charge Time Break", "blade": {"look": "dengasher_sword"},
			"fx": {"hit": "spark", "swing": "slash", "final": "ring", "color": Color(1.0, 0.3, 0.3)},
			"skills_from": [&"den_o", &"sword"]},
		&"kiva_armor": {"name": "Kiva Armor", "style": "lancer", "hp": 140.0, "armor": 15.0, "speed": 165.0,
			"jump": 1.3, "atk": 0.95, "poise": 5.0, "final": "Wake Up Time Break", "attacks": {"final": {"tags": [&"stun"]}},
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.3, 0.4)},
			"skills_from": [&"kiva", &"kiva"]},
		&"double_armor": {"name": "W Armor", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 135.0,
			"jump": 1.15, "atk": 1.05, "poise": 7.0, "final": "Maximum Time Break", "attacks": {"final": {"hits": 2, "damage": 30.0}},
			"fx": {"hit": "spark", "final": "ring", "color": Color(0.4, 0.95, 0.5)},
			"skills_from": [&"double", &"cyclone_joker"]},
		&"fourze_armor": {"name": "Fourze Armor", "style": "heavy", "hp": 190.0, "armor": 45.0, "speed": 95.0,
			"jump": 1.0, "atk": 1.3, "poise": 15.0, "final": "Limit Time Break", "attacks": {"final": {"hits": 4, "damage": 16.0}},
			"fx": {"hit": "fire", "final": "ring", "color": Color(1.0, 0.6, 0.25)},
			"skills_from": [&"fourze", &"base_states"]},
		&"decade_armor": {"name": "Decade Armor", "style": "blade", "hp": 170.0, "armor": 32.0, "speed": 128.0,
			"jump": 1.05, "atk": 1.25, "poise": 12.0, "final": "Attack Time Break", "blade": {"look": "ride_heisaber"},
			"skills_from": [&"decade", &"decade"]},
	},
	"lv5": {"name": "Grand Zi-O", "final_mult": 1.5},
}

## Giọng Ziku Driver (tools/gen_audio.py → audio/voice/zi_o_<khóa>.wav), xem VOICE của w01_kuuga.gd.
const VOICE := {
	"henshin": ["belt", "Rider Time! Kamen Rider Zi-O!"],
	"build_armor": ["belt", "Armor Time! Best Match! Build!"],
	"ex_aid_armor": ["belt", "Armor Time! Level Up! Ex-Aid!"],
	"ghost_armor": ["belt", "Armor Time! Kaigan! Ghost!"],
	"drive_armor": ["belt", "Armor Time! Drive! Drive!"],
	"gaim_armor": ["belt", "Armor Time! Soiya! Gaim!"],
	"wizard_armor": ["belt", "Armor Time! Pretty Good! Wizard!"],
	"ooo_armor": ["belt", "Armor Time! Taka! Tora! Batta! OOO!"],
	"decade_armor": ["belt", "Armor Time! Kamen Ride! Wow! Decade!"],
	"kuuga_armor": ["belt", "Armor Time! Kuuga!"],
	"agito_armor": ["belt", "Armor Time! Agito!"],
	"ryuki_armor": ["belt", "Armor Time! Advent! Ryuki!"],
	"faiz_armor": ["belt", "Armor Time! Complete! Faiz!"],
	"blade_armor": ["belt", "Armor Time! Turn Up! Blade!"],
	"hibiki_armor": ["belt", "Armor Time! Hibiki!"],
	"kabuto_armor": ["belt", "Armor Time! Change Beetle! Kabuto!"],
	"den_o_armor": ["belt", "Armor Time! Sword Form! Den-O!"],
	"kiva_armor": ["belt", "Armor Time! Kiva!"],
	"double_armor": ["belt", "Armor Time! Cyclone! Joker! Double!"],
	"fourze_armor": ["belt", "Armor Time! Three, two, one! Fourze!"],
	"final": ["belt", "Finish Time! Time Break!"],
}

const SPEAKERS := {
	"sougo": {"name": "TOKIWA SOUGO", "color": Color(1.0, 0.5, 0.75), "portrait": "sougo",
		"look": "hair=2a1e1a jacket=2a2a36 stripe=e040a0 eyes=3a2a20"},
	"woz": {"name": "WOZ", "color": Color(0.6, 0.85, 0.55), "portrait": "woz",
		"look": "hair=1a1a1e jacket=4a5a44 stripe=e8dcc0 eyes=2a2a2a"},
	"another_zi_o": {"name": "ANOTHER ZI-O", "color": Color(0.9, 0.7, 0.35), "portrait": "another_zi_o",
		"look": "base=grongi tint=a07a30"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Zi-O · Tiệm đồng hồ Kujigoji."],
			["sougo", "Tokiwa Sougo đây. Ước mơ của tôi là trở thành vua! Một vị vua tốt, làm cho mọi người hạnh phúc."],
			["woz", "Tôi là Woz, người hầu của Ma Vương tương lai. Ziku Driver bị Void khóa, còn Time Jacker muốn xóa sổ ngài ấy."],
			["woz", "Theo cuốn sách này, Driver chỉ tỉnh lại nếu Ma Vương của tôi bình an tới cuối ngày. Hãy bảo vệ ngài ấy."],
		],
		"goal": [
			["sougo", "Con Kasshine cầm giáo kia đeo Ziku Driver trên lưng! Tôi đỡ không nổi nữa rồi!"],
		],
		"key": [
			["narrator", "Ziku Driver xoay một vòng. Mặt đồng hồ khổng lồ hiện sau lưng {name}, chữ RIDER bay vào mặt nạ."],
			["woz", "Iwae! Hãy chúc mừng! Người kế thừa sức mạnh của các Rider, băng qua quá khứ và tương lai, đã ra đời!"],
			["hero", "Henshin!"],
		],
		"clear": [
			["pen", "Zi-O là form gốc: cân bằng. Ride Watch của các Rider khác nằm rải rác trong tay Another Rider, ở nhiều năm khác nhau."],
		],
	},
	"2": {
		"start": [
			["sougo", "Time Mazine đưa ta về năm 2017. Another Build đang phá phố, lũ Kasshine đi theo hắn."],
			["woz", "Build Ride Watch ở đây. Theo cuốn sách này, cậu sẽ nhặt được nó trong vòng... ba phút nữa."],
		],
		"key": [
			["woz", "Iwae! Zi-O Build Armor! Mũi khoan Drill Crusher Crusher, đâm nhanh và xa, chạy cũng nhanh hơn."],
		],
		"clear": [
			["sougo", "Tôi cũng đi gom sức mạnh của các Rider đấy. Không phải để cướp, mà để kế thừa họ. Cậu cũng vậy, đúng không?"],
		],
	},
	"3": {
		"start": [
			["woz", "Năm 2016. Another Build theo tới đây rồi. Giáp hắn dày, mũi khoan chỉ làm trầy thôi."],
			["pen", "Lại là bệnh viện! Ride Watch Ex-Aid chắc ở quanh đây. Level Up thôi!"],
		],
		"key": [
			["woz", "Iwae! Zi-O Ex-Aid Armor! Hai búa Gashacon Breaker Breaker. Chậm, nhưng mỗi nhát nện là vỡ giáp."],
		],
		"clear": [
			["sougo", "Theo sách của Woz, tôi sẽ thành một Ma Vương độc ác. Tôi không tin. Tương lai là thứ mình chọn lại mỗi ngày."],
		],
	},
	"4": {
		"start": [
			["woz", "Năm 2068, nơi tôi sinh ra. Another Faiz và Another Build cùng tấn công. Cần một sức mạnh đổi được theo đối thủ."],
		],
		"key": [
			["woz", "Iwae! Zi-O Decade Armor! Kiếm Ride Heisaber, sức mạnh của kẻ hủy diệt thế giới. Chém nhanh, chém mạnh."],
		],
		"clear": [
			["narrator", "Thời gian ngừng lại. Một bóng áo choàng đứng trên đỉnh tháp đổ nát."],
			["void", "Cuốn sách đó nói quá nhiều, Woz. Đừng đọc trang tiếp theo."],
			["woz", "...Hắn biết tên tôi. Và hắn sợ. Thú vị thật."],
		],
	},
	"B": {
		"start": [
			["woz", "{name}. Trang tiếp theo trong sách có tên cậu. Sau trận này, tôi sẽ đọc nó."],
		],
		"goal": [
			["another_zi_o", "Tokiwa Sougo! Thời gian không cần ngươi làm vua. Ta mới là Zi-O!"],
			["sougo", "Tôi sẽ trở thành vua. Nhưng không phải bằng cách xóa ai đó khỏi thời gian."],
		],
		"clear": [
			["narrator", "Another Zi-O vỡ tan. Sức mạnh Zi-O trở về trọn vẹn: Grand Zi-O! Giữa mảnh vỡ là Hiden Zero-One Driver bọc tinh thể tím."],
			["woz", "Theo cuốn sách này, tên thật của Chronos Void là Rei, anh trai của {name}. Vụ cháy mười năm trước đã kéo cậu ấy vào một dòng thời gian bị xóa."],
			["hero", "...Anh Rei? Không. Anh ấy đẩy tôi ra khỏi đám cháy mà. Pen... nói là không phải đi. Làm ơn."],
			["pen", "...Là thật. Tôi là Chrono Pass của anh ấy. Tôi biết từ đầu, và tôi sợ phải nói ra. Xin lỗi, {name}."],
			["sougo", "Tương lai viết trong sách không phải là tất cả. Cậu vẫn chọn được cách gặp lại anh mình."],
		],
	},
}

const WORLD_CLEAR := [
	["hero", "Anh hai đang đợi ở cuối chuỗi. Mười năm nay... anh ấy đã ở đó một mình sao?"],
	["pen", "Trái Đất Zi-O đã sáng lại. Chặng tiếp theo: Trái Đất Zero-One. ...Tôi vẫn ở đây, nếu cậu còn muốn."],
	["hero", "...Đi thôi, Pen."],
]
