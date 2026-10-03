extends RefCounted
class_name WorldData
## Các thế giới Rider, xếp theo NĂM PHÁT SÓNG (FILES). Mỗi thế giới là một file trong scripts/data/worlds/
## (xem file mẫu w02_agito.gd), gồm các hằng:
##   WORLD       : Rider, Driver, quái, các màn (thường 5), trùm (bên dưới)
##   RIDER       : dữ liệu Rider cho DataRider (Kuuga / Faiz / W có script riêng thì để {})
##   SPEAKERS    : người nói riêng của thế giới (Echo Rider, trùm...), gộp vào StoryData.SPEAKERS
##   STORY       : hội thoại theo màn, khóa "1".."4" (hoặc tới "N-1"), "B" → nhịp "start" / "goal" / "key" / "clear"
##   WORLD_CLEAR : thoại trên bản đồ Chuỗi Trái Đất sau khi hạ trùm
##
## Thế giới dùng chung khuôn 5 màn (bậc 0..4 = khóa "tier" bộ nạp điền):
##   X-1 Thức tỉnh : chơi bằng Rider cũ (thế giới 1: dạng người), quái rơi Driver → nhặt → biến thân form gốc, Lv1
##   X-2..X-4      : màn luyện tập, quái rơi một form ("form" / "form_name"; Rider ít form như Kabuto có màn
##                   không rơi form), qua màn Rider +1 cấp
##   X-B Trùm      : hạ trùm → Lv5 + rơi Driver của thế giới kế tiếp (còn phong ấn)
## Rider nhiều form (OOO) có thể có nhiều màn luyện tập hơn (X-2..X-8): các màn này chia đều vào bậc 1..3, nên cấp
## thưởng, độ khó, lộ trình và đợt quái mặc định vẫn theo khuôn 5 màn (tier_of).
## Bộ nạp tự điền: "id" màn ("4-1".."4-B" theo vị trí trong FILES), "type", "tier", "reward_level", "next_driver" /
## "next_driver_name" (Driver của file kế tiếp; thế giới cuối rơi Chrono Driver), "route" và "waves" mặc định
## nếu file không ghi, đường dẫn ảnh nền "bg", và nhân máu / sát thương trùm theo thế hệ.
##
## Khóa của một màn trong WORLD["stages"]:
##   "name"       tên màn                      "goal"      mục tiêu (màn Thức tỉnh)
##   "form", "form_name"  form quái rơi ra ở màn luyện tập
##   "bg"         tên ảnh nền art/backgrounds/<bg>.png; "bg_theme" kiểu nền để tools/gen_backgrounds.py vẽ
##   "bg_tint"    màu phủ nền (tùy chọn)       "route", "waves"  (tùy chọn, xem StageBuilder)
##   "boss"       (X-B) {name, hp, damage, poise, speed, traits, color, sprite}: chỉ số ở thế giới 1,
##                bộ nạp nhân theo thế hệ (BOSS_HP_PER_WORLD, BOSS_DMG_PER_WORLD)
## Loại quái trong "waves": "basic", "fast", "armored", "boss" và quái đặc biệt "flying", "giant", "phantom", "spectral"
## (Enemy.SPECIALS, chỉ đòn đúng loại mới gây sát thương).
##
## Màn EX (StageType.CHALLENGE): mỗi thế giới có thêm một màn đặc biệt sau màn Trùm, id "<số>-EX", mở khi đã giải cứu
## thế giới đó, không nằm trong chuỗi tiến trình (không mở màn kế, không lên cấp). Quái đặc biệt một loại
## (CHALLENGE_THEMES theo thứ tự FILES, hoặc WORLD "challenge": {"special", "name", "waves", "route", "bg"} để ghi đè)
## lẫn với quái thường (quái thường cho nộ để vào form khắc chế). Qua lần đầu thưởng GameState.CHALLENGE_FRAGMENTS.
## Mỗi màn chỉ một loại quái đặc biệt vì mỗi màn chỉ mang được một form biến đổi (cộng item).
## w["main_count"] = số màn chính (không tính EX).
## "sprite": tiền tố animation trong art/characters/enemy_frames.tres. Thiếu thì hiện khối màu tạm.
##
## Thế giới phụ (SIDE_WORLDS, dữ liệu ở scripts/data/side_worlds.gd): nhánh rẽ từ một thế giới chính, chỉ số tiếp sau
## WORLDS (world_at(i) đọc cả hai). Màn StageType.DUEL: quái của thế giới Rider đối thủ, cuối đường đấu chính Rider đó,
## thắng thì nhặt form ("form") cho Rider của thế giới phụ. Màn khóa "source_world" (thế giới của Rider đối thủ) mở khi
## đã giải cứu thế giới đó; "level_world" = thế giới tính cấp quái (thế giới cha hoặc thế giới đối thủ, lấy cái sau hơn).

