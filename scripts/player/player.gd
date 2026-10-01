extends CharacterBody2D
class_name Player
## Nhân vật chính (Amane Sora): dạng người + biến thân thành các Rider đã trang bị.
##
## Mỗi dạng (người / từng form Rider) có chỉ số riêng: máu, giáp, tốc độ, sát thương.
## Máu người và máu Rider tách riêng. Ở dạng Rider chỉ mất máu Rider; máu Rider về 0 thì
## "Henshin Break": về dạng người, máu người còn nguyên. Máu người về 0 thì thua.
##
## Đánh (J / nút Đánh): chuỗi đấm rồi tự ra cú ĐÁ kết thúc (sát thương cao hơn, đẩy xa, tag &"heavy" phá giáp).
##   Số đòn trước cú đá: RiderForm.punch_count() (dạng người HUMAN_PUNCHES). Bấm tiếp trong lúc đang đánh để nối chuỗi;
##   ngừng bấm thì chuỗi về đầu. Form bắn xa (Pegasus, Trigger): 2 phát bắn rồi 1 phát nạp mạnh.
## Thanh tài nguyên: MÁU · NỘ
##   Nộ: tích khi đánh trúng và khi bị đánh.
##       Dạng người: nộ đầy thì biến thân (I) vào form gốc của Rider ở ô đầu (không mất nộ).
##       Dạng Rider: nộ là nhiên liệu của form đặc biệt. Đổi form (L) cần ≥ FORM_ENTER_MIN_RAGE
##           và tốn FORM_SWITCH_COST; ở form đặc biệt nộ tụt dần (RiderForm.rage_drain), về 0 thì
##           tự về form gốc. Final Attack (U) cần ≥ FINAL_MIN_RAGE và đốt hết nộ.
##   Nhặt Driver / form lần đầu (transform_into): nộ đầy và biến thân ngay vào form đó.
## Bắn: chỉ form có súng (RiderForm.get_shot khác {}). Dạng người không bắn được.
## Né (Shift) bất tử với đòn cận chiến nhưng KHÔNG tránh được đạn: đạn cao thì cúi, đạn thấp thì nhảy.
## Qua màn: release_henshin() giải trừ biến thân (cảnh biến thân chạy ngược, không bị phạt như Henshin Break).
## Vào màn: reset_for_stage() đưa về dạng người, máu người đầy, nộ đầy. input_locked = true thì đứng yên, bỏ qua phím.
## Cần các node con: Sprite (AnimatedSprite2D), Hitbox, Hurtbox, Forms (Node).

signal hp_changed(current: int, maximum: int)
signal rider_hp_changed(current: float, maximum: float)
signal rage_changed(value: float)
signal form_changed(rider_id: StringName)        ## &"" = trở về dạng người
signal form_status_changed(text: String)         ## dòng trạng thái phụ (form Kuuga, đồng hồ Axel...)
signal combo_changed(count: int)
signal notice(text: String)                      ## thông báo ngắn cho màn chơi hiện banner (hết nộ, thiếu nộ...)
signal died

enum State { NORMAL, ATTACK, DODGE, HURT, HENSHIN, SWAP, BREAK, KO, CROUCH, RELEASE }

const GAUGE_MAX := 100.0
const HENSHIN_TIME := 1.2
const RELEASE_TIME := 0.8      ## giải trừ biến thân khi qua màn (cảnh biến thân chạy ngược, nhanh hơn)
const SWAP_TIME := 0.3
const SWAP_COOLDOWN := 8.0
const BREAK_STUN := 1.0
const HURT_TIME := 0.3
const COMBO_WINDOW := 1.5
const COMBO_BONUS_PER_HIT := 0.02
const COMBO_BONUS_MAX := 0.5

# Chỉ số dạng người (dạng Rider lấy từ RiderForm)
const HUMAN_ARMOR := 0.0
const HUMAN_ATTACK_MULT := 1.0
const HUMAN_PUNCHES := 3       ## dạng người: 3 đấm rồi 1 đá

# Thời gian hồi chiêu (giây). Special của Rider lấy từ RiderForm.special_cooldown.
const DODGE_COOLDOWN := 0.6

const PLATFORM_LAYER := 5      ## lớp va chạm của bệ một chiều (xuống bằng ↓ + nhảy, hoặc bấm đúp ↓)
const DOUBLE_TAP_TIME := 0.3   ## bấm ↓ hai lần trong chừng này giây khi đứng trên bệ = xuống khỏi bệ
const RESPAWN_INVULN := 1.5
## Bất tử ngắn sau mỗi lần trúng đòn, để không bị nhiều quái/đạn trừ máu dồn dập cùng lúc.
const HIT_INVULN_HUMAN := 0.6
const HIT_INVULN_RIDER := 0.35
const REVERT_INVULN := 0.6     ## hết nộ, về form gốc: bất tử một chút

