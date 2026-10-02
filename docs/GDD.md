# Kamen Rider: Chrono Henshin — Tài liệu thiết kế game (GDD)

> Fan game phi thương mại · Bản 0.2 · 29/09/2026
> Bản 0.2: đổi cấu trúc thành **chuỗi thế giới**. Mỗi thế giới cho một Driver, lên cấp qua từng màn, trùm rơi Driver của thế giới kế tiếp.
> Bản 0.3: thêm hệ thanh tài nguyên (2 hoặc 3 thanh), chỉ số riêng cho từng dạng/form, cấp độ quái.
> Bản 0.4: màn chơi kiểu **Contra** — đường cuộn ngang, camera chỉ tiến, vực, bệ nhiều tầng, bắn 8 hướng, quái chạy ào và lính bắn tỉa.
> Bản 0.13: **27 thế giới theo năm phát sóng** (Kuuga 2000 → Zeztz 2025), chơi được liền mạch 139 màn (OOO 9 màn, các thế giới khác 5 màn). Faiz thành thế giới 4, W thành thế giới 11. Mỗi thế giới là một file dữ liệu (`scripts/data/worlds/`, đặc tả ở `docs/WORLD_FILES.md`); Rider mới dựng từ dữ liệu (`DataRider`). Rider thế hệ sau mạnh hơn, quái tăng cấp chậm hơn để 27 thế giới cân bằng (mục 2.4, 3.13).
> Bản 0.12: **sửa AI quái**: quái chạy ào tới gần người chơi thì dừng lại đuổi đánh (không lướt qua bỏ mặc), vướng thùng thì nhảy qua; quái đánh xong nghỉ 1 giây mới xin lượt mới để quái đang chờ được vào đánh; quái không còn bị thả lọt vào chồng thùng rồi xuyên qua (mục 3.13).
> Bản 0.11: **luồng qua màn mới**: qua màn thì dọn quái, **giải trừ biến thân về dạng người**, thoại, kết quả, rồi màn hình tối dần sang màn mới và **đổi nền theo bối cảnh màn** (14 nền vẽ bằng `tools/gen_backgrounds.py`). Mỗi màn bắt đầu ở dạng người, máu người đầy, nộ đầy (mục 3.1).
> Bản 0.10: **camera đi tự do hai chiều**: chạy ngược lại, leo ngược giếng tụt đều được; tường vô hình chỉ còn ở đầu màn (sau điểm xuất phát) và hai bên đấu trường trùm. Quái chỉ nhảy lên / tụt xuống bệ khi người chơi đang đứng ở đó, không nhảy theo lúc người chơi nhảy (mục 3.14).
> Bản 0.9: **phần mở đầu (intro) và hội thoại dạng chữ**. Bối cảnh mới: có nhiều Trái Đất song song, mỗi Trái Đất là một thế giới Rider; Chronos Void hút hết sức mạnh Driver rồi trốn tới Trái Đất "Điểm Không"; nhân vật chính được Pen giao nhiệm vụ lấy lại sức mạnh từng Driver. Hội thoại hiện ở đầu màn, lúc gặp trùm, lúc nhặt Driver/form, lúc qua màn; sau mỗi trùm có bản đồ Chuỗi Trái Đất (mục 2.1, 2.5, 3.18).
> Bản 0.8: **chọn Rider chính trước mỗi màn** (màn chọn có thanh chỉ số); đội hình trong màn = Rider chính + Rider của thế giới, Đổi Rider chỉ đổi giữa hai Rider này; bỏ ô trang bị 1–3. Chỉ số 3 Rider khác biệt rõ: Kuuga bền, Faiz nhanh và đánh mạnh, W nhảy cao. D-pad 4 nút cùng cỡ.
> Bản 0.7: bỏ nút Đá và thanh Năng lượng: nút **Đánh** đấm theo chuỗi rồi tự ra **cú đá** kết thúc (mạnh hơn, phá giáp). Nút cảm ứng: D-pad ◀ ▶ ▲ ▼ góc trái (▲ = nhảy), Đánh + kỹ năng góc phải.
> Bản 0.6: màn **kiểu Contra / Contra 2**: lộ trình nhiều đoạn (chạy sang phải, sang trái, leo giếng lên, tụt giếng xuống), thùng và bậc khối để nhảy lên, cột đá giữa vực rộng.
> Bản 0.5: **chỉ form có súng mới bắn được**; đạn quái bay ngang ở 2 độ cao (cúi / nhảy để né); **quái rơi Driver và form** ngẫu nhiên; **thanh nộ là nhiên liệu của form đặc biệt**, hết nộ thì về form gốc; bỏ chế độ 2 thanh; bỏ Kuuga Growing (form gốc là Mighty).
> Các con số ở mục 3 khớp với code trong `scripts/`. Khi chỉnh cân bằng, sửa code rồi cập nhật lại bảng.

---

## 0. Tóm tắt

| Mục | Nội dung |
|---|---|
| Thể loại | Action platformer màn ngang, combat kiểu beat 'em up |
| Đồ họa | Pixel art 2D nhìn ngang, độ phân giải gốc 320×180 |
| Nền tảng | PC trước, sau đó Android và Web |
| Engine | **Godot 4.4 trở lên** |
| Vòng lặp cốt lõi | **Vào thế giới mới → quái rơi Driver → biến thân → qua 3 màn, mỗi màn nhặt một form mới → hạ trùm → nhận Driver của thế giới kế tiếp** |
| Quy mô | 27 thế giới theo **năm phát sóng** (Kuuga 2000 → Zeztz 2025) và thế giới cuối "Điểm Không". Bản hiện tại chơi được cả 27 thế giới (139 màn); Điểm Không chưa làm |

**Tóm tắt vòng lặp một thế giới:**
```
 Driver bị phong ấn (nhận từ trùm thế giới trước)
        │
        ▼
 X-1 THỨC TỈNH  ── chơi bằng Rider cũ ─────────► quái rơi Driver → nhặt → biến thân form gốc, Lv1
 X-2 LUYỆN TẬP  ── quái rơi form thứ nhất ─────► Lv2
 X-3 LUYỆN TẬP  ── quái rơi form thứ hai ──────► Lv3
 X-4 LUYỆN TẬP  ── quái rơi form thứ ba ───────► Lv4
 X-B TRÙM       ── bài kiểm tra cuối ──────────► Lv5
        │                                       + rơi Driver thế giới kế tiếp (phong ấn)
        ▼
 Cổng thế giới tiếp theo mở ...
```
Riêng màn 1-1 (màn đầu tiên của cả game), người chơi **chưa có Driver nào** nên phải đánh ở dạng người để giành lấy Arcle.

---

## 1. Engine và công cụ

### 1.1 Chọn Godot 4

1. **Mỗi thế giới là một file dữ liệu** (`scripts/data/worlds/wNN_<id>.gd`: Rider và form, quái, 5 màn (OOO 9 màn: mỗi combo cùng hệ một màn), trùm, thoại, nền). Rider dựng từ dữ liệu bằng `DataRider`; chỉ Rider có cơ chế đặc biệt (Kuuga, Faiz, W) mới có script riêng. Thêm thế giới mới không phải sửa code lõi. Với 26 thế giới, đây là yếu tố quan trọng nhất.
2. **`AnimationPlayer`** keyframe được sprite, âm thanh, rung camera và hitbox trên cùng một timeline. Hợp để dựng hơn 26 cảnh biến thân và hơn 130 Final Attack.
3. **Pixel-perfect có sẵn**: viewport 320×180, phóng to theo số nguyên, lọc Nearest (đã cấu hình trong `project.godot`).
4. **`Area2D`** dùng làm hitbox, hurtbox, vật phẩm nhặt và vùng khóa màn.
5. Miễn phí, nhẹ, xuất được nhiều nền tảng. Quan trọng với fan game vì không có doanh thu.

| So với | Vì sao không chọn |
|---|---|
| Unity | Nặng, phần 2D pixel phải cấu hình nhiều, từng thay đổi điều khoản giá |
| GameMaker | Xuất bản phải trả phí; ngôn ngữ GML khó tổ chức khi có 26 hệ Rider |
| Phaser | Chỉ hợp game trình duyệt, thiếu editor dựng màn và animation |

### 1.2 Công cụ đi kèm

| Việc | Công cụ |
|---|---|
| Sprite và animation | Aseprite (hoặc LibreSprite) + plugin *Aseprite Wizard* |
| Dựng màn | `TileMapLayer` có sẵn trong Godot |
| Hiệu ứng âm thanh / nhạc | jsfxr, ChipTone / BeepBox, FamiStudio |
| Quản lý mã nguồn | Git |

Quy ước kích thước: dạng người 32×32, Rider 48×48, quái 32–48, trùm từ 96×96 trở lên, tile 16×16.

---

## 2. Kịch bản

### 2.1 Bối cảnh — Nhiều Trái Đất và Chuỗi Phong Ấn

Vũ trụ có **vô số Trái Đất song song**. Mỗi Trái Đất là một thế giới Rider (Trái Đất Kuuga, Trái Đất Faiz, Trái Đất W...), có Kamen Rider của riêng nó. Sức mạnh của mỗi Rider nằm trong Driver.

**Chronos Void** xuất hiện giữa các Trái Đất và **hút sạch sức mạnh khỏi Driver của mọi Rider**. Các Trái Đất lần lượt tắt sáng. Mang theo toàn bộ sức mạnh đó, hắn **trốn tới Điểm Không**, Trái Đất nằm ở tận cùng, ngoài mọi dòng thời gian, để viết lại thời gian thành một thế giới "không cần anh hùng".

Sau lưng, hắn khóa đường đi bằng **Chuỗi Phong Ấn**:

- **Sức mạnh của mỗi Driver bị cấy vào quái vật ở từng Trái Đất.** Quái rơi ra Driver và form khi bị hạ (mục 3.8).
- **Driver là chìa khóa.** Chỉ Driver của một Trái Đất mới mở được cổng dẫn tới Trái Đất đó.
- **Driver của Trái Đất tiếp theo bị giấu trong kẻ mạnh nhất Trái Đất trước**, phong ấn bằng tinh thể tím. Chỉ khi mang về đúng Trái Đất của nó và vượt qua thử thách ở đó, nó mới thức tỉnh.

Vì vậy, muốn tới Điểm Không thì phải đi hết chuỗi, từng Trái Đất một. Đó chính là điều Void muốn: *"Nếu có kẻ nào đi được hết chuỗi này, ta sẽ đợi hắn ở cuối."*

Khe nứt Void mở khi bỏ trốn quét qua **Tokyo 2026**, một Trái Đất chưa từng có Kamen Rider. Arcle của Kuuga rơi xuống Shibuya, lũ Grongi theo sau. **Pen**, AI trong Chrono Pass, chọn nhân vật chính và **giao nhiệm vụ: lấy lại sức mạnh của mọi Driver, đi hết Chuỗi Phong Ấn, chặn Void ở Điểm Không.** Mỗi khi hạ trùm một Trái Đất, Trái Đất đó sáng trở lại trên bản đồ Chuỗi Trái Đất.

### 2.2 Nhân vật

| Nhân vật | Vai trò |
|---|---|
| **Nhân vật chính** (19 tuổi, **tên do người chơi đặt**, mặc định "Sora") | Shipper ở Tokyo, tóc đen, áo khoác xanh sọc vàng. Tốt bụng, liều lĩnh. Anh trai mất tích trong một vụ hỏa hoạn 10 năm trước. |
| **Pen** (Pendulum) | AI sống trong **Chrono Pass**, một tấm vé tàu phát sáng đọc được Driver và mở cổng thế giới. Nói nhiều, hay chê Sora. Bí mật: từng là cộng sự của Void. |
| **Chronos Void / Rei** | Phản diện, anh trai của nhân vật chính. Mười năm trước, Rei cứu Sora khỏi đám cháy do khe nứt thời gian gây ra, rồi bị kéo vào một dòng thời gian đã bị xóa, nơi không Rider nào đến cứu. Rei muốn viết lại thời gian thành thế giới "không cần anh hùng". |
| **Echo Rider** | "Tiếng vọng" của Rider gốc ở mỗi thế giới (Godai, Takumi, Shotaro...). Họ mất Driver nhưng vẫn chiến đấu theo cách của mình, dẫn dắt Sora qua màn Thức tỉnh và các màn luyện tập. |
| **Hollow Kaijin** | Quái vật bị nhiễm Void, mắt phát sáng tím. |

