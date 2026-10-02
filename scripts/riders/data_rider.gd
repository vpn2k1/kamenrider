extends RiderForm
class_name DataRider
## Rider dựng từ dữ liệu: hằng RIDER trong file thế giới (scripts/data/worlds/). Dùng cho mọi Rider không có
## script riêng (Kuuga, Faiz, W có script riêng). Thêm Rider mới = viết dữ liệu, không cần viết code.
##
## RIDER := {
##   "name": "Kamen Rider Agito", "tagline": "một dòng lối chơi", "color": Color(...) (khối màu tạm),
##   "base": &"ground",                                   form gốc
##   "order": [&"ground", &"storm", &"flame", &"trinity"], vòng đổi form (L), form gốc đứng đầu
##   "forms": {form_id: {
##       "name": "Storm Form",
##       "style": "brawler" | "blade" | "lancer" | "heavy" | "gunner"   (kiểu đòn của form, xem STYLES). Nút Đánh
##                             luôn là tay không: "blade" / "gunner" đánh tay như "brawler"; kiếm sang nút Chém, súng
##                             sang nút Bắn. Final Attack theo đúng "style".
##       "blade": {"look": "wizarsword", "style": "blade"}  tùy chọn: vũ khí cận chiến cho nút Chém. "look" = kiểu vũ khí
##                             tools/import_pixellab.py vẽ vào animation "slash" (vũ khí chỉ hiện khi chém), "style" = bảng
##                             đòn của chuỗi chém (blade / lancer / heavy). Form "style": "blade" không ghi thì có sẵn.
##       "armed": true         vũ khí cầm sẵn trong hình (AI vẽ cứng, như Blay Rouzer của Blade): nút Đánh dùng luôn vũ
##                             khí theo "style" ("gunner" thì chém như "blade"), không có nút Chém
##       "hp", "armor", "speed", "jump", "atk", "poise"                 (như bảng FORMS của Kuuga)
##       "gun": {...}          tùy chọn: form có súng, nút Bắn dùng dữ liệu này (khóa như RiderForm.base_shot);
##                             "look": hình súng art/characters/weapons/<look>.png hiện ở tay lúc bắn
##       "effect": "time"      tùy chọn: tăng tốc thời gian (Faiz Axel, Kabuto Clock Up...): quái chậm còn 15%,
##                             Rider chạy và ra đòn nhanh ×1.6, để bóng mờ, màn hình ngả xanh, đòn mang tag &"time"
##                             (đánh trúng quái nhanh), nộ tụt 10/giây. "time_call": chữ hiện khi bật ("CLOCK UP")
##       "fx": {...}           tùy chọn: hiệu ứng đánh của form (xem RiderForm.fx)
##       "final": "Rider Kick" tên Final Attack của form
##       Kỹ năng riêng theo nguyên tác (tùy chọn):
##       "tags": [&"shock"]    tag thêm vào mọi đòn của form. Tag hiệu ứng (xử lý ở Enemy): &"stun" choáng, &"freeze"
##                             đóng băng, &"burn" cháy, &"shock" điện lan sang quái gần, &"force" đẩy / hút / hất kể cả
##                             khi đòn không làm quái khựng; &"heavy" phá giáp. "gun" cũng nhận "tags" cho đạn.
##       "attacks": {"light" | "kick" | "slash" | "slash_finish" | "final": {khóa của make_attack}}  ghi đè từng đòn của kiểu đòn: "damage",
##                             "size", "offset", "knockback" (x âm = hút về phía Rider), "hits" (số nhịp trúng),
##                             "lunge", "startup", "active", "recovery"; "tags" thì cộng thêm
##       "guard": 0.5          nhận chừng này sát thương từ phía trước khi không đang ra đòn (khiên)
##       "rage_drain": 6.0     nộ tụt mỗi giây ở form này (mặc định RiderForm.RAGE_DRAIN)
##   }},
##   "lv5": {"name": "Shining", "final_mult": 1.5}  Lv5: tên hiện kèm form + Final Attack mạnh hơn
##   "lv5": {"form": &"survive", ...}  Lv5 mở final form này (GameState.set_level), thay cho tên hiện kèm
##   "final_fx": {"intro": "dragon", "signature": "seal"}  tùy chọn: dấu hiệu tuyệt chiêu riêng (Fx.KINDS) hiện quanh
##                             Rider lúc tung Final ("intro") và trên quái lúc Final trúng ("signature"), mọi form
## }
##
## Kiểu đòn (STYLES): số đòn trước cú kết thúc và đặc điểm:
##   brawler  3 đấm + đá (như Kuuga Mighty)       lancer  3 đòn tầm xa hơn, nhẹ hơn (như Dragon)
##   blade    3 chém + chém nặng phá giáp          heavy   2 đòn nặng phá giáp + đòn kết (như Titan)
##   gunner   2 phát bắn + 1 phát nạp (đòn &"ranged" tầm xa, như Pegasus)

