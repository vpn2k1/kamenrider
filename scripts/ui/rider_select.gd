extends FigurePicker
class_name RiderSelect
## Chọn Rider dùng trong màn (mỗi màn một Rider) hoặc mang vào trận đấu. Ở hành trình chỉ hiện khi có từ 2 Rider.
## Mỗi Rider là hình đứng + tên dưới chân (FigurePicker); chạm để xem thông số form gốc ở cấp hiện tại
## (Máu · Giáp · Tốc độ · Sức đánh · Nhảy), mô tả lối chơi, số form đã có, sức mạnh thế hệ (RiderForm.power), thẻ
## Skill 1 / Skill 2 / Final có icon theo từng form đã có (◀ tên form ▶ đổi form xem, hình đổi theo), và dấu "★ Rider thế giới" (Driver / form / item của màn là của Rider này; nhặt khi dùng Rider khác thì chỉ
## mở khóa, dùng ở màn sau). Bấm CHỌN để xác nhận. Có tới 27 Rider: kéo ngang để cuộn.

signal chosen(id: StringName)

## Dòng gợi ý dưới tiêu đề: "%s" = tên Rider đang xem. Chế độ đấu đặt lại câu khác.
var footer := "Rider trong màn: %s · bước sau chọn form và item"


## options: các Rider chọn được; current: Rider chính lần trước (chọn sẵn); colors: màu theo rider_id.
func open(options: Array[StringName], title_text: String, subtitle_text: String, current: StringName,
		colors: Dictionary) -> void:
	title = title_text
	subtitle = subtitle_text
	confirm_text = "CHỌN"
	multi = false
	entries.clear()
	var world_rider := GameState.world_rider()
	for id in options:
		var form := GameState.create_form(id)
		if form == null:
			continue
		var lines: Array = [form.tagline, "Form đã có: %d · Sức mạnh thế hệ ×%.2f" % [GameState.form_count(id), form.power]]
		# Skill theo từng form đã có (◀ ▶ trong bảng): form khác có skill và hình khác.
		var sets: Array = []
		for fid in RiderCaps.owned_forms(id):
			var pf := preview_form(id, fid)
			if pf:
				sets.append(skill_set(pf, form_label(id, fid)))
				pf.free()
		entries.append({
			"id": id, "name": form.display_name.replace("Kamen Rider ", "").to_upper(), "sub": "Lv%d" % form.level,
			"prefix": form.animation_prefix(), "fallback": "human", "color": colors.get(id, WorldData.rider_color(id)),
			"stats": form.stat_summary(), "lines": lines, "skill_sets": sets,
			"tag": "★ Rider thế giới: form / item rơi ở màn này là của Rider này" if id == world_rider else "",
		})
		form.free()
	index = 0
	for i in entries.size():
		if entries[i]["id"] == current:
			index = i
	_show()


## Chọn thẳng một Rider (dùng cho bot test).
func pick(id: StringName) -> void:
	for i in entries.size():
		if entries[i]["id"] == id:
			index = i
			_confirm()
			return


func _process(delta: float) -> void:
	if visible and not entries.is_empty():
		hint = footer % entries[index]["name"] if "%s" in footer else footer
	super(delta)


func _on_confirm() -> void:
	chosen.emit(entries[index]["id"])
