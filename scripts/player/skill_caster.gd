extends Node
class_name SkillCaster
## Thi triển skill của form (Skill 1 / Skill 2, nút U / Y) và Final Attack (nút O) theo docs/SKILLS.md.
## Node con của Player (Player.skills), dữ liệu skill lấy từ RiderForm.get_skills() / final_type() (xem Skills).
##
## Mọi skill chạy trong trạng thái ATTACK của Player (Player.begin_skill): pha "startup" là lúc tụ đòn / dấu khoá (bị
## đánh trúng lúc này thì hỏng, nộ đã trả), hết startup thì gọi "on_active" (đòn chắc trúng, bắn đạn, bật buff...) hoặc
## bật hitbox như đòn thường (lướt chém, vùng).
##   [Đ] aim     : lướt chém / đạn / sóng / boomerang theo hướng mặt hoặc hướng ngắm (8 hướng như nút Bắn)
##   [K] lock    : khoá quái gần nhất phía trước, dấu khoá LOCK_TIME giây rồi đánh chắc trúng (Hurtbox.receive)
##   [T] bind    : như [K] (hoặc đạn / vùng) kèm trói; Hibiki Ongekidaiko: trong lúc trói nút Đánh = đánh trống theo nhịp
##   [V] area    : hitbox phủ quanh mình
##   [P] counter : thế đỡ, bị đánh trong lúc đó thì không mất máu và phản đòn chắc trúng; đạn tới thì phản đạn
##   [C] buff    : hiệu ứng có thời hạn (_effects), Player hỏi qua các hàm bên dưới
## Hồi chiêu đếm theo giây thật; đổi form / về dạng người thì hồi chiêu giữ nguyên, buff bị huỷ.

const CLONE_DAMAGE := 0.5
const CLONE_SPACING := 26.0
const DRUM_BEAT := 0.5           ## giây giữa hai nhịp trống
const DRUM_WINDOW := 0.13        ## bấm trong chừng này giây quanh nhịp = trúng nhịp
const DRUM_HIT := 0.35           ## mỗi nhịp đúng cộng chừng này × sát thương skill vào cú "thanh tẩy" cuối
const DRUM_MISS := 0.08
const FINAL_LOCK_RANGE := 190.0
const TIME_ENEMY_SCALE := 0.15
const TIME_SPEED_MULT := 1.6
const ELEMENTS := [&"burn", &"freeze", &"shock"]

var player: Player
var cooldowns := [0.0, 0.0]
var _effects := {}               ## tên hiệu ứng buff -> {"value", "time"}
var _clones: Array[Node2D] = []
var _marked: Array = []          ## quái đang hiện dấu khoá của skill đang tụ
var _counter := {}               ## thế phản đòn đang mở: {"damage", "tags", "fx", "final", "time"}
var _drum := {}                  ## đánh trống: {"target", "time", "beat", "score", "damage", "tags"}
var _element := 0
var _color := Color.WHITE        ## màu hiệu ứng của skill đang tung ("color" của skill, mặc định màu form)


func _init(p: Player) -> void:
	player = p
	name = "Skills"


# --- Cho Player / giao diện hỏi ----------------------------------------------

func skills() -> Array:
	return player.current_form.get_skills() if player.current_form else []


func skill(i: int) -> Dictionary:
	var list := skills()
	return list[i] if i < list.size() else {}


func can_use(i: int) -> bool:
	var s := skill(i)
	return not s.is_empty() and cooldowns[i] <= 0.0 and player.rage >= float(s["cost"])


func can_final() -> bool:
	return player.current_form != null and player.rage >= Skills.FINAL_COST


func has_effect(e: String) -> bool:
	return _effects.has(e)


func effect(e: String, default = 1.0):
	return _effects[e]["value"] if _effects.has(e) else default


## Hệ số sát thương của buff (Agito Crest, Ore Sanjou...).
func damage_mult() -> float:
	return float(effect("atk", 1.0))


func speed_mult() -> float:
	return float(effect("speed", 1.0))


## Hệ số sát thương nhận (Metal Trilobite...).
func guard_mult() -> float:
	return float(effect("guard", 1.0))


func superarmor() -> bool:
	return has_effect("superarmor")


func flying() -> bool:
	return has_effect("fly")


func hidden() -> bool:
	return has_effect("invis")


func homing() -> bool:
	return has_effect("homing")


