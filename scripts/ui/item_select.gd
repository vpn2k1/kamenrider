extends FigurePicker
class_name ItemSelect
## Chọn item mang vào màn (sau khi chọn Rider và form): item là form chỉ gồm vũ khí / lá bài / đòn ("item": true trong
## RIDER, ví dụ Ryuki Sword Vent), quái rơi ở các màn của thế giới đó. Mang tối đa GameState.MAX_ITEMS món.
## Trong màn, item mang theo vào vòng Kỹ năng (L) như form; item không mang thì không dùng được.
## Mỗi item là hình đứng + tên dưới chân (FigurePicker, chọn nhiều): chạm để xem chỉ số, chạm lần nữa hoặc nút
## "MANG THEO" để bật / tắt, bấm VÀO MÀN để xác nhận. Chế độ đấu dùng lại để chọn vũ khí mang vào trận bằng cách đổi
## các chữ (title, button_text, hint, on_text, off_text).

signal done(items: Array[StringName])

var button_text := "VÀO MÀN"


func _init() -> void:
	super()
	multi = true
	max_pick = GameState.MAX_ITEMS
	title = "CHỌN ITEM MANG VÀO MÀN"
	hint = "Item dùng bằng nút Kỹ năng (L) như đổi form · item không mang thì không dùng được"


func open(rider: StringName, items: Array[StringName], preselected: Array[StringName]) -> void:
	confirm_text = button_text
	entries.clear()
	picked.clear()
	for f in items:
		entries.append(form_entry(rider, f, "item"))
		if preselected.has(f) and picked.size() < max_pick:
			picked.append(entries.size() - 1)
	var wi := WorldData.world_index_of(rider)
	subtitle = "%s · tối đa %d món" % [str(WorldData.rider_data(rider).get("name",
		"Kamen Rider %s" % WorldData.WORLDS[wi]["rider_name"] if wi >= 0 else String(rider))), max_pick]
	index = 0
	_show()


## Chọn thẳng (bot test).
func pick(items: Array[StringName]) -> void:
	picked.clear()
	for i in entries.size():
		if items.has(entries[i]["id"]) and picked.size() < max_pick:
			picked.append(i)
	_confirm()


func _on_confirm() -> void:
	var out: Array[StringName] = []
	for i in picked:
		out.append(entries[i]["id"])
	done.emit(out)
