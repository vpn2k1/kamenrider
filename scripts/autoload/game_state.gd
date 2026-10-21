extends Node
## Dữ liệu toàn cục (autoload "GameState"): tiến trình thế giới/màn, Driver đã có, chỉ số cộng của form,
## đội hình, Mảnh Ký Ức, lưu/đọc save. Đồng thời khai báo phím điều khiển.
##
## Trạng thái một Driver:  chưa có  →  phong ấn (nhận từ trùm)  →  hoạt động (nhặt ở màn Thức tỉnh)
## Không có cấp Rider: qua màn thì form dùng trong màn được cộng chỉ số (stage_clear_bonus). "level" trong drivers chỉ là
## mốc tiến độ ẩn 1..5 để mở thưởng theo nguyên tác (Rising, Best Match, final form "lv5").
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
## Chế độ test (unlock_all_for_test): mở hết thế giới / Rider / form / item, lưu vào save riêng này để không đè lên
## tiến trình thật. Chỉ có khi chạy từ Godot editor (test_tools_enabled); bật / tắt ở màn hình chính, nhớ trong
## settings.cfg ("debug", "test_save"). Bản export (APK, web) luôn dùng save thật.
const TEST_SAVE_PATH := "user://save_test.json"
## Cài đặt người chơi (tên nhân vật), tách khỏi save tiến trình: save cũ / hỏng bị làm lại thì tên vẫn còn.
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_VERSION := 4                ## 4: OOO có 9 màn (chỉ số màn thế giới 12 đổi)
const MAX_LEVEL := 5
const MAX_ITEMS := 2                    ## số item (vũ khí) mang vào một màn
## Đặt true để mỗi lần mở game đều chơi lại từ màn 1-1 (không đọc save). Mặc định đọc save: Driver, cấp, form và
## item đã nhặt, màn đã qua được giữ lại giữa các lần mở game (user://save.json; bản web lưu trong trình duyệt).
const DEBUG_FRESH_START := false
## Sức mạnh quái theo màn (liên tục, không làm tròn): máu × (1 + 0,12 × thế giới) × (1 + 0,05 × bậc màn), sát thương
## × (1 + 0,11 × thế giới) × (1 + 0,04 × bậc màn). Thế giới đếm từ 0 (level_world), bậc màn 0..4 (WorldData.tier_of).
## Mỗi thế giới quái mạnh lên đúng bằng Rider của thế giới đó (POWER_PER_WORLD); trong một thế giới, quái tăng vừa
## bằng chỉ số form nhận được khi qua các màn trước (STAGE_BONUS). Độ khó cao thì quái đánh dồn hơn
## (StageRun._apply_difficulty), không dồn thêm máu.
const ENEMY_HP_PER_WORLD := 0.12
const ENEMY_DAMAGE_PER_WORLD := 0.11
const ENEMY_HP_PER_TIER := 0.05
const ENEMY_DAMAGE_PER_TIER := 0.04
const ELITE_HP_MULT := 1.15             ## quái tinh nhuệ (★): nhỉnh hơn quái thường, đặc tính thêm mới là cái khó
const ELITE_DAMAGE_MULT := 1.1
## Sức mạnh Rider theo thế hệ: Rider của thế giới thứ i (đếm từ 0) có máu và sát thương × (1 + 0.12 × i).
## Quái mỗi thế giới cũng mạnh thêm chừng đó, nên dùng Rider mới nhất thì độ khó các thế giới xấp xỉ nhau.
## Đồng bộ theo màn: trong màn của thế giới w, Rider tính tối đa như Rider thế giới w + POWER_SYNC_AHEAD (Rider đời sau
## về màn cũ vẫn mạnh hơn một chút nhưng không áp đảo), và tối thiểu như Rider thế giới w: Rider đời trước vào màn mới
## được nâng máu / sát thương / giáp cho xứng với quái (không còn một chiêu của trùm mất nửa máu).
## Luyện lại: Rider đời trước muốn dùng ở thế giới sau phải chơi lại màn đã qua. Mỗi lần qua lại một màn bằng Rider đó,
## Rider được thêm TRAIN_PER_REPLAY đời sức mạnh (trùm TRAIN_PER_BOSS), lưu ở drivers[rider]["train"], tối đa bằng
## Rider của thế giới cuối. Ví dụ Kuuga muốn mạnh như Rider thế giới 10 cần khoảng 9 / 0,5 = 18 lần qua lại màn.
const POWER_PER_WORLD := 0.12
const POWER_SYNC_AHEAD := 2
const TRAIN_PER_REPLAY := 0.5
const TRAIN_PER_BOSS := 1.0
## Dạng người cũng mạnh dần theo hành trình: máu và sức đánh × (1 + 0.06 × số thế giới đã qua).
const HUMAN_POWER_PER_WORLD := 0.06
## Tên nhân vật chính do người chơi đặt ở màn nhập tên (scenes/ui/name_entry.tscn, sau màn hình chính).
const DEFAULT_PLAYER_NAME := "Sora"
const MAX_NAME_LENGTH := 12
const CHALLENGE_FRAGMENTS := 150        ## qua màn EX lần đầu (WorldData.StageType.CHALLENGE)
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
	"attack_slash": [KEY_K],     ## chém bằng vũ khí cận chiến (form có kiếm)
	"special": [KEY_L],
	"dodge": [KEY_SHIFT],
	"henshin": [KEY_I],
	"swap_rider": [],            ## đổi Rider (mỗi màn một Rider nên không gán phím)
	"menu": [KEY_ESCAPE, KEY_P],   ## về màn chọn màn
	"final_attack": [KEY_O],
	"skill_1": [KEY_U],          ## skill nhẹ của form (docs/SKILLS.md)
	"skill_2": [KEY_Y],          ## skill mạnh của form
	"ultimate": [],   ## nút tuyệt chiêu trên màn hình: biến thân hoặc Final Attack
	"help": [KEY_TAB, KEY_F1],   ## nút "?" góc trên phải: bảng thông tin màn + hướng dẫn (HelpOverlay)
	"auto_attack": [KEY_T],   ## bật / tắt tự đánh (Player._auto_attack_step), không có ở chế độ đấu
}

