extends Node
## In mục Rider của docs/FORMS.md từ code, cho các Rider dựng từ dữ liệu (DataRider: mọi Rider trừ Kuuga, Faiz, W):
## đầu mục, từng form (chỉ số, vũ khí, kỹ năng riêng, hiệu ứng, bảng đòn Lv1, tuyệt chiêu, thoại nhận form) và các
## hàng của bảng phụ lục. Dùng khi thêm / sửa form để tài liệu khớp với game.
##
##   FORMS_RIDERS=decade,zi_o godot --headless --path . res://tools/forms_doc.tscn > out.md
##
## Mỗi Rider in giữa hai dòng "<!-- section N -->" ... "<!-- /section N -->", hàng phụ lục giữa
## "<!-- appendix N -->" ... "<!-- /appendix N -->" để ghép vào docs/FORMS.md.

const FX_DESC := {
	"spark": "tia va chạm toả ra", "slash": "vệt chém hình cung", "fire": "lửa bùng bốc lên",
	"lightning": "tia sét gấp khúc", "sound": "vòng sóng âm lan ra", "wind": "vệt gió xoáy",
	"ring": "sóng chấn động dẹt", "tachyon": "hạt tachyon bắn ngược lên", "feather": "lông vũ vàng rơi lả tả",
	"seal": "dấu phong ấn Linto bốc cháy", "crest": "huy hiệu sừng Agito dưới chân",
	"dragon": "rồng lửa Dragreder xoáy quanh", "pointer": "mũi nón đỏ Pointer chĩa tới", "phi": "ký hiệu Φ đỏ",
	"cards": "hàng thẻ bài hologram", "taiko": "huy hiệu trống Ongeki + sóng âm", "moon": "trăng lưỡi liềm sau lưng",
	"rings3": "ba vòng Medal đỏ / vàng / lục", "rocket": "lửa tên lửa phụt sau lưng", "circle": "vòng phép đỏ có ký tự",
	"crack": "khe nứt khóa kéo Helheim mở trên đầu", "fruit": "lát trái cây khổng lồ chụp xuống rồi tách múi",
	"tire": "lốp xe vành bạc lăn vòng quanh Rider", "eye": "con mắt Ghost khổng lồ sau lưng, viền gai lửa",
	"hit_text": "chữ HIT! vàng viền đen bật lên", "graph": "trục đồ thị x-y và đường cong Vortex vẽ dần",
}
## Tên hiện của súng ("gun": {"look"}); không có trong bảng thì ghi id như cũ.
const GUN_NAMES := {"ichigo_kunai": "Ichigo Kunai", "sonic_arrow": "Sonic Arrow", "hawk_gatlinger": "Hawk Gatlinger",
	"gun": "súng", "door_ju": "Door-Ju", "gangun": "Gan Gun Saber (súng)", "tricker": "bánh xe Tricker",
	"drago_gun": "súng rồng Drago Knight"}
const SHOT_DESC := {"ball": "viên đạn tròn", "bolt": "tia sét", "fire": "cầu lửa", "arrow": "mũi tên khí"}
const STYLE_DESC := {"brawler": "Brawler (tay chân)", "blade": "Blade (kiếm)", "lancer": "Lancer (giáo / tầm xa, nhẹ)",
	"heavy": "Heavy (nặng, phá giáp)", "gunner": "Gunner (bắn)"}
## Tên hiện của hình vũ khí cận chiến ("blade": {"look"}); thiếu thì viết hoa từ id.
const BLADE_NAMES := {"flame_saber": "Flame Saber", "halberd": "Storm Halberd", "rekka": "Ongekibo Rekka",
	"dengasher_sword": "DenGasher Sword", "dengasher_rod": "DenGasher Rod", "dengasher_axe": "DenGasher Axe",
	"garulu_saber": "Garulu Saber", "dogga_hammer": "Dogga Hammer", "drill_crusher": "Drill Crusher",
	"gashacon_breaker": "Gashacon Breaker (búa)", "gangunsaber": "Gan Gun Saber (kiếm)",
	"nito": "Gan Gun Saber Nitoryu (song kiếm)", "handle_ken": "Handle-Ken", "rumble_dump": "Rumble Dump",
	"pine_iron": "Pine Iron", "ninpoutou": "Yonkoma Ninpoutou", "daidaimaru": "Daidaimaru",
	"drago_blade": "kiếm rồng Drago Knight", "zikan_girade": "Zikan Girade", "ride_heisaber": "Ride Heisaber",
	"tora": "Tora Claw (vuốt hổ)"}
