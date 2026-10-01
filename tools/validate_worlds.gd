extends SceneTree
## Kiểm tra các file thế giới (scripts/data/worlds/) theo docs/WORLD_FILES.md.
##
##   godot --headless --path . -s tools/validate_worlds.gd            # mọi thế giới
##   godot --headless --path . -s tools/validate_worlds.gd -- ryuki   # chỉ vài thế giới (theo id)
##
## In lỗi từng file và thoát với mã lỗi = số lỗi. Kiểm: đủ hằng và khóa, 5 màn, form của màn có trong RIDER,
## mỗi form phụ rơi ra ở đúng một màn luyện tập,
## kiểu đòn / hiệu ứng hợp lệ, chỉ số trong khoảng, tên nền "<id>_1".."<id>_4", "<id>_b" và kiểu nền có trong
## tools/gen_backgrounds.py, người nói trong STORY có khai báo, câu thoại không quá dài, không trùng người nói /
## tên nền giữa các file.

const DIR := "res://scripts/data/worlds/"
const CUSTOM := ["kuuga", "faiz", "double"]       ## Rider có script riêng, RIDER để trống
const STYLES := ["brawler", "blade", "lancer", "heavy", "gunner"]
const GUN_KEYS := ["damage", "speed", "cooldown", "count", "spread", "radius", "color", "pierce", "life"]
const BEATS := ["start", "goal", "key", "clear"]
const BASE_SPEAKERS := ["narrator", "hero", "pen", "void"]
const MAX_LINE := 165
const RANGES := {"hp": [110.0, 220.0], "armor": [0.0, 65.0], "speed": [75.0, 185.0], "jump": [0.75, 1.5],
	"atk": [0.75, 1.5], "poise": [2.0, 22.0]}

var errors := 0
var _file := ""


func _initialize() -> void:
	var only := OS.get_cmdline_user_args()
	var themes := _themes()
	var files: Array = []
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".gd"):
			files.append(f)
	files.sort()
	var seen_speakers := {}
	var seen_bg := {}
	var ids: Array = []
	for f in files:
		_file = f
		var script := load(DIR + f) as GDScript
		if script == null:
			_err("không nạp được (lỗi cú pháp?)")
			continue
		var c: Dictionary = script.get_script_constant_map()
		for k in ["WORLD", "RIDER", "SPEAKERS", "STORY", "WORLD_CLEAR"]:
			if not c.has(k):
				_err("thiếu hằng %s" % k)
		if not c.has("WORLD"):
			continue
		var w: Dictionary = c["WORLD"]
		var id := str(w.get("id", ""))
		ids.append(id)
		if not only.is_empty() and not only.has(id):
			# vẫn gom tên để kiểm trùng
			for sp in c.get("SPEAKERS", {}):
				seen_speakers[sp] = f
			for st in w.get("stages", []):
				seen_bg[str(st.get("bg", ""))] = f
			continue
		_check_world(w, c, themes, seen_speakers, seen_bg, f)
	print("[validate] %d file · %s" % [files.size(), "TẤT CẢ OK" if errors == 0 else "%d lỗi" % errors])
	quit(errors)


func _err(msg: String) -> void:
	errors += 1
	print("  ✘ %s: %s" % [_file, msg])


func _themes() -> Array:
	var out: Array = []
	var text := FileAccess.get_file_as_string("res://tools/gen_backgrounds.py")
	var re := RegEx.new()
	re.compile('^\\s+"(\\w+)":\\s*(bg_|lambda)')
	for line in text.split("\n"):
		var m := re.search(line)
		if m:
			out.append(m.get_string(1))
	return out


