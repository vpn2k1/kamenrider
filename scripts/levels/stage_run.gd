extends Node2D
## Màn chơi kiểu Contra: lộ trình gồm nhiều đoạn ngang (sang phải / sang trái) và giếng dọc (leo lên / tụt xuống).
##
##   - Bố cục sinh từ StageBuilder theo màn hiện tại trong GameState (WorldData "route").
##   - Màn chọn màn (StageSelect, chọn thế giới rồi chọn màn): sau mỗi màn và khi bấm Menu (Esc / P / nút ≡)
##     trong màn. Lần đầu chơi (chưa qua màn nào) vào thẳng 1-1, không qua màn chọn.
##     Màn mở dần (qua màn xa nhất thì mở màn kế), màn đã mở chơi lại được để luyện cấp và nhặt item.
##   - Trước khi vào màn: chọn MỘT Rider (RiderSelect, khi có từ 2 Rider), MỘT form biến đổi (FormSelect, khi Rider
##     đã nhặt form; form gốc = không mang) rồi item mang theo (ItemSelect, tối đa GameState.MAX_ITEMS, khi Rider đã
##     nhặt item). Trong màn không đổi sang Rider khác; form nhặt giữa màn dùng được ngay.
##     Gục thì tải lại thẳng vào màn từ checkpoint (GameState.in_stage), không hỏi lại.
##   - Camera chạy trên đường gấp khúc của bố cục (vị trí là quãng đường cam_s) và đi theo người chơi CẢ HAI
##     CHIỀU: chạy ngược lại, leo ngược giếng tụt, rơi xuống giếng leo đều được. Camera nhìn trước CAMERA_LEAD
##     theo hướng nhân vật đang quay mặt (đoạn ngang) hoặc đang di chuyển (giếng), trượt theo cho mượt.
##     Tường vô hình chỉ còn ở hai đầu: phía sau điểm xuất phát, và hai bên đấu trường lúc đánh trùm.
##     Cuối màn và vách giếng là vật cứng thật (StageBuilder).
##   - Camera tới s của điểm spawn thì thả quái (mép màn hình phía trước / phía sau, hoặc trên bệ giếng),
##     mỗi điểm một lần; quay lại không thả lại. Lính bắn đứng gác tại chỗ.
##     Quái đã thả ở lại chỗ của nó (quay lại vẫn gặp), trừ quái chạy ngang ra khỏi khung nhìn thì biến mất.
##   - Rơi vực (rơi xuống dưới mép khung nhìn mà camera không theo xuống được): mất 25% máu rồi hồi sinh
##     ở chỗ đứng an toàn trong khung nhìn. Gục: chơi lại từ checkpoint.
##   - Vật phẩm rơi từ quái (tối đa 1 món trên màn, tồn tại DROP_LIFETIME giây):
##       Món chính của màn: Driver của thế giới (màn Thức tỉnh) hoặc form của màn (WorldData "form").
##           Tỉ lệ KEY_DROP_BASE, mỗi con hạ mà chưa rơi +KEY_DROP_STEP (bảo hiểm xui).
##           Nhặt lần đầu: mở khóa, nộ đầy, biến thân ngay vào form đó.
##       Hết món chính thì thỉnh thoảng rơi "nạp nộ" của một form đặc biệt đã có: +CHARGE_RAGE nộ.
##   - Phải DIỆT HẾT QUÁI mới qua màn: tới vạch đích mà còn quái thì phải quay lại hạ nốt (quái chạy ngang ra
##     khỏi khung nhìn sẽ quay đầu chạy lại, không biến mất). HUD hiện số quái còn lại.
##   - Món chính là item (vũ khí, "item": true) thì chỉ rơi từ quái, không bắt buộc: lỡ thì chơi lại màn để nhặt.
##     Nhặt Driver / form của Rider khác Rider đang dùng: chỉ mở khóa, dùng ở màn sau.
##   - Tới vạch đích (cuối đoạn ngang cuối cùng), khi đã diệt hết quái:
##       Luyện tập  → qua màn (chưa nhặt được form của màn thì form rơi ở vạch đích, nhặt mới qua)
##       Thức tỉnh  → đánh nhóm quái canh giữ → chưa có Driver thì Driver rơi ra → nhặt
##       Trùm       → khóa camera ở đấu trường, đánh trùm → Driver thế giới kế rơi ra → nhặt
##       EX         → đánh nhóm canh giữ cuối → qua màn (thưởng Mảnh Ký Ức lần đầu)
##   - Màn EX (WorldData.StageType.CHALLENGE): quái đặc biệt (Enemy.SPECIALS) chỉ nhận đòn của form khắc chế.
##     Đầu màn báo loại quái và form phù hợp đang có (RiderCaps); đánh sai cách thì banner giải thích (IMMUNE_NAG).
##     Nạp nộ rơi nhiều hơn (CHALLENGE_CHARGE_CHANCE) vì form khắc chế tốn nộ.
##   - Qua màn (_finish_stage): khóa điều khiển, dọn quái / đạn còn lại, GIẢI TRỪ BIẾN THÂN về dạng người,
##     thoại "clear" → (trùm) bản đồ Chuỗi Trái Đất → bảng kết quả → về màn chọn màn (con trỏ ở màn kế).
##     Dựng màn mới thì ĐỔI NỀN theo màn (WorldData "bg"). Mỗi màn (kể cả chơi lại từ checkpoint) bắt đầu ở dạng
##     người, máu người đầy, nộ đầy: đã có Driver thì bấm Biến thân lúc nào cũng được.
##   - Màn hình máy dài / vuông hơn 16:9 (Screen): camera thấy rộng / cao hơn (view_rect theo khung nhìn thật, quái
##     thả ngoài mép màn hình thật), chữ trạng thái bám góc phải, banner ở giữa màn hình.
##   - Hội thoại (StoryData, DialogueBox): đầu màn ("start"), tới vạch đích màn Thức tỉnh / Trùm ("goal"),
##     vừa nhặt món chính ("key"), qua màn ("clear"); sau trùm thêm bản đồ Chuỗi Trái Đất.
##     Trong lúc thoại cả màn dừng lại (get_tree().paused), phase = TALK.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const TOP_TEX := preload("res://art/tiles/street_top.png")
const FILL_TEX := preload("res://art/tiles/street_fill.png")
const CRATE_TEX := preload("res://art/tiles/crate.png")
const WALL_TEX := preload("res://art/tiles/wall.png")
const HALF_W := StageBuilder.HALF_W
const HALF_H := StageBuilder.HALF_H
const CAMERA_LEAD := 40.0       ## camera nhìn trước chừng này theo hướng người chơi đang đi
const CAMERA_FOLLOW := 8.0       ## độ bám của camera (1/giây): càng lớn càng sát người chơi
const LEAD_TURN := 2.5           ## tốc độ đổi phía nhìn trước khi người chơi quay đầu (1/giây)
const DESPAWN_MARGIN := 160.0    ## quái chạy ngang ra khỏi khung nhìn quá chừng này thì biến mất
const FALL_MARGIN := 40.0        ## xuống dưới mép khung nhìn quá chừng này = rơi vực
const WALL_LAYER := 32           ## lớp va chạm 6 "camera_wall": chỉ chặn người chơi
const FALL_DAMAGE := 0.25
const RESULT_TIME := 3.5
const KEY_DROP_BASE := 0.05
const KEY_DROP_STEP := 0.05
const CHARGE_DROP_CHANCE := 0.08
const CHARGE_RAGE := 40.0
const DROP_LIFETIME := 10.0
const CHALLENGE_CHARGE_CHANCE := 0.3   ## màn EX: tỉ lệ rơi nạp nộ mỗi quái
const IMMUNE_NAG := 4.0                ## giây giữa hai lần banner "quái này chỉ trúng..."
## Chỉ số cấp 1 của quái đặc biệt (Enemy.SPECIALS), hình lấy theo loại quái thường "art" của thế giới.
const SPECIAL_ENEMIES := {
	"flying": {"art": "fast", "name": "%s có cánh", "hp": 24.0, "speed": 70.0, "damage": 7.0, "windup": 0.35,
		"interval": 2.4},
	"giant": {"art": "armored", "name": "%s khổng lồ", "hp": 150.0, "speed": 34.0, "damage": 18.0, "windup": 0.6,
		"poise": 9999.0, "knockback": Vector2(220, -100)},
	"phantom": {"art": "fast", "name": "%s siêu tốc", "hp": 22.0, "speed": 120.0, "damage": 8.0, "windup": 0.25},
	"spectral": {"art": "basic", "name": "Bóng ma %s", "hp": 34.0, "speed": 52.0, "damage": 9.0, "windup": 0.45},
}
const KEY_STORY_DELAY := 1.0     ## giây chờ cảnh biến thân xong rồi mới hiện thoại "key"
const FADE_TIME := 0.45          ## màn hình tối dần / sáng dần khi chuyển màn
const DEFAULT_BG := "res://art/backgrounds/shibuya_night.png"
const BG_TINT := Color(0.78, 0.78, 0.86)   ## nền xa tối bớt để cảnh gần nổi lên (màn có thể đặt "bg_tint" riêng)
const HUMAN_COLOR := Color(0.9, 0.9, 0.9)   ## khối tạm dạng người
const TIME_TINT := Color(0.35, 0.55, 1.0, 0.16)   ## thời gian chậm lại: thế giới ngả xanh

