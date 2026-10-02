extends RiderForm
## Kamen Rider Faiz. Form gốc: Faiz (bắn bằng Faiz Phone). Form đặc biệt mở khi nhặt ở màn:
##   2-2 Axel Form   : quái chậm còn 15%, Faiz nhanh x1.6, mọi đòn mang tag &"time".
##                     Nộ tụt 10/giây (đầy thanh = 10 giây), không có súng. Final = Accel Crimson Smash.
##   2-4 Blaster Form: máu 200, giáp 40, ATK x1.3, bắn bằng Faiz Blaster (đạn to, xuyên).
## Special (L) đổi form theo vòng Faiz → Axel → Blaster (các form đã mở).
## Nút Đánh: 3 đấm + 1 đá (mọi form của Faiz). Súng chỉ hiện ở tay lúc bắn: Faiz Phone, Faiz Blaster.
## Crimson Smash: mũi Pointer hình nón ghim quái lại trước cú đá (&"stun").

## Faiz: nhanh, đánh mạnh, có súng ngay từ form gốc, nhưng máu và giáp mỏng.
const FORMS := {
	&"faiz":    {"name": "Faiz",              "hp": 125.0, "armor": 15.0, "speed": 155.0, "jump": 1.05, "atk": 1.2,  "poise": 5.0},
	&"axel":    {"name": "Faiz Axel Form",    "hp": 125.0, "armor": 15.0, "speed": 155.0, "jump": 1.05, "atk": 1.2,  "poise": 5.0},
	&"blaster": {"name": "Faiz Blaster Form", "hp": 200.0, "armor": 40.0, "speed": 135.0, "jump": 0.95, "atk": 1.35, "poise": 12.0},
}
const ORDER := [&"faiz", &"axel", &"blaster"]
const AXEL_ENEMY_SCALE := 0.15
const AXEL_SPEED_MULT := 1.6
const AXEL_RAGE_DRAIN := 10.0

var form: StringName = &"faiz"
var _last_shown := -1


func _init() -> void:
	rider_id = &"faiz"
	display_name = "Kamen Rider Faiz"
	tagline = "Nhanh, đánh mạnh, có súng"
	special_cooldown = 1.0
	_apply_form()


func on_enter(p: Player) -> void:
	super(p)
	_apply_form()
	if is_axel():
		_set_axel_effects(true)


func on_exit() -> void:
	if is_axel():
		_set_axel_effects(false)


func base_form() -> StringName:
	return &"faiz"


func current_form_id() -> StringName:
	return form


func is_axel() -> bool:
	return form == &"axel"


func rage_drain() -> float:
	return AXEL_RAGE_DRAIN if is_axel() else RAGE_DRAIN


func special_available() -> bool:
	return has_form(&"axel") or has_form(&"blaster")


func _next_form() -> StringName:
	return _cycle(ORDER)


func _set_form(form_id: StringName) -> void:
	if not FORMS.has(form_id) or form_id == form:
		return
	# Form chưa gắn vào nhân vật (bản xem trước ở màn chọn form) thì không bật hiệu ứng Axel; on_enter bật lại.
	if is_axel() and player:
		_set_axel_effects(false)
	form = form_id
	if is_axel() and player:
		_set_axel_effects(true)
	_apply_form()


## Faiz Phone: loạt 3 viên hơi xòe. Blaster: đạn to, xuyên. Axel không bắn (lao vào đánh gần).
## Hiệu ứng: tia Photon Blood đỏ; Crimson Smash là chóp nón đỏ chụp lên quái rồi nổ (vòng chấn động).
const FX := {
	&"faiz":    {"intro": "pointer", "signature": "phi", "hit": "spark", "final": "ring", "color": Color(1.0, 0.25, 0.25)},
	&"axel":    {"intro": "pointer", "signature": "phi", "hit": "spark", "final": "ring", "color": Color(1.0, 0.35, 0.3)},
	&"blaster": {"intro": "pointer", "signature": "phi", "hit": "ring", "final": "ring", "color": Color(1.0, 0.2, 0.2)},
}


func fx() -> Dictionary:
	return FX.get(form, {})


func gun_look() -> String:
	match form:
		&"faiz":
			return "faiz_phone"
		&"blaster":
			return "faiz_blaster"
	return ""


func get_shot() -> Dictionary:
	match form:
		&"faiz":
			return {"damage": 3.0, "speed": 300.0, "cooldown": 0.45, "count": 3, "spread": 0.1,
				"radius": 2.5, "color": Color(1, 0.3, 0.3), "pierce": false, "life": 0.8}
		&"blaster":
			return {"damage": 10.0, "speed": 320.0, "cooldown": 0.5, "count": 1, "spread": 0.0,
				"radius": 5.0, "color": Color(1, 0.25, 0.2), "pierce": true, "life": 1.0}
	return {}


func update(delta: float) -> void:
	super(delta)
	if not is_axel() or player == null:
		return
	var secs := ceili(player.rage / AXEL_RAGE_DRAIN)
	if secs != _last_shown:
		_last_shown = secs
		player.set_form_status("AXEL %d" % secs)


func _set_axel_effects(on: bool) -> void:
	_last_shown = -1
	CombatDirector.set_enemy_time_scale(AXEL_ENEMY_SCALE if on else 1.0)
	if on:
		Sound.sfx("clock_up", 0.0)
	if player:
		player.speed_mult = AXEL_SPEED_MULT if on else 1.0


func _apply_form() -> void:
	var s: Dictionary = FORMS[form]
	max_hp = s["hp"]
	armor = s["armor"]
	move_speed = s["speed"]
	jump_mult = s["jump"]
	attack_mult = s["atk"]
	poise = s["poise"]
	if player:
		player.set_form_status("START UP" if is_axel() else str(s["name"]))
		player.refresh_animation()


func animation_prefix() -> String:
	return "faiz" if form == &"faiz" else "faiz_" + String(form)


func form_display_name() -> String:
	return str(FORMS[form]["name"])


func final_attack_name() -> String:
	return "Accel Crimson Smash" if is_axel() else "Crimson Smash"


func get_attack(kind: StringName, _chain: int) -> Dictionary:
	match kind:
		&"light":
			return make_attack(5.0, 0.04, 0.06, 0.1, Vector2(18, 12), Vector2(14, -14), Vector2(40, -10), _tags([]))
		&"kick":
			return make_attack(13.0, 0.1, 0.1, 0.28, Vector2(30, 16), Vector2(20, -14), Vector2(170, -60), _tags([&"heavy"]))
		&"swap_in":
			return make_attack(10.0, 0.0, 0.1, 0.15, Vector2(24, 14), Vector2(16, -12), Vector2(140, -60), _tags([]))
		&"final":
			if is_axel():
				return make_attack(16.0, 0.2, 0.08, 0.5, Vector2(40, 24), Vector2(20, -14), Vector2(60, -20),
					_tags([]), {"hits": 5, "lunge": Vector2(200, 0), "no_cancel": true})
			return make_attack(60.0, 0.5, 0.25, 0.4, Vector2(26, 20), Vector2(16, -12), Vector2(260, -160),
				_tags([&"heavy", &"stun"]), {"lunge": Vector2(260, -140), "no_cancel": true})
	return {}


func special_tags() -> Array:
	return [&"time"] if is_axel() else []


func _tags(base: Array) -> Array:
	var t := base.duplicate()
	if is_axel():
		t.append(&"time")
	return t
