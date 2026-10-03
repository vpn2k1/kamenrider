extends Node
## Test đấu qua mạng: các tiến trình Godot trên cùng một máy, một tạo phòng, các máy khác vào phòng, bot tự đánh.
##
##   sh tools/run_versus.sh                              # 1 VS 1: Kuuga đấu Kuuga
##   RIDERS="faiz agito" sh tools/run_versus.sh          # Rider của chủ phòng, Rider của máy vào phòng
##   RIDERS="kuuga ryuki faiz double" sh tools/run_versus.sh   # 3–4 Rider = phòng ALL COMBAT (hỗn chiến)
##
## Tham số: --host / --join, --rider=<id>, --mode=duel|all, --expect=<số người chủ phòng chờ trước khi bắt đầu>,
## --name=<tên bot>.
##
## Mỗi bên dùng tiến trình test (không đụng save thật): kích hoạt Driver của Rider đó, nhặt hết form và item, rồi chọn
## form biến đổi đầu tiên + item đầu tiên (nếu có) qua đúng 3 bước chọn của phòng. --form=<id> / --no-form để đổi.
## Máy vào phòng tìm phòng qua broadcast UDP; sau JOIN_FALLBACK giây chưa thấy thì vào thẳng 127.0.0.1.
## Bot đi về phía đối thủ gần nhất còn đứng, biến thân khi nộ đầy, đánh khi tới gần, bắn nếu form có súng, Final Attack khi đủ nộ.
## In các dòng chữ lớn của trận (đếm ngược, K.O., kết quả) và tóm tắt. Thoát mã 0 khi trận kết thúc có người thắng,
## hai bên đều bị đánh trúng, rồi cả hai quay về phòng.

const SCENE := "res://scenes/versus/versus.tscn"
const TIMEOUT_MS := 420000
const JOIN_FALLBACK := 4.0
const ACTIONS := ["move_left", "move_right", "attack_light", "henshin", "final_attack", "shoot", "special", "skill_1",
	"skill_2"]

var v: Node
var host := false
var rider: StringName = &"kuuga"
var tag := ""
var picked := false
var join_wait := 0.0
var joined := false
var hits_taken := 0
var foe_hit_seen := 0
var last_hp := 0.0
var last_foe_hp := {}              ## peer_id -> máu đã thấy lần trước
var mode := "duel"
var expect := 2
var last_banner := ""
var last_small := ""
var winner_text := ""
var frame := 0
var form_arg := ""
var verbose := false
var seen_forms: Array[StringName] = []
var bad_form := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	host = "--host" in args
	verbose = "--verbose" in args
	for a in args:
		if a.begins_with("--rider="):
			rider = StringName(a.get_slice("=", 1))
		elif a.begins_with("--form="):
			form_arg = a.get_slice("=", 1)
		elif a == "--no-form":
			form_arg = "-"
		elif a.begins_with("--mode="):
			mode = a.get_slice("=", 1)
		elif a.begins_with("--expect="):
			expect = a.get_slice("=", 1).to_int()
		elif a.begins_with("--name="):
			GameState.player_name = a.get_slice("=", 1)
	var bot_name := GameState.player_name
	GameState.use_test_profile()
	GameState.player_name = bot_name if bot_name != GameState.DEFAULT_PLAYER_NAME \
		else "Bot" + ("Host" if host else "Join")
	tag = "[versus %s]" % GameState.player_name
	GameState.activate_driver(rider)
	GameState.set_level(rider, 3)
	for st in WorldData.WORLDS[WorldData.world_index_of(rider)]["stages"]:
		if st.get("form", &"") != &"":
			GameState.unlock_form(rider, st["form"])
	v = load(SCENE).instantiate()
	add_child(v)
	print("%s bắt đầu, Rider %s" % [tag, rider])


func _process(delta: float) -> void:
	frame += 1
	if Time.get_ticks_msec() > TIMEOUT_MS:
		_finish("hết giờ")
		return
	var want: Array = []
	match v.screen:
		0:   # MENU
			if host and frame == 5:
				v._on_host(2 if mode == "duel" else maxi(expect, 3))   # số người tối đa của phòng
				print("%s tạo phòng: %s · màn %d" % [tag, v._status_menu.text, v.screen])
			elif not host and not joined:
				join_wait += delta
				if not v.lan.rooms.is_empty():
					var ip: String = v.lan.rooms.keys()[0]
					print("%s tìm thấy phòng qua broadcast: %s" % [tag, ip])
					joined = true
					v._join(ip)
				elif join_wait > JOIN_FALLBACK:
					print("%s không thấy broadcast, vào 127.0.0.1" % tag)
					joined = true
					v._join("127.0.0.1")
					print("%s vào phòng: %s" % [tag, v._status_menu.text])
		1:   # ROOM
			if winner_text != "":
				_finish("")
				return
			if v.players.size() >= 2 and not picked:
				picked = true
				_pick_loadout()
			if host and v.players.size() >= expect and v._ready_to_start() and frame % 30 == 0:
				v._on_start_pressed()
		3:   # MATCH
			want = _bot()
			_track()
	for a in ACTIONS:
		if a in want:
			Input.action_press(a)
		else:
			Input.action_release(a)