enum StageType { AWAKEN, TRAINING, BOSS, CHALLENGE, DUEL }
const SIDE := preload("res://scripts/data/side_worlds.gd")
const DUEL_WAVES := [["basic", "fast", "basic"], ["boss"]]

## Thứ tự năm phát sóng. Đổi thứ tự / chèn thế giới mới = sửa danh sách này (số màn và chuỗi Driver tự tính lại).
const FILES := [
	preload("res://scripts/data/worlds/w01_kuuga.gd"),      # 2000
	preload("res://scripts/data/worlds/w02_agito.gd"),      # 2001
	preload("res://scripts/data/worlds/w03_ryuki.gd"),      # 2002
	preload("res://scripts/data/worlds/w04_faiz.gd"),       # 2003
	preload("res://scripts/data/worlds/w05_blade.gd"),      # 2004
	preload("res://scripts/data/worlds/w06_hibiki.gd"),     # 2005
	preload("res://scripts/data/worlds/w07_kabuto.gd"),     # 2006
	preload("res://scripts/data/worlds/w08_den_o.gd"),      # 2007
	preload("res://scripts/data/worlds/w09_kiva.gd"),       # 2008
	preload("res://scripts/data/worlds/w10_decade.gd"),     # 2009
	preload("res://scripts/data/worlds/w11_double.gd"),     # 2009
	preload("res://scripts/data/worlds/w12_ooo.gd"),        # 2010
	preload("res://scripts/data/worlds/w13_fourze.gd"),     # 2011
	preload("res://scripts/data/worlds/w14_wizard.gd"),     # 2012
	preload("res://scripts/data/worlds/w15_gaim.gd"),       # 2013
	preload("res://scripts/data/worlds/w16_drive.gd"),      # 2014
	preload("res://scripts/data/worlds/w17_ghost.gd"),      # 2015
	preload("res://scripts/data/worlds/w18_ex_aid.gd"),     # 2016
	preload("res://scripts/data/worlds/w19_build.gd"),      # 2017
	preload("res://scripts/data/worlds/w20_zi_o.gd"),       # 2018
	preload("res://scripts/data/worlds/w21_zero_one.gd"),   # 2019
	preload("res://scripts/data/worlds/w22_saber.gd"),      # 2020
	preload("res://scripts/data/worlds/w23_revice.gd"),     # 2021
	preload("res://scripts/data/worlds/w24_geats.gd"),      # 2022
	preload("res://scripts/data/worlds/w25_gotchard.gd"),   # 2023
	preload("res://scripts/data/worlds/w26_gavv.gd"),       # 2024
	preload("res://scripts/data/worlds/w27_zeztz.gd"),      # 2025
]
const FINAL_DRIVER := &"chrono"
const FINAL_DRIVER_NAME := "Chrono Driver"
const BOSS_HP_PER_WORLD := 0.12
const BOSS_DMG_PER_WORLD := 0.10
const DEFAULT_BOSS := {"name": "Trùm", "hp": 250.0, "damage": 15.0, "poise": 25.0, "speed": 65.0, "traits": [],
	"color": Color(0.9, 0.9, 0.9)}
## Lộ trình mặc định theo thứ tự màn (Thức tỉnh luôn chạy thẳng sang phải, không vực: màn hướng dẫn).
## Mỗi màn chọn mẫu theo số thế giới để các thế giới không giống hệt nhau.
const DEFAULT_ROUTES := [
	[["right"]],
	[["right", "up", "right"], ["left"], ["right", "down", "left"], ["right"]],
	[["right", "down", "left"], ["up", "right", "up", "right"], ["left", "up", "left"], ["right", "up", "right"]],
	[["left", "up", "left"], ["left", "down", "right"], ["left", "down", "right", "down", "left"], ["right", "up", "left"]],
	[["up", "right"], ["left"], ["right", "up", "right"], ["right"]],
]
## Loại quái đặc biệt của màn EX từng thế giới (theo FILES), chọn theo form của chính Rider thế giới đó
## (tools/special_caps.tscn kiểm Rider của thế giới có form / item khắc chế, và form gốc KHÔNG tự khắc chế được — phải đổi
## form): Kuuga Titan, Agito Flame, Ryuki Strike Vent, Faiz Axel, Blade Thunder, Hibiki Kaentsuzumi, Kabuto Hyper,
## Den-O Gun, Kiva Basshaa, Decade Kabuto, W Heat, OOO Tajador, Fourze Elek, Wizard Land, Gaim Pine, Drive Formula, Ghost Edison, Ex-Aid Sports, Build HawkGatling, Zi-O Ex-Aid Armor,
## Zero-One Freezing Bear, Saber Dragonic Knight, Revice Mammoth, Geats Boost, Gotchard Venom Mariner, Gavv Chocodan,
## Zeztz Gravity.
const CHALLENGE_THEMES := [&"giant", &"spectral", &"flying", &"phantom", &"spectral", &"giant", &"phantom", &"flying",
	&"flying", &"phantom", &"spectral", &"flying", &"spectral", &"giant", &"giant", &"phantom", &"spectral", &"flying",
	&"flying", &"giant", &"giant", &"giant", &"giant", &"phantom", &"flying", &"flying", &"giant"]
