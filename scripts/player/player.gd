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
##   ngừng bấm thì chuỗi về đầu. Nút Đánh luôn là tay không (Rider có script riêng như Kuuga Pegasus vẫn tự quyết).
## Chém (K / nút Chém): chỉ form có kiếm / vũ khí cận chiến (RiderForm.has_blade): chuỗi slash_count() nhát rồi nhát kết
##   &"slash_finish", animation "slash" (vũ khí chỉ hiện trong animation này).
## Thanh tài nguyên: MÁU · NỘ
##   Nộ: tích khi đánh trúng và khi bị đánh (đòn skill và Final không cộng nộ).
##       Dạng người: nộ đầy thì biến thân (I) vào form gốc của Rider ở ô đầu (không mất nộ).
##       Dạng Rider: từ form gốc đổi sang form đặc biệt (L) tốn FORM_SWITCH_COST; ở form đặc biệt nút L ẩn. Ở mọi form đặc biệt nộ tụt dần
##           (RiderForm.rage_drain: RAGE_DRAIN, form tăng tốc thời gian nhanh hơn), về 0 thì tự về form gốc. Lúc nộ đang tụt vẫn tích được nộ
##           (đánh trúng, bị đánh, hạ quái, chém đạn) nhưng chỉ DRAIN_GAIN_MULT lượng thường và mỗi giây không quá
##           DRAIN_GAIN_SHARE lượng bị trừ (gain_rage), nên nộ vẫn luôn giảm.
##           Skill 1 (U) / Skill 2 (Y) tốn nộ và có hồi chiêu, Final Attack (O) tốn Skills.FINAL_COST (SkillCaster).
##   Nhặt Driver / form lần đầu (transform_into): nộ đầy và biến thân ngay vào form đó.
## Bắn: chỉ form có súng (RiderForm.get_shot khác {}). Dạng người không bắn được. Hình súng (RiderForm.gun_look,
##   art/characters/weapons/) hiện ở tay theo hướng ngắm suốt lúc giữ nút Bắn, thả nút thì cất sau GUN_SHOW_TIME giây.
## Đổi nút giữa chừng: đang hồi chiêu mà bấm nút KHÁC loại (đấm ↔ chém) hoặc giữ Bắn thì ra ngay, không chờ hồi chiêu.
## Né (Shift) bất tử với đòn cận chiến nhưng KHÔNG tránh được đạn: đạn cao thì cúi, đạn thấp thì nhảy.
## Chém đạn: vung vũ khí (nút Chém; form cầm sẵn vũ khí thì cả nút Đánh, RiderForm.can_parry) mở cửa sổ PARRY_WINDOW
##   giây. Đạn của phe kia bay vào tầm lưỡi (phía trước, tầm hitbox của nhát chém + PARRY_PAD, cả chiều cao người) trong
##   cửa sổ thì bị chém tan, cộng nộ. Vung đúng lúc (trong PARRY_PERFECT giây đầu) và đạn ở mũi lưỡi (xa hơn PARRY_TIP
##   tầm với) thì PHẢN ĐẠN: đạn bật ngược về kẻ bắn, nhanh ×REFLECT_SPEED, sát thương ×REFLECT_DAMAGE, phá giáp.
##   Vung trễ / đạn ngoài tầm thì vẫn trúng như thường. Chế độ đấu: đạn của đối thủ trên máy này chỉ là bản sao
##   (Projectile.visual_only) nên chém tan bản sao, giữ một "lượt đỡ" để bỏ qua đòn đạn máy đối thủ báo về sau đó
##   (PARRY_NET_GRACE giây); phản đạn thì bắn ra một viên đạn thật của mình.
## Qua màn: release_henshin() giải trừ biến thân (cảnh biến thân chạy ngược, không bị phạt như Henshin Break).
## Vào màn: reset_for_stage() đưa về dạng người, máu người đầy, nộ đầy. input_locked = true thì đứng yên, bỏ qua phím.
## Cần các node con: Sprite (AnimatedSprite2D), Hitbox, Hurtbox, Forms (Node).
##
## Chế độ đấu qua mạng (scripts/versus/versus.gd):
##   versus_riders: Rider của nhân vật này (thay cho GameState.equipped; hai người chơi chọn riêng, trùng nhau cũng được).
##   team: phe của Hitbox / Hurtbox / đạn (&"p1" / &"p2"), để hai người chơi đánh trúng nhau.
##   net_puppet = true: bản sao của đối thủ trên máy này. Không tự chạy, không đọc phím; vị trí và hình do mạng
##   cập nhật (VersusSync). Bị đánh trúng thì không tự trừ máu mà phát net_hit cho máy của đối thủ xử lý.

signal hp_changed(current: int, maximum: int)
signal rider_hp_changed(current: float, maximum: float)
signal rage_changed(value: float)
signal form_changed(rider_id: StringName)        ## &"" = trở về dạng người
signal form_status_changed(text: String)         ## dòng trạng thái phụ (form Kuuga, đồng hồ Axel...)
signal combo_changed(count: int)
signal notice(text: String)                      ## thông báo ngắn cho màn chơi hiện banner (hết nộ, thiếu nộ...)
signal form_pick_requested(form: RiderForm)      ## Decade / Zi-O bấm Kỹ năng: màn chơi mở bảng chọn form (DataRider.picks_form)
signal died
signal net_hit(info: DamageInfo)                 ## net_puppet bị đánh trúng: chuyển đòn sang máy của người chơi đó
signal shot_fired(projectile: Projectile)        ## vừa bắn một viên đạn (chế độ đấu gửi bản sao sang máy kia)
signal parried(perfect: bool)                    ## vừa chém tan (false) hoặc phản (true) một viên đạn
signal lock_marked(targets: Array, time: float)  ## skill khoá vừa hiện dấu khoá lên các mục tiêu (chế độ đấu báo đối thủ)
signal status_inflicted(target: Player, kind: String, time: float)  ## làm chậm / lộ yếu bản sao đối thủ (chế độ đấu gửi đi)

enum State { NORMAL, ATTACK, DODGE, HURT, HENSHIN, SWAP, BREAK, KO, CROUCH, RELEASE }

const GUN_SHOW_TIME := 0.3       ## giây súng còn trên tay sau khi thả nút Bắn
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
const COYOTE_TIME := 0.1       ## vừa rời mép trong chừng này giây vẫn nhảy được
const JUMP_BUFFER := 0.12      ## bấm Nhảy sớm chừng này giây trước khi chạm đất / hết đòn thì vẫn nhảy
const RESPAWN_INVULN := 1.5
## Bất tử ngắn sau mỗi lần trúng đòn, để không bị nhiều quái/đạn trừ máu dồn dập cùng lúc.
const HIT_INVULN_HUMAN := 0.6
const HIT_INVULN_RIDER := 0.35
const REVERT_INVULN := 0.6     ## hết nộ, về form gốc: bất tử một chút

# Chém đạn (xem đầu file)
const PARRY_WINDOW := 0.22     ## giây kể từ lúc vung: đạn vào tầm lưỡi trong khoảng này thì bị chém
const PARRY_PERFECT := 0.11    ## vung trong chừng này giây đầu + đạn ở mũi lưỡi = phản đạn
const PARRY_TIP := 0.45        ## mũi lưỡi: đạn cách tâm người từ chừng này phần tầm với trở ra
const PARRY_PAD := 8.0         ## px cộng vào tầm hitbox của nhát chém
const PARRY_TOP := -62.0       ## vùng chém theo chiều dọc (px so với chân): cả người, đạn cao lẫn đạn thấp
const PARRY_BOTTOM := 4.0
const REFLECT_SPEED := 1.4
const REFLECT_DAMAGE := 2.0
const REFLECT_VERSUS_DAMAGE := 8.0   ## chế độ đấu: sát thương gốc của viên đạn phản (× sức đánh của form)
const PARRY_RAGE := 4.0
const PERFECT_PARRY_RAGE := 10.0
const PARRY_NET_GRACE := 0.5
const MELEE_BACK := 8.0          ## đòn cận chiến phủ ra sau tâm người chừng này (đơn vị thiết kế ≈ 14 px)
const TURN_CHECK_FRONT := 50.0   ## px: trước mặt có quái trong chừng này thì không tự quay lại
const TURN_CHECK_BACK := 36.0    ## px: quái sát sau lưng trong chừng này thì tự quay lại khi bấm đánh

# Cúi người = thế thủ: đứng yên, thân thấp lại (đạn cao bay qua đầu), đòn cận chiến chỉ còn 40% và không bị đẩy lùi.
const CROUCH_DAMAGE_MULT := 0.4
const CROUCH_HURTBOX_HEIGHT := 30.0

# Nộ
const MAX_HIT_SHARE := 0.25                  ## một đòn của quái không lấy quá chừng này phần máu Rider tối đa
const RAGE_ON_HIT_HUMAN := 8.0
const RAGE_ON_DEAL := 0.5                    ## × sát thương gây ra (đạn chỉ tính một nửa)
const RAGE_ON_DAMAGE := 0.8                  ## × máu mất
const RAGE_ON_KILL := 4.0                    ## hạ một quái
const DRAIN_GAIN_MULT := 0.25                ## form đang tụt nộ: nộ tích được chỉ bằng chừng này lượng thường
const DRAIN_GAIN_SHARE := 0.6                ## và mỗi giây không quá chừng này phần nộ bị trừ (nộ vẫn luôn giảm)
const FORM_ENTER_MIN_RAGE := 10.0            ## nộ tối thiểu để vào form đặc biệt
const FORM_SWITCH_COST := 10.0               ## nộ tốn mỗi lần đổi sang form đặc biệt
const FINAL_MIN_RAGE := Skills.FINAL_COST    ## nộ của Final Attack (vạch trắng trên thanh nộ)
const VERSUS_BIND_TIME := 1.2                ## chế độ đấu: bị skill trói đứng im tối đa chừng này giây
# Chế độ đấu: hiệu ứng skill của đối thủ lên mình (nhẹ hơn lên quái, xem apply_status / _apply_hit_status).
const VERSUS_FREEZE_TIME := 0.8              ## đòn đóng băng: đứng im
const VERSUS_STUN_TIME := 0.6                ## đòn choáng: đứng im
const VERSUS_SHOCK_TIME := 0.35              ## đòn điện: giật khựng
const VERSUS_BURN_TIME := 2.0                ## đòn cháy: mất máu dần
const VERSUS_BURN_TICK := 0.5
const VERSUS_BURN_RATIO := 0.1               ## mỗi nhịp cháy mất chừng này sát thương của đòn gây cháy
const VERSUS_SLOW_MULT := 0.6                ## skill làm chậm: tốc độ (chạy, ra đòn) còn chừng này
const VERSUS_SLOW_MAX := 2.5
const VERSUS_EXPOSE_MULT := 1.2              ## bị lộ yếu: nhận thêm sát thương
const VERSUS_EXPOSE_MAX := 3.0
const VERSUS_TIME_SOFTEN := 0.5              ## đối thủ tăng tốc thời gian (Clock Up, Axel): mình chậm bằng nửa mức quái
const FLY_SPEED := 120.0                     ## buff bay (Hurricane Fly...): tốc độ lên / xuống
const HIDDEN_ALPHA := 0.3

