extends RefCounted
class_name Skills
## Skill theo form (docs/SKILLS.md): mỗi form có 2 skill (Skill 1 nhẹ, Skill 2 mạnh) và một kiểu Final Attack.
## Dữ liệu viết gọn trong form ("skills": [s1, s2], "final_type"), resolve() điền mặc định theo bậc và kiểu.
## Player.skill_caster (SkillCaster) thi triển.
##
## Một skill (Dictionary). Bắt buộc "name", "type"; còn lại tùy chọn:
##   "type"     "aim" [Đ] định hướng · "lock" [K] khoá mục tiêu · "lock_multi" [K×n] · "bind" [T] trói
##              · "area" [V] vùng quanh mình · "counter" [P] phản đòn · "buff" [C] cường hoá
##   "move"     (aim) "dash" lướt đánh cận chiến (mặc định) · "shot" một viên đạn · "spread" loạt đạn tỏa
##              · "wave" sóng chém to bay xuyên · "leap" nhảy vọt rồi bổ xuống · "pull" móc kéo quái về
##              · "boomerang" ném ra rồi bay về · "steer" như boomerang, giữ ↑ / ↓ để lái (Den-O Sword)
##   "via"      (bind) "lock" khoá quái gần (mặc định) · "shot" bắn vật trói theo hướng · "area" trói mọi quái quanh mình
##   "bind"     giây trói (mặc định BIND_TIME)        "targets"  số quái của lock_multi (mặc định 3)
##   "charge"   (lock) giây tụ / dấu khoá trước khi ra đòn (mặc định LOCK_TIME)
##   "slow"     (area) quái trong vùng chậm lại chừng này giây
##   "range"    tầm khoá phía trước (px, LOCK_RANGE)  "radius"   bán kính vùng (px, AREA_RADIUS)
##   "dmg"      hệ số sát thương so với mặc định của bậc / kiểu
##   "hits"     số nhịp trúng (chia đều tổng sát thương) "tags"     tag hiệu ứng (&"burn", &"force", &"bind"...)
##   "knockback" Vector2 (x âm = hút về phía Rider)   "anim"     "light" | "heavy" | "slash" | "final"
##   "fx"       Fx.KINDS hiện trên quái trúng / quanh Rider ("dragon", "seal", "lightning"...)
##   "summon"   Fx.KINDS hiện quanh Rider lúc tung (gọi quái thú, đồng đội: "dragon", "tire"...)
##   "shot"     (shot / spread / wave / boomerang / steer) {"style", "speed", "radius", "count", "spread", "pierce", "life"}
##   "buff"     (buff) {"time": giây, và các hiệu ứng: "atk" ×sát thương, "speed" ×tốc độ, "guard" ×sát thương nhận,
##              "superarmor" không bị khựng, "clock" tăng tốc thời gian, "homing" đạn Bắn tự đuổi, "clones" số phân thân,
##              "fly" bay, "invis" tàng hình (quái mất dấu), "phase" bất tử, "liquid" đòn cận chiến xuyên qua người,
##              "dodge_next" tự né đòn kế tiếp, "expose" quái quanh mình mất giáp / kháng, "taunt" khiêu khích,
##              "elements" đòn đổi nguyên tố theo vòng, "heal" hồi máu (phần máu tối đa), "behind" trồi ra sau lưng quái}
##   "heal"     hồi chừng này phần máu Rider tối đa lúc tung (mọi kiểu)
##   "color"    màu hiệu ứng / đạn của skill (mặc định màu form)
##   "icon"     icon nút (SkillIcons.NAMES), mặc định tự chọn theo kiểu và tag
##   "special"  skill viết riêng: "drum" đánh trống theo nhịp (Hibiki Ongekidaiko)
##
## Form mượn sức Rider khác (Decade Kamen Ride, Zi-O Armor): "skills_from": [rider, form] thay cho "skills", skill
## lấy nguyên từ form gốc đó (sửa Rider gốc là form mượn đổi theo).
##
## Final Attack: "final_type" (mặc định "aim" = đòn Final của kiểu đòn như trước). "lock" / "lock_multi" (+ "final_targets")
## / "bind" khoá rồi ra đòn chắc trúng; "area" trúng mọi quái quanh mình; "counter" thế chờ, bị đánh thì phản đòn,
## hết thế mà không ai đánh thì tự tung cú đá.

