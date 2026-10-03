extends RefCounted
## Thế giới 22 · Kamen Rider Saber (2020) — "Viết lại cái kết"
## Echo Rider: Kamiyama Touma (tiểu thuyết gia, Kiếm sĩ Lửa, "Cái kết của câu chuyện, tôi sẽ quyết định!").
## Hỗ trợ: Shindo Rintaro (Kiếm sĩ Nước, Blades). Quái: Shimi, Megid. Trùm: Storious, thi sĩ tin mọi câu chuyện
## đều phải kết thúc bằng diệt vong. Mạch Hồi 3: hy vọng câu chuyện của Rei còn viết lại được.

const WORLD := {
	"id": "saber",
	"year": 2020,
	"name": "Thế giới Saber",
	"motto": "Viết lại cái kết",
	"rider": &"saber",
	"rider_name": "Saber",
	"driver_name": "Seiken Swordriver",
	"color": Color(1.0, 0.3, 0.22),
	"enemies": {
		"basic": {"name": "Shimi", "color": Color(0.68, 0.62, 0.5), "sprite": "shimi"},
		"fast": {"name": "Piranha Megid", "color": Color(0.35, 0.75, 0.8), "sprite": "piranha_megid"},
		"armored": {"name": "Golem Megid", "color": Color(0.6, 0.52, 0.42), "sprite": "golem_megid"},
	},
	"unlocks": [
		"Brave Dragon (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Xross Saber: Final Attack x1.5",
	],
	"stages": [
		{"name": "Hiệu sách Kamiyama", "goal": "Đi hết câu chuyện trong sách, rút thánh kiếm Kaenken Rekka để đánh thức Seiken Swordriver",
			"bg": "saber_1", "bg_theme": "library"},
		{"name": "Wonder World: Tây Du", "form": &"crimson_dragon", "form_name": "Crimson Dragon",
			"bg": "saber_2", "bg_theme": "book_world"},
		{"name": "Căn cứ phương Bắc", "form": &"dragonic_knight", "form_name": "Dragonic Knight",
			"bg": "saber_3", "bg_theme": "library"},
		{"name": "Wonder World: Lâu đài cổ tích", "form": &"elemental_dragon", "form_name": "Elemental Primitive Dragon",
			"bg": "saber_4", "bg_theme": "book_world"},
		{"name": "Trùm: Storious", "bg": "saber_b", "bg_theme": "boss_storm",
			"boss": {"name": "Storious", "hp": 320.0, "damage": 18.0, "poise": 30.0, "speed": 65.0,
				"traits": ["armored"], "color": Color(0.55, 0.6, 0.9)}},
	],
}

