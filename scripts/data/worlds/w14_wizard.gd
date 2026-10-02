extends RefCounted
## Thế giới 14 · Kamen Rider Wizard (2012) — "Hy vọng cuối cùng"
## Echo Rider: Soma Haruto (điềm tĩnh, "Saa, showtime da"). Hỗ trợ: Koyomi (cảm nhận được ma lực).
## Quái: Ghoul và Phantom săn các Gate, đẩy họ vào tuyệt vọng. Trùm: Wiseman, thủ lĩnh Phantom.
## Bài học: hy vọng. {name} suýt thành "Gate" vì nỗi đau về anh trai; Pen hứa sẽ kéo cậu lên.

const WORLD := {
	"id": "wizard",
	"year": 2012,
	"name": "Thế giới Wizard",
	"motto": "Hy vọng cuối cùng",
	"rider": &"wizard",
	"rider_name": "Wizard",
	"driver_name": "WizarDriver",
	"color": Color(0.95, 0.15, 0.4),
	"enemies": {
		"basic": {"name": "Ghoul", "color": Color(0.62, 0.58, 0.5), "sprite": "ghoul"},
		"fast": {"name": "Phantom Hellhound", "color": Color(0.55, 0.35, 0.8), "sprite": "hellhound"},
		"armored": {"name": "Phantom Minotaurus", "color": Color(0.6, 0.4, 0.3), "sprite": "minotaurus"},
	},
	"unlocks": [
		"Flame Style (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Infinity Style: Final Attack x1.5",
	],
	"stages": [
		{"name": "Tiệm đồ cổ Omokagedo", "goal": "Bảo vệ Gate khỏi đám Ghoul, lấy lại Flame Ring",
			"bg": "wizard_1", "bg_theme": "suburb"},
		{"name": "Bờ biển lúc hoàng hôn", "form": &"water", "form_name": "Water Style",
			"bg": "wizard_2", "bg_theme": "coast"},
		{"name": "Underworld của Gate", "form": &"hurricane", "form_name": "Hurricane Style",
			"bg": "wizard_3", "bg_theme": "underworld"},
		{"name": "Mỏ đá ngoại ô", "form": &"land", "form_name": "Land Style",
			"bg": "wizard_4", "bg_theme": "mountain_dawn"},
		{"name": "Trùm: Wiseman", "bg": "wizard_b", "bg_theme": "boss_dark",
			"boss": {"name": "Wiseman", "hp": 280.0, "damage": 17.0, "poise": 28.0, "speed": 65.0,
				"traits": [], "color": Color(0.92, 0.92, 0.98)}},
	],
}

