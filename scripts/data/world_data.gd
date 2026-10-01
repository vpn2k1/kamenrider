extends RefCounted
class_name WorldData
## Các thế giới Rider, xếp theo NĂM PHÁT SÓNG (FILES). Mỗi thế giới là một file trong scripts/data/worlds/
## (xem file mẫu w02_agito.gd), gồm các hằng:
##   WORLD       : Rider, Driver, quái, 5 màn, trùm (bên dưới)
##   RIDER       : dữ liệu Rider cho DataRider (Kuuga / Faiz / W có script riêng thì để {})
##   SPEAKERS    : người nói riêng của thế giới (Echo Rider, trùm...), gộp vào StoryData.SPEAKERS
##   STORY       : hội thoại theo màn, khóa "1".."4", "B" → nhịp "start" / "goal" / "key" / "clear"
##   WORLD_CLEAR : thoại trên bản đồ Chuỗi Trái Đất sau khi hạ trùm
##
## Mọi thế giới dùng chung khuôn 5 màn:
##   X-1 Thức tỉnh : chơi bằng Rider cũ (thế giới 1: dạng người), quái rơi Driver → nhặt → biến thân form gốc, Lv1
##   X-2..X-4      : màn luyện tập, quái rơi một form ("form" / "form_name"; Rider ít form như Kabuto có màn
##                   không rơi form), qua màn Rider +1 cấp
##   X-B Trùm      : hạ trùm → Lv5 + rơi Driver của thế giới kế tiếp (còn phong ấn)
## Bộ nạp tự điền: "id" màn ("4-1".."4-B" theo vị trí trong FILES), "type", "reward_level", "next_driver" /
## "next_driver_name" (Driver của file kế tiếp; thế giới cuối rơi Chrono Driver), "route" và "waves" mặc định
## nếu file không ghi, đường dẫn ảnh nền "bg", và nhân máu / sát thương trùm theo thế hệ.
##
## Khóa của một màn trong WORLD["stages"]:
##   "name"       tên màn                      "goal"      mục tiêu (màn Thức tỉnh)
##   "form", "form_name"  form quái rơi ra ở màn (X-2..X-4)
##   "bg"         tên ảnh nền art/backgrounds/<bg>.png; "bg_theme" kiểu nền để tools/gen_backgrounds.py vẽ
##   "bg_tint"    màu phủ nền (tùy chọn)       "route", "waves"  (tùy chọn, xem StageBuilder)
##   "boss"       (X-B) {name, hp, damage, poise, speed, traits, color, sprite}: chỉ số ở thế giới 1,
##                bộ nạp nhân theo thế hệ (BOSS_HP_PER_WORLD, BOSS_DMG_PER_WORLD)
## Loại quái trong "waves": "basic", "fast", "armored", "boss".
## "sprite": tiền tố animation trong art/characters/enemy_frames.tres. Thiếu thì hiện khối màu tạm.

enum StageType { AWAKEN, TRAINING, BOSS }

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
			st["reward_level"] = si + 1
			if not st.has("route"):
				var options: Array = DEFAULT_ROUTES[mini(si, DEFAULT_ROUTES.size() - 1)]
				st["route"] = options[i % options.size()]
			if not st.has("waves"):
				st["waves"] = DEFAULT_WAVES[mini(si, DEFAULT_WAVES.size() - 1)]
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


## Tên hiển thị của một form đặc biệt (tra từ các màn có "form"). Không có thì trả về "".
static func form_name(rider: StringName, form: StringName) -> String:
	for world in WORLDS:
		if world["rider"] != rider:
			continue
		for stage in world["stages"]:
			if stage.get("form", &"") == form:
				return stage["form_name"]
	return ""


## Dữ liệu DataRider của Rider (rỗng nếu Rider có script riêng hoặc không có).
static func rider_data(rider: StringName) -> Dictionary:
	return riders.get(rider, {})


## Chỉ số thế giới của Rider (-1 nếu không phải Rider của thế giới nào, ví dụ Chrono Driver).
static func world_index_of(rider: StringName) -> int:
	return int(world_of_rider.get(rider, -1))


## Màu khối tạm / màu nhận diện của Rider (WORLD "color").
static func rider_color(rider: StringName) -> Color:
	var i := world_index_of(rider)
	return WORLDS[i].get("color", Color.WHITE) if i >= 0 else Color(0.9, 0.9, 0.9)