# Cúi người = thế thủ: đứng yên, thân thấp lại (đạn cao bay qua đầu), đòn cận chiến chỉ còn 40% và không bị đẩy lùi.
const CROUCH_DAMAGE_MULT := 0.4
const CROUCH_HURTBOX_HEIGHT := 30.0

# Nộ
const RAGE_ON_HIT_HUMAN := 8.0
const RAGE_ON_DEAL := 0.7                    ## × sát thương gây ra ở form gốc (đạn chỉ tính một nửa)
const RAGE_ON_DAMAGE := 0.8                  ## × máu mất
## Ở form đặc biệt nộ chỉ tụt, đánh trúng hay bị đánh đều không được cộng: thanh nộ là đồng hồ đếm ngược.
const FORM_ENTER_MIN_RAGE := 20.0            ## nộ tối thiểu để vào form đặc biệt
const FORM_SWITCH_COST := 10.0               ## nộ tốn mỗi lần đổi sang form đặc biệt
const FINAL_MIN_RAGE := 50.0                 ## nộ tối thiểu để tung Final Attack (đốt hết nộ)

@export var max_hp := 100
## Hiệu ứng mặc định, form ghi đè từng khóa qua RiderForm.fx().
const DEFAULT_FX := {"hit": "spark", "swing": "", "shot": "ball", "final": "ring", "color": Color(1.0, 0.85, 0.5),
	"trail": false, "glide": false}
const GHOST_INTERVAL := 0.05   ## giây giữa hai bóng mờ khi tăng tốc thời gian / form tốc độ
const GLIDE_FALL := 45.0       ## tốc độ rơi tối đa khi lượn (Blade Jack Form, giữ Nhảy)
const FEATHER_INTERVAL := 0.25
const BASE_HUMAN_HP := 100.0   ## máu dạng người ở thế giới 1, tăng theo GameState.human_power()
@export var human_speed := 110.0
@export var jump_velocity := -330.0   ## nhảy cao ~60 đơn vị thiết kế, đủ lên bệ kiểu Contra
@export var dodge_speed := 230.0
@export var dodge_time := 0.25

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var forms_root: Node = $Forms

var state := State.NORMAL
var hp := 0                    ## máu dạng người
var rider_hp := 0.0            ## máu của Rider đang biến thân
var rage := 0.0
var facing := 1
var current_form: RiderForm = null
var equipped: Array[RiderForm] = []
var active_slot := 0
var swap_cooldown := 0.0
var invincible := false
var input_locked := false      ## màn chơi khóa điều khiển lúc qua màn / chuyển màn
var speed_mult := 1.0          ## Rider có thể chỉnh (Faiz Axel)
var shoot_cooldown := 0.0
var _grace_timer := 0.0        ## bất tử ngắn sau khi hồi sinh / hết nộ (đếm riêng, không đụng cờ invincible)
var dodge_cooldown := 0.0
var _pending_form: StringName = &""   ## form sẽ vào khi biến thân / đổi Rider xong (nhặt form)

var _state_timer := 0.0
var _attack: Dictionary = {}
var _attack_kind: StringName = &""
var _attack_phase := 0         ## 0 = startup, 1 = active, 2 = recovery
var _hits_left := 0
var _light_chain := 0          ## số đòn đấm đã ra trong chuỗi hiện tại (tới punch_count thì đòn kế là cú đá)
var _down_tap := INF           ## giây kể từ lần bấm ↓ trước (bấm đúp để xuống bệ)
var _buffered: StringName = &""
var _combo := 0
var _combo_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _stand_hurtbox_height := 0.0
var _ghost_timer := 0.0
var _feather_timer := 0.0


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	hitbox.team = &"player"
	hurtbox.team = &"player"
	hitbox.hit_landed.connect(_on_hit_landed)
	GameState.equipped_changed.connect(_sync_forms)
	GameState.rider_leveled.connect(_on_rider_leveled)
	_sync_forms()
	hp_changed.emit(hp, max_hp)
	_play("idle")


func _draw() -> void:
	# Bóng đổ dưới chân, giúp nhân vật nổi lên khỏi nền.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 17.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if current_form:
		current_form.update(delta)
	if not is_on_floor():
		velocity.y += _gravity * delta
	_update_fx(delta)
	match state:
		State.NORMAL:
			_state_normal(delta)
		State.ATTACK:
			_state_attack(delta)
		State.DODGE, State.HURT, State.BREAK:
			_state_timed(delta)
		State.HENSHIN:
			_state_henshin(delta)
		State.SWAP:
			_state_swap(delta)
		State.CROUCH:
			_state_crouch(delta)
		State.RELEASE:
			_state_release(delta)
		State.KO:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	move_and_slide()


# --- Chỉ số theo dạng -----------------------------------------------------

func current_armor() -> float:
	return current_form.armor if current_form else HUMAN_ARMOR


func current_speed() -> float:
	return (current_form.move_speed if current_form else human_speed) * speed_mult * Units.SCALE


# --- Tài nguyên -----------------------------------------------------------

