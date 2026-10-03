extends Control
class_name StageSelect
## Màn chọn màn, hai bước: chọn THẾ GIỚI rồi chọn MÀN của thế giới đó.
##   Hiện sau mỗi màn và khi bấm Menu trong màn (lần đầu chơi stage_run vào thẳng 1-1, không qua màn này).
##   Bước 1 · thế giới: cả 27 thế giới là các Trái Đất tự quay (Planet) nối nhau thành một dải trải từ trái sang phải
##     (theo năm phát sóng). Kéo / lăn chuột để cuộn dải, có quán tính.
##     Quầng màu Rider, huy hiệu số thế giới. Đã giải cứu: huy hiệu và đường nối vàng. Đang tới: viền vàng nhấp nháy.
##     Chưa mở: hành tinh nhuộm xám, khoá tinh thể.
##     ◀ ▶ đổi thế giới · Đánh / Enter vào. Chạm vòng để chọn, chạm lần nữa (hoặc nút VÀO) để vào.
##     Esc / Menu / nút "◀ MENU" góc trái trên: về màn hình chính (để vào COMBAT hoặc đổi tên).
##     Dưới dải: bảng thông tin thế giới đang chọn (tên, số màn đã qua).
##     Thế giới phụ (WorldData.SIDE_WORLDS): nhánh rẽ nhỏ chéo dưới thế giới cha (Decade: lá thẻ, Zi-O: mặt đồng hồ),
##     ▼ từ thế giới cha xuống nhánh, ▲ về lại. Mở khi đã giải cứu thế giới cha; màn mở theo thế giới đã giải cứu.
##   Bước 2 · màn: lưới dọc 2 ô một hàng, mỗi màn một ô vuông bo góc 1 · 2 · 3 · 4 · B (OOO tới 8 · B).
##     Lưới dài hơn màn hình thì kéo dọc để cuộn. Ô đã qua: viền vàng + dấu ✓. Ô đã mở chưa qua: sáng. Ô chưa mở: xám.
##     ◀ ▶ ▲ ▼ đổi màn · Đánh / Enter vào · Esc / nút "◀ THẾ GIỚI" về bước 1.
##     Bên phải lưới: tên màn, loại màn, món quái có thể rơi (form / item, ✓ nếu đã có).
##     Ô cuối "EX" (màn đặc biệt, mở khi đã giải cứu thế giới): bảng bên phải ghi loại quái đặc biệt, khả năng cần mang
##     và các form người chơi đang có khắc chế được (RiderCaps, tính một lần mỗi khi đổi ô).
## Vẽ bằng _draw như RiderSelect để giữ nét pixel; khung bo tròn vẽ bằng StyleBoxFlat không khử răng cưa.
## Bố cục theo khung 480×270 đặt giữa màn hình (Screen.fit); nền, sao và dải thế giới tràn ra cả màn hình máy.

signal chosen(world: int, stage: int)
signal menu_requested    ## bước 1 bấm Esc / Menu / nút ◀ MENU: về màn hình chính

enum Mode { WORLD, STAGE }

const GOLD := Color(1, 0.85, 0.3)
const SEAL := Color(0.72, 0.4, 1.0)
const LOCKED := Color(0.3, 0.3, 0.38)
const PLANET_LOCKED := Color(0.38, 0.36, 0.48)   ## nhuộm hành tinh bị phong ấn
const BG := Color(0.02, 0.01, 0.07)
const DRAG_START := 6.0          ## kéo quá chừng này (px) thì là kéo, không phải chạm
const FRICTION := 4.0            ## quán tính tắt dần (càng lớn càng nhanh dừng)
const EASE := 10.0               ## tốc độ trượt về vị trí đích khi đổi lựa chọn bằng phím

# Bước 1: dải thế giới
const STRIP_Y := 90.0
const SPACING := 74.0
const ORB_R := 16.0          ## 32 px: khớp cỡ ảnh planets_32
const ORB_R_SEL := 24.0      ## 48 px: planets_48
const INFO := Rect2(90, 150, 300, 66)
# Bước 2: lưới màn (2 cột, cuộn dọc trong GRID_VIEW)
const GRID_VIEW := Rect2(20, 40, 170, 226)
const CELL := 62.0
const CELL_GAP := 10.0
const COLS := 2
const PANEL := Rect2(206, 44, 258, 170)
# Nút dưới cùng
const BUTTON_CENTER := Rect2(185, 236, 110, 26)
const BUTTON := Rect2(340, 228, 110, 30)
const BACK := Rect2(220, 228, 110, 30)
const MENU_BTN := Rect2(8, 8, 66, 20)   ## nút ◀ MENU ở bước 1

