extends Node
## Âm thanh của game, tạo bằng tools/gen_audio.py. Thiếu file thì lặng lẽ bỏ qua (Rider chưa có giọng đai...).
##   Sound.sfx("punch")               hiệu ứng (audio/sfx/), cao độ lệch ngẫu nhiên nhẹ cho đỡ nhàm
##   Sound.voice("faiz_henshin", 0.5) giọng đai / tiếng hô (audio/voice/) sau `delay` giây; giọng mới cắt giọng cũ
##   Sound.music("stage_kuuga")       nhạc nền (audio/music/) lặp, đổi bài có fade; Sound.music("") tắt nhạc
##   Sound.henshin_ext("faiz")        tiếng biến thân lấy từ phim (audio/henshin_ext/, xem README ở đó); không có thì
##                                    trả false để người gọi dùng tiếng tự tạo
## Bus Music / SFX / Voice tạo lúc chạy, chỉnh bằng set_volume(bus, 0..1).
## Cài đặt (màn Cài đặt, scripts/ui/settings_menu.gd): âm lượng chung (bus Master) và bật / tắt từng nhóm CATEGORIES.
## Nhóm của một tiếng tính theo tên (category_of_sfx / category_of_voice). Lưu trong GameState.SETTINGS_PATH, mục "audio".

const SFX_PATH := "res://audio/sfx/%s.wav"
const VOICE_PATH := "res://audio/voice/%s.wav"
const MUSIC_PATH := "res://audio/music/%s.mp3"
const HENSHIN_EXT_PATH := "res://audio/henshin_ext/%s.wav"
const POOL := 14                 ## số hiệu ứng phát cùng lúc
const SAME_SFX_GAP := 30         ## ms: cùng một tiếng không phát dày hơn (nhiều quái trúng một lúc)
const MUSIC_DB := -10.0
const FADE := 0.5
const NO_LOOP := ["clear"]       ## nhạc ngắn không lặp
## Nhóm âm thanh bật / tắt được, theo thứ tự hiện ở màn Cài đặt: [khóa, tên, tiếng nghe thử khi bật lại]
const CATEGORIES := [
	["music", "Nhạc nền", ""],
	["combat", "Đánh, chém, bắn, trúng đòn", "punch"],
	["skill", "Kỹ năng, đổi form, tuyệt chiêu", "final_charge"],
	["henshin", "Biến thân (tiếng + giọng đai)", "henshin_flash"],
	["enemy", "Quái (bắn, gục, trùm xuất hiện)", "enemy_die"],
	["move", "Nhảy, né, bị thương", "jump"],
	["ui", "Menu, hội thoại, nhặt đồ", "ui_ok"],
]
const SKILL_SFX := ["form_change", "final_charge", "final_impact", "clock_up", "rage_full"]
const ENEMY_SFX := ["enemy_shot", "enemy_die", "boss_appear"]
const MOVE_SFX := ["jump", "dodge", "hurt", "break", "ko"]
const UI_SFX := ["ui_move", "ui_ok", "ui_back", "text_blip", "pickup", "pickup_key"]

var master_volume := 1.0
var enabled := {}                ## khóa nhóm → bool

var _cache := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}
var _voice: AudioStreamPlayer
var _voice_token := 0
var _music: AudioStreamPlayer
var _music_name := ""
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX", "Voice"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_voice = AudioStreamPlayer.new()
	_voice.bus = "Voice"
	_voice.volume_db = 2.0
	add_child(_voice)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = MUSIC_DB
	add_child(_music)
	for c in CATEGORIES:
		enabled[c[0]] = true
	load_settings()


# --- Cài đặt ------------------------------------------------------------------

## Nhóm của một hiệu ứng (audio/sfx/<tên>).
static func category_of_sfx(sfx_name: String) -> String:
	if sfx_name.begins_with("henshin_"):
		return "henshin"
	if SKILL_SFX.has(sfx_name):
		return "skill"
	if ENEMY_SFX.has(sfx_name):
		return "enemy"
	if MOVE_SFX.has(sfx_name):
		return "move"
	if UI_SFX.has(sfx_name):
		return "ui"
	return "combat"   # đấm, đá, chém, bắn, trúng đòn, chém đạn, hiệu ứng cháy / điện / băng / choáng


