extends RefCounted
## Thế giới 17 · Kamen Rider Ghost (2015) — "Thắp cháy sinh mệnh"
## Echo Rider: Tenkuji Takeru (từng chết, sống lại nhờ Eyecon anh hùng). Hỗ trợ: Onari (sư chùa Daitenkuji),
## Alain (hoàng tử Thế giới Gamma, em trai Adel). Quái: Gamma. Trùm: Adel, kẻ muốn hợp nhất mọi người làm một.
## Thức tỉnh: {name} bị cổng kéo hồn ra khỏi xác, phải tìm Ore Eyecon ở dạng hồn ma.

const WORLD := {
	"id": "ghost",
	"year": 2015,
	"name": "Thế giới Ghost",
	"motto": "Thắp cháy sinh mệnh",
	"rider": &"ghost",
	"rider_name": "Ghost",
	"driver_name": "Ghost Driver",
	"color": Color(1.0, 0.55, 0.1),
	"enemies": {
		"basic": {"name": "Gamma Command", "color": Color(0.55, 0.55, 0.62), "sprite": "gamma_command"},
		"fast": {"name": "Katana Gamma", "color": Color(0.35, 0.6, 0.85), "sprite": "katana_gamma"},
		"armored": {"name": "Gamma Ultima", "color": Color(0.85, 0.82, 0.9), "sprite": "gamma_ultima"},
	},
	"unlocks": [
		"Ore Damashii (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Mugen Damashii: Final Attack x1.5",
	],
	"stages": [
		{"name": "Chùa Daitenkuji", "goal": "Dạng hồn ma: hạ Gamma giữ Ore Eyecon, giành lại Ghost Driver",
			"bg": "ghost_1", "bg_theme": "temple_ghost"},
		{"name": "Rừng tre sau chùa", "form": &"musashi", "form_name": "Musashi Damashii",
			"bg": "ghost_2", "bg_theme": "forest_night"},
		{"name": "Nhà máy điện bỏ hoang", "form": &"edison", "form_name": "Edison Damashii",
			"bg": "ghost_3", "bg_theme": "industrial"},
		{"name": "Hang Monolith dưới chùa", "form": &"newton", "form_name": "Newton Damashii",
			"bg": "ghost_4", "bg_theme": "underworld"},
		{"name": "Trùm: Adel", "bg": "ghost_b", "bg_theme": "boss_red",
			"boss": {"name": "Adel", "hp": 280.0, "damage": 16.0, "poise": 26.0, "speed": 72.0,
				"traits": [], "color": Color(0.92, 0.9, 0.98)}},
	],
}