## Bất tử theo buff: hoá ma (phase), lặn vào giấc mơ (behind). liquid chỉ miễn đòn cận chiến (Player.take_hit).
func invulnerable() -> bool:
	return has_effect("phase") or has_effect("behind")


func drum_active() -> bool:
	return not _drum.is_empty()


## Tag cộng vào mọi đòn / đạn: &"time" khi đang Clock Up bằng skill, nguyên tố xoay vòng (Element Shift).
func extra_tags() -> Array:
	var t: Array = []
	if has_effect("clock"):
		t.append(&"time")
	if has_effect("elements"):
		t.append(ELEMENTS[_element % ELEMENTS.size()])
	return t


# --- Thi triển -----------------------------------------------------------------

## Skill `i` (0 = Skill 1, 1 = Skill 2). Trả true nếu đã tung.
func try_skill(i: int) -> bool:
	var s := skill(i)
	if s.is_empty() or player.current_form == null:
		return false
	if cooldowns[i] > 0.0:
		return false
	var cost := float(s["cost"])
	if player.rage < cost:
		player.notice.emit("Cần %d nộ cho %s" % [int(cost), s["name"]])
		return false
	var targets: Array = []
	var type := str(s["type"])
	if type in ["lock", "lock_multi"] or (type == "bind" and str(s.get("via", "lock")) == "lock"):
		targets = find_targets(float(s.get("range", Skills.LOCK_RANGE)), int(s.get("targets", 1)))
		if targets.is_empty():
			player.notice.emit("Không có mục tiêu trong tầm")
			return false
	player.pay_rage(cost)
	cooldowns[i] = float(s["cooldown"])
	_announce(s)
	if s.has("heal"):
		player.heal_rider(float(s["heal"]))      # Kiva Bat: Kivat cắn rồi hồi chút máu
	match type:
		"aim":
			_aim(s)
		"lock", "lock_multi":
			_lock(s, targets)
		"bind":
			_bind(s, targets)
		"area":
			_area(s)
		"counter":
			_start_counter(s, false)
		"buff":
			_buff_skill(s)
	return true


## Final Attack theo kiểu của form (Skills). Tốn FINAL_COST nộ.
func try_final() -> bool:
	if not can_final() or player.state != Player.State.NORMAL and player.state != Player.State.CROUCH:
		return false
	var form := player.current_form
	var type := form.final_type()
	var targets: Array = []
	if type in ["lock", "lock_multi", "bind"]:
		targets = find_targets(FINAL_LOCK_RANGE, form.final_targets() if type == "lock_multi" else 1)
		if targets.is_empty():
			type = "aim"       # không có ai trong tầm khoá: tung như Final thường, không phí nộ
	player.pay_rage(Skills.FINAL_COST)
	player.final_fanfare()
	var data := form.get_attack(&"final", 0)
	if data.is_empty():
		return true
	match type:
		"lock", "lock_multi", "bind":
			_final_lock(data, targets, type)
		"area":
			var d := data.duplicate()
			d.erase("lunge")
			d["damage"] = float(d["damage"]) * float(Skills.FINAL_TYPE_DAMAGE["area"])
			d["size"] = Vector2(Skills.AREA_RADIUS * 2.0, 60)
			d["offset"] = Vector2(0, -20)
			Fx.spawn(player.get_parent(), player.global_position + Vector2(0, -20) * Units.SCALE, "ring",
				player.current_fx()["color"], player.facing, 2.2)
			player.begin_skill(&"final", d)
		"counter":
			_start_counter({"damage": float(data["damage"]) * float(Skills.FINAL_TYPE_DAMAGE["counter"]),
				"tags": data["tags"], "fx": "", "knockback": data["knockback"]}, true)
		_:
			player.start_attack(&"final")
	return true


## Quái / đối thủ phe kia gần nhất phía trước trong tầm `range_px` (đơn vị thiết kế), tối đa `count`.
func find_targets(range_px: float, count: int) -> Array:
	var me := player.global_position
	var reach := range_px * Units.SCALE
	var found: Array = []
	for node in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("player"):
		var n := node as Node2D
		if n == null or n == player or not is_instance_valid(n) or n.is_queued_for_deletion() or not _alive(n):
			continue
		var hb := n.get_node_or_null("Hurtbox") as Hurtbox
		if hb == null or hb.team == player.team:
			continue
		var d := n.global_position - me
		if d.x * player.facing < -12.0 or absf(d.x) > reach or absf(d.y) > 110.0 * Units.SCALE:
			continue
		found.append([d.length(), n])
	found.sort_custom(func(a, b): return a[0] < b[0])
	return found.slice(0, count).map(func(pair): return pair[1])


