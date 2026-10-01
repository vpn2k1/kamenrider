extends RefCounted
## Thế giới 11 · Kamen Rider W (2009) — "Hai người, một Rider"
## Rider có script riêng: scripts/riders/double.gd (RIDER để trống). Pen điều khiển nửa Soul.

const WORLD := {
	"id": "double",
	"year": 2009,
	"name": "Thế giới W",
	"motto": "Hai người, một Rider",
	"rider": &"double",
	"rider_name": "W",
	"driver_name": "Double Driver",
	"color": Color(0.25, 0.85, 0.4),
	"enemies": {
		"basic": {"name": "Dopant", "color": Color(0.3, 0.55, 0.9)},
		"fast": {"name": "Dopant tốc độ", "color": Color(0.6, 0.35, 0.85)},
		"armored": {"name": "Dopant giáp", "color": Color(0.5, 0.5, 0.6)},
	},
	"unlocks": [
		"CycloneJoker (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"Best Match: sát thương +15%",
		"sát thương +40%, máu +32%",
	],
	"stages": [
		{"name": "Văn phòng thám tử", "goal": "Hạ 2 Dopant để lấy lại Gaia Memory Cyclone và Joker", "bg": "fuuto",
			"waves": [["basic", "fast", "basic"], ["armored", "basic", "basic"]]},
		{"name": "Phố gió Fuuto", "form": &"heat_metal", "form_name": "Memory Heat & Metal", "bg": "fuuto_street",
			"route": ["right", "up", "left"], "waves": [["basic", "basic", "basic"], ["armored", "basic", "basic"]]},
		{"name": "Tháp gió", "form": &"luna_trigger", "form_name": "Memory Luna & Trigger", "bg": "wind_tower",
			"route": ["up", "right", "up", "right"], "waves": [["basic", "armored", "basic"], ["armored", "basic", "armored"]]},
		{"name": "Khu công nghiệp", "form": &"xtreme", "form_name": "Xtreme Memory", "bg": "industrial",
			"route": ["left", "down", "right", "down", "left"], "waves": [["fast", "armored", "basic"], ["basic", "armored", "fast"]]},
		{"name": "Trùm: Kamen Rider Eternal", "bg": "boss_w", "route": ["right", "up", "right"],
			"boss": {"name": "Kamen Rider Eternal", "hp": 300.0, "damage": 18.0, "poise": 30.0, "speed": 65.0,
				"traits": ["armored"], "color": Color(0.95, 0.95, 1.0)},
			"waves": [["basic", "armored"], ["boss"]]},
	],
}

const RIDER := {}

const SPEAKERS := {
	"shotaro": {"name": "SHOTARO", "color": Color(0.35, 0.85, 0.45), "portrait": "shotaro",
		"look": "hair=37261c jacket=302824 stripe=dccdaa eyes=3c2d23 hat"},
	"philip": {"name": "PHILIP", "color": Color(0.55, 0.9, 0.6), "portrait": "philip",
		"look": "hair=966e46 jacket=3c7846 stripe=e6e6c8 eyes=46965a"},
	"eternal": {"name": "ETERNAL", "color": Color(0.8, 0.9, 1.0), "portrait": "eternal", "look": "base=kuuga eternal"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất W · Thành phố gió Fuuto."],
			["shotaro", "Hidari Shotaro, thám tử. Void đã kéo Philip, cộng sự của tôi, vào hư không."],
			["shotaro", "Double Driver cần hai Gaia Memory và hai tâm trí. Dopant đang giữ Cyclone và Joker."],
		],
		"goal": [
			["shotaro", "Hai Dopant kia! Memory nằm trên người chúng."],
		],
		"key": [
			["shotaro", "Rider không bao giờ chiến đấu một mình, kể cả khi trông có vẻ như vậy."],
			["hero", "Nhưng tôi đâu có cộng sự..."],
			["pen", "...Có đấy. Để tôi lo nửa bên trái."],
			["narrator", "Cyclone! Joker! Hai người, một Rider: Kamen Rider W!"],
		],
		"clear": [
			["pen", "Cậu lo tay chân, tôi lo Memory. Đổi form để đổi nửa trái, giữ lên khi đổi form để đổi nửa phải."],
		],
	},
	"2": {
		"start": [
			["shotaro", "Dopant giáp đang càn quét phố. Tay không của W không đủ nặng đâu."],
		],
		"key": [
			["pen", "Heat và Metal! Lửa cho nửa trái, gậy thép cho nửa phải."],
		],
		"clear": [
			["shotaro", "Thành phố này lúc nào cũng có gió. Philip bảo gió mang theo mọi câu chuyện."],
		],
	},
	"3": {
		"start": [
			["shotaro", "Tháp gió. Mục tiêu ở xa ngoài tầm với, phải có thứ gì bắn được."],
		],
		"key": [
			["pen", "Luna và Trigger! Giờ đủ cả 9 tổ hợp rồi. Trigger bắn được đấy."],
		],
		"clear": [
			["shotaro", "Tín hiệu lạ từ Driver... Là Philip! Cậu ấy vẫn còn ở đâu đó trong hư không."],
		],
	},
	"4": {
		"start": [
			["shotaro", "Quái nhanh trộn quái giáp. Nhớ Best Match: mỗi cặp Memory có một điểm mạnh riêng."],
		],
		"key": [
			["philip", "Tín hiệu... bắt được rồi. Xtreme Memory, gửi tới các cậu đây."],
			["shotaro", "Philip!"],
		],
		"clear": [
			["pen", "Kẻ mạnh nhất Trái Đất W đang chờ: Kamen Rider Eternal. Giáp hắn chỉ đòn nặng và Final Attack mới xuyên được."],
		],
	},
	"B": {
		"goal": [
			["eternal", "Một Rider đi mượn sức mạnh... Để xem ngươi trụ được bao lâu."],
			["hero", "Kẻ mạnh nhất Trái Đất W... cũng là một Rider?"],
			["pen", "Void cấy năng lượng vào hắn. Đổi form liên tục, đừng đứng yên!"],
		],
		"clear": [
			["philip", "Xin lỗi vì đến trễ, Shotaro. Và cảm ơn cậu, {name}."],
			["philip", "Pendulum... dữ liệu về cậu trong Thư viện Trái Đất bị xóa trắng. Lẽ ra cậu không được tồn tại."],
			["pen", "......"],
			["narrator", "Giữa đống đổ nát là OOO Driver cùng ba Core Medal, bọc trong tinh thể tím."],
			["shotaro", "Một Rider bị xóa khỏi Thư viện Trái Đất... Nghe như một vụ án đấy. Cẩn thận, cả hai người."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất W sáng rồi. Mười một thế giới. Hồi hai mới chỉ bắt đầu thôi."],
	["hero", "Pen... chuyện Philip nói. Cậu thật sự không nên tồn tại à?"],
	["pen", "Tôi đang ở đây, đang nói chuyện với cậu. Vậy là đủ rồi. Chặng tiếp theo: Trái Đất OOO."],
]
