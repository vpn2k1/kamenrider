extends Node2D
## Chế độ ĐẤU qua WiFi: các máy cùng mạng, một máy tạo phòng, các máy khác vào phòng, mỗi người chọn một Rider đã mở
## khoá ở hành trình (chọn trùng Rider cũng được) rồi đấu trên đấu trường một màn hình. Hai kiểu phòng:
##   1 VS 1      đúng 2 người.
##   ALL COMBAT  hỗn chiến 2–MAX_PLAYERS người: ai cũng đánh được tất cả, gục thì nằm xem tới hết hiệp, người cuối cùng
##               còn đứng thắng hiệp.
## Màn hình chính chỉ cho vào đây khi đã kích hoạt ít nhất một Driver.
##
##   Sảnh: TẠO PHÒNG 1 VS 1 · TẠO PHÒNG ALL COMBAT · danh sách phòng tìm thấy trong mạng (bấm để vào) · nhập IP chủ
##     phòng + VÀO · QUAY LẠI.
##   Phòng: P1 = chủ phòng, P2.. = máy vào sau (slot trống nhỏ nhất). CHỌN RIDER: 3 bước
##       1. Rider (chỉ Rider đã kích hoạt Driver, cấp và sức mạnh như ở hành trình)
##       2. Form biến đổi: tối đa 1 form đã nhặt được, hoặc chọn form gốc. Bỏ qua nếu chưa nhặt form nào.
##       3. Vũ khí (item đã nhặt, như Sword Vent): mang tối đa GameState.MAX_ITEMS món hoặc không mang. Bỏ qua nếu chưa có.
##     Bộ đã chọn lưu trong save (GameState.set_versus_loadout): lần sau vào phòng tự chọn sẵn, không cần chọn lại.
##     Chủ phòng bấm BẮT ĐẦU khi đủ người (1 VS 1: 2 người, ALL COMBAT: từ 2 người) và ai cũng đã chọn.
##     RỜI PHÒNG để ngắt kết nối. Đấu xong quay về phòng: đấu lại hoặc đổi.
##   Trận: thắng WINS_NEEDED hiệp là thắng trận. Mỗi hiệp bắt đầu ở dạng người, máu đầy, nộ đầy: bấm Biến thân.
##     Luật như màn thường: máu Rider về 0 thì Henshin Break về dạng người, máu người về 0 là gục.
##     Menu (Esc / P / nút ≡) bấm 2 lần = bỏ trận, mọi người về phòng. Có người thoát giữa trận thì tính như gục;
##     còn dưới 2 người thì về phòng.
##   Trong trận chỉ đổi được sang form / vũ khí đã chọn (nút Kỹ năng L, tốn nộ như ở hành trình). Dạng người ai cũng
##   như nhau. GameState.versus bật trong cả cảnh này.
##
## Mạng (VersusLan: WebSocket, chủ phòng là server, gói giữa hai client đi vòng qua chủ phòng):
##   - Mỗi máy tự điều khiển nhân vật của mình (Player thật, đọc phím / nút cảm ứng như màn thường) và gửi gói trạng
##     thái mỗi khung vật lý cho mọi máy (_net_state). Nhân vật của người khác là Player net_puppet (foes[peer_id]):
##     chỉ vẽ theo gói nhận được. Mỗi người một phe (team "p1".."p4") nên đánh trúng được tất cả.
##   - Đòn trúng do máy NGƯỜI ĐÁNH phát hiện (hitbox / đạn của mình chạm hurtbox của bản sao người khác) rồi gửi
##     _net_hit cho đúng máy đó; máy bị đánh chạy take_hit trên nhân vật thật nên né, bất tử, cúi, giáp... vẫn đúng luật.
##   - Đạn: bản thật ở máy người bắn, các máy khác nhận bản sao chỉ để nhìn (Projectile.visual_only).
##   - Chủ phòng quyết định kết quả hiệp / trận (_report_ko → _player_out / _round_over → _round_start / _match_over),
##     để mọi máy thấy cùng một kết quả khi nhiều người gục cùng lúc.
##   Mọi RPC nằm trên node gốc của cảnh này (cùng đường dẫn trên mọi máy): sảnh, phòng và trận ở chung một cảnh.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const TOUCH_SCRIPT := preload("res://scripts/ui/touch_controls.gd")
const TOP_TEX := preload("res://art/tiles/street_top.png")
const FILL_TEX := preload("res://art/tiles/street_fill.png")
const BG_TEX := preload("res://art/backgrounds/tokyo.png")
const BG_TINT := Color(0.78, 0.78, 0.86)
const HUMAN_COLOR := Color(0.9, 0.9, 0.9)
const VIEW := Vector2(480, 270)
const GROUND_Y := 226.0
## Bệ một chiều (x, y, rộng): hai bệ thấp hai bên, một bệ cao ở giữa.
const PLATFORMS := [Vector3(60, 168, 110), Vector3(310, 168, 110), Vector3(185, 112, 110)]
const MAX_PLAYERS := 4             ## ALL COMBAT
## Chỗ đứng đầu hiệp theo slot: P1 trái, P2 phải, P3 / P4 vào giữa. Ai đứng nửa trái thì quay mặt sang phải.
const SPAWN_X := [90.0, 390.0, 190.0, 290.0]
const WINS_NEEDED := 2
const COUNTDOWN := 3
const ROUND_END_TIME := 2.5
const MATCH_END_TIME := 3.5
const MENU_CONFIRM_TIME := 2.0
const CONNECT_TIMEOUT := 6.0
const SNAP_DISTANCE := 80.0      ## bản sao đối thủ lệch xa hơn chừng này thì đặt thẳng tới vị trí mới
const FOLLOW := 0.5              ## mỗi khung vật lý bản sao trượt chừng này phần quãng còn lại tới vị trí nhận được
const SNAPSHOT_SIZE := 19

enum Screen { MENU, ROOM, PICK, MATCH }

