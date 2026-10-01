extends Node2D
class_name Fx
## Hiệu ứng đánh vẽ bằng _draw rồi tự biến mất, không cần sprite. Tạo bằng Fx.spawn(); bóng mờ bằng Fx.ghost().
##
## Kiểu hiệu ứng (KINDS), mỗi form chọn trong RiderForm.fx():
##   spark      tia va chạm toả ra (đấm đá thường)
##   slash      vệt chém hình cung trước mặt (kiếm, giáo, dùi trống)
##   fire       lửa bùng bốc lên (Agito Flame, Ryuki Strike Vent, Hibiki Onibi / Kurenai)
##   lightning  tia sét gấp khúc (Blade Thunder Deer, Lightning Blast)
##   sound      vòng sóng âm lan ra (Hibiki: Makamou chỉ bị thanh tẩy bằng âm thanh)
##   wind       vệt gió xoáy (Agito Storm, Kuuga Dragon)
##   ring       sóng chấn động dẹt (đòn nặng, Final Attack)
##   tachyon    hạt sáng bắn ngược lên (Kabuto Rider Kick)
##   feather    lông vũ vàng rơi lả tả (Blade Jack Form lượn)
## Kiểu đạn (SHOTS, Projectile.style): ball, bolt (tia sét), fire (cầu lửa), arrow (mũi tên khí Pegasus).

const KINDS := ["spark", "slash", "fire", "lightning", "sound", "wind", "ring", "tachyon", "feather"]
const SHOTS := ["ball", "bolt", "fire", "arrow"]
const LIFE := {"spark": 0.18, "slash": 0.16, "fire": 0.35, "lightning": 0.22, "sound": 0.45, "wind": 0.3,
	"ring": 0.35, "tachyon": 0.45, "feather": 0.7, "ghost": 0.22}

var kind := "spark"
var color := Color.WHITE
var dir := 1
var size := 1.0
var life := 0.2

var _t := 0.0
var _seed := 0
var _tex: Texture2D = null
var _flip := false


## Hiệu ứng `kind` tại `pos` (toạ độ toàn cục), hướng `dir` (1 = phải), to gấp `scale_mult`.
static func spawn(parent: Node, pos: Vector2, fx_kind: String, fx_color: Color, fx_dir := 1, scale_mult := 1.0) -> Fx:
	if parent == null or not fx_kind in KINDS:
		return null
	var f := Fx.new()
	f.kind = fx_kind
	f.color = fx_color
	f.dir = 1 if fx_dir >= 0 else -1
	f.size = scale_mult * Units.SCALE
	f.life = LIFE[fx_kind]
	f._seed = randi()
	f.z_index = 20
	parent.add_child(f)
	f.global_position = pos
	return f


## Bóng mờ của khung hình đang hiện (tăng tốc thời gian, chạy nhanh): mờ dần tại chỗ.
static func ghost(parent: Node, sprite: AnimatedSprite2D, ghost_color: Color) -> void:
	if parent == null or sprite == null or sprite.sprite_frames == null or not sprite.visible:
		return
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return
	var f := Fx.new()
	f.kind = "ghost"
	f.color = ghost_color
	f.life = LIFE["ghost"]
	f._tex = tex
	f._flip = sprite.flip_h
	f.z_index = -1
	parent.add_child(f)
	f.global_position = sprite.global_position
	f.scale = sprite.global_scale


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / life
	var a := 1.0 - k
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var core := Color(1, 1, 1, a)
	var col := Color(color, a)
	match kind:
		"ghost":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if _flip else 1.0, 1.0))
			draw_texture(_tex, -_tex.get_size() / 2.0, Color(color, 0.55 * a))
		"spark":
			draw_circle(Vector2.ZERO, 5.0 * size * a, core)
			for i in 7:
				var ang := rng.randf_range(0.0, TAU)
				var v := Vector2.from_angle(ang)
				var r0 := 3.0 * size * k
				var r1 := r0 + rng.randf_range(6.0, 13.0) * size * (1.0 - 0.5 * k)
				draw_line(v * r0, v * r1, col, 1.6 * size * a + 0.5)
		"slash":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
			var sweep := minf(1.0, k * 2.5)
			var start := deg_to_rad(-110.0)
			var end := start + deg_to_rad(150.0) * sweep
			draw_arc(Vector2.ZERO, 16.0 * size, start, end, 14, col, 4.0 * size * a + 0.5)
			draw_arc(Vector2.ZERO, 16.0 * size, start, end, 14, core, 1.4 * size * a + 0.3)
		"fire":
			for i in 7:
				var off := Vector2(rng.randf_range(-7.0, 7.0), rng.randf_range(-4.0, 4.0)) * size
				off.y -= rng.randf_range(6.0, 16.0) * size * k
				var r := rng.randf_range(3.0, 6.0) * size * (1.0 - 0.6 * k)
				draw_circle(off, r, Color(color.lerp(Color(0.8, 0.1, 0.05), k), a))
				draw_circle(off, r * 0.5, Color(1.0, 0.9, 0.4, a))
		"lightning":
			for b in 3:
				var ang := rng.randf_range(0.0, TAU)
				var pts := PackedVector2Array([Vector2.ZERO])
				var p := Vector2.ZERO
				for s in 5:
					p += Vector2.from_angle(ang + rng.randf_range(-0.9, 0.9)) * 4.5 * size
					pts.append(p)
				draw_polyline(pts, col, 2.4 * size * a + 0.5)
				draw_polyline(pts, core, 0.8 * size + 0.3)
			draw_circle(Vector2.ZERO, 4.0 * size * a, core)
		"sound":
			for i in 3:
				var r := (5.0 + 26.0 * k - i * 6.0) * size
				if r > 0.0:
					draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(color, a * (1.0 - i * 0.25)), 2.0 * size * a + 0.5)
		"wind":
			for i in 3:
				var r := (7.0 + i * 5.0 + 6.0 * k) * size
				var s0 := k * TAU * 0.8 + i * 2.1
				draw_arc(Vector2.ZERO, r, s0, s0 + 2.2, 12, Color(color.lightened(0.3), a), 2.0 * size * a + 0.5)
		"ring":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, (6.0 + 40.0 * k) * size, 0.0, TAU, 36, col, 4.0 * size * a + 0.5)
			draw_arc(Vector2.ZERO, (4.0 + 28.0 * k) * size, 0.0, TAU, 36, core, 1.5 * size * a + 0.3)
		"tachyon":
			for i in 12:
				var x := rng.randf_range(-10.0, 10.0) * size
				var y0 := -rng.randf_range(0.0, 8.0) * size - 34.0 * size * k
				var c := color if i % 2 == 0 else Color(0.4, 0.75, 1.0)
				draw_line(Vector2(x, y0), Vector2(x, y0 + 6.0 * size), Color(c, a), 1.5 * size)
			draw_circle(Vector2.ZERO, 6.0 * size * a, core)
		"feather":
			for i in 3:
				var p := Vector2(rng.randf_range(-8.0, 8.0) + sin(k * 6.0 + i) * 4.0, 14.0 * k + i * 3.0) * size
				draw_line(p, p + Vector2(3.0, -5.0) * size, col, 1.6 * size)
				draw_line(p + Vector2(1.0, -2.0) * size, p + Vector2(3.0, -1.0) * size, Color(1, 1, 0.8, a), 1.0 * size)
