extends Node
## Màn EX (WorldData.StageType.CHALLENGE): in bảng form khắc chế quái đặc biệt (Enemy.SPECIALS) của từng Rider
## (RiderCaps) và kiểm Rider của mỗi thế giới có form (hoặc item) tự hạ được quái của màn EX thế giới mình, còn form gốc
## thì không (màn EX phải bắt đổi form).
##
##   godot --headless --path . res://tools/special_caps.tscn
##
## Thoát với mã lỗi = số thế giới sai (không form nào khắc chế, hoặc form gốc đã khắc chế).


func _ready() -> void:
	var errors := 0
	for w in WorldData.WORLDS:
		var rider: StringName = w["rider"]
		var special: StringName = WorldData.challenge_of(int(w["number"]) - 1)["special"]
		var parts: Array[String] = []
		var ok: Array[String] = []
		for f in RiderCaps.all_forms(rider):
			var c: Array[StringName] = RiderCaps.counters(rider, f)
			if not c.is_empty():
				parts.append("%s=%s" % [f, ",".join(c.map(func(x): return str(x)))])
			if c.has(special):
				ok.append(String(f) + (" (item)" if WorldData.form_is_item(rider, f) else ""))
		var base: StringName = RiderCaps.all_forms(rider)[0]
		var mark := "✓ " + ", ".join(ok) if not ok.is_empty() else "✘ KHÔNG CÓ FORM KHẮC CHẾ"
		if ok.has(String(base)):
			mark = "✘ FORM GỐC %s ĐÃ KHẮC CHẾ (không cần đổi form)" % base
		errors += int(ok.is_empty() or ok.has(String(base)))
		print("%2d %-9s EX %-8s %s · %s" % [w["number"], rider, special, mark, " | ".join(parts)])
	print("[special_caps] %s" % ("TẤT CẢ OK" if errors == 0 else "%d thế giới lỗi" % errors))
	get_tree().quit(errors)
