# File thế giới (`scripts/data/worlds/`)

Mỗi thế giới Rider là **một file** `wNN_<id>.gd`. Thứ tự các thế giới là thứ tự **năm phát sóng**, khai báo ở `WorldData.FILES` (`scripts/data/world_data.gd`). Bộ nạp tự đánh số màn (`"4-1"` … `"4-B"`), tự nối Driver của thế giới kế tiếp, tự điền lộ trình / đợt quái mặc định và nhân chỉ số trùm theo thế hệ.

File mẫu đầy đủ: **`w02_agito.gd`**. Kuuga, Faiz, W có script Rider riêng (`scripts/riders/`), các Rider khác dựng từ dữ liệu `RIDER` (`scripts/riders/data_rider.gd`).

Kiểm tra sau khi sửa:

```bash
godot --headless --path . -s tools/validate_worlds.gd -- ryuki blade
python3 tools/gen_backgrounds.py ryuki_1 ryuki_2
```

## Chuỗi thế giới và Driver (cố định)

Câu thoại cuối trùm mỗi thế giới nhắc đúng tên Driver của thế giới kế tiếp (Driver đó rơi ra, còn phong ấn).

| # | id | Rider | Năm | Driver | # | id | Rider | Năm | Driver |
|---|---|---|---|---|---|---|---|---|---|
| 1 | kuuga | Kuuga | 2000 | Arcle | 15 | gaim | Gaim | 2013 | Sengoku Driver |
| 2 | agito | Agito | 2001 | Alter Ring | 16 | drive | Drive | 2014 | Drive Driver |
| 3 | ryuki | Ryuki | 2002 | Advent Deck | 17 | ghost | Ghost | 2015 | Ghost Driver |
| 4 | faiz | Faiz | 2003 | Faiz Driver | 18 | ex_aid | Ex-Aid | 2016 | Gamer Driver |
| 5 | blade | Blade | 2004 | Blay Buckle | 19 | build | Build | 2017 | Build Driver |
| 6 | hibiki | Hibiki | 2005 | Henshin Onsa | 20 | zi_o | Zi-O | 2018 | Ziku Driver |
| 7 | kabuto | Kabuto | 2006 | Kabuto Zecter | 21 | zero_one | Zero-One | 2019 | Hiden Zero-One Driver |
| 8 | den_o | Den-O | 2007 | Den-O Belt | 22 | saber | Saber | 2020 | Seiken Swordriver |
| 9 | kiva | Kiva | 2008 | Kivat-bat III | 23 | revice | Revice | 2021 | Revice Driver |
| 10 | decade | Decade | 2009 | Decadriver | 24 | geats | Geats | 2022 | Desire Driver |
| 11 | double | W | 2009 | Double Driver | 25 | gotchard | Gotchard | 2023 | Gotchard Driver |
| 12 | ooo | OOO | 2010 | OOO Driver | 26 | gavv | Gavv | 2024 | Henshin Belt Gavv |
| 13 | fourze | Fourze | 2011 | Fourze Driver | 27 | zeztz | Zeztz | 2025 | (tra cứu) |
| 14 | wizard | Wizard | 2012 | WizarDriver | — | — | Điểm Không | — | Chrono Driver (rơi từ trùm thế giới 27) |

## Các hằng trong file

```gdscript
extends RefCounted
## Thế giới N · Kamen Rider X (năm) — "chủ đề"

const WORLD := {...}        # bên dưới
const RIDER := {...}        # Rider dùng DataRider; Rider có script riêng thì {}
const SPEAKERS := {...}     # người nói riêng của thế giới
const STORY := {...}        # hội thoại theo màn
const WORLD_CLEAR := [...]  # thoại trên bản đồ sau khi hạ trùm
```

### WORLD

