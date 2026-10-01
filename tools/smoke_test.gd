extends Node
## Test khói: bot tự chơi màn cuộn ngang để bắt lỗi khi chạy (không cần bấm phím).
##
##   godot --headless --path . res://tools/smoke_test.tscn
##
## Bot chạy sang phải, giữ nút bắn (chỉ có tác dụng khi form có súng), nhảy khi phía trước là vực,
## đấm khi quái áp sát, thấy vật phẩm rơi thì đi nhặt. Theo mốc thời gian nó thử: nhặt Driver rơi từ quái,
## mở form + đổi form bằng nộ, Final Attack, cạn nộ về form gốc, đổi Rider, nhặt form (biến thân ngay),
## vỡ giáp, biến thân lại, cúi, chạm nút trên màn hình. In tóm tắt ở cuối.
##
## Chế độ quay hình (có cửa sổ): mở sẵn Kuuga để thấy đủ tính năng.
##   godot --path . --always-on-top --fixed-fps 60 --write-movie <thư_mục>/f.png res://tools/smoke_test.tscn -- --showcase

const STAGE := "res://scenes/levels/stage_run.tscn"
const TOTAL_FRAMES := 5400   # 90 giây ở 60 fps

var frame := 0
var stage: Node
var player: Player
var held: Array[String] = []
var log_lines: Array[String] = []
var total_frames := TOTAL_FRAMES
var falls := 0
var _last_y := 0.0
var _seen_items: Array = []


func _ready() -> void:
	# Hội thoại dừng màn chơi (get_tree().paused); bot vẫn chạy để bấm qua thoại.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--showcase" in OS.get_cmdline_user_args():
		total_frames = 2700
		GameState.activate_driver(&"kuuga")
		GameState.set_level(&"kuuga", 4)
		for f in [&"dragon", &"pegasus", &"titan"]:
			GameState.unlock_form(&"kuuga", f)
	stage = load(STAGE).instantiate()
	add_child(stage)
	player = stage.get_node("Player")
	print("[smoke] bắt đầu")


func _process(_delta: float) -> void:
	frame += 1
	if not is_instance_valid(player):
		player = stage.get_node_or_null("Player") as Player
		if player == null:
			return
	_release_all()
	if stage._dialogue.is_open():
		stage._dialogue.advance()
		return
	if stage.phase == stage.Phase.SELECT:
		_log("màn chọn Rider: chọn %s" % GameState.selectable_riders()[0])
		stage._select.pick(GameState.selectable_riders()[0])
		return
	_drive()
	_milestones()
	if player.global_position.y > 320.0 and _last_y <= 320.0:
		falls += 1
	_last_y = player.global_position.y
	if frame % 600 == 0:
		_report()
		if OS.get_environment("SMOKE_DEBUG") != "":
			print("   player y=%d state=%d floor=%s" % [int(player.global_position.y), player.state, player.is_on_floor()])
			for c in stage.get_node("Level").get_children():
				if c is DriverPickup:
					print("   pickup x=%d y=%d monitoring=%s overlaps=%s" % [int(c.global_position.x), int(c.global_position.y),
						c.monitoring, str(c.get_overlapping_bodies().map(func(b): return b.name))])
			for e in get_tree().get_nodes_in_group("enemies"):
				var en := e as Enemy
				print("   quái %s x=%d y=%d state=%d hp=%d beh=%s cam=%d tokens=%s free=%s floor=%s dbg=%s" % [en.display_name,
					int(en.global_position.x), int(en.global_position.y), en.state, int(en.hp), en.behavior, int(stage.cam_s),
					str(CombatDirector._token_holders.map(func(h): return str(h.get("display_name")) + "@" + str(int(h.global_position.x)) if is_instance_valid(h) else "freed")),
					CombatDirector.has_free_token(en), en.is_on_floor(), en.dbg])
	if frame >= total_frames:
		_report()
		print("[smoke] xong sau %d frame · rơi vực %d lần" % [frame, falls])
		for l in log_lines:
			print("  ", l)
		get_tree().quit()


func _press(action: String) -> void:
	Input.action_press(action)
	held.append(action)


func _release_all() -> void:
	for a in held:
		Input.action_release(a)
	held.clear()


func _drive() -> void:
	if frame > 640 and frame < 700:
		_press("move_down")              # giữ cúi/thủ thế
		return
	if frame == 800:
		_touch(Vector2(428, 226), true)  # chạm nút Đánh trên màn hình
	if frame == 806:
		_touch(Vector2(428, 226), false)
	var layout: Dictionary = stage.layout
	var px := player.global_position.x
	# Có Driver rơi ra thì chỉ lo đi nhặt.
	for child in stage.get_node("Level").get_children():
		if child is DriverPickup:
			if not _seen_items.has(child):
				_seen_items.append(child)
				_log("thấy vật phẩm rơi: %s" % (child as DriverPickup).label_text)
			var dx := (child as Node2D).global_position.x - px
			_press("move_right" if dx > 0.0 else "move_left")
			if player.global_position.y < 130.0:
				_press("move_down")
				_press("jump")
			return
	var target := _nearest_enemy()
	var close := target != null and absf(target.global_position.x - px) < 45.0 \
		and absf(target.global_position.y - player.global_position.y) < 40.0
	if close:
		# quay mặt về phía quái rồi đấm
		if frame % 8 == 0:
			_press("attack_light")
		else:
			_press("move_right" if target.global_position.x > px else "move_left")
	else:
		_press("move_right")
	_press("shoot")
	var above := target != null and target.global_position.y < player.global_position.y - 30.0 \
		and absf(target.global_position.x - px) < 200.0
	if above or frame % 240 < 30:
		_press("move_up")                # ngắm lên khi quái đứng trên bệ
	var below := target != null and target.global_position.y > player.global_position.y + 40.0 \
		and absf(target.global_position.x - px) < 160.0
	if below and player.is_on_floor():
		_press("move_down")              # xuống khỏi bệ để đánh quái bên dưới
		if frame % 20 == 0:
			_press("jump")
	elif not layout.is_empty() and player.is_on_floor():
		var pit_ahead := StageBuilder.pit_ahead(layout, player.global_position, 1.0)
		if pit_ahead or frame % 150 == 0:
			_press("jump")
	if player.hp < 40:
		player.hp = player.max_hp        # bot không được gục sớm, để kịp thử hết tính năng


