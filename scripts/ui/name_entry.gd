extends Control
## Màn hình đầu game: người chơi đặt tên cho nhân vật chính.
## Tên được lưu trong GameState.player_name, dùng trong hội thoại ({name}) và HUD.
## Để trống thì dùng tên mặc định (GameState.DEFAULT_PLAYER_NAME).
## Sau đó chạy phần mở đầu (intro) nếu lượt chơi này chưa xem, rồi vào màn chơi.

const INTRO_SCENE := "res://scenes/ui/intro.tscn"
const STAGE_SCENE := "res://scenes/levels/stage_run.tscn"

@onready var name_edit: LineEdit = %NameEdit
@onready var start_button: Button = %StartButton
@onready var preview: Label = %Preview


func _ready() -> void:
	name_edit.max_length = GameState.MAX_NAME_LENGTH
	name_edit.placeholder_text = GameState.DEFAULT_PLAYER_NAME
	if GameState.player_name != GameState.DEFAULT_PLAYER_NAME:
		name_edit.text = GameState.player_name
	name_edit.text_changed.connect(func(_text: String) -> void: _update_preview())
	name_edit.text_submitted.connect(func(_text: String) -> void: _start())
	start_button.pressed.connect(_start)
	_update_preview()
	name_edit.grab_focus()


func _update_preview() -> void:
	var shown := name_edit.text.strip_edges()
	if shown.is_empty():
		shown = GameState.DEFAULT_PLAYER_NAME
	# Câu thoại mẫu của Void ở cuối Hồi 1, cho người chơi thấy tên mình xuất hiện trong truyện.
	preview.text = "\"Về nhà đi, %s.\"" % shown


func _start() -> void:
	GameState.set_player_name(name_edit.text)
	var intro_seen := GameState.seen_story.has("intro") or not GameState.story_enabled
	get_tree().change_scene_to_file(STAGE_SCENE if intro_seen else INTRO_SCENE)