## Vũ khí cầm sẵn trong hình ("armed": true) theo form.
const ARMED_NAMES := {"blade": "Blay Rouzer", "ace": "Blay Rouzer", "jack": "Blay Rouzer", "mach": "Blay Rouzer",
	"thunder": "Blay Rouzer"}
var fd_form: DataRider = null   ## form đang in (để _skill đọc tầm đòn đã ghi đè)


func p_attack(f: DataRider, kind: String) -> Dictionary:
	return f.get_attack(StringName(kind), 0)


const KIND_LABEL := {"light": "Đánh (đòn thường)", "kick": "Đánh (đòn kết chuỗi)", "slash": "Chém (nhát thường)",
	"slash_finish": "Chém (nhát kết)", "final": "Final Attack"}


func _ready() -> void:
	GameState.use_test_profile()   # mọi form ở Lv1, không đọc / ghi save thật
	var only := OS.get_environment("FORMS_RIDERS").split(",", false)
	for w in WorldData.WORLDS:
		var rider: StringName = w["rider"]
		if not only.is_empty() and not only.has(String(rider)):
			continue
		if WorldData.rider_data(rider).is_empty():
			push_warning("%s có script riêng, tools/forms_doc.gd chưa hỗ trợ" % rider)
			continue
		var out := PackedStringArray()
		var rows := PackedStringArray()
		_rider(w, out, rows)
		print("<!-- section %d -->\n%s\n<!-- /section %d -->" % [w["number"], "\n".join(out), w["number"]])
		print("<!-- appendix %d -->\n%s\n<!-- /appendix %d -->" % [w["number"], "\n".join(rows), w["number"]])
	get_tree().quit()


func _rider(w: Dictionary, out: PackedStringArray, rows: PackedStringArray) -> void:
	var rider: StringName = w["rider"]
	var n: int = w["number"]
	var data := WorldData.rider_data(rider)
	var consts: Dictionary = (WorldData.FILES[n - 1] as GDScript).get_script_constant_map()
	var power := GameState.rider_power(rider)
	out.append("## %d. Kamen Rider %s · %d" % [n, w["rider_name"], w["year"]])
	out.append("")
	out.append("- **Driver:** %s · **Lối chơi:** %s · **Sức mạnh thế hệ:** ×%s" % [w["driver_name"], data.get("tagline", ""),
		_n(snappedf(power, 0.01))])
	out.append("- **Form gốc:** `%s`" % data["base"])
	var drops: Array[String] = []
	var empty: Array[String] = []
	var drop_stage := {}
	for st in (w["stages"] as Array).slice(0, int(w["main_count"])):
		if st.has("form"):
			drops.append("%s → **%s**" % [st["id"], st["form_name"]])
			drop_stage[st["form"]] = st
		elif st["type"] == WorldData.StageType.TRAINING:
			empty.append(str(st["id"]))
	if not empty.is_empty():
		drops.append("(màn %s không rơi form)" % ", ".join(empty))
	out.append("- **Form rơi ở màn luyện tập:** " + " · ".join(drops))
	var unlocks: Array = w["unlocks"]
	var lv: Array[String] = []
	for i in unlocks.size():
		lv.append("Lv%d: %s" % [i + 1, unlocks[i]])
	out.append("- **Thưởng theo cấp:** " + " → ".join(lv))
	var lv5: Dictionary = data.get("lv5", {})
	if lv5.has("name"):
		out.append("- **Lv5 — %s:** tên hiện kèm form, mọi Final ×%s và đổi tên thành \"%s <tên chiêu>\"" % [lv5["name"],
			_n(float(lv5.get("final_mult", 1.5))), lv5["name"]])
	elif lv5.has("form"):
		out.append("- **Lv5:** mở form `%s` + mọi Final ×%s" % [lv5["form"], _n(float(lv5.get("final_mult", 1.5)))])
	var ffx: Dictionary = data.get("final_fx", {})
	if not ffx.is_empty():
		var parts: Array[String] = []
		for k in ["intro", "signature"]:
			if ffx.has(k):
				parts.append("%s `%s` (%s)" % [k, ffx[k], FX_DESC.get(str(ffx[k]), str(ffx[k]))])
		out.append("- **Dấu hiệu tuyệt chiêu chung (mọi form):** " + ", ".join(parts))
	var voice: Dictionary = consts.get("VOICE", {})
	if not voice.is_empty():
		var keys := voice.keys()
		keys.sort()
		var vs: Array[String] = []
		for k in keys:
			vs.append("`%s` \"%s\"" % [k, voice[k][1]])
		out.append("- **Giọng đai / tiếng hô:** " + " · ".join(vs))
	var i := 0
	for f in RiderCaps.all_forms(rider):
		i += 1
		out.append("")
		_form(w, consts, f, i, drop_stage, power, out, rows)
	out.append("")
	out.append("---")


