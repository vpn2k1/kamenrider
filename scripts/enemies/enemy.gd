extends CharacterBody2D
class_name Enemy
## Quái cơ bản. Grongi, Orphnoch, Dopant... dùng chung logic này, chỉ khác chỉ số và traits.
## Đuổi theo người chơi, xin "lượt tấn công" từ CombatDirector, ra đòn có báo trước (windup).
##
## traits:
##   &"fast"    : né 75% đòn, trừ khi đòn có tag &"time" hoặc quái đang bị làm chậm (Faiz Axel...)
##   &"armored" : chỉ nhận 40% sát thương, trừ đòn &"heavy" hoặc Final Attack
## Quái đặc biệt (màn EX, xem SPECIALS): MIỄN NHIỄM mọi đòn không mang tag khắc chế, phải mang đúng form vào màn:
##   &"flying"   : bay lượn trên đầu, bổ nhào xuống đánh. Chỉ trúng đạn / đòn bắn xa (&"ranged", form có súng)
##   &"giant"    : to gấp GIANT_SCALE, rất trâu, không bị đẩy lùi. Chỉ form nặng mới xuyên da (&"crush")
##   &"phantom"  : siêu tốc, để bóng mờ. Chỉ trúng khi tăng tốc thời gian (&"time" hoặc quái đang bị làm chậm)
##   &"spectral" : bóng ma trong suốt. Chỉ nhận đòn nguyên tố (&"burn", &"freeze", &"shock")
## Đòn bị chặn: tiếng giáp, quái chớp xám, hiện chữ gợi ý trên đầu, đạn bật ra (DamageInfo.blocked), phát immune_hit.
## Rider ở form gốc vẫn tích BLOCKED_RAGE nộ như đòn trúng thường, để còn nộ vào form khắc chế khi chỉ còn quái đặc biệt.
##
## behavior (kiểu Contra):
##   "melee"   : đuổi theo người chơi, xin lượt rồi đánh cận chiến (mặc định)
##   "runner"  : lao nhanh một hướng (run_dir) từ mép màn hình; tới gần người chơi (ENGAGE_RANGE, cùng độ cao)
##               thì chuyển sang đuổi đánh như "melee", không lướt qua bỏ mặc người chơi. Vướng thùng / bậc khối thì
##               nhảy qua; nhảy rồi vẫn không lên được (tường cao) mới quay đầu.
##   "shooter" : đứng gác trên mặt đất, định kỳ tụ đòn rồi bắn một viên bay NGANG ở một trong hai độ cao:
##               cao (ửng đỏ, đạn đỏ) ngang ngực → người chơi cúi để né
##               thấp (ửng xanh, đạn xanh) sát đất → người chơi nhảy để né
##               Lúc tụ đòn có chấm sáng nhấp nháy đúng độ cao viên đạn sắp bay ra.
##   "flyer"   : (quái &"flying", tự đặt) lượn chếch trên đầu người chơi, xin lượt rồi tụ đòn và bổ nhào xuống,
##               xong bay vọt lên lại. Bay xuyên địa hình (không va chạm), không chịu trọng lực tới khi gục.
## Lượt tấn công (CombatDirector, tối đa 2 quái đánh cùng lúc): đánh xong nghỉ TOKEN_REST giây mới xin lượt mới,
## lùi ra vòng ngoài, để quái đang chờ được vào đánh (không để 2 con giữ lượt mãi).
##
## Cấp độ: máu +18% và sát thương +15% mỗi cấp (tính từ chỉ số cấp 1 đặt trong Inspector).
## Trùm đặt scale_with_level = false vì chỉ số đã được chỉnh tay trong WorldData.

signal died(enemy: Enemy)
signal damaged(amount: float)
signal evaded
signal immune_hit(special: StringName)   ## đòn bị quái đặc biệt chặn (khóa của SPECIALS)

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HURT, DEAD }