@export var max_hp := 100
## Hiệu ứng mặc định, form ghi đè từng khóa qua RiderForm.fx().
const DEFAULT_FX := {"hit": "spark", "swing": "", "shot": "ball", "final": "ring", "color": Color(1.0, 0.85, 0.5),
	"trail": false, "glide": false, "intro": "", "signature": ""}
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
var team: StringName = &"player"
var versus_riders: Array[StringName] = []
var net_puppet := false
var net_invulnerable := false  ## net_puppet: đối thủ đang bất tử (theo gói trạng thái gần nhất)
var _pending_form: StringName = &""   ## form sẽ vào khi biến thân / đổi Rider xong (nhặt form)

var _state_timer := 0.0
var _attack: Dictionary = {}
var _attack_kind: StringName = &""
var _attack_phase := 0         ## 0 = startup, 1 = active, 2 = recovery
var _hits_left := 0
var _light_chain := 0          ## số đòn đấm đã ra trong chuỗi hiện tại (tới punch_count thì đòn kế là cú đá)
var _slash_chain := 0          ## số nhát chém đã ra (tới slash_count thì nhát kế là nhát kết)
var _gun: Sprite2D             ## hình súng hiện ở tay lúc bắn
var _gun_timer := 0.0
static var _weapon_textures := {}
var _down_tap := INF           ## giây kể từ lần bấm ↓ trước (bấm đúp để xuống bệ)
var _air_time := 0.0           ## giây kể từ lúc rời mặt đất (COYOTE_TIME)
var _jump_buffer := 0.0        ## còn chừng này giây thì lần bấm Nhảy gần nhất vẫn được tính (JUMP_BUFFER)
var _buffered: StringName = &""
var _combo := 0
var _combo_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _stand_hurtbox_height := 0.0
var _ghost_timer := 0.0
var _feather_timer := 0.0
var _drain_gain_budget := 0.0  ## form đang tụt nộ: lượng nộ còn được tích thêm (gain_rage)
var _parry_timer := 0.0        ## thời gian còn lại của cửa sổ chém đạn (0 = đòn hiện tại không chém đạn)
var _parry_tokens := 0         ## chế độ đấu: số đòn đạn sắp báo về sẽ bỏ qua (đã chém bản sao trên máy này)
var _parry_token_timer := 0.0
var _parry_force := false      ## thế phản đòn [P]: đạn trong tầm luôn bị phản
var _lock_mark := 0.0          ## đang bị đối thủ khoá (chế độ đấu): vẽ khung ngắm
var _slow_time := 0.0          ## chế độ đấu: đang bị skill làm chậm
var _time_slow := 1.0          ## chế độ đấu: đối thủ đang tăng tốc thời gian (set_time_slow)
var _exposed := 0.0            ## chế độ đấu: đang bị lộ yếu
var _burn := 0.0               ## chế độ đấu: còn cháy chừng này giây
var _burn_tick := 0.0
var _burn_damage := 0.0
var _motion := {}              ## vũ đạo của đòn đang ra (Moves, _motion_step): {} = đòn thường đứng tại chỗ
var skills: SkillCaster       ## thi triển Skill 1 / Skill 2 / Final (null ở bản sao mạng)


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	hitbox.team = team
	hurtbox.team = team
	if net_puppet:
		set_physics_process(false)
		return
	hitbox.hit_landed.connect(_on_hit_landed)
	skills = SkillCaster.new(self)
	add_child(skills)
	_gun = Sprite2D.new()
	_gun.centered = false
	_gun.visible = false
	_gun.z_index = 1
	add_child(_gun)
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
	if _lock_mark > 0.0:
		# Bị đối thủ khoá (skill [K] / [T]): khung ngắm đỏ nhấp nháy để kịp Né.
		var mid := Vector2(0, -30)
		var c := Enemy.LOCK_COLOR if Engine.get_process_frames() % 8 < 5 else Color.WHITE
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var corner := mid + Vector2(sx * 24.0, sy * 28.0)
				draw_line(corner, corner - Vector2(sx * 7.0, 0), c, 1.5)
				draw_line(corner, corner - Vector2(0, sy * 7.0), c, 1.5)


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_air_time = 0.0 if is_on_floor() else _air_time + delta
	if Input.is_action_just_pressed("jump") and not input_locked:
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	if current_form:
		current_form.update(delta)
	if skills and skills.flying() and state != State.KO:
		# Buff bay: giữ Nhảy / ↑ bay lên, ↓ hạ xuống, thả thì lơ lửng.
		var up := Input.is_action_pressed("jump") or Input.is_action_pressed("move_up")
		var vy := -1.0 if up and not input_locked else (1.0 if Input.is_action_pressed("move_down") else 0.0)
		velocity.y = move_toward(velocity.y, vy * FLY_SPEED * _time_slow * Units.SCALE, 900.0 * Units.SCALE * delta)
	elif not is_on_floor():
		velocity.y += _gravity * delta * _time_slow * _time_slow   # thời gian chậm: rơi lơ lửng
	if state != State.ATTACK and (not _motion.is_empty() or sprite.rotation != 0.0):
		_motion_reset()            # bị đánh / đổi trạng thái giữa vũ đạo
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
	var buff := skills.speed_mult() if skills else 1.0
	return (current_form.move_speed * current_form.bonus("speed") if current_form else human_speed * GameState.human_bonus("speed")) \
		* time_mult() * buff * Units.SCALE


## Nhịp thời gian của nhân vật: tăng tốc của mình (speed_mult) nhân với làm chậm do đối thủ gây ra (chế độ đấu).
func time_mult() -> float:
	return speed_mult * _time_slow * (VERSUS_SLOW_MULT if _slow_time > 0.0 else 1.0)


# --- Tài nguyên -----------------------------------------------------------

func can_henshin() -> bool:
	return current_form == null and not equipped.is_empty() and rage >= GAUGE_MAX


func can_final() -> bool:
	return current_form != null and rage >= Skills.FINAL_COST


func add_rage(amount: float) -> void:
	_set_rage(rage + amount)


## Nộ tích từ giao chiến (đánh trúng, bị đánh, hạ quái, chém đạn). Form đang tụt nộ: giảm còn DRAIN_GAIN_MULT và
## giới hạn theo _drain_gain_budget (tích DRAIN_GAIN_SHARE × lượng trừ mỗi giây), nên tích luôn ít hơn trừ.
func gain_rage(amount: float) -> void:
	if amount <= 0.0:
		return
	if rage_draining() and in_special_form():
		amount = minf(amount * DRAIN_GAIN_MULT, _drain_gain_budget)
		_drain_gain_budget -= amount
		if amount <= 0.0:
			return
	add_rage(amount)


## Hạ một quái (màn chơi gọi).
func on_enemy_killed() -> void:
	gain_rage(RAGE_ON_KILL)


func _set_rage(value: float) -> void:
	if value >= GAUGE_MAX and rage < GAUGE_MAX and not net_puppet:
		Sound.sfx("rage_full", 0.0)
	rage = clampf(value, 0.0, GAUGE_MAX)
	rage_changed.emit(rage)


func _gain_from_damage(damage_taken: float) -> void:
	gain_rage(damage_taken * RAGE_ON_DAMAGE)


func in_special_form() -> bool:
	return current_form != null and current_form.is_special_form()


## Form hiện tại tụt nộ theo thời gian (tăng tốc thời gian...): nộ là đồng hồ đếm ngược (tích thêm rất ít, gain_rage).
func rage_draining() -> bool:
	return current_form != null and current_form.rage_drain() > 0.0


## Trả nộ cho skill / Final (SkillCaster).
func pay_rage(amount: float) -> void:
	_set_rage(rage - amount)


func has_gun() -> bool:
	return current_form != null and current_form.has_gun()


