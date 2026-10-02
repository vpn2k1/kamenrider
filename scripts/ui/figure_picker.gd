extends Control
class_name FigurePicker
## Nền chung của các màn chọn trước khi vào màn / trận: RiderSelect (Rider), FormSelect (form biến đổi),
## ItemSelect (item / vũ khí, chọn nhiều).
##   - Mỗi lựa chọn là hình nhân vật đang thở (animation idle trong player_frames.tres) đứng trên bục màu Rider,
##     tên dưới chân. Lựa chọn đang xem được rọi đèn vàng, các hình khác tối đi.
##   - Chạm hình (hoặc ◀ ▶) để xem thông số ở bảng dưới: tên, mô tả, 5 thanh chỉ số, các dòng thông tin thêm.
##   - Nút xác nhận bo tròn ở góc dưới phải. Chọn nhiều (multi): nút "mang theo" bật / tắt món đang xem,
##     chạm lần nữa vào hình cũng bật / tắt; huy hiệu ✓ trên đầu món đã chọn.
##   - Nhiều lựa chọn hơn bề ngang màn hình thì kéo ngang / lăn chuột để cuộn (có quán tính).
## Lớp con điền `entries` rồi gọi _show(); ghi đè _on_confirm().
##   entry = {"id", "name", "sub" (dòng nhỏ dưới tên), "prefix" (tiền tố animation), "fallback" (tiền tố dự phòng),
##            "color", "stats" ({} = không có thanh chỉ số), "lines" (các dòng thông tin), "tag" (dòng vàng, tùy chọn)}
## Bàn phím: ◀ ▶ xem · Đánh (J): chọn nhiều thì bật / tắt, không thì xác nhận · Enter: xác nhận.

const FRAMES := preload("res://art/characters/player_frames.tres")
const STAT_MAX := {"hp": 220.0, "armor": 60.0, "speed": 180.0, "atk": 1.6, "jump": 1.4}
const STAT_ROWS := [["hp", "Máu"], ["armor", "Giáp"], ["speed", "Tốc độ"], ["atk", "Sức đánh"], ["jump", "Nhảy"]]
const GOLD := Color(1, 0.85, 0.3)
const BG := Color(0.02, 0.01, 0.07)
const SLOT := 80.0              ## khoảng cách giữa hai hình
const EDGE := 44.0              ## lề trái / phải của hàng hình khi phải cuộn
const FEET := 126.0             ## chân nhân vật
const FIG := 68.0               ## khung hình nhân vật (px)
const PANEL := Rect2(12, 158, 336, 106)
const CONFIRM := Rect2(358, 226, 112, 32)
const TOGGLE := Rect2(358, 186, 112, 28)
const DRAG_START := 6.0
const FRICTION := 4.0
const EASE := 10.0

var entries: Array = []
var index := 0
var multi := false
var max_pick := 1
var picked: Array[int] = []      ## multi: chỉ số các lựa chọn đang bật
var title := ""
var subtitle := ""
var hint := ""
var confirm_text := "CHỌN"
var on_text := "✓ MANG THEO"
var off_text := "MANG THEO"

var _t := 0.0
var _scroll := 0.0
var _scroll_target := 0.0
var _easing := false
var _vel := 0.0
var _touching := false
var _dragged := false
var _press_pos := Vector2.ZERO
var _sb := StyleBoxFlat.new()


func _init() -> void:
	_sb.anti_aliasing = false
	_sb.corner_detail = 10


## Hiện màn chọn (lớp con gọi sau khi điền entries / index / picked).
func _show() -> void:
	index = clampi(index, 0, maxi(entries.size() - 1, 0))
	Screen.fit(self)   # khung 480×270 giữa màn hình, nền tràn ra cả màn hình máy
	visible = true
	_touching = false
	_vel = 0.0
	_focus(true)
	queue_redraw()


## Lớp con ghi đè: phát tín hiệu kết quả. Lớp nền đã ẩn màn và phát tiếng.
func _on_confirm() -> void:
	pass


func _confirm() -> void:
	if entries.is_empty():
		return
	Sound.sfx("ui_ok", 0.0)
	visible = false
	_on_confirm()


func _toggle(i: int) -> void:
	if picked.has(i):
		picked.erase(i)
	elif max_pick == 1:
		picked = [i]
	elif picked.size() < max_pick:
		picked.append(i)
	Sound.sfx("ui_move", 0.0)


func _select(i: int) -> void:
	if i == index:
		return
	index = i
	Sound.sfx("ui_move", 0.0)
	_focus()


# --- Cuộn ---------------------------------------------------------------------

func _fits() -> bool:
	return (entries.size() - 1) * SLOT + 2.0 * EDGE <= size.x


