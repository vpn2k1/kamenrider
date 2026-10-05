extends RefCounted
class_name DuelKits
## Rider đối thủ ở màn ĐẤU RIDER (side_worlds.gd) đánh bằng skill riêng theo nguyên tác của chính Rider đó, thay cho bộ
## chiêu chung, và khó dần theo thứ tự màn, bắt đầu từ Trung bình.
##
## KITS[rider] = các kỹ năng BossSkills (khóa "kind", "name", "color" và khóa riêng của kiểu, xem boss_skills.gd).
## Thứ tự có nghĩa: các kỹ năng đầu dùng ngay từ đầu trận (số lượng theo độ khó, LEVELS "pool"), kỹ năng sau chỉ mở
## khi nổi giận; kỹ năng cuối thường là Final (Rider Kick...) mạnh nhất.
## Kiểu thêm cho Rider: "kick" bật cao rồi đá chéo xuống chỗ người chơi (dấu đỏ báo trước) · "wave" sóng chém bay sát
## đất (nhảy qua).

const LEVELS := [
	## 0: trùm thường (không dùng cho Rider đối thủ, giữ như cũ)
	{"name": "", "cooldown": 1.0, "windup": 1.0, "pool": 2, "enrage": 0.5, "hp": 1.0, "damage": 1.0},
	{"name": "Trung bình", "cooldown": 0.85, "windup": 0.95, "pool": 2, "enrage": 0.55, "hp": 1.0, "damage": 1.0},
	{"name": "Khó", "cooldown": 0.7, "windup": 0.85, "pool": 3, "enrage": 0.6, "hp": 1.15, "damage": 1.1},
	{"name": "Rất khó", "cooldown": 0.55, "windup": 0.75, "pool": 4, "enrage": 0.7, "hp": 1.3, "damage": 1.2},
]