const FAST_EVADE_CHANCE := 0.75
const ARMORED_DAMAGE_MULT := 0.4
const HP_PER_LEVEL := 0.18
const DAMAGE_PER_LEVEL := 0.15
const BAR_WIDTH := 30.0
const JUMP_VELOCITY := -330.0  ## cùng sức nhảy với người chơi (đơn vị thiết kế)
const ENGAGE_RANGE := 70.0     ## quái chạy ào tới gần người chơi chừng này (cùng độ cao) thì dừng lại đuổi đánh
const TOKEN_REST := 1.0        ## đánh xong nghỉ chừng này giây mới xin lượt tấn công mới
const WALL_JUMP_WINDOW := 1.2  ## nhảy qua vật chắn mà trong chừng này giây vẫn vướng ở cùng độ cao = tường cao
const SHOT_HIGH_Y := -40.0     ## đạn cao: trúng người đứng (hurtbox cao 50), bay qua người cúi (cao 30)
const SHOT_LOW_Y := -8.0       ## đạn thấp: sát đất, cúi vẫn trúng, phải nhảy
const SHOT_HIGH_COLOR := Color(1.0, 0.3, 0.35)
const SHOT_LOW_COLOR := Color(0.3, 0.85, 1.0)
## Trạng thái do tag của đòn Rider gây ra (DataRider "tags" / "attacks"): &"stun" choáng, &"freeze" đóng băng
## (đứng im, không ra đòn), &"burn" cháy (mất máu theo nhịp), &"shock" điện lan sang quái gần, &"force" đẩy / hút / hất
## theo knockback kể cả khi đòn không làm quái khựng. Trùm chỉ chịu BOSS_STATUS_MULT thời gian và không bị &"force".
const STUN_TIME := 1.2
const FREEZE_TIME := 1.5
const BURN_TIME := 2.0
const BURN_TICK := 0.5
const BURN_RATIO := 0.15        ## mỗi nhịp cháy mất chừng này sát thương của đòn gây cháy
const SHOCK_RANGE := 70.0
const SHOCK_TARGETS := 2
const SHOCK_RATIO := 0.4
const BOSS_STATUS_MULT := 0.4
## Quái đặc biệt: tag khắc chế ("needs", đòn có ít nhất một tag mới gây sát thương), chữ hiện trên đầu khi bị đánh sai
## cách ("hint"), tên khả năng cần mang theo ("need", màn chọn màn) và câu giải thích ("how", banner trong màn).
const SPECIALS := {
	&"flying": {"needs": [&"ranged"], "hint": "CẦN SÚNG!", "need": "Súng (bắn xa)",
		"how": "Quái bay chỉ trúng ĐẠN: dùng form có súng, giữ ↑ để bắn lên"},
	&"giant": {"needs": [&"crush"], "hint": "ĐÒN NẶNG!", "need": "Form nặng",
		"how": "Quái khổng lồ chỉ thủng bởi FORM NẶNG (Titan, Ax, Dogga, Metal...)"},
	&"phantom": {"needs": [&"time"], "hint": "QUÁ NHANH!", "need": "Tăng tốc thời gian",
		"how": "Quái siêu tốc chỉ trúng khi TĂNG TỐC THỜI GIAN (Axel, Clock Up...)"},
	&"spectral": {"needs": [&"burn", &"freeze", &"shock"], "hint": "NGUYÊN TỐ!", "need": "Đòn lửa / băng / điện",
		"how": "Bóng ma chỉ nhận đòn NGUYÊN TỐ: lửa, băng hoặc điện"},
}
const GIANT_SCALE := 1.6
const FLY_HEIGHT := 78.0        ## quái bay lượn cao hơn chân người chơi chừng này (px)
const FLY_SIDE := 46.0          ## và chếch sang một bên chừng này
const DIVE_SPEED := 240.0
const DIVE_TIME := 0.6
const SPECTRAL_ALPHA := 0.5
const BLOCKED_RAGE := 0.5         ## đòn bị chặn cho chừng này phần nộ so với đòn trúng
const GHOST_EVERY := 0.07       ## quái siêu tốc để bóng mờ mỗi chừng này giây khi đang chạy

