# Rà soát IP: chuyển fan game thành game IP riêng

Ngày rà: 2026-10-05. Mục đích: liệt kê mọi thứ trong project đang dính bản quyền / nhãn hiệu Kamen Rider
(Ishimori Pro / Toei / Bandai), để quyết định phạm vi việc cần làm trước khi gắn quảng cáo hoặc lên Google Play.
Đây là định hướng kỹ thuật, không phải tư vấn pháp lý.

## Kết luận nhanh

- **Phần lõi (code gameplay) là của mình, giữ được gần như toàn bộ**: combat, hitbox/hurtbox, parry/dodge, hệ form,
  hệ skill (`skill_caster.gd`, `skills.gd`), summon, stage builder, đấu LAN, điều khiển cảm ứng, HUD, bản đồ hành
  tinh, nhạc chiptune tự sinh (`gen_audio.py music`), tiếng hiệu ứng (sfx) tự sinh.
- **Phần nội dung dính IP gần như 100%**: 27 world = 27 series, khoảng 120 sprite form Rider, 103 quái, 88 chân
  dung nhân vật, 131 câu giọng đai, 28 icon Driver, toàn bộ cốt truyện và tên chiêu.
- "Đổi tên + đổi âm thanh" **không đủ**: sprite, quái, cấu trúc world và câu thoại vẫn nhận ra ngay từng series.
- Cách khả thi: **giữ engine, làm lại lớp nội dung với quy mô nhỏ hơn** (đề xuất 6–8 world tự sáng tác cho bản
  thương mại đầu tiên), thay vì đổi tên 27 world.

## Chi tiết theo hạng mục

Mức độ: 🔴 vi phạm rõ, phải thay · 🟡 tên / chi tiết cần đổi · 🟢 của mình, giữ được.

### 1. Tên và nhãn hiệu 🔴
| Chỗ | Hiện trạng | Việc cần làm |
|---|---|---|
| Thư mục repo, file `KamenRider.apk` | Chứa "Kamen Rider" | Đổi tên repo, tên APK |
| `project.godot` | `VPN Chrono(fan game)` | Đặt tên game mới, bỏ "(fan game)" |
| `export_presets.cfg` | `com.namvp.chronohenshin` | Nên đổi nếu tên game đổi ("henshin" là từ tiếng Nhật thông thường, không phải nhãn hiệu, nhưng gắn với Kamen Rider) |
| Chuỗi trong code | "Kamen Rider %s", "Rider Kick", "Kamen Ride: …", "Rider Time Break"… (khoảng 60 chuỗi, 13 file UI + `versus.gd`) | Thay bằng thuật ngữ riêng (ví dụ "Rider" → tên hệ anh hùng của game) |

### 2. Dữ liệu world `scripts/data/worlds/w01…w27` 🔴
Mỗi file là một series: tên Rider, tên Driver (Kabuto Zecter…), form (Hyper Form…), quái (Salis Worm…), địa danh
(Bistro la Salle, trụ sở ZECT…), trùm (Dark Kabuto, Odin, Gaoh, Eternal…), tên chiêu, câu giọng đai
("Henshin. Change, Beetle."…). Cùng loại: `story_data.gd`, `side_worlds.gd`, `scripts/riders/kuuga.gd`,
`faiz.gd`, `double.gd`.

→ **Phải viết lại toàn bộ.** Cấu trúc dữ liệu (WORLD / RIDER / VOICE, stages, forms, skills) giữ nguyên, chỉ thay
nội dung.

Giữ được: nhân vật **Void**, **Pen**, nhân vật chính, mạch "khóa chuỗi các Trái Đất" (kiểm lại xem có bám theo
Decade / Zi-O quá sát không). Cơ chế chung (tăng tốc thời gian, nhân bóng, đổi vũ khí, dạng nguyên tố) là ý tưởng,
dùng được, chỉ cần đổi tên và hình.

### 3. Sprite nhân vật chơi `art/characters/player`, `art/pixellab`, `art/pixelengine` 🔴
Khoảng 120 form: kuuga_*, agito_*, ryuki_*, decade_* (21 thẻ Kamen Ride), zi_o_* (20 Armor), double_* (10 tổ hợp),
ooo_* (8 combo)… Có cả ảnh tham chiếu (`art/pixellab/kuuga_mighty_ref`). Dù do AI vẽ, các sprite này mô phỏng thiết
kế gốc nên vẫn là bản phái sinh.

→ **Vẽ lại toàn bộ** theo thiết kế riêng. Bỏ hẳn hai cơ chế "mượn form Rider khác" (thẻ Decade, Armor Zi-O), vì cả
hai chỉ có nghĩa khi dùng nhân vật thật.

### 4. Quái và trùm `art/characters/enemies`, `art/kitbash` 🔴
103 sprite mang tên và hình chủng quái từng series: Grongi, Lord, Orphnoch, Undead, Worm, Imagin, Fangire, Dopant,
Yummy, Zodiarts, Inves, Roidmude, Bugster, Smash, Magia, Megid, Jyamato, Malgam, Granute, Dai-Shocker… cùng các
trùm Rider (Odin, Dark Kabuto, Eternal, Glare, Genm, Gaoh…).

