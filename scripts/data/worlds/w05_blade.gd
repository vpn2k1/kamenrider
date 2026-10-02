extends RefCounted
## Thế giới 5 · Kamen Rider Blade (2004) — "Chiến đấu với vận mệnh"
## Echo Rider: Kenzaki Kazuma (coi làm Rider là công việc). Hỗ trợ: Aikawa Hajime (Chalice, thật ra là Joker).
## Quái: Undead bất tử, chỉ phong ấn được vào lá bài. Darkroach tràn ra vì Void làm lệch luật Battle Fight.
## Trùm: Caucasus Undead, Vua Bích. Mạch truyện: Void đứng từ xa thử thách; Pen lỡ lời, biết quá rõ cách Void làm việc.

const WORLD := {
	"id": "blade",
	"year": 2004,
	"name": "Thế giới Blade",
	"motto": "Chiến đấu với vận mệnh",
	"rider": &"blade",
	"rider_name": "Blade",
	"driver_name": "Blay Buckle",
	"color": Color(0.3, 0.5, 1.0),
	"enemies": {
		"basic": {"name": "Darkroach", "color": Color(0.38, 0.45, 0.32), "sprite": "darkroach"},
		"fast": {"name": "Jaguar Undead", "color": Color(0.92, 0.72, 0.3), "sprite": "jaguar_undead"},
		"armored": {"name": "Trilobite Undead", "color": Color(0.5, 0.56, 0.64), "sprite": "trilobite_undead"},
	},
	"unlocks": [
		"Ace Form (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"King Form: Final Attack x1.5",
	],
	"stages": [
		{"name": "Viện nghiên cứu BOARD", "goal": "Phong ấn Undead, giành lại lá Change Beetle cho Blay Buckle",
			"bg": "blade_1", "bg_theme": "lab"},
		{"name": "Quán cà phê Hakaranda", "form": &"mach", "form_name": "Mach Jaguar",
			"bg": "blade_2", "bg_theme": "suburb"},
		{"name": "Khu công nghiệp bỏ hoang", "form": &"thunder", "form_name": "Thunder Deer",
			"bg": "blade_3", "bg_theme": "industrial"},
		{"name": "Vách núi lộng gió", "form": &"jack", "form_name": "Jack Form",
			"bg": "blade_4", "bg_theme": "mountain_dawn"},
		{"name": "Trùm: Caucasus Undead", "bg": "blade_b", "bg_theme": "boss_storm",
			"boss": {"name": "Caucasus Undead", "hp": 270.0, "damage": 16.0, "poise": 30.0, "speed": 62.0,
				"traits": ["armored"], "color": Color(0.85, 0.72, 0.35)}},
	],
}