@export var display_name := "Grongi"
## Tiền tố animation trong enemy_frames.tres, ví dụ "grongi_zu" → "grongi_zu_run". Để trống = hiện hình tạm.
@export var sprite_prefix := ""
@export var behavior := "melee"
@export var run_dir := -1
@export var shoot_interval := 2.2
@export var shot_windup := 0.6       ## tụ đòn trước khi bắn, đủ lâu để đọc được độ cao
@export var shot_speed := 150.0
@export var shot_range := 300.0
@export var level := 1
@export var scale_with_level := true
@export var max_hp := 30.0
@export var move_speed := 55.0
@export var sight_range := 180.0
@export var attack_range := 24.0
@export var attack_damage := 8.0
@export var attack_size := Vector2(20, 14)
@export var attack_offset := Vector2(14, -12)
@export var attack_knockback := Vector2(120, -60)
@export var windup_time := 0.45
@export var active_time := 0.12
@export var recover_time := 0.6
@export var poise := 6.0              ## sát thương nhỏ hơn mức này không làm quái khựng
@export var traits: Array[StringName] = []
@export var fragment_reward := 5
@export var fall_limit := 420.0      ## rơi xuống quá độ cao này thì biến mất (màn chơi đặt theo đáy bố cục)
@export var is_boss := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

var state := State.IDLE
var hp := 0.0
var facing := -1

var _timer := 0.0
var _flash := 0.0
var _shot_low := false
var _player: Node2D = null
var _token_rest := 0.0
var _wall_jump_timer := 0.0
var _wall_jump_y := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _frozen := 0.0
var _stunned := 0.0
var _burn := 0.0
var _burn_tick := 0.0
var _burn_damage := 0.0
var _immune_time := 0.0
var _immune_hint := ""
var _ghost_timer := 0.0
var _bob_phase := randf() * TAU
var _dive_target := Vector2.ZERO


func _ready() -> void:
	add_to_group("enemies")
	if scale_with_level:
		max_hp *= 1.0 + HP_PER_LEVEL * (level - 1)
		attack_damage *= 1.0 + DAMAGE_PER_LEVEL * (level - 1)
	hp = max_hp
	if traits.has(&"giant"):
		_make_giant()
	if traits.has(&"flying"):
		behavior = "flyer"
		collision_mask = 0   # bay xuyên thùng, tường, sàn
	elif behavior == "shooter" and (traits.has(&"giant") or traits.has(&"phantom")):
		behavior = "melee"   # khổng lồ chắn kín bệ giếng hẹp, siêu tốc đứng gác thì phí tốc độ: đuổi đánh
	_setup_sprite()
	queue_redraw()
	hitbox.team = &"enemy"
	hurtbox.team = &"enemy"
	if behavior != "melee":
		state = State.CHASE
		facing = run_dir
		_timer = randf_range(0.5, shoot_interval)


func _physics_process(delta: float) -> void:
	var ts: float = CombatDirector.enemy_time_scale
	var d := delta * ts
	sprite.speed_scale = ts   # Clock Up / Axel: cả cử động của quái cũng chậm lại, không chỉ bước đi
	_token_rest = maxf(_token_rest - d, 0.0)
	_wall_jump_timer = maxf(_wall_jump_timer - d, 0.0)
	var flying := behavior == "flyer" and state != State.DEAD
	if not is_on_floor() and not flying:
		velocity.y += _gravity * d
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	match state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			match behavior:
				"runner":
					_state_run()
				"shooter":
					_state_shooter(d)
				"flyer":
					_state_flyer(d)
				_:
					_state_chase()
		State.WINDUP, State.ATTACK, State.RECOVER:
			if behavior == "flyer":
				_state_dive(d)
			else:
				_state_attack(d)
		State.HURT:
			_state_hurt(d)
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * Units.SCALE * d)
	_update_status(d)
	# Nháy sáng khi sắp ra đòn để người chơi kịp né.
	_flash = maxf(_flash - delta, 0.0)
	_immune_time = maxf(_immune_time - delta, 0.0)
	var aiming := state == State.WINDUP and behavior == "shooter"
	if _immune_time > 0.9:
		modulate = Color(0.45, 0.45, 0.55)         # đòn bị chặn: chớp xám
	elif _flash > 0.0:
		modulate = Color(2.5, 2.5, 2.5)            # chớp trắng khi trúng đòn
	elif _frozen > 0.0:
		modulate = Color(0.6, 1.3, 2.0)            # đóng băng: xanh băng
	elif _stunned > 0.0:
		modulate = Color(1.8, 1.7, 0.6) if Engine.get_process_frames() % 12 < 6 else Color.WHITE   # choáng: nháy vàng
	elif _burn > 0.0:
		modulate = Color(2.0, 1.1, 0.5) if Engine.get_process_frames() % 8 < 4 else Color(1.4, 1.0, 0.8)   # cháy
	elif aiming:
		modulate = Color(1.0, 1.4, 1.9) if _shot_low else Color(1.9, 1.1, 1.1)   # xanh = nhảy, đỏ = cúi
	elif state == State.WINDUP:
		modulate = Color(1.6, 1.3, 1.3)            # ửng đỏ báo sắp ra đòn
	else:
		modulate = Color.WHITE
	if traits.has(&"spectral") and state != State.DEAD:
		modulate.a = SPECTRAL_ALPHA + 0.15 * sin(float(Time.get_ticks_msec()) * 0.005 + _bob_phase)
	_trail(d)
	if aiming or behavior == "flyer" or _immune_time > 0.0:
		queue_redraw()
	# Nhân vận tốc với time scale: Faiz Axel / Clock Up làm quái chậm mà không ảnh hưởng người chơi.
	velocity *= ts
	move_and_slide()
	if ts > 0.0:
		velocity /= ts
	if global_position.y > fall_limit:
		CombatDirector.release_attack_token(self)
		queue_free()


