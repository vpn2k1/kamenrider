extends RefCounted
## Thế giới 24 · Kamen Rider Geats (2022) — "Trò chơi của những điều ước"
## Echo Rider: Ukiyo Ace (nhà vô địch Desire Grand Prix, tự tin, đi tìm mẹ). Hỗ trợ: Tsumuri (người dẫn đường DGP).
## Quái: Jyamato (Pawn / Knight / Rook). Trùm: Kamen Rider Glare (Game Master, Vision Driver).
## Hồi 3: {name} viết lên Desire Card điều ước duy nhất của mình: đưa anh Rei về nhà.

const WORLD := {
	"id": "geats",
	"year": 2022,
	"name": "Thế giới Geats",
	"motto": "Trò chơi của những điều ước",
	"rider": &"geats",
	"rider_name": "Geats",
	"driver_name": "Desire Driver",
	"color": Color(1.0, 0.92, 0.84),
	"enemies": {
		"basic": {"name": "Pawn Jyamato", "color": Color(0.45, 0.62, 0.32), "sprite": "pawn_jyamato"},
		"fast": {"name": "Knight Jyamato", "color": Color(0.55, 0.38, 0.8), "sprite": "knight_jyamato"},
		"armored": {"name": "Rook Jyamato", "color": Color(0.5, 0.52, 0.42), "sprite": "rook_jyamato"},
	},
	"unlocks": [
		"Magnum Form (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Geats IX: Final Attack x1.5",
	],
	"stages": [
		{"name": "Khu Jyamato: vòng loại", "goal": "Vòng loại Desire Grand Prix: hạ Jyamato, thắng Desire Driver",
			"bg": "geats_1", "bg_theme": "city_day"},
		{"name": "Vòng hai: đường đua đêm", "form": &"boost", "form_name": "Boost Form",
			"bg": "geats_2", "bg_theme": "race_city"},
		{"name": "Vòng ba: công trường", "form": &"powered_builder", "form_name": "Powered Builder Form",
			"bg": "geats_3", "bg_theme": "industrial"},
		{"name": "Sân khấu chung kết", "form": &"magnum_boost", "form_name": "Magnum Boost Form",
			"bg": "geats_4", "bg_theme": "arena"},
		{"name": "Trùm: Kamen Rider Glare", "bg": "geats_b", "bg_theme": "boss_purple",
			"boss": {"name": "Kamen Rider Glare", "hp": 250.0, "damage": 16.0, "poise": 24.0, "speed": 82.0,
				"traits": ["fast"], "color": Color(0.5, 0.38, 0.78)}},
	],
}

## Geats: form gốc là xạ thủ (Magnum Shooter 40X). Boost nhanh, tăng tốc thời gian nhưng ngốn nộ; Powered Builder
## là cả cỗ máy xây dựng, chậm mà phá giáp; Magnum Boost ghép hai buckle: đấm đá và bắn, cân bằng mà mạnh.
const RIDER := {
	"name": "Kamen Rider Geats",
	"tagline": "Xạ thủ · form tăng tốc thời gian, form máy xây dựng",
	"base": &"magnum",
	"order": [&"magnum", &"boost", &"powered_builder", &"magnum_boost"],
	"forms": {
		&"magnum": {"name": "Magnum Form", "style": "gunner", "hp": 150.0, "armor": 20.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.0, "poise": 6.0, "final": "Magnum Strike",
			"gun": {"damage": 7.5, "speed": 440.0, "cooldown": 0.28, "color": Color(1.0, 0.95, 0.85)}},
		&"boost": {"name": "Boost Form", "style": "lancer", "hp": 135.0, "armor": 10.0, "speed": 175.0,
			"jump": 1.3, "atk": 0.95, "poise": 4.0, "effect": "time", "final": "Boost Grand Strike"},
		&"powered_builder": {"name": "Powered Builder Form", "style": "heavy", "hp": 205.0, "armor": 58.0,
			"speed": 82.0, "jump": 0.8, "atk": 1.42, "poise": 20.0, "final": "Cú giáng Powered Builder"},
		&"magnum_boost": {"name": "Magnum Boost Form", "style": "brawler", "hp": 165.0, "armor": 28.0,
			"speed": 145.0, "jump": 1.15, "atk": 1.2, "poise": 9.0, "final": "Magnum Boost Grand Victory",
			"gun": {"damage": 7.0, "speed": 420.0, "cooldown": 0.35, "color": Color(1.0, 0.7, 0.45)}},
	},
	"lv5": {"name": "Geats IX", "final_mult": 1.5},
}