static func _alive(n: Node) -> bool:
	if n is Enemy:
		return (n as Enemy).state != Enemy.State.DEAD
	if n is Player:
		return (n as Player).state != Player.State.KO
	return true


## Đánh chắc trúng `target` (đi qua Hurtbox nên né, bất tử, quái đặc biệt... vẫn đúng luật). Trả true nếu trúng.
func strike(node: Variant, damage: float, knockback: Vector2, tags: Array, fx_kind := "", bind := 0.0) -> bool:
	if not is_instance_valid(node) or not node is Node2D or not _alive(node):
		return false      # mục tiêu đã gục / biến mất trong lúc tụ đòn
	var target := node as Node2D
	var hb := target.get_node_or_null("Hurtbox") as Hurtbox
	if hb == null or hb.team == player.team:
		return false
	var dir := 1 if target.global_position.x >= player.global_position.x else -1
	var info := DamageInfo.new(damage, knockback, dir, player.attack_tags(tags), player)
	info.bind_time = bind
	var at := target.global_position + Vector2(0, -30) * Units.SCALE
	if fx_kind != "":
		Fx.spawn(player.get_parent(), at, fx_kind, _color, dir, 1.3)
	if hb.receive(info):
		player.on_skill_hit(target, info)
		return true
	return false


# --- Từng kiểu ------------------------------------------------------------------

func _announce(s: Dictionary) -> void:
	var fx := player.current_fx()
	_color = s.get("color", fx["color"])
	CombatDirector.skill_used.emit(str(s["name"]), _color)
	Sound.sfx("form_change" if str(s["type"]) == "buff" else "final_charge", 0.05, -8.0)
	var summon := str(s.get("summon", ""))
	if summon != "":
		Fx.spawn(player.get_parent(), player.global_position + Vector2(0, -30) * Units.SCALE, summon, _color,
			player.facing, 1.2)


func _anim(s: Dictionary) -> String:
	return str(s.get("anim", "light" if int(s["tier"]) == 0 else "heavy"))


func _tags(s: Dictionary, extra: Array = []) -> Array:
	var t: Array = (s["tags"] as Array).duplicate()
	t.append(&"skill")
	for x in extra:
		if not t.has(x):
			t.append(x)
	return t


func _aim(s: Dictionary) -> void:
	var tier := int(s["tier"])
	var move := str(s["move"])
	var kb: Vector2 = s.get("knockback", Vector2(150, -50) if tier == 0 else Vector2(220, -90))
	var extra := {"anim": _anim(s), "hits": int(s.get("hits", 1)), "no_cancel": true, "fx_color": _color}
	if s.has("fx"):
		extra["hit_fx"] = str(s["fx"])     # hiệu ứng riêng của skill hiện trên quái trúng đòn
	match move:
		"dash":
			extra["lunge"] = Vector2(230, -10) if tier == 0 else Vector2(280, -40)
			player.begin_skill(&"skill", RiderForm.make_attack(s["damage"], 0.08, 0.16, 0.25, Vector2(32, 18),
				Vector2(20, -14), kb, _tags(s), extra))
		"pull":
			player.begin_skill(&"skill", RiderForm.make_attack(s["damage"], 0.1, 0.14, 0.3, Vector2(70, 16),
				Vector2(40, -14), s.get("knockback", Vector2(-200, -40)), _tags(s, [&"force"]), extra))
		"leap":
			extra["lunge"] = Vector2(150, -330)
			player.begin_skill(&"skill", RiderForm.make_attack(s["damage"], 0.06, 0.45, 0.3, Vector2(40, 46),
				Vector2(16, -6), kb, _tags(s, [&"heavy"]), extra))
		_:
			var d := RiderForm.make_attack(0.0, 0.12, 0.05, 0.22, Vector2.ZERO, Vector2.ZERO, kb, _tags(s, [&"ranged"]), extra)
			d["on_active"] = _fire_shots.bind(s)
			player.begin_skill(&"skill", d)


