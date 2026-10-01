extends Node
## Dữ liệu toàn cục (autoload "GameState"): tiến trình thế giới/màn, Driver đã có, cấp Rider,
## đội hình, Mảnh Ký Ức, lưu/đọc save. Đồng thời khai báo phím điều khiển.
##
## Trạng thái một Driver:  chưa có  →  phong ấn (nhận từ trùm)  →  hoạt động Lv1 (nhặt ở màn Thức tỉnh)  →  Lv5
## Form đặc biệt của Rider (Dragon, Axel, HeatMetal...) mở khi nhặt được ở màn tương ứng (WorldData "form").
## Đội hình trong màn: Rider CHÍNH (chọn trước mỗi màn, choose_main) + Rider của thế giới đang chơi nếu đã kích hoạt.
## Đổi Rider giữa màn chỉ đổi qua lại giữa hai Rider này.

signal driver_obtained(rider_id: StringName)
signal driver_activated(rider_id: StringName)
signal rider_leveled(rider_id: StringName, level: int)
signal equipped_changed
signal fragments_changed(amount: int)
signal form_unlocked(rider_id: StringName, form_id: StringName)

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 2
const MAX_LEVEL := 5
## Bản mẫu: mỗi lần mở game đều chơi lại từ màn 1-1. Đặt false để đọc save.
const DEBUG_FRESH_START := true
## Cấp quái: mỗi màn +1, mỗi thế giới +2/3 (làm tròn xuống): thế giới 1 Lv1–5, thế giới 4 Lv3–7, thế giới 11
## Lv7–11, thế giới 27 Lv18–22. Trùm +2. Tăng chậm để khớp với sức mạnh Rider theo thế hệ (POWER_PER_WORLD).
const ENEMY_LEVELS_PER_WORLD := 2.0 / 3.0
## Sức mạnh Rider theo thế hệ: Rider của thế giới thứ i (đếm từ 0) có máu và sát thương × (1 + 0.12 × i).
## Quái mỗi thế giới cũng mạnh thêm chừng đó, nên dùng Rider mới nhất thì độ khó các thế giới xấp xỉ nhau.
const POWER_PER_WORLD := 0.12
## Dạng người cũng mạnh dần theo hành trình: máu và sức đánh × (1 + 0.06 × số thế giới đã qua).
const HUMAN_POWER_PER_WORLD := 0.06
## Tên nhân vật chính do người chơi đặt ở màn hình đầu game (scenes/ui/name_entry.tscn).
const DEFAULT_PLAYER_NAME := "Sora"
const MAX_NAME_LENGTH := 12
const BOSS_LEVEL_BONUS := 2
## Hệ số sát thương của quái theo tiến độ, để các màn đầu dễ thở:
##   chưa có Driver nào (màn 1-1, đánh tay không) 35% · thế giới 1: 1-2 60%, 1-3 75%, 1-4 90%, trùm 100%
##   từ thế giới 2 trở đi 100%. Áp cho cả đòn đánh lẫn đạn của quái.
const NO_DRIVER_DAMAGE_MULT := 0.35
const WORLD1_DAMAGE_MULT := [0.35, 0.6, 0.75, 0.9, 1.0]

## Rider có script riêng. Rider khác dựng từ dữ liệu RIDER trong file thế giới (DataRider), không cần dòng ở đây.
const RIDER_SCRIPTS := {
	&"kuuga": "res://scripts/riders/kuuga.gd",
	&"faiz": "res://scripts/riders/faiz.gd",
	&"double": "res://scripts/riders/double.gd",
}

const INPUT_KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE],
	"attack_light": [KEY_J],
	"shoot": [KEY_H],
	"special": [KEY_L],
	"dodge": [KEY_SHIFT],
	"henshin": [KEY_I],
	"swap_rider": [KEY_O],
	"final_attack": [KEY_U],
	"ultimate": [],   ## nút tuyệt chiêu trên màn hình: biến thân hoặc Final Attack
}

var world_index := 0
var stage_index := 0
var worlds_cleared := 0
var drivers := {}                       ## "kuuga" -> {"active": bool, "level": int, "forms": ["dragon", ...]}
var main_rider: StringName = &""        ## Rider chính, chọn trước mỗi màn (màn chọn Rider)
var equipped: Array[StringName] = []    ## đội hình trong màn: [Rider chính, Rider của thế giới]; ô đầu dùng khi biến thân
var memory_fragments := 0
var cleared_stages: Array[String] = []
var rei_memories: Array[String] = []    ## ký ức ẩn của Rei đã nhặt → điều kiện Kết thúc thật
var player_name := DEFAULT_PLAYER_NAME
## Hội thoại đã xem (StoryData): "intro", "1-1:start", "world:kuuga"... Mỗi đoạn chỉ hiện một lần mỗi lượt chơi,
## gục rồi chơi lại từ checkpoint không bị lặp.
var seen_story: Array[String] = []
## Tắt để bot test chạy không dừng vì hội thoại.
var story_enabled := true
## Checkpoint trong màn hiện tại: chỉ số trong layout["checkpoints"] (-1 = đầu màn).
## Giữ qua lần chơi lại khi gục, xóa khi qua màn.
var checkpoint := -1


