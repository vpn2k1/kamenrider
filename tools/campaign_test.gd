extends Node
## Test cả chiến dịch: bot chơi lần lượt 15 màn (1-1 → 3-B) với luật hiện tại, in báo cáo từng màn.
##
##   godot --headless --path . --fixed-fps 60 res://tools/campaign_test.tscn
##
## (--fixed-fps để chạy nhanh hết mức máy cho phép thay vì theo thời gian thực.)
##
## Chạy một đoạn: CAMP_FROM="4-1" (bắt đầu từ màn đó, có sẵn Driver / cấp / form như khi chơi tới đó) và
## CAMP_TO="6-B" (dừng sau màn đó). tools/run_campaign.sh chạy cả 27 thế giới thành nhiều phần song song.
##
## Bot: chạy sang phải, đánh quái gần, bắn khi form có súng, nhảy qua vực, đi nhặt vật phẩm rơi,
## cúi khi đạn cao bay tới và nhảy khi đạn thấp bay tới, biến thân khi nộ đầy, đổi form khi đủ nộ,
## tung Final với trùm, thỉnh thoảng đổi Rider. Máu người xuống thấp thì bot được hồi đầy (ghi là "suýt gục")
## để chiến dịch không bị chơi lại từ checkpoint.
##
## Bot đi theo layout["waypoints"] (cửa giếng, từng bệ leo, gờ ra cửa, vạch đích): cao hơn thì nhảy lên,
## thấp hơn thì S + nhảy / bước khỏi mép bệ, gặp vực hoặc khối chắn thì nhảy.
##
## Mỗi màn kiểm tra: qua được trong giới hạn thời gian; không kẹt một chỗ quá 20 giây; bố cục không đè lên nhau;
## món chính (Driver / form) rơi từ quái hay phải nhặt ở vạch đích; nhặt xong có vào đúng form không;
## form đặc biệt có tự về form gốc khi hết nộ không; hội thoại (StoryData) của màn có hiện đủ không;
## vào màn có ở dạng người với nộ đầy và đúng nền của màn không; qua màn có giải trừ biến thân về dạng người không.
## Bot bấm qua từng câu thoại (hội thoại dừng màn chơi nhưng bot vẫn chạy: PROCESS_MODE_ALWAYS).
## Cuối cùng in tổng kết và thoát với mã lỗi = số màn có vấn đề.

const STAGE := "res://scenes/levels/stage_run.tscn"
const STAGE_TIMEOUT := 300.0      ## giây trong game
const LOW_HP := 60                ## quái cấp cao đánh một đòn gần 40 máu, hồi sớm để không gục thật
const FORM_CHECK_TIME := 2.0      ## giây chờ cảnh biến thân / đổi form sau khi nhặt

var stage: Node
var player: Player
var frame := 0
var held: Array[String] = []

# Theo dõi màn hiện tại
var _stage_id := ""
var _stage_start := 0
var _kills := 0
var _shots := 0
var _shot_hits := 0
var _breaks := 0
var _reverts := 0
var _near_deaths := 0
var _items_seen := 0
var _items_taken := 0
var _key_note := "-"
var _form_check := ""
var _nav_target := Vector2.INF
var _chosen_note := ""
var _prev_state := 0
var _prev_threat := ""
var _expect := {}                 ## {rider, form, deadline}: form phải vào sau khi nhặt
var _problems: Array[String] = []
var _stuck_x := 0.0
var _stuck_since := 0
var _last_swap := 0
var _report: Array[String] = []
var _bad_stages := 0

var _seen_enemies := {}
var _seen_shots := {}
var _seen_items := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.set_player_name("Bot")
	_jump_to(OS.get_environment("CAMP_FROM"))
	stage = load(STAGE).instantiate()
	add_child(stage)
	player = stage.get_node("Player")
	player.notice.connect(_on_notice)
	# Chỉ Henshin Break mới đưa Rider về dạng người giữa màn.
	player.form_changed.connect(func(id: StringName) -> void:
		if id == &"" and _stage_id != "":
			_breaks += 1)
	GameState.driver_activated.connect(func(id: StringName) -> void: _on_key_taken(id, &""))
	GameState.form_unlocked.connect(_on_key_taken)
	player.died.connect(func() -> void:
		_problems.append("nhân vật gục thật (màn sẽ tải lại, báo cáo các màn trước bị mất)"))
	print("[camp] bắt đầu")