var world_index := 0                    ## màn đang chơi (chọn ở màn chọn màn)
var stage_index := 0
var frontier_world := 0                 ## màn xa nhất đã mở: các màn tới đây chọn được, qua màn này thì mở màn kế
var frontier_stage := 0
var in_stage := false                   ## đang trong màn (gục thì tải lại vào thẳng màn đó, không về màn chọn màn)
var carried_items: Array[StringName] = []   ## item của Rider chính mang vào màn đang chơi (tối đa MAX_ITEMS)
## Form biến đổi dùng được trong màn đang chơi: form chọn trước màn (tối đa 1, như trận đấu) + form nhặt giữa màn.
var carried_forms: Array[StringName] = []
var chosen_form: StringName = &""       ## form chọn mang vào màn (&"" = form gốc), nhận chỉ số khi qua màn (stage_clear_bonus)
var worlds_cleared := 0
var drivers := {}                       ## "kuuga" -> {"active": bool, "level": int, "forms": ["dragon", ...]}
## Chỉ số cộng thêm của từng form: "kuuga" -> {"dragon" -> {"atk": 0.0123, ...}} = +1.23% sức đánh cho riêng form đó
## (RiderForm.bonus; dạng người lưu ở HUMAN_KEY / HUMAN_KEY, Player tự áp). Chỉ số: BOOST_STATS.
## Nhận được khi qua màn (stage_clear_bonus): form mang vào màn (form gốc nếu không mang form nào; chưa có Rider thì
## dạng người) được STAGE_BONUS: Sát thương + Máu + một chỉ số đặc trưng của form (form nặng thêm Giáp, form nhanh
## thêm Tốc độ...). Các form khác Rider đó đã có nhận OTHER_FORMS_SHARE phần. Chơi lại màn đã qua: REPLAY_SHARE phần.
## Form mới nhặt kế thừa Sát thương / Máu đã cộng của form gốc (không phải bắt đầu lại từ 0). Mỗi chỉ số có trần
## BONUS_CAP. Hạ quái không cộng chỉ số (chỉ cho nộ). Qua 4 màn đầu của một thế giới, Rider được khoảng +24% sát thương,
## +20% máu: bằng mức quái mạnh lên tới màn Trùm (ENEMY_*_PER_TIER).
var form_bonus := {}
const BOOST_STEP := 0.01        ## (save cũ) mỗi điểm cũ = +1%, đổi sang tỉ lệ khi đọc save
const STAGE_BONUS := {"atk": 0.06, "hp": 0.05, "signature": 0.05}
const OTHER_FORMS_SHARE := 0.75
const REPLAY_SHARE := 1.0 / 3.0
const BONUS_CAP := {"atk": 0.5, "hp": 0.5, "armor": 0.25, "speed": 0.25, "jump": 0.25, "poise": 0.25}
## Mức "bình thường" của từng chỉ số đặc trưng: form có tỉ lệ chỉ số / mức này cao nhất thì chỉ số đó là đặc trưng.
const SIGNATURE_NORMS := {"armor": 25.0, "speed": 125.0, "jump": 1.0, "poise": 10.0}
const HUMAN_KEY := &"human"
const HUMAN_BOOST_STATS := ["hp", "atk", "speed", "jump"]   ## dạng người không có giáp / trụ vững
const BOOST_STATS := {"hp": "Máu", "atk": "Sát thương", "armor": "Giáp", "speed": "Tốc độ", "jump": "Sức nhảy",
	"poise": "Trụ vững"}