## Saber: kiếm sĩ, form gốc đã cầm kiếm Kaenken Rekka. Crimson Dragon (Brave Dragon + Storm Eagle + Saiyuu Journey)
## có cánh và gậy Như Ý: nhanh, đánh xa; Dragonic Knight giáp hiệp sĩ, chậm và nặng; Elemental Primitive Dragon gom
## mọi nguyên tố vào một kiếm, mạnh và nhanh.
const RIDER := {
	"name": "Kamen Rider Saber",
	"tagline": "Kiếm sĩ lửa · ba cuốn sách, hiệp sĩ rồng, kiếm nguyên tố",
	"base": &"brave_dragon",
	"order": [&"brave_dragon", &"crimson_dragon", &"dragonic_knight", &"elemental_dragon"],
	"forms": {
		&"brave_dragon": {"name": "Brave Dragon", "style": "blade", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.12, "poise": 9.0, "final": "Kaen Juujizan",
			"skills": [
				{"name": "Kaenken Slash", "type": "aim", "move": "dash", "tags": [&"burn"], "anim": "slash", "fx": "fire",
					"color": Color(1.0, 0.5, 0.1)},
				{"name": "Wonder Ride: Dragon", "type": "lock", "tags": [&"burn"], "summon": "dragon", "fx": "dragon",
					"color": Color(0.95, 0.15, 0.2)},
			]},
		&"crimson_dragon": {"name": "Crimson Dragon", "style": "lancer", "hp": 140.0, "armor": 14.0, "speed": 168.0,
			"jump": 1.35, "atk": 0.95, "poise": 5.0, "final": "Sansatsu Giri",
			"skills": [
				{"name": "Crimson Wing", "type": "buff", "buff": {"fly": true, "time": 4.0}, "fx": "wings",
					"color": Color(0.95, 0.15, 0.3)},
				{"name": "Triple Strike", "type": "aim", "move": "dash", "hits": 3, "tags": [&"burn"], "anim": "heavy",
					"fx": "slash", "color": Color(1.0, 0.65, 0.2)},
			]},
		&"dragonic_knight": {"name": "Dragonic Knight", "style": "heavy", "hp": 205.0, "armor": 58.0, "speed": 84.0,
			"jump": 0.85, "atk": 1.4, "poise": 19.0, "final": "Shinka Ryuuhazan",
			"skills": [
				{"name": "Knight Shield", "type": "counter", "fx": "shield", "color": Color(0.8, 0.85, 1.0)},
				{"name": "Dragon Lance", "type": "aim", "move": "dash", "tags": [&"crush", &"heavy"], "anim": "heavy",
					"fx": "drill", "color": Color(0.3, 0.5, 1.0), "icon": "slash"},
			]},
		&"elemental_dragon": {"name": "Elemental Primitive Dragon", "style": "blade", "hp": 165.0, "armor": 28.0,
			"speed": 145.0, "jump": 1.1, "atk": 1.3, "poise": 11.0, "final": "Hissatsu Dokuha",
			"skills": [
				{"name": "Element Shift", "type": "buff", "buff": {"elements": true, "time": 6.0}, "fx": "rings3",
					"color": Color(0.95, 0.85, 0.4)},
				{"name": "Elemental Wave", "type": "area", "tags": [&"burn", &"freeze", &"shock"], "fx": "water",
					"radius": 85.0, "anim": "slash", "summon": "wind", "color": Color(0.35, 0.8, 1.0), "icon": "shockwave"},
			]},
	},
	"lv5": {"name": "Xross Saber", "final_mult": 1.5},
}