> **Tên nhân vật chính:** người chơi đặt tên ở màn hình đầu game. Trong kịch bản, "SORA" là tên mặc định. Chỗ nào nhân vật khác gọi tên nhân vật chính thì viết `{name}`; game tự thay bằng tên người chơi (`GameState.format_text`).

### 2.3 Khuôn một thế giới

| Màn | Loại | Người chơi dùng | Nội dung | Phần thưởng |
|---|---|---|---|---|
| **X-1** | Thức tỉnh | Các Rider đã có (riêng thế giới 1: dạng người) | Thử thách riêng của thế giới để giải phong ấn Driver (xem kiểu thử thách ở mục 3.4). Echo Rider xuất hiện | Driver hoạt động, **Lv1** |
| **X-2** | Luyện tập | Rider mới Lv1 + Rider cũ | Làm quen Rider mới | **Lv2** |
| **X-3** | Luyện tập | Lv2 | Màn được thiết kế để dạy kỹ năng Lv2 | **Lv3** |
| **X-4** | Luyện tập | Lv3 | Màn dạy kỹ năng Lv3 | **Lv4** |
| **X-B** | Trùm | Lv4 | Trùm có điểm yếu khắc chế bởi kỹ năng của Rider thế giới đó | **Lv5** (form tối thượng) + **Driver thế giới kế tiếp** |

**Nguyên tắc thiết kế:** màn thứ N luôn có tình huống cần tới kỹ năng vừa mở ở màn N-1, ví dụ tường cao cần Dragon, quái bay cần Pegasus, quái giáp cần Titan. Nhờ vậy lên cấp luôn *có cảm giác*, không chỉ là tăng số.

Mỗi thế giới giấu 1 **Ký ức của Rei** ở một màn luyện tập, cần tới kỹ năng của thế giới sau mới lấy được. Đây là lý do để chơi lại màn cũ.

### 2.4 Cấu trúc toàn game

```
Thứ tự = năm phát sóng. Số trong ngoặc là số thế giới (mã màn "4-1" = thế giới 4, màn 1).

Mở đầu ─► Hồi 1 (2000–2008): Kuuga(1) ─► Agito(2) ─► Ryuki(3) ─► Faiz(4) ─► Blade(5) ─► Hibiki(6)
                               ─► Kabuto(7) ─► Den-O(8) ─► Kiva(9)            kết hồi: Void "Về nhà đi", Pen thú nhận
       ─► Giữa game (2009):   Decade(10), kẻ du hành qua các thế giới
       ─► Hồi 2 (2009–2018):  W(11) ─► OOO(12) ─► Fourze(13) ─► Wizard(14) ─► Gaim(15) ─► Drive(16)
                               ─► Ghost(17) ─► Ex-Aid(18) ─► Build(19) ─► Zi-O(20)   kết hồi: Void là Rei, anh trai
       ─► Hồi 3 (2019–2025):  Zero-One(21) ─► Saber(22) ─► Revice(23) ─► Geats(24) ─► Gotchard(25)
                               ─► Gavv(26) ─► Zeztz(27)                       trùm rơi Chrono Driver
       ─► Thế giới cuối: Điểm Không ─► Kết thúc thường / Kết thúc thật   (chưa làm)
       ─► Post-game: Đường Huyền Thoại (Rider thời Showa)
```

**Trạm Thời Không (hub, mở sau màn 1-1):** nhà ga bỏ hoang trôi giữa hư không.
- Mỗi cửa soát vé là một thế giới. Cửa chỉ sáng khi có Driver tương ứng.
- **Phòng chờ**: xem chỉ số và form của các Rider (việc chọn Rider chính diễn ra trước mỗi màn, mục 3.2).
- **Máy bán hàng tự động** để nâng cấp chung bằng Mảnh Ký Ức.
- **Bảng giờ tàu** để chơi lại màn cũ.
- Pen kể thêm một đoạn quá khứ sau mỗi thế giới.

---

### 2.5 Mở đầu và Thế giới 1 — Kuuga: *"Vì nụ cười"*

**Phần mở đầu** *(cutscene, `scenes/ui/intro.tscn`, chạy sau màn đặt tên; Esc / "BỎ QUA" để bỏ qua)*

Lời thoại đầy đủ nằm ở `StoryData.INTRO` (`scripts/data/story_data.gd`). Sáu cảnh, hình vẽ bằng code:

| Cảnh | Hình | Nội dung |
|---|---|---|
| Đa vũ trụ | Các Trái Đất màu của từng Rider trôi giữa sao | Có vô số Trái Đất, mỗi Trái Đất có một Rider, sức mạnh nằm trong Driver |
| Hút sức mạnh | Void giữa vòng đồng hồ, dòng sáng chảy từ từng Trái Đất về tay hắn, các Trái Đất xám dần | *"Năm mươi lăm năm. Bao nhiêu anh hùng... vậy mà thế giới của ta không có lấy một người."* |
| Bỏ trốn | Void bay vào khe nứt tới Điểm Không, xích tinh thể nối các Trái Đất đã tắt | Hắn trốn tới Điểm Không, khóa đường bằng Chuỗi Phong Ấn |
| Tokyo 2026 | Shibuya về đêm, bầu trời nứt, Arcle rơi xuống đường | Trái Đất chưa từng có Rider; {name} thấy đai rơi, quái theo sau |
| Pen | Chrono Pass lơ lửng cạnh {name}, Grongi chạy tới | Pen tự giới thiệu, kể chuyện Void, giao nhiệm vụ; {name}: *"Tôi chỉ là người giao hàng thôi mà!"* |
| Nhiệm vụ | Bản đồ Chuỗi Phong Ấn: Tokyo 2026 → Kuuga → Faiz → W → Agito → Ryuki → ... → Điểm Không | *"Giao hàng tận nơi là nghề của tôi mà."* Chặng đầu: giành lại Arcle |

Sau cùng là thẻ tựa **KAMEN RIDER · CHRONO HENSHIN**, bấm để vào màn 1-1.

#### Màn 1-1 · Shibuya hỗn loạn — *Thức tỉnh, chơi ở dạng người*

Hội thoại trong màn chơi (đầu màn, gặp trùm, nhặt Driver/form, qua màn) nằm ở `StoryData.STAGES`; bảng dưới đây là tóm tắt, câu chữ chính thức lấy theo code.

> *Lũ Grongi từ Trái Đất Kuuga tràn qua khe nứt.* (Pen đã xuất hiện ở phần mở đầu.)
> **PEN:** Một con trong đám đó đang giữ Arcle.
> **SORA:** Tôi phải đánh bằng tay KHÔNG á?!

- **Hướng dẫn:** di chuyển, nhảy, cúi, đánh (chuỗi đấm rồi đá), né, thanh máu. Dạng người không có súng: lính Grongi bắn đạn đỏ thì cúi, đạn xanh thì nhảy. Thanh nộ đầy nhưng chưa có Driver để biến thân.

- **Mục tiêu:** hạ Grongi cho tới khi Arcle rơi ra (một con Grongi đang giữ nó). Chưa rơi thì tên đầu lĩnh cuối màn giữ nó.

> *Sora nhặt Arcle. Chiếc đai phát sáng và hòa vào cơ thể anh.*
> **PEN:** Nó... chọn cậu rồi. Hô lên đi!
> **SORA:** ...HENSHIN!
> *Bộ giáp đỏ của Kuuga Mighty Form hiện ra.*

→ **Arcle kích hoạt, Kuuga Lv1 (Mighty Form, form gốc), nộ đầy.**

> *Mọi thứ đông cứng. Void hiện ra trên nóc tòa nhà.*
> **VOID:** Thằng nhóc giao hàng à. Được thôi. Driver tiếp theo nằm trong kẻ mạnh nhất thế giới Kuuga. Đi hết chuỗi đi, rồi ta nói chuyện.
> **PEN** *(run rẩy)*: ...Cái giọng đó...
> *Arcle cộng hưởng với Chrono Pass, cổng Thế giới Kuuga mở ra.*

#### Màn 1-2 · Di tích Kuuga — *Luyện tập, lên Lv2*

Ở di tích cổ Nagano, Sora gặp **Godai Yusuke** (Echo). Godai không biến thân được nữa, nhưng vẫn cười và dẫn dân đi sơ tán.

> **GODAI:** Cậu cũng đến giúp à? Tốt quá!
> **SORA:** Anh không sợ à?
> **GODAI:** Sợ chứ. Nhưng nếu tôi mà mặt mày ủ rũ thì mọi người còn sợ hơn. *(giơ ngón cái)*
>
> *(Cuối màn)*
> **GODAI:** Kuuga có nhiều màu lắm, mỗi màu là một cách để bảo vệ người khác. Nhưng màu nào rồi cũng phai. Lúc đó cứ quay về màu đỏ, chỗ cậu bắt đầu.

→ **Quái rơi Dragon Form** (nhặt: nộ đầy, biến thân ngay; mở khóa đổi form bằng L) · **Kuuga Lv2.**

#### Màn 1-3 · Tokyo về đêm — *lên Lv3*
Thanh tra cảnh sát yểm trợ bằng súng. Grongi hạng Me bay trên nóc nhà, lính bắn đứng gác trên đường. Kuuga chưa có súng nên người chơi thấy cần bắn xa.
→ **Quái rơi Pegasus Form** (form súng đầu tiên) · **Lv3.**

#### Màn 1-4 · Kho hàng bến cảng — *lên Lv4*
Tường cao cần Dragon, quái bay cần Pegasus. Grongi hạng Go có giáp dày xuất hiện cuối màn, gây cảm giác "phải có thứ gì đó mạnh hơn".
→ **Quái rơi Titan Form** · **Lv4.**

#### Màn 1-B · Trùm: N-Daguba-Zeba
> **DAGUBA** *(cười)*: Cậu... sẽ làm tôi vui hơn chứ?
> **SORA:** Tôi không đến đây để chơi với anh.

Pha 1 cận chiến (dùng Titan để đỡ đòn), pha 2 phóng lửa trên mặt đất (dùng Dragon nhảy tránh), pha 3 đốt cháy từ xa (dùng Pegasus bắn trả từ chỗ nấp).

> *(Sau trận) Thân xác Daguba tan thành tro. Giữa đống tro là một chiếc đai kim loại bị bọc trong tinh thể tím: **Faiz Driver**.*
> **GODAI:** Đánh nhau chẳng phải chuyện hay ho. Nhưng nếu phải đánh để giữ nụ cười cho mọi người, thì đừng đánh mất nụ cười của chính mình.
> **PEN:** Driver của Faiz... bị phong ấn rồi. Phải mang tới thế giới của nó mới giải được.

→ **Kuuga Lv5: Rising (Final Attack ×1.5)** · **Nhận Faiz Driver (phong ấn)**.

---

Từ đây, mục 2.6 và 2.7 là thiết kế gốc của Faiz và W. Nội dung đầy đủ của mọi thế giới (thoại, form, trùm) nằm trong file thế giới; bảng tóm tắt 27 thế giới ở mục 2.8.

### 2.6 Thế giới 4 — Faiz: *"Giấc mơ"*

#### Màn 4-1 · Tiệm giặt ủi Kikuchi — *Thức tỉnh, chơi bằng các Rider đã có*
Faiz Driver vẫn bị phong ấn. Pen phát hiện nó thiếu **Faiz Phone**, thiết bị nhập mã biến thân, và Orphnoch đã cướp mất. **Inui Takumi** (Echo), người giao đồ cho tiệm giặt, cộc cằn và sợ đồ nóng, miễn cưỡng dẫn đường.

- **Mục tiêu:** bảo vệ Takumi, hạ Orphnoch cho tới khi Faiz Phone rơi ra.