→ Hệ `tools/kitbash.py` tốt, giữ lại, nhưng 3 thân gốc (jaguar_lord, sheerghost, grongi_zu) cũng là quái gốc nên
cần làm 3 thân mới rồi ghép lại các họ quái tự đặt.

### 5. Chân dung `art/ui/portraits` 🔴
88 ảnh, phần lớn là nhân vật trong phim (godai, tendou, eiji, shotaro, philip, momotaros, kivat, sougo, woz…).
Giữ: hero, void, pen (nếu là nhân vật tự tạo), oblivion. Còn lại thay.

### 6. Icon Driver `art/items/drivers` 🔴
28 icon theo từng Driver. Giữ `chrono.png` (Driver của nhân vật chính, nếu tự thiết kế), còn lại thay.

### 7. Hiệu ứng `art/fx` 🟡
Nhiều hiệu ứng mang biểu tượng series: cards (Decade), crest (Kiva?), dragon (Ryuki), eye (Ghost), fruit (Gaim),
moon (Kiva), phi (Φ của Faiz), rings3, seal, pointer (Kuuga?). Hiệu ứng chung (spark, crack, circle, tachyon) giữ được.
→ Vẽ lại các hiệu ứng có biểu tượng đặc trưng; biểu tượng Φ của Faiz chắc chắn phải bỏ.

### 8. Nền `art/backdrops`, `art/backgrounds` 🟡
Ảnh nền do AI hoặc code tạo, đặt theo tên series. Phần lớn là cảnh chung (phố, phòng thí nghiệm, xa lộ) nên **giữ
được, chỉ đổi tên file**. Cần xem lại nền nào có logo, địa danh hoặc vật thể đặc trưng (ví dụ `fuuto*`: Fuuto là
thành phố trong W; Den-Liner; hình biểu tượng sau lưng trong `backdrops`).

### 9. Âm thanh
| Thư mục | Mức | Việc cần làm |
|---|---|---|
| `audio/henshin_ext/` (14 bản rip từ Zedge) | 🔴 | **Xoá cả thư mục** (README đã ghi) |
| `audio/voice/` (131 câu giọng đai, máy đọc bằng `say`) | 🔴 | Tiếng là tự tạo, nhưng **lời** là câu đai trong phim ("Change, Beetle", "Kamen Ride"…). Viết lời mới vào VOICE của từng world rồi chạy lại `gen_audio.py` |
| `audio/sfx/henshin_<rider>.wav` | 🟢/🟡 | Tự sinh, giữ được; đổi tên file theo world mới |
| `audio/music/` | 🟢 | Chiptune tự soạn bằng `gen_audio.py`; nên xác nhận giai điệu không chép nhạc phim |

### 10. Tài liệu `docs/`, `README.md` 🟡
GDD, FORMS, SKILLS, WORLD_FILES mô tả theo từng series. Không phát hành cùng game nhưng nên cập nhật theo nội dung mới.

## Đề xuất kế hoạch

1. **Tách nhánh**: giữ `main` làm bản fan game miễn phí (để trên itch.io / GitHub, không quảng cáo). Làm bản
   thương mại trên nhánh hoặc repo mới.
2. **Chốt khái niệm IP mới**: tên game, nhân vật chính và Driver Chrono, phe phản diện (Void, Pen), lý do du hành.
   Một hướng gợi ý: mỗi thế giới là một "dòng thời gian" có anh hùng riêng do mình tự nghĩ, nhân vật chính nhận
   sức mạnh dạng "chip / thẻ thời gian" của riêng game.
3. **Thu nhỏ phạm vi**: 6–8 world cho bản đầu (mỗi world 1 anh hùng, 2–3 form, 3 loại quái + 1 trùm). 27 world
   làm lại hết là quá lớn.
4. **Làm lại tài nguyên** cho các world đó: sprite (PixelLab, prompt không nhắc tên Rider), 3 thân quái mới +
   kitbash, chân dung, icon Driver, hiệu ứng, lời giọng đai mới → chạy `gen_audio.py`.
5. **Làm sạch**: xoá `henshin_ext`, chuỗi "Kamen Rider", file world cũ, sprite cũ; đổi tên game và gói.
6. **Kiểm tra lại**: grep tên series / tên Rider / tên quái phải ra 0 kết quả; cho người không biết dự án xem ảnh
   chụp màn hình xem có nhận ra series nào không.
7. Sau đó mới gắn AdMob (bật gradle build) và đưa lên Google Play.

## Ước lượng khối lượng (cho 6 world)
| Hạng mục | Số lượng ước tính |
|---|---|
| Sprite anh hùng (form × animation) | khoảng 15–18 form |
| Quái thường + trùm | khoảng 18 + 6 (kitbash giúp giảm nhiều) |
| Chân dung | khoảng 15 |
| Icon Driver / item | khoảng 8 |
| Hiệu ứng đặc trưng | khoảng 6–10 |
| File world + cốt truyện | 6 file world + `story_data.gd` viết lại |
| Giọng đai | khoảng 30 câu (tự sinh) |

Lưu ý credit PixelLab gói miễn phí (xem ghi chú trong memory): sprite là phần tốn nhất, nên làm từng world một.
