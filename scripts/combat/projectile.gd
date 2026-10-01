extends Area2D
class_name Projectile
## Viên đạn (của người chơi hoặc quái). Bay thẳng, trúng Hurtbox phe kia thì gây sát thương rồi biến mất
## (trừ đạn xuyên), chạm tường/mặt đất (lớp world) thì vỡ. Bay xuyên qua bệ một chiều.
## Tự vẽ bằng _draw theo style (Fx.SHOTS): ball quả cầu sáng, bolt tia sét, fire cầu lửa, arrow mũi tên khí.
## hit_fx: hiệu ứng Fx khi trúng ("" = không có).

signal hit_landed(target: Node, info: DamageInfo)

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

var _hit: Array = []


func _ready() -> void:
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
	position += velocity * delta * ts
	life -= delta * ts
	if life <= 0.0:
		queue_free()
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null or hurtbox.team == team or _hit.has(hurtbox):
		return
	_hit.append(hurtbox)
	var dir := 1 if velocity.x >= 0.0 else -1
	# Người bắn có thể đã chết khi đạn còn bay: khi đó bỏ source (hướng đẩy lùi lấy theo hướng đạn).
	var src: Node = source if is_instance_valid(source) else null
	var info := DamageInfo.new(damage, Vector2(40, -20), dir, tags, src)
	if hurtbox.receive(info):
		if hit_fx != "":
			Fx.spawn(get_parent(), global_position, hit_fx, color, dir)
		hit_landed.emit(hurtbox.get_parent(), info)
		if not pierce:
			queue_free()


func _on_body_entered(_body: Node2D) -> void:
	queue_free()


func _draw() -> void:
	var fwd := velocity.normalized()
	match style:
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