func _ready() -> void:
	_setup_input()
	if not DEBUG_FRESH_START:
		load_game()


# --- Tiến trình ----------------------------------------------------------

func set_player_name(value: String) -> void:
	var cleaned := value.strip_edges().left(MAX_NAME_LENGTH)
	player_name = cleaned if not cleaned.is_empty() else DEFAULT_PLAYER_NAME
	save_game()


## Lời thoại viết "{name}" ở chỗ gọi tên nhân vật chính, hàm này thay bằng tên người chơi đã đặt.
func format_text(text: String) -> String:
	return text.replace("{name}", player_name)


## Đánh dấu một đoạn hội thoại. Trả về true nếu đoạn này cần hiện (bật truyện và chưa xem).
func take_story(key: String) -> bool:
	if not story_enabled or seen_story.has(key):
		return false
	seen_story.append(key)
	return true


func has_active_driver() -> bool:
	for key in drivers:
		if bool(drivers[key]["active"]):
			return true
	return false


func enemy_damage_mult() -> float:
	if not has_active_driver():
		return NO_DRIVER_DAMAGE_MULT
	if world_index == 0:
		return WORLD1_DAMAGE_MULT[mini(stage_index, WORLD1_DAMAGE_MULT.size() - 1)]
	return 1.0


func current_enemy_level() -> int:
	return 1 + int(world_index * ENEMY_LEVELS_PER_WORLD) + stage_index


## Hệ số sức mạnh thế hệ của Rider (RiderForm.power).
func rider_power(id: StringName) -> float:
	return 1.0 + POWER_PER_WORLD * maxi(WorldData.world_index_of(id), 0)


## Hệ số sức mạnh dạng người (máu và sức đánh).
func human_power() -> float:
	return 1.0 + HUMAN_POWER_PER_WORLD * mini(world_index, WorldData.WORLDS.size() - 1)


func is_demo_finished() -> bool:
	return world_index >= WorldData.WORLDS.size()


func current_world() -> Dictionary:
	return WorldData.WORLDS[world_index]


func current_stage() -> Dictionary:
	var stages: Array = current_world()["stages"]
	return stages[stage_index]


## Gọi khi hoàn thành màn hiện tại (màn Thức tỉnh và màn Trùm: gọi lúc nhặt Driver).
## Trả về những gì vừa thay đổi để giao diện hiển thị.
func complete_stage() -> Dictionary:
	var world := current_world()
	var stage := current_stage()
	var rider: StringName = world["rider"]
	var result := {"world": world, "stage_id": stage["id"], "activated": false, "level": 0, "obtained": &"", "form_name": ""}

	if stage["type"] == WorldData.StageType.AWAKEN:
		activate_driver(rider)
		result["activated"] = true
		result["level"] = get_level(rider)

	var reward_level: int = stage["reward_level"]
	if reward_level > get_level(rider):
		set_level(rider, reward_level)
		result["level"] = reward_level

	# Form của màn đã được nhặt giữa màn; gọi lại ở đây để chắc chắn không bị kẹt tiến trình.
	var stage_form: StringName = stage.get("form", &"")
	if stage_form != &"":
		unlock_form(rider, stage_form)
		result["form_name"] = stage["form_name"]

	if stage["type"] == WorldData.StageType.BOSS:
		var next_driver: StringName = world["next_driver"]
		obtain_driver(next_driver)
		result["obtained"] = next_driver
		worlds_cleared += 1

	checkpoint = -1
	if not cleared_stages.has(stage["id"]):
		cleared_stages.append(stage["id"])
	var stages: Array = world["stages"]
	stage_index += 1
	if stage_index >= stages.size():
		stage_index = 0
		world_index += 1
		rebuild_team()   # sang thế giới mới: Rider của thế giới cũ không còn đi kèm
	save_game()
	return result


# --- Driver & cấp --------------------------------------------------------

## Nhận Driver ở trạng thái phong ấn (chưa biến thân được).
func obtain_driver(id: StringName) -> void:
	var key := String(id)
	if drivers.has(key):
		return
	drivers[key] = {"active": false, "level": 0, "forms": []}
	driver_obtained.emit(id)