func _form(w: Dictionary, consts: Dictionary, f: StringName, idx: int, drop_stage: Dictionary, power: float,
		out: PackedStringArray, rows: PackedStringArray) -> void:
	var rider: StringName = w["rider"]
	var n: int = w["number"]
	var data := WorldData.rider_data(rider)
	var fd: Dictionary = data["forms"][f]
	var p := FigurePicker.preview_form(rider, f) as DataRider
	var base := f == StringName(data["base"])
	var item := bool(fd.get("item", false))
	var kind := "form gốc" if base else ("item" if item else "form đặc biệt")
	var how := "nhận ở màn Thức tỉnh" if base else ("rơi ở màn %s" % drop_stage[f]["id"] if drop_stage.has(f)
		else "mở ở Lv5")
	out.append("### %d.%d %s  ·  _%s, %s_" % [n, idx, fd["name"], kind, how])
	out.append("")
	var time := str(fd.get("effect", "")) == "time"
	var drain := "—" if base else "%s/s" % _n(p.rage_drain())
	var style := str(fd.get("style", "brawler"))
	out.append("| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |")
	out.append("|---|---|---|---|---|---|---|---|")
	out.append("| %s | %s | %s | ×%s | ×%s | %s | %s | %s |" % [_n(p.max_hp), _n(p.armor), _n(p.move_speed), _n(p.jump_mult),
		_n(p.attack_mult), _n(p.poise), drain, STYLE_DESC.get(style, style)])
	out.append("")
	out.append("**Vũ khí:** " + _weapons(p, fd, f) + ".")
	var skill := _skill(fd, p)
	if skill != "":
		out.append("")
		out.append("**Kỹ năng riêng:** " + skill)
	out.append("")
	var fx: Dictionary = Player.DEFAULT_FX.duplicate()
	fx.merge(p.fx(), true)
	out.append("**Hiệu ứng hình ảnh:**")
	out.append("")
	out.append("- Màu hiệu ứng: `#%s`" % (fx["color"] as Color).to_html(false))
	out.append("- Đòn trúng: `%s` — %s" % [fx["hit"], _fx(fx["hit"])])
	if str(fx["swing"]) != "":
		out.append("- Vệt vung đòn: `%s` — %s" % [fx["swing"], _fx(fx["swing"])])
	out.append("- Final Attack trúng: `%s` — %s" % [fx["final"], _fx(fx["final"])])
	if str(fx["intro"]) != "":
		out.append("- Lúc tung Final (quanh Rider): `%s` — %s" % [fx["intro"], _fx(fx["intro"])])
	if str(fx["signature"]) != "":
		out.append("- Dấu ấn trên quái khi Final trúng: `%s` — %s" % [fx["signature"], _fx(fx["signature"])])
	if bool(fx["trail"]):
		out.append("- Để bóng mờ khi di chuyển (form tốc độ)")
	if bool(fx["glide"]):
		out.append("- **Lượn**: giữ Nhảy khi đang rơi → rơi chậm tối đa %s, rắc lông vũ" % _n(Player.GLIDE_FALL))
	out.append("")
	out.append("<details><summary>Bảng đòn chi tiết (Lv1)</summary>")
	out.append("")
	out.append("| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |")
	out.append("|---|---|---|---|---|---|---|---|")
	var kinds := ["light", "kick"]
	if p.has_blade():
		kinds += ["slash", "slash_finish"]
	kinds.append("final")
	var fin := {}
	for k in kinds:
		var a: Dictionary = p.get_attack(StringName(k), 0)
		if a.is_empty():
			continue
		if k == "final":
			fin = a
		var label: String = KIND_LABEL[k]
		out.append("| %s | %s | %d | %s / %s / %s | %s | (%s, %s) | %s | %s |" % [("**%s**" % label) if k == "final" else label,
			_n(a["damage"]), int(a.get("hits", 1)), _n(a["startup"]), _n(a["active"]), _n(a["recovery"]), _n(_reach(a)),
			_n(a["knockback"].x), _n(a["knockback"].y), _tags(a["tags"]), _note(a)])
	out.append("")
	var chain := "Chuỗi nút Đánh: %d đòn thường + 1 đòn kết." % p.punch_count()
	if p.has_blade():
		chain += " Chuỗi nút Chém: %d nhát + 1 nhát kết." % p.slash_count()
	out.append(chain)
	out.append("")
	out.append("</details>")
	out.append("")
	var skills := p.get_skills()
	if not skills.is_empty():
		out.append("**Skill** (docs/SKILLS.md)")
		out.append("")
		for i in skills.size():
			var sk: Dictionary = skills[i]
			out.append("- Skill %d: %s %s · %d nộ · hồi %s giây%s" % [i + 1, sk["name"],
				Skills.mark(str(sk["type"]), int(sk.get("targets", 0))), int(sk["cost"]), _n(sk["cooldown"]),
				(" · " + _tags(sk["tags"])) if not (sk["tags"] as Array).is_empty() else ""])
		out.append("")
	var lv5 := FigurePicker.preview_form(rider, f)
	lv5.set_level(5)
	var title := "**Tuyệt chiêu — %s %s**" % [p.final_attack_name(), Skills.mark(p.final_type(), p.final_targets())]
	if lv5.final_attack_name() != p.final_attack_name():
		title += " (Lv5: *%s*)" % lv5.final_attack_name()
	out.append(title)
	var fin5 := lv5.get_attack(&"final", 0)
	out.append("")
	out.append("- " + _final_line(fin))
	if time:
		out.append("- Đây là Final dạng tăng tốc thời gian: chuỗi 5 đòn lướt liên hoàn thay cho Final của kiểu đòn.")
	var tags: Array = fin["tags"]
	out.append("- Tag: %s`final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được." % (
		(_tags(tags) + " + ") if not tags.is_empty() else ""))
	var hits := int(fin.get("hits", 1))
	var real1 := float(fin["damage"]) * hits * p.attack_mult * p.level_mult()
	var real5 := float(fin5["damage"]) * int(fin5.get("hits", 1)) * lv5.attack_mult * lv5.level_mult()
	var mult := float((data.get("lv5", {}) as Dictionary).get("final_mult", 1.0))
	var note := "Final tăng tốc thời gian **không** nhận ×%s Lv5" % _n(mult) if time and mult != 1.0 else (
		"đã gồm ×%s Lv5" % _n(mult) if mult != 1.0 else "")
	out.append("- Sát thương thực (chưa tính combo): **Lv1 ≈ %d** · **Lv5 ≈ %d**%s." % [roundi(real1), roundi(real5),
		(" (%s)" % note) if note != "" else ""])
	var look := ""
	if str(fx["intro"]) != "":
		look += "quanh Rider hiện %s, " % _fx(fx["intro"])
	look += "trúng quái nổ %s" % _fx(fx["final"])
	if str(fx["signature"]) != "":
		look += ", in %s lên quái" % _fx(fx["signature"])
	out.append("- Hình ảnh: %s (màu `#%s`); tiếng nạp *final_charge* + giọng `%s_final`." % [look,
		(fx["color"] as Color).to_html(false), rider])
	var lines := _key_lines(consts, w, f, base, drop_stage)
	if not lines.is_empty():
		out.append("")
		out.append("*Mô tả trong game (thoại lúc nhận form):*")
		out.append("")
		for l in lines:
			out.append("> " + l)
	rows.append("| %d | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %d | %d |" % [n, w["rider_name"], fd["name"], kind,
		_n(p.max_hp), _n(p.armor), _n(p.move_speed), _n(p.jump_mult), _n(p.attack_mult), style, "✓" if p.has_gun() else "",
		"✓" if p.has_blade() else "", p.final_attack_name(), roundi(real1), roundi(real5)])
	p.free()
	lv5.free()


