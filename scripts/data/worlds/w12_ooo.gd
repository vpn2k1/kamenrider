extends RefCounted
## Thế giới 12 · Kamen Rider OOO (2010) — "Ham muốn và bàn tay chìa ra"
## Echo Rider: Hino Eiji (hiền, "chút tiền lẻ và cái quần lót cho ngày mai"). Hỗ trợ: Ankh (Greeed, mê kem que).
## Quái: Yummy sinh ra từ ham muốn con người. Trùm: Kazari (Greeed hệ Mèo).
## Bài học: dám chìa tay ra. Pen lần đầu nói mình có một "ham muốn".
## 8 combo cùng hệ (ba Medal cùng màu) theo thứ tự xuất hiện trong phim, mỗi màn luyện tập rơi một combo: 9 màn
## (12-1, 12-2..12-8, 12-B). Lv5 = Super TaToBa (Medal từ tương lai).

const WORLD := {
	"id": "ooo",
	"year": 2010,
	"name": "Thế giới OOO",
	"motto": "Ham muốn và bàn tay chìa ra",
	"rider": &"ooo",
	"rider_name": "OOO",
	"driver_name": "OOO Driver",
	"color": Color(0.95, 0.38, 0.2),
	"enemies": {
		"basic": {"name": "Waste Yummy", "color": Color(0.72, 0.66, 0.52), "sprite": "waste_yummy"},
		"fast": {"name": "Neko Yummy", "color": Color(0.92, 0.85, 0.6), "sprite": "neko_yummy"},
		"armored": {"name": "Bison Yummy", "color": Color(0.55, 0.42, 0.32), "sprite": "bison_yummy"},
	},
	"unlocks": [
		"TaToBa Combo (form gốc)",
		"sát thương +10%, máu +8%",
		"sát thương +20%, máu +16%",
		"sát thương +30%, máu +24%",
		"Super TaToBa: Final Attack x1.5",
	],
	"stages": [
		{"name": "Nhà hàng Cous Coussier", "goal": "Hạ Waste Yummy, giành lại O Scanner cho OOO Driver",
			"bg": "ooo_1", "bg_theme": "city_day"},
		{"name": "Phố mua sắm lúc chiều", "form": &"latorartar", "form_name": "LaTorarTar Combo",
			"bg": "ooo_2", "bg_theme": "city_dusk"},
		{"name": "Công viên rừng cây", "form": &"gatakiriba", "form_name": "GataKiriBa Combo",
			"bg": "ooo_3", "bg_theme": "forest_day"},
		{"name": "Bến cảng Tokyo", "form": &"shauta", "form_name": "ShaUTa Combo",
			"bg": "ooo_4", "bg_theme": "coast"},
		{"name": "Vách núi lúc bình minh", "form": &"tajador", "form_name": "TaJaDor Combo",
			"bg": "ooo_5", "bg_theme": "mountain_dawn"},
		{"name": "Tòa nhà Tập đoàn Kougami", "form": &"sagohzo", "form_name": "SaGohZo Combo",
			"bg": "ooo_6", "bg_theme": "city_night"},
		{"name": "Phòng thí nghiệm của tiến sĩ Maki", "form": &"putotyra", "form_name": "PuToTyra Combo",
			"bg": "ooo_7", "bg_theme": "lab"},
		{"name": "Tàn tích vị vua OOO cổ đại", "form": &"burakawani", "form_name": "BuraKaWani Combo",
			"bg": "ooo_8", "bg_theme": "ruins"},
		{"name": "Trùm: Kazari", "bg": "ooo_b", "bg_theme": "boss_gold",
			"boss": {"name": "Kazari", "hp": 250.0, "damage": 16.0, "poise": 22.0, "speed": 85.0,
				"traits": [], "color": Color(0.95, 0.78, 0.25)}},
	],
}