## Blade: mọi form cầm kiếm Blay Rouzer, khác nhau ở lá bài Bích được quẹt. Mach Jaguar nhanh, đâm liên tục;
## Thunder Deer phóng sét từ mũi kiếm (tia nhanh, xuyên hàng, tầm ngắn); Jack Form có cánh, nhảy cao, chém nặng.
const RIDER := {
	"name": "Kamen Rider Blade",
	"tagline": "Kiếm Blay Rouzer · lá bài Bích: tốc độ, sấm sét, đôi cánh",
	"base": &"ace",
	"order": [&"ace", &"mach", &"thunder", &"jack"],
	"forms": {
		&"ace": {"name": "Ace Form", "style": "blade", "hp": 160.0, "armor": 28.0, "speed": 128.0,
			"jump": 1.05, "atk": 1.1, "poise": 8.0, "final": "Lightning Blast", "armed": true, "attacks": {"final": {"tags": [&"shock"]}},
			"fx": {"hit": "spark", "swing": "slash", "final": "lightning", "color": Color(0.55, 0.75, 1.0)}},
		&"mach": {"item": true, "name": "Mach Jaguar", "style": "lancer", "hp": 130.0, "armor": 8.0, "speed": 178.0,
			"jump": 1.3, "atk": 0.88, "poise": 4.0, "final": "Lightning Sonic", "armed": true,
			"fx": {"hit": "spark", "swing": "slash", "trail": true, "final": "lightning", "color": Color(0.45, 0.95, 0.85)}},
		&"thunder": {"item": true, "name": "Thunder Deer", "style": "gunner", "hp": 140.0, "armor": 15.0, "speed": 118.0,
			"jump": 1.0, "atk": 1.0, "poise": 5.0, "final": "Thunder Deer", "armed": true, "attacks": {"final": {"tags": [&"shock"]}},
			"fx": {"hit": "lightning", "swing": "slash", "shot": "bolt", "final": "lightning", "color": Color(1.0, 0.95, 0.45)},
			"gun": {"tags": [&"shock"], "damage": 7.5, "speed": 560.0, "cooldown": 0.42, "radius": 3.0, "color": Color(1.0, 0.95, 0.45),
				"pierce": true, "life": 0.45}},
		&"jack": {"name": "Jack Form", "style": "blade", "hp": 170.0, "armor": 35.0, "speed": 132.0,
			"jump": 1.35, "atk": 1.25, "poise": 11.0, "final": "Lightning Slash", "armed": true, "attacks": {"final": {"tags": [&"shock"]}},
			"fx": {"hit": "spark", "swing": "slash", "glide": true, "final": "lightning", "color": Color(1.0, 0.8, 0.3)}},
	},
	"lv5": {"name": "King Form", "final_mult": 1.5},
	"final_fx": {"intro": "cards"},
}

## Giọng đai / tiếng hô (tools/gen_audio.py → audio/voice/<rider>_<khóa>.wav): "henshin" lúc biến thân, khóa = id form
## lúc đổi sang form đó, "final" lúc Final Attack. Mỗi dòng: [kiểu giọng, câu]
## (kiểu giọng: belt / belt_deep / belt_bright / kivat / hero, xem VOICES trong gen_audio.py).
const VOICE := {
	"henshin": ["belt", "Turn up!"],
	"mach": ["belt", "Mach."],
	"thunder": ["belt", "Thunder."],
	"jack": ["belt", "Absorb Queen. Fusion Jack."],
	"final": ["belt", "Kick. Thunder. Lightning Blast."],
}

