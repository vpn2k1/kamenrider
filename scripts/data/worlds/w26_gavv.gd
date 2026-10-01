extends RefCounted
## Thế giới 26 · Kamen Rider Gavv (2024) — "Vị ngọt của hạnh phúc"
## Echo Rider: Shouma (nửa người nửa Granute, mê đồ ngọt của loài người; ăn kẹo sinh ra Gochizo để biến thân).
## Hỗ trợ: Amane Sachika (giám đốc tiệm vạn năng Hapipare, mong ai cũng hạnh phúc). Quái: Granute của nhà Stomach
## (Agent, Granute làm thuê). Trùm: Bocca Jaldak. Hồi 3: {name} nhớ lại những ngày vui bên anh Rei.
## Nguồn tra cứu: en/ja.wikipedia "Kamen Rider Gavv" (form, chiêu "<form> Finish", Gavvgablade, Over Mode).

const WORLD := {
	"id": "gavv",
	"year": 2024,
	"name": "Thế giới Gavv",
	"motto": "Vị ngọt của hạnh phúc",
	"rider": &"gavv",
	"rider_name": "Gavv",
	"driver_name": "Henshin Belt Gavv",
	"color": Color(1.0, 0.55, 0.88),
	"enemies": {
		"basic": {"name": "Agent", "color": Color(0.35, 0.35, 0.45)},
		"fast": {"name": "Granute làm thuê", "color": Color(0.65, 0.38, 0.82)},
		"armored": {"name": "Granute giáp", "color": Color(0.5, 0.45, 0.5)},
	},
	"unlocks": [
		"Poppingummy Form (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Over Mode: Final Attack x1.5",
	],
	"stages": [
		{"name": "Tiệm vạn năng Hapipare", "goal": "Cứu người bị Granute bắt, giành lại Henshin Belt Gavv",
			"bg": "gavv_1", "bg_theme": "suburb"},
		{"name": "Phố bánh ngọt lúc chiều", "form": &"fuwamallow", "form_name": "Fuwamallow Form",
			"bg": "gavv_2", "bg_theme": "city_dusk"},
		{"name": "Nhà máy kẹo Stomach", "form": &"chocodan", "form_name": "Chocodan Form",
			"bg": "gavv_3", "bg_theme": "candy_factory"},
		{"name": "Lễ hội đồ ngọt về đêm", "form": &"zakuzakuchips", "form_name": "Zakuzakuchips Form",
			"bg": "gavv_4", "bg_theme": "city_night"},
		{"name": "Trùm: Bocca Jaldak", "bg": "gavv_b", "bg_theme": "boss_purple",
			"boss": {"name": "Bocca Jaldak", "hp": 310.0, "damage": 18.0, "poise": 30.0, "speed": 62.0,
				"traits": ["armored"], "color": Color(0.25, 0.42, 0.48)}},
	],
}

## Gavv: mỗi form sinh ra từ một Gochizo. Poppingummy giáp dẻo, cân bằng; Fuwamallow nảy tưng tưng, nhảy cao,
## đòn nhẹ mà xa; Chocodan bắn chuẩn; Zakuzakuchips cầm kiếm Gavvgablade, chém nặng phá giáp.
const RIDER := {
	"name": "Kamen Rider Gavv",
	"tagline": "Đồ ngọt thành sức mạnh · form nảy, form bắn sô-cô-la, form kiếm giòn",
	"base": &"poppingummy",
	"order": [&"poppingummy", &"fuwamallow", &"chocodan", &"zakuzakuchips"],
	"forms": {
		&"poppingummy": {"name": "Poppingummy Form", "style": "brawler", "hp": 165.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.1, "atk": 1.05, "poise": 7.0, "final": "Poppingummy Finish"},
		&"fuwamallow": {"name": "Fuwamallow Form", "style": "lancer", "hp": 140.0, "armor": 12.0, "speed": 160.0,
			"jump": 1.45, "atk": 0.9, "poise": 4.0, "final": "Fuwamallow Finish"},
		&"chocodan": {"name": "Chocodan Form", "style": "gunner", "hp": 145.0, "armor": 15.0, "speed": 115.0,
			"jump": 1.0, "atk": 0.95, "poise": 5.0, "final": "Chocodan Finish",
			"gun": {"damage": 7.5, "speed": 420.0, "cooldown": 0.3, "color": Color(0.82, 0.55, 0.32)}},
		&"zakuzakuchips": {"name": "Zakuzakuchips Form", "style": "blade", "hp": 175.0, "armor": 35.0, "speed": 108.0,
			"jump": 0.95, "atk": 1.3, "poise": 13.0, "final": "Zakuzakuchips Finish"},
	},
	"lv5": {"name": "Over Mode", "final_mult": 1.5},
}

