extends CharacterBody2D
class_name Enemy
## Quái cơ bản. Grongi, Orphnoch, Dopant... dùng chung logic này, chỉ khác chỉ số và traits.
## Đuổi theo người chơi, xin "lượt tấn công" từ CombatDirector, ra đòn có báo trước (windup).
##
## traits:
##   &"fast"    : né 75% đòn, trừ khi đòn có tag &"time" hoặc quái đang bị làm chậm (Faiz Axel...)
##   &"armored" : chỉ nhận 40% sát thương, trừ đòn &"heavy" hoặc Final Attack
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
## Lượt tấn công (CombatDirector, tối đa 2 quái đánh cùng lúc): đánh xong nghỉ TOKEN_REST giây mới xin lượt mới,
## lùi ra vòng ngoài, để quái đang chờ được vào đánh (không để 2 con giữ lượt mãi).
##
## Cấp độ: máu +18% và sát thương +15% mỗi cấp (tính từ chỉ số cấp 1 đặt trong Inspector).
## Trùm đặt scale_with_level = false vì chỉ số đã được chỉnh tay trong WorldData.

signal died(enemy: Enemy)
signal damaged(amount: float)
signal evaded

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


func _ready() -> void:
	add_to_group("enemies")
	if scale_with_level:
		max_hp *= 1.0 + HP_PER_LEVEL * (level - 1)
		attack_damage *= 1.0 + DAMAGE_PER_LEVEL * (level - 1)
	hp = max_hp
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
	if not is_on_floor():
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
				_:
					_state_chase()
		State.WINDUP, State.ATTACK, State.RECOVER:
			_state_attack(d)
		State.HURT:
			_state_hurt(d)
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * Units.SCALE * d)
	# Nháy sáng khi sắp ra đòn để người chơi kịp né.
	_flash = maxf(_flash - delta, 0.0)
	var aiming := state == State.WINDUP and behavior == "shooter"
	if _flash > 0.0:
		modulate = Color(2.5, 2.5, 2.5)            # chớp trắng khi trúng đòn
	elif aiming:
		modulate = Color(1.0, 1.4, 1.9) if _shot_low else Color(1.9, 1.1, 1.1)   # xanh = nhảy, đỏ = cúi
	elif state == State.WINDUP:
		modulate = Color(1.6, 1.3, 1.3)            # ửng đỏ báo sắp ra đòn
	else:
		modulate = Color.WHITE
	if aiming:
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
	_timer -= d
	if _timer <= 0.0:
		state = State.CHASE
		_play("idle")


## Được Hurtbox gọi. Trả về true nếu đòn trúng.
func take_hit(info: DamageInfo) -> bool:
	if state == State.DEAD:
		return false
	var slowed: bool = CombatDirector.enemy_time_scale < 1.0
	if traits.has(&"fast") and not info.has_tag(&"time") and not slowed and randf() < FAST_EVADE_CHANCE:
		evaded.emit()
		return false
	var dmg := info.damage
	if traits.has(&"armored") and not (info.has_tag(&"heavy") or info.has_tag(&"final")):
		dmg *= ARMORED_DAMAGE_MULT
	hp -= dmg
	_flash = 0.08
	damaged.emit(dmg)
	queue_redraw()
	if hp <= 0.0:
		_die(info)
		return true
	if dmg >= poise:
		_cancel_attack()
		state = State.HURT
		_timer = 0.35
		velocity = Vector2(info.knockback.x * _knock_dir(info), info.knockback.y) * Units.SCALE
		_play("hurt")
	return true


func _die(info: DamageInfo) -> void:
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
	if state == State.DEAD:
		return
	if state == State.WINDUP and behavior == "shooter":
		var pulse := 1.5 if Engine.get_process_frames() % 10 < 5 else 0.0
		draw_circle(_muzzle(), 3.0 + pulse, SHOT_LOW_COLOR if _shot_low else SHOT_HIGH_COLOR)
	var top := -_sprite_height() - 4.0
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-BAR_WIDTH / 2.0 - 1.0, top - 1.0, BAR_WIDTH + 2.0, 4.0), Color(0.05, 0.04, 0.08))
	draw_rect(Rect2(-BAR_WIDTH / 2.0, top, BAR_WIDTH * ratio, 2.0), Color(0.9, 0.25, 0.25))
	draw_string(ThemeDB.fallback_font, Vector2(-BAR_WIDTH / 2.0, top - 2.0), "Lv%d" % level,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 0.9))


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
			return float(tex.get_height())
	return 30.0 * Units.SCALE


func _play(anim_name: String) -> void:
	if not sprite.visible:
		return
	var full := "%s_%s" % [sprite_prefix, anim_name]
	if sprite.sprite_frames.has_animation(full) and sprite.animation != full:
		sprite.play(full)