## Đạn của skill [Đ]: shot (1 viên), spread (loạt tỏa), wave (sóng chém xuyên), boomerang / steer (bay về tay).
func _fire_shots(s: Dictionary) -> void:
	var move := str(s["move"])
	var fx := player.current_fx()
	var shot := {"style": str(fx["shot"]), "speed": 340.0, "radius": 4.0, "count": 1, "spread": 0.0, "pierce": false,
		"life": 0.9}
	match move:
		"spread":
			shot.merge({"count": 3, "spread": 0.26}, true)
		"wave":
			shot.merge({"style": "wave", "speed": 260.0, "radius": 7.0, "pierce": true, "life": 0.8}, true)
		"boomerang", "steer":
			shot.merge({"style": "spin", "speed": 280.0, "radius": 6.0, "pierce": true, "life": 1.4}, true)
	shot.merge(s.get("shot", {}), true)
	var count := int(shot["count"])
	var aim := player.aim_dir()
	var per := float(s["damage"]) * (1.0 if count == 1 else 0.55)
	for i in count:
		var off: float = (i - (count - 1) / 2.0) * float(shot["spread"])
		var p := player.spawn_projectile(per, aim.rotated(off) * float(shot["speed"]) * Units.SCALE,
			float(shot["radius"]), s.get("color", fx["color"]), bool(shot["pierce"]), float(shot["life"]),
			str(shot["style"]), _tags(s))
		if s.has("fx"):
			p.hit_fx = str(s["fx"])
		if move in ["boomerang", "steer"]:
			p.boomerang = player
			p.steer = move == "steer"
	Sound.sfx("shot_heavy", 0.08, -3.0)


func _lock(s: Dictionary, targets: Array) -> void:
	var charge := float(s.get("charge", Skills.LOCK_TIME))
	_mark(targets, charge)
	var d := RiderForm.make_attack(0.0, charge, 0.12, 0.3, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, [],
		{"anim": _anim(s), "no_cancel": true})
	d["on_active"] = func() -> void:
		_clear_marks()
		for t in targets:
			for h in int(s.get("hits", 1)):
				strike(t, float(s["damage"]) * player.damage_mult(),
					s.get("knockback", Vector2(120, -60)), _tags(s), str(s.get("fx", "spark")))
	player.begin_skill(&"skill", d)


func _bind(s: Dictionary, targets: Array) -> void:
	var bind := float(s["bind"])
	match str(s.get("via", "lock")):
		"shot":
			var d := RiderForm.make_attack(0.0, 0.12, 0.05, 0.25, Vector2.ZERO, Vector2.ZERO, Vector2(20, -10),
				[], {"anim": _anim(s), "no_cancel": true})
			d["on_active"] = func() -> void:
				var fx := player.current_fx()
				var shot := {"style": "spin", "speed": 300.0, "radius": 6.0}
				shot.merge(s.get("shot", {}), true)
				var p := player.spawn_projectile(float(s["damage"]), player.aim_dir() * float(shot["speed"]) * Units.SCALE,
					float(shot["radius"]), s.get("color", fx["color"]), false, 0.9, str(shot["style"]),
					_tags(s, [&"bind"]))
				p.bind_time = bind
			player.begin_skill(&"skill", d)
		"area":
			var d := RiderForm.make_attack(s["damage"], 0.15, 0.12, 0.3,
				Vector2(float(s.get("radius", Skills.AREA_RADIUS)) * 2.0, 60), Vector2(0, -20),
				s.get("knockback", Vector2(-40, -20)), _tags(s, [&"bind"]), {"anim": _anim(s), "no_cancel": true})
			d["bind_time"] = bind
			Fx.spawn(player.get_parent(), player.global_position, str(s.get("fx", "ring")), _color,
				player.facing, 2.0)
			player.begin_skill(&"skill", d)
		_:
			_mark(targets, Skills.LOCK_TIME)
			var drum := str(s.get("special", "")) == "drum"
			var d := RiderForm.make_attack(0.0, Skills.LOCK_TIME, bind if drum else 0.12, 0.3, Vector2.ZERO, Vector2.ZERO,
				Vector2.ZERO, [], {"anim": _anim(s), "no_cancel": true})
			d["on_active"] = func() -> void:
				_clear_marks()
				for t in targets:
					if is_instance_valid(t) and t is Enemy:
						(t as Enemy).apply_bind(bind)
					strike(t, float(s["damage"]) * player.damage_mult(), Vector2(10, -10), _tags(s, [&"bind"]),
						str(s.get("fx", "ring")), bind)
				if drum and not targets.is_empty():
					_drum = {"target": targets[0], "time": bind, "beat": DRUM_BEAT, "score": 0.0,
						"damage": float(s["damage"]) * player.damage_mult(), "tags": _tags(s), "fx": str(s.get("fx", "taiko"))}
					player.notice.emit("ĐÁNH TRỐNG THEO NHỊP!")
			if drum:
				d["on_end"] = _drum_finish
			player.begin_skill(&"skill", d)


