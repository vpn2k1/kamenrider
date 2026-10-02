extends RefCounted
## Thế giới 15 · Kamen Rider Gaim (2013) — "Thay đổi số phận"
## Echo Rider: Kazuraba Kouta (Team Gaim, "Từ đây trở đi là sân khấu của tôi!"). Hỗ trợ: Kumon Kaito (Team Baron).
## Quái: Inves từ rừng Helheim. Trùm: Lord Baron, Kaito sau khi ăn trái Helheim và nhận năng lượng Void.
## Bài học: số phận là thứ để thay đổi. Gieo trước nỗi sợ "phải đối đầu với người mình quý".

const WORLD := {
	"id": "gaim",
	"year": 2013,
	"name": "Thế giới Gaim",
	"motto": "Thay đổi số phận",
	"rider": &"gaim",
	"rider_name": "Gaim",
	"driver_name": "Sengoku Driver",
	"color": Color(1.0, 0.55, 0.05),
	"enemies": {
		"basic": {"name": "Inves sơ cấp", "color": Color(0.5, 0.75, 0.35), "sprite": "elementary_inves"},
		"fast": {"name": "Komori Inves", "color": Color(0.7, 0.3, 0.35), "sprite": "komori_inves"},
		"armored": {"name": "Shika Inves", "color": Color(0.62, 0.5, 0.35), "sprite": "shika_inves"},
	},
	"unlocks": [
		"Orange Arms (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Kiwami Arms: Final Attack x1.5",
	],
	"stages": [
		{"name": "Sân khấu ngoài trời Zawame", "goal": "Thắng Inves Game, giành lại Sengoku Driver và Orange Lockseed",
			"bg": "gaim_1", "bg_theme": "city_day"},
		{"name": "Rừng Helheim", "form": &"pine", "form_name": "Pine Arms",
			"bg": "gaim_2", "bg_theme": "helheim"},
		{"name": "Phố Zawame lúc hoàng hôn", "form": &"ichigo", "form_name": "Ichigo Arms",
			"bg": "gaim_3", "bg_theme": "city_dusk"},
		{"name": "Tháp Yggdrasill", "form": &"jimber_lemon", "form_name": "Jimber Lemon Arms",
			"bg": "gaim_4", "bg_theme": "city_night"},
		{"name": "Trùm: Lord Baron", "bg": "gaim_b", "bg_theme": "boss_red",
			"boss": {"name": "Lord Baron", "hp": 300.0, "damage": 18.0, "poise": 30.0, "speed": 65.0,
				"traits": ["armored"], "color": Color(0.8, 0.15, 0.2)}},
	],
}

