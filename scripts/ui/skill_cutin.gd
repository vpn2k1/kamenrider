extends Control
class_name SkillCutIn
## Cut-in kỹ năng trên HUD (kiểu game đối kháng: chớp chân dung trước tuyệt chiêu).
##   final(): dải chéo màu form quét ngang giữa màn hình, trong dải là mặt Rider phóng to (cắt từ khung hình đang hiện
##            của sprite, giữ nguyên điểm ảnh, luôn quay về phía chữ) và tên tuyệt chiêu.
##   skill(): dải nhỏ trượt vào từ mép trái phía trên (đổi form, bật tăng tốc thời gian...): tên kỹ năng + vạch màu.
## Thời gian cộng theo khung hình, bỏ hệ số Engine.time_scale: Final có khựng hình mà cut-in vẫn chạy đều.

const FINAL_TIME := 1.1
const SKILL_TIME := 1.6
const BAND_H := 58.0          ## chiều cao dải cut-in Final (đơn vị khung 480×270, nhân theo cỡ màn hình)
const SLANT := 18.0
const FACE_SCALE := 3.0
const FACE_ROWS := 0.3        ## phần trên cùng của vùng có hình coi là đầu / mặt

var _final_t := -1.0
var _final_name := ""
var _color := Color.WHITE
var _face: Texture2D = null
var _face_region := Rect2()
var _skill_t := -1.0
var _skill_name := ""
var _skill_color := Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Cut-in tuyệt chiêu. sprite: sprite của người chơi, idle_anim: animation đứng yên của form ("kuuga_mighty_idle").
## Chân dung = phần đầu (FACE_ROWS trên cùng của vùng có hình) ở khung đứng yên đầu tiên, giữ nguyên điểm ảnh.
func final(attack_name: String, color: Color, sprite: AnimatedSprite2D, idle_anim: String) -> void:
	_final_name = attack_name.to_upper()
	_color = color
	_face = _portrait(sprite, idle_anim)
	_final_t = 0.0


func _portrait(sprite: AnimatedSprite2D, anim: String) -> Texture2D:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim):
		return null
	var tex := sprite.sprite_frames.get_frame_texture(anim, 0)
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return null
	var used := img.get_used_rect()
	if used.size.y < 4:
		return null
	var head := Rect2i(used.position, Vector2i(used.size.x, int(used.size.y * FACE_ROWS)))
	var crop := img.get_region(head)
	_face_region = Rect2(Vector2.ZERO, Vector2(crop.get_size()))
	return ImageTexture.create_from_image(crop)


## Dải kỹ năng nhỏ (đổi form, Clock Up...).
func skill(skill_name: String, color: Color) -> void:
	_skill_name = skill_name.to_upper()
	_skill_color = color
	_skill_t = 0.0


func _process(delta: float) -> void:
	var dt := delta / maxf(Engine.time_scale, 0.01)
	if _final_t >= 0.0:
		_final_t += dt
	if _skill_t >= 0.0:
		_skill_t += dt
	if _final_t >= 0.0 or _skill_t >= 0.0:
		queue_redraw()


func _ui_scale() -> float:
	return get_viewport_rect().size.y / 270.0


func _draw() -> void:
	var s := _ui_scale()
	var vs := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	if _final_t > FINAL_TIME:
		_final_t = -1.0
	elif _final_t >= 0.0:
		_draw_final(_final_t, s, vs, font)
	if _skill_t > SKILL_TIME:
		_skill_t = -1.0
	elif _skill_t >= 0.0:
		_draw_skill(_skill_t, s, font)


func _draw_final(t: float, s: float, vs: Vector2, font: Font) -> void:
	# 0–0.15s dải quét vào từ trái, 0.15–0.85s đứng yên (mặt trượt chậm), 0.85–1.1s dải thu lại và mờ.
	var enter := clampf(t / 0.15, 0.0, 1.0)
	var leave := clampf((t - 0.85) / 0.25, 0.0, 1.0)
	var h := BAND_H * s * (1.0 - leave)
	var cy := vs.y * 0.42
	var w := vs.x * enter
	var sl := SLANT * s
	if w < sl * 2.0 or h < 2.0:
		return
	var band := PackedVector2Array([Vector2(0, cy - h / 2.0), Vector2(w + sl, cy - h / 2.0),
		Vector2(w - sl, cy + h / 2.0), Vector2(0, cy + h / 2.0)])
	draw_colored_polygon(band, Color(0.04, 0.04, 0.07, 0.88))
	draw_line(band[0], band[1], _color, 3.0 * s)
	draw_line(band[3], band[2], _color, 3.0 * s)
	if h < 4.0:
		return
	# vệt tốc độ chạy ngang trong dải
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		var y := cy + rng.randf_range(-h / 2.4, h / 2.4)
		var x := fmod(rng.randf_range(0.0, vs.x) + t * 900.0 * s, vs.x + 80.0 * s) - 40.0 * s
		draw_line(Vector2(x, y), Vector2(x + rng.randf_range(20.0, 60.0) * s, y), Color(_color, 0.45), 1.5 * s)
	if _face:
		var fs := _face_region.size * FACE_SCALE * s
		var fx := vs.x * 0.2 - fs.x / 2.0 + t * 14.0 * s
		var dst := Rect2(Vector2(fx, cy - fs.y / 2.0), fs)
		# chỉ phần mặt nằm trong dải: cắt theo chiều cao dải
		var clip_top := maxf(dst.position.y, cy - h / 2.0)
		var clip_bot := minf(dst.end.y, cy + h / 2.0)
		if clip_bot > clip_top:
			var k0 := (clip_top - dst.position.y) / fs.y
			var k1 := (clip_bot - dst.position.y) / fs.y
			var src := Rect2(_face_region.position + Vector2(0, _face_region.size.y * k0),
				Vector2(_face_region.size.x, _face_region.size.y * (k1 - k0)))
			var out := Rect2(Vector2(dst.position.x, clip_top), Vector2(fs.x, clip_bot - clip_top))
			draw_texture_rect_region(_face, out, src, Color(1, 1, 1, enter))
	var fsz := int(20.0 * s)
	var text_w := font.get_string_size(_final_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
	var tx := clampf(vs.x * 0.62 - text_w / 2.0, vs.x * 0.36, vs.x - text_w - 8.0 * s) + (1.0 - enter) * 120.0 * s
	var ty := cy + fsz * 0.35
	draw_string_outline(font, Vector2(tx, ty), _final_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, int(4.0 * s), Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(tx, ty), _final_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, _color.lightened(0.45))


func _draw_skill(t: float, s: float, font: Font) -> void:
	var enter := clampf(t / 0.12, 0.0, 1.0)
	var leave := clampf((t - SKILL_TIME + 0.3) / 0.3, 0.0, 1.0)
	var fsz := int(11.0 * s)
	var text_w := font.get_string_size(_skill_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
	var w := text_w + 26.0 * s
	var h := 18.0 * s
	var x := -w + w * enter - w * leave
	if enter <= 0.0:
		return
	var y := 52.0 * s
	var poly := PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w - 8.0 * s, y + h), Vector2(x, y + h)])
	draw_colored_polygon(poly, Color(0.04, 0.04, 0.07, 0.85))
	draw_rect(Rect2(Vector2(x, y), Vector2(5.0 * s, h)), _skill_color)
	draw_line(poly[0], poly[1], Color(_skill_color, 0.8), 1.5 * s)
	draw_string(font, Vector2(x + 11.0 * s, y + h * 0.72), _skill_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(1, 1, 1, 1.0 - leave))