func _weapons(p: DataRider, fd: Dictionary, f: StringName) -> String:
	var parts: Array[String] = []
	if fd.get("armed", false):
		parts.append("Vũ khí cầm sẵn trong hình (%s): nút Đánh chém luôn, **không có nút Chém**" % ARMED_NAMES.get(String(f),
			"vũ khí"))
	elif p.has_blade():
		var b: Dictionary = fd.get("blade", {})
		var look := str(b.get("look", ""))
		parts.append("Nút Chém: **%s** (%d nhát + nhát kết, bảng đòn %s)" % [BLADE_NAMES.get(look, look.capitalize()) if look != ""
			else "kiếm (hình mặc định)", p.slash_count(), str(b.get("style", "blade"))])
	var shot := p.get_shot()
	if not shot.is_empty():
		var g: Dictionary = fd.get("gun", {})
		var s := "Nút Bắn: **%s** — %s sát thương/viên, hồi %ss, tốc độ %s, bay %ss, bán kính %s, đạn `%s` (%s)" % [
			GUN_NAMES.get(str(g.get("look", "súng")), str(g.get("look", "súng"))), _n(shot["damage"]), _n(shot["cooldown"]), _n(shot["speed"]), _n(shot["life"]),
			_n(shot["radius"]), _shot_style(p), SHOT_DESC.get(_shot_style(p), "")]
		if int(shot["count"]) > 1:
			s += ", %d viên xòe %s rad" % [shot["count"], _n(shot["spread"])]
		if shot["pierce"]:
			s += ", xuyên"
		if not (shot.get("tags", []) as Array).is_empty():
			s += ", tag " + _tags(shot["tags"])
		parts.append(s)
	if parts.is_empty():
		return "Chỉ tay chân (không nút Chém, không súng)"
	return ". ".join(parts)


