extends RefCounted
class_name StageBuilder
## Sinh bố cục màn kiểu Contra từ dữ liệu màn trong WorldData.
## Cùng một màn luôn ra cùng một bố cục (seed = id màn), nên chơi lại vẫn quen đường.
##
## Một màn là một LỘ TRÌNH gồm nhiều đoạn nối nhau (WorldData "route", mặc định ["right"]):
##   "right" / "left" : đoạn chạy ngang sang phải / sang trái. Mặt đất có vực, bệ một chiều, thùng,
##                      bậc thang khối, cột đá giữa vực rộng. Lính bắn đứng gác trên mặt đất.
##   "up"             : giếng leo lên, rộng đúng một màn hình. Bệ một chiều xếp zig-zag (nhảy xuyên từ dưới lên),
##                      trên cùng là gờ ra cửa. Rơi khỏi bệ thì rơi xuống bệ dưới / sàn đáy giếng.
##   "down"           : giếng tụt xuống, từ gờ cửa trên cùng xuống sàn đáy (S + nhảy để xuống bệ).
## Đoạn cuối luôn là đoạn ngang (có vạch đích; màn trùm có đấu trường ở cuối).
##
## Camera đi theo một ĐƯỜNG GẤP KHÚC (path): đoạn ngang ở độ cao sàn - BAND, đoạn dọc ở giữa giếng.
## Vị trí camera là một số s (quãng đường dọc theo path). Camera đi theo người chơi cả hai chiều (StageRun),
## dừng ở hai đầu path. Vách giếng và tường cuối màn là vật cứng thật; tường sau điểm xuất phát là tường vô hình.
##
## Kết quả (Dictionary, đơn vị pixel thật):
##   solids      : [{rect: Rect2, kind: "ground" | "wall" | "block"}] vật cứng (lớp world)
##   platforms   : [Vector3(x, y_mặt_trên, rộng)] bệ một chiều
##   path, path_s: các điểm gấp của đường camera và quãng đường s tại từng điểm; length = tổng
##   spawns      : [{s, kind, count, behavior, side, floor, dir, limit, pos}] camera tới s lần đầu thì thả quái
##                 side "ahead"/"behind": thả ở mép màn hình phía trước/sau; "at": thả tại pos (trên bệ giếng)
##   shooters    : [{s, pos, kind}] lính bắn đứng gác
##   checkpoints : [{s, pos}] điểm hồi sinh khi gục
##   waypoints   : [{pos, s}] các điểm cần đi qua theo thứ tự (bot test dùng để tìm đường)
##   start, start_dir, goal_x, goal_dir, goal_s0, exit_floor, is_boss, bottom
##   overlaps    : [String] lỗi bố cục: vật cứng của đoạn này chắn vào khoảng trống của đoạn khác
##                 (lộ trình quay đầu đè lên chính nó). Rỗng = hợp lệ.
##
## Sức nhảy: nhảy cao ~109 px (Titan ~70 px), xa ~170 px ⇒ bệ leo cách nhau tối đa 56 px, vực 60–120 px.

const GROUND_Y := 150.0
const ARENA_W := 480.0
const HALF_W := 240.0
const HALF_H := 135.0
const BAND := 50.0               ## tâm camera cao hơn sàn chừng này
const SHAFT_W := 480.0           ## giếng rộng đúng một màn hình
const WALL_T := 16.0
const DOOR_H := 120.0
const LEDGE_W := 176.0
const BLOCK := 32.0
const FILL := 224.0              ## độ dày khối đất dưới mặt sàn
const PIT_MIN := 60.0
const PIT_MAX := 120.0
const PLATFORM_MIN_H := 60.0
const PLATFORM_MAX_H := 95.0
const CLIMB_STEP_MAX := 56.0            ## Titan (nhảy ×0.8) cao tối đa ~70 px, còn dư ~14 px
const DROP_STEP_MIN := 70.0
const DROP_STEP_MAX := 90.0
const CHECKPOINT_EVERY := 900.0


static func build(stage: Dictionary, stage_index: int) -> Dictionary:
	var g := _Gen.new()
	g.run(stage, stage_index)
	return g.result()


# --- Tra cứu lúc chạy -----------------------------------------------------------

