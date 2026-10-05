extends Node2D
class_name Summon
## Quái thú / đồng đội được skill hay Final gọi tới, theo nguyên tác: Dragreder lượn quanh Ryuki rồi phun lửa, Kivat
## bay tới cắn, Kabuto Zecter lao vào, Parka Ghost lướt qua quái... Khác Fx (hiệu ứng đứng yên một chỗ), Summon BAY:
## hiện sau lưng Rider, theo đường cong lao qua mục tiêu rồi biến mất. Sát thương vẫn do skill tính (SkillCaster),
## Summon chỉ là hình ảnh, canh giờ cho tới mục tiêu đúng lúc đòn khoá ra (~0,4 giây).
##
## Hình: art/summons/<kind>.png, dải khung nằm ngang nhìn sang phải (tools/gen_summons.py, PixelLab). Thiếu ảnh thì
## rồng (dragreder, dragranzer, brave_dragon) vẽ bằng code: thân rắn lượn sóng có vảy, sừng, bờm gai; con khác bỏ qua.
##
## Kiểu đường bay ("path"):
##   swoop  vòng từ trên sau lưng Rider xuống lao qua mục tiêu (rồng)
##   orbit  lượn một vòng quanh Rider rồi phóng về phía trước (Final Vent: rồng cuộn quanh rồi đẩy cú đá)
##   dart   bay thẳng nhanh tới mục tiêu, chạm thì vụt lên (Kivat, Zecter)
##   float  trôi chậm qua mục tiêu, nhấp nhô (Parka Ghost)
##   hop    nhảy nảy tới mục tiêu (Vice)

const SPECS := {
	"dragreder": {"frame": Vector2(128, 64), "scale": 1.1, "life": 1.2, "path": "swoop", "breath": "fire",
		"color": Color(0.9, 0.12, 0.1), "trim": Color(1.0, 0.8, 0.25)},
	"dragranzer": {"frame": Vector2(128, 64), "scale": 1.25, "life": 1.3, "path": "swoop", "breath": "fire",
		"color": Color(0.75, 0.08, 0.08), "trim": Color(0.15, 0.12, 0.14)},
	"brave_dragon": {"frame": Vector2(128, 64), "scale": 1.1, "life": 1.2, "path": "swoop", "breath": "fire",
		"color": Color(0.95, 0.2, 0.12), "trim": Color(1.0, 0.82, 0.3)},
	"kivat": {"frame": Vector2(64, 64), "scale": 0.6, "life": 0.8, "path": "dart", "fallback": "bat"},
	"kabuto_zecter": {"frame": Vector2(64, 64), "scale": 0.55, "life": 0.7, "path": "dart", "trail": "tachyon", "fallback": "tachyon"},
	"parka_ghost": {"frame": Vector2(64, 64), "scale": 0.9, "life": 1.1, "path": "float", "fallback": "eye"},
	"vice": {"frame": Vector2(64, 64), "scale": 0.8, "life": 1.0, "path": "hop", "fallback": "tachyon"},
}
const DRAGONS := ["dragreder", "dragranzer", "brave_dragon"]
const FPS := 12.0
const BREATH_EVERY := 0.07
const DRAWN_SCALE := 1.7          ## rồng vẽ bằng code: phóng thêm (nét vẽ mảnh hơn ảnh pixel)
static var _strips := {}

var kind := "dragreder"
var dir := 1
var from := Vector2.ZERO        ## toạ độ toàn cục điểm xuất hiện
var to := Vector2.ZERO          ## toạ độ toàn cục mục tiêu (Summon lướt qua đây ở khoảng 40% đường)
var center := Vector2.ZERO      ## orbit: tâm vòng lượn (Rider)
var life := 1.0
var _spec := {}
var _t := 0.0
var _breath_t := 0.0
var _tex: Texture2D
var _last := Vector2.ZERO
var _heading := 0.0


static func has(summon_kind: String) -> bool:
	return SPECS.has(summon_kind)


## Gọi `summon_kind` từ Rider ở `rider_pos` (toàn cục), hướng `facing`, lao tới `target` (toàn cục). Chưa có ảnh
## (và không phải rồng vẽ bằng code) thì hiện Fx "fallback" quanh Rider và trả null.
static func spawn(parent: Node, summon_kind: String, rider_pos: Vector2, target: Vector2, facing: int,
		path_override := "") -> Summon:
	if parent == null or not SPECS.has(summon_kind):
		return null
	var tex := _strip(summon_kind)
	if tex == null and not summon_kind in DRAGONS:
		Fx.spawn(parent, rider_pos + Vector2(0, -30) * Units.SCALE, str(SPECS[summon_kind].get("fallback", "ring")),
			Color(1.0, 0.85, 0.5), facing, 1.2)
		return null
	var s := Summon.new()
	s.kind = summon_kind
	s._spec = SPECS[summon_kind].duplicate()
	if path_override != "":
		s._spec["path"] = path_override
	s._tex = tex
	s.dir = 1 if facing >= 0 else -1
	s.life = float(s._spec["life"]) * (1.25 if s._spec["path"] == "orbit" else 1.0)
	s.center = rider_pos + Vector2(0, -30) * Units.SCALE
	s.from = rider_pos + Vector2(-60.0 * s.dir, -70.0) * Units.SCALE
	s.to = target
	s.z_index = 19
	parent.add_child(s)
	s.global_position = s._point(0.0)
	s._last = s.global_position
	return s


