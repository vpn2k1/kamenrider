extends Control
## Phần mở đầu (sau màn đặt tên, trước màn 1-1). Kịch bản ở StoryData.INTRO, mỗi cảnh một hình nền vẽ bằng code:
##   multiverse : vô số Trái Đất song song, mỗi Trái Đất có một Rider bảo vệ
##   theft      : Chronos Void hút sạch sức mạnh Driver, các Trái Đất tắt sáng dần
##   escape     : Void trốn tới Điểm Không, xích Chuỗi Phong Ấn khóa các Trái Đất lại
##   tokyo      : Tokyo 2026, bầu trời nứt, Arcle rơi xuống Shibuya
##   pen        : Pen (Chrono Pass) xuất hiện, giao nhiệm vụ; Grongi kéo tới
##   mission    : bản đồ Chuỗi Trái Đất (EarthMap), chặng đầu là Trái Đất Kuuga
## Sau cùng là thẻ tựa "CHRONO HENSHIN", bấm để vào màn 1-1.
## Esc / "BỎ QUA" lúc nào cũng được: nhảy tới thẻ tựa.

const NEXT_SCENE := "res://scenes/levels/stage_run.tscn"
const EARTH_TEX := preload("res://art/story/earth.png")
const VOID_TEX := preload("res://art/story/void.png")
const CITY_TEX := preload("res://art/backgrounds/shibuya_night.png")
const PEN_TEX := preload("res://art/ui/portraits/pen.png")
const HERO_FRAMES := preload("res://art/characters/player_frames.tres")
const ENEMY_FRAMES := preload("res://art/characters/enemy_frames.tres")
const FADE_TIME := 0.45
const SCENE_LEAD := 0.8          ## giây xem cảnh trước khi thoại hiện
const STREET_Y := 182.0          ## mặt đường ở cảnh Tokyo (phía trên khung thoại)
const VOID_CENTER := Vector2(240, 88)
const ZERO_POINT := Vector2(432, 78)
const ARCLE_FROM := Vector2(172, 18)
const ARCLE_TO := Vector2(214, STREET_Y - 4.0)
const GOLD := Color(1.0, 0.85, 0.35)
const SEAL := Color(0.72, 0.4, 1.0)
const DRAINED := Color(0.3, 0.3, 0.36)
## Các Trái Đất trôi trong vũ trụ ở 3 cảnh đầu: vị trí, bán kính, màu, tên (trống = không ghi).
const PLANETS := [
	{"pos": Vector2(70, 58), "r": 14.0, "color": Color(0.95, 0.3, 0.3), "name": "Trái Đất Kuuga"},
	{"pos": Vector2(165, 118), "r": 11.0, "color": Color(1.0, 0.62, 0.15), "name": "Trái Đất Agito"},
	{"pos": Vector2(318, 30), "r": 13.0, "color": Color(0.75, 0.12, 0.18), "name": "Trái Đất Ryuki"},
	{"pos": Vector2(345, 112), "r": 12.0, "color": Color(0.95, 0.8, 0.2), "name": "Trái Đất Faiz"},
	{"pos": Vector2(420, 44), "r": 10.0, "color": Color(0.25, 0.4, 0.95), "name": "Trái Đất Blade"},
	{"pos": Vector2(36, 142), "r": 8.0, "color": Color(0.35, 0.55, 1.0), "name": ""},
	{"pos": Vector2(292, 160), "r": 7.0, "color": Color(0.65, 0.45, 0.95), "name": ""},
	{"pos": Vector2(446, 150), "r": 9.0, "color": Color(1.0, 0.45, 0.4), "name": ""},
	{"pos": Vector2(118, 170), "r": 6.0, "color": Color(0.95, 0.55, 0.75), "name": ""},
]

var _scene := ""
var _t := 0.0
var _skip_all := false
var _waiting_start := false
var _leaving := false
var _dialogue: DialogueBox
var _fade: ColorRect
var _hero: AnimatedSprite2D
var _grongi: Array[AnimatedSprite2D] = []


