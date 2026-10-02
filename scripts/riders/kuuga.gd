extends RiderForm
## Kamen Rider Kuuga. Form gốc: Mighty. Form đặc biệt mở khi nhặt ở màn (tốn nộ theo thời gian):
##   1-2 Dragon  (nhanh, nhảy cao)
##   1-3 Pegasus (cầm Pegasus Bowgun: form duy nhất của Kuuga bắn được, đòn &"ranged")
##   1-4 Titan   (chậm, rất cứng, đòn &"heavy" phá giáp)
## Special (L) đổi form theo vòng Mighty → Dragon → Pegasus → Titan (các form đã mở).
## Nút Đánh luôn là tay không: Mighty / Dragon / Pegasus 3 đấm + 1 đá; Titan 2 đòn nặng + 1 đá.
## Vũ khí chỉ hiện khi dùng: Dragon Rod (nút Chém, 3 nhát quét gió + nhát kết đẩy bay), Titan Sword (nút Chém, 2 nhát
## nặng + nhát kết), Pegasus Bowgun (nút Bắn, hiện ở tay lúc bắn).
## Kỹ năng: Mighty Kick khắc dấu phong ấn bốc cháy (&"burn"); Calamity Titan đâm kiếm phong ấn làm choáng (&"stun").
## Lv5 Rising: mọi Final Attack x1.5.

const FORMS := {
	&"mighty":  {"name": "Mighty",  "hp": 170.0, "armor": 30.0, "speed": 125.0, "jump": 1.0,  "atk": 1.0, "poise": 8.0},
	&"dragon":  {"name": "Dragon",  "hp": 130.0, "armor": 5.0,  "speed": 175.0, "jump": 1.35, "atk": 0.8, "poise": 3.0},
	&"pegasus": {"name": "Pegasus", "hp": 140.0, "armor": 15.0, "speed": 110.0, "jump": 1.0,  "atk": 0.9, "poise": 4.0},
	&"titan":   {"name": "Titan",   "hp": 200.0, "armor": 60.0, "speed": 80.0,  "jump": 0.8,  "atk": 1.4, "poise": 20.0},
}
const ORDER := [&"mighty", &"dragon", &"pegasus", &"titan"]
const RISING_LEVEL := 5
const RISING_FINAL_MULT := 1.5

var form: StringName = &"mighty"


func _init() -> void:
	rider_id = &"kuuga"
	display_name = "Kamen Rider Kuuga"
	tagline = "Bền bỉ: máu, giáp cao · 4 form"
	special_cooldown = 1.0
	_apply_form()


func on_enter(p: Player) -> void:
	super(p)
	_apply_form()


func _on_level_changed() -> void:
	_apply_form()


func base_form() -> StringName:
	return &"mighty"


func current_form_id() -> StringName:
	return form


func special_available() -> bool:
	return ORDER.any(func(f): return f != base_form() and has_form(f))


func _next_form() -> StringName:
	return _cycle(ORDER)


func _set_form(form_id: StringName) -> void:
	if FORMS.has(form_id):
		form = form_id
		_apply_form()


## Chỉ Pegasus có súng (Pegasus Bowgun): chậm, rất xa, xuyên.
## Hiệu ứng theo nguyên tác: Mighty Kick khắc dấu phong ấn bốc cháy trên quái; Dragon Rod quét gió;
## Pegasus Bowgun bắn mũi tên khí; Titan Sword chém nặng dội sóng chấn động.
const FX := {
	&"mighty":  {"signature": "seal", "hit": "spark", "final": "fire", "color": Color(1.0, 0.45, 0.3)},
	&"dragon":  {"signature": "seal", "hit": "wind", "swing": "wind", "color": Color(0.4, 0.6, 1.0)},
	&"pegasus": {"signature": "seal", "hit": "spark", "shot": "arrow", "color": Color(0.45, 0.95, 0.5)},
	&"titan":   {"signature": "seal", "hit": "ring", "swing": "slash", "color": Color(0.75, 0.45, 1.0)},
}


func fx() -> Dictionary:
	return FX.get(form, {})


func get_shot() -> Dictionary:
	if form != &"pegasus":
		return {}
	var shot := base_shot()
	shot.merge({"damage": 8.0, "cooldown": 0.35, "speed": 420.0, "life": 1.4, "pierce": true,
		"radius": 2.5, "color": Color(0.5, 1, 0.55)}, true)
	return shot


func _apply_form() -> void:
	var s: Dictionary = FORMS[form]
	max_hp = s["hp"]
	armor = s["armor"]
	move_speed = s["speed"]
	jump_mult = s["jump"]
	attack_mult = s["atk"]
	poise = s["poise"]
	if player:
		var rising := " · Rising" if level >= RISING_LEVEL else ""
		player.set_form_status("Kuuga %s Form%s" % [s["name"], rising])
		player.refresh_animation()


func punch_count() -> int:
	return 2 if form == &"titan" else 3


func has_blade() -> bool:
	return form == &"dragon" or form == &"titan"


func slash_count() -> int:
	return 2 if form == &"titan" else 3