## RiderForm gọi khi đổi sang form đặc biệt. Đủ nộ thì trừ phí và trả về true.
func pay_form_switch() -> bool:
	if rage_draining():
		return true       # đang ở form đặc biệt: đổi tiếp không tốn thêm (nộ vẫn đang tụt)
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
	_slash_chain = 0
	invincible = true
	velocity.x = 0.0
	if current_form == null:
		state = State.HENSHIN
		_state_timer = HENSHIN_TIME
		_play("henshin", form.animation_prefix())
		_henshin_sound(form)
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
	if _jump_buffer > 0.0 and _air_time <= COYOTE_TIME:
		_jump_buffer = 0.0
		if is_on_floor() and Input.is_action_pressed("move_down") and _on_platform():
			_drop_through()            # ↓ + nhảy trên bệ = xuống khỏi bệ (như Contra)
			return
		_air_time = COYOTE_TIME + 1.0   # đã nhảy: hết quyền nhảy trên không tới khi chạm đất lại
		velocity.y = jump_velocity * Units.SCALE * _time_slow * (current_form.jump_mult * current_form.bonus("jump") if current_form else GameState.human_bonus("jump"))
		Sound.sfx("jump", 0.03, -4.0)
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
	elif Input.is_action_just_pressed("attack_slash"):
		start_attack(&"slash")
	elif Input.is_action_just_pressed("dodge"):
		start_dodge()
	elif Input.is_action_just_pressed("henshin"):
		try_henshin()
	elif Input.is_action_just_pressed("swap_rider"):
		try_swap()
	elif Input.is_action_just_pressed("final_attack"):
		try_final_attack()
	elif Input.is_action_just_pressed("skill_1"):
		try_skill(0)
	elif Input.is_action_just_pressed("skill_2"):
		try_skill(1)
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
	if not _motion.is_empty():
		_motion_step(delta)
		return
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * Units.SCALE * delta)
	if _parry_timer > 0.0:
		_check_parry()
		_parry_timer -= delta * time_mult()
	if skills and skills.drum_active() and not input_locked and Input.is_action_just_pressed("attack_light"):
		skills.drum_hit()
	var cancellable: bool = not _attack.get("no_cancel", false)
	if _attack_phase == 2 and not input_locked and current_form and _skill_pressed() >= 0:
		# Hồi chiêu của đòn thường / skill: bấm skill thì tung ngay (huỷ hồi chiêu).
		var i := _skill_pressed()
		hitbox.deactivate()
		invincible = false
		state = State.NORMAL
		if try_skill(i):
			return
		state = State.ATTACK
	if cancellable:
		if input_locked:
			pass
		elif Input.is_action_just_pressed("attack_light"):
			_buffered = &"light"
		elif Input.is_action_just_pressed("attack_slash"):
			_buffered = &"slash"
		elif _attack_phase == 2 and Input.is_action_just_pressed("dodge"):
			# Né hủy hồi chiêu (dodge cancel)
			hitbox.deactivate()
			start_dodge()
			return
		if _attack_phase == 2 and not input_locked and _switch_cancel():
			return

	_state_timer -= delta * time_mult()   # tăng tốc thời gian: ra đòn nhanh như chạy
	if _state_timer > 0.0:
		return
	match _attack_phase:
		0:
			_attack_phase = 1
			_hits_left = int(_attack.get("hits", 1))
			if _attack.has("lunge"):
				var lunge: Vector2 = _attack["lunge"]
				velocity = Vector2(lunge.x * facing, lunge.y) * Units.SCALE * _time_slow
			if _attack.has("on_active"):
				# Skill: ra đòn bằng hàm riêng (đòn chắc trúng, bắn đạn, bật buff) thay cho hitbox.
				_hits_left = 1
				_state_timer = _attack["active"]
				(_attack["on_active"] as Callable).call()
			else:
				_fire_hitbox()
		1:
			_hits_left -= 1
			if _hits_left > 0:
				_fire_hitbox()
			else:
				hitbox.deactivate()
				_attack_phase = 2
				_state_timer = _attack["recovery"]
				_parry_force = false
				if _attack.has("on_end"):
					(_attack["on_end"] as Callable).call()
		2:
			invincible = false
			state = State.NORMAL
			if _buffered != &"":
				start_attack(_buffered)
			else:
				_light_chain = 0
				_slash_chain = 0


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
	elif Input.is_action_just_pressed("attack_slash"):
		_set_crouch(false)
		start_attack(&"slash")
	elif Input.is_action_just_pressed("dodge"):
		_set_crouch(false)
		start_dodge()
	elif Input.is_action_just_pressed("skill_1") or Input.is_action_just_pressed("skill_2"):
		try_skill(0 if Input.is_action_just_pressed("skill_1") else 1)
	elif Input.is_action_just_pressed("final_attack"):
		_set_crouch(false)
		try_final_attack()


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
	_state_timer -= delta * (_time_slow if state == State.DODGE else 1.0)   # khựng / choáng không kéo dài thêm
	if _state_timer <= 0.0:
		invincible = false
		state = State.NORMAL


func _state_henshin(delta: float) -> void:
	velocity.x = 0.0
	_state_timer -= delta
	if _state_timer > 0.0:
		return
	_enter_form(equipped[active_slot], true)
	# Biến thân dùng hết thanh nộ đầy: vào form gốc với 0 nộ, đánh để tích lại. Nhặt form đặc biệt khi đang là người
	# (transform_into) thì giữ nộ đầy, vì form đặc biệt tụt nộ và về form gốc khi hết.
	if not in_special_form():
		_set_rage(0.0)
	Sound.sfx("henshin_flash", 0.0)
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
	if kind == &"light" or kind == &"slash":
		_face_close_enemy()
	var chain := 0
	if kind == &"light":
		var punches := current_form.punch_count() if current_form else HUMAN_PUNCHES
		if _light_chain >= punches:
			kind = &"kick"
		else:
			chain = _light_chain
	elif kind == &"slash":
		if current_form == null or not current_form.has_blade():
			return
		if _slash_chain >= current_form.slash_count():
			kind = &"slash_finish"
		else:
			chain = _slash_chain
	var data := current_form.get_attack(kind, chain) if current_form else _human_attack(kind, chain)
	if data.is_empty():
		return
	_light_chain = _light_chain + 1 if kind == &"light" else 0
	_slash_chain = _slash_chain + 1 if kind == &"slash" else 0
	if kind == &"kick" and not data.has("anim"):
		data["anim"] = "heavy"   # bộ hình cú đá trong SpriteFrames tên là "<form>_heavy"
	if kind == &"final" and skills and not data.has("motion"):
		var m := skills.final_motion(data)   # vũ đạo Final theo nguyên tác (Moves)
		if not m.is_empty():
			data["motion"] = m
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
	var muzzle := _muzzle(aim)
	var count: int = shot["count"]
	for i in count:
		var p := Projectile.new()
		p.team = team
		p.damage = float(shot["damage"]) * _damage_mult()
		p.radius = shot["radius"]
		p.color = shot["color"]
		p.pierce = shot["pierce"]
		p.life = shot["life"]
		p.source = self
		if shot.has("tags"):
			p.tags = p.tags + Array(shot["tags"])   # đạn mang hiệu ứng của form (&"burn"...)
		p.tags = p.tags + current_form.special_tags() + skills.extra_tags()
		p.homing = skills.homing()
		p.style = str(current_fx()["shot"])
		p.hit_fx = str(current_fx()["hit"])
		var offset: float = (i - (count - 1) / 2.0) * float(shot["spread"])
		p.velocity = aim.rotated(offset) * float(shot["speed"]) * Units.SCALE
		p.hit_landed.connect(_on_hit_landed)
		get_parent().add_child(p)
		p.global_position = global_position + muzzle
		shot_fired.emit(p)
	_show_gun(aim)
	var shot_sfx: String = {"bolt": "shot_bolt", "fire": "shot_fire", "arrow": "shot_arrow"}.get(str(current_fx()["shot"]), "shot_ball")
	Sound.sfx("shot_heavy" if float(shot["damage"]) >= 10.0 else shot_sfx, 0.08, -3.0)


## Chỗ đạn bay ra (so với chân nhân vật): ngang ngực, cúi thì thấp xuống, bắn thẳng lên thì trên đầu.
func _muzzle(aim: Vector2) -> Vector2:
	if aim.y < -0.5 and aim.x == 0.0:
		return Vector2(4.0 * facing, -58.0)
	return Vector2(14.0 * facing, -18.0 if state == State.CROUCH else -34.0)


## Súng của form hiện ở tay, chĩa theo hướng bắn, nòng ở chỗ đạn bay ra. Ảnh súng: báng ở mép trái, nòng ở mép phải.
## Giữ nút Bắn thì súng ở yên trên tay (không tắt giữa hai phát), thả nút thì cất sau GUN_SHOW_TIME giây.
func _show_gun(aim: Vector2) -> void:
	if _gun == null or current_form == null:
		return
	var tex := _weapon_texture(current_form.gun_look())
	if tex == null:
		return
	_gun.texture = tex
	_gun.offset = Vector2(-2.0, -tex.get_height() / 2.0)
	_aim_gun(aim)
	_gun.visible = true
	_gun_timer = GUN_SHOW_TIME


func _aim_gun(aim: Vector2) -> void:
	_gun.rotation = aim.angle()
	_gun.flip_v = aim.x < 0.0
	_gun.position = _muzzle(aim) - aim.normalized() * (_gun.texture.get_width() - 2.0)


func _hide_gun() -> void:
	if _gun:
		_gun.visible = false
	_gun_timer = 0.0


static func _weapon_texture(look: String) -> Texture2D:
	if look == "":
		return null
	if not _weapon_textures.has(look):
		var path := "res://art/characters/weapons/%s.png" % look
		_weapon_textures[look] = load(path) if ResourceLoader.exists(path) else null
	return _weapon_textures[look]


## Hướng bắn. Nút ▲ cảm ứng bấm cùng lúc "jump" và "move_up": đang giữ nhảy thì "move_up" là của nút nhảy, không
## tính là ngắm lên (nếu không, nhảy mà bắn thì đạn bay thẳng lên trời). Ngắm lên bằng W / ↑ trên bàn phím.
func aim_dir() -> Vector2:
	return _aim_dir()


func _aim_dir() -> Vector2:
	var x := Input.get_axis("move_left", "move_right")
	var y := 0.0
	if Input.is_action_pressed("move_up") and not Input.is_action_pressed("jump"):
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
	_jump_buffer = 0.0
	_air_time = COYOTE_TIME + 1.0   # xuống khỏi bệ không phải bước hụt: không nhảy ngược lên được
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
	return invincible or _grace_timer > 0.0 or (skills != null and skills.invulnerable())


## Tàng hình (Attack Ride: Invisible): quái mất dấu.
func is_hidden() -> bool:
	return skills != null and skills.hidden()


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
	velocity.x = d * dodge_speed * Units.SCALE * _time_slow * (1.2 if current_form == null else 1.0)
	_play("dodge")
	Sound.sfx("dodge")


func try_henshin() -> void:
	if not can_henshin():
		return
	state = State.HENSHIN
	_state_timer = HENSHIN_TIME
	invincible = true
	velocity.x = 0.0
	_play("henshin", equipped[active_slot].animation_prefix())
	_henshin_sound(equipped[active_slot])


## Âm thanh biến thân: tiếng món đồ biến thân riêng của Rider (audio/sfx/henshin_<rider>), Sora hô "Henshin!",
## rồi giọng đai (audio/voice/<rider>_henshin, như "Standing by... Complete").
func _henshin_sound(form: RiderForm) -> void:
	var rid := String(form.rider_id)
	if Sound.henshin_ext(rid):
		return          # tiếng biến thân lấy từ phim đã gồm tiếng đai + tiếng hô
	Sound.sfx("henshin_" + rid if Sound.has_sfx("henshin_" + rid) else "henshin_charge", 0.0)
	Sound.voice("hero_henshin")
	Sound.voice(rid + "_henshin", 0.6)