## OOO: đổi bộ ba Core Medal cùng hệ. Mỗi combo có kỹ năng theo phim (khóa "tags" / "attacks" / "guard" / "rage_drain"
## của DataRider, hiệu ứng xử lý ở Enemy):
##   TaToBa      Tatoba Kick đá xuyên ba vòng Medal (3 nhịp), chân Batta nhảy cao
##   LaTorarTar  chân Cheetah nhanh nhất (để bóng mờ), vuốt Tora cào đôi, cú kết chớp Lionde làm choáng quanh mình
##   GataKiriBa  sừng Kuwagata phóng điện lan sang quái gần, chân Batta nhảy cao nhất, Final phân thân (6 nhịp, rộng)
##   ShaUTa      roi điện Unagi tầm xa có điện, cú kết quấn roi kéo quái về, Octo Banish khoan nhiều nhịp
##   TaJaDor     cánh bay lượn, Taja Spinner bắn lửa gây cháy, Final Magna Blaze
##   SaGohZo     bắn nắm đấm Gorilla Bagootcha xuyên, dậm chân Zou hất tung, Final trọng lực hút quái về và choáng
##   PuToTyra    đuôi Tyranno quét rộng, hơi thở băng Ptera đóng băng, cánh bay lượn, Strain Doom đóng băng diện rộng;
##               Medal tím đói: nộ tụt nhanh
##   BuraKaWani  khiên mai rùa Kame chặn sát thương phía trước, đầu Cobra mổ tầm cao, hàm Wani cắn nhiều nhát
const RIDER := {
	"name": "Kamen Rider OOO",
	"tagline": "Đổi Medal · 8 combo, mỗi bộ ba một kỹ năng: choáng, điện, lửa, trọng lực, băng, khiên",
	"base": &"tatoba",
	"order": [&"tatoba", &"latorartar", &"gatakiriba", &"shauta", &"tajador", &"sagohzo", &"putotyra", &"burakawani"],
	"forms": {
		&"tatoba": {"name": "TaToBa Combo", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.2, "atk": 1.05, "poise": 7.0, "final": "Tatoba Kick",
			"fx": {"hit": "spark", "final": "ring", "color": Color(1.0, 0.4, 0.3)},
			"attacks": {"final": {"hits": 3, "damage": 24.0}}},
		&"latorartar": {"name": "LaTorarTar Combo", "style": "lancer", "hp": 130.0, "armor": 10.0, "speed": 182.0,
			"jump": 1.25, "atk": 0.95, "poise": 4.0, "final": "Gush Cross",
			"fx": {"hit": "spark", "swing": "slash", "final": "slash", "trail": true, "color": Color(1.0, 0.85, 0.25)},
			"attacks": {
				"light": {"hits": 2, "damage": 2.5},
				"kick": {"size": Vector2(90, 50), "offset": Vector2(0, -24), "damage": 6.0, "knockback": Vector2(20, -10),
					"tags": [&"stun"]},
				"final": {"hits": 2, "damage": 26.0, "lunge": Vector2(320, -40)}}},
		&"gatakiriba": {"name": "GataKiriBa Combo", "style": "blade", "hp": 148.0, "armor": 18.0, "speed": 148.0,
			"jump": 1.38, "atk": 1.08, "poise": 7.0, "final": "Gatakiriba Kick", "tags": [&"shock"],
			"fx": {"hit": "lightning", "swing": "slash", "final": "lightning", "color": Color(0.45, 1.0, 0.4)},
			"attacks": {"final": {"hits": 6, "damage": 13.0, "size": Vector2(130, 40), "offset": Vector2(30, -20),
				"lunge": Vector2(200, -260)}}},
		&"shauta": {"name": "ShaUTa Combo", "style": "lancer", "hp": 150.0, "armor": 15.0, "speed": 135.0,
			"jump": 1.15, "atk": 0.95, "poise": 5.0, "final": "Octo Banish", "blade": {"style": "lancer"},
			"fx": {"hit": "lightning", "swing": "wind", "final": "ring", "color": Color(0.35, 0.6, 1.0)},
			"attacks": {
				"slash": {"size": Vector2(52, 10), "offset": Vector2(32, -14), "tags": [&"shock"]},
				"slash_finish": {"size": Vector2(60, 12), "offset": Vector2(36, -14), "knockback": Vector2(-180, -30),
					"tags": [&"shock", &"force"]},
				"final": {"hits": 5, "damage": 10.0, "lunge": Vector2(220, -160)}}},
		&"tajador": {"name": "TaJaDor Combo", "style": "gunner", "hp": 165.0, "armor": 25.0, "speed": 138.0,
			"jump": 1.3, "atk": 1.15, "poise": 8.0, "final": "Magna Blaze", "tags": [&"burn"],
			"fx": {"hit": "fire", "shot": "fire", "final": "fire", "glide": true, "color": Color(1.0, 0.45, 0.2)},
			"gun": {"damage": 6.0, "speed": 360.0, "cooldown": 0.32, "radius": 4.0, "color": Color(1.0, 0.45, 0.15),
				"life": 0.8, "tags": [&"burn"]}},
		&"sagohzo": {"name": "SaGohZo Combo", "style": "heavy", "hp": 212.0, "armor": 60.0, "speed": 80.0,
			"jump": 0.8, "atk": 1.42, "poise": 21.0, "final": "Sagohzo Impact",
			"fx": {"hit": "ring", "shot": "ball", "final": "ring", "color": Color(0.8, 0.8, 0.85)},
			"gun": {"damage": 14.0, "speed": 260.0, "cooldown": 1.1, "radius": 5.0, "pierce": true,
				"color": Color(0.75, 0.75, 0.8), "life": 0.9},
			"attacks": {
				"kick": {"size": Vector2(140, 18), "offset": Vector2(0, -6), "knockback": Vector2(10, -320),
					"tags": [&"force"]},
				"final": {"size": Vector2(260, 90), "offset": Vector2(0, -30), "knockback": Vector2(-240, -60),
					"damage": 55.0, "tags": [&"force", &"stun"]}}},
		&"putotyra": {"name": "PuToTyra Combo", "style": "heavy", "hp": 190.0, "armor": 38.0, "speed": 108.0,
			"jump": 1.1, "atk": 1.48, "poise": 18.0, "final": "Strain Doom", "rage_drain": 6.5, "blade": {"style": "heavy"},
			"fx": {"hit": "ring", "swing": "slash", "final": "slash", "glide": true, "color": Color(0.7, 0.45, 1.0)},
			"attacks": {
				"light": {"size": Vector2(40, 16), "offset": Vector2(18, -10)},
				"kick": {"size": Vector2(80, 26), "offset": Vector2(46, -30), "damage": 14.0, "tags": [&"freeze"]},
				"final": {"size": Vector2(170, 44), "offset": Vector2(60, -22), "damage": 75.0, "tags": [&"freeze"]}}},
		&"burakawani": {"name": "BuraKaWani Combo", "style": "brawler", "hp": 200.0, "armor": 64.0, "speed": 100.0,
			"jump": 0.9, "atk": 0.98, "poise": 18.0, "final": "Burakawani Scanning Charge", "guard": 0.4,
			"fx": {"hit": "spark", "final": "ring", "color": Color(0.95, 0.55, 0.2)},
			"attacks": {
				"light": {"size": Vector2(28, 10), "offset": Vector2(22, -30)},
				"kick": {"hits": 2, "damage": 7.0, "knockback": Vector2(80, -40)},
				"final": {"hits": 3, "damage": 20.0, "lunge": Vector2(200, -220)}}},
	},
	"lv5": {"name": "Super TaToBa", "final_mult": 1.5},
	"final_fx": {"intro": "rings3"},
}

