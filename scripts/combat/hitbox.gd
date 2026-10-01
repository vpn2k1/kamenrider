extends Area2D
class_name Hitbox
## Vùng gây sát thương. Chỉ "có hiệu lực" trong active frames của đòn (giữa activate và deactivate).
## Luôn để monitoring bật, dùng _info làm cờ, để tránh lỗi bật/tắt monitoring trong cùng một frame.
## Cần một node con tên CollisionShape2D.

signal hit_landed(target: Node, info: DamageInfo)

@export var team: StringName = &"player"

var _info: DamageInfo = null
var _already_hit: Array = []
var _activated_frame := -1
var _check_overlaps := false
var _shape: RectangleShape2D

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitorable = false
	area_entered.connect(_try_hit)
	# Mỗi instance có shape riêng, vì kích thước thay đổi theo từng đòn.
	if _collision.shape is RectangleShape2D:
		_shape = (_collision.shape as RectangleShape2D).duplicate() as RectangleShape2D
	else:
		_shape = RectangleShape2D.new()
	_collision.shape = _shape


func activate(info: DamageInfo, size: Vector2, offset: Vector2) -> void:
	_info = info
	_already_hit.clear()
	_shape.size = size * Units.SCALE
	_collision.position = Vector2(offset.x * info.direction, offset.y) * Units.SCALE
	# Shape mới chỉ được cập nhật ở physics step kế tiếp, nên đợi 1 frame rồi mới quét vật đang chồng lấn.
	_activated_frame = Engine.get_physics_frames()
	_check_overlaps = true


func deactivate() -> void:
	_info = null
	_check_overlaps = false


func is_active() -> bool:
	return _info != null


func _physics_process(_delta: float) -> void:
	if _check_overlaps and Engine.get_physics_frames() > _activated_frame:
		_check_overlaps = false
		for area in get_overlapping_areas():
			_try_hit(area)


func _try_hit(area: Area2D) -> void:
	if _info == null or not (area is Hurtbox):
		return
	var hurtbox := area as Hurtbox
	if hurtbox.team == team or _already_hit.has(hurtbox):
		return
	_already_hit.append(hurtbox)
	if hurtbox.receive(_info):
		hit_landed.emit(hurtbox.get_parent(), _info)
