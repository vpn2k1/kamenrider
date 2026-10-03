extends Node2D
class_name Fx
## Hiệu ứng đánh: kiểu có ảnh PixelLab (SPRITES) chạy hoạt hình, còn lại vẽ bằng _draw; tự biến mất. Tạo bằng Fx.spawn(); bóng mờ bằng Fx.ghost().
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
## Dấu hiệu tuyệt chiêu riêng từng Rider (RiderForm.fx "intro" lúc tung Final quanh Rider, "signature" lúc Final trúng):
##   seal       dấu phong ấn Linto bốc cháy (Kuuga Mighty Kick)     crest    huy hiệu sừng Agito dưới chân
##   dragon     rồng lửa Dragreder xoáy quanh (Ryuki Final Vent)     pointer  mũi nón đỏ Pointer chĩa tới (Faiz)
##   phi        ký hiệu Φ đỏ trên quái (Faiz Crimson Smash)          cards    hàng thẻ bài hologram (Blade, Decade)
##   taiko      huy hiệu trống Ongeki + sóng âm (Hibiki)             moon     trăng lưỡi liềm sau lưng (Kiva)
##   rings3     ba vòng Medal đỏ / vàng / lục phía trước (OOO)       rocket   lửa tên lửa phụt sau lưng (Fourze)
##   circle     vòng phép đỏ có ký tự (Wizard)
##   graph      trục đồ thị x-y và đường cong parabol vẽ dần về phía trước (Build Vortex Finish)
##   hit_text   chữ "HIT!" vàng viền đen bật lên (Ex-Aid, như hiệu ứng game trong phim)
##   eye        con mắt Ghost khổng lồ sau lưng, viền gai lửa (Ghost Omega Drive)
##   tire       lốp xe đen vành bạc lăn vòng quanh Rider (Drive Tire Koukan)
##   crack      khe nứt khóa kéo Helheim mở ra trên đầu (Gaim)       fruit    lát trái cây khổng lồ chụp xuống rồi tách múi (Gaim)
## Hiệu ứng skill (docs/SKILLS.md, "fx" / "summon" của skill):
##   hexnet     lưới lục giác chụp quanh quái (Den-O Solid Attack)   chains   xích phép quấn vòng (Wizard Bind, trói)
##   pine       quả thông khổng lồ chụp xuống đầu (Gaim Pine Iron)   bulb     bóng đèn sáng chớp tỏa tia (Edison)
##   diamond    tường kim cương trước mặt, lấp lánh (Build GorillaMond) wheel  bánh xe lăn tới, nan quay (Ex-Aid Sports)
##   wings      đôi cánh lửa xòe sau lưng (Crimson Wing, bay)        water    cột nước dâng lên tỏa giọt (Shachi, Aqua)
##   cage       lồng cầu lưới bao quanh quái (Gatling Sphere)        kick_text chữ "KICK" bật lên (Zi-O Time Break)
##   drill      mũi khoan xoáy lao về trước (Fourze Drill)           claw     ba vệt vuốt chéo (Tora, Tiger, Garulu)
##   ice        tinh thể băng tỏa sáu nhánh (Blizzard, Freezing)     gravity  vòng xoáy hút vào tâm (Newton, Gravity)
##   shield     khiên lục giác sáng trước mặt (Defend, Guard Vent)   bat      đàn dơi nhỏ bay vòng (Kiva Bat)
##   clock      mặt đồng hồ kim quay nhanh (Clock Up, Boost)         stamp    dấu tem in xuống đất (Revice Stamping)
##   ken_text   chữ "KEN" bật lên (Zi-O Zikan Girade)
## Kiểu đạn (SHOTS, Projectile.style): ball, bolt (tia sét), fire (cầu lửa), arrow (mũi tên khí Pegasus),
## wave (sóng chém vầng trăng, skill), spin (vật ném xoay: lưỡi kiếm, bánh xe, khiên).

const KINDS := ["spark", "slash", "fire", "lightning", "sound", "wind", "ring", "tachyon", "feather",
	"seal", "crest", "dragon", "pointer", "phi", "cards", "taiko", "moon", "rings3", "rocket", "circle", "crack", "fruit", "tire", "eye", "hit_text", "graph",
	"hexnet", "chains", "pine", "bulb", "diamond", "wheel", "wings", "water", "cage", "kick_text", "drill", "claw", "ice",
	"gravity", "shield", "bat", "clock", "stamp", "ken_text"]