## Giọng đai / tiếng hô (tools/gen_audio.py → audio/voice/<rider>_<khóa>.wav): "henshin" lúc biến thân, khóa = id form
## lúc đổi sang form đó, "final" lúc Final Attack. Mỗi dòng: [kiểu giọng, câu]
## (kiểu giọng: belt / belt_deep / belt_bright / kivat / hero, xem VOICES trong gen_audio.py).
const VOICE := {
	"henshin": ["belt", "Taka! Tora! Batta! Ta-To-Ba! Ta-To-Ba! Ta-To-Ba!"],
	"latorartar": ["belt", "Lion! Tora! Cheetah! La-Tora-Tah! La-Tora-Tah!"],
	"gatakiriba": ["belt", "Kuwagata! Kamakiri! Batta! Gata-gata-kiriba! Gata-kiriba!"],
	"shauta": ["belt", "Shachi! Unagi! Tako! Sha-Sha-Shauta! Sha-Sha-Shauta!"],
	"tajador": ["belt", "Taka! Kujaku! Condor! Ta-Ja-Dor!"],
	"sagohzo": ["belt", "Sai! Gorilla! Zou! Sa-Go-Zo! Sa-Go-Zo!"],
	"putotyra": ["belt", "Ptera! Tricera! Tyranno! Pu-To-Tyranno-saurus!"],
	"burakawani": ["belt", "Cobra! Kame! Wani! Bura-ka-wani!"],
	"final": ["belt", "Scanning Charge!"],
}