## Tên màn EX theo loại quái: %s = tên quái thường của thế giới ("basic").
const CHALLENGE_NAMES := {&"flying": "EX: %s có cánh", &"giant": "EX: %s khổng lồ", &"phantom": "EX: %s siêu tốc",
	&"spectral": "EX: Bóng ma %s"}
const CHALLENGE_TIER := 3
const DEFAULT_WAVES := [
	[["basic", "basic", "basic"], ["basic", "armored", "basic"]],
	[["basic", "basic", "fast"], ["basic", "basic", "basic"]],
	[["basic", "fast", "armored"], ["basic", "basic", "fast"]],
	[["fast", "armored", "basic"], ["armored", "basic", "fast"]],
	[["basic", "fast"], ["boss"]],
]

# Thứ tự khai báo quan trọng: các bảng phụ phải có trước WORLDS (_build điền vào chúng).
static var riders := {}        ## rider_id -> RIDER (dữ liệu DataRider)
static var world_of_rider := {}  ## rider_id -> chỉ số thế giới
static var stories := {}       ## mã màn "4-2" -> {nhịp: [câu thoại]}
static var world_clear := {}   ## id thế giới -> [câu thoại trên bản đồ]
static var speakers := {}      ## người nói của các thế giới
static var WORLDS: Array = _build()
static var SIDE_WORLDS: Array = _build_side()


## Bậc 0..4 của màn thứ `si` trong `count` màn: 0 Thức tỉnh, 4 Trùm, màn luyện tập chia đều vào 1..3.
## Thế giới 5 màn: bậc = vị trí màn. OOO 9 màn: 0, 1, 1, 1, 2, 2, 3, 3, 4.
## Độ khó 0..1 của màn bậc `tier` (0..4) ở thế giới thứ `wi` (0..26): tăng đều theo thế giới, trong một thế giới
## tăng thêm theo bậc màn (Trùm khó nhất). StageBuilder / StageRun dùng để chỉnh mật độ quái, lính bắn, độ hung hăng,
## quái tinh nhuệ và cấp quái thêm (GameState.current_enemy_level).
static func difficulty_of(wi: int, tier: int) -> float:
	return clampf((wi + tier / 4.0) / float(maxi(FILES.size() - 1, 1)), 0.0, 1.0)


static func tier_of(si: int, count: int) -> int:
	if si == 0:
		return 0
	if si == count - 1:
		return 4
	return 1 + (si - 1) * 3 / maxi(count - 2, 1)



static func _first_of_tier(tier: int, count: int) -> int:
	for si in count:
		if tier_of(si, count) == tier:
			return si
	return 0

