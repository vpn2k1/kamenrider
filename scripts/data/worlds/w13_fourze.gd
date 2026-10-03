extends RefCounted
## Thế giới 13 · Kamen Rider Fourze (2011) — "Làm bạn với cả vũ trụ"
## Echo Rider: Kisaragi Gentaro (tóc pompadour, muốn làm bạn với cả trường). Hỗ trợ: Utahoshi Kengo (CLB Kamen Rider).
## Quái: Dustard và Zodiarts của Horoscopes. Trùm: Sagittarius Zodiarts, thủ lĩnh Horoscopes.
## Bài học: tình bạn. Pen nhận cái "bắt tay" đầu tiên.

const WORLD := {
	"id": "fourze",
	"year": 2011,
	"name": "Thế giới Fourze",
	"motto": "Làm bạn với cả vũ trụ",
	"rider": &"fourze",
	"rider_name": "Fourze",
	"driver_name": "Fourze Driver",
	"color": Color(0.92, 0.94, 1.0),
	"enemies": {
		"basic": {"name": "Dustard", "color": Color(0.45, 0.4, 0.6), "sprite": "dustard"},
		"fast": {"name": "Unicorn Zodiarts", "color": Color(0.85, 0.82, 0.95), "sprite": "unicorn_zodiarts"},
		"armored": {"name": "Orion Zodiarts", "color": Color(0.6, 0.52, 0.35), "sprite": "orion_zodiarts"},
	},
	"unlocks": [
		"Base States (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Cosmic States: Final Attack x1.5",
	],
	"stages": [
		{"name": "Trường trung học Amanogawa", "goal": "Hạ Dustard, lấy lại bốn Astroswitch cho Fourze Driver",
			"bg": "fourze_1", "bg_theme": "school"},
		{"name": "Rabbit Hatch trên Mặt Trăng", "form": &"rocket", "form_name": "Rocket States",
			"bg": "fourze_2", "bg_theme": "space_moon"},
		{"name": "Khu phố Amanogawa", "form": &"elek", "form_name": "Elek States",
			"bg": "fourze_3", "bg_theme": "city_dusk"},
		{"name": "Phòng thí nghiệm bốc cháy", "form": &"fire", "form_name": "Fire States",
			"bg": "fourze_4", "bg_theme": "lab"},
		{"name": "Trùm: Sagittarius Zodiarts", "bg": "fourze_b", "bg_theme": "boss_purple",
			"boss": {"name": "Sagittarius Zodiarts", "hp": 280.0, "damage": 17.0, "poise": 26.0, "speed": 60.0,
				"traits": [], "color": Color(0.95, 0.88, 0.6)}},
	],
}