const SPEAKERS := {
	"eiji": {"name": "HINO EIJI", "color": Color(0.95, 0.5, 0.3), "portrait": "eiji",
		"look": "hair=2e2018 jacket=b4885a stripe=e8dcc0 eyes=3c2a1e"},
	"ankh": {"name": "ANKH", "color": Color(0.95, 0.3, 0.25), "portrait": "ankh",
		"look": "hair=e6c060 jacket=c83a2a stripe=202020 eyes=b43a2a"},
	"kazari": {"name": "KAZARI", "color": Color(0.95, 0.8, 0.3), "portrait": "kazari",
		"look": "base=grongi tint=e0b030"},
}

const STORY := {
	"1": {
		"start": [
			["narrator", "Trái Đất OOO · Nhà hàng Cous Coussier."],
			["eiji", "Hino Eiji, phục vụ ở đây. Tôi chỉ cần chút tiền lẻ và một cái quần lót cho ngày mai là đủ sống."],
			["ankh", "Bớt lảm nhảm. OOO Driver có Medal rồi, nhưng thiếu O Scanner để quét. Lũ Waste Yummy cướp mất."],
			["pen", "Ở thế giới này, Yummy sinh ra từ ham muốn của con người. Hạ chúng, O Scanner sẽ rơi ra!"],
		],
		"goal": [
			["ankh", "Con đầu đàn đang ôm O Scanner kìa. Lấy về, rồi giao hết Medal cho tôi giữ."],
		],
		"key": [
			["hero", "Henshin!"],
			["narrator", "O Scanner lướt qua ba Medal. TAKA! TORA! BATTA! Ta-To-Ba, TaToBa, Ta-To-Ba!"],
			["eiji", "Bài hát đó thì cứ kệ nó. Lần nào biến thân nó cũng tự hát."],
		],
		"clear": [
			["pen", "TaToBa là form gốc: mắt Taka, vuốt Tora, chân Batta nhảy cao. Medal khác nằm trong bụng lũ Yummy."],
		],
	},
	"2": {
		"start": [
			["eiji", "Neko Yummy đang chạy khắp phố mua sắm. Nó nhanh lắm, trong bụng còn Medal Lion và Cheetah."],
		],
		"key": [
			["eiji", "LION! TORA! CHEETAH! LaTorarTar! Chạy như gió, vuốt cào đôi. Cú kết chuỗi lóe sáng Lionde làm quái quanh mình choáng."],
		],
		"clear": [
			["eiji", "{name}, trông cậu có tâm sự. Kể nghe được không?"],
			["hero", "Tôi đang đuổi theo một người hình như biết anh trai tôi. Nhưng càng đuổi, càng thấy xa."],
			["eiji", "Tay với tới mà không với, sau này sẽ hối hận lắm. Tôi từng như thế rồi. Cứ chìa tay ra đi."],
		],
	},
	"3": {
		"start": [
			["ankh", "Uva, Greeed hệ côn trùng, giấu Medal Kuwagata và Kamakiri trong lũ Yummy ở công viên. Lấy về trước khi hắn tới."],
		],
		"key": [
			["eiji", "KUWAGATA! KAMAKIRI! BATTA! GataKiriBa! Sừng Kuwagata phóng điện lan sang quái gần. Final tung cả bầy phân thân."],
		],
		"clear": [
			["pen", "Ba Medal cùng màu hợp nhau thì thành combo. Mỗi combo một bài hát riêng. Hơi ồn."],
			["ankh", "Ồn nhưng mạnh. Đừng quen dùng Medal xanh, mấy cái đó không phải của tôi."],
		],
	},
	"4": {
		"start": [
			["ankh", "Dưới nước có Yummy của Mezool làm tổ. Trong đó là Medal Shachi, Unagi, Tako."],
		],
		"key": [
			["eiji", "SHACHI! UNAGI! TAKO! ShaUTa! Roi điện Unagi quất xa, điện lan. Cú kết chuỗi quấn roi kéo quái về phía mình."],
		],
		"clear": [
			["pen", "Hồi còn ở với Void, tôi chỉ là một cái thẻ. Không có ham muốn gì hết."],
			["ankh", "Hừ. Không có ham muốn thì đã chẳng nói ra câu đó."],
			["pen", "...Tôi muốn đi cùng {name} tới cuối đường. Vậy có tính là ham muốn không?"],
		],
	},
	"5": {
		"start": [
			["ankh", "Lũ Yummy nuốt mất Medal Kujaku và Condor. Medal đỏ là của tôi. Lấy về cho bằng được."],
		],
		"key": [
			["narrator", "TAKA! KUJAKU! CONDOR! Ta~Ja~Dor~!"],
			["eiji", "TaJaDor bay lượn được: giữ Nhảy khi rơi. Taja Spinner bắn lửa, quái trúng còn cháy thêm một lúc."],
		],
		"clear": [
			["ankh", "Medal đỏ hợp với cậu thế à... Đừng tưởng bở, cho mượn thôi."],
			["pen", "Ankh nói vậy, chứ lúc {name} bay lên cậu ấy nhìn không chớp mắt."],
		],
	},
	"6": {
		"start": [
			["eiji", "Bison Yummy húc sập cả sảnh Tập đoàn Kougami. Giáp nó dày quá, đòn thường chỉ gãi ngứa."],
		],
		"key": [
			["eiji", "SAI! GORILLA! ZOU! SaGohZo! Bắn nắm đấm Gorilla, dậm chân Zou hất tung quái. Final hút mọi quái về bằng trọng lực."],
		],
		"clear": [
			["ankh", "Gorilla với Zou vốn nằm trong tay Greeed khác. Cậu giành được thì chúng sẽ tìm tới."],
			["eiji", "Cứ để chúng tới. Mình giành Medal không phải để có nhiều hơn, mà để không ai phải khóc vì ham muốn của chúng."],
		],
	},
	"7": {
		"start": [
			["eiji", "Tiến sĩ Maki tạo ra Medal tím, Medal của hư vô. Lũ Yummy trong phòng thí nghiệm đang giữ ba cái."],
			["ankh", "Medal tím ăn cả Medal của Greeed. Cẩn thận, nó nuốt luôn ham muốn của người dùng."],
		],
		"key": [
			["narrator", "PTERA! TRICERA! TYRANNO! PuToTyranosaurus!"],
			["eiji", "Rìu Medagabryu chém rộng, hơi thở Ptera đóng băng quái. Nhưng Medal tím đói lắm: nộ tụt nhanh hơn."],
		],
		"clear": [
			["hero", "Lúc nãy tôi suýt chẳng muốn gì nữa. Trống rỗng, giống Void vậy."],
			["pen", "Nhưng cậu vẫn quay lại, vì cậu còn muốn tìm anh trai. Ham muốn đó giữ cậu lại."],
		],
	},
	"8": {
		"start": [
			["narrator", "Tàn tích của vị vua OOO đầu tiên, 800 năm trước."],
			["eiji", "Medal bò sát Cobra, Kame, Wani bị phong ấn ở đây. Lũ Yummy đào lên mất rồi."],
		],
		"key": [
			["narrator", "COBRA! KAME! WANI! BuraKaWani!"],
			["eiji", "Khiên Kame chặn hơn nửa sát thương phía trước khi cậu không ra đòn. Hàm Wani cắn hai nhát liền."],
		],
		"clear": [
			["ankh", "Kazari đang gom Medal để thành Greeed hoàn chỉnh. Năng lượng Void làm nó càng đói."],
			["eiji", "Kazari muốn tất cả. Còn tụi mình chỉ cần nắm lấy những bàn tay đang chìa ra."],
		],
	},
	"B": {
		"goal": [
			["kazari", "Ham muốn là thứ đẹp nhất trên đời. Medal của ngươi... đưa hết cho ta."],
			["hero", "Ham muốn của tôi là tìm lại anh trai, và giữ lấy người đang đi cùng mình. Anh không lấy được đâu."],
		],
		"clear": [
			["narrator", "Kazari vỡ thành mưa Cell Medal. Giữa đống xu bạc là một chiếc đai trắng bọc tinh thể tím: Fourze Driver."],
			["narrator", "Ba Medal từ tương lai sáng lên. SUPER TAKA! SUPER TORA! SUPER BATTA! Super TaToBa!"],
			["ankh", "Medal của ngày mai à... Hừ. Lần này thì không phải của tôi."],
			["eiji", "Có những thứ tay không với tới. Nhưng đừng bao giờ thôi chìa tay ra, {name}."],
			["pen", "Fourze Driver: bốn khe công tắc và một cần gạt. Thế giới kế tiếp... có trường học, và cả vũ trụ?"],
		],
	},
}

const WORLD_CLEAR := [
	["pen", "Trái Đất OOO sáng lại. Chặng tiếp theo: Trái Đất Fourze, một trường trung học có căn cứ trên Mặt Trăng!"],
	["hero", "Trường học à? Lâu lắm rồi tôi mới bước vào cổng trường. Hơi hồi hộp đấy."],
]