func can_henshin() -> bool:
	return current_form == null and not equipped.is_empty() and rage >= GAUGE_MAX


func can_final() -> bool:
	return current_form != null and rage >= FINAL_MIN_RAGE


func add_rage(amount: float) -> void:
	_set_rage(rage + amount)


func _set_rage(value: float) -> void:
	rage = clampf(value, 0.0, GAUGE_MAX)
	rage_changed.emit(rage)


func _gain_from_damage(damage_taken: float) -> void:
	if not in_special_form():
		add_rage(damage_taken * RAGE_ON_DAMAGE)


func in_special_form() -> bool:
	return current_form != null and current_form.is_special_form()


func has_gun() -> bool:
	return current_form != null and current_form.has_gun()


## RiderForm gọi khi đổi sang form đặc biệt. Đủ nộ thì trừ phí và trả về true.
func pay_form_switch() -> bool:
	if rage < FORM_ENTER_MIN_RAGE:
		notice.emit("Cần %d nộ để đổi form" % int(FORM_ENTER_MIN_RAGE))
		return false
	_set_rage(rage - FORM_SWITCH_COST)
	return true


## Nhặt Driver / form lần đầu: nộ đầy và biến thân ngay vào form đó (form_id &"" = form gốc).
## Đang là người thì chạy cảnh biến thân; đang là Rider thì đổi nhanh như đổi Rider.
func transform_into(rider_id: StringName, form_id: StringName) -> void:
	if state == State.KO:
		return
	var form := _find_form(rider_id)
	var slot := equipped.find(form)
	if slot < 0:
		return
	_set_rage(GAUGE_MAX)
	_pending_form = form_id if form_id != &"" else form.base_form()
	active_slot = slot
	_set_crouch(false)
	hitbox.deactivate()
	_light_chain = 0
	invincible = true
	velocity.x = 0.0
	if current_form == null:
		state = State.HENSHIN
		_state_timer = HENSHIN_TIME
		_play("henshin", form.animation_prefix())
	else:
		state = State.SWAP
		_state_timer = SWAP_TIME
		_play("swap")


# --- Trạng thái -----------------------------------------------------------

func _state_normal(delta: float) -> void:
	if input_locked:
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * Units.SCALE * delta)
		_play("idle" if is_on_floor() else "jump")
		return
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, dir * current_speed(), 1200.0 * Units.SCALE * delta)
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		sprite.flip_h = facing < 0
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if Input.is_action_pressed("move_down") and _on_platform():
			_drop_through()            # ↓ + nhảy trên bệ = xuống khỏi bệ (như Contra)
			return
		velocity.y = jump_velocity * Units.SCALE * (current_form.jump_mult if current_form else 1.0)
	if Input.is_action_just_pressed("move_down") and is_on_floor():
		# Bấm đúp ↓ trên bệ = xuống khỏi bệ (nút cảm ứng không bấm được ↓ cùng lúc với nhảy).
		if _down_tap < DOUBLE_TAP_TIME and _on_platform():
			_down_tap = INF
			_drop_through()
			return
		_down_tap = 0.0
	if Input.is_action_pressed("move_down") and is_on_floor():
		_set_crouch(true)
		return
	if Input.is_action_pressed("shoot"):
		try_shoot()

	if Input.is_action_just_pressed("attack_light"):
		start_attack(&"light")
	elif Input.is_action_just_pressed("dodge"):
		start_dodge()
	elif Input.is_action_just_pressed("henshin"):
		try_henshin()
	elif Input.is_action_just_pressed("swap_rider"):
		try_swap()
	elif Input.is_action_just_pressed("final_attack"):
		try_final_attack()
	elif Input.is_action_just_pressed("ultimate"):
		# Nút tuyệt chiêu trên màn hình: dạng người thì biến thân, dạng Rider thì Final Attack.
		if current_form:
			try_final_attack()
		else:
			try_henshin()
	elif Input.is_action_just_pressed("special") and current_form:
		# Dạng người chỉ có kỹ năng cơ bản; Special thuộc về từng form Rider.
		current_form.try_special()

	if state == State.NORMAL:
		if not is_on_floor():
			_play("jump")
		elif absf(velocity.x) > 5.0:
			_play("run")
		else:
			_play("idle")


func _state_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * Units.SCALE * delta)
	var cancellable: bool = not _attack.get("no_cancel", false)
	if cancellable:
		if input_locked:
			pass
		elif Input.is_action_just_pressed("attack_light"):
			_buffered = &"light"
		elif _attack_phase == 2 and Input.is_action_just_pressed("dodge"):
			# Né hủy hồi chiêu (dodge cancel)
			hitbox.deactivate()
			start_dodge()
			return

	_state_timer -= delta * speed_mult   # tăng tốc thời gian: ra đòn nhanh như chạy
	if _state_timer > 0.0:
		return
	match _attack_phase:
		0:
			_attack_phase = 1
			_hits_left = int(_attack.get("hits", 1))
			if _attack.has("lunge"):
				var lunge: Vector2 = _attack["lunge"]
				velocity = Vector2(lunge.x * facing, lunge.y) * Units.SCALE
			_fire_hitbox()
		1:
			_hits_left -= 1
			if _hits_left > 0:
				_fire_hitbox()
			else:
				hitbox.deactivate()
				_attack_phase = 2
				_state_timer = _attack["recovery"]
		2:
			invincible = false
			state = State.NORMAL
			if _buffered != &"":
				start_attack(_buffered)
			else:
				_light_chain = 0