const TIME_ENEMY_SCALE := 0.15
const TIME_SPEED_MULT := 1.6
const TIME_RAGE_DRAIN := 10.0

var data: Dictionary = {}
var form: StringName = &""
var _last_shown := -1


func _init(rider_data: Dictionary = {}, id: StringName = &"") -> void:
	data = rider_data
	rider_id = id
	display_name = str(data.get("name", "Kamen Rider"))
	tagline = str(data.get("tagline", ""))
	special_cooldown = 1.0
	form = base_form()
	_apply_form()


func on_enter(p: Player) -> void:
	super(p)
	_apply_form()
	if _is_time():
		_set_time_effects(true)


func on_exit() -> void:
	if _is_time():
		_set_time_effects(false)


func _on_level_changed() -> void:
	_apply_form()


func base_form() -> StringName:
	return data.get("base", &"")


func current_form_id() -> StringName:
	return form


## "agito_storm" → animation "agito_storm_run"... (tools/import_pixellab.py ghi đủ mọi form, form đổi màu từ form gốc).
func animation_prefix() -> String:
	return "%s_%s" % [rider_id, form]


func _stats() -> Dictionary:
	var forms: Dictionary = data.get("forms", {})
	return forms.get(form, {})


## Hiệu ứng của form, cộng dấu hiệu tuyệt chiêu chung của Rider (RIDER "final_fx": {"intro", "signature"}).
func fx() -> Dictionary:
	var f: Dictionary = (_stats().get("fx", {}) as Dictionary).duplicate()
	f.merge(data.get("final_fx", {}), false)
	return f


func _is_time() -> bool:
	return str(_stats().get("effect", "")) == "time"


func rage_drain() -> float:
	return TIME_RAGE_DRAIN if _is_time() else float(_stats().get("rage_drain", RAGE_DRAIN))


func special_available() -> bool:
	var order: Array = data.get("order", [])
	return order.any(func(f): return f != base_form() and has_form(f))


func _next_form() -> StringName:
	return _cycle(data.get("order", []))


func _set_form(form_id: StringName) -> void:
	var forms: Dictionary = data.get("forms", {})
	if not forms.has(form_id) or form_id == form:
		return
	# Form chưa gắn vào nhân vật (bản xem trước ở màn chọn form / item) thì không bật hiệu ứng thời gian;
	# on_enter bật lại khi gắn vào.
	if _is_time() and player:
		_set_time_effects(false)
	form = form_id
	if _is_time() and player:
		_set_time_effects(true)
	_apply_form()


func get_shot() -> Dictionary:
	var gun: Dictionary = _stats().get("gun", {})
	if gun.is_empty():
		return {}
	var shot := base_shot()
	shot.merge(gun, true)
	return shot


func update(delta: float) -> void:
	super(delta)
	if not _is_time() or player == null:
		return
	var secs := ceili(player.rage / TIME_RAGE_DRAIN)
	if secs != _last_shown:
		_last_shown = secs
		player.set_form_status("%s %d" % [str(_stats().get("name", "")).to_upper(), secs])


func _set_time_effects(on: bool) -> void:
	_last_shown = -1
	CombatDirector.set_enemy_time_scale(TIME_ENEMY_SCALE if on else 1.0)
	if player:
		player.speed_mult = TIME_SPEED_MULT if on else 1.0
		if on:
			player.notice.emit(str(_stats().get("time_call", "CLOCK UP")))
			Sound.sfx("clock_up", 0.0)