const TYPE_NAMES := {0: "Thức tỉnh", 1: "Luyện tập", 2: "Trùm", 3: "Đặc biệt", 4: "Đấu Rider"}
const SIDE_OFFSET := Vector2(37, 30)   ## nhánh rẽ: chéo xuống bên phải thế giới cha, giữa hai hành tinh, dưới đường nối
const SIDE_R := 10.0

var mode := Mode.WORLD
var _world := 0
var _stage := 0
var _t := 0.0
var _scroll := 0.0              ## bước 1: độ cuộn ngang của dải; bước 2: độ cuộn dọc của lưới
var _scroll_target := 0.0
var _easing := false            ## đang trượt về _scroll_target
var _vel := 0.0                 ## vận tốc quán tính sau khi thả tay (px/giây)
var _touching := false
var _dragged := false
var _press_pos := Vector2.ZERO
var _notice := ""
var _notice_time := 0.0
var _sb := StyleBoxFlat.new()
var _counter_key := ""          ## ô EX đã tính danh sách form khắc chế ("thế giới-màn")
var _counter_text := ""


func _init() -> void:
	_sb.anti_aliasing = false
	_sb.corner_detail = 10


## Mở ở bước chọn thế giới, con trỏ ở `world`; `stage` là màn chọn sẵn khi vào thế giới đó.
func open(world: int, stage: int) -> void:
	_world = world if WorldData.is_side(world) and _world_unlocked(world) else clampi(world, 0, _last_world())
	_stage = stage if GameState.is_stage_unlocked(_world, stage) else 0
	mode = Mode.WORLD
	Screen.fit(self)
	visible = true
	_touching = false
	_vel = 0.0
	_notice = ""
	_focus(true)
	queue_redraw()


## Mở thẳng ở bước chọn màn của thế giới `world`, con trỏ ở `stage` (quay lại từ màn chọn Rider / form / item).
func open_at_stage(world: int, stage: int) -> void:
	open(world, stage)
	if _world_unlocked(_world):
		mode = Mode.STAGE
		_focus(true)


## Chọn thẳng một màn (bot test).
func pick(world: int, stage: int) -> void:
	_world = world
	_stage = stage
	_confirm()


func _last_world() -> int:
	return mini(GameState.frontier_world, WorldData.WORLDS.size() - 1)


func _world_count() -> int:
	return WorldData.WORLDS.size()


func _world_unlocked(w: int) -> bool:
	return GameState.is_world_unlocked(w) if WorldData.is_side(w) else w <= _last_world()


## Thế giới chính đứng trên dải ở chỗ của w (thế giới phụ: thế giới cha).
func _strip_index(w: int) -> int:
	return int(WorldData.world_at(w)["parent_world"]) if WorldData.is_side(w) else w


## Màn chọn sẵn khi vào một thế giới: màn xa nhất đã mở nếu là thế giới đang mở dở, không thì màn 1.
## Thế giới phụ: màn đầu tiên đã mở mà chưa qua.
func _default_stage(w: int) -> int:
	if WorldData.is_side(w):
		var stages: Array = WorldData.world_at(w)["stages"]
		for s in stages.size():
			if GameState.is_stage_unlocked(w, s) and not GameState.cleared_stages.has(str(stages[s]["id"])):
				return s
		return 0
	return GameState.frontier_stage if w == GameState.frontier_world else 0


func _stage_count() -> int:
	return (WorldData.world_at(_world)["stages"] as Array).size()


# --- Cuộn ---------------------------------------------------------------------

func _max_scroll() -> float:
	if mode == Mode.WORLD:
		return (_world_count() - 1) * SPACING
	var rows := ceili(_stage_count() / float(COLS))
	return maxf(0.0, rows * CELL + (rows - 1) * CELL_GAP + 2.0 * CELL_GAP - GRID_VIEW.size.y)


## Trượt dải / lưới tới lựa chọn hiện tại (instant: nhảy ngay, dùng khi mở hoặc đổi bước).
func _focus(instant := false) -> void:
	if mode == Mode.WORLD:
		_scroll_target = _strip_index(_world) * SPACING
	else:
		# Chỉ cuộn khi hàng đang chọn khuất khỏi khung lưới
		var row := _stage / COLS
		var top := CELL_GAP + row * (CELL + CELL_GAP)
		_scroll_target = clampf(_scroll, top + CELL + CELL_GAP - GRID_VIEW.size.y, top - CELL_GAP)
	_scroll_target = clampf(_scroll_target, 0.0, _max_scroll())
	_vel = 0.0
	if instant:
		_scroll = _scroll_target
		_easing = false
	else:
		_easing = true