func _max_scroll() -> float:
	return 0.0 if _fits() else (entries.size() - 1) * SLOT + 2.0 * EDGE - size.x


func _figure_x(i: int) -> float:
	if _fits():
		return (size.x - (entries.size() - 1) * SLOT) / 2.0 + i * SLOT
	return EDGE + i * SLOT - _scroll


## Trượt hàng hình để lựa chọn đang xem nằm giữa màn hình.
func _focus(instant := false) -> void:
	_scroll_target = clampf(EDGE + index * SLOT - size.x / 2.0, 0.0, _max_scroll())
	_vel = 0.0
	if instant:
		_scroll = _scroll_target
		_easing = false
	else:
		_easing = true


func _process(delta: float) -> void:
	if not visible or entries.is_empty():
		return
	Screen.fit(self)
	_t += delta
	if not _touching:
		if _easing:
			_scroll = lerpf(_scroll, _scroll_target, 1.0 - exp(-EASE * delta))
			if absf(_scroll - _scroll_target) < 0.5:
				_scroll = _scroll_target
				_easing = false
		elif absf(_vel) > 1.0:
			_scroll = clampf(_scroll - _vel * delta, 0.0, _max_scroll())
			_vel *= exp(-FRICTION * delta)
	if Input.is_action_just_pressed("move_left"):
		_select(maxi(index - 1, 0))
	elif Input.is_action_just_pressed("move_right"):
		_select(mini(index + 1, entries.size() - 1))
	elif Input.is_action_just_pressed("ui_accept"):
		_confirm()
		return
	elif Input.is_action_just_pressed("attack_light"):
		if multi:
			_toggle(index)
		else:
			_confirm()
			return
	queue_redraw()


# --- Chạm / kéo ---------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var wheel := event as InputEventMouseButton
	if wheel and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
		var dir := -1.0 if wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT] else 1.0
		_scroll = clampf(_scroll + dir * SLOT * 0.5, 0.0, _max_scroll())
		_easing = false
		_vel = 0.0
		get_viewport().set_input_as_handled()
		return
	var drag := event as InputEventScreenDrag
	if drag and _touching:
		if not _dragged and Screen.local(self, drag.position).distance_to(_press_pos) > DRAG_START \
				and _press_pos.y < PANEL.position.y:
			_dragged = true
		if _dragged:
			_scroll = clampf(_scroll - drag.relative.x, 0.0, _max_scroll())
			_vel = drag.velocity.x
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
	if CONFIRM.has_point(p):
		_confirm()
		return
	if multi and TOGGLE.has_point(p):
		_toggle(index)
		return
	for i in entries.size():
		if _figure_rect(i).has_point(p):
			if i == index:
				if multi:
					_toggle(i)
			else:
				_select(i)
			return


## Vùng chạm của một hình: cả thân và tên dưới chân.
func _figure_rect(i: int) -> Rect2:
	return Rect2(_figure_x(i) - SLOT / 2.0 + 2.0, FEET - FIG + 4.0, SLOT - 4.0, FIG + 26.0)


# --- Vẽ -----------------------------------------------------------------------

func _draw() -> void:
	var full := Screen.bleed(self)
	draw_rect(full, BG)
	EarthMap.draw_stars(self, full, _t, 50)
	# Sàn sân khấu (trải hết bề ngang màn hình)
	draw_rect(Rect2(full.position.x, FEET + 2.0, full.size.x, PANEL.position.y - FEET - 2.0), Color(0.07, 0.05, 0.14))
	draw_line(Vector2(full.position.x, FEET + 2.0), Vector2(full.end.x, FEET + 2.0), Color(0.3, 0.26, 0.5), 1.0)
	if entries.is_empty():
		return
	for i in entries.size():
		var x := _figure_x(i)
		if x < -SLOT or x > size.x + SLOT:
			continue
		_draw_figure(i, x)
	_text(Vector2(0, 14), title, 10, Color(1, 0.9, 0.5), size.x)
	_text(Vector2(0, 26), subtitle, 7, Color(0.85, 0.85, 0.95), size.x)
	if not _fits():
		var a := 0.6 + 0.4 * sin(_t * 4.0)
		if _scroll > 1.0:
			_text(Vector2(2, FEET - 30.0), "◀", 10, Color(GOLD, a), 14)
		if _scroll < _max_scroll() - 1.0:
			_text(Vector2(size.x - 16.0, FEET - 30.0), "▶", 10, Color(GOLD, a), 14)
		_text(Vector2(size.x - 70.0, 14), "%d / %d" % [index + 1, entries.size()], 7, GOLD, 60)
	_draw_panel(entries[index])
	if multi:
		var on := picked.has(index)
		_pill(TOGGLE, on_text if on else off_text, Color(0.75, 0.55, 0.12, 0.95) if on else Color(0.25, 0.25, 0.35, 0.95),
			8)
		_text(Vector2(TOGGLE.position.x, TOGGLE.position.y - 5.0), "đã chọn %d / %d" % [picked.size(), max_pick], 7,
			Color(0.85, 0.85, 0.95), TOGGLE.size.x)
	_pill(CONFIRM, confirm_text, Color(0.85, 0.22, 0.25, 0.95), 10)
	if hint != "":
		_text(Vector2(0, 36), hint, 6, Color(0.7, 0.7, 0.8), size.x)


