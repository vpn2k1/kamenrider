extends Node2D
## Test tầm đánh: mọi Rider, mọi form, từng loại đòn thường (đấm từng nhịp, đá, chém từng nhịp, nhát chém cuối, bắn
## thẳng) đánh vào MỘT bia đặt ở nhiều khoảng cách phía trước (tâm tới tâm, px thật), in tầm trúng gần nhất / xa nhất.
## Không cần bấm phím.
##
##   godot --headless --path . --fixed-fps 60 res://tools/reach_test.tscn                 (mọi Rider)
##   godot --headless --path . --fixed-fps 60 res://tools/reach_test.tscn -- kuuga faiz   (chỉ các Rider này)
##
## Dòng có "!!" là đáng ngờ: đòn không trúng ở khoảng cách nào, hoặc đòn cận chiến không với tới chỗ quái thường đứng
## ra đòn (ENEMY_STAND = attack_range quái thường × Units.SCALE): quái đánh được người chơi mà người chơi không đánh lại.

const PLAYER := preload("res://scenes/player/player.tscn")
const ENEMY := preload("res://scenes/enemies/enemy.tscn")
const MELEE_DIST := [6.0, 14.0, 22.0, 30.0, 38.0, 46.0, 56.0, 68.0, 82.0, 100.0]
const SHOT_DIST := [40.0, 120.0, 220.0]
const WAIT := 75              ## khung tối đa cho một đòn
const DUMMY_HP := 100000.0

var player: Player
var dummy: Enemy
var jobs: Array = []          ## [rider, form, kind, chain, dist]
var job := -1
var wait := 0
var hp_before := 0.0
var results := {}             ## "rider/form/kind#chain" -> [các khoảng cách trúng]
var order: Array = []
var enemy_stand := 0.0


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
	player = PLAYER.instantiate()
	add_child(player)
	dummy = ENEMY.instantiate()
	dummy.max_hp = DUMMY_HP
	dummy.scale_stats = false
	dummy.poise = 1.0e9
	add_child(dummy)
	dummy.set_physics_process(false)
	enemy_stand = dummy.attack_range * Units.SCALE
	for world in WorldData.WORLDS:
		var rider: StringName = world["rider"]
		if not only.is_empty() and not only.has(String(rider)):
			continue
		GameState.activate_driver(rider)
		GameState.set_level(rider, 5)
		for form_id in RiderCaps.all_forms(rider):
			_queue(rider, form_id)
	print("[reach] %d lần đánh · quái thường đứng ra đòn cách %.0f px" % [jobs.size(), enemy_stand])


## Xếp việc cho một form (biết số nhịp đấm / chém và có súng hay không thì phải vào form trước).
func _queue(rider: StringName, form_id: StringName) -> void:
	var f := _enter(rider, form_id)
	if f == null:
		return
	var kinds: Array = []
	for c in f.punch_count():
		kinds.append([&"light", c])
	kinds.append([&"kick", 0])
	if f.has_blade():
		for c in f.slash_count():
			kinds.append([&"slash", c])
		kinds.append([&"slash_finish", 0])
	for k in kinds:
		var key := "%s/%s/%s#%d" % [rider, form_id, k[0], k[1]]
		order.append(key)
		results[key] = []
		for dist in MELEE_DIST:
			jobs.append([rider, form_id, k[0], k[1], dist, key])
	if not f.get_shot().is_empty():
		var key := "%s/%s/shoot#0" % [rider, form_id]
		order.append(key)
		results[key] = []
		for dist in SHOT_DIST:
			jobs.append([rider, form_id, &"shoot", 0, dist, key])


func _enter(rider: StringName, form_id: StringName) -> RiderForm:
	GameState.main_rider = rider
	GameState.rebuild_team()
	player._sync_forms()
	var f := player._find_form(rider)
	if f == null:
		return null
	if player.current_form != f:
		player._enter_form(f, true)
	f.set_form(form_id)
	return f


func _physics_process(_delta: float) -> void:
	if wait > 0:
		wait -= 1
		var j: Array = jobs[job]
		var landed := dummy.hp < hp_before
		var idle: bool = player.state == Player.State.NORMAL and j[2] != &"shoot"
		if landed or wait == 0 or (idle and wait < WAIT - 3):
			if landed:
				results[j[5]].append(j[4])
			wait = 0
		return
	job += 1
	if job >= jobs.size():
		_report()
		get_tree().quit()
		return
	_start(jobs[job])


func _start(j: Array) -> void:
	var f := _enter(j[0], j[1])
	if f == null:
		return
	for p in get_tree().get_nodes_in_group(Projectile.GROUP):
		p.queue_free()
	player.global_position = Vector2(0, 0)
	player.velocity = Vector2.ZERO
	player.face(1)
	player.state = Player.State.NORMAL
	player.hitbox.deactivate()
	player.skills.clear(true)
	player._set_rage(100.0)
	player.shoot_cooldown = 0.0
	dummy.global_position = Vector2(float(j[4]), 0)
	dummy.velocity = Vector2.ZERO
	dummy.hp = DUMMY_HP
	dummy.state = Enemy.State.CHASE
	hp_before = dummy.hp
	match j[2]:
		&"light":
			player._light_chain = j[3]
			player.start_attack(&"light")
		&"kick":
			player._light_chain = f.punch_count()
			player.start_attack(&"light")
		&"slash":
			player._slash_chain = j[3]
			player.start_attack(&"slash")
		&"slash_finish":
			player._slash_chain = f.slash_count()
			player.start_attack(&"slash")
		&"shoot":
			player.try_shoot()
	wait = WAIT


func _report() -> void:
	var bad := 0
	for key in order:
		var hits: Array = results[key]
		var shoot: bool = str(key).ends_with("shoot#0")
		var line := ""
		if hits.is_empty():
			line = "!! %-40s KHÔNG TRÚNG ở khoảng cách nào" % key
			bad += 1
		else:
			var lo: float = hits.min()
			var hi: float = hits.max()
			line = "   %-40s trúng %3.0f–%3.0f px" % [key, lo, hi]
			if not shoot and hi < enemy_stand:
				line = "!! %-40s trúng %3.0f–%3.0f px · ngắn hơn chỗ quái đứng ra đòn (%.0f px)" % [key, lo, hi, enemy_stand]
				bad += 1
			elif not shoot and lo > MELEE_DIST[0]:
				line = "!! %-40s trúng %3.0f–%3.0f px · trượt khi quái đứng sát" % [key, lo, hi]
				bad += 1
		print(line)
	print("[reach] xong · %d / %d đòn đáng ngờ" % [bad, order.size()])