func _process(delta: float) -> void:
	if not visible:
		return
	Screen.fit(self)   # đổi cỡ cửa sổ / xoay máy
	_t += delta
	_notice_time = maxf(0.0, _notice_time - delta)
	if not _touching:
		if _easing:
			_scroll = lerpf(_scroll, _scroll_target, 1.0 - exp(-EASE * delta))
			if absf(_scroll - _scroll_target) < 0.5:
				_scroll = _scroll_target
				_easing = false
		elif absf(_vel) > 1.0:
			_scroll = clampf(_scroll - _vel * delta, 0.0, _max_scroll())
			_vel *= exp(-FRICTION * delta)
	if mode == Mode.WORLD:
		_process_world()
	else:
		_process_stage()
	queue_redraw()


func _process_world() -> void:
	var w := _world
	var at := _strip_index(_world)
	var sides := WorldData.sides_of(at)
	if Input.is_action_just_pressed("move_left"):
		w = maxi(at - 1, 0)
	elif Input.is_action_just_pressed("move_right"):
		w = mini(at + 1, _last_world())
	elif Input.is_action_just_pressed("move_down") and not WorldData.is_side(_world) and not sides.is_empty():
		w = sides[0]
	elif (Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump")) and WorldData.is_side(_world):
		w = at
	elif Input.is_action_just_pressed("attack_light") or Input.is_action_just_pressed("ui_accept"):
		_enter_world()
		return
	elif (Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("ui_cancel")) \
			and not HelpOverlay.is_showing():
		menu_requested.emit()
		return
	if w != _world:
		_set_world(w)


func _process_stage() -> void:
	var s := _stage
	if Input.is_action_just_pressed("move_left"):
		s -= 1
	elif Input.is_action_just_pressed("move_right"):
		s += 1
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump"):
		s -= COLS
	elif Input.is_action_just_pressed("move_down"):
		s += COLS
	elif Input.is_action_just_pressed("attack_light") or Input.is_action_just_pressed("ui_accept"):
		_confirm()
		return
	elif Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("ui_cancel"):
		_back()
		return
	s = clampi(s, 0, _stage_count() - 1)
	while s > 0 and not GameState.is_stage_unlocked(_world, s):
		s -= 1
	if s != _stage:
		_stage = s
		_focus()


func _enter_world() -> void:
	if not _world_unlocked(_world):
		if WorldData.is_side(_world):
			_show_notice("Nhánh rẽ mở khi giải cứu Thế giới %s" % WorldData.WORLDS[_strip_index(_world)]["rider_name"])
		else:
			_show_notice("Thế giới này còn bị phong ấn · qua thế giới trước để mở")
		return
	mode = Mode.STAGE
	_scroll = 0.0
	_focus(true)


## Đổi thế giới ở bước 1: màn chọn sẵn theo thế giới mới.
func _set_world(w: int) -> void:
	if w != _world:
		Sound.sfx("ui_move", 0.0)
	_world = w
	_stage = _default_stage(w) if _world_unlocked(w) else 0
	_notice = ""
	_focus()


func _back() -> void:
	mode = Mode.WORLD
	_focus(true)


func _show_notice(text: String) -> void:
	_notice = text
	_notice_time = 2.0


# --- Chạm / kéo ---------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var wheel := event as InputEventMouseButton
	if wheel and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
		var dir := -1.0 if wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT] else 1.0
		_scroll = clampf(_scroll + dir * (SPACING * 0.5 if mode == Mode.WORLD else CELL * 0.5), 0.0, _max_scroll())
		_easing = false
		_vel = 0.0
		get_viewport().set_input_as_handled()
		return
	var drag := event as InputEventScreenDrag
	if drag and _touching:
		if not _dragged and Screen.local(self, drag.position).distance_to(_press_pos) > DRAG_START:
			_dragged = true
		if _dragged:
			var d := drag.relative.x if mode == Mode.WORLD else drag.relative.y
			_scroll = clampf(_scroll - d, 0.0, _max_scroll())
			var v := (drag.velocity.x if mode == Mode.WORLD else drag.velocity.y)
			_vel = v
			_easing = false
		get_viewport().set_input_as_handled()
		return
	var touch := event as InputEventScreenTouch
	if touch == null:
		return
	get_viewport().set_input_as_handled()
	if touch.pressed:
		_touching = true
		_dragged = false
		_press_pos = Screen.local(self, touch.position)
		_vel = 0.0
		_easing = false
		return
	_touching = false
	if _dragged:
		return
	_vel = 0.0
	_tap(Screen.local(self, touch.position))