func _ready() -> void:
	GameState.take_story("intro")
	_hero = AnimatedSprite2D.new()
	_hero.sprite_frames = HERO_FRAMES
	_hero.position = Vector2(92, STREET_Y - 34.0)
	_hero.play(&"human_idle")
	_hero.visible = false
	add_child(_hero)
	for i in 2:
		var g := AnimatedSprite2D.new()
		g.sprite_frames = ENEMY_FRAMES
		g.flip_h = true
		g.play(&"grongi_zu_run")
		g.visible = false
		add_child(g)
		_grongi.append(g)
	_dialogue = DialogueBox.new()
	_dialogue.pause_tree = false
	add_child(_dialogue)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.size = get_viewport_rect().size
	add_child(_fade)
	_run()


func _run() -> void:
	for scene in StoryData.INTRO:
		if _skip_all:
			break
		_enter_scene(str(scene["scene"]))
		await _fade_to(0.0)
		await _lead_in()
		if _skip_all:
			break
		_dialogue.play(scene["lines"])
		await _dialogue.finished
		if _dialogue.skipped:
			_skip_all = true
			break
		await _fade_to(1.0)
	# Thẻ tựa
	_fade.color.a = 1.0
	_enter_scene("title")
	await _fade_to(0.0)
	_waiting_start = true


func _enter_scene(scene: String) -> void:
	_scene = scene
	_t = 0.0
	_hero.visible = scene == "tokyo" or scene == "pen"
	_hero.flip_h = false
	for g in _grongi:
		g.visible = false
	queue_redraw()


## Xem cảnh một chút trước khi thoại hiện; Esc trong lúc này cũng bỏ qua được.
func _lead_in() -> void:
	var left := SCENE_LEAD
	while left > 0.0 and not _skip_all:
		await get_tree().process_frame
		left -= get_process_delta_time()


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished


func _start_game() -> void:
	if _leaving:
		return
	_leaving = true
	_waiting_start = false
	await _fade_to(1.0)
	get_tree().change_scene_to_file(NEXT_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _scene == "pen":
		# Grongi chạy tới từ mép phải sau vài giây.
		for i in _grongi.size():
			var g := _grongi[i]
			g.visible = _t > 5.0 + i * 0.8
			var x := maxf(330.0 + i * 46.0, 500.0 - (_t - 5.0 - i * 0.8) * 60.0)
			g.position = Vector2(x, STREET_Y - 34.0)
			if x <= 330.0 + i * 46.0 + 0.5 and g.animation != &"grongi_zu_idle":
				g.play(&"grongi_zu_idle")
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	if _waiting_start:
		var touch := event as InputEventScreenTouch
		if event.is_action_pressed("attack_light") or event.is_action_pressed("ui_accept") \
				or event.is_action_pressed("jump") or (touch and touch.pressed):
			get_viewport().set_input_as_handled()
			_start_game()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_skip_all = true
	var t := event as InputEventScreenTouch
	if t and t.pressed and not _dialogue.is_open() and DialogueBox.SKIP.has_point(t.position):
		get_viewport().set_input_as_handled()
		_skip_all = true


# --- Vẽ các cảnh ---------------------------------------------------------

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	match _scene:
		"multiverse":
			_draw_space(rect)
			_draw_planets(func(_i: int) -> float: return 0.0, true)
		"theft":
			_draw_space(rect)
			_draw_theft()
		"escape":
			_draw_space(rect)
			_draw_escape()
		"tokyo":
			_draw_tokyo(false)
		"pen":
			_draw_tokyo(true)
		"mission":
			EarthMap.draw(self, rect, 0, _t)
		"title":
			_draw_title(rect)
	if _scene != "title" and _scene != "" and not _dialogue.is_open():
		draw_rect(DialogueBox.SKIP, Color(0.02, 0.01, 0.06, 0.75))
		draw_rect(DialogueBox.SKIP, Color(0.6, 0.58, 0.75), false, 1.0)
		draw_string(ThemeDB.fallback_font, DialogueBox.SKIP.position + Vector2(0, 11), "BỎ QUA (Esc) »",
			HORIZONTAL_ALIGNMENT_CENTER, DialogueBox.SKIP.size.x, 7, Color(0.9, 0.9, 1.0))


func _draw_space(rect: Rect2) -> void:
	draw_rect(rect, Color(0.03, 0.02, 0.08))
	# vệt tinh vân mờ
	draw_circle(Vector2(120, 90), 110.0, Color(0.25, 0.1, 0.45, 0.12))
	draw_circle(Vector2(380, 70), 90.0, Color(0.1, 0.2, 0.45, 0.12))
	EarthMap.draw_stars(self, rect, _t, 140)


## Vẽ các Trái Đất. drain(i) trả về 0..1: mức đã bị hút sức mạnh (1 = tắt hẳn, xám).
func _draw_planets(drain: Callable, labels: bool) -> void:
	var font := ThemeDB.fallback_font
	for i in PLANETS.size():
		var p: Dictionary = PLANETS[i]
		var pos := _planet_pos(i)
		var r: float = p["r"]
		var d: float = drain.call(i)
		var col: Color = (p["color"] as Color).lerp(DRAINED, d)
		draw_circle(pos, r + 5.0 + sin(_t * 2.0 + i) * 1.0, Color(col, 0.16 * (1.0 - d)))
		var sz := Vector2(r, r) * 2.0
		draw_texture_rect(EARTH_TEX, Rect2(pos - sz / 2.0, sz), false, col.lightened(0.15))
		if labels and not str(p["name"]).is_empty():
			var a := clampf((_t - 0.4 - i * 0.25) / 0.6, 0.0, 1.0)
			draw_string(font, Vector2(pos.x - 50.0, pos.y + r + 11.0), p["name"], HORIZONTAL_ALIGNMENT_CENTER, 100.0, 7,
				Color(0.9, 0.9, 1.0, a))


func _planet_pos(i: int) -> Vector2:
	var p: Dictionary = PLANETS[i]
	return (p["pos"] as Vector2) + Vector2(0, sin(_t * 0.8 + i * 1.7) * 2.0)


func _drain_at(i: int) -> float:
	return clampf((_t - 1.0 - i * 0.35) / 2.0, 0.0, 1.0)


func _draw_theft() -> void:
	var total := 0.0
	for i in PLANETS.size():
		total += _drain_at(i)
	total /= float(PLANETS.size())
	var appear := clampf(_t / 1.0, 0.0, 1.0)
	# vòng đồng hồ sau lưng Void
	var ring := Color(SEAL, 0.5 * appear)
	draw_circle(VOID_CENTER, 50.0 + total * 14.0 + sin(_t * 3.0) * 2.0, Color(SEAL, (0.1 + total * 0.18) * appear))
	draw_arc(VOID_CENTER, 44.0, 0.0, TAU, 48, ring, 1.0)
	for k in 12:
		var a := TAU * k / 12.0
		draw_line(VOID_CENTER + Vector2.from_angle(a) * 40.0, VOID_CENTER + Vector2.from_angle(a) * 44.0, ring, 1.0)
	draw_line(VOID_CENTER, VOID_CENTER + Vector2.from_angle(_t * 1.5 - PI / 2.0) * 34.0, Color(GOLD, appear), 1.0)
	draw_line(VOID_CENTER, VOID_CENTER + Vector2.from_angle(_t * 0.2 - PI / 2.0) * 24.0, Color(GOLD, appear), 1.0)
	_draw_planets(_drain_at, false)
	# dòng sáng từ từng Trái Đất chảy về tay Void
	for i in PLANETS.size():
		var d := _drain_at(i)
		if d <= 0.0 or d >= 1.0:
			continue
		var from := _planet_pos(i)
		var col: Color = PLANETS[i]["color"]
		for k in 7:
			var f := fmod(_t * 0.9 + k / 7.0, 1.0)
			var p := from.lerp(VOID_CENTER + Vector2(0, 6), f)
			draw_rect(Rect2(p.floor() - Vector2(1, 1), Vector2(2, 2)), Color(col.lightened(0.3), 1.0 - d * 0.5))
	_draw_void(VOID_CENTER, 1.4, appear)


func _draw_escape() -> void:
	# Điểm Không ở mép phải: Trái Đất tím, quầng tối.
	var pulse := 0.5 + 0.5 * sin(_t * 2.0)
	draw_circle(ZERO_POINT, 30.0 + pulse * 4.0, Color(SEAL, 0.14))
	var zs := Vector2(40, 40)
	draw_texture_rect(EARTH_TEX, Rect2(ZERO_POINT - zs / 2.0, zs), false, Color(0.75, 0.45, 1.0))
	var font := ThemeDB.fallback_font
	draw_string_outline(font, ZERO_POINT + Vector2(-50, 34), "ĐIỂM KHÔNG", HORIZONTAL_ALIGNMENT_CENTER, 100.0, 8, 3, Color.BLACK)
	draw_string(font, ZERO_POINT + Vector2(-50, 34), "ĐIỂM KHÔNG", HORIZONTAL_ALIGNMENT_CENTER, 100.0, 8, Color(0.85, 0.6, 1.0))
	# Các Trái Đất đã tắt sáng (trừ vài hành tinh ở gần Điểm Không cho thoáng).
	_draw_planets(func(_i: int) -> float: return 1.0, false)
	# Xích phong ấn nối dần các Trái Đất theo thứ tự từ trái sang phải.
	var order := [5, 0, 8, 1, 2, 6, 3, 4, 7]
	for k in order.size() - 1:
		var grow := clampf((_t - 1.2 - k * 0.3) / 0.3, 0.0, 1.0)
		if grow <= 0.0:
			break
		var a := _planet_pos(order[k])
		var b := a.lerp(_planet_pos(order[k + 1]), grow)
		var links := int(a.distance_to(b) / 7.0)
		for j in range(1, links + 1):
			var p := a.lerp(b, float(j) / float(links + 1))
			var glow := 0.6 + 0.4 * sin(_t * 4.0 + j)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -2.5), p + Vector2(1.8, 0), p + Vector2(0, 2.5),
				p + Vector2(-1.8, 0)]), Color(SEAL, glow))
	# Void bay về Điểm Không, nhỏ dần rồi biến mất vào khe nứt.
	var f := clampf((_t - 0.3) / 2.6, 0.0, 1.0)
	var ease_f := f * f * (3.0 - 2.0 * f)
	var pos := VOID_CENTER.lerp(ZERO_POINT + Vector2(-26, 0), ease_f)
	var alpha := 1.0 - clampf((_t - 2.9) / 0.5, 0.0, 1.0)
	for k in 10:
		var back := VOID_CENTER.lerp(pos, clampf(ease_f - k * 0.03, 0.0, 1.0) / maxf(ease_f, 0.001))
		draw_circle(back, 3.0 - k * 0.25, Color(SEAL, 0.35 * alpha * (1.0 - k / 10.0)))
	if _t > 2.2:
		_draw_rift(ZERO_POINT + Vector2(-30, -42), clampf((_t - 2.2) / 0.6, 0.0, 1.0))
	if alpha > 0.0:
		_draw_void(pos, 1.4 - 0.9 * ease_f, alpha)