func _apply_form() -> void:
	var s := _stats()
	max_hp = float(s.get("hp", 150.0))
	armor = float(s.get("armor", 20.0))
	move_speed = float(s.get("speed", 130.0))
	jump_mult = float(s.get("jump", 1.0))
	attack_mult = float(s.get("atk", 1.0))
	poise = float(s.get("poise", 6.0))
	if player:
		var status := str(s.get("name", display_name))
		if _lv5() and str(data["lv5"].get("name", "")) != "":
			status += " · " + str(data["lv5"]["name"])
		player.set_form_status(status)
		player.refresh_animation()


func _lv5() -> bool:
	return level >= MAX_LEVEL and data.has("lv5")


func _style() -> String:
	return str(_stats().get("style", "brawler"))


## Kiểu đòn tay không của nút Đánh: kiếm và súng đã có nút riêng nên đánh tay như brawler.
func _hand_style() -> String:
	var s := _style()
	if _stats().get("armed", false):
		return "blade" if s == "gunner" else s
	return s if s in ["brawler", "lancer", "heavy"] else "brawler"


## Vũ khí cận chiến của nút Chém ({} = không có).
func _blade() -> Dictionary:
	if _stats().get("armed", false):
		return {}
	var b: Dictionary = _stats().get("blade", {})
	if b.is_empty() and _style() == "blade":
		return {"style": "blade"}
	return b


func has_blade() -> bool:
	return not _blade().is_empty()


func slash_count() -> int:
	return 2 if str(_blade().get("style", "blade")) == "heavy" else 3


## Form cầm sẵn vũ khí (Blade): nút Đánh là chém nên tiếng cũng là tiếng chém.
func swing_sfx(kind: StringName) -> String:
	if _stats().get("armed", false) and (kind == &"light" or kind == &"kick"):
		return "slash" if kind == &"light" else "slash_heavy"
	return super(kind)


func gun_look() -> String:
	return str((_stats().get("gun", {}) as Dictionary).get("look", ""))


## Form kiểu "heavy" (hoặc cầm vũ khí nặng ở nút Chém) xuyên da quái khổng lồ; form tăng tốc thời gian trúng quái siêu tốc.
func special_tags() -> Array:
	var t: Array = []
	if _style() == "heavy" or str(_blade().get("style", "")) == "heavy":
		t.append(&"crush")
	if _is_time():
		t.append(&"time")
	return t


func punch_count() -> int:
	return 2 if _hand_style() in ["heavy", "gunner"] else 3


func final_attack_name() -> String:
	var attack_name := str(_stats().get("final", "Rider Kick"))
	if _lv5() and str(data["lv5"].get("name", "")) != "":
		attack_name = "%s %s" % [str(data["lv5"]["name"]), attack_name]
	return attack_name


func get_attack(kind: StringName, _chain: int) -> Dictionary:
	if kind == &"swap_in":
		return make_attack(8.0, 0.0, 0.1, 0.15, Vector2(26, 14), Vector2(16, -12), Vector2(120, -60), _tags([]))
	var d: Dictionary
	match kind:
		&"slash", &"slash_finish":
			if not has_blade():
				return {}
			d = _style_attack(str(_blade().get("style", "blade")), &"light" if kind == &"slash" else &"kick")
			d["anim"] = "slash"
		&"final":
			d = _style_attack(_style(), kind)
		_:
			d = _style_attack(_hand_style(), kind)
	if d.is_empty():
		return d
	_apply_form_attack(d, kind)
	if kind == &"final" and _lv5():
		d["damage"] = float(d["damage"]) * float(data["lv5"].get("final_mult", 1.5))
	if _is_time():
		d["tags"] = _tags(d["tags"])
		if kind == &"final":
			# Tăng tốc thời gian: Final là loạt đòn liên hoàn lướt tới (như Accel Crimson Smash).
			d = make_attack(16.0, 0.2, 0.08, 0.5, Vector2(40, 24), Vector2(20, -14), Vector2(60, -20),
				_tags([]), {"hits": 5, "lunge": Vector2(200, 0), "no_cancel": true})
	return d