enum Phase { SELECT, RUN, GOAL_FIGHT, PICKUP, RESULT, DONE, TALK, TRANSITION, MAP, ITEMS, FORMS }

@onready var player: Player = $Player
@onready var placeholder: Polygon2D = $Player/Placeholder
@onready var camera: Camera2D = $Camera2D
@onready var level_root: Node2D = $Level
@onready var enemies: Node2D = $Enemies
@onready var status_label: Label = $HUD/Status
@onready var banner: Label = $HUD/Banner
@onready var bars: Control = $HUD/Bars
@onready var touch: Node2D = $HUD/Touch
@onready var sky_color: ColorRect = $Sky/Color
@onready var far_city: Parallax2D = $FarCity
@onready var far_a: Sprite2D = $FarCity/A
@onready var far_b: Sprite2D = $FarCity/B

var layout := {}
var phase := Phase.RUN
var cam_s := 0.0                   ## vị trí camera trên đường gấp khúc của bố cục (đi cả hai chiều)
var _lead := 1.0                   ## -1..1: camera nhìn về phía trước (+) hay phía sau (-) của lộ trình
var _last_ps := 0.0                ## quãng đường của người chơi ở khung hình trước
var _start_wall := Rect2()         ## tường vô hình sau điểm xuất phát (rỗng nếu màn bắt đầu bằng giếng)
var _spawn_index := 0
var _shooter_index := 0
var _arena_locked := false
var _last_safe := Vector2.ZERO
var _phase_timer := 0.0
var _banner_timer := 0.0
var _status := ""
var _combo := 0
var _restarting := false
var _shake := 0.0
var _drop: DriverPickup = null     ## vật phẩm đang nằm trên màn (tối đa một món)
var _key_misses := 0               ## số quái đã hạ mà món chính chưa rơi
var _walls: Array[CollisionShape2D] = []   ## 3 tường vô hình: đầu màn + hai bên đấu trường trùm
var _select: RiderSelect
var _stage_select: StageSelect
var _form_select: FormSelect
var _item_select: ItemSelect
var _boost_select: BoostSelect
var _boost_given := false        ## màn chơi lại: đã rơi / nhặt vật phẩm Tăng sức mạnh của lượt này chưa
var _goal_nag := 0.0               ## hẹn giờ nhắc "còn quái" ở vạch đích
var _dialogue: DialogueBox
var _fade: ColorRect               ## màn đen phủ khi chuyển màn
var _time_tint: ColorRect          ## phủ xanh nhạt khi thời gian chậm lại (Clock Up, Axel)
var _flash: ColorRect              ## chớp trắng khi tung Final Attack
var _backdrop: FinisherBackdrop    ## phông tuyệt chiêu: ảnh lớn sau trận đánh khi tung Final
var _cutin: SkillCutIn             ## dải cut-in mặt Rider + tên chiêu (Final), dải nhỏ khi đổi form
var _far_ground: ColorRect         ## tô phần dưới ảnh nền xa (lộ ra khi xuống tầng thấp trong giếng)
var _pending_key := ""             ## mã màn có thoại "key" đang chờ cảnh biến thân xong ("" = không có)
var _immune_nag := 0.0             ## hẹn giờ banner giải thích quái đặc biệt


func _ready() -> void:
	# Hội thoại dừng cả màn bằng get_tree().paused; màn luôn dừng theo dù nút cha (bot test) chạy ALWAYS.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = false
	player.form_changed.connect(_on_form_changed)
	player.form_status_changed.connect(func(text: String) -> void: _status = text)
	player.combo_changed.connect(func(count: int) -> void: _combo = count)
	player.died.connect(_on_player_died)
	player.notice.connect(func(text: String) -> void: _show_banner(text, 1.2))
	bars.player = player
	touch.player = player
	CombatDirector.shake_requested.connect(func(s: float) -> void: _shake = maxf(_shake, s))
	CombatDirector.enemy_time_scale_changed.connect(_on_time_scale_changed)
	CombatDirector.final_attack_started.connect(_on_final_attack)
	CombatDirector.final_attack_landed.connect(func() -> void: _backdrop.impact())
	CombatDirector.skill_used.connect(func(label: String, color: Color) -> void: _cutin.skill(label, color))
	_backdrop = FinisherBackdrop.new()
	add_child(_backdrop)
	move_child(_backdrop, far_city.get_index() + 1)    # sau nền xa, trước địa hình / quái / người chơi
	for i in 3:
		var body := StaticBody2D.new()
		body.collision_layer = WALL_LAYER
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		shape.disabled = true
		body.add_child(shape)
		add_child(body)
		_walls.append(shape)
	_select = RiderSelect.new()
	_select.visible = false
	_select.chosen.connect(_on_rider_chosen)
	$HUD.add_child(_select)
	_stage_select = StageSelect.new()
	_stage_select.visible = false
	_stage_select.chosen.connect(_on_stage_chosen)
	_stage_select.menu_requested.connect(_to_main_menu)
	$HUD.add_child(_stage_select)
	_form_select = FormSelect.new()
	_form_select.visible = false
	_form_select.hint = "Form biến đổi đổi bằng Kỹ năng (L), tốn nộ · form nhặt giữa màn vẫn dùng được ngay"
	_form_select.done.connect(_on_form_chosen)
	$HUD.add_child(_form_select)
	_item_select = ItemSelect.new()
	_item_select.visible = false
	_item_select.done.connect(_on_items_done)
	$HUD.add_child(_item_select)
	_boost_select = BoostSelect.new()
	$HUD.add_child(_boost_select)
	_time_tint = _overlay(TIME_TINT)
	_flash = _overlay(Color(1, 1, 1, 0))
	_cutin = SkillCutIn.new()
	$HUD.add_child(_cutin)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.size = get_viewport_rect().size
	$HUD.add_child(_fade)
	_dialogue = DialogueBox.new()
	$HUD.add_child(_dialogue)
	# Bảng hướng dẫn nút bấm (bản web, nút "?"): trên cùng, dừng cả màn khi đang mở
	var help := HelpOverlay.new()
	help.pause_tree = true
	$HUD.add_child(help)
	_layout_hud()
	get_viewport().size_changed.connect(_layout_hud)
	_on_form_changed(&"")
	if GameState.in_stage:
		_start_stage()     # gục: tải lại thẳng vào màn, chơi tiếp từ checkpoint
	else:
		_open_map(not GameState.cleared_stages.is_empty())   # lần đầu chơi: vào thẳng 1-1