func _process(_delta: float) -> void:
	frame += 1
	_release_all()
	# Nhặt xong có vào đúng form không: kiểm cả lúc đang thoại (nhặt ở vạch đích thì thoại "key" rồi qua màn ngay).
	_check_expected_form()
	# Đang thoại (kể cả 2 khung hình khung thoại đóng lại): bấm qua, chưa tính là xong màn.
	if stage._dialogue.is_open() or stage.phase == stage.Phase.TALK:
		stage._dialogue.advance()
		return
	if stage.phase == stage.Phase.SELECT:
		_choose_rider()
		return
	_track_stage()
	if GameState.is_demo_finished():
		_finish()
		return
	_track_nodes()
	if player.hp <= LOW_HP and player.state != Player.State.KO:
		player.hp = player.max_hp
		_near_deaths += 1
	_drive()
	if OS.get_environment("CAMP_DEBUG") != "" and frame % 60 == 0:
		print("   t=%d %s phase=%d x=%d y=%d s=%d/%d cam_s=%d state=%d form=%s hp=%d quái=%d" % [frame / 60, GameState.current_stage()["id"],
			stage.phase, int(player.global_position.x), int(player.global_position.y), int(stage.player_s()), int(stage.layout["length"]), int(stage.cam_s),
			player.state, _form_name(), player.hp, get_tree().get_nodes_in_group("enemies").size()])
		if stage.phase == stage.Phase.GOAL_FIGHT:
			for e in get_tree().get_nodes_in_group("enemies"):
				var en := e as Enemy
				print("      quái %s %s x=%d y=%d state=%d hp=%d" % [en.display_name, en.behavior, int(en.global_position.x), int(en.global_position.y), en.state, int(en.hp)])
	if _stage_id != "" and _secs(frame - _stage_start) > STAGE_TIMEOUT:
		_problems.append("quá %d giây chưa qua màn (phase=%d, x=%d)" % [int(STAGE_TIMEOUT), stage.phase, int(player.global_position.x)])
		_end_stage("KẸT")
		_finish()


## CAMP_FROM="2-4": bắt đầu từ màn đó, với Driver / cấp / form như khi chơi tới đó.
func _jump_to(stage_id: String) -> void:
	if stage_id == "":
		return
	for w in WorldData.WORLDS.size():
		var world: Dictionary = WorldData.WORLDS[w]
		var stages: Array = world["stages"]
		for i in stages.size():
			if stages[i]["id"] == stage_id:
				GameState.world_index = w
				GameState.stage_index = i
				GameState.worlds_cleared = w
				return
			# Màn đã qua: Driver kích hoạt, lên cấp, form của màn đã nhặt, Driver thế giới kế phong ấn.
			var rider: StringName = world["rider"]
			GameState.activate_driver(rider)
			GameState.set_level(rider, int(stages[i]["reward_level"]))
			if stages[i].has("form"):
				GameState.unlock_form(rider, stages[i]["form"])
			if stages[i]["type"] == WorldData.StageType.BOSS:
				GameState.obtain_driver(world["next_driver"])
	push_warning("CAMP_FROM: không có màn %s" % stage_id)


# --- Theo dõi ---------------------------------------------------------------

func _track_stage() -> void:
	if stage.phase == stage.Phase.RESULT and _stage_id != "":
		var done_id := _stage_id
		_end_stage("OK")
		_stage_id = ""
		if done_id == OS.get_environment("CAMP_TO"):
			_finish()
	elif stage.phase == stage.Phase.RUN and _stage_id == "" and not GameState.is_demo_finished():
		_begin_stage(GameState.current_stage()["id"])


