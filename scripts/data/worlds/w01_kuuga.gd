extends RefCounted
## Thế giới 1 · Kamen Rider Kuuga (2000) — "Vì nụ cười"
## Rider có script riêng: scripts/riders/kuuga.gd (RIDER để trống). Màn 1-1 chơi ở dạng người.

const WORLD := {
	"id": "kuuga",
	"year": 2000,
	"name": "Thế giới Kuuga",
	"motto": "Vì nụ cười",
	"rider": &"kuuga",
	"rider_name": "Kuuga",
	"driver_name": "Arcle",
	"color": Color(0.9, 0.2, 0.2),
	"enemies": {
		"basic": {"name": "Grongi", "color": Color(0.4, 0.75, 0.35), "sprite": "grongi_zu"},
		"fast": {"name": "Grongi hạng Me", "color": Color(0.6, 0.35, 0.85), "sprite": "grongi_me"},
		"armored": {"name": "Grongi hạng Go", "color": Color(0.5, 0.5, 0.55), "sprite": "grongi_go"},
	},
	"unlocks": [
		"Mighty Form (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Rising: Final Attack x1.5",
	],
	"stages": [
		{"name": "Shibuya hỗn loạn", "goal": "Dạng người: hạ đám Grongi đang giữ Arcle",
			"bg": "shibuya_night", "bg_tint": Color(0.55, 0.52, 0.68), "route": ["right"],
			"waves": [["basic", "basic"], ["basic", "basic", "basic"]]},
		{"name": "Di tích Kuuga", "form": &"dragon", "form_name": "Dragon Form", "bg": "ruins",
			"route": ["right", "up", "right"], "waves": [["basic", "basic", "basic"], ["basic", "basic", "basic"]]},
		{"name": "Tokyo về đêm", "form": &"pegasus", "form_name": "Pegasus Form", "bg": "tokyo",
			"route": ["right", "down", "left"], "waves": [["basic", "basic", "armored"], ["basic", "basic", "basic"]]},
		{"name": "Kho hàng bến cảng", "form": &"titan", "form_name": "Titan Form", "bg": "harbor",
			"route": ["left", "up", "left"], "waves": [["basic", "armored", "basic"], ["armored", "basic", "basic"]]},
		{"name": "Trùm: N-Daguba-Zeba", "bg": "boss_kuuga", "route": ["up", "right"],
			"boss": {"name": "N-Daguba-Zeba", "hp": 260.0, "damage": 16.0, "poise": 30.0, "speed": 60.0,
				"traits": [], "color": Color(0.95, 0.92, 0.8), "sprite": "daguba"},
			"waves": [["basic", "basic"], ["boss"]]},
	],
}

const RIDER := {}

## Giọng đai / tiếng hô (tools/gen_audio.py → audio/voice/<rider>_<khóa>.wav): "henshin" lúc biến thân, khóa = id form
## lúc đổi sang form đó, "final" lúc Final Attack. Mỗi dòng: [kiểu giọng, câu]
## (kiểu giọng: belt / belt_deep / belt_bright / kivat / hero, xem VOICES trong gen_audio.py).
const VOICE := {
	"dragon": ["hero", "超変身!"],
	"pegasus": ["hero", "超変身!"],
	"titan": ["hero", "超変身!"],
}

const SPEAKERS := {
	"godai": {"name": "GODAI", "color": Color(0.95, 0.4, 0.3), "portrait": "godai",
		"look": "hair=462d1e jacket=963728 stripe=ebe1d2 eyes=6e4628"},
	"ichijo": {"name": "THANH TRA ICHIJO", "color": Color(0.7, 0.72, 0.8), "portrait": "ichijo",
		"look": "hair=16161c jacket=464852 stripe=e6e6eb eyes=282832"},
	"daguba": {"name": "N-DAGUBA-ZEBA", "color": Color(0.95, 0.85, 0.5), "portrait": "daguba", "look": "base=daguba"},
}

