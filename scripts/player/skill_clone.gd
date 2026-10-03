extends Node2D
class_name SkillClone
## Phân thân của skill [C] (Attack Ride: Illusion, Gatakiriba, Shuriken Clone...): bóng mờ màu form đứng sau / trước
## Rider, sao chép hình đang hiện và đánh theo mỗi đòn (SkillCaster.on_hitbox_fired). Tự biến mất khi hết buff.

const FOLLOW := 10.0
const OFFSETS := [Vector2(-26, 0), Vector2(26, 0), Vector2(-48, 0)]

var player: Player
var slot := 0
var tint := Color.WHITE
var _flash := 0.0
var _fade := -1.0


func _ready() -> void:
	z_index = -1


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	var off: Vector2 = OFFSETS[slot % OFFSETS.size()]
	var target := player.global_position + Vector2(off.x * player.facing, off.y) * Units.SCALE
	global_position = global_position.lerp(target, clampf(FOLLOW * delta, 0.0, 1.0))
	_flash = maxf(_flash - delta, 0.0)
	if _fade >= 0.0:
		_fade -= delta
		if _fade <= 0.0:
			queue_free()
	queue_redraw()


## Vừa đánh theo Rider: chớp sáng.
func swing() -> void:
	_flash = 0.12


func vanish() -> void:
	_fade = 0.25


func _draw() -> void:
	if not is_instance_valid(player):
		return
	var spr := player.sprite
	var a := 0.55 if _fade < 0.0 else 0.55 * _fade / 0.25
	var col := Color(tint.lightened(0.4 if _flash > 0.0 else 0.0), a)
	if spr.visible and spr.sprite_frames:
		var tex := spr.sprite_frames.get_frame_texture(spr.animation, spr.frame)
		if tex:
			draw_set_transform(spr.position, 0.0, Vector2(-1.0 if spr.flip_h else 1.0, 1.0) * spr.scale)
			draw_texture(tex, -tex.get_size() / 2.0, col)
			return
	draw_rect(Rect2(-11, -50, 22, 50), col)