func _milestones() -> void:
	match frame:
		240:
			_log("chưa có Driver: bấm biến thân không có tác dụng (dạng người=%s)" % (player.current_form == null))
			player.add_rage(100.0)
			_press("henshin")
		1000:
			_log("mở Dragon + Pegasus (Kuuga %s) → đổi form bằng nộ" % _form_name())
			if not GameState.is_active(&"kuuga"):
				GameState.activate_driver(&"kuuga")
				player.transform_into(&"kuuga", &"")
			GameState.set_level(&"kuuga", 4)
			GameState.unlock_form(&"kuuga", &"dragon")
			GameState.unlock_form(&"kuuga", &"pegasus")
		1100:
			player.add_rage(100.0)
			_special()
		1180:
			_special()
		1200:
			_log("form hiện tại %s · có súng=%s" % [_form_name(), player.has_gun()])
		1500:
			_log("Final Attack (%s)" % _form_name())
			player.add_rage(100.0)
			player.try_final_attack()
		1800:
			_log("sau Final: nộ=%d · form %s" % [int(player.rage), _form_name()])
		1850:
			player.add_rage(100.0)
			_special()
		1900:
			_log("cạn nộ ở %s" % _form_name())
			_clear_items()
			player.add_rage(-100.0)
		2000:
			_log("→ %s (mong đợi form gốc)" % _form_name())
		2100:
			_log("kích hoạt Faiz + W, đổi Rider")
			GameState.activate_driver(&"faiz")
			GameState.set_level(&"faiz", 4)
			GameState.unlock_form(&"faiz", &"axel")
			GameState.activate_driver(&"double")
			GameState.set_level(&"double", 3)
			GameState.unlock_form(&"double", &"heat_metal")
			GameState.choose_main(&"double")   # đội hình: W (chính) ⇄ Kuuga (Rider của thế giới 1)
			player.use_main_rider()
		2160:
			player.try_swap()
		2440:
			player.add_rage(100.0)
			_special()
		2460:
			_log("đổi form: %s" % _form_name())
		3000:
			_log("ép rơi form W Luna & Trigger trước mặt")
			_clear_items()
			stage._spawn_item({"kind": "form", "rider": &"double", "form": &"luna_trigger", "name": "Memory Luna & Trigger"},
				player.global_position + Vector2(0, -16), 10.0)
		3200:
			_log("sau khi nhặt: %s · nộ=%d" % [_form_name(), int(player.rage)])
		3260:
			_clear_items()
			player.try_final_attack()
			_log("Final ở %s: nộ=%d" % [_form_name(), int(player.rage)])
		3500:
			_log("sau Final: %s (mong đợi form gốc)" % _form_name())
		3560:
			_log("ép vỡ giáp (Henshin Break)")
			if player.current_form:
				player.take_fall_damage(1.0)
		3660:
			_log("sau vỡ giáp: %s · nộ=%d" % [_form_name(), int(player.rage)])
		4200:
			player.add_rage(100.0)
			player.try_henshin()
		4400:
			_log("biến thân lại: %s" % _form_name())


func _clear_items() -> void:
	for child in stage.get_node("Level").get_children():
		if child is DriverPickup:
			child.queue_free()


## Gọi thẳng Special (bot hay đang giữa đòn đấm nên phím L dễ bị bỏ qua).
func _special() -> void:
	if player.current_form:
		player.current_form.special_timer = 0.0
		var before := _form_name()
		player.current_form.try_special()
		_log("Special: %s → %s (nộ %d)" % [before, _form_name(), int(player.rage)])


func _form_name() -> String:
	if player.current_form == null:
		return "người"
	return "%s/%s" % [player.current_form.rider_id, player.current_form.current_form_id()]


func _touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 5
	ev.position = pos
	ev.pressed = pressed
	Input.parse_input_event(ev)
	if pressed:
		_log("chạm nút Đánh trên màn hình")


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and en.state != Enemy.State.DEAD:
			var d := absf(en.global_position.x - player.global_position.x)
			if d < best_d:
				best_d = d
				best = en
	return best


func _report() -> void:
	var form := _form_name()
	var stage_id: String = GameState.current_stage()["id"] if not GameState.is_demo_finished() else "-"
	print("[smoke] f=%d  phase=%d  màn %s  x=%d  dạng=%s  hp=%d  máuRider=%d  nộ=%d  quái=%d  mảnh=%d" % [
		frame, stage.phase, stage_id, int(player.global_position.x), form, player.hp, int(player.rider_hp),
		int(player.rage), get_tree().get_nodes_in_group("enemies").size(), GameState.memory_fragments])


func _log(text: String) -> void:
	log_lines.append("f=%d: %s" % [frame, text])
	print("[smoke] ", text)