## Ghost: nhẹ, nhảy bồng bềnh. Musashi (song kiếm Gan Gun Saber) chém nặng; Edison (súng Gan Gun Saber) bắn tia điện
## xuyên hàng quái; Newton (tay đẩy, tay hút) chậm nhưng đấm nặng như trọng lực.
const RIDER := {
	"name": "Kamen Rider Ghost",
	"tagline": "Cân bằng · mượn hồn anh hùng: song kiếm, súng điện, trọng lực",
	"base": &"ore",
	"order": [&"ore", &"musashi", &"edison", &"newton"],
	"forms": {
		# Ore Damashii: Gan Gun Saber dạng kiếm (nút Chém). Là hồn ma nên lượn được (giữ Nhảy khi rơi).
		&"ore": {"name": "Ore Damashii", "style": "brawler", "hp": 158.0, "armor": 24.0, "speed": 132.0,
			"jump": 1.15, "atk": 1.05, "poise": 7.0, "final": "Omega Drive", "blade": {"look": "gangunsaber"},
			"fx": {"hit": "spark", "swing": "slash", "final": "fire", "glide": true, "color": Color(1.0, 0.55, 0.15)},
			"skills": [
				{"name": "Ghost Phase", "type": "buff", "buff": {"phase": true, "time": 2.0}, "fx": "feather",
					"color": Color(0.8, 0.85, 1.0)},
				{"name": "Parka Ghost", "type": "lock", "range": 200.0, "fx": "wind", "summon": "eye",
					"color": Color(1.0, 0.55, 0.15)},
			]},
		# Musashi Damashii: song kiếm Gan Gun Saber Nitoryu. Omega Slash: hai nhát chéo liên tiếp.
		&"musashi": {"name": "Musashi Damashii", "style": "blade", "hp": 165.0, "armor": 26.0, "speed": 122.0,
			"jump": 1.0, "atk": 1.25, "poise": 11.0, "final": "Omega Slash", "blade": {"look": "nito"},
			"attacks": {"final": {"hits": 2, "damage": 34.0}},
			"fx": {"hit": "spark", "swing": "slash", "final": "slash", "color": Color(1.0, 0.25, 0.2)},
			"skills": [
				{"name": "Nitoryu", "type": "aim", "hits": 2, "fx": "claw", "anim": "slash", "icon": "spinblade",
					"color": Color(1.0, 0.3, 0.25)},
				{"name": "Gan-Gun Saber Slash", "type": "aim", "move": "wave", "fx": "slash", "anim": "slash",
					"shot": {"style": "wave"}, "color": Color(1.0, 0.7, 0.3)},
			]},
		# Edison Damashii: Gan Gun Saber dạng súng bắn tia điện xuyên, điện lan sang quái gần.
		&"edison": {"name": "Edison Damashii", "style": "gunner", "hp": 145.0, "armor": 15.0, "speed": 118.0,
			"jump": 1.0, "atk": 0.95, "poise": 5.0, "final": "Omega Shoot",
			"gun": {"look": "gangun", "tags": [&"shock"], "damage": 7.0, "speed": 400.0, "cooldown": 0.34, "radius": 3.0,
				"color": Color(1.0, 0.92, 0.35), "pierce": true, "life": 0.85},
			"attacks": {"final": {"tags": [&"shock"]}},
			"fx": {"hit": "lightning", "shot": "bolt", "final": "lightning", "color": Color(1.0, 0.92, 0.35)},
			"skills": [
				{"name": "Edison Shock", "type": "aim", "move": "shot", "tags": [&"shock"],
					"shot": {"style": "bolt", "speed": 440.0, "pierce": true}, "fx": "lightning", "color": Color(1.0, 0.92, 0.35)},
				{"name": "Light Bulb", "type": "area", "radius": 90.0, "tags": [&"stun"], "fx": "bulb",
					"color": Color(1.0, 1.0, 0.75)},
			]},
		# Newton Damashii: tay trái đẩy, tay phải hút. Đòn kết đẩy văng; Omega Drive hút cả vùng về rồi ghim lại.
		&"newton": {"name": "Newton Damashii", "style": "heavy", "hp": 200.0, "armor": 52.0, "speed": 85.0,
			"jump": 0.85, "atk": 1.4, "poise": 18.0, "final": "Omega Drive",
			"attacks": {"kick": {"knockback": Vector2(260, -40), "tags": [&"force"]},
				"final": {"size": Vector2(140, 40), "offset": Vector2(40, -14), "knockback": Vector2(-200, -40),
					"tags": [&"force", &"stun"]}},
			"fx": {"hit": "ring", "final": "ring", "color": Color(0.35, 0.55, 1.0)},
			"skills": [
				{"name": "Newton Repel", "type": "area", "knockback": Vector2(320, -80), "tags": [&"force"], "fx": "ring",
					"color": Color(0.45, 0.75, 1.0)},
				{"name": "Newton Attract", "type": "bind", "via": "area", "radius": 100.0, "knockback": Vector2(-160, -20),
					"tags": [&"force"], "fx": "gravity", "color": Color(0.55, 0.35, 1.0)},
			],
			"final_type": "bind"},
	},
	"lv5": {"name": "Mugen", "final_mult": 1.5},
	"final_fx": {"intro": "eye"},
}

## Giọng Ghost Driver (tools/gen_audio.py → audio/voice/ghost_<khóa>.wav), xem VOICE của w01_kuuga.gd.
const VOICE := {
	"henshin": ["belt", "Kaigan! Ore! Let's go! Kakugo! Gho-Gho-Gho-Ghost!"],
	"musashi": ["belt", "Kaigan! Musashi! Kettou! Zubatto! Chouken-gou!"],
	"edison": ["belt", "Kaigan! Edison! Hirameki! Hatsumei! Hatsumei-ou!"],
	"newton": ["belt", "Kaigan! Newton! Ringo ga rakka! Hikiyoseru gekka!"],
	"final": ["belt", "Dai Kaigan! Omega Drive!"],
}