var lan: VersusLan
var screen := Screen.MENU
## Người trong phòng, chủ phòng giữ bản gốc và gửi cho các máy khác (_lobby):
##   peer_id -> {"name", "slot", "rider", "form", "items", "level"} (form / items / level chỉ để hiện trong phòng)
var players := {}
var room_mode := "duel"          ## "duel" (1 VS 1) hoặc "all" (ALL COMBAT)
var max_players := 2

var me: Player                   ## nhân vật của máy này
var foes := {}                   ## peer_id -> bản sao nhân vật của người khác (net_puppet)
var my_slot := 0                 ## 0 = P1 (chủ phòng), 1 = P2...
var _wins := [0, 0, 0, 0]        ## số hiệp thắng theo slot
var _round := 0
var _match_id := 0               ## tăng mỗi lần vào / rời trận, để các bước chờ (await) của trận cũ tự dừng
var _host_round_live := false    ## chỉ chủ phòng: hiệp đang đấu, còn từ 2 người đứng
var _alive: Array = []           ## chỉ chủ phòng: slot còn đứng trong hiệp
var _round_live := false         ## hiệp đang đấu trên máy này (hết hiệp thì banner Final Attack đến trễ không đè chữ K.O.)
var _foe_targets := {}           ## peer_id -> vị trí nhận qua gói gần nhất
var _foe_infos := {}             ## peer_id -> số liệu HUD từ gói gần nhất
var _my_status := ""
var _stand_hurt_h := 50.0
var _menu_armed := 0.0
var _connect_timer := 0.0
var _banner_timer := 0.0
var _shake := 0.0

var world: Node2D
var camera: Camera2D
var hud: VersusHud
var touch: Node2D
var _flash: ColorRect
var _backdrop: FinisherBackdrop     ## phông tuyệt chiêu sau trận đánh (xem stage_run.gd)
var _cutin: SkillCutIn
var _menu_root: Control
var _room_root: Control
var _rider_select: RiderSelect
var _form_select: FormSelect
var _weapon_select: ItemSelect
var _pick_rider: StringName = &""
var _pick_form: StringName = &""
var _status_menu: Label
var _status_room: Label
var _room_list: VBoxContainer
var _ip_edit: LineEdit
var _host_button: Button
var _host_all_button: Button
var _room_title: Label
var _room_ip: Label
var _slot_labels: Array[Label] = []
var _pick_button: Button
var _start_button: Button


func _ready() -> void:
	GameState.versus = true
	lan = VersusLan.new()
	add_child(lan)
	lan.rooms_changed.connect(_refresh_rooms)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connect_failed)
	multiplayer.server_disconnected.connect(_on_server_lost)
	CombatDirector.shake_requested.connect(_on_shake)
	CombatDirector.final_attack_started.connect(_on_final_attack)
	CombatDirector.final_attack_landed.connect(func() -> void:
		if _backdrop:
			_backdrop.impact())
	CombatDirector.skill_used.connect(func(label: String, color: Color) -> void:
		if _cutin and screen == Screen.MATCH:
			_cutin.skill(label, color))
	_build_arena()
	_build_ui()
	_show_menu("")


func _exit_tree() -> void:
	GameState.versus = false
	CombatDirector.set_enemy_time_scale(1.0)
	Engine.time_scale = 1.0
	if lan:
		lan.close()


# --- Sảnh: tạo / tìm / vào phòng ------------------------------------------

## mode "duel" = 1 VS 1, "all" = ALL COMBAT.
func _on_host(mode: String) -> void:
	var err := lan.host(GameState.player_name)
	if err != OK:
		_status_menu.text = "Không tạo được phòng (lỗi %d). Cổng %d có thể đang bận." % [err, VersusLan.GAME_PORT]
		return
	lan.stop_listening()
	room_mode = mode
	max_players = 2 if mode == "duel" else MAX_PLAYERS
	lan.mode = mode
	lan.max_players = max_players
	players = {1: {"name": GameState.player_name, "rider": "", "slot": 0}}
	my_slot = 0
	_show_room("Đã tạo phòng. Chờ người khác vào...")
	_send_saved_pick()


func _join(ip: String) -> void:
	ip = ip.strip_edges()
	if ip.is_empty():
		_status_menu.text = "Nhập IP của máy chủ phòng (hiện trên màn hình máy đó)."
		return
	var err := lan.join(ip)
	if err != OK:
		_status_menu.text = "Không kết nối được tới %s (lỗi %d)." % [ip, err]
		return
	_connect_timer = CONNECT_TIMEOUT
	_status_menu.text = "Đang kết nối tới %s..." % ip


func _on_connected() -> void:
	_connect_timer = 0.0
	lan.stop_listening()
	players = {}
	my_slot = 1
	_hello.rpc_id(1, GameState.player_name)
	_show_room("Đã vào phòng.")
	_send_saved_pick()


func _on_connect_failed() -> void:
	_connect_timer = 0.0
	lan.close()
	_show_menu("Không kết nối được. Kiểm tra IP và hai máy cùng một mạng WiFi.")


func _on_server_lost() -> void:
	_end_match_local()
	lan.close()
	players = {}
	_show_menu("Mất kết nối với chủ phòng.")


## Mọi máy đều nhận tín hiệu này khi một máy khác thoát (chủ phòng chuyển tiếp cho các client).
func _on_peer_disconnected(id: int) -> void:
	_remove_foe(id)
	if not multiplayer.is_server() or not players.has(id):
		return
	var who := str(players[id]["name"])
	var slot := int(players[id]["slot"])
	players.erase(id)
	lan.players_in_room = players.size()
	if screen == Screen.MATCH:
		if players.size() < 2:
			_abort.rpc(who)
		else:
			_host_ko(slot)     # thoát giữa trận = gục
	_sync_lobby("%s đã rời phòng." % who)


func _leave_room() -> void:
	_end_match_local()
	players = {}
	lan.close()
	_show_menu("Đã rời phòng.")


func _on_back() -> void:
	lan.close()
	get_tree().change_scene_to_file(MENU_SCENE)