const SPEAKERS := {
	"kenzaki": {"name": "KENZAKI KAZUMA", "color": Color(0.4, 0.6, 1.0), "portrait": "kenzaki",
		"look": "hair=2a1e18 jacket=3a4a6a stripe=c8c8d0 eyes=3a2a22"},
	"hajime": {"name": "AIKAWA HAJIME", "color": Color(0.75, 0.3, 0.4), "portrait": "hajime",
		"look": "hair=121216 jacket=2a1a1e stripe=8a2a3a eyes=2a2228"},
	"caucasus": {"name": "CAUCASUS UNDEAD", "color": Color(0.9, 0.78, 0.4), "portrait": "caucasus",
		"look": "base=grongi tint=c8b060"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Blade · Tàn tích viện nghiên cứu BOARD."],
			["kenzaki", "Kenzaki Kazuma, từng là Blade. Cẩn thận: Undead bất tử, chỉ phong ấn vào lá bài được thôi."],
			["pen", "Blay Buckle còn đây, nhưng lá biến thân Change Beetle bị Undead cướp mất. Thiếu lá Ace Bích thì đai chỉ là cục sắt."],
		],
		"goal": [
			["kenzaki", "Con đầu đàn kia! Lá Change Beetle đang phát sáng trên người nó."],
		],
		"key": [
			["narrator", "Lá Change Beetle trượt vào Blay Buckle. TURN UP! Tấm màn ánh sáng xanh dựng lên, {name} lao xuyên qua nó."],
			["hero", "Henshin!"],
		],
		"clear": [
			["kenzaki", "Làm Kamen Rider là công việc của tôi. Không lương, không ngày nghỉ, nhưng tôi chưa từng muốn bỏ."],
			["pen", "Ace Form luôn cầm Blay Rouzer: nút Đánh là chém, nhát cuối phá giáp. Lightning Blast mang sét. Lá bài khác ở trong lũ Undead."],
		],
	},
	"2": {
		"start": [
			["hajime", "Aikawa Hajime. Đừng dính vào chuyện của tôi."],
			["kenzaki", "Darkroach chỉ xuất hiện khi Joker thắng Battle Fight... Sao giờ chúng tràn khắp quán Hakaranda thế này?"],
		],
		"key": [
			["kenzaki", "Mach Jaguar! Nhẹ và nhanh như báo, đâm liên tục từ xa hơn. Giáp mỏng lắm, đừng ham đỡ đòn."],
		],
		"clear": [
			["pen", "Darkroach là do năng lượng Void làm lệch luật Battle Fight. Hắn hay làm vậy lắm."],
			["hero", "Hay làm vậy? Sao cô rành về hắn thế?"],
			["pen", "Tôi... đọc tín hiệu thôi mà! Đi tiếp đi."],
		],
	},
	"3": {
		"start": [
			["kenzaki", "Lũ Undead bám trên giàn thép cao. Kiếm của cậu không với tới đâu."],
			["pen", "Lá Thunder Deer! Blay Rouzer sẽ phóng sét từ mũi kiếm, bắn xuyên cả hàng quái."],
		],
		"key": [
			["kenzaki", "Thunder! Giữ nút Bắn là sét phóng từ mũi kiếm, xuyên cả hàng Undead và lan điện sang con bên cạnh. Tầm ngắn thôi."],
		],
		"clear": [
			["narrator", "Trên đỉnh ống khói phía xa, một bóng áo choàng đứng nhìn xuống. Hắn giơ một lá bài trống lên, rồi bóp nát."],
			["void", "Vận mệnh không đổi được đâu, nhóc. Cứ thử đi."],
			["kenzaki", "Vậy thì tôi sẽ chiến đấu với vận mệnh. Và thắng."],
			["pen", "Hắn không ra tay. Hắn đang thử cậu... giống hệt ngày xưa."],
		],
	},
	"4": {
		"start": [
			["kenzaki", "Eagle Undead và Capricorn Undead ở trên vách núi này. Hai lá J và Q Bích ghép lại là ra Jack Form."],
		],
		"key": [
			["kenzaki", "Jack Form! Giáp vàng, có cánh: giữ Nhảy khi rơi để lượn. Lightning Slash mang sét giật."],
		],
		"clear": [
			["hajime", "Caucasus Undead, Vua Bích, đang đợi trên kia. Hợp nhất với quá nhiều Undead... cái giá không nhỏ đâu."],
		],
	},
	"B": {
		"start": [
			["pen", "Năng lượng Void quấn quanh Vua Bích. Driver kế tiếp bị giấu sau tấm khiên của hắn."],
		],
		"goal": [
			["caucasus", "Battle Fight là cuộc chiến của các loài. Loài người như ngươi chỉ là con mồi."],
			["hero", "Con mồi này biết cắn đấy."],
		],
		"clear": [
			["narrator", "Caucasus Undead bị phong ấn thành lá Evolution Caucasus. Nó để lại một âm thoa bọc tinh thể tím: Henshin Onsa."],
			["narrator", "Đủ mười ba lá Bích. Sức mạnh Blade trở về trọn vẹn: King Form!"],
			["kenzaki", "Vận mệnh không có sẵn đâu, {name}. Cậu đánh tới đâu, nó thành ra tới đó."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Blade đã sáng lại. Chặng tiếp theo: Trái Đất Hibiki, nơi các Oni diệt quái bằng âm thanh."],
	["hero", "Diệt quái... bằng tiếng trống á?"],
]
