extends Node2D
class_name BossSkills
## Kỹ năng của trùm (node con của Enemy trùm, StageRun gắn từ "skills" của trùm trong WorldData). Mỗi kỹ năng đều báo
## trước (tên chiêu hiện trên đầu trùm, trùm ửng màu, vạch / dấu đỏ ở chỗ sắp trúng) để người chơi kịp né:
##   "dash"    lao ngang qua đấu trường (vạch đỏ dưới đất) → Né (i-frame) hoặc nhảy qua
##   "fan"     bắn quạt đạn về phía người chơi → né / nhảy / cúi theo độ cao
##   "slam"    nhảy vọt lên đập xuống chỗ người chơi (dấu đỏ dưới đất), sóng xung kích chạy dọc mặt đất hai bên → nhảy
##   "rain"    dấu đỏ quanh người chơi, lát sau đạn trút xuống từng dấu → chạy khỏi dấu
##   "summon"  gọi lính (StageRun sinh quái thường, trùm gục thì lính tan theo)
##   "haste"   tăng tốc (Clock Up, siêu tốc...): chạy và ra đòn nhanh gấp đôi một lúc, để bóng mờ
##   "guard"   dựng khiên: đòn thường bị chặn, chỉ đòn nặng / skill / Final phá được
##   "warp"    biến mất rồi hiện sau lưng người chơi, chém ngay (chớp sáng báo trước)
##   "beam"    tia ngắm mảnh rồi bắn tia ngang xuyên đấu trường: tia cao (đỏ) → cúi, tia thấp (xanh) → nhảy
##   "combo"   3 nhát chém liên hoàn vừa chém vừa tiến tới, nhát cuối nặng → lùi ra / né
##   "homing"  thả 3 quả cầu chậm đuổi theo người chơi một lúc → chạy vòng, né, chém tan
##   "vortex"  hút người chơi về phía trùm rồi nổ vùng quanh trùm → chạy ngược chiều hút, né lúc nổ
##   "quake"   chuỗi cột đất trồi lên lần lượt từ trùm tới chỗ người chơi (dấu đỏ trước) → nhảy qua
##   "kick"    Rider Kick (Rider đối thủ): bật cao, dấu đỏ chỗ người chơi, khựng tạo dáng rồi đá chéo xuống dấu
##             ("drill": khoan thêm một nhịp vùng khi chạm đất) → chạy khỏi dấu hoặc Né đúng lúc
##   "wave"    sóng chém to bay ngang tầm thấp theo hướng mặt → nhảy qua
## Độ khó `level` (DuelKits.LEVELS, Rider đối thủ ở màn ĐẤU RIDER): hồi kỹ năng nhanh hơn, báo trước ngắn hơn, dùng
## nhiều kỹ năng ngay từ đầu, nổi giận sớm hơn. 0 = trùm thường như cũ.
## Đổi form (`forms`, DuelKits.FORMS): máu tụt dưới mốc của form kế tiếp thì Rider đối thủ dừng lại biến đổi (chớp sáng,
## tên form trên đầu), mang hình của form đó (bộ hình người chơi) và ưu tiên kỹ năng của form.
## Mỗi kỹ năng: {"kind", "name", "color", "damage" (× sát thương đòn thường của trùm), và khoá riêng của kiểu}.
## Ba giai đoạn theo máu: đầu trận dùng 2 kỹ năng đầu; dưới ENRAGE_AT máu nổi giận (thêm tới kỹ năng thứ 4, hồi kỹ
## năng nhanh hơn, chạy nhanh hơn, StageRun hiện banner qua tín hiệu enraged); dưới FURY_AT máu cuồng nộ (mọi kỹ năng,
## FURY_CHAIN khả năng tung liền kỹ năng thứ hai ngay sau kỹ năng vừa xong).
## Thời gian tính bằng delta của Enemy (đã nhân enemy_time_scale): Clock Up / Axel làm chậm cả kỹ năng của trùm.

signal summon_requested(count: int)
signal enraged(fury: bool)          ## false = nổi giận (ENRAGE_AT), true = cuồng nộ (FURY_AT)