func _check_world(w: Dictionary, c: Dictionary, themes: Array, seen_speakers: Dictionary, seen_bg: Dictionary, f: String) -> void:
	var id := str(w.get("id", ""))
	if not f.ends_with("_%s.gd" % id):
		_err("id \"%s\" không khớp tên file" % id)
	for k in ["year", "name", "motto", "rider", "rider_name", "driver_name", "color", "enemies", "unlocks", "stages"]:
		if not w.has(k):
			_err("WORLD thiếu khóa %s" % k)
	if w.get("rider", &"") != StringName(id):
		_err("\"rider\" phải là &\"%s\"" % id)
	if not (w.get("color") is Color):
		_err("\"color\" phải là Color")
	var en: Dictionary = w.get("enemies", {})
	for kind in ["basic", "fast", "armored"]:
		var e: Dictionary = en.get(kind, {})
		if str(e.get("name", "")).is_empty() or not (e.get("color") is Color):
			_err("enemies.%s cần name và color" % kind)
	if (w.get("unlocks", []) as Array).size() != 5:
		_err("unlocks phải có 5 dòng")
	var custom := CUSTOM.has(id)
	var rider: Dictionary = c.get("RIDER", {})
	var forms: Dictionary = rider.get("forms", {})
	if not custom:
		_check_rider(rider)
	var stages: Array = w.get("stages", [])
	if stages.size() != 5:
		_err("cần đúng 5 màn (có %d)" % stages.size())
	if not custom:
		# Mỗi form phụ rơi ra ở đúng một màn luyện tập (2–4). Rider ít form (Kabuto) có màn luyện tập không rơi form.
		for fid in forms:
			if fid == rider.get("base", &""):
				continue
			var drops := 0
			for i in range(1, mini(stages.size(), 4)):
				if (stages[i] as Dictionary).get("form", &"") == fid:
					drops += 1
			if drops != 1:
				_err("form %s phải rơi ra ở đúng một màn luyện tập (đang %d màn)" % [fid, drops])
	var suffixes := ["1", "2", "3", "4", "b"]
	for i in stages.size():
		var st: Dictionary = stages[i]
		if str(st.get("name", "")).is_empty():
			_err("màn %d thiếu name" % (i + 1))
		var bg := str(st.get("bg", ""))
		if not custom:
			if bg != "%s_%s" % [id, suffixes[mini(i, 4)]]:
				_err("màn %d: \"bg\" phải là \"%s_%s\"" % [i + 1, id, suffixes[mini(i, 4)]])
			if not themes.has(str(st.get("bg_theme", ""))):
				_err("màn %d: bg_theme \"%s\" không có trong tools/gen_backgrounds.py" % [i + 1, st.get("bg_theme", "")])
		if seen_bg.has(bg) and seen_bg[bg] != f:
			_err("tên nền \"%s\" trùng với %s" % [bg, seen_bg[bg]])
		seen_bg[bg] = f
		if i == 0 and str(st.get("goal", "")).is_empty():
			_err("màn 1 (Thức tỉnh) cần \"goal\"")
		if i in [1, 2, 3] and st.has("form"):
			if str(st.get("form_name", "")).is_empty():
				_err("màn %d có form nhưng thiếu form_name" % (i + 1))
			if not custom and not forms.has(st["form"]):
				_err("màn %d: form %s không có trong RIDER.forms" % [i + 1, st["form"]])
			if not custom and st["form"] == rider.get("base", &""):
				_err("màn %d: form rơi ra không được là form gốc" % (i + 1))
		if i == 4:
			var boss: Dictionary = st.get("boss", {})
			for k in ["name", "hp", "damage", "poise", "speed", "traits", "color"]:
				if not boss.has(k):
					_err("trùm thiếu khóa %s" % k)
			for t in boss.get("traits", []):
				if not str(t) in ["fast", "armored"]:
					_err("trait trùm \"%s\" không hợp lệ (fast / armored)" % t)
	# Người nói
	var sps: Dictionary = c.get("SPEAKERS", {})
	var look_re := RegEx.new()
	look_re.compile("^(base=(hero|kuuga|grongi|orphnoch|daguba)( tint=[0-9a-f]{6})?( eternal)?|hair=[0-9a-f]{6} jacket=[0-9a-f]{6} stripe=[0-9a-f]{6} eyes=[0-9a-f]{6}( hat)?( glasses)?( long)?)$")
	for key in sps:
		var sp: Dictionary = sps[key]
		if seen_speakers.has(key) and seen_speakers[key] != f:
			_err("người nói \"%s\" trùng với %s" % [key, seen_speakers[key]])
		seen_speakers[key] = f
		if BASE_SPEAKERS.has(key):
			_err("người nói \"%s\" trùng người nói chung" % key)
		if str(sp.get("name", "")).is_empty() or not (sp.get("color") is Color):
			_err("người nói %s cần name và color" % key)
		if str(sp.get("portrait", "")) != str(key):
			_err("người nói %s: \"portrait\" phải bằng khóa" % key)
		if look_re.search(str(sp.get("look", ""))) == null:
			_err("người nói %s: \"look\" sai định dạng: %s" % [key, sp.get("look", "")])
	# Hội thoại
	var story: Dictionary = c.get("STORY", {})
	for sk in story:
		if not str(sk) in ["1", "2", "3", "4", "B"]:
			_err("STORY khóa \"%s\" không hợp lệ" % sk)
		var beats: Dictionary = story[sk]
		for b in beats:
			if not BEATS.has(b):
				_err("STORY[%s] nhịp \"%s\" không hợp lệ" % [sk, b])
			for line in beats[b]:
				_check_line(line, sps, "STORY[%s].%s" % [sk, b])
	for sk in ["1", "2", "3", "4"]:
		if not (story.get(sk, {}) as Dictionary).has("start"):
			_err("STORY[%s] thiếu \"start\"" % sk)
	for sk in ["1", "2", "3", "4", "B"]:
		if not (story.get(sk, {}) as Dictionary).has("clear"):
			_err("STORY[%s] thiếu \"clear\"" % sk)
	if not (story.get("B", {}) as Dictionary).has("goal"):
		_err("STORY[B] thiếu \"goal\" (lời trùm trước trận)")
	if not (story.get("1", {}) as Dictionary).has("key"):
		_err("STORY[1] thiếu \"key\" (cảnh nhặt Driver)")
	for i in [1, 2, 3]:
		if i < stages.size() and (stages[i] as Dictionary).has("form") and not (story.get(str(i + 1), {}) as Dictionary).has("key"):
			_err("STORY[%d] thiếu \"key\" (cảnh nhặt form)" % (i + 1))
	var wc: Array = c.get("WORLD_CLEAR", [])
	if wc.is_empty():
		_err("WORLD_CLEAR trống")
	for line in wc:
		_check_line(line, sps, "WORLD_CLEAR")