func _state_crouch(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1200.0 * Units.SCALE * delta)
	if input_locked or not Input.is_action_pressed("move_down") or not is_on_floor():
		_set_crouch(false)
		return
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		sprite.flip_h = facing < 0
	if Input.is_action_pressed("shoot"):
		try_shoot()
	if Input.is_action_just_pressed("jump") and _on_platform():
		_drop_through()
	elif Input.is_action_just_pressed("attack_light"):
		_set_crouch(false)
		start_attack(&"light")
	elif Input.is_action_just_pressed("dodge"):
		_set_crouch(false)
		start_dodge()


func _set_crouch(on: bool) -> void:
	var shape := hurtbox.get_node("CollisionShape2D") as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	if on:
		if _stand_hurtbox_height == 0.0:
			_stand_hurtbox_height = rect.size.y
		rect.size.y = CROUCH_HURTBOX_HEIGHT
		shape.position.y = -CROUCH_HURTBOX_HEIGHT / 2.0
		state = State.CROUCH
		_play("crouch")
	else:
		if _stand_hurtbox_height > 0.0:
			rect.size.y = _stand_hurtbox_height
			shape.position.y = -_stand_hurtbox_height / 2.0
		if state == State.CROUCH:
			state = State.NORMAL


func _state_timed(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * Units.SCALE * delta)
	_state_timer -= delta
	if _state_timer <= 0.0:
		invincible = false
		state = State.NORMAL


func _state_henshin(delta: float) -> void:
	velocity.x = 0.0
	_state_timer -= delta
	if _state_timer > 0.0:
		return
	_enter_form(equipped[active_slot], true)
	# Sóng xung kích lúc biến thân xong: đẩy lùi quái xung quanh.
	_begin_attack(&"henshin", RiderForm.make_attack(4.0, 0.0, 0.12, 0.1, Vector2(90, 40), Vector2(0, -14),
		Vector2(180, -90), [&"henshin"], {"no_cancel": true, "anim": "idle"}))


func _state_release(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * Units.SCALE * delta)
	_state_timer -= delta
	if _state_timer > 0.0:
		return
	_to_human()
	invincible = false
	state = State.NORMAL
	_play("idle")


func _state_swap(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_state_timer -= delta
	if _state_timer > 0.0:
		return
	invincible = false
	state = State.NORMAL
	_enter_form(equipped[active_slot], false)
	start_attack(&"swap_in")


# --- Hành động ------------------------------------------------------------

## kind &"light" = nút Đánh: đấm theo chuỗi, đủ punch_count đòn thì ra cú đá (&"kick") rồi chuỗi về đầu.
func start_attack(kind: StringName) -> void:
	var chain := 0
	if kind == &"light":
		var punches := current_form.punch_count() if current_form else HUMAN_PUNCHES
		if _light_chain >= punches:
			kind = &"kick"
		else:
			chain = _light_chain
	var data := current_form.get_attack(kind, chain) if current_form else _human_attack(kind, chain)
	if data.is_empty():
		return
	_light_chain = _light_chain + 1 if kind == &"light" else 0
	if kind == &"kick" and not data.has("anim"):
		data["anim"] = "heavy"   # bộ hình cú đá trong SpriteFrames tên là "<form>_heavy"
	_begin_attack(kind, data)


## Bắn theo hướng đang giữ (8 hướng): ↑ bắn lên, ↑ + tiến bắn chéo, trên không giữ ↓ bắn xuống.
## Chỉ form có súng mới bắn được.
func try_shoot() -> void:
	if shoot_cooldown > 0.0 or current_form == null:
		return
	var shot := current_form.get_shot()
	if shot.is_empty():
		return
	shoot_cooldown = shot["cooldown"]
	var aim := _aim_dir()
	var crouching := state == State.CROUCH
	var muzzle := Vector2(14.0 * facing, -18.0 if crouching else -34.0)
	if aim.y < -0.5 and aim.x == 0.0:
		muzzle = Vector2(4.0 * facing, -58.0)
	var count: int = shot["count"]
	for i in count:
		var p := Projectile.new()
		p.team = &"player"
		p.damage = float(shot["damage"]) * _damage_mult()
		p.radius = shot["radius"]
		p.color = shot["color"]
		p.pierce = shot["pierce"]
		p.life = shot["life"]
		p.source = self
		p.style = str(current_fx()["shot"])
		p.hit_fx = str(current_fx()["hit"])
		var offset: float = (i - (count - 1) / 2.0) * float(shot["spread"])
		p.velocity = aim.rotated(offset) * float(shot["speed"]) * Units.SCALE
		p.hit_landed.connect(_on_hit_landed)
		get_parent().add_child(p)
		p.global_position = global_position + muzzle


func _aim_dir() -> Vector2:
	var x := Input.get_axis("move_left", "move_right")
	var y := 0.0
	if Input.is_action_pressed("move_up"):
		y = -1.0
	elif Input.is_action_pressed("move_down") and not is_on_floor():
		y = 1.0
	if x == 0.0 and y == 0.0:
		x = facing
	return Vector2(signf(x), y).normalized()


func _on_platform() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var body := c.get_collider() as CollisionObject2D
		if body and body.get_collision_layer_value(PLATFORM_LAYER) and c.get_normal().y < -0.5:
			return true
	return false


func _drop_through() -> void:
	_set_crouch(false)
	set_collision_mask_value(PLATFORM_LAYER, false)
	velocity.y = 80.0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: set_collision_mask_value(PLATFORM_LAYER, true))