## Máy vào phòng chào chủ phòng. Phòng đã đủ người (hoặc đang đấu) thì từ chối. Nhận slot trống nhỏ nhất.
@rpc("any_peer", "call_remote", "reliable")
func _hello(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if players.size() >= max_players or screen == Screen.MATCH:
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	var used: Array = []
	for pid in players:
		used.append(int(players[pid]["slot"]))
	var slot := 0
	while used.has(slot):
		slot += 1
	var cleaned := player_name.strip_edges().left(GameState.MAX_NAME_LENGTH)
	players[id] = {"name": cleaned if not cleaned.is_empty() else "?", "rider": "", "slot": slot}
	lan.players_in_room = players.size()
	_sync_lobby("%s đã vào phòng." % players[id]["name"])


func _sync_lobby(message := "") -> void:
	_lobby.rpc(players, message, room_mode, max_players)


@rpc("authority", "call_local", "reliable")
func _lobby(state: Dictionary, message: String, mode: String, max_count: int) -> void:
	players = state
	room_mode = mode
	max_players = max_count
	for id in foes.keys():
		if not players.has(id):
			_remove_foe(id)
	if screen == Screen.ROOM or screen == Screen.PICK:
		_refresh_room()
		if message != "":
			_status_room.text = message


# --- Phòng: chọn Rider, bắt đầu -------------------------------------------

func _open_pick() -> void:
	screen = Screen.PICK
	_room_root.visible = false
	# Đợi một khung hình: phím Enter / Đánh vừa bấm nút này không được tính luôn là "chọn" trong màn chọn Rider.
	await get_tree().process_frame
	if screen != Screen.PICK:
		return
	var options := GameState.selectable_riders()
	if options.is_empty():
		_show_room("Chưa có Rider nào: mở khoá Rider ở chế độ CHƠI trước.")
		return
	var colors := {}
	for id in options:
		colors[id] = WorldData.rider_color(id)
	var current := GameState.versus_rider if options.has(GameState.versus_rider) else options[options.size() - 1]
	_rider_select.open(options, "CHỌN RIDER", "Rider đã mở khoá · cấp và form như ở hành trình", current, colors)


## Bước 2: form biến đổi (tối đa 1). Rider chưa nhặt form nào thì sang thẳng bước 3.
func _on_rider_chosen(id: StringName) -> void:
	_pick_rider = id
	var forms := GameState.owned_forms(id)
	if forms.is_empty():
		_on_form_chosen([] as Array[StringName])
		return
	await get_tree().process_frame
	var pre: Array[StringName] = []
	if id == GameState.versus_rider and GameState.versus_form != &"":
		pre.append(GameState.versus_form)
	_form_select.open(id, forms, pre)


## Bước 3: vũ khí (item). Rider chưa nhặt item nào thì xong luôn.
func _on_form_chosen(picked: Array[StringName]) -> void:
	_pick_form = picked[0] if not picked.is_empty() else &""
	var items := GameState.owned_items(_pick_rider)
	if items.is_empty():
		_on_weapons_chosen([] as Array[StringName])
		return
	await get_tree().process_frame
	_weapon_select.open(_pick_rider, items,
		GameState.versus_items if _pick_rider == GameState.versus_rider else ([] as Array[StringName]))


func _on_weapons_chosen(items: Array[StringName]) -> void:
	GameState.set_versus_loadout(_pick_rider, _pick_form, items)
	_show_room("")
	_send_pick()


## Vào phòng: dùng luôn bộ đã chọn lần trước (nếu Rider đó vẫn dùng được), khỏi phải chọn lại.
func _send_saved_pick() -> void:
	var rider := GameState.versus_rider
	if rider != &"" and GameState.is_active(rider):
		GameState.set_versus_loadout(rider, GameState.versus_form, GameState.versus_items.duplicate())
		_send_pick()


func _send_pick() -> void:
	var items: Array = []
	for f in GameState.versus_items:
		items.append(String(f))
	var pick := {"rider": String(GameState.versus_rider), "form": String(GameState.versus_form), "items": items,
		"level": GameState.get_level(GameState.versus_rider)}
	if multiplayer.is_server():
		_apply_pick(1, pick)
	else:
		_pick.rpc_id(1, pick)


@rpc("any_peer", "call_remote", "reliable")
func _pick(pick: Dictionary) -> void:
	if multiplayer.is_server():
		_apply_pick(multiplayer.get_remote_sender_id(), pick)


func _apply_pick(id: int, pick: Dictionary) -> void:
	var rider := str(pick.get("rider", ""))
	if not players.has(id) or WorldData.world_index_of(StringName(rider)) < 0:
		return
	var items: Array = []
	for f in pick.get("items", []):
		items.append(str(f))
	players[id]["rider"] = rider
	players[id]["form"] = str(pick.get("form", ""))
	players[id]["items"] = items.slice(0, GameState.MAX_ITEMS)
	players[id]["level"] = int(pick.get("level", 1))
	_sync_lobby("%s chọn %s." % [players[id]["name"], _loadout_text(players[id])])


func _ready_to_start() -> bool:
	if players.size() < 2 or players.size() > max_players or (room_mode == "duel" and players.size() != 2):
		return false
	for id in players:
		if str(players[id]["rider"]).is_empty():
			return false
	return true


func _on_start_pressed() -> void:
	if multiplayer.is_server() and _ready_to_start() and screen == Screen.ROOM:
		_start_match.rpc(players)


# --- Trận đấu ---------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func _start_match(state: Dictionary) -> void:
	players = state
	_match_id += 1
	_build_fighters()
	screen = Screen.MATCH
	_menu_root.visible = false
	_room_root.visible = false
	_rider_select.visible = false
	_form_select.visible = false
	_weapon_select.visible = false
	hud.visible = true
	touch.visible = true
	_wins = [0, 0, 0, 0]
	if multiplayer.is_server():
		_round_start.rpc(1, _wins)


@rpc("authority", "call_local", "reliable")
func _round_start(n: int, wins: Array) -> void:
	if me == null:
		return
	_round = n
	_wins = wins
	_clear_projectiles()
	me.reset_for_stage()
	me.respawn_at(Vector2(SPAWN_X[my_slot], GROUND_Y))
	me.facing = 1 if SPAWN_X[my_slot] < VIEW.x / 2.0 else -1
	me.sprite.flip_h = me.facing < 0
	me.input_locked = true
	hud.round_text = "HIỆP %d" % n
	if multiplayer.is_server():
		_host_round_live = true
		_alive.clear()
		for id in players:
			_alive.append(int(players[id]["slot"]))
	_round_live = true
	var token := _match_id
	for i in range(COUNTDOWN, 0, -1):
		_set_banner(str(i), "Nộ đầy: bấm BIẾN THÂN (I)" if i == COUNTDOWN else "", 1.0)
		await get_tree().create_timer(1.0).timeout
		if token != _match_id:
			return
	_set_banner("ĐẤU!", "Hỗn chiến: người cuối cùng còn đứng thắng" if players.size() > 2 else "", 0.8)
	me.input_locked = false


func _on_me_died() -> void:
	if multiplayer.is_server():
		_host_ko(my_slot)
	else:
		_report_ko.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _report_ko() -> void:
	var id := multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and players.has(id):
		_host_ko(int(players[id]["slot"]))


## Chủ phòng: người ở `slot` vừa gục (hoặc thoát). Còn từ 2 người đứng thì hiệp đấu tiếp; còn 1 người thì người đó
## thắng hiệp (không còn ai thì hoà). Đủ WINS_NEEDED thì thắng trận, chưa thì hiệp kế.
func _host_ko(slot: int) -> void:
	if not _host_round_live or not _alive.has(slot):
		return
	_alive.erase(slot)
	if _alive.size() >= 2:
		_player_out.rpc(slot)
		return
	_host_round_live = false
	var winner: int = _alive[0] if not _alive.is_empty() else -1
	var wins := _wins.duplicate()
	if winner >= 0:
		wins[winner] += 1
	_round_over.rpc(winner, wins)
	var token := _match_id
	await get_tree().create_timer(ROUND_END_TIME).timeout
	if token != _match_id:
		return
	if winner >= 0 and wins[winner] >= WINS_NEEDED:
		_match_over.rpc(winner)
	else:
		_round_start.rpc(_round + 1, wins)


## ALL COMBAT: một người gục nhưng hiệp còn tiếp.
@rpc("authority", "call_local", "reliable")
func _player_out(slot: int) -> void:
	if hud.banner == "":
		_set_banner("", "%s bị hạ!" % ("Bạn" if slot == my_slot else _slot_name(slot)), 1.5)


@rpc("authority", "call_local", "reliable")
func _round_over(winner: int, wins: Array) -> void:
	_wins = wins
	_round_live = false
	if me:
		me.input_locked = true
	if winner < 0:
		_set_banner("HOÀ", "Không ai còn đứng · hiệp %d không tính" % _round, ROUND_END_TIME)
	else:
		_set_banner("K.O.", "%s thắng hiệp %d" % [_slot_name(winner), _round], ROUND_END_TIME)


@rpc("authority", "call_local", "reliable")
func _match_over(winner: int) -> void:
	var text := "BẠN THẮNG!" if winner == my_slot else "%s THẮNG!" % _slot_name(winner).to_upper()
	_set_banner(text, _score_text(), MATCH_END_TIME)
	var token := _match_id
	await get_tree().create_timer(MATCH_END_TIME).timeout
	if token != _match_id:
		return
	_end_match_local()
	_show_room("Chủ phòng bấm BẮT ĐẦU để đấu lại, hoặc CHỌN RIDER khác.")


## "Tỉ số 2 - 1" (1 VS 1) hoặc "P1 2 · P2 1 · P3 0" (ALL COMBAT).
func _score_text() -> String:
	var slots := _match_slots()
	if slots.size() == 2:
		return "Tỉ số %d - %d" % [_wins[slots[0]], _wins[slots[1]]]
	var parts := PackedStringArray()
	for slot in slots:
		parts.append("P%d %d" % [slot + 1, _wins[slot]])
	return " · ".join(parts)


## Bấm Menu hai lần trong trận (hoặc còn dưới 2 người): mọi người về phòng.
@rpc("any_peer", "call_local", "reliable")
func _abort(who: String) -> void:
	if screen != Screen.MATCH:
		return
	_end_match_local()
	_show_room("%s đã bỏ trận." % who)


func _build_fighters() -> void:
	_clear_fighters()
	var my_id := multiplayer.get_unique_id()
	my_slot = int(players[my_id]["slot"])
	me = _make_player(my_slot, StringName(str(players[my_id]["rider"])), false)
	for id in players:
		if id == my_id:
			continue
		var p := _make_player(int(players[id]["slot"]), StringName(str(players[id]["rider"])), true)
		foes[id] = p
		_foe_targets[id] = p.global_position
		p.net_hit.connect(_on_foe_hit.bind(id))
	me.died.connect(_on_me_died)
	me.form_changed.connect(_on_my_form_changed)
	me.form_status_changed.connect(_on_my_status)
	me.notice.connect(_on_notice)
	me.shot_fired.connect(_on_my_shot)
	touch.player = me
	_on_my_form_changed(&"")


func _make_player(slot: int, rider: StringName, puppet: bool) -> Player:
	var p: Player = PLAYER_SCENE.instantiate()
	p.name = "P%d" % (slot + 1)
	p.team = StringName("p%d" % (slot + 1))
	var riders: Array[StringName] = [rider]
	p.versus_riders = riders
	p.net_puppet = puppet
	# Shape của Hurtbox dùng chung giữa các bản của player.tscn: tách riêng để một người cúi không làm người kia thấp theo.
	var hurt_shape := p.get_node("Hurtbox/CollisionShape2D") as CollisionShape2D
	hurt_shape.shape = hurt_shape.shape.duplicate()
	_stand_hurt_h = (hurt_shape.shape as RectangleShape2D).size.y
	# Bảng tên trên đầu (P1..P4 theo màu slot, "BẠN" là nhân vật của máy này).
	var tag := Label.new()
	tag.text = "P%d" % (slot + 1) if puppet else "P%d · BẠN" % (slot + 1)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.size = Vector2(60, 10)
	tag.position = Vector2(-30, -80)
	tag.add_theme_font_size_override("font_size", 7)
	tag.add_theme_color_override("font_color", VersusHud.SLOT_COLORS[slot % VersusHud.SLOT_COLORS.size()])
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 3)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tag)
	p.position = Vector2(SPAWN_X[slot], GROUND_Y)
	world.add_child(p)
	p.facing = 1 if SPAWN_X[slot] < VIEW.x / 2.0 else -1
	p.sprite.flip_h = p.facing < 0
	return p