## Gaim: đổi Lockseed. Orange Arms cầm kiếm Daidaimaru; Pine Arms vung chùy Pine Iron, chậm mà phá giáp;
## Ichigo Arms nhẹ như ninja, phóng Ichigo Kunai; Jimber Lemon Arms bắn cung Sonic Arrow xuyên hàng quái.
const RIDER := {
	"name": "Kamen Rider Gaim",
	"tagline": "Lockseed · chùy nặng, kunai nhanh, cung xuyên",
	"base": &"orange",
	"order": [&"orange", &"pine", &"ichigo", &"jimber_lemon"],
	"forms": {
		# Orange Arms: kiếm Daidaimaru (nút Chém). Naginata Musou Slicer nhốt quái trong lát cam (choáng).
		&"orange": {"name": "Orange Arms", "style": "blade", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.1, "poise": 8.0, "final": "Naginata Musou Slicer", "blade": {"look": "daidaimaru"},
			"attacks": {"final": {"tags": [&"stun"]}},
			"fx": {"hit": "spark", "swing": "slash", "final": "ring", "color": Color(1.0, 0.55, 0.1)}},
		# Pine Arms: chùy xích Pine Iron (nút Chém, đòn nặng). Pine Squash ném chùy kéo quái về, nhốt trong quả dứa.
		&"pine": {"name": "Pine Arms", "style": "heavy", "hp": 200.0, "armor": 55.0, "speed": 85.0,
			"jump": 0.85, "atk": 1.4, "poise": 18.0, "final": "Pine Squash", "blade": {"look": "pine_iron", "style": "heavy"},
			"attacks": {"final": {"size": Vector2(90, 22), "offset": Vector2(50, -14), "knockback": Vector2(-120, -40),
				"tags": [&"force", &"stun"]}},
			"fx": {"hit": "ring", "swing": "slash", "final": "ring", "color": Color(0.95, 0.8, 0.25)}},
		# Ichigo Arms: ném Ichigo Kunai (nút Bắn). Ichigo Squash bật cao, trút mưa kunai xuống vùng trước mặt.
		&"ichigo": {"name": "Ichigo Arms", "style": "lancer", "hp": 132.0, "armor": 10.0, "speed": 175.0,
			"jump": 1.3, "atk": 0.9, "poise": 4.0, "final": "Ichigo Squash",
			"gun": {"look": "ichigo_kunai", "damage": 3.5, "speed": 420.0, "cooldown": 0.4, "count": 2, "spread": 0.08,
				"radius": 2.5, "color": Color(1.0, 0.3, 0.35), "life": 0.6},
			"attacks": {"final": {"hits": 4, "damage": 13.0, "size": Vector2(80, 40), "offset": Vector2(50, -20)}},
			"fx": {"hit": "spark", "shot": "arrow", "final": "ring", "trail": true, "color": Color(1.0, 0.3, 0.35)}},
		# Jimber Lemon Arms: cung Sonic Arrow (nút Bắn, xuyên). Sonic Volley: mũi tên chanh xuyên dài, phá giáp, hất văng.
		&"jimber_lemon": {"name": "Jimber Lemon Arms", "style": "gunner", "hp": 150.0, "armor": 20.0, "speed": 120.0,
			"jump": 1.05, "atk": 1.0, "poise": 6.0, "final": "Sonic Volley",
			"gun": {"look": "sonic_arrow", "damage": 7.5, "speed": 440.0, "cooldown": 0.45, "radius": 3.0, "pierce": true,
				"color": Color(1.0, 0.92, 0.3), "life": 0.9},
			"attacks": {"final": {"damage": 58.0, "size": Vector2(230, 12), "offset": Vector2(120, -16),
				"tags": [&"heavy", &"force"]}},
			"fx": {"hit": "spark", "shot": "arrow", "final": "ring", "color": Color(1.0, 0.9, 0.3)}},
	},
	"lv5": {"name": "Kiwami Arms", "final_mult": 1.5},
	"final_fx": {"intro": "crack", "signature": "fruit"},
}

## Giọng Sengoku Driver (tools/gen_audio.py → audio/voice/gaim_<khóa>.wav), xem VOICE của w01_kuuga.gd.
const VOICE := {
	"henshin": ["belt_deep", "Lock on! Soiya! Orange Arms! Hanamichi, on stage!"],
	"pine": ["belt_deep", "Pine Arms! Funsai, destroy!"],
	"ichigo": ["belt_deep", "Ichigo Arms! Shushutto spark!"],
	"jimber_lemon": ["belt_deep", "Mix! Jimber Lemon! Ha-ha!"],
	"final": ["belt_deep", "Soiya! Squash!"],
}