func _state_run() -> void:
	if is_on_wall() and is_on_floor():
		_hop_or_turn()
	facing = run_dir
	sprite.flip_h = facing < 0
	velocity.x = run_dir * move_speed * 1.6 * Units.SCALE
	_play("run")
	if _player == null:
		return
	# Lao tới gần người chơi (cùng độ cao) thì thôi chạy thẳng, chuyển sang đuổi đánh như quái cận chiến.
	var dx := _player.global_position.x - global_position.x
	if absf(dx) <= ENGAGE_RANGE * Units.SCALE and absf(_player.global_position.y - global_position.y) < 40.0:
		behavior = "melee"
		_state_chase()


## Vướng vật chắn khi đang đứng trên sàn: nhảy qua (thùng, bậc khối). Vừa nhảy mà vẫn vướng ở cùng độ cao
## (tường cao hơn sức nhảy) thì quay đầu.
func _hop_or_turn() -> void:
	if _wall_jump_timer > 0.0 and absf(global_position.y - _wall_jump_y) < 4.0:
		run_dir = -run_dir
		_wall_jump_timer = 0.0
		return
	velocity.y = JUMP_VELOCITY * Units.SCALE
	_wall_jump_timer = WALL_JUMP_WINDOW
	_wall_jump_y = global_position.y


func _state_shooter(d: float) -> void:
	velocity.x = 0.0
	_play("idle")
	if _player == null:
		return
	var dx := _player.global_position.x - global_position.x
	facing = 1 if dx > 0.0 else -1
	sprite.flip_h = facing < 0
	_timer -= d
	# Đạn bay ngang nên chỉ bắn khi người chơi ở gần cùng độ cao.
	var same_level := absf(_player.global_position.y - global_position.y) < 60.0
	if _timer <= 0.0 and absf(dx) <= shot_range * Units.SCALE and same_level:
		state = State.WINDUP
		_timer = shot_windup
		_shot_low = randf() < 0.5
		_play("windup")


func _muzzle() -> Vector2:
	return Vector2(facing * 16.0, SHOT_LOW_Y if _shot_low else SHOT_HIGH_Y)


func _fire() -> void:
	Sound.sfx("enemy_shot", 0.1, -6.0)
	var p := Projectile.new()
	p.team = &"enemy"
	p.damage = attack_damage * 0.8
	p.color = SHOT_LOW_COLOR if _shot_low else SHOT_HIGH_COLOR
	p.radius = 3.0
	p.life = shot_range / shot_speed + 0.5
	p.source = self
	p.velocity = Vector2(facing * shot_speed * Units.SCALE, 0.0)
	get_parent().add_child(p)
	p.global_position = global_position + _muzzle()
	queue_redraw()


func _state_idle() -> void:
	velocity.x = 0.0
	_play("idle")
	if _player and absf(_player.global_position.x - global_position.x) <= sight_range * Units.SCALE:
		state = State.CHASE