const FIRST_DELAY := 2.0
const COOLDOWN := 3.4
const COOLDOWN_JITTER := 0.8
const ENRAGE_AT := 0.6
const ENRAGE_COOLDOWN := 0.65
const ENRAGE_SPEED := 1.2
const FURY_AT := 0.25
const FURY_COOLDOWN := 0.5
const FURY_CHAIN := 0.5
const VORTEX_PULL := 75.0           ## px/giây kéo người chơi về phía trùm
const BEAM_LENGTH := 340.0
const SKILL_RANGE := 320.0          ## người chơi xa hơn chừng này thì chưa dùng kỹ năng
const NAME_TIME := 1.4              ## tên chiêu hiện trên đầu chừng này giây
const MAX_MINIONS := 3
const KICK_POSE := 0.35             ## Rider Kick: khựng trên không chừng này giây (dấu đỏ đã hiện) rồi mới đá
const KICK_SPEED := 560.0

var enemy: Enemy
var skills: Array = []
var level := 0                      ## độ khó Rider đối thủ (DuelKits.LEVELS), StageRun đặt; 0 = trùm thường
var forms: Array = []               ## các form đổi theo máu (DuelKits.FORMS), StageRun đặt
var _form_i := 0                    ## form kế tiếp trong `forms`
var current: Dictionary = {}
var phase := ""                     ## pha của kỹ năng đang chạy ("" = không có)

var _cooldown := FIRST_DELAY
var _timer := 0.0
var _enraged := false
var _name := ""
var _name_time := 0.0
var _marks: Array[Vector2] = []      ## dấu đỏ (toạ độ thế giới) của rain / slam / dash
var _target := Vector2.ZERO
var _haste := 0.0
var _base_speed := 0.0
var _base_windup := 0.0
var _guard := 0.0
var _ghost := 0.0
var _airborne := false
var _minions: Array[Enemy] = []
var _rng_index := -1
var _fury := false
var _step := 0                       ## combo: nhát thứ mấy
var _beam_low := false
var _beam_show := 0.0                ## beam: còn vẽ tia chừng này giây
var _quake: Array = []               ## quake: [[vị trí, giây còn lại tới lúc trồi]]


func _init(owner_enemy: Enemy, list: Array) -> void:
	enemy = owner_enemy
	skills = list
	name = "BossSkills"
	z_index = -1


func _ready() -> void:
	_base_speed = enemy.move_speed
	_base_windup = enemy.windup_time


# --- Enemy hỏi -------------------------------------------------------------------

## Đang chạy kỹ năng (Enemy ở State.SKILL).
func busy() -> bool:
	return phase != ""


## Khiên đang dựng: đòn không nặng bị chặn (Enemy.take_hit).
func blocks(info: DamageInfo) -> bool:
	return _guard > 0.0 and not (info.has_tag(&"heavy") or info.has_tag(&"final") or info.has_tag(&"skill"))


## Gọi mỗi khung từ Enemy._physics_process (mọi trạng thái), d đã nhân time scale.
func tick(d: float) -> void:
	_name_time = maxf(_name_time - d, 0.0)
	if _guard > 0.0:
		_guard = maxf(_guard - d, 0.0)
	if _haste > 0.0:
		_haste -= d
		_ghost -= d
		if _ghost <= 0.0 and absf(enemy.velocity.x) > 10.0:
			_ghost = 0.07
			Fx.ghost(enemy.get_parent(), enemy.sprite, _color())
		if _haste <= 0.0:
			_apply_speed()
	if not _enraged and enemy.hp <= enemy.max_hp * float(_lv("enrage", ENRAGE_AT)) and enemy.state != Enemy.State.DEAD:
		_enraged = true
		_apply_speed()
		enraged.emit(false)
	if _enraged and not _fury and enemy.hp <= enemy.max_hp * FURY_AT and enemy.state != Enemy.State.DEAD:
		_fury = true
		enraged.emit(true)
	_beam_show = maxf(_beam_show - d, 0.0)
	if phase == "":
		_cooldown -= d
	queue_redraw()


## Có nên tung kỹ năng ngay (Enemy._state_chase hỏi khi đang đuổi).
func want_cast() -> bool:
	if phase == "" and _form_due() and enemy.is_on_floor():
		return true                      # đổi form ngay khi máu qua mốc, không chờ hồi kỹ năng
	if phase != "" or _cooldown > 0.0 or skills.is_empty() or not enemy.is_on_floor():
		return false
	var p := enemy._player
	if p == null:
		return false
	return absf(p.global_position.x - enemy.global_position.x) <= SKILL_RANGE * Units.SCALE