## Rơi xuống vực: mất một phần máu (máu Rider nếu đang biến thân). Trả về true nếu gục.
func take_fall_damage(ratio: float) -> bool:
	if current_form:
		rider_hp -= current_form.get_max_hp() * ratio
		rider_hp_changed.emit(maxf(rider_hp, 0.0), current_form.get_max_hp())
		if rider_hp <= 0.0:
			_henshin_break()
		return false
	hp -= ceili(max_hp * ratio)
	hp_changed.emit(maxi(hp, 0), max_hp)
	if hp <= 0:
		_die()
		return true
	return false


## Bất tử vì đang né / biến thân / tung chiêu, hoặc vừa hồi sinh.
func is_invulnerable() -> bool:
	return invincible or _grace_timer > 0.0


## Đưa về điểm an toàn sau khi rơi vực, bất tử một lúc (đếm riêng, không đụng cờ invincible của các trạng thái).
func respawn_at(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_set_crouch(false)
	if state != State.KO:
		state = State.NORMAL
		invincible = false
	_grace_timer = RESPAWN_INVULN


func start_dodge() -> void:
	if dodge_cooldown > 0.0:
		return
	dodge_cooldown = DODGE_COOLDOWN
	var dir := Input.get_axis("move_left", "move_right")
	var d := facing if dir == 0.0 else int(signf(dir))
	state = State.DODGE
	_state_timer = dodge_time
	invincible = true
	velocity.x = d * dodge_speed * Units.SCALE * (1.2 if current_form == null else 1.0)
	_play("dodge")


func try_henshin() -> void:
	if not can_henshin():
		return
	state = State.HENSHIN
	_state_timer = HENSHIN_TIME
	invincible = true
	velocity.x = 0.0
	_play("henshin", equipped[active_slot].animation_prefix())


## Qua màn: giải trừ biến thân. Chạy ngược cảnh biến thân của Rider đang mang (Rider chưa có sprite thì chỉ chớp
## sáng), xong thì về dạng người. Không mất nộ, không choáng như Henshin Break. Đang ở dạng người thì bỏ qua.
func release_henshin() -> void:
	if current_form == null or state == State.KO:
		return
	_set_crouch(false)
	hitbox.deactivate()
	_light_chain = 0
	_pending_form = &""
	state = State.RELEASE
	_state_timer = RELEASE_TIME
	invincible = true
	var anim := "%s_henshin" % current_form.animation_prefix()
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim, -HENSHIN_TIME / RELEASE_TIME, true)
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color(2.2, 2.2, 2.2), RELEASE_TIME * 0.6)
	flash.tween_property(self, "modulate", Color.WHITE, RELEASE_TIME * 0.4)


func is_releasing() -> bool:
	return state == State.RELEASE


## Vào màn mới (kể cả chơi lại từ checkpoint): dạng người, máu người đầy, nộ đầy để biến thân được ngay
## khi đã có Driver, hồi chiêu và combo về 0, mở khóa điều khiển.
func reset_for_stage() -> void:
	if current_form:
		_to_human()
	_set_crouch(false)
	max_hp = int(round(BASE_HUMAN_HP * GameState.human_power()))
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	_set_rage(GAUGE_MAX)
	swap_cooldown = 0.0
	dodge_cooldown = 0.0
	shoot_cooldown = 0.0
	_combo = 0
	combo_changed.emit(0)
	active_slot = 0
	state = State.NORMAL
	invincible = false
	input_locked = false
	modulate = Color.WHITE
	_play("idle")


## Vào màn: nếu đang biến thân thì chuyển ngay sang Rider chính (ô đầu đội hình), giữ tỉ lệ máu Rider.
func use_main_rider() -> void:
	active_slot = 0
	if current_form != null and not equipped.is_empty() and current_form != equipped[0]:
		_enter_form(equipped[0], false)