# --- Chọn màn, Rider, item -------------------------------------------------

## Về màn chọn màn: dọn màn đang chơi, con trỏ ở màn xa nhất đã mở (hoặc màn vừa chơi nếu đã qua hết).
## show_select = false: không hiện màn chọn, vào thẳng màn xa nhất đã mở (lần đầu chơi là 1-1).
func _open_map(show_select := true) -> void:
	phase = Phase.MAP
	GameState.in_stage = false
	CombatDirector.set_enemy_time_scale(1.0)
	_clear_field()
	player.reset_for_stage()
	player.input_locked = true
	player.set_physics_process(false)
	touch.visible = false
	banner.text = ""
	var w := GameState.frontier_world
	var st := GameState.frontier_stage
	if GameState.is_demo_finished():
		w = GameState.world_index
		st = GameState.stage_index
	if not show_select:
		_on_stage_chosen(w, st)
		return
	_stage_select.open(w, st)
	Sound.music("map")
	_fade_to(0.0)


## Màn chọn thế giới bấm ◀ MENU / Esc: lưu rồi về màn hình chính (CHƠI / COMBAT).
func _to_main_menu() -> void:
	GameState.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_stage_chosen(world: int, stage: int) -> void:
	GameState.select_stage(world, stage)
	var options := GameState.selectable_riders()
	if options.size() >= 2:
		phase = Phase.SELECT
		var current := GameState.main_rider if options.has(GameState.main_rider) else options[options.size() - 1]
		var colors := {}
		for id in options:
			colors[id] = WorldData.rider_color(id)
		var st := GameState.current_stage()
		_select.open(options, "CHỌN RIDER", "Màn %s · %s · mỗi màn một Rider" % [st["id"], st["name"]], current, colors)
		return
	if options.size() == 1:
		GameState.choose_main(options[0])
	_open_forms()


func _on_rider_chosen(id: StringName) -> void:
	GameState.choose_main(id)
	_open_forms()


## Chọn form biến đổi mang vào màn (tối đa 1, như trận đấu). Rider chưa nhặt form nào thì bỏ qua.
func _open_forms() -> void:
	var rider := GameState.main_rider
	var forms := GameState.owned_forms(rider) if rider != &"" else ([] as Array[StringName])
	if forms.is_empty():
		_on_form_chosen([] as Array[StringName])
		return
	phase = Phase.FORMS
	_form_select.open(rider, forms, GameState.carried_forms.slice(0, 1))


func _on_form_chosen(forms: Array[StringName]) -> void:
	GameState.set_carried_form(forms[0] if not forms.is_empty() else &"")
	_open_items()


## Chọn item mang vào màn (bỏ qua nếu Rider chưa nhặt item nào).
func _open_items() -> void:
	var rider := GameState.main_rider
	var items := GameState.owned_items(rider) if rider != &"" else ([] as Array[StringName])
	if items.is_empty():
		_on_items_done([] as Array[StringName])
		return
	phase = Phase.ITEMS
	_item_select.open(rider, items, GameState.carried_items)


func _on_items_done(items: Array[StringName]) -> void:
	GameState.set_carried(items)
	GameState.in_stage = true
	GameState.rebuild_team()
	phase = Phase.TRANSITION
	await _fade_to(1.0)
	player.set_physics_process(true)
	_start_stage()


## Menu trong màn hoặc hết bảng kết quả: tối dần rồi về màn chọn màn.
func _back_to_map() -> void:
	phase = Phase.TRANSITION
	player.input_locked = true
	touch.visible = false
	CombatDirector.set_enemy_time_scale(1.0)
	await _fade_to(1.0)
	for c in level_root.get_children():
		c.queue_free()
	_open_map()


# --- Dựng màn -------------------------------------------------------------

## Dựng màn hiện tại (gọi lúc màn hình đang đen), rồi sáng dần và vào màn. Nhân vật luôn bắt đầu ở dạng người.
func _start_stage() -> void:
	phase = Phase.TRANSITION
	CombatDirector.set_enemy_time_scale(1.0)
	for c in level_root.get_children():
		c.queue_free()
	for c in enemies.get_children():
		c.queue_free()
	_drop = null
	_pending_key = ""
	_boost_given = false
	var stage := GameState.current_stage()
	Sound.music(_stage_music(stage))
	layout = StageBuilder.build(stage, int(stage.get("tier", GameState.stage_index)))
	for o in layout["overlaps"]:
		push_warning("Màn %s: bố cục chồng lấn — %s" % [stage["id"], o])
	_build_level()
	_apply_background(stage)

	var start: Vector2 = layout["start"]
	var cps: Array = layout["checkpoints"]
	if GameState.checkpoint >= 0 and GameState.checkpoint < cps.size():
		start = cps[GameState.checkpoint]["pos"]
	player.reset_for_stage()
	player.input_locked = true     # mở khi bắt đầu chạy (_begin_run)
	player.respawn_at(start)
	player.facing = layout["start_dir"]
	player.sprite.flip_h = player.facing < 0
	_last_safe = start
	cam_s = StageBuilder.project(layout, start)
	_last_ps = cam_s
	_lead = 1.0
	_arena_locked = false
	# Tường sau điểm xuất phát: đúng mép sau khung nhìn khi camera ở đầu lộ trình (s = 0).
	# Màn bắt đầu bằng giếng thì vách giếng đã chặn sẵn.
	_start_wall = Rect2()
	var d0 := StageBuilder.path_dir(layout, 0.0)
	if absf(d0.x) > 0.5:
		var edge := StageBuilder.path_point(layout, 0.0) - d0 * HALF_W
		_start_wall = Rect2(edge.x - (20.0 if d0.x > 0.0 else 0.0), edge.y - 300.0, 20.0, 500.0)
	_update_camera()
	# Khi hồi sinh ở checkpoint thì bỏ qua các điểm spawn / lính bắn đã đi qua.
	_spawn_index = 0
	while _spawn_index < layout["spawns"].size() and layout["spawns"][_spawn_index]["s"] <= cam_s:
		_spawn_index += 1
	_shooter_index = 0
	while _shooter_index < layout["shooters"].size() and layout["shooters"][_shooter_index]["s"] < cam_s - HALF_W:
		_shooter_index += 1
	_key_misses = 0
	touch.visible = false
	await _fade_to(0.0)
	phase = Phase.TALK
	await _story(stage["id"], "start")
	GameState.rebuild_team()
	player.use_main_rider()
	_begin_run()


func _begin_run() -> void:
	var stage := GameState.current_stage()
	phase = Phase.RUN
	player.input_locked = false
	touch.visible = true
	# Gọn: chỉ tên màn (màn EX thêm một dòng cách hạ quái đặc biệt). Món cần tìm đã có ở HUD ("Tìm: ...").
	var text := "MÀN %s · %s" % [stage["id"], stage["name"]]
	if stage.has("special"):
		text += "\n" + _special_brief(stage["special"])
	_show_banner(text, 3.5 if stage.has("special") else 2.0)