func _begin_stage(id: String) -> void:
	_stage_id = id
	_stage_start = frame
	_kills = 0
	_shots = 0
	_shot_hits = 0
	_breaks = 0
	_reverts = 0
	_near_deaths = 0
	_items_seen = 0
	_items_taken = 0
	_key_note = "-"
	_form_check = ""
	_problems.clear()
	for o in stage.layout["overlaps"]:
		_problems.append("bố cục chồng lấn: %s" % o)
	_nav_target = Vector2.INF
	_stuck_x = 0.0
	_stuck_since = frame
	var key: Dictionary = stage._key_item()
	print("[camp] ▶ %s %s · dạng %s · nộ %d · đội hình %s%s%s" % [id, GameState.current_stage()["name"], _form_name(), int(player.rage),
		str(GameState.equipped), (" (" + _chosen_note + ")") if _chosen_note != "" else "",
		(" · cần nhặt: " + str(key["name"])) if not key.is_empty() else ""])
	_chosen_note = ""
	if player.current_form != null:
		_problems.append("vào màn mà không ở dạng người (đang là %s)" % _form_name())
	if player.rage < Player.GAUGE_MAX:
		_problems.append("vào màn mà nộ chưa đầy (%d)" % int(player.rage))
	var want_bg: String = GameState.current_stage().get("bg", stage.DEFAULT_BG)
	if stage.far_a.texture == null or stage.far_a.texture.resource_path != want_bg:
		_problems.append("nền không đổi theo màn: đang là %s, cần %s" % [
			stage.far_a.texture.resource_path if stage.far_a.texture else "(trống)", want_bg])


func _end_stage(result: String) -> void:
	var stage_data: Dictionary = WorldData.WORLDS[_world_of(_stage_id)]["stages"].filter(
		func(s): return s["id"] == _stage_id)[0]
	var rider: StringName = WorldData.WORLDS[_world_of(_stage_id)]["rider"]
	# Kiểm tra món chính của màn đã vào tay.
	if stage_data["type"] == WorldData.StageType.AWAKEN and not GameState.is_active(rider):
		_problems.append("qua màn Thức tỉnh mà chưa có Driver %s" % rider)
	var form: StringName = stage_data.get("form", &"")
	if form != &"" and not GameState.has_form(rider, form):
		_problems.append("qua màn mà chưa có form %s" % form)
	if _form_check.begins_with("SAI"):
		_problems.append(_form_check)
	if player.current_form != null:
		_problems.append("qua màn mà chưa giải trừ biến thân (đang là %s)" % _form_name())
	# Hội thoại: "start" và "clear" luôn phải hiện; "goal" ở màn trùm; "key" khi màn có món chính.
	var beats: Dictionary = WorldData.stories.get(_stage_id, {})
	var seen: Array[String] = []
	for beat in ["start", "goal", "key", "clear"]:
		if GameState.seen_story.has("%s:%s" % [_stage_id, beat]):
			seen.append(beat)
		elif beats.has(beat) and (beat == "start" or beat == "clear"
				or (beat == "goal" and stage_data["type"] == WorldData.StageType.BOSS)
				or (beat == "key" and (stage_data["type"] == WorldData.StageType.AWAKEN or form != &""))):
			_problems.append("không hiện hội thoại \"%s\"" % beat)
	var world_id: String = WorldData.WORLDS[_world_of(_stage_id)]["id"]
	if stage_data["type"] == WorldData.StageType.BOSS:
		if GameState.seen_story.has("world:" + world_id):
			seen.append("bản đồ")
		else:
			_problems.append("không hiện bản đồ Chuỗi Trái Đất sau trùm")
	var line := "%s %-4s %5.0fs · hạ %2d · vật phẩm %d/%d nhặt · món chính: %s · đạn quái %d (trúng %d) · vỡ giáp %d · hết nộ→gốc %d · suýt gục %d · thoại: %s" % [
		"✔" if _problems.is_empty() and result == "OK" else "✘", _stage_id, _secs(frame - _stage_start), _kills,
		_items_taken, _items_seen, _key_note, _shots, _shot_hits, _breaks, _reverts, _near_deaths, ", ".join(seen)]
	if _form_check != "":
		line += "\n        " + _form_check
	for p in _problems:
		line += "\n        ⚠ " + p
	if not _problems.is_empty() or result != "OK":
		_bad_stages += 1
	_report.append(line)
	print("[camp] ■ " + line)


