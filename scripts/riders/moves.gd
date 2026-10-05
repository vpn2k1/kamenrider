extends RefCounted
class_name Moves
## Vũ đạo đòn theo nguyên tác: Final Attack và skill định hướng chuyển động thế nào (nhảy lên rồi đá chéo xuống, bay đá
## ngang, xoay người đá vòng, lướt chém xuyên qua quái, nhảy cao bổ xuống...). Player chạy vũ đạo (Player._motion_step)
## khi dữ liệu đòn có khóa "motion"; đòn không có vũ đạo (bắn, phép, trống, vùng tại chỗ) đánh như cũ.
##
## Một vũ đạo (Dictionary), các khóa tùy chọn ghi đè mặc định của kiểu:
##   "type"    "kick"    nhảy vọt lên ("rise" tốc độ bật, "rise_t" giây), khựng tạo dáng ("pose_t"), rồi lao chéo xuống theo
##                       góc "angle" (độ dưới phương ngang, 0 = bay ngang) với tốc độ "speed"; trúng thì bật ngược ra sau
##                       (Rider Kick kinh điển). "drill": giây khoan tại chỗ trúng (Crimson Smash, Rocket Drill Kick).
##                       "repeat": số cú đá nối nhau (SpeeDrop dội qua lại). "anim": "final" (cú đá) | "slash" (bổ kiếm)
##                       | "light" (đấm).
##             "spin"    quay lưng rồi xoay người đá vòng (Kabuto Rider Kick).
##             "through" thủ thế rồi lướt ngang xuyên qua quái ("speed", "dist" px), dừng sau lưng quái (chém iai, húc).
##             "slam"    nhảy cao rồi bổ thẳng xuống, nổ sóng xung kích khi chạm đất (Dynamic Chop, Dragon Leap).
## Final kiểu khoá / trói (Skills) vẫn chắc trúng: vũ đạo lao thẳng vào mục tiêu đã khoá, chạm là ra đòn.

const PRESETS := {
	## Rider Kick kinh điển: thủ thế, bật cao, khựng trên không, đá chéo xuống ~40°.
	"rider_kick": {"type": "kick", "rise": 360.0, "rise_t": 0.3, "pose_t": 0.14, "angle": 38.0, "speed": 540.0},
	## Bật rất cao rồi đá dốc xuống (Darkness Moon Break dưới trăng, Magna Blaze bổ nhào).
	"high_kick": {"type": "kick", "rise": 480.0, "rise_t": 0.38, "pose_t": 0.18, "angle": 58.0, "speed": 620.0},
	## Đá khoan: lao chéo xuống rồi khoan tại chỗ trúng nhiều nhịp (Crimson Smash, Rocket Drill Kick, Octo Banish).
	"drill_kick": {"type": "kick", "rise": 380.0, "rise_t": 0.3, "pose_t": 0.16, "angle": 42.0, "speed": 560.0,
		"drill": 0.42},
	## Đá bay ngang: nhảy thấp rồi lao thẳng (Solid Attack, Pine Squash, Burakawani).
	"flying_kick": {"type": "kick", "rise": 170.0, "rise_t": 0.12, "pose_t": 0.06, "angle": 6.0, "speed": 560.0},
	## SpeeDrop: Tridoron chạy vòng, Drive dội qua lại đá nhiều lần.
	"ricochet": {"type": "kick", "rise": 220.0, "rise_t": 0.14, "pose_t": 0.04, "angle": 14.0, "speed": 640.0,
		"repeat": 3},
	## Bổ nhào chém từ trên không (Splash Dragon, Lightning Slash của Jack Form).
	"dive_slash": {"type": "kick", "rise": 380.0, "rise_t": 0.3, "pose_t": 0.12, "angle": 48.0, "speed": 560.0,
		"anim": "slash"},
	## Xoay người đá vòng (Kabuto).
	"spin_kick": {"type": "spin"},
	## Lướt chém xuyên qua quái, dừng sau lưng (Saber Slash, Extreme Slash...).
	"slash_through": {"type": "through", "speed": 760.0, "dist": 160.0, "anim": "slash"},
	## Lao húc / đấm xuyên tới (xe, tên lửa, bánh xích).
	"charge": {"type": "through", "speed": 620.0, "dist": 150.0, "anim": "light"},
	## Nhảy cao bổ thẳng xuống, sóng xung kích khi chạm đất.
	"slam": {"type": "slam", "rise": 430.0, "rise_t": 0.3, "anim": "slash"},
	"stomp": {"type": "slam", "rise": 430.0, "rise_t": 0.3, "anim": "final"},
}

