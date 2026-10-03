extends RiderForm
## Kamen Rider W — ghép 2 nửa, tối đa 3 × 3 = 9 tổ hợp. Form gốc: CycloneJoker.
##   Special        : đổi nửa Soul (trái)  Cyclone → Heat → Luna → Xtreme
##   Giữ ↑ + Special: đổi nửa Body (phải) Joker → Metal → Trigger
## Memory mở khi nhặt ở màn: 3-2 Heat & Metal · 3-3 Luna & Trigger · 3-4 Xtreme.
## Mọi tổ hợp khác CycloneJoker (và Xtreme) là form đặc biệt: tốn nộ theo thời gian.
## Soul quyết định hiệu ứng: Cyclone nhanh + đẩy xa, Heat sát thương ×1.2 và gây cháy, Luna tầm đánh ×1.5.
## Body quyết định vũ khí: Joker tay chân, Metal gậy Metal Shaft (nút Chém: 2 đòn gậy nặng + 1 đòn kết, &"heavy"),
## Trigger súng Trigger Magnum (nút Bắn). Nút Đánh luôn là tay không như Joker: 3 đấm + 1 đá.
## Final Attack theo Body: Joker Extreme, Metal Branding, Trigger Full Burst.
## Xtreme = CycloneJokerXtreme: máu 190, ATK ×1.2.
## W nhảy cao hơn mọi Rider khác (×1.2), Cyclone chạy nhanh. Lv4 mở "Best Match" (CycloneJoker, HeatMetal, LunaTrigger): +15% sát thương.

const BEST_MATCH_LEVEL := 4

const SOULS := ["Cyclone", "Heat", "Luna"]
const BODIES := ["Joker", "Metal", "Trigger"]
const SOUL_TAGS := [&"wind", &"fire", &"luna"]
## Memory nhặt được mở nửa thứ i của cả Soul lẫn Body.
const HALF_UNLOCKS := [&"", &"heat_metal", &"luna_trigger"]

var soul := 0
var body := 0
var xtreme := false


func _init() -> void:
	rider_id = &"double"
	display_name = "Kamen Rider W"
	tagline = "Nhảy cao, ghép 2 nửa linh hoạt"
	special_cooldown = 0.6
	_apply()


func on_enter(p: Player) -> void:
	super(p)
	_apply()


func _on_level_changed() -> void:
	_apply()


func base_form() -> StringName:
	return &"cyclone_joker"


## Id form: &"xtreme" hoặc "<soul>_<body>" viết thường, ví dụ &"heat_trigger".
func current_form_id() -> StringName:
	if xtreme:
		return &"xtreme"
	return StringName("%s_%s" % [SOULS[soul].to_lower(), BODIES[body].to_lower()])


func special_available() -> bool:
	return _half_open(1) or _half_open(2) or has_form(&"xtreme")


func _half_open(i: int) -> bool:
	return i == 0 or GameState.has_form(rider_id, HALF_UNLOCKS[i])


func _next_form() -> StringName:
	if Input.is_action_pressed("move_up"):
		if xtreme:
			return &""
		var b := body
		for _i in BODIES.size():
			b = (b + 1) % BODIES.size()
			if _half_open(b):
				return _form_id(soul, b)
		return &""
	# Nửa trái: các Soul đã mở (trừ Cyclone = form gốc) rồi tới Xtreme, lần lượt sau form dùng lần trước.
	var slots: Array = []
	for i in SOULS.size():
		if _half_open(i) and _form_id(i, body) != base_form():
			slots.append(_form_id(i, body))
	if has_form(&"xtreme"):
		slots.append(&"xtreme")
	return _after_last(slots)


func _form_id(s: int, b: int) -> StringName:
	return StringName("%s_%s" % [SOULS[s].to_lower(), BODIES[b].to_lower()])


## Id tổ hợp → Vector2i(soul, body); không hợp lệ thì (-1, -1).
## Id của Memory nhặt được trùng với Best Match: &"heat_metal", &"luna_trigger".
func _parse(form_id: StringName) -> Vector2i:
	var parts := String(form_id).split("_")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(SOULS.map(func(x): return x.to_lower()).find(parts[0]),
		BODIES.map(func(x): return x.to_lower()).find(parts[1]))


func has_form(form_id: StringName) -> bool:
	if form_id == &"xtreme":
		return GameState.has_form(rider_id, form_id)
	var sb := _parse(form_id)
	return sb.x >= 0 and sb.y >= 0 and _half_open(sb.x) and _half_open(sb.y)