func _track_nodes() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not _seen_enemies.has(e):
			_seen_enemies[e] = true
			(e as Enemy).died.connect(func(_en: Enemy) -> void: _kills += 1)
	for c in stage.get_node("Enemies").get_children():
		if c is Projectile and not _seen_shots.has(c):
			_seen_shots[c] = true
			_shots += 1
			var shot := c as Projectile
			shot.hit_landed.connect(func(_t: Node, _i: DamageInfo) -> void:
				_shot_hits += 1
				if OS.get_environment("CAMP_DEBUG") != "":
					print("   trúng đạn %s: trước đó state=%d bot=%s · dx=%d" % ["THẤP" if shot.color == Enemy.SHOT_LOW_COLOR else "CAO",
						_prev_state, _prev_threat, int(shot.global_position.x - player.global_position.x)]))
	for c in stage.get_node("Level").get_children():
		if c is DriverPickup and not _seen_items.has(c):
			_seen_items[c] = true
			_items_seen += 1
			(c as DriverPickup).collected.connect(func() -> void: _items_taken += 1)


func _on_key_taken(rider: StringName, form: StringName) -> void:
	var where := "ở vạch đích" if stage.phase == stage.Phase.PICKUP else "từ quái sau %d con" % _kills
	_key_note = "%s %s" % [String(form) if form != &"" else "Driver " + String(rider), where]
	_last_swap = frame   # để bot không đổi Rider ngay khi vừa nhặt
	# form &"" = Driver mới: form gốc, tra lúc kiểm tra vì Rider chưa được tạo khi tín hiệu phát ra.
	_expect = {"rider": rider, "form": form, "deadline": frame + int(FORM_CHECK_TIME * 60.0)}


## Sau khi nhặt: trong FORM_CHECK_TIME giây phải thấy nhân vật ở đúng Rider/form vừa nhặt.
func _check_expected_form() -> void:
	if _expect.is_empty():
		return
	var f := player.current_form
	var want: StringName = _expect["form"]
	if want == &"" and f and f.rider_id == _expect["rider"]:
		want = f.base_form()
	if f and f.rider_id == _expect["rider"] and f.current_form_id() == want and player.state != Player.State.SWAP:
		_form_check = "OK: nhặt xong → %s, nộ %d" % [_form_name(), int(player.rage)]
		_expect = {}
	elif frame > int(_expect["deadline"]):
		_form_check = "SAI: nhặt xong sau %.0f giây vẫn là %s (mong đợi %s/%s)" % [FORM_CHECK_TIME, _form_name(), _expect["rider"], _expect["form"]]
		_expect = {}


func _on_notice(text: String) -> void:
	if text.begins_with("HẾT NỘ"):
		_reverts += 1
		if player.in_special_form():
			_problems.append("báo hết nộ nhưng vẫn ở form đặc biệt %s" % _form_name())


# --- Bot --------------------------------------------------------------------