const KITS := {
	&"kuuga": [
		{"kind": "dash", "name": "Mighty Punch", "color": Color(1.0, 0.35, 0.3)},
		{"kind": "slam", "name": "Dragon Leap", "color": Color(0.35, 0.55, 1.0)},
		{"kind": "fan", "name": "Pegasus Snipe", "color": Color(0.4, 1.0, 0.5), "count": 1, "speed": 300.0, "style": "arrow",
			"damage": 1.3},
		{"kind": "guard", "name": "Titan Guard", "color": Color(0.75, 0.45, 1.0)},
		{"kind": "kick", "name": "Mighty Kick", "color": Color(1.0, 0.45, 0.2)},
	],
	&"agito": [
		{"kind": "wave", "name": "Storm Halberd", "color": Color(0.35, 0.55, 1.0)},
		{"kind": "dash", "name": "Flame Saber", "color": Color(1.0, 0.4, 0.15)},
		{"kind": "haste", "name": "Agito Crest", "color": Color(1.0, 0.85, 0.3), "time": 3.0},
		{"kind": "kick", "name": "Rider Kick", "color": Color(1.0, 0.8, 0.25)},
	],
	&"ryuki": [
		{"kind": "fan", "name": "Strike Vent", "color": Color(1.0, 0.45, 0.15), "count": 3, "spread": 0.18, "style": "fire"},
		{"kind": "dash", "name": "Sword Vent", "color": Color(1.0, 0.35, 0.3)},
		{"kind": "rain", "name": "Advent: Dragreder", "color": Color(1.0, 0.3, 0.2), "count": 5},
		{"kind": "guard", "name": "Guard Vent", "color": Color(1.0, 0.5, 0.4)},
		{"kind": "kick", "name": "Dragon Rider Kick", "color": Color(1.0, 0.4, 0.15), "jump": 420.0},
	],
	&"faiz": [
		{"kind": "dash", "name": "Grand Impact", "color": Color(1.0, 0.25, 0.25)},
		{"kind": "wave", "name": "Faiz Edge", "color": Color(1.0, 0.2, 0.2)},
		{"kind": "haste", "name": "Start Up: Axel", "color": Color(1.0, 0.35, 0.3), "time": 3.0},
		{"kind": "kick", "name": "Crimson Smash", "color": Color(1.0, 0.15, 0.2), "drill": true},
	],
	&"blade": [
		{"kind": "dash", "name": "Slash Lizard", "color": Color(0.4, 0.6, 1.0)},
		{"kind": "rain", "name": "Thunder Deer", "color": Color(1.0, 0.95, 0.4), "count": 4, "style": "bolt"},
		{"kind": "haste", "name": "Mach Jaguar", "color": Color(1.0, 0.75, 0.2), "time": 3.0},
		{"kind": "kick", "name": "Lightning Blast", "color": Color(1.0, 0.95, 0.4)},
	],
	&"hibiki": [
		{"kind": "fan", "name": "Onibi", "color": Color(0.7, 0.4, 1.0), "count": 5, "style": "fire"},
		{"kind": "rain", "name": "Rekka Dan", "color": Color(1.0, 0.45, 0.2), "count": 4, "style": "fire"},
		{"kind": "guard", "name": "Kitaeteru", "color": Color(0.7, 0.4, 1.0)},
		{"kind": "slam", "name": "Ongekidaiko", "color": Color(1.0, 0.35, 0.2), "damage": 1.3},
	],
	&"kabuto": [
		{"kind": "haste", "name": "Clock Up", "color": Color(0.4, 0.9, 1.0), "time": 3.0},
		{"kind": "dash", "name": "Kabuto Kunai", "color": Color(1.0, 0.3, 0.3)},
		{"kind": "fan", "name": "Kunai Gun", "color": Color(1.0, 0.3, 0.3), "count": 3, "spread": 0.2},
		## Kabuto Rider Kick: Clock Up biến mất, hiện sau lưng rồi xoay người đá vòng.
		{"kind": "warp", "name": "Rider Kick", "color": Color(1.0, 0.25, 0.25), "damage": 1.3},
	],
	&"den_o": [
		{"kind": "wave", "name": "Extreme Slash", "color": Color(1.0, 0.3, 0.3)},
		{"kind": "dash", "name": "Ore Sanjou!", "color": Color(1.0, 0.35, 0.35)},
		{"kind": "fan", "name": "Wild Shot", "color": Color(0.7, 0.4, 1.0), "count": 5},
		{"kind": "slam", "name": "Dynamic Chop", "color": Color(1.0, 0.85, 0.3), "damage": 1.3},
	],
	&"kiva": [
		{"kind": "dash", "name": "Garulu Saber", "color": Color(0.4, 0.6, 1.0)},
		{"kind": "fan", "name": "Basshaa Aqua Bullet", "color": Color(0.3, 0.9, 0.6), "count": 3, "spread": 0.3},
		{"kind": "slam", "name": "Dogga Hammer", "color": Color(0.65, 0.35, 0.9)},
		{"kind": "kick", "name": "Darkness Moon Break", "color": Color(1.0, 0.85, 0.3), "jump": 440.0},
	],
	&"decade": [
		{"kind": "dash", "name": "Attack Ride: Slash", "color": Color(1.0, 0.4, 0.7)},
		{"kind": "fan", "name": "Attack Ride: Blast", "color": Color(1.0, 0.45, 0.75), "count": 5, "spread": 0.4},
		{"kind": "warp", "name": "Attack Ride: Invisible", "color": Color(0.95, 0.3, 0.65)},
		{"kind": "kick", "name": "Dimension Kick", "color": Color(1.0, 0.85, 0.3)},
	],
	&"double": [
		{"kind": "dash", "name": "Joker Rush", "color": Color(0.65, 0.3, 0.95)},
		{"kind": "fan", "name": "Trigger Magnum", "color": Color(0.35, 0.55, 1.0), "count": 4, "spread": 0.3},
		{"kind": "wave", "name": "Cyclone Gust", "color": Color(0.4, 1.0, 0.5)},
		{"kind": "kick", "name": "Joker Extreme", "color": Color(0.4, 1.0, 0.5)},
	],
	&"ooo": [
		{"kind": "dash", "name": "Tora Claws", "color": Color(1.0, 0.85, 0.2)},
		{"kind": "slam", "name": "Batta Leap", "color": Color(0.4, 1.0, 0.4)},
		{"kind": "fan", "name": "Taja Spinner", "color": Color(1.0, 0.45, 0.15), "count": 3, "style": "fire"},
		{"kind": "kick", "name": "Tatoba Kick", "color": Color(1.0, 0.35, 0.3)},
	],
	&"fourze": [
		{"kind": "dash", "name": "Rocket Module", "color": Color(1.0, 0.5, 0.2)},
		{"kind": "rain", "name": "Launcher Module", "color": Color(1.0, 0.85, 0.3), "count": 4},
		{"kind": "guard", "name": "Shield Module", "color": Color(0.9, 0.9, 1.0)},
		{"kind": "kick", "name": "Rider Rocket Drill Kick", "color": Color(1.0, 0.6, 0.2), "drill": true},
	],
	&"wizard": [
		{"kind": "fan", "name": "Flame Shooting", "color": Color(1.0, 0.35, 0.3), "count": 3, "style": "fire"},
		{"kind": "guard", "name": "Defend", "color": Color(1.0, 0.45, 0.3)},
		{"kind": "warp", "name": "Teleport", "color": Color(0.5, 0.8, 1.0)},
		{"kind": "kick", "name": "Strike Wizard", "color": Color(1.0, 0.35, 0.25)},
	],
	&"gaim": [
		{"kind": "dash", "name": "Daidaimaru", "color": Color(1.0, 0.55, 0.1)},
		{"kind": "fan", "name": "Musou Saber Shot", "color": Color(1.0, 0.75, 0.2), "count": 3},
		{"kind": "rain", "name": "Ichigo Kunai", "color": Color(1.0, 0.3, 0.35), "count": 5, "style": "arrow"},
		{"kind": "wave", "name": "Naginata Musou Slicer", "color": Color(1.0, 0.55, 0.1), "damage": 1.4},
	],
	&"drive": [
		{"kind": "haste", "name": "Speed! Speed! Speed!", "color": Color(1.0, 0.3, 0.3), "time": 3.0},
		{"kind": "dash", "name": "Handle-Ken Drift", "color": Color(1.0, 0.3, 0.3)},
		{"kind": "fan", "name": "Door-Ju", "color": Color(1.0, 0.3, 0.3), "count": 3},
		{"kind": "kick", "name": "SpeeDrop", "color": Color(1.0, 0.85, 0.3)},
	],
	&"ghost": [
		{"kind": "warp", "name": "Ghost Phase", "color": Color(1.0, 0.55, 0.15)},
		{"kind": "fan", "name": "Gan Gun Saber Shot", "color": Color(1.0, 0.55, 0.15), "count": 3},
		{"kind": "dash", "name": "Musashi Nitoryu", "color": Color(1.0, 0.3, 0.3)},
		{"kind": "kick", "name": "Omega Drive", "color": Color(1.0, 0.55, 0.15)},
	],
	&"ex_aid": [
		{"kind": "slam", "name": "Muteki Jump", "color": Color(1.0, 0.35, 0.75)},
		{"kind": "dash", "name": "Gashacon Breaker", "color": Color(1.0, 0.35, 0.75)},
		{"kind": "haste", "name": "Speed Up", "color": Color(1.0, 0.85, 0.3), "time": 3.0},
		{"kind": "kick", "name": "Mighty Critical Strike", "color": Color(1.0, 0.35, 0.75)},
	],
	&"build": [
		{"kind": "slam", "name": "Rabbit Hop", "color": Color(1.0, 0.3, 0.3)},
		{"kind": "dash", "name": "Tank Tread", "color": Color(0.35, 0.55, 1.0)},
		{"kind": "fan", "name": "Hawk Gatlinger", "color": Color(1.0, 0.6, 0.2), "count": 6, "spread": 0.35},
		{"kind": "kick", "name": "Vortex Finish", "color": Color(1.0, 0.4, 0.4)},
	],
	&"zi_o": [
		{"kind": "wave", "name": "Zikan Girade: Ken", "color": Color(1.0, 0.35, 0.7)},
		{"kind": "fan", "name": "Zikan Jacorder", "color": Color(1.0, 0.85, 0.3), "count": 1, "speed": 300.0,
			"style": "arrow", "damage": 1.3},
		{"kind": "warp", "name": "Time Mazine", "color": Color(1.0, 0.85, 0.3)},
		{"kind": "kick", "name": "Time Break", "color": Color(1.0, 0.35, 0.7)},
	],
}


