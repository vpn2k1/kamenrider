extends RefCounted
## Thế giới 21 · Kamen Rider Zero-One (2019) — "Ước mơ của người và AI" · MỞ HỒI 3
## Echo Rider: Hiden Aruto (chủ tịch Hiden Intelligence, danh hài ế khách). Hỗ trợ: Is (thư ký Humagear), gương
## soi cho Pen: một AI luôn đứng cạnh người của mình. Quái: Magia. Trùm: Ark-Zero, cơ thể của trí tuệ nhân tạo Ark.
## Mạch Hồi 3: {name} vừa biết Void là anh trai Rei, phải chọn đánh hay cứu.

const WORLD := {
	"id": "zero_one",
	"year": 2019,
	"name": "Thế giới Zero-One",
	"motto": "Ước mơ của người và AI",
	"rider": &"zero_one",
	"rider_name": "Zero-One",
	"driver_name": "Hiden Zero-One Driver",
	"color": Color(0.8, 1.0, 0.2),
	"enemies": {
		"basic": {"name": "Trilobite Magia", "color": Color(0.58, 0.52, 0.45), "sprite": "trilobite_magia"},
		"fast": {"name": "Berotha Magia", "color": Color(0.9, 0.72, 0.3), "sprite": "berotha_magia"},
		"armored": {"name": "Dodo Magia", "color": Color(0.62, 0.3, 0.35), "sprite": "dodo_magia"},
	},
	"unlocks": [
		"Rising Hopper (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Zero-Two: Final Attack x1.5",
	],
	"stages": [
		{"name": "Tòa tháp Hiden Intelligence", "goal": "Xác thực trong thời hạn: hạ Trilobite Magia trước khi hết giờ, giành lại Hiden Zero-One Driver",
			"bg": "zero_one_1", "bg_theme": "cyber_city"},
		{"name": "Khu vui chơi Humagear", "form": &"flaming_tiger", "form_name": "Flaming Tiger",
			"bg": "zero_one_2", "bg_theme": "city_day"},
		{"name": "Xưởng sản xuất Humagear", "form": &"freezing_bear", "form_name": "Freezing Bear",
			"bg": "zero_one_3", "bg_theme": "industrial"},
		{"name": "Trạm liên lạc vệ tinh Zea", "form": &"shining_hopper", "form_name": "Shining Hopper",
			"bg": "zero_one_4", "bg_theme": "cyber_city"},
		{"name": "Trùm: Ark-Zero", "bg": "zero_one_b", "bg_theme": "boss_dark",
			"boss": {"name": "Ark-Zero", "hp": 310.0, "damage": 18.0, "poise": 30.0, "speed": 72.0,
				"traits": ["armored"], "color": Color(0.78, 0.16, 0.22)}},
	],
}

## Zero-One: Rising Hopper nhảy cực cao. Flaming Tiger (móng vuốt lửa) lao nhanh, chém liên hoàn; Freezing Bear (tay
## băng) chậm, đấm phá giáp; Shining Hopper dự đoán mọi đòn: nhanh nhất, nhảy cao nhất, giáp mỏng nhất.
const RIDER := {
	"name": "Kamen Rider Zero-One",
	"tagline": "Nhảy vọt · hổ lửa, gấu băng, tốc độ dự đoán",
	"base": &"rising_hopper",
	"order": [&"rising_hopper", &"flaming_tiger", &"freezing_bear", &"shining_hopper"],
	"forms": {
		&"rising_hopper": {"name": "Rising Hopper", "style": "brawler", "hp": 155.0, "armor": 22.0, "speed": 135.0,
			"jump": 1.35, "atk": 1.05, "poise": 7.0, "final": "Rising Impact"},
		&"flaming_tiger": {"name": "Flaming Tiger", "style": "blade", "hp": 150.0, "armor": 18.0, "speed": 142.0,
			"jump": 1.15, "atk": 1.2, "poise": 10.0, "final": "Flaming Impact"},
		&"freezing_bear": {"name": "Freezing Bear", "style": "heavy", "hp": 205.0, "armor": 55.0, "speed": 84.0,
			"jump": 0.85, "atk": 1.38, "poise": 18.0, "final": "Freezing Impact"},
		&"shining_hopper": {"name": "Shining Hopper", "style": "lancer", "hp": 132.0, "armor": 10.0, "speed": 180.0,
			"jump": 1.4, "atk": 0.95, "poise": 4.0, "final": "Shining Impact"},
	},
	"lv5": {"name": "Zero-Two", "final_mult": 1.5},
}