func _remove_foe(id: int) -> void:
	if foes.has(id):
		if is_instance_valid(foes[id]):
			foes[id].queue_free()
		foes.erase(id)
	_foe_targets.erase(id)
	_foe_infos.erase(id)


func _clear_fighters() -> void:
	if is_instance_valid(me):
		me.queue_free()
	me = null
	for id in foes.keys():
		_remove_foe(id)
	_clear_projectiles()


func _clear_projectiles() -> void:
	for c in world.get_children():
		if c is Projectile or c is Fx:
			c.queue_free()


## Rời trận trên máy này (không gửi gì qua mạng).
func _end_match_local() -> void:
	_match_id += 1
	_host_round_live = false
	_round_live = false
	_clear_fighters()
	hud.visible = false
	hud.banner = ""
	hud.banner_small = ""
	hud.sides = []
	touch.visible = false
	Engine.time_scale = 1.0
	CombatDirector.set_enemy_time_scale(1.0)


## Các slot đang đấu, theo thứ tự.
func _match_slots() -> Array:
	var out: Array = []
	for id in players:
		out.append(int(players[id]["slot"]))
	out.sort()
	return out


# --- Đồng bộ trong trận -----------------------------------------------------

func _physics_process(_delta: float) -> void:
	if screen != Screen.MATCH or me == null:
		return
	if lan.is_online():
		_net_state.rpc(_snapshot())
	for id in foes:
		var p: Player = foes[id]
		var d: Vector2 = _foe_targets[id] - p.global_position
		p.global_position = _foe_targets[id] if d.length() > SNAP_DISTANCE else p.global_position + d * FOLLOW