func try_swap() -> void:
	if current_form == null or equipped.size() < 2 or swap_cooldown > 0.0:
		return
	active_slot = (active_slot + 1) % equipped.size()
	swap_cooldown = SWAP_COOLDOWN
	state = State.SWAP
	_state_timer = SWAP_TIME
	invincible = true
	_play("swap")


func try_final_attack() -> void:
	if not can_final():
		return
	_set_rage(0.0)   # ở form đặc biệt: đánh xong thì về form gốc (_tick_rage)
	CombatDirector.final_attack_started.emit(current_form.rider_id, current_form.final_attack_name())
	start_attack(&"final")


## Được Hurtbox gọi. Trả về true nếu đòn trúng.
func take_hit(info: DamageInfo) -> bool:
	if state == State.KO:
		return false
	# Né chỉ tránh được đòn cận chiến; đạn phải nhảy hoặc cúi mà tránh.
	var dodging_bullet := state == State.DODGE and _grace_timer <= 0.0 and info.has_tag(&"ranged")
	if is_invulnerable() and not dodging_bullet:
		return false
	var blocking := state == State.CROUCH
	var mult := CROUCH_DAMAGE_MULT if blocking else 1.0
	if current_form:
		var dmg := current_form.modify_incoming_damage(info) * mult
		if not blocking:
			_grace_timer = maxf(_grace_timer, HIT_INVULN_RIDER)
		rider_hp -= dmg
		rider_hp_changed.emit(maxf(rider_hp, 0.0), current_form.get_max_hp())
		_gain_from_damage(dmg)
		if rider_hp <= 0.0:
			_henshin_break()
			return true
		if info.damage < current_form.poise:
			return true   # siêu giáp: đòn nhẹ không làm Rider khựng
	else:
		var dmg := info.damage * 100.0 / (100.0 + HUMAN_ARMOR) * mult
		if not blocking:
			_grace_timer = maxf(_grace_timer, HIT_INVULN_HUMAN)
		hp -= ceili(dmg)
		hp_changed.emit(maxi(hp, 0), max_hp)
		_gain_from_damage(dmg)
		if hp <= 0:
			_die()
			return true
	if blocking:
		return true   # đang thủ thế: không bị khựng, không bị đẩy
	hitbox.deactivate()
	_light_chain = 0
	state = State.HURT
	_state_timer = HURT_TIME
	velocity = Vector2(info.knockback.x * _knock_dir(info), info.knockback.y) * Units.SCALE
	_play("hurt")
	return true


# --- Cho nút bấm trên màn hình --------------------------------------------

## [thời gian hồi còn lại, tổng thời gian hồi] của một action, để vẽ vòng hồi chiêu.
func cooldown_of(action: String) -> Vector2:
	match action:
		"dodge":
			return Vector2(dodge_cooldown, DODGE_COOLDOWN)
		"swap_rider":
			return Vector2(swap_cooldown, SWAP_COOLDOWN)
		"special":
			if current_form:
				return Vector2(current_form.special_timer, current_form.special_cooldown)
	return Vector2.ZERO


## Action có dùng được ngay lúc này không (đủ nộ, đã mở khóa, đủ điều kiện).
func is_action_available(action: String) -> bool:
	match action:
		"special":
			return current_form != null and current_form.special_available() \
				and (in_special_form() or rage >= FORM_ENTER_MIN_RAGE)
		"swap_rider":
			return current_form != null and equipped.size() >= 2
		"ultimate":
			return can_final() or can_henshin()
	return true


## Nút có nên hiện không. Chưa mở khóa thì ẩn hẳn (dạng người chỉ có nút cơ bản).
func is_action_visible(action: String) -> bool:
	match action:
		"shoot":
			return has_gun()
		"special":
			return current_form != null and current_form.special_available()
		"swap_rider":
			return current_form != null and equipped.size() >= 2
		"ultimate":
			return current_form != null or not equipped.is_empty()
	return true


## Chữ dưới nút, đổi theo dạng hiện tại. Trả về "" để giữ nhãn mặc định.
func action_label(action: String) -> String:
	match action:
		"special":
			return current_form.special_label() if current_form else ""
		"ultimate":
			return "Tuyệt chiêu" if current_form else "Biến thân"
	return ""


# --- Cho RiderForm gọi ----------------------------------------------------

func set_form_status(text: String) -> void:
	form_status_changed.emit(text)


func refresh_animation() -> void:
	_play("idle")


## Máu tối đa của form đổi (đổi form Kuuga, lên cấp) → giữ nguyên tỉ lệ máu Rider.
func rescale_rider_hp(old_max: float, new_max: float) -> void:
	if old_max <= 0.0:
		return
	rider_hp = rider_hp / old_max * new_max
	rider_hp_changed.emit(rider_hp, new_max)


# --- Nội bộ ---------------------------------------------------------------