| Khóa | Ý nghĩa |
|---|---|
| `id` | trùng phần tên file (`w03_ryuki.gd` → `"ryuki"`) |
| `year`, `name` ("Thế giới Ryuki"), `motto` (chủ đề ngắn) | |
| `rider` | `&"<id>"` |
| `rider_name`, `driver_name` | tên hiển thị; `driver_name` theo bảng trên |
| `color` | màu nhận diện, cũng là màu khối tạm của Rider. Chọn màu sáng, dễ thấy trên nền tối |
| `enemies` | `basic` / `fast` / `armored`: `{"name": tên quái trong phim, "color": Color}` |
| `unlocks` | 5 dòng: `"<form gốc> (form gốc)"`, `"sát thương +10%, máu +8%"`, `+20%/+16%`, `+30%/+24%`, `"<tên Lv5>: Final Attack x1.5"` |
| `stages` | đúng 5 màn (bảng dưới) |

Màn (`stages`):

| # | Loại | Khóa |
|---|---|---|
| 1 | Thức tỉnh (người chơi dùng Rider cũ) | `name`, `goal` (mục tiêu, theo kiểu thử thách của thế giới), `bg`, `bg_theme` |
| 2–4 | Luyện tập | `name`, `form` (`&"id"` form trong `RIDER.forms`, không phải form gốc), `form_name`, `bg`, `bg_theme` |
| 5 | Trùm | `name` ("Trùm: …"), `bg`, `bg_theme`, `boss` |

- `bg` = `"<id>_1"`, `"<id>_2"`, `"<id>_3"`, `"<id>_4"`, `"<id>_b"`. `bg_theme` chọn trong danh mục cuối trang, hợp bối cảnh màn.
- `boss` = `{"name", "hp" (220–320), "damage" (13–19), "poise" (18–32), "speed" (55–90), "traits": [] | ["fast"] | ["armored"], "color": Color}`. Đây là chỉ số ở **thế giới 1**; bộ nạp tự nhân theo thế hệ.
- Không cần ghi `route`, `waves`, `id`, `type`: bộ nạp tự điền.

### RIDER

```gdscript
const RIDER := {
	"name": "Kamen Rider Ryuki",
	"tagline": "một dòng lối chơi (hiện ở màn chọn Rider)",
	"base": &"ryuki",
	"order": [&"ryuki", &"sword_vent", &"strike_vent", &"guard_vent"],   # form gốc đứng đầu, rồi 3 form theo màn 2–4
	"forms": {
		&"ryuki": {"name": "Ryuki", "style": "brawler", "hp": 160.0, "armor": 25.0, "speed": 130.0,
			"jump": 1.05, "atk": 1.05, "poise": 7.0, "final": "Dragon Rider Kick"},
		...
	},
	"lv5": {"name": "Survive", "final_mult": 1.5},
}
```

**Kiểu đòn (`style`)**, quyết định chuỗi đòn của nút Đánh:

| style | Chuỗi đòn | Hợp với |
|---|---|---|
| `brawler` | 3 đấm + 1 đá, cân bằng | form gốc tay không |
| `blade` | 3 chém + 1 chém nặng phá giáp | form cầm kiếm |
| `lancer` | 3 đòn tầm xa hơn, nhẹ hơn + 1 đòn | form nhanh, giáo, roi |
| `heavy` | 2 đòn nặng phá giáp + 1 đòn rất nặng | form giáp dày, búa, sức mạnh |
| `gunner` | 2 phát bắn tầm xa + 1 phát nạp | form cung / súng (bắt buộc có `gun`) |

**Chỉ số** (validate kiểm khoảng): `hp` 110–220 · `armor` 0–65 · `speed` 75–185 · `jump` 0.75–1.5 · `atk` 0.75–1.5 · `poise` 2–22. Tham khảo: form gốc hp ~160, armor ~25, speed ~130, atk ~1.05. Form nhanh: hp thấp, speed 165–180, jump 1.2–1.4. Form nặng: hp 190–210, armor 50–60, speed 80–90, atk 1.35–1.45. Mọi form cộng lại nên "đổi cái này lấy cái kia", không form nào hơn hẳn.

**Tùy chọn trong một form:**
- `"gun": {"damage": 7.0, "speed": 380.0, "cooldown": 0.35, "count": 1, "spread": 0.0, "radius": 3.0, "color": Color(...), "pierce": false, "life": 0.9}`: form có súng (nút Bắn). Có thể gắn cho form không phải `gunner` (ví dụ form gốc cầm súng như Faiz).
- `"effect": "time"`: tăng tốc thời gian (Clock Up, Formula...): quái chậm còn 15%, Rider nhanh ×1.6, đánh trúng được quái nhanh, nộ tụt nhanh (≈10 giây). Tối đa một form mỗi Rider, chỉ khi hợp nguyên tác.
- `"final"`: tên Final Attack của form (tên chiêu trong phim).