## Chọn và bắt đầu một kỹ năng (khác kỹ năng vừa dùng nếu có thể).
func cast() -> void:
	if _form_due():
		_begin_form_change()
		return
	var start_pool := int(_lv("pool", 2))
	var pool := skills.size() if _fury else mini(maxi(4, start_pool + 1) if _enraged else start_pool, skills.size())
	var i := randi() % pool
	if pool > 1 and i == _rng_index:
		i = (i + 1) % pool
	_rng_index = i
	current = skills[i]
	_name = str(current.get("name", ""))
	_name_time = NAME_TIME
	_marks.clear()
	enemy.velocity.x = 0.0
	_face_player()
	Sound.sfx("enemy_shot", 0.1, -2.0)
	_set_phase("windup", float(current.get("windup", 0.6)) * float(_lv("windup", 1.0)))
	enemy.play_anim("windup")


## Bị trói / đóng băng / gục giữa chừng: dừng kỹ năng, dọn hitbox và dấu.
func cancel() -> void:
	if phase == "":
		return
	enemy.hitbox.deactivate()
	enemy.modulate.a = 1.0
	enemy.sprite.rotation = 0.0
	enemy.hurtbox.set_deferred("monitorable", enemy.state != Enemy.State.DEAD)
	_marks.clear()
	_finish()


## Trùm gục: lính gọi ra tan theo.
func on_boss_died() -> void:
	cancel()
	for m in _minions:
		if is_instance_valid(m) and m.state != Enemy.State.DEAD:
			m.take_hit(DamageInfo.new(m.hp + 1.0, Vector2(40, -60), 1, [&"final"], null))
	_minions.clear()


## StageRun báo lính vừa gọi ra (để tan theo khi trùm gục, và không gọi quá MAX_MINIONS).
func add_minion(m: Enemy) -> void:
	_minions.append(m)


func minion_room() -> int:
	_minions = _minions.filter(func(m): return is_instance_valid(m) and m.state != Enemy.State.DEAD)
	return MAX_MINIONS - _minions.size()


# --- Chạy kỹ năng (Enemy._physics_process gọi khi State.SKILL) ---------------------

func step(d: float) -> void:
	_timer -= d
	var kind := str(current.get("kind", ""))
	match phase:
		"windup":
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 600.0 * Units.SCALE * d)
			if kind in ["dash", "slam", "kick", "wave"]:
				_face_player()
			if _timer <= 0.0:
				_begin_active(kind)
		"active":
			_step_active(kind, d)
		"rain_wait":
			if _timer <= 0.0:
				for m in _marks:
					_drop_shot(m)
				_marks.clear()
				_set_phase("recover", 0.5)
		"kick_rise", "kick_pose", "kick_dive":
			_step_kick(d)
		"form_change":
			enemy.velocity.x = 0.0
			if _timer <= 0.0:
				_change_form(forms[_form_i - 1])
				_set_phase("recover", 0.35)
		"warp_out":
			if _timer <= 0.0:
				_warp_in()
		"warp_strike":
			if _timer <= 0.0:
				_strike_melee(1.3 * float(current.get("damage", 1.0)))
				_set_phase("recover", 0.5)
				get_tree().create_timer(0.15, false).timeout.connect(func() -> void:
					if is_instance_valid(enemy) and phase == "recover":
						enemy.hitbox.deactivate())
		"beam_aim":
			if _timer <= 0.0:
				_fire_beam()
		"combo":
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 500.0 * Units.SCALE * d)
			if _timer <= 0.0:
				_combo_next()
		"vortex":
			_pull_player(d)
			if _timer <= 0.0:
				_vortex_burst()
		"quake":
			_step_quake(d)
		"recover":
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 600.0 * Units.SCALE * d)
			if _timer <= 0.0:
				enemy.hitbox.deactivate()
				_finish()