## Nhóm của một giọng (audio/voice/<tên>): tiếng hô biến thân là "henshin", đổi form / tuyệt chiêu là "skill".
static func category_of_voice(voice_name: String) -> String:
	return "henshin" if voice_name.ends_with("_henshin") else "skill"


func is_enabled(category: String) -> bool:
	return bool(enabled.get(category, true))


func set_enabled(category: String, on: bool) -> void:
	enabled[category] = on
	if category == "music":
		var idx := AudioServer.get_bus_index("Music")
		if idx >= 0:
			AudioServer.set_bus_mute(idx, not on)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_mute(0, master_volume <= 0.001)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(GameState.SETTINGS_PATH) == OK and GameState.persist:
		master_volume = float(cfg.get_value("audio", "master", 1.0))
		for c in CATEGORIES:
			enabled[c[0]] = bool(cfg.get_value("audio", c[0], true))
	set_master_volume(master_volume)
	for c in CATEGORIES:
		set_enabled(c[0], enabled[c[0]])


## Ghi mục "audio", giữ các mục khác của file cài đặt (tên người chơi...).
func save_settings() -> void:
	if not GameState.persist:
		return
	var cfg := ConfigFile.new()
	cfg.load(GameState.SETTINGS_PATH)
	cfg.set_value("audio", "master", master_volume)
	for c in CATEGORIES:
		cfg.set_value("audio", c[0], enabled[c[0]])
	cfg.save(GameState.SETTINGS_PATH)


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


func has_sfx(sfx_name: String) -> bool:
	return _load(SFX_PATH % sfx_name) != null


func has_voice(voice_name: String) -> bool:
	return _load(VOICE_PATH % voice_name) != null


func sfx(sfx_name: String, pitch_jitter := 0.06, volume_db := 0.0) -> void:
	if not is_enabled(category_of_sfx(sfx_name)):
		return
	var stream := _load(SFX_PATH % sfx_name)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(sfx_name, -1000)) < SAME_SFX_GAP:
		return
	_last[sfx_name] = now
	var p := _pool[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db
	p.play()


## Giọng đai / tiếng hô. Trả false nếu không có file (để gọi giọng dự phòng).
func voice(voice_name: String, delay := 0.0) -> bool:
	var stream := _load(VOICE_PATH % voice_name)
	if stream == null:
		return false
	if not is_enabled(category_of_voice(voice_name)):
		return true         # tắt nhóm này: coi như đã phát, không gọi giọng dự phòng
	_voice_token += 1
	if delay > 0.0:
		get_tree().create_timer(delay, true, false, true).timeout.connect(_play_voice.bind(stream, _voice_token))
	else:
		_play_voice(stream, _voice_token)
	return true


func henshin_ext(rider: String) -> bool:
	var stream := _load(HENSHIN_EXT_PATH % rider)
	if stream == null:
		return false
	if not is_enabled("henshin"):
		return true
	_voice_token += 1
	_play_voice(stream, _voice_token)
	return true


func _play_voice(stream: AudioStream, token: int) -> void:
	if token != _voice_token:
		return              # đã có giọng mới hơn
	_voice.stream = stream
	_voice.play()


func music(music_name: String) -> void:
	if music_name == _music_name:
		return
	_music_name = music_name
	var stream := _load(MUSIC_PATH % music_name) if music_name != "" else null
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = not NO_LOOP.has(music_name)
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -40.0, FADE)
	_music_tween.tween_callback(func() -> void:
		_music.stop()
		if stream:
			_music.stream = stream
			_music.volume_db = -40.0
			_music.play())
	if stream:
		_music_tween.tween_property(_music, "volume_db", MUSIC_DB, FADE)


func _exit_tree() -> void:
	if _music_tween:
		_music_tween.kill()
	_voice_token += 1
	_cache.clear()
	for p in _pool:
		p.stream = null
	_voice.stream = null
	_music.stream = null


func current_music() -> String:
	return _music_name


func set_volume(bus: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))