func _drive() -> void:
	if stage.phase in [stage.Phase.RESULT, stage.Phase.DONE, stage.Phase.TRANSITION]:
		return
	var px := player.global_position.x
	var py := player.global_position.y

	# 1. Né đạn theo báo hiệu như người chơi: đỏ thì cúi, xanh thì chờ rồi nhảy.
	_prev_state = player.state
	_prev_threat = _threat()
	match _prev_threat:
		"crouch":
			_press("move_down")
			return
		"jump":
			if player.is_on_floor():
				_press("jump")
			return
		"hold":
			return

	# 2. Dùng nộ.
	_use_rage()

	# 3. Có vật phẩm thì đi nhặt (nếu không cách quá xa theo chiều dọc).
	for child in stage.get_node("Level").get_children():
		if child is DriverPickup and is_instance_valid(child) and (child as Node2D).is_inside_tree():
			var item := child as DriverPickup
			if absf(item.global_position.y - py) < 90.0 or stage.phase == stage.Phase.PICKUP:
				_move_to(item.global_position + Vector2(0, 16))
				return

	# 4. Đánh quái gần, không thì đi theo lộ trình. Đứng đánh quá 6 giây mà không tiến được (ví dụ nhóm quái
	#    giáp chặn ở miệng giếng) thì bỏ đánh, đi tiếp như người chơi thật (tụt giếng, chạy qua).
	var target := _nearest_enemy()
	var close := target != null and absf(target.global_position.x - px) < 50.0 \
		and absf(target.global_position.y - py) < 40.0
	var stalled: bool = stage.phase == stage.Phase.RUN and _secs(frame - _stuck_since) > 6.0
	if close and not stalled:
		var want_dir := "move_right" if target.global_position.x > px else "move_left"
		if (target.global_position.x > px) != (player.facing > 0):
			_press(want_dir)
		elif frame % 10 == 0:
			_press("attack_light")
	elif stage.phase == stage.Phase.GOAL_FIGHT and target != null:
		_move_to(target.global_position)
	else:
		_move_to(_next_waypoint())
	_press("shoot")
	if target != null and target.global_position.y < py - 30.0 and absf(target.global_position.x - px) < 220.0:
		_press("move_up")

	# 5. Kẹt một chỗ quá lâu (quãng đường không tăng) thì nhảy.
	if stage.phase == stage.Phase.RUN:
		var ps: float = stage.player_s()
		if ps > _stuck_x + 30.0:
			_stuck_x = ps
			_stuck_since = frame
		elif _secs(frame - _stuck_since) > 6.0 and player.is_on_floor():
			_press("jump")
			if _secs(frame - _stuck_since) > 20.0:
				var near := []
				for e in get_tree().get_nodes_in_group("enemies"):
					var en := e as Enemy
					if en.global_position.distance_to(player.global_position) < 200.0:
						near.append("%s(%s) %s" % [en.display_name, en.behavior, str(en.global_position.round())])
				_problems.append("kẹt ở %s (s=%d) hơn 20 giây · đích %s · quái gần: %s" % [str(player.global_position.round()),
					int(ps), str(_nav_target.round()), ", ".join(near)])
				_stuck_since = frame


## Màn chọn Rider chính: luân phiên màn chẵn chọn Rider của thế giới, màn lẻ chọn Rider khác
## (để thử cả trường hợp Đổi Rider qua lại giữa Rider chính và Rider của thế giới).
func _choose_rider() -> void:
	var options := GameState.selectable_riders()
	var world := GameState.world_rider()
	var pick: StringName = options[0]
	var want_world := (GameState.world_index * 5 + GameState.stage_index) % 2 == 0
	for id in options:
		if (id == world) == want_world:
			pick = id
			break
	_chosen_note = "chọn %s trong %s" % [pick, str(options)]
	stage._select.pick(pick)


## Điểm dẫn đường kế tiếp: waypoint đầu tiên nằm phía trước người chơi trên lộ trình. Hết thì đi về vạch đích.
## Chỉ chọn lại khi đang đứng trên sàn: lúc đang nhảy, quãng đường tăng theo độ cao nên dễ đổi đích giữa không trung.
func _next_waypoint() -> Vector2:
	if not player.is_on_floor() and _nav_target != Vector2.INF:
		return _nav_target
	_nav_target = _pick_waypoint()
	return _nav_target


func _pick_waypoint() -> Vector2:
	var ps: float = stage.player_s()
	for wp in stage.layout["waypoints"]:
		# Đứng sát điểm rồi thì coi như đã tới: có điểm (gờ vào giếng) mang s lớn hơn s tính từ vị trí đứng
		# ở đó, không bỏ qua thì bot đứng yên tại chỗ.
		if float(wp["s"]) > ps + 12.0 and (wp["pos"] as Vector2).distance_to(player.global_position) > 16.0:
			return wp["pos"]
	var dir: int = stage.layout["goal_dir"]
	return Vector2(float(stage.layout["goal_x"]) + dir * 60.0, float(stage.layout["exit_floor"]) - 2.0)