func _begin_active(kind: String) -> void:
	match kind:
		"dash":
			var dist := float(current.get("distance", 240.0)) * Units.SCALE
			_target = enemy.global_position + Vector2(enemy.facing * dist, 0.0)
			enemy.velocity.x = enemy.facing * float(current.get("speed", 420.0)) * Units.SCALE
			enemy.hitbox.activate(_info(1.3, Vector2(220, -140)), Vector2(26, 30), Vector2(6, -18))
			enemy.play_anim("run")
			_set_phase("active", dist / (float(current.get("speed", 420.0)) * Units.SCALE) + 0.05)
		"fan":
			_fire_fan()
			enemy.play_anim("attack")
			_set_phase("recover", 0.45)
		"slam":
			var p := enemy._player
			_target = p.global_position if p else enemy.global_position
			_marks = [_target]
			var t := 0.75                                   # thời gian bay lên rồi rơi
			enemy.velocity = Vector2((_target.x - enemy.global_position.x) / t,
				-float(current.get("jump", 330.0)) * Units.SCALE)
			_airborne = false
			enemy.play_anim("run")
			_set_phase("active", 2.0)
		"rain":
			var p := enemy._player
			var base := p.global_position if p else enemy.global_position
			var n := int(current.get("count", 4))
			var gap := float(current.get("gap", 34.0)) * Units.SCALE
			for i in n:
				_marks.append(base + Vector2((i - (n - 1) / 2.0) * gap, 0.0))
			enemy.play_anim("attack")
			_set_phase("rain_wait", float(current.get("delay", 0.9)))
		"summon":
			var room := minion_room()
			if room > 0:
				summon_requested.emit(mini(int(current.get("count", 2)), room))
			Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -20), "ring", _color(), enemy.facing, 2.0)
			enemy.play_anim("attack")
			_set_phase("recover", 0.6)
		"haste":
			_haste = float(current.get("time", 3.5))
			_apply_speed()
			Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -20), "clock", _color(), enemy.facing, 1.4)
			_set_phase("recover", 0.2)
		"guard":
			_guard = float(current.get("time", 3.0))
			Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -20), "shield", _color(), enemy.facing, 1.4)
			_set_phase("recover", 0.3)
		"beam":
			_beam_low = randf() < 0.5
			_face_player()
			_set_phase("beam_aim", float(current.get("aim", 0.7)))
		"combo":
			_step = 0
			_combo_next()
		"homing":
			var from := enemy.global_position + Vector2(0, -30) * Units.SCALE
			for i in int(current.get("count", 3)):
				var a := -PI / 2.0 + (i - 1) * 0.7
				var p := _shot(from, Vector2.from_angle(a) * 110.0 * Units.SCALE, 0.7)
				p.homing = true
				p.radius = 5.0
				p.life = float(current.get("life", 3.2))
			enemy.play_anim("attack")
			_set_phase("recover", 0.5)
		"vortex":
			Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -20), "ring", _color(), enemy.facing, 2.5)
			_set_phase("vortex", float(current.get("time", 1.4)))
		"quake":
			var p := enemy._player
			var tx := p.global_position.x if p else enemy.global_position.x + enemy.facing * 150.0
			var dir := 1 if tx >= enemy.global_position.x else -1
			var gap := 30.0 * Units.SCALE
			var n := int(current.get("count", 6))
			_quake.clear()
			for i in n:
				var at := Vector2(enemy.global_position.x + dir * gap * (i + 1), enemy.global_position.y)
				_quake.append([at, 0.45 + 0.16 * i])
			enemy.play_anim("attack")
			_set_phase("quake", 0.45 + 0.16 * n + 0.2)
		"kick":
			enemy.velocity = Vector2(enemy.facing * 40.0, -float(current.get("jump", 380.0))) * Units.SCALE
			enemy.play_anim("run")
			_set_phase("kick_rise", 0.32)
		"wave":
			var w := _shot(enemy.global_position + Vector2(enemy.facing * 18.0, Enemy.SHOT_LOW_Y - 6.0) * Units.SCALE,
				Vector2(enemy.facing * float(current.get("speed", 230.0)) * Units.SCALE, 0.0), 1.2)
			w.style = "wave"
			w.radius = 7.0
			w.pierce = true
			w.life = 1.6
			enemy.play_anim("attack")
			Sound.sfx("slash_heavy", 0.05, -2.0)
			_set_phase("recover", 0.5)
		"warp":
			enemy.modulate.a = 0.0
			enemy.hurtbox.set_deferred("monitorable", false)
			Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -20), "spark", _color(), enemy.facing, 1.5)
			_set_phase("warp_out", 0.5)
		_:
			_finish()