func _tap(p: Vector2) -> void:
	if mode == Mode.WORLD:
		if MENU_BTN.has_point(p):
			menu_requested.emit()
			return
		if BUTTON_CENTER.has_point(p):
			_enter_world()
			return
		for w in _side_indices():
			if _side_pos(w).distance_to(p) <= SIDE_R + 6.0:
				if w == _world:
					_enter_world()
				else:
					_set_world(w)
				return
		for w in _world_count():
			if _orb_pos(w).distance_to(p) <= ORB_R_SEL + 4.0:
				if w == _world:
					_enter_world()
				else:
					_set_world(w)
				return
		return
	if BACK.has_point(p):
		_back()
		return
	if BUTTON.has_point(p):
		_confirm()
		return
	if not GRID_VIEW.has_point(p):
		return
	for s in _stage_count():
		if _cell_rect(s).has_point(p):
			if not GameState.is_stage_unlocked(_world, s):
				_show_notice("Màn chưa mở · giải cứu thế giới của Rider này để mở" if WorldData.is_side(_world)
					else "Màn chưa mở · qua màn trước để mở")
			elif s == _stage:
				_confirm()
			else:
				_stage = s
				_focus()
			return


func _confirm() -> void:
	if not GameState.is_stage_unlocked(_world, _stage):
		return
	visible = false
	Sound.sfx("ui_ok", 0.0)
	chosen.emit(_world, _stage)


# --- Vị trí -------------------------------------------------------------------

## Tâm vòng tròn của thế giới w trên dải (cuộn ngang, thế giới đang chọn ở giữa màn hình).
func _orb_pos(w: int) -> Vector2:
	return Vector2(size.x / 2.0 + w * SPACING - _scroll, STRIP_Y + sin(w * 1.3) * 8.0)


## Chỉ số mọi thế giới phụ (sau WORLDS).
func _side_indices() -> Array[int]:
	var out: Array[int] = []
	for k in WorldData.SIDE_WORLDS.size():
		out.append(WorldData.WORLDS.size() + k)
	return out


## Tâm biểu tượng nhánh rẽ (thế giới phụ w) dưới thế giới cha.
func _side_pos(w: int) -> Vector2:
	return _orb_pos(_strip_index(w)) + SIDE_OFFSET


func _cell_rect(s: int) -> Rect2:
	var grid_w := COLS * CELL + (COLS - 1) * CELL_GAP
	var x0 := GRID_VIEW.position.x + (GRID_VIEW.size.x - grid_w) / 2.0
	var col := s % COLS
	var row := s / COLS
	return Rect2(x0 + col * (CELL + CELL_GAP), GRID_VIEW.position.y + CELL_GAP + row * (CELL + CELL_GAP) - _scroll,
		CELL, CELL)


# --- Vẽ -----------------------------------------------------------------------

func _draw() -> void:
	var full := Screen.bleed(self)
	draw_rect(full, BG)
	EarthMap.draw_stars(self, full, _t, 60)
	if mode == Mode.WORLD:
		_draw_worlds()
	else:
		_draw_stages()
	if _notice_time > 0.0 and _notice != "":
		var a := minf(1.0, _notice_time * 2.0)
		_round(Rect2(60, 4, 360, 16), Color(0.3, 0.05, 0.1, 0.9 * a), 8, Color(1, 0.5, 0.45, a), 1)
		_text(Vector2(60, 15), _notice, 7, Color(1, 0.85, 0.8, a), 360)


# --- Bước 1: thế giới ---------------------------------------------------------

func _draw_worlds() -> void:
	_text(Vector2(0, 18), "CHỌN THẾ GIỚI", 11, Color(1, 0.9, 0.5), size.x)
	var saved := mini(GameState.worlds_cleared, _world_count())
	_text(Vector2(0, 30), "Trái Đất đã giải cứu: %d / %d · kéo để xem" % [saved, _world_count()], 7,
		Color(0.8, 0.8, 0.92), size.x)
	var frontier := GameState.frontier_world
	var full := Screen.bleed(self)   # dải thế giới trải hết bề ngang màn hình
	# Đường nối: vàng giữa hai thế giới đã qua, xích tinh thể tím tới các thế giới chưa mở
	for w in _world_count() - 1:
		var a := _orb_pos(w)
		var b := _orb_pos(w + 1)
		if b.x < full.position.x - SPACING or a.x > full.end.x + SPACING:
			continue
		if w + 1 <= frontier:
			draw_line(a, b, GOLD.darkened(0.15), 3.0)
		else:
			var links := int(a.distance_to(b) / 8.0)
			for j in range(1, links):
				var p := a.lerp(b, float(j) / float(links))
				_diamond(p, 2.5, Color(SEAL, 0.45 + 0.35 * sin(_t * 3.0 + float(j + w * 3))))
	for w in _side_indices():
		var p := _side_pos(w)
		if p.x < full.position.x - SPACING or p.x > full.end.x + SPACING:
			continue
		_draw_side(w, p)
	for w in _world_count():
		var p := _orb_pos(w)
		if p.x < full.position.x - ORB_R_SEL * 2.0 or p.x > full.end.x + ORB_R_SEL * 2.0:
			continue
		_draw_orb(w, p)
	# Mép trái / phải mờ dần và mũi tên báo còn thế giới
	for i in 16:
		var a := 0.9 * (1.0 - i / 16.0)
		draw_rect(Rect2(full.position.x + i * 2, 40, 2, 100), Color(BG, a))
		draw_rect(Rect2(full.end.x - 2 - i * 2, 40, 2, 100), Color(BG, a))
	if _scroll > 1.0:
		_text(Vector2(full.position.x + 4, STRIP_Y + 4), "◀", 10, Color(GOLD, 0.6 + 0.4 * sin(_t * 4.0)), 16)
	if _scroll < _max_scroll() - 1.0:
		_text(Vector2(full.end.x - 20, STRIP_Y + 4), "▶", 10, Color(GOLD, 0.6 + 0.4 * sin(_t * 4.0)), 16)
	_draw_world_info()
	_text(Vector2(0, 230), "◀ ▶ / kéo: chọn thế giới · chạm lần nữa / Đánh / Enter: vào", 7, Color(0.7, 0.7, 0.8),
		size.x)
	_pill(MENU_BTN, "◀ MENU", Color(0.25, 0.25, 0.35, 0.95))
	_pill(BUTTON_CENTER, "VÀO" if _world_unlocked(_world) else "BỊ KHOÁ",
		Color(0.85, 0.22, 0.25, 0.95) if _world_unlocked(_world) else Color(0.25, 0.25, 0.32, 0.95))


