extends RefCounted
## Thế giới 8 · Kamen Rider Den-O (2007) — "Ký ức chính là thời gian"
## Echo Rider: Nogami Ryotaro (xui xẻo, hiền, là Điểm Đặc Dị). Hỗ trợ: Momotaros (Imagin nóng nảy, "Ore, sanjou!").
## Mỗi form là một Imagin nhập vào {name}: Momotaros (Sword), Urataros (Rod), Kintaros (Ax), Ryutaros (Gun).
## Quái: Imagin. Trùm: Kamen Rider Gaoh. Mạch truyện: Void nói thẳng với Chrono Pass; Ryotaro: "Pass nào cũng nhớ chủ cũ".

const WORLD := {
	"id": "den_o",
	"year": 2007,
	"name": "Thế giới Den-O",
	"motto": "Ký ức chính là thời gian",
	"rider": &"den_o",
	"rider_name": "Den-O",
	"driver_name": "Den-O Belt",
	"color": Color(1.0, 0.35, 0.5),
	"enemies": {
		"basic": {"name": "Mole Imagin", "color": Color(0.62, 0.5, 0.38)},
		"fast": {"name": "Bat Imagin", "color": Color(0.5, 0.35, 0.62)},
		"armored": {"name": "Rhino Imagin", "color": Color(0.5, 0.52, 0.56)},
	},
	"unlocks": [
		"Sword Form (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Climax Form: Final Attack x1.5",
	],
	"stages": [
		{"name": "Quán cà phê Milk Dipper", "goal": "Hạ Imagin, giành lại Rider Pass cho Den-O Belt",
			"bg": "den_o_1", "bg_theme": "city_day"},
		{"name": "Bến sông lúc chiều", "form": &"rod", "form_name": "Rod Form",
			"bg": "den_o_2", "bg_theme": "coast"},
		{"name": "Công trường xây dựng", "form": &"ax", "form_name": "Ax Form",
			"bg": "den_o_3", "bg_theme": "industrial"},
		{"name": "Sa mạc thời gian", "form": &"gun", "form_name": "Gun Form",
			"bg": "den_o_4", "bg_theme": "desert_rails"},
		{"name": "Trùm: Kamen Rider Gaoh", "bg": "den_o_b", "bg_theme": "boss_red",
			"boss": {"name": "Kamen Rider Gaoh", "hp": 280.0, "damage": 18.0, "poise": 28.0, "speed": 72.0,
				"traits": [], "color": Color(0.85, 0.7, 0.3)}},
	],
}

## Den-O: Sword Form (Momotaros) chém bằng DenGasher; Rod Form (Urataros) cần câu dài, đánh xa và nhanh;
## Ax Form (Kintaros) rìu nặng phá giáp; Gun Form (Ryutaros) bắn liên thanh, giáp mỏng.
const RIDER := {
	"name": "Kamen Rider Den-O",
	"tagline": "Bốn Imagin · kiếm, cần câu, rìu, súng",
	"base": &"sword",
	"order": [&"sword", &"rod", &"ax", &"gun"],
	"forms": {
		&"sword": {"name": "Sword Form", "style": "blade", "hp": 165.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.15, "poise": 9.0, "final": "Extreme Slash"},
		&"rod": {"name": "Rod Form", "style": "lancer", "hp": 145.0, "armor": 18.0, "speed": 150.0,
			"jump": 1.15, "atk": 0.95, "poise": 5.0, "final": "Solid Attack"},
		&"ax": {"name": "Ax Form", "style": "heavy", "hp": 210.0, "armor": 55.0, "speed": 82.0,
			"jump": 0.85, "atk": 1.42, "poise": 20.0, "final": "Dynamic Chop"},
		&"gun": {"name": "Gun Form", "style": "gunner", "hp": 138.0, "armor": 12.0, "speed": 135.0,
			"jump": 1.1, "atk": 1.0, "poise": 5.0, "final": "Wild Shot",
			"gun": {"damage": 6.0, "speed": 420.0, "cooldown": 0.22, "radius": 3.0, "color": Color(0.7, 0.4, 1.0),
				"life": 0.9}},
	},
	"lv5": {"name": "Climax Form", "final_mult": 1.5},
}