### SPEAKERS

```gdscript
const SPEAKERS := {
	"shinji": {"name": "KIDO SHINJI", "color": Color(0.9, 0.3, 0.3), "portrait": "shinji",
		"look": "hair=3a2a1e jacket=7a2a2a stripe=e0e0e0 eyes=3a2a20"},
	"odin": {"name": "ODIN", "color": Color(1.0, 0.85, 0.3), "portrait": "odin", "look": "base=kuuga tint=e8c040"},
}
```

- Khóa người nói **không trùng** giữa các file (validate kiểm). `portrait` = khóa.
- `look` để `tools/gen_story_art.py` vẽ chân dung 28×28:
  - Người: `hair=RRGGBB jacket=RRGGBB stripe=RRGGBB eyes=RRGGBB` + tùy chọn `hat` (mũ phớt), `glasses` (kính), `long` (tóc dài). Vẽ từ đầu nhân vật chính, đổi màu tóc / áo / viền áo / mắt.
  - Quái / Rider: `base=kuuga|grongi|orphnoch|daguba|hero` + tùy chọn `tint=RRGGBB` (nhuộm màu). Rider dùng `base=kuuga`, quái dùng `grongi` / `orphnoch`, trùm to dùng `daguba`.

### STORY

Khóa `"1"`…`"4"`, `"B"`. Mỗi màn gồm các nhịp, mỗi nhịp là danh sách `[người nói, lời]`:

| Nhịp | Khi nào | Bắt buộc |
|---|---|---|
| `start` | đầu màn | màn 1–4 (màn B tùy chọn) |
| `goal` | tới vạch đích màn 1 (nhóm canh giữ) / màn B (trùm xuất hiện) | màn B (lời trùm trước trận) |
| `key` | vừa nhặt Driver (màn 1) / form (màn 2–4), sau cảnh biến thân | màn 1–4 |
| `clear` | qua màn | mọi màn |

- Người nói chung: `narrator` (dẫn truyện), `hero` (nhân vật chính, tên người chơi đặt; trong lời viết `{name}`), `pen` (AI trong Chrono Pass), `void` (Chronos Void).
- Mỗi câu **tối đa 165 ký tự** (khung thoại 2 dòng). Mỗi nhịp 1–5 câu. Cả thế giới khoảng 20–30 câu.
- **Giọng**: Pen nói nhiều, hay trêu, giải thích luật chơi ngắn gọn (form mới làm gì). {name} là shipper 19 tuổi, liều, tốt bụng, đang tìm anh trai mất tích. Void lạnh lùng, ít lời. Echo Rider (Rider gốc của thế giới, đã mất Driver) dẫn dắt, nói đúng tính cách trong phim.
- Nội dung bám nguyên tác: tên nhân vật, quái, form, vũ khí, chiêu, câu cửa miệng (chỉ câu ngắn, không chép lời thoại dài của phim).
- Màn 1 `start`: giới thiệu Trái Đất (`["narrator", "Trái Đất Ryuki · <nơi chốn>."]`), Echo Rider, vì sao Driver chưa dùng được và thử thách để giải phong ấn.
- Màn 2–4 `key`: một câu nói form mới làm gì (nhanh / nặng / bắn xa...), khớp `style` và chỉ số.
- Màn B `clear`: trùm tan, **Driver thế giới kế tiếp** (tên theo bảng) hiện ra bọc tinh thể tím; sức mạnh Rider của thế giới trở về trọn vẹn (tên form Lv5); Echo Rider nói câu chia tay.
- `WORLD_CLEAR`: 1–3 câu trên bản đồ, nhắc Trái Đất vừa sáng lại và chặng tiếp theo.

## Mạch truyện toàn game

