extends RefCounted
class_name DamageInfo
## Gói dữ liệu của một đòn đánh, truyền từ Hitbox sang Hurtbox.

var damage := 0.0
var knockback := Vector2.ZERO
var direction := 1          ## hướng mặt của người ra đòn (1 = phải, -1 = trái)
var tags: Array = []        ## StringName: &"heavy", &"ranged", &"time", &"final", &"fire"...
var source: Node = null
var bind_time := 0.0        ## > 0 kèm tag &"bind": trói mục tiêu chừng này giây (skill [T])
var blocked := false        ## quái đặc biệt miễn nhiễm đòn này (Enemy.SPECIALS): đạn bật ra, không bay xuyên


func _init(p_damage := 0.0, p_knockback := Vector2.ZERO, p_direction := 1, p_tags: Array = [], p_source: Node = null) -> void:
	damage = p_damage
	knockback = p_knockback
	direction = p_direction
	tags = p_tags
	source = p_source


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)
