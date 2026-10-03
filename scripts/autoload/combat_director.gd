extends Node
## Điều phối combat toàn cục (autoload "CombatDirector"):
## - hit-stop: khựng hình một chút khi đánh trúng cho cảm giác "đã tay"
## - enemy_time_scale: làm chậm riêng quái (Faiz Axel, Kabuto Clock Up...)
## - attack token: giới hạn số quái được tấn công cùng lúc, tránh bị đánh hội đồng

signal enemy_time_scale_changed(value: float)
signal final_attack_started(rider_id: StringName, attack_name: String)
signal final_attack_landed()                          ## đòn tuyệt chiêu trúng (phông tuyệt chiêu rung, chớp)
signal skill_used(label: String, color: Color)         ## đổi form / kỹ năng: dải cut-in nhỏ trên HUD
signal shake_requested(strength: float)

const MAX_ATTACK_TOKENS := 2
## Màn chơi đặt theo độ khó (StageRun._apply_difficulty): thế giới sau thêm quái đánh cùng lúc, nghỉ giữa hai đòn ngắn hơn.
var max_attack_tokens := MAX_ATTACK_TOKENS
var token_rest := 1.0

var enemy_time_scale := 1.0

var _token_holders: Array = []
var _hit_stop_depth := 0


func set_enemy_time_scale(value: float) -> void:
	enemy_time_scale = value
	enemy_time_scale_changed.emit(value)


func hit_stop(duration: float, time_scale_value := 0.05) -> void:
	_hit_stop_depth += 1
	Engine.time_scale = time_scale_value
	await get_tree().create_timer(duration, true, false, true).timeout
	_hit_stop_depth -= 1
	if _hit_stop_depth == 0:
		Engine.time_scale = 1.0


## Rung màn hình (camera của màn chơi lắng nghe tín hiệu này).
func shake(strength: float) -> void:
	shake_requested.emit(strength)


func has_free_token(enemy: Node) -> bool:
	_cleanup_tokens()
	return _token_holders.has(enemy) or _token_holders.size() < max_attack_tokens


func request_attack_token(enemy: Node) -> bool:
	if not has_free_token(enemy):
		return false
	if not _token_holders.has(enemy):
		_token_holders.append(enemy)
	return true


func release_attack_token(enemy: Node) -> void:
	_token_holders.erase(enemy)


func _cleanup_tokens() -> void:
	_token_holders = _token_holders.filter(func(e): return is_instance_valid(e))