## Nhánh rẽ: nối xuống từ thế giới cha, biểu tượng lá thẻ (Decade) hoặc mặt đồng hồ (Zi-O). Khoá: nhuộm xám + khoá tím.
func _draw_side(w: int, p: Vector2) -> void:
	var world := WorldData.world_at(w)
	var col := WorldData.rider_color(world["rider"])
	var open := _world_unlocked(w)
	var sel := w == _world
	var parent := _orb_pos(_strip_index(w))
	var top := parent + (p - parent).normalized() * (ORB_R + 2.0)
	var end := p - (p - parent).normalized() * SIDE_R
	if open:
		draw_line(top, end, Color(GOLD, 0.7), 2.0)
	else:
		for j in range(1, 4):
			_diamond(top.lerp(end, j / 4.0), 2.0, Color(SEAL, 0.6))
	var body := col if open else PLANET_LOCKED
	if sel:
		draw_circle(p, SIDE_R + 5.0, Color(GOLD, 0.25 + 0.15 * sin(_t * 4.0)))
	if str(world["rider"]) == "decade":
		var card := Rect2(p - Vector2(7, SIDE_R), Vector2(14, SIDE_R * 2.0))
		_round(card, body.darkened(0.35), 2, GOLD if sel else body.lightened(0.3), 1)
		for i in 3:
			draw_rect(Rect2(card.position.x + 3, card.position.y + 4 + i * 4, 8, 2), body.lightened(0.4))
	else:
		draw_circle(p, SIDE_R, body.darkened(0.35))
		draw_arc(p, SIDE_R, 0.0, TAU, 32, GOLD if sel else body.lightened(0.3), 1.5)
		var a := _t * 1.5
		draw_line(p, p + Vector2(sin(a), -cos(a)) * (SIDE_R - 3.0), Color.WHITE, 1.0)
		draw_line(p, p + Vector2(0, -SIDE_R * 0.5), body.lightened(0.5), 1.5)
	if not open:
		_diamond(p, 4.0, SEAL)
	elif _side_has_new(w):
		var pulse := 0.5 + 0.5 * sin(_t * 5.0)
		draw_circle(p + Vector2(SIDE_R, -SIDE_R), 3.0, Color(1, 0.4, 0.3, 0.6 + 0.4 * pulse))


## Thế giới phụ còn màn đã mở mà chưa qua (chấm đỏ báo mới).
func _side_has_new(w: int) -> bool:
	var stages: Array = WorldData.world_at(w)["stages"]
	for s in stages.size():
		if GameState.is_stage_unlocked(w, s) and not GameState.cleared_stages.has(str(stages[s]["id"])):
			return true
	return false


## Dòng tiêu đề của thế giới: "THẾ GIỚI N · RIDER", thế giới phụ dùng "title" của nó.
func _world_title(world: Dictionary) -> String:
	if world.get("side", false):
		return "%s · %s" % [world["title"], str(world["name"]).to_upper()]
	return "THẾ GIỚI %d · %s" % [int(world["number"]), str(world["rider_name"]).to_upper()]