func _set_form(form_id: StringName) -> void:
	var sb := Vector2i.ZERO if form_id == &"xtreme" else _parse(form_id)
	if sb.x < 0 or sb.y < 0:
		return
	xtreme = form_id == &"xtreme"
	soul = sb.x
	body = sb.y
	_apply()


## Chỉ nửa Trigger cầm súng: bắn liên thanh tầm xa; ghép Luna thì xòe 3 viên.
func get_shot() -> Dictionary:
	if body != 2:
		return {}
	var shot := base_shot()
	shot.merge({"damage": 4.0, "cooldown": 0.13, "speed": 380.0, "life": 1.2, "color": Color(0.4, 0.6, 1)}, true)
	if soul == 2:
		shot.merge({"count": 3, "spread": 0.22, "color": Color(1, 0.95, 0.4)}, true)
	elif soul == 1:
		shot.merge({"damage": 5.0, "color": Color(1, 0.5, 0.3)}, true)
	return shot


## Hiệu ứng theo nửa Soul: Cyclone gió lục, Heat lửa đỏ, Luna ánh vàng. Final mở đầu bằng gió xoáy hai màu.
func fx() -> Dictionary:
	var hit: String = ["wind", "fire", "spark"][soul]
	var color: Color = [Color(0.4, 1.0, 0.5), Color(1.0, 0.4, 0.25), Color(1.0, 0.9, 0.35)][soul]
	return {"hit": hit, "final": "ring", "intro": "wind", "color": color}


## Skill 1 theo nửa Soul (trái), Skill 2 theo nửa Body (phải); Xtreme có 2 skill riêng (docs/SKILLS.md).
const SOUL_SKILLS := [
	{"name": "Cyclone Gust", "type": "aim", "tags": [&"force"], "knockback": Vector2(280, -90), "fx": "wind",
		"color": Color(0.3, 1.0, 0.5)},
	{"name": "Heat Flare", "type": "area", "tags": [&"burn"], "fx": "fire", "color": Color(1.0, 0.4, 0.15)},
	{"name": "Luna Stretch", "type": "lock", "range": 120.0, "fx": "chains", "color": Color(1.0, 0.92, 0.25),
		"icon": "aura"},
]
const BODY_SKILLS := [
	{"name": "Joker Rush", "type": "aim", "hits": 3, "fx": "spark", "color": Color(0.65, 0.3, 0.95)},
	{"name": "Metal Shaft Twirl", "type": "area", "tags": [&"crush", &"heavy"], "anim": "slash", "hits": 2,
		"fx": "slash", "color": Color(0.75, 0.8, 0.9)},
	{"name": "Trigger Lock", "type": "lock_multi", "targets": 3, "tags": [&"ranged"], "fx": "ring",
		"color": Color(0.3, 0.55, 1.0)},
]
const XTREME_SKILLS := [
	{"name": "Prism Bicker", "type": "aim", "tags": [&"heavy", &"crush"], "fx": "diamond",
		"color": Color(0.75, 0.95, 1.0), "icon": "slash"},
	{"name": "Xtreme Analysis", "type": "buff", "buff": {"expose": true, "time": 6.0}, "fx": "graph",
		"color": Color(0.4, 1.0, 0.6)},
]


func skill_specs() -> Array:
	if xtreme:
		return XTREME_SKILLS
	return [SOUL_SKILLS[soul], BODY_SKILLS[body]]


func final_type() -> String:
	return "lock_multi" if body == 2 and not xtreme else "aim"


func special_label() -> String:
	return "Đổi Memory"


func punch_count() -> int:
	return 3


func has_blade() -> bool:
	return body == 1 and not xtreme


func slash_count() -> int:
	return 2


func gun_look() -> String:
	return "magnum" if body == 2 else ""


## Metal: gậy Metal Shaft nặng xuyên da quái khổng lồ.
func special_tags() -> Array:
	return [&"crush"] if body == 1 and not xtreme else []



func _apply() -> void:
	max_hp = 190.0 if xtreme else 150.0
	move_speed = 145.0 if soul == 0 else 125.0
	jump_mult = 1.2
	attack_mult = (1.2 if soul == 1 else 1.0) * (1.2 if xtreme else 1.0)
	armor = 45.0 if body == 1 else 20.0
	poise = 12.0 if body == 1 else 6.0
	if player:
		var status := combo_name()
		if xtreme:
			status += " Xtreme"
		if is_best_match():
			status += " ★Best Match"
		player.set_form_status(status)
		player.refresh_animation()