func _shot_style(p: DataRider) -> String:
	return str(p.fx().get("shot", "ball"))


## Kỹ năng riêng: tăng tốc thời gian, khiên, nộ tụt riêng, tag cả form, đòn được ghi đè ("attacks").
func _skill(fd: Dictionary, p_form: DataRider) -> String:
	fd_form = p_form
	var parts: Array[String] = []
	if str(fd.get("effect", "")) == "time":
		parts.append("**Tăng tốc thời gian** (xem 0.5), chữ báo `%s`." % fd.get("time_call", "CLOCK UP"))
	if fd.has("guard"):
		parts.append("**Khiên** guard %s: đứng chắn chỉ nhận %d%% sát thương từ phía trước." % [_n(fd["guard"]),
			roundi(float(fd["guard"]) * 100.0)])
	if fd.has("rage_drain"):
		parts.append("Nộ tụt %s/giây (form thường không tụt)." % _n(fd["rage_drain"]))
	if fd.has("tags"):
		parts.append("Mọi đòn mang thêm %s (%s)." % [_tags(fd["tags"]), ", ".join(_effects(fd["tags"]))])
	var attacks: Dictionary = fd.get("attacks", {})
	for k in ["final", "slash", "slash_finish", "kick", "light"]:
		if not attacks.has(k):
			continue
		var o: Dictionary = attacks[k]
		var bits: Array[String] = []
		if o.has("damage"):
			bits.append("%s sát thương/nhịp" % _n(o["damage"]))
		if o.has("hits"):
			bits.append("%d nhịp" % o["hits"])
		if o.has("knockback"):
			bits.append("lực đẩy (%s, %s)%s" % [_n(o["knockback"].x), _n(o["knockback"].y),
				" — **hút về**" if o["knockback"].x < 0.0 else ""])
		if o.has("lunge"):
			bits.append("lướt (%s, %s)" % [_n(o["lunge"].x), _n(o["lunge"].y)])
		if o.has("size"):
			var reach := float(o.get("offset", Vector2.ZERO).x) + float(o["size"].x) / 2.0
			if not o.has("offset"):
				reach = _reach(p_attack(fd_form, k))
			bits.append("vùng đánh %s×%s, với tới %s" % [_n(o["size"].x), _n(o["size"].y), _n(reach)])
		if o.has("tags"):
			bits.append("thêm " + _tags(o["tags"]))
		if not bits.is_empty():
			parts.append("%s: %s." % [KIND_LABEL[k], ", ".join(bits)])
	return " ".join(parts)