> **TAKUMI:** Tôi không có ước mơ. Nhưng tôi có thể bảo vệ ước mơ của người khác.
> **SORA:** Tôi thì có. Tôi muốn tìm lại anh trai mình.
> **TAKUMI:** Vậy thì đừng có chết trước khi tìm được. *(ném Faiz Phone cho {name})* Mã là 5-5-5.
>
> *Sora nhập mã (mini-game bấm nút). Tinh thể tím vỡ tan.* **HENSHIN!**

→ **Faiz Lv1.** Faiz vào đội hình cùng Rider chính (Kuuga), đổi qua lại bằng nút Đổi Rider. Từ màn 4-2, trước mỗi màn chọn Kuuga hoặc Faiz làm Rider chính.

#### Màn 4-2 · Đường cao tốc — *lên Lv2*
Màn tự cuộn ngang trên xe Auto Vajin. Riotrooper đuổi theo bằng xe máy, Orphnoch tốc độ bám theo, né gần hết đòn thường. Takumi: "Thứ đó nhanh hơn mắt cậu." → **Quái rơi Axel Form** (nộ đầy = 10 giây) · **Lv2.**

#### Màn 4-3 · Sảnh Smart Brain — *lên Lv3*
Không có form mới. Người chơi tập tích nộ ở form gốc rồi bật Axel đúng lúc quái tốc độ ùa ra. → **Lv3.**

#### Màn 4-4 · Phòng thí nghiệm — *lên Lv4*
Đầy quái tốc độ và lính bắn. → **Quái rơi Blaster Form** (máu 200, giáp 40, cầm Faiz Blaster) · **Lv4.**

#### Màn 4-B · Trùm: Dragon Orphnoch
Hai dạng đổi nhau: *Pháp sư* (chậm, bắn phép tầm xa) và *Long nhân* (siêu tốc, né 75% đòn). Phải để dành nộ để bật Axel lúc hắn đổi sang dạng Long nhân.

> *(Sau trận) Trong lõi tro của Dragon Orphnoch là **Double Driver**, bị phong ấn.*
> *Void đứng xa trên nóc tòa nhà.* **VOID:** Đi nhanh hơn ta tưởng đấy... {name}.
> *(Sora không nghe thấy. Pen thì nghe thấy, và im lặng.)*

→ **Faiz Lv5** · **Nhận Double Driver (phong ấn)**.

---

### 2.7 Thế giới 11 — W: *"Hai người, một Rider"*

#### Màn 11-1 · Văn phòng thám tử Narumi — *Thức tỉnh, chơi bằng các Rider đã có*
Ở thành phố gió Fuuto, Void đã kéo **Philip** vào hư không. **Hidari Shotaro** (Echo) mất "nửa kia". Double Driver cần hai Gaia Memory (Cyclone và Joker) và **hai tâm trí**.

- **Mục tiêu:** hạ Dopant cho tới khi Double Driver (kèm Memory Cyclone và Joker) rơi ra.

> **SHOTARO:** Rider không bao giờ chiến đấu một mình, kể cả khi trông có vẻ như vậy.
> **SORA:** Nhưng tôi đâu có cộng sự...
> **PEN** *(bay ra khỏi Chrono Pass)*: ...Có đấy. Để tôi lo nửa bên trái.

→ **W Lv1: CycloneJoker (form gốc).** Pen điều khiển nửa Soul, có lời thoại khi người chơi đổi Memory.

| Màn | Bối cảnh | Nội dung | Quái rơi ra · phần thưởng |
|---|---|---|---|
| 11-2 | Phố gió Fuuto | Dopant giáp xuất hiện, W chỉ có tay chân nên đánh rất vất vả | **Memory Heat & Metal** · Lv2 |
| 11-3 | Tháp gió | Nhiều quái giáp (dùng Metal), mục tiêu ở xa ngoài tầm với | **Memory Luna & Trigger** (đủ 9 tổ hợp) · Lv3 |
| 11-4 | Khu công nghiệp | Trộn quái nhanh và quái giáp; Shotaro dạy về "Best Match". Tín hiệu của Philip lọt ra từ hư không | **Xtreme Memory** · Lv4: bonus Best Match |

#### Màn 11-B · Trùm: Kamen Rider Eternal
Giáp dày (chỉ đòn nặng và Final xuyên được). Pha 3 là mưa Maximum Drive, phải đổi form liên tục. Giữa trận, **Philip thoát khỏi hư không** nhờ tín hiệu từ Driver.

> **PHILIP:** Xin lỗi vì đến trễ. Cho tôi mượn cơ thể một chút nhé.
> *Cánh chim Xtreme lao xuống, hợp nhất với W.*
>
> *(Sau trận)* **PHILIP:** Pendulum... dữ liệu về cậu trong Thư viện Trái Đất bị xóa trắng. Lẽ ra cậu không được tồn tại.

→ **W Lv5** · **Nhận OOO Driver (phong ấn).**

#### Kết Hồi 1 *(cuối thế giới 9 — Kiva, màn 9-B)*
> *Void chặn Sora ngay sau trận trùm Kiva, nhấn chìm cậu trong bóng tối. Sora thua, nhưng mặt nạ Void bị nứt một góc.*
> **VOID:** Về nhà đi, **{name}**.
> **SORA:** ...Sao hắn biết tên mình?
> **PEN** *(im lặng rất lâu)*: Vì tôi từng là Chrono Pass của hắn.

---

### 2.8 Chuỗi Driver toàn game

27 thế giới theo năm phát sóng. Trùm mỗi thế giới rơi Driver của thế giới kế tiếp (còn phong ấn); trùm thế giới 27 rơi **Chrono Driver**. Bảng sinh tự động từ file thế giới bằng `godot --headless --path . -s tools/world_table.gd` (chạy lại khi sửa dữ liệu). Chi tiết (mục tiêu màn Thức tỉnh, kiểu đòn và chỉ số từng form, thoại) nằm trong `scripts/data/worlds/`.

| # | Năm | Rider | Driver | Form gốc · form rơi ở các màn luyện tập | Lv5 | Trùm | Echo Rider |
|---|---|---|---|---|---|---|---|
| 1 | 2000 | Kuuga | Arcle | Mighty · Dragon Form / Pegasus Form / Titan Form | Rising | N-Daguba-Zeba | Godai |
| 2 | 2001 | Agito | Alter Ring | Ground Form · Storm Form / Flame Form / Trinity Form | Shining | Overlord of Darkness | Tsugami Shouichi |
| 3 | 2002 | Ryuki | Advent Deck | Ryuki · Sword Vent / Strike Vent / Guard Vent (vũ khí) | Ryuki Survive (final form) | Kamen Rider Odin | Kido Shinji |
| 4 | 2003 | Faiz | Faiz Driver | Faiz · Axel Form / — / Blaster Form | sát thương +40%, máu +32% | Dragon Orphnoch | Takumi |
| 5 | 2004 | Blade | Blay Buckle | Ace Form · Mach Jaguar / Thunder Deer / Jack Form | King Form | Caucasus Undead | Kenzaki Kazuma |
| 6 | 2005 | Hibiki | Henshin Onsa | Hibiki · Onibi / Kaentsuzumi / Hibiki Kurenai | Armed Hibiki | Orochi | Hibiki |
| 7 | 2006 | Kabuto | Kabuto Zecter | Rider Form · — / — / Hyper Form | Perfect Zecter | Dark Kabuto | Tendou Souji |
| 8 | 2007 | Den-O | Den-O Belt | Sword Form · Rod Form / Ax Form / Gun Form | Climax Form | Kamen Rider Gaoh | Nogami Ryotaro |
| 9 | 2008 | Kiva | Kivat-bat III | Kiva Form · Garulu Form / Basshaa Form / Dogga Form | Emperor Form | Dark Kiva | Kurenai Wataru |
| 10 | 2009 | Decade | Decadriver | Decade · Attack Ride: Slash / Attack Ride: Blast / Kamen Ride: Kabuto | Complete Form | Apollo Geist | Kadoya Tsukasa |
| 11 | 2009 | W | Double Driver | CycloneJoker · Memory Heat & Metal / Memory Luna & Trigger / Xtreme Memory | sát thương +40%, máu +32% | Kamen Rider Eternal | Shotaro |
| 12 | 2010 | OOO | OOO Driver | TaToBa Combo · LaTorarTar Combo / GataKiriBa Combo / ShaUTa Combo / TaJaDor Combo / SaGohZo Combo / PuToTyra Combo / BuraKaWani Combo | Super TaToBa | Kazari | Hino Eiji |
| 13 | 2011 | Fourze | Fourze Driver | Base States · Rocket States / Elek States / Fire States | Cosmic States | Sagittarius Zodiarts | Kisaragi Gentaro |
| 14 | 2012 | Wizard | WizarDriver | Flame Style · Water Style / Hurricane Style / Land Style | Infinity Style | Wiseman | Soma Haruto |
| 15 | 2013 | Gaim | Sengoku Driver | Orange Arms · Pine Arms / Ichigo Arms / Jimber Lemon Arms | Kiwami Arms | Lord Baron | Kazuraba Kouta |
| 16 | 2014 | Drive | Drive Driver | Type Speed · Type Wild / Type Technic / Type Formula | Type Tridoron | Heart Roidmude | Tomari Shinnosuke |
| 17 | 2015 | Ghost | Ghost Driver | Ore Damashii · Musashi Damashii / Edison Damashii / Newton Damashii | Mugen | Adel | Tenkuji Takeru |
| 18 | 2016 | Ex-Aid | Gamer Driver | Action Gamer Level 2 · Sports Action Gamer Level 3 / Robot Action Gamer Level 3 / Hunter Action Gamer Level 5 | Muteki Gamer | Kamen Rider Genm | Hojo Emu |
| 19 | 2017 | Build | Build Driver | RabbitTank · GorillaMond / HawkGatling / NinninComic | Genius | Evolto | Kiryu Sento |
| 20 | 2018 | Zi-O | Ziku Driver | Zi-O · Build Armor / Ex-Aid Armor / Decade Armor | Grand Zi-O | Another Zi-O | Tokiwa Sougo |
| 21 | 2019 | Zero-One | Hiden Zero-One Driver | Rising Hopper · Flaming Tiger / Freezing Bear / Shining Hopper | Zero-Two | Ark-Zero | Hiden Aruto |
| 22 | 2020 | Saber | Seiken Swordriver | Brave Dragon · Crimson Dragon / Dragonic Knight / Elemental Primitive Dragon | Xross Saber | Storious | Kamiyama Touma |
| 23 | 2021 | Revice | Revice Driver | Rex Genome · Eagle Genome / Jackal Genome / Mammoth Genome | Ultimate Revice | Giff | Igarashi Ikki |
| 24 | 2022 | Geats | Desire Driver | Magnum Form · Boost Form / Powered Builder Form / Magnum Boost Form | Geats IX | Kamen Rider Glare | Ukiyo Ace |
| 25 | 2023 | Gotchard | Gotchard Driver | Steamhopper · Appare Skebow / Venom Mariner / Burning Gorilla | Rainbow Gotchard | Glion | Ichinose Houtarou |
| 26 | 2024 | Gavv | Henshin Belt Gavv | Poppingummy Form · Fuwamallow Form / Chocodan Form / Zakuzakuchips Form | Over Mode | Bocca Jaldak | Shouma |
| 27 | 2025 | Zeztz | Zeztz Driver | Physicam Impact · Physicam Wing / Inazuma Plasma / Paradigm Gravity | Exdream | Oblivion Gore Nightmare | Yorozu Baku |

> Series 2026 trở đi: thêm một file thế giới và một dòng vào `WorldData.FILES` trước khi làm thế giới cuối.

---

### 2.9 Thế giới cuối — Điểm Không

Trùm thế giới Gavv rơi ra **Chrono Driver**, chiếc Driver không thuộc về Rider nào. Đó là Driver của **chính Sora**, được tạo nên từ mọi Driver trong chuỗi. Thế giới cuối dùng cùng khuôn 5 màn:

| Màn | Nội dung | Phần thưởng |
|---|---|---|
| Z-1 Thức tỉnh | Tháp đồng hồ đổ nát. Mỗi đợt quái bị hạ, một Echo Rider lên tiếng trao lại sức mạnh | **Kamen Rider Chrono Lv1**: dùng được đòn của mọi Rider đang mang |
| Z-2 | Hành lang Lịch sử I: đấu lại 3 trùm cũ (bản Hollow) | Lv2: mang được 4 Driver |
| Z-3 | Hành lang Lịch sử II | Lv3: đổi Rider không mất thời gian hồi chiêu |
| Z-4 | Hành lang Lịch sử III | Lv4: All Final, nối Final Attack của 2 Rider liền nhau |
| Z-B | **Chronos Void**, 3 pha (bên dưới) | Lv5: **Chrono Legacy Form** giữa trận → kết thúc game |

- **Pha 1 — Void Blade:** đấu kiếm tay đôi, Void dịch chuyển liên tục.
- **Pha 2 — Hollow History:** Void dùng bản sao đen của chính các Rider người chơi đang mang. Phải đổi Rider để khắc chế.
- **Pha 3 — Void Omega:** Void khổng lồ chiếm cả màn hình. Sora lên Chrono Legacy Form. Mỗi lần đánh trúng điểm yếu, một Echo Rider hỗ trợ. Kết thúc bằng QTE **All Rider Kick**.

> **REI:** Mười năm trước, anh đã chờ. Không một Rider nào đến. Vậy tại sao thế giới của em lại được có anh hùng?
> **SORA:** Vì có một người đã đến, anh hai. Người kéo em ra khỏi đám cháy hôm đó... chính là anh.
> **PEN:** Rei... trước khi bị kéo đi, cậu đã dặn tôi: "Nếu tôi lạc đường, hãy đi tìm {name}." Tôi chỉ làm đúng lời dặn thôi.

### 2.10 Kết thúc và post-game

- **Kết thúc thường:** Rei tan biến cùng dòng thời gian đã bị xóa. Sora lại đạp xe giao hàng dưới bầu trời đã lành. Chrono Pass trong túi anh đã tắt sáng.
- **Kết thúc thật** *(cần đủ 26 Ký ức của Rei)*: Chrono Driver mở lại dòng thời gian bị xóa và kéo Rei trở về. Mở khóa **Kamen Rider Void** (chơi được) và chế độ 2 người "Anh em".
- **Đường Huyền Thoại:** các màn thử thách với Rider thời Showa (Ichigo → Black RX). Mỗi màn có luật riêng, ví dụ "chỉ được dùng Rider Kick".

---

## 3. Logic game

### 3.1 Vòng lặp tiến trình

```
            ┌──────────────────────────────────────────────────────────┐
            ▼                                                          │
   [Bắt đầu màn]  banner: tên thế giới, tên màn, mục tiêu              │
            │                                                          │
   [Chiến đấu]    quái rơi Driver / form / nạp nộ ngẫu nhiên (3.8)     │
            │ tới vạch đích                                            │
            ├── Thức tỉnh → canh giữ → (chưa có) Driver → nhặt ─┐      │
            ├── Luyện tập → (chưa có) form của màn → nhặt ──────┤      │
            └── Trùm → Driver thế giới kế rơi ra ──┤                   │
                                                   ▼                   │
                                    [Qua màn]                          │
                                    · khóa điều khiển, quái / đạn tan  │
                                    · GIẢI TRỪ BIẾN THÂN → dạng người  │
                                    · thoại "clear" (trùm: bản đồ)     │
                                    GameState.complete_stage()         │
                                    · kích hoạt / lên cấp / nhận Driver│
                                    · lưu game                         │
                                    · bảng kết quả 3,5 giây            │
                                    · màn hình tối dần                 │
                                    · dựng màn kế + ĐỔI NỀN ───────────┘
   Vào màn: dạng người, máu người đầy, nộ đầy → thoại đầu màn → chọn Rider chính → chạy.
   Chết giữa màn → chơi lại từ checkpoint (cũng vào ở dạng người, nộ đầy). Tiến trình và cấp đã đạt được giữ nguyên.
```

**Chi tiết luồng qua màn** (`stage_run.gd` `_finish_stage`, `_go_next_stage`, `_start_stage`):

| Bước | Việc xảy ra |
|---|---|
| 1. Tới vạch đích / nhặt món chính | Nếu vừa nhặt món chính thì hiện thoại "key" trước |
| 2. Dọn màn | Khóa điều khiển, ẩn nút cảm ứng. Quái còn lại mờ dần rồi biến mất, đạn và vật phẩm thừa biến mất |
| 3. Giải trừ biến thân | Đợi đòn đang ra / cảnh biến thân xong (tối đa 3 giây), rồi chạy ngược cảnh biến thân của Rider đang mang trong 0,8 giây, chớp sáng, về dạng người. Không mất nộ, không choáng (khác Henshin Break) |
| 4. Thoại và kết quả | Thoại "clear"; màn trùm thêm bản đồ Chuỗi Trái Đất; bảng kết quả 3,5 giây |
| 5. Chuyển màn | Màn hình tối dần 0,45 giây; trong lúc tối: dựng bố cục màn kế, **đổi nền xa và màu trời** theo `"bg"` của màn, đặt nhân vật ở điểm xuất phát |
| 6. Vào màn | Sáng dần; nhân vật ở **dạng người, máu người đầy, nộ đầy**; thoại đầu màn; chọn Rider chính (nếu có từ 2 Rider); banner tên màn + "bấm BIẾN THÂN". Đã có Driver thì biến thân lúc nào cũng được (biến thân không mất nộ nên vào Rider vẫn còn đầy nộ) |

**Nền từng màn** (`tools/gen_backgrounds.py`, ảnh 800×224 nối liền hai mép, `art/backgrounds/`; màu trời lấy từ điểm trên cùng của ảnh):

| Thế giới 1 | Nền | Thế giới 2 | Nền | Thế giới 3 | Nền |
|---|---|---|---|---|---|
| 1-1 | Shibuya đêm (ảnh có sẵn) | 4-1 | Phố nhỏ chiều tà, cột điện | 11-1 | Fuuto chiều, tháp gió |
| 1-2 | Di tích đá, núi Nagano hoàng hôn | 4-2 | Cầu cạn cao tốc, vệt đèn xe | 11-2 | Fuuto ban ngày, turbine trên mái |
| 1-3 | Tokyo đêm, trăng tròn, tháp Tokyo | 4-3 | Cao ốc kính, tháp tập đoàn | 11-3 | Cận cảnh tháp gió, mây |
| 1-4 | Bến cảng đêm, cần cẩu, container | 4-4 | Phòng thí nghiệm: bể kính, màn hình | 11-4 | Khu công nghiệp, ống khói |
| 1-B | Trời đỏ máu, thành phố cháy | 4-B | Trời tro xám, tàn tro rơi | 11-B | Đêm bão, sét, mưa |

Các thế giới khác: mỗi màn một ảnh `<id>_1` … `<id>_b`, kiểu nền chọn trong 50 kiểu của `tools/gen_backgrounds.py` (danh mục ở `docs/WORLD_FILES.md`); mỗi ảnh một hạt giống theo tên nên hai màn cùng kiểu vẫn khác nhau.

Bản mẫu (`scripts/levels/stage_run.gd`) chạy đúng vòng lặp này, mỗi màn là một đường cuộn ngang kiểu Contra (mục 3.14), qua đủ 15 màn của 3 thế giới đầu.

### 3.2 Driver, cấp Rider, đội hình

**Trạng thái một Driver:**

| Trạng thái | Khi nào | Biến thân được? |
|---|---|---|
| Chưa có | — | Không |
| **Phong ấn** | Nhặt từ trùm thế giới trước (`obtain_driver`) | Không. Hub hiện cửa thế giới tương ứng |
| **Hoạt động Lv1–5** | Nhặt ở màn Thức tỉnh: quái rơi ra ngẫu nhiên, hoặc nhóm canh giữ ở vạch đích (`activate_driver`) | Có, vào form gốc |

**Luật trong `GameState.complete_stage()`:**
```
màn Thức tỉnh : activate_driver(rider)           → Lv1, vào đội hình (Rider của thế giới)
mọi màn       : nếu reward_level > cấp hiện tại  → set_level(rider, reward_level)
                (reward_level = bậc màn + 1, bậc 0..4 theo WorldData.tier_of; thế giới 5 màn: bậc = vị trí màn)
màn có "form" : unlock_form(rider, form)          → đã nhặt giữa màn; gọi lại để không bao giờ kẹt tiến trình
màn Trùm      : obtain_driver(next_driver)        → Driver kế tiếp ở trạng thái phong ấn
                worlds_cleared += 1
sau đó        : stage_index += 1 (hết màn thì sang thế giới kế), lưu game
```
Nhờ luật "chỉ lên, không xuống", chơi lại màn cũ không bao giờ làm tụt cấp.

**Chọn Rider chính và đội hình:**
- **Trước mỗi màn**, nếu đã có từ 2 Rider trở lên, hiện **màn chọn Rider chính** (`scripts/ui/rider_select.gd`): mỗi thẻ có tên, cấp, mô tả lối chơi, 5 thanh chỉ số của form gốc (Máu · Giáp · Tốc độ · Sức đánh · Nhảy), số form đã có, và dấu **★ Rider thế giới** (form của màn chỉ rơi cho Rider này). Chỉ có 1 Rider thì tự chọn. Hồi sinh ở checkpoint thì không hỏi lại.
- **Đội hình trong màn** = Rider chính + Rider của thế giới đang chơi (nếu đã kích hoạt và khác Rider chính) — `GameState.rebuild_team()`. **Đổi Rider** chỉ đổi qua lại giữa hai Rider này. Biến thân (I) luôn vào Rider chính.
- Vào màn mà đang biến thân thì chuyển ngay sang Rider chính (giữ tỉ lệ máu Rider).
- Nhặt Driver của thế giới ở màn X-1: Rider mới vào đội hình (không thay Rider chính) và biến thân ngay vào nó như luật nhặt Driver.
- Player lắng nghe tín hiệu `equipped_changed` và `rider_leveled`, nên Driver mới và form mới dùng được **ngay giữa màn**, không cần tải lại.

**Chỉ số form gốc từng Rider** (Lv1; mỗi cấp +8% máu, +10% sát thương):

| Rider | Lối chơi | Máu | Giáp | Tốc độ | Sức đánh | Nhảy |
|---|---|---|---|---|---|---|
| Kuuga (Mighty) | Bền bỉ, 4 form | **170** | **30** | 125 | ×1.0 | ×1.0 |
| Faiz | Nhanh, đánh mạnh, có súng; máu mỏng | 125 | 15 | **155** | **×1.2** | ×1.05 |
| W (CycloneJoker) | Nhảy cao, ghép 2 nửa linh hoạt | 150 | 20 | 145 | ×1.0 | **×1.2** |

**Cấp Rider:**
- Mỗi cấp tăng **+10% sát thương** (`level_mult`) và **+8% máu Rider**.
- Vài thưởng riêng theo cấp: Kuuga Lv5 Rising (Final ×1.5), W Lv4 Best Match (+15%).
- **Form không mở theo cấp** mà nhặt từ quái (`GameState.unlock_form`, lưu trong `drivers[rider]["forms"]`), xem mục 3.8 và 3.11.

### 3.3 Dữ liệu thế giới (`scripts/data/world_data.gd`)

Mỗi thế giới là một file `scripts/data/worlds/wNN_<id>.gd` với các hằng `WORLD`, `RIDER`, `SPEAKERS`, `STORY`, `WORLD_CLEAR`. **Đặc tả đầy đủ: `docs/WORLD_FILES.md`**, file mẫu `w02_agito.gd`. `WorldData.FILES` liệt kê các file theo năm phát sóng; bộ nạp (`WorldData._build`) tự:
- đánh mã màn theo vị trí (`"4-1"` … `"4-B"`), gán loại màn và cấp thưởng;
- nối Driver: trùm thế giới N rơi Driver của thế giới N+1, thế giới cuối rơi Chrono Driver;
- điền lộ trình và đợt quái mặc định nếu file không ghi (`DEFAULT_ROUTES`, `DEFAULT_WAVES`);
- nhân máu / sát thương trùm theo thế hệ (+12% / +10% mỗi thế giới);
- gộp thoại (`WorldData.stories`), người nói (`StoryData.SPEAKERS`), dữ liệu Rider (`WorldData.riders`).

