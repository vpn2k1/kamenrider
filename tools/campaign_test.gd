extends Node
## Test cả chiến dịch: bot chơi lần lượt các màn (mặc định 1-1 → 3-B) với luật hiện tại, in báo cáo từng màn.
##
##   godot --headless --path . --fixed-fps 60 res://tools/campaign_test.tscn
##
## (--fixed-fps để chạy nhanh hết mức máy cho phép thay vì theo thời gian thực.)
##
## Chạy một đoạn: CAMP_FROM="4-1" (bắt đầu từ màn đó, có sẵn Driver / cấp / form như khi chơi tới đó) và
## CAMP_TO="6-B" (dừng sau màn đó). tools/run_campaign.sh chạy cả 27 thế giới thành nhiều phần song song.
## Màn EX: CAMP_FROM="1-EX" CAMP_TO="27-EX" chơi lần lượt màn EX của từng thế giới (mỗi lần coi như đã giải cứu thế
## giới đó: có Driver, Lv5, mọi form của thế giới). Bot mang form / item khắc chế quái đặc biệt của màn (RiderCaps),
## gặp quái đặc biệt mà form đang dùng không khắc chế thì đổi form (Special) khi đủ nộ.
##
## Bot: chạy sang phải, đánh quái gần, bắn khi form có súng, nhảy qua vực, đi nhặt vật phẩm rơi,
## cúi khi đạn cao bay tới và nhảy khi đạn thấp bay tới, biến thân khi nộ đầy, đổi form khi đủ nộ,
## tung Final với trùm. Ở màn chọn màn bot chọn màn xa nhất đã mở; chọn Rider của thế giới (đã có thì thôi,
## không thì Rider mới nhất), mang các item đã nhặt. Tới cuối lộ trình mà còn quái thì đi săn nốt (diệt hết mới qua). Máu người xuống thấp thì bot được hồi đầy (ghi là "suýt gục")
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
var _slashes := 0              ## số nhát chém (nút Chém) trong màn
var _was_slashing := false
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
var _hunting := false             ## đã tới vạch đích mà còn quái: săn nốt tới khi hết quái
var _hunt_best := INF            ## khoảng cách gần nhất tới quái đang săn
var _hunt_since := 0
var _hunt_prey: Node2D = null     ## quái đang săn (đổi con thì tính lại từ đầu)
var _prey_since := 0              ## bắt đầu săn con hiện tại (săn quá 20 giây vẫn chưa hạ được thì dịch chuyển)
var _hold := 0                    ## CAMP_SHOW: dừng ở mỗi màn chọn 90 khung hình để quay hình giao diện
var _menu_tested := false         ## CAMP_MENU: bấm Menu một lần giữa màn, phải về màn chọn màn rồi chơi lại được
var _warps := 0                   ## số lần dịch chuyển bot tới quái còn sót (bot không tự dẫn đường ngược được)
var _report: Array[String] = []
var _ex_world := -1               ## chế độ màn EX (CAMP_FROM="N-EX"): chỉ số thế giới của màn EX kế tiếp
var _counter_cache := {}          ## "rider/form" -> RiderCaps.counters
var _fight_target: Node2D = null  ## quái đang đứng đánh và máu của nó lần cuối giảm
var _fight_hp := 0.0
var _fight_since := 0
var _bad_stages := 0