## Kích hoạt Driver: biến thân được từ Lv1, tự vào ô đầu của đội hình.
func activate_driver(id: StringName) -> void:
	obtain_driver(id)
	var d: Dictionary = drivers[String(id)]
	if d["active"]:
		return
	d["active"] = true
	d["level"] = maxi(int(d["level"]), 1)
	driver_activated.emit(id)
	if main_rider == &"":
		main_rider = id
	rebuild_team()


func is_active(id: StringName) -> bool:
	var key := String(id)
	return drivers.has(key) and bool(drivers[key]["active"])


func get_level(id: StringName) -> int:
	var key := String(id)
	return int(drivers[key]["level"]) if drivers.has(key) else 0


func set_level(id: StringName, level: int) -> void:
	var key := String(id)
	if not drivers.has(key):
		return
	var lv := clampi(level, 1, MAX_LEVEL)
	drivers[key]["level"] = lv
	rider_leveled.emit(id, lv)


## Số ô trang bị: 1 ô lúc đầu, +1 mỗi thế giới đã qua, tối đa 3.
## Mở form đặc biệt cho Rider. Trả về true nếu là lần đầu (để biến thân ngay với nộ đầy).
func unlock_form(id: StringName, form_id: StringName) -> bool:
	var key := String(id)
	if not drivers.has(key) or has_form(id, form_id):
		return false
	var forms: Array = drivers[key].get("forms", [])
	forms.append(String(form_id))
	drivers[key]["forms"] = forms
	form_unlocked.emit(id, form_id)
	return true


func has_form(id: StringName, form_id: StringName) -> bool:
	var key := String(id)
	return drivers.has(key) and (drivers[key].get("forms", []) as Array).has(String(form_id))


## Các Rider chọn được làm Rider chính (mọi Driver đã kích hoạt), theo thứ tự thế giới.
func selectable_riders() -> Array[StringName]:
	var out: Array[StringName] = []
	for world in WorldData.WORLDS:
		var id: StringName = world["rider"]
		if is_active(id):
			out.append(id)
	return out


## Rider của thế giới đang chơi (form của màn chỉ rơi cho Rider này).
func world_rider() -> StringName:
	return current_world()["rider"] if not is_demo_finished() else &""


## Chọn Rider chính trước khi vào màn.
func choose_main(id: StringName) -> void:
	if not is_active(id):
		return
	main_rider = id
	rebuild_team()
	save_game()


## Đội hình = [Rider chính] + Rider của thế giới (nếu đã kích hoạt và khác Rider chính).
func rebuild_team() -> void:
	var team: Array[StringName] = []
	if main_rider != &"" and is_active(main_rider):
		team.append(main_rider)
	var wr := world_rider()
	if wr != &"" and is_active(wr) and not team.has(wr):
		team.append(wr)
	if team != equipped:
		equipped = team
		equipped_changed.emit()


func create_form(id: StringName) -> RiderForm:
	var form: RiderForm
	var path: String = RIDER_SCRIPTS.get(id, "")
	if not path.is_empty():
		form = (load(path) as GDScript).new()
	else:
		var data := WorldData.rider_data(id)
		if data.is_empty():
			push_warning("Chưa có dữ liệu cho Rider: %s" % id)
			return null
		form = DataRider.new(data, id)
	form.power = rider_power(id)
	form.set_level(maxi(get_level(id), 1))
	return form


func add_fragments(amount: int) -> void:
	memory_fragments += amount
	fragments_changed.emit(memory_fragments)


# --- Lưu / đọc -----------------------------------------------------------

func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"world_index": world_index,
		"stage_index": stage_index,
		"worlds_cleared": worlds_cleared,
		"drivers": drivers,
		"main_rider": str(main_rider),
		"fragments": memory_fragments,
		"cleared_stages": cleared_stages,
		"rei_memories": rei_memories,
		"player_name": player_name,
		"seen_story": seen_story,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Không ghi được save: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != SAVE_VERSION:
		push_warning("Save cũ hoặc hỏng, bắt đầu lại từ đầu.")
		return
	world_index = int(data.get("world_index", 0))
	stage_index = int(data.get("stage_index", 0))
	worlds_cleared = int(data.get("worlds_cleared", 0))
	drivers = data.get("drivers", {})
	main_rider = StringName(str(data.get("main_rider", "")))
	memory_fragments = int(data.get("fragments", 0))
	cleared_stages.clear()
	for s in data.get("cleared_stages", []):
		cleared_stages.append(str(s))
	rei_memories.clear()
	for s in data.get("rei_memories", []):
		rei_memories.append(str(s))
	player_name = str(data.get("player_name", DEFAULT_PLAYER_NAME))
	seen_story.clear()
	for s in data.get("seen_story", []):
		seen_story.append(str(s))
	rebuild_team()


func _setup_input() -> void:
	for action in INPUT_KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in INPUT_KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