## Khe nứt không gian: đường gấp khúc phát sáng, open 0..1 là độ dài đã mở.
func _draw_rift(top: Vector2, open: float) -> void:
	var pts := PackedVector2Array()
	var steps := 9
	for k in int(steps * open) + 1:
		pts.append(top + Vector2((k % 2) * 7.0 - 3.0 + sin(k * 2.3) * 3.0, k * 10.0))
	if pts.size() < 2:
		return
	var flick := 0.7 + 0.3 * sin(_t * 17.0)
	draw_polyline(pts, Color(1.0, 0.45, 1.0, 0.35 * flick), 5.0)
	draw_polyline(pts, Color(1.0, 0.8, 1.0, flick), 1.5)


func _draw_void(center: Vector2, scale_f: float, alpha: float) -> void:
	var sz := Vector2(VOID_TEX.get_width(), VOID_TEX.get_height()) * scale_f
	draw_texture_rect(VOID_TEX, Rect2(center - Vector2(sz.x / 2.0, sz.y * 0.45), sz), false, Color(1, 1, 1, alpha))


func _draw_tokyo(with_pen: bool) -> void:
	draw_texture_rect(CITY_TEX, Rect2(0, 0, 480, 269), false)
	# Chớp tím từ khe nứt trên trời.
	var flash := pow(maxf(0.0, sin(_t * 2.6)), 12.0)
	draw_rect(Rect2(0, 0, 480, 270), Color(1.0, 0.4, 1.0, flash * 0.18))
	if with_pen:
		draw_rect(Rect2(0, 0, 480, 270), Color(0.0, 0.0, 0.05, 0.3))
	# Mặt đường
	draw_rect(Rect2(0, STREET_Y, 480, 270.0 - STREET_Y), Color(0.09, 0.07, 0.15))
	draw_rect(Rect2(0, STREET_Y, 480, 2), Color(0.45, 0.35, 0.7))
	for k in 8:
		draw_rect(Rect2(k * 64.0 + 12.0, STREET_Y + 10.0, 30, 2), Color(0.55, 0.5, 0.35, 0.6))
	# Arcle rơi từ khe nứt xuống đường.
	var fall := 1.0 if with_pen else clampf((_t - 1.2) / 2.2, 0.0, 1.0)
	var p := ARCLE_FROM.lerp(ARCLE_TO, fall * fall)
	if fall > 0.0 and fall < 1.0:
		for k in 8:
			var q := ARCLE_FROM.lerp(ARCLE_TO, maxf(0.0, fall * fall - k * 0.025))
			draw_circle(q, 3.0 - k * 0.3, Color(GOLD, 0.5 * (1.0 - k / 8.0)))
	if fall > 0.0:
		var glow := 0.6 + 0.4 * sin(_t * 5.0)
		draw_circle(p, 7.0 + glow * 2.0, Color(GOLD, 0.25))
		draw_rect(Rect2(p - Vector2(5, 1.5), Vector2(10, 3)), Color(0.75, 0.75, 0.8))
		draw_circle(p, 2.5, Color(1.0, 0.3, 0.25))
		draw_circle(p, 1.2, Color(1.0, 0.9, 0.6))
	if not with_pen and fall >= 1.0:
		var burst := _t - 3.4
		if burst > 0.0 and burst < 0.8:
			draw_arc(ARCLE_TO, burst * 60.0, 0.0, TAU, 32, Color(GOLD, 1.0 - burst / 0.8), 2.0)
	if with_pen:
		# Chrono Pass lơ lửng bên cạnh nhân vật chính.
		var bob := sin(_t * 2.5) * 3.0
		var center := Vector2(150, 96 + bob)
		draw_circle(center, 30.0 + sin(_t * 4.0) * 2.0, Color(0.4, 1.0, 0.95, 0.14))
		draw_circle(center, 22.0, Color(0.4, 1.0, 0.95, 0.12))
		var sz := Vector2(56, 56)
		draw_texture_rect(PEN_TEX, Rect2(center - sz / 2.0, sz), false)
		for k in 4:
			var a := _t * 1.2 + k * TAU / 4.0
			var sp := center + Vector2(cos(a) * 34.0, sin(a) * 18.0)
			draw_rect(Rect2(sp.floor(), Vector2(2, 2)), Color(1.0, 1.0, 0.8, 0.8))