const SPEAKERS := {
	"shouma": {"name": "SHOUMA", "color": Color(1.0, 0.55, 0.75), "portrait": "shouma",
		"look": "hair=5a3a2a jacket=e87aa0 stripe=f8e0f0 eyes=6a4a3a"},
	"sachika": {"name": "AMANE SACHIKA", "color": Color(1.0, 0.8, 0.5), "portrait": "sachika",
		"look": "hair=d8a860 jacket=f0a0c0 stripe=ffffff eyes=4a3030 long"},
	"bocca": {"name": "BOCCA JALDAK", "color": Color(0.4, 0.7, 0.75), "portrait": "bocca",
		"look": "base=daguba tint=3a5a6a"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Gavv · Tiệm vạn năng Hapipare."],
			["sachika", "Amane Sachika, giám đốc Hapipare! Nhận mọi việc, miễn là làm ai đó hạnh phúc. Còn đây là Shouma, nhân viên của tôi."],
			["shouma", "Cái Gavv trên bụng tôi im bặt từ khi Void tới. Granute đang bắt người ở phố bên, mà tôi không biến thân được."],
			["pen", "Henshin Belt Gavv chạy bằng đồ ngọt. Phải có Gochizo, mà Gochizo thì sinh ra khi ăn một món thật ngon."],
		],
		"goal": [
			["shouma", "Con Granute to kia đang giữ Henshin Belt Gavv! Đừng để nó chạy về thế giới Granute."],
		],
		"key": [
			["narrator", "{name} bóc viên kẹo dẻo Shouma đưa. Một Gochizo nhỏ bật ra, nhảy tưng tưng rồi chui vào Henshin Belt Gavv."],
			["shouma", "Ngon đúng không? Cái cảm giác vui đó chính là sức mạnh của Gavv."],
			["hero", "Henshin!"],
		],
		"clear": [
			["pen", "Poppingummy là form gốc: giáp dẻo như kẹo, đấm liên tục. Ăn thêm món ngọt là thêm Gochizo, thêm form!"],
		],
	},
	"2": {
		"start": [
			["sachika", "Phố bánh ngọt bị Agent của nhà Stomach bao vây. Mấy tiệm quen của tôi đều ở đây đó!"],
			["shouma", "Tiệm đầu phố có kẹo marshmallow ngon nhất vùng. Cứu người xong mình ăn nhé!"],
		],
		"key": [
			["shouma", "Fuwamallow! Mềm như kẹo bông, nảy tưng tưng. Nhảy cao, lơ lửng lâu, đánh nhẹ mà với xa."],
		],
		"clear": [
			["hero", "Hồi nhỏ anh Rei hay nướng marshmallow cho tôi. Lúc nào anh cũng để tôi ăn cái đầu tiên."],
			["sachika", "Kỷ niệm ngọt thế cơ mà. Giữ kỹ nhé, đó là thứ không ai cướp được."],
		],
	},
	"3": {
		"start": [
			["shouma", "Nhà máy kẹo của nhà Stomach, gia đình ruột của tôi. Họ làm kẹo bóng tối từ chính con người."],
		],
		"key": [
			["shouma", "Chocodan! Bắn đạn sô-cô-la, chuẩn từng phát. Đứng xa mà ngắm, đừng lao vào."],
		],
		"clear": [
			["shouma", "Gia đình ruột làm kẹo từ nỗi đau của người khác. Còn những người tôi gặp ở đây dạy tôi ăn kẹo để cười."],
			["hero", "Gia đình là mình chọn... Tôi chọn anh Rei. Dù giờ anh ấy là ai đi nữa."],
		],
	},
	"4": {
		"start": [
			["sachika", "Granute giáp tràn vào lễ hội đồ ngọt! Da tụi nó cứng như kẹo đắng, phải có món gì giòn mà chắc mới đấu lại."],
		],
		"key": [
			["shouma", "Zakuzakuchips! Giòn rụm như khoai tây chiên, cầm kiếm Gavvgablade. Chém nặng, giáp vỡ giòn tan."],
		],
		"clear": [
			["hero", "Tôi nhớ rồi. Sinh nhật năm tôi tám tuổi, anh Rei tự làm bánh. Hơi khét, mà ngon nhất đời tôi."],
			["shouma", "Vậy là cậu biết mình chiến đấu vì cái gì rồi. Vì những ngày như vậy."],
		],
	},
	"B": {
		"goal": [
			["bocca", "Hạnh phúc của loài người chỉ là nguyên liệu. Ta sẽ vắt tới giọt cuối cùng."],
			["hero", "Hạnh phúc không phải để vắt. Là để chia nhau, như anh tôi từng chia kẹo cho tôi."],
		],
		"clear": [
			["narrator", "Bocca Jaldak tan biến. Giữa đống kẹo vỡ là một chiếc đai đeo chéo ngực, bọc tinh thể tím: Zeztz Driver."],
			["narrator", "Sức mạnh Gavv trở về trọn vẹn. Over Mode!"],
			["shouma", "Ăn ngon, cười thật tươi. Đó là thứ đáng bảo vệ nhất. Đón anh cậu về rồi mời anh ấy ăn bánh nhé."],
			["sachika", "Nhớ ghé Hapipare nha! Hai anh em tới là giảm giá gấp đôi!"],
			["pen", "Zeztz Driver, đai đeo ngang ngực. Nghe nói người đeo nó chiến đấu... ngay trong giấc mơ."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Gavv sáng rồi. Chặng cuối cùng: Trái Đất Zeztz, thế giới của những giấc mơ."],
	["hero", "Chặng cuối... Anh Rei, đợi em thêm chút nữa."],
]