## Điểm trên đường camera ứng với quãng đường s.
static func path_point(layout: Dictionary, s: float) -> Vector2:
	var pts: Array = layout["path"]
	var ps: Array = layout["path_s"]
	var k := path_segment(layout, s)
	var seg_len: float = ps[k + 1] - ps[k]
	var t := 0.0 if seg_len <= 0.0 else clampf((s - ps[k]) / seg_len, 0.0, 1.0)
	return (pts[k] as Vector2).lerp(pts[k + 1], t)


## Chỉ số đoạn path chứa s (s nằm trong [path_s[k], path_s[k+1])).
static func path_segment(layout: Dictionary, s: float) -> int:
	var ps: Array = layout["path_s"]
	for k in ps.size() - 2:
		if s < ps[k + 1]:
			return k
	return ps.size() - 2


## Hướng đi của camera tại s: (1,0) phải, (-1,0) trái, (0,-1) lên, (0,1) xuống.
static func path_dir(layout: Dictionary, s: float) -> Vector2:
	var pts: Array = layout["path"]
	var k := path_segment(layout, s)
	return ((pts[k + 1] as Vector2) - pts[k]).normalized()


## Quãng đường s ứng với một vị trí trên màn (vị trí chân nhân vật). Chỉ xét các đoạn gần near_s
## để không nhầm sang đoạn khác nằm chồng phía trên / dưới.
static func project(layout: Dictionary, pos: Vector2, near_s := -1.0) -> float:
	var pts: Array = layout["path"]
	var ps: Array = layout["path_s"]
	var anchor := pos + Vector2(0.0, -BAND)
	var k0 := 0
	var k1 := pts.size() - 2
	if near_s >= 0.0:
		var kc := path_segment(layout, near_s)
		k0 = maxi(kc - 1, 0)
		k1 = mini(kc + 1, pts.size() - 2)
	var best_s := 0.0
	var best_d := INF
	for k in range(k0, k1 + 1):
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var ab := b - a
		var len2 := ab.length_squared()
		var t := 0.0 if len2 <= 0.0 else clampf((anchor - a).dot(ab) / len2, 0.0, 1.0)
		var q := a + ab * t
		var d := ((anchor - q) / Vector2(HALF_W, HALF_H)).length()
		if d < best_d:
			best_d = d
			best_s = ps[k] + t * sqrt(len2)
	return best_s


## Độ cao mặt trên của chỗ đứng gần nhất bên dưới pos (trong max_depth). Không có thì INF.
static func surface_below(layout: Dictionary, pos: Vector2, max_depth: float) -> float:
	var best := INF
	for so in layout["solids"]:
		var r: Rect2 = so["rect"]
		if pos.x >= r.position.x and pos.x <= r.end.x and r.position.y >= pos.y - 1.0 and r.position.y - pos.y <= max_depth:
			best = minf(best, r.position.y)
	for p in layout["platforms"]:
		if pos.x >= p.x and pos.x <= p.x + p.z and p.y >= pos.y - 1.0 and p.y - pos.y <= max_depth:
			best = minf(best, p.y)
	return best


## Phía trước (dir = ±1) có vực không.
static func pit_ahead(layout: Dictionary, pos: Vector2, dir: float) -> bool:
	return surface_below(layout, pos + Vector2(dir * 40.0, -4.0), 70.0) == INF


## Chỗ đứng an toàn trong khung nhìn, gần near nhất (để hồi sinh sau khi rơi).
static func safe_spot(layout: Dictionary, view: Rect2, near: Vector2) -> Vector2:
	var best := near
	var best_d := INF
	var tops: Array = []
	for so in layout["solids"]:
		if so["kind"] != "wall":
			var r: Rect2 = so["rect"]
			tops.append(Vector3(r.position.x, r.position.y, r.size.x))
	tops.append_array(layout["platforms"])
	for t in tops:
		if t.y < view.position.y + 40.0 or t.y > view.end.y - 10.0:
			continue
		var x0 := maxf(t.x, view.position.x) + 24.0
		var x1 := minf(t.x + t.z, view.end.x) - 24.0
		if x1 < x0:
			continue
		var p := Vector2(clampf(near.x, x0, x1), t.y)
		if _inside_solid(layout, p + Vector2(0, -20)):
			continue
		var d := p.distance_squared_to(near)
		if d < best_d:
			best_d = d
			best = p
	return best - Vector2(0, 2)