func _step_active(kind: String, d: float) -> void:
	match kind:
		"dash":
			var done := _timer <= 0.0 or enemy.is_on_wall() \
				or (enemy.global_position.x - _target.x) * enemy.facing >= 0.0
			if done:
				enemy.velocity.x = 0.0
				enemy.hitbox.deactivate()
				_set_phase("recover", 0.6)
		"slam":
			if not enemy.is_on_floor():
				_airborne = true
			elif _airborne or _timer <= 0.0:
				_marks.clear()
				enemy.velocity.x = 0.0
				enemy.hitbox.activate(_info(1.2, Vector2(160, -160)), Vector2(56, 26), Vector2(0, -12))
				for dir in [-1, 1]:
					_wave(dir)
				Fx.spawn(enemy.get_parent(), enemy.global_position, "ring", _color(), enemy.facing, 2.2)
				CombatDirector.shake(4.0)
				enemy.play_anim("attack")
				_set_phase("recover", 0.7)
				get_tree().create_timer(0.15, false).timeout.connect(func() -> void:
					if is_instance_valid(enemy) and phase == "recover":
						enemy.hitbox.deactivate())


# --- Đổi form (Rider đối thủ) -------------------------------------------------------

const PLAYER_FRAMES := preload("res://art/characters/player_frames.tres")
const FORM_ANIMS := Enemy.PLAYER_LOOK_ANIMS
const FORM_CHANGE_TIME := 0.5


func _form_due() -> bool:
	return _form_i < forms.size() and enemy.state != Enemy.State.DEAD \
		and enemy.hp <= enemy.max_hp * float(forms[_form_i].get("at", 0.5))


func _begin_form_change() -> void:
	var f: Dictionary = forms[_form_i]
	_form_i += 1
	current = {"kind": "form", "name": str(f.get("name", "")), "color": f.get("color", _color())}
	_name = str(current["name"])
	_name_time = NAME_TIME
	_marks.clear()
	enemy.velocity.x = 0.0
	enemy.play_anim("windup")
	Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -20), "ring", _color(), enemy.facing, 1.6)
	Sound.sfx("form_change", 0.0, -4.0)
	_set_phase("form_change", FORM_CHANGE_TIME)


## Mang hình form `f` (bộ hình người chơi của form đó), áp hiệu ứng form, đưa kỹ năng của form lên đầu danh sách.
func _change_form(f: Dictionary) -> void:
	var prefix := ""
	var preview := FigurePicker.preview_form(StringName(str(f.get("rider", ""))), StringName(str(f.get("form", ""))))
	if preview:
		prefix = preview.animation_prefix()
		preview.free()
	if prefix != "" and PLAYER_FRAMES.has_animation(prefix + "_idle"):
		enemy.sprite.sprite_frames = PLAYER_FRAMES
		enemy.sprite_prefix = prefix
		enemy.anim_alias = FORM_ANIMS
		enemy.play_anim("idle")
	Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -24), "ring", _color(), enemy.facing, 2.2)
	Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -24), "spark", _color(), enemy.facing, 1.6)
	CombatDirector.shake(3.0)
	if f.has("speed"):
		_base_speed = _base_speed * float(f["speed"])
		_apply_speed()
	if f.has("haste"):
		_haste = float(f["haste"])
		_apply_speed()
	if f.has("guard"):
		_guard = float(f["guard"])
	var first: Array = []
	for want in f.get("skills", []):
		for sk in skills:
			if str(sk.get("name", "")) == str(want) and not first.has(sk):
				first.append(sk)
	if not first.is_empty():
		skills = first + skills.filter(func(sk): return not first.has(sk))
		_rng_index = -1