func _state_chase() -> void:
	if _player == null:
		state = State.IDLE
		return
	var dx := _player.global_position.x - global_position.x
	var dist := absf(dx)
	facing = 1 if dx > 0.0 else -1
	sprite.flip_h = facing < 0
	if dist > sight_range * 1.5 * Units.SCALE:
		state = State.IDLE
		return
	var dy := _player.global_position.y - global_position.y
	# Người chơi ĐỨNG ở dưới: nhảy xuống khỏi bệ. Đứng ở trên: nhảy lên bệ (như lính Contra).
	# Người chơi đang giữa cú nhảy thì không tính, nếu không quái sẽ nhảy theo mỗi lần người chơi nhảy.
	var player_body := _player as CharacterBody2D
	var player_standing := player_body == null or player_body.is_on_floor()
	if dy > 30.0 and is_on_floor() and dist < 160.0 and player_standing:
		_drop_through()
	elif dy < -40.0 and is_on_floor() and dist < 90.0 and player_standing:
		velocity.y = JUMP_VELOCITY * Units.SCALE
		velocity.x = facing * move_speed * Units.SCALE
	var can_attack: bool = _token_rest <= 0.0 and CombatDirector.has_free_token(self)
	var reach := attack_range * Units.SCALE
	var same_height := absf(dy) < 40.0
	if dist <= reach and same_height and can_attack and CombatDirector.request_attack_token(self):
		_start_windup()
		return
	# Chưa tới lượt thì đứng vòng ngoài chờ, không xúm lại.
	var want := reach if can_attack else reach * 3.0
	var speed := move_speed * Units.SCALE
	if dist > want:
		velocity.x = facing * speed
		_play("run")
		# Vướng thùng / bậc khối thì nhảy qua.
		if is_on_wall() and is_on_floor():
			velocity.y = JUMP_VELOCITY * Units.SCALE
	elif dist < want * 0.6:
		velocity.x = -facing * speed * 0.5
		_play("run")
	else:
		velocity.x = 0.0
		_play("idle")


func _drop_through() -> void:
	if not get_collision_mask_value(5):
		return
	set_collision_mask_value(5, false)
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		if is_instance_valid(self):
			set_collision_mask_value(5, true))


func _start_windup() -> void:
	state = State.WINDUP
	_timer = windup_time
	velocity.x = 0.0
	_play("windup")


func _state_attack(d: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * Units.SCALE * d)
	_timer -= d
	if _timer > 0.0:
		return
	match state:
		State.WINDUP:
			if behavior == "shooter":
				_fire()
				_play("attack")
				state = State.RECOVER
				_timer = 0.35
				return
			state = State.ATTACK
			_timer = active_time
			hitbox.activate(DamageInfo.new(attack_damage, attack_knockback, facing, [], self), attack_size, attack_offset)
			_play("attack")
		State.ATTACK:
			hitbox.deactivate()
			state = State.RECOVER
			_timer = recover_time
		State.RECOVER:
			CombatDirector.release_attack_token(self)
			_token_rest = TOKEN_REST
			state = State.CHASE
			if behavior == "shooter":
				_timer = shoot_interval


func _state_hurt(d: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * Units.SCALE * d)
	if behavior == "flyer":
		velocity.y = move_toward(velocity.y, 0.0, 500.0 * Units.SCALE * d)
	_timer -= d
	if _timer <= 0.0 and _frozen <= 0.0 and _stunned <= 0.0:
		state = State.CHASE
		_play("idle")


## Được Hurtbox gọi. Trả về true nếu đòn trúng.
func take_hit(info: DamageInfo) -> bool:
	if state == State.DEAD:
		return false
	var slowed: bool = CombatDirector.enemy_time_scale < 1.0
	var special := unmet_special(info, slowed)
	if special != &"":
		_block(info, special)
		return false
	if traits.has(&"fast") and not info.has_tag(&"time") and not slowed and randf() < FAST_EVADE_CHANCE:
		evaded.emit()
		return false
	var dmg := info.damage
	if traits.has(&"armored") and not (info.has_tag(&"heavy") or info.has_tag(&"final")):
		dmg *= ARMORED_DAMAGE_MULT
		Sound.sfx("hit_guard", 0.05, -4.0)   # giáp đỡ đòn: tiếng kim loại
	hp -= dmg
	_flash = 0.08
	damaged.emit(dmg)
	queue_redraw()
	if hp <= 0.0:
		_die(info)
		return true
	var forced := info.has_tag(&"force") and not _is_tough()
	if dmg >= poise or forced:
		_cancel_attack()
		_timer = maxf(_timer, 0.35) if state == State.HURT else 0.35   # không cắt ngắn choáng / đóng băng
		state = State.HURT
		velocity = Vector2(info.knockback.x * _knock_dir(info), info.knockback.y) * Units.SCALE
		_play("hurt")
	_apply_status(info)
	return true


