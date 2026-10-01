extends RefCounted
## Thế giới 18 · Kamen Rider Ex-Aid (2016) — "Cứu lấy sinh mạng"
## Echo Rider: Hojo Emu (bác sĩ thực tập ở CR, game thủ thiên tài "M"). Hỗ trợ: Poppy Pipopapo (Bugster tốt bụng).
## Quái: Bugster. Trùm: Dan Kuroto / Kamen Rider Genm, kẻ tự xưng là "thần" tạo ra mọi Gashat.
## Thức tỉnh: phá đảo mini-game Mighty Action X trong Game Area.

const WORLD := {
	"id": "ex_aid",
	"year": 2016,
	"name": "Thế giới Ex-Aid",
	"motto": "Cứu lấy sinh mạng",
	"rider": &"ex_aid",
	"rider_name": "Ex-Aid",
	"driver_name": "Gamer Driver",
	"color": Color(1.0, 0.42, 0.78),
	"enemies": {
		"basic": {"name": "Bugster Virus", "color": Color(1.0, 0.6, 0.2)},
		"fast": {"name": "Charlie Bugster", "color": Color(0.95, 0.85, 0.3)},
		"armored": {"name": "Gatton Bugster", "color": Color(0.55, 0.6, 0.72)},
	},
	"unlocks": [
		"Action Gamer Level 2 (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Muteki Gamer: Final Attack x1.5",
	],
	"stages": [
		{"name": "Game Area: Mighty Action X", "goal": "Phá đảo mini-game Mighty Action X: hạ Bugster, giành lại Gamer Driver",
			"bg": "ex_aid_1", "bg_theme": "game_world"},
		{"name": "Sân Bệnh viện Seito", "form": &"sports", "form_name": "Sports Action Gamer Level 3",
			"bg": "ex_aid_2", "bg_theme": "hospital"},
		{"name": "Nhà máy bỏ hoang", "form": &"robot", "form_name": "Robot Action Gamer Level 3",
			"bg": "ex_aid_3", "bg_theme": "industrial"},
		{"name": "Game Area: Drago Knight Hunter Z", "form": &"hunter", "form_name": "Hunter Action Gamer Level 5",
			"bg": "ex_aid_4", "bg_theme": "game_world"},
		{"name": "Trùm: Kamen Rider Genm", "bg": "ex_aid_b", "bg_theme": "boss_purple",
			"boss": {"name": "Kamen Rider Genm", "hp": 290.0, "damage": 16.0, "poise": 26.0, "speed": 70.0,
				"traits": ["armored"], "color": Color(0.6, 0.5, 0.72)}},
	],
}

## Ex-Aid: Level 2 nhảy cực cao như game đi cảnh. Sports (Shakariki Sports) chạy nhanh, ném bánh xe tầm xa;
## Robot (Gekitotsu Robots) tay robot đấm nặng phá giáp; Hunter Level 5 (Drago Knight Hunter Z) giáp rồng, súng lửa.
const RIDER := {
	"name": "Kamen Rider Ex-Aid",
	"tagline": "Nhảy cao · đổi Level: xe đạp tốc độ, nắm đấm robot, rồng săn",
	"base": &"action_gamer",
	"order": [&"action_gamer", &"sports", &"robot", &"hunter"],
	"forms": {
		&"action_gamer": {"name": "Action Gamer Level 2", "style": "brawler", "hp": 155.0, "armor": 22.0,
			"speed": 135.0, "jump": 1.25, "atk": 1.05, "poise": 7.0, "final": "Mighty Critical Strike"},
		&"sports": {"name": "Sports Action Gamer Level 3", "style": "lancer", "hp": 135.0, "armor": 12.0,
			"speed": 175.0, "jump": 1.2, "atk": 0.9, "poise": 4.0, "final": "Shakariki Critical Strike"},
		&"robot": {"name": "Robot Action Gamer Level 3", "style": "heavy", "hp": 205.0, "armor": 55.0,
			"speed": 84.0, "jump": 0.85, "atk": 1.42, "poise": 19.0, "final": "Gekitotsu Critical Strike"},
		&"hunter": {"name": "Hunter Action Gamer Level 5", "style": "gunner", "hp": 170.0, "armor": 35.0,
			"speed": 108.0, "jump": 0.95, "atk": 1.05, "poise": 9.0, "final": "Drago Knight Critical Strike",
			"gun": {"damage": 8.0, "speed": 340.0, "cooldown": 0.38, "radius": 4.0, "color": Color(1.0, 0.5, 0.15),
				"life": 0.7}},
	},
	"lv5": {"name": "Muteki Gamer", "final_mult": 1.5},
}