func _draw_title(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(rect, Color(0.03, 0.02, 0.08))
	EarthMap.draw_stars(self, rect, _t, 120)
	var c := Vector2(240, 104)
	draw_circle(c, 70.0 + sin(_t * 1.5) * 3.0, Color(SEAL, 0.12))
	var sz := Vector2(84, 84)
	draw_texture_rect(EARTH_TEX, Rect2(c - sz / 2.0, sz), false, Color(0.45, 0.7, 1.0))
	draw_arc(c, 52.0, 0.0, TAU, 64, Color(GOLD, 0.6), 1.0)
	for k in 12:
		var a := TAU * k / 12.0
		draw_line(c + Vector2.from_angle(a) * 48.0, c + Vector2.from_angle(a) * 52.0, Color(GOLD, 0.6), 1.0)
	draw_line(c, c + Vector2.from_angle(_t * 2.0 - PI / 2.0) * 44.0, GOLD, 1.5)
	_title_text(Vector2(0, 40), "KAMEN RIDER", 12, GOLD)
	_title_text(Vector2(0, 176), "CHRONO HENSHIN", 22, Color.WHITE, SEAL)
	_title_text(Vector2(0, 196), "Hành trình qua các Trái Đất bắt đầu", 9, Color(0.8, 0.8, 0.95))
	if _waiting_start and fmod(_t, 1.0) < 0.65:
		_title_text(Vector2(0, 238), "Đánh / Enter / chạm để bắt đầu", 8, Color(1.0, 0.95, 0.7))
	draw_string(font, Vector2(0, 264), "Fan game phi thương mại", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 7,
		Color(0.5, 0.5, 0.6))


func _title_text(pos: Vector2, text: String, font_size: int, color: Color, outline := Color.BLACK) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, 4, outline)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, color)