## Trùm và quái khổng lồ: không bị &"force" đẩy, choáng / đóng băng ngắn hơn.
func _is_tough() -> bool:
	return is_boss or traits.has(&"giant")


## Đặc tính quái đặc biệt (khóa của SPECIALS) mà đòn KHÔNG khắc chế được. &"" = đòn gây sát thương bình thường.
func unmet_special(info: DamageInfo, slowed := false) -> StringName:
	for t in traits:
		if not SPECIALS.has(t):
			continue
		if t == &"phantom" and slowed:
			continue
		var needs: Array = SPECIALS[t]["needs"]
		if not needs.any(func(tag): return info.has_tag(tag)):
			return t
	return &""


## Đòn bị chặn: tiếng giáp, chớp xám, chữ gợi ý trên đầu, đạn bật ra.
func _block(info: DamageInfo, special: StringName) -> void:
	info.blocked = true
	if _immune_time < 0.8:
		Sound.sfx("hit_guard", 0.05, -4.0)
	_immune_time = 1.0
	_immune_hint = str(SPECIALS[special]["hint"])
	var rider := info.source as Player
	if rider and rider.current_form and not rider.in_special_form():
		rider.add_rage(info.damage * Player.RAGE_ON_DEAL * BLOCKED_RAGE * (0.5 if info.has_tag(&"ranged") else 1.0))
	immune_hit.emit(special)
	queue_redraw()


## Quái khổng lồ: phóng to hình, thân, vùng nhận đòn và đòn đánh (shape trong scene dùng chung nên nhân bản trước khi sửa).
func _make_giant() -> void:
	for path in ["CollisionShape2D", "Hurtbox/CollisionShape2D"]:
		var cs := get_node(path) as CollisionShape2D
		var shape := (cs.shape as RectangleShape2D).duplicate() as RectangleShape2D
		shape.size *= GIANT_SCALE
		cs.shape = shape
		cs.position *= GIANT_SCALE
	($Placeholder as Node2D).scale = Vector2.ONE * GIANT_SCALE
	sprite.scale = Vector2.ONE * GIANT_SCALE
	attack_size *= GIANT_SCALE
	attack_offset *= GIANT_SCALE
	attack_range *= GIANT_SCALE


## Quái siêu tốc để bóng mờ khi đang di chuyển.
func _trail(d: float) -> void:
	if not traits.has(&"phantom") or not sprite.visible or state == State.DEAD or absf(velocity.x) < 20.0:
		return
	_ghost_timer -= d
	if _ghost_timer <= 0.0:
		_ghost_timer = GHOST_EVERY
		Fx.ghost(get_parent(), sprite, Color(0.8, 0.5, 1.0))


## Quái bay: lượn chếch trên đầu người chơi, bồng bềnh lên xuống; tới lượt (CombatDirector) thì tụ đòn rồi bổ nhào.
func _state_flyer(d: float) -> void:
	_play("run")
	if _player == null:
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * Units.SCALE * d)
		return
	var side := 1.0 if global_position.x >= _player.global_position.x else -1.0
	var bob := sin(float(Time.get_ticks_msec()) * 0.004 + _bob_phase) * 6.0
	var to := _player.global_position + Vector2(side * FLY_SIDE, -FLY_HEIGHT + bob) - global_position
	var speed := move_speed * 1.5 * Units.SCALE
	var want := to.normalized() * speed * clampf(to.length() / 40.0, 0.0, 1.0)
	velocity = velocity.lerp(want, clampf(5.0 * d, 0.0, 1.0))
	facing = -1 if side > 0.0 else 1
	sprite.flip_h = facing < 0
	_timer -= d
	if _timer <= 0.0 and to.length() < 60.0 and _token_rest <= 0.0 and CombatDirector.request_attack_token(self):
		state = State.WINDUP
		_timer = windup_time + 0.25
		_play("windup")