func gun_look() -> String:
	return "pegasus_bowgun" if form == &"pegasus" else ""


func special_tags() -> Array:
	return [&"crush"] if form == &"titan" else []


func animation_prefix() -> String:
	return "kuuga_" + String(form)


func form_display_name() -> String:
	return "%s Form" % FORMS[form]["name"]


func final_attack_name() -> String:
	var attack_name := "Mighty Kick"
	match form:
		&"dragon":
			attack_name = "Splash Dragon"
		&"pegasus":
			attack_name = "Blast Pegasus"
		&"titan":
			attack_name = "Calamity Titan"
	if level >= RISING_LEVEL:
		attack_name = "Rising " + attack_name
	return attack_name


func get_attack(kind: StringName, chain: int) -> Dictionary:
	if kind == &"swap_in":
		return make_attack(8.0, 0.0, 0.1, 0.15, Vector2(26, 14), Vector2(16, -12), Vector2(120, -60))
	var data: Dictionary
	if kind == &"slash" or kind == &"slash_finish":
		if not has_blade():
			return {}
		var k := &"light" if kind == &"slash" else &"kick"
		data = _dragon(k, chain) if form == &"dragon" else _titan_sword(k)
		data["anim"] = "slash"
	elif kind == &"final":
		match form:
			&"dragon":
				data = _dragon(kind, chain)
			&"pegasus":
				data = _pegasus(kind, chain)
			&"titan":
				data = _titan(kind, chain)
			_:
				data = _mighty(kind, chain)
	else:
		data = _titan(kind, chain) if form == &"titan" else _mighty(kind, chain)   # tay không
	if kind == &"final" and level >= RISING_LEVEL and not data.is_empty():
		data["damage"] = float(data["damage"]) * RISING_FINAL_MULT
	return data


func _mighty(kind: StringName, _chain: int) -> Dictionary:
	match kind:
		&"light":
			return make_attack(5.0, 0.05, 0.08, 0.12, Vector2(18, 12), Vector2(14, -14), Vector2(50, -20))
		&"kick":
			return make_attack(12.0, 0.12, 0.1, 0.3, Vector2(22, 14), Vector2(16, -14), Vector2(180, -70), [&"heavy"])
		&"final":
			return make_attack(60.0, 0.5, 0.25, 0.4, Vector2(28, 20), Vector2(16, -12), Vector2(260, -160),
				[&"heavy", &"burn"], {"lunge": Vector2(260, -120), "no_cancel": true})
	return {}


func _dragon(kind: StringName, _chain: int) -> Dictionary:
	match kind:
		&"light":
			return make_attack(4.0, 0.04, 0.08, 0.1, Vector2(30, 10), Vector2(20, -14), Vector2(40, -20))
		&"kick":
			return make_attack(10.0, 0.1, 0.12, 0.25, Vector2(34, 12), Vector2(22, -14), Vector2(220, -80), [&"force"])
		&"final":
			return make_attack(45.0, 0.45, 0.2, 0.4, Vector2(40, 16), Vector2(24, -14), Vector2(240, -120),
				[], {"lunge": Vector2(200, -200), "no_cancel": true})
	return {}


func _pegasus(kind: StringName, _chain: int) -> Dictionary:
	match kind:
		&"light":
			return make_attack(7.0, 0.15, 0.06, 0.3, Vector2(140, 6), Vector2(80, -16), Vector2(30, 0), [&"ranged"])
		&"kick":
			# Phát nạp mạnh kết thúc chuỗi bắn
			return make_attack(18.0, 0.35, 0.08, 0.35, Vector2(160, 8), Vector2(90, -16), Vector2(90, -20), [&"ranged"])
		&"final":
			return make_attack(50.0, 0.6, 0.1, 0.4, Vector2(170, 10), Vector2(95, -16), Vector2(200, -60),
				[&"ranged"], {"no_cancel": true})
	return {}


func _titan(kind: StringName, _chain: int) -> Dictionary:
	match kind:
		&"light":
			return make_attack(9.0, 0.14, 0.1, 0.3, Vector2(24, 16), Vector2(16, -14), Vector2(60, -20), [&"heavy"])
		&"kick":
			return make_attack(25.0, 0.24, 0.12, 0.45, Vector2(28, 18), Vector2(18, -14), Vector2(240, -100), [&"heavy"])
		&"final":
			return make_attack(70.0, 0.55, 0.2, 0.5, Vector2(34, 24), Vector2(18, -14), Vector2(300, -160),
				[&"heavy", &"stun"], {"no_cancel": true})
	return {}


## Titan Sword (nút Chém): tầm dài hơn tay, nặng, phá giáp.
func _titan_sword(kind: StringName) -> Dictionary:
	if kind == &"light":
		return make_attack(11.0, 0.15, 0.1, 0.3, Vector2(32, 16), Vector2(22, -14), Vector2(70, -20), [&"heavy"])
	return make_attack(28.0, 0.25, 0.12, 0.45, Vector2(36, 18), Vector2(24, -14), Vector2(260, -100), [&"heavy"])