## FORMS[rider] = các form Rider đối thủ đổi sang khi máu tụt dưới "at" (phần máu tối đa), lần lượt như trong phim:
##   "form"   id form (hình lấy từ bộ hình người chơi của form đó)   "name"  tên hiện trên đầu lúc đổi
##   "skills" tên kỹ năng (trong KITS) ưu tiên dùng ở form này        "color" màu chớp đổi form
##   "haste" / "guard" giây tăng tốc / dựng khiên ngay khi đổi        "speed" hệ số tốc độ chạy giữ suốt form
const FORMS := {
	&"kuuga": [
		{"at": 0.75, "form": &"dragon", "name": "Dragon Form", "skills": ["Dragon Leap"], "speed": 1.25,
			"color": Color(0.35, 0.55, 1.0)},
		{"at": 0.5, "form": &"pegasus", "name": "Pegasus Form", "skills": ["Pegasus Snipe"], "color": Color(0.4, 1.0, 0.5)},
		{"at": 0.3, "form": &"titan", "name": "Titan Form", "skills": ["Titan Guard", "Mighty Kick"], "guard": 3.0,
			"speed": 0.8, "color": Color(0.75, 0.45, 1.0)},
	],
	&"agito": [
		{"at": 0.7, "form": &"storm", "name": "Storm Form", "skills": ["Storm Halberd"], "speed": 1.2,
			"color": Color(0.35, 0.55, 1.0)},
		{"at": 0.45, "form": &"flame", "name": "Flame Form", "skills": ["Flame Saber"], "color": Color(1.0, 0.35, 0.15)},
		{"at": 0.25, "form": &"trinity", "name": "Trinity Form", "skills": ["Rider Kick"], "color": Color(1.0, 0.85, 0.3)},
	],
	&"ryuki": [
		{"at": 0.4, "form": &"survive", "name": "Survive!", "skills": ["Advent: Dragreder", "Dragon Rider Kick"],
			"color": Color(1.0, 0.3, 0.2)},
	],
	&"faiz": [
		{"at": 0.55, "form": &"axel", "name": "Complete: Axel Form", "skills": ["Grand Impact", "Crimson Smash"],
			"haste": 4.0, "color": Color(1.0, 0.35, 0.3)},
		{"at": 0.25, "form": &"blaster", "name": "Blaster Form", "skills": ["Faiz Edge", "Crimson Smash"],
			"color": Color(1.0, 0.15, 0.2)},
	],
	&"blade": [
		{"at": 0.6, "form": &"mach", "name": "Mach Jaguar", "skills": ["Slash Lizard"], "speed": 1.3, "color": Color(1.0, 0.75, 0.2)},
		{"at": 0.35, "form": &"jack", "name": "Jack Form", "skills": ["Lightning Blast"], "color": Color(0.4, 0.6, 1.0)},
	],
	&"hibiki": [
		{"at": 0.4, "form": &"kurenai", "name": "Hibiki Kurenai", "skills": ["Rekka Dan", "Ongekidaiko"],
			"color": Color(1.0, 0.3, 0.2)},
	],
	&"kabuto": [
		{"at": 0.35, "form": &"hyper", "name": "Hyper Cast Off", "skills": ["Clock Up", "Rider Kick"], "haste": 4.0,
			"color": Color(0.9, 0.9, 1.0)},
	],
	&"den_o": [
		{"at": 0.75, "form": &"rod", "name": "Rod Form", "skills": ["Wild Shot"], "color": Color(0.3, 0.5, 1.0)},
		{"at": 0.5, "form": &"ax", "name": "Ax Form", "skills": ["Dynamic Chop"], "guard": 2.5, "speed": 0.85,
			"color": Color(1.0, 0.85, 0.3)},
		{"at": 0.25, "form": &"gun", "name": "Gun Form", "skills": ["Wild Shot"], "color": Color(0.7, 0.4, 1.0)},
	],
	&"kiva": [
		{"at": 0.75, "form": &"garulu", "name": "Garulu Form", "skills": ["Garulu Saber"], "speed": 1.25,
			"color": Color(0.4, 0.6, 1.0)},
		{"at": 0.5, "form": &"basshaa", "name": "Basshaa Form", "skills": ["Basshaa Aqua Bullet"], "color": Color(0.3, 0.9, 0.6)},
		{"at": 0.3, "form": &"dogga", "name": "Dogga Form", "skills": ["Dogga Hammer"], "guard": 3.0, "speed": 0.8,
			"color": Color(0.65, 0.35, 0.9)},
	],
	## Decade đối thủ cũng Kamen Ride thành Rider khác như phim, cuối cùng Complete Form.
	&"decade": [
		{"at": 0.7, "form": &"kuuga", "name": "Kamen Ride: Kuuga", "skills": ["Attack Ride: Slash"],
			"color": Color(1.0, 0.35, 0.3)},
		{"at": 0.45, "form": &"faiz", "name": "Kamen Ride: Faiz", "skills": ["Attack Ride: Blast"], "haste": 3.0,
			"color": Color(1.0, 0.2, 0.25)},
		{"at": 0.2, "form": &"complete", "name": "Final Kamen Ride: Decade", "skills": ["Dimension Kick"],
			"color": Color(0.95, 0.3, 0.65)},
	],
	&"double": [
		{"at": 0.7, "form": &"heat_metal", "name": "HeatMetal", "skills": ["Joker Rush"], "color": Color(1.0, 0.35, 0.2)},
		{"at": 0.45, "form": &"luna_trigger", "name": "LunaTrigger", "skills": ["Trigger Magnum"], "color": Color(1.0, 0.85, 0.3)},
		{"at": 0.2, "form": &"xtreme", "name": "CycloneJokerXtreme", "skills": ["Joker Extreme"], "color": Color(0.6, 1.0, 0.85)},
	],
	&"ooo": [
		{"at": 0.7, "form": &"gatakiriba", "name": "GataKiriBa Combo", "skills": ["Tora Claws"], "color": Color(0.4, 1.0, 0.4)},
		{"at": 0.45, "form": &"tajador", "name": "TaJaDor Combo", "skills": ["Taja Spinner"], "color": Color(1.0, 0.45, 0.15)},
		{"at": 0.25, "form": &"sagohzo", "name": "SaGohZo Combo", "skills": ["Batta Leap"], "guard": 3.0, "speed": 0.8,
			"color": Color(0.7, 0.7, 0.75)},
	],
	&"fourze": [
		{"at": 0.6, "form": &"elek", "name": "Elek States", "skills": ["Rocket Module"], "color": Color(1.0, 0.9, 0.3)},
		{"at": 0.35, "form": &"fire", "name": "Fire States", "skills": ["Launcher Module"], "color": Color(1.0, 0.35, 0.2)},
	],
	&"wizard": [
		{"at": 0.7, "form": &"water", "name": "Water Style", "skills": ["Teleport"], "color": Color(0.3, 0.55, 1.0)},
		{"at": 0.45, "form": &"hurricane", "name": "Hurricane Style", "skills": ["Flame Shooting"], "speed": 1.25,
			"color": Color(0.4, 1.0, 0.5)},
		{"at": 0.25, "form": &"land", "name": "Land Style", "skills": ["Defend", "Strike Wizard"], "guard": 3.0,
			"color": Color(1.0, 0.85, 0.3)},
	],
	&"gaim": [
		{"at": 0.7, "form": &"pine", "name": "Pine Arms", "skills": ["Daidaimaru"], "speed": 0.85, "color": Color(0.85, 0.65, 0.2)},
		{"at": 0.45, "form": &"ichigo", "name": "Ichigo Arms", "skills": ["Ichigo Kunai"], "color": Color(1.0, 0.3, 0.35)},
		{"at": 0.25, "form": &"jimber_lemon", "name": "Jimber Lemon Arms", "skills": ["Musou Saber Shot",
			"Naginata Musou Slicer"], "color": Color(1.0, 0.9, 0.3)},
	],
	&"drive": [
		{"at": 0.65, "form": &"wild", "name": "Type Wild", "skills": ["Handle-Ken Drift"], "guard": 2.5,
			"color": Color(0.8, 0.8, 0.9)},
		{"at": 0.4, "form": &"technic", "name": "Type Technic", "skills": ["Door-Ju"], "color": Color(0.35, 0.95, 0.45)},
		{"at": 0.2, "form": &"formula", "name": "Type Formula", "skills": ["SpeeDrop"], "haste": 4.0,
			"color": Color(0.3, 0.55, 1.0)},
	],
	&"ghost": [
		{"at": 0.65, "form": &"musashi", "name": "Musashi Damashii", "skills": ["Musashi Nitoryu"], "color": Color(1.0, 0.3, 0.3)},
		{"at": 0.4, "form": &"edison", "name": "Edison Damashii", "skills": ["Gan Gun Saber Shot"], "color": Color(1.0, 0.9, 0.3)},
		{"at": 0.2, "form": &"newton", "name": "Newton Damashii", "skills": ["Omega Drive"], "color": Color(0.35, 0.55, 1.0)},
	],
	&"ex_aid": [
		{"at": 0.7, "form": &"sports", "name": "Sports Action Gamer", "skills": ["Muteki Jump"], "speed": 1.25,
			"color": Color(0.3, 0.9, 0.85)},
		{"at": 0.45, "form": &"robot", "name": "Robot Action Gamer", "skills": ["Gashacon Breaker"], "guard": 2.5,
			"color": Color(1.0, 0.35, 0.35)},
		{"at": 0.2, "form": &"hunter", "name": "Hunter Action Gamer", "skills": ["Mighty Critical Strike"],
			"color": Color(0.45, 0.95, 0.4)},
	],
	&"build": [
		{"at": 0.65, "form": &"gorilla_mond", "name": "GorillaMond", "skills": ["Tank Tread"], "guard": 2.5,
			"color": Color(0.55, 0.85, 1.0)},
		{"at": 0.4, "form": &"hawk_gatling", "name": "HawkGatling", "skills": ["Hawk Gatlinger"], "color": Color(1.0, 0.6, 0.2)},
		{"at": 0.2, "form": &"ninnin_comic", "name": "NinninComic", "skills": ["Vortex Finish"], "color": Color(0.75, 0.45, 1.0)},
	],
	&"zi_o": [
		{"at": 0.6, "form": &"ex_aid_armor", "name": "Armor Time: Ex-Aid", "skills": ["Zikan Girade: Ken"],
			"color": Color(1.0, 0.4, 0.8)},
		{"at": 0.35, "form": &"ghost_armor", "name": "Armor Time: Ghost", "skills": ["Time Mazine"], "color": Color(1.0, 0.55, 0.15)},
		{"at": 0.15, "form": &"decade_armor", "name": "Armor Time: Decade", "skills": ["Time Break"], "color": Color(0.95, 0.3, 0.6)},
	],
}