## Chọn qua đủ 3 bước như người chơi: Rider → form (tối đa 1) → vũ khí.
func _pick_loadout() -> void:
	var forms := GameState.owned_forms(rider)
	var items := GameState.owned_items(rider)
	var form: Array[StringName] = []
	if form_arg == "" and not forms.is_empty():
		form.append(forms[0])
	elif form_arg != "-" and form_arg != "":
		form.append(StringName(form_arg))
	var weapons: Array[StringName] = items.slice(0, 1)
	print("%s chọn %s · form %s · vũ khí %s (đã có form %s, item %s)" % [tag, rider, form, weapons, forms, items])
	v._on_rider_chosen(rider)
	await get_tree().create_timer(0.2).timeout
	if v._form_select.visible:
		v._form_select.pick(form)
	await get_tree().create_timer(0.2).timeout
	if v._weapon_select.visible:
		v._weapon_select.pick(weapons)


## Đối thủ gần nhất còn đứng (ALL COMBAT có nhiều người).
func _target() -> Player:
	var me: Player = v.me
	var best: Player = null
	for id in v.foes:
		var p: Player = v.foes[id]
		if p.state == Player.State.KO:
			continue
		if best == null or absf(p.global_position.x - me.global_position.x) \
				< absf(best.global_position.x - me.global_position.x):
			best = p
	return best


func _bot() -> Array:
	var me: Player = v.me
	if me == null or me.input_locked or me.state == Player.State.KO:
		return []
	var foe := _target()
	if foe == null:
		return []
	var out: Array = []
	var tap := frame % 2 == 0
	var dx := foe.global_position.x - me.global_position.x
	if me.can_henshin() and tap:
		out.append("henshin")
	elif me.can_final() and absf(dx) < 70.0 and tap:
		out.append("final_attack")
	elif me.current_form and absf(dx) < 90.0 and tap and frame % 90 < 2:
		out.append("skill_1" if frame % 180 < 90 else "skill_2")   # skill của form (docs/SKILLS.md)
	if absf(dx) > 34.0:
		out.append("move_right" if dx > 0.0 else "move_left")
	elif signf(dx) != me.facing and dx != 0.0:
		# Quay lưng về đối thủ (vừa lướt qua nhau): ngừng đánh để chuỗi đòn kết thúc rồi quay lại.
		out.append("move_right" if dx > 0.0 else "move_left")
	elif tap:
		out.append("attack_light")
	if me.has_gun():
		out.append("shoot")
	# Thỉnh thoảng đổi form (L): chỉ được vào form / vũ khí đã chọn trước trận.
	if me.current_form and frame % 240 == 0 and me.rage >= Player.FORM_ENTER_MIN_RAGE:
		out.append("special")
	if me.current_form:
		var f := me.current_form.current_form_id()
		if f != me.current_form.base_form() and not seen_forms.has(f):
			seen_forms.append(f)
			var allowed := f == GameState.versus_form or GameState.versus_items.has(f) \
				or (rider == &"double" and GameState.versus_form != &"")
			print("%s vào form %s%s" % [tag, f, "" if allowed else " · SAI: form chưa chọn trước trận!"])
			if not allowed:
				bad_form = true
	return out


func _track() -> void:
	var me: Player = v.me
	if me == null:
		return
	var hp := float(me.hp) + me.rider_hp
	if hp < last_hp - 0.01:
		hits_taken += 1
	last_hp = hp
	for id in v._foe_infos:
		var info: Dictionary = v._foe_infos[id]
		var fh := float(info.get("hp", 0)) + float(info.get("rider_hp", 0.0))
		if last_foe_hp.has(id) and fh < float(last_foe_hp[id]) - 0.01:
			foe_hit_seen += 1
		last_foe_hp[id] = fh
	if verbose and frame % 120 == 0:
		var others := PackedStringArray()
		for id in v.foes:
			others.append("%s st=%d" % [(v.foes[id] as Player).global_position.round(), v.foes[id].state])
		print("%s t=%ds me %s st=%d hp=%d rider=%.0f rage=%.0f lock=%s · khác %s" % [tag,
			Time.get_ticks_msec() / 1000, me.global_position.round(), me.state, me.hp, me.rider_hp, me.rage,
			me.input_locked, ", ".join(others)])
	var b: String = v.hud.banner
	if b != last_banner:
		last_banner = b
		if b != "" and not b.is_valid_int():
			print("%s %s · %s" % [tag, b, v.hud.banner_small])
		if b.ends_with("THẮNG!"):
			winner_text = b
	var small: String = v.hud.banner_small
	if small.ends_with("bị hạ!") and small != last_small:
		print("%s %s" % [tag, small])
	last_small = small


func _finish(reason: String) -> void:
	var ok := reason == "" and winner_text != "" and hits_taken > 0 and foe_hit_seen > 0 and not bad_form
	print("%s trúng đòn %d lần · thấy đối thủ trúng đòn %d lần · kết quả: %s%s" % [tag, hits_taken, foe_hit_seen,
		winner_text if winner_text != "" else "chưa xong", "" if reason == "" else " (%s)" % reason])
	print("%s %s" % [tag, "OK" if ok else "CÓ VẤN ĐỀ"])
	set_process(false)
	get_tree().quit(0 if ok else 1)