## Fourze: đổi công tắc. Rocket States hai tay tên lửa, lao nhanh, nhảy xa; Elek States cầm gậy điện Billy the Rod,
## chém nặng phá giáp; Fire States cầm súng Hee-Hackgun, bắn cầu lửa tầm xa.
const RIDER := {
	"name": "Kamen Rider Fourze",
	"tagline": "Công tắc · tên lửa, gậy điện, súng lửa",
	"base": &"base_states",
	"order": [&"base_states", &"rocket", &"elek", &"fire"],
	"forms": {
		&"base_states": {"name": "Base States", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.1, "atk": 1.05, "poise": 7.0, "final": "Rider Rocket Drill Kick", "attacks": {"final": {"hits": 4, "damage": 16.0}},
			"skills": [
				{"name": "Drill Module", "type": "aim", "hits": 2, "tags": [&"heavy"], "fx": "drill",
					"color": Color(1.0, 0.8, 0.25)},
				{"name": "Chain Array", "type": "bind", "via": "shot", "shot": {"style": "ball", "radius": 7.0}, "fx": "chains",
					"color": Color(0.7, 0.75, 0.85)},
			]},
		&"rocket": {"name": "Rocket States", "style": "lancer", "hp": 130.0, "armor": 8.0, "speed": 180.0,
			"jump": 1.35, "atk": 0.9, "poise": 4.0, "final": "Rider Rocket Punch", "fx": {"trail": true, "color": Color(1.0, 0.55, 0.2)},
			"attacks": {"kick": {"lunge": Vector2(260, -20)}, "final": {"lunge": Vector2(340, -60)}},
			"skills": [
				{"name": "Rocket Rush", "type": "aim", "knockback": Vector2(260, -60), "tags": [&"force"], "fx": "wind",
					"summon": "rocket", "color": Color(1.0, 0.5, 0.15)},
				{"name": "Rocket Lift", "type": "buff", "buff": {"fly": true, "time": 4.0}, "fx": "rocket",
					"color": Color(1.0, 0.85, 0.4)},
			]},
		&"elek": {"name": "Elek States", "style": "blade", "hp": 165.0, "armor": 28.0, "speed": 118.0,
			"jump": 1.0, "atk": 1.25, "poise": 11.0, "final": "Rider 10 Billion Volt Break", "attacks": {"slash": {"tags": [&"shock"]}, "slash_finish": {"tags": [&"shock"]}, "final": {"tags": [&"shock"]}},
			"skills": [
				{"name": "Billy the Rod", "type": "aim", "tags": [&"shock"], "fx": "lightning", "anim": "slash",
					"color": Color(1.0, 0.9, 0.3)},
				{"name": "Plug Shock", "type": "area", "tags": [&"shock"], "fx": "cage", "icon": "shockwave",
					"color": Color(0.5, 0.8, 1.0)},
			]},
		&"fire": {"name": "Fire States", "style": "gunner", "hp": 150.0, "armor": 20.0, "speed": 115.0,
			"jump": 1.0, "atk": 0.95, "poise": 6.0, "final": "Rider Bakunetsu Shoot", "attacks": {"final": {"tags": [&"burn"]}},
			"gun": {"tags": [&"burn"], "look": "hackgun", "damage": 7.0, "speed": 340.0, "cooldown": 0.4, "radius": 4.0,
				"color": Color(1.0, 0.5, 0.15), "life": 0.7},
			"skills": [
				{"name": "Hee-hackgun", "type": "aim", "move": "spread", "tags": [&"burn"], "fx": "fire",
					"shot": {"style": "fire", "count": 4, "spread": 0.12, "life": 0.5}, "color": Color(1.0, 0.35, 0.15)},
				{"name": "Fire Extinguish", "type": "area", "slow": 3.0, "radius": 85.0, "fx": "water",
					"color": Color(0.9, 0.95, 1.0)},
			]},
	},
	"lv5": {"name": "Cosmic States", "final_mult": 1.5},
	"final_fx": {"intro": "rocket"},
}

## Giọng đai / tiếng hô (tools/gen_audio.py → audio/voice/<rider>_<khóa>.wav): "henshin" lúc biến thân, khóa = id form
## lúc đổi sang form đó, "final" lúc Final Attack. Mỗi dòng: [kiểu giọng, câu]
## (kiểu giọng: belt / belt_deep / belt_bright / kivat / hero, xem VOICES trong gen_audio.py).
const VOICE := {
	"henshin": ["belt", "Three. Two. One."],
	"rocket": ["belt", "Rocket. On."],
	"elek": ["belt", "Elek. On."],
	"fire": ["belt", "Fire. On."],
	"final": ["belt", "Rocket. Drill. Limit Break!"],
}