const SPEAKERS := {
	"takeru": {"name": "TENKUJI TAKERU", "color": Color(1.0, 0.6, 0.2), "portrait": "takeru",
		"look": "hair=1c1a1e jacket=26262c stripe=f07820 eyes=3a2a20"},
	"onari": {"name": "ONARI", "color": Color(0.95, 0.8, 0.45), "portrait": "onari",
		"look": "hair=c89a78 jacket=2a2a30 stripe=d8b060 eyes=2a2220"},
	"alain": {"name": "ALAIN", "color": Color(0.55, 0.7, 1.0), "portrait": "alain",
		"look": "hair=2a2430 jacket=ecebf2 stripe=3a6ae0 eyes=2a2a3a"},
	"adel": {"name": "ADEL", "color": Color(0.95, 0.4, 0.45), "portrait": "adel",
		"look": "hair=202028 jacket=f4f2f8 stripe=c02a3a eyes=b02030"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất Ghost · Chùa Daitenkuji, nửa đêm."],
			["hero", "Khoan... sao tay tôi xuyên qua cột nhà? Sao người tôi trong suốt thế này?!"],
			["pen", "Cổng vừa rồi kéo hồn cậu đi trước, xác còn kẹt lại phía sau. Nói ngắn gọn: giờ cậu là ma."],
			["takeru", "Đừng hoảng! Tenkuji Takeru, tôi cũng chết một lần rồi đây. Ghost Driver chỉ tỉnh khi một linh hồn chạm vào Ore Eyecon."],
		],
		"goal": [
			["onari", "Bần tăng Onari xin trợ giúp! Takeru-dono, con mắt trên ngực tên Gamma kia chắc chắn là Eyecon!"],
		],
		"key": [
			["narrator", "Ore Eyecon mở mắt. Ghost Driver hiện ra, hồn {name} nhập lại vào xác trong một vạt áo choàng đen cam."],
			["takeru", "Nhịp tim đó là sinh mệnh của cậu. Đừng lãng phí nó. Thắp cháy nó lên!"],
			["hero", "Henshin!"],
		],
		"clear": [
			["pen", "Ore Damashii là form gốc: cân bằng, nhảy bồng bềnh như ma. Eyecon anh hùng thì nằm trong tay lũ Gamma."],
		],
	},
	"2": {
		"start": [
			["takeru", "Rừng tre sau chùa. Katana Gamma lượn trong đó, chém nhanh như gió."],
			["onari", "Eyecon Musashi đang ở quanh đây! Kiếm sĩ song kiếm bất bại của Nhật Bản!"],
		],
		"key": [
			["takeru", "Musashi Damashii! Gan Gun Saber tách thành hai kiếm. Chém liên hoàn, nhát cuối phá giáp."],
		],
		"clear": [
			["takeru", "Các anh hùng trong Eyecon đã mất từ lâu. Nhưng khát vọng của họ vẫn sống, và họ cho mình mượn nó."],
			["hero", "Sống tiếp nhờ người khác... Tôi hiểu. Hồi nhỏ, anh tôi đẩy tôi ra khỏi đám cháy. Rồi anh ấy biến mất."],
		],
	},
	"3": {
		"start": [
			["alain", "Ta là Alain, đến từ Thế giới Gamma. Đừng hiểu lầm, ta chỉ muốn xem kẻ đi gom Driver trông ra sao."],
			["alain", "Gamma Command đứng trên giàn điện bắn xuống. Kiếm của ngươi không với tới đâu."],
		],
		"key": [
			["pen", "Eyecon Edison! Gan Gun Saber thành súng, bắn tia điện xuyên qua cả hàng quái. Ông tổ bóng đèn đấy!"],
		],
		"clear": [
			["alain", "Ở Thế giới Gamma không ai già, không ai đói. Nhưng cũng không ai cười. Anh trai ta gọi đó là hoàn hảo."],
		],
	},
	"4": {
		"start": [
			["onari", "Hang Monolith dưới chùa! Cổng sang Thế giới Gamma mở toang, Gamma Ultima đang tràn ra!"],
			["pen", "Giáp chúng dày lắm. Tia điện của Edison chỉ làm chúng ngứa thôi."],
		],
		"key": [
			["takeru", "Newton Damashii! Tay trái đẩy, tay phải hút. Chậm, nhưng mỗi cú đấm nặng như trọng lực."],
		],
		"clear": [
			["alain", "Anh trai ta là Adel. Ta từng tin anh ấy đúng. Giờ ta muốn kéo anh ấy về, dù phải đối đầu."],
			["hero", "Phải đánh chính anh trai mình... Tôi không tưởng tượng nổi."],
			["takeru", "Không phải đánh để hạ gục. Mà để chạm tới trái tim người đó. Trái tim nào cũng kết nối được."],
		],
	},
	"B": {
		"goal": [
			["adel", "Con người đau khổ vì có cảm xúc. Ta sẽ hợp nhất tất cả làm một, trong ta. Không ai còn phải chết."],
			["hero", "Không chết, vì chẳng còn là chính mình nữa à? Tôi xin kiếu."],
		],
		"clear": [
			["narrator", "Adel tan thành muôn đốm sáng. Giữa đó là một chiếc đai hình máy chơi game bọc tinh thể tím: Gamer Driver."],
			["narrator", "Sức mạnh Ghost trở về trọn vẹn. Mugen Damashii!"],
			["alain", "Anh hai... Lần sau gặp lại, em sẽ nắm lấy tay anh."],
			["takeru", "Sinh mệnh không phải để giữ riêng. Là để trao tiếp cho nhau. Đi đi, {name}, và thắp cháy nó lên!"],
			["pen", "Gamer Driver của Ex-Aid. Chuẩn bị tinh thần đi, thế giới tiếp theo là... một trò chơi."],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất Ghost đã sáng lại. Chặng tiếp theo: Trái Đất Ex-Aid, nơi bác sĩ chữa bệnh bằng game."],
	["hero", "Bác sĩ... chơi game? Nghe còn lạ hơn chuyện tôi vừa làm ma."],
]