static func _build() -> Array:
	var out: Array = []
	for i in FILES.size():
		var consts: Dictionary = (FILES[i] as GDScript).get_script_constant_map()
		var w: Dictionary = (consts["WORLD"] as Dictionary).duplicate(true)
		var n := i + 1
		w["number"] = n
		var src: Array = w["stages"]
		var stages: Array = []
		for si in src.size():
			var st: Dictionary = src[si]
			var suffix := "B" if si == src.size() - 1 else str(si + 1)
			st["id"] = "%d-%s" % [n, suffix]
			st["type"] = StageType.AWAKEN if si == 0 else (StageType.BOSS if suffix == "B" else StageType.TRAINING)
			var tier := tier_of(si, src.size())
			st["tier"] = tier
			st["difficulty"] = difficulty_of(i, tier)
			st["reward_level"] = tier + 1
			if not st.has("route"):
				# Màn luyện tập thêm (trùng bậc với màn trước) lấy lộ trình kế tiếp trong danh sách để không lặp y hệt.
				var options: Array = DEFAULT_ROUTES[tier]
				var repeat := si - _first_of_tier(tier, src.size())
				st["route"] = options[(i + repeat) % options.size()]
			if not st.has("waves"):
				st["waves"] = DEFAULT_WAVES[tier]
			st["bg"] = "res://art/backgrounds/%s.png" % str(st.get("bg", "shibuya_night"))
			if st["type"] == StageType.BOSS:
				var boss: Dictionary = DEFAULT_BOSS.duplicate()
				boss.merge(st.get("boss", {}), true)
				boss["hp"] = float(boss["hp"]) * (1.0 + BOSS_HP_PER_WORLD * i)
				boss["damage"] = float(boss["damage"]) * (1.0 + BOSS_DMG_PER_WORLD * i)
				st["boss"] = boss
			var beats: Dictionary = (consts.get("STORY", {}) as Dictionary).get(suffix, {})
			if not beats.is_empty():
				stories[st["id"]] = beats
			stages.append(st)
		w["main_count"] = stages.size()
		stages.append(_challenge_stage(w, i, stages))
		w["stages"] = stages
		var rider: StringName = w["rider"]
		world_of_rider[rider] = i
		riders[rider] = consts.get("RIDER", {})
		world_clear[w["id"]] = consts.get("WORLD_CLEAR", [])
		speakers.merge(consts.get("SPEAKERS", {}), true)
		out.append(w)
	for i in out.size():
		if i + 1 < out.size():
			var nxt: Dictionary = out[i + 1]
			out[i]["next_driver"] = nxt["rider"]
			var dname: String = nxt["driver_name"]
			out[i]["next_driver_name"] = dname if dname.contains(str(nxt["rider_name"])) \
				else "%s (%s)" % [dname, nxt["rider_name"]]
		else:
			out[i]["next_driver"] = FINAL_DRIVER
			out[i]["next_driver_name"] = FINAL_DRIVER_NAME
	return out


## Thế giới phụ: chỉ số WORLDS.size() + thứ tự trong SideWorlds.WORLDS (xem đầu file).
static func _build_side() -> Array:
	var out: Array = []
	for k in SIDE.WORLDS.size():
		var src: Dictionary = SIDE.WORLDS[k]
		var parent_i := world_index_of(src["parent"])
		var parent: Dictionary = WORLDS[parent_i]
		var n := WORLDS.size() + k + 1
		var w := {
			"id": src["id"], "side": true, "parent_world": parent_i, "number": n, "year": parent["year"],
			"name": src["name"], "motto": src["motto"], "title": src["title"], "rider": parent["rider"],
			"rider_name": parent["rider_name"], "driver_name": parent["driver_name"], "color": parent["color"],
			"enemies": parent["enemies"], "unlocks": parent["unlocks"],
		}
		var forms: Dictionary = rider_data(parent["rider"]).get("forms", {})
		var stories_src: Dictionary = SIDE.STORY.get(src["id"], {})
		var stages: Array = []
		for duel in src["duels"]:
			var si := world_index_of(duel)
			if si < 0:
				continue
			var foe: Dictionary = WORLDS[si]
			var form := StringName(String(duel) + str(src["form_suffix"]))
			var form_title: String = (forms.get(form, {}) as Dictionary).get("name", String(form))
			var foe_name := str(foe["rider_name"])
			var level_world := maxi(parent_i, si)
			var boss: Dictionary = DEFAULT_BOSS.duplicate()
			boss.merge(SIDE.DUEL_BOSS, true)
			boss["name"] = "Kamen Rider %s" % foe_name
			boss["color"] = foe["color"]
			boss["sprite"] = "rider_%s" % duel
			boss["traits"] = (src.get("boss_traits", {}) as Dictionary).get(duel, [])
			boss["hp"] = float(boss["hp"]) * (1.0 + BOSS_HP_PER_WORLD * level_world)
			boss["damage"] = float(boss["damage"]) * (1.0 + BOSS_DMG_PER_WORLD * level_world)
			var foe_stages: Array = foe["stages"]
			var st := {
				"id": "%d-%d" % [n, stages.size() + 1],
				"name": str(src["stage_name"]).replace("{rider}", foe_name).replace("{year}", str(foe["year"])),
				"type": StageType.DUEL, "tier": 4, "reward_level": 0, "source_world": si, "level_world": level_world,
				"form": form, "form_name": form_title, "enemies": foe["enemies"], "boss": boss, "foe_name": foe_name,
				"route": DEFAULT_ROUTES[4][stages.size() % DEFAULT_ROUTES[4].size()], "waves": DUEL_WAVES,
				"bg": foe_stages[mini(1, foe_stages.size() - 1)]["bg"],
			}
			var own: Dictionary = stories_src.get(duel, {})
			var beats := {}
			for beat in src["template"]:
				var lines: Array = own.get(beat, src["template"][beat])
				var filled: Array = []
				for line in lines:
					filled.append([line[0], str(line[1]).replace("{rider}", foe_name).replace("{form}", form_title)
						.replace("{year}", str(foe["year"]))])
				beats[beat] = filled
			stories[st["id"]] = beats
			stages.append(st)
		w["stages"] = stages
		w["main_count"] = stages.size()
		out.append(w)
	return out


