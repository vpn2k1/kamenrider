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
		"basic": {"name": "Chiến binh Dai-Shocker", "color": Color(0.45, 0.45, 0.55)},
		"fast": {"name": "Okami Otoko", "color": Color(0.62, 0.52, 0.4)},
		"armored": {"name": "Kanibubbler", "color": Color(0.85, 0.35, 0.3)},
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
## bắn chùm đạn từ xa; Kamen Ride Kabuto dùng Attack Ride Clock Up, tăng tốc thời gian nhưng nộ tụt nhanh.
const RIDER := {
	"name": "Kamen Rider Decade",
	"tagline": "Đổi thẻ · kiếm nhân bóng, súng chùm, Clock Up",
	"base": &"decade",
	"order": [&"decade", &"slash", &"blast", &"kabuto"],
	"forms": {
		&"decade": {"name": "Decade", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "Dimension Kick"},
		&"slash": {"name": "Attack Ride: Slash", "style": "blade", "hp": 165.0, "armor": 28.0, "speed": 120.0,
			"jump": 1.0, "atk": 1.25, "poise": 11.0, "final": "Dimension Slash"},
		&"blast": {"name": "Attack Ride: Blast", "style": "gunner", "hp": 140.0, "armor": 12.0, "speed": 120.0,
			"jump": 1.0, "atk": 0.9, "poise": 5.0, "final": "Dimension Blast",
			"gun": {"damage": 3.5, "speed": 380.0, "cooldown": 0.4, "count": 3, "spread": 0.12, "radius": 3.0,
				"color": Color(1.0, 0.4, 0.75), "life": 0.8}},
		&"kabuto": {"name": "Kamen Ride: Kabuto", "style": "lancer", "hp": 130.0, "armor": 10.0, "speed": 165.0,
			"jump": 1.2, "atk": 0.95, "poise": 4.0, "effect": "time", "final": "Rider Kick"},
	},
	"lv5": {"name": "Complete Form", "final_mult": 1.5},
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
			["pen", "...Decade là form gốc: tay không, cân bằng. Thẻ Attack Ride còn nằm trong tay lũ Dai-Shocker."],
		],
	},
	"2": {
		"start": [
			["natsumi", "Hikari Natsumi, cháu ông chủ tiệm ảnh. Các thế giới đang nhập vào nhau, con phố này sắp biến mất! Thẻ Slash ở trong đám lính kia."],
		],
		"key": [
			["tsukasa", "ATTACK RIDE: SLASH! Một nhát thành ba. Chậm hơn chút, nhưng nhát cuối phá được giáp."],
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
			["tsukasa", "ATTACK RIDE: BLAST! Ride Booker hóa súng, một phát ra cả chùm đạn. Giáp mỏng đi, đừng để chúng áp sát."],
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