**Thêm thế giới mới:** tạo file theo mẫu, thêm một dòng vào `WorldData.FILES` đúng vị trí năm phát sóng, chạy `godot --headless --path . -s tools/validate_worlds.gd`, `python3 tools/gen_backgrounds.py`, `python3 tools/gen_story_art.py`.

### 3.4 Các kiểu thử thách Thức tỉnh

Màn X-1 dùng lại một trong các kiểu sau. Mỗi kiểu là một script mục tiêu gắn vào màn, báo "hoàn thành" thì Driver rơi ra.

| Kiểu | Luật hoàn thành | Thế giới dùng |
|---|---|---|
| HẠ KẺ GIỮ | Hạ quái mang Driver hoặc vật phẩm (quái có đánh dấu) | Kuuga, Blade |
| THU THẬP | Nhặt đủ N vật phẩm, thường rơi ra từ quái | W, OOO, Gaim, Build, Gavv |
| HỘ TỐNG | Giữ NPC còn máu tới cuối màn | Faiz, Agito, Fourze, Zi-O |
| ĐUỔI BẮT | Chạm được mục tiêu đang chạy hoặc bay trốn (thường cần Rider nhanh đã có) | Ryuki, Kabuto, Drive, Gotchard |
| SỐNG SÓT | Trụ được X giây trước quái vô tận | Wizard, Geats |
| ĐẤU TAY ĐÔI | Hạ một đối thủ đặc biệt (Echo Rider hoặc bóng tối của Sora) | Den-O, Revice |
| THỬ THÁCH / GIẢI ĐỐ | Màn platform, câu đố hoặc mini-game | Hibiki, Kiva, Ex-Aid, Zero-One, Saber |
| ĐẶC BIỆT | Luật riêng, ví dụ bị tịch thu Driver (Decade), chơi dạng hồn ma (Ghost) | Decade, Ghost |

Bản mẫu mới làm kiểu đơn giản nhất: hạ hết các đợt quái thì Driver rơi ra.

### 3.4.1 Màn EX — quái đặc biệt

- Mỗi thế giới có thêm **màn EX** (`<số>-EX`, ô cuối ở màn chọn màn) sau màn Trùm. Mở khi đã giải cứu thế giới đó, **không nằm trong chuỗi tiến trình**: không mở màn kế, không lên cấp, không rơi form. Qua lần đầu thưởng **150 Mảnh Ký Ức**.
- Mỗi màn EX có **một loại quái đặc biệt** (3.13) lẫn với quái thường; quái thường cho nộ ở form gốc để vào form khắc chế. Một loại mỗi màn vì mỗi màn chỉ mang được **một form biến đổi** (cộng item).
- Loại quái chọn theo form của **chính Rider thế giới đó** (`WorldData.CHALLENGE_THEMES`, file thế giới ghi đè bằng `"challenge"`), `tools/special_caps.tscn` kiểm mọi thế giới đều có form / item khắc chế và form gốc không tự khắc chế được (phải đổi form):

  | Loại | Thế giới |
  |---|---|
  | Khổng lồ | Kuuga (Titan), Hibiki (Kaentsuzumi), Wizard (Land), Gaim (Pine), Zi-O, Zero-One, Saber, Revice, Zeztz |
  | Bóng ma | Agito (Flame), Blade (Thunder), W (Heat), Fourze (Elek), Ghost (Edison) |
  | Quái bay | Ryuki (Strike Vent / Survive), Den-O (Gun), Kiva (Basshaa), OOO (Tajador), Ex-Aid, Build, Gotchard, Gavv |
  | Siêu tốc | Faiz (Axel), Kabuto (Hyper), Decade (Kamen Ride Kabuto), Drive (Formula), Geats (Boost) |

- **Báo trước:** màn chọn màn ghi "Cần: …" và các form người chơi đang có khắc chế được (mọi Rider); màn chọn form / item có dòng "Khắc chế: …"; đầu màn banner nói cách hạ và form khắc chế đang mang, hoặc cảnh báo chưa mang (vào Menu chọn lại).
- Nạp nộ rơi nhiều hơn (30% mỗi quái) vì form khắc chế tốn nộ.

### 3.5 Kiến trúc

```
Autoload
├── GameState        scripts/autoload/game_state.gd      tiến trình, Driver, cấp, đội hình, save, phím
└── CombatDirector   scripts/autoload/combat_director.gd hit-stop, làm chậm quái, lượt tấn công

Dữ liệu
├── WorldData        scripts/data/world_data.gd          các thế giới, màn, đợt quái, trùm, chuỗi Driver

Player (CharacterBody2D)            scripts/player/player.gd
├── Placeholder / Sprite / CollisionShape2D
├── Hurtbox, Hitbox                 scripts/combat/
└── Forms (Node)                    ← RiderForm được tạo và đồng bộ theo GameState.equipped
    └── kuuga.gd / faiz.gd / double.gd  (extends RiderForm)

Enemy (CharacterBody2D)             scripts/enemies/enemy.gd
DriverPickup (Area2D)               scripts/items/driver_pickup.gd
Màn chơi cuộn ngang                 scripts/levels/stage_run.gd + stage_builder.gd
Đạn                                 scripts/combat/projectile.gd
```

**Lớp va chạm:** 1 = world, 2 = player, 3 = enemy, 4 = hurtbox. Player và quái đi xuyên qua nhau. `DriverPickup` quét lớp 2.

### 3.6 Điều khiển

| Phím | Hành động |
|---|---|
| A / D | Di chuyển (camera theo cả hai chiều) |
| W (giữ) | Ngắm (form có súng): W bắn thẳng lên, W + A/D bắn chéo; trên không giữ S bắn xuống |
| H (giữ) | **Bắn** liên tục, **chỉ khi form có súng** (mục 3.14). Súng chỉ hiện ở tay lúc bắn |
| K | **Chém**, **chỉ khi form có kiếm / vũ khí cận chiến**: chuỗi chém rồi nhát kết. Vũ khí chỉ hiện khi chém |
| S (giữ) | **Cúi / thủ thế**: đứng yên, thân thấp lại (hurtbox cao 50 → 30, đạn cao bay qua), đòn cận chiến chỉ còn 40%, không bị đẩy lùi. Đánh nhẹ hoặc né để thoát |
| W | W Rider: giữ W khi bấm Special để đổi nửa Body |
| Space | Nhảy (cao ~110 px, xa ~170 px). Đứng trên bệ: S + Space, hoặc bấm đúp S (trong 0.3 giây) để xuống |
| J | **Đánh** (luôn tay không): chuỗi đấm (có bộ đệm bấm trước), đủ `punch_count()` đòn thì tự ra **cú đá** kết thúc, rồi chuỗi về đầu. Ngừng bấm giữa chừng thì chuỗi về đầu |
| L | **Đổi form** theo vòng các form đã nhặt (W: nửa Soul; giữ W + L: nửa Body). Vào form đặc biệt cần ≥ 20 nộ, tốn 10; về form gốc miễn phí. Hồi chiêu 1 giây (W 0.6). Dạng người không có |
| Shift | Né (bất tử với đòn cận chiến, hủy được pha hồi chiêu của đòn), hồi chiêu 0.6 giây. **Không tránh được đạn** |
| I | Biến thân vào form gốc (cần nộ đầy và ít nhất 1 Driver hoạt động; không mất nộ) |
| O | Đổi Rider: đổi qua lại giữa Rider chính và Rider của thế giới (khi đã nhặt Driver của thế giới), hồi chiêu 8 giây. Rider vừa rời đi và Rider mới đều ở form gốc |
| U | Final Attack (cần ≥ 50 nộ, đốt hết nộ) |

**Nút trên màn hình** (chạm trên điện thoại, bấm chuột trên máy tính; `scripts/ui/touch_controls.gd`):
- Góc trái: D-pad ◀ ▶ di chuyển, **▲ nhảy** (nút này nhấn cùng lúc `jump` và `move_up`, nên giữ ▲ còn để ngắm lên khi có súng và để W đổi nửa Body), ▼ cúi (bấm đúp ▼ trên bệ = xuống khỏi bệ).
- Góc phải: **Đánh** (nút to nhất), Né, **tuyệt chiêu** (một nút duy nhất: dạng người thì biến thân, dạng Rider thì Final Attack), kỹ năng, đổi Rider, bắn.
- Mỗi nút có **chữ ngắn bên dưới** (Đánh, Nhảy, Né, Cúi…). Chữ của nút kỹ năng đổi theo Rider (Kuuga/Faiz "Đổi form", W "Đổi Memory"); nút tuyệt chiêu ghi "Biến thân" ở dạng người, "Tuyệt chiêu" ở dạng Rider.
- **Chỉ hiện nút đã dùng được:** dạng người chỉ có D-pad, Đánh, Né. Nút **bắn** chỉ hiện khi form hiện tại có súng. Nút biến thân hiện khi đã có Driver; nút kỹ năng hiện khi Rider đã nhặt ít nhất một form đặc biệt; nút đổi Rider hiện khi đang biến thân và có từ 2 Driver.
- Vòng tối quét theo thời gian hồi chiêu kèm số giây; nút mờ đi khi thiếu nộ; nút tuyệt chiêu phát sáng nhấp nháy khi dùng được.

### 3.7 Máy trạng thái người chơi

```
 NORMAL ───J/U───► ATTACK ──hết recovery──► NORMAL
   │  ▲               └─Shift (lúc recovery)─► DODGE ──hết giờ──► NORMAL
   │  └──────────── HURT ◄── bị đánh (sát thương ≥ poise) ──────┘
   ├─ I  (dạng người, nộ đầy)    ─► HENSHIN 1.2s ─► vào form gốc + sóng xung kích ─► NORMAL
   ├─ nhặt Driver/form lần đầu   ─► HENSHIN 1.2s (dạng người) / SWAP 0.3s (dạng Rider) ─► vào đúng form đó, nộ đầy
   ├─ O  (dạng Rider)            ─► SWAP 0.3s    ─► Rider mới + đòn swap_in  ─► NORMAL
   ├─ nộ về 0 ở form đặc biệt    ─► về form gốc, bất tử 0.6s (chờ Final đánh xong; đòn thường thì bị ngắt)
   ├─ máu Rider về 0             ─► BREAK 1s     ─► NORMAL ở dạng người
   └─ máu người về 0             ─► KO           ─► chơi lại màn
```
Trạng thái bất tử: DODGE (trừ đạn), HENSHIN, SWAP, BREAK, và các đòn `final`, `swap_in`, `henshin`.

### 3.8 Thanh tài nguyên, form đặc biệt và vật phẩm rơi

**Hai thanh:** MÁU · NỘ (thanh Năng lượng đã bỏ ở bản 0.7: đòn đá giờ là đòn kết thúc chuỗi, miễn phí).

| Thanh | Dùng để | Tăng | Giảm |
|---|---|---|---|
| **Nộ** | Biến thân · đổi sang form đặc biệt · Final Attack · **nhiên liệu của form đặc biệt** | Dạng người: +8 mỗi đòn trúng. Form gốc: +0.7 × sát thương gây ra (đạn tính một nửa). Cả hai: +0.8 × máu mất | Xem bên dưới |

**Nộ theo từng dạng:**

| Dạng | Luật |
|---|---|
| Dạng người | Nộ đầy → **I** biến thân vào **form gốc** của Rider chính. Biến thân **không** mất nộ. Mỗi màn bắt đầu ở dạng người với nộ đầy |
| Form gốc (Kuuga Mighty, Faiz, W CycloneJoker) | Nộ không tụt. **L** vào form đặc biệt: cần ≥ 20, tốn 10. **U** Final Attack: cần ≥ 50, đốt hết nộ |
| **Form đặc biệt** | Nộ **tụt 4/giây** (đầy thanh ≈ 25 giây; Faiz Axel tụt 10/giây ≈ 10 giây). Đánh trúng hay bị đánh đều **không** được cộng: thanh nộ là đồng hồ đếm ngược. **Nộ về 0 → tự về form gốc**, bất tử 0.6 giây. Final Attack ở đây cũng đốt hết nộ, đánh xong thì về form gốc |
| Henshin Break | Mất hết nộ, về dạng người (máu Rider về 0 như cũ) |

