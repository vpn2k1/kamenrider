extends RefCounted
## Thế giới 9 · Kamen Rider Kiva (2008) — "Đánh thức linh hồn" · KẾT HỒI 1
## Echo Rider: Kurenai Wataru (thợ làm violin, nhút nhát, mẹ là Fangire). Hỗ trợ: Kivat-bat III (chính là "Driver").
## Quái: Fangire hút sinh mệnh người. Trùm: Dark Kiva, bộ giáp của Vua Fangire, người mặc là Nobori Taiga, anh trai Wataru.
## Mạch truyện: sau khi hạ trùm, Void chặn đường, đánh gục {name}: "Về nhà đi, {name}." Pen thú nhận mình từng là
## Chrono Pass của hắn. Chủ đề anh em (Wataru và Taiga) dọn đường cho sự thật ở Zi-O.

const WORLD := {
	"id": "kiva",
	"year": 2008,
	"name": "Thế giới Kiva",
	"motto": "Đánh thức linh hồn",
	"rider": &"kiva",
	"rider_name": "Kiva",
	"driver_name": "Kivat-bat III",
	"color": Color(0.95, 0.2, 0.38),
	"enemies": {
		"basic": {"name": "Spider Fangire", "color": Color(0.62, 0.35, 0.72), "sprite": "spider_fangire"},
		"fast": {"name": "Horse Fangire", "color": Color(0.72, 0.78, 0.92), "sprite": "horse_fangire"},
		"armored": {"name": "Moose Fangire", "color": Color(0.6, 0.48, 0.36), "sprite": "moose_fangire"},
	},
	"unlocks": [
		"Kiva Form (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Emperor Form: Final Attack x1.5",
	],
	"stages": [
		{"name": "Phố đêm quanh quán mald'amour", "goal": "Lần theo tiếng đàn Bloody Rose, hạ Fangire và đánh thức Kivat-bat III",
			"bg": "kiva_1", "bg_theme": "city_night"},
		{"name": "Rừng đêm trăng tròn", "form": &"garulu", "form_name": "Garulu Form",
			"bg": "kiva_2", "bg_theme": "forest_night"},
		{"name": "Bờ biển lúc chiều tà", "form": &"basshaa", "form_name": "Basshaa Form",
			"bg": "kiva_3", "bg_theme": "coast"},
		{"name": "Lâu đài cổ", "form": &"dogga", "form_name": "Dogga Form",
			"bg": "kiva_4", "bg_theme": "castle_night"},
		{"name": "Trùm: Dark Kiva", "bg": "kiva_b", "bg_theme": "boss_dark",
			"boss": {"name": "Dark Kiva", "hp": 320.0, "damage": 19.0, "poise": 30.0, "speed": 70.0,
				"traits": ["armored"], "color": Color(0.35, 0.12, 0.2)}},
	],
}

