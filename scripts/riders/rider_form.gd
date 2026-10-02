extends Node
class_name RiderForm
## Lớp gốc của mọi Rider. Mỗi Rider là một script kế thừa lớp này và ghi đè các hook.
## Player chỉ gọi các hàm khai báo ở đây, nên thêm Rider mới không phải sửa Player.
##
## Form: mỗi Rider có một FORM GỐC (Kuuga Mighty, Faiz, W CycloneJoker) và các FORM ĐẶC BIỆT
## mở khi nhặt được ở màn (GameState.unlock_form). Ở form đặc biệt, thanh nộ tụt dần theo
## rage_drain(); nộ về 0 thì Player đưa Rider về form gốc. Special (L) đổi form, xem try_special().
##
## Súng: get_shot() trả {} = form không có súng (không bắn được). Chỉ form cầm súng mới ghi đè. Hình súng (gun_look)
## chỉ hiện ở tay lúc bắn.
## Kiếm / vũ khí cận chiến: has_blade() = có nút Chém. Nút Đánh luôn là đấm / đá tay không; nút Chém ra chuỗi
## &"slash" (slash_count() nhát) rồi &"slash_finish", animation "slash" (hình có vũ khí, tools/import_pixellab.py).
##
## Dữ liệu một đòn đánh (Dictionary, tạo bằng make_attack):
##   damage, startup, active, recovery   — sát thương gốc và thời gian 3 pha (giây)
##   size, offset                        — kích thước và vị trí hitbox, tính khi quay mặt sang phải
##   knockback                           — lực đẩy (x theo hướng bị đánh, y âm = hất lên)
##   tags                                — &"heavy" (phá giáp), &"ranged", &"time"...
##   extra (tùy chọn): hits, lunge, no_cancel, anim

const MAX_LEVEL := 5
const HP_PER_LEVEL := 0.08     ## mỗi cấp +8% máu Rider
const RAGE_DRAIN := 4.0        ## nộ tụt mỗi giây ở form đặc biệt (đầy thanh dùng được 25 giây)

var rider_id: StringName = &""
var display_name := ""
var tagline := ""           ## một dòng mô tả lối chơi, hiện ở màn chọn Rider
var max_hp := 150.0         ## máu Rider gốc (chưa tính cấp), tách riêng với máu dạng người
var move_speed := 130.0
var jump_mult := 1.0
var attack_mult := 1.0
var armor := 0.0            ## giáp: sát thương nhận = sát thương × 100 / (100 + giáp)
var poise := 6.0            ## đòn yếu hơn mức này không làm Rider bị khựng
var special_cooldown := 1.0
var level := 1              ## cấp Rider 1..5, tăng khi qua màn ở thế giới của Rider đó
## Sức mạnh theo thế hệ: Rider của thế giới sau mạnh hơn (GameState.rider_power), nhân vào máu và sát thương,
## để theo kịp quái các thế giới sau. Kuuga (thế giới 1) = 1.0.
var power := 1.0

var player: Player = null
var special_timer := 0.0


func on_enter(p: Player) -> void:
	player = p


func on_exit() -> void:
	pass


func update(delta: float) -> void:
	special_timer = maxf(special_timer - delta, 0.0)


## kind: &"light" (đòn đấm thứ chain trong chuỗi: 0, 1, 2...), &"kick" (cú đá kết thúc chuỗi),
## &"slash" / &"slash_finish" (nút Chém, chỉ khi has_blade()), &"swap_in", &"final".
func get_attack(_kind: StringName, _chain: int) -> Dictionary:
	return {}


## Số đòn &"light" trước cú đá kết thúc. Form thường 3, form nặng / bắn xa 2.
func punch_count() -> int:
	return 3


## Form có kiếm / vũ khí cận chiến (hiện nút Chém).
func has_blade() -> bool:
	return false


## Số nhát &"slash" trước nhát kết &"slash_finish".
func slash_count() -> int:
	return 3


## Tiếng vung đòn (audio/sfx/) lúc ra đòn `kind`. "" = không phát (Final đã có tiếng nạp riêng).
func swing_sfx(kind: StringName) -> String:
	match kind:
		&"light":
			return "punch"
		&"kick", &"swap_in":
			return "kick"
		&"slash":
			return "slash"
		&"slash_finish":
			return "slash_heavy"
	return ""


## Tên hình súng trong art/characters/weapons/ hiện ở tay lúc bắn. "" = không vẽ súng.
func gun_look() -> String:
	return ""


# --- Form ------------------------------------------------------------------

## Id form gốc. Rider không có form đặc biệt thì để &"".
func base_form() -> StringName:
	return &""


## Id form đang dùng.
func current_form_id() -> StringName:
	return base_form()


func is_special_form() -> bool:
	return current_form_id() != base_form()


## Nộ tụt mỗi giây khi đang ở form đặc biệt (Faiz Axel tụt nhanh hơn).
func rage_drain() -> float:
	return RAGE_DRAIN


## Form dùng được trong màn: form gốc, form đã mở, item thì phải đang mang theo (GameState.form_usable).
func has_form(form_id: StringName) -> bool:
	return form_id == base_form() or GameState.form_usable(rider_id, form_id)


## Đổi sang form `form_id` (gọi khi nhặt form, khi hết nộ, khi đổi Rider). Giữ nguyên tỉ lệ máu Rider.
func set_form(form_id: StringName) -> void:
	var old_max := get_max_hp()
	var before := current_form_id()
	_set_form(form_id)
	_notify_max_hp(old_max)
	if player and player.current_form == self and current_form_id() != before:
		player.on_form_changed(self)