**Vật phẩm rơi từ quái** (`stage_run.gd`, `DriverPickup`):
- Mỗi lúc chỉ có **một** vật phẩm trên màn. Vật phẩm rơi tồn tại **10 giây**, nhấp nháy 3 giây cuối, bị bỏ lại sau camera thì mất.
- **Món chính của màn:** màn Thức tỉnh là Driver của thế giới (khi chưa kích hoạt); màn có khóa `form` trong `WorldData` là form đó (khi Rider của thế giới đã hoạt động và chưa có form này).
  - Tỉ lệ rơi **5% + 5% cho mỗi con đã hạ mà chưa rơi** (bảo hiểm xui: trung bình khoảng 5 con, gần như chắc chắn trước con thứ 10). Rơi ra mà để mất thì con tiếp theo rơi lại gần như ngay.
  - Tới vạch đích mà vẫn chưa nhặt: món chính rơi ngay trước mặt, không biến mất, nhặt mới qua màn.
  - **Nhặt lần đầu:** mở khóa, **nộ = 100**, **biến thân ngay** vào form đó (dạng người thì chạy cảnh biến thân, dạng Rider thì đổi nhanh như đổi Rider). Driver mới vào đội hình (Rider của thế giới).
- **Nạp nộ:** khi màn không còn món chính, mỗi quái có **8%** (quái giáp 16%) rơi một form đặc biệt đã có của Rider trong đội hình; nhặt được **+40 nộ**, không đổi form.
- Màu: vàng = Driver · màu của Rider = form mới · cam nhỏ = nạp nộ · xanh = Driver thế giới kế (phong ấn, rơi từ trùm).

**Súng:** chỉ form cầm súng trong nguyên tác mới bắn được (`RiderForm.get_shot()` khác `{}`), xem bảng ở mục 3.14.

### 3.9 Chỉ số theo dạng, biến thân, vỡ giáp

**Máu người và máu Rider tách riêng.** Ở dạng Rider, đòn đánh chỉ trừ máu Rider. Máu Rider về 0 thì bị **Henshin Break**: về dạng người, choáng 1 giây (bất tử), máu người vẫn giữ nguyên. Máu người về 0 thì thua và chơi lại màn.

| Dạng | Máu | Giáp | Tốc độ | ATK |
|---|---|---|---|---|
| **Dạng người** | 100 | 0 | 110 | ×1.0 (3 đấm × 3, đá 8) |
| Kuuga Mighty / Dragon / Pegasus / Titan | 170 / 130 / 140 / 200 | 30 / 5 / 15 / 60 | 125 / 175 / 110 / 80 | ×1.0 / 0.8 / 0.9 / 1.4 |
| Faiz (và Axel) / Blaster | 125 / 200 | 15 / 40 | 155 (Axel ×1.6) / 135 | ×1.2 / 1.35 |
| W (Metal) / Xtreme | 150 / 190 | 20 (45) | 145 Cyclone, 125 còn lại; nhảy ×1.2 | ×1.0 (Heat ×1.2; Xtreme ×1.2) |

- **Máu Rider** tăng **+8% mỗi cấp**, **sát thương** tăng **+10% mỗi cấp**.
- Biến thân thì máu Rider hồi đầy. Đổi Rider hoặc đổi form (Kuuga) thì **giữ nguyên tỉ lệ máu**, ví dụ còn 50% máu thì form mới cũng vào với 50%.

**Công thức:**
```
sát thương gây ra = gốc × (1 + min(combo × 0.02, 0.5)) × ATK của dạng × (1 + 0.1 × (cấp − 1))
máu mất           = sát thương của quái × 100 / (100 + giáp)
                    (giáp 25 → giảm 20%; giáp 60 → giảm 37.5%; giáp 100 → giảm 50%)
sát thương gốc < poise của Rider → Rider không bị khựng (siêu giáp)
quái fast         : né 75% trừ khi đòn có tag "time" hoặc quái đang bị làm chậm
quái armored      : ×0.4 trừ đòn "heavy" hoặc Final Attack
```

**Các bước:**
1. **Biến thân (I):** dùng Rider chính, vào form gốc. Bất tử 1.2 giây, kết thúc bằng sóng xung kích đẩy lùi quái.
2. **Đổi Rider (O):** giữa Rider chính và Rider của thế giới. 0.3 giây bất tử, hồi chiêu 8 giây, Rider mới vào ở form gốc và tự tung đòn `swap_in`.
3. **Final Attack (U):** cần ≥ 50 nộ, đốt hết nộ. Cả đòn đều bất tử, không hủy được, phát tín hiệu để chạy cảnh cắt cinematic.
4. **Combo và hit-stop:** combo reset nếu 1.5 giây không trúng. Khựng hình 0.035 giây (đòn thường) / 0.08 giây (heavy, final).

### 3.10 Dữ liệu đòn đánh

Tạo bằng `RiderForm.make_attack(damage, startup, active, recovery, size, offset, knockback, tags, extra)`.

| Khóa | Ý nghĩa |
|---|---|
| `startup` / `active` / `recovery` | thời gian 3 pha; hitbox chỉ bật ở pha active |
| `size`, `offset` | hitbox khi quay phải (tự lật khi quay trái) |
| `tags` | `heavy`, `ranged`, `time`, `wind` / `fire` / `luna`... (`final` được tự thêm vào) |
| `hits`, `lunge`, `no_cancel`, `anim` | số lần hitbox bật lại / lao tới / không hủy được / tên animation (cú đá dùng `heavy`) |

**Chuỗi đánh:** `kind` là `&"light"` (đòn đấm thứ `chain`) hoặc `&"kick"` (cú đá kết thúc). Số đòn đấm trước cú đá do `RiderForm.punch_count()` quyết định. Các cú đấm đẩy lùi nhẹ để quái không văng ra trước khi cú đá tới; cú đá sát thương cao, đẩy xa, thường mang tag `heavy` (phá giáp).

### 3.11 Ba Rider trong bản mẫu — form nhặt từ quái

Sát thương trong bảng là **sát thương gốc** (chưa nhân ATK, combo và cấp). Special (L) đổi form theo vòng các form đã có, hồi chiêu 1 giây (W 0.6 giây). Form đặc biệt tốn nộ theo mục 3.8.

#### Kuuga · form gốc Mighty

| Form | Có ở | Máu | Giáp | Tốc độ | ATK | Poise | Chuỗi đánh | Đòn kết thúc | Súng | Final |
|---|---|---|---|---|---|---|---|---|---|---|
| **Mighty** (gốc) | 1-1 (Arcle) | 170 | 30 | 125 | ×1.0 | 8 | 3 đấm × 5 | đá 12 (heavy) | — | Mighty Kick 60 |
| **Dragon** | rơi ở 1-2 | 130 | 5 | 175, nhảy ×1.35 | ×0.8 | 3 | 3 đòn gậy × 4, tầm 30 | đá 10 | — | Splash Dragon 45 |
| **Pegasus** | rơi ở 1-3 | 140 | 15 | 110 | ×0.9 | 4 | 2 phát × 7, tầm 140 | phát nạp 18 | Pegasus Bowgun | Blast Pegasus 50 |
| **Titan** | rơi ở 1-4 | 200 | 60 | 80 | ×1.4 | 20 | 2 đòn kiếm × 9 (heavy) | đá 25 (heavy) | — | Calamity Titan 70 |

Lv5 **Rising**: mọi Final ×1.5, tên thành "Rising Mighty Kick"...

#### Faiz · form gốc Faiz · máu 125 · giáp 15 · tốc độ 155 · sức đánh ×1.2

| Form | Có ở | Khác biệt | Súng | Final |
|---|---|---|---|---|
| **Faiz** (gốc) | 4-1 (Faiz Driver) | 3 đấm × 5 + đá 13 (heavy); các form Faiz đánh giống nhau | Faiz Phone: 3 viên xòe × 3 | Crimson Smash 60 |
| **Axel** | rơi ở 4-2 | Quái chậm còn 15%, Faiz ×1.6 tốc độ, mọi đòn có tag `time`. **Nộ tụt 10/giây** (≈ 10 giây) | — | Accel Crimson Smash (5 hit × 16) |
| **Blaster** | rơi ở 4-4 | Máu 200, giáp 40, tốc độ 135, ATK ×1.35, poise 12 | Faiz Blaster: đạn to 10, xuyên | Crimson Smash 60 |

Màn 4-3 không có form mới.

#### W · form gốc CycloneJoker · máu 150 · giáp 20 · nhảy ×1.2

| Memory | Có ở | Mở |
|---|---|---|
| Cyclone + Joker (gốc) | 11-1 (Double Driver) | CycloneJoker |
| **Heat & Metal** | rơi ở 11-2 | Heat (ATK ×1.2) cho nửa Soul, Metal (gậy heavy, giáp 45, poise 12) cho nửa Body; nhặt thì vào HeatMetal |
| **Luna & Trigger** | rơi ở 11-3 | Luna (tầm ×1.5) cho Soul, Trigger (súng, tầm 150) cho Body, đủ 9 tổ hợp; nhặt thì vào LunaTrigger |
| **Xtreme** | rơi ở 11-4 | CycloneJokerXtreme: máu 190, ATK ×1.2. Nằm cuối vòng đổi nửa Soul (Cyclone → Heat → Luna → Xtreme) |

- Mọi tổ hợp khác CycloneJoker đều là form đặc biệt (tốn nộ).
- Chỉ nửa **Trigger** có súng: liên thanh 4 (Heat 5), ghép Luna thì xòe 3 viên.
- Lv4 **Best Match** (CycloneJoker / HeatMetal / LunaTrigger): sát thương +15%.

Chiêu theo nửa Body: Joker 3 đấm × 5 + đá 12, Final *Joker Extreme* 65 · Metal 2 đòn gậy × 7 + đá 16, Final *Metal Branding* 70 · Trigger 2 phát × 5 + loạt 3 × 5, Final *Trigger Full Burst* 6×12. Cyclone tăng tốc độ lên 150 và knockback ×1.5.

### 3.12 Khung cho các Rider sau

| Hook | Dùng để |
|---|---|
| `_init()` | đặt `rider_id`, chỉ số gốc (`max_hp`, `armor`, `move_speed`, `attack_mult`), hồi chiêu Special |
| `punch_count()` | số đòn `&"light"` trước cú đá `&"kick"` (mặc định 3) |
| `base_form()` / `current_form_id()` | id form gốc và form đang dùng. Khác nhau = đang ở form đặc biệt (tốn nộ) |
| `_set_form(id)` | áp chỉ số / hiệu ứng của form. Gọi qua `set_form()` để giữ tỉ lệ máu Rider |
| `_next_form()` | form kế tiếp khi bấm Special; `&""` = không đổi được. Thường chỉ cần `_cycle(ORDER)` |
| `special_available()` | đã nhặt ít nhất một form đặc biệt chưa (để hiện nút) |
| `rage_drain()` | tốc độ tụt nộ ở form đặc biệt (mặc định 4/giây; Axel 10/giây) |
| `get_shot()` | kiểu đạn của form; `{}` = form không có súng |
| `_on_level_changed()` | thưởng theo cấp (Rising, Best Match...) |
| `get_attack(kind, chain)` | trả về dữ liệu đòn (`light`, `kick`, `swap_in`, `final`); trả `{}` nếu form đó không có đòn này |
| `update(delta)` | đồng hồ / hiển thị riêng (đếm giây Axel...) |
| `modify_incoming_damage(info)` | phản đòn, hút máu, Cast Off... |
| `on_enter` / `on_exit` | bật/tắt hiệu ứng; **phải dọn dẹp** khi rời form (như Faiz tắt Axel) |
| `animation_prefix()` / `final_attack_name()` | bộ animation và tên tuyệt chiêu theo form |

Form nào rơi ở màn nào thì khai báo bằng `"form"` / `"form_name"` trong `WorldData`. Ví dụ Kabuto: form gốc Masked Form; X-2 rơi Rider Form (Cast Off), X-3 rơi Clock Up (giống Axel, `rage_drain` cao, quái chậm còn 5%), X-4 rơi Hyper Form.

