extends Area2D
class_name DriverPickup
## Vật phẩm để nhặt: Driver, form đặc biệt, hoặc nạp nộ. Rơi ra từ quái (ngẫu nhiên) hoặc cuối màn.
## Có icon (hình Driver, art/items/drivers/<rider>.png) thì hiện icon nhấp nhô; không có thì hiện viên kim cương
## màu `color`. Kèm nhãn tên, người chơi chạm vào là nhặt.
## lifetime > 0: tự biến mất sau chừng đó giây, nhấp nháy trong BLINK_TIME giây cuối.

signal collected

const BLINK_TIME := 3.0
const ICON_DIR := "res://art/items/drivers/"
## Driver còn phong ấn: đổi ảnh sang độ sáng rồi tô theo dải xanh lạnh (giữ nguyên chi tiết pixel).
## Nhân màu bằng modulate thì vàng hóa màu bùn, nên dùng shader.
const SEALED_SHADER := """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(0.16, 0.22, 0.48), vec3(0.82, 0.94, 1.0), l), c.a);
}
"""

static var _sealed_material: ShaderMaterial

var label_text := "Driver"
var color := Color(1.0, 0.85, 0.3)
var icon: Texture2D = null
var sealed := false
var lifetime := -1.0
var data := {}                 ## thông tin do màn chơi gắn vào (loại vật phẩm, Rider, form)

var _taken := false
var _time := 0.0
var _visual: Node2D
var _base_y := 0.0


## Hình Driver của một Rider (cùng tên với id Rider, "chrono" cho Chrono Driver). Chưa có hình thì trả về null.
static func driver_icon(rider: StringName) -> Texture2D:
	var path := ICON_DIR + String(rider) + ".png"
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## Hình món thắng từ Rider đối thủ, vẽ bằng code (không cần ảnh): "card" thẻ Kamen Ride (khung bạc, mặt màu Rider,
## vạch mắt), "watch" Ride Watch (vỏ tròn bạc, mặt màu Rider, kim). Có cache theo kiểu + màu.
static var _reward_cache := {}


static func reward_icon(look: String, tint: Color) -> Texture2D:
	var key := "%s/%s" % [look, tint.to_html()]
	if _reward_cache.has(key):
		return _reward_cache[key]
	var img: Image
	var dark := Color(0.08, 0.08, 0.1)
	var silver := Color(0.82, 0.84, 0.9)
	if look == "watch":
		img = Image.create_empty(20, 20, false, Image.FORMAT_RGBA8)
		var c := Vector2(9.5, 9.5)
		for y in 20:
			for x in 20:
				var d := Vector2(x, y).distance_to(c)
				if d <= 9.5:
					img.set_pixel(x, y, dark if d > 8.6 else (silver if d > 6.8 else tint))
		for i in 5:      # kim đồng hồ chỉ lên
			img.set_pixel(9 + (1 if i > 3 else 0), 9 - i, Color.WHITE)
		for i in 3:
			img.set_pixel(10 + i, 10, dark)
		for x in [7, 8, 11, 12]:     # núm vặn trên đỉnh
			img.set_pixel(x, 0, silver)
	else:
		img = Image.create_empty(16, 22, false, Image.FORMAT_RGBA8)
		for y in 22:
			for x in 16:
				var edge := x == 0 or y == 0 or x == 15 or y == 21
				var frame := x <= 1 or y <= 1 or x >= 14 or y >= 20
				img.set_pixel(x, y, dark if edge else (silver if frame else tint.darkened(0.15 * (y / 21.0))))
		for x in range(4, 12):       # mặt nạ Rider: vạch mắt sáng
			img.set_pixel(x, 8, Color(1, 1, 1))
			img.set_pixel(x, 9, tint.lightened(0.6))
		for y in range(13, 18):      # dải tên dưới thẻ
			for x in range(3, 13):
				img.set_pixel(x, y, dark if y == 13 or y == 17 else silver.darkened(0.2))
	var tex := ImageTexture.create_from_image(img)
	_reward_cache[key] = tex
	return tex


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # lớp "player"
	monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 28) if icon else Vector2(18, 18)
	shape.shape = rect
	add_child(shape)

	var label_y := -26.0
	if icon:
		var sprite := Sprite2D.new()
		sprite.texture = icon
		if sealed:
			if _sealed_material == null:
				var shader := Shader.new()
				shader.code = SEALED_SHADER
				_sealed_material = ShaderMaterial.new()
				_sealed_material.shader = shader
			sprite.material = _sealed_material
		_visual = sprite
		_base_y = -4.0   # dây đai nằm giữa ảnh: nâng lên để lúc nhấp nhô không lún xuống đất
		label_y = _base_y - icon.get_height() / 2.0 - 12.0
	else:
		var gem := Polygon2D.new()
		gem.polygon = PackedVector2Array([Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0)])
		gem.color = color
		_visual = gem
	add_child(_visual)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, label_y)
	label.size = Vector2(120, 12)
	add_child(label)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_visual.position.y = _base_y + sin(_time * 4.0) * 3.0
	if lifetime > 0.0:
		var left := lifetime - _time
		if left <= 0.0:
			queue_free()
		elif left < BLINK_TIME:
			visible = int(_time * 10.0) % 2 == 0


func _on_body_entered(body: Node2D) -> void:
	if _taken or not (body is Player):
		return
	_taken = true
	collected.emit()
	queue_free()
