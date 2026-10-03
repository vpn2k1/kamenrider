extends SceneTree
func _front(tex: Texture2D) -> float:
	var img := tex.get_image()
	var w := img.get_width()
	var hi := -1
	for y in img.get_height():
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				hi = maxi(hi, x)
	return hi + 1 - w / 2.0

func _init() -> void:
	var ef: SpriteFrames = load("res://art/characters/enemy_frames.tres")
	var delays: Array = []
	var shown := 0
	for anim in ef.get_animation_names():
		var a := String(anim)
		if not a.ends_with("_attack"):
			continue
		var n := ef.get_frame_count(anim)
		var best := -1.0
		var bi := 0
		var fronts: Array = []
		for i in n:
			var f := _front(ef.get_frame_texture(anim, i))
			fronts.append(int(f))
			if f > best + 0.5:
				best = f
				bi = i
		var fps := ef.get_animation_speed(anim)
		delays.append(bi / fps)
		if shown < 8:
			print("[strike] %-22s %d khung @%.0ffps · tầm từng khung %s · vươn xa nhất ở khung %d (%.2f s)" % [a, n, fps, fronts, bi, bi / fps])
			shown += 1
	delays.sort()
	print("[strike] %d con · thời điểm tay vươn xa nhất: min %.2f s · trung vị %.2f s · max %.2f s" % [delays.size(), delays[0], delays[delays.size() / 2], delays.back()])
	quit()