| Thế giới | Mốc truyện |
|---|---|
| 1–3 | Sora học cách chiến đấu. Pen nghe giọng Void thì run, lảng tránh |
| 4 (Faiz) | Void xuất hiện, gọi đúng tên {name}. Pen hỏi "nếu tôi giấu cậu một chuyện..." |
| 5–8 | Void thỉnh thoảng hiện ra từ xa, thử thách Sora. Pen biết nhiều về Void hơn mức bình thường |
| **9 (Kiva)** · kết Hồi 1 | Màn B `clear`: Void chặn đường, đánh bại tạm Sora bằng bóng tối, nói "Về nhà đi, {name}." · {name}: "...Sao hắn biết tên mình?" · Pen: "Vì tôi từng là Chrono Pass của hắn." |
| 10 (Decade) | Kadoya Tsukasa, kẻ du hành qua các thế giới, nhận ra Chrono Pass giống sức mạnh của mình; nói Void từng là một người du hành, và có một dòng thời gian đã bị xóa |
| 11 (W) | Philip: dữ liệu về Pen trong Thư viện Trái Đất bị xóa trắng |
| 12–19 | Sora mạnh dần, gom đồng đội; mỗi Echo Rider để lại một bài học (ham muốn, tình bạn, hy vọng, tương lai...) |
| **20 (Zi-O)** · kết Hồi 2 | Woz đọc cuốn sách: tên thật của Void là **Rei**, anh trai {name}, bị kéo vào dòng thời gian bị xóa trong vụ cháy 10 năm trước. {name} biết sự thật |
| 21–26 | Hồi 3 (Reiwa): {name} phải chọn chiến đấu hay cứu anh trai. Revice (ác quỷ bên trong: nỗi sợ phải đánh anh mình), Geats (điều ước: cứu Rei) |
| **27 (Zeztz)** · cuối | Thế giới giấc mơ: {name} mơ lại đám cháy, thấy khuôn mặt Rei. Trùm rơi **Chrono Driver**; cổng tới Điểm Không mở |

## Danh mục kiểu nền (`bg_theme`)

Nguồn: `THEMES` trong `tools/gen_backgrounds.py`. Nền riêng của Kuuga / Faiz / W cũng dùng lại được.

| Kiểu | Mô tả | Kiểu | Mô tả |
|---|---|---|---|
| `city_day` | phố ban ngày, trời xanh | `game_world` | thế giới game 8-bit |
| `city_dusk` | phố hoàng hôn | `hospital` | bệnh viện |
| `city_night` | phố đêm, trăng | `sky_wall` | bức tường khổng lồ chia thành phố |
| `suburb` | khu dân cư nhà thấp | `clock_tower` | tháp đồng hồ, bánh răng |
| `coast` | biển, bãi đá, hoàng hôn | `cyber_city` | thành phố tương lai, hologram |
| `mountain_dawn` | núi, bình minh, sương | `library` | thư viện (trong nhà) |
| `forest_day` | rừng ban ngày | `book_world` | thế giới trong sách |
| `forest_night` | rừng đêm, đom đóm | `arena` | đấu trường, đèn chiếu |
| `shrine` | đền, cổng torii, đèn lồng | `academy` | học viện giả kim |
| `snow_mountain` | núi tuyết | `candy_factory` | nhà máy kẹo |
| `mirror_city` | thế giới gương | `dreamscape` | giấc mơ, đảo nổi, cửa lơ lửng |
| `castle_night` | lâu đài gothic, trăng | `boss_red` | trùm: trời đỏ, cháy |
| `desert_rails` | sa mạc thời gian, đường ray | `boss_purple` | trùm: trời tím, khe nứt |
| `space_moon` | mặt trăng, Trái Đất trên trời | `boss_dark` | trùm: đêm đen, sương |
| `school` | trường học, hoa anh đào | `boss_storm` | trùm: bão, sét |
| `underworld` | không gian phép tím | `boss_gold` | trùm: trời vàng kim |
| `helheim` | rừng Helheim | `boss_ice` | trùm: băng giá |
| `race_city` | thành phố đêm, vệt tốc độ | `temple_ghost` | chùa, bia mộ, linh hồn |
| Nền cũ | `ruins`, `tokyo`, `harbor`, `laundry`, `highway`, `smart_brain`, `lab`, `industrial`, `fuuto`, `fuuto_street`, `wind_tower`, `boss_kuuga`, `boss_faiz`, `boss_w` | | |