## Wizard: đổi nhẫn nguyên tố, mỗi Style một phép theo phim. Flame Style: lửa, cú kết chuỗi và Strike Wizard gây cháy.
## Water Style: đạn nước WizarSwordGun xuyên cả hàng quái, Shooting Strike 3 nhịp. Hurricane Style: gió nâng người (bay
## lượn), cú kết chuỗi thổi bay quái, Slash Strike 3 nhát gió. Land Style: phép Defend dựng tường đá chặn nửa sát thương
## phía trước, dậm chân hất tung quái.
const RIDER := {
	"name": "Kamen Rider Wizard",
	"tagline": "Nhẫn phép · súng nước, gió lốc, đá tảng",
	"base": &"flame",
	"order": [&"flame", &"water", &"hurricane", &"land"],
	"forms": {
		&"flame": {"name": "Flame Style", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.1, "atk": 1.05, "poise": 7.0, "final": "Strike Wizard",
			"fx": {"hit": "fire", "final": "fire", "color": Color(1.0, 0.35, 0.3)},
			"attacks": {"kick": {"tags": [&"burn"]}, "final": {"tags": [&"burn"]}}},
		&"water": {"name": "Water Style", "style": "gunner", "hp": 145.0, "armor": 15.0, "speed": 125.0,
			"jump": 1.05, "atk": 0.95, "poise": 5.0, "final": "Shooting Strike",
			"fx": {"hit": "spark", "shot": "ball", "final": "ring", "color": Color(0.35, 0.6, 1.0)},
			"gun": {"look": "wizargun", "damage": 6.5, "speed": 380.0, "cooldown": 0.35, "radius": 3.5, "pierce": true,
				"color": Color(0.35, 0.6, 1.0), "life": 0.85},
			"attacks": {"final": {"hits": 3, "damage": 18.0}}},
		&"hurricane": {"name": "Hurricane Style", "style": "lancer", "hp": 130.0, "armor": 8.0, "speed": 175.0,
			"jump": 1.4, "atk": 0.9, "poise": 4.0, "final": "Slash Strike", "blade": {"style": "lancer"},
			"fx": {"hit": "wind", "swing": "wind", "final": "wind", "trail": true, "glide": true,
				"color": Color(0.45, 1.0, 0.55)},
			"attacks": {
				"kick": {"knockback": Vector2(240, -80), "tags": [&"force"]},
				"final": {"hits": 3, "damage": 16.0, "size": Vector2(60, 20), "offset": Vector2(32, -14)}}},
		&"land": {"name": "Land Style", "style": "heavy", "hp": 205.0, "armor": 58.0, "speed": 82.0,
			"jump": 0.8, "atk": 1.4, "poise": 19.0, "final": "Strike Wizard (Land)", "guard": 0.5,
			"fx": {"hit": "ring", "final": "ring", "color": Color(1.0, 0.85, 0.3)},
			"attacks": {"kick": {"size": Vector2(120, 18), "offset": Vector2(0, -6), "knockback": Vector2(10, -260),
				"tags": [&"force"]}}},
	},
	"lv5": {"name": "Infinity Style", "final_mult": 1.5},
	"final_fx": {"intro": "circle", "signature": "circle"},
}

## Giọng đai / tiếng hô (tools/gen_audio.py → audio/voice/<rider>_<khóa>.wav): "henshin" lúc biến thân, khóa = id form
## lúc đổi sang form đó, "final" lúc Final Attack. Mỗi dòng: [kiểu giọng, câu]
## (kiểu giọng: belt / belt_deep / belt_bright / kivat / hero, xem VOICES trong gen_audio.py).
const VOICE := {
	"henshin": ["belt_bright", "Flame, please. Hi! Hi! Hi-Hi-Hi!"],
	"water": ["belt_bright", "Water, please. Sui! Sui! Sui-Sui-Sui!"],
	"hurricane": ["belt_bright", "Hurricane, please. Fu! Fu! Fu-Fu-Fu!"],
	"land": ["belt_bright", "Land, please. Do! Do-Do-Do-Don!"],
	"final": ["belt_bright", "Very nice! Kick Strike! Saiko!"],
}