func _area(s: Dictionary) -> void:
	var r := float(s.get("radius", Skills.AREA_RADIUS))
	var d := RiderForm.make_attack(s["damage"], 0.12, 0.14, 0.3, Vector2(r * 2.0, 64), Vector2(0, -20),
		s.get("knockback", Vector2(200, -80)), _tags(s), {"anim": _anim(s), "hits": int(s.get("hits", 1)), "no_cancel": true,
		"fx_color": _color})
	if s.has("fx"):
		d["hit_fx"] = str(s["fx"])
	Fx.spawn(player.get_parent(), player.global_position + Vector2(0, -16) * Units.SCALE, str(s.get("fx", "ring")),
		_color, player.facing, r / 30.0)
	if s.has("slow"):
		d["on_active"] = func() -> void:
			player.fire_attack_hitbox()
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Enemy and (e as Node2D).global_position.distance_to(player.global_position) <= r * Units.SCALE * 1.2:
					(e as Enemy).slow(float(s["slow"]))
	player.begin_skill(&"skill", d)


## Thế phản đòn: Skill [P] hoặc Final kiểu "counter" (final = true: hết thế mà không ai đánh thì tự tung Final thường).
func _start_counter(s: Dictionary, final: bool) -> void:
	var window := Skills.FINAL_COUNTER_WINDOW if final else float(s.get("window", Skills.COUNTER_WINDOW))
	_counter = {"damage": float(s["damage"]), "tags": s.get("tags", []), "fx": str(s.get("fx", "")), "final": final,
		"knockback": s.get("knockback", Vector2(240, -100))}
	var d := RiderForm.make_attack(0.0, 0.0, window, 0.15, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, [],
		{"anim": "crouch", "no_cancel": true})
	d["on_active"] = func() -> void: pass
	d["on_end"] = func() -> void:
		if not _counter.is_empty():
			_counter = {}
			if final:
				player.start_attack(&"final")
	d["parry"] = true      # đạn bay tới trong thế đỡ: phản đạn
	Fx.spawn(player.get_parent(), player.global_position + Vector2(10 * player.facing, -30) * Units.SCALE, "ring",
		player.current_fx()["color"], player.facing, 1.0)
	player.begin_skill(&"final" if final else &"skill", d)


## Player.take_hit gọi trước khi trừ máu. Trả true nếu đòn bị hoá giải (phản đòn, tự né).
func intercept_hit(info: DamageInfo) -> bool:
	if not _counter.is_empty():
		var c := _counter
		_counter = {}
		var src := info.source as Node2D
		player.counter_pose(bool(c["final"]))
		if is_instance_valid(src) and src != player:
			var tags: Array = (c["tags"] as Array).duplicate()
			tags.append(&"skill")
			if c["final"]:
				tags.append(&"final")
			strike(src, float(c["damage"]) * player.damage_mult(), c["knockback"], tags,
				str(c["fx"]) if str(c["fx"]) != "" else "slash")
		player.notice.emit("PHẢN ĐÒN!")
		return true
	if has_effect("dodge_next") and not info.has_tag(&"final"):
		_effects.erase("dodge_next")
		player.auto_dodge()
		player.notice.emit("DỰ ĐOÁN!")
		return true
	if has_effect("liquid") and not info.has_tag(&"ranged"):
		return true
	return false


func _buff_skill(s: Dictionary) -> void:
	var d := RiderForm.make_attack(0.0, 0.1, 0.05, 0.15, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, [],
		{"anim": str(s.get("anim", "light")), "no_cancel": true})
	d["on_active"] = func() -> void: apply_buff(s.get("buff", {}), str(s.get("fx", "")))
	player.begin_skill(&"skill", d)


