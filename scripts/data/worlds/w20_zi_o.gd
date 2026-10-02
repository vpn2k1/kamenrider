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
## Ex-Aid Armor (hai búa Gashacon Breaker Breaker) chậm, nện vỡ giáp; Decade Armor (kiếm Ride Heisaber) chém mạnh.
const RIDER := {
	"name": "Kamen Rider Zi-O",
	"tagline": "Kế thừa · khoác Armor của Build, Ex-Aid, Decade",
	"base": &"zi_o",
	"order": [&"zi_o", &"build_armor", &"ex_aid_armor", &"decade_armor"],
	"forms": {
		&"zi_o": {"name": "Zi-O", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "Time Break"},
		&"build_armor": {"name": "Build Armor", "style": "lancer", "hp": 140.0, "armor": 15.0, "speed": 165.0,
			"jump": 1.25, "atk": 0.95, "poise": 5.0, "final": "Vortex Time Break"},
		&"ex_aid_armor": {"name": "Ex-Aid Armor", "style": "heavy", "hp": 200.0, "armor": 52.0, "speed": 85.0,
			"jump": 0.9, "atk": 1.4, "poise": 18.0, "final": "Critical Time Break"},
		&"decade_armor": {"name": "Decade Armor", "style": "blade", "hp": 170.0, "armor": 32.0, "speed": 128.0,
			"jump": 1.05, "atk": 1.25, "poise": 12.0, "final": "Attack Time Break"},
	},
	"lv5": {"name": "Grand Zi-O", "final_mult": 1.5},
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