## Kiva: form gốc nhảy cao, đấm đá. Mỗi form là một Arms Monster: Garulu (người sói, kiếm Garulu Saber) nhanh và
## chém mạnh; Basshaa (người cá, súng Basshaa Magnum) bắn đạn nước; Dogga (búa Dogga Hammer) chậm, cực nặng, phá giáp.
const RIDER := {
	"name": "Kamen Rider Kiva",
	"tagline": "Arms Monster · kiếm sói, súng nước, búa khổng lồ",
	"base": &"kiva",
	"order": [&"kiva", &"garulu", &"basshaa", &"dogga"],
	"forms": {
		&"kiva": {"name": "Kiva Form", "style": "brawler", "hp": 160.0, "armor": 22.0, "speed": 135.0,
			"jump": 1.15, "atk": 1.05, "poise": 7.0, "final": "Darkness Moon Break", "attacks": {"final": {"tags": [&"stun"]}},
			"skills": [
				{"name": "Kiva Bat", "type": "lock", "heal": 0.08, "fx": "bat", "color": Color(0.9, 0.15, 0.3),
					"icon": "wings"},
				{"name": "Kiva Emblem", "type": "bind", "fx": "moon", "color": Color(1.0, 0.85, 0.3)},
			],
			"final_type": "bind",
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.3, 0.35)}},
		&"garulu": {"name": "Garulu Form", "style": "blade", "hp": 140.0, "armor": 15.0, "speed": 160.0,
			"jump": 1.2, "atk": 1.2, "poise": 8.0, "final": "Garulu Howling Slash", "blade": {"look": "garulu_saber"}, "attacks": {"final": {"hits": 2, "damage": 34.0}},
			"skills": [
				{"name": "Garulu Saber", "type": "aim", "fx": "claw", "anim": "slash", "color": Color(0.4, 0.6, 1.0)},
				{"name": "Howling", "type": "area", "radius": 90.0, "tags": [&"stun"], "fx": "sound", "anim": "heavy",
					"summon": "moon", "color": Color(0.75, 0.88, 1.0)},
			],
			"fx": {"hit": "spark", "swing": "slash", "final": "wind", "color": Color(0.4, 0.55, 1.0)}},
		&"basshaa": {"name": "Basshaa Form", "style": "gunner", "hp": 145.0, "armor": 20.0, "speed": 115.0,
			"jump": 1.0, "atk": 1.0, "poise": 5.0, "final": "Basshaa Aqua Tornado", "attacks": {"final": {"knockback": Vector2(-220, -40), "tags": [&"force"]}},
			"skills": [
				{"name": "Aqua Bullet", "type": "lock", "range": 240.0, "tags": [&"ranged"], "fx": "water",
					"color": Color(0.2, 0.9, 0.7)},
				{"name": "Aqua Field", "type": "area", "radius": 90.0, "slow": 3.0, "fx": "gravity",
					"color": Color(0.25, 0.5, 1.0), "icon": "ice"},
			],
			"final_type": "lock",
			"fx": {"hit": "spark", "shot": "ball", "final": "wind", "color": Color(0.3, 0.9, 0.7)},
			"gun": {"look": "basshaa_magnum", "damage": 6.5, "speed": 400.0, "cooldown": 0.28, "radius": 3.0, "color": Color(0.3, 0.9, 0.7),
				"life": 1.0}},
		&"dogga": {"name": "Dogga Form", "style": "heavy", "hp": 215.0, "armor": 60.0, "speed": 78.0,
			"jump": 0.8, "atk": 1.45, "poise": 21.0, "final": "Dogga Thunder Slap", "blade": {"look": "dogga_hammer", "style": "heavy"},
			"attacks": {"final": {"tags": [&"stun", &"shock"]}},
			"skills": [
				{"name": "Dogga Hammer", "type": "aim", "tags": [&"crush", &"heavy"], "fx": "ring", "anim": "slash",
					"color": Color(0.65, 0.35, 0.9), "icon": "punch"},
				{"name": "Thunder Grip", "type": "bind", "tags": [&"shock"], "fx": "lightning", "color": Color(1.0, 0.9, 0.3),
					"icon": "lightning"},
			],
			"final_type": "bind",
			"fx": {"hit": "ring", "final": "lightning", "color": Color(0.65, 0.4, 0.9)}},
	},
	"lv5": {"name": "Emperor Form", "final_mult": 1.5},
	"final_fx": {"intro": "moon"},
}

## Giọng đai / tiếng hô (tools/gen_audio.py → audio/voice/<rider>_<khóa>.wav): "henshin" lúc biến thân, khóa = id form
## lúc đổi sang form đó, "final" lúc Final Attack. Mỗi dòng: [kiểu giọng, câu]
## (kiểu giọng: belt / belt_deep / belt_bright / kivat / hero, xem VOICES trong gen_audio.py).
const VOICE := {
	"henshin": ["kivat", "Gabu!"],
	"garulu": ["kivat", "Garulu Saber!"],
	"basshaa": ["kivat", "Basshaa Magnum!"],
	"dogga": ["kivat", "Dogga Hammer!"],
	"final": ["kivat", "Wake up!"],
}

