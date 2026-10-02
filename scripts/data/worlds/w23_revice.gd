extends RefCounted
## Thế giới 23 · Kamen Rider Revice (2021) — "Ác quỷ bên trong"
## Echo Rider: Igarashi Ikki (con cả nhà tắm Shiawase-yu, sống vì gia đình). Hỗ trợ: Vice, ác quỷ trong lòng Ikki
## (hay đùa, hay nói với khán giả). Quái: Deadmans (Giffjunior, Deadman). Trùm: Giff, thứ Deadmans tôn thờ.
## Hồi 3: Vice nói ra nỗi sợ {name} giấu kín, sợ tới cuối chuỗi phải đánh chính anh trai mình.

const WORLD := {
	"id": "revice",
	"year": 2021,
	"name": "Thế giới Revice",
	"motto": "Ác quỷ bên trong",
	"rider": &"revice",
	"rider_name": "Revice",
	"driver_name": "Revice Driver",
	"color": Color(1.0, 0.42, 0.68),
	"enemies": {
		"basic": {"name": "Giffjunior", "color": Color(0.5, 0.45, 0.58), "sprite": "giffjunior"},
		"fast": {"name": "Deadman", "color": Color(0.72, 0.3, 0.62), "sprite": "deadman"},
		"armored": {"name": "Deadman giáp", "color": Color(0.45, 0.42, 0.5), "sprite": "deadman_armored"},
	},
	"unlocks": [
		"Rex Genome (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Ultimate Revice: Final Attack x1.5",
	],
	"stages": [
		{"name": "Nhà tắm Shiawase-yu", "goal": "Đối mặt ác quỷ trong lòng: hạ Giffjunior, giành lại Revice Driver",
			"bg": "revice_1", "bg_theme": "suburb"},
		{"name": "Mái nhà tổng hành dinh Fenix", "form": &"eagle", "form_name": "Eagle Genome",
			"bg": "revice_2", "bg_theme": "city_day"},
		{"name": "Phố đêm quanh nhà tắm", "form": &"jackal", "form_name": "Jackal Genome",
			"bg": "revice_3", "bg_theme": "city_night"},
		{"name": "Căn cứ Deadmans", "form": &"mammoth", "form_name": "Mammoth Genome",
			"bg": "revice_4", "bg_theme": "underworld"},
		{"name": "Trùm: Giff", "bg": "revice_b", "bg_theme": "boss_red",
			"boss": {"name": "Giff", "hp": 290.0, "damage": 17.0, "poise": 30.0, "speed": 60.0,
				"traits": ["armored"], "color": Color(0.55, 0.16, 0.3)}},
	],
}

## Revice: Rex Genome cân bằng. Eagle bay lượn (nhảy cao nhất, vuốt với xa); Jackal nhanh nhất, đấm đá liên hoàn
## nhưng máu mỏng; Mammoth chậm và to, phá giáp. Chiêu kết mỗi Genome là "Stamping Finish".
const RIDER := {
	"name": "Kamen Rider Revice",
	"tagline": "Một người, một ác quỷ · form bay, form tốc độ, form ma-mút",
	"base": &"rex",
	"order": [&"rex", &"eagle", &"jackal", &"mammoth"],
	"forms": {
		&"rex": {"name": "Rex Genome", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "Rex Stamping Finish"},
		&"eagle": {"name": "Eagle Genome", "style": "lancer", "hp": 140.0, "armor": 12.0, "speed": 150.0,
			"jump": 1.45, "atk": 0.95, "poise": 5.0, "final": "Eagle Stamping Finish"},
		&"jackal": {"name": "Jackal Genome", "style": "brawler", "hp": 130.0, "armor": 8.0, "speed": 180.0,
			"jump": 1.2, "atk": 0.92, "poise": 4.0, "final": "Jackal Stamping Finish"},
		&"mammoth": {"name": "Mammoth Genome", "style": "heavy", "hp": 210.0, "armor": 60.0, "speed": 80.0,
			"jump": 0.8, "atk": 1.45, "poise": 20.0, "final": "Mammoth Stamping Finish"},
	},
	"lv5": {"name": "Ultimate Revice", "final_mult": 1.5},
}