## Thế giới theo chỉ số: thế giới chính (0..WORLDS.size()-1) rồi tới thế giới phụ.
static func world_at(i: int) -> Dictionary:
	return WORLDS[i] if i < WORLDS.size() else SIDE_WORLDS[i - WORLDS.size()]


static func is_side(i: int) -> bool:
	return i >= WORLDS.size()


## Chỉ số các thế giới phụ rẽ ra từ thế giới chính w.
static func sides_of(w: int) -> Array[int]:
	var out: Array[int] = []
	for k in SIDE_WORLDS.size():
		if int(SIDE_WORLDS[k]["parent_world"]) == w:
			out.append(WORLDS.size() + k)
	return out


## Màn EX của thế giới thứ i (đếm từ 0), dựng sau các màn chính (xem đầu file).
static func _challenge_stage(w: Dictionary, i: int, stages: Array) -> Dictionary:
	var over: Dictionary = w.get("challenge", {})
	var special: StringName = over.get("special", CHALLENGE_THEMES[i % CHALLENGE_THEMES.size()])
	var x := String(special)
	var basic := str((w["enemies"] as Dictionary).get("basic", {}).get("name", "quái"))
	var last_training: Dictionary = stages[maxi(stages.size() - 2, 0)]
	var routes: Array = DEFAULT_ROUTES[CHALLENGE_TIER]
	var st := {
		"name": over.get("name", CHALLENGE_NAMES[special] % basic),
		"special": special,
		"route": over.get("route", routes[(i + 1) % routes.size()]),
		# Quái thường cho nộ (đánh ở form gốc), quái đặc biệt phải đổi sang form khắc chế. Đợt cuối = nhóm canh giữ ở đích.
		"waves": over.get("waves", [["basic", x, "basic"], ["fast", x, "armored"], [x, "basic", x]]),
		"id": "%d-EX" % (i + 1),
		"type": StageType.CHALLENGE,
		"tier": CHALLENGE_TIER,
		"difficulty": difficulty_of(i, 4),
		"reward_level": 0,
		"bg": "res://art/backgrounds/%s.png" % str(over["bg"]) if over.has("bg") else last_training["bg"],
	}
	if last_training.has("bg_tint"):
		st["bg_tint"] = last_training["bg_tint"]
	return st


## Màn EX (StageType.CHALLENGE) của thế giới w.
static func challenge_of(w: int) -> Dictionary:
	var stages: Array = WORLDS[w]["stages"]
	return stages[stages.size() - 1]


## Tên hiển thị của một form đặc biệt (tra từ các màn có "form"). Không có thì trả về "".
static func form_name(rider: StringName, form: StringName) -> String:
	for world in WORLDS + SIDE_WORLDS:
		if world["rider"] != rider:
			continue
		for stage in world["stages"]:
			if stage.get("form", &"") == form:
				return stage["form_name"]
	return ""


## Dữ liệu DataRider của Rider (rỗng nếu Rider có script riêng hoặc không có).
static func rider_data(rider: StringName) -> Dictionary:
	return riders.get(rider, {})


## Form là item (vũ khí / lá bài / đòn, "item": true trong RIDER.forms): quái rơi, mang vào màn khi chọn.
static func form_is_item(rider: StringName, form: StringName) -> bool:
	var forms: Dictionary = rider_data(rider).get("forms", {})
	return bool((forms.get(form, {}) as Dictionary).get("item", false))


## Chỉ số thế giới của Rider (-1 nếu không phải Rider của thế giới nào, ví dụ Chrono Driver).
static func world_index_of(rider: StringName) -> int:
	return int(world_of_rider.get(rider, -1))


## Màu khối tạm / màu nhận diện của Rider (WORLD "color").
static func rider_color(rider: StringName) -> Color:
	var i := world_index_of(rider)
	return WORLDS[i].get("color", Color.WHITE) if i >= 0 else Color(0.9, 0.9, 0.9)
