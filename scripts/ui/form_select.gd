extends FigurePicker
class_name FormSelect
## Chọn form biến đổi mang vào màn / trận (tối đa 1), sau khi chọn Rider. Form gốc luôn có sẵn (vào màn bằng form
## gốc) nên không nằm trong danh sách; chỉ chọn form biến đổi. Có đúng 1 form thì khỏi chọn (should_skip).
## Trong màn / trận đổi sang form đã chọn bằng Kỹ năng (L), tốn nộ.
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
	var rider_name := base.display_name if base else String(rider)
	if base:
		base.free()
	for f in forms:
		var e := form_entry(rider, f, "form biến đổi")
		e["tag"] = "Đổi sang form này bằng Kỹ năng (L), tốn nộ"
		entries.append(e)
	subtitle = "%s · form gốc luôn có sẵn, chọn 1 form biến đổi" % rider_name
	index = 0
	for i in entries.size():
		if not preselected.is_empty() and entries[i]["id"] == preselected[0]:
			index = i
	_show()


## Chỉ có 0–1 form biến đổi: không cần màn chọn (1 form thì mang luôn form đó).
static func should_skip(forms: Array[StringName]) -> bool:
	return forms.size() <= 1


## Chọn thẳng (bot test): forms rỗng = form đầu danh sách.
func pick(forms: Array[StringName]) -> void:
	index = 0
	for i in entries.size():
		if not forms.is_empty() and entries[i]["id"] == forms[0]:
			index = i
	_confirm()


func _on_confirm() -> void:
	var out: Array[StringName] = []
	if not entries.is_empty() and entries[index]["id"] != &"":
		out.append(entries[index]["id"])
	done.emit(out)