## Trạng thái nhân vật của máy này, gửi cho máy kia mỗi khung vật lý (thứ tự khớp _apply_snapshot).
func _snapshot() -> Array:
	var f := me.current_form
	return [me.global_position, String(me.sprite.animation), me.sprite.frame, me.sprite.flip_h, me.sprite.visible,
		me.sprite.modulate.a, me.modulate, me.facing, int(me.state), me.is_invulnerable(),
		me.hp, me.max_hp, me.rider_hp, f.get_max_hp() if f else 0.0, me.rage, me.in_special_form(),
		f.rage_drain() if f else 1.0, String(f.rider_id) if f else "", _status_text()]


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _net_state(s: Array) -> void:
	var id := multiplayer.get_remote_sender_id()
	var foe: Player = foes.get(id)
	if foe == null or s.size() != SNAPSHOT_SIZE:
		return
	_foe_targets[id] = s[0]
	var spr := foe.sprite
	var anim := StringName(str(s[1]))
	if spr.sprite_frames and spr.sprite_frames.has_animation(anim):
		if spr.animation != anim:
			spr.animation = anim
		spr.frame = int(s[2])
	spr.flip_h = s[3]
	spr.visible = s[4]
	spr.modulate.a = s[5]
	foe.modulate = s[6]
	foe.facing = s[7]
	foe.state = s[8]
	foe.net_invulnerable = s[9]
	_set_crouch(foe, foe.state == Player.State.CROUCH)
	var rider := StringName(str(s[17]))
	var ph := foe.get_node("Placeholder") as Polygon2D
	ph.visible = not spr.visible
	ph.scale.x = foe.facing
	ph.color = WorldData.rider_color(rider) if rider != &"" else HUMAN_COLOR
	_foe_infos[id] = {"hp": s[10], "max_hp": s[11], "rider_hp": s[12], "rider_max": s[13], "rage": s[14],
		"special": s[15], "drain": s[16], "status": s[18]}


## Người khác cúi thì hurtbox của bản sao thấp xuống (đạn cao bay qua đầu, như trên máy của họ).
func _set_crouch(p: Player, on: bool) -> void:
	var shape := p.hurtbox.get_node("CollisionShape2D") as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	var h := Player.CROUCH_HURTBOX_HEIGHT if on else _stand_hurt_h
	if rect.size.y != h:
		rect.size.y = h
		shape.position.y = -h / 2.0


## Mình đánh trúng bản sao của người chơi `peer_id`: gửi đòn sang đúng máy đó xử lý.
func _on_foe_hit(info: DamageInfo, peer_id: int) -> void:
	var tags: Array = []
	for t in info.tags:
		tags.append(String(t))
	_net_hit.rpc_id(peer_id, info.damage, info.knockback, info.direction, tags)


@rpc("any_peer", "call_remote", "reliable")
func _net_hit(damage: float, knockback: Vector2, direction: int, tags: Array) -> void:
	if me == null or screen != Screen.MATCH:
		return
	var t: Array = []
	for x in tags:
		t.append(StringName(str(x)))
	var attacker: Player = foes.get(multiplayer.get_remote_sender_id())
	if not me.take_hit(DamageInfo.new(damage, knockback, direction, t, attacker)):
		return
	var heavy := t.has(&"heavy") or t.has(&"final")
	Fx.spawn(world, me.global_position + Vector2(0, -34), "spark", Color(1.0, 0.85, 0.5), -direction,
		1.3 if heavy else 1.0)
	if heavy:
		_shake = maxf(_shake, 5.0 if t.has(&"final") else 3.0)


func _on_my_shot(p: Projectile) -> void:
	if lan.is_online():
		_net_shot.rpc(p.global_position, p.velocity, p.radius, p.color, p.pierce, p.life, p.style, p.hit_fx)