func reset_to_base() -> void:
	if is_special_form():
		set_form(base_form())


## Special (L) = đổi sang form kế tiếp trong vòng các form đã mở.
## Vào form đặc biệt phải có đủ nộ (Player.pay_form_switch); quay về form gốc thì miễn phí.
func try_special() -> void:
	if special_timer > 0.0 or player == null:
		return
	var target := _next_form()
	if target == &"" or target == current_form_id():
		return
	if target != base_form() and not player.pay_form_switch():
		return
	set_form(target)
	special_timer = special_cooldown


## Đã mở ít nhất một form đặc biệt chưa (để nút Special hiện ra).
func special_available() -> bool:
	return false


## Chữ hiện dưới nút Special trên màn hình.
func special_label() -> String:
	return "Đổi form"


## Ghi đè: form kế tiếp khi bấm Special. &"" = không đổi được.
func _next_form() -> StringName:
	return &""


## Ghi đè: áp chỉ số / hiệu ứng của form.
func _set_form(_form_id: StringName) -> void:
	pass


## Kiểu đạn khi bấm Bắn (Player.try_shoot). {} = form này không có súng.
func get_shot() -> Dictionary:
	return {}


func has_gun() -> bool:
	return not get_shot().is_empty()


## Tag đặc tính của form, Player cộng vào MỌI đòn và đạn của form: &"crush" form nặng (Titan, Ax, Dogga, Metal...)
## xuyên được da quái khổng lồ; &"time" form tăng tốc thời gian (Axel, Clock Up...) đánh trúng quái siêu tốc.
## Xem Enemy.SPECIALS.
func special_tags() -> Array:
	return []


## Hiệu ứng của form hiện tại, ghi đè các khóa cần đổi so với Player.DEFAULT_FX:
##   "hit"   kiểu Fx khi đòn trúng      "swing" kiểu Fx vung theo đòn ("" = không, thường là "slash" / "wind")
##   "shot"  kiểu đạn (Fx.SHOTS)        "final" kiểu Fx khi Final Attack trúng
##   "color" màu hiệu ứng               "trail" để bóng mờ khi di chuyển (form tốc độ)
##   "glide" giữ Nhảy khi rơi để lượn (Blade Jack Form)
func fx() -> Dictionary:
	return {}


## Mẫu đạn chung, form có súng merge thêm chỉ số riêng.
static func base_shot() -> Dictionary:
	return {"damage": 5.0, "speed": 260.0, "cooldown": 0.3, "count": 1, "spread": 0.0,
		"radius": 3.0, "color": Color(1, 0.9, 0.6), "pierce": false, "life": 0.9}


func modify_incoming_damage(info: DamageInfo) -> float:
	return info.damage * 100.0 / (100.0 + armor)


## Chỉ số form hiện tại ở cấp hiện tại, cho màn chọn Rider (gọi trên bản mới tạo = form gốc).
## Thanh chỉ số không tính sức mạnh thế hệ (màn chọn Rider hiện riêng dòng "Sức mạnh").
func stat_summary() -> Dictionary:
	return {"hp": get_max_hp() / power, "armor": armor, "speed": move_speed, "atk": attack_mult * level_mult() / power,
		"jump": jump_mult}


func get_max_hp() -> float:
	return max_hp * (1.0 + HP_PER_LEVEL * (level - 1)) * power


## Đổi form hoặc lên cấp làm máu tối đa thay đổi → báo Player giữ nguyên tỉ lệ máu hiện có.
func _notify_max_hp(old_max: float) -> void:
	if player and player.current_form == self and not is_equal_approx(old_max, get_max_hp()):
		player.rescale_rider_hp(old_max, get_max_hp())


## Gọi khi tạo form và mỗi lần Rider lên cấp.
func set_level(value: int) -> void:
	var old_max := get_max_hp()
	level = clampi(value, 1, MAX_LEVEL)
	_on_level_changed()
	_notify_max_hp(old_max)


## Ghi đè để mở thưởng theo cấp (Rising, Best Match...). Form thì mở bằng cách nhặt, không theo cấp.
func _on_level_changed() -> void:
	pass


## Mỗi cấp +10% sát thương, nhân sức mạnh thế hệ.
func level_mult() -> float:
	return (1.0 + 0.1 * (level - 1)) * power


## Tiền tố tên animation trong SpriteFrames của Player, ví dụ "kuuga_mighty" → "kuuga_mighty_run".
func animation_prefix() -> String:
	return String(rider_id)


func final_attack_name() -> String:
	return "Rider Kick"


## Vòng đổi form mặc định: đi lần lượt qua các form đã mở theo thứ tự `order`.
func _cycle(order: Array) -> StringName:
	var owned: Array = order.filter(func(f): return has_form(f))
	if owned.size() < 2:
		return &""
	return owned[(owned.find(current_form_id()) + 1) % owned.size()]


static func make_attack(damage: float, startup: float, active: float, recovery: float,
		size := Vector2(18, 12), offset := Vector2(14, -14), knockback := Vector2(50, -20),
		tags: Array = [], extra := {}) -> Dictionary:
	var data := {
		"damage": damage, "startup": startup, "active": active, "recovery": recovery,
		"size": size, "offset": offset, "knockback": knockback, "tags": tags,
	}
	data.merge(extra, true)
	return data

