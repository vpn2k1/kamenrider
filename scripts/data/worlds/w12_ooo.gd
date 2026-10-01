extends RefCounted
## Thế giới 12 · Kamen Rider OOO (2010) — "Ham muốn và bàn tay chìa ra"
## Echo Rider: Hino Eiji (hiền, "chút tiền lẻ và cái quần lót cho ngày mai"). Hỗ trợ: Ankh (Greeed, mê kem que).
## Quái: Yummy sinh ra từ ham muốn con người. Trùm: Kazari (Greeed hệ Mèo).
## Bài học: dám chìa tay ra. Pen lần đầu nói mình có một "ham muốn".

const WORLD := {
	"id": "ooo",
	"year": 2010,
	"name": "Thế giới OOO",
	"motto": "Ham muốn và bàn tay chìa ra",
	"rider": &"ooo",
	"rider_name": "OOO",
	"driver_name": "OOO Driver",
	"color": Color(0.95, 0.38, 0.2),
	"enemies": {
		"basic": {"name": "Waste Yummy", "color": Color(0.72, 0.66, 0.52)},
		"fast": {"name": "Neko Yummy", "color": Color(0.92, 0.85, 0.6)},
		"armored": {"name": "Bison Yummy", "color": Color(0.55, 0.42, 0.32)},
	},
	"unlocks": [
		"TaToBa Combo (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"TaJaDor Combo: Final Attack x1.5",
	],
	"stages": [
		{"name": "Nhà hàng Cous Coussier", "goal": "Hạ Waste Yummy, giành lại O Scanner cho OOO Driver",
			"bg": "ooo_1", "bg_theme": "city_day"},
		{"name": "Phố mua sắm lúc chiều", "form": &"latorartar", "form_name": "LaTorarTar Combo",
			"bg": "ooo_2", "bg_theme": "city_dusk"},
		{"name": "Bến cảng Tokyo", "form": &"shauta", "form_name": "ShaUTa Combo",
			"bg": "ooo_3", "bg_theme": "coast"},
		{"name": "Tòa nhà Tập đoàn Kougami", "form": &"sagohzo", "form_name": "SaGohZo Combo",
			"bg": "ooo_4", "bg_theme": "city_night"},
		{"name": "Trùm: Kazari", "bg": "ooo_b", "bg_theme": "boss_gold",
			"boss": {"name": "Kazari", "hp": 250.0, "damage": 16.0, "poise": 22.0, "speed": 85.0,
				"traits": [], "color": Color(0.95, 0.78, 0.25)}},
	],
}

## OOO: đổi bộ ba Core Medal. LaTorarTar (Lion-Tora-Cheetah) chạy nhanh, cào vuốt liên hoàn; ShaUTa (Shachi-Unagi-Tako)
## quất roi điện Unagi tầm xa; SaGohZo (Sai-Gorilla-Zou) chậm, giáp dày, đòn nào cũng phá giáp.
const RIDER := {
	"name": "Kamen Rider OOO",
	"tagline": "Đổi Medal · vuốt siêu tốc, roi điện, giáp nặng",
	"base": &"tatoba",
	"order": [&"tatoba", &"latorartar", &"shauta", &"sagohzo"],
	"forms": {
		&"tatoba": {"name": "TaToBa Combo", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.15, "atk": 1.05, "poise": 7.0, "final": "Tatoba Kick"},
		&"latorartar": {"name": "LaTorarTar Combo", "style": "blade", "hp": 135.0, "armor": 10.0, "speed": 178.0,
			"jump": 1.25, "atk": 0.95, "poise": 5.0, "final": "Gush Cross"},
		&"shauta": {"name": "ShaUTa Combo", "style": "lancer", "hp": 150.0, "armor": 15.0, "speed": 135.0,
			"jump": 1.15, "atk": 0.95, "poise": 5.0, "final": "Octo Banish"},
		&"sagohzo": {"name": "SaGohZo Combo", "style": "heavy", "hp": 205.0, "armor": 58.0, "speed": 82.0,
			"jump": 0.8, "atk": 1.42, "poise": 19.0, "final": "Sagohzo Impact"},
	},
	"lv5": {"name": "TaJaDor", "final_mult": 1.5},
}