@rpc("any_peer", "call_remote", "reliable")
func _net_shot(pos: Vector2, vel: Vector2, radius: float, color: Color, pierce: bool, life: float, style: String,
		hit_fx: String) -> void:
	var foe: Player = foes.get(multiplayer.get_remote_sender_id())
	if foe == null:
		return
	var p := Projectile.new()
	p.visual_only = true
	p.team = foe.team
	p.velocity = vel
	p.radius = radius
	p.color = color
	p.pierce = pierce
	p.life = life
	p.style = style
	p.hit_fx = hit_fx
	p.source = foe
	world.add_child(p)
	p.global_position = pos


func _on_final_attack(rider_id: StringName, attack_name: String) -> void:
	if screen != Screen.MATCH:
		return
	_show_final(attack_name, rider_id, me)
	if lan.is_online():
		_net_final.rpc(attack_name, String(rider_id))


@rpc("any_peer", "call_remote", "reliable")
func _net_final(attack_name: String, rider_id := "") -> void:
	if screen == Screen.MATCH:
		_show_final(attack_name, StringName(rider_id), null)


## Tung Final: phông tuyệt chiêu + cut-in (đòn của máy kia: không có chân dung, màu theo màu Rider).
func _show_final(attack_name: String, rider_id: StringName, who: Player) -> void:
	if not _round_live:
		return
	var color := WorldData.rider_color(rider_id)
	var mark := ""
	if who and who.current_form:
		var fx := who.current_fx()
		color = fx["color"]
		mark = str(fx["signature"]) if str(fx["signature"]) != "" else str(fx["intro"])
	_backdrop.play(rider_id, color, mark)
	_cutin.final(attack_name, color, who.sprite if who else null,
		who.current_form.animation_prefix() + "_idle" if who and who.current_form else "")
	CombatDirector.hit_stop(0.16, 0.1)
	_flash.visible = true
	_flash.color = Color(1, 1, 1, 0.35)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: _flash.visible = false)


func _on_my_form_changed(rider_id: StringName) -> void:
	var ph := me.get_node("Placeholder") as Polygon2D
	ph.color = WorldData.rider_color(rider_id) if rider_id != &"" else HUMAN_COLOR
	if rider_id == &"":
		_my_status = "dạng người"


func _on_my_status(text: String) -> void:
	_my_status = text


func _status_text() -> String:
	if me.current_form:
		return "%s  Lv%d" % [_my_status, me.current_form.level]
	return _my_status


func _on_notice(text: String) -> void:
	if hud.banner == "":
		_set_banner("", text, 1.2)


func _on_shake(strength: float) -> void:
	_shake = maxf(_shake, strength)


# --- Khung hình -------------------------------------------------------------

func _process(delta: float) -> void:
	if _connect_timer > 0.0:
		_connect_timer -= delta
		if _connect_timer <= 0.0 and screen == Screen.MENU:
			lan.close()
			_status_menu.text = "Hết thời gian kết nối. Kiểm tra IP, hai máy cùng WiFi, tường lửa cho phép game."
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	_shake = move_toward(_shake, 0.0, 30.0 * delta)
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			hud.banner = ""
			hud.banner_small = ""
	# Esc / Menu lúc bảng hướng dẫn đang mở là để đóng bảng, không thoát phòng / bỏ trận
	var menu_pressed := Input.is_action_just_pressed("menu") and not HelpOverlay.is_showing()
	if screen == Screen.MENU and menu_pressed:
		_on_back()
		return
	if screen != Screen.MATCH or me == null:
		return
	_update_my_placeholder()
	_update_hud()
	_menu_armed = maxf(_menu_armed - delta, 0.0)
	if menu_pressed:
		if _menu_armed > 0.0:
			_abort.rpc(GameState.player_name)
		else:
			_menu_armed = MENU_CONFIRM_TIME
			_set_banner("", "Bấm Menu lần nữa để bỏ trận", MENU_CONFIRM_TIME)


func _my_info() -> Dictionary:
	var f := me.current_form
	return {"hp": me.hp, "max_hp": me.max_hp, "rider_hp": me.rider_hp, "rider_max": f.get_max_hp() if f else 0.0,
		"rage": me.rage, "special": me.in_special_form(), "drain": f.rage_drain() if f else 1.0,
		"status": _status_text()}


## Ô HUD của mọi người đang đấu, theo thứ tự slot.
func _update_hud() -> void:
	var my_id := multiplayer.get_unique_id()
	var by_slot := {}
	for id in players:
		var slot := int(players[id]["slot"])
		var info: Dictionary
		var ko := false
		if id == my_id:
			info = _my_info()
			ko = me.state == Player.State.KO
		elif foes.has(id):
			info = (_foe_infos.get(id, {}) as Dictionary).duplicate()
			ko = foes[id].state == Player.State.KO
		else:
			continue
		info["slot"] = slot
		info["name"] = str(players[id]["name"])
		info["wins"] = _wins[slot]
		info["you"] = id == my_id
		info["ko"] = ko
		by_slot[slot] = info
	var keys := by_slot.keys()
	keys.sort()
	hud.sides = keys.map(func(k): return by_slot[k])


func _update_my_placeholder() -> void:
	var ph := me.get_node("Placeholder") as Polygon2D
	ph.visible = not me.sprite.visible
	ph.scale.x = me.facing
	var fading := me.state == Player.State.DODGE or me.state == Player.State.BREAK or me.is_invulnerable()
	me.sprite.modulate.a = 0.55 if fading and Engine.get_process_frames() % 8 < 4 else 1.0


func _set_banner(big: String, small: String, seconds: float) -> void:
	hud.banner = big
	hud.banner_small = small
	_banner_timer = seconds


func _my_entry() -> Dictionary:
	return players.get(multiplayer.get_unique_id(), {})


func _slot_name(slot: int) -> String:
	for id in players:
		if int(players[id]["slot"]) == slot:
			return str(players[id]["name"])
	return "P%d" % (slot + 1)