func _draw_orb(w: int, p: Vector2) -> void:
	var world: Dictionary = WorldData.WORLDS[w]
	var col := WorldData.rider_color(world["rider"])
	var open := _world_unlocked(w)
	var done := w < GameState.frontier_world
	var sel := w == _world
	var r := ORB_R_SEL if sel else ORB_R
	# Quầng khí quyển màu Rider phía sau hành tinh
	if open:
		draw_circle(p, r + 5.0, Color(col, 0.16 if sel else 0.1))
		draw_circle(p, r + 2.0, Color(col, 0.28 if sel else 0.18))
	if open and w == GameState.frontier_world:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_arc(p, r + 5.0 + pulse * 2.0, 0.0, TAU, 48, Color(GOLD, 0.4 + 0.5 * pulse), 1.5)
	Planet.draw(self, p, r, w, _t, Color.WHITE if open else PLANET_LOCKED)
	if sel:
		draw_arc(p, r + 2.0, 0.0, TAU, 48, GOLD, 1.5)
	if not open:
		_diamond(p, 6.0, SEAL)
		_diamond(p, 3.0, Color(0.95, 0.8, 1.0))
	# Huy hiệu số thế giới ở góc trên phải
	var b := p + Vector2(r * 0.72, -r * 0.72)
	draw_circle(b, 7.0, GOLD if done else (col.darkened(0.2) if open else Color(0.2, 0.2, 0.26)))
	draw_arc(b, 7.0, 0.0, TAU, 24, Color(0.05, 0.03, 0.1), 1.0)
	draw_string(ThemeDB.fallback_font, b + Vector2(-7, 3), str(int(world["number"])), HORIZONTAL_ALIGNMENT_CENTER, 14,
		7, Color(0.2, 0.12, 0.02) if done else (Color.WHITE if open else Color(0.55, 0.55, 0.65)))
	var name_col := (Color.WHITE if sel else Color(0.85, 0.85, 0.95)) if open else Color(0.5, 0.5, 0.6)
	_text(Vector2(p.x - 36, p.y + r + 15), str(world["rider_name"]), 7, name_col, 72)
	_text(Vector2(p.x - 36, p.y + r + 24), str(world["year"]), 6, Color(name_col, 0.7), 72)


func _draw_world_info() -> void:
	var world: Dictionary = WorldData.world_at(_world)
	var side: bool = world.get("side", false)
	var col := WorldData.rider_color(world["rider"])
	var open := _world_unlocked(_world)
	_round(INFO, Color(0.08, 0.07, 0.15, 0.95), 10, col.lightened(0.2) if open else LOCKED, 1)
	_text(Vector2(INFO.position.x, INFO.position.y + 15), _world_title(world), 10,
		col.lightened(0.4) if open else Color(0.6, 0.6, 0.7), INFO.size.x)
	var sub := str(world["motto"]) if side else str(world["name"])
	_text(Vector2(INFO.position.x, INFO.position.y + 28), sub if open or side else "??? · bị phong ấn", 7,
		Color(0.8, 0.8, 0.9), INFO.size.x)
	var stages: Array = world["stages"]
	var cleared := 0
	for s in stages.size():
		cleared += int(GameState.cleared_stages.has(str(stages[s]["id"])))
	# Mỗi màn một ô nhỏ bo góc: vàng = đã qua, màu Rider = đã mở, xám = chưa mở
	var dot := 9.0
	var gap := 4.0
	var total := stages.size() * dot + (stages.size() - 1) * gap
	var x0 := INFO.position.x + (INFO.size.x - total) / 2.0
	for s in stages.size():
		var done := GameState.cleared_stages.has(str(stages[s]["id"]))
		var c := GOLD if done else (col.darkened(0.2) if GameState.is_stage_unlocked(_world, s) else LOCKED)
		_round(Rect2(x0 + s * (dot + gap), INFO.position.y + 36, dot, dot), c, 3)
	var status := "Đã giải cứu" if _world < GameState.frontier_world else ("Đang tới" if open else "Chưa mở")
	if side:
		status = "Nhánh rẽ · ▲ về thế giới chính" if open else "Mở khi giải cứu Thế giới %s" % \
			WorldData.WORLDS[_strip_index(_world)]["rider_name"]
	_text(Vector2(INFO.position.x, INFO.position.y + 59), "%s · %d / %d màn" % [status, cleared, stages.size()], 7,
		GOLD if cleared == stages.size() else Color(0.8, 0.8, 0.88), INFO.size.x)


# --- Bước 2: màn --------------------------------------------------------------