const SPEAKERS := {
	"kouta": {"name": "KAZURABA KOUTA", "color": Color(1.0, 0.6, 0.15), "portrait": "kouta",
		"look": "hair=3a2618 jacket=2a3a8a stripe=f08a20 eyes=3a2a1e"},
	"kaito": {"name": "KUMON KAITO", "color": Color(0.9, 0.3, 0.3), "portrait": "kaito",
		"look": "hair=1a1416 jacket=a01e24 stripe=f0d060 eyes=2a2024"},
	"lord_baron": {"name": "LORD BARON", "color": Color(0.85, 0.2, 0.25), "portrait": "lord_baron",
		"look": "base=daguba tint=b02830"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Gaim · Sân khấu ngoài trời thành phố Zawame."],
			["kouta", "Kazuraba Kouta, Team Gaim! Inves cướp Sengoku Driver với Orange Lockseed ngay giữa buổi diễn!"],
			["pen", "Ở đây các nhóm nhảy tranh sân khấu bằng Inves Game. Nhưng lũ Inves này thoát khỏi Lockseed rồi, không còn là trò chơi nữa!"],
		],
		"goal": [
			["kouta", "Con Inves to kia nuốt mất Lockseed rồi! Ép nó nhả ra!"],
		],
		"key": [
			["hero", "Henshin!"],
			["narrator", "LOCK ON! SOIYA! ORANGE ARMS: HANAMICHI ON STAGE! Một quả cam khổng lồ rơi xuống, bung thành giáp."],
			["kouta", "Giờ nói đi! Từ đây trở đi là sân khấu của cậu!"],
		],
		"clear": [
			["pen", "Orange Arms là form gốc: kiếm Daidaimaru, chém cân bằng. Lockseed khác đang mọc trong rừng Helheim."],
			["kouta", "Vào đó thì nhớ: đừng ăn trái cây trong rừng. Ăn vào là hóa Inves đấy."],
		],
	},
	"2": {
		"start": [
			["kaito", "Kumon Kaito, Team Baron. Kẻ yếu thì biến khỏi rừng này. Pine Lockseed treo trên cành kia, lấy được thì lấy."],
		],
		"key": [
			["kouta", "PINE ARMS: FUNSAI DESTROY! Chậm, nhưng vung chùy Pine Iron thì giáp nào cũng vỡ."],
		],
		"clear": [
			["kaito", "Ngươi chiến đấu vì cái gì? Kẻ không có lý do sẽ gục trước tiên."],
			["hero", "Vì anh trai tôi. Tôi phải tìm ra anh ấy."],
			["kaito", "Hừ. Vậy thì đừng yếu."],
		],
	},
	"3": {
		"start": [
			["kouta", "Komori Inves tràn ra phố! Chúng bay nhanh quá, cần thứ gì nhẹ hơn. Ichigo Lockseed đang ở quanh đây!"],
		],
		"key": [
			["kouta", "ICHIGO ARMS: SHUSHUTTO SPARK! Nhẹ như ninja, chạy nhanh, phóng Ichigo Kunai liên tục."],
		],
		"clear": [
			["kouta", "Kaito với tôi từng là đối thủ trên sân khấu. Giờ tôi không biết cậu ta sẽ chọn con đường nào."],
			["kouta", "Có khi cậu sẽ phải đối đầu với một người mình quý, {name}. Lúc đó, đừng bỏ chạy."],
			["hero", "...Tôi mong chuyện đó không bao giờ xảy ra."],
		],
	},
	"4": {
		"start": [
			["kaito", "Tháp Yggdrasill giấu Lemon Energy Lockseed, sức mạnh thế hệ mới. Ta cần nó. Ngươi cũng vậy."],
		],
		"key": [
			["kouta", "MIX! JIMBER LEMON! HA-HA! Cung Sonic Arrow bắn xa, xuyên cả hàng quái. Cứ đứng xa mà ngắm."],
		],
		"clear": [
			["kaito", "Năng lượng Void... nó hỏi ta có muốn đập nát thế giới này để làm lại không. Câu trả lời là có."],
			["narrator", "Kaito cắn một trái Helheim rồi biến vào rừng. Dây leo đỏ bắt đầu mọc khắp Zawame."],
		],
	},
	"B": {
		"start": [
			["pen", "Năng lượng Void biến Kaito thành Overlord! Giáp hắn cứng lắm, chỉ đòn nặng và Final Attack mới xuyên được."],
		],
		"goal": [
			["lord_baron", "Thế giới này để kẻ mạnh giẫm lên kẻ yếu. Ta sẽ phá nát nó, rồi dựng lại từ đầu."],
			["hero", "Số phận không phải thứ để phá. Là thứ để thay đổi. Từ đây trở đi là sân khấu của tôi!"],
		],
		"clear": [
			["narrator", "Lord Baron gục xuống. Rễ Helheim rút đi, để lại một chiếc đai có màn hình mặt người, bọc tinh thể tím: Drive Driver."],
			["narrator", "Một Lockseed vàng rơi vào tay {name}. KIWAMI ARMS! DAI-DAI-DAI-DAISHOGUN! Kiwami Arms!"],
			["kaito", "...Ngươi mạnh thật. Đừng để ai quyết định số phận thay ngươi."],
			["kouta", "Nếu số phận bắt cậu chiến đấu, hãy chiến đấu để thay đổi nó. Sân khấu đó là của cậu, {name}."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Gaim sáng lại. Chặng tiếp theo: Trái Đất Drive. Cái đai đó... hình như vừa nháy mắt với tôi?"],
	["hero", "Một cái đai biết nháy mắt? Cậu có đối thủ rồi đấy, Pen."],
]