const SHOTS := ["ball", "bolt", "fire", "arrow", "wave", "spin"]
const LIFE := {"spark": 0.18, "slash": 0.16, "fire": 0.35, "lightning": 0.22, "sound": 0.45, "wind": 0.3,
	"ring": 0.35, "tachyon": 0.45, "feather": 0.7, "ghost": 0.22,
	"seal": 0.9, "crest": 0.8, "dragon": 0.7, "pointer": 0.6, "phi": 0.8, "cards": 0.6, "taiko": 0.8, "moon": 0.8,
	"rings3": 0.6, "rocket": 0.6, "circle": 0.7, "crack": 0.7, "fruit": 0.8, "tire": 0.7, "eye": 0.9, "hit_text": 0.7, "graph": 0.9,
	"hexnet": 0.8, "chains": 0.8, "pine": 0.7, "bulb": 0.6, "diamond": 0.7, "wheel": 0.6, "wings": 0.8, "water": 0.7,
	"cage": 0.8, "kick_text": 0.8, "drill": 0.5, "claw": 0.3, "ice": 0.6, "gravity": 0.7, "shield": 0.5, "bat": 0.7,
	"clock": 0.8, "stamp": 0.7, "ken_text": 0.8}

## Kiểu có hoạt hình PixelLab (art/fx/<kind>.png: dải khung 64×64 nằm ngang, vẽ trắng để tô màu form, trừ lửa).
## Thiếu ảnh thì quay về hình vẽ bằng _draw bên dưới. scale = cỡ khung so với size (size đã nhân Units.SCALE),
## tint = trộn màu form với trắng (0 = đúng màu form, 1 = giữ màu gốc của ảnh), y = dời tâm lên/xuống (× size),
## x = dời tâm về phía trước theo hướng dir (× size), grow = cỡ lúc đầu → cỡ cuối (nhân với scale), squash = ép dẹt
## theo chiều dọc (sóng chấn động trên mặt đất).
## Dấu hiệu tuyệt chiêu (seal ... eye): khung gốc PixelLab create_image_pixflux theo nguyên tác (Φ và mũi nón Pointer vẽ
## bằng code cho đúng hình), hoạt hình PixelLab animate_image; giữ màu gốc của ảnh (tint 1), trừ dấu Linto / thẻ / vòng
## phép tô theo màu form (Kuuga đổi màu theo form, thẻ Blade lam / Decade hồng, vòng phép Wizard theo Style).
const SPRITES := {
	"spark": {"scale": 0.45, "tint": 0.45},
	"slash": {"scale": 0.55, "tint": 0.35},
	"fire": {"scale": 0.5, "tint": 0.6, "y": -10.0},
	"lightning": {"scale": 0.6, "tint": 0.45},
	"sound": {"scale": 0.9, "tint": 0.3},
	"wind": {"scale": 0.65, "tint": 0.5},
	"ring": {"scale": 1.2, "tint": 0.35, "grow": [0.3, 1.4], "squash": 0.45},
	"tachyon": {"scale": 0.7, "tint": 0.4, "y": -22.0},
	"seal": {"scale": 0.55, "tint": 0.45},
	"crest": {"scale": 1.1, "tint": 1.0, "y": 30.0, "squash": 0.4, "grow": [0.4, 1.1]},
	"dragon": {"scale": 1.0, "tint": 1.0},
	"pointer": {"scale": 1.0, "tint": 1.0, "x": 36.0, "grow": [0.5, 1.0]},
	"phi": {"scale": 0.6, "tint": 1.0},
	"cards": {"scale": 1.0, "tint": 0.4, "x": 22.0},
	"taiko": {"scale": 0.6, "tint": 1.0},
	"moon": {"scale": 0.6, "tint": 1.0, "x": -10.0, "y": -40.0},
	"rings3": {"scale": 0.9, "tint": 1.0, "x": 24.0},
	"circle": {"scale": 0.75, "tint": 0.4, "x": 12.0, "y": -24.0},
	"crack": {"scale": 0.7, "tint": 1.0, "y": -34.0},
	"fruit": {"scale": 0.55, "tint": 1.0, "y": -16.0},
	"eye": {"scale": 0.8, "tint": 1.0, "y": -30.0},
}
const FRAME := 64
static var _strips := {}

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