## Màn EX: loại quái đặc biệt, cách hạ, và form khắc chế đang mang (hoặc cảnh báo chưa mang).
func _special_brief(special: StringName) -> String:
	var how := str(Enemy.SPECIALS[special]["how"])
	var rider := GameState.main_rider
	var mine: Array[String] = []
	var probe := GameState.create_form(rider) if rider != &"" else null
	if probe:
		for f in RiderCaps.all_forms(rider):
			# Dùng được trong màn này (form gốc, form / item mang theo) và khắc chế được
			if probe.has_form(f) and RiderCaps.counters(rider, f).has(special):
				mine.append(FigurePicker.form_label(rider, f))
		probe.free()
	if mine.is_empty():
		return how + "\n⚠ Chưa mang form khắc chế! (Menu → chọn lại form / item)"
	return how + "\nForm khắc chế: %s" % ", ".join(mine)


## Quái đặc biệt bị đánh sai cách: banner giải thích, cách nhau IMMUNE_NAG giây.
func _on_enemy_immune(special: StringName) -> void:
	if _immune_nag > 0.0 or phase not in [Phase.RUN, Phase.GOAL_FIGHT]:
		return
	_immune_nag = IMMUNE_NAG
	_show_banner(str(Enemy.SPECIALS[special]["how"]), 2.2)


## Nền xa và màu trời theo màn (WorldData "bg", "bg_tint"). Ảnh rộng 800 px (tools/gen_backgrounds.py) lặp nguyên
## ảnh, đặt thấp hơn 30 px để thấy trọn phần trên (trăng, đỉnh tháp); ảnh hẹp hơn (shibuya_night 400 px) ghép với
## bản lật để đủ 800 px. Màu trời = điểm trên cùng của ảnh × tint; dưới ảnh tô bằng màu hàng dưới cùng.
func _apply_background(stage: Dictionary) -> void:
	var path := str(stage.get("bg", DEFAULT_BG))
	if not ResourceLoader.exists(path):
		push_warning("Thiếu ảnh nền %s (chạy tools/gen_backgrounds.py rồi mở Godot để nhập ảnh)" % path)
		path = DEFAULT_BG
	var tex: Texture2D = load(path)
	var tint: Color = stage.get("bg_tint", BG_TINT)
	var wide := tex.get_width() >= 800
	var top := -30.0 if wide else -60.0
	far_a.texture = tex
	far_b.texture = tex
	far_b.visible = not wide
	far_a.position = Vector2(-400.0, top)
	far_b.position = Vector2(0.0, top)
	far_city.repeat_size = Vector2(tex.get_width() if wide else tex.get_width() * 2, 0.0)
	far_city.modulate = tint
	var img := tex.get_image()
	sky_color.color = img.get_pixel(0, 0) * tint
	if _far_ground == null:
		_far_ground = ColorRect.new()
		_far_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		far_city.add_child(_far_ground)
	_far_ground.position = Vector2(-400.0, top + tex.get_height())
	_far_ground.size = Vector2(800.0, 800.0)
	_far_ground.color = img.get_pixel(0, img.get_height() - 1)


func _build_level() -> void:
	for so in layout["solids"]:
		var r: Rect2 = so["rect"]
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		shape.position = r.get_center()
		body.add_child(shape)
		level_root.add_child(body)
		match so["kind"]:
			"ground":
				_add_tiles(TOP_TEX, r.position.x, r.position.y - 16.0, r.size.x, 32.0)
				_add_tiles(FILL_TEX, r.position.x, r.position.y + 16.0, r.size.x, r.size.y - 16.0)
			"block":
				_add_tiles(CRATE_TEX, r.position.x, r.position.y, r.size.x, r.size.y)
			_:
				_add_tiles(WALL_TEX, r.position.x, r.position.y, r.size.x, r.size.y)

	for p in layout["platforms"]:
		var body := StaticBody2D.new()
		body.collision_layer = 0
		body.set_collision_layer_value(Player.PLATFORM_LAYER, true)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(p.z, 8.0)
		shape.shape = rect
		shape.one_way_collision = true
		shape.position = Vector2(p.x + p.z / 2.0, p.y + 4.0)
		body.add_child(shape)
		level_root.add_child(body)
		_add_tiles(TOP_TEX, p.x, p.y - 16.0, p.z, 32.0)


func _add_tiles(tex: Texture2D, x: float, y: float, w: float, h: float) -> void:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_TILE
	tr.position = Vector2(x, y)
	tr.size = Vector2(w, h)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_root.add_child(tr)


# --- Vòng lặp -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if phase in [Phase.DONE, Phase.SELECT, Phase.FORMS, Phase.ITEMS, Phase.TALK, Phase.TRANSITION] or layout.is_empty():
		return
	_update_camera(delta)
	_spawn_ahead()
	_despawn_far()
	_keep_in_arena()
	_check_player_position()


func _process(delta: float) -> void:
	_update_placeholder()
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	_shake = move_toward(_shake, 0.0, 30.0 * delta)
	status_label.text = _hud_text()
	bars.form_text = _form_text()
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			banner.text = ""
	_goal_nag = maxf(_goal_nag - delta, 0.0)
	_immune_nag = maxf(_immune_nag - delta, 0.0)
	if _restarting:
		return
	if phase in [Phase.RUN, Phase.GOAL_FIGHT, Phase.PICKUP] and Input.is_action_just_pressed("menu"):
		_back_to_map()
		return
	match phase:
		Phase.GOAL_FIGHT:
			if _enemies_left() == 0:
				_goal_cleared()
		Phase.RESULT:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_back_to_map()


## Khung nhìn hiện tại của camera (tọa độ thế giới), theo kích thước màn hình thật (máy 20:9 rộng hơn 480).
func view_rect() -> Rect2:
	var c := StageBuilder.path_point(layout, cam_s)
	var half := Screen.view(self) / 2.0
	return Rect2(c - half, half * 2.0)


## Chữ trạng thái bám góc phải, banner ở giữa màn hình (vị trí trong scene tính theo khung 480×270).
func _layout_hud() -> void:
	var e := Screen.extra(self)
	status_label.position.x = 300.0 + e.x
	banner.position = Vector2(60.0, 70.0) + e / 2.0


## Số quái còn sống trên cả màn (đã thả ra). Phải về 0 mới qua màn.
func _enemies_left() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and en.state != Enemy.State.DEAD:
			n += 1
	return n


## Quãng đường s ứng với vị trí người chơi.
func player_s() -> float:
	return StageBuilder.project(layout, player.global_position, cam_s)


## Camera theo người chơi hai chiều, chỉ dừng ở hai đầu lộ trình (s = 0 và s = length) và ở đấu trường trùm.
## delta <= 0: đặt camera ngay (đầu màn, hồi sinh); còn lại camera trượt theo cho mượt.
func _update_camera(delta := 0.0) -> void:
	if _arena_locked:
		cam_s = layout["length"]
	elif phase != Phase.RESULT:
		var ps := player_s()
		var want := _lead
		var dir := StageBuilder.path_dir(layout, ps)
		if absf(dir.x) > 0.5:
			want = signf(dir.x * float(player.facing))   # đoạn ngang: nhìn về phía nhân vật quay mặt
		elif absf(ps - _last_ps) > 0.5:
			want = signf(ps - _last_ps)                   # giếng: nhìn theo hướng đang leo lên / rơi xuống
		_last_ps = ps
		if delta <= 0.0:
			_lead = want
			cam_s = clampf(ps + CAMERA_LEAD * _lead, 0.0, layout["length"])
		else:
			_lead = move_toward(_lead, want, LEAD_TURN * delta)
			var target := clampf(ps + CAMERA_LEAD * _lead, 0.0, layout["length"])
			cam_s = lerpf(cam_s, target, 1.0 - exp(-CAMERA_FOLLOW * delta))
	camera.global_position = StageBuilder.path_point(layout, cam_s)
	_update_walls()


