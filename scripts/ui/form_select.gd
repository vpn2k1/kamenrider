extends FigurePicker
class_name FormSelect
## Chọn form biến đổi mang vào màn / trận (tối đa 1), sau khi chọn Rider. Form gốc luôn có và đứng đầu hàng:
## chọn form gốc = không mang form biến đổi. Trong màn / trận đổi sang form đã chọn bằng Kỹ năng (L), tốn nộ.
## Ở hành trình, form nhặt được giữa màn vẫn dùng được ngay (GameState.unlock_form).
## Mỗi form là hình đứng + tên dưới chân (FigurePicker); chạm để xem chỉ số của form đó, bấm TIẾP để xác nhận.

signal done(forms: Array[StringName])


## forms: các form biến đổi đã nhặt (GameState.owned_forms); preselected: form chọn lần trước (rỗng = form gốc).
func open(rider: StringName, forms: Array[StringName], preselected: Array[StringName]) -> void:
	if title == "":
		title = "CHỌN FORM"
	if confirm_text == "CHỌN":
		confirm_text = "TIẾP"
	multi = false
	entries.clear()
	var base := preview_form(rider, &"")
	var base_id := base.base_form() if base else &""
	var rider_name := base.display_name if base else String(rider)
	if base:
		base.free()
	var first := form_entry(rider, base_id, "form gốc")
	first["id"] = &""
	first["tag"] = "Chọn form gốc = không mang form biến đổi"
	entries.append(first)
	for f in forms:
		var e := form_entry(rider, f, "form biến đổi")
		e["tag"] = "Đổi sang form này bằng Kỹ năng (L), tốn nộ"
		entries.append(e)
	subtitle = "%s · tối đa 1 form ngoài form gốc" % rider_name
	index = 0
	for i in entries.size():
		if not preselected.is_empty() and entries[i]["id"] == preselected[0]:
			index = i
	_show()


## Chọn thẳng (bot test): forms rỗng = form gốc.
func pick(forms: Array[StringName]) -> void:
	index = 0
	for i in entries.size():
		if not forms.is_empty() and entries[i]["id"] == forms[0]:
			index = i
	_confirm()


func _on_confirm() -> void:
	var out: Array[StringName] = []
	if entries[index]["id"] != &"":
		out.append(entries[index]["id"])
	done.emit(out)