## Đồng bộ danh sách Rider với GameState.equipped (khi kích hoạt Driver mới giữa màn chơi).
func _sync_forms() -> void:
	var new_list: Array[RiderForm] = []
	for id in GameState.equipped:
		var form := _find_form(id)
		if form == null:
			form = GameState.create_form(id)
			if form == null:
				continue
			forms_root.add_child(form)
		new_list.append(form)
	for old in equipped:
		if not new_list.has(old) and old != current_form:
			old.queue_free()
	equipped = new_list
	active_slot = maxi(equipped.find(current_form), 0) if current_form else 0


func _find_form(id: StringName) -> RiderForm:
	for child in forms_root.get_children():
		var form := child as RiderForm
		if form and form.rider_id == id:
			return form
	return null


func _on_rider_leveled(id: StringName, level: int) -> void:
	var form := _find_form(id)
	if form:
		form.set_level(level)
		if form == current_form:
			rider_hp_changed.emit(rider_hp, form.get_max_hp())


func _begin_attack(kind: StringName, data: Dictionary) -> void:
	_attack = data
	_attack_kind = kind
	_attack_phase = 0
	_state_timer = data["startup"]
	_buffered = &""
	state = State.ATTACK
	invincible = kind in [&"final", &"swap_in", &"henshin"]
	_play(str(data.get("anim", kind)), "", true)
	var fx := current_fx()
	var swing := str(fx["swing"])
	if current_form and swing != "" and not (&"ranged" in data["tags"]):
		var off: Vector2 = data["offset"]
		Fx.spawn(get_parent(), global_position + Vector2(off.x * facing, off.y) * Units.SCALE, swing, fx["color"],
			facing, 1.3 if kind in [&"kick", &"final"] else 1.0)


func _fire_hitbox() -> void:
	_state_timer = _attack["active"]
	var base_tags: Array = _attack["tags"]
	var tags := base_tags.duplicate()
	if _attack_kind == &"final":
		tags.append(&"final")
	var dmg: float = _attack["damage"] * _damage_mult()
	var info := DamageInfo.new(dmg, _attack["knockback"], facing, tags, self)
	hitbox.activate(info, _attack["size"], _attack["offset"])


func _damage_mult() -> float:
	var m := 1.0 + minf(_combo * COMBO_BONUS_PER_HIT, COMBO_BONUS_MAX)
	if current_form:
		m *= current_form.attack_mult * current_form.level_mult()
	else:
		m *= HUMAN_ATTACK_MULT * GameState.human_power()
	return m


## Vào Rider `form`. Rider vừa rời đi trở về form gốc. Có _pending_form (vừa nhặt form) thì vào luôn form đó.
func _enter_form(form: RiderForm, fresh: bool) -> void:
	var ratio := 1.0
	if current_form:
		if not fresh:
			ratio = rider_hp / current_form.get_max_hp()
		_leave_form()
	current_form = form
	speed_mult = 1.0
	form.on_enter(self)
	if _pending_form != &"":
		form.set_form(_pending_form)
		_pending_form = &""
	rider_hp = form.get_max_hp() * ratio
	form_changed.emit(form.rider_id)
	rider_hp_changed.emit(rider_hp, form.get_max_hp())
	_play("idle")


func _leave_form() -> void:
	current_form.reset_to_base()
	current_form.on_exit()


## Ở form đặc biệt thì nộ tụt dần; về 0 thì trở về form gốc (đợi Final Attack đánh xong, đòn thường thì ngắt).
func _tick_rage(delta: float) -> void:
	if not in_special_form() or state in [State.HENSHIN, State.SWAP, State.KO]:
		return
	if rage > 0.0:
		_set_rage(rage - current_form.rage_drain() * delta)
	if rage > 0.0 or (state == State.ATTACK and _attack_kind == &"final"):
		return
	if state == State.ATTACK:
		hitbox.deactivate()
		_light_chain = 0
		invincible = false
		state = State.NORMAL
	current_form.reset_to_base()
	_grace_timer = maxf(_grace_timer, REVERT_INVULN)
	notice.emit("HẾT NỘ · về form gốc")


## Rời Rider về dạng người (dùng chung cho Henshin Break và giải trừ biến thân khi qua màn).
func _to_human() -> void:
	if current_form:
		_leave_form()
	current_form = null
	speed_mult = 1.0
	rider_hp = 0.0
	_pending_form = &""
	form_changed.emit(&"")
	hitbox.deactivate()
	_light_chain = 0


func _henshin_break() -> void:
	_set_crouch(false)
	_to_human()
	_set_rage(0.0)   # hình phạt: mất hết nộ
	state = State.BREAK
	_state_timer = BREAK_STUN
	invincible = true
	velocity = Vector2(-facing * 120.0, -120.0) * Units.SCALE
	_play("break")


func _die() -> void:
	_set_crouch(false)
	state = State.KO
	hitbox.deactivate()
	_play("ko")
	died.emit()