const SPEAKERS := {
	"touma": {"name": "KAMIYAMA TOUMA", "color": Color(1.0, 0.45, 0.35), "portrait": "touma",
		"look": "hair=2a1e1a jacket=b02a26 stripe=f0dca0 eyes=3a2a20"},
	"rintaro": {"name": "SHINDO RINTARO", "color": Color(0.4, 0.65, 1.0), "portrait": "rintaro",
		"look": "hair=18181e jacket=24448a stripe=e8f0f8 eyes=2a2a3a"},
	"storious": {"name": "STORIOUS", "color": Color(0.65, 0.7, 1.0), "portrait": "storious",
		"look": "base=daguba tint=6a70c0"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Saber · Hiệu sách Kamiyama."],
			["touma", "Kamiyama Touma, tiểu thuyết gia kiêm chủ tiệm. Void đã nhốt thánh kiếm Kaenken Rekka vào trong một cuốn sách."],
			["touma", "Muốn rút kiếm, phải đi hết câu chuyện trong đó. Lũ Shimi đang gặm nát từng trang."],
			["hero", "Đi hết một câu chuyện... Nếu cái kết đã được viết sẵn thì sao?"],
		],
		"goal": [
			["touma", "Trang cuối! Kaenken Rekka cắm ở đó, Megid đang canh. Nhanh lên, trước khi chúng xé mất trang!"],
		],
		"key": [
			["narrator", "{name} rút Kaenken Rekka. Cuốn Brave Dragon mở ra, một con rồng lửa lượn quanh rồi hóa thành giáp."],
			["touma", "Cái kết của câu chuyện, tôi sẽ quyết định! ...Giờ tới lượt cậu."],
			["hero", "Henshin!"],
		],
		"clear": [
			["pen", "Brave Dragon là form gốc: kiếm lửa, ba nhát chém rồi một nhát phá giáp. Các Wonder Ride Book khác nằm trong tay Megid."],
		],
	},
	"2": {
		"start": [
			["rintaro", "Shindo Rintaro, Kiếm sĩ Nước của Sword of Logos. Piranha Megid bơi qua các trang Tây Du, nhanh lắm."],
			["pen", "Storm Eagle và Saiyuu Journey đang rơi đâu đó quanh đây. Ghép cùng Brave Dragon là thành Wonder Combo!"],
		],
		"key": [
			["touma", "Crimson Dragon! Cánh đại bàng, gậy Như Ý. Bay nhảy nhẹ, đánh xa và nhanh, nhưng giáp mỏng."],
		],
		"clear": [
			["rintaro", "Kiếm sĩ bảo vệ sách vì mỗi cuốn là ký ức của một thế giới. Mất sách, thế giới đó cũng mất theo."],
			["hero", "Anh tôi cũng bị xóa khỏi một dòng thời gian. Có cuốn sách nào còn nhớ anh ấy không?"],
		],
	},
	"3": {
		"start": [
			["rintaro", "Căn cứ phương Bắc bị Golem Megid tấn công. Người chúng là đá, kiếm nước của tôi chỉ làm ướt thôi."],
		],
		"key": [
			["touma", "Dragonic Knight! Giáp hiệp sĩ rồng. Chậm và nặng, nhưng mỗi nhát kiếm nghiền nát cả đá."],
		],
		"clear": [
			["touma", "Hồi nhỏ, tôi hứa viết một câu chuyện cho Luna, cô bạn bị cuốn vào thế giới trong sách. Tôi chưa bao giờ bỏ lời hứa đó."],
			["hero", "Vậy tôi cũng hứa. Tôi sẽ viết lại câu chuyện của anh Rei."],
		],
	},
	"4": {
		"start": [
			["pen", "Lâu đài cổ tích. Megid nhanh, Megid giáp, Shimi bay kín trời. Không form nào gánh nổi một mình."],
		],
		"key": [
			["touma", "Elemental Primitive Dragon! Lửa, nước, gió, đất gom vào một thanh kiếm. Mạnh và nhanh. Đừng để nó điều khiển cậu."],
		],
		"clear": [
			["rintaro", "Storious đang chờ ở trang cuối. Hắn tin mọi câu chuyện đều phải kết thúc bằng diệt vong."],
			["touma", "Hắn từng là một thi sĩ. Rồi hắn đọc một cái kết buồn, và không bao giờ tin vào cái kết nào khác nữa."],
		],
	},
	"B": {
		"goal": [
			["storious", "Thế giới này, và cả câu chuyện của anh trai ngươi, đều đã có cái kết. Ta chỉ đọc nốt trang cuối thôi."],
			["hero", "Vậy thì tôi sẽ viết thêm một trang nữa."],
			["touma", "Cái kết của câu chuyện này, cậu ấy sẽ quyết định!"],
		],
		"clear": [
			["narrator", "Storious tan thành những trang giấy. Giữa đó là một chiếc đai có con dấu, bọc tinh thể tím: Revice Driver."],
			["narrator", "Sức mạnh Saber trở về trọn vẹn. Xross Saber!"],
			["storious", "...Hóa ra, một câu chuyện có hậu... cũng đẹp thật."],
			["touma", "Câu chuyện của Rei chưa kết thúc đâu. Chừng nào còn người muốn viết tiếp, thì vẫn còn trang sau."],
			["pen", "Revice Driver. Thế giới tiếp theo là ác quỷ trong mỗi con người, {name}. Cả trong cậu nữa."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Saber đã sáng lại. Chặng tiếp theo: Trái Đất Revice, nơi mỗi người mang một ác quỷ bên trong."],
	["hero", "Ác quỷ của tôi... chắc là nỗi sợ phải đánh chính anh mình."],
]
