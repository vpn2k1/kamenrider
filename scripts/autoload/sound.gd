extends Node
## Âm thanh của game, tạo bằng tools/gen_audio.py. Thiếu file thì lặng lẽ bỏ qua (Rider chưa có giọng đai...).
##   Sound.sfx("punch")               hiệu ứng (audio/sfx/), cao độ lệch ngẫu nhiên nhẹ cho đỡ nhàm
##   Sound.voice("faiz_henshin", 0.5) giọng đai / tiếng hô (audio/voice/) sau `delay` giây; giọng mới cắt giọng cũ
##   Sound.music("stage_kuuga")       nhạc nền (audio/music/) lặp, đổi bài có fade; Sound.music("") tắt nhạc
##   Sound.henshin_ext("faiz")        tiếng biến thân lấy từ phim (audio/henshin_ext/, xem README ở đó); không có thì
##                                    trả false để người gọi dùng tiếng tự tạo
## Bus Music / SFX / Voice tạo lúc chạy, chỉnh bằng set_volume(bus, 0..1).

const SFX_PATH := "res://audio/sfx/%s.wav"
const VOICE_PATH := "res://audio/voice/%s.wav"
const MUSIC_PATH := "res://audio/music/%s.mp3"
const HENSHIN_EXT_PATH := "res://audio/henshin_ext/%s.wav"
const POOL := 14                 ## số hiệu ứng phát cùng lúc
const SAME_SFX_GAP := 30         ## ms: cùng một tiếng không phát dày hơn (nhiều quái trúng một lúc)
const MUSIC_DB := -10.0
const FADE := 0.5
const NO_LOOP := ["clear"]       ## nhạc ngắn không lặp

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


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


func has_sfx(sfx_name: String) -> bool:
	return _load(SFX_PATH % sfx_name) != null


func has_voice(voice_name: String) -> bool:
	return _load(VOICE_PATH % voice_name) != null


func sfx(sfx_name: String, pitch_jitter := 0.06, volume_db := 0.0) -> void:
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