const SPEAKERS := {
	"emu": {"name": "HOJO EMU", "color": Color(1.0, 0.5, 0.8), "portrait": "emu",
		"look": "hair=3a281e jacket=f2f2f2 stripe=f050a0 eyes=3a2a20"},
	"poppy": {"name": "POPPY PIPOPAPO", "color": Color(1.0, 0.7, 0.85), "portrait": "poppy",
		"look": "hair=f070b0 jacket=f8d850 stripe=60d0f0 eyes=6a3a8a long"},
	"kuroto": {"name": "DAN KUROTO", "color": Color(0.75, 0.55, 0.95), "portrait": "kuroto",
		"look": "hair=18181c jacket=24222a stripe=a060d0 eyes=3a2230"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Ex-Aid · Game Area trước Bệnh viện Seito."],
			["emu", "Tôi là Hojo Emu, bác sĩ thực tập ở CR. Void lấy Gamer Driver rồi khóa nó trong một trò chơi."],
			["poppy", "Poppy Pipopapo đây! Muốn mở khóa thì phải phá đảo Mighty Action X. Không được continue đâu nha~"],
			["hero", "Tôi chơi game dở tệ luôn á..."],
		],
		"goal": [
			["emu", "(ánh mắt đổi hẳn) Để tôi chỉ. Phá đảo không cần continue! Con Bugster to nhất kia đang giữ Gamer Driver."],
		],
		"key": [
			["narrator", "GAME CLEAR! Gamer Driver bật sáng. Một bộ giáp hồng mắt to hiện ra, rồi vỡ vỏ thành Level 2."],
			["emu", "Số phận của bệnh nhân, tôi sẽ thay đổi nó! ...Câu cửa miệng của tôi đấy. Cho cậu mượn."],
			["hero", "Dai Henshin!"],
		],
		"clear": [
			["pen", "Action Gamer Level 2 là form gốc: nhảy cực cao, dậm đầu quái như chơi game đi cảnh. Các Gashat khác trong tay Bugster."],
		],
	},
	"2": {
		"start": [
			["poppy", "Charlie Bugster đang đạp xe vòng quanh bệnh viện! Nhanh quá trời, bệnh nhân không dám ra sân luôn."],
			["pen", "Gashat Shakariki Sports ở ngay trong đám đó. Muốn đuổi xe đạp thì phải có xe đạp!"],
		],
		"key": [
			["emu", "Sports Action Gamer Level 3! Chạy nhanh, ném bánh xe từ xa. Đánh nhẹ hơn, nhưng không ai bắt kịp."],
		],
		"clear": [
			["emu", "Với bác sĩ, Bugster không chỉ là quái vật. Chúng là bệnh. Và sau mỗi con bệnh là một bệnh nhân đang chờ."],
			["hero", "Vậy đánh Bugster cũng là... chữa bệnh?"],
		],
	},
	"3": {
		"start": [
			["emu", "Gatton Bugster chiếm nhà máy cũ. Người hắn cứng như thép, bánh xe không làm xước nổi."],
		],
		"key": [
			["poppy", "Gekitotsu Robots! Tay robot khổng lồ, chậm rì rì nhưng đấm một phát là bay giáp nha!"],
		],
		"clear": [
			["emu", "Hồi nhỏ tôi gặp tai nạn, một bác sĩ đã cứu tôi. Từ đó tôi muốn làm bác sĩ, để trả nụ cười ấy cho người khác."],
			["hero", "Anh tôi cũng từng cứu tôi. Nhưng tôi chưa kịp nói cảm ơn."],
		],
	},
	"4": {
		"start": [
			["poppy", "Game Area mới vừa mở! Drago Knight Hunter Z, có cả Graphite, con Bugster rồng mạnh nhất!"],
			["pen", "Lũ quái bay vòng trên đầu và phun lửa từ xa. Cần thứ gì bắn được, và lì đòn hơn Level 3."],
		],
		"key": [
			["emu", "Hunter Action Gamer Level 5! Giáp rồng, một tay kiếm, một tay súng. Bắn lửa từ xa, chịu đòn tốt hơn hẳn."],
		],
		"clear": [
			["kuroto", "Tuyệt vời... Một người chơi mới trong game của ta. Lên tầng thượng Tập đoàn Genm đi, ta sẽ cho ngươi GAME OVER."],
			["poppy", "Dan Kuroto! Anh ta... chết mấy lần rồi mà vẫn quay lại được!"],
		],
	},
	"B": {
		"goal": [
			["kuroto", "Ta là THẦN! Kẻ tạo ra mọi Gashat. Ngươi nghĩ chơi game của ta mà thắng được ta sao?"],
			["emu", "Genm Level X là zombie, không biết chết. Cứ dồn đòn nặng cho tới khi hắn không đứng dậy nổi!"],
			["hero", "Một bác sĩ, một shipper, đấu với một ông thần zombie. Nghe giống game thật."],
		],
		"clear": [
			["narrator", "GAME CLEAR! Genm vỡ thành điểm ảnh. Giữa đó là một chiếc đai có tay quay, bọc tinh thể tím: Build Driver."],
			["narrator", "Sức mạnh Ex-Aid trở về trọn vẹn. Muteki Gamer!"],
			["kuroto", "Mạng còn lại... chín mươi tám. Ta sẽ quay lại! Ha ha ha!"],
			["emu", "Cứu một sinh mạng không cần là thiên tài. Chỉ cần không bỏ cuộc. {name}, đừng bỏ cuộc với anh trai cậu."],
			["pen", "Build Driver của Build. Thế giới tiếp theo bị chia làm ba bởi một bức tường khổng lồ."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Ex-Aid đã sáng lại. Chặng tiếp theo: Trái Đất Build, nơi một thiên tài vật lý chiến đấu vì Love & Peace."],
	["hero", "Love & Peace... Nghe hơi sến, nhưng tôi thích."],
]