## Đổi sang form khác (Special, nhặt form, hết nộ về form gốc): tiếng chuyển form + giọng đai của form ("Rod Form").
func on_form_changed(form: RiderForm) -> void:
	if net_puppet:
		return
	if form == current_form:
		skills.clear()
	Sound.sfx("form_change", 0.0)
	Sound.voice("%s_%s" % [form.rider_id, form.current_form_id()])
	if form == current_form:
		var fx := current_fx()
		var mark := str(fx["intro"]) if str(fx["intro"]) != "" else (str(fx["signature"]) if str(fx["signature"]) != "" else "ring")
		if Summon.has(mark):     # quái thú của Rider (Dragreder...): đổi form chỉ hiện vòng sáng, quái thú để dành cho Final
			mark = "ring"
		Fx.spawn(get_parent(), global_position + Vector2(0, -28) * Units.SCALE, mark, fx["color"], facing, 1.4)
		CombatDirector.skill_used.emit(form.form_display_name(), fx["color"])


## Qua màn: giải trừ biến thân. Chạy ngược cảnh biến thân của Rider đang mang (Rider chưa có sprite thì chỉ chớp
## sáng), xong thì về dạng người. Không mất nộ, không choáng như Henshin Break. Đang ở dạng người thì bỏ qua.
func release_henshin() -> void:
	if current_form == null or state == State.KO:
		return
	_set_crouch(false)
	hitbox.deactivate()
	_light_chain = 0
	_slash_chain = 0
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
	max_hp = int(round(BASE_HUMAN_HP * GameState.human_power() * GameState.human_bonus("hp")))
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	_set_rage(GAUGE_MAX)
	swap_cooldown = 0.0
	dodge_cooldown = 0.0
	shoot_cooldown = 0.0
	if skills:
		skills.clear(true)
	_combo = 0
	combo_changed.emit(0)
	_clear_status()
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


## Final Attack (O / nút Tuyệt chiêu): kiểu đòn theo form (SkillCaster.try_final).
func try_final_attack() -> void:
	if skills and can_final():
		skills.try_final()


## Skill 1 / Skill 2 của form (U / Y). Trả true nếu đã tung.
func try_skill(i: int) -> bool:
	if skills == null or current_form == null or state not in [State.NORMAL, State.CROUCH]:
		return false
	_set_crouch(false)
	_face_close_enemy()   # quái sát sau lưng mà trước mặt trống: quay lại rồi mới tung
	return skills.try_skill(i)


func _skill_pressed() -> int:
	if Input.is_action_just_pressed("skill_1"):
		return 0
	if Input.is_action_just_pressed("skill_2"):
		return 1
	return -1


## Tiếng nạp, giọng đai, dấu hiệu tuyệt chiêu quanh Rider và phông tuyệt chiêu lúc tung Final.
func final_fanfare() -> void:
	Sound.sfx("final_charge", 0.0)
	Sound.voice("%s_final" % current_form.rider_id)
	var fx := current_fx()
	if Summon.has(str(fx["intro"])):     # quái thú lượn một vòng quanh Rider rồi đẩy cú đá (Final Vent của Ryuki)
		Summon.spawn(get_parent(), str(fx["intro"]), global_position,
			global_position + Vector2(facing * 200.0, -30.0) * Units.SCALE, facing, "orbit")
	elif str(fx["intro"]) != "":       # dấu hiệu tuyệt chiêu riêng quanh Rider (vòng Medal OOO...)
		Fx.spawn(get_parent(), global_position + Vector2(0, -30) * Units.SCALE, str(fx["intro"]), fx["color"], facing, 1.2)
	CombatDirector.final_attack_started.emit(current_form.rider_id, current_form.final_attack_name())


## Được Hurtbox gọi. Trả về true nếu đòn trúng.
func take_hit(info: DamageInfo) -> bool:
	if state == State.KO:
		return false
	if net_puppet:
		# Đoán theo trạng thái nhận qua mạng; máy của đối thủ mới quyết định trừ máu (take_hit trên bản thật).
		if net_invulnerable and not (state == State.DODGE and info.has_tag(&"ranged")):
			return false
		net_hit.emit(info)
		return true
	# Chế độ đấu: viên đạn này đã bị chém tan trên máy này (bản sao), máy đối thủ báo trúng trễ thì bỏ qua.
	if _parry_tokens > 0 and info.has_tag(&"ranged"):
		_parry_tokens -= 1
		return false
	# Né chỉ tránh được đòn cận chiến; đạn phải nhảy hoặc cúi mà tránh.
	var dodging_bullet := state == State.DODGE and _grace_timer <= 0.0 and info.has_tag(&"ranged")
	if is_invulnerable() and not dodging_bullet:
		return false
	if skills and skills.intercept_hit(info):
		return false      # phản đòn [P], tự né (Prediction), thân lỏng (Liquid)
	var blocking := state == State.CROUCH
	var mult := CROUCH_DAMAGE_MULT if blocking else 1.0
	if _exposed > 0.0:
		mult *= VERSUS_EXPOSE_MULT
	var holds := info.has_tag(&"bind") or (GameState.versus and _hold_time(info) > 0.0)
	if current_form:
		var dmg := current_form.modify_incoming_damage(info) * mult * skills.guard_mult()
		if not GameState.versus:
			# Một đòn của quái / trùm (kể cả chiêu cuối) không lấy quá MAX_HIT_SHARE máu Rider.
			dmg = minf(dmg, current_form.get_max_hp() * MAX_HIT_SHARE)
		if not blocking:
			_grace_timer = maxf(_grace_timer, HIT_INVULN_RIDER)
		rider_hp -= dmg
		rider_hp_changed.emit(maxf(rider_hp, 0.0), current_form.get_max_hp())
		Sound.sfx("hurt", 0.08, -3.0)
		_gain_from_damage(dmg)
		if rider_hp <= 0.0:
			_henshin_break()
			return true
		_apply_hit_status(info)
		if info.damage < current_form.poise * current_form.bonus("poise") and not holds:
			return true   # siêu giáp: đòn nhẹ không làm Rider khựng
		if skills.superarmor() and not holds:
			return true   # buff thân thép (Metal Trilobite): không bị khựng
	else:
		var dmg := info.damage * 100.0 / (100.0 + HUMAN_ARMOR) * mult
		if not blocking:
			_grace_timer = maxf(_grace_timer, HIT_INVULN_HUMAN)
		hp -= ceili(dmg)
		Sound.sfx("hurt", 0.08, -3.0)
		hp_changed.emit(maxi(hp, 0), max_hp)
		_gain_from_damage(dmg)
		if hp <= 0:
			_die()
			return true
		_apply_hit_status(info)
	if blocking:
		return true   # đang thủ thế: không bị khựng, không bị đẩy
	hitbox.deactivate()
	skills.interrupt()      # đang tụ skill / thế đỡ / đánh trống: hỏng
	_light_chain = 0
	_slash_chain = 0
	state = State.HURT
	_state_timer = HURT_TIME
	velocity = Vector2(info.knockback.x * _knock_dir(info), info.knockback.y) * Units.SCALE
	if info.has_tag(&"bind") and info.bind_time > 0.0:
		# Bị đối thủ trói (chế độ đấu): đứng im.
		_state_timer = minf(info.bind_time, VERSUS_BIND_TIME)
		velocity = Vector2.ZERO
	elif GameState.versus and _hold_time(info) > 0.0:
		# Đóng băng / choáng / giật điện do đối thủ (chế độ đấu): đứng im ngắn.
		_state_timer = maxf(_state_timer, _hold_time(info))
		velocity = Vector2.ZERO
	_play("hurt")
	return true


## Chế độ đấu: thời gian đứng im theo tag của đòn (0 = không).
func _hold_time(info: DamageInfo) -> float:
	var t := 0.0
	if info.has_tag(&"freeze"):
		t = VERSUS_FREEZE_TIME
	if info.has_tag(&"stun"):
		t = maxf(t, VERSUS_STUN_TIME)
	if info.has_tag(&"shock"):
		t = maxf(t, VERSUS_SHOCK_TIME)
	return t


## Chế độ đấu: đòn của đối thủ gây cháy thì mất máu dần (gọi sau khi trừ máu, còn đứng).
func _apply_hit_status(info: DamageInfo) -> void:
	if not GameState.versus or not info.has_tag(&"burn"):
		return
	_burn = VERSUS_BURN_TIME
	_burn_damage = maxf(_burn_damage if _burn_tick > 0.0 else 0.0, maxf(info.damage * VERSUS_BURN_RATIO, 1.0))
	_burn_tick = VERSUS_BURN_TICK


## Chế độ đấu: hiệu ứng skill của đối thủ không qua đòn đánh ("slow" làm chậm, "expose" lộ yếu = nhận thêm sát thương).
## versus.gd gọi theo tin nhắn mạng; trên cùng máy thì SkillCaster gọi qua inflict_status.
func apply_status(kind: String, time: float) -> void:
	if state == State.KO:
		return
	match kind:
		"slow":
			_slow_time = minf(maxf(_slow_time, time), VERSUS_SLOW_MAX)
		"expose":
			_exposed = minf(maxf(_exposed, time), VERSUS_EXPOSE_MAX)
	_update_status_tint()


## Chế độ đấu: đối thủ đang tăng tốc thời gian, `enemy_scale` = hệ số họ làm chậm quái (1 = hết).
## Thời gian chậm làm chậm mọi nhịp: chạy, ra đòn, skill, né, nhảy / rơi, hồi chiêu, đạn mình bắn (Projectile hỏi
## clock_mult). Riêng khựng / choáng không kéo dài thêm. Bản sao mạng cũng được đặt để đạn bản sao bay chậm khớp.
func set_time_slow(enemy_scale: float) -> void:
	var old := _time_slow
	_time_slow = lerpf(1.0, clampf(enemy_scale, 0.0, 1.0), VERSUS_TIME_SOFTEN)
	if not net_puppet and not is_equal_approx(old, _time_slow):
		velocity *= _time_slow / old      # đang bay / rơi giữa chừng: chậm lại ngay
	_update_status_tint()