const SPEAKERS := {
	"wataru": {"name": "KURENAI WATARU", "color": Color(0.95, 0.45, 0.5), "portrait": "wataru",
		"look": "hair=1a1612 jacket=d8d0c0 stripe=6a4a3a eyes=2a2018"},
	"kivat": {"name": "KIVAT-BAT III", "color": Color(1.0, 0.85, 0.3), "portrait": "kivat",
		"look": "base=grongi tint=d8b020"},
	"dark_kiva": {"name": "DARK KIVA", "color": Color(0.75, 0.25, 0.35), "portrait": "dark_kiva",
		"look": "base=kuuga tint=4a1a2a"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Kiva · Phố đêm quanh quán cà phê mald'amour."],
			["wataru", "X-xin chào... Tôi là Kurenai Wataru, thợ làm violin, từng là Kiva. Cây đàn Bloody Rose đang rung... Fangire ở gần đây."],
			["pen", "Driver của Kiva là một chú dơi sống: Kivat-bat III. Nó đang ngủ trong tinh thể phong ấn, trong tay lũ Fangire."],
		],
		"goal": [
			["wataru", "Con Fangire kia... tinh thể trên cổ nó đang phát sáng. Kivat ở trong đó!"],
		],
		"key": [
			["kivat", "Phù, ngủ đã đời! Ơ, người mới à? Không sao hết! Kivatte ikuze!"],
			["narrator", "Kivat cắn vào tay {name}. Hoa văn đỏ như kính màu lan trên da, xích bạc quấn quanh eo."],
			["hero", "Henshin!"],
		],
		"clear": [
			["wataru", "Fangire hút sinh mệnh con người. Nhưng không phải Fangire nào cũng xấu... Mẹ tôi cũng là một Fangire."],
			["pen", "Kiva Form: nhảy cao, đấm đá cân bằng. Darkness Moon Break kéo trăng xuống, ghim quái đứng im. Ba Arms Monster đang bị giam."],
		],
	},
	"2": {
		"start": [
			["kivat", "Rừng đêm trăng tròn! Garulu, người sói cuối cùng, bị nhốt ở đây. Horse Fangire chạy nhanh lắm đấy!"],
		],
		"key": [
			["kivat", "Garulu Saber! Xanh như trăng đêm. Bấm Chém để vung kiếm sói: nhanh, ba nhát rồi phá giáp."],
		],
		"clear": [
			["wataru", "Bố tôi là người dám yêu cả một Fangire. Tôi... muốn dũng cảm được như bố."],
		],
	},
	"3": {
		"start": [
			["wataru", "Basshaa, người cá, bị giam trong chiếc bình dưới biển. Fangire canh bờ đông lắm, đừng để bị vây."],
		],
		"key": [
			["kivat", "Basshaa Magnum! Giữ nút Bắn để bắn đạn nước. Aqua Tornado hút quái về phía cậu. Giáp mỏng đó nha!"],
		],
		"clear": [
			["kivat", "Hồi trước Wataru bị dị ứng với cả thế giới, không dám ra khỏi nhà đâu. Giờ cậu ấy có bạn rồi!"],
		],
	},
	"4": {
		"start": [
			["pen", "Lâu đài cổ. Moose Fangire gác cổng, sừng cứng như đá. Dogga đang bị nhốt bên trong."],
		],
		"key": [
			["kivat", "Dogga Hammer! Bấm Chém để vung búa to như cánh cửa. Thunder Slap giật điện, quái đứng hình luôn!"],
		],
		"clear": [
			["wataru", "Trong lâu đài có Dark Kiva, bộ giáp của Vua Fangire. Và Vua bây giờ là... anh trai tôi, Nobori Taiga."],
			["pen", "{name}, sau trận này... tôi sẽ kể cậu nghe chuyện đó. Chuyện tôi đã hứa."],
		],
	},
	"B": {
		"start": [
			["pen", "Năng lượng Void đặc nhất từ trước tới giờ. Nó đang nuốt lấy người trong bộ giáp kia."],
		],
		"goal": [
			["dark_kiva", "Ta là Vua của tộc Fangire. Kẻ đứng trước Vua chỉ có một con đường: quỳ xuống."],
			["wataru", "Anh Taiga! Năng lượng đó đang điều khiển anh... {name}, xin cậu, đừng giết anh ấy."],
			["hero", "Tôi cũng có một người anh. Tôi hiểu mà. Tôi sẽ kéo anh ấy ra."],
		],
		"clear": [
			["narrator", "Giáp Dark Kiva vỡ tung, Taiga ngã xuống và mở mắt. Giữa mảnh vỡ là một chiếc đai trắng bọc tinh thể tím: Decadriver."],
			["narrator", "Xích trên người {name} bung hết. Sức mạnh Kiva trở về trọn vẹn: Emperor Form!"],
			["wataru", "Dù đứng ở hai phía, anh em vẫn là anh em. Mong cậu tìm được anh mình, {name}."],
			["narrator", "{name} vừa vươn tay tới Decadriver thì bóng tối đổ ập xuống. Một bóng áo choàng đứng chắn trước mặt."],
			["narrator", "Chỉ một cái phẩy tay. Bóng tối nuốt chửng {name}, giáp Emperor vỡ vụn, cậu khuỵu xuống nền đá lạnh."],
			["void", "Về nhà đi, {name}."],
			["narrator", "Rồi hắn biến mất. Decadriver vẫn nằm đó, như thể hắn cố tình để lại."],
			["hero", "...Sao hắn biết tên mình?"],
			["pen", "Vì tôi... từng là Chrono Pass của hắn."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Ký ức của tôi có một khoảng trắng. Tôi chỉ nhớ bàn tay hắn từng cầm tôi... ấm như tay cậu bây giờ."],
	["hero", "Hắn là ai? Sao lại bảo tôi về nhà?"],
	["pen", "Tôi không biết. Chặng tiếp theo: Trái Đất Decade, nơi có kẻ đi qua mọi thế giới. Có lẽ người đó biết."],
]
