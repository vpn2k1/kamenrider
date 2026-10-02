extends Node
## Test né đạn quái: đạn cao phải cúi, đạn thấp phải nhảy, Né (Shift) không tránh được đạn.
##
##   godot --headless --path . res://tools/dodge_test.tscn

const STAGE := "res://scenes/levels/stage_run.tscn"

var stage: Node
var player: Player
var failed := 0
var _floor_y := 0.0


func _ready() -> void:
	GameState.use_test_profile()   # tiến trình trống, không đè save thật
	GameState.story_enabled = false   # không để hội thoại đầu màn dừng game giữa các trường hợp
	stage = load(STAGE).instantiate()
	add_child(stage)
	_run()


func _run() -> void:
	await _wait(0.5)
	player = stage.get_node("Player")
	stage.set_physics_process(false)   # dừng camera và thả quái
	player.global_position = Vector2(300, 140)
	await _wait(2.0)
	_floor_y = player.global_position.y   # chân nhân vật đang đứng trên sàn
	await _case("đứng, đạn cao", Enemy.SHOT_HIGH_Y, func(): pass, true)
	await _case("cúi, đạn cao", Enemy.SHOT_HIGH_Y, func(): Input.action_press("move_down"), false)
	await _case("cúi, đạn thấp", Enemy.SHOT_LOW_Y, func(): Input.action_press("move_down"), true)
	await _case("nhảy, đạn thấp", Enemy.SHOT_LOW_Y, func(): player.velocity.y = player.jump_velocity * Units.SCALE, false)
	await _case("né (Shift), đạn cao", Enemy.SHOT_HIGH_Y, func(): player.start_dodge(), true)
	print("[dodge] %s" % ("TẤT CẢ OK" if failed == 0 else "%d trường hợp SAI" % failed))
	get_tree().quit(failed)


func _case(label: String, y_offset: float, setup: Callable, expect_hit: bool) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	player.hp = player.max_hp
	player._grace_timer = 0.0
	setup.call()
	await _wait(0.05)
	var before := player.hp
	var p := Projectile.new()
	p.team = &"enemy"
	p.damage = 10.0
	p.life = 3.0
	p.velocity = Vector2(-270, 0)
	stage.add_child(p)
	p.global_position = Vector2(player.global_position.x + 60.0, _floor_y + y_offset)
	await _wait(0.5)
	var hit := player.hp < before
	if hit != expect_hit:
		failed += 1
	print("[dodge] %s: %s (mong đợi %s) %s" % [label, "TRÚNG" if hit else "trượt",
		"TRÚNG" if expect_hit else "trượt", "OK" if hit == expect_hit else "SAI"])
	Input.action_release("move_down")
	await _wait(0.8)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