## Bật các hiệu ứng của buff (xem Skills "buff").
func apply_buff(b: Dictionary, fx_kind := "") -> void:
	var time := float(b.get("time", Skills.BUFF_TIME))
	var color: Color = _color
	Fx.spawn(player.get_parent(), player.global_position + Vector2(0, -28) * Units.SCALE,
		fx_kind if fx_kind != "" else "ring", color, player.facing, 1.4)
	for key in b:
		var v = b[key]
		if key == "time":
			pass
		elif key == "heal":
			player.heal_rider(float(v))
		elif key == "expose":
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Enemy and (e as Node2D).global_position.distance_to(player.global_position) <= 260.0 * Units.SCALE:
					(e as Enemy).expose(time)
		else:
			if key == "clock" and not has_effect("clock"):
				CombatDirector.set_enemy_time_scale(TIME_ENEMY_SCALE)
				if player.speed_mult == 1.0:
					player.speed_mult = TIME_SPEED_MULT
				player.notice.emit(str(v) if v is String else "CLOCK UP")
				Sound.sfx("clock_up", 0.0)
			elif key == "clones":
				_spawn_clones(int(v))
			_effects[key] = {"value": v, "time": minf(time, 2.0) if key == "behind" else time}
	player.on_buffs_changed()


func _end_effect(key: String) -> void:
	_effects.erase(key)
	match key:
		"clock":
			if player.current_form == null or not player.current_form.is_time_form():
				CombatDirector.set_enemy_time_scale(1.0)
				player.speed_mult = 1.0
		"clones":
			_clear_clones()
		"behind":
			_teleport_behind()
	player.on_buffs_changed()


## Dream Dive: hết giấc mơ thì trồi ra sau lưng quái gần nhất.
func _teleport_behind() -> void:
	var t := find_targets(220.0, 1)
	if t.is_empty():
		return
	var e := t[0] as Node2D
	var side := 1 if e.global_position.x >= player.global_position.x else -1
	player.global_position = Vector2(e.global_position.x + side * 30.0 * Units.SCALE, player.global_position.y)
	player.face(-side)
	Fx.spawn(player.get_parent(), player.global_position + Vector2(0, -30) * Units.SCALE, "ring",
		player.current_fx()["color"], player.facing, 1.2)


# --- Phân thân ----------------------------------------------------------------

func _spawn_clones(n: int) -> void:
	_clear_clones()
	for i in n:
		var c := SkillClone.new()
		c.player = player
		c.slot = i
		c.tint = player.current_fx()["color"]
		player.get_parent().add_child(c)
		c.global_position = player.global_position
		_clones.append(c)


func _clear_clones() -> void:
	for c in _clones:
		if is_instance_valid(c):
			c.vanish()
	_clones.clear()


## Player vừa bật hitbox của một đòn: phân thân đánh theo (CLONE_DAMAGE sát thương) ở chỗ của mình.
func on_hitbox_fired(info: DamageInfo, size: Vector2, offset: Vector2) -> void:
	if has_effect("elements"):
		_element += 1
	for c in _clones:
		if not is_instance_valid(c):
			continue
		var center := c.global_position + Vector2(offset.x * player.facing, offset.y) * Units.SCALE
		var rect := Rect2(center - size * Units.SCALE / 2.0, size * Units.SCALE).grow(4.0)
		for node in get_tree().get_nodes_in_group("enemies"):
			var e := node as Enemy
			if e == null or e.state == Enemy.State.DEAD:
				continue
			if rect.has_point(e.global_position + Vector2(0, -20) * Units.SCALE):
				strike(e, info.damage * CLONE_DAMAGE, info.knockback, info.tags.filter(func(t): return t != &"final"))
		c.swing()


# --- Đánh trống (Hibiki) ---------------------------------------------------------

## Nút Đánh trong lúc trống: đúng nhịp thì cộng nhiều sát thương vào cú thanh tẩy cuối.
func drum_hit() -> void:
	if _drum.is_empty():
		return
	var to_beat := absf(float(_drum["beat"]))
	var on_beat := to_beat <= DRUM_WINDOW or DRUM_BEAT - to_beat <= DRUM_WINDOW
	_drum["score"] = float(_drum["score"]) + (DRUM_HIT if on_beat else DRUM_MISS)
	var t: Node2D = _drum["target"] if is_instance_valid(_drum["target"]) else null
	if t:
		Fx.spawn(player.get_parent(), t.global_position + Vector2(0, -30) * Units.SCALE, "taiko" if on_beat else "sound",
			player.current_fx()["color"], player.facing, 1.0 if on_beat else 0.6)
	Sound.sfx("hit_heavy" if on_beat else "hit", 0.05, -2.0)
	player.play_anim("light")


