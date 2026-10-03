extends RefCounted
## Thế giới 6 · Kamen Rider Hibiki (2005) — "Rèn luyện không ngừng"
## Echo Rider: Hidaka Hitoshi, tức Hibiki (Oni thổi trống, vui tính, "Shu!"). Hỗ trợ: Adachi Asumu (cậu học trò).
## Quái: Makamou, chỉ bị thanh tẩy bằng âm thanh. Trùm: Orochi, hiện tượng Makamou trào lên hàng loạt.
## Mạch truyện: Void đứng giữa biển nhìn ngọn lửa Kurenai; Pen vội kéo {name} đi.

const WORLD := {
	"id": "hibiki",
	"year": 2005,
	"name": "Thế giới Hibiki",
	"motto": "Rèn luyện không ngừng",
	"rider": &"hibiki",
	"rider_name": "Hibiki",
	"driver_name": "Henshin Onsa",
	"color": Color(0.72, 0.45, 1.0),
	"enemies": {
		"basic": {"name": "Kappa", "color": Color(0.35, 0.72, 0.45), "sprite": "kappa"},
		"fast": {"name": "Ittanmomen", "color": Color(0.9, 0.88, 0.78), "sprite": "ittanmomen"},
		"armored": {"name": "Bakegani", "color": Color(0.85, 0.38, 0.25), "sprite": "bakegani"},
	},
	"unlocks": [
		"Hibiki (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Armed Hibiki: Final Attack x1.5",
	],
	"stages": [
		{"name": "Rừng Yakushima", "goal": "Rèn luyện: vượt rừng, hạ Makamou đang giữ Henshin Onsa",
			"bg": "hibiki_1", "bg_theme": "forest_day"},
		{"name": "Phố trước tiệm Tachibana", "form": &"onibi", "form_name": "Onibi",
			"bg": "hibiki_2", "bg_theme": "suburb"},
		{"name": "Thác nước trong núi", "form": &"kaentsuzumi", "form_name": "Kaentsuzumi",
			"bg": "hibiki_3", "bg_theme": "mountain_dawn"},
		{"name": "Bờ biển mùa hè", "form": &"kurenai", "form_name": "Hibiki Kurenai",
			"bg": "hibiki_4", "bg_theme": "coast"},
		{"name": "Trùm: Orochi", "bg": "hibiki_b", "bg_theme": "boss_purple",
			"boss": {"name": "Orochi", "hp": 310.0, "damage": 17.0, "poise": 32.0, "speed": 55.0,
				"traits": [], "color": Color(0.45, 0.3, 0.55)}},
	],
}