var main_rider: StringName = &""        ## Rider dùng trong màn, chọn trước mỗi màn; trong màn không đổi Rider
var equipped: Array[StringName] = []    ## [Rider chính] (một Rider mỗi màn)
var memory_fragments := 0
var cleared_stages: Array[String] = []
var rei_memories: Array[String] = []    ## ký ức ẩn của Rei đã nhặt → điều kiện Kết thúc thật
var player_name := DEFAULT_PLAYER_NAME
## Đã đặt tên (lưu trong SETTINGS_PATH): mở game lại thì vào thẳng, không qua màn nhập tên (đổi tên ở màn hình chính).
var name_set := false
## Hội thoại đã xem (StoryData): "intro", "1-1:start", "world:kuuga"... Mỗi đoạn chỉ hiện một lần mỗi lượt chơi,
## gục rồi chơi lại màn không bị lặp.
var seen_story: Array[String] = []
## Tắt để bot test chạy không dừng vì hội thoại.
var story_enabled := true
## Chế độ đấu 2 người qua WiFi (scenes/versus/versus.tscn). Chỉ dùng Rider đã kích hoạt Driver, với cấp và sức mạnh
## như ở hành trình; trong trận chỉ dùng được form và item đã chọn trước trận (versus_form, versus_items, phải là thứ đã
## nhặt được). Dạng người ai cũng như nhau (human_power = 1).
var versus := false
var versus_rider: StringName = &""
var versus_form: StringName = &""          ## &"" = chỉ form gốc
var versus_items: Array[StringName] = []   ## tối đa MAX_ITEMS
## false: không đọc / ghi save (bot test gọi use_test_profile để không đè lên tiến trình thật của người chơi).
var persist := true
var test_save := false   ## đang dùng save test (TEST_SAVE_PATH) đã mở hết
var auto_attack := false ## tự đánh quái đang khoá (nút "Tự đánh" / phím T), nhớ trong settings.cfg; chế độ đấu luôn tắt


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # nút back vẫn nhận khi game đang dừng (hội thoại)
	_setup_input()
	load_settings()
	if not DEBUG_FRESH_START:
		load_game()


## Nút back của Android (project.godot: quit_on_go_back = false) = bấm phím Esc: quay lại ở mọi màn (chọn màn, chọn
## Rider / form / item, hội thoại, bảng hướng dẫn, nhập tên, trong màn về màn chọn màn); màn hình chính thì thoát app.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_tap_key(KEY_ESCAPE)