func _draw_stages() -> void:
	var world: Dictionary = WorldData.world_at(_world)
	var col := WorldData.rider_color(world["rider"])
	var stages: Array = world["stages"]
	for s in stages.size():
		var r := _cell_rect(s)
		if r.end.y < GRID_VIEW.position.y or r.position.y > GRID_VIEW.end.y:
			continue
		_draw_cell(s, stages[s], r, col)
	# Che phần lưới tràn ra ngoài khung (trên tiêu đề, dưới đáy màn hình) và làm mờ mép
	var full := Screen.bleed(self)
	draw_rect(Rect2(full.position.x, full.position.y, full.size.x, GRID_VIEW.position.y - full.position.y), BG)
	draw_rect(Rect2(full.position.x, GRID_VIEW.end.y, full.size.x, full.end.y - GRID_VIEW.end.y), BG)
	for i in 5:
		var a := 0.85 * (1.0 - i / 5.0)
		draw_rect(Rect2(GRID_VIEW.position.x, GRID_VIEW.position.y + i * 2, GRID_VIEW.size.x, 2), Color(BG, a))
		draw_rect(Rect2(GRID_VIEW.position.x, GRID_VIEW.end.y - 2 - i * 2, GRID_VIEW.size.x, 2), Color(BG, a))
	if _max_scroll() > 0.0:
		# Thanh cuộn mảnh bên phải lưới
		var track := Rect2(GRID_VIEW.end.x - 6, GRID_VIEW.position.y + 6, 3, GRID_VIEW.size.y - 12)
		_round(track, Color(1, 1, 1, 0.08), 1)
		var frac := GRID_VIEW.size.y / (GRID_VIEW.size.y + _max_scroll())
		var h := track.size.y * frac
		var y := track.position.y + (track.size.y - h) * (_scroll / _max_scroll())
		_round(Rect2(track.position.x, y, 3, h), Color(GOLD, 0.6), 1)
	_text(Vector2(0, 16), _world_title(world), 10, col.lightened(0.35), size.x)
	_text(Vector2(0, 29), str(world["motto"] if world.get("side", false) else world["name"]), 7, Color(0.8, 0.8, 0.9),
		size.x)
	_draw_info()
	_pill(BACK, "◀ THẾ GIỚI", Color(0.25, 0.25, 0.35, 0.95))
	_pill(BUTTON, "VÀO", Color(0.85, 0.22, 0.25, 0.95))
	_text(Vector2(PANEL.position.x, 268), "◀ ▶ ▲ ▼ chọn màn · Đánh / Enter: vào · Esc: thế giới", 6,
		Color(0.65, 0.65, 0.75), PANEL.size.x)


func _draw_cell(s: int, stage: Dictionary, r: Rect2, col: Color) -> void:
	var open := GameState.is_stage_unlocked(_world, s)
	var cleared := GameState.cleared_stages.has(str(stage["id"]))
	var sel := s == _stage
	var fill := col.darkened(0.45) if open else Color(0.13, 0.13, 0.17)
	if sel:
		fill = col.darkened(0.25)
		_round(r.grow(3), Color(GOLD, 0.2 + 0.1 * sin(_t * 4.0)), 14)
	var border := Color(1, 0.97, 0.8) if sel else (Color(GOLD, 0.55) if cleared else (col.lightened(0.1) if open else LOCKED))
	_round(r, fill, 12, border, 2 if sel else 1)
	var label: String = str(stage["id"]).get_slice("-", 1) if open else "—"
	_text(Vector2(r.position.x, r.position.y + 34), label, 18,
		Color(1, 0.9, 0.5) if cleared else (Color.WHITE if open else Color(0.45, 0.45, 0.52)), r.size.x)
	var kind: String = stage.get("foe_name", TYPE_NAMES.get(int(stage["type"]), ""))   # màn đấu Rider: tên đối thủ
	_text(Vector2(r.position.x, r.position.y + 50), kind if open else "khoá", 6,
		Color(0.8, 0.8, 0.9) if open else Color(0.45, 0.45, 0.52), r.size.x)
	if cleared:
		var b := Vector2(r.end.x - 15, r.position.y + 4)
		_round(Rect2(b, Vector2(11, 11)), GOLD, 5)
		draw_polyline(PackedVector2Array([b + Vector2(3, 5.5), b + Vector2(5, 7.5), b + Vector2(8.5, 3.5)]),
			Color(0.2, 0.12, 0.02), 1.5)