## Hệ số thời gian do đối thủ tăng tốc thời gian (1 = bình thường).
func clock_mult() -> float:
	return _time_slow


## Gây hiệu ứng `kind` lên `target` (quái, hoặc người chơi khác phe ở chế độ đấu). Bản sao mạng thì báo versus.gd gửi đi.
func inflict_status(target: Node, kind: String, time: float) -> void:
	if target is Enemy:
		match kind:
			"slow":
				(target as Enemy).slow(time)
			"expose":
				(target as Enemy).expose(time)
	elif target is Player and target != self and (target as Player).team != team:
		if (target as Player).net_puppet:
			status_inflicted.emit(target, kind, time)
		else:
			(target as Player).apply_status(kind, time)


func _clear_status() -> void:
	_slow_time = 0.0
	_time_slow = 1.0
	_exposed = 0.0
	_burn = 0.0
	_burn_tick = 0.0
	_update_status_tint()


func _tick_status(delta: float) -> void:
	if _slow_time <= 0.0 and _exposed <= 0.0 and _burn <= 0.0:
		return
	_slow_time = maxf(_slow_time - delta, 0.0)
	_exposed = maxf(_exposed - delta, 0.0)
	if _burn > 0.0:
		_burn -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0 and state != State.KO:
			_burn_tick = VERSUS_BURN_TICK
			_lose_hp(_burn_damage)
	_update_status_tint()


## Mất máu không khựng (cháy): Rider về 0 thì Henshin Break, người về 0 thì gục.
func _lose_hp(dmg: float) -> void:
	if current_form:
		rider_hp -= dmg
		rider_hp_changed.emit(maxf(rider_hp, 0.0), current_form.get_max_hp())
		if rider_hp <= 0.0:
			_burn = 0.0
			_henshin_break()
	else:
		hp -= ceili(dmg)
		hp_changed.emit(maxi(hp, 0), max_hp)
		if hp <= 0:
			_burn = 0.0
			_die()


## Màu báo hiệu ứng trên người: cháy cam, chậm tím, lộ yếu đỏ.
func _update_status_tint() -> void:
	var c := Color.WHITE
	if _burn > 0.0:
		c = Color(1.0, 0.7, 0.5)
	elif _slow_time > 0.0 or _time_slow < 1.0:
		c = Color(0.75, 0.7, 1.0)
	elif _exposed > 0.0:
		c = Color(1.0, 0.6, 0.6)
	sprite.self_modulate = c


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
		"skill_1", "skill_2":
			if skills:
				return skills.cooldown_of(0 if action == "skill_1" else 1)
	return Vector2.ZERO


## Action có dùng được ngay lúc này không (đủ nộ, đã mở khóa, đủ điều kiện).
func is_action_available(action: String) -> bool:
	match action:
		"special":
			return current_form != null and current_form.special_available() \
				and (not in_special_form() or current_form.special_anywhere()) and rage >= FORM_ENTER_MIN_RAGE
		"swap_rider":
			return current_form != null and equipped.size() >= 2
		"ultimate":
			return can_final() or can_henshin()
		"final_attack":
			return can_final()
		"skill_1", "skill_2":
			return skills != null and skills.can_use(0 if action == "skill_1" else 1)
	return true


## Nút có nên hiện không. Chưa mở khóa thì ẩn hẳn (dạng người chỉ có nút cơ bản).
func is_action_visible(action: String) -> bool:
	match action:
		"shoot":
			return has_gun()
		"attack_slash":
			return current_form != null and current_form.has_blade()
		"special":
			return current_form != null and current_form.special_available() \
				and (not in_special_form() or current_form.special_anywhere())
		"swap_rider":
			return current_form != null and equipped.size() >= 2
		"ultimate":
			return current_form == null and not equipped.is_empty()
		"final_attack":
			return current_form != null
		"skill_1", "skill_2":
			return skills != null and not skills.skill(0 if action == "skill_1" else 1).is_empty()
		"help":
			return HelpOverlay.enabled()
	return true


## Chữ dưới nút, đổi theo dạng hiện tại. Trả về "" để giữ nhãn mặc định.
func action_label(action: String) -> String:
	match action:
		"special":
			return current_form.special_label() if current_form else ""
		"ultimate":
			return "Tuyệt chiêu" if current_form else "Biến thân"
	return ""


## Hình trên nút skill / Final (SkillIcons). null = dùng biểu tượng mặc định của nút.
func action_icon(action: String) -> Texture2D:
	match action:
		"skill_1", "skill_2":
			if skills:
				var sk := skills.skill(0 if action == "skill_1" else 1)
				if not sk.is_empty():
					return SkillIcons.texture(SkillIcons.pick(sk))
		"final_attack":
			return SkillIcons.texture("kick")
	return null


## Số nộ action cần (vẽ trên nút). 0 = không tốn nộ.
func action_cost(action: String) -> int:
	match action:
		"skill_1", "skill_2":
			if skills:
				return int(skills.skill(0 if action == "skill_1" else 1).get("cost", 0))
		"final_attack":
			return int(Skills.FINAL_COST)
	return 0


# --- Cho SkillCaster gọi --------------------------------------------------

## Ra đòn skill / Final theo dữ liệu make_attack (kèm "on_active", "on_end", "parry", "bind_time" tùy chọn).
func begin_skill(kind: StringName, data: Dictionary) -> void:
	_set_crouch(false)
	_light_chain = 0
	_slash_chain = 0
	_begin_attack(kind, data)


## Tag cộng thêm vào đòn skill đánh thẳng (không qua hitbox): tag đặc tính form và buff.
func attack_tags(base: Array) -> Array:
	var tags := base.duplicate()
	var extra: Array = current_form.special_tags() if current_form else []
	if skills:
		extra = extra + skills.extra_tags()
	for t in extra:
		if not tags.has(t):
			tags.append(t)
	return tags


## Đạn của skill: sát thương gốc `damage` (nhân sức đánh như đòn thường), bay theo `vel`.
func spawn_projectile(damage: float, vel: Vector2, radius: float, color: Color, pierce: bool, life: float,
		style: String, tags: Array) -> Projectile:
	var p := Projectile.new()
	p.team = team
	p.damage = damage * _damage_mult()
	p.radius = radius
	p.color = color
	p.pierce = pierce
	p.life = life
	p.source = self
	p.style = style
	p.hit_fx = str(current_fx()["hit"])
	p.tags = attack_tags([&"ranged"] + tags)
	p.velocity = vel
	p.hit_landed.connect(_on_hit_landed)
	get_parent().add_child(p)
	p.global_position = global_position + _muzzle(vel.normalized())
	shot_fired.emit(p)
	return p


func on_skill_hit(target: Node, info: DamageInfo) -> void:
	_on_hit_landed(target, info)


## Phản đòn [P] vừa bắt được đòn: tung đòn đáp trả, bất tử ngắn.
func counter_pose(final: bool) -> void:
	hitbox.deactivate()
	_grace_timer = maxf(_grace_timer, 0.4)
	_attack_phase = 2
	_state_timer = 0.35
	_parry_force = false
	sprite.flip_h = facing < 0
	_play("final" if final else "heavy", "", true)
	if final:
		# Kabuto Rider Kick: xoay người một vòng rồi đá vòng vào kẻ vừa lao tới.
		var tw := create_tween()
		tw.tween_property(sprite, "scale:x", -absf(sprite.scale.x), 0.06)
		tw.tween_property(sprite, "scale:x", absf(sprite.scale.x), 0.06)
	Sound.sfx("parry_perfect", 0.0)
	if team == &"player":
		CombatDirector.hit_stop(0.08, 0.1)


## Buff Prediction: tự né đòn vừa tới.
func auto_dodge() -> void:
	dodge_cooldown = 0.0
	if state == State.ATTACK:
		hitbox.deactivate()
		state = State.NORMAL
	start_dodge()
	_grace_timer = maxf(_grace_timer, dodge_time)


## Hồi `ratio` phần máu Rider tối đa (Kiva Bat...).
func heal_rider(ratio: float) -> void:
	if current_form == null:
		return
	rider_hp = minf(rider_hp + current_form.get_max_hp() * ratio, current_form.get_max_hp())
	rider_hp_changed.emit(rider_hp, current_form.get_max_hp())


func face(dir: int) -> void:
	facing = 1 if dir >= 0 else -1
	sprite.flip_h = facing < 0


func play_anim(action: String) -> void:
	_play(action, "", true)


## Buff bật / tắt: bóng mờ tàng hình, chữ trạng thái.
func on_buffs_changed() -> void:
	sprite.modulate.a = HIDDEN_ALPHA if is_hidden() else 1.0


## Bị đối thủ khoá (chế độ đấu, versus.gd gọi theo tin nhắn mạng): hiện khung ngắm `time` giây.
func mark_lock(time: float) -> void:
	_lock_mark = maxf(_lock_mark, time)
	queue_redraw()


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
	for id in (versus_riders if not versus_riders.is_empty() else GameState.equipped):
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


## Đang hồi chiêu: bấm nút đòn khác loại (đấm ↔ chém) thì ra đòn mới ngay; giữ Bắn (form có súng) thì bắn ngay.
## Nối đòn cùng loại vẫn chờ hồi chiêu như cũ. Trả true nếu đã chuyển.
func _switch_cancel() -> bool:
	var to_shoot := Input.is_action_pressed("shoot") and has_gun() and shoot_cooldown <= 0.0
	var next := _buffered
	if not to_shoot and (next == &"" or _attack_group(next) == _attack_group(_attack_kind)):
		return false
	hitbox.deactivate()
	invincible = false
	state = State.NORMAL
	_buffered = &""
	if to_shoot:
		_light_chain = 0
		_slash_chain = 0
		try_shoot()
	else:
		start_attack(next)
	return true


static func _attack_group(kind: StringName) -> StringName:
	if kind == &"light" or kind == &"kick":
		return &"hand"
	if kind == &"slash" or kind == &"slash_finish":
		return &"blade"
	return kind