var _seen_enemies := {}
var _seen_shots := {}
var _seen_items := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.use_test_profile()   # tiến trình trống, không đè save thật
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
	var slashing: bool = player.state == Player.State.ATTACK and player._attack_kind in [&"slash", &"slash_finish"]
	if slashing and not _was_slashing:
		_slashes += 1
	_was_slashing = slashing
	# Đang thoại (kể cả 2 khung hình khung thoại đóng lại): bấm qua, chưa tính là xong màn.
	if stage._dialogue.is_open() or stage.phase == stage.Phase.TALK:
		stage._dialogue.advance()
		return
	if stage.phase in [stage.Phase.MAP, stage.Phase.SELECT, stage.Phase.FORMS, stage.Phase.ITEMS] and OS.get_environment("CAMP_SHOW") != "":
		_hold += 1
		if _hold < 90:
			return
		_hold = 0
	if stage.phase == stage.Phase.MAP:
		if _all_done():
			_finish()
		elif stage._stage_select.visible:
			if _ex_world >= 0:
				_pick_ex()
			else:
				stage._stage_select.pick(GameState.frontier_world, GameState.frontier_stage)
		return
	if stage.phase == stage.Phase.SELECT:
		_choose_rider()
		return
	if stage.phase == stage.Phase.FORMS:
		# Mang form nhặt gần nhất (thường mạnh nhất); màn EX: form khắc chế quái đặc biệt (không có thì form gốc,
		# khắc chế bằng item).
		var forms := GameState.owned_forms(GameState.main_rider)
		var pick: Array[StringName] = []
		pick.assign(forms.slice(forms.size() - 1))
		var special: StringName = GameState.current_stage().get("special", &"")
		if special != &"":
			pick.assign(forms.filter(func(f): return _counters(GameState.main_rider, f, special)).slice(0, 1))
		stage._form_select.pick(pick)
		return
	if stage.phase == stage.Phase.ITEMS:
		# Màn EX: item khắc chế đứng đầu (chỉ mang được GameState.MAX_ITEMS món).
		var items: Array[StringName] = GameState.owned_items(GameState.main_rider)
		var special: StringName = GameState.current_stage().get("special", &"")
		if special != &"":
			var first: Array[StringName] = []
			first.assign(items.filter(func(f): return _counters(GameState.main_rider, f, special)))
			for f in items:
				if not first.has(f):
					first.append(f)
			items = first
		stage._item_select.pick(items)
		return
	_track_stage()
	if _all_done():
		_finish()
		return
	_track_nodes()
	if player.hp <= LOW_HP and player.state != Player.State.KO:
		player.hp = player.max_hp
		_near_deaths += 1
	if OS.get_environment("CAMP_MENU") != "" and not _menu_tested and stage.phase == stage.Phase.RUN \
			and _stage_id != "" and _secs(frame - _stage_start) > 5.0:
		_menu_tested = true
		print("[camp] thử Menu giữa màn %s → phải về màn chọn màn" % _stage_id)
		_press("menu")
		_stage_id = ""
		return
	_drive()
	if OS.get_environment("CAMP_DEBUG") != "" and frame % 60 == 0:
		print("   t=%d %s phase=%d x=%d y=%d s=%d/%d cam_s=%d state=%d form=%s hp=%d quái=%d" % [frame / 60, GameState.current_stage()["id"],
			stage.phase, int(player.global_position.x), int(player.global_position.y), int(stage.player_s()), int(stage.layout["length"]), int(stage.cam_s),
			player.state, _form_name(), player.hp, get_tree().get_nodes_in_group("enemies").size()] + " nộ=%d phím=%s chạm=%s" % [int(player.rage), str(held),
			_touching()])
		if stage.phase == stage.Phase.GOAL_FIGHT or _route_done():
			for e in get_tree().get_nodes_in_group("enemies"):
				var en := e as Enemy
				print("      quái %s %s x=%d y=%d state=%d hp=%d" % [en.display_name, en.behavior, int(en.global_position.x), int(en.global_position.y), en.state, int(en.hp)])
	if _stage_id != "" and _secs(frame - _stage_start) > STAGE_TIMEOUT:
		_problems.append("quá %d giây chưa qua màn (phase=%d, x=%d) · quái còn: %s" % [int(STAGE_TIMEOUT), stage.phase,
			int(player.global_position.x), _enemies_note()])
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
				if stages[i]["type"] == WorldData.StageType.CHALLENGE:
					# Các màn chính của thế giới w đã được cấp ở vòng lặp. Có màn đã qua thì StageRun mở màn chọn màn
					# (không vào thẳng màn xa nhất).
					_ex_world = w
					GameState.cleared_stages.append(str(stages[i - 1]["id"]))
					return
				GameState.frontier_world = w
				GameState.frontier_stage = i
				GameState.worlds_cleared = w
				return
			_grant(w, i)
	push_warning("CAMP_FROM: không có màn %s" % stage_id)