## Rider Kick của Rider đối thủ: bật lên → dấu đỏ chỗ người chơi, khựng tạo dáng → đá chéo xuống dấu → bật ngược ra sau.
func _step_kick(d: float) -> void:
	match phase:
		"kick_rise":
			if _timer <= 0.0:
				var p := enemy._player
				_target = p.global_position if p else enemy.global_position + Vector2(enemy.facing * 80.0, 0) * Units.SCALE
				_marks = [_target]
				_face_player()
				enemy.play_anim("attack")
				_set_phase("kick_pose", KICK_POSE)
		"kick_pose":
			enemy.velocity = Vector2.ZERO          # khựng trên không tạo dáng: người chơi kịp chạy khỏi dấu / Né
			enemy.sprite.rotation = enemy.facing * 0.5 * clampf(1.0 - _timer / KICK_POSE, 0.0, 1.0)
			if _timer <= 0.0:
				enemy.hitbox.activate(_info(1.6, Vector2(260, -160)), Vector2(30, 30), Vector2(12, -12))
				_set_phase("kick_dive", 1.0)
		"kick_dive":
			var dir := (_target - enemy.global_position).normalized()
			if dir.y < 0.25:
				dir = Vector2(enemy.facing * 0.9, 0.45).normalized()   # luôn là cú đá chéo xuống
			enemy.velocity = dir * KICK_SPEED * Units.SCALE
			enemy.sprite.rotation = enemy.facing * clampf(atan2(dir.y, absf(dir.x)), 0.2, 1.2)
			_ghost -= d
			if _ghost <= 0.0:
				_ghost = 0.04
				Fx.ghost(enemy.get_parent(), enemy.sprite, _color())
			if (enemy.is_on_floor() and _timer < 0.95) or _timer <= 0.0:
				_kick_land()


func _kick_land() -> void:
	_marks.clear()
	enemy.sprite.rotation = 0.0
	enemy.velocity = Vector2(-enemy.facing * 120.0, -180.0) * Units.SCALE
	Fx.spawn(enemy.get_parent(), enemy.global_position, "ring", _color(), enemy.facing, 2.0)
	CombatDirector.shake(4.0)
	if current.get("drill", false):     # đá khoan (Crimson Smash, Rocket Drill Kick): nổ thêm một nhịp quanh chỗ đáp
		enemy.hitbox.activate(_info(0.5, Vector2(200, -120)), Vector2(44, 26), Vector2(0, -12))
	_set_phase("recover", 0.8)
	get_tree().create_timer(0.15, false).timeout.connect(func() -> void:
		if is_instance_valid(enemy) and phase == "recover":
			enemy.hitbox.deactivate())


func _warp_in() -> void:
	var p := enemy._player
	if p:
		var p_facing := (p as Player).facing if p is Player else 1
		enemy.global_position = Vector2(p.global_position.x - p_facing * 30.0 * Units.SCALE, enemy.global_position.y)
	enemy.modulate.a = 1.0
	enemy.hurtbox.set_deferred("monitorable", true)
	_face_player()
	Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -20), "spark", _color(), enemy.facing, 1.5)
	enemy.play_anim("windup")
	_set_phase("warp_strike", float(current.get("strike_delay", 0.4)))


func _finish() -> void:
	phase = ""
	current = {}
	_quake.clear()
	var cd := COOLDOWN + randf_range(-COOLDOWN_JITTER, COOLDOWN_JITTER)
	_cooldown = cd * (FURY_COOLDOWN if _fury else (ENRAGE_COOLDOWN if _enraged else 1.0)) * float(_lv("cooldown", 1.0))
	if _fury and randf() < FURY_CHAIN:
		_cooldown = 0.35         # cuồng nộ: nối liền kỹ năng kế tiếp
	enemy.end_skill()


# --- Kỹ năng beam / combo / vortex / quake ---------------------------------------

func _fire_beam() -> void:
	var y := Enemy.SHOT_LOW_Y if _beam_low else Enemy.SHOT_HIGH_Y
	enemy.hitbox.activate(_info(1.5, Vector2(200, -80)), Vector2(BEAM_LENGTH, 8), Vector2(BEAM_LENGTH / 2.0 + 10.0, y))
	_beam_show = 0.3
	Sound.sfx("enemy_shot", 0.05, 0.0)
	CombatDirector.shake(3.0)
	enemy.play_anim("attack")
	_set_phase("recover", 0.6)
	get_tree().create_timer(0.2, false).timeout.connect(func() -> void:
		if is_instance_valid(enemy) and phase == "recover":
			enemy.hitbox.deactivate())