const SPEAKERS := {
	"eiji": {"name": "HINO EIJI", "color": Color(0.95, 0.5, 0.3), "portrait": "eiji",
		"look": "hair=2e2018 jacket=b4885a stripe=e8dcc0 eyes=3c2a1e"},
	"ankh": {"name": "ANKH", "color": Color(0.95, 0.3, 0.25), "portrait": "ankh",
		"look": "hair=e6c060 jacket=c83a2a stripe=202020 eyes=b43a2a"},
	"kazari": {"name": "KAZARI", "color": Color(0.95, 0.8, 0.3), "portrait": "kazari",
		"look": "base=grongi tint=e0b030"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất OOO · Nhà hàng Cous Coussier."],
			["eiji", "Hino Eiji, phục vụ ở đây. Tôi chỉ cần chút tiền lẻ và một cái quần lót cho ngày mai là đủ sống."],
			["ankh", "Bớt lảm nhảm. OOO Driver có Medal rồi, nhưng thiếu O Scanner để quét. Lũ Waste Yummy cướp mất."],
			["pen", "Ở thế giới này, Yummy sinh ra từ ham muốn của con người. Hạ chúng, O Scanner sẽ rơi ra!"],
		],
		"goal": [
			["ankh", "Con đầu đàn đang ôm O Scanner kìa. Lấy về, rồi giao hết Medal cho tôi giữ."],
		],
		"key": [
			["hero", "Henshin!"],
			["narrator", "O Scanner lướt qua ba Medal. TAKA! TORA! BATTA! Ta-To-Ba, TaToBa, Ta-To-Ba!"],
			["eiji", "Bài hát đó thì cứ kệ nó. Lần nào biến thân nó cũng tự hát."],
		],
		"clear": [
			["pen", "TaToBa là form gốc: mắt Taka, vuốt Tora, chân Batta nhảy cao. Medal khác nằm trong bụng lũ Yummy."],
		],
	},
	"2": {
		"start": [
			["eiji", "Neko Yummy đang chạy khắp phố mua sắm. Nó nhanh lắm, trong bụng còn Medal Lion và Cheetah."],
		],
		"key": [
			["eiji", "LION! TORA! CHEETAH! LaTorarTar! Chân Cheetah chạy như gió, vuốt Tora cào liên hoàn. Giáp thì mỏng."],
		],
		"clear": [
			["eiji", "{name}, trông cậu có tâm sự. Kể nghe được không?"],
			["hero", "Tôi đang đuổi theo một người hình như biết anh trai tôi. Nhưng càng đuổi, càng thấy xa."],
			["eiji", "Tay với tới mà không với, sau này sẽ hối hận lắm. Tôi từng như thế rồi. Cứ chìa tay ra đi."],
		],
	},
	"3": {
		"start": [
			["ankh", "Dưới nước có Yummy của Mezool làm tổ. Trong đó là Medal Shachi, Unagi, Tako."],
		],
		"key": [
			["eiji", "SHACHI! UNAGI! TAKO! ShaUTa! Hai roi điện Unagi quất rất xa. Cứ giữ khoảng cách mà đánh."],
		],
		"clear": [
			["pen", "Hồi còn ở với Void, tôi chỉ là một cái thẻ. Không có ham muốn gì hết."],
			["ankh", "Hừ. Không có ham muốn thì đã chẳng nói ra câu đó."],
			["pen", "...Tôi muốn đi cùng {name} tới cuối đường. Vậy có tính là ham muốn không?"],
		],
	},
	"4": {
		"start": [
			["eiji", "Bison Yummy húc sập cả sảnh Tập đoàn Kougami. Giáp nó dày quá, đòn thường chỉ gãi ngứa."],
		],
		"key": [
			["eiji", "SAI! GORILLA! ZOU! SaGohZo! Đập ngực là đất rung. Chậm, nhưng đòn nào cũng phá giáp."],
		],
		"clear": [
			["ankh", "Kazari đang gom Medal để thành Greeed hoàn chỉnh. Năng lượng Void làm nó càng đói."],
			["eiji", "Kazari muốn tất cả. Còn tụi mình chỉ cần nắm lấy những bàn tay đang chìa ra."],
		],
	},
	"B": {
		"goal": [
			["kazari", "Ham muốn là thứ đẹp nhất trên đời. Medal của ngươi... đưa hết cho ta."],
			["hero", "Ham muốn của tôi là tìm lại anh trai, và giữ lấy người đang đi cùng mình. Anh không lấy được đâu."],
		],
		"clear": [
			["narrator", "Kazari vỡ thành mưa Cell Medal. Giữa đống xu bạc là một chiếc đai trắng bọc tinh thể tím: Fourze Driver."],
			["narrator", "Ba Core Medal đỏ bùng cháy. TAKA! KUJAKU! CONDOR! TaJaDor!"],
			["ankh", "Medal của tôi đấy. Cho mượn thôi, đừng có tưởng bở."],
			["eiji", "Có những thứ tay không với tới. Nhưng đừng bao giờ thôi chìa tay ra, {name}."],
			["pen", "Fourze Driver: bốn khe công tắc và một cần gạt. Thế giới kế tiếp... có trường học, và cả vũ trụ?"],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất OOO sáng lại. Chặng tiếp theo: Trái Đất Fourze, một trường trung học có căn cứ trên Mặt Trăng!"],
	["hero", "Trường học à? Lâu lắm rồi tôi mới bước vào cổng trường. Hơi hồi hộp đấy."],
]