## Tiếng đòn trúng: trúng thường / nặng, tiếng hiệu ứng (cháy, điện, băng, choáng), Final trúng thì nổ lớn.
func _hit_sound(info: DamageInfo) -> void:
	Sound.sfx("hit_heavy" if info.has_tag(&"heavy") or info.has_tag(&"final") else "hit")
	for tag in [&"burn", &"shock", &"freeze", &"stun"]:
		if info.has_tag(tag):
			Sound.sfx(String(tag), 0.04, -4.0)
	if info.has_tag(&"final"):
		Sound.sfx("final_impact", 0.0)


func _begin_attack(kind: StringName, data: Dictionary) -> void:
	var swing_sound := current_form.swing_sfx(kind) if current_form else ("kick" if kind == &"kick" else "punch")
	if swing_sound != "" and not net_puppet:
		Sound.sfx(swing_sound, 0.08, -2.0)
	_attack = data
	_attack_kind = kind
	_attack_phase = 0
	_state_timer = data["startup"]
	_parry_timer = PARRY_WINDOW if current_form and not net_puppet and current_form.can_parry(kind) else 0.0
	_parry_force = bool(data.get("parry", false)) and not net_puppet
	if _parry_force:
		_parry_timer = float(data["active"]) + 0.05
	_buffered = &""
	state = State.ATTACK
	invincible = kind in [&"final", &"swap_in", &"henshin"] and not data.has("parry")
	_play(str(data.get("anim", kind)), "", true)
	_motion_reset()
	if data.has("motion") and not net_puppet:
		_motion_begin(data["motion"])
	var fx := current_fx()
	var swing := str(fx["swing"])
	if current_form and swing != "" and not (&"ranged" in data["tags"]):
		var off: Vector2 = data["offset"]
		Fx.spawn(get_parent(), global_position + Vector2(off.x * facing, off.y) * Units.SCALE, swing, fx["color"],
			facing, 1.3 if kind in [&"kick", &"final"] else 1.0)


# --- Vũ đạo đòn theo nguyên tác (Moves) ------------------------------------------

const MOTION_GHOST := 0.03             ## giây giữa hai bóng mờ khi lao đòn
const KICK_BOX := Vector2(30, 30)      ## vùng đòn cú đá lao: chân dẫn đầu, chéo xuống phía trước
const KICK_OFFSET := Vector2(14, -10)
const DASH_BOX := Vector2(44, 34)      ## vùng đòn khi lướt xuyên: cả thân người
const DASH_OFFSET := Vector2(6, -18)
const SPIN_BOX := Vector2(64, 26)      ## đá xoay vòng: trúng cả trước lẫn sau
const DRILL_TICKS := 4
const SLAM_WIDTH := 64.0               ## sóng xung kích khi giáng xuống: rộng tối thiểu (trúng cả hai bên)
const SLAM_DAMAGE := 0.8               ## trúng cả vùng nên nhẹ hơn đòn một mục tiêu (như Final kiểu vùng)
const DRILL_FIRST := 0.4               ## đá khoan: cú chạm đầu chừng này phần sát thương, phần còn lại chia cho các nhịp khoan
const KICK_AIM_RANGE := 260.0         ## cú đá không khoá vẫn ngắm mềm quái gần nhất phía trước trong tầm này
const KICK_AIM_SLACK := 0.6            ## lệch tối đa (radian) so với góc đá của vũ đạo
const KICK_CONTACT := 26.0             ## Final khoá: chạm mục tiêu khi tâm người cách tâm quái chừng này (đơn vị thiết kế)


## Bắt đầu vũ đạo `m` (Moves). Final khoá truyền m["targets"] và m["strike"] (Callable(mục tiêu, hệ số sát thương)):
## lao vào lần lượt từng mục tiêu, chạm là đánh chắc trúng. Không có targets thì cú lao bật hitbox như đòn thường.
func _motion_begin(m: Dictionary) -> void:
	_motion = m.duplicate()
	var targets: Array = (m.get("targets", []) as Array).duplicate()
	_motion["targets"] = targets
	_motion["left"] = maxi(int(m.get("repeat", 1)), 1) * maxi(targets.size(), 1)
	_motion["done"] = 0
	_motion_phase("charge")


func _motion_reset() -> void:
	if _motion.is_empty() and sprite.rotation == 0.0:
		return
	_motion = {}
	sprite.rotation = 0.0
	sprite.flip_h = facing < 0
	if not sprite.is_playing():
		sprite.play()


func _motion_end() -> void:
	hitbox.deactivate()
	_motion_reset()
	invincible = _attack_kind == &"final"
	_attack_phase = 2
	_state_timer = float(_attack["recovery"])
	_play("idle" if is_on_floor() else "jump", "", true)
	if _attack.has("on_end"):
		(_attack["on_end"] as Callable).call()


func _motion_phase(p: String) -> void:
	_motion["phase"] = p
	_motion["t"] = 0.0
	var type := str(_motion["type"])
	match p:
		"charge":
			if type == "spin":
				sprite.flip_h = facing > 0          # quay lưng về phía quái, chờ rồi xoay người đá
				_play("idle", "", true)
			elif type == "through":
				_hold_frame(str(_motion.get("anim", "slash")), 0.0)
			else:
				_play("crouch", "", true)           # thủ thế, khuỵu gối lấy đà
		"rise":
			_motion_face()
			hitbox.deactivate()
			sprite.rotation = 0.0
			_play("jump", "", true)
		"pose":
			_hold_frame(str(_motion.get("anim", "final")), float(_motion.get("frac", 0.65)))
			if not _motion_targeted() and skills:
				var near := skills.find_targets(KICK_AIM_RANGE, 1)   # cú đá ngắm quái gần nhất phía trước
				_motion["aim_at"] = near[0] if not near.is_empty() else null
		"dive":
			_motion.erase("contact")
			if not _motion_targeted():
				_fire_hitbox(_hits_scale() * _kick_scale(), KICK_BOX, KICK_OFFSET)
		"drill":
			_motion["tick"] = 0.0
			Fx.spawn(get_parent(), global_position + Vector2(facing * 14.0, -14.0) * Units.SCALE, "drill",
				current_fx()["color"], facing, 1.2)
		"pass":
			hitbox.deactivate()
		"bounce":
			hitbox.deactivate()
			sprite.rotation = 0.0
			velocity = Vector2(-facing * 170.0, -300.0) * Units.SCALE   # bật ngược ra sau sau cú đá
			_play("jump", "", true)
			sprite.play()
		"dash":
			invincible = true
			_motion_face()
			_motion["x0"] = global_position.x
			_motion["struck"] = []
			var reach := float(_motion.get("dist", 150.0))
			for tgt in _motion["targets"]:
				if is_instance_valid(tgt):
					reach = maxf(reach, absf((tgt as Node2D).global_position.x - global_position.x) / Units.SCALE + 34.0)
			_motion["reach"] = reach
			_hold_frame(str(_motion.get("anim", "slash")), 0.99)
			if not _motion_targeted():
				_fire_hitbox(_hits_scale(), DASH_BOX, DASH_OFFSET)
		"hold":
			hitbox.deactivate()
			for tgt in _motion["targets"]:       # khoá: quái chưa bị lướt qua vẫn trúng (chắc trúng)
				if not (_motion["struck"] as Array).has(tgt):
					_motion_strike(tgt, 1.0)
		"fall":
			_hold_frame(str(_motion.get("anim", "slash")), 0.35)
		"impact":
			sprite.play()
			var size: Vector2 = _attack["size"]
			size = Vector2(maxf(size.x, SLAM_WIDTH), maxf(size.y, 40.0))
			Fx.spawn(get_parent(), global_position + Vector2(0, -6) * Units.SCALE, "ring", current_fx()["color"],
				facing, size.x / 30.0)
			CombatDirector.shake(4.0)
			if _motion_targeted():
				for tgt in _motion["targets"]:
					_motion_strike(tgt, 1.0)
			else:
				var widened := (_attack["size"] as Vector2).x < SLAM_WIDTH   # Final kiểu vùng đã giảm sát thương sẵn
				_fire_hitbox(_hits_scale() * (SLAM_DAMAGE if widened else 1.0), size, Vector2(4, -14))
		"spin":
			sprite.flip_h = facing < 0
			_play("final", "", true)
			if not _motion_targeted():
				_fire_hitbox(_hits_scale(), SPIN_BOX, Vector2(4, -14))


func _motion_step(delta: float) -> void:
	var m := _motion
	var s := Units.SCALE * _time_slow
	m["t"] = float(m["t"]) + delta * time_mult()
	var t := float(m["t"])
	var type := str(m["type"])
	match str(m["phase"]):
		"charge":
			velocity.x = move_toward(velocity.x, 0.0, 1800.0 * s * delta)
			if t >= float(_attack["startup"]):
				match type:
					"kick", "slam":
						_motion_phase("rise")
					"through":
						_motion_phase("dash")
					_:
						_motion_phase("spin")
		"rise":
			var rise := float(m.get("rise", 360.0))
			var rise_t := float(m.get("rise_t", 0.3))
			velocity = Vector2(facing * rise * (0.22 if type == "kick" else 0.15), -rise * clampf(1.0 - t / rise_t, 0.0, 1.0)) * s
			if t >= rise_t:
				_motion_phase("pose" if type == "kick" else "fall")
		"pose":
			velocity = Vector2.ZERO
			var pose_t := maxf(float(m.get("pose_t", 0.12)), 0.01)
			sprite.rotation = lerpf(0.0, _dive_rot(_dive_dir()), clampf(t / pose_t, 0.0, 1.0))
			if t >= pose_t:
				_motion_phase("dive")
		"dive":
			var dir := _dive_dir()
			velocity = dir * float(m.get("speed", 540.0)) * s
			sprite.rotation = _dive_rot(dir)
			_motion_ghost(delta)
			var hit := _motion_contact(t)
			if hit != null:
				_kick_contact(hit)
			elif (is_on_floor() and t > 0.05) or t > float(m.get("max_t", 0.75)):
				_kick_landed()
		"drill":
			velocity = Vector2.ZERO
			var drill := float(m.get("drill", 0.4))
			sprite.rotation = _dive_rot(_dive_dir()) + sin(t * 70.0) * 0.1   # khoan rung
			m["tick"] = float(m["tick"]) + delta * time_mult()
			if float(m["tick"]) >= drill / DRILL_TICKS:
				m["tick"] = 0.0
				var per := (1.0 - DRILL_FIRST) / DRILL_TICKS / float(maxi(int(m.get("repeat", 1)), 1))
				var tgt = m.get("hit_at")
				if _motion_targeted():
					if tgt is Node2D and is_instance_valid(tgt):
						_motion_strike(tgt, per)
				else:
					_fire_hitbox(_hits_scale() * per, KICK_BOX, KICK_OFFSET)
			if t >= drill:
				_kick_done()
		"pass":
			_motion_ghost(delta)
			if t >= 0.1:
				if not _motion_targeted():
					face(-facing)                     # dội ngược lại đá tiếp (SpeeDrop)
				m["rise_t"] = minf(float(m.get("rise_t", 0.3)), 0.14)
				m["rise"] = minf(float(m.get("rise", 360.0)), 260.0)
				m["pose_t"] = 0.04
				_motion_phase("rise")
		"bounce":
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * s * delta)
			if (is_on_floor() and t > 0.1) or t > 1.2:
				_motion_end()
		"dash":
			velocity = Vector2(facing * float(m.get("speed", 700.0)), 0.0) * s
			_motion_ghost(delta)
			for tgt in m["targets"]:
				if is_instance_valid(tgt) and not (m["struck"] as Array).has(tgt) \
						and ((tgt as Node2D).global_position.x - global_position.x) * facing <= 0.0:
					_motion_strike(tgt, 1.0)
			if absf(global_position.x - float(m["x0"])) >= float(m["reach"]) * s or is_on_wall() or t > 0.6:
				velocity.x = 0.0
				_motion_phase("hold")
		"hold":
			velocity.x = 0.0                          # đứng thủ thế sau lưng quái (zanshin)
			if t >= 0.22:
				_motion_end()
		"fall":
			velocity = Vector2(facing * 50.0, 780.0) * s
			if (is_on_floor() and t > 0.02) or t > 1.0:
				_motion_phase("impact")
		"impact", "spin":
			velocity.x = 0.0
			if t >= maxf(float(_attack["active"]), 0.18):
				_motion_end()