## "Kuuga Lv3 · Dragon · + Sword Vent" cho dòng người chơi trong phòng.
func _loadout_text(entry: Dictionary) -> String:
	var rider := str(entry.get("rider", ""))
	var parts := PackedStringArray(["%s Lv%d" % [_rider_name(rider), int(entry.get("level", 1))]])
	var form := str(entry.get("form", ""))
	parts.append(_form_name(rider, form) if not form.is_empty() else "form gốc")
	var items: Array = entry.get("items", [])
	if not items.is_empty():
		parts.append("+ " + ", ".join(PackedStringArray(items.map(func(f): return _form_name(rider, str(f))))))
	return " · ".join(parts)


func _form_name(rider: String, form: String) -> String:
	var forms: Dictionary = WorldData.rider_data(StringName(rider)).get("forms", {})
	var name := str((forms.get(StringName(form), {}) as Dictionary).get("name", ""))
	if name.is_empty():
		name = WorldData.form_name(StringName(rider), StringName(form))
	return name if not name.is_empty() else form.capitalize()


func _rider_name(rider: String) -> String:
	var i := WorldData.world_index_of(StringName(rider))
	return str(WorldData.WORLDS[i].get("rider_name", rider)) if i >= 0 else rider


# --- Dựng cảnh --------------------------------------------------------------

func _build_arena() -> void:
	var sky := CanvasLayer.new()
	sky.layer = -10
	add_child(sky)
	var sky_rect := ColorRect.new()
	sky_rect.color = BG_TEX.get_image().get_pixel(0, 0) * BG_TINT
	sky.add_child(sky_rect)
	sky_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)   # phủ cả màn hình máy (Screen)
	var bg := Sprite2D.new()
	bg.texture = BG_TEX
	bg.centered = false
	bg.modulate = BG_TINT
	bg.position = Vector2((VIEW.x - BG_TEX.get_width()) / 2.0, GROUND_Y + 24.0 - BG_TEX.get_height())
	add_child(bg)
	_backdrop = FinisherBackdrop.new()     # sau nền, trước sàn đấu và nhân vật (thêm trước world)
	add_child(_backdrop)

	world = Node2D.new()
	world.name = "World"
	add_child(world)
	# Nền đất, hai vách hai bên (không cho chạy ra khỏi khung 480) và trần (nhảy cao không bay mất).
	# Mặt đất vẽ rộng / sâu hơn khung: máy 20:9 / tablet thấy rộng / cao hơn 480×270 (Screen).
	_solid(Rect2(-40.0, GROUND_Y, VIEW.x + 80.0, 80.0))
	_tiles(TOP_TEX, -240.0, GROUND_Y - 16.0, VIEW.x + 480.0, 32.0)
	_tiles(FILL_TEX, -240.0, GROUND_Y + 16.0, VIEW.x + 480.0, 128.0)
	_solid(Rect2(-40.0, -300.0, 40.0, 600.0))
	_solid(Rect2(VIEW.x, -300.0, 40.0, 600.0))
	_solid(Rect2(-40.0, -80.0, VIEW.x + 80.0, 40.0))
	for p in PLATFORMS:
		var body := StaticBody2D.new()
		body.collision_layer = 0
		body.set_collision_layer_value(Player.PLATFORM_LAYER, true)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(p.z, 8.0)
		shape.shape = rect
		shape.one_way_collision = true
		shape.position = Vector2(p.x + p.z / 2.0, p.y + 4.0)
		body.add_child(shape)
		world.add_child(body)
		_tiles(TOP_TEX, p.x, p.y - 16.0, p.z, 32.0)

	camera = Camera2D.new()
	camera.position = VIEW / 2.0
	add_child(camera)

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = VersusHud.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.wins_needed = WINS_NEEDED
	hud.visible = false
	layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.visible = false
	layer.add_child(_flash)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cutin = SkillCutIn.new()
	layer.add_child(_cutin)
	touch = Node2D.new()
	touch.set_script(TOUCH_SCRIPT)
	touch.visible = false
	layer.add_child(touch)
	# Bảng hướng dẫn nút bấm (bản web, nút "?"): trận qua mạng không dừng được nên không pause
	layer.add_child(HelpOverlay.new())