func _combo_next() -> void:
	enemy.hitbox.deactivate()
	if _step >= 3:
		_set_phase("recover", 0.6)
		return
	_face_player()
	var last := _step == 2
	enemy.velocity.x = enemy.facing * (200.0 if last else 140.0) * Units.SCALE
	enemy.hitbox.activate(_info(1.5 if last else 0.8, Vector2(260, -160) if last else Vector2(60, -30)),
		Vector2(26, 26), Vector2(14, -20))
	Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(enemy.facing * 16, -20), "slash", _color(),
		enemy.facing, 1.3 if last else 1.0)
	enemy.play_anim("attack")
	_step += 1
	_set_phase("combo", 0.42 if not last else 0.3)


func _pull_player(d: float) -> void:
	var p := enemy._player as CharacterBody2D
	if p == null or (p is Player and (p as Player).is_invulnerable()):
		return
	var dx := enemy.global_position.x - p.global_position.x
	if absf(dx) < 20.0 * Units.SCALE:
		return
	p.move_and_collide(Vector2(signf(dx) * VORTEX_PULL * Units.SCALE * d, 0.0))
	if Engine.get_physics_frames() % 6 == 0:
		Fx.spawn(enemy.get_parent(), p.global_position + Vector2(0, -20), "wind", _color(), int(signf(dx)), 0.8)


func _vortex_burst() -> void:
	enemy.hitbox.activate(_info(1.4, Vector2(240, -160)), Vector2(110, 50), Vector2(0, -20))
	Fx.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -20), "ring", _color(), enemy.facing, 3.0)
	CombatDirector.shake(4.0)
	enemy.play_anim("attack")
	_set_phase("recover", 0.7)
	get_tree().create_timer(0.15, false).timeout.connect(func() -> void:
		if is_instance_valid(enemy) and phase == "recover":
			enemy.hitbox.deactivate())


func _step_quake(d: float) -> void:
	for q in _quake:
		if q[1] <= 0.0:
			continue
		q[1] -= d
		if q[1] <= 0.0:
			var p := _shot(q[0] + Vector2(0, -14) * Units.SCALE, Vector2.ZERO, 1.1)   # nằm trên sàn, không chạm đất
			p.radius = 10.0
			p.life = 0.22
			p.pierce = true
			Fx.spawn(enemy.get_parent(), q[0], "spark", _color(), 1, 1.4)
	if _timer <= 0.0:
		_quake.clear()
		_set_phase("recover", 0.4)


func _set_phase(p: String, time: float) -> void:
	phase = p
	_timer = time


# --- Đòn ------------------------------------------------------------------------

func _info(mult: float, knockback: Vector2) -> DamageInfo:
	var m := mult * float(current.get("damage", 1.0))
	return DamageInfo.new(enemy.attack_damage * m, knockback, enemy.facing, [&"boss_skill"], enemy)


func _strike_melee(mult: float) -> void:
	enemy.hitbox.activate(DamageInfo.new(enemy.attack_damage * mult, Vector2(180, -100), enemy.facing,
		[&"boss_skill"], enemy), Vector2(30, 26), Vector2(14, -20))
	enemy.play_anim("attack")


func _fire_fan() -> void:
	var p := enemy._player
	var from := enemy.global_position + Vector2(enemy.facing * 14.0, -26.0) * Units.SCALE
	var aim := Vector2(enemy.facing, 0.0)
	if p:
		aim = ((p.global_position + Vector2(0, -24) * Units.SCALE) - from).normalized()
	var n := int(current.get("count", 5))
	var spread := float(current.get("spread", 0.5))
	for i in n:
		var a := (i - (n - 1) / 2.0) * (spread / maxf(n - 1, 1))
		_shot(from, aim.rotated(a) * float(current.get("speed", 170.0)) * Units.SCALE, 0.8)
	Sound.sfx("enemy_shot", 0.1, -4.0)


func _wave(dir: int) -> void:
	var from := enemy.global_position + Vector2(dir * 20.0, Enemy.SHOT_LOW_Y) * Units.SCALE
	var p := _shot(from, Vector2(dir * float(current.get("wave_speed", 210.0)) * Units.SCALE, 0.0), 0.7)
	p.radius = 5.0
	p.style = "ball"
	p.life = 1.4


func _drop_shot(at: Vector2) -> void:
	var p := _shot(at + Vector2(0, -150.0) * Units.SCALE, Vector2(0, 340.0) * Units.SCALE, 0.9)
	p.radius = 5.0
	p.life = 0.8
	Fx.spawn(enemy.get_parent(), at, "spark", _color(), 1, 0.8)