func _motion_targeted() -> bool:
	return not (_motion["targets"] as Array).is_empty()


## Mục tiêu khoá của cú đá hiện tại (lần lượt theo số cú đã đá), bỏ qua mục tiêu đã gục.
func _motion_target() -> Node2D:
	var targets: Array = _motion["targets"]
	for i in targets.size():
		var tgt = targets[(int(_motion["done"]) + i) % targets.size()]
		if is_instance_valid(tgt) and tgt is Node2D and SkillCaster._alive(tgt):
			return tgt
	return null


func _motion_face() -> void:
	var tgt := _motion_target() if _motion_targeted() else null
	if tgt:
		face(1 if tgt.global_position.x >= global_position.x else -1)


func _motion_strike(tgt, scale: float) -> void:
	if _motion.has("struck"):
		(_motion["struck"] as Array).append(tgt)
	if _motion.has("strike"):
		(_motion["strike"] as Callable).call(tgt, scale)


## Hướng lao của cú đá: vào mục tiêu khoá, hoặc chéo xuống theo "angle".
func _dive_dir() -> Vector2:
	if _motion_targeted():
		var tgt := _motion_target()
		if tgt:
			var d := (tgt.global_position + Vector2(0, -22) * Units.SCALE) - (global_position + Vector2(0, -20) * Units.SCALE)
			if d.length() > 2.0:
				return d.normalized()
	var a := deg_to_rad(float(_motion.get("angle", 38.0)))
	var aim = _motion.get("aim_at")
	if aim is Node2D and is_instance_valid(aim) and SkillCaster._alive(aim):
		# Ngắm mềm: lệch góc đá về phía quái nhưng vẫn giữ dáng cú đá (chéo xuống / bay ngang).
		var d: Vector2 = ((aim as Node2D).global_position + Vector2(0, -22) * Units.SCALE) \
			- (global_position + Vector2(0, -20) * Units.SCALE)
		if d.x * facing > 4.0:
			var want := atan2(d.y, absf(d.x))
			a = clampf(want, a - KICK_AIM_SLACK, a + KICK_AIM_SLACK)
	return Vector2(facing * cos(a), sin(a))


## Nghiêng hình cú đá theo hướng lao (chân duỗi thẳng theo đường lao).
func _dive_rot(dir: Vector2) -> float:
	return facing * clampf(atan2(dir.y, absf(dir.x)), -1.2, 1.2)


func _motion_contact(t: float) -> Node2D:
	if _motion_targeted():
		var tgt := _motion_target()
		if tgt == null:
			return null
		var me := global_position + Vector2(0, -20) * Units.SCALE
		var at := tgt.global_position + Vector2(0, -22) * Units.SCALE
		if me.distance_to(at) <= KICK_CONTACT * Units.SCALE or (is_on_floor() and t > 0.05):
			return tgt
		return null
	var c = _motion.get("contact")
	return c if c is Node2D and is_instance_valid(c) else null


## Hệ số sát thương một cú chạm: chia đều cho số cú đá nối nhau, đá khoan thì cú chạm đầu chỉ một phần.
func _kick_scale() -> float:
	var sc := 1.0 / float(maxi(int(_motion.get("repeat", 1)), 1))
	if float(_motion.get("drill", 0.0)) > 0.0:
		sc *= DRILL_FIRST
	return sc


## Đòn "hits" nhịp đi theo vũ đạo chỉ trúng một lần: nhân bù để tổng sát thương như cũ.
func _hits_scale() -> float:
	return float(maxi(int(_attack.get("hits", 1)), 1))


func _kick_contact(tgt: Node2D) -> void:
	if _motion_targeted():
		_motion_strike(tgt, _kick_scale())
	_motion["hit_at"] = tgt
	if float(_motion.get("drill", 0.0)) > 0.0:
		_motion_phase("drill")
	else:
		_kick_done()


func _kick_done() -> void:
	_motion["done"] = int(_motion["done"]) + 1
	var more := int(_motion["done"]) < int(_motion["left"])
	if more and (not _motion_targeted() or _motion_target() != null):
		_motion_phase("pass")
	else:
		_motion_phase("bounce")


## Cú đá chạm đất mà chưa trúng ai: Final khoá vẫn chắc trúng, còn lại tiếp đất bụi tung.
func _kick_landed() -> void:
	if _motion_targeted():
		var tgt := _motion_target()
		if tgt:
			_kick_contact(tgt)
			return
	Fx.spawn(get_parent(), global_position + Vector2(0, -4) * Units.SCALE, "ring", current_fx()["color"], facing, 1.0)
	_motion_end()


func _motion_ghost(delta: float) -> void:
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_ghost_timer = MOTION_GHOST
		Fx.ghost(get_parent(), sprite, current_fx()["color"])


## Dừng hình ở khung `frac` (0..1) của animation `action` (khung duỗi chân của cú đá, khung vung kiếm hết tầm).
func _hold_frame(action: String, frac: float) -> void:
	_play(action, "", true)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(sprite.animation):
		var n := sprite.sprite_frames.get_frame_count(sprite.animation)
		sprite.frame = clampi(roundi((n - 1) * frac), 0, n - 1)
	sprite.pause()


## Quét đạn phe kia trong tầm lưỡi khi đang vung vũ khí (xem đầu file).
func _check_parry() -> void:
	var size: Vector2 = _attack.get("size", Vector2(18, 12))
	var off: Vector2 = _attack.get("offset", Vector2(14, -14))
	var reach := (absf(off.x) + size.x / 2.0) * Units.SCALE + PARRY_PAD
	if _parry_force:
		reach = maxf(reach, 40.0 * Units.SCALE)
	var elapsed := PARRY_WINDOW - _parry_timer
	for node in get_tree().get_nodes_in_group(Projectile.GROUP):
		var p := node as Projectile
		if p == null or p.parried or p.team == team or p.is_queued_for_deletion():
			continue
		var d := p.global_position - global_position
		var ahead := d.x * facing
		if ahead < -4.0 or ahead > reach + p.radius or d.y < PARRY_TOP or d.y > PARRY_BOTTOM:
			continue
		if p.velocity.x * facing > 0.0:
			continue   # đạn bay ra xa (không lao vào mình)
		_parry(p, elapsed <= PARRY_PERFECT and ahead >= reach * PARRY_TIP)


func _parry(p: Projectile, perfect: bool) -> void:
	perfect = perfect or _parry_force
	var at := p.global_position
	var target: Node2D = p.source as Node2D if is_instance_valid(p.source) else null
	if p.visual_only:
		# Chế độ đấu: đạn thật nằm trên máy đối thủ. Bỏ qua lần báo trúng tới sau, phản thì bắn viên thật của mình.
		_parry_tokens += 1
		_parry_token_timer = PARRY_NET_GRACE
		if perfect:
			_shoot_reflected(p, target)
		p.cut()
	elif perfect:
		p.reflect(self, team, target, REFLECT_SPEED, REFLECT_DAMAGE)
		if not p.hit_landed.is_connected(_on_hit_landed):
			p.hit_landed.connect(_on_hit_landed)
	else:
		p.cut()
	var fx := current_fx()
	Fx.spawn(get_parent(), at, "slash", Projectile.REFLECT_COLOR if perfect else fx["color"], facing, 1.4 if perfect else 1.0)
	if perfect:
		Fx.spawn(get_parent(), at, "ring", Projectile.REFLECT_COLOR, facing, 0.8)
	Sound.sfx("parry_perfect" if perfect else "parry", 0.05)
	gain_rage(PERFECT_PARRY_RAGE if perfect else PARRY_RAGE)
	if perfect:
		notice.emit("PHẢN ĐẠN!")
		if team == &"player":
			CombatDirector.hit_stop(0.07, 0.1)
	parried.emit(perfect)


## Chế độ đấu: viên đạn phản là đạn thật của mình (máy này tính trúng, gửi bản sao sang máy khác qua shot_fired).
func _shoot_reflected(from: Projectile, target: Node2D) -> void:
	var p := Projectile.new()
	p.team = team
	p.source = self
	p.style = from.style
	p.radius = from.radius + 1.0
	p.color = Projectile.REFLECT_COLOR
	p.damage = REFLECT_VERSUS_DAMAGE * _damage_mult()
	p.tags = [&"ranged", &"heavy"]
	p.life = 1.2
	var dir := -from.velocity.normalized()
	if is_instance_valid(target):
		var aim := (target.global_position + Vector2(0, -30) - from.global_position).normalized()
		if aim.x * dir.x > 0.0:
			dir = aim
	p.velocity = dir * from.velocity.length() * REFLECT_SPEED
	p.hit_landed.connect(_on_hit_landed)
	get_parent().add_child(p)
	p.global_position = from.global_position
	shot_fired.emit(p)