## Coi như đã qua màn i của thế giới w: Driver kích hoạt, lên cấp, form của màn đã nhặt, Driver thế giới kế phong ấn.
## Màn EX không thuộc chuỗi tiến trình nên bỏ qua.
func _grant(w: int, i: int) -> void:
	var world: Dictionary = WorldData.WORLDS[w]
	var st: Dictionary = world["stages"][i]
	if st["type"] == WorldData.StageType.CHALLENGE:
		return
	var rider: StringName = world["rider"]
	GameState.activate_driver(rider)
	GameState.set_level(rider, int(st["reward_level"]))
	if st.has("form"):
		GameState.unlock_form(rider, st["form"])
	if st["type"] == WorldData.StageType.BOSS:
		GameState.obtain_driver(world["next_driver"])


## Chế độ EX: cấp mọi màn chính của thế giới (như đã giải cứu) rồi chọn màn EX của nó.
func _pick_ex() -> void:
	var world: Dictionary = WorldData.WORLDS[_ex_world]
	for i in int(world["main_count"]):
		_grant(_ex_world, i)
	GameState.frontier_world = maxi(GameState.frontier_world, _ex_world + 1)
	GameState.frontier_stage = 0
	GameState.worlds_cleared = GameState.frontier_world
	stage._stage_select.pick(_ex_world, int(world["main_count"]))


## Hết việc: qua hết mọi thế giới (chế độ thường) hoặc hết màn EX (chế độ EX).
func _all_done() -> bool:
	if _ex_world >= 0:
		return _ex_world >= WorldData.WORLDS.size()
	return GameState.is_demo_finished()


## Form `form_id` của Rider đang dùng hạ được loại quái đặc biệt `special` không (có lưu đệm).
func _counters(rider: StringName, form_id: StringName, special: StringName) -> bool:
	var key := "%s/%s" % [rider, form_id]
	if not _counter_cache.has(key):
		_counter_cache[key] = RiderCaps.counters(rider, form_id)
	return (_counter_cache[key] as Array).has(special)


# --- Theo dõi ---------------------------------------------------------------

func _track_stage() -> void:
	if stage.phase == stage.Phase.RESULT and _stage_id != "":
		var done_id := _stage_id
		_end_stage("OK")
		_stage_id = ""
		if done_id.ends_with("-EX"):
			_ex_world += 1
		if done_id == OS.get_environment("CAMP_TO"):
			_finish()
	elif stage.phase == stage.Phase.RUN and _stage_id == "" and not _all_done():
		_begin_stage(GameState.current_stage()["id"])