const TYPES := ["aim", "lock", "lock_multi", "bind", "area", "counter", "buff"]
const TYPE_MARK := {"aim": "Đ", "lock": "K", "lock_multi": "K×", "bind": "T", "area": "V", "counter": "P", "buff": "C"}
const TYPE_NAME := {"aim": "định hướng", "lock": "khoá mục tiêu", "lock_multi": "khoá nhiều", "bind": "trói",
	"area": "vùng", "counter": "phản đòn", "buff": "cường hoá"}
const MOVES := ["dash", "shot", "spread", "wave", "leap", "pull", "boomerang", "steer"]

const COST := [15.0, 30.0]           ## nộ của Skill 1 / Skill 2
const LOCK_EXTRA_COST := 5.0         ## skill khoá / trói đắt hơn cùng bậc (không trượt)
const COOLDOWN := [2.0, 5.0]
const FINAL_COST := 60.0
## Sát thương gốc [Đ] của bậc (trước sức đánh form, cấp): Skill 1 ngang cú đá kết chuỗi (12), Skill 2 hơn một chút.
## Chỉ Final Attack (~60) mới là đòn mạnh; skill là công cụ (khoá, trói, vùng, buff), không thay Final.
const BASE_DAMAGE := [9.0, 14.0]
const MAX_DMG_MULT := 1.2            ## "dmg" ghi trong dữ liệu không vượt quá mức này
const TYPE_DAMAGE := {"aim": 1.0, "lock": 0.7, "lock_multi": 0.5, "bind": 0.5, "area": 0.8, "counter": 1.2, "buff": 0.0}
const FINAL_TYPE_DAMAGE := {"aim": 1.0, "lock": 0.7, "lock_multi": 0.5, "bind": 0.8, "area": 0.8, "counter": 1.2}
const LOCK_RANGE := 160.0
const AREA_RADIUS := 70.0
const BIND_TIME := 2.5
const LOCK_TIME := 0.4               ## dấu khoá hiện chừng này giây trước khi ra đòn
const COUNTER_WINDOW := 0.5
const FINAL_COUNTER_WINDOW := 1.2
const BUFF_TIME := 6.0


## Điền mặc định cho skill bậc `tier` (0 = Skill 1, 1 = Skill 2). Trả bản sao.
static func resolve(spec: Dictionary, tier: int) -> Dictionary:
	var s := spec.duplicate(true)
	var type := str(s.get("type", "aim"))
	s["type"] = type
	s["tier"] = tier
	var locking := type in ["lock", "lock_multi", "bind"]
	s["cost"] = float(s.get("cost", COST[tier] + (LOCK_EXTRA_COST if locking else 0.0)))
	s["cooldown"] = float(s.get("cooldown", COOLDOWN[tier]))
	# "damage" = sát thương MỖI nhịp: tổng của skill chia đều cho "hits" (nhiều nhịp không mạnh hơn một nhịp).
	var total: float = BASE_DAMAGE[tier] * float(TYPE_DAMAGE.get(type, 1.0)) * minf(float(s.get("dmg", 1.0)), MAX_DMG_MULT)
	s["damage"] = total / maxf(float(s.get("hits", 1)), 1.0)
	if type == "aim" and not s.has("move"):
		s["move"] = "dash"
	if type == "lock_multi" and not s.has("targets"):
		s["targets"] = 3
	if type == "bind" and not s.has("bind"):
		s["bind"] = BIND_TIME
	if type == "buff":
		var b: Dictionary = s.get("buff", {})
		if not b.has("time"):
			b["time"] = BUFF_TIME
		s["buff"] = b
	if not s.has("tags"):
		s["tags"] = []
	return s


## Chữ ngắn "[Đ]", "[K×3]"... của một skill / kiểu Final.
static func mark(type: String, targets := 0) -> String:
	var m := str(TYPE_MARK.get(type, "Đ"))
	if type == "lock_multi":
		m += str(targets if targets > 0 else 3)
	return "[%s]" % m


## "Mighty Punch [Đ] · 15 nộ" cho màn chọn form / bảng nút.
static func describe(s: Dictionary) -> String:
	return "%s %s · %d nộ" % [s.get("name", "?"), mark(str(s["type"]), int(s.get("targets", 0))), int(s["cost"])]