## Các form Rider `rider` đổi sang trong trận đấu (bản sao, kèm "rider").
static func forms(rider: StringName) -> Array:
	var out: Array = (FORMS.get(rider, []) as Array).duplicate(true)
	for f in out:
		f["rider"] = rider
	return out


## Rider đối thủ chưa có hình quái riêng ("rider_<id>" trong enemy_frames): mượn hình người chơi của form gốc.
const LOOKS := {&"decade": "decade_decade"}


## Bộ kỹ năng của Rider `rider`; Rider chưa có bộ riêng thì dùng `fallback` (bộ chung DUEL_BOSS).
static func kit(rider: StringName, fallback: Array) -> Array:
	return (KITS.get(rider, fallback) as Array).duplicate(true)


## Độ khó của màn đấu thứ `index` trong `count` màn của một thế giới phụ: chia ba nhóm theo thứ tự (Rider đời đầu →
## đời sau), bắt đầu từ Trung bình (1), rồi Khó (2), cuối là Rất khó (3).
static func level_of(index: int, count: int) -> int:
	return 1 + clampi(int(3.0 * index / float(maxi(count, 1))), 0, 2)


static func level_name(level: int) -> String:
	return str(LEVELS[clampi(level, 0, LEVELS.size() - 1)]["name"])
