extends RefCounted
## Thế giới phụ (nhánh rẽ): mở sau khi giải cứu thế giới cha (WORLD "parent"), không nằm trong chuỗi Driver.
## Mỗi màn là một trận ĐẤU RIDER (WorldData.StageType.DUEL): đi một đoạn ngắn với quái của thế giới Rider đó, cuối
## đường là chính Rider ấy (hình art/characters/enemy_frames.tres "rider_<id>"). Thắng thì nhặt form của Rider cha
## (thẻ Kamen Ride của Decade / Ride Watch của Zi-O). Màn của Rider nào chỉ mở khi đã giải cứu thế giới của Rider đó,
## nên qua thêm thế giới chính thì thế giới phụ có thêm màn.
##
## Khóa của một thế giới phụ:
##   "id"           id thế giới (mã màn "<số>-<thứ tự>", số = 27 + thứ tự trong WORLDS)
##   "parent"       Rider của thế giới cha (Rider nhận form)
##   "name", "motto", "title" (chữ trên bản đồ thay cho "THẾ GIỚI N")
##   "stage_name"   tên màn: {rider} = tên Rider, {year} = năm thế giới của Rider đó
##   "form_suffix"  id form = id Rider + hậu tố ("" → &"kuuga", "_armor" → &"kuuga_armor"); form phải có trong RIDER.forms
##   "duels"        các Rider đối thủ, theo thứ tự năm. Thêm Rider mới (khi đã có hình) = thêm một dòng.
##   "template"     thoại mặc định từng nhịp ({rider}, {form}); STORY[id][rider] ghi đè từng nhịp
## Chỉ số Rider đối thủ: DUEL_BOSS, nhân theo thế hệ như trùm (WorldData), traits theo "boss_traits".

const DUEL_BOSS := {"hp": 230.0, "damage": 14.0, "poise": 24.0, "speed": 78.0, "traits": []}

const WORLDS := [
	{
		"id": "decade_cards",
		"parent": &"decade",
		"name": "Hành trình thẻ Kamen Ride",
		"motto": "Thẻ chỉ có màu khi thắng chính Rider đó",
		"title": "NHÁNH DECADE",
		"stage_name": "Thế giới {rider}",
		"form_suffix": "",
		"duels": [&"kuuga", &"agito", &"ryuki", &"faiz", &"blade", &"hibiki", &"den_o", &"kiva", &"double", &"ooo",
			&"fourze", &"wizard", &"gaim", &"drive", &"ghost", &"ex_aid", &"build", &"zi_o"],
		"boss_traits": {&"faiz": ["fast"], &"kiva": ["fast"], &"hibiki": ["armored"], &"fourze": ["armored"]},
		"template": {
			"start": [["tsukasa", "Bức màn cực quang mở sang Thế giới {rider}. Thẻ Kamen Ride {rider} chỉ có màu lại khi thắng được chính Rider của thế giới này."]],
			"goal": [["narrator", "Kamen Rider {rider} bước ra chắn đường. Muốn lấy thẻ thì phải thắng."]],
			"key": [["tsukasa", "KAMEN RIDE: {rider}! Từ giờ cậu biến thành {rider} được rồi. Chọn thẻ trước khi vào màn."]],
			"clear": [["natsumi", "Thêm một tấm thẻ có màu. Tsukasa giả vờ không để ý, nhưng cậu ta vừa chụp ảnh cậu đấy."]],
		},
	},
	{
		"id": "zi_o_watches",
		"parent": &"zi_o",
		"name": "Kho Ride Watch",
		"motto": "Kế thừa sức mạnh từ chính tay các Rider",
		"title": "NHÁNH ZI-O",
		"stage_name": "Năm {year} · {rider}",
		"form_suffix": "_armor",
		"duels": [&"kuuga", &"agito", &"ryuki", &"faiz", &"blade", &"hibiki", &"kabuto", &"den_o", &"kiva", &"double",
			&"ooo", &"fourze", &"wizard", &"gaim", &"drive", &"ghost"],
		"boss_traits": {&"faiz": ["fast"], &"kabuto": ["fast"], &"kiva": ["fast"], &"hibiki": ["armored"]},
		"template": {
			"start": [["woz", "Năm {year}. Theo cuốn sách này, Kamen Rider {rider} sẽ thử sức cậu trước khi trao Ride Watch."]],
			"goal": [["narrator", "Kamen Rider {rider} xuất hiện, tay cầm Ride Watch của mình."]],
			"key": [["woz", "Iwae! Zi-O {form}! Sức mạnh của {rider} giờ được kế thừa."]],
			"clear": [["sougo", "Ride Watch là ký ức của một Rider. Giữ cẩn thận nhé, {name}."]],
		},
	},
]

