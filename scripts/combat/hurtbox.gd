extends Area2D
class_name Hurtbox
## Vùng nhận sát thương. Chuyển đòn đánh cho node cha qua hàm take_hit(info) -> bool.

@export var team: StringName = &"enemy"


func _ready() -> void:
	monitoring = false
	monitorable = true


## Trả về true nếu đòn thực sự trúng (false khi đang bất tử, né được...).
func receive(info: DamageInfo) -> bool:
	var target = get_parent()
	if target != null and target.has_method("take_hit"):
		return target.take_hit(info)
	return false