const STORY := {
	"1": {
		"start": [
			["pen", "Lũ Grongi từ Trái Đất Kuuga tràn qua khe nứt! Một con trong đám đó đang giữ Arcle."],
			["hero", "Tôi phải đánh bằng tay KHÔNG á?!"],
			["pen", "Chưa có Driver thì đành vậy. Đạn đỏ bay ngang ngực thì cúi, đạn xanh sát đất thì nhảy. Đấm liên tục sẽ ra cú đá!"],
		],
		"goal": [
			["pen", "Nhóm canh giữ kia! Arcle chắc chắn nằm trên người một con."],
		],
		"key": [
			["narrator", "Chiếc Arcle phát sáng rồi hòa vào cơ thể {name}. Bộ giáp đỏ hiện ra."],
			["pen", "Nó... chọn cậu rồi! Đây là Kamen Rider Kuuga, Mighty Form."],
			["hero", "Cảm giác này... sức mạnh đang chảy về!"],
		],
		"clear": [
			["narrator", "Mọi thứ đông cứng. Một bóng áo choàng hiện ra trên nóc tòa nhà."],
			["void", "Thằng nhóc giao hàng à. Được thôi."],
			["void", "Sức mạnh tiếp theo nằm trong kẻ mạnh nhất Trái Đất Kuuga. Đi hết chuỗi đi, rồi ta nói chuyện."],
			["pen", "...Cái giọng đó..."],
			["pen", "À, không có gì! Arcle đang cộng hưởng với Chrono Pass. Cổng sang Trái Đất Kuuga mở rồi!"],
		],
	},
	"2": {
		"start": [
			["narrator", "Trái Đất Kuuga · Di tích cổ ở Nagano."],
			["godai", "Cậu cũng đến giúp à? Tốt quá! Tôi là Godai Yusuke."],
			["hero", "Anh là... Kuuga của thế giới này? Mất sức mạnh rồi mà anh không sợ à?"],
			["godai", "Sợ chứ. Nhưng nếu tôi mặt mày ủ rũ thì mọi người còn sợ hơn. (giơ ngón cái)"],
			["pen", "Quái trong di tích đang giữ sức mạnh Dragon Form. Hạ chúng cho tới khi nó rơi ra!"],
		],
		"key": [
			["godai", "Màu xanh! Dragon nhảy cao, chạy nhanh. Bấm Chém để quét gậy Dragon Rod, nhát cuối đẩy bay quái."],
			["pen", "Form đặc biệt ăn nộ. Hết nộ là tự về Mighty, nhớ nhé."],
		],
		"clear": [
			["godai", "Kuuga có nhiều màu lắm, mỗi màu là một cách để bảo vệ người khác."],
			["godai", "Nhưng màu nào rồi cũng phai. Lúc đó cứ quay về màu đỏ, chỗ cậu bắt đầu."],
		],
	},
	"3": {
		"start": [
			["ichijo", "Thanh tra Ichijo, Sở Cảnh sát. Grongi hạng Me bay trên nóc nhà, lính bắn gác dưới đường."],
			["hero", "Chúng ở xa quá, tay chân tôi không với tới!"],
			["pen", "Vậy thì cần một form bắn xa. Sức mạnh Pegasus đang nằm đâu đó trong đám quái này."],
		],
		"key": [
			["ichijo", "Pegasus Bowgun... Được, tôi yểm trợ. Giữ Bắn để bắn liên tục, giữ lên để ngắm lên. Mũi tên khí xuyên cả hàng Grongi."],
		],
		"clear": [
			["ichijo", "Godai hay nói cậu ta chiến đấu vì nụ cười. Còn cậu thì sao, {name}?"],
			["hero", "Tôi... vì anh trai tôi. Anh ấy mất tích trong một vụ cháy, mười năm rồi."],
			["pen", "......"],
		],
	},
	"4": {
		"start": [
			["godai", "Grongi hạng Go đang tụ ở bến cảng. Giáp chúng dày lắm, đòn thường không ăn thua."],
			["pen", "Tường cao thì Dragon, quái bay thì Pegasus. Còn giáp dày... phải có thứ gì đó nặng hơn."],
		],
		"key": [
			["godai", "Màu tím! Titan chậm nhưng cứng như đá. Bấm Chém để đâm Titan Sword. Final đâm trúng là quái bị phong ấn, đứng im."],
		],
		"clear": [
			["pen", "Tín hiệu Void mạnh nhất nằm sâu phía trước. Kẻ mạnh nhất Trái Đất này đang chờ."],
			["godai", "N-Daguba-Zeba. Hắn đánh nhau chỉ để vui thôi. Cẩn thận nhé, {name}."],
		],
	},
	"B": {
		"start": [
			["pen", "Năng lượng Void đặc quánh ở đây... Driver tiếp theo đang bị giấu trong người hắn."],
		],
		"goal": [
			["daguba", "Cậu... sẽ làm tôi vui hơn chứ?"],
			["hero", "Tôi không đến đây để chơi với anh."],
		],
		"clear": [
			["narrator", "Daguba tan thành tro. Giữa đống tro là một chiếc đai bọc trong tinh thể tím: Alter Ring."],
			["narrator", "Sức mạnh của Arcle đã trở về trọn vẹn. Kuuga Rising!"],
			["godai", "Đánh nhau chẳng phải chuyện hay ho. Nhưng nếu phải đánh để giữ nụ cười cho mọi người, thì đừng đánh mất nụ cười của chính mình."],
			["pen", "Alter Ring, sức mạnh của Agito. Bị phong ấn rồi. Phải mang về đúng Trái Đất của nó mới giải được."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Kuuga đã sáng trở lại! Chặng tiếp theo: Trái Đất Agito."],
	["hero", "Một thế giới xong. Còn bao nhiêu nữa..."],
	["pen", "Hai mươi sáu. Theo đúng thứ tự các Rider xuất hiện. Void khóa chuỗi theo dòng thời gian."],
]