## Hibiki: form gốc đánh tay không, kết liễu bằng trống. Onibi bắn cầu lửa Rekka Dan từ dùi trống Ongekibou Rekka;
## Kaentsuzumi gõ trống lớn: chậm, cực nặng, phá giáp; Hibiki Kurenai rực đỏ, dùi trống chém như kiếm lửa.
const RIDER := {
	"name": "Kamen Rider Hibiki",
	"tagline": "Âm thanh thanh tẩy · dùi trống lửa, trống lớn, lửa đỏ",
	"base": &"hibiki",
	"order": [&"hibiki", &"onibi", &"kaentsuzumi", &"kurenai"],
	"forms": {
		&"hibiki": {"name": "Hibiki", "style": "brawler", "hp": 165.0, "armor": 25.0, "speed": 128.0,
			"jump": 1.05, "atk": 1.05, "poise": 8.0, "final": "Kaen Renda no Kata", "attacks": {"final": {"hits": 6, "damage": 11.0}},
			"skills": [
				{"name": "Onibi", "type": "area", "tags": [&"burn"], "fx": "fire", "color": Color(0.85, 0.4, 1.0)},
				{"name": "Ongekidaiko", "type": "bind", "special": "drum", "bind": 3.0, "fx": "taiko",
					"color": Color(1.0, 0.3, 0.2)},
			],
			"final_type": "bind",
			"fx": {"hit": "sound", "final": "sound", "color": Color(0.75, 0.5, 1.0)}},
		&"onibi": {"item": true, "name": "Onibi", "style": "gunner", "hp": 145.0, "armor": 15.0, "speed": 120.0,
			"jump": 1.0, "atk": 1.0, "poise": 5.0, "final": "Rekka Dan",
			"skills": [
				{"name": "Rekka Dan", "type": "aim", "move": "shot", "shot": {"style": "fire"}, "tags": [&"burn"], "fx": "fire",
					"color": Color(1.0, 0.45, 0.15)},
				{"name": "Onibi Spread", "type": "aim", "move": "spread", "shot": {"style": "ball"}, "tags": [&"burn"],
					"fx": "spark", "color": Color(0.8, 0.4, 1.0), "icon": "bullets"},
			],
			"fx": {"hit": "fire", "shot": "fire", "final": "sound", "color": Color(1.0, 0.5, 0.2)},
			"gun": {"look": "onibi", "tags": [&"burn"], "damage": 8.0, "speed": 330.0, "cooldown": 0.42, "radius": 4.5, "color": Color(1.0, 0.45, 0.2),
				"life": 0.8}},
		&"kaentsuzumi": {"item": true, "name": "Kaentsuzumi", "style": "heavy", "hp": 205.0, "armor": 55.0, "speed": 84.0,
			"jump": 0.85, "atk": 1.4, "poise": 19.0, "final": "Bakuretsu Kyouda no Kata", "attacks": {"kick": {"tags": [&"stun"]}},
			"skills": [
				{"name": "Ongekidaiko Kaen", "type": "bind", "tags": [&"stun"], "fx": "taiko", "color": Color(1.0, 0.55, 0.15),
					"icon": "drum"},
				{"name": "Bakuretsu", "type": "area", "radius": 90.0, "fx": "sound", "anim": "heavy",
					"color": Color(1.0, 0.85, 0.4)},
			],
			"final_type": "bind",
			"fx": {"hit": "sound", "final": "sound", "color": Color(1.0, 0.75, 0.3)}},
		&"kurenai": {"name": "Hibiki Kurenai", "style": "blade", "hp": 170.0, "armor": 30.0, "speed": 140.0,
			"jump": 1.1, "atk": 1.3, "poise": 12.0, "final": "Shakunetsu Shinku no Kata", "blade": {"look": "rekka"},
			"attacks": {"slash": {"tags": [&"burn"]}, "slash_finish": {"tags": [&"burn"]}, "final": {"tags": [&"burn"]}},
			"skills": [
				{"name": "Ongekibou Rekka", "type": "aim", "move": "shot", "shot": {"style": "fire", "radius": 6.0},
					"tags": [&"burn"], "fx": "fire", "anim": "slash", "color": Color(1.0, 0.25, 0.15), "icon": "bullets"},
				{"name": "Shakunetsu", "type": "area", "tags": [&"burn"], "fx": "sound", "summon": "fire",
					"color": Color(1.0, 0.6, 0.25)},
			],
			"final_type": "bind",
			"fx": {"hit": "fire", "swing": "slash", "final": "sound", "color": Color(1.0, 0.3, 0.25)}},
	},
	"lv5": {"name": "Armed Hibiki", "final_mult": 1.5},
	"final_fx": {"signature": "taiko"},
}