const SPEAKERS := {
	"ace": {"name": "UKIYO ACE", "color": Color(1.0, 0.85, 0.7), "portrait": "ace",
		"look": "hair=1c1818 jacket=f2ece2 stripe=c0303a eyes=3a2622"},
	"tsumuri": {"name": "TSUMURI", "color": Color(0.55, 0.8, 1.0), "portrait": "tsumuri",
		"look": "hair=3a2a24 jacket=f4eef4 stripe=6aa8d8 eyes=4a3434 long"},
	"glare": {"name": "GLARE", "color": Color(0.7, 0.55, 1.0), "portrait": "glare",
		"look": "base=kuuga tint=6a4aa0"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Geats · Khu Jyamato, giữa một ván Desire Grand Prix."],
			["tsumuri", "Chào mừng tới Desire Grand Prix! Tôi là Tsumuri, người dẫn đường. Người thắng cuộc sẽ được biến điều ước thành thật."],
			["ace", "Ukiyo Ace, nhà vô địch bất bại. Void cuỗm Desire Driver của tôi, khóa nó làm phần thưởng vòng loại. Muốn lấy thì phải thắng."],
		],
		"goal": [
			["tsumuri", "Vòng loại: hạ nhóm Jyamato kia. Người trụ lại sẽ nhận Desire Driver."],
		],
		"key": [
			["narrator", "Desire Driver khóa quanh eo {name}. Magnum Raise Buckle cắm vào, trên tay hiện ra khẩu súng trắng Magnum Shooter 40X."],
			["ace", "Không tệ, tay mới. Nhớ lấy: trong trò chơi này, ai có điều ước mạnh nhất thì trụ lại lâu nhất."],
			["hero", "Henshin!"],
		],
		"clear": [
			["tsumuri", "Mời người chơi mới điền Desire Card. Hãy viết ra thế giới lý tưởng của bạn."],
			["hero", "Thế giới lý tưởng à... (viết) Anh Rei về nhà. Vậy thôi."],
			["pen", "Magnum Form bắn ngay từ đầu, giữ Bắn để nã liên tục. Buckle khác là phần thưởng của các vòng sau."],
		],
	},
	"2": {
		"start": [
			["tsumuri", "Vòng hai: đua tốc độ! Knight Jyamato chạy rất nhanh, về chậm là bị loại."],
		],
		"key": [
			["ace", "Boost Form. Tay đấm phụt lửa, nhanh như cáo. Bật lên là mọi thứ quanh cậu chậm lại, nhưng ngốn nộ cực nhanh."],
		],
		"clear": [
			["ace", "Cậu viết gì trên Desire Card thế?"],
			["hero", "Mang anh trai tôi về. Còn anh?"],
			["ace", "Tìm mẹ tôi. Xem ra tụi mình cùng một kiểu người: chơi chỉ để giành lại một người."],
		],
	},
	"3": {
		"start": [
			["tsumuri", "Vòng ba: phòng thủ. Rook Jyamato đang phá công trường, giáp dày như tường. Phần thưởng là Powered Builder Buckle."],
		],
		"key": [
			["pen", "Powered Builder Form! Cả một cỗ máy xây dựng đeo trên người. Chậm, to, nặng, đòn nào cũng phá giáp."],
		],
		"clear": [
			["hero", "Nếu điều ước của tôi là cứu anh Rei... thì hạ gục anh ấy có tính là thắng không?"],
			["ace", "Trò chơi nào cũng có luật. Nhưng kẻ mạnh nhất là kẻ tự viết lại luật chơi."],
		],
	},
	"4": {
		"start": [
			["ace", "Chung kết. Magnum ở trên, Boost ở dưới. Ghép hai buckle lại xem nào."],
		],
		"key": [
			["ace", "Magnum Boost Form. Súng trong tay, lửa dưới chân, cân bằng mọi mặt. Từ đây mới là cao trào."],
		],
		"clear": [
			["pen", "Ván đấu bị can thiệp rồi! Game Master tự bước xuống sân: Kamen Rider Glare."],
			["ace", "Hắn coi Rider như quân cờ. Đừng để hắn đoán trước nước đi của cậu."],
		],
	},
	"B": {
		"goal": [
			["glare", "Ta là Game Master. Điều ước nào được thành thật, do ta quyết định."],
			["hero", "Điều ước của tôi, tôi tự giành lấy."],
		],
		"clear": [
			["narrator", "Glare vỡ thành những mảnh dữ liệu. Trên bục trao giải chỉ còn một chiếc đai bọc tinh thể tím: Gotchard Driver."],
			["narrator", "Sức mạnh Geats trở về trọn vẹn. Geats IX!"],
			["ace", "Điều ước không tự thành thật đâu, {name}. Cứ thắng tiếp, tới khi chạm được nó."],
			["pen", "Gotchard Driver. Nghe có mùi giả kim thuật, với cả một trăm lẻ một sinh vật nhỏ."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Geats sáng rồi! Chặng tiếp theo: Trái Đất Gotchard, nơi người và Chemy sống chung một nhà."],
	["hero", "Desire Card vẫn còn trong túi tôi. Tôi sẽ giữ nó tới cuối."],
]
