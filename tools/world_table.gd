extends SceneTree
## In bảng tóm tắt các thế giới (Markdown) cho GDD mục 2.8, lấy từ file thế giới:
##   godot --headless --path . -s tools/world_table.gd
const BASE_NAMES := {"kuuga": "Mighty", "faiz": "Faiz", "double": "CycloneJoker"}


func _initialize() -> void:
	print("| # | Năm | Rider | Driver | Form gốc · form rơi ở các màn luyện tập | Lv5 | Trùm | Echo Rider |")
	print("|---|---|---|---|---|---|---|---|")
	for i in WorldData.WORLDS.size():
		var w: Dictionary = WorldData.WORLDS[i]
		var consts: Dictionary = (WorldData.FILES[i] as GDScript).get_script_constant_map()
		var rider: Dictionary = consts.get("RIDER", {})
		var base := str(BASE_NAMES.get(w["id"], ""))
		if not rider.is_empty():
			base = str(rider["forms"][rider["base"]]["name"])
		var forms: Array = []
		var stages: Array = (w["stages"] as Array).slice(0, int(w["main_count"]))   # bỏ màn EX
		for si in range(1, stages.size() - 1):
			forms.append(str(w["stages"][si].get("form_name", "—")))
		var lv5 := str(w["unlocks"][4]).split(":")[0]
		if not rider.is_empty():
			var lv5_data: Dictionary = rider.get("lv5", {})
			if lv5_data.has("form"):
				lv5 = str(rider["forms"][lv5_data["form"]]["name"])
			else:
				lv5 = str(lv5_data.get("name", lv5))
		var sps: Dictionary = consts.get("SPEAKERS", {})
		var echo := ""
		if not sps.is_empty():
			echo = str(sps[sps.keys()[0]]["name"]).capitalize()
		print("| %d | %d | %s | %s | %s · %s | %s | %s | %s |" % [i + 1, w["year"], w["rider_name"], w["driver_name"], base,
			" / ".join(forms), lv5, stages.back()["boss"]["name"], echo])
	quit()