const SPEAKERS := {
	"hidaka": {"name": "HIBIKI", "color": Color(0.75, 0.5, 1.0), "portrait": "hidaka",
		"look": "hair=1a1612 jacket=4a3a2a stripe=a08a5a eyes=2a2018"},
	"asumu": {"name": "ADACHI ASUMU", "color": Color(0.55, 0.75, 0.95), "portrait": "asumu",
		"look": "hair=2a1e16 jacket=2a2e4a stripe=e8e8f0 eyes=3a2a20"},
	"orochi": {"name": "OROCHI", "color": Color(0.6, 0.4, 0.75), "portrait": "orochi", "look": "base=daguba tint=5a2a6a"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Hibiki · Rừng Yakushima, sương sớm còn đọng trên lá."],
			["pen", "Henshin Onsa không chịu kêu. Âm thoa của Oni chỉ ngân lên với một cơ thể đã rèn luyện."],
			["hidaka", "Yo! Hidaka Hitoshi, cứ gọi Hibiki. Shu! Muốn rèn thì chạy hết khu rừng này, tiện tay dọn luôn lũ Makamou nhé."],
		],
		"goal": [
			["hidaka", "Con Makamou đầu đàn kia đang giữ âm thoa. Hít sâu, đứng vững, rồi lao vào!"],
		],
		"key": [
			["narrator", "{name} gõ Henshin Onsa rồi áp lên trán. Tiếng ngân lan ra, lửa tím bùng lên phủ kín người."],
			["hero", "Henshin!"],
		],
		"clear": [
			["hidaka", "Oni ở đây không hô biến thân đâu, nhưng thôi, hô cũng được. Nhớ nhé: Makamou chỉ sợ âm thanh thanh tẩy."],
			["pen", "Hibiki đánh tay không, Final là Kaen Renda: gõ trống liên hồi sáu nhịp. Các kỹ thuật khác đang trong tay Makamou."],
		],
	},
	"2": {
		"start": [
			["asumu", "Em là Adachi Asumu! Kappa sinh sôi khắp phố quanh tiệm Tachibana rồi, anh Hibiki ơi!"],
			["pen", "Kỹ thuật Onibi nằm trong đám Kappa này. Dùi trống Ongekibou Rekka sẽ bắn ra cầu lửa, quét từ xa."],
		],
		"key": [
			["hidaka", "Onibi! Giữ nút Bắn, dùi trống phun cầu lửa Rekka Dan, quái trúng còn cháy thêm. Đừng để bị vây."],
		],
		"clear": [
			["asumu", "Làm sao để mạnh được như anh Hibiki vậy ạ?"],
			["hidaka", "Vì tôi luôn rèn luyện mà. (cười) Cậu cũng vậy đấy, {name}."],
		],
	},
	"3": {
		"start": [
			["hidaka", "Thác nước này là chỗ tôi hay rèn luyện. Bakegani bò ra từ khe đá, vỏ cua cứng lắm."],
			["pen", "Cần trống Kaentsuzumi: gắn lên người quái rồi gõ. Chậm, nhưng đập vỡ mọi lớp vỏ."],
		],
		"key": [
			["hidaka", "Kaentsuzumi! Gắn trống Ongeki lên quái: cú đánh kết làm nó choáng đứng im. Nặng tay, bước chậm."],
		],
		"clear": [
			["hidaka", "Nghe tiếng trống là biết người đánh. Trống của cậu thật thà lắm, {name}."],
		],
	},
	"4": {
		"start": [
			["hidaka", "Mùa hè là mùa Makamou. Ittanmomen bay dọc bờ biển, nhanh như gió."],
			["pen", "Hibiki Kurenai: lửa đỏ thiêu rực cả thân. Mạnh và nhanh, nhưng ngốn nộ lắm đấy!"],
		],
		"key": [
			["hidaka", "Kurenai! Cả người đỏ rực như than hồng. Bấm Chém để vung dùi Rekka thành kiếm lửa, đốt cháy quái."],
		],
		"clear": [
			["narrator", "Trên mỏm đá ngoài khơi, một bóng áo choàng đứng giữa sóng, lặng nhìn ngọn lửa đỏ trên người {name}."],
			["void", "Lửa đẹp đấy. Ta từng thấy thứ lửa lớn hơn nhiều."],
			["pen", "...Đừng nhìn hắn. Hắn chỉ muốn cậu dao động thôi."],
			["hidaka", "Kẻ đó không có âm thanh. Người rèn luyện nghe là biết: bên trong hắn im lặng quá."],
		],
	},
	"B": {
		"start": [
			["pen", "Mặt đất đang nứt ra! Hiện tượng Orochi: Makamou trào lên hàng loạt. Driver kế tiếp ở ngay tâm vết nứt."],
		],
		"goal": [
			["orochi", "Âm thanh... ồn ào quá. Ta sẽ nuốt hết. Núi, biển, và cả tiếng tim các ngươi."],
			["hidaka", "Phải thanh tẩy nó bằng âm thanh. {name}, đánh trống đi, bằng hết sức!"],
		],
		"clear": [
			["narrator", "Tiếng trống cuối cùng vang khắp núi. Orochi tan thành sương, để lại một con bọ cánh cứng đỏ bọc tinh thể tím: Kabuto Zecter."],
			["narrator", "Sức mạnh Hibiki trở về trọn vẹn. Kiếm Armed Saber ngân vang: Armed Hibiki!"],
			["hidaka", "Mạnh lên là để bảo vệ người khác. Cứ rèn luyện tiếp nhé, {name}. Shu!"],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Hibiki đã sáng lại. Chặng tiếp theo: Trái Đất Kabuto, nơi lũ Worm đội lốt con người."],
	["hero", "Rèn luyện xong rồi, giờ tới lượt chạy nhanh hả?"],
]