func _draw_figure(i: int, x: float) -> void:
	var e: Dictionary = entries[i]
	var col: Color = e.get("color", Color.WHITE)
	var sel := i == index
	var on := multi and picked.has(i)
	# Đèn rọi và bục dưới chân
	if sel:
		var cone := PackedVector2Array([Vector2(x - 8, 30), Vector2(x + 8, 30), Vector2(x + 34, FEET),
			Vector2(x - 34, FEET)])
		draw_colored_polygon(cone, Color(1, 0.9, 0.55, 0.07 + 0.02 * sin(_t * 3.0)))
	_ellipse(Vector2(x, FEET + 2.0), Vector2(30, 6), Color(GOLD, 0.35) if sel else Color(col, 0.22))
	_ellipse(Vector2(x, FEET + 2.0), Vector2(22, 4), col.darkened(0.2) if sel else col.darkened(0.55))
	# Hình nhân vật: animation idle; chưa có hình thì dùng hình dự phòng nhuộm màu Rider
	var anim := "%s_idle" % e.get("prefix", "")
	var tint := Color.WHITE if sel else Color(0.55, 0.55, 0.65)
	if not FRAMES.has_animation(anim):
		anim = "%s_idle" % e.get("fallback", "human")
		tint = tint * Color(col.lightened(0.3), 1.0)
		if not FRAMES.has_animation(anim):
			anim = "human_idle"
	var count := FRAMES.get_frame_count(anim)
	if count > 0:
		var frame := int(_t * FRAMES.get_animation_speed(anim) + i * 3) % count
		var tex := FRAMES.get_frame_texture(anim, frame)
		draw_texture_rect(tex, Rect2(Vector2(roundf(x - FIG / 2.0), FEET - FIG), Vector2(FIG, FIG)), false, tint)
	# Tên dưới chân
	var name_col := Color.WHITE if sel else Color(0.72, 0.72, 0.8)
	_text(Vector2(x - SLOT / 2.0, FEET + 14.0), str(e.get("name", "")), 7, GOLD if sel else name_col, SLOT)
	var sub := str(e.get("sub", ""))
	if sub != "":
		_text(Vector2(x - SLOT / 2.0, FEET + 23.0), sub, 6, Color(name_col, 0.75), SLOT)
	if on:
		var b := Vector2(x + 16.0, FEET - FIG + 8.0)
		draw_circle(b, 6.0, GOLD)
		draw_polyline(PackedVector2Array([b + Vector2(-3, 0), b + Vector2(-1, 2), b + Vector2(3, -2)]),
			Color(0.2, 0.12, 0.02), 1.5)