## Đòn cận chiến: kéo mép sau của vùng đòn ra sau tâm người tới MELEE_BACK (đơn vị thiết kế), để quái đi xuyên vào
## giữa người (quái không va chạm với người chơi) vẫn bị đánh trúng. Đòn bắn xa giữ nguyên. Trả về [size, offset].
func _melee_box(size: Vector2, offset: Vector2, ranged: bool) -> Array:
	var back := offset.x - size.x / 2.0
	if ranged or back <= -MELEE_BACK:
		return [size, offset]
	var front := offset.x + size.x / 2.0
	return [Vector2(front + MELEE_BACK, size.y), Vector2((front - MELEE_BACK) / 2.0, offset.y)]


## Bấm đánh mà không giữ hướng: trước mặt không có quái mà sát sau lưng có thì quay lại (quái đi xuyên qua người).
func _face_close_enemy() -> void:
	if net_puppet or input_locked or Input.get_axis("move_left", "move_right") != 0.0:
		return
	var behind := false
	for e in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("player"):
		var en := e as Node2D
		if en == null or en == self or not SkillCaster._alive(en) or (en is Player and (en as Player).team == team):
			continue
		var d := en.global_position - global_position
		if absf(d.y) > 40.0:
			continue
		var ahead := d.x * facing
		if ahead >= -4.0 and ahead <= TURN_CHECK_FRONT:
			return            # trước mặt có quái: giữ hướng
		if ahead < -4.0 and ahead >= -TURN_CHECK_BACK:
			behind = true
	if behind:
		facing = -facing
		sprite.flip_h = facing < 0


## dmg_scale / size / offset: vũ đạo đổi sát thương và vùng đòn theo pha (cú đá lao, khoan, sóng xung kích).
func _fire_hitbox(dmg_scale := 1.0, size := Vector2.ZERO, offset := Vector2.ZERO) -> void:
	_state_timer = _attack["active"]
	var base_tags: Array = _attack["tags"]
	var tags := base_tags.duplicate()
	if _attack_kind == &"final":
		tags.append(&"final")
	if current_form:
		for t in current_form.special_tags() + skills.extra_tags():   # &"crush" form nặng, &"time" tăng tốc...
			if not tags.has(t):
				tags.append(t)
	var dmg: float = _attack["damage"] * _damage_mult() * dmg_scale
	var info := DamageInfo.new(dmg, _attack["knockback"], facing, tags, self)
	info.bind_time = float(_attack.get("bind_time", 0.0))
	if size == Vector2.ZERO:
		size = _attack["size"]
		offset = _attack["offset"]
	var box := _melee_box(size, offset, tags.has(&"ranged"))
	hitbox.activate(info, box[0], box[1])
	if skills and current_form:
		skills.on_hitbox_fired(info, size, offset)


## Skill bật hitbox của đòn đang ra (khi on_active cần thêm việc khác, như vùng làm chậm).
func fire_attack_hitbox() -> void:
	_fire_hitbox()


func damage_mult() -> float:
	return _damage_mult()


func _damage_mult() -> float:
	var m := 1.0 + minf(_combo * COMBO_BONUS_PER_HIT, COMBO_BONUS_MAX)
	if current_form:
		m *= current_form.attack_mult * current_form.power_mult() * (skills.damage_mult() if skills else 1.0)
	else:
		m *= HUMAN_ATTACK_MULT * GameState.human_power() * GameState.human_bonus("atk")
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
	if not rage_draining() or not in_special_form() or state in [State.HENSHIN, State.SWAP, State.KO]:
		return
	if rage > 0.0:
		var drain := current_form.rage_drain() * delta
		_set_rage(rage - drain)
		# Quỹ nộ được tích thêm: tối đa DRAIN_GAIN_SHARE lượng vừa trừ, không để dồn quá 1 giây
		_drain_gain_budget = minf(_drain_gain_budget + drain * DRAIN_GAIN_SHARE,
			current_form.rage_drain() * DRAIN_GAIN_SHARE)
	if rage > 0.0 or (state == State.ATTACK and _attack_kind == &"final"):
		return
	if state == State.ATTACK:
		hitbox.deactivate()
		_light_chain = 0
		_slash_chain = 0
		invincible = false
		state = State.NORMAL
	current_form.reset_to_base()
	_grace_timer = maxf(_grace_timer, REVERT_INVULN)
	notice.emit("HẾT NỘ · về form gốc")


## Rời Rider về dạng người (dùng chung cho Henshin Break và giải trừ biến thân khi qua màn).
func _to_human() -> void:
	if skills:
		skills.clear()
	if current_form:
		_leave_form()
	current_form = null
	speed_mult = 1.0
	rider_hp = 0.0
	_pending_form = &""
	form_changed.emit(&"")
	hitbox.deactivate()
	_light_chain = 0
	_slash_chain = 0


func _henshin_break() -> void:
	_set_crouch(false)
	_to_human()
	_set_rage(0.0)   # hình phạt: mất hết nộ
	state = State.BREAK
	_state_timer = BREAK_STUN
	invincible = true
	velocity = Vector2(-facing * 120.0, -120.0) * Units.SCALE
	_play("break")
	Sound.sfx("break", 0.0)


func _die() -> void:
	_set_crouch(false)
	state = State.KO
	hitbox.deactivate()
	_play("ko")
	Sound.sfx("ko", 0.0)
	died.emit()


func _tick_timers(delta: float) -> void:
	swap_cooldown = maxf(swap_cooldown - delta, 0.0)
	_down_tap += delta
	shoot_cooldown = maxf(shoot_cooldown - delta * _time_slow, 0.0)
	if _gun_timer > 0.0:
		if state in [State.NORMAL, State.CROUCH] and Input.is_action_pressed("shoot") and not input_locked:
			_gun_timer = GUN_SHOW_TIME     # đang giữ Bắn: súng ở yên trên tay, xoay theo hướng ngắm
			_aim_gun(_aim_dir())
		elif state in [State.NORMAL, State.CROUCH]:
			_gun_timer -= delta
		else:
			_gun_timer = 0.0               # ra đòn / né / trúng đòn: cất súng ngay
		if _gun_timer <= 0.0:
			_gun.visible = false
	_grace_timer = maxf(_grace_timer - delta, 0.0)
	dodge_cooldown = maxf(dodge_cooldown - delta * _time_slow, 0.0)
	if _parry_tokens > 0:
		_parry_token_timer -= delta
		if _parry_token_timer <= 0.0:
			_parry_tokens = 0
	_tick_rage(delta)
	if skills:
		skills.tick(delta * _time_slow)   # hồi chiêu, thời gian buff chậm theo thời gian
	if _lock_mark > 0.0:
		_lock_mark = maxf(_lock_mark - delta, 0.0)
		queue_redraw()
	_tick_status(delta)
	if _combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo = 0
			combo_changed.emit(0)


func _on_hit_landed(target: Node, info: DamageInfo) -> void:
	if info.has_tag(&"henshin"):
		return
	if not _motion.is_empty() and not _motion.has("contact") and not info.has_tag(&"ranged"):
		_motion["contact"] = target     # cú đá / lướt của vũ đạo vừa chạm quái
	_hit_sound(info)
	if not info.has_tag(&"ranged") and target is Node2D:   # đạn tự vẽ hiệu ứng trúng (Projectile.hit_fx)
		var fx := current_fx()
		var at := (target as Node2D).global_position + Vector2(-facing * 4.0, -34.0)
		if info.has_tag(&"final"):
			CombatDirector.final_attack_landed.emit()
			Fx.spawn(get_parent(), at, str(fx["final"]), fx["color"], facing, 1.6)
			if str(fx["signature"]) != "":   # dấu ấn trên quái (phong ấn Kuuga, Φ của Faiz...)
				Fx.spawn(get_parent(), at, str(fx["signature"]), fx["color"], facing, 1.3)
			Fx.spawn(get_parent(), at, str(fx["hit"]), fx["color"], facing, 1.4)
		elif info.has_tag(&"skill") and state == State.ATTACK and _attack.has("hit_fx"):
			# Skill có hiệu ứng riêng ("fx" của skill, SkillCaster): hiện thay cho hiệu ứng trúng của form.
			Fx.spawn(get_parent(), at, str(_attack["hit_fx"]), _attack.get("fx_color", fx["color"]), facing, 1.2)
			Fx.spawn(get_parent(), at, "spark", _attack.get("fx_color", fx["color"]), facing, 0.7)
		else:
			Fx.spawn(get_parent(), at, str(fx["hit"]), fx["color"], facing, 1.2 if info.has_tag(&"heavy") else 1.0)
			if info.has_tag(&"heavy") and str(fx["hit"]) != "ring":
				Fx.spawn(get_parent(), at + Vector2(0, 30.0), "ring", fx["color"], facing, 0.6)
	_combo += 1
	_combo_timer = COMBO_WINDOW
	combo_changed.emit(_combo)
	var ranged := info.has_tag(&"ranged")
	if not info.has_tag(&"final") and not info.has_tag(&"skill"):
		if current_form == null:
			gain_rage(RAGE_ON_HIT_HUMAN)
		else:
			gain_rage(info.damage * RAGE_ON_DEAL * (0.5 if ranged else 1.0))
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
	sprite.speed_scale = time_mult()
	if current_form == null:
		return
	var fx := current_fx()
	var moving := absf(velocity.x) > 10.0 or state in [State.ATTACK, State.DODGE]
	if (speed_mult > 1.0 or fx["trail"]) and moving:
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = GHOST_INTERVAL
			Fx.ghost(get_parent(), sprite, fx["color"])
	if fx["glide"] and not is_on_floor() and velocity.y > GLIDE_FALL * Units.SCALE * _time_slow \
			and Input.is_action_pressed("jump") and state in [State.NORMAL, State.ATTACK]:
		velocity.y = GLIDE_FALL * Units.SCALE * _time_slow
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