func _final_line(a: Dictionary) -> String:
	var s := ""
	var lunge: Vector2 = a.get("lunge", Vector2.ZERO)
	if (a["tags"] as Array).has(&"ranged"):
		s = "phát bắn tầm xa (vùng trúng dài %s, chạm tới %s trước mặt); " % [_n(a["size"].x), _n(_reach(a))]
	elif lunge != Vector2.ZERO:
		s = "lao tới %s%s rồi tung đòn (tầm %s); " % [_n(lunge.x), (", bật lên %s" % _n(-lunge.y)) if lunge.y < 0.0 else "",
			_n(_reach(a))]
	else:
		s = "đứng tại chỗ tung đòn (tầm %s); " % _n(_reach(a))
	var hits := int(a.get("hits", 1))
	if hits > 1:
		s += "%d nhịp × %s = %s sát thương gốc" % [hits, _n(a["damage"]), _n(float(a["damage"]) * hits)]
	else:
		s += "%s sát thương gốc" % _n(a["damage"])
	var kb: Vector2 = a["knockback"]
	s += ("; hút quái về phía Rider (%s, %s)" if kb.x < 0.0 else "; hất văng (%s, %s)") % [_n(kb.x), _n(kb.y)]
	var eff := _effects(a["tags"])
	if not eff.is_empty():
		s += "; gây " + ", ".join(eff)
	return s + "."


## Hiệu ứng của tag lên quái, theo hằng của Enemy.
func _effects(tags: Array) -> Array[String]:
	var eff: Array[String] = []
	if tags.has(&"force"):
		eff.append("đẩy cưỡng bức")
	if tags.has(&"burn"):
		eff.append("cháy %ss" % _n(Enemy.BURN_TIME))
	if tags.has(&"stun"):
		eff.append("choáng %ss" % _n(Enemy.STUN_TIME))
	if tags.has(&"freeze"):
		eff.append("đóng băng %ss" % _n(Enemy.FREEZE_TIME))
	if tags.has(&"shock"):
		eff.append("điện lan %d quái" % Enemy.SHOCK_TARGETS)
	if tags.has(&"time"):
		eff.append("trúng chắc quái Fast (tag time)")
	return eff


## Thoại nhịp "key" của màn nhận form (form gốc: màn Thức tỉnh).
func _key_lines(consts: Dictionary, w: Dictionary, f: StringName, base: bool, drop_stage: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var suffix := "1"
	if not base:
		if not drop_stage.has(f):
			return out
		suffix = str(drop_stage[f]["id"]).get_slice("-", 1)
	var beats: Dictionary = (consts.get("STORY", {}) as Dictionary).get(suffix, {})
	for line in beats.get("key", []):
		out.append("**%s:** %s" % [_speaker(consts, str(line[0])), line[1]])
	return out


func _speaker(consts: Dictionary, id: String) -> String:
	match id:
		"narrator":
			return "Dẫn truyện"
		"hero":
			return "{name}"
		"pen":
			return "Pen"
		"void":
			return "Void"
	return id.left(1).to_upper() + id.substr(1)   # tên gọi tắt theo id người nói (kenzaki → Kenzaki)


func _reach(a: Dictionary) -> float:
	return float(a["offset"].x) + float(a["size"].x) / 2.0


func _note(a: Dictionary) -> String:
	var bits: Array[String] = []
	var lunge: Vector2 = a.get("lunge", Vector2.ZERO)
	if lunge != Vector2.ZERO:
		bits.append("lao tới %s%s" % [_n(lunge.x), (", bật lên %s" % _n(-lunge.y)) if lunge.y < 0.0 else ""])
	if a.get("no_cancel", false):
		bits.append("không hủy được")
	return ", ".join(bits) if not bits.is_empty() else "—"


func _tags(tags: Array) -> String:
	if tags.is_empty():
		return "—"
	var out: Array[String] = []
	for t in tags:
		out.append("`%s`" % t)
	return " ".join(out)


func _fx(kind) -> String:
	return FX_DESC.get(str(kind), str(kind))


## Số gọn: 5 thay cho 5.0, 3.5 giữ nguyên, 1.05 làm tròn 2 chữ số.
func _n(v) -> String:
	var f := snappedf(float(v), 0.01)
	if is_equal_approx(f, roundf(f)):
		return str(int(roundf(f)))
	return str(f)