func _tap_key(key: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = key
		ev.physical_keycode = key
		ev.pressed = pressed
		Input.parse_input_event(ev)
		if pressed:
			await get_tree().process_frame


## Bot test: bắt đầu từ tiến trình trống và không ghi save (save thật của người chơi giữ nguyên).
func use_test_profile() -> void:
	persist = false
	_reset_progress()


## Xoá tiến trình trong bộ nhớ (không đụng file save).
func _reset_progress() -> void:
	world_index = 0
	stage_index = 0
	frontier_world = 0
	frontier_stage = 0
	in_stage = false
	carried_items.clear()
	carried_forms.clear()
	worlds_cleared = 0
	drivers = {}
	form_bonus = {}
	main_rider = &""
	memory_fragments = 0
	cleared_stages.clear()
	rei_memories.clear()
	player_name = DEFAULT_PLAYER_NAME
	name_set = false
	seen_story.clear()
	versus_rider = &""
	versus_form = &""
	versus_items.clear()
	rebuild_team()


## Chế độ test: chuyển sang save test rồi mở hết mọi thế giới (chính + phụ), mọi Driver ở cấp tối đa, mọi form và
## item. Save thật (SAVE_PATH) giữ nguyên; leave_test_save() để quay về.
func unlock_all_for_test() -> void:
	if not test_tools_enabled():
		return
	_set_test_save(true)
	_reset_progress()
	load_settings()              # giữ tên nhân vật
	var keep_persist := persist
	persist = false              # ghi một lần ở cuối, không ghi mỗi form
	for world in WorldData.WORLDS:
		var rider: StringName = world["rider"]
		activate_driver(rider)
		set_level(rider, MAX_LEVEL)
		var forms := RiderCaps.all_forms(rider)
		for i in range(1, forms.size()):          # forms[0] là form gốc
			unlock_form(rider, forms[i])
	for w in WorldData.WORLDS.size() + WorldData.SIDE_WORLDS.size():
		for stage in WorldData.world_at(w)["stages"]:
			if not cleared_stages.has(str(stage["id"])):
				cleared_stages.append(str(stage["id"]))
	frontier_world = WorldData.WORLDS.size()
	frontier_stage = 0
	worlds_cleared = WorldData.WORLDS.size()
	name_set = true
	persist = keep_persist
	rebuild_team()
	save_game()


## Thoát chế độ test: về save thật như lúc chưa bật.
func leave_test_save() -> void:
	_set_test_save(false)
	_reset_progress()
	load_settings()
	load_game()


func _set_test_save(on: bool) -> void:
	test_save = on
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("debug", "test_save", on)
	cfg.save(SETTINGS_PATH)


## Công cụ test chỉ chạy khi mở game từ Godot editor trên máy phát triển, không bao giờ trong bản export.
func test_tools_enabled() -> bool:
	return OS.has_feature("editor")


func _save_path() -> String:
	return TEST_SAVE_PATH if test_save else SAVE_PATH


# --- Tiến trình ----------------------------------------------------------

## Bật / tắt tự đánh (nhớ cho lần chơi sau).
func set_auto_attack(on: bool) -> void:
	auto_attack = on
	save_settings()


## Tự đánh có tác dụng không: chế độ đấu luôn tắt (đấu công bằng).
func auto_attack_on() -> bool:
	return auto_attack and not versus


func set_player_name(value: String) -> void:
	var cleaned := value.strip_edges().left(MAX_NAME_LENGTH)
	player_name = cleaned if not cleaned.is_empty() else DEFAULT_PLAYER_NAME
	name_set = true
	save_settings()


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


## Bậc của màn đang chơi 0..4 (WorldData.tier_of).
func current_tier() -> int:
	return int(current_stage().get("tier", stage_index))


## Hệ số máu quái thường của màn đang chơi (trùm có chỉ số chỉnh tay trong WorldData).
func enemy_hp_scale() -> float:
	return (1.0 + ENEMY_HP_PER_WORLD * level_world()) * (1.0 + ENEMY_HP_PER_TIER * current_tier())


## Hệ số sát thương quái thường của màn đang chơi (nhân thêm enemy_damage_mult của các màn đầu).
func enemy_damage_scale() -> float:
	return (1.0 + ENEMY_DAMAGE_PER_WORLD * level_world()) * (1.0 + ENEMY_DAMAGE_PER_TIER * current_tier())


## Độ khó 0..1 của màn đang chơi (WorldData.difficulty_of): thế giới càng sau càng khó.
func difficulty() -> float:
	return float(current_stage().get("difficulty", 0.0))


## Thế giới tính cấp quái / sức mạnh dạng người: thế giới đang chơi, màn ở thế giới phụ thì theo "level_world" của màn.
func level_world() -> int:
	return int(current_stage().get("level_world", world_index))


## Hệ số sức mạnh thế hệ của Rider (RiderForm.power), đồng bộ theo thế giới của màn đang chơi (POWER_SYNC_AHEAD).
## Chế độ đấu: mọi Rider = 1 cho công bằng.
func rider_power(id: StringName) -> float:
	if versus:
		return 1.0
	var gen := clampf(rider_generation(id), float(level_world()), float(level_world() + POWER_SYNC_AHEAD))
	return 1.0 + POWER_PER_WORLD * gen


## Đời sức mạnh của Rider chưa đồng bộ theo màn: thế giới gốc (đếm từ 0) + số đời đã luyện lại.
func rider_generation(id: StringName) -> float:
	var base := float(maxi(WorldData.world_index_of(id), 0))
	var train := float((drivers.get(String(id), {}) as Dictionary).get("train", 0.0))
	return minf(base + train, float(WorldData.WORLDS.size() - 1))


## Qua lại màn đã qua bằng Rider `id`: cộng đời sức mạnh luyện lại. Trả về số đời vừa cộng (0 nếu đã tối đa).
func train_rider(id: StringName, boss: bool) -> float:
	var key := String(id)
	if not drivers.has(key):
		return 0.0
	var room := float(WorldData.WORLDS.size() - 1) - rider_generation(id)
	var gain := minf(TRAIN_PER_BOSS if boss else TRAIN_PER_REPLAY, room)
	if gain <= 0.0:
		return 0.0
	drivers[key]["train"] = float(drivers[key].get("train", 0.0)) + gain
	save_game()
	return gain


## Hệ số sức mạnh dạng người (máu và sức đánh).
func human_power() -> float:
	if versus:
		return 1.0
	return 1.0 + HUMAN_POWER_PER_WORLD * mini(level_world(), WorldData.WORLDS.size() - 1)


## Đã qua hết mọi thế giới (vẫn chọn lại được các màn cũ ở màn chọn màn).
func is_demo_finished() -> bool:
	return frontier_world >= WorldData.WORLDS.size()


## Màn EX (sau màn Trùm) mở khi đã giải cứu thế giới đó: frontier_stage không bao giờ trỏ tới nó.
## Màn ở thế giới phụ: mở khi đã giải cứu cả thế giới cha lẫn thế giới của Rider đối thủ (WorldData "source_world").
func is_stage_unlocked(w: int, s: int) -> bool:
	if WorldData.is_side(w):
		var stage: Dictionary = WorldData.world_at(w)["stages"][s]
		return is_world_unlocked(w) and int(stage["source_world"]) < frontier_world
	return w < frontier_world or (w == frontier_world and s <= frontier_stage)


## Thế giới chính: đã tới (đang chơi hoặc đã giải cứu). Thế giới phụ: đã giải cứu thế giới cha.
func is_world_unlocked(w: int) -> bool:
	if WorldData.is_side(w):
		return int(WorldData.world_at(w)["parent_world"]) < frontier_world
	return w <= frontier_world


## Chọn màn để chơi (màn chọn màn). Bắt đầu từ đầu màn.
func select_stage(w: int, s: int) -> void:
	world_index = w
	stage_index = s


func current_world() -> Dictionary:
	return WorldData.world_at(world_index)


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
	# Item (vũ khí) thì không: chỉ có khi nhặt được từ quái, lỡ thì chơi lại màn.
	var stage_form: StringName = stage.get("form", &"")
	if stage_form != &"" and not is_item(rider, stage_form):
		unlock_form(rider, stage_form)
	if stage_form != &"" and has_form(rider, stage_form):
		result["form_name"] = stage["form_name"]

	if stage["type"] == WorldData.StageType.BOSS:
		var next_driver: StringName = world["next_driver"]
		obtain_driver(next_driver)
		result["obtained"] = next_driver
		if not cleared_stages.has(stage["id"]):
			worlds_cleared += 1

	in_stage = false
	var first_clear := not cleared_stages.has(stage["id"])
	if first_clear:
		cleared_stages.append(stage["id"])
	# Qua màn xa nhất đã mở thì mở màn kế (chơi lại màn cũ không mở gì thêm). Thế giới phụ không nằm trong chuỗi.
	if not WorldData.is_side(world_index) and world_index == frontier_world and stage_index == frontier_stage:
		frontier_stage += 1
		if frontier_stage >= int(world["main_count"]):
			frontier_stage = 0
			frontier_world += 1
	result["first_clear"] = first_clear
	result["fragments"] = 0
	if stage["type"] == WorldData.StageType.CHALLENGE and first_clear:
		add_fragments(CHALLENGE_FRAGMENTS)
		result["fragments"] = CHALLENGE_FRAGMENTS
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
	save_game()   # nhặt giữa màn rồi tắt game cũng không mất


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
	_unlock_level_forms(id)


## Final form mở khi lên Lv5 (RIDER "lv5": {"form": ...}, ví dụ Ryuki Survive).
func _unlock_level_forms(id: StringName) -> void:
	var form_id: StringName = (WorldData.rider_data(id).get("lv5", {}) as Dictionary).get("form", &"")
	if form_id != &"" and get_level(id) >= MAX_LEVEL:
		unlock_form(id, form_id)


## Số ô trang bị: 1 ô lúc đầu, +1 mỗi thế giới đã qua, tối đa 3.
## Mở form đặc biệt cho Rider. Trả về true nếu là lần đầu (để biến thân ngay với nộ đầy).
func unlock_form(id: StringName, form_id: StringName) -> bool:
	var key := String(id)
	if not drivers.has(key) or owns_form(id, form_id):
		return false
	var forms: Array = drivers[key].get("forms", [])
	forms.append(String(form_id))
	drivers[key]["forms"] = forms
	if not is_item(id, form_id):
		var base := _base_form_of(id)
		for stat in ["atk", "hp"]:      # kế thừa chỉ số đã cộng của form gốc
			var gap := bonus_value(id, base, stat) - bonus_value(id, form_id, stat)
			if gap > 0.0:
				add_bonus(id, form_id, stat, gap, false)
	# Form nhặt giữa màn dùng được ngay trong màn này
	if in_stage and not versus and id == main_rider and not is_item(id, form_id) and not carried_forms.has(form_id):
		carried_forms.append(form_id)
	form_unlocked.emit(id, form_id)
	save_game()   # nhặt giữa màn rồi tắt game cũng không mất
	return true


## Form / item đã nhặt được (đã lưu trong save), không tính giới hạn của trận đấu.
func owns_form(id: StringName, form_id: StringName) -> bool:
	var key := String(id)
	return drivers.has(key) and (drivers[key].get("forms", []) as Array).has(String(form_id))


## Form đã mở. Trong trận đấu chỉ tính form / item đã chọn mang vào trận.
func has_form(id: StringName, form_id: StringName) -> bool:
	if versus and (form_id != versus_form and not versus_items.has(form_id)):
		return false
	if versus and combat_unlock_all():
		return true
	return owns_form(id, form_id)


## COMBAT (đấu WiFi) ở bản web: mọi Rider, form và item mở sẵn, không cần chơi hành trình trước. Bản APK / máy tính
## vẫn chỉ dùng thứ đã mở khoá ở hành trình. Trong trận chỉ số vẫn công bằng (cấp 1, sức mạnh thế hệ 1, không cộng).
func combat_unlock_all() -> bool:
	return OS.has_feature("web")


## Rider chọn được ở COMBAT.
func combat_riders() -> Array[StringName]:
	if not combat_unlock_all():
		return selectable_riders()
	var out: Array[StringName] = []
	for world in WorldData.WORLDS:
		out.append(world["rider"])
	return out


## Form biến đổi (không phải item, không tính form gốc) chọn được ở COMBAT.
func combat_forms(id: StringName) -> Array[StringName]:
	if not combat_unlock_all():
		return owned_forms(id)
	var out: Array[StringName] = []
	var all := RiderCaps.all_forms(id)
	for i in range(1, all.size()):            # all[0] là form gốc (luôn có sẵn)
		if not is_item(id, all[i]):
			out.append(all[i])
	return out


## Item chọn được ở COMBAT.
func combat_items(id: StringName) -> Array[StringName]:
	if not combat_unlock_all():
		return owned_items(id)
	var out: Array[StringName] = []
	for f in WorldData.rider_data(id).get("order", []):
		if is_item(id, f):
			out.append(f)
	return out


## Item: form chỉ là vũ khí / lá bài / đòn ("item": true trong RIDER), quái rơi, mang vào màn tối đa MAX_ITEMS.
func is_item(id: StringName, form_id: StringName) -> bool:
	return WorldData.form_is_item(id, form_id)


## Các item Rider đã nhặt, theo thứ tự order của Rider.
func owned_items(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for f in WorldData.rider_data(id).get("order", []):
		if is_item(id, f) and owns_form(id, f):
			out.append(f)
	return out


## Các form biến đổi (không phải item) Rider đã nhặt, theo thứ tự nhặt.
func owned_forms(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for f in drivers.get(String(id), {}).get("forms", []):
		if not is_item(id, StringName(f)):
			out.append(StringName(f))
	return out


## Chọn Rider, form (tối đa 1, &"" = chỉ form gốc) và item mang vào trận đấu; lưu lại để lần sau chọn sẵn.
## Chỉ nhận thứ đã mở khoá.
func set_versus_loadout(id: StringName, form_id: StringName, items: Array[StringName]) -> void:
	versus_rider = id
	versus_form = form_id if combat_forms(id).has(form_id) else &""
	versus_items.clear()
	for f in items:
		if combat_items(id).has(f) and versus_items.size() < MAX_ITEMS:
			versus_items.append(f)
	save_game()


## Item mang vào màn (chọn trước khi vào màn).
func set_carried(items: Array[StringName]) -> void:
	carried_items = items.slice(0, MAX_ITEMS)


## Form biến đổi mang vào màn (chọn trước màn, &"" = chỉ form gốc).
func set_carried_form(form_id: StringName) -> void:
	carried_forms.clear()
	chosen_form = &""
	if form_id != &"" and owned_forms(main_rider).has(form_id):
		carried_forms.append(form_id)
		chosen_form = form_id


## Form dùng được trong màn: form biến đổi phải là form đã chọn mang vào (hoặc nhặt giữa màn), item phải đang mang theo.
func form_usable(id: StringName, form_id: StringName) -> bool:
	if not has_form(id, form_id):
		return false
	if versus:
		return true
	if is_item(id, form_id):
		return carried_items.has(form_id)
	# Decade / Zi-O: mọi thẻ Kamen Ride / Armor đã có đều dùng được, không giới hạn 1 form mang vào ("card_swap",
	# "pick_form" trong RIDER; đổi bằng bảng chọn Rider giữa màn, DataRider.picks_form).
	var data := WorldData.rider_data(id)
	return carried_forms.has(form_id) or data.get("card_swap", false) or data.get("pick_form", false)


## Các Rider chọn được làm Rider chính (mọi Driver đã kích hoạt), theo thứ tự thế giới.
func selectable_riders() -> Array[StringName]:
	var out: Array[StringName] = []
	for world in WorldData.WORLDS:
		var id: StringName = world["rider"]
		if is_active(id):
			out.append(id)
	return out


## Số form (kể cả form gốc và item) Rider đã có, hiện ở màn chọn Rider.
func form_count(id: StringName) -> int:
	return 1 + (drivers.get(String(id), {}).get("forms", []) as Array).size()


## Rider của thế giới đang chơi (form của màn chỉ rơi cho Rider này).
func world_rider() -> StringName:
	return current_world()["rider"] if world_index < WorldData.WORLDS.size() + WorldData.SIDE_WORLDS.size() else &""


## Chọn Rider chính trước khi vào màn.
func choose_main(id: StringName) -> void:
	if not is_active(id):
		return
	main_rider = id
	rebuild_team()
	save_game()


## Đội hình = [Rider chính]: mỗi màn chỉ một Rider, không đổi Rider giữa màn.
func rebuild_team() -> void:
	var team: Array[StringName] = []
	if main_rider != &"" and is_active(main_rider):
		team.append(main_rider)
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

## Hệ số của chỉ số `stat` cho form `form` của Rider `rider`: 1 + tỉ lệ đã cộng. Chế độ đấu: luôn 1 (chỉ số cộng
## thêm từ hạ quái / chơi lại màn không mang vào trận, người mới và người chơi lâu ngang nhau).
func bonus_mult(rider: StringName, form: StringName, stat: String) -> float:
	if versus:
		return 1.0
	return 1.0 + bonus_value(rider, form, stat)


## Tỉ lệ đã cộng (0.0123 = +1.23%).
func bonus_value(rider: StringName, form: StringName, stat: String) -> float:
	var forms: Dictionary = form_bonus.get(String(rider), {})
	return float((forms.get(String(form), {}) as Dictionary).get(stat, 0.0))


## Hệ số chỉ số của dạng người. Chế độ đấu: dạng người ai cũng như nhau.
func human_bonus(stat: String) -> float:
	return bonus_mult(HUMAN_KEY, HUMAN_KEY, stat)


## Cộng `amount` (mặc định BOOST_STEP) vào chỉ số `stat` của form. save = false: chỉ ghi khi có dịp lưu kế tiếp
## (hạ quái liên tục, không ghi file mỗi con).
func add_bonus(rider: StringName, form: StringName, stat: String, amount := BOOST_STEP, save := true) -> void:
	var forms: Dictionary = form_bonus.get(String(rider), {})
	var stats: Dictionary = forms.get(String(form), {})
	stats[stat] = float(stats.get(stat, 0.0)) + amount
	forms[String(form)] = stats
	form_bonus[String(rider)] = forms
	if save:
		save_game()


## Qua màn: cộng chỉ số cho form mang vào màn (`form`, của Rider `rider`; rider = &"" thì dạng người) và một phần cho
## các form khác của Rider đó. first = lần đầu qua màn này (chơi lại chỉ được REPLAY_SHARE). Trả về
## [{"stat", "amount"}] đã cộng cho form mang vào màn (sau khi chạm trần), để hiện ở bảng kết quả.
func stage_clear_bonus(rider: StringName, form: StringName, first: bool) -> Array:
	var share := 1.0 if first else REPLAY_SHARE
	if rider == &"":
		var got := _apply_stage_bonus(HUMAN_KEY, HUMAN_KEY, "speed", share)
		save_game()
		return got
	var gained: Array = []
	var base := _base_form_of(rider)
	for f in RiderCaps.all_forms(rider):
		var is_main: bool = f == form
		if not is_main and f != base and not owns_form(rider, f):
			continue
		if is_item(rider, f):
			continue
		var got := _apply_stage_bonus(rider, f, signature_stat(rider, f), share * (1.0 if is_main else OTHER_FORMS_SHARE))
		if is_main:
			gained = got
	save_game()
	return gained


func _apply_stage_bonus(rider: StringName, form: StringName, signature: String, share: float) -> Array:
	var got: Array = []
	for key in STAGE_BONUS:
		var stat: String = signature if key == "signature" else key
		var have := bonus_value(rider, form, stat)
		var amount := minf(float(STAGE_BONUS[key]) * share, float(BONUS_CAP[stat]) - have)
		if amount > 0.0001:
			add_bonus(rider, form, stat, amount, false)
			got.append({"stat": stat, "amount": amount})
	return got


func _base_form_of(rider: StringName) -> StringName:
	var f := create_form(rider)
	if f == null:
		return &""
	var id := f.base_form()
	f.free()
	return id


## Chỉ số đặc trưng của form (giáp / tốc độ / sức nhảy / trụ vững): chỉ số cao nhất so với SIGNATURE_NORMS.
func signature_stat(rider: StringName, form: StringName) -> String:
	var f := FigurePicker.preview_form(rider, form)
	if f == null:
		return "armor"
	var values := {"armor": f.armor, "speed": f.move_speed, "jump": f.jump_mult, "poise": f.poise}
	f.free()
	var best := "armor"
	var best_r := -1.0
	for k in values:
		var r := float(values[k]) / float(SIGNATURE_NORMS[k])
		if r > best_r:
			best_r = r
			best = k
	return best


## Cộng `amount` vào một chỉ số ngẫu nhiên; rider = HUMAN_KEY cho dạng người. Trả về khóa chỉ số đã cộng.
func add_random_bonus(rider: StringName, form: StringName, amount: float, save := true) -> String:
	var pool: Array = HUMAN_BOOST_STATS if rider == HUMAN_KEY else BOOST_STATS.keys()
	var stat: String = pool.pick_random()
	add_bonus(rider, form, stat, amount, save)
	return stat


## Đã qua hết các màn chính (không tính màn EX) của thế giới `w` chưa.
func world_fully_cleared(w: int) -> bool:
	if w < 0 or w >= WorldData.WORLDS.size():
		return false
	var stages: Array = WorldData.WORLDS[w]["stages"]
	for i in int(WorldData.WORLDS[w].get("main_count", stages.size())):
		if not cleared_stages.has(str(stages[i]["id"])):
			return false
	return true


func save_game() -> void:
	if not persist:
		return
	var data := {
		"version": SAVE_VERSION,
		"world_index": world_index,
		"stage_index": stage_index,
		"frontier_world": frontier_world,
		"frontier_stage": frontier_stage,
		"worlds_cleared": worlds_cleared,
		"drivers": drivers,
		"form_bonus": form_bonus,
		"bonus_unit": "fraction",
		"main_rider": str(main_rider),
		"fragments": memory_fragments,
		"cleared_stages": cleared_stages,
		"rei_memories": rei_memories,
		"seen_story": seen_story,
		"versus": {"rider": str(versus_rider), "form": str(versus_form), "items": versus_items.map(func(f): return str(f))},
	}
	var file := FileAccess.open(_save_path(), FileAccess.WRITE)
	if file == null:
		push_error("Không ghi được save: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))


func save_settings() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)   # giữ các mục khác (âm thanh, Sound.save_settings)
	cfg.set_value("player", "name", player_name)
	cfg.set_value("player", "name_set", name_set)
	cfg.set_value("play", "auto_attack", auto_attack)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if not persist or cfg.load(SETTINGS_PATH) != OK:
		return
	player_name = str(cfg.get_value("player", "name", DEFAULT_PLAYER_NAME))
	name_set = bool(cfg.get_value("player", "name_set", false))
	test_save = test_tools_enabled() and bool(cfg.get_value("debug", "test_save", false))
	auto_attack = bool(cfg.get_value("play", "auto_attack", false))


func load_game() -> void:
	if not persist or not FileAccess.file_exists(_save_path()):
		return
	var file := FileAccess.open(_save_path(), FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != SAVE_VERSION:
		push_warning("Save cũ hoặc hỏng, bắt đầu lại từ đầu.")
		return
	world_index = int(data.get("world_index", 0))
	stage_index = int(data.get("stage_index", 0))
	frontier_world = int(data.get("frontier_world", 0))
	frontier_stage = int(data.get("frontier_stage", 0))
	# Màn đang chọn không còn (thế giới phụ bớt màn / đổi thứ tự): về màn xa nhất đã mở.
	if world_index >= WorldData.WORLDS.size() + WorldData.SIDE_WORLDS.size() \
			or stage_index >= (WorldData.world_at(world_index)["stages"] as Array).size():
		world_index = mini(frontier_world, WorldData.WORLDS.size() - 1)
		stage_index = frontier_stage if frontier_world < WorldData.WORLDS.size() else 0
	worlds_cleared = int(data.get("worlds_cleared", 0))
	drivers = data.get("drivers", {})
	form_bonus = data.get("form_bonus", {})
	if str(data.get("bonus_unit", "")) != "fraction":
		# Save cũ lưu số lần +1%: đổi sang tỉ lệ
		for r in form_bonus:
			for f in form_bonus[r]:
				for k in form_bonus[r][f]:
					form_bonus[r][f][k] = float(form_bonus[r][f][k]) * BOOST_STEP
	main_rider = StringName(str(data.get("main_rider", "")))
	memory_fragments = int(data.get("fragments", 0))
	cleared_stages.clear()
	for s in data.get("cleared_stages", []):
		cleared_stages.append(str(s))
	rei_memories.clear()
	for s in data.get("rei_memories", []):
		rei_memories.append(str(s))
	# Save trước khi có file cài đặt: lấy tên từ save sang cài đặt.
	if not name_set and str(data.get("player_name", DEFAULT_PLAYER_NAME)) != DEFAULT_PLAYER_NAME:
		set_player_name(str(data["player_name"]))
	seen_story.clear()
	for s in data.get("seen_story", []):
		seen_story.append(str(s))
	var vs: Dictionary = data.get("versus", {})
	versus_rider = StringName(str(vs.get("rider", "")))
	versus_form = StringName(str(vs.get("form", "")))
	versus_items.clear()
	for f in vs.get("items", []):
		versus_items.append(StringName(str(f)))
	_drop_removed_forms()
	# Save cũ: Rider đã Lv5 trước khi có final form thì mở bù
	for key in drivers:
		_unlock_level_forms(StringName(key))
	rebuild_team()


## Save cũ còn form đã bỏ khỏi dữ liệu (Decade Slash / Blast nay là skill của form gốc): xoá khỏi danh sách form đã
## nhặt và bộ đồ chọn cho chế độ đấu. Chỉ xét Rider dựng từ dữ liệu ("order" trong RIDER).
func _drop_removed_forms() -> void:
	for key in drivers:
		var order: Array = WorldData.rider_data(StringName(key)).get("order", [])
		if order.is_empty():
			continue
		var kept: Array = []
		for f in drivers[key].get("forms", []):
			if order.has(StringName(str(f))):
				kept.append(f)
		drivers[key]["forms"] = kept
		if StringName(key) == versus_rider:
			if versus_form != &"" and not order.has(versus_form):
				versus_form = &""
			versus_items.assign(versus_items.filter(func(f: StringName) -> bool: return order.has(f)))


func _setup_input() -> void:
	for action in INPUT_KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in INPUT_KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
