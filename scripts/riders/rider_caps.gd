extends RefCounted
class_name RiderCaps
## Form nào khắc chế được quái đặc biệt nào (Enemy.SPECIALS): gom tag của mọi đòn (Đánh, đá, Chém, Final), đạn
## (&"ranged" + tag của đạn) và RiderForm.special_tags() của form, rồi so với "needs" của từng loại quái.
## Dùng ở màn chọn màn (màn EX: "Phù hợp: Kuuga Pegasus..."), màn chọn form / item (dòng "Khắc chế") và
## tools/validate_worlds.gd (Rider của thế giới phải tự qua được màn EX của thế giới mình).

## Không tính Final: form chỉ có Final mang nguyên tố vẫn hạ được bóng ma nhưng chậm, không gợi ý.
const ATTACK_KINDS := [&"light", &"kick", &"slash", &"slash_finish"]
## Tên ngắn của từng loại quái đặc biệt (dòng "Khắc chế" ở màn chọn form).
const SHORT := {&"flying": "Quái bay", &"giant": "Khổng lồ", &"phantom": "Siêu tốc", &"spectral": "Bóng ma"}


## Mọi tag form `form_id` của `rider` đánh ra được (&"" = form gốc).
static func form_tags(rider: StringName, form_id: StringName) -> Array:
	var f := FigurePicker.preview_form(rider, form_id)
	if f == null:
		return []
	var tags: Array = f.special_tags().duplicate()
	for kind in ATTACK_KINDS:
		var a: Dictionary = f.get_attack(kind, 0)
		if not a.is_empty():
			tags.append_array(a["tags"])
	var shot := f.get_shot()
	if not shot.is_empty():
		tags.append(&"ranged")
		tags.append_array(shot.get("tags", []))
	f.free()
	return tags


## Các loại quái đặc biệt form này gây sát thương được.
static func counters(rider: StringName, form_id: StringName) -> Array[StringName]:
	var tags := form_tags(rider, form_id)
	var out: Array[StringName] = []
	for special in Enemy.SPECIALS:
		var needs: Array = Enemy.SPECIALS[special]["needs"]
		if needs.any(func(t): return tags.has(t)):
			out.append(special)
	return out


## Mọi form của Rider (form gốc đứng đầu), kể cả form chưa nhặt. W: 9 tổ hợp Soul × Body + Xtreme.
static func all_forms(rider: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var f := GameState.create_form(rider)
	if f == null:
		return out
	out.append(f.base_form())
	var consts: Dictionary = f.get_script().get_script_constant_map()
	if f is DataRider:
		for id in (f as DataRider).data.get("forms", {}):
			if not out.has(id):
				out.append(id)
	elif consts.has("SOULS"):
		for s in consts["SOULS"]:
			for b in consts["BODIES"]:
				var id := StringName("%s_%s" % [str(s).to_lower(), str(b).to_lower()])
				if not out.has(id):
					out.append(id)
		out.append(&"xtreme")
	else:
		for id in consts.get("ORDER", []):
			if not out.has(id):
				out.append(id)
	f.free()
	return out


## Form người chơi đã có (form gốc, form / item đã nhặt; W: tổ hợp của các nửa đã mở).
static func owned_forms(rider: StringName) -> Array[StringName]:
	var f := GameState.create_form(rider)
	if f == null:
		return [] as Array[StringName]
	var out: Array[StringName] = []
	var is_double: bool = f.get_script().get_script_constant_map().has("SOULS")
	for id in all_forms(rider):
		var owned := id == f.base_form() or GameState.owns_form(rider, id)
		if is_double:
			owned = f.has_form(id)   # W: nửa Soul / Body đã mở (không xét giới hạn mang vào màn)
		if owned:
			out.append(id)
	f.free()
	return out


## Các form (của mọi Rider đã kích hoạt) khắc chế được `special`, dạng "Kuuga Pegasus". Tối đa `limit` tên.
static func owned_counters(special: StringName, limit := 4) -> Array[String]:
	var out: Array[String] = []
	for rider in GameState.selectable_riders():
		for id in owned_forms(rider):
			if counters(rider, id).has(special):
				out.append(FigurePicker.form_label(rider, id))
				if out.size() >= limit:
					return out
	return out


## Dòng "Khắc chế: Quái bay · Bóng ma" cho màn chọn form / item ("" = không khắc chế loại nào).
static func counter_line(rider: StringName, form_id: StringName) -> String:
	var names: Array[String] = []
	for special in counters(rider, form_id):
		names.append(str(SHORT[special]))
	return "Khắc chế: %s" % " · ".join(names) if not names.is_empty() else ""