func _solid(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.get_center()
	body.add_child(shape)
	world.add_child(body)


func _tiles(tex: Texture2D, x: float, y: float, w: float, h: float) -> void:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_TILE
	tr.position = Vector2(x, y)
	tr.size = Vector2(w, h)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(tr)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var ui := Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 8
	ui.theme = theme
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Sảnh
	var box := _screen(ui)
	_menu_root = box.get_parent().get_parent() as Control
	box.add_child(_label("ĐẤU CÙNG WIFI", 16, Color(1, 0.85, 0.3)))
	box.add_child(_label("Tên của bạn: %s" % GameState.player_name, 8, Color(0.75, 0.65, 1)))
	var host_row := HBoxContainer.new()
	host_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_host_button = _button("TẠO PHÒNG 1 VS 1", _on_host.bind("duel"))
	_host_all_button = _button("TẠO PHÒNG ALL COMBAT (2–%d người)" % MAX_PLAYERS, _on_host.bind("all"))
	host_row.add_child(_host_button)
	host_row.add_child(_host_all_button)
	box.add_child(host_row)
	if not VersusLan.can_host():
		_host_button.disabled = true
		_host_all_button.disabled = true
		box.add_child(_label("Trình duyệt không tạo phòng được: tạo phòng trên bản cài (máy tính / Android).", 7,
			Color(1, 0.7, 0.6)))
	box.add_child(_label("Phòng trong mạng WiFi:", 8, Color(0.85, 0.85, 0.95)))
	_room_list = VBoxContainer.new()
	_room_list.add_theme_constant_override("separation", 2)
	box.add_child(_room_list)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_ip_edit = LineEdit.new()
	_ip_edit.custom_minimum_size = Vector2(150, 16)
	_ip_edit.placeholder_text = "IP chủ phòng, vd 192.168.1.5"
	_ip_edit.text_submitted.connect(_join)
	row.add_child(_ip_edit)
	row.add_child(_button("VÀO", func() -> void: _join(_ip_edit.text)))
	box.add_child(row)
	box.add_child(_button("◀ QUAY LẠI", _on_back))
	_status_menu = _label("", 7, Color(1, 0.9, 0.6))
	box.add_child(_status_menu)

	# Phòng
	box = _screen(ui)
	_room_root = box.get_parent().get_parent() as Control
	_room_title = _label("", 14, Color(1, 0.85, 0.3))
	box.add_child(_room_title)
	_room_ip = _label("", 7, Color(0.75, 0.65, 1))
	box.add_child(_room_ip)
	for i in MAX_PLAYERS:
		var l := _label("", 9, VersusHud.SLOT_COLORS[i])
		_slot_labels.append(l)
		box.add_child(l)
	row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_pick_button = _button("CHỌN RIDER", _open_pick)
	_start_button = _button("BẮT ĐẦU", _on_start_pressed)
	row.add_child(_pick_button)
	row.add_child(_start_button)
	row.add_child(_button("RỜI PHÒNG", _leave_room))
	box.add_child(row)
	_status_room = _label("", 7, Color(1, 0.9, 0.6))
	box.add_child(_status_room)

	_rider_select = RiderSelect.new()
	_rider_select.visible = false
	_rider_select.footer = "Bạn chọn: %s · bước sau chọn form và vũ khí · trùng Rider với người khác cũng được"
	_rider_select.chosen.connect(_on_rider_chosen)
	ui.add_child(_rider_select)
	_form_select = FormSelect.new()
	_form_select.visible = false
	_form_select.title = "CHỌN FORM BIẾN ĐỔI"
	_form_select.confirm_text = "TIẾP"
	_form_select.hint = "Tối đa 1 form · chọn form gốc thì chỉ có form gốc · trong trận đổi form bằng Kỹ năng (L), tốn nộ"
	_form_select.done.connect(_on_form_chosen)
	ui.add_child(_form_select)
	_weapon_select = ItemSelect.new()
	_weapon_select.visible = false
	_weapon_select.title = "MANG VŨ KHÍ VÀO TRẬN?"
	_weapon_select.button_text = "XONG"
	_weapon_select.hint = "Vũ khí dùng bằng nút Kỹ năng (L) như đổi form · không mang thì bấm XONG luôn"
	_weapon_select.done.connect(_on_weapons_chosen)
	ui.add_child(_weapon_select)


## Một màn hình giao diện: nền tối phủ đấu trường + cột giữa. Trả về cột (VBoxContainer).
func _screen(parent: Control) -> VBoxContainer:
	var root := Control.new()
	root.visible = false
	parent.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.78)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	center.add_child(box)
	return box


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	# Kích hoạt lúc nhấn (không phải lúc thả), để lần thả phím ở màn trước không bấm nhầm nút vừa hiện ra.
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.pressed.connect(action)
	return b


func _show_menu(message: String) -> void:
	screen = Screen.MENU
	_menu_root.visible = true
	_room_root.visible = false
	_rider_select.visible = false
	_form_select.visible = false
	_weapon_select.visible = false
	hud.visible = false
	touch.visible = false
	lan.start_listening()
	_refresh_rooms()
	_status_menu.text = message
	if VersusLan.can_host():
		_host_button.grab_focus()
	else:
		_ip_edit.grab_focus()


func _show_room(message: String) -> void:
	screen = Screen.ROOM
	_menu_root.visible = false
	_room_root.visible = true
	_rider_select.visible = false
	_form_select.visible = false
	_weapon_select.visible = false
	_refresh_room()
	_status_room.text = message
	if _start_button.visible and not _start_button.disabled:
		_start_button.grab_focus()
	else:
		_pick_button.grab_focus()


func _refresh_rooms() -> void:
	for c in _room_list.get_children():
		c.queue_free()
	if not VersusLan.can_host():
		_room_list.add_child(_label("(trình duyệt không tự tìm phòng được: nhập IP bên dưới)", 7, Color(0.6, 0.6, 0.7)))
		return
	if lan.rooms.is_empty():
		_room_list.add_child(_label("(đang tìm phòng...)", 7, Color(0.6, 0.6, 0.7)))
		return
	for ip in lan.rooms:
		var room: Dictionary = lan.rooms[ip]
		var full := int(room["players"]) >= int(room["max"])
		var kind := "ALL COMBAT" if room["mode"] == "all" else "1 VS 1"
		var b := _button("Phòng của %s · %s %d/%d · %s%s" % [room["name"], kind, room["players"], room["max"], ip,
			" · đã đủ người" if full else ""], _join.bind(String(ip)))
		b.disabled = full
		_room_list.add_child(b)


func _refresh_room() -> void:
	var host_name := _slot_name(0)
	var all := room_mode == "all"
	_room_title.text = "PHÒNG CỦA %s · %s" % [host_name.to_upper(), "ALL COMBAT" if all else "1 VS 1"]
	if multiplayer.is_server():
		var ips := VersusLan.local_ips()
		_room_ip.text = "IP máy này: %s\nMáy khác: bấm vào phòng trong danh sách, hoặc nhập IP này" % \
			(" / ".join(ips) if not ips.is_empty() else "không rõ (máy chưa vào WiFi?)")
	else:
		_room_ip.text = "Đã vào phòng · chủ phòng bấm BẮT ĐẦU khi %s đã chọn Rider" % ("mọi người" if all else "cả hai")
	for slot in MAX_PLAYERS:
		_slot_labels[slot].visible = slot < max_players
		var text := "P%d · đang chờ người vào phòng..." % (slot + 1)
		for id in players:
			if int(players[id]["slot"]) != slot:
				continue
			var rider := str(players[id]["rider"])
			text = "P%d · %s%s · %s" % [slot + 1, players[id]["name"],
				" (bạn)" if id == multiplayer.get_unique_id() else "",
				_loadout_text(players[id]) if not rider.is_empty() else "chưa chọn Rider"]
		_slot_labels[slot].text = text
	_start_button.visible = multiplayer.is_server()
	_start_button.disabled = not _ready_to_start()
	if all and multiplayer.is_server() and players.size() < 2:
		_status_room.text = "ALL COMBAT: chờ thêm người (bắt đầu được khi có từ 2 người, tối đa %d)." % max_players