const SPEAKERS := {
	"ikki": {"name": "IGARASHI IKKI", "color": Color(1.0, 0.5, 0.7), "portrait": "ikki",
		"look": "hair=241a14 jacket=4a6a9a stripe=f0e0d0 eyes=3a2a20"},
	"vice": {"name": "VICE", "color": Color(0.75, 0.45, 1.0), "portrait": "vice",
		"look": "base=kuuga tint=b050e0"},
	"giff": {"name": "GIFF", "color": Color(0.8, 0.3, 0.4), "portrait": "giff",
		"look": "base=daguba tint=7a2a4a"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Revice · Nhà tắm công cộng Shiawase-yu."],
			["ikki", "Chào mừng tới Shiawase-yu! Tôi là Igarashi Ikki. Void lấy mất Revice Driver của tôi, cả Vice cũng biến đâu mất."],
			["pen", "Ở thế giới này ai cũng có một ác quỷ trong lòng. Ấn Vistamp lên Revice Driver là con quỷ đó hiện ra thành người."],
		],
		"goal": [
			["ikki", "Giffjunior vây nhà tắm, gia đình tôi còn ở trong! Driver với Rex Vistamp nằm chỗ con dẫn đầu."],
		],
		"key": [
			["narrator", "{name} ấn Rex Vistamp. Từ cái bóng của cậu, một gã hồng tím bật dậy, vươn vai như vừa ngủ trưa xong."],
			["vice", "Yahoo, được ra ngoài rồi! Tôi là Vice... ơ, cậu đâu phải Ikki? Thôi kệ, tạm lập khế ước nhé!"],
			["hero", "Henshin!"],
		],
		"clear": [
			["vice", "Nãy giờ ở trong đầu cậu, tôi nghe hết rồi nha. Dưới đáy có một cái tên cậu cứ giấu mãi: Rei."],
			["pen", "Rex Genome là form gốc, cân bằng mọi mặt. Vistamp khác nằm trong tay Deadmans, hạ tụi nó là có."],
		],
	},
	"2": {
		"start": [
			["ikki", "Deadmans chiếm mái tổng hành dinh Fenix. Tụi nó đứng trên cao, tay chân mình không với tới."],
		],
		"key": [
			["vice", "Eagle Genome! Nhảy cao, lượn xa, vuốt đại bàng với tới xa hơn. Nhẹ ký, nên né đòn chứ đừng đỡ nha."],
		],
		"clear": [
			["vice", "Lúc nãy cậu khựng lại một nhịp. Con Deadman đó cao, gầy, khoác áo choàng... giống ai nhỉ?"],
			["hero", "...Tôi không khựng."],
		],
	},
	"3": {
		"start": [
			["pen", "Deadman chạy vòng vòng khắp phố đêm. Mắt thường theo không kịp đâu."],
			["ikki", "Vice, tới lượt cậu đấy. Cậu nhanh nhất mà!"],
		],
		"key": [
			["vice", "Jackal Genome! Nhanh như chó rừng, đấm đá liên hoàn. Máu hơi mỏng, bù lại chẳng ai đuổi kịp."],
		],
		"clear": [
			["vice", "Tôi là ác quỷ nên nói thẳng nhé: cậu sợ tới cuối chuỗi. Sợ người đứng chờ ở đó là anh cậu."],
			["hero", "Nếu phải đánh anh ấy thì sao? Nếu tôi thắng... tôi có mất anh ấy thêm lần nữa không?"],
		],
	},
	"4": {
		"start": [
			["ikki", "Căn cứ Deadmans. Tụi nó dâng Vistamp để đánh thức Giff. Quái ở đây giáp dày lắm, cần đòn thật nặng."],
		],
		"key": [
			["vice", "Mammoth Genome! To, chậm, nặng như voi ma-mút. Giáp nào cũng nát, cứ lừ lừ mà tiến."],
		],
		"clear": [
			["ikki", "Vice là nỗi sợ, là cả những gì xấu xí trong tôi. Nhưng thiếu cậu ấy, tôi không còn là tôi."],
			["ikki", "Đừng cố xóa con quỷ của cậu, {name}. Nói chuyện với nó. Cậu sợ, là vì cậu thương anh mình."],
		],
	},
	"B": {
		"start": [
			["pen", "Giff. Thứ mà Deadmans tôn thờ như thần. Năng lượng Void quấn quanh nó dày đặc."],
		],
		"goal": [
			["giff", "Ác quỷ của ngươi... thuộc về ta. Dâng nó lên."],
			["hero", "Nỗi sợ này là của tôi. Tôi mang nó theo tới cuối, và vẫn bước tiếp."],
		],
		"clear": [
			["narrator", "Giff vỡ vụn. Giữa làn khói còn lại một chiếc đai bọc tinh thể tím: Desire Driver."],
			["narrator", "Sức mạnh Revice trở về trọn vẹn. Ultimate Revice!"],
			["vice", "Tới giờ tôi về với Ikki rồi. Con quỷ trong cậu thì cứ giữ lấy, nó sẽ chỉ đường về nhà cho cậu."],
			["ikki", "Gia đình là thứ đáng để liều. Đi đón anh trai cậu về đi, {name}!"],
			["pen", "Desire Driver. Đai của một cuộc thi sinh tử, nơi người thắng được biến điều ước thành thật."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Revice đã sáng lại. Chặng tiếp theo: Trái Đất Geats, nơi người ta thi đấu để giành một điều ước."],
	["hero", "Điều ước à... Tôi chỉ có đúng một."],
]