## Thông tin màn đang chọn: tên, loại màn, món quái rơi.
func _draw_info() -> void:
	var world: Dictionary = WorldData.world_at(_world)
	var stage: Dictionary = world["stages"][_stage]
	var rider: StringName = world["rider"]
	var col := WorldData.rider_color(rider)
	_round(PANEL, Color(0.08, 0.07, 0.15, 0.95), 12, col.lightened(0.15), 1)
	var x := PANEL.position.x
	var w := PANEL.size.x
	_text(Vector2(x, PANEL.position.y + 34), "MÀN %s" % stage["id"], 20, GOLD, w)
	_text(Vector2(x, PANEL.position.y + 54), str(stage["name"]), 9, Color(0.92, 0.95, 1.0), w)
	var badge := TYPE_NAMES.get(int(stage["type"]), "") as String
	var bw := 70.0
	_round(Rect2(x + (w - bw) / 2.0, PANEL.position.y + 62, bw, 14), col.darkened(0.3), 7, col.lightened(0.3), 1)
	_text(Vector2(x + (w - bw) / 2.0, PANEL.position.y + 72), badge, 7, Color.WHITE, bw)
	var drop := ""
	if int(stage["type"]) == WorldData.StageType.AWAKEN:
		drop = "Quái rơi: %s%s" % [world["driver_name"], " ✓" if GameState.is_active(rider) else ""]
	elif int(stage["type"]) == WorldData.StageType.DUEL:
		drop = "Thắng %s: %s%s" % [stage["boss"]["name"], stage["form_name"],
			" ✓" if GameState.owns_form(rider, stage["form"]) else ""]
	elif stage.has("form"):
		var kind := "item" if GameState.is_item(rider, stage["form"]) else "form"
		drop = "Quái rơi %s: %s%s" % [kind, stage["form_name"], " ✓" if GameState.has_form(rider, stage["form"]) else ""]
	elif int(stage["type"]) == WorldData.StageType.BOSS:
		drop = "Trùm: %s" % stage["boss"]["name"]
	var y := PANEL.position.y + 98
	if stage.has("special"):
		y = _draw_special(stage, x, w, y - 8.0)
	if drop != "":
		_text(Vector2(x + 8, y), drop, 8, Color(1, 0.85, 0.4), w - 16)
		y += 14
	if int(stage["type"]) == WorldData.StageType.BOSS:
		_text(Vector2(x + 8, y), "Hạ trùm rơi: %s" % world["next_driver_name"], 8, Color(1, 0.85, 0.4), w - 16)
		y += 14
	if int(stage["type"]) == WorldData.StageType.DUEL and not GameState.is_stage_unlocked(_world, _stage):
		_text(Vector2(x + 8, y), "Mở khi giải cứu Thế giới %s" % WorldData.WORLDS[int(stage["source_world"])]["rider_name"],
			8, Color(0.75, 0.75, 0.85), w - 16)
		y += 14
	if GameState.cleared_stages.has(str(stage["id"])):
		_text(Vector2(x, y), "✓ Đã qua màn này", 8, GOLD, w)
		y += 14
	_text(Vector2(x, PANEL.end.y - 10), "Diệt hết quái mới qua màn", 7, Color(0.7, 0.7, 0.8), w)


## Màn EX: cần khả năng gì, form nào đang có khắc chế được. Trả về y của dòng kế tiếp.
func _draw_special(stage: Dictionary, x: float, w: float, y: float) -> float:
	var special: StringName = stage["special"]
	if not GameState.is_stage_unlocked(_world, _stage):
		_text(Vector2(x + 8, y), "Mở khi giải cứu thế giới này", 8, Color(0.75, 0.75, 0.85), w - 16)
		return y + 14
	_text(Vector2(x + 8, y), "Cần: %s" % Enemy.SPECIALS[special]["need"], 8, Color(1, 0.85, 0.4), w - 16)
	var key := "%d-%d" % [_world, _stage]
	if key != _counter_key:
		_counter_key = key
		var names := RiderCaps.owned_counters(special)
		_counter_text = "Đang có: %s" % ", ".join(names) if not names.is_empty() else "Chưa có form khắc chế"
	_text(Vector2(x + 8, y + 13), _counter_text, 7,
		Color(0.7, 1, 0.75) if _counter_text.begins_with("Đang") else Color(1, 0.55, 0.5), w - 16)
	if not GameState.cleared_stages.has(str(stage["id"])):
		_text(Vector2(x + 8, y + 25), "Qua lần đầu: +%d Mảnh Ký Ức" % GameState.CHALLENGE_FRAGMENTS, 7,
			Color(0.8, 0.8, 0.9), w - 16)
		return y + 38
	return y + 26


# --- Hình cơ bản --------------------------------------------------------------

## Khung chữ nhật bo góc (dùng chung một StyleBoxFlat, lệnh vẽ được ghi ngay nên đổi thông số giữa các lần vẽ được).
func _round(r: Rect2, fill: Color, radius: int, border := Color.TRANSPARENT, border_width := 0) -> void:
	_sb.bg_color = fill
	_sb.set_corner_radius_all(radius)
	_sb.border_color = border
	_sb.set_border_width_all(border_width)
	draw_style_box(_sb, r)


## Nút bo tròn hai đầu.
func _pill(r: Rect2, label: String, fill: Color) -> void:
	_round(r, fill, int(r.size.y / 2.0), GOLD, 1)
	_text(Vector2(r.position.x, r.position.y + r.size.y / 2.0 + 4.0), label, 9, Color.WHITE, r.size.x)


func _diamond(p: Vector2, r: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.7, 0), p + Vector2(0, r),
		p + Vector2(-r * 0.7, 0)]), color)


func _text(pos: Vector2, text: String, font_size: int, color: Color, width: float) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 3, Color(0, 0, 0, color.a))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
