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
## Cài đặt người chơi (tên nhân vật), tách khỏi save tiến trình: save cũ / hỏng bị làm lại thì tên vẫn còn.
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_VERSION := 4                ## 4: OOO có 9 màn (chỉ số màn thế giới 12 đổi)
const MAX_LEVEL := 5
const MAX_ITEMS := 2                    ## số item (vũ khí) mang vào một màn
## Đặt true để mỗi lần mở game đều chơi lại từ màn 1-1 (không đọc save). Mặc định đọc save: Driver, cấp, form và
## item đã nhặt, màn đã qua được giữ lại giữa các lần mở game (user://save.json; bản web lưu trong trình duyệt).
const DEBUG_FRESH_START := false
## Cấp quái: mỗi bậc màn (WorldData.tier_of) +1, mỗi thế giới +2/3 (làm tròn xuống): thế giới 1 Lv1–5, thế giới 4 Lv3–7, thế giới 11
## Lv7–11, thế giới 27 Lv18–22. Trùm +2. Tăng chậm để khớp với sức mạnh Rider theo thế hệ (POWER_PER_WORLD).
const ENEMY_LEVELS_PER_WORLD := 2.0 / 3.0
## Sức mạnh Rider theo thế hệ: Rider của thế giới thứ i (đếm từ 0) có máu và sát thương × (1 + 0.12 × i).
## Quái mỗi thế giới cũng mạnh thêm chừng đó, nên dùng Rider mới nhất thì độ khó các thế giới xấp xỉ nhau.
const POWER_PER_WORLD := 0.12
## Dạng người cũng mạnh dần theo hành trình: máu và sức đánh × (1 + 0.06 × số thế giới đã qua).
const HUMAN_POWER_PER_WORLD := 0.06
## Tên nhân vật chính do người chơi đặt ở màn nhập tên (scenes/ui/name_entry.tscn, sau màn hình chính).
const DEFAULT_PLAYER_NAME := "Sora"
const MAX_NAME_LENGTH := 12
const BOSS_LEVEL_BONUS := 2
const DIFFICULTY_EXTRA_LEVELS := 3.0   ## quái ở độ khó tối đa (thế giới cuối) mạnh hơn thêm chừng này cấp
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
	"help": [],       ## nút "?" trên màn hình (chỉ bản web): mở bảng hướng dẫn nút bấm (HelpOverlay)
}

var world_index := 0                    ## màn đang chơi (chọn ở màn chọn màn)
var stage_index := 0
var frontier_world := 0                 ## màn xa nhất đã mở: các màn tới đây chọn được, qua màn này thì mở màn kế
var frontier_stage := 0
var in_stage := false                   ## đang trong màn (gục thì tải lại vào thẳng màn đó, không về màn chọn màn)
var carried_items: Array[StringName] = []   ## item của Rider chính mang vào màn đang chơi (tối đa MAX_ITEMS)
## Form biến đổi dùng được trong màn đang chơi: form chọn trước màn (tối đa 1, như trận đấu) + form nhặt giữa màn.
var carried_forms: Array[StringName] = []
var chosen_form: StringName = &""       ## form chọn mang vào màn (&"" = form gốc), nhận thưởng CLEAR_BOOST
var worlds_cleared := 0
var drivers := {}                       ## "kuuga" -> {"active": bool, "level": int, "forms": ["dragon", ...]}
## Chỉ số cộng thêm của từng form: "kuuga" -> {"dragon" -> {"atk": 0.0123, ...}} = +1.23% sức đánh cho riêng form đó
## (RiderForm.bonus; dạng người lưu ở HUMAN_KEY / HUMAN_KEY, Player tự áp). Chỉ số: BOOST_STATS. Nhận được từ:
##   - hạ mỗi quái: +KILL_BOOST một chỉ số ngẫu nhiên của dạng đang dùng (form Rider hoặc dạng người)
##   - qua màn của thế giới đã qua hết các màn từ trước (chơi lại): +CLEAR_BOOST một chỉ số ngẫu nhiên cho form mang
##     vào màn (form gốc nếu không mang form nào; chưa có Rider thì dạng người). Lần đầu đi qua thế giới thì không,
##     thưởng vẫn là lên cấp / Driver / form như cũ.
var form_bonus := {}
const BOOST_STEP := 0.01        ## (save cũ) mỗi điểm cũ = +1%, đổi sang tỉ lệ khi đọc save
const KILL_BOOST := 0.0001      ## +0.01% mỗi quái hạ được
const CLEAR_BOOST := 0.001      ## +0.1% mỗi màn chơi lại
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


# --- Tiến trình ----------------------------------------------------------

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


func current_enemy_level() -> int:
	return 1 + int(level_world() * ENEMY_LEVELS_PER_WORLD) + int(current_stage().get("tier", stage_index)) \
		+ int(difficulty() * DIFFICULTY_EXTRA_LEVELS)


## Độ khó 0..1 của màn đang chơi (WorldData.difficulty_of): thế giới càng sau càng khó.
func difficulty() -> float:
	return float(current_stage().get("difficulty", 0.0))


## Thế giới tính cấp quái / sức mạnh dạng người: thế giới đang chơi, màn ở thế giới phụ thì theo "level_world" của màn.
func level_world() -> int:
	return int(current_stage().get("level_world", world_index))


## Hệ số sức mạnh thế hệ của Rider (RiderForm.power).
func rider_power(id: StringName) -> float:
	return 1.0 + POWER_PER_WORLD * maxi(WorldData.world_index_of(id), 0)


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
	return owns_form(id, form_id)


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
	versus_form = form_id if owned_forms(id).has(form_id) else &""
	versus_items.clear()
	for f in items:
		if owned_items(id).has(f) and versus_items.size() < MAX_ITEMS:
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
	return carried_items.has(form_id) if is_item(id, form_id) else carried_forms.has(form_id)


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

## Hệ số của chỉ số `stat` cho form `form` của Rider `rider`: 1 + tỉ lệ đã cộng.
func bonus_mult(rider: StringName, form: StringName, stat: String) -> float:
	return 1.0 + bonus_value(rider, form, stat)


## Tỉ lệ đã cộng (0.0123 = +1.23%).
func bonus_value(rider: StringName, form: StringName, stat: String) -> float:
	var forms: Dictionary = form_bonus.get(String(rider), {})
	return float((forms.get(String(form), {}) as Dictionary).get(stat, 0.0))


## Hệ số chỉ số của dạng người. Chế độ đấu: dạng người ai cũng như nhau.
func human_bonus(stat: String) -> float:
	return 1.0 if versus else bonus_mult(HUMAN_KEY, HUMAN_KEY, stat)


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
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
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
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if not persist or cfg.load(SETTINGS_PATH) != OK:
		return
	player_name = str(cfg.get_value("player", "name", DEFAULT_PLAYER_NAME))
	name_set = bool(cfg.get_value("player", "name_set", false))


func load_game() -> void:
	if not persist or not FileAccess.file_exists(SAVE_PATH):
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
	# Save cũ: Rider đã Lv5 trước khi có final form thì mở bù
	for key in drivers:
		_unlock_level_forms(StringName(key))
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