## Thoại riêng: STORY[id thế giới phụ][Rider đối thủ] = {nhịp: [câu]}, nhịp thiếu thì dùng "template".
const STORY := {
	"decade_cards": {
		&"kuuga": {
			"start": [
				["tsukasa", "Bức màn cực quang mở sang Thế giới Kuuga. Thẻ của Rider nào thì phải thắng chính Rider đó mới có."],
				["pen", "Cậu từng đi qua đây rồi, {name}. Lần này Kuuga đứng về phía tấm thẻ, không phải phía cậu."],
			],
			"key": [["tsukasa", "KAMEN RIDE: KUUGA! Cân bằng, giáp chắc hơn form gốc một chút. Mighty Kick để lại dấu lửa trên quái."]],
			"clear": [["natsumi", "Tsukasa toàn chụp ảnh méo, nhưng thế giới nào cũng có một tấm cậu ta giữ lại. Cậu ấy nhớ hết đấy."]],
		},
		&"agito": {
			"start": [["pen", "Thế giới Agito, bờ biển lộng gió. Agito chỉ trao sức mạnh cho người đã thức tỉnh thật sự."]],
			"key": [["tsukasa", "KAMEN RIDE: AGITO! Nhẹ hơn, nhảy cao hơn. Rider Kick từ trên cao xuống."]],
			"clear": [["tsukasa", "Ở mỗi thế giới tôi được giao một vai. Ở thế giới của Void, chắc chẳng còn ai giao vai nữa."]],
		},
		&"ryuki": {
			"start": [["natsumi", "Ở đây ai cũng có bóng trong gương, nhưng bóng không bắt chước mình! Ryuki bước ra từ tấm kính kìa."]],
			"key": [["tsukasa", "KAMEN RIDE: RYUKI! Kèm Strike Vent: giữ nút Bắn, Dragclaw khạc lửa đốt cháy quái. Giáp mỏng, đứng xa mà đánh."]],
			"clear": [
				["hero", "Ở thế giới Ryuki, các Rider đánh nhau để giành một điều ước. Nếu tôi có một điều ước..."],
				["pen", "...Cậu sẽ ước gặp lại anh trai. Tôi biết mà."],
			],
		},
		&"faiz": {
			"start": [["tsukasa", "Tòa nhà Smart Brain. Faiz không thích người lạ, càng không thích người lạ cầm thẻ của cậu ta."]],
			"key": [["tsukasa", "KAMEN RIDE: FAIZ! Nhanh, đánh đau, nhưng máu mỏng. Faiz Phone bắn ba viên một lượt. Crimson Smash kết thúc."]],
			"clear": [["natsumi", "Pen dạo này ít trêu cậu hẳn. Cô ấy đang cố nhớ ra chuyện gì đó, đúng không?"]],
		},
		&"blade": {
			"start": [["pen", "Thế giới Blade. Blade đứng trên đỉnh núi, Blay Rouzer đã rút sẵn khỏi vỏ."]],
			"key": [["tsukasa", "KAMEN RIDE: BLADE! Blay Rouzer cầm sẵn trên tay, nút Đánh là chém luôn. Lightning Blast phóng điện lan ra."]],
			"clear": [
				["tsukasa", "Blade ở thế giới này đã chọn thành Undead để cứu bạn. Có người đổi cả bản thân để giữ một người."],
				["hero", "...Anh Rei cũng từng làm vậy vì tôi."],
			],
		},
		&"hibiki": {
			"start": [["natsumi", "Ngôi đền trên núi, tiếng trống vọng xuống tận chân đèo. Hibiki muốn xem cậu luyện tập tới đâu."]],
			"key": [["tsukasa", "KAMEN RIDE: HIBIKI! Chậm mà chắc, đòn nặng phá giáp. Kaen Renda no Kata: sáu nhịp trống lửa liền."]],
			"clear": [["tsukasa", "Hibiki luyện cả đời mới thành Oni. Cậu thì đi mượn thẻ. Nhưng mượn rồi thì phải xứng đáng."]],
		},
		&"den_o": {
			"start": [["pen", "Sa mạc thời gian, đường ray chạy giữa hư không. Den-O nhảy xuống từ Den-Liner: \"Ore, sanjou!\""]],
			"key": [["tsukasa", "KAMEN RIDE: DEN-O! DenGasher dạng kiếm ở nút Chém. Extreme Slash, lưỡi kiếm bay ra chém xa."]],
			"clear": [
				["pen", "Ở thế giới Den-O, ký ức giữ cho thời gian tồn tại. Người còn nhớ thì thời gian còn đó."],
				["hero", "Vậy tôi sẽ nhớ anh Rei thật kỹ. Để anh ấy không biến mất."],
			],
		},
		&"kiva": {
			"start": [["natsumi", "Lâu đài Fangire, trăng to quá. Kiva đứng trên tường thành, xích trên chân kêu lách cách."]],
			"key": [["tsukasa", "KAMEN RIDE: KIVA! Nhanh, nhảy cao, đòn nhẹ mà xa. Darkness Moon Break làm quái choáng."]],
		},
	},
	"zi_o_watches": {
		&"ghost": {
			"start": [
				["woz", "Năm 2015, chùa Daitenku. Ghost lơ lửng giữa nghĩa địa, Ride Watch của cậu ấy phát sáng mờ mờ."],
				["pen", "Ride Watch Ghost! Nó... đang bay lơ lửng kìa. Đúng là đồ của hồn ma."],
			],
			"key": [["woz", "Iwae! Zi-O Ghost Armor! Áo choàng Parka nhẹ tênh: chạy nhanh, nhảy cao, giữ nút nhảy để lượn. Giáp mỏng, cẩn thận."]],
			"clear": [["sougo", "Ghost từng chết rồi sống lại để bảo vệ người khác. Tôi nghĩ một vị vua cũng phải dám như thế."]],
		},
		&"drive": {
			"start": [["woz", "Năm 2014. Drive chạy trên cao tốc đêm, Trì Trệ lan ra quanh cậu ấy như sóng."]],
			"key": [["woz", "Iwae! Zi-O Drive Armor! Tăng tốc như Formula: quái chậm lại quanh cậu, nhưng nộ tụt rất nhanh."]],
			"clear": [
				["sougo", "Woz cứ bảo tôi sinh ra để làm vua. Nhưng tôi thấy mình chọn làm vua, chứ không phải được sinh ra như thế."],
				["hero", "Tôi cũng không sinh ra để làm Rider. Tôi chỉ là người giao hàng... đang đi tìm anh mình."],
			],
		},
		&"gaim": {
			"start": [
				["pen", "Rừng Helheim, trái lạ mọc khắp nơi. Đừng ăn! Ăn vào là thành Inves đấy."],
				["woz", "Gaim chờ ở giữa rừng, hai thanh đao trong tay. Ride Watch của cậu ấy không cho không đâu."],
			],
			"key": [["woz", "Iwae! Zi-O Gaim Armor! Song đao Daidaimaru ở nút Chém, mỗi nhát chém hai lần."]],
			"clear": [["sougo", "Gaim đã thành thần chỉ để không ai phải tranh giành nữa. Làm vua chắc cũng cô đơn y như vậy."]],
		},
		&"wizard": {
			"start": [["woz", "Năm 2012. Cổng phép mở ra, Wizard bước qua vòng lửa đỏ: \"Saa, showtime da.\""]],
			"key": [["woz", "Iwae! Zi-O Wizard Armor! WizarSwordGun bắn lửa từ xa, đạn làm quái bốc cháy. Đừng để chúng áp sát."]],
			"clear": [
				["pen", "Wizard là hy vọng cuối cùng của mọi người. {name}... cậu có còn hy vọng không, sau tất cả những chuyện này?"],
				["hero", "Còn chứ. Càng đi tôi càng thấy anh Rei ở gần."],
			],
		},
		&"ooo": {
			"start": [["woz", "Năm 2010. OOO đứng giữa phố chiều, ba Medal trên đai sáng lên. Cậu ấy muốn biết cậu với tay được tới đâu."]],
			"key": [["woz", "Iwae! Zi-O OOO Armor! Vuốt Tora ở nút Chém. Scanning Time Break ba nhịp, quái choáng tại chỗ."]],
			"clear": [
				["sougo", "Eiji nói tay với tới thì phải với. Mấy năm qua cậu đã với được bao xa rồi, {name}?"],
				["hero", "Gần lắm rồi. Tôi nghĩ vậy."],
			],
		},
	},
}
