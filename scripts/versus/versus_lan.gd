extends Node
class_name VersusLan
## Kết nối hai máy cùng mạng WiFi cho chế độ đấu (scripts/versus/versus.gd).
##
##   Kết nối: WebSocket (WebSocketMultiplayerPeer) ở cổng GAME_PORT. Chủ phòng là server, các máy khác là client
##     (ALL COMBAT tới 4 máy: gói giữa hai client đi vòng qua chủ phòng, SceneMultiplayer.server_relay).
##     Chọn WebSocket thay vì ENet để bản web (trình duyệt) cũng VÀO phòng được; trình duyệt không mở server được
##     nên chỉ bản cài (macOS / Windows / Linux / Android) mới TẠO phòng. Trong mạng LAN độ trễ của TCP không đáng kể.
##   Tìm phòng: chủ phòng phát gói UDP broadcast mỗi BROADCAST_INTERVAL giây ở cổng DISCOVERY_PORT
##     ({"game", "name", "port", "players", "max", "mode"}), máy tìm phòng nghe cổng đó và liệt kê các phòng (rooms).
##     Trình duyệt không dùng được UDP: nhập IP chủ phòng bằng tay (chủ phòng hiện IP của mình trên màn hình).
##
## Máy Mac / Windows có thể hỏi cho phép kết nối đến (tường lửa) lần đầu tạo phòng: chọn Cho phép.

signal rooms_changed

const GAME_ID := "chrono_henshin_versus"
const GAME_PORT := 24990
const DISCOVERY_PORT := 24991
const BROADCAST_INTERVAL := 1.0
const ROOM_TIMEOUT := 3.5          ## không nghe thấy phòng quá chừng này giây thì bỏ khỏi danh sách

## Phòng tìm thấy: ip -> {"ip", "name", "port", "players", "max", "mode", "seen"}
var rooms := {}
var room_name := ""
var players_in_room := 1           ## chủ phòng cập nhật để gói broadcast báo phòng đã đầy
var max_players := 2
var mode := "duel"                 ## "duel" (1 vs 1) hoặc "all" (ALL COMBAT, hỗn chiến)

var _peer: WebSocketMultiplayerPeer = null
var _listener: PacketPeerUDP = null
var _sender: PacketPeerUDP = null
var _broadcast_timer := 0.0


## Bản này tạo phòng và tìm phòng tự động được không (trình duyệt thì không).
static func can_host() -> bool:
	return not OS.has_feature("web")


## Tạo phòng: mở server WebSocket và bắt đầu phát broadcast.
func host(name_of_room: String) -> Error:
	close()
	var peer := WebSocketMultiplayerPeer.new()
	var err := peer.create_server(GAME_PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_peer = peer
	room_name = name_of_room
	players_in_room = 1
	_sender = PacketPeerUDP.new()
	_sender.set_broadcast_enabled(true)
	_broadcast_timer = 0.0
	return OK


## Vào phòng ở địa chỉ `ip` (kết quả báo qua multiplayer.connected_to_server / connection_failed).
func join(ip: String) -> Error:
	close()
	var peer := WebSocketMultiplayerPeer.new()
	var err := peer.create_client("ws://%s:%d" % [ip.strip_edges(), GAME_PORT])
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_peer = peer
	return OK


## Ngắt kết nối (rời phòng / đóng phòng), dừng broadcast.
func close() -> void:
	_sender = null
	if _peer:
		_peer.close()
		_peer = null
	# Lúc đóng game (cây đã gỡ node) không còn multiplayer để trả về chế độ offline.
	if is_inside_tree():
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func is_online() -> bool:
	return _peer != null and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Bắt đầu nghe broadcast để tìm phòng. Trả về false nếu không nghe được (trình duyệt, cổng bận).
func start_listening() -> bool:
	stop_listening()
	if not can_host():
		return false
	_listener = PacketPeerUDP.new()
	if _listener.bind(DISCOVERY_PORT) != OK:
		_listener = null
		return false
	return true


func stop_listening() -> void:
	if _listener:
		_listener.close()
	_listener = null
	if not rooms.is_empty():
		rooms.clear()
		rooms_changed.emit()


## Địa chỉ IPv4 trong mạng nội bộ của máy này (để hiện cho máy kia nhập tay).
static func local_ips() -> Array[String]:
	var out: Array[String] = []
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or _is_172_private(ip):
			out.append(ip)
	return out


static func _is_172_private(ip: String) -> bool:
	if not ip.begins_with("172."):
		return false
	var second := ip.get_slice(".", 1).to_int()
	return second >= 16 and second <= 31


func _process(delta: float) -> void:
	if _sender:
		_broadcast_timer -= delta
		if _broadcast_timer <= 0.0:
			_broadcast_timer = BROADCAST_INTERVAL
			_broadcast()
	if _listener:
		_poll_rooms()


func _broadcast() -> void:
	var packet := JSON.stringify({"game": GAME_ID, "name": room_name, "port": GAME_PORT,
		"players": players_in_room, "max": max_players, "mode": mode}).to_utf8_buffer()
	# 255.255.255.255 không phải lúc nào cũng ra được card WiFi (máy nhiều card mạng), nên gửi thêm địa chỉ
	# broadcast của từng mạng /24 mà máy đang ở.
	var targets: Array[String] = ["255.255.255.255"]
	for ip in local_ips():
		var parts := ip.split(".")
		targets.append("%s.%s.%s.255" % [parts[0], parts[1], parts[2]])
	for target in targets:
		_sender.set_dest_address(target, DISCOVERY_PORT)
		_sender.put_packet(packet)


func _poll_rooms() -> void:
	var changed := false
	var now := Time.get_ticks_msec() / 1000.0
	while _listener.get_available_packet_count() > 0:
		var data = JSON.parse_string(_listener.get_packet().get_string_from_utf8())
		var ip := _listener.get_packet_ip()
		if typeof(data) != TYPE_DICTIONARY or data.get("game", "") != GAME_ID or ip.is_empty():
			continue
		var known: bool = rooms.has(ip)
		var old_players: int = rooms[ip]["players"] if known else -1
		rooms[ip] = {"ip": ip, "name": str(data.get("name", "?")), "port": int(data.get("port", GAME_PORT)),
			"players": int(data.get("players", 1)), "max": int(data.get("max", 2)), "mode": str(data.get("mode", "duel")),
			"seen": now}
		if not known or old_players != rooms[ip]["players"]:
			changed = true
	for ip in rooms.keys():
		if now - float(rooms[ip]["seen"]) > ROOM_TIMEOUT:
			rooms.erase(ip)
			changed = true
	if changed:
		rooms_changed.emit()