const SPEAKERS := {
	"haruto": {"name": "SOMA HARUTO", "color": Color(0.95, 0.3, 0.4), "portrait": "haruto",
		"look": "hair=2a1c16 jacket=1e1e24 stripe=b42a34 eyes=3a2820"},
	"koyomi": {"name": "KOYOMI", "color": Color(0.85, 0.75, 1.0), "portrait": "koyomi",
		"look": "hair=1a1418 jacket=e8e0f0 stripe=6a5aa0 eyes=3a3050 long"},
	"wiseman": {"name": "WISEMAN", "color": Color(0.9, 0.9, 0.98), "portrait": "wiseman",
		"look": "base=kuuga tint=f0ecd8"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Wizard · Tiệm đồ cổ Omokagedo."],
			["haruto", "Soma Haruto, pháp sư. WizarDriver chỉ tỉnh lại khi có Flame Ring. Lũ Ghoul cướp nó để dụ tôi ra."],
			["koyomi", "Koyomi. Tôi cảm nhận được ma lực. Đằng kia có một Gate, người mà Phantom muốn đẩy vào tuyệt vọng."],
		],
		"goal": [
			["haruto", "Con Ghoul to nhất kia đeo nhẫn của tôi. Chẳng hợp với nó chút nào."],
		],
		"key": [
			["hero", "Henshin!"],
			["narrator", "Flame Ring chạm vào bàn tay trên WizarDriver. FLAME, PLEASE! HI, HI, HI-HI-HI!"],
			["haruto", "Giờ nói theo tôi. Saa, showtime da."],
		],
		"clear": [
			["pen", "Flame Style là form gốc: đá xoay, cân bằng. Các nhẫn nguyên tố khác đang nằm trong tay Phantom."],
			["koyomi", "Trong cậu có rất nhiều ma lực, {name}. Và rất nhiều nỗi buồn."],
		],
	},
	"2": {
		"start": [
			["haruto", "Một Phantom đang săn Gate dọc bờ biển. Water Ring chắc chắn ở gần đây."],
		],
		"key": [
			["haruto", "WATER, PLEASE! SUI, SUI, SUI-SUI! Đạn nước xuyên qua cả hàng quái. Mạnh về phép, đừng để bị áp sát."],
		],
		"clear": [
			["hero", "Haruto, anh có bao giờ tuyệt vọng không?"],
			["haruto", "Có. Nhưng tôi đã hứa sẽ là hy vọng cuối cùng của một người. Từ đó, tôi không được phép gục."],
		],
	},
	"3": {
		"start": [
			["koyomi", "Gate sắp tuyệt vọng rồi. Nếu không vào Underworld của cô ấy ngay, một Phantom sẽ ra đời."],
			["haruto", "Engage Ring mở lối vào tâm trí. Trong đó không có đất để đứng đâu. Phải bay."],
		],
		"key": [
			["haruto", "HURRICANE, PLEASE! FUU, FUU, FUU-FUU! Gió nâng người: giữ Nhảy khi rơi để lượn, cú kết thổi bay quái. Giáp mỏng lắm."],
		],
		"clear": [
			["pen", "Underworld của cô ấy toàn ký ức đẹp. Còn của {name} thì sao nhỉ..."],
			["hero", "Chắc toàn là lửa. Vụ cháy mười năm trước, cái đêm anh tôi biến mất."],
			["pen", "Nếu có ngày cậu tuyệt vọng, tôi sẽ kéo cậu lên. Tôi hứa."],
		],
	},
	"4": {
		"start": [
			["haruto", "Minotaurus đang phá mỏ đá. Da nó cứng như đá, đòn nhẹ vô dụng. Land Ring nằm dưới đống đổ nát."],
		],
		"key": [
			["haruto", "LAND, PLEASE! DO-DO-DO-DON! Phép Defend dựng tường đá chặn nửa đòn phía trước. Dậm chân là quái bật lên."],
		],
		"clear": [
			["koyomi", "Ma lực của Void ở ngay phía trước. Và một người áo trắng đang chờ."],
			["haruto", "Wiseman. Kẻ muốn nhấn chìm cả thế giới trong tuyệt vọng. Đi thôi, {name}."],
		],
	},
	"B": {
		"goal": [
			["wiseman", "Ngươi là một Gate, {name}. Nỗi đau về người anh mất tích... chỉ cần đẩy nhẹ thôi."],
			["pen", "Đừng nghe hắn! Cậu không một mình!"],
			["hero", "Có thể tôi từng tuyệt vọng. Nhưng giờ có người tin tôi. Chừng đó đủ để đứng dậy."],
		],
		"clear": [
			["narrator", "Wiseman tan vào nhật thực. Trong bóng tối còn lại là một chiếc đai có lưỡi dao, bọc tinh thể tím: Sengoku Driver."],
			["narrator", "Viên kim cương trắng rực sáng. INFINITY, PLEASE! Infinity Style!"],
			["haruto", "Hy vọng không phải thứ ai cho mình. Là thứ mình giữ lấy, kể cả khi mọi thứ tối đen."],
			["pen", "Sengoku Driver... Thế giới kế tiếp có một khu rừng đang nuốt chửng thành phố."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Wizard sáng lại. Chặng tiếp theo: Trái Đất Gaim, thành phố Zawame và khu rừng Helheim."],
	["hero", "Pen, cậu hứa kéo tôi lên rồi đấy nhé. Tôi nhớ đấy."],
	["pen", "Thì cứ nhớ. Tôi cũng nhớ."],
]
