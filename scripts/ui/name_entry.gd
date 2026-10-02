extends Control
class_name NameEntry
## Màn hình nhập tên, mở từ màn hình chính (scenes/ui/main_menu.tscn) sau khi chọn CHƠI hoặc COMBAT.
## Tên được lưu trong GameState.player_name, dùng trong hội thoại ({name}), HUD và tên trong phòng đấu.
## Để trống thì dùng tên mặc định (GameState.DEFAULT_PLAYER_NAME).
##   mode PLAY:   chạy phần mở đầu (intro) nếu lượt chơi này chưa xem, rồi vào màn chơi.
##   mode VERSUS: vào sảnh đấu qua WiFi (1 VS 1 / ALL COMBAT) (scenes/versus/versus.tscn).
## "◀ Quay lại" / Esc về màn hình chính.

enum Mode { PLAY, VERSUS }

const INTRO_SCENE := "res://scenes/ui/intro.tscn"
const STAGE_SCENE := "res://scenes/levels/stage_run.tscn"
const VERSUS_SCENE := "res://scenes/versus/versus.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

## Lựa chọn ở màn hình chính (giữ lại để quay về màn hình chính thì con trỏ ở đúng lựa chọn cũ).
static var mode := Mode.PLAY

@onready var name_edit: LineEdit = %NameEdit
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton
@onready var preview: Label = %Preview


func _ready() -> void:
	name_edit.max_length = GameState.MAX_NAME_LENGTH
	name_edit.placeholder_text = GameState.DEFAULT_PLAYER_NAME
	if GameState.player_name != GameState.DEFAULT_PLAYER_NAME:
		name_edit.text = GameState.player_name
	name_edit.text_changed.connect(func(_text: String) -> void: _update_preview())
	name_edit.text_submitted.connect(func(_text: String) -> void: _start())
	start_button.pressed.connect(_start)
	back_button.pressed.connect(_back)
	start_button.text = "Vào sảnh đấu (Enter)" if mode == Mode.VERSUS else "Bắt đầu (Enter)"
	_update_preview()
	name_edit.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_back()


func _update_preview() -> void:
	var shown := name_edit.text.strip_edges()
	if shown.is_empty():
		shown = GameState.DEFAULT_PLAYER_NAME
	if mode == Mode.VERSUS:
		preview.text = "Tên hiện trong phòng đấu: %s" % shown
	else:
		# Câu thoại mẫu của Void ở cuối Hồi 1, cho người chơi thấy tên mình xuất hiện trong truyện.
		preview.text = "\"Về nhà đi, %s.\"" % shown


func _start() -> void:
	GameState.set_player_name(name_edit.text)
	if mode == Mode.VERSUS:
		get_tree().change_scene_to_file(VERSUS_SCENE)
		return
	var intro_seen := GameState.seen_story.has("intro") or not GameState.story_enabled
	get_tree().change_scene_to_file(STAGE_SCENE if intro_seen else INTRO_SCENE)


func _back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