func _begin_stage(id: String) -> void:
	_stage_id = id
	_stage_start = frame
	_kills = 0
	_shots = 0
	_shot_hits = 0
	_breaks = 0
	_slashes = 0
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
	_hunting = false
	_hunt_prey = null
	_warps = 0
	var key: Dictionary = stage._key_item()
	print("[camp] ▶ %s %s · dạng %s · nộ %d · đội hình %s%s%s" % [id, GameState.current_stage()["name"], _form_name(), int(player.rage),
		str(GameState.equipped), (" (" + _chosen_note + ")") if _chosen_note != "" else "",
		(" · cần nhặt: " + str(key["name"])) if not key.is_empty() else ""])
	_chosen_note = ""
	if OS.get_environment("CAMP_DEBUG") != "":
		print("   đích: goal_x=%d goal_s0=%d dir=%d length=%d" % [int(stage.layout["goal_x"]), int(stage.layout["goal_s0"]), int(stage.layout["goal_dir"]), int(stage.layout["length"])])
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
	var item := form != &"" and GameState.is_item(rider, form)
	if form != &"" and not item and not GameState.has_form(rider, form):
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
				or (beat == "key" and (stage_data["type"] == WorldData.StageType.AWAKEN
					or (form != &"" and GameState.has_form(rider, form))))):
			_problems.append("không hiện hội thoại \"%s\"" % beat)
	var world_id: String = WorldData.WORLDS[_world_of(_stage_id)]["id"]
	if stage_data["type"] == WorldData.StageType.BOSS:
		if GameState.seen_story.has("world:" + world_id):
			seen.append("bản đồ")
		else:
			_problems.append("không hiện bản đồ Chuỗi Trái Đất sau trùm")
	var line := "%s %-4s %5.0fs · hạ %2d · vật phẩm %d/%d nhặt · món chính: %s · đạn quái %d (trúng %d) · vỡ giáp %d · hết nộ→gốc %d · suýt gục %d · săn quái sót: dịch chuyển %d · chém %d · thoại: %s" % [
		"✔" if _problems.is_empty() and result == "OK" else "✘", _stage_id, _secs(frame - _stage_start), _kills,
		_items_taken, _items_seen, _key_note, _shots, _shot_hits, _breaks, _reverts, _near_deaths, _warps, _slashes, ", ".join(seen)]
	if item and not GameState.has_form(rider, form):
		line += "\n        (item %s không rơi lần này, chơi lại màn để nhặt)" % form
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
	# Chỉ biến thân ngay khi đồ nhặt là của Rider đang dùng (Driver: khi chưa có Rider nào); không thì chỉ mở khóa.
	# Tín hiệu phát trước khi activate_driver gán Rider chính, nên Driver đầu tiên thấy main_rider còn rỗng.
	var own := rider == GameState.main_rider if form != &"" else GameState.main_rider == &""
	if not own:
		return
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
	# Đứng đánh 5 giây mà quái không mất máu (đòn không với tới, quái đặc biệt chặn đòn): thôi đứng đánh, bước tới sát
	# quái (xuống khỏi thùng, đổi độ cao) như người chơi thật.
	if close and (target != _fight_target or (target as Enemy).hp < _fight_hp - 0.01):
		_fight_target = target
		_fight_hp = (target as Enemy).hp
		_fight_since = frame
	var futile := close and _secs(frame - _fight_since) > 5.0
	if futile:
		_move_to(target.global_position)
		if _secs(frame - _fight_since) > 7.0:
			_fight_since = frame   # thử đánh lại
	elif close and not stalled:
		_stuck_since = frame   # đang đánh: đứng yên không tính là kẹt
		_hunt_since = frame
		var want_dir := "move_right" if target.global_position.x > px else "move_left"
		if (target.global_position.x > px) != (player.facing > 0):
			_press(want_dir)
		elif frame % 10 == 0:
			# Form có kiếm: xen kẽ chuỗi chém (nút Chém) với chuỗi đấm để thử cả hai nút.
			var slash: bool = player.is_action_visible("attack_slash") and (frame / 60) % 2 == 0
			_press("attack_slash" if slash else "attack_light")
	elif stage.phase == stage.Phase.GOAL_FIGHT and target != null:
		_move_to(target.global_position)
	elif target != null and (_hunting or _route_done()):
		if not _hunting:
			_hunting = true
			_hunt_best = INF
			_hunt_since = frame
		var prey := _hunt_target()
		if prey != _hunt_prey:
			_hunt_prey = prey
			_hunt_best = INF
			_hunt_since = frame
			_prey_since = frame
		_move_to(_hunt_point(prey))
		# Bot không tự leo ngược giếng / vòng qua khối được như người: săn 8 giây không tới gần hơn thì dịch chuyển
		# tới cạnh quái (ghi số lần vào báo cáo, không tính là lỗi màn). Gần hơn tính theo lộ trình khi quái ở đoạn
		# khác: quái bị bỏ lại ở đoạn dưới chạy theo ngay dưới chân, đi ngược về giếng thì xa ra trên màn hình.
		_stuck_since = frame
		var dist := _hunt_gap(prey)
		if dist < _hunt_best - 20.0:
			_hunt_best = dist
			_hunt_since = frame
		elif _secs(frame - _hunt_since) > 8.0 or (_secs(frame - _prey_since) > 20.0 and dist > 80.0):
			# Leo ngược giếng tụt: nhảy lên rơi xuống làm khoảng cách theo lộ trình lúc gần lúc xa, nên ngoài "8 giây
			# không gần hơn" còn giới hạn tổng 20 giây cho một con.
			_prey_since = frame
			var to := prey.global_position + Vector2(-24.0 * signf(prey.global_position.x - px), -8.0)
			# Quái (chỉ người chơi bị tường chặn) có thể đi ra sau tường vô hình đầu màn: dịch chuyển vào phía trong
			# tường, không thì bot kẹt ngoài màn. Quái tự đuổi theo vào.
			var wall: Rect2 = stage._start_wall
			if wall.has_area() and to.y > wall.position.y and to.y < wall.end.y:
				if wall.get_center().x > StageBuilder.path_point(stage.layout, 0.0).x:
					to.x = minf(to.x, wall.position.x - 16.0)
				else:
					to.x = maxf(to.x, wall.end.x + 16.0)
			player.global_position = to
			player.velocity = Vector2.ZERO
			# Camera nhảy theo luôn: không thì chỗ mới nằm ngoài khung nhìn cũ, StageRun tính là rơi vực và đưa
			# người chơi về chỗ đứng cũ (dịch chuyển mãi không tới).
			stage.cam_s = StageBuilder.project(stage.layout, player.global_position)
			_warps += 1
			if OS.get_environment("CAMP_DEBUG") != "":
				print("   dịch chuyển tới %s %s" % [(prey as Enemy).display_name, str(prey.global_position.round())])
			_hunt_best = INF
			_hunt_since = frame   # hết đường mà còn quái: lần ngược lộ trình đi săn nốt
	else:
		_move_to(_next_waypoint())
	_press("shoot")
	if target != null and target.global_position.y < py - 30.0 and absf(target.global_position.x - px) < 220.0:
		_press("move_up")

	# 5. Kẹt một chỗ quá lâu (quãng đường không tăng) thì nhảy.
	if stage.phase == stage.Phase.RUN:
		var ps: float = stage.player_s()
		if absf(ps - _stuck_x) > 30.0:
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