func _drum_finish() -> void:
	if _drum.is_empty():
		return
	var dr := _drum
	_drum = {}
	var t: Node2D = dr["target"] if is_instance_valid(dr["target"]) else null
	if t:
		Fx.spawn(player.get_parent(), t.global_position + Vector2(0, -30) * Units.SCALE, "sound",
			player.current_fx()["color"], player.facing, 2.2)
		strike(t, float(dr["damage"]) * (1.0 + float(dr["score"])), Vector2(220, -120), dr["tags"] + [&"heavy"], "taiko")
	player.notice.emit("THANH TẨY!")


# --- Final kiểu khoá / trói ------------------------------------------------------

func _final_lock(data: Dictionary, targets: Array, type: String) -> void:
	_mark(targets, Skills.LOCK_TIME + 0.1)
	var bind := type == "bind"
	if bind:
		for t in targets:
			if is_instance_valid(t) and t is Enemy:
				(t as Enemy).apply_bind(Skills.BIND_TIME)
	var mult := float(Skills.FINAL_TYPE_DAMAGE[type])
	var d := data.duplicate()
	d.erase("lunge")
	d["startup"] = Skills.LOCK_TIME + 0.1
	d["active"] = 0.15
	var hits := int(data.get("hits", 1))
	d["hits"] = 1
	d["on_active"] = func() -> void:
		_clear_marks()
		var tags: Array = (data["tags"] as Array).duplicate()
		tags.append(&"final")
		if bind:
			tags.append(&"bind")
		for t in targets:
			for h in hits:
				strike(t, float(data["damage"]) * mult * player.damage_mult(), data["knockback"], tags, "",
					Skills.BIND_TIME if bind else 0.0)
	player.begin_skill(&"final", d)


# --- Dấu khoá -------------------------------------------------------------------

func _mark(targets: Array, time: float) -> void:
	_marked = targets.duplicate()
	for t in targets:
		if not is_instance_valid(t):
			continue
		if t is Enemy:
			(t as Enemy).mark_lock(time)
		elif t is Player:
			(t as Player).mark_lock(time)
	player.lock_marked.emit(targets, time)


func _clear_marks() -> void:
	_marked.clear()


# --- Mỗi khung --------------------------------------------------------------------

func tick(delta: float) -> void:
	for i in cooldowns.size():
		cooldowns[i] = maxf(cooldowns[i] - delta, 0.0)
	for key in _effects.keys():
		_effects[key]["time"] = float(_effects[key]["time"]) - delta
		if float(_effects[key]["time"]) <= 0.0:
			_end_effect(key)
	if not _drum.is_empty():
		_drum["time"] = float(_drum["time"]) - delta
		_drum["beat"] = float(_drum["beat"]) - delta
		if float(_drum["beat"]) <= -DRUM_WINDOW:
			_drum["beat"] = float(_drum["beat"]) + DRUM_BEAT
			var t: Node2D = _drum["target"] if is_instance_valid(_drum["target"]) else null
			if t:
				Fx.spawn(player.get_parent(), t.global_position + Vector2(0, -30) * Units.SCALE, "sound",
					Color(1, 1, 1), 1, 0.5)


## Bị đánh trúng lúc đang tụ: huỷ skill (dấu khoá, thế đỡ, trống).
func interrupt() -> void:
	_clear_marks()
	_counter = {}
	_drum = {}


## Đổi form / về dạng người / vào màn: huỷ buff, phân thân, thế đỡ. reset_cooldowns: vào màn mới.
func clear(reset_cooldowns := false) -> void:
	interrupt()
	for key in _effects.keys():
		_end_effect(key)
	_effects.clear()
	_clear_clones()
	if reset_cooldowns:
		cooldowns = [0.0, 0.0]


## [còn lại, tổng] hồi chiêu của Skill `i` (vòng hồi chiêu trên nút).
func cooldown_of(i: int) -> Vector2:
	var s := skill(i)
	return Vector2(cooldowns[i], float(s.get("cooldown", 1.0))) if not s.is_empty() else Vector2.ZERO