## Kỹ năng của form: ghi đè đòn theo "attacks" và cộng "tags" (xem đầu file).
func _apply_form_attack(d: Dictionary, kind: StringName) -> void:
	var over: Dictionary = (_stats().get("attacks", {}) as Dictionary).get(String(kind), {})
	for k in over:
		d[k] = (d["tags"] as Array) + (over[k] as Array) if k == "tags" else over[k]
	for tag in _stats().get("tags", []):
		if not (d["tags"] as Array).has(tag):
			d["tags"] = (d["tags"] as Array) + [tag]


## Khiên ("guard"): đòn đánh / đạn từ phía trước nhẹ đi khi Rider không đang ra đòn.
func modify_incoming_damage(info: DamageInfo) -> float:
	var dmg := super(info)
	var guard := float(_stats().get("guard", 1.0))
	if guard < 1.0 and player and player.state != Player.State.ATTACK and _from_front(info):
		dmg *= guard
	return dmg


func _from_front(info: DamageInfo) -> bool:
	if is_instance_valid(info.source) and info.source is Node2D:
		return signf((info.source as Node2D).global_position.x - player.global_position.x) == float(player.facing)
	return info.direction == -player.facing


func _tags(base: Array) -> Array:
	var t := base.duplicate()
	if _is_time() and not t.has(&"time"):
		t.append(&"time")
	return t


func _style_attack(style: String, kind: StringName) -> Dictionary:
	match style:
		"lancer":
			match kind:
				&"light":
					return make_attack(4.0, 0.04, 0.08, 0.1, Vector2(30, 10), Vector2(20, -14), Vector2(40, -20))
				&"kick":
					return make_attack(10.0, 0.1, 0.12, 0.25, Vector2(34, 12), Vector2(22, -14), Vector2(160, -60))
				&"final":
					return make_attack(45.0, 0.45, 0.2, 0.4, Vector2(40, 16), Vector2(24, -14), Vector2(240, -120),
						[], {"lunge": Vector2(200, -200), "no_cancel": true})
		"blade":
			match kind:
				&"light":
					return make_attack(6.0, 0.07, 0.08, 0.14, Vector2(26, 14), Vector2(18, -14), Vector2(50, -20))
				&"kick":
					return make_attack(14.0, 0.14, 0.1, 0.3, Vector2(32, 18), Vector2(20, -14), Vector2(190, -70), [&"heavy"])
				&"final":
					return make_attack(65.0, 0.5, 0.22, 0.45, Vector2(44, 22), Vector2(24, -14), Vector2(260, -100),
						[&"heavy"], {"lunge": Vector2(240, -60), "no_cancel": true})
		"heavy":
			match kind:
				&"light":
					return make_attack(9.0, 0.14, 0.1, 0.3, Vector2(24, 16), Vector2(16, -14), Vector2(60, -20), [&"heavy"])
				&"kick":
					return make_attack(25.0, 0.24, 0.12, 0.45, Vector2(28, 18), Vector2(18, -14), Vector2(240, -100), [&"heavy"])
				&"final":
					return make_attack(70.0, 0.55, 0.2, 0.5, Vector2(34, 24), Vector2(18, -14), Vector2(300, -160),
						[&"heavy"], {"no_cancel": true})
		"gunner":
			match kind:
				&"light":
					return make_attack(7.0, 0.15, 0.06, 0.3, Vector2(140, 6), Vector2(80, -16), Vector2(30, 0), [&"ranged"])
				&"kick":
					return make_attack(18.0, 0.35, 0.08, 0.35, Vector2(160, 8), Vector2(90, -16), Vector2(90, -20), [&"ranged"])
				&"final":
					return make_attack(50.0, 0.6, 0.1, 0.4, Vector2(170, 10), Vector2(95, -16), Vector2(200, -60),
						[&"ranged"], {"no_cancel": true})
		_:
			match kind:
				&"light":
					return make_attack(5.0, 0.05, 0.08, 0.12, Vector2(18, 12), Vector2(14, -14), Vector2(50, -20))
				&"kick":
					return make_attack(12.0, 0.12, 0.1, 0.3, Vector2(22, 14), Vector2(16, -14), Vector2(180, -70), [&"heavy"])
				&"final":
					return make_attack(60.0, 0.5, 0.25, 0.4, Vector2(28, 20), Vector2(16, -12), Vector2(260, -160),
						[&"heavy"], {"lunge": Vector2(260, -120), "no_cancel": true})
	return {}