## Bổ nhào: tụ đòn (đứng khựng trên không) → lao thẳng tới chỗ người chơi đang đứng, dừng lại ngang chân người chơi →
## bay vọt lên, nghỉ rồi về lượn.
func _state_dive(d: float) -> void:
	_timer -= d
	match state:
		State.WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * Units.SCALE * d)
			if _timer > 0.0:
				return
			var aim := global_position + Vector2(facing * 40.0, 70.0)
			if _player:
				aim = _player.global_position + Vector2(0.0, -8.0)
			_dive_target = aim
			velocity = (aim - global_position).normalized() * DIVE_SPEED * Units.SCALE
			state = State.ATTACK
			_timer = DIVE_TIME
			hitbox.activate(DamageInfo.new(attack_damage, attack_knockback, facing, [], self), attack_size,
				Vector2(0.0, -20.0))
			_play("attack")
		State.ATTACK:
			if _timer <= 0.0 or velocity.dot(_dive_target - global_position) <= 0.0:
				hitbox.deactivate()
				state = State.RECOVER
				_timer = 0.6
				velocity = Vector2(velocity.x * 0.3, -DIVE_SPEED * 0.6 * Units.SCALE)
		State.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * Units.SCALE * d)
			if _timer <= 0.0:
				CombatDirector.release_attack_token(self)
				_token_rest = TOKEN_REST
				state = State.CHASE
				_timer = shoot_interval


## Hiệu ứng theo tag của đòn (xem STUN_TIME...). Gọi sau khi đã trừ máu, quái còn sống.
func _apply_status(info: DamageInfo) -> void:
	var mult := BOSS_STATUS_MULT if _is_tough() else 1.0
	if info.has_tag(&"freeze"):
		_hold(FREEZE_TIME * mult)
		_frozen = maxf(_frozen, FREEZE_TIME * mult)
	if info.has_tag(&"stun"):
		_hold(STUN_TIME * mult)
		_stunned = maxf(_stunned, STUN_TIME * mult)
	if info.has_tag(&"burn"):
		_burn = BURN_TIME * (1.0 if mult == 1.0 else 0.75)
		_burn_damage = maxf(_burn_damage if _burn_tick > 0.0 else 0.0, maxf(info.damage * BURN_RATIO, 1.0))
		_burn_tick = BURN_TICK
	if info.has_tag(&"shock"):
		_chain_shock(info)


## Choáng / đóng băng: dừng mọi đòn, đứng tại chỗ tới khi hết.
func _hold(duration: float) -> void:
	_cancel_attack()
	state = State.HURT
	_timer = maxf(_timer, duration)
	velocity.x = 0.0
	_play("hurt")


## Điện lan: tối đa SHOCK_TARGETS quái gần nhất trong SHOCK_RANGE trúng SHOCK_RATIO sát thương (không lan tiếp).
func _chain_shock(info: DamageInfo) -> void:
	var near: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e) or (e as Enemy).state == State.DEAD:
			continue
		var dist := (e as Node2D).global_position.distance_to(global_position)
		if dist <= SHOCK_RANGE * Units.SCALE:
			near.append([dist, e])
	near.sort_custom(func(a, b): return a[0] < b[0])
	for pair in near.slice(0, SHOCK_TARGETS):
		var target: Enemy = pair[1]
		Fx.spawn(get_parent(), target.global_position + Vector2(0, -20) * Units.SCALE, "lightning", Color(0.6, 0.9, 1.0))
		target.take_hit(DamageInfo.new(info.damage * SHOCK_RATIO, Vector2(30, -20), info.direction, [], info.source))


func _update_status(d: float) -> void:
	_frozen = maxf(_frozen - d, 0.0)
	_stunned = maxf(_stunned - d, 0.0)
	sprite.speed_scale = 0.0 if _frozen > 0.0 else sprite.speed_scale
	if _burn <= 0.0 or state == State.DEAD:
		return
	_burn -= d
	_burn_tick -= d
	if _burn_tick <= 0.0:
		_burn_tick = BURN_TICK
		hp -= _burn_damage
		damaged.emit(_burn_damage)
		if hp <= 0.0:
			_die(DamageInfo.new(_burn_damage, Vector2(20, -40), 1, [], null))


