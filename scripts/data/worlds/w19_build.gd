extends RefCounted
## Thế giới 19 · Kamen Rider Build (2017) — "Love & Peace"
## Echo Rider: Kiryu Sento (thiên tài vật lý, từng mất trí nhớ, khuôn mặt vốn của người khác). Hỗ trợ: Banjo Ryuga
## (cựu võ sĩ, Cross-Z). Quái: Smash, Guardian. Trùm: Evolto, kẻ đã hủy diệt Sao Hỏa.
## Thức tỉnh: hạ Smash, tịnh hóa Fullbottle Rabbit và Tank.

const WORLD := {
	"id": "build",
	"year": 2017,
	"name": "Thế giới Build",
	"motto": "Love & Peace",
	"rider": &"build",
	"rider_name": "Build",
	"driver_name": "Build Driver",
	"color": Color(0.3, 0.6, 1.0),
	"enemies": {
		"basic": {"name": "Guardian", "color": Color(0.5, 0.6, 0.75)},
		"fast": {"name": "Flying Smash", "color": Color(0.55, 0.85, 0.45)},
		"armored": {"name": "Strong Smash", "color": Color(0.75, 0.45, 0.35)},
	},
	"unlocks": [
		"RabbitTank (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Genius Form: Final Attack x1.5",
	],
	"stages": [
		{"name": "Phố Touto dưới Sky Wall", "goal": "Hạ Smash, tịnh hóa Fullbottle Rabbit và Tank để kích hoạt Build Driver",
			"bg": "build_1", "bg_theme": "sky_wall"},
		{"name": "Viện Vật lý Tiên tiến Touto", "form": &"gorilla_mond", "form_name": "GorillaMond",
			"bg": "build_2", "bg_theme": "lab"},
		{"name": "Vùng trời biên giới Hokuto", "form": &"hawk_gatling", "form_name": "HawkGatling",
			"bg": "build_3", "bg_theme": "sky_wall"},
		{"name": "Căn cứ Seito về đêm", "form": &"ninnin_comic", "form_name": "NinninComic",
			"bg": "build_4", "bg_theme": "city_night"},
		{"name": "Trùm: Evolto", "bg": "build_b", "bg_theme": "boss_red",
			"boss": {"name": "Evolto", "hp": 300.0, "damage": 18.0, "poise": 28.0, "speed": 78.0,
				"traits": ["fast"], "color": Color(0.88, 0.22, 0.32)}},
	],
}

## Build: mỗi Best Match hai nửa. RabbitTank nhảy xa, đấm chắc; GorillaMond chậm, đấm vỡ thép; HawkGatling bay nhảy,
## súng Hawk Gatlinger bắn như mưa nhưng giáp mỏng; NinninComic nhanh như ninja, kiếm Yonkoma Ninpoutou chém lửa.
const RIDER := {
	"name": "Kamen Rider Build",
	"tagline": "Best Match · thỏ nhảy xa, đấm kim cương, diều hâu bắn, ninja chém",
	"base": &"rabbit_tank",
	"order": [&"rabbit_tank", &"gorilla_mond", &"hawk_gatling", &"ninnin_comic"],
	"forms": {
		&"rabbit_tank": {"name": "RabbitTank", "style": "brawler", "hp": 160.0, "armor": 28.0, "speed": 132.0,
			"jump": 1.3, "atk": 1.05, "poise": 7.0, "final": "Vortex Finish"},
		&"gorilla_mond": {"name": "GorillaMond", "style": "heavy", "hp": 205.0, "armor": 58.0, "speed": 82.0,
			"jump": 0.85, "atk": 1.42, "poise": 19.0, "final": "Vortex Finish"},
		&"hawk_gatling": {"name": "HawkGatling", "style": "gunner", "hp": 140.0, "armor": 14.0, "speed": 125.0,
			"jump": 1.35, "atk": 0.9, "poise": 4.0, "final": "Full Bullet",
			"gun": {"damage": 4.5, "speed": 460.0, "cooldown": 0.16, "spread": 0.08, "radius": 2.5,
				"color": Color(0.95, 0.8, 0.35), "life": 0.7}},
		&"ninnin_comic": {"name": "NinninComic", "style": "blade", "hp": 138.0, "armor": 14.0, "speed": 170.0,
			"jump": 1.3, "atk": 1.1, "poise": 6.0, "final": "Kaen Giri"},
	},
	"lv5": {"name": "Genius", "final_mult": 1.5},
}