static func _inside_solid(layout: Dictionary, p: Vector2) -> bool:
	for so in layout["solids"]:
		if (so["rect"] as Rect2).has_point(p):
			return true
	return false


# --- Bộ sinh ------------------------------------------------------------------

class _Gen:
	var rng := RandomNumberGenerator.new()
	var solids: Array = []
	var platforms: Array = []
	var path: Array = []
	var path_len := 0.0
	var spawns: Array = []
	var shooters: Array = []
	var checkpoints: Array = []
	var waypoints: Array = []
	var pool: Array = []
	var idx := 0
	var is_boss := false
	var is_awaken := false
	var start := Vector2.ZERO
	var start_dir := 1
	var goal_x := 0.0
	var goal_dir := 1
	var goal_s0 := 0.0
	var exit_floor := GROUND_Y
	var cursor_x := 0.0
	var floor_y := GROUND_Y
	var sec := 0                  ## chỉ số đoạn đang dựng (gắn vào từng vật cứng để kiểm tra chồng lấn)
	var spaces: Array = []        ## [Rect2] khoảng trống người chơi đi qua của từng đoạn

	func run(stage: Dictionary, stage_index: int) -> void:
		rng.seed = hash(str(stage["id"]))
		idx = stage_index
		is_boss = stage["type"] == WorldData.StageType.BOSS
		is_awaken = stage["type"] == WorldData.StageType.AWAKEN
		pool = StageBuilder._enemy_pool(stage)
		var route := _normalize(stage.get("route", ["right"]))
		var has_shaft := route.has("up") or route.has("down")
		var horizontals := route.filter(func(r): return r == "right" or r == "left").size()
		var budget := 1500.0 if is_boss else 2200.0 + 450.0 * idx
		if has_shaft:
			budget *= 0.75
		var h_len := maxf(budget / horizontals, 700.0)
		for i in route.size():
			sec = i
			var r: String = route[i]
			var first := i == 0
			var last := i == route.size() - 1
			if r == "right" or r == "left":
				_horizontal(1 if r == "right" else -1, h_len, first, last)
			else:
				var entry_h := 0 if first else (1 if route[i - 1] == "right" else -1)
				var exit_h := 1 if route[i + 1] == "right" else -1
				if r == "up":
					_shaft(-1, entry_h, exit_h, 480.0 + 40.0 * idx)
				else:
					_shaft(1, entry_h, exit_h, 440.0 + 40.0 * idx)

	## Đoạn cuối phải là đoạn ngang; không cho hai giếng liền nhau.
	func _normalize(raw: Array) -> Array:
		var out: Array = []
		for r in raw:
			var v := str(r)
			if not v in ["right", "left", "up", "down"]:
				continue
			if (v == "up" or v == "down") and not out.is_empty() and (out.back() == "up" or out.back() == "down"):
				continue
			out.append(v)
		if out.is_empty():
			out.append("right")
		if out.back() == "up" or out.back() == "down":
			var last_h := "right"
			for r in out:
				if r == "right" or r == "left":
					last_h = r
			out.append(last_h)
		return out

	func add_point(p: Vector2) -> void:
		if not path.is_empty():
			path_len += (p - path.back()).length()
		path.append(p)

	func add_solid(r: Rect2, kind: String) -> void:
		if r.size.x > 0.5 and r.size.y > 0.5:
			solids.append({"rect": r.abs(), "kind": kind, "sec": sec})

	## Đoạn ngang: h = 1 sang phải, -1 sang trái. d là quãng đường tính từ cửa vào của đoạn.
	func _horizontal(h: int, length: float, first: bool, last: bool) -> void:
		var entry := cursor_x
		var fy := floor_y
		var w := func(d: float) -> float: return entry + h * d
		var cam_y := fy - BAND
		if first:
			add_point(Vector2(w.call(140.0), cam_y))
			start = Vector2(w.call(60.0), fy - 2.0)
			start_dir = h
		var cam_start_x: float = path.back().x
		var s0 := path_len
		var cam_end_x: float
		if last:
			cam_end_x = w.call(length + ARENA_W / 2.0) if is_boss else w.call(length + 40.0 - HALF_W)
		else:
			cam_end_x = w.call(length + SHAFT_W / 2.0)
		var s_of := func(cam_x: float) -> float:
			return s0 + clampf((cam_x - cam_start_x) * h, 0.0, absf(cam_end_x - cam_start_x))

		# Mặt đất, vực, cột đá giữa vực rộng
		var ground_from := -400.0 if first else 0.0
		var ground_to := length
		if last:
			ground_to = length + (ARENA_W + 40.0 if is_boss else 400.0)
		var pits: Array = []
		if not is_awaken:
			var d := 520.0
			while d < length - 500.0:
				d += rng.randf_range(320.0, 620.0)
				if rng.randf() < 0.5 and d < length - 500.0:
					var wide := rng.randf() < 0.3
					var gap := snappedf(rng.randf_range(170.0, 220.0) if wide else rng.randf_range(PIT_MIN, PIT_MAX), 4.0)
					pits.append(Vector3(d, d + gap, 1.0 if wide else 0.0))
					d += gap
		var seg_start := ground_from
		for p in pits:
			_ground_span(w, seg_start, p.x, fy)
			if p.z > 0.0:
				# Cột đá giữa vực rộng: nhảy hai nhịp để qua.
				var mid: float = (p.x + p.y) / 2.0
				var top: float = fy - (BLOCK if rng.randf() < 0.4 else 0.0)
				var x0: float = minf(w.call(mid - BLOCK), w.call(mid + BLOCK))
				add_solid(Rect2(x0, top, BLOCK * 2.0, FILL + fy - top), "ground")
			seg_start = p.y
		_ground_span(w, seg_start, ground_to, fy)
		var on_pit := func(d: float, margin: float) -> bool:
			for p in pits:
				if d > p.x - margin and d < p.y + margin:
					return true
			return false

		# Bệ một chiều
		var d := 380.0 if first else 240.0
		while true:
			d += rng.randf_range(240.0, 440.0)
			var pw := snappedf(rng.randf_range(96.0, 200.0), 32.0)
			if d + pw > length - 120.0:
				break
			var ph := snappedf(rng.randf_range(PLATFORM_MIN_H, PLATFORM_MAX_H), 4.0)
			_platform(w, d, d + pw, fy - ph)
			if rng.randf() < 0.25 + 0.05 * idx:
				_platform(w, d + pw * 0.5, d + pw * 0.5 + 96.0, fy - ph - rng.randf_range(55.0, 75.0))

		# Khối kiểu Contra 2: thùng, chồng thùng, bậc thang
		var blocks: Array = []   # [d0, d1] đã chiếm
		d = 360.0 if first else 220.0
		var tries := 0
		while d < length - 320.0 or (blocks.is_empty() and tries < 12):
			tries += 1
			d = d + rng.randf_range(200.0, 380.0) if d < length - 320.0 else rng.randf_range(160.0, length - 320.0)
			var cols: Array
			match rng.randi() % 5:
				0, 1:
					cols = [1] if rng.randf() < 0.5 else [1, 1]
				2:
					cols = [2] if rng.randf() < 0.5 else [2, 2]
				3:
					cols = [1, 2, 3, 2, 1] if idx >= 2 else [1, 2, 1]
				_:
					cols = [1, 2, 2]
			var span := cols.size() * BLOCK
			if on_pit.call(d, 48.0) or on_pit.call(d + span, 48.0) or d + span > length - 260.0:
				continue
			var tallest: float = cols.max() * BLOCK
			if _platform_clash(minf(w.call(d), w.call(d + span)), absf(span), fy - tallest):
				continue
			for c in cols.size():
				var hgt: float = cols[c] * BLOCK
				var x0: float = minf(w.call(d + c * BLOCK), w.call(d + (c + 1) * BLOCK))
				add_solid(Rect2(x0, fy - hgt, BLOCK, hgt), "block")
			blocks.append(Vector2(d, d + span))
			d += span
		var on_block := func(dd: float, margin: float) -> bool:
			for b in blocks:
				if dd > b.x - margin and dd < b.y + margin:
					return true
			return false

		# Quái xuất hiện theo đoạn đường
		var runner_share := 0.3 if is_awaken else 0.45
		var limit: float = w.call(length - 20.0) if not last else w.call(ground_to - 20.0)
		if last and is_boss:
			limit = w.call(length + ARENA_W - 20.0)
		d = 360.0 if first else 200.0
		while true:
			d += rng.randf_range(250.0, 420.0) - 10.0 * idx
			if d > length - (250.0 if last else 120.0):
				break
			spawns.append({
				"s": s_of.call(w.call(d - HALF_W)),
				"kind": pool[rng.randi() % pool.size()],
				"count": rng.randi_range(1, 2 + int(idx / 2.0)),
				"behavior": "runner" if rng.randf() < runner_share else "melee",
				"side": "behind" if rng.randf() < 0.12 else "ahead",
				"floor": fy, "dir": h, "limit": limit, "pos": Vector2.ZERO,
			})

		# Lính bắn đứng gác trên mặt đất (không sát vực, không đứng trên / trong khối)
		var shooter_chance := 0.2 + 0.12 * idx
		d = 520.0 if first else 320.0
		while true:
			d += rng.randf_range(300.0, 520.0)
			if d > length - 200.0:
				break
			if rng.randf() < shooter_chance and not on_pit.call(d, 40.0) and not on_block.call(d, 40.0):
				shooters.append({"s": s_of.call(w.call(d) - h * (HALF_W + 40.0)), "pos": Vector2(w.call(d), fy),
					"kind": pool[rng.randi() % pool.size()]})

		# Checkpoint: đầu đoạn (nếu vào từ giếng) và mỗi CHECKPOINT_EVERY
		var cp_ds: Array = [] if first else [60.0]
		d = CHECKPOINT_EVERY
		while d < length - 300.0:
			cp_ds.append(d)
			d += CHECKPOINT_EVERY
		for cd in cp_ds:
			var dd: float = cd
			while on_pit.call(dd, 32.0) or on_block.call(dd, 24.0):
				dd += 32.0
			var pos := Vector2(w.call(dd), fy - 2.0)
			checkpoints.append({"s": s_of.call(pos.x + h * 40.0), "pos": pos})

		add_point(Vector2(cam_end_x, cam_y))
		waypoints.append({"pos": Vector2(w.call(length), fy - 2.0), "s": s_of.call(w.call(length))})
		var sx0: float = minf(w.call(0.0), w.call(length))
		spaces.append(Rect2(sx0, fy - 190.0, absf(length), 188.0))
		if last:
			goal_x = w.call(length + 60.0) if is_boss else w.call(length - 30.0)
			goal_dir = h
			goal_s0 = s0
			exit_floor = fy
			var wall_x: float = w.call(length + ARENA_W if is_boss else length + 40.0)
			add_solid(Rect2(wall_x if h > 0 else wall_x - 20.0, fy - 420.0, 20.0, 420.0 + FILL), "wall")
		cursor_x = w.call(length)

	func _ground_span(w: Callable, d0: float, d1: float, fy: float) -> void:
		if d1 <= d0:
			return
		var x0: float = minf(w.call(d0), w.call(d1))
		add_solid(Rect2(x0, fy, absf(d1 - d0), FILL), "ground")

	## Có bệ nào bị khối che lấp (bệ thấp hơn đỉnh khối) không. Bệ một chiều cao hơn khối thì không sao:
	## người chơi đi xuyên bệ từ dưới lên được.
	func _platform_clash(x0: float, span: float, top_y: float) -> bool:
		for p in platforms:
			if p.x < x0 + span and p.x + p.z > x0 and p.y > top_y - 12.0:
				return true
		return false

	func _platform(w: Callable, d0: float, d1: float, y: float) -> void:
		var x0: float = minf(w.call(d0), w.call(d1))
		platforms.append(Vector3(x0, y, absf(d1 - d0)))

	## Giếng dọc: vdir = -1 leo lên, 1 tụt xuống. entry_h: hướng đang đi khi vào (0 = giếng là đoạn đầu),
	## exit_h: hướng của đoạn ngang kế tiếp (quyết định cửa ra nằm ở vách trái hay phải).
	func _shaft(vdir: int, entry_h: int, exit_h: int, height: float) -> void:
		var first := entry_h == 0
		var sx0 := 0.0
		if not first:
			sx0 = cursor_x if entry_h > 0 else cursor_x - SHAFT_W
		var sx1 := sx0 + SHAFT_W
		var cx := (sx0 + sx1) / 2.0
		var y_in := floor_y
		var y_out := floor_y + vdir * height
		var top := minf(y_in, y_out)
		var bottom := maxf(y_in, y_out)
		var in_left := entry_h > 0 if not first else exit_h < 0
		var out_right := exit_h > 0
		var inner0 := sx0 + WALL_T
		var inner_w := SHAFT_W - 2.0 * WALL_T

		# Sàn đáy + hai vách (chừa cửa vào, cửa ra)
		add_solid(Rect2(sx0, bottom, SHAFT_W, FILL), "ground")
		var wall_top := top - 170.0
		var doors_left: Array = []
		var doors_right: Array = []
		if not first:
			(doors_left if in_left else doors_right).append(Vector2(y_in - DOOR_H, y_in))
		(doors_right if out_right else doors_left).append(Vector2(y_out - DOOR_H, y_out))
		_wall(sx0, wall_top, bottom, doors_left)
		_wall(sx1 - WALL_T, wall_top, bottom, doors_right)

		# Gờ ở cửa trên cùng (một chiều: leo xuyên lên được / tụt xuống được)
		var ledge_y := top
		var ledge_right := out_right if vdir < 0 else not in_left
		var ledge_x := sx1 - WALL_T - LEDGE_W if ledge_right else inner0
		platforms.append(Vector3(ledge_x, ledge_y, LEDGE_W))

		# Bệ zig-zag theo 3 làn
		var lanes := [Vector2(0.0, 160.0), Vector2(144.0, 304.0), Vector2(288.0, 448.0)]
		var ys: Array = []
		if vdir < 0:
			var n := ceili((bottom - top) / CLIMB_STEP_MAX)
			var step := (bottom - top) / n
			for i in range(1, n):
				ys.append(bottom - i * step)
		else:
			var y := top + rng.randf_range(DROP_STEP_MIN, DROP_STEP_MAX)
			while y < bottom - 60.0:
				ys.append(y)
				y += rng.randf_range(DROP_STEP_MIN, DROP_STEP_MAX)
		# Làn: đi ngược từ bệ cuối (gần gờ ra cửa khi leo) để bệ cuối luôn nằm dưới gờ.
		var lane_of: Array = []
		lane_of.resize(ys.size())
		var lane := 2 if ledge_right else 0
		for i in range(ys.size() - 1, -1, -1):
			lane_of[i] = lane
			var moves: Array = [-1, 1] if lane == 1 else ([1] if lane == 0 else [-1])
			if rng.randf() < 0.25:
				moves.append(0)
			lane = clampi(lane + moves[rng.randi() % moves.size()], 0, 2)
		var s_start := path_len
		if first:
			add_point(Vector2(cx, y_in - BAND))
			s_start = path_len
		var cam_y0 := y_in - BAND
		var s_at_view := func(y: float) -> float:
			# Camera tới s này thì mép trên (leo) / mép dưới (tụt) của khung nhìn chạm y.
			var cam_y := (y + HALF_H) if vdir < 0 else (y - HALF_H)
			return s_start + clampf((cam_y - cam_y0) * vdir, 0.0, height)
		var chance := 0.35 + 0.08 * idx
		for i in ys.size():
			var ln: Vector2 = lanes[lane_of[i]]
			var pw := snappedf(rng.randf_range(112.0, 160.0), 16.0)
			var px := inner0 + ln.x + rng.randf_range(0.0, maxf(ln.y - ln.x - pw, 0.0))
			var py: float = ys[i]
			platforms.append(Vector3(px, py, pw))
			if vdir < 0:
				waypoints.append({"pos": Vector2(px + pw / 2.0, py - 2.0),
					"s": s_start + clampf((cam_y0 - (py - 2.0 - BAND)), 0.0, height)})
			# Quái trên bệ (không đặt ở bệ ngay sát cửa vào)
			if i == 0 or i == ys.size() - 1:
				continue
			var ahead_y := py - 60.0 if vdir < 0 else py + 60.0
			if lane_of[i] != 1 and rng.randf() < chance * 0.6:
				shooters.append({"s": s_at_view.call(ahead_y), "pos": Vector2(px + pw / 2.0, py),
					"kind": pool[rng.randi() % pool.size()]})
			elif rng.randf() < chance:
				spawns.append({"s": s_at_view.call(ahead_y), "kind": pool[rng.randi() % pool.size()], "count": 1,
					"behavior": "melee", "side": "at", "floor": py, "dir": 0, "limit": 0.0,
					"pos": Vector2(px + pw / 2.0, py - 40.0)})

		# Điểm vào / checkpoint / điểm ra
		var in_x := inner0 + 60.0 if in_left else sx1 - WALL_T - 60.0
		if first:
			start = Vector2(in_x, y_in - 2.0)
			start_dir = exit_h
		else:
			checkpoints.append({"s": s_start, "pos": Vector2(in_x, y_in - 2.0)})
		var out_x := sx1 if out_right else sx0
		var s_end := s_start + height
		if vdir < 0:
			waypoints.append({"pos": Vector2(ledge_x + LEDGE_W / 2.0, y_out - 2.0), "s": s_end})
		else:
			waypoints.append({"pos": Vector2(cx + exit_h * 120.0, y_out - 2.0), "s": s_end + 120.0})
		waypoints.append({"pos": Vector2(out_x, y_out - 2.0), "s": s_end + SHAFT_W / 2.0})
		add_point(Vector2(cx, y_out - BAND))
		spaces.append(Rect2(inner0, top - DOOR_H, inner_w, bottom - top + DOOR_H - 2.0))
		cursor_x = out_x
		floor_y = y_out

	## Vách đứng từ y0 xuống y1, chừa các ô cửa [Vector2(từ, tới)].
	func _wall(x: float, y0: float, y1: float, doors: Array) -> void:
		var cuts := doors.duplicate()
		cuts.sort_custom(func(a, b): return a.x < b.x)
		var y := y0
		for c in cuts:
			add_solid(Rect2(x, y, WALL_T, c.x - y), "wall")
			y = maxf(y, c.y)
		add_solid(Rect2(x, y, WALL_T, y1 - y), "wall")

	func result() -> Dictionary:
		var path_s: Array = [0.0]
		for i in range(1, path.size()):
			path_s.append(path_s[i - 1] + (path[i] - path[i - 1]).length())
		if path.size() < 2:
			path.append(path[0] + Vector2(1, 0))
			path_s.append(path_s[0] + 1.0)
		spawns.sort_custom(func(a, b): return a["s"] < b["s"])
		shooters.sort_custom(func(a, b): return a["s"] < b["s"])
		checkpoints.sort_custom(func(a, b): return a["s"] < b["s"])
		var bottom := -INF
		for so in solids:
			bottom = maxf(bottom, (so["rect"] as Rect2).end.y)
		waypoints.sort_custom(func(a, b): return a["s"] < b["s"])
		var overlaps: Array = []
		for so in solids:
			for i in spaces.size():
				if i != so["sec"] and (so["rect"] as Rect2).intersects(spaces[i]):
					overlaps.append("%s của đoạn %d chắn vào đoạn %d tại %s" % [so["kind"], so["sec"], i, str((so["rect"] as Rect2).position)])
		return {
			"solids": solids, "platforms": platforms, "path": path, "path_s": path_s, "length": path_s.back(),
			"spawns": spawns, "shooters": shooters, "checkpoints": checkpoints, "waypoints": waypoints,
			"start": start, "start_dir": start_dir, "goal_x": goal_x, "goal_dir": goal_dir, "goal_s0": goal_s0,
			"exit_floor": exit_floor, "is_boss": is_boss, "bottom": bottom, "overlaps": overlaps,
		}


## Loại quái thường của màn, lấy từ các đợt quái trong WorldData (bỏ trùm).
static func _enemy_pool(stage: Dictionary) -> Array:
	var pool: Array = []
	for wave in stage["waves"]:
		for kind in wave:
			if kind != "boss":
				pool.append(kind)
	if pool.is_empty():
		pool.append("basic")
	return pool