## Tường vô hình (chỉ chặn người chơi) ở hai đầu màn: sau điểm xuất phát, và hai bên đấu trường lúc đánh trùm.
func _update_walls() -> void:
	var rects: Array = [_start_wall]
	if _arena_locked:
		var c := camera.global_position
		rects.append(Rect2(c.x - HALF_W - 20.0, c.y - 400.0, 20.0, 800.0))
		rects.append(Rect2(c.x + HALF_W, c.y - 400.0, 20.0, 800.0))
	_set_walls(rects)


func _set_walls(rects: Array) -> void:
	for i in _walls.size():
		var shape := _walls[i]
		if i < rects.size() and (rects[i] as Rect2).has_area():
			var r: Rect2 = rects[i]
			(shape.shape as RectangleShape2D).size = r.size
			(shape.get_parent() as Node2D).global_position = r.get_center()
			shape.disabled = false
		else:
			shape.disabled = true


func _spawn_ahead() -> void:
	if phase != Phase.RUN:
		return
	var view := view_rect()
	var spawns: Array = layout["spawns"]
	while _spawn_index < spawns.size() and spawns[_spawn_index]["s"] <= cam_s:
		var sp: Dictionary = spawns[_spawn_index]
		_spawn_index += 1
		var dir: int = sp["dir"]
		for i in int(sp["count"]):
			var pos: Vector2 = sp["pos"]
			var run_dir := -dir
			match sp["side"]:
				"ahead":
					var x := view.get_center().x + dir * (view.size.x / 2.0 + 20.0 + i * 30.0)
					var limit: float = sp["limit"]
					x = minf(x, limit - i * 16.0) if dir > 0 else maxf(x, limit + i * 16.0)
					pos = Vector2(x, float(sp["floor"]) - 40.0)
				"behind":
					pos = Vector2(view.get_center().x - dir * (view.size.x / 2.0 + 20.0 + i * 30.0),
						float(sp["floor"]) - 40.0)
					run_dir = dir
				_:
					pos += Vector2(i * 24.0, 0.0)
					run_dir = 1 if player.global_position.x > pos.x else -1
			var e := _make_enemy(sp["kind"], _free_spawn_pos(pos))
			e.behavior = sp["behavior"]
			e.run_dir = run_dir
			enemies.add_child(e)
	var shooters: Array = layout["shooters"]
	while _shooter_index < shooters.size() and shooters[_shooter_index]["s"] <= cam_s:
		var sh: Dictionary = shooters[_shooter_index]
		_shooter_index += 1
		var e := _make_enemy(sh["kind"], (sh["pos"] as Vector2) - Vector2(0, 2))
		e.behavior = "shooter"
		enemies.add_child(e)


## Quái chạy ngang (runner) ra khỏi khung nhìn quá DESPAWN_MARGIN thì quay đầu chạy về phía người chơi (phải diệt
## hết quái mới qua màn nên không cho chúng biến mất). Quái đuổi đánh và lính bắn ở lại chỗ của chúng.
## Vật phẩm tự hết hạn (DROP_LIFETIME).
## Chỗ thả quái không được lọt vào trong thùng / khối (thả ở mép màn hình, cao hơn sàn 40 px, mà chỗ đó có chồng
## thùng 2–3 tầng thì quái bị vật lý đẩy xuyên qua chồng thùng): đè lên vật cứng nào thì đặt lên nóc vật đó.
func _free_spawn_pos(pos: Vector2) -> Vector2:
	for _i in 4:
		var body := Rect2(pos.x - 13.0, pos.y - 48.0, 26.0, 48.0)
		var hit := false
		for so in layout["solids"]:
			var r: Rect2 = so["rect"]
			if body.intersects(r):
				pos.y = r.position.y - 2.0
				hit = true
		if not hit:
			break
	return pos


func _despawn_far() -> void:
	var keep := view_rect().grow(DESPAWN_MARGIN)
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and en.behavior == "runner" and en.state != Enemy.State.DEAD and not keep.has_point(en.global_position):
			en.run_dir = 1 if player.global_position.x > en.global_position.x else -1


## Đấu trường trùm khóa camera và chặn người chơi bằng tường vô hình; tường không chặn quái, nên giữ quái
## (cả trùm) trong khung nhìn, không thì trùm đi ra ngoài và người chơi không với tới được.
func _keep_in_arena() -> void:
	if not _arena_locked:
		return
	var view := view_rect()
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en == null or en.state == Enemy.State.DEAD:
			continue
		var x := clampf(en.global_position.x, view.position.x + 16.0, view.end.x - 16.0)
		if x != en.global_position.x:
			en.global_position.x = x
			en.run_dir = 1 if x < view.get_center().x else -1


func _check_player_position() -> void:
	if _restarting:
		return
	var pos := player.global_position
	var view := view_rect()
	if player.is_on_floor() and view.grow(-20.0).has_point(pos):
		_last_safe = pos
	var ps := player_s()
	# Chỉ ghi checkpoint khi đang chơi: lúc hiện kết quả, GameState đã sang màn kế (checkpoint đã xóa)
	# mà layout vẫn là màn cũ, ghi lúc đó sẽ làm màn kế bắt đầu giữa đường.
	if phase == Phase.RUN or phase == Phase.GOAL_FIGHT:
		var cps: Array = layout["checkpoints"]
		for i in cps.size():
			if i > GameState.checkpoint and ps >= float(cps[i]["s"]) - CAMERA_LEAD:
				GameState.checkpoint = i
				_show_banner("CHECKPOINT", 1.2)
	# Rơi vực: xuống dưới mép khung nhìn, tính cả khung nhìn đặt đúng chỗ người chơi (camera đang trượt theo
	# thì chưa tới kịp). Trong giếng khung nhìn đi xuống theo người chơi nên rơi từ bệ xuống không tính là vực.
	var fall_line := maxf(view.end.y, StageBuilder.path_point(layout, ps).y + HALF_H) + FALL_MARGIN
	if pos.y > fall_line:
		if not player.take_fall_damage(FALL_DAMAGE):
			var spot := StageBuilder.safe_spot(layout, view, _last_safe)
			player.respawn_at(spot - Vector2(0, 40))
	if phase == Phase.RUN and ps >= float(layout["goal_s0"]) - CAMERA_LEAD:
		var dir: int = layout["goal_dir"]
		if (pos.x - float(layout["goal_x"])) * dir >= 0.0 and absf(pos.y - float(layout["exit_floor"])) < 120.0:
			_reach_goal()


# --- Cuối màn -------------------------------------------------------------