## Màn chọn Rider: Rider của thế giới nếu đã có (để nhặt form / item của màn), không thì Rider mới nhất.
func _choose_rider() -> void:
	var options := GameState.selectable_riders()
	var world := GameState.world_rider()
	var pick: StringName = world if options.has(world) else options[options.size() - 1]
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


## Đã tới vạch đích (cùng điều kiện với stage_run._check_player_position) mà còn quái nên chưa qua màn.
func _route_done() -> bool:
	var ps: float = stage.player_s()
	var dir: int = stage.layout["goal_dir"]
	return ps >= float(stage.layout["goal_s0"]) - stage.CAMERA_LEAD \
		and (player.global_position.x - float(stage.layout["goal_x"])) * dir >= -20.0


## Quãng đường s của quái trên lộ trình. Chiếu trên cả lộ trình chứ không chỉ quanh s của người chơi: lộ trình quay
## đầu (24-4 "right, up, left") làm đoạn trước nằm ngay dưới đoạn sau, quái bị bỏ lại ở đó mà chiếu quanh s người chơi
## thì bị nhận nhầm là đang ở cùng đoạn, ngay cạnh.
func _enemy_s(en: Node2D) -> float:
	return StageBuilder.project(stage.layout, en.global_position)


## Quái còn sót cần săn: gần nhất theo lộ trình, không theo khoảng cách trên màn hình.
func _hunt_target() -> Node2D:
	var ps: float = stage.player_s()
	var best: Node2D = null
	var best_d := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and en.state != Enemy.State.DEAD:
			var d := absf(_enemy_s(en) - ps)
			if d < best_d:
				best_d = d
				best = en
	return best


