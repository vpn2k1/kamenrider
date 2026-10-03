extends Area2D
class_name Projectile
## Viên đạn (của người chơi hoặc quái). Bay thẳng, trúng Hurtbox phe kia thì gây sát thương rồi biến mất
## (trừ đạn xuyên), chạm tường/mặt đất (lớp world) thì vỡ. Bay xuyên qua bệ một chiều.
## Tự vẽ bằng _draw theo style (Fx.SHOTS): ball quả cầu sáng, bolt tia sét, fire cầu lửa, arrow mũi tên khí.
## hit_fx: hiệu ứng Fx khi trúng ("" = không có).
## Chém đạn (Player._check_parry): vung vũ khí đúng lúc, đạn ở trong tầm lưỡi thì đạn bị chém tan (cut) hoặc,
## vung sớm và đạn ở mũi lưỡi, bị đánh bật ngược lại về phía kẻ bắn (reflect) với sát thương gấp đôi.
## Mọi viên đạn nằm trong nhóm GROUP để người chơi quét.
## Skill (SkillCaster): homing tự đuổi quái gần nhất; boomerang bay ra rồi quay về người ném (trúng lại được lúc về);
## steer lái lên / xuống bằng ↑ ↓ khi đang bay ra (Den-O Extreme Slash Toss); bind_time trói quái trúng đạn.

signal hit_landed(target: Node, info: DamageInfo)

const GROUP := &"projectiles"
const REFLECT_COLOR := Color(1.0, 0.85, 0.3)

var velocity := Vector2.ZERO
var damage := 5.0
var team: StringName = &"player"
var tags: Array = [&"ranged"]
var radius := 3.0
var color := Color(1, 1, 1)
var pierce := false
var life := 1.0
var source: Node = null
var style := "ball"
var hit_fx := ""
## Bản sao để nhìn (chế độ đấu: đạn của đối thủ do máy đối thủ tính trúng). Chạm Hurtbox phe kia thì tan, không gây sát thương.
var visual_only := false
var parried := false           ## đã bị chém / phản: không bị chém lần nữa
var bind_time := 0.0           ## > 0: trói quái trúng đạn chừng này giây (tag &"bind")
var homing := false            ## tự đuổi mục tiêu phe kia gần nhất phía trước
var boomerang: Node2D = null   ## người ném: bay ra hết nửa đời thì quay về người này
var steer := false             ## (boomerang) giữ ↑ / ↓ để lái khi đang bay ra

const HOMING_TURN := 6.0       ## rad/giây
const HOMING_RANGE := 220.0
const STEER_SPEED := 150.0

var _returning := false
var _life0 := 0.0


var _hit: Array = []


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 0
	collision_mask = 1 | 8        # world + hurtbox
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var ts: float = CombatDirector.enemy_time_scale if team == &"enemy" else 1.0
	if _life0 == 0.0:
		_life0 = life
	if homing:
		_home(delta)
	if is_instance_valid(boomerang):
		_boomerang(delta)
	position += velocity * delta * ts
	life -= delta * ts
	if life <= 0.0:
		queue_free()
	queue_redraw()


func _home(delta: float) -> void:
	var best: Node2D = null
	var best_d := HOMING_RANGE * Units.SCALE
	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node2D
		if n == null or (n is Enemy and (n as Enemy).state == Enemy.State.DEAD):
			continue
		var d := n.global_position + Vector2(0, -20) - global_position
		if d.length() < best_d and d.dot(velocity) > 0.0:
			best_d = d.length()
			best = n
	if best == null:
		return
	var want := (best.global_position + Vector2(0, -20) - global_position).angle()
	var cur := velocity.angle()
	var turn := clampf(wrapf(want - cur, -PI, PI), -HOMING_TURN * delta, HOMING_TURN * delta)
	velocity = velocity.rotated(turn)


func _boomerang(delta: float) -> void:
	if not _returning:
		if steer:
			var dy := Input.get_axis("move_up", "move_down")
			position.y += dy * STEER_SPEED * Units.SCALE * delta
		if life <= _life0 * 0.5:
			_returning = true
			_hit.clear()      # quay về: trúng lại được quái cũ
		return
	var to := boomerang.global_position + Vector2(0, -30) - global_position
	if to.length() < 14.0:
		queue_free()
		return
	velocity = to.normalized() * velocity.length()
	life = maxf(life, 0.2)


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null or hurtbox.team == team or _hit.has(hurtbox):
		return
	_hit.append(hurtbox)
	if visual_only:
		if not pierce:
			queue_free()
		return
	var dir := 1 if velocity.x >= 0.0 else -1
	# Người bắn có thể đã chết khi đạn còn bay: khi đó bỏ source (hướng đẩy lùi lấy theo hướng đạn).
	var src: Node = source if is_instance_valid(source) else null
	var info := DamageInfo.new(damage, Vector2(40, -20), dir, tags, src)
	info.bind_time = bind_time
	if hurtbox.receive(info):
		if hit_fx != "":
			Fx.spawn(get_parent(), global_position, hit_fx, color, dir)
		hit_landed.emit(hurtbox.get_parent(), info)
		if not pierce:
			queue_free()
	elif info.blocked:
		Fx.spawn(get_parent(), global_position, "spark", Color(0.75, 0.75, 0.8), -dir)
		queue_free()