## Bảng thông số của lựa chọn đang xem.
func _draw_panel(e: Dictionary) -> void:
	var col: Color = e.get("color", Color.WHITE)
	_round(PANEL, Color(0.08, 0.07, 0.15, 0.96), 10, col.lightened(0.15), 1)
	var x := PANEL.position.x + 10.0
	var y := PANEL.position.y
	var font := ThemeDB.fallback_font
	draw_string_outline(font, Vector2(x, y + 15), str(e.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, 200, 10, 3,
		Color.BLACK)
	draw_string(font, Vector2(x, y + 15), str(e.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, 200, 10, col.lightened(0.4))
	var sub := str(e.get("sub", ""))
	if sub != "":
		draw_string(font, Vector2(PANEL.end.x - 130.0, y + 14), sub, HORIZONTAL_ALIGNMENT_RIGHT, 120, 7, GOLD)
	var lines: Array = e.get("lines", [])
	var stats: Dictionary = e.get("stats", {})
	var ly := y + 27.0
	if not lines.is_empty():
		draw_string(font, Vector2(x, ly), str(lines[0]), HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 20.0, 7,
			Color(0.85, 0.85, 0.92))
		ly += 11.0
	if not stats.is_empty():
		# 5 thanh chỉ số, hai cột
		for k in STAT_ROWS.size():
			var key: String = STAT_ROWS[k][0]
			var cx := x + (k / 3) * 162.0
			var cy := ly + (k % 3) * 11.0
			draw_string(font, Vector2(cx, cy + 6.0), STAT_ROWS[k][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
				Color(0.88, 0.88, 0.95))
			var bx := cx + 44.0
			var bw := 104.0
			var ratio := clampf(float(stats.get(key, 0.0)) / float(STAT_MAX[key]), 0.0, 1.0)
			_round(Rect2(bx, cy + 1.0, bw, 6.0), Color(0.18, 0.17, 0.24), 3)
			if ratio > 0.0:
				_round(Rect2(bx, cy + 1.0, maxf(bw * ratio, 6.0), 6.0), col, 3)
				draw_rect(Rect2(bx + 2.0, cy + 2.0, maxf(bw * ratio - 4.0, 1.0), 1.0), Color(col.lightened(0.5), 0.6))
		ly += 42.0
	for k in range(1, lines.size()):
		if ly > PANEL.end.y - 4.0:
			break
		draw_string(font, Vector2(x, ly), str(lines[k]), HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 20.0, 7,
			Color(0.8, 0.8, 0.9))
		ly += 10.0
	var tag := str(e.get("tag", ""))
	if tag != "":
		draw_string(font, Vector2(x, PANEL.end.y - 6.0), tag, HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 20.0, 7, GOLD)


# --- Hình cơ bản --------------------------------------------------------------

func _round(r: Rect2, fill: Color, radius: int, border := Color.TRANSPARENT, border_width := 0) -> void:
	_sb.bg_color = fill
	_sb.set_corner_radius_all(radius)
	_sb.border_color = border
	_sb.set_border_width_all(border_width)
	draw_style_box(_sb, r)


func _pill(r: Rect2, label: String, fill: Color, font_size: int) -> void:
	_round(r, fill, int(r.size.y / 2.0), GOLD, 1)
	_text(Vector2(r.position.x, r.position.y + r.size.y / 2.0 + font_size * 0.4), label, font_size, Color.WHITE,
		r.size.x)


func _ellipse(c: Vector2, radius: Vector2, color: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, radius.y / radius.x))
	draw_circle(Vector2.ZERO, radius.x, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _text(pos: Vector2, text: String, font_size: int, color: Color, width: float) -> void:
	if text == "":
		return
	var font := ThemeDB.fallback_font
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 3, Color(0, 0, 0, color.a))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


# --- Dữ liệu dùng chung cho lớp con -------------------------------------------

## Bản form của Rider đã đổi sang `form_id` (&"" = form gốc), chỉ để đọc chỉ số / hình. Gọi xong phải free().
static func preview_form(rider: StringName, form_id: StringName) -> RiderForm:
	var f := GameState.create_form(rider)
	if f != null and form_id != &"" and form_id != f.base_form():
		f.set_form(form_id)
	return f


## Tên hiển thị của một form: bảng form của Rider → tên món quái rơi → bảng FORMS của script riêng → id.
static func form_label(rider: StringName, form_id: StringName) -> String:
	var forms: Dictionary = WorldData.rider_data(rider).get("forms", {})
	var label := str((forms.get(form_id, {}) as Dictionary).get("name", ""))
	if label.is_empty():
		label = WorldData.form_name(rider, form_id)
	if label.is_empty():
		var f := GameState.create_form(rider)
		if f != null:
			var table: Dictionary = f.get_script().get_script_constant_map().get("FORMS", {})
			label = str((table.get(form_id, {}) as Dictionary).get("name", ""))
			f.free()
	return label if not label.is_empty() else String(form_id).capitalize()


## Entry của một form (dùng cho FormSelect / ItemSelect).
static func form_entry(rider: StringName, form_id: StringName, sub: String) -> Dictionary:
	var f := preview_form(rider, form_id)
	var e := {"id": form_id, "name": form_label(rider, form_id), "sub": sub, "color": WorldData.rider_color(rider),
		"stats": {}, "lines": [], "prefix": "", "fallback": "human"}
	if f == null:
		return e
	e["prefix"] = f.animation_prefix()
	e["stats"] = f.stat_summary()
	var kinds: Array[String] = []
	if f.has_blade():
		kinds.append("kiếm")
	if f.has_gun():
		kinds.append("súng")
	var kind := " · ".join(kinds) if not kinds.is_empty() else "tay không"
	var lines: Array = [str(f.tagline) if form_id == &"" or form_id == f.base_form() else "Kiểu đánh: %s" % kind]
	lines.append("Tuyệt chiêu: %s" % f.final_attack_name())
	f.free()
	var counter := RiderCaps.counter_line(rider, form_id)   # quái đặc biệt của màn EX form này hạ được
	if counter != "":
		lines.append(counter)
	e["lines"] = lines
	# Hình dự phòng: form gốc của Rider (form đổi màu chưa có hình riêng)
	var b := preview_form(rider, &"")
	if b != null:
		e["fallback"] = b.animation_prefix()
		b.free()
	return e