## Còn cách quái bao xa: theo lộ trình khi khác đoạn, đường chim bay khi cùng đoạn.
func _hunt_gap(en: Node2D) -> float:
	var gap := absf(_enemy_s(en) - float(stage.player_s()))
	return gap if gap >= 80.0 else player.global_position.distance_to(en.global_position)


## Đường tới quái còn sót: cùng đoạn thì chạy thẳng tới; quái ở phía sau lộ trình thì lùi lại từng waypoint
## (leo ngược giếng tụt, tụt ngược giếng leo) cho tới đoạn có quái.
func _hunt_point(en: Node2D) -> Vector2:
	var ps: float = stage.player_s()
	var es := _enemy_s(en)
	if absf(es - ps) < 80.0:
		return en.global_position
	var wps: Array = stage.layout["waypoints"]
	if es < ps:
		for i in range(wps.size() - 1, -1, -1):
			# Bỏ qua điểm đang đứng: gờ ra cửa giếng leo mang s nhỏ hơn s tính từ chỗ đứng trên gờ (như _pick_waypoint).
			if float(wps[i]["s"]) < ps - 12.0 and (wps[i]["pos"] as Vector2).distance_to(player.global_position) > 16.0:
				return wps[i]["pos"] if float(wps[i]["s"]) > es - 40.0 else en.global_position
		return en.global_position
	return _pick_waypoint()


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
		elif absf(dx) < 40.0:
			_press("move_right" if player.facing > 0 else "move_left")   # đứng trên khối: bước khỏi mép để xuống
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
	# Màn EX: quái đặc biệt ở gần mà form đang dùng không hạ được → đổi form (vòng Special) tới form khắc chế.
	var special := _special_near()
	if special != &"":
		if _counters(form.rider_id, form.current_form_id(), special):
			return
		if form.special_available() and (player.in_special_form() or player.rage >= 40.0):
			_press("special")
		return
	if not player.in_special_form() and form.special_available() and player.rage >= 70.0:
		_press("special")
		return


## Loại quái đặc biệt (Enemy.SPECIALS) gần nhất trong 260 px. &"" = không có.
func _special_near() -> StringName:
	var best := &""
	var best_d := 260.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en == null or en.state == Enemy.State.DEAD:
			continue
		for t in en.traits:
			var d := en.global_position.distance_to(player.global_position)
			if Enemy.SPECIALS.has(t) and d < best_d:
				best = t
				best_d = d
	return best


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


## CAMP_DEBUG: vật người chơi đang chạm (tên node cha của collider, vị trí).
func _touching() -> String:
	var out: Array[String] = []
	for i in player.get_slide_collision_count():
		var c := player.get_slide_collision(i)
		var n := c.get_collider() as Node
		out.append("%s/%s@%s" % [n.get_parent().name if n and n.get_parent() else "?", n.name if n else "?",
			str(c.get_position().round())])
	return ",".join(out)


func _secs(frames: int) -> float:
	return frames / 60.0


## Quái còn sống: tên, kiểu, vị trí, s trên lộ trình, state (để biết vì sao kẹt).
func _enemies_note() -> String:
	var out: Array[String] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and en.state != Enemy.State.DEAD:
			out.append("%s(%s) %s s=%d state=%d" % [en.display_name, en.behavior, str(en.global_position.round()),
				int(_enemy_s(en)), en.state])
	return ", ".join(out) if not out.is_empty() else "không"


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