static func _strip(summon_kind: String) -> Texture2D:
	if not _strips.has(summon_kind):
		var path := "res://art/summons/%s.png" % summon_kind
		_strips[summon_kind] = load(path) if ResourceLoader.exists(path) else null
	return _strips[summon_kind]


## Vị trí trên đường bay ở tiến độ k (0..1).
func _point(k: float) -> Vector2:
	var d := float(dir)
	match str(_spec["path"]):
		"orbit":
			# 0..0,65: một vòng quanh Rider (bắt đầu sau lưng, phía trên); sau đó phóng về trước theo hướng mặt
			var r := 46.0 * Units.SCALE
			if k < 0.65:
				var ang := -PI / 2.0 - d * (PI / 2.0) + d * TAU * (k / 0.65)
				return center + Vector2(cos(ang) * r, sin(ang) * r * 0.55)
			var start := center + Vector2(cos(-PI / 2.0 - d * PI / 2.0) * r, sin(-PI / 2.0 - d * PI / 2.0) * r * 0.55)
			return start + Vector2(d * 420.0 * Units.SCALE * pow((k - 0.65) / 0.35, 1.4), 0.0)
		"dart":
			var mid := to + Vector2(-d * 6.0, -6.0) * Units.SCALE
			if k < 0.55:
				return from.lerp(mid, ease(k / 0.55, 0.6))
			var u := (k - 0.55) / 0.45
			return mid + Vector2(d * 90.0 * u, -120.0 * u * u) * Units.SCALE
		"float":
			var end := to + Vector2(d * 140.0, -20.0) * Units.SCALE
			var p := from.lerp(end, k)
			return p + Vector2(0.0, sin(k * TAU * 2.0) * 8.0 * Units.SCALE)
		"hop":
			var start2 := center + Vector2(-d * 30.0, 30.0) * Units.SCALE
			var end2 := to + Vector2(d * 40.0, 0.0)
			var p2 := start2.lerp(end2, k)
			return p2 - Vector2(0.0, absf(sin(k * PI * 3.0)) * 40.0 * Units.SCALE)
		_:
			# swoop: Bézier bậc hai từ sau lưng trên cao, võng xuống ngang mục tiêu ở k ≈ 0,45 rồi vút lên phía trước
			var end3 := to + Vector2(d * 220.0, -110.0) * Units.SCALE
			var ctrl := Vector2(lerpf(from.x, to.x, 0.6), to.y + 40.0 * Units.SCALE)
			var u3 := k
			return from * (1.0 - u3) * (1.0 - u3) + ctrl * 2.0 * u3 * (1.0 - u3) + end3 * u3 * u3


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	var k := _t / life
	var p := _point(k)
	var v := p - _last
	if v.length() > 0.5:
		_heading = lerp_angle(_heading, atan2(v.y, absf(v.x)), 0.35)
	_last = p
	global_position = p
	if _spec.has("breath") and k > 0.2 and k < 0.7:
		_breath_t -= delta
		if _breath_t <= 0.0:
			_breath_t = BREATH_EVERY
			_breathe()
	if _spec.has("trail") and int(_t * 30.0) % 3 == 0:
		Fx.spawn(get_parent(), global_position, str(_spec["trail"]), Color(1, 0.4, 0.3), dir, 0.5)
	queue_redraw()


## Lửa phun ra từ miệng về phía mục tiêu (Strike Vent / Final Vent).
func _breathe() -> void:
	var s := float(_spec["scale"])
	var fs: Vector2 = _spec["frame"]
	var mouth := global_position + Vector2(fs.x * 0.42 * dir, 4.0) * s * (1.0 if _tex else DRAWN_SCALE)
	var aim := (to - mouth)
	if aim.length() < 1.0 or signf(aim.x) != float(dir):
		aim = Vector2(dir, 0.35)
	# luồng lửa: cụm nhỏ sát miệng, to dần về phía mục tiêu
	var u := randf()
	var p := mouth + aim.normalized() * lerpf(14.0, 70.0, u) * Units.SCALE
	Fx.spawn(get_parent(), p, "fire", Color(1.0, 0.55, 0.15), dir, lerpf(0.35, 0.8, u))


