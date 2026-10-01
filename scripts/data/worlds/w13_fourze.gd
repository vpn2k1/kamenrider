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
		"basic": {"name": "Dustard", "color": Color(0.45, 0.4, 0.6)},
		"fast": {"name": "Unicorn Zodiarts", "color": Color(0.85, 0.82, 0.95)},
		"armored": {"name": "Orion Zodiarts", "color": Color(0.6, 0.52, 0.35)},
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
			"jump": 1.1, "atk": 1.05, "poise": 7.0, "final": "Rider Rocket Drill Kick"},
		&"rocket": {"name": "Rocket States", "style": "lancer", "hp": 130.0, "armor": 8.0, "speed": 180.0,
			"jump": 1.35, "atk": 0.9, "poise": 4.0, "final": "Rider Rocket Punch"},
		&"elek": {"name": "Elek States", "style": "blade", "hp": 165.0, "armor": 28.0, "speed": 118.0,
			"jump": 1.0, "atk": 1.25, "poise": 11.0, "final": "Rider 10 Billion Volt Break"},
		&"fire": {"name": "Fire States", "style": "gunner", "hp": 150.0, "armor": 20.0, "speed": 115.0,
			"jump": 1.0, "atk": 0.95, "poise": 6.0, "final": "Rider Bakunetsu Shoot",
			"gun": {"damage": 7.0, "speed": 340.0, "cooldown": 0.4, "radius": 4.0,
				"color": Color(1.0, 0.5, 0.15), "life": 0.7}},
	},
	"lv5": {"name": "Cosmic States", "final_mult": 1.5},
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
			["kengo", "Base States: cân bằng, tay phải Rocket, chân trái Drill. Các Switch mạnh hơn đang ở căn cứ trên Mặt Trăng."],
			["gentaro", "Nào, bắt tay kiểu bạn bè: nắm tay đụng trên, đụng dưới. Xong! Giờ tụi mình là bạn!"],
		],
	},
	"2": {
		"start": [
			["kengo", "Rabbit Hatch, căn cứ CLB Kamen Rider trên Mặt Trăng. Dustard theo cửa không gian lên đây, ôm theo Rocket Switch Super-1."],
		],
		"key": [
			["kengo", "Rocket States! Hai tay tên lửa, lao nhanh và nhảy xa. Nhưng giáp mỏng, đừng lao đầu bừa."],
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
			["kengo", "Elek States! Billy the Rod phóng điện. Chém chậm hơn, nhưng nhát cuối phá được giáp."],
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
			["kengo", "Fire States! Súng Hee-Hackgun bắn cầu lửa từ xa. Giữ khoảng cách, đừng để bị áp sát."],
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