## Đi tới điểm p: cao hơn thì nhảy lên, thấp hơn thì xuống bệ / bước khỏi mép, cùng độ cao thì chạy tới
## (nhảy qua vực và qua khối chắn đường).
func _move_to(p: Vector2) -> void:
	var pos := player.global_position
	var dx := p.x - pos.x
	var dy := p.y - pos.y
	var dir := signf(dx) if absf(dx) > 6.0 else 0.0
	if dir > 0.0:
		_press("move_right")
	elif dir < 0.0:
		_press("move_left")
	if not player.is_on_floor():
		return
	if dy < -30.0:
		if absf(dx) < 110.0:
			_press("jump")
	elif dy > 30.0:
		if absf(dx) < 40.0 and player._on_platform():
			_press("move_down")
			_press("jump")
	if dir != 0.0 and (player.is_on_wall() or StageBuilder.pit_ahead(stage.layout, pos, dir)) and dy < 30.0:
		_press("jump")


func _use_rage() -> void:
	if player.state != Player.State.NORMAL:
		return
	if player.can_henshin():
		_press("henshin")
		return
	var form := player.current_form
	if form == null:
		return
	var boss := _boss()
	if boss != null and player.can_final() and absf(boss.global_position.x - player.global_position.x) < 60.0:
		_press("final_attack")
		return
	if not player.in_special_form() and form.special_available() and player.rage >= 70.0:
		_press("special")
		return
	if GameState.equipped.size() >= 2 and _secs(frame - _last_swap) > 25.0 and player.swap_cooldown <= 0.0:
		_last_swap = frame
		_press("swap_rider")


## "crouch": đạn cao đang bay tới, hoặc lính gần đó đang tụ đạn cao (ửng đỏ)
## "jump"  : đạn thấp sắp chạm chân
## "hold"  : lính gần đó đang tụ đạn thấp (ửng xanh) hoặc đạn thấp còn xa → đứng chờ, không lao vào
## ""      : an toàn
func _threat() -> String:
	var px := player.global_position.x
	var py := player.global_position.y
	var low_coming := false
	for c in stage.get_node("Enemies").get_children():
		var p := c as Projectile
		if p == null:
			continue
		var dx := p.global_position.x - px
		var rel_y := p.global_position.y - py
		if signf(dx) != -signf(p.velocity.x) or absf(dx) > 130.0 or rel_y < -60.0 or rel_y > 5.0:
			continue
		if rel_y < -24.0:
			return "crouch"
		if absf(dx) < 70.0:
			return "jump"
		low_coming = true
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en == null or en.behavior != "shooter" or en.state != Enemy.State.WINDUP:
			continue
		var dx := px - en.global_position.x
		if absf(dx) < 220.0 and absf(py - en.global_position.y) < 60.0 and signf(dx) == float(en.facing):
			return "hold" if en._shot_low else "crouch"
	return "hold" if low_coming else ""


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and en.state != Enemy.State.DEAD:
			var d := absf(en.global_position.x - player.global_position.x) + absf(en.global_position.y - player.global_position.y) * 0.5
			if d < best_d:
				best_d = d
				best = en
	return best


func _boss() -> Node2D:
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and en.fragment_reward >= 50 and en.state != Enemy.State.DEAD:
			return en
	return null


# --- Tiện ích -----------------------------------------------------------------

func _press(action: String) -> void:
	Input.action_press(action)
	held.append(action)


func _release_all() -> void:
	for a in held:
		Input.action_release(a)
	held.clear()


func _secs(frames: int) -> float:
	return frames / 60.0


func _form_name() -> String:
	if player.current_form == null:
		return "người"
	return "%s/%s" % [player.current_form.rider_id, player.current_form.current_form_id()]


func _world_of(stage_id: String) -> int:
	return int(stage_id.split("-")[0]) - 1


func _finish() -> void:
	set_process(false)
	print("\n[camp] ===== TỔNG KẾT (%.0f giây trong game) =====" % _secs(frame))
	for l in _report:
		print("  " + l)
	var drivers := []
	for id in GameState.drivers:
		var d: Dictionary = GameState.drivers[id]
		drivers.append("%s Lv%d %s%s" % [id, int(d["level"]), "" if d["active"] else "(phong ấn) ", str(d.get("forms", []))])
	print("  Driver: " + ", ".join(drivers))
	print("[camp] %s" % ("TẤT CẢ OK" if _bad_stages == 0 else "%d màn có vấn đề" % _bad_stages))
	get_tree().quit(_bad_stages)