func _reach_goal() -> void:
	var left := _enemies_left()
	if left > 0:
		if _goal_nag <= 0.0:
			_goal_nag = 2.5
			_show_banner("Còn %d quái · diệt hết mới qua màn!" % left, 2.0)
		return
	var stage := GameState.current_stage()
	var type: int = stage["type"]
	if type == WorldData.StageType.TRAINING:
		var key := _key_item()
		# Item (vũ khí) chỉ rơi từ quái, không bắt buộc: lỡ thì chơi lại màn để nhặt.
		if key.is_empty() or GameState.is_item(key["rider"], key["form"]):
			_finish_stage()
		else:
			_place_goal_item(key, "Nhặt %s!" % key["name"])
		return
	phase = Phase.GOAL_FIGHT
	var waves: Array = stage["waves"]
	var last_wave: Array = waves[waves.size() - 1]
	if type == WorldData.StageType.BOSS:
		_arena_locked = true
		cam_s = layout["length"]
		_update_camera()
		await _story(stage["id"], "goal")
		Sound.sfx("boss_appear", 0.0)
		_show_banner("TRÙM: %s" % stage["boss"]["name"], 2.5)
	elif type == WorldData.StageType.CHALLENGE:
		_show_banner("Hạ nhóm canh giữ cuối!", 2.0)
	else:
		# Driver đã rơi và được nhặt giữa màn thì không nhắc "Driver nằm trên người nhóm canh giữ" nữa.
		if not _key_item().is_empty():
			await _story(stage["id"], "goal")
		_show_banner("Hạ nhóm canh giữ Driver!", 2.0)
	var view := view_rect()
	for i in last_wave.size():
		var side := 1 if i % 2 == 0 else -1
		var x := clampf(player.global_position.x + side * (140.0 + 40.0 * i), view.position.x + 30.0, view.end.x - 30.0)
		var e := _make_enemy(str(last_wave[i]), Vector2(x, float(layout["exit_floor"]) - 60.0))
		enemies.add_child(e)


func _goal_cleared() -> void:
	var stage := GameState.current_stage()
	var world := GameState.current_world()
	if stage["type"] == WorldData.StageType.CHALLENGE:
		_finish_stage()
	elif stage["type"] == WorldData.StageType.AWAKEN:
		var key := _key_item()
		if not key.is_empty():
			_place_goal_item(key, "Nhặt Driver!")
		elif not _boost_item().is_empty():
			_place_goal_item(_boost_item(), "Nhặt Tăng sức mạnh!")
		else:
			_finish_stage()     # Driver đã rơi và được nhặt giữa màn
	elif GameState.drivers.has(String(world.get("next_driver", &""))):
		# Chơi lại màn trùm: Driver kế tiếp đã có rồi, không rơi lại; thay bằng Tăng sức mạnh (nếu lượt này chưa nhận).
		if not _boost_item().is_empty():
			_place_goal_item(_boost_item(), "Nhặt Tăng sức mạnh!")
		else:
			_finish_stage()
	else:
		_place_goal_item({"kind": "sealed", "rider": world["next_driver"], "form": &"",
			"name": "%s (phong ấn)" % world["next_driver_name"]}, "Nhặt Driver!")


## Món bắt buộc phải nhặt để qua màn, đặt ngay trước mặt người chơi, không tự biến mất.
func _place_goal_item(item: Dictionary, message: String) -> void:
	phase = Phase.PICKUP
	if is_instance_valid(_drop):
		_drop.queue_free()
	var view := view_rect()
	var x := clampf(player.global_position.x + 90.0 * player.facing, view.position.x + 30.0, view.end.x - 30.0)
	_spawn_item(item, Vector2(x, float(layout["exit_floor"]) - 16.0), -1.0)
	_show_banner(message, 3.0)


# --- Vật phẩm rơi từ quái ---------------------------------------------------

## Món chính của màn còn chờ nhặt: Driver của thế giới (màn Thức tỉnh) hoặc form của màn. {} = không còn.
func _key_item() -> Dictionary:
	var world := GameState.current_world()
	var stage := GameState.current_stage()
	var rider: StringName = world["rider"]
	if stage["type"] == WorldData.StageType.AWAKEN and not GameState.is_active(rider):
		return {"kind": "driver", "rider": rider, "form": &"", "name": world["driver_name"]}
	var form: StringName = stage.get("form", &"")
	if form != &"" and GameState.is_active(rider) and not GameState.has_form(rider, form):
		return {"kind": "form", "rider": rider, "form": form, "name": stage["form_name"]}
	return {}


## Tăng sức mạnh: chỉ khi chơi lại màn đã qua (Driver / form / trang bị của màn đã nhặt rồi nên không rơi lại),
## mỗi lượt chơi một lần, và đã có Rider để cộng. {} = không có.
func _boost_item() -> Dictionary:
	if _boost_given or not GameState.cleared_stages.has(str(GameState.current_stage()["id"])):
		return {}
	if GameState.main_rider == &"" or not GameState.is_active(GameState.main_rider):
		return {}
	return {"kind": "boost", "rider": GameState.world_rider(), "form": &"#boost",
		"name": "Tăng sức mạnh +%d%%" % int(GameState.BOOST_STEP * 100.0)}


## Nạp nộ: chọn ngẫu nhiên một form đặc biệt đã có của các Rider trong đội hình. {} = chưa có form nào.
func _charge_item() -> Dictionary:
	var options: Array = []
	for rider in GameState.equipped:
		for form in GameState.drivers[String(rider)].get("forms", []):
			var form_id := StringName(form)
			if not GameState.form_usable(rider, form_id):
				continue
			options.append({"kind": "charge", "rider": rider, "form": form_id,
				"name": "%s +%d nộ" % [WorldData.form_name(rider, form_id), int(CHARGE_RAGE)]})
	return options.pick_random() if not options.is_empty() else {}


func _on_enemy_died(enemy: Enemy) -> void:
	if is_instance_valid(_drop) or not (phase == Phase.RUN or phase == Phase.GOAL_FIGHT):
		return
	var item := _key_item()
	if item.is_empty():
		item = _boost_item()      # chơi lại màn đã qua: món chính thay bằng Tăng sức mạnh
	if not item.is_empty():
		if randf() >= KEY_DROP_BASE + KEY_DROP_STEP * _key_misses:
			_key_misses += 1
			return
	else:
		item = _charge_item()
		var chance := CHARGE_DROP_CHANCE * (2.0 if enemy.traits.has(&"armored") else 1.0)
		if GameState.current_stage()["type"] == WorldData.StageType.CHALLENGE:
			chance = CHALLENGE_CHARGE_CHANCE
		if item.is_empty() or randf() >= chance:
			return
	# Rơi tại chỗ quái gục, nằm trên chỗ đứng ngay bên dưới; bên dưới là vực thì dời về chỗ an toàn trong khung nhìn.
	var view := view_rect()
	var pos := enemy.global_position
	var floor_y := pos.y if enemy.is_on_floor() else StageBuilder.surface_below(layout, pos, view.end.y - pos.y)
	if floor_y == INF:
		pos = StageBuilder.safe_spot(layout, view, _last_safe)
		floor_y = pos.y + 2.0
	var x := clampf(pos.x, view.position.x + 20.0, view.end.x - 20.0)
	_spawn_item(item, Vector2(x, floor_y - 16.0), DROP_LIFETIME)


func _spawn_item(item: Dictionary, pos: Vector2, lifetime: float) -> void:
	var pickup := DriverPickup.new()
	pickup.data = item
	pickup.label_text = item["name"]
	pickup.lifetime = lifetime
	match item["kind"]:
		"driver":
			pickup.color = Color(1.0, 0.85, 0.3)
			pickup.icon = DriverPickup.driver_icon(item["rider"])
		"sealed":
			pickup.color = Color(0.6, 0.8, 1.0)
			pickup.icon = DriverPickup.driver_icon(item["rider"])
			pickup.sealed = true
		"form":
			pickup.color = WorldData.rider_color(item["rider"]).lightened(0.3)
		"boost":
			pickup.color = Color(0.4, 1.0, 0.55)      # Tăng sức mạnh: viên kim cương xanh lục
		_:
			pickup.color = Color(1.0, 0.55, 0.2)
	# Hình Driver giữ đúng cỡ pixel gốc; viên kim cương (form) phóng to cho dễ thấy, nạp nộ để nhỏ.
	pickup.scale = Vector2(1.0, 1.0) if item["kind"] == "charge" or pickup.icon else Vector2(1.5, 1.5)
	pickup.position = pos
	pickup.collected.connect(_on_item_collected.bind(item))
	# Quái thường chết giữa lúc engine đang xử lý va chạm (đạn / đòn trúng): thêm Area2D mới lúc đó sẽ lỗi,
	# nên đợi hết bước vật lý rồi mới thêm vào màn.
	level_root.add_child.call_deferred(pickup)
	_drop = pickup