## Final Attack theo tên (khớp đuôi tên, nên "Rising Mighty Kick", "Shining Rider Kick" vẫn khớp). Không có tên ở đây:
## đòn bắn (&"ranged") đứng bắn, còn lại là Rider Kick.
const FINALS := {
	# Kuuga
	"Mighty Kick": "rider_kick", "Splash Dragon": "dive_slash", "Blast Pegasus": "", "Calamity Titan": "charge",
	# Agito
	"Rider Kick": "rider_kick", "Haldent Tornado": "", "Saber Slash": "slash_through", "Fire Storm Attack": "slash_through",
	# Ryuki
	"Dragon Rider Kick": "high_kick", "Dragon Fire Stream": "charge", "Drag Saber Slash": "slash_through",
	"Dragclaw Fire": "", "Advent: Dragreder": "",
	# Faiz
	"Crimson Smash": "drill_kick", "Accel Crimson Smash": "drill_kick",
	# Blade
	"Lightning Blast": "rider_kick", "Lightning Sonic": "rider_kick", "Thunder Deer": "", "Lightning Slash": "dive_slash",
	# Hibiki: đánh trống tại chỗ
	"Kaen Renda no Kata": "", "Rekka Dan": "", "Bakuretsu Kyouda no Kata": "", "Shakunetsu Shinku no Kata": "",
	# Kabuto (Rider Kick của Kabuto là Final kiểu phản đòn: xoay người đá vòng, xem final_motion)
	"Hyper Kick": "high_kick",
	# Den-O
	"Extreme Slash": "slash_through", "Solid Attack": "flying_kick", "Dynamic Chop": "slam", "Wild Shot": "",
	# Kiva
	"Darkness Moon Break": "high_kick", "Garulu Howling Slash": "slash_through", "Basshaa Aqua Tornado": "",
	"Dogga Thunder Slap": "slam",
	# Decade
	"Dimension Kick": "rider_kick", "Dimension Slash": "slash_through", "Dimension Blast": "",
	# W
	"Joker Extreme": "rider_kick", "Metal Branding": "charge", "Trigger Full Burst": "", "Xtreme Golden Extreme": "high_kick",
	# OOO
	"Tatoba Kick": "rider_kick", "Gush Cross": "slash_through", "Gatakiriba Kick": "rider_kick", "Octo Banish": "drill_kick",
	"Magna Blaze": "high_kick", "Sagohzo Impact": "slam", "Strain Doom": "slash_through",
	"Burakawani Scanning Charge": "flying_kick",
	# Fourze
	"Rider Rocket Drill Kick": "drill_kick", "Rider Rocket Punch": "charge", "Rider 10 Billion Volt Break": "slash_through",
	"Rider Bakunetsu Shoot": "",
	# Wizard
	"Strike Wizard": "rider_kick", "Strike Wizard (Land)": "rider_kick", "Shooting Strike": "", "Slash Strike": "slash_through",
	# Gaim
	"Naginata Musou Slicer": "slash_through", "Pine Squash": "flying_kick", "Ichigo Squash": "", "Sonic Volley": "",
	# Drive
	"SpeeDrop": "ricochet", "Full Throttle: Wild": "charge", "Full Throttle: Technic": "", "Formula Drop": "flying_kick",
	# Ghost
	"Omega Drive": "rider_kick", "Omega Slash": "slash_through", "Omega Shoot": "",
	# Ex-Aid
	"Mighty Critical Strike": "rider_kick", "Shakariki Critical Strike": "flying_kick", "Gekitotsu Critical Strike": "charge",
	"Drago Knight Critical Strike": "",
	# Build
	"Vortex Finish": "rider_kick", "Full Bullet": "", "Kaen Giri": "slash_through",
	# Zi-O và các Armor (kiểu đòn theo Rider gốc)
	"Time Break": "rider_kick", "Vortex Time Break": "rider_kick", "Critical Time Break": "slam",
	"Omega Time Break": "rider_kick", "Hissatsu Time Break": "ricochet", "Burai Time Break": "slash_through",
	"Strike Time Break": "rider_kick", "Scanning Time Break": "rider_kick", "Mighty Time Break": "rider_kick",
	"Rider Time Break": "rider_kick", "Dragon Time Break": "high_kick", "Exceed Time Break": "drill_kick",
	"Lightning Time Break": "slash_through", "Ongeki Time Break": "", "Rider Kick Time Break": "spin_kick",
	"Full Charge Time Break": "slash_through", "Wake Up Time Break": "high_kick", "Maximum Time Break": "rider_kick",
	"Limit Time Break": "drill_kick", "Attack Time Break": "rider_kick",
	# Zero-One
	"Rising Impact": "high_kick", "Flaming Impact": "slash_through", "Freezing Impact": "stomp", "Shining Impact": "rider_kick",
	# Saber
	"Kaen Juujizan": "slash_through", "Sansatsu Giri": "slash_through", "Shinka Ryuuhazan": "slam", "Hissatsu Dokuha": "",
	# Revice
	"Rex Stamping Finish": "rider_kick", "Eagle Stamping Finish": "high_kick", "Jackal Stamping Finish": "slash_through",
	"Mammoth Stamping Finish": "stomp",
	# Geats
	"Magnum Strike": "", "Boost Grand Strike": "high_kick", "Cú giáng Powered Builder": "slam",
	"Magnum Boost Grand Victory": "",
	# Gotchard
	"Steamhopper Fever": "rider_kick", "Appare Skebow Fever": "flying_kick", "Venom Mariner Fever": "",
	"Burning Gorilla Fever": "charge",
	# Gavv
	"Poppingummy Finish": "rider_kick", "Fuwamallow Finish": "", "Chocodan Finish": "", "Zakuzakuchips Finish": "slash_through",
	# Zeztz
	"Impact Vanish": "rider_kick", "Wing Vanish": "high_kick", "Plasma Vanish": "", "Gravity Vanish": "slam",
}