func _die(info: DamageInfo) -> void:
	Sound.sfx("enemy_die", 0.1, -2.0)
	_cancel_attack()
	state = State.DEAD
	queue_redraw()
	hurtbox.set_deferred("monitorable", false)
	velocity = Vector2(info.knockback.x * _knock_dir(info) * 1.5, -120.0) * Units.SCALE
	_play("die")
	GameState.add_fragments(fragment_reward)
	died.emit(self)
	await get_tree().create_timer(0.8).timeout
	queue_free()


func _cancel_attack() -> void:
	hitbox.deactivate()
	CombatDirector.release_attack_token(self)


func _knock_dir(info: DamageInfo) -> int:
	if is_instance_valid(info.source) and info.source is Node2D:
		var src := info.source as Node2D
		return 1 if global_position.x >= src.global_position.x else -1
	return info.direction


## Thanh máu nhỏ và cấp độ trên đầu quái.
func _draw() -> void:
	# Bóng đổ hình bầu dục dưới chân (vẽ trước nên nằm dưới sprite).
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, _sprite_height() * 0.28, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if behavior == "flyer" and state != State.DEAD:
		_draw_wings()
	if state == State.DEAD:
		return
	if state == State.WINDUP and behavior == "shooter":
		var pulse := 1.5 if Engine.get_process_frames() % 10 < 5 else 0.0
		draw_circle(_muzzle(), 3.0 + pulse, SHOT_LOW_COLOR if _shot_low else SHOT_HIGH_COLOR)
	var top := -_sprite_height() - 4.0
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	var bw := BAR_WIDTH * (GIANT_SCALE if traits.has(&"giant") else 1.0)
	draw_rect(Rect2(-bw / 2.0 - 1.0, top - 1.0, bw + 2.0, 4.0), Color(0.05, 0.04, 0.08))
	draw_rect(Rect2(-bw / 2.0, top, bw * ratio, 2.0), Color(0.9, 0.25, 0.25))
	draw_string(ThemeDB.fallback_font, Vector2(-bw / 2.0, top - 2.0), "Lv%d" % level,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 0.9))
	if _immune_time > 0.0:
		# Đánh sai cách: chữ gợi ý nảy lên trên đầu (CẦN SÚNG!...), nhạt dần.
		var font := ThemeDB.fallback_font
		var w := font.get_string_size(_immune_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var y := top - 10.0 - (1.0 - _immune_time) * 8.0
		var c := Color(1.0, 0.85, 0.3, clampf(_immune_time * 1.5, 0.0, 1.0))
		draw_string_outline(font, Vector2(-w / 2.0, y), _immune_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3,
			Color(0, 0, 0, c.a))
		draw_string(font, Vector2(-w / 2.0, y), _immune_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, c)


## Đôi cánh vỗ sau lưng quái bay (vẽ trước sprite nên nằm phía sau).
func _draw_wings() -> void:
	var flap := sin(float(Time.get_ticks_msec()) * 0.025) * 7.0
	var y := -_sprite_height() * 0.62
	for s in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(s * 3.0, y), Vector2(s * 26.0, y - 12.0 + flap),
			Vector2(s * 22.0, y + 2.0 + flap * 0.5), Vector2(s * 10.0, y + 8.0)])
		draw_colored_polygon(pts, Color(0.85, 0.92, 1.0, 0.8))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.3, 0.4, 0.6, 0.9), 1.0)


## Có sprite thì hiện sprite (chân chạm gốc tọa độ), không thì hiện hình tạm Placeholder.
func _setup_sprite() -> void:
	var has_art := sprite.sprite_frames != null and sprite_prefix != "" \
		and sprite.sprite_frames.has_animation(sprite_prefix + "_idle")
	sprite.visible = has_art
	($Placeholder as CanvasItem).visible = not has_art
	if has_art:
		sprite.position = Vector2(0, -_sprite_height() / 2.0)
		_play("idle")


func _sprite_height() -> float:
	if sprite.visible and sprite.sprite_frames:
		var tex := sprite.sprite_frames.get_frame_texture(sprite_prefix + "_idle", 0)
		if tex:
			return float(tex.get_height()) * sprite.scale.y
	return 30.0 * Units.SCALE * ($Placeholder as Node2D).scale.y


func _play(anim_name: String) -> void:
	if not sprite.visible:
		return
	var full := "%s_%s" % [sprite_prefix, anim_name]
	if sprite.sprite_frames.has_animation(full) and sprite.animation != full:
		sprite.play(full)
