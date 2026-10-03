extends RefCounted
class_name SkillIcons
## Hình trên nút Skill 1 / Skill 2 / Final (art/ui/skill_icons/<tên>.png, 48×48, vẽ bằng PixelLab).
## Bộ icon chung theo kiểu skill và hiệu ứng (không vẽ riêng từng skill): pick() chọn icon hợp nhất cho một skill
## theo "icon" ghi tay (nếu có) → skill riêng → kiểu buff → kiểu skill → nguyên tố → cách ra đòn.

const DIR := "res://art/ui/skill_icons/"
const NAMES := ["punch", "kick", "slash", "fire", "lightning", "ice", "wind", "dragon", "shield", "clock", "clones",
	"wings", "chains", "crosshair", "shockwave", "bullets", "spinblade", "drum", "ghost", "aura"]
## Tag nguyên tố → icon (xét theo thứ tự).
const ELEMENT := [[&"burn", "fire"], [&"shock", "lightning"], [&"freeze", "ice"], [&"force", "wind"]]

static var _cache := {}


## Tên icon cho skill đã resolve (Skills.resolve).
static func pick(s: Dictionary) -> String:
	if s.has("icon"):
		return str(s["icon"])
	if str(s.get("special", "")) == "drum":
		return "drum"
	if str(s.get("summon", "")) == "dragon" or str(s.get("fx", "")) == "dragon":
		return "dragon"
	var type := str(s.get("type", "aim"))
	var tags: Array = s.get("tags", [])
	match type:
		"buff":
			var b: Dictionary = s.get("buff", {})
			if b.has("clock"):
				return "clock"
			if b.has("clones"):
				return "clones"
			if b.has("fly"):
				return "wings"
			if b.has("invis") or b.has("phase") or b.has("behind") or b.has("liquid"):
				return "ghost"
			if b.has("guard") or b.has("superarmor"):
				return "shield"
			if b.has("homing") or b.has("expose") or b.has("dodge_next"):
				return "crosshair"
			if b.has("elements"):
				return "fire"
			return "aura"
		"counter":
			return "shield"
		"bind":
			return "chains"
		"lock", "lock_multi":
			return "crosshair"
		"area":
			return _element(tags, "shockwave")
	match str(s.get("move", "dash")):
		"shot", "spread":
			return _element(tags, "bullets")
		"wave":
			return "slash"
		"boomerang", "steer":
			return "spinblade"
		"leap":
			return "kick"
	if str(s.get("anim", "")) == "slash":
		return _element(tags, "slash")
	return _element(tags, "punch")


static func _element(tags: Array, fallback: String) -> String:
	for pair in ELEMENT:
		if tags.has(pair[0]):
			return pair[1]
	return fallback


## Ảnh của icon `icon_name` (null nếu chưa vẽ: nút dùng biểu tượng mặc định).
static func texture(icon_name: String) -> Texture2D:
	if not _cache.has(icon_name):
		var path := DIR + icon_name + ".png"
		_cache[icon_name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[icon_name]