func _on_body_entered(_body: Node2D) -> void:
	if is_instance_valid(boomerang):
		return        # vật ném bay xuyên tường rồi về tay
	queue_free()


## Bị chém tan: tia lửa rồi biến mất.
func cut() -> void:
	parried = true
	Fx.spawn(get_parent(), global_position, "spark", REFLECT_COLOR, 1 if velocity.x < 0.0 else -1, 1.2)
	queue_free()


## Bị đánh bật ngược: đổi phe sang người chém, bay về phía `target` (kẻ bắn, nếu còn sống) hoặc ngược hướng cũ,
## nhanh hơn speed_mult lần, sát thương ×dmg_mult, thêm &"heavy" (phá giáp).
func reflect(by: Node, new_team: StringName, target: Node2D, speed_mult: float, dmg_mult: float) -> void:
	parried = true
	team = new_team
	source = by
	damage *= dmg_mult
	tags = tags.duplicate()
	if not tags.has(&"heavy"):
		tags.append(&"heavy")
	var dir := -velocity.normalized()
	if is_instance_valid(target):
		var aim := (target.global_position + Vector2(0, -30) - global_position).normalized()
		if aim.x * dir.x > 0.0:      # kẻ bắn còn ở phía trước thì nhắm thẳng vào nó
			dir = aim
	velocity = dir * velocity.length() * speed_mult
	color = REFLECT_COLOR
	radius += 1.0
	life = maxf(life, 1.2)
	_hit.clear()
	queue_redraw()


func _draw() -> void:
	var fwd := velocity.normalized()
	match style:
		"wave":
			# Sóng chém: vầng trăng khuyết dựng đứng, lõi trắng.
			var ang := fwd.angle()
			draw_arc(Vector2.ZERO, radius * 2.2, ang - 1.2, ang + 1.2, 12, Color(color, 0.55), radius * 1.1)
			draw_arc(Vector2.ZERO, radius * 2.2, ang - 1.0, ang + 1.0, 12, Color(1, 1, 1, 0.9), maxf(radius * 0.35, 1.0))
		"spin":
			# Vật ném xoay tròn (lưỡi kiếm, bánh xe, khiên): đĩa có nan quay.
			var t := float(Time.get_ticks_msec()) * 0.02
			draw_circle(Vector2.ZERO, radius * 1.3, Color(color, 0.45))
			for i in 3:
				var v := Vector2.from_angle(t + TAU * i / 3.0) * radius * 1.4
				draw_line(-v, v, color, maxf(radius * 0.4, 1.0))
			draw_circle(Vector2.ZERO, radius * 0.4, Color(1, 1, 1))
		"bolt":
			# Tia sét: đường gấp khúc dọc theo hướng bay, đổi hình mỗi frame.
			var side := fwd.orthogonal()
			var pts := PackedVector2Array()
			for i in 6:
				var along := -fwd * radius * (5.0 - i * 1.2)
				pts.append(along + side * randf_range(-radius, radius) * (0.0 if i == 5 else 1.0))
			draw_polyline(pts, Color(color, 0.6), radius * 1.3)
			draw_polyline(pts, Color(1, 1, 1), maxf(radius * 0.4, 1.0))
		"fire":
			for i in 3:
				var off := -fwd * radius * (1.2 + i * 1.3) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * radius * 0.4
				draw_circle(off, radius * (0.9 - i * 0.22), Color(color.lerp(Color(0.8, 0.1, 0.05), i * 0.35), 0.75))
			draw_circle(Vector2.ZERO, radius * 1.1, color)
			draw_circle(Vector2.ZERO, radius * 0.55, Color(1.0, 0.95, 0.5))
		"arrow":
			var tail := -fwd * radius * 4.0
			draw_line(tail, Vector2.ZERO, Color(color, 0.7), radius * 0.8)
			draw_line(tail * 0.5, Vector2.ZERO, Color(1, 1, 1), maxf(radius * 0.35, 1.0))
			draw_colored_polygon(PackedVector2Array([fwd * radius * 1.4, fwd.orthogonal() * radius * 0.8,
				-fwd.orthogonal() * radius * 0.8]), color)
		_:
			var tail := -fwd * radius * 2.5
			draw_line(tail, Vector2.ZERO, Color(color, 0.5), radius * 1.4)
			draw_circle(Vector2.ZERO, radius + 1.5, Color(color, 0.45))
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1))