const SPEAKERS := {
	"ryotaro": {"name": "NOGAMI RYOTARO", "color": Color(0.85, 0.8, 0.65), "portrait": "ryotaro",
		"look": "hair=2a1e16 jacket=8a7a5a stripe=e8e0d0 eyes=3a2a20"},
	"momotaros": {"name": "MOMOTAROS", "color": Color(1.0, 0.35, 0.35), "portrait": "momotaros",
		"look": "base=grongi tint=d83030"},
	"gaoh": {"name": "GAOH", "color": Color(0.9, 0.75, 0.35), "portrait": "gaoh", "look": "base=kuuga tint=b89030"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Den-O · Quán cà phê Milk Dipper."],
			["ryotaro", "Nogami Ryotaro, từng là Den-O. Tôi xui lắm... xui tới mức bị Imagin cướp cả Rider Pass. Không có vé thì Den-O Belt không chạy."],
			["momotaros", "Lũ Imagin kia dám cướp vé hả? Để ta! Từ đầu tới cuối, ta luôn ở cao trào!"],
		],
		"goal": [
			["ryotaro", "Con Mole Imagin kia đang cầm Rider Pass! Cẩn thận, chúng đào đất chui lên đấy."],
		],
		"key": [
			["narrator", "Rider Pass quẹt qua Den-O Belt. Một luồng cát đỏ lao thẳng vào người {name}: Momotaros nhập vào!"],
			["hero", "Ore, sanjou! (Ta đây rồi!)"],
		],
		"clear": [
			["ryotaro", "Imagin bám vào ký ức con người để quay về quá khứ. Ký ức chính là thời gian đấy."],
			["pen", "Sword Form: kiếm DenGasher, chém ba nhát rồi phá giáp. Ba Imagin còn lại đang bị lũ quái nuốt mất."],
		],
	},
	"2": {
		"start": [
			["ryotaro", "Bat Imagin lượn quanh bến sông. Urataros chắc ở gần đây, anh ấy thích chỗ có nước."],
		],
		"key": [
			["narrator", "Một giọng nói ngọt xớt vang lên: Urataros nhập vào! Rod Form cầm cần câu dài, đánh xa hơn, nhẹ mà nhanh."],
			["hero", "Muốn bị tôi câu không?"],
		],
		"clear": [
			["momotaros", "Con rùa dẻo miệng đó mà cũng được ra sân à? Lần sau để ta!"],
		],
	},
	"3": {
		"start": [
			["ryotaro", "Rhino Imagin chiếm công trường, da dày như tường bê tông. Phải nhờ Kintaros thôi, anh ấy khỏe nhất bọn."],
		],
		"key": [
			["narrator", "Tiếng bẻ cổ răng rắc: Kintaros nhập vào! Ax Form chậm, nhưng rìu bổ một nhát là giáp nào cũng vỡ."],
			["hero", "Sức mạnh của ta khiến ngươi phải khóc! Nước mắt thì lau bằng cái này!"],
		],
		"clear": [
			["momotaros", "Con gấu ngủ gật đó giành hết phần rồi! Chán ghê."],
		],
	},
	"4": {
		"start": [
			["pen", "Sa mạc thời gian, nơi tàu Den-Liner chạy qua. Imagin đông lắm, phải đứng xa mà quét. Mong là Ryutaros không dỗi."],
		],
		"key": [
			["narrator", "{name} bỗng nhún nhảy theo điệu nhạc không ai nghe thấy: Ryutaros nhập vào! Gun Form bắn liên thanh, nhưng giáp mỏng."],
			["hero", "Hạ ngươi được chứ? Ta không nghe trả lời đâu!"],
		],
		"clear": [
			["narrator", "Giữa sa mạc, một bóng áo choàng đứng trên đường ray. Hắn không nhìn {name}. Hắn nhìn Chrono Pass."],
			["void", "Ngươi vẫn còn đi theo nó à."],
			["hero", "Pen? Hắn đang nói với cô à?"],
			["pen", "...Hắn nhầm thôi. Pass nào trông chẳng giống nhau."],
			["ryotaro", "Không đâu. Tấm Pass nào cũng nhớ người từng cầm nó."],
		],
	},
	"B": {
		"start": [
			["pen", "Tiếng còi tàu! Gaoh-Liner đang lao tới, thân tàu phủ đầy năng lượng Void."],
		],
		"goal": [
			["gaoh", "Ta là Gaoh. Thời gian, ký ức, thế giới... ta ăn hết."],
			["momotaros", "Ăn hết hả? Nuốt thử kiếm của ta xem! Nhóc, xông lên!"],
			["hero", "Từ đầu tới cuối, tôi cũng đang ở cao trào đây!"],
		],
		"clear": [
			["narrator", "Gaoh tan vào cát thời gian. Trên đường ray còn một chú dơi nhỏ ngủ say trong tinh thể tím: Kivat-bat III."],
			["narrator", "Bốn Imagin cùng nhập vào {name} một lúc. Sức mạnh Den-O trở về trọn vẹn: Climax Form!"],
			["ryotaro", "Chỉ cần còn có người nhớ, thời gian sẽ không mất đi. Anh trai cậu cũng vậy, {name}."],
		],
	},
}

const WORLD_CLEAR := [
	["hero", "Trái Đất Den-O sáng lại rồi. Pen, lúc ở sa mạc... cô có chuyện gì muốn nói với tôi không?"],
	["pen", "...Tới Trái Đất Kiva rồi tôi kể. Hứa đấy."],
]