func _on_item_collected(item: Dictionary) -> void:
	var rider: StringName = item["rider"]
	var stage := GameState.current_stage()
	var stage_id: String = stage["id"]
	var is_stage_key: bool = rider == GameState.world_rider() and (item["kind"] == "driver" or item["form"] == stage.get("form", &""))
	Sound.sfx("pickup_key" if is_stage_key else "pickup", 0.0)
	var unlocked := false
	match item["kind"]:
		"driver":
			# Chưa có Rider nào (dạng người) thì biến thân ngay; đang dùng Rider khác thì Driver mới dùng ở màn sau.
			var had_rider := GameState.main_rider != &"" and GameState.is_active(GameState.main_rider)
			GameState.activate_driver(rider)
			if had_rider:
				_show_banner("Nhận %s · chọn Rider này ở màn sau" % item["name"], 2.5)
			else:
				player.transform_into(rider, &"")
				_show_banner("%s · BIẾN THÂN!" % item["name"], 2.0)
			unlocked = true
		"form":
			if GameState.unlock_form(rider, item["form"]):
				unlocked = true
				if rider == GameState.main_rider:
					# Item nhặt giữa màn dùng được ngay trong màn này.
					if GameState.is_item(rider, item["form"]) and not GameState.carried_items.has(item["form"]):
						GameState.carried_items.append(item["form"])
					player.transform_into(rider, item["form"])
					_show_banner("%s · NỘ ĐẦY!" % item["name"], 2.0)
				else:
					_show_banner("Nhặt %s · dùng cho %s ở màn sau" % [item["name"],
						WorldData.WORLDS[WorldData.world_index_of(rider)]["rider_name"]], 2.5)
		"charge":
			player.add_rage(CHARGE_RAGE)
			_show_banner("+%d NỘ" % int(CHARGE_RAGE), 1.0)
		"boost":
			await _choose_boost()
	var at_goal := phase == Phase.PICKUP
	var key_story := "%s:key" % stage_id
	if unlocked and is_stage_key and GameState.story_enabled and not GameState.seen_story.has(key_story) \
			and not StoryData.stage_beat(stage_id, "key").is_empty():
		_pending_key = stage_id
		await _wait(KEY_STORY_DELAY)
		# Trong lúc chờ mà đã tới vạch đích qua màn thì _finish_stage đã hiện thoại này trước thoại "clear".
		if _pending_key == stage_id:
			_pending_key = ""
			await _story(stage_id, "key")
	if at_goal:
		_finish_stage()


## Nhạc nền của màn: màn Trùm dùng nhạc trùm (thế giới cuối: boss_final), màn khác dùng bài của thế giới.
func _stage_music(stage: Dictionary) -> String:
	if stage["type"] == WorldData.StageType.BOSS:
		return "boss_final" if GameState.world_index == WorldData.WORLDS.size() - 1 else "boss"
	return "stage_%s" % GameState.current_world()["id"]


## Dừng màn, hiện bảng chọn chỉ số; cộng +1% cho form đang dùng (dạng người thì cho form gốc của Rider chính).
func _choose_boost() -> void:
	_boost_given = true
	var form: RiderForm = player.current_form
	if form == null and not player.equipped.is_empty():
		form = player.equipped[player.active_slot]
	if form == null:
		return
	get_tree().paused = true
	touch.visible = false
	_boost_select.open(form)
	var stat: String = await _boost_select.chosen
	get_tree().paused = false
	touch.visible = phase == Phase.RUN or phase == Phase.GOAL_FIGHT
	_show_banner("%s +1%% · %s" % [GameState.BOOST_STATS[stat], form.display_name], 2.0)


func _finish_stage() -> void:
	phase = Phase.TALK
	var stage := GameState.current_stage()
	var world := GameState.current_world()
	if _pending_key == stage["id"]:
		_pending_key = ""
		await _story(stage["id"], "key")
	# Qua màn: khóa điều khiển, dọn quái / đạn còn lại, đợi đòn đang ra hoặc cảnh biến thân xong rồi giải trừ biến thân.
	player.input_locked = true
	touch.visible = false
	_clear_field()
	await _wait_player_settled()
	if player.current_form:
		player.release_henshin()
		while player.is_releasing():
			await get_tree().physics_frame
		await _wait(0.2)
	Sound.music("clear")
	await _story(stage["id"], "clear")
	var result := GameState.complete_stage()
	if stage["type"] == WorldData.StageType.BOSS and GameState.take_story("world:%s" % world["id"]):
		await _talk(StoryData.world_clear(world["id"]), "map", int(world["number"]) - 1)
	_show_banner(_format_result(result), RESULT_TIME)
	phase = Phase.RESULT
	_phase_timer = RESULT_TIME


func _fade_to(alpha: float) -> void:
	if is_equal_approx(_fade.color.a, alpha):
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished


## Qua màn: quái còn lại tan biến, đạn và vật phẩm thừa biến mất, để không bị đánh lúc giải trừ biến thân / đọc thoại.
func _clear_field() -> void:
	CombatDirector.set_enemy_time_scale(1.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en == null:
			continue
		en.remove_from_group("enemies")
		CombatDirector.release_attack_token(en)
		en.set_physics_process(false)
		en.hitbox.deactivate()
		var tween := en.create_tween()
		tween.tween_property(en, "modulate:a", 0.0, 0.35)
		tween.tween_callback(en.queue_free)
	for n in find_children("*", "", true, false):
		if n is Projectile:
			n.queue_free()
	if is_instance_valid(_drop):
		_drop.queue_free()
	_drop = null


## Đợi nhân vật xong đòn đang ra / cảnh biến thân / đổi Rider (tối đa 3 giây) rồi mới giải trừ biến thân.
func _wait_player_settled() -> void:
	var left := 3.0
	while left > 0.0 and player.state not in [Player.State.NORMAL, Player.State.CROUCH, Player.State.KO]:
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()


## Hiện hội thoại một nhịp của màn (STORY trong file thế giới), mỗi nhịp một lần mỗi lượt chơi. Cả màn dừng trong lúc thoại.
func _story(stage_id: String, beat: String) -> void:
	var lines := StoryData.stage_beat(stage_id, beat)
	if lines.is_empty() or not GameState.take_story("%s:%s" % [stage_id, beat]):
		return
	await _talk(lines)


## Mở khung thoại: phase = TALK, ẩn nút cảm ứng, chờ đọc xong rồi trả lại như cũ.
func _talk(lines: Array, backdrop := "", fresh := -1) -> void:
	if lines.is_empty():
		return
	var before := phase
	var touch_shown := touch.visible
	phase = Phase.TALK
	touch.visible = false
	_dialogue.play(lines, backdrop, fresh)
	await _dialogue.finished
	touch.visible = touch_shown
	if phase == Phase.TALK:
		phase = before


## Chờ theo thời gian của màn (dừng khi game dừng). Timer là con của màn nên bị hủy cùng màn khi tải lại.
func _wait(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	timer.queue_free()


func _format_result(r: Dictionary) -> String:
	var world: Dictionary = r["world"]
	var lines := PackedStringArray(["HOÀN THÀNH!"])
	if r["activated"]:
		lines.append("Nhận %s — có thể biến thân!" % world["driver_name"])
	var level: int = r["level"]
	if level > 0:
		var unlocks: Array = world["unlocks"]
		lines.append("%s Lv%d · %s" % [world["rider_name"], level, unlocks[mini(level, unlocks.size()) - 1]])
	if r["form_name"] != "":
		lines.append("Form: %s" % r["form_name"])
	if r["obtained"] != &"":
		lines.append("Nhận %s" % world["next_driver_name"])
	if int(r.get("fragments", 0)) > 0:
		lines.append("Thưởng màn EX: +%d Mảnh Ký Ức" % int(r["fragments"]))
	return "\n".join(lines)


func _make_enemy(kind: String, pos: Vector2) -> Enemy:
	var e := ENEMY_SCENE.instantiate() as Enemy
	var color := Color.WHITE
	e.level = GameState.current_enemy_level()
	if kind == "boss":
		var boss: Dictionary = GameState.current_stage()["boss"]
		e.level += GameState.BOSS_LEVEL_BONUS
		e.scale_with_level = false
		e.is_boss = true
		e.display_name = boss["name"]
		e.max_hp = boss["hp"]
		e.attack_damage = boss["damage"]
		e.poise = boss["poise"]
		e.move_speed = boss["speed"]
		# Vùng đòn tới ~38 px trước tâm trùm (hình trùm vươn tối đa ~34 px), không trúng khi còn cách xa
		e.attack_range = 24.0
		e.attack_size = Vector2(18, 22)
		e.attack_offset = Vector2(12, -24)
		e.sight_range = 400.0
		e.fragment_reward = 50
		e.sprite_prefix = boss.get("sprite", "")
		var boss_traits: Array[StringName] = []
		for t in boss["traits"]:
			boss_traits.append(StringName(str(t)))
		e.traits = boss_traits
		color = boss["color"]
	elif SPECIAL_ENEMIES.has(kind):
		var sp: Dictionary = SPECIAL_ENEMIES[kind]
		var info: Dictionary = GameState.current_world()["enemies"][sp["art"]]
		e.display_name = str(sp["name"]) % info["name"]
		e.sprite_prefix = info.get("sprite", "")
		color = info["color"]
		e.max_hp = sp["hp"]
		e.move_speed = sp["speed"]
		e.attack_damage = sp["damage"]
		e.windup_time = sp["windup"]
		e.poise = sp.get("poise", e.poise)
		e.attack_knockback = sp.get("knockback", e.attack_knockback)
		e.shoot_interval = sp.get("interval", e.shoot_interval)
		e.fragment_reward = 10
		var t: Array[StringName] = [StringName(kind)]
		e.traits = t
		e.immune_hit.connect(_on_enemy_immune)
	else:
		var info: Dictionary = GameState.current_world()["enemies"][kind]
		e.display_name = info["name"]
		e.sprite_prefix = info.get("sprite", "")
		color = info["color"]
		match kind:
			"fast":
				e.max_hp = 25.0
				e.move_speed = 90.0
				e.windup_time = 0.3
				var t: Array[StringName] = [&"fast"]
				e.traits = t
			"armored":
				e.max_hp = 60.0
				e.move_speed = 40.0
				e.attack_damage = 14.0
				e.poise = 15.0
				var t: Array[StringName] = [&"armored"]
				e.traits = t
	e.attack_damage *= GameState.enemy_damage_mult()
	if kind != "boss":
		e.died.connect(_on_enemy_died)
	e.fall_limit = float(layout["bottom"]) + 200.0
	e.position = pos
	(e.get_node("Placeholder") as Polygon2D).color = color
	return e


func _on_player_died() -> void:
	_restarting = true
	CombatDirector.set_enemy_time_scale(1.0)
	_show_banner("THẤT BẠI\nChơi lại từ checkpoint...", 3.0)
	await get_tree().create_timer(2.0).timeout
	await _fade_to(1.0)
	get_tree().reload_current_scene()


# --- Hiển thị -------------------------------------------------------------

## Lớp phủ toàn màn, nằm dưới các phần HUD (thêm vào đầu $HUD).
func _overlay(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size = get_viewport_rect().size
	r.visible = false
	$HUD.add_child(r)
	$HUD.move_child(r, 0)
	return r


func _on_time_scale_changed(value: float) -> void:
	_time_tint.visible = value < 1.0


## Tung Final: khựng hình, phông tuyệt chiêu sau trận đánh, cut-in mặt Rider + tên chiêu, chớp trắng nhẹ.
func _on_final_attack(rider_id: StringName, attack_name: String) -> void:
	var fx := player.current_fx()
	var mark := str(fx["signature"]) if str(fx["signature"]) != "" else str(fx["intro"])
	_backdrop.play(rider_id, fx["color"], mark)
	_cutin.final(attack_name, fx["color"], player.sprite, player.current_form.animation_prefix() + "_idle")
	CombatDirector.hit_stop(0.16, 0.1)
	_flash.visible = true
	_flash.color = Color(1, 1, 1, 0.35)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: _flash.visible = false)


func _show_banner(text: String, duration: float) -> void:
	banner.text = text
	_banner_timer = duration


func _hud_text() -> String:
	var lines := PackedStringArray()
	if phase == Phase.RUN or phase == Phase.GOAL_FIGHT:
		var progress := clampf(player_s() / float(layout["length"]), 0.0, 1.0)
		lines.append("%s · %d%%" % [GameState.current_stage()["id"], int(progress * 100.0)])
		var key := _key_item()
		if not key.is_empty():
			lines.append("Tìm: %s" % key["name"])
		var left := _enemies_left()
		lines.append("Quái còn: %d%s" % [left, _nearest_left_hint() if left > 0 else ""])
	if _combo >= 3:
		lines.append("%d HIT!" % _combo)
	return "\n".join(lines)


## Hướng tới con quái còn sống gần nhất theo lộ trình: " · ◀ phía sau" / " · ▶ phía trước" / " · ở gần".
func _nearest_left_hint() -> String:
	var ps := player_s()
	var best := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and en.state != Enemy.State.DEAD:
			# Chiếu trên cả lộ trình: quái bị bỏ lại ở đoạn trước có thể nằm ngay dưới chân (lộ trình quay đầu).
			var d := StageBuilder.project(layout, en.global_position) - ps
			if absf(d) < absf(best):
				best = d
	if absf(best) < 120.0:
		return " · ở gần"
	return " · ◀ phía sau" if best < 0.0 else " · ▶ phía trước"


func _form_text() -> String:
	if player.current_form:
		return "%s  Lv%d" % [_status, player.current_form.level]
	return GameState.player_name


func _update_placeholder() -> void:
	placeholder.visible = not player.sprite.visible
	var fading := player.state == Player.State.DODGE or player.state == Player.State.BREAK or player.is_invulnerable()
	player.sprite.modulate.a = 0.55 if fading and Engine.get_process_frames() % 8 < 4 else 1.0
	placeholder.scale.x = player.facing


func _on_form_changed(rider_id: StringName) -> void:
	placeholder.color = WorldData.rider_color(rider_id) if rider_id != &"" else HUMAN_COLOR
	if rider_id == &"":
		_status = "%s · dạng người" % GameState.player_name