### 3.13 Quái, trùm và AI

```
IDLE ─thấy người chơi 180px─► CHASE ─trong tầm + có lượt─► WINDUP (nháy sáng) ─► ATTACK ─► RECOVER ─► CHASE
Bị đánh (sát thương ≥ poise) → HURT 0.35 giây · HP về 0 → DEAD (+ Mảnh Ký Ức)
```
- **Kiểu quái (behavior):**
  - **Cận chiến** (melee): đuổi theo, xin lượt rồi đánh; người chơi ở trên bệ thì nhảy lên, ở dưới thì nhảy xuống.
  - **Chạy ào** (runner): lao nhanh (×1.6 tốc độ) từ mép màn hình như lính Contra. Tới cách người chơi **70** (cùng độ cao) thì thôi chạy thẳng, **chuyển sang đuổi đánh như quái cận chiến**: không con nào lướt qua bỏ mặc người chơi. Vướng thùng / bậc khối thì nhảy qua; nhảy rồi mà vẫn vướng ở cùng độ cao (tường cao hơn sức nhảy) mới quay đầu.
  - **Bắn** (shooter): đứng gác trên mặt đất. Cứ 2.2 giây, khi người chơi ở gần cùng độ cao và trong tầm 300, nó tụ đòn 0.6 giây rồi bắn một viên **bay ngang** (sát thương 80% đòn đánh), chọn ngẫu nhiên một trong hai độ cao:
    - **Đạn cao** (cách chân 40): quái ửng **đỏ**, đạn đỏ. Trúng người đứng (hurtbox cao 50), bay qua người **cúi** (hurtbox cao 30).
    - **Đạn thấp** (cách chân 8): quái ửng **xanh**, đạn xanh. Cúi vẫn trúng, phải **nhảy**.
    - Lúc tụ đòn có chấm sáng nhấp nháy đúng độ cao viên đạn sắp bay ra. Né (Shift) không tránh được đạn.
- **Lượt tấn công:** tối đa 2 quái cận chiến ra đòn cùng lúc; quái khác đứng vòng ngoài (3 lần tầm đánh) chờ. Đánh xong quái **nghỉ 1 giây** mới xin lượt mới và lùi ra vòng ngoài, nhường lượt cho quái đang chờ (trước đây 2 con đứng sát cứ giành lại lượt, các con vòng ngoài hầu như không bao giờ được đánh). Quái chỉ vung đòn khi cùng độ cao với người chơi.
- **Chỗ thả quái:** thả ở mép màn hình cao hơn sàn 40; nếu chỗ đó có chồng thùng 2–3 tầng thì đặt lên nóc chồng thùng (trước đây quái bị thả lọt vào trong rồi xuyên qua chồng thùng).
- **Làm chậm:** mọi chuyển động và bộ đếm giờ của quái nhân với `enemy_time_scale`.
- **Trait:** `fast` (khắc chế bằng Faiz Axel hoặc Kabuto Clock Up), `armored` (khắc chế bằng Titan, Metal hoặc Final).
- **Quái đặc biệt (màn EX, `Enemy.SPECIALS`):** **miễn nhiễm** mọi đòn không mang tag khắc chế, nên phải mang đúng form vào màn:

  | Loại (`waves`) | Đặc điểm | Chỉ nhận đòn | Ví dụ form khắc chế |
  |---|---|---|---|
  | `flying` (Quái bay) | lượn cao hơn chân người chơi 78 px, chếch một bên; tới lượt thì tụ đòn rồi bổ nhào, xong bay vọt lên. Bay xuyên địa hình | `ranged` (đạn, đòn bắn xa) | Kuuga Pegasus, Faiz, Den-O Gun, Kiva Basshaa |
  | `giant` (Khổng lồ) | to ×1.6, máu 150, không bị đẩy lùi / không bị `force`, hiệu ứng choáng ngắn như trùm | `crush` (form nặng) | Kuuga Titan, W Metal, Den-O Ax, Kiva Dogga |
  | `phantom` (Siêu tốc) | tốc độ 120, để bóng mờ | `time` (hoặc quái đang bị làm chậm) | Faiz Axel, Kabuto Hyper, Drive Formula, Geats Boost |
  | `spectral` (Bóng ma) | trong suốt, chập chờn | `burn` / `freeze` / `shock` | Agito Flame, W Heat, Fourze Elek, Ghost Edison |

  `crush` và `time` là tag theo form (`RiderForm.special_tags()`, Player cộng vào mọi đòn và đạn): form kiểu `heavy` (hoặc vũ khí nặng ở nút Chém) có `crush`, form tăng tốc thời gian có `time`. Đòn bị chặn: tiếng giáp, quái chớp xám, chữ gợi ý trên đầu ("CẦN SÚNG!"...), đạn bật ra, banner giải thích (cách nhau 4 giây). Đòn bị chặn ở form gốc vẫn tích **một nửa** nộ, để khi chỉ còn quái đặc biệt người chơi vẫn nạp được nộ vào form khắc chế. Quái khổng lồ / siêu tốc không làm lính bắn đứng gác (chuyển sang đuổi đánh), quái bay luôn là quái bay.
- **Trùm trong bản mẫu:** dùng chung AI quái nhưng to gấp 1.8 lần, chỉ số lấy từ `WorldData`. Daguba (HP 260, poise 30), Dragon Orphnoch (HP 220, `fast`), Eternal (HP 300, `armored`).
- **Trùm bản đầy đủ:** lớp `Boss` kế thừa `Enemy`. Chuyển pha ở 66% và 33% HP; mỗi pha có danh sách chiêu riêng. Khi chuyển pha: bất tử 1.5 giây và phát cutscene ngắn.
- **Cấp độ quái:** `cấp = 1 + ⌊(số thế giới đã qua) × 2/3⌋ + (thứ tự màn)`, trùm thêm 2 cấp. Thế giới 1 có quái Lv1–5, thế giới 4 Lv3–7, thế giới 11 Lv7–11, thế giới 27 Lv18–22.
- **Sức mạnh theo thế hệ:** Rider của thế giới thứ i (đếm từ 0) có máu và sát thương × (1 + 0.12 × i) (`RiderForm.power`, hiện ở màn chọn Rider là "Sức mạnh ×N"). Quái mạnh thêm cùng nhịp đó, nên dùng Rider mới nhất thì mỗi thế giới khó xấp xỉ nhau; Rider cũ yếu dần ở các thế giới sau. Dạng người cũng mạnh dần: máu và sức đánh × (1 + 0.06 × số thế giới đã qua).
- **Chỉ số theo cấp** (tính từ chỉ số Lv1): máu **+18%**, sát thương **+15%** mỗi cấp. Chỉ số trùm được chỉnh tay trong `WorldData`, không nhân theo cấp.
- **Giảm sát thương các màn đầu** (`GameState.enemy_damage_mult`, nhân sau cấp độ, áp cho cả đòn đánh lẫn đạn):

  | Tiến độ | Sát thương quái |
  |---|---|
  | Chưa có Driver nào (màn 1-1, đánh tay không) | 35% |
  | 1-2 · 1-3 · 1-4 · 1-B | 60% · 75% · 90% · 100% |
  | Từ thế giới 2 | 100% |

- **Bất tử ngắn sau khi trúng đòn:** dạng người 0.6 giây, dạng Rider 0.35 giây (nhân vật nhấp nháy), để không bị nhiều quái hoặc đạn trừ máu dồn dập cùng lúc. Đỡ đòn khi cúi thì không tính.
- Mỗi quái có **thanh máu và cấp độ** nhỏ trên đầu.

| Loại quái (Lv1) | Máu | Sát thương | Tốc độ | Poise | Ví dụ ở Lv9 (máu / sát thương) |
|---|---|---|---|---|---|
| Thường | 30 | 8 | 55 | 6 | 73 / 17.6 |
| Nhanh (`fast`) | 25 | 8 | 90 | 6 | 61 / 17.6 |
| Giáp (`armored`) | 60 | 14 | 40 | 15 | 146 / 30.8 |
| Bay (`flying`) | 24 | 7 | 70 | 6 | 59 / 15.4 |
| Khổng lồ (`giant`) | 150 | 18 | 34 | ∞ | 366 / 39.6 |
| Siêu tốc (`phantom`) | 22 | 8 | 120 | 6 | 54 / 17.6 |
| Bóng ma (`spectral`) | 34 | 9 | 52 | 6 | 83 / 19.8 |

Ví dụ: một đòn 17.6 của quái Lv9 làm dạng người (giáp 0) mất 18 máu, nhưng Kuuga Titan (giáp 60) chỉ mất 11. Quái cấp cao đánh đau hơn hẳn, nên biến thân và chọn form có giáp dày là quan trọng.

### 3.14 Màn chơi kiểu Contra

**Lộ trình.** Mỗi màn là một chuỗi đoạn nối nhau, khai báo bằng `"route"` trong `WorldData` (thiếu thì mặc định `["right"]`):

| Đoạn | Mô tả |
|---|---|
| `right` / `left` | Chạy ngang sang phải / sang trái: mặt đất có vực, bệ một chiều, thùng, bậc thang khối, cột đá giữa vực rộng. Lính bắn đứng gác trên mặt đất |
| `up` | **Giếng leo**, rộng đúng một màn hình, vách thép hai bên. Bệ một chiều xếp zig-zag theo 3 làn, nhảy xuyên từ dưới lên; trên cùng là gờ dẫn ra cửa. Rơi khỏi bệ thì rơi xuống bệ dưới / sàn đáy giếng |
| `down` | **Giếng tụt**: từ gờ ở cửa trên xuống sàn đáy, S + nhảy để xuống bệ hoặc bước khỏi mép bệ. Leo ngược lên theo các bệ được |

- Đoạn cuối luôn là đoạn ngang (vạch đích; màn trùm có đấu trường ở cuối). Không có hai giếng liền nhau.
- Builder tự kiểm tra: nếu vật cứng của đoạn này chắn vào khoảng trống của đoạn khác (lộ trình quay đầu đè lên chính nó) thì báo trong `layout["overlaps"]`, màn chơi in cảnh báo và test chiến dịch đánh lỗi màn đó.

| Màn | Lộ trình | Màn | Lộ trình | Màn | Lộ trình |
|---|---|---|---|---|---|
| 1-1 | → | 4-1 | → | 11-1 | → |
| 1-2 | → ↑ → | 4-2 | ← | 11-2 | → ↑ ← |
| 1-3 | → ↓ ← | 4-3 | → ↑ → | 11-3 | ↑ → ↑ → |
| 1-4 | ← ↑ ← | 4-4 | ← ↓ → | 11-4 | ← ↓ → ↓ ← |
| 1-B | ↑ → (đấu trường) | 4-B | ← (đấu trường) | 11-B | → ↑ → (đấu trường) |

Các thế giới khác không ghi `route` thì dùng mẫu mặc định theo thứ tự màn (`WorldData.DEFAULT_ROUTES`, chọn theo số thế giới để các thế giới không giống hệt nhau); màn Thức tỉnh luôn chạy thẳng sang phải.

Màn Thức tỉnh (X-1) chỉ chạy sang phải, không có vực, để làm màn hướng dẫn.

**Bố cục** (`StageBuilder`, sinh theo seed = id màn nên chơi lại vẫn quen đường):