func _check_line(line, sps: Dictionary, where: String) -> void:
	if not (line is Array) or (line as Array).size() != 2:
		_err("%s: câu thoại phải là [người nói, lời]" % where)
		return
	var who := str(line[0])
	if not BASE_SPEAKERS.has(who) and not sps.has(who):
		_err("%s: người nói \"%s\" chưa khai báo trong SPEAKERS" % [where, who])
	var text := str(line[1])
	if text.length() > MAX_LINE:
		_err("%s: câu dài %d ký tự (tối đa %d): %s..." % [where, text.length(), MAX_LINE, text.left(40)])


func _check_rider(r: Dictionary) -> void:
	for k in ["name", "tagline", "base", "order", "forms", "lv5"]:
		if not r.has(k):
			_err("RIDER thiếu khóa %s" % k)
	var forms: Dictionary = r.get("forms", {})
	var order: Array = r.get("order", [])
	if order.is_empty() or order[0] != r.get("base", &""):
		_err("RIDER.order phải bắt đầu bằng form gốc")
	if not forms.has(r.get("base", &"")):
		_err("RIDER.forms thiếu form gốc")
	for fid in forms:
		if not order.has(fid):
			_err("form %s không có trong order" % fid)
		var fm: Dictionary = forms[fid]
		for k in ["name", "style", "hp", "armor", "speed", "jump", "atk", "poise", "final"]:
			if not fm.has(k):
				_err("form %s thiếu %s" % [fid, k])
		if not STYLES.has(str(fm.get("style", ""))):
			_err("form %s: style \"%s\" không hợp lệ" % [fid, fm.get("style", "")])
		for k in RANGES:
			var v := float(fm.get(k, 0.0))
			if v < RANGES[k][0] or v > RANGES[k][1]:
				_err("form %s: %s = %s ngoài khoảng %s" % [fid, k, v, RANGES[k]])
		if fm.has("effect") and str(fm["effect"]) != "time":
			_err("form %s: effect chỉ có thể là \"time\"" % fid)
		var fx: Dictionary = fm.get("fx", {})
		for fk in fx:
			if not fk in ["hit", "swing", "shot", "final", "color", "trail", "glide"]:
				_err("form %s: fx có khóa lạ \"%s\"" % [fid, fk])
		for fk in ["hit", "swing", "final"]:
			if fx.has(fk) and not str(fx[fk]) in Fx.KINDS and not (fk == "swing" and str(fx[fk]) == ""):
				_err("form %s: fx.%s \"%s\" không có trong Fx.KINDS" % [fid, fk, fx[fk]])
		if fx.has("shot") and not str(fx["shot"]) in Fx.SHOTS:
			_err("form %s: fx.shot \"%s\" không có trong Fx.SHOTS" % [fid, fx["shot"]])
		for gk in (fm.get("gun", {}) as Dictionary):
			if not GUN_KEYS.has(gk):
				_err("form %s: gun có khóa lạ \"%s\"" % [fid, gk])
		if str(fm.get("style", "")) == "gunner" and not fm.has("gun"):
			_err("form %s kiểu gunner nên có \"gun\"" % fid)
	var lv5: Dictionary = r.get("lv5", {})
	if str(lv5.get("name", "")).is_empty():
		_err("RIDER.lv5 cần name")
