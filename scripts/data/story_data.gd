extends RefCounted
class_name StoryData
## Kịch bản: phần mở đầu (scenes/ui/intro.tscn) và hội thoại trong từng màn (DialogueBox).
##
## Một câu thoại là [người nói, lời]. Người nói là khóa trong SPEAKERS. "{name}" trong lời được thay
## bằng tên người chơi (GameState.format_text); người nói "hero" cũng hiện tên đó.
##
## Hội thoại trong màn nằm trong file của từng thế giới (scripts/data/worlds/, hằng STORY, khóa "1".."4", "B"),
## WorldData gộp lại theo mã màn ("4-2"...). Mỗi màn gồm các "nhịp":
##   "start" : đầu màn, trước màn chọn Rider
##   "goal"  : tới vạch đích của màn Thức tỉnh / Trùm, trước khi nhóm canh giữ hoặc trùm xuất hiện
##   "key"   : vừa nhặt món chính của màn (Driver hoặc form), sau cảnh biến thân
##   "clear" : qua màn, trước bảng kết quả
## Sau trùm mỗi thế giới còn có WORLD_CLEAR của file thế giới: hiện trên bản đồ Chuỗi Trái Đất.
## Mỗi nhịp chỉ hiện một lần mỗi lượt chơi (GameState.seen_story), gục rồi chơi lại không lặp.
##
## Người nói: BASE_SPEAKERS dùng chung + SPEAKERS của các file thế giới. "portrait" là tên ảnh trong
## art/ui/portraits/; "look" để tools/gen_story_art.py vẽ chân dung (xem ghi chú ở script đó).

const BASE_SPEAKERS := {
	"narrator": {"name": "", "color": Color(0.72, 0.72, 0.85)},
	"hero": {"name": "{name}", "color": Color(0.35, 0.6, 1.0), "portrait": "hero"},
	"pen": {"name": "PEN", "color": Color(0.35, 0.95, 0.88), "portrait": "pen"},
	"void": {"name": "CHRONOS VOID", "color": Color(0.72, 0.4, 1.0), "portrait": "void"},
}

static var SPEAKERS: Dictionary = _speakers()


static func _speakers() -> Dictionary:
	var out := BASE_SPEAKERS.duplicate()
	out.merge(WorldData.speakers, false)
	return out


## Phần mở đầu: mỗi cảnh có một hình nền vẽ bằng code (Intro._draw_<scene>) và các câu thoại.
const INTRO := [
	{"scene": "multiverse", "lines": [
		["narrator", "Vũ trụ không chỉ có một Trái Đất."],
		["narrator", "Có vô số Trái Đất song song. Mỗi Trái Đất là một thế giới, và mỗi thế giới có một Kamen Rider bảo vệ."],
		["narrator", "Sức mạnh của họ nằm trong Driver, chiếc đai giúp họ biến thân."],
	]},
	{"scene": "theft", "lines": [
		["narrator", "Rồi một kẻ xuất hiện giữa các Trái Đất."],
		["void", "Năm mươi lăm năm. Bao nhiêu anh hùng..."],
		["void", "...vậy mà thế giới của ta không có lấy một người."],
		["narrator", "Chronos Void rút sạch sức mạnh khỏi Driver của mọi Rider. Từng Trái Đất lần lượt tắt sáng."],
	]},
	{"scene": "escape", "lines": [
		["void", "Với sức mạnh này, ta sẽ viết lại thời gian. Một thế giới không cần đến anh hùng."],
		["narrator", "Hắn mang theo tất cả, trốn tới ĐIỂM KHÔNG, Trái Đất nằm ở tận cùng, ngoài mọi dòng thời gian."],
		["narrator", "Sau lưng, hắn khóa đường bằng CHUỖI PHONG ẤN. Sức mạnh của mỗi Driver bị cấy vào quái vật ở từng Trái Đất."],
		["void", "Nếu có kẻ nào đi được hết chuỗi này, ta sẽ đợi hắn ở cuối."],
	]},
	{"scene": "tokyo", "lines": [
		["narrator", "Tokyo, năm 2026. Một Trái Đất chưa từng có Kamen Rider."],
		["narrator", "Đêm đó, bầu trời nứt ra như mặt kính."],
		["hero", "Cái gì thế kia...? Sét màu tím à?"],
		["narrator", "Từ khe nứt, một chiếc đai rơi xuống Shibuya. Theo sau nó là lũ quái vật."],
	]},
	{"scene": "pen", "lines": [
		["pen", "Ái da! Này, cậu kia! Cậu nhìn thấy tôi à? Tốt quá!"],
		["hero", "Một... tấm vé tàu biết nói?!"],
		["pen", "Tôi là Pen, sống trong Chrono Pass. Tấm vé này đọc được Driver và mở cổng sang các Trái Đất khác."],
		["pen", "Nghe kỹ này: Chronos Void vừa lấy hết sức mạnh của các Driver rồi trốn tới Điểm Không."],
		["pen", "Void khóa chuỗi theo đúng thứ tự các Rider ra đời: Kuuga, Agito, Ryuki... hai mươi bảy Trái Đất. Mỗi nơi lấy lại sức mạnh của một Driver."],
		["hero", "Khoan đã. Tôi chỉ là người giao hàng thôi mà!"],
		["pen", "Chrono Pass đã chọn cậu, {name}. Mà lũ Grongi kia cũng chẳng đợi cậu nghĩ xong đâu."],
	]},
	{"scene": "mission", "lines": [
		["pen", "Nhiệm vụ của cậu: lấy lại sức mạnh của mọi Driver, đi hết Chuỗi Phong Ấn, rồi chặn Void ở Điểm Không."],
		["hero", "...Được rồi. Giao hàng tận nơi là nghề của tôi mà."],
		["pen", "Chặng đầu tiên: chiếc đai vừa rơi xuống là Arcle, Driver của Kuuga. Đi giành lại nó thôi!"],
	]},
]


## Hội thoại của một nhịp trong màn. [] = không có.
static func stage_beat(stage_id: String, beat: String) -> Array:
	var stage: Dictionary = WorldData.stories.get(stage_id, {})
	return stage.get(beat, [])


## Thoại trên bản đồ Chuỗi Trái Đất sau khi hạ trùm thế giới world_id.
static func world_clear(world_id: String) -> Array:
	return WorldData.world_clear.get(world_id, [])