const SPEAKERS := {
	"sento": {"name": "KIRYU SENTO", "color": Color(0.45, 0.7, 1.0), "portrait": "sento",
		"look": "hair=2a2226 jacket=34343e stripe=e03a3a eyes=3a2a20"},
	"banjo": {"name": "BANJO RYUGA", "color": Color(0.35, 0.55, 1.0), "portrait": "banjo",
		"look": "hair=4a321e jacket=2a4aa0 stripe=e8e8e8 eyes=3a2a20"},
	"evolto": {"name": "EVOLTO", "color": Color(0.95, 0.35, 0.4), "portrait": "evolto", "look": "base=kuuga tint=a01e30"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Build · Phố Touto, dưới chân Sky Wall."],
			["sento", "Kiryu Sento, thiên tài vật lý. Tự giới thiệu vậy thôi, chứ thiên tài thì ai chẳng nhận ra. Build Driver của tôi bị khóa."],
			["sento", "Muốn mở phải có một Best Match: Rabbit và Tank. Thành phần của chúng đang nằm trong người lũ Smash kia."],
			["pen", "Hạ Smash, thu thành phần, tịnh hóa thành Fullbottle. Nghe như bài thí nghiệm thực hành ấy nhỉ."],
		],
		"goal": [
			["sento", "Hai con Smash cuối cùng! Một con mang thành phần Rabbit, một con mang Tank. Nào, bắt đầu thí nghiệm thôi!"],
		],
		"key": [
			["narrator", "Rabbit! Tank! Best Match! Tay quay xoay tít, hai nửa giáp đỏ và xanh ép lại quanh {name}."],
			["sento", "Are you ready?"],
			["hero", "Henshin!"],
		],
		"clear": [
			["pen", "RabbitTank là form gốc: chân thỏ nhảy xa, tay xe tăng đấm chắc. Các Best Match khác nằm trong đám Smash."],
		],
	},
	"2": {
		"start": [
			["banjo", "Banjo Ryuga, cựu võ sĩ quyền anh! Lũ Guardian đang phá viện nghiên cứu, người tụi nó toàn sắt!"],
			["sento", "Đấm tay không vào sắt thì chỉ có tên ngốc này làm. Ta cần Gorilla và Diamond."],
		],
		"key": [
			["sento", "GorillaMond! Tay khỉ đột, thân kim cương. Chậm như rùa, nhưng mỗi cú đấm làm vỡ cả thép."],
		],
		"clear": [
			["banjo", "Này, sao cậu phải đánh nhau vì người lạ vậy? Tôi thì đánh để rửa oan cho mình thôi."],
			["hero", "Tôi đi tìm anh trai. Nhưng dọc đường, người lạ nào cũng đáng được cứu."],
		],
	},
	"3": {
		"start": [
			["sento", "Biên giới Hokuto. Flying Smash lượn sát Sky Wall, tay khỉ đột không với tới."],
		],
		"key": [
			["sento", "HawkGatling! Cánh diều hâu, súng Hawk Gatlinger. Nhảy cao, bắn như mưa. Bù lại, giáp mỏng."],
		],
		"clear": [
			["sento", "Khoa học tạo ra được Sky Wall, cũng tạo ra được vũ khí. Nhưng nó phải được dùng để con người sống tốt hơn."],
			["sento", "Love & Peace. Nghe sến, nhưng đó là định luật duy nhất tôi không bao giờ phá."],
		],
	},
	"4": {
		"start": [
			["banjo", "Căn cứ Seito! Smash cứng như đá, lẫn cả lính bay. Đổi form liên tục đi, cái đầu tôi thì chịu."],
		],
		"key": [
			["sento", "NinninComic! Kiếm Yonkoma Ninpoutou. Nhanh như ninja, chém ra lửa, nhưng máu mỏng. Đừng đứng yên."],
		],
		"clear": [
			["sento", "Tôi từng mất trí nhớ. Rồi phát hiện khuôn mặt mình vốn thuộc về một người khác."],
			["sento", "Tên và mặt có thể bị đánh tráo. Nhưng việc cậu chọn làm hôm nay mới là con người thật của cậu."],
			["pen", "......"],
		],
	},
	"B": {
		"goal": [
			["evolto", "Ciao~! Ta là Evolto, kẻ đã nuốt trọn Sao Hỏa. Driver của thế giới sau trông ngon quá, để ta giữ nhé?"],
			["sento", "Định luật chiến thắng đã được xác lập!"],
			["banjo", "Giờ tôi chẳng thấy mình có thể thua! Đúng không, {name}?"],
		],
		"clear": [
			["narrator", "Evolto vỡ thành bụi đỏ. Giữa đó là một chiếc đai có mặt đồng hồ, bọc tinh thể tím: Ziku Driver."],
			["narrator", "Sức mạnh Build trở về trọn vẹn. Genius Form!"],
			["sento", "Khoa học vì con người, sức mạnh vì Love & Peace. Mang theo cả hai nhé, {name}."],
			["pen", "Ziku Driver của Zi-O. Thế giới của thời gian, và của một cuốn sách biết trước tương lai. ...Tôi hơi sợ nơi đó."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Build đã sáng lại. Chặng tiếp theo: Trái Đất Zi-O, nơi một cậu trai muốn trở thành vua của thời gian."],
	["hero", "Pen, cậu im lặng từ lúc Sento nói về khuôn mặt bị đánh tráo. Có chuyện gì à?"],
	["pen", "...Tới Zi-O rồi cậu sẽ biết. Tôi hứa."],
]