func _shot(from: Vector2, vel: Vector2, mult: float) -> Projectile:
	var p := Projectile.new()
	p.team = &"enemy"
	p.damage = enemy.attack_damage * mult * float(current.get("damage", 1.0))
	p.color = _color()
	p.style = str(current.get("style", "ball"))
	p.radius = 4.0
	p.life = 2.0
	p.source = enemy
	p.tags = [&"ranged", &"boss_skill"]
	p.velocity = vel
	enemy.get_parent().add_child(p)
	p.global_position = from
	return p


# --- Phụ -----------------------------------------------------------------------

## Thông số độ khó `key` theo `level` (DuelKits.LEVELS); trùm thường (level 0) dùng `default`.
func _lv(key: String, default):
	if level <= 0:
		return default
	return DuelKits.LEVELS[clampi(level, 0, DuelKits.LEVELS.size() - 1)].get(key, default)


func _color() -> Color:
	return current.get("color", Color(1.0, 0.35, 0.35)) if not current.is_empty() else Color(0.8, 0.6, 1.0)


func _face_player() -> void:
	var p := enemy._player
	if p:
		enemy.facing = 1 if p.global_position.x >= enemy.global_position.x else -1
		enemy.sprite.flip_h = enemy.facing < 0


## Tốc độ theo tăng tốc và nổi giận.
func _apply_speed() -> void:
	var mult := (2.0 if _haste > 0.0 else 1.0) * (ENRAGE_SPEED if _enraged else 1.0)
	enemy.move_speed = _base_speed * mult
	enemy.windup_time = _base_windup / (1.6 if _haste > 0.0 else 1.0)


## Tên chiêu trên đầu trùm, dấu đỏ chỗ sắp trúng, vạch đường lao, khiên.
func _draw() -> void:
	var c := _color()
	var blink := Engine.get_process_frames() % 10 < 6
	if phase == "windup" and str(current.get("kind", "")) == "dash":
		var dist := float(current.get("distance", 240.0)) * Units.SCALE
		draw_rect(Rect2(Vector2(minf(0.0, enemy.facing * dist), -2.0), Vector2(dist, 3.0)),
			Color(1.0, 0.25, 0.25, 0.55 if blink else 0.3))
	if phase == "beam_aim" or _beam_show > 0.0:
		var y := Enemy.SHOT_LOW_Y if _beam_low else Enemy.SHOT_HIGH_Y
		var col := Enemy.SHOT_LOW_COLOR if _beam_low else Enemy.SHOT_HIGH_COLOR
		var from := Vector2(enemy.facing * 10.0, y) * Units.SCALE
		var to := from + Vector2(enemy.facing * BEAM_LENGTH * Units.SCALE, 0.0)
		if _beam_show > 0.0:
			draw_line(from, to, Color(col.r, col.g, col.b, 0.9), 7.0)
			draw_line(from, to, Color(1, 1, 1, 0.9), 2.5)
		else:
			draw_line(from, to, Color(col.r, col.g, col.b, 0.6 if blink else 0.3), 1.0)
	for q in _quake:
		if q[1] > 0.0:
			var qa := to_local(q[0])
			draw_set_transform(qa, 0.0, Vector2(1.0, 0.35))
			draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.2, 0.2, 0.45 if blink else 0.25))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for m in _marks:
		var at := to_local(m)
		draw_set_transform(at, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.2, 0.2, 0.45 if blink else 0.25))
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 20, Color(1.0, 0.35, 0.3, 0.9), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _guard > 0.0:
		var h := enemy._sprite_height()
		draw_arc(Vector2(0, -h * 0.5), h * 0.62, 0.0, TAU, 28, Color(0.6, 0.85, 1.0, 0.5 + 0.3 * float(blink)), 2.0)
	if _name_time > 0.0 and _name != "":
		var font := ThemeDB.fallback_font
		var w := font.get_string_size(_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var y := -enemy._sprite_height() - 16.0
		var a := clampf(_name_time * 2.0, 0.0, 1.0)
		draw_string_outline(font, Vector2(-w / 2.0, y), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0, 0, 0, a))
		draw_string(font, Vector2(-w / 2.0, y), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(c.r, c.g, c.b, a))