| Thành phần | Luật |
|---|---|
| Chiều dài đoạn ngang | Tổng 2.200 px + 450 px mỗi màn trong thế giới (màn trùm 1.500 px), chia đều cho các đoạn ngang, tối thiểu 700 px mỗi đoạn. Màn có giếng dùng 75% tổng này |
| Chiều cao giếng | Leo: 480 px + 40 px mỗi màn · Tụt: 440 px + 40 px mỗi màn |
| Vực | Rộng 60–120 px, cách nhau 320–620 px. 30% là **vực rộng** 170–220 px có **cột đá** ở giữa (nhảy hai nhịp) |
| Bệ một chiều | Đoạn ngang: cao 60–95 px, rộng 96–200 px, đôi khi thêm tầng hai. Giếng leo: cách nhau đều, **tối đa 56 px** (Titan nhảy ×0.8 cao ~70 px vẫn leo được). Giếng tụt: cách nhau 70–90 px |
| Khối (kiểu Contra 2) | Thùng gỗ 32×32: thùng lẻ, hai thùng, chồng 2 tầng, bậc thang 1-2-1, từ màn thứ 3 có bậc 1-2-3-2-1. Là vật cứng: đứng lên được, **chặn đạn** (dùng làm chỗ nấp). Quái vướng khối thì nhảy qua |
| Quái | Đoạn ngang: cứ 250–420 px một nhóm 1–3 con, ~45% chạy ào, 12% xuất hiện từ phía sau. Giếng: quái cận chiến đứng trên bệ phía trước |
| Lính bắn | Đoạn ngang: đứng gác trên mặt đất (không sát vực, không trên khối), tỉ lệ 20% + 12% mỗi màn. Giếng: đứng trên bệ làn bên trái / phải |
| Checkpoint | Đầu mỗi đoạn vào từ giếng, đầu mỗi giếng, và mỗi 900 px đoạn ngang |

Giới hạn khoảng cách theo sức nhảy: `jump_velocity` −330 × SCALE với trọng lực 1.620 ⇒ nhảy cao ~109 px, xa ~170 px.

**Camera và luật chơi:**
- Camera chạy trên **đường gấp khúc** của bố cục (đoạn ngang: cao hơn sàn 50 px; giếng: giữa giếng). Vị trí camera là quãng đường `cam_s` dọc theo đường đó và **đi theo người chơi cả hai chiều**, chỉ dừng ở hai đầu đường. Camera nhìn trước 40 px: đoạn ngang theo hướng nhân vật quay mặt, trong giếng theo hướng đang leo / rơi; đổi phía và bám theo có trượt cho mượt.
- **Tường chặn chỉ ở hai đầu màn:** tường vô hình (lớp va chạm 6, chỉ chặn người chơi) sau điểm xuất phát, đúng mép khung nhìn khi camera ở đầu đường; cuối màn là tường thật. Màn trùm: lúc vào đấu trường camera khóa lại, có tường vô hình hai bên. Vách giếng là vật cứng thật.
- Quái thả ra lần đầu khi camera tới điểm spawn; quay lại không thả lại. Quái đuổi đánh và lính bắn ở lại chỗ của chúng, quay lại vẫn gặp; quái chạy ào ra khỏi khung nhìn quá 160 px thì biến mất. Vật phẩm rơi tự hết hạn sau 10 giây.
- Quái cận chiến nhảy lên bệ / tụt xuống bệ theo người chơi chỉ khi người chơi đang **đứng** ở bệ đó (cao hơn 40 px và cách dưới 90 px, hoặc thấp hơn 30 px và cách dưới 160 px); người chơi nhảy giữa không trung thì quái không nhảy theo. Vướng thùng / khối thì nhảy qua.
- **Rơi vực:** xuống quá mép dưới khung nhìn 40 px (tính cả khung nhìn đặt đúng chỗ người chơi, vì camera trượt theo có độ trễ). Trong giếng khung nhìn đi xuống theo người chơi nên rơi khỏi bệ không phải rơi vực. Mất 25% máu (máu Rider nếu đang biến thân), hồi sinh ở chỗ đứng an toàn trong khung nhìn gần chỗ đứng cuối cùng, bất tử 1.5 giây.
- **Gục:** chơi lại từ checkpoint gần nhất (`GameState.checkpoint` là chỉ số checkpoint).
- **Vạch đích** ở cuối đoạn ngang cuối cùng: màn Luyện tập qua màn ngay. Màn Thức tỉnh: đánh nhóm canh giữ rồi nhặt Driver. Màn trùm: camera khóa ở đấu trường, đánh trùm rồi nhặt Driver thế giới kế. Nhóm canh giữ / trùm chỉ tính quái trong khung nhìn.

**Bắn** (giữ nút, đạn vô hạn, tag `ranged`). **Chỉ form có súng**; dạng người và form khác không bắn được, nút Bắn ẩn đi:

| Form có súng | Sát thương | Hồi (giây) | Đặc điểm |
|---|---|---|---|
| Kuuga Pegasus (Pegasus Bowgun) | 8 | 0.35 | rất nhanh, xa, **xuyên** |
| Faiz (Faiz Phone) | 3 × 3 viên | 0.45 | loạt xòe |
| Faiz Blaster (Faiz Blaster) | 10 | 0.5 | đạn to, **xuyên** |
| W nửa Trigger | 4 (Heat 5) | 0.13 | liên thanh; Luna: xòe 3 viên |

Đạn trúng tích ít nộ hơn đòn cận chiến (tính một nửa) và không gây khựng hình, để giữ nhịp bắn liên tục.

### 3.15 Nâng cấp chung (Mảnh Ký Ức)

Cấp Rider chỉ tăng khi qua màn, vì đó là phần cốt truyện. Mảnh Ký Ức (5 mỗi quái, 50 mỗi trùm) dùng ở hub cho nâng cấp chung, áp dụng cho mọi Rider:

| Nâng cấp | Hiệu quả mỗi bậc | Giá (bậc 1 / 2 / 3) |
|---|---|---|
| Thể lực | +10 HP dạng người | 50 / 120 / 250 |
| Cộng hưởng | Nộ tích nhanh hơn 10% | 50 / 120 / 250 |
| Cường hóa | +10% máu mọi Rider | 80 / 160 / 300 |

### 3.16 Lưu game (`user://save.json`, version 2)

```json
{
  "version": 2,
  "world_index": 1, "stage_index": 2, "worlds_cleared": 1,
  "drivers": {
    "kuuga": {"active": true,  "level": 5, "forms": ["dragon", "pegasus", "titan"]},
    "faiz":  {"active": true,  "level": 2, "forms": ["axel"]},
    "double":{"active": false, "level": 0, "forms": []}
  },
  "main_rider": "faiz",
  "fragments": 340,
  "cleared_stages": ["1-1", "1-2", "1-3", "1-4", "1-B", "2-1", "2-2"],
  "rei_memories": ["kuuga"]
}
```
Game tự lưu mỗi khi qua màn. Save có `version` khác thì bị bỏ qua (bản mẫu). Bản đầy đủ sẽ có hàm chuyển đổi save cũ.

### 3.17 HUD

```
 MÁU [██████████████░░░░] 112/160        Kuuga · Màn 1-3 · Đợt 1/2
     ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁  ← máu người                Kuuga Mighty Form Lv2
 NỘ  [██████████|░░░░░░░] 18s   (tím: đang ở form đặc biệt)  Combo 5 · Tìm: Titan Form
```
- **Góc trên trái** (`scripts/ui/player_hud.gd`, vẽ bằng `_draw`):
  - Dạng người: MÁU màu đỏ.
  - Dạng Rider: MÁU là máu Rider (xanh lá), kèm vạch mảnh bên dưới là máu người.
  - NỘ màu cam; đầy thì nhấp nháy và hiện "MAX". Ở dạng Rider có vạch trắng ở mức 50 (Final Attack). Ở form đặc biệt thanh chuyển **tím**, hiện số giây còn lại; dưới 25 thì nháy đỏ.
- **Góc trên phải:** màn · tiến độ, món chính của màn còn chờ nhặt ("Tìm: Dragon Form"), combo.
- **Trên đầu quái:** thanh máu và cấp độ.
- **Banner giữa màn hình:** giới thiệu màn (kèm "Quái có thể rơi: ..."), nhặt vật phẩm, "HẾT NỘ · về form gốc", "Cần 20 nộ để đổi form", kết quả màn.

### 3.18 Hội thoại (`scripts/data/story_data.gd`, `scripts/ui/dialogue_box.gd`)

**Khung thoại** (`DialogueBox`) ở cuối màn hình: chân dung 28×28 phóng 2 lần, bảng tên màu của người nói, chữ chạy 55 ký tự/giây, số câu "2/5", mũi tên nhấp nháy khi câu đã hiện hết. Người dẫn truyện không có chân dung, chữ căn giữa.

| Thao tác | Tác dụng |
|---|---|
| Đánh (J) / Enter / Space / chạm | Hiện hết câu; bấm lần nữa sang câu kế |
| Esc / chạm "BỎ QUA" | Bỏ qua cả đoạn (ở phần mở đầu: nhảy tới thẻ tựa) |

- Trong màn chơi, lúc thoại **cả màn dừng** (`get_tree().paused`, phase `TALK`), nút cảm ứng ẩn đi. Câu cuối xong thì đợi 2 khung hình mới chạy lại, để phím vừa bấm không lọt thành cú đấm.
- **Nhịp thoại** mỗi màn (`StoryData.STAGES["1-2"]`...): `start` (đầu màn, trước màn chọn Rider) · `goal` (tới vạch đích màn Trùm; màn Thức tỉnh chỉ khi chưa có Driver) · `key` (1 giây sau khi nhặt món chính của màn, chờ cảnh biến thân) · `clear` (trước bảng kết quả). Sau trùm có thêm `WORLD_CLEAR`: thoại trên **bản đồ Chuỗi Trái Đất** (`EarthMap`), Trái Đất vừa giải cứu sáng lại.
- Mỗi đoạn chỉ hiện **một lần mỗi lượt chơi** (`GameState.seen_story`, có lưu trong save). Gục rồi chơi lại từ checkpoint không bị lặp.
- Người nói khai báo ở `StoryData.SPEAKERS` (tên, màu, chân dung). `{name}` trong lời thoại và tên người nói "hero" là tên người chơi đặt.
- **Chân dung** trong `art/ui/portraits/`, vẽ bằng `python3 tools/gen_story_art.py`: cắt đầu từ sprite PixelLab (nhân vật chính, Kuuga, Daguba), đổi màu tóc / áo cho Echo Rider (Godai, Ichijo, Takumi, Shotaro có mũ phớt, Philip), vẽ bằng hình khối cho Void và Pen. Script này cũng vẽ `art/story/earth.png` (hành tinh thang xám, game nhuộm màu) và `art/story/void.png`.
- Thêm hội thoại cho thế giới mới: thêm khóa mã màn vào `STAGES`, một dòng vào `WORLD_CLEAR`, người nói mới vào `SPEAKERS`; đặt `"world"` cho Trái Đất đó trong `EARTHS`.
- Bot test (`campaign_test`) bấm qua từng câu và báo màn nào thiếu nhịp thoại.

---

## 4. Lộ trình phát triển

| Giai đoạn | Mục tiêu | Việc cần làm |
|---|---|---|
| **0. Bản mẫu** *(đã có)* | Chạy trọn vòng lặp | ✅ Combat, biến thân, 3 Rider với form rơi từ quái và nộ làm nhiên liệu, đạn quái cao/thấp, chuỗi Driver qua 3 thế giới, save · ☐ Cân bằng số liệu · ☐ Âm thanh |
| **1. Art cơ bản** | Thay hình tạm | Dạng người + Kuuga Mighty, 2 loại quái, 1 tileset |
| **2. Màn 1-1 thật** | Màn đầu hoàn chỉnh | Màn cuộn ngang, khóa đấu trường, hội thoại, cutscene mở đầu, mục tiêu HẠ KẺ GIỮ |
| **3. Demo Hồi 1** | 15 màn, 3 trùm | Lớp Boss, các kiểu thử thách Thức tỉnh, hub, cổng kỹ năng, Ký ức của Rei |
| **4. Hồi 2 → 4** | Toàn bộ chuỗi | Mỗi thế giới khoảng 3–4 tuần |
| **5. Hoàn thiện** | Phát hành | Tay cầm, cài đặt, 2 người chơi, post-game, xuất bản lên itch.io |

---

## 5. Bản quyền

Kamen Rider thuộc bản quyền của **Ishimori Productions và Toei**. Đây là **fan game phi thương mại**:
- Không bán, không nhận donate gắn với game.
- Ghi rõ: *"Fan game không chính thức. Kamen Rider © Ishimori Productions / Toei."*
- Tự vẽ sprite, tự soạn nhạc; không dùng nhạc hay hình cắt từ phim.
- Muốn thương mại hóa: giữ nguyên hệ thống (chuỗi Driver, `RiderForm`, cấp, trait) và thay các Rider bằng nhân vật tự thiết kế.