## Dải khung PixelLab của `fx_kind`, nạp một lần; null nếu kiểu này không có ảnh.
static func _strip(fx_kind: String) -> Texture2D:
	if not SPRITES.has(fx_kind):
		return null
	if not _strips.has(fx_kind):
		var path := "res://art/fx/%s.png" % fx_kind
		_strips[fx_kind] = load(path) if ResourceLoader.exists(path) else null
	return _strips[fx_kind]


## Khung hoạt hình PixelLab ứng với tiến độ k (0..1), mờ dần ở 25% cuối.
func _draw_strip(strip: Texture2D, k: float) -> void:
	var spec: Dictionary = SPRITES[kind]
	var n := strip.get_width() / FRAME
	var i := mini(int(k * n), n - 1)
	var s := float(spec["scale"]) * size
	if spec.has("grow"):
		s *= lerpf(spec["grow"][0], spec["grow"][1], k)
	draw_set_transform(Vector2(float(spec.get("x", 0.0)) * dir, float(spec.get("y", 0.0))) * size, 0.0,
		Vector2(s * dir, s * float(spec.get("squash", 1.0))))
	var fade := 1.0 - maxf(0.0, k - 0.75) / 0.25
	draw_texture_rect_region(strip, Rect2(-FRAME / 2.0, -FRAME / 2.0, FRAME, FRAME), Rect2(i * FRAME, 0, FRAME, FRAME),
		Color(color.lerp(Color.WHITE, float(spec["tint"])), fade))


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
	var strip := _strip(kind)
	if strip:
		_draw_strip(strip, k)
		return
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
		"seal":                                   # dấu phong ấn: vòng tròn + nét chữ, cháy rực rồi tắt
			var r := 11.0 * size * (0.8 + 0.2 * sin(k * 20.0))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, col, 2.2 * size)
			draw_line(Vector2(-r * 0.6, -r * 0.3), Vector2(r * 0.6, -r * 0.3), col, 2.0 * size)
			draw_line(Vector2(0, -r * 0.7), Vector2(0, r * 0.7), col, 2.0 * size)
			draw_line(Vector2(-r * 0.5, r * 0.4), Vector2(r * 0.5, r * 0.4), col, 2.0 * size)
			draw_line(Vector2(-r * 0.35, -r * 0.65), Vector2(r * 0.35, r * 0.65), core, 1.0 * size)
		"crest":                                  # huy hiệu sừng Agito trải dưới chân
			draw_set_transform(Vector2(0, 30.0 * size), 0.0, Vector2(1.0, 0.35))
			var r := (10.0 + 22.0 * minf(1.0, k * 3.0)) * size
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, col, 2.5 * size)
			for i in 6:
				var v := Vector2.from_angle(PI + i * PI / 5.0)
				draw_line(v * r * 0.4, v * r * 1.25, core, 1.6 * size)
		"dragon":                                 # rồng lửa xoáy quanh
			for i in 14:
				var ang := k * TAU * 1.4 + i * 0.32
				var rr := (10.0 + i * 1.6) * size
				var p := Vector2(cos(ang) * rr, sin(ang) * rr * 0.6 - 20.0 * size)
				draw_circle(p, (3.6 - i * 0.18) * size, Color(color.lerp(Color(1, 0.85, 0.3), i / 14.0), a))
		"pointer":                                # mũi nón đỏ chĩa về trước
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
			var reach := (20.0 + 50.0 * minf(1.0, k * 2.0)) * size
			draw_colored_polygon(PackedVector2Array([Vector2(10, 0) * size, Vector2(reach, -10.0 * size), Vector2(reach, 10.0 * size)]),
				Color(color, 0.45 * a))
			draw_polyline(PackedVector2Array([Vector2(reach, -10.0 * size), Vector2(10, 0) * size, Vector2(reach, 10.0 * size)]), col, 1.5 * size)
			draw_line(Vector2(reach, -10.0 * size), Vector2(reach, 10.0 * size), core, 1.5 * size)
		"phi":                                    # ký hiệu Φ đỏ
			var r := 10.0 * size * (1.0 + 0.3 * k)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, col, 2.4 * size)
			draw_line(Vector2(0, -r * 1.5), Vector2(0, r * 1.5), col, 2.4 * size)
			draw_line(Vector2(0, -r * 1.5), Vector2(0, r * 1.5), core, 0.8 * size)
		"cards":                                  # hàng thẻ bài hologram hiện dần về phía trước
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
			var n := int(minf(6.0, k * 14.0)) + 1
			for i in n:
				var c0 := Vector2((14.0 + i * 13.0) * size, -12.0 * size)
				draw_rect(Rect2(c0, Vector2(8.0, 14.0) * size), Color(color, 0.35 * a))
				draw_rect(Rect2(c0, Vector2(8.0, 14.0) * size), col, false, 1.2 * size)
				draw_line(c0 + Vector2(2, 3) * size, c0 + Vector2(6, 3) * size, core, 1.0 * size)
		"taiko":                                  # huy hiệu trống Ongeki + sóng âm
			var r := 12.0 * size
			draw_circle(Vector2.ZERO, r, Color(color, 0.35 * a))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, col, 2.2 * size)
			for i in 3:
				var v := Vector2.from_angle(i * TAU / 3.0 + k * 4.0)
				draw_circle(v * r * 0.45, 2.6 * size, core)
			for i in 2:
				draw_arc(Vector2.ZERO, r + (6.0 + 22.0 * k + i * 7.0) * size, 0.0, TAU, 32, Color(color, a * 0.6), 1.5 * size)
		"moon":                                   # trăng lưỡi liềm vàng sau lưng (đêm của Kiva)
			var c := Vector2(-dir * 10.0, -40.0) * size
			draw_circle(c, 16.0 * size, Color(0.05, 0.03, 0.12, 0.6 * a))
			draw_circle(c, 12.0 * size, Color(1.0, 0.9, 0.4, a))
			draw_circle(c + Vector2(4.0 * dir, -3.0) * size, 11.0 * size, Color(0.05, 0.03, 0.12, a))
		"rings3":                                 # ba vòng Medal đỏ / vàng / lục xếp hàng phía trước
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
			var cols := [Color(1, 0.3, 0.25, a), Color(1, 0.85, 0.25, a), Color(0.35, 0.9, 0.4, a)]
			for i in 3:
				if k * 3.5 > i:
					draw_set_transform(Vector2((22.0 + i * 18.0) * size * dir, -18.0 * size), 0.0, Vector2(0.35 * dir, 1.0))
					draw_arc(Vector2.ZERO, 14.0 * size, 0.0, TAU, 28, cols[i], 2.6 * size)
		"rocket":                                 # lửa tên lửa phụt ra sau lưng + khói
			for i in 8:
				var p := Vector2(-dir * (6.0 + i * 4.0 + 20.0 * k), rng.randf_range(-4.0, 4.0)) * size
				draw_circle(p, (4.5 - i * 0.4) * size, Color(Color(1, 0.6, 0.15).lerp(Color(0.85, 0.85, 0.9), i / 8.0), a))
		"circle":                                 # vòng phép đỏ (đứng) có ký tự xoay
			draw_set_transform(Vector2(dir * 12.0 * size, -24.0 * size), 0.0, Vector2(0.4, 1.0))
			var r := 20.0 * size
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, col, 2.4 * size)
			draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 32, col, 1.4 * size)
			for i in 8:
				var v := Vector2.from_angle(i * TAU / 8.0 + k * 3.0)
				draw_circle(v * r * 0.85, 1.4 * size, core)
		"crack":                                  # khe nứt khóa kéo Helheim mở trên đầu, rừng xanh lấp ló bên trong
			var c := Vector2(0, -34.0) * size
			var w := 16.0 * size * minf(1.0, k * 2.5)
			var h := 6.0 * size * minf(1.0, k * 2.5)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-w, 0), c + Vector2(0, -h), c + Vector2(w, 0), c + Vector2(0, h)]),
				Color(0.15, 0.45, 0.2, 0.85 * a))
			for i in 9:
				var x := -w + i * w / 4.0
				var y := (h if i % 2 == 0 else -h) * 0.9
				draw_line(c + Vector2(x, 0), c + Vector2(x, y), Color(0.85, 0.85, 0.9, a), 1.2 * size)
			draw_line(c + Vector2(-w, 0), c + Vector2(w, 0), Color(1, 1, 1, a), 1.0 * size)
		"fruit":                                  # lát trái cây khổng lồ chụp xuống quái rồi tách thành các múi
			var r := 13.0 * size
			var drop := minf(1.0, k * 3.0)
			var c := Vector2(0, -16.0 * size - 30.0 * size * (1.0 - drop))
			var spread := maxf(0.0, k - 0.45) * 30.0 * size
			for i in 8:
				var a0 := i * TAU / 8.0
				var mid := Vector2.from_angle(a0 + TAU / 16.0)
				var pts := PackedVector2Array([c + mid * spread])
				for j in 5:
					pts.append(c + mid * spread + Vector2.from_angle(a0 + j * TAU / 32.0) * r)
				draw_colored_polygon(pts, Color(color, 0.85 * a))
				draw_polyline(pts, Color(1, 0.97, 0.85, a), 1.0 * size)
			if spread == 0.0:
				draw_arc(c, r, 0.0, TAU, 32, Color(color.darkened(0.3), a), 2.0 * size)
			draw_circle(c, 2.0 * size, core)
		"tire":                                   # lốp xe lăn một vòng quanh Rider, nan vành quay
			var c := Vector2.from_angle(-PI / 2.0 + k * TAU * dir) * Vector2(20.0, 26.0) * size + Vector2(0, -6.0 * size)
			var r := 7.0 * size
			draw_circle(c, r, Color(0.08, 0.08, 0.1, a))
			draw_arc(c, r * 0.6, 0.0, TAU, 20, Color(0.8, 0.82, 0.88, a), 1.6 * size)
			for i in 4:
				var v := Vector2.from_angle(i * TAU / 4.0 + k * 12.0 * dir)
				draw_line(c, c + v * r * 0.55, Color(0.8, 0.82, 0.88, a), 1.0 * size)
			draw_arc(c, r, 0.0, TAU, 24, col, 1.2 * size)
		"eye":                                    # con mắt Ghost sau lưng: mí mắt hạnh nhân, tròng sáng, gai lửa quanh viền
			var c := Vector2(-dir * 4.0, -30.0) * size
			var w := 18.0 * size * minf(1.0, 0.4 + k * 2.0)
			var h := 9.0 * size * minf(1.0, k * 3.0)
			var lid := PackedVector2Array()
			for i in 17:
				var u := -1.0 + i / 8.0
				lid.append(c + Vector2(u * w, -h * (1.0 - u * u)))
			for i in range(15, 0, -1):
				var u := -1.0 + i / 8.0
				lid.append(c + Vector2(u * w, h * (1.0 - u * u)))
			if h > 0.5:      # mắt còn nhắm hẳn (khung đầu): mí dẹt thành đường thẳng, không tô được
				draw_colored_polygon(lid, Color(0.05, 0.05, 0.08, 0.6 * a))
			draw_polyline(lid, col, 2.0 * size)
			draw_circle(c, h * 0.7, col)
			draw_circle(c, h * 0.3, core)
			for i in 6:
				var u := -0.8 + i * 0.32
				var p := c + Vector2(u * w, -h * (1.0 - u * u))
				draw_line(p, p + Vector2(u * 3.0, -5.0) * size, col, 1.4 * size)
		"hit_text":                               # chữ HIT! bật lên rồi bay nhẹ lên trên
			var font := ThemeDB.fallback_font
			var fs := int(11.0 * size * (1.0 + 0.4 * maxf(0.0, 0.25 - k) * 4.0))
			var p := Vector2(-fs * 1.1, -26.0 * size - 10.0 * size * k)
			draw_string_outline(font, p, "HIT!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(3.0 * size), Color(0, 0, 0, a))
			draw_string(font, p, "HIT!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.92, 0.2, a))
		"graph":                                  # trục x-y trắng, đường cong đi xuống phía trước vẽ dần (Vortex Finish)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
			var o := Vector2(-6.0, 2.0) * size
			var grow := minf(1.0, k * 2.5)
			draw_line(o, o + Vector2(90.0 * grow, 0) * size, Color(1, 1, 1, a), 1.4 * size)
			draw_line(o, o + Vector2(0, -60.0 * grow) * size, Color(1, 1, 1, a), 1.4 * size)
			var pts := PackedVector2Array()
			for i in int(24 * grow) + 1:
				var u := i / 24.0
				pts.append(o + Vector2(10.0 + 80.0 * u, -55.0 * (1.0 - u * u)) * size)
			if pts.size() > 1:
				draw_polyline(pts, col, 2.4 * size)
			for i in 4:
				var x := o.x + (20.0 + i * 20.0) * size * grow
				draw_line(Vector2(x, o.y - 2.0 * size), Vector2(x, o.y + 2.0 * size), Color(1, 1, 1, a), 1.0 * size)
		"hexnet":                                 # lưới lục giác chụp xuống quanh quái
			var c := Vector2(0, -24.0) * size
			var grow := minf(1.0, k * 3.0)
			for i in 7:
				var hc := c + (Vector2.ZERO if i == 0 else Vector2.from_angle(i * TAU / 6.0) * 11.0 * size) * grow
				var pts := PackedVector2Array()
				for j in 7:
					pts.append(hc + Vector2.from_angle(j * TAU / 6.0 + PI / 6.0) * 6.0 * size * grow)
				draw_polyline(pts, col, 1.4 * size)
			draw_arc(c, 22.0 * size * grow, 0.0, TAU, 30, Color(color, 0.4 * a), 1.0 * size)
		"chains":                                 # vòng xích phép quấn quanh người quái
			var c := Vector2(0, -24.0) * size
			for ring in 2:
				var y := (ring * 2 - 1) * 8.0 * size
				for i in 10:
					var ang := i * TAU / 10.0 + k * 5.0 * (1 if ring == 0 else -1)
					var p := c + Vector2(cos(ang) * 16.0, y / size + sin(ang) * 5.0) * size
					draw_set_transform(p, ang, Vector2.ONE)
					draw_arc(Vector2.ZERO, 3.0 * size, 0.0, TAU, 10, col, 1.4 * size)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"pine":                                   # quả thông khổng lồ rơi chụp xuống đầu
			var drop := minf(1.0, k * 3.0)
			var c := Vector2(0, -44.0 * size - 30.0 * size * (1.0 - drop))
			for row in 5:
				for i in row + 2:
					var x := (i - (row + 1) / 2.0) * 5.0 * size
					var p := c + Vector2(x, row * 4.5 * size)
					draw_colored_polygon(PackedVector2Array([p + Vector2(-2.5, 0) * size, p + Vector2(0, -3) * size,
						p + Vector2(2.5, 0) * size, p + Vector2(0, 3) * size]), Color(color.darkened(0.15 * (row % 2)), a))
			draw_line(c + Vector2(0, -6) * size, c + Vector2(0, -12) * size, Color(0.4, 0.8, 0.3, a), 2.0 * size)
		"bulb":                                   # bóng đèn chớp sáng tỏa tia
			var c := Vector2(0, -30.0) * size
			for i in 10:
				var v := Vector2.from_angle(i * TAU / 10.0)
				draw_line(c + v * 12.0 * size, c + v * (18.0 + 14.0 * k) * size, Color(1, 0.95, 0.5, a), 1.6 * size)
			draw_circle(c, 9.0 * size, Color(1, 0.95, 0.6, a))
			draw_circle(c, 5.0 * size, core)
			draw_rect(Rect2(c + Vector2(-4, 8) * size, Vector2(8, 6) * size), Color(0.7, 0.7, 0.75, a))
		"diamond":                                # tường kim cương dựng trước mặt
			draw_set_transform(Vector2(dir * 18.0 * size, -26.0 * size), 0.0, Vector2(dir, 1.0))
			var grow := minf(1.0, k * 4.0)
			for i in 3:
				var o := Vector2(0, (i - 1) * 14.0) * size * grow
				var pts := PackedVector2Array([o + Vector2(0, -8) * size, o + Vector2(6, 0) * size, o + Vector2(0, 8) * size,
					o + Vector2(-6, 0) * size])
				draw_colored_polygon(pts, Color(color.lightened(0.4), 0.55 * a))
				draw_polyline(pts + PackedVector2Array([pts[0]]), core, 1.2 * size)
			var tw := Vector2(rng.randf_range(-6, 6), rng.randf_range(-20, 20)) * size
			draw_line(tw + Vector2(-3, 0) * size, tw + Vector2(3, 0) * size, core, 1.0 * size)
			draw_line(tw + Vector2(0, -3) * size, tw + Vector2(0, 3) * size, core, 1.0 * size)
		"wheel":                                  # bánh xe lăn về trước, nan quay
			var c := Vector2(dir * (8.0 + 50.0 * k), -10.0) * size
			var r := 10.0 * size
			draw_arc(c, r, 0.0, TAU, 24, Color(0.15, 0.15, 0.2, a), 3.0 * size)
			draw_arc(c, r, 0.0, TAU, 24, col, 1.2 * size)
			for i in 6:
				var v := Vector2.from_angle(i * TAU / 6.0 + k * 18.0 * dir)
				draw_line(c, c + v * r, Color(color.lightened(0.3), a), 1.0 * size)
		"wings":                                  # đôi cánh xòe sau lưng
			var c := Vector2(-dir * 4.0, -36.0) * size
			var open := minf(1.0, k * 3.0)
			for sgn in [-1.0, 1.0]:
				for f in 4:
					var ang := deg_to_rad(-90.0 + sgn * (25.0 + f * 18.0) * open)
					var tip := c + Vector2.from_angle(ang) * (22.0 - f * 3.0) * size
					draw_line(c, tip, Color(color.lerp(Color(1, 0.9, 0.5), f / 4.0), a), (3.0 - f * 0.5) * size)
		"water":                                  # cột nước dâng lên rồi tỏa giọt
			var h := 40.0 * size * minf(1.0, k * 2.5)
			draw_rect(Rect2(Vector2(-6.0 * size, -h), Vector2(12.0 * size, h)), Color(0.3, 0.6, 1.0, 0.55 * a))
			draw_rect(Rect2(Vector2(-2.0 * size, -h), Vector2(4.0 * size, h)), Color(0.8, 0.95, 1.0, 0.7 * a))
			for i in 8:
				var v := Vector2.from_angle(PI + i * PI / 7.0)
				draw_circle(Vector2(0, -h) + v * 14.0 * size * k, 2.0 * size, Color(0.5, 0.8, 1.0, a))
		"cage":                                   # lồng cầu lưới bao quanh quái
			var c := Vector2(0, -24.0) * size
			var r := 20.0 * size * minf(1.0, k * 3.0)
			draw_arc(c, r, 0.0, TAU, 28, col, 1.6 * size)
			for i in 4:
				draw_set_transform(c, 0.0, Vector2(cos(i * PI / 4.0 + k * 2.0), 1.0))
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(color, 0.6 * a), 1.0 * size)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), Color(color, 0.6 * a), 1.0 * size)
		"kick_text", "ken_text":                  # chữ KICK / KEN của Zi-O bật lên
			var font := ThemeDB.fallback_font
			var word := "KICK" if kind == "kick_text" else "KEN"
			var fs := int(12.0 * size * (1.0 + maxf(0.0, 0.2 - k) * 2.0))
			var p := Vector2(-fs * 1.3, -30.0 * size - 8.0 * size * k)
			draw_string_outline(font, p, word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(3.0 * size), Color(0, 0, 0, a))
			draw_string(font, p, word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color.lightened(0.3), a))
		"drill":                                  # mũi khoan xoáy lao về trước
			draw_set_transform(Vector2(dir * (6.0 + 24.0 * k) * size, -20.0 * size), 0.0, Vector2(dir, 1.0))
			var pts := PackedVector2Array([Vector2(0, -7) * size, Vector2(22, 0) * size, Vector2(0, 7) * size])
			draw_colored_polygon(pts, Color(0.75, 0.78, 0.85, a))
			for i in 4:
				var x := (i * 5.0 + fmod(k * 40.0, 5.0)) * size
				var hh := 7.0 * size * (1.0 - x / (22.0 * size))
				draw_line(Vector2(x, -hh), Vector2(x + 3.0 * size, hh), Color(color, a), 1.4 * size)
		"claw":                                   # ba vệt vuốt chéo
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
			var reach := 26.0 * size * minf(1.0, k * 4.0)
			for i in 3:
				var o := Vector2(-6.0 + i * 6.0, -32.0 + i * 2.0) * size
				draw_line(o, o + Vector2(0.6, 1.0).normalized() * reach, col, 2.6 * size * a + 0.4)
				draw_line(o, o + Vector2(0.6, 1.0).normalized() * reach, core, 0.9 * size)
		"ice":                                    # tinh thể băng sáu nhánh tỏa ra
			var c := Vector2(0, -24.0) * size
			var r := 18.0 * size * minf(1.0, k * 3.0)
			for i in 6:
				var v := Vector2.from_angle(i * TAU / 6.0)
				draw_line(c, c + v * r, Color(0.7, 0.92, 1.0, a), 2.2 * size)
				draw_line(c + v * r * 0.55, c + v * r * 0.55 + v.rotated(0.6) * 5.0 * size, Color(0.85, 0.97, 1.0, a), 1.2 * size)
				draw_line(c + v * r * 0.55, c + v * r * 0.55 + v.rotated(-0.6) * 5.0 * size, Color(0.85, 0.97, 1.0, a), 1.2 * size)
			draw_circle(c, 3.0 * size, core)
		"gravity":                                # vòng xoáy hút về tâm
			var c := Vector2(0, -20.0) * size
			for i in 4:
				var r := (30.0 - 26.0 * fmod(k + i * 0.25, 1.0)) * size
				draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
				draw_arc(Vector2.ZERO, r, k * 6.0 + i, k * 6.0 + i + 4.0, 16, Color(color, a * (r / (30.0 * size))), 1.6 * size)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(c, 3.0 * size, Color(0.1, 0.05, 0.2, a))
		"shield":                                 # khiên lục giác sáng trước mặt
			var c := Vector2(dir * 16.0, -26.0) * size
			draw_set_transform(c, 0.0, Vector2(0.45, 1.0))
			var pts := PackedVector2Array()
			for j in 6:
				pts.append(Vector2.from_angle(j * TAU / 6.0) * 20.0 * size)
			draw_colored_polygon(pts, Color(color, 0.35 * a))
			draw_polyline(pts + PackedVector2Array([pts[0]]), core, 2.0 * size)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"bat":                                    # đàn dơi bay vòng quanh rồi tản ra
			for i in 5:
				var ang := k * TAU * 1.5 + i * TAU / 5.0
				var p := Vector2(cos(ang) * (12.0 + 20.0 * k), -26.0 + sin(ang) * 8.0) * size
				var flap := (2.0 + sin(k * 40.0 + i) * 3.0) * size
				for sgn in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([p, p + Vector2(sgn * 8.0 * size, -flap),
						p + Vector2(sgn * 5.0 * size, 2.0 * size)]), Color(color.lightened(0.15), a))
				draw_circle(p, 1.8 * size, Color(0.15, 0.1, 0.2, a))
				draw_circle(p + Vector2(0, -0.5) * size, 0.7 * size, Color(1, 0.9, 0.3, a))
		"clock":                                  # mặt đồng hồ kim quay nhanh
			var c := Vector2(0, -36.0) * size
			draw_circle(c, 11.0 * size, Color(0.05, 0.05, 0.1, 0.5 * a))
			draw_arc(c, 11.0 * size, 0.0, TAU, 28, col, 1.8 * size)
			for i in 12:
				var v := Vector2.from_angle(i * TAU / 12.0)
				draw_line(c + v * 8.5 * size, c + v * 10.5 * size, core, 1.0 * size)
			draw_line(c, c + Vector2.from_angle(k * TAU * 6.0) * 9.0 * size, core, 1.4 * size)
			draw_line(c, c + Vector2.from_angle(k * TAU) * 6.0 * size, col, 1.8 * size)
		"stamp":                                  # dấu tem tròn in xuống đất, có răng cưa viền
			draw_set_transform(Vector2(0, 2.0 * size), 0.0, Vector2(1.0, 0.4))
			var r := 18.0 * size * (1.2 - 0.2 * minf(1.0, k * 4.0))
			for i in 16:
				draw_circle(Vector2.from_angle(i * TAU / 16.0) * r, 2.2 * size, col)
			draw_circle(Vector2.ZERO, r * 0.85, Color(color, 0.45 * a))
			draw_arc(Vector2.ZERO, r * 0.55, 0.0, TAU, 20, core, 1.4 * size)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"feather":
			for i in 3:
				var p := Vector2(rng.randf_range(-8.0, 8.0) + sin(k * 6.0 + i) * 4.0, 14.0 * k + i * 3.0) * size
				draw_line(p, p + Vector2(3.0, -5.0) * size, col, 1.6 * size)
				draw_line(p + Vector2(1.0, -2.0) * size, p + Vector2(3.0, -1.0) * size, Color(1, 1, 0.8, a), 1.0 * size)
