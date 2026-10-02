extends Node2D
class_name FinisherBackdrop
## Phông tuyệt chiêu: khi tung Final Attack, nền màn chơi tối lại và một ảnh lớn của Rider hiện SAU trận đánh (trước
## nền xa, sau địa hình / quái / người chơi), phóng to nhẹ rồi đứng yên; đòn trúng thì rung và chớp; hết giờ thì mờ đi.
##
## Ảnh: art/backdrops/<rider_id>.png (320×180, tools: PixelLab create_image_pixflux). Rider chưa có ảnh thì vẽ phông
## thay thế bằng code: tia sáng toả từ tâm theo màu form và dấu hiệu tuyệt chiêu của Rider (Fx "intro" / "signature")
## phóng to giữa màn hình.
##
## Dùng: thêm làm con của màn chơi, ngay SAU nền xa trong cây node (thứ tự vẽ), rồi gọi play() / impact().
## Thời gian cộng theo khung hình, bỏ hệ số Engine.time_scale, vì Final có khựng hình (hit_stop).

const DIR := "res://art/backdrops/"
const DIM := 0.62           ## độ tối phủ lên nền màn chơi
const FADE_IN := 0.18
const HOLD := 1.25          ## giây phông đứng yên (Final dài hơn thì vẫn tắt, không che trận đánh quá lâu)
const FADE_OUT := 0.35
const ZOOM_FROM := 1.18     ## ảnh phóng từ 118% về 100% lúc hiện
const IMAGE_ALPHA := 0.9
const SHAKE_TIME := 0.3

var _tex: Texture2D = null
var _color := Color.WHITE
var _emblem := ""
var _t := 0.0
var _impact := -1.0
var _seed := 0


func _ready() -> void:
	z_index = 0
	visible = false


## Bắt đầu phông cho Rider `rider_id`. color: màu hiệu ứng của form; emblem: kiểu Fx dấu hiệu tuyệt chiêu (có thể "").
func play(rider_id: StringName, color: Color, emblem := "") -> void:
	var path := DIR + String(rider_id) + ".png"
	_tex = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_color = color
	_emblem = emblem if emblem in Fx.KINDS else ""
	_t = 0.0
	_impact = -1.0
	_seed = randi()
	visible = true
	if _tex == null and _emblem != "":
		_spawn_emblem()


## Đòn tuyệt chiêu trúng: rung ảnh, chớp viền màu form.
func impact() -> void:
	if visible:
		_impact = _t


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta / maxf(Engine.time_scale, 0.01)
	var cam := get_viewport().get_camera_2d()
	if cam:
		global_position = cam.get_screen_center_position()
	if _t > FADE_IN + HOLD + FADE_OUT:
		visible = false
		return
	queue_redraw()


func _alpha() -> float:
	var t := _t
	if t < FADE_IN:
		return t / FADE_IN
	if t > FADE_IN + HOLD:
		return clampf(1.0 - (t - FADE_IN - HOLD) / FADE_OUT, 0.0, 1.0)
	return 1.0


func _view_size() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	var zoom := cam.zoom if cam else Vector2.ONE
	return get_viewport_rect().size / zoom


func _draw() -> void:
	var a := _alpha()
	var size := _view_size() * 1.1          # phủ dư ra để rung không lộ mép
	var half := size / 2.0
	var t := _t
	var shake := Vector2.ZERO
	if _impact >= 0.0 and _t - _impact < SHAKE_TIME:
		var k := 1.0 - (_t - _impact) / SHAKE_TIME
		shake = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 6.0 * k * Units.SCALE
	draw_rect(Rect2(-half, size), Color(0, 0, 0, DIM * a))
	var zoom := lerpf(ZOOM_FROM, 1.0, clampf(t / (FADE_IN * 2.0), 0.0, 1.0))
	if _tex:
		var img := size * zoom
		draw_texture_rect(_tex, Rect2(-img / 2.0 + shake, img), false, Color(1, 1, 1, IMAGE_ALPHA * a))
	else:
		_draw_rays(half.length(), t, a, shake)
	if _impact >= 0.0:
		var k := clampf(1.0 - (_t - _impact) / 0.25, 0.0, 1.0)
		if k > 0.0:
			draw_rect(Rect2(-half, size), Color(_color, 0.35 * k * a))


## Phông thay thế: tia sáng màu form toả từ tâm, xoay chậm, viền tối.
func _draw_rays(r: float, t: float, a: float, shake: Vector2) -> void:
	var n := 18
	for i in n:
		var ang := i * TAU / n + t * 0.4
		var w := TAU / n * 0.35
		var p0 := shake
		var p1 := shake + Vector2.from_angle(ang - w) * r
		var p2 := shake + Vector2.from_angle(ang + w) * r
		var c := _color if i % 2 == 0 else _color.lightened(0.35)
		draw_colored_polygon(PackedVector2Array([p0, p1, p2]), Color(c, 0.28 * a))
	draw_circle(shake, 30.0 * Units.SCALE, Color(_color.lightened(0.5), 0.35 * a))


## Rider chưa có ảnh: dấu hiệu tuyệt chiêu riêng (phong ấn, vòng Medal...) phóng to giữa phông, sống theo LIFE của Fx.
func _spawn_emblem() -> void:
	var f := Fx.spawn(self, global_position, _emblem, _color, 1, 4.0)
	if f:
		f.z_index = 0
		f.life = maxf(f.life, HOLD)