func _tick_timers(delta: float) -> void:
	swap_cooldown = maxf(swap_cooldown - delta, 0.0)
	_down_tap += delta
	shoot_cooldown = maxf(shoot_cooldown - delta, 0.0)
	_grace_timer = maxf(_grace_timer - delta, 0.0)
	dodge_cooldown = maxf(dodge_cooldown - delta, 0.0)
	_tick_rage(delta)
	if _combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo = 0
			combo_changed.emit(0)


func _on_hit_landed(target: Node, info: DamageInfo) -> void:
	if info.has_tag(&"henshin"):
		return
	if not info.has_tag(&"ranged") and target is Node2D:   # đạn tự vẽ hiệu ứng trúng (Projectile.hit_fx)
		var fx := current_fx()
		var at := (target as Node2D).global_position + Vector2(-facing * 4.0, -34.0)
		if info.has_tag(&"final"):
			Fx.spawn(get_parent(), at, str(fx["final"]), fx["color"], facing, 1.6)
			Fx.spawn(get_parent(), at, str(fx["hit"]), fx["color"], facing, 1.4)
		else:
			Fx.spawn(get_parent(), at, str(fx["hit"]), fx["color"], facing, 1.2 if info.has_tag(&"heavy") else 1.0)
			if info.has_tag(&"heavy") and str(fx["hit"]) != "ring":
				Fx.spawn(get_parent(), at + Vector2(0, 30.0), "ring", fx["color"], facing, 0.6)
	_combo += 1
	_combo_timer = COMBO_WINDOW
	combo_changed.emit(_combo)
	var ranged := info.has_tag(&"ranged")
	if not info.has_tag(&"final") and not in_special_form():
		if current_form == null:
			add_rage(RAGE_ON_HIT_HUMAN)
		else:
			add_rage(info.damage * RAGE_ON_DEAL * (0.5 if ranged else 1.0))
	var heavy := info.has_tag(&"heavy") or info.has_tag(&"final")
	if not ranged or heavy:
		CombatDirector.hit_stop(0.08 if heavy else 0.035)
	if heavy:
		CombatDirector.shake(5.0 if info.has_tag(&"final") else 3.0)


func _knock_dir(info: DamageInfo) -> int:
	if is_instance_valid(info.source) and info.source is Node2D:
		var src := info.source as Node2D
		return 1 if global_position.x >= src.global_position.x else -1
	return info.direction


## Hiệu ứng của dạng hiện tại: DEFAULT_FX ghi đè bởi form (dạng người dùng mặc định).
func current_fx() -> Dictionary:
	var fx := DEFAULT_FX.duplicate()
	if current_form:
		fx.merge(current_form.fx(), true)
	return fx


## Bóng mờ khi tăng tốc thời gian / form tốc độ, lượn khi giữ Nhảy (Jack Form), animation nhanh theo speed_mult.
func _update_fx(delta: float) -> void:
	sprite.speed_scale = speed_mult
	if current_form == null:
		return
	var fx := current_fx()
	var moving := absf(velocity.x) > 10.0 or state in [State.ATTACK, State.DODGE]
	if (speed_mult > 1.0 or fx["trail"]) and moving:
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = GHOST_INTERVAL
			Fx.ghost(get_parent(), sprite, fx["color"])
	if fx["glide"] and not is_on_floor() and velocity.y > GLIDE_FALL * Units.SCALE \
			and Input.is_action_pressed("jump") and state in [State.NORMAL, State.ATTACK]:
		velocity.y = GLIDE_FALL * Units.SCALE
		_feather_timer -= delta
		if _feather_timer <= 0.0:
			_feather_timer = FEATHER_INTERVAL
			Fx.spawn(get_parent(), global_position + Vector2(-facing * 10.0, -40.0), "feather", fx["color"], facing)


## Dạng người: 3 đấm 3 rồi đá 8.
func _human_attack(kind: StringName, _chain: int) -> Dictionary:
	match kind:
		&"light":
			return RiderForm.make_attack(3.0, 0.06, 0.08, 0.14, Vector2(16, 12), Vector2(12, -14), Vector2(40, -20))
		&"kick":
			return RiderForm.make_attack(8.0, 0.14, 0.1, 0.28, Vector2(20, 14), Vector2(14, -14), Vector2(140, -60), [&"heavy"])
	return {}


## restart = true: phát lại từ đầu kể cả khi đang phát đúng animation đó (các đòn trong chuỗi combo).
func _play(action: String, prefix := "", restart := false) -> void:
	if sprite.sprite_frames == null:
		return
	if prefix == "":
		prefix = current_form.animation_prefix() if current_form else "human"
	# Rider chưa có sprite thì ẩn Sprite, để màn chơi hiện hình tạm (Placeholder) thay thế.
	sprite.visible = sprite.sprite_frames.has_animation(prefix + "_idle")
	var anim_name := "%s_%s" % [prefix, action]
	if not sprite.sprite_frames.has_animation(anim_name):
		return
	if restart:
		sprite.stop()
		sprite.play(anim_name)
	elif sprite.animation != anim_name:
		sprite.play(anim_name)