## Skill [Đ] theo tên: "move" mới thay cho "move" ghi trong dữ liệu (SkillCaster._aim).
##   "dive_kick" nhảy đá chéo xuống · "steep_kick" bật cao đạp dốc xuống · "flying_kick" bay đá ngang
##   "slash_through" lướt chém xuyên · "uppercut" đấm móc hất lên · "leap" nhảy cao bổ xuống
const SKILLS := {
	"Batta Leap": "dive_kick", "Hopper Leap": "dive_kick", "Steam Jump": "dive_kick", "Rabbit Hop": "steep_kick",
	"Muteki Jump": "steep_kick", "Eagle Dive": "steep_kick", "Drill Module": "dive_kick",
	"Cyclone Gust": "flying_kick", "Boost Kick": "flying_kick", "Wani Jaws": "flying_kick", "Rex Bite": "flying_kick",
	"Fox Tail": "flying_kick",
	"Accel Dash": "slash_through", "Mach Strike": "slash_through", "Mirror Dash": "slash_through",
	"Jackal Dash": "slash_through", "Shining Arrow": "slash_through", "Flame Saber": "slash_through",
	"Ground Uppercut": "uppercut", "Dynamic Chop Lite": "leap", "Dogga Hammer": "leap",
}

## Vũ đạo của skill theo "move" (SkillCaster._aim).
const SKILL_MOTIONS := {
	"dive_kick": {"type": "kick", "rise": 300.0, "rise_t": 0.22, "pose_t": 0.06, "angle": 35.0, "speed": 480.0},
	"steep_kick": {"type": "kick", "rise": 400.0, "rise_t": 0.28, "pose_t": 0.06, "angle": 62.0, "speed": 560.0},
	"flying_kick": {"type": "kick", "rise": 150.0, "rise_t": 0.1, "pose_t": 0.03, "angle": 5.0, "speed": 500.0,
		"max_t": 0.32},
	"slash_through": {"type": "through", "speed": 700.0, "dist": 120.0, "anim": "slash", "draw_t": 0.06},
	"leap": {"type": "slam", "rise": 380.0, "rise_t": 0.26, "anim": "slash"},
}


## Vũ đạo Final Attack tên `attack_name`. {} = đánh tại chỗ như cũ. `ranged`: đòn bắn (mặc định đứng bắn).
## Final kiểu phản đòn (Kabuto Rider Kick, Kamen Ride / Armor Kabuto) luôn là xoay người đá vòng.
static func final_motion(attack_name: String, ranged: bool, final_type := "aim") -> Dictionary:
	var key := _match(attack_name)
	var preset := ""
	if final_type == "counter":
		preset = "spin_kick"
	elif key != "":
		preset = str(FINALS[key])
	elif not ranged:
		preset = "rider_kick"
	return (PRESETS[preset] as Dictionary).duplicate() if PRESETS.has(preset) else {}


## Khóa dài nhất của FINALS mà tên đòn kết thúc bằng nó ("Shining Rider Kick" → "Rider Kick").
static func _match(attack_name: String) -> String:
	if FINALS.has(attack_name):
		return attack_name
	var best := ""
	for k in FINALS:
		if attack_name.ends_with(" " + str(k)) and str(k).length() > best.length():
			best = str(k)
	return best


## "move" theo nguyên tác của skill `skill_name` ("" = giữ như dữ liệu).
static func skill_move(skill_name: String) -> String:
	return str(SKILLS.get(skill_name, ""))