func _draw() -> void:
	var k := _t / life
	var alpha := minf(1.0, k / 0.12) * (1.0 - maxf(0.0, k - 0.8) / 0.2)
	var s := float(_spec["scale"])     # khung ảnh vẽ đúng cỡ pixel gốc × scale
	draw_set_transform(Vector2.ZERO, _heading * dir * 0.6, Vector2(s * dir, s))
	if _tex:
		var fs: Vector2 = _spec["frame"]
		var n := maxi(int(_tex.get_width() / fs.x), 1)
		var i := int(_t * FPS) % n
		draw_texture_rect_region(_tex, Rect2(-fs / 2.0, fs), Rect2(Vector2(i * fs.x, 0), fs), Color(1, 1, 1, alpha))
	else:
		draw_set_transform(Vector2.ZERO, _heading * dir * 0.6, Vector2(s * dir, s) * DRAWN_SCALE)
		_draw_dragon(alpha)


## Rồng vẽ bằng code (khi chưa có ảnh PixelLab): thân rắn lượn sóng từ đuôi tới đầu, vảy bụng, gai lưng, đầu có
## hàm, sừng, mắt. Toạ độ theo khung 128×64 nhìn sang phải (tâm khung = gốc).
func _draw_dragon(alpha: float) -> void:
	var body: Color = _spec["color"]
	var trim: Color = _spec["trim"]
	var dark := body.darkened(0.45)
	var n := 18
	var pts: Array[Vector2] = []
	for i in n:
		var x := 34.0 - i * 5.2
		var y := sin(_t * 11.0 - i * 0.55) * (3.0 + i * 0.35)
		pts.append(Vector2(x, y))
	# thân: từ đuôi tới cổ, vòng to dần
	for j in n:
		var i := n - 1 - j
		var r := lerpf(7.5, 2.0, float(i) / (n - 1))
		var p := pts[i]
		draw_circle(p + Vector2(0, 1.0), r + 1.0, Color(0, 0, 0, alpha))
		draw_circle(p, r, Color(body, alpha))
		draw_circle(p + Vector2(0, r * 0.45), r * 0.5, Color(trim.lerp(Color(1, 0.9, 0.5), 0.3), alpha))   # vảy bụng
		if i % 2 == 0 and i > 0:                                                                            # gai lưng
			draw_colored_polygon(PackedVector2Array([p + Vector2(-2.2, -r + 0.5), p + Vector2(2.2, -r + 0.5),
				p + Vector2(-1.5, -r - 3.5)]), Color(trim, alpha))
	# chân trước, chân sau
	for leg in [3, 10]:
		var p: Vector2 = pts[leg]
		draw_line(p + Vector2(0, 3), p + Vector2(-3, 9), Color(dark, alpha), 2.2)
		draw_line(p + Vector2(-3, 9), p + Vector2(0, 11), Color(trim, alpha), 1.4)
	# đầu
	var h := pts[0] + Vector2(6, -2)
	var jaw := sin(_t * 14.0) * 1.5 + 2.5
	var head := PackedVector2Array([h + Vector2(-6, -6), h + Vector2(6, -6), h + Vector2(17, -2), h + Vector2(18, 1),
		h + Vector2(6, 2), h + Vector2(-5, 4)])
	var lower := PackedVector2Array([h + Vector2(-3, 3), h + Vector2(6, 2 + jaw * 0.3), h + Vector2(16, 3 + jaw),
		h + Vector2(5, 6 + jaw), h + Vector2(-4, 6)])
	draw_colored_polygon(lower, Color(trim.darkened(0.2), alpha))
	draw_colored_polygon(head, Color(body, alpha))
	draw_polyline(head + PackedVector2Array([head[0]]), Color(0, 0, 0, alpha), 1.0)
	draw_line(h + Vector2(4, -4), h + Vector2(16, -2), Color(trim, alpha), 1.2)          # mũi giáp bạc / vàng
	for horn in [Vector2(-3, -6), Vector2(1, -6)]:                                       # hai sừng vuốt ra sau
		draw_line(h + horn, h + horn + Vector2(-11, -6), Color(trim, alpha), 1.6)
	for m in 4:                                                                          # bờm gai sau đầu
		draw_line(h + Vector2(-5, -3 + m * 2), h + Vector2(-12 - m, -5 + m * 3), Color(trim.lightened(0.2), alpha), 1.0)
	draw_circle(h + Vector2(6, -3), 1.4, Color(1, 0.95, 0.3, alpha))                    # mắt
	draw_line(h + Vector2(14, 3), h + Vector2(15, 5 + jaw * 0.5), Color(1, 1, 1, alpha), 0.8)   # răng nanh