const SPEAKERS := {
	"gentaro": {"name": "KISARAGI GENTARO", "color": Color(0.98, 0.85, 0.4), "portrait": "gentaro",
		"look": "hair=3a2618 jacket=24242a stripe=e8e8e8 eyes=3a2a20"},
	"kengo": {"name": "UTAHOSHI KENGO", "color": Color(0.5, 0.75, 1.0), "portrait": "kengo",
		"look": "hair=1a1a1e jacket=4a4270 stripe=e0e0e8 eyes=2a2a30"},
	"sagittarius": {"name": "SAGITTARIUS", "color": Color(0.95, 0.88, 0.6), "portrait": "sagittarius",
		"look": "base=daguba tint=f0d890"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Fourze · Trường trung học Amanogawa."],
			["gentaro", "Tớ là Kisaragi Gentaro! Người sẽ làm bạn với toàn bộ học sinh trường Amanogawa!"],
			["kengo", "Utahoshi Kengo. Fourze Driver cần bốn Astroswitch: Rocket, Launcher, Drill, Radar. Dustard của Horoscopes lấy hết rồi."],
		],
		"goal": [
			["gentaro", "Mấy tên ninja áo đen kia! Công tắc của tụi mình nằm trong tay chúng."],
		],
		"key": [
			["narrator", "Bốn công tắc gạt xuống. THREE... TWO... ONE..."],
			["hero", "Henshin!"],
			["gentaro", "Giờ giơ tay lên trời mà hét đi! UCHUU KITAAA!"],
		],
		"clear": [
			["kengo", "Base States: cân bằng, tay phải Rocket, chân trái Drill. Drill Kick khoan bốn nhịp. Switch mạnh hơn ở căn cứ trên Mặt Trăng."],
			["gentaro", "Nào, bắt tay kiểu bạn bè: nắm tay đụng trên, đụng dưới. Xong! Giờ tụi mình là bạn!"],
		],
	},
	"2": {
		"start": [
			["kengo", "Rabbit Hatch, căn cứ CLB Kamen Rider trên Mặt Trăng. Dustard theo cửa không gian lên đây, ôm theo Rocket Switch Super-1."],
		],
		"key": [
			["kengo", "Rocket States! Cú đá kết lao theo tên lửa, chạy nhanh, nhảy xa. Nhưng giáp mỏng, đừng lao đầu bừa."],
		],
		"clear": [
			["hero", "Gentaro, sao cậu tin người lạ dễ vậy?"],
			["gentaro", "Bạn bè đâu cần lý do! Cả cô bạn trong thẻ của cậu nữa. Tớ nhìn là biết cô ấy thật lòng."],
			["pen", "......Cảm ơn."],
		],
	},
	"3": {
		"start": [
			["gentaro", "Unicorn Zodiarts đang quậy khu phố. Nó múa kiếm nhanh như chớp! Elek Switch cũng ở đó."],
		],
		"key": [
			["kengo", "Elek States! Bấm Chém để vung Billy the Rod: điện lan sang quái bên cạnh, nhát cuối phá giáp."],
		],
		"clear": [
			["pen", "Hồi còn ở với Void, tôi không có bạn. Chrono Pass chỉ cần làm theo lệnh."],
			["hero", "Giờ thì có rồi. Đưa tay đây... à, cậu không có tay. Thôi, coi như bắt tay rồi nhé."],
		],
	},
	"4": {
		"start": [
			["kengo", "Phòng thí nghiệm bốc cháy! Orion Zodiarts giáp dày đang đứng giữa biển lửa."],
			["gentaro", "Fire Switch ở đó! Vừa phun lửa vừa dập lửa được. Cứu người trước, đánh sau!"],
		],
		"key": [
			["kengo", "Fire States! Giữ nút Bắn, Hee-Hackgun phun lửa, quái trúng còn cháy thêm. Giữ khoảng cách nhé."],
		],
		"clear": [
			["kengo", "Thủ lĩnh Horoscopes là Sagittarius. Và hắn là... chủ tịch hội đồng quản trị của chính ngôi trường này."],
			["gentaro", "Kể cả ông ta, tớ cũng sẽ làm bạn! ...Nhưng trước hết phải đấm một trận đã."],
		],
	},
	"B": {
		"start": [
			["pen", "Void cấy năng lượng vào Sagittarius. Mũi tên của hắn bay rất xa, áp sát mà đánh!"],
		],
		"goal": [
			["sagittarius", "Học sinh không có quyền chống lại định mệnh. Các vì sao đã sắp đặt cả rồi."],
			["hero", "Kamen Rider Fourze! Ra đây đấu tay đôi!"],
		],
		"clear": [
			["narrator", "Sagittarius vỡ như sao băng. Trong ánh sáng còn lại là một chiếc đai hình bàn tay, bọc tinh thể tím: WizarDriver."],
			["narrator", "Bốn mươi Astroswitch đồng loạt sáng lên. Cosmic States!"],
			["gentaro", "{name}, Pen! Hai người là bạn tớ rồi. Có chuyện gì cứ gọi, dù tớ đang ở trên Mặt Trăng!"],
			["pen", "WizarDriver. Thế giới kế tiếp có phù thủy... và những người đang tuyệt vọng."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Fourze sáng lại. Chặng tiếp theo: Trái Đất Wizard, nơi pháp sư chiến đấu vì hy vọng."],
	["hero", "Pen, lúc nãy cậu vừa cười đúng không? Tôi nghe thấy đấy."],
	["pen", "...Nhìn đường đi kìa."],
]