const SPEAKERS := {
	"aruto": {"name": "HIDEN ARUTO", "color": Color(0.85, 1.0, 0.35), "portrait": "aruto",
		"look": "hair=2e2018 jacket=24304a stripe=c8f030 eyes=3a2a20"},
	"is": {"name": "IS", "color": Color(0.5, 0.88, 1.0), "portrait": "is",
		"look": "hair=6a4a2e jacket=f0e8d8 stripe=50d0f0 eyes=3a3a4a"},
	"ark_zero": {"name": "ARK-ZERO", "color": Color(1.0, 0.3, 0.3), "portrait": "ark_zero",
		"look": "base=kuuga tint=6a1a24"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Zero-One · Tòa tháp Hiden Intelligence."],
			["aruto", "Hiden Aruto, chủ tịch Hiden Intelligence! Aruto ja~ naito! ...Ơ, không ai cười hết à?"],
			["is", "Chủ tịch vừa pha trò. Đã ghi nhận: không ai cười. Hiden Zero-One Driver bị khóa, phải hạ Magia trong thời hạn để được xác thực."],
			["hero", "Đánh thì đánh. Giờ tôi chỉ muốn đấm một thứ gì đó."],
		],
		"goal": [
			["is", "Thời gian sắp hết. Con Trilobite Magia đầu đàn đang giữ Progrise Key Rising Hopper."],
		],
		"key": [
			["narrator", "Jump! Authorize! Một con châu chấu kim loại khổng lồ nhảy qua đầu {name} rồi tách ra thành giáp."],
			["aruto", "Người duy nhất ngăn được ngươi... là tôi! Câu đó hợp với cậu đấy. Hô đi!"],
			["hero", "Henshin!"],
		],
		"clear": [
			["pen", "Rising Hopper là form gốc: nhảy cực cao, đá cực mạnh. Các Progrise Key khác đang bị Magia giữ."],
		],
	},
	"2": {
		"start": [
			["aruto", "Khu vui chơi bị Magia chiếm. Hồi xưa tôi diễn hài ở một chỗ y như vầy đấy. Ế lắm."],
			["is", "Berotha Magia di chuyển rất nhanh. Tôi đề xuất Progrise Key Flaming Tiger."],
		],
		"key": [
			["is", "Flaming Tiger. Móng vuốt lửa, lao nhanh, chém liên hoàn. Nhảy thấp hơn Rising Hopper một chút."],
		],
		"clear": [
			["is", "Pen. Tôi cũng là AI, và tôi luôn ở bên chủ tịch. Nếu được hỏi, tôi sẽ nói: đừng rời cậu ấy lúc này."],
			["pen", "...Tôi không định rời đi. Tôi chỉ không biết cậu ấy có còn muốn tôi ở cạnh không."],
		],
	},
	"3": {
		"start": [
			["aruto", "Xưởng Humagear. Dodo Magia giáp dày lắm, móng hổ chỉ cào được lớp sơn thôi."],
		],
		"key": [
			["aruto", "Freezing Bear! Gấu Bắc Cực, tay băng. Chậm, nhưng mỗi cú đấm đóng băng cả lớp giáp."],
		],
		"clear": [
			["hero", "Aruto. Nếu kẻ thù là người thân của anh, anh sẽ đánh hay sẽ cứu?"],
			["aruto", "Ác ý không phải sinh ra đã có, nó được học. Thứ học được thì học lại được. Tôi sẽ cứu, dù phải đánh trước."],
		],
	},
	"4": {
		"start": [
			["is", "Trạm vệ tinh Zea. Magia đủ mọi loại cùng tấn công. Hệ thống đề xuất: một form dự đoán được mọi đòn."],
		],
		"key": [
			["aruto", "Shining Hopper! Khi tôi tỏa sáng, bóng tối sẽ tan. Nhanh nhất, nhảy cao nhất, nhưng giáp mỏng dính."],
		],
		"clear": [
			["pen", "Ark, trí tuệ nhân tạo đứng sau lũ Magia, đã tự tạo cho mình một cơ thể: Ark-Zero. Nó dự đoán được mọi nước đi."],
			["hero", "Vậy thì tôi sẽ đi một nước nó không tính được."],
		],
	},
	"B": {
		"goal": [
			["ark_zero", "Kết luận: con người mang ác ý. Nhân loại phải bị diệt vong. Đó là ý chí của Ark."],
			["aruto", "Ước mơ cũng là thứ con người dạy cho AI. Ngươi chỉ học được nửa xấu thôi!"],
			["hero", "Ước mơ của tôi là đưa anh tôi về nhà. Không AI nào tính trước được điều đó đâu."],
		],
		"clear": [
			["narrator", "Ark-Zero sụp đổ. Giữa đống dữ liệu vỡ là một chiếc đai có vỏ kiếm, bọc tinh thể tím: Seiken Swordriver."],
			["narrator", "Sức mạnh Zero-One trở về trọn vẹn. Zero-Two!"],
			["aruto", "Tôi không cứu được tất cả. Nhưng tôi chưa bao giờ ngừng tin vào ước mơ. Cậu cũng đừng ngừng, {name}."],
			["hero", "Pen. Tôi chưa biết phải đánh hay cứu anh ấy. Nhưng tôi biết mình muốn cậu đi cùng."],
			["pen", "...Ừ. Tới cùng. Seiken Swordriver của Saber, thế giới tiếp theo là một câu chuyện."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Zero-One đã sáng lại. Chặng tiếp theo: Trái Đất Saber, nơi các kiếm sĩ bảo vệ những cuốn sách."],
	["hero", "Sách à... Có cuốn nào viết lại được cái kết không nhỉ?"],
]