func combo_name() -> String:
	return SOULS[soul] + BODIES[body]


func is_best_match() -> bool:
	return soul == body and not xtreme and level >= BEST_MATCH_LEVEL


func animation_prefix() -> String:
	return "double_" + combo_name().to_lower() + ("xtreme" if xtreme else "")


func form_display_name() -> String:
	return combo_name() + (" Xtreme" if xtreme else "")


func final_attack_name() -> String:
	if xtreme:
		return "Xtreme Golden Extreme"
	match body:
		1:
			return "Metal Branding"
		2:
			return "Trigger Full Burst"
	return "Joker Extreme"


func get_attack(kind: StringName, chain: int) -> Dictionary:
	var data: Dictionary
	if kind == &"swap_in":
		data = make_attack(8.0, 0.0, 0.1, 0.15, Vector2(24, 14), Vector2(16, -12), Vector2(120, -60))
	elif kind == &"slash" or kind == &"slash_finish":
		if not has_blade():
			return {}
		data = _metal(&"light" if kind == &"slash" else &"kick", chain)
		data["anim"] = "slash"
	elif kind == &"final":
		match body:
			1:
				data = _metal(kind, chain)
			2:
				data = _trigger(kind, chain)
			_:
				data = _joker(kind, chain)
	else:
		data = _joker(kind, chain)
	if data.is_empty():
		return data
	return _apply_soul(data)


func _apply_soul(data: Dictionary) -> Dictionary:
	var base_tags: Array = data["tags"]
	var tags := base_tags.duplicate()
	tags.append(SOUL_TAGS[soul])
	if soul == 1:
		tags.append(&"burn")   # Heat: đòn nào cũng bốc lửa
	data["tags"] = tags
	if soul == 0:
		var knockback: Vector2 = data["knockback"]
		data["knockback"] = knockback * 1.5
	elif soul == 2:
		var size: Vector2 = data["size"]
		var offset: Vector2 = data["offset"]
		data["size"] = Vector2(size.x * 1.5, size.y)
		data["offset"] = Vector2(offset.x + size.x * 0.25, offset.y)
	if is_best_match():
		data["damage"] = float(data["damage"]) * 1.15
	return data


func _joker(kind: StringName, _chain: int) -> Dictionary:
	match kind:
		&"light":
			return make_attack(5.0, 0.05, 0.08, 0.11, Vector2(18, 12), Vector2(14, -14), Vector2(50, -20))
		&"kick":
			return make_attack(12.0, 0.12, 0.1, 0.3, Vector2(22, 14), Vector2(16, -14), Vector2(180, -70), [&"heavy"])
		&"final":
			return make_attack(65.0, 0.5, 0.25, 0.4, Vector2(28, 20), Vector2(16, -12), Vector2(260, -160),
				[&"heavy"], {"lunge": Vector2(240, -140), "no_cancel": true})
	return {}


func _metal(kind: StringName, _chain: int) -> Dictionary:
	match kind:
		&"light":
			return make_attack(7.0, 0.1, 0.1, 0.25, Vector2(34, 12), Vector2(22, -14), Vector2(60, -20), [&"heavy"])
		&"kick":
			return make_attack(16.0, 0.2, 0.12, 0.4, Vector2(38, 16), Vector2(24, -14), Vector2(230, -90), [&"heavy"])
		&"final":
			return make_attack(70.0, 0.5, 0.2, 0.45, Vector2(40, 20), Vector2(24, -14), Vector2(300, -150),
				[&"heavy"], {"lunge": Vector2(160, -60), "no_cancel": true})
	return {}


func _trigger(kind: StringName, _chain: int) -> Dictionary:
	match kind:
		&"light":
			return make_attack(5.0, 0.06, 0.05, 0.18, Vector2(150, 6), Vector2(85, -16), Vector2(20, 0), [&"ranged"])
		&"kick":
			# Loạt 3 viên kết thúc chuỗi bắn
			return make_attack(5.0, 0.15, 0.06, 0.35, Vector2(150, 8), Vector2(85, -16), Vector2(40, -10),
				[&"ranged"], {"hits": 3})
		&"final":
			return make_attack(12.0, 0.4, 0.06, 0.4, Vector2(170, 12), Vector2(95, -16), Vector2(60, -10),
				[&"ranged"], {"hits": 6, "no_cancel": true})
	return {}
