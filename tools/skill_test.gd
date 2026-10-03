extends Node2D
## Bot test skill (docs/SKILLS.md): mọi Rider, mọi form, tung Skill 1, Skill 2, Final vào một hàng bia (quái không
## đánh lại, máu rất nhiều) và in bảng: sát thương gây ra, hiệu ứng thấy được, lỗi. Không cần bấm phím.
##
##   godot --headless --path . res://tools/skill_test.tscn                  (mọi Rider)
##   godot --headless --path . res://tools/skill_test.tscn -- kuuga faiz    (chỉ các Rider này)
##
## Dòng có "!!" là đáng ngờ: skill đánh (không phải buff) mà không gây sát thương, hoặc form thiếu skill.

const PLAYER := preload("res://scenes/player/player.tscn")
const ENEMY := preload("res://scenes/enemies/enemy.tscn")
const WAIT := 110             ## khung chờ mỗi lần tung (đủ cho dấu khoá, trói, trống)
const SETTLE := 40            ## khung nghỉ giữa hai lần tung (đòn trước đánh xong hẳn, không tính lẫn sát thương)
const DUMMY_HP := 100000.0

var player: Player
var jobs: Array = []          ## [rider, form, slot] slot 0/1 = skill, 2 = final
var job := -1
var wait := 0
var settle := 0
var hp_before := 0.0
var lines: Array[String] = []
var problems := 0
var dummies: Array[Enemy] = []


func _ready() -> void:
	GameState.use_test_profile()
	var only := OS.get_cmdline_user_args()
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 40)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0, 20)
	add_child(floor_body)
	for world in WorldData.WORLDS:
		var rider: StringName = world["rider"]
		if not only.is_empty() and not only.has(String(rider)):
			continue
		GameState.activate_driver(rider)
		GameState.set_level(rider, 5)
		for form_id in RiderCaps.all_forms(rider):
			for slot in 3:
				jobs.append([rider, form_id, slot])
	player = PLAYER.instantiate()
	add_child(player)
	player.global_position = Vector2(0, 0)
	print("[skill] %d lần tung" % jobs.size())


func _physics_process(_delta: float) -> void:
	if wait > 0:
		wait -= 1
		if wait == 0:
			_finish_job()
			settle = SETTLE
		return
	if settle > 0:
		settle -= 1
		return
	job += 1
	if job >= jobs.size():
		for l in lines:
			print(l)
		print("[skill] xong · %d dòng đáng ngờ" % problems)
		get_tree().quit()
		return
	_start_job(jobs[job])


func _start_job(j: Array) -> void:
	var rider: StringName = j[0]
	var form_id: StringName = j[1]
	var slot: int = j[2]
	if slot == 0:
		_reset_dummies()
		GameState.main_rider = rider
		GameState.rebuild_team()
		player._sync_forms()
		var f := player._find_form(rider)
		if f == null:
			return
		if player.current_form != f:
			player._enter_form(f, true)
		f.set_form(form_id)
		if f.current_form_id() != form_id:
			lines.append("!! %s/%s: không vào được form" % [rider, form_id])
			problems += 1
	for i in dummies.size():
		if is_instance_valid(dummies[i]):
			dummies[i].global_position = Vector2(55 + i * 40, 0)
			dummies[i].velocity = Vector2.ZERO
	player.global_position = Vector2(0, 0)
	player.velocity = Vector2.ZERO
	player.face(1)
	player.state = Player.State.NORMAL
	player.invincible = false
	player.skills.clear(true)
	player._set_rage(100.0)
	hp_before = _dummy_hp()
	var ok := false
	if slot < 2:
		ok = player.try_skill(slot)
	else:
		player.try_final_attack()
		ok = player.rage < 100.0
	j.append(ok)
	wait = WAIT


func _finish_job() -> void:
	var j: Array = jobs[job]
	var rider: StringName = j[0]
	var form_id: StringName = j[1]
	var slot: int = j[2]
	var f := player.current_form
	var dealt := hp_before - _dummy_hp()
	var desc := ""
	var bad := false
	if slot < 2:
		var list := f.get_skills() if f else []
		if slot >= list.size():
			desc = "THIẾU SKILL"
			bad = true
		else:
			var s: Dictionary = list[slot]
			desc = Skills.describe(s)
			if str(s["type"]) not in ["buff", "counter"] and dealt <= 0.0:
				bad = true
			if not j[3]:
				desc += " (không tung được)"
				bad = true
	else:
		desc = "Final %s %s" % [f.final_attack_name() if f else "?", Skills.mark(f.final_type() if f else "aim", f.final_targets() if f else 0)]
		if dealt <= 0.0 and f and f.final_type() != "counter":
			bad = true
	var status := []
	for e in dummies:
		if e._bound > 0.0:
			status.append("trói")
		if e._burn > 0.0:
			status.append("cháy")
		if e._frozen > 0.0:
			status.append("băng")
		if e._stunned > 0.0:
			status.append("choáng")
	if bad:
		problems += 1
	lines.append("%s %s/%s S%s: %s · gây %d %s" % ["!!" if bad else "  ", rider, form_id, "F" if slot == 2 else str(slot + 1),
		desc, roundi(dealt), ",".join(PackedStringArray(_uniq(status)))])
	# Sau Final ở form tăng tốc thời gian / buff: dọn trạng thái cho lần kế.
	player.skills.clear()
	CombatDirector.set_enemy_time_scale(1.0)


func _uniq(a: Array) -> Array:
	var out := []
	for x in a:
		if not out.has(x):
			out.append(x)
	return out


func _reset_dummies() -> void:
	for e in dummies:
		if is_instance_valid(e):
			e.queue_free()
	dummies.clear()
	for i in 3:
		var e: Enemy = ENEMY.instantiate()
		e.max_hp = DUMMY_HP
		e.scale_with_level = false
		e.attack_damage = 0.0
		e.sight_range = 0.0
		e.poise = 9999.0
		e.move_speed = 0.0
		add_child(e)
		e.global_position = Vector2(55 + i * 40, 0)
		dummies.append(e)


func _dummy_hp() -> float:
	var t := 0.0
	for e in dummies:
		if is_instance_valid(e):
			t += e.hp
	return t
