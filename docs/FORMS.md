# Kamen Rider: Chrono Henshin — Tổng hợp Form · Hiệu ứng · Tuyệt chiêu

Tài liệu tra cứu mọi form của 27 Rider: chỉ số, kiểu đòn, vũ khí, súng, kỹ năng riêng, hiệu ứng hình ảnh và Final Attack (tuyệt chiêu). **Mọi con số được lấy trực tiếp từ code** (chạy Godot headless, gọi `GameState.create_form()` rồi đọc `get_attack()` / `get_shot()` / `fx()` của từng form ở Lv1 và Lv5), nên khớp với game tại thời điểm viết.

Nguồn: `scripts/riders/kuuga.gd`, `faiz.gd`, `double.gd` (3 Rider có script riêng), `scripts/riders/data_rider.gd` + hằng `RIDER` trong `scripts/data/worlds/wNN_*.gd` (24 Rider còn lại), `scripts/player/player.gd`, `scripts/enemies/enemy.gd`, `scripts/combat/fx.gd`. Sửa dữ liệu form thì cập nhật lại file này.

## Mục lục

- [0. Cơ chế chung](#0-cơ-chế-chung)
- [1. Kamen Rider Kuuga · 2000](#1-kamen-rider-kuuga--2000)
- [2. Kamen Rider Agito · 2001](#2-kamen-rider-agito--2001)
- [3. Kamen Rider Ryuki · 2002](#3-kamen-rider-ryuki--2002)
- [4. Kamen Rider Faiz · 2003](#4-kamen-rider-faiz--2003)
- [5. Kamen Rider Blade · 2004](#5-kamen-rider-blade--2004)
- [6. Kamen Rider Hibiki · 2005](#6-kamen-rider-hibiki--2005)
- [7. Kamen Rider Kabuto · 2006](#7-kamen-rider-kabuto--2006)
- [8. Kamen Rider Den-O · 2007](#8-kamen-rider-den-o--2007)
- [9. Kamen Rider Kiva · 2008](#9-kamen-rider-kiva--2008)
- [10. Kamen Rider Decade · 2009](#10-kamen-rider-decade--2009)
- [11. Kamen Rider W · 2009](#11-kamen-rider-w--2009)
- [12. Kamen Rider OOO · 2010](#12-kamen-rider-ooo--2010)
- [13. Kamen Rider Fourze · 2011](#13-kamen-rider-fourze--2011)
- [14. Kamen Rider Wizard · 2012](#14-kamen-rider-wizard--2012)
- [15. Kamen Rider Gaim · 2013](#15-kamen-rider-gaim--2013)
- [16. Kamen Rider Drive · 2014](#16-kamen-rider-drive--2014)
- [17. Kamen Rider Ghost · 2015](#17-kamen-rider-ghost--2015)
- [18. Kamen Rider Ex-Aid · 2016](#18-kamen-rider-ex-aid--2016)
- [19. Kamen Rider Build · 2017](#19-kamen-rider-build--2017)
- [20. Kamen Rider Zi-O · 2018](#20-kamen-rider-zi-o--2018)
- [21. Kamen Rider Zero-One · 2019](#21-kamen-rider-zero-one--2019)
- [22. Kamen Rider Saber · 2020](#22-kamen-rider-saber--2020)
- [23. Kamen Rider Revice · 2021](#23-kamen-rider-revice--2021)
- [24. Kamen Rider Geats · 2022](#24-kamen-rider-geats--2022)
- [25. Kamen Rider Gotchard · 2023](#25-kamen-rider-gotchard--2023)
- [26. Kamen Rider Gavv · 2024](#26-kamen-rider-gavv--2024)
- [27. Kamen Rider Zeztz · 2025](#27-kamen-rider-zeztz--2025)
- [Phụ lục: bảng so sánh mọi form](#phụ-lục-bảng-so-sánh-mọi-form)

## 0. Cơ chế chung

### 0.1 Nút bấm và form

| Nút | Tác dụng |
|---|---|
| **Đánh** (J) | Luôn là tay không: chuỗi N đòn thường rồi 1 đòn kết. N = 2 nếu đòn tay kiểu Heavy, còn lại 3. Form `armed` (Blade) thì nút Đánh chém luôn bằng vũ khí cầm sẵn. |
| **Chém** (K) | Chỉ form có vũ khí cận chiến: 3 nhát + nhát kết (vũ khí kiểu Heavy: 2 nhát + nhát kết). Vũ khí chỉ hiện trong animation chém. |
| **Bắn** (giữ H) | Chỉ form có súng. Bắn 8 hướng, súng hiện ở tay lúc giữ nút. Đạn luôn mang tag `ranged`. |
| **Special** (L) | Đổi sang form kế tiếp trong vòng `order` (chỉ các form đã mở / item đang mang). Hồi chiêu 1s. W: L đổi nửa Soul, giữ W + L đổi nửa Body (hồi 0.6s). |
| **Final** (U) | Tuyệt chiêu. Cần ≥ 50 nộ, **đốt hết nộ**. Bất tử trong lúc ra đòn, không hủy được. |

- **Form gốc**: dùng thoải mái, không tốn nộ.
- **Form đặc biệt**: vào cần ≥ 20 nộ và tốn 10 nộ; ở form này nộ tụt **4/giây** (đầy thanh dùng được 25 giây) trừ khi form ghi `rage_drain` riêng; nộ về 0 thì tự về form gốc (bất tử 0.6s). Tung Final ở form đặc biệt → nộ về 0 → đánh xong về form gốc.
- **Item** (`item: true`, vd. thẻ Sword / Strike / Guard Vent của Ryuki, lá Mach / Thunder của Blade, Onibi / Kaentsuzumi của Hibiki): quái rơi, mang vào màn tối đa **2 item**, dùng như form đặc biệt.
- Nhặt Driver / form lần đầu trong màn: nộ đầy và biến thân ngay vào form đó; nếu đang là Rider thì ra đòn vào sân (`swap_in`, ~8 sát thương, hất văng, bất tử).
- Nộ tích được: đánh trúng ở form gốc (0.7 × sát thương, đạn tính một nửa), bị đánh (0.8 × máu mất).

### 0.2 Công thức

- **Sát thương thực** = sát thương gốc × (1 + 2% mỗi đòn combo, tối đa +50%) × `atk` của form × (1 + 10% × (Lv − 1)) × **sức mạnh thế hệ**.
- **Sức mạnh thế hệ** = 1 + 0.12 × (số thế giới − 1): Kuuga ×1.00 … Zeztz ×4.12. Nhân vào cả máu lẫn sát thương.
- **Máu tối đa** = `hp` × (1 + 8% × (Lv − 1)) × sức mạnh thế hệ.
- **Giáp**: sát thương nhận = sát thương × 100 / (100 + giáp). **Trụ đòn** (`poise`): đòn yếu hơn mức này không làm Rider khựng.
- **Khiên** (`guard`): đứng yên / không ra đòn mà bị đánh từ phía trước → chỉ nhận `guard` × sát thương (vd. 0.4 = chặn 60%).
- **Lv5**: mọi Final Attack ×1.5 (`final_mult`) và tên chiêu thêm tiền tố (Rising, Shining…); riêng Ryuki Lv5 mở form Survive thay cho tên.
- Trong các bảng bên dưới: **sát thương = gốc** (chưa nhân `atk`, cấp, thế hệ); cột *Thực Lv1 / Lv5* ở phần Final đã nhân đủ (chưa tính combo). Thời gian tính bằng giây, tầm / lực đẩy tính bằng đơn vị thiết kế (px).

### 0.3 Kiểu đòn (style) của DataRider

Sát thương gốc · khởi động / ra đòn / hồi (giây) · tầm với phía trước:

| Kiểu | Đòn thường | Đòn kết | Final Attack |
|---|---|---|---|
| Brawler | 5 · 0.05/0.08/0.12 · 23 | 12 · phá giáp · 27 | 60 · phá giáp · lao tới 260, bật lên 120 · 30 |
| Lancer | 4 · 0.04/0.08/0.1 · 35 | 10 · 39 | 45 · lao tới 200, bật lên 200 · 44 |
| Blade | 6 · 0.07/0.08/0.14 · 31 | 14 · phá giáp · 36 | 65 · phá giáp · lao tới 240, bật lên 60 · 46 |
| Heavy (2 đòn + kết) | 9 · phá giáp · 0.14/0.1/0.3 · 28 | 25 · phá giáp · 32 | 70 · phá giáp · đứng tại chỗ · 35 |
| Gunner | *(nút Đánh dùng Brawler)* | *(nút Đánh dùng Brawler)* | 50 · tầm xa · đứng bắn · 180 |

Nút Đánh của form Blade / Gunner dùng bảng Brawler (vũ khí sang nút Chém / Bắn). Final Attack luôn theo `style` của form. Form có thể ghi đè từng đòn qua `attacks` (sát thương, số nhịp, lực đẩy, tag…) và cộng tag cho mọi đòn qua `tags`.

### 0.4 Tag hiệu ứng lên quái

| Tag | Tác dụng (enemy.gd) |
|---|---|
| `heavy` | Phá giáp: quái **Armored** nhận đủ sát thương (bình thường chỉ 40%). |
| `final` | Tự gắn cho mọi Final Attack: xuyên giáp Armored, rung màn hình mạnh, tiếng va chạm nặng. |
| `ranged` | Đòn / đạn tầm xa (nạp nộ chỉ một nửa). |
| `time` | Quái **Fast** không né được (bình thường né 75%). Quái đang bị làm chậm cũng không né. |
| `stun` | Choáng **1.2s**: dừng mọi đòn, đứng im. |
| `freeze` | Đóng băng **1.5s**: đứng im, không ra đòn. |
| `burn` | Cháy **2s**, cứ 0.5s mất 15% sát thương của đòn gây cháy (tối thiểu 1). |
| `shock` | Điện lan: tối đa **2 quái** gần nhất trong bán kính 70 nhận 40% sát thương (không lan tiếp). |
| `force` | Đẩy / hút / hất theo lực đẩy **kể cả khi đòn không đủ làm quái khựng**. |

Trùm: thời gian choáng / đóng băng chỉ còn 40%, cháy 75%, và **miễn** `force`.

### 0.5 Tăng tốc thời gian (`effect: "time"`)

Faiz Axel, Kabuto Hyper, Decade Kamen Ride: Kabuto, Drive Type Formula, Geats Boost Form:

- Quái chậm còn **15%**; Rider chạy và ra đòn nhanh **×1.6**, để bóng mờ, màn hình ngả xanh, tiếng *Clock Up*, chữ báo (vd. `CLOCK UP`).
- Mọi đòn mang tag `time`. Nộ tụt **10/giây** (đầy thanh = 10 giây), HUD đếm ngược tên form + số giây.
- Final Attack bị thay bằng **loạt đòn liên hoàn**: lao tới 200, **5 nhịp × 16** (= 80 gốc), tag `time`, không hủy được.
- Lưu ý (theo code hiện tại): Final tăng tốc thời gian thay thế đòn **sau** khi đã nhân ×1.5 Lv5, nên ở Lv5 chiêu này **không** được ×1.5 (`DataRider.get_attack`). Các ghi đè `attacks.final` của form cũng không áp dụng.

### 0.6 Hiệu ứng hình ảnh (Fx)

| Mã | Hình | Mã | Hình |
|---|---|---|---|
| `spark` | tia va chạm toả ra | `slash` | vệt chém hình cung |
| `fire` | lửa bùng bốc lên | `lightning` | tia sét gấp khúc |
| `sound` | vòng sóng âm lan ra | `wind` | vệt gió xoáy |
| `ring` | sóng chấn động dẹt | `tachyon` | hạt tachyon bắn ngược lên |
| `feather` | lông vũ vàng rơi | `seal` | dấu phong ấn Linto bốc cháy |
| `crest` | huy hiệu sừng Agito dưới chân | `dragon` | rồng lửa Dragreder xoáy quanh |
| `pointer` | mũi nón đỏ Pointer chĩa tới | `phi` | ký hiệu Φ đỏ |
| `cards` | hàng thẻ bài hologram | `taiko` | huy hiệu trống Ongeki + sóng âm |
| `moon` | trăng lưỡi liềm sau lưng | `rings3` | ba vòng Medal đỏ / vàng / lục |
| `rocket` | lửa tên lửa phụt sau lưng | `circle` | vòng phép đỏ có ký tự |
| `crack` | khe nứt khóa kéo Helheim mở trên đầu | `tire` | lốp xe vành bạc lăn vòng quanh Rider |
| `eye` | con mắt Ghost khổng lồ sau lưng, viền gai lửa | `hit_text` | chữ HIT! vàng viền đen bật lên |
| `fruit` | lát trái cây khổng lồ chụp xuống rồi tách múi |  |  |

Kiểu đạn: `ball` viên tròn · `bolt` tia sét · `fire` cầu lửa · `arrow` mũi tên khí. Mặc định (form không ghi `fx`): trúng `spark`, Final `ring`, đạn `ball`, màu `#ffd980`.

## 1. Kamen Rider Kuuga · 2000

- **Driver:** Arcle · **Lối chơi:** Bền bỉ: máu, giáp cao · 4 form · **Sức mạnh thế hệ:** ×1
- **Form gốc:** `mighty`
- **Form rơi ở màn luyện tập:** 1-2 → **Dragon Form** · 1-3 → **Pegasus Form** · 1-4 → **Titan Form**
- **Thưởng theo cấp:** Lv1: Mighty Form (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Rising: Final Attack x1.5
- **Giọng đai / tiếng hô:** `dragon` "超変身!" · `pegasus` "超変身!" · `titan` "超変身!"

### 1.1 Mighty Form  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 170 | 30 | 125 | ×1 | ×1 | 8 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Mighty Kick khắc dấu phong ấn bốc cháy lên quái (`burn`).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff734d`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Dấu ấn trên quái khi Final trúng: `seal` — dấu phong ấn Linto bốc cháy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` `burn` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Mighty Kick** (Lv5: *Rising Mighty Kick*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160); gây cháy 2s.
- Tag: `heavy` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 60** · **Lv5 ≈ 126** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ lửa bùng bốc lên, in dấu phong ấn Linto bốc cháy lên quái (màu `#ff734d`); tiếng nạp *final_charge* + giọng `kuuga_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Chiếc Arcle phát sáng rồi hòa vào cơ thể {name}. Bộ giáp đỏ hiện ra.
> **Pen:** Nó... chọn cậu rồi! Đây là Kamen Rider Kuuga, Mighty Form.
> **{name}:** Cảm giác này... sức mạnh đang chảy về!

### 1.2 Dragon Form  ·  _form đặc biệt, rơi ở màn 1-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 130 | 5 | 175 | ×1.35 | ×0.8 | 3 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Nút Chém: **Dragon Rod** (3 nhát + nhát kết, bảng đòn lancer).

**Kỹ năng riêng:** Nhảy ×1.35, chạy 175. Nhát kết Dragon Rod đẩy bay quái (`force`). Sức đánh thấp nhất của Kuuga (×0.8) nhưng gậy với xa.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#6699ff`
- Đòn trúng: `wind` — vệt gió xoáy
- Vệt vung đòn: `wind` — vệt gió xoáy
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Dấu ấn trên quái khi Final trúng: `seal` — dấu phong ấn Linto bốc cháy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Chém (nhát kết) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (220, -80) | `force` | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Splash Dragon** (Lv5: *Rising Splash Dragon*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 36** · **Lv5 ≈ 76** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt, in dấu phong ấn Linto bốc cháy lên quái (màu `#6699ff`); tiếng nạp *final_charge* + giọng `kuuga_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Godai:** Màu xanh! Dragon nhảy cao, chạy nhanh. Bấm Chém để quét gậy Dragon Rod, nhát cuối đẩy bay quái.
> **Pen:** Form đặc biệt ăn nộ. Hết nộ là tự về Mighty, nhớ nhé.

### 1.3 Pegasus Form  ·  _form đặc biệt, rơi ở màn 1-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 15 | 110 | ×1 | ×0.9 | 4 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **Pegasus Bowgun** — 8 sát thương/viên, hồi 0.35s, tốc độ 420, bay 1.4s, bán kính 2.5, đạn `arrow` (mũi tên khí), xuyên.

**Kỹ năng riêng:** Form duy nhất của Kuuga có súng: Pegasus Bowgun bắn chậm nhưng rất xa, mũi tên xuyên hàng quái. Final Attack cũng là phát bắn tầm xa.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#73f280`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Dấu ấn trên quái khi Final trúng: `seal` — dấu phong ấn Linto bốc cháy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Blast Pegasus** (Lv5: *Rising Blast Pegasus*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 45** · **Lv5 ≈ 94** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt, in dấu phong ấn Linto bốc cháy lên quái (màu `#73f280`); tiếng nạp *final_charge* + giọng `kuuga_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Ichijo:** Pegasus Bowgun... Được, tôi yểm trợ. Giữ Bắn để bắn liên tục, giữ lên để ngắm lên. Mũi tên khí xuyên cả hàng Grongi.

### 1.4 Titan Form  ·  _form đặc biệt, rơi ở màn 1-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 200 | 60 | 80 | ×0.8 | ×1.4 | 20 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Nút Chém: **Titan Sword** (2 nhát + nhát kết, bảng đòn heavy).

**Kỹ năng riêng:** Giáp 60, trụ đòn 20: cứng như đá. Mọi đòn tay đều phá giáp. Calamity Titan đâm kiếm phong ấn làm quái choáng (`stun`).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#bf73ff`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Dấu ấn trên quái khi Final trúng: `seal` — dấu phong ấn Linto bốc cháy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| Chém (nhát thường) | 11 | 1 | 0.15 / 0.1 / 0.3 | 38 | (70, -20) | `heavy` | — |
| Chém (nhát kết) | 28 | 1 | 0.25 / 0.12 / 0.45 | 42 | (260, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` `stun` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết. Chuỗi nút Chém: 2 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Calamity Titan** (Lv5: *Rising Calamity Titan*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160); gây choáng 1.2s.
- Tag: `heavy` `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 98** · **Lv5 ≈ 206** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt, in dấu phong ấn Linto bốc cháy lên quái (màu `#bf73ff`); tiếng nạp *final_charge* + giọng `kuuga_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Godai:** Màu tím! Titan chậm nhưng cứng như đá. Bấm Chém để đâm Titan Sword. Final đâm trúng là quái bị phong ấn, đứng im.

---

## 2. Kamen Rider Agito · 2001

- **Driver:** Alter Ring · **Lối chơi:** Cân bằng · form giáo, form kiếm · **Sức mạnh thế hệ:** ×1.12
- **Form gốc:** `ground`
- **Form rơi ở màn luyện tập:** 2-2 → **Storm Form** · 2-3 → **Flame Form** · 2-4 → **Trinity Form**
- **Thưởng theo cấp:** Lv1: Ground Form (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Shining Form: Final Attack x1.5
- **Lv5 — Shining:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Shining <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `crest` (huy hiệu sừng Agito dưới chân)

### 2.1 Ground Form  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.05 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffcc40`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `crest` — huy hiệu sừng Agito dưới chân

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Rider Kick** (Lv5: *Shining Rider Kick*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 71** · **Lv5 ≈ 148** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện huy hiệu sừng Agito dưới chân, trúng quái nổ sóng chấn động dẹt (màu `#ffcc40`); tiếng nạp *final_charge* + giọng `agito_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Alter Ring hiện ra quanh eo {name}. Ánh sáng vàng như mặt trời mọc.
> **Shouichi:** Cảm giác đó... tôi cũng từng có. Đó là sức mạnh Agito. Nó không hỏi cậu có sẵn sàng chưa đâu.
> **{name}:** Henshin!

### 2.2 Storm Form  ·  _form đặc biệt, rơi ở màn 2-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 135 | 10 | 170 | ×1.25 | ×0.9 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Nút Chém: **Storm Halberd** (3 nhát + nhát kết, bảng đòn lancer).

**Kỹ năng riêng:** Chém (nhát kết): lực đẩy (240, -80), thêm `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#6699ff`
- Đòn trúng: `wind` — vệt gió xoáy
- Vệt vung đòn: `wind` — vệt gió xoáy
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `crest` — huy hiệu sừng Agito dưới chân

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| Chém (nhát thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Chém (nhát kết) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (240, -80) | `force` | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Haldent Tornado** (Lv5: *Shining Haldent Tornado*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 45** · **Lv5 ≈ 95** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện huy hiệu sừng Agito dưới chân, trúng quái nổ sóng chấn động dẹt (màu `#6699ff`); tiếng nạp *final_charge* + giọng `agito_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shouichi:** Màu xanh! Storm Form nhẹ và nhanh. Bấm Chém để quay Storm Halberd, nhát cuối tạo lốc thổi bay quái.

### 2.3 Flame Form  ·  _form đặc biệt, rơi ở màn 2-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 170 | 30 | 110 | ×0.95 | ×1.25 | 12 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **Flame Saber** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: thêm `burn`. Chém (nhát thường): thêm `burn`. Chém (nhát kết): thêm `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff5933`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `crest` — huy hiệu sừng Agito dưới chân

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | `burn` | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` `burn` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` `burn` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Saber Slash** (Lv5: *Shining Saber Slash*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100); gây cháy 2s.
- Tag: `heavy` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 91** · **Lv5 ≈ 191** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện huy hiệu sừng Agito dưới chân, trúng quái nổ sóng chấn động dẹt (màu `#ff5933`); tiếng nạp *final_charge* + giọng `agito_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shouichi:** Màu đỏ! Flame Form. Bấm Chém để rút Flame Saber: chậm hơn, nhưng lưỡi lửa đốt cháy quái.

### 2.4 Trinity Form  ·  _form đặc biệt, rơi ở màn 2-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 175 | 35 | 135 | ×1.1 | ×1.3 | 12 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **Flame Saber** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: 34 sát thương/nhịp, 2 nhịp, thêm `burn`. Chém (nhát thường): thêm `burn`. Chém (nhát kết): lực đẩy (240, -80), thêm `burn` `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `crest` — huy hiệu sừng Agito dưới chân

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | `burn` | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (240, -80) | `heavy` `burn` `force` | — |
| **Final Attack** | 34 | 2 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` `burn` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Fire Storm Attack** (Lv5: *Shining Fire Storm Attack*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 2 nhịp × 34 = 68 sát thương gốc; hất văng (260, -100); gây cháy 2s.
- Tag: `heavy` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 99** · **Lv5 ≈ 208** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện huy hiệu sừng Agito dưới chân, trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `agito_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shouichi:** Vai trái xanh, vai phải đỏ: Trinity Form! Kiếm lửa và lốc xoáy cùng lúc. Cậu học nhanh thật đấy.

---

## 3. Kamen Rider Ryuki · 2002

- **Driver:** Advent Deck · **Lối chơi:** Thẻ Vent · kiếm rồng, cầu lửa, khiên rồng · **Sức mạnh thế hệ:** ×1.24
- **Form gốc:** `ryuki`
- **Form rơi ở màn luyện tập:** 3-2 → **Sword Vent** · 3-3 → **Strike Vent** · 3-4 → **Guard Vent**
- **Thưởng theo cấp:** Lv1: Ryuki (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: mở final form Ryuki Survive, Final Attack x1.5
- **Lv5:** mở form `survive` + mọi Final ×1.5
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `dragon` (rồng lửa Dragreder xoáy quanh)
- **Giọng đai / tiếng hô:** `final` "Final Vent." · `guard_vent` "Guard Vent." · `strike_vent` "Strike Vent." · `survive` "Survive." · `sword_vent` "Sword Vent."

### 3.1 Ryuki  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.05 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: thêm `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff6640`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Lúc tung Final (quanh Rider): `dragon` — rồng lửa Dragreder xoáy quanh

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` `burn` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Dragon Rider Kick**

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160); gây cháy 2s.
- Tag: `heavy` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 78** · **Lv5 ≈ 164** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện rồng lửa Dragreder xoáy quanh, trúng quái nổ lửa bùng bốc lên (màu `#ff6640`); tiếng nạp *final_charge* + giọng `ryuki_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Advent Deck bay về tay {name}. Trong mặt kính, rồng đỏ Dragreder gầm lên: khế ước đã thành. Đai hiện ra quanh eo.
> **{name}:** Henshin!

### 3.2 Ryuki Survive  ·  _form đặc biệt, mở ở Lv5_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 195 | 40 | 145 | ×1.1 | ×1.45 | 14 | 5/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade). Nút Bắn: **súng** — 11 sát thương/viên, hồi 0.45s, tốc độ 360, bay 0.9s, bán kính 5, đạn `fire` (cầu lửa), tag `burn`.

**Kỹ năng riêng:** Nộ tụt 5/giây (thay vì 4). Final Attack: thêm `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff9933`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Lúc tung Final (quanh Rider): `dragon` — rồng lửa Dragreder xoáy quanh

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` `burn` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Dragon Fire Stream**

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100); gây cháy 2s.
- Tag: `heavy` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 117** · **Lv5 ≈ 245** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện rồng lửa Dragreder xoáy quanh, trúng quái nổ lửa bùng bốc lên (màu `#ff9933`); tiếng nạp *final_charge* + giọng `ryuki_final`.

### 3.3 Sword Vent  ·  _item, rơi ở màn 3-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 28 | 122 | ×1 | ×1.25 | 11 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: thêm `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffbf59`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Lúc tung Final (quanh Rider): `dragon` — rồng lửa Dragreder xoáy quanh

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` `burn` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Drag Saber Slash**

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100); gây cháy 2s.
- Tag: `heavy` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 101** · **Lv5 ≈ 212** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện rồng lửa Dragreder xoáy quanh, trúng quái nổ lửa bùng bốc lên (màu `#ffbf59`); tiếng nạp *final_charge* + giọng `ryuki_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shinji:** Sword Vent! Drag Saber làm từ đuôi Dragreder. Bấm Chém: ba nhát, nhát cuối phá giáp, Final còn đốt cháy quái.

### 3.4 Strike Vent  ·  _item, rơi ở màn 3-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 145 | 15 | 118 | ×1 | ×1 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **súng** — 9 sát thương/viên, hồi 0.5s, tốc độ 320, bay 0.9s, bán kính 5, đạn `fire` (cầu lửa), tag `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff8026`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Lúc tung Final (quanh Rider): `dragon` — rồng lửa Dragreder xoáy quanh

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Dragclaw Fire**

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 62** · **Lv5 ≈ 130** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện rồng lửa Dragreder xoáy quanh, trúng quái nổ lửa bùng bốc lên (màu `#ff8026`); tiếng nạp *final_charge* + giọng `ryuki_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shinji:** Strike Vent! Giữ nút Bắn, Dragclaw phun lửa, quái trúng còn cháy thêm. Bắn xa được, đừng để bị áp sát.

### 3.5 Guard Vent  ·  _item, rơi ở màn 3-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 58 | 82 | ×0.85 | ×1.35 | 20 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** **Khiên** guard 0.4: đứng chắn chỉ nhận 40% sát thương từ phía trước.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#d9d9f2`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Lúc tung Final (quanh Rider): `dragon` — rồng lửa Dragreder xoáy quanh

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Advent: Dragreder**

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 117** · **Lv5 ≈ 246** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện rồng lửa Dragreder xoáy quanh, trúng quái nổ lửa bùng bốc lên (màu `#d9d9f2`); tiếng nạp *final_charge* + giọng `ryuki_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shinji:** Guard Vent! Khiên Dragshield chặn hơn nửa sát thương phía trước khi cậu không ra đòn. Cứ đứng vững mà đập.

---

## 4. Kamen Rider Faiz · 2003

- **Driver:** Faiz Driver · **Lối chơi:** Nhanh, đánh mạnh, có súng · **Sức mạnh thế hệ:** ×1.36
- **Form gốc:** `faiz`
- **Form rơi ở màn luyện tập:** 4-2 → **Axel Form** · 4-4 → **Blaster Form** · (màn 4-3 không rơi form)
- **Thưởng theo cấp:** Lv1: Faiz (form gốc, bắn bằng Faiz Phone) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: sát thương +40%, máu +32%
- **Giọng đai / tiếng hô:** `axel` "Complete. Start up." · `blaster` "Awakening." · `final` "Exceed Charge." · `henshin` "Standing by. Complete."

### 4.1 Faiz (form gốc)  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 125 | 15 | 155 | ×1.05 | ×1.2 | 5 | — | Brawler (tay chân) |

**Vũ khí:** Nút Bắn: **Faiz Phone** — 3 sát thương/viên, hồi 0.45s, tốc độ 300, bay 0.8s, bán kính 2.5, đạn `ball` (viên đạn tròn), 3 viên xòe 0.1 rad.

**Kỹ năng riêng:** Có súng ngay từ form gốc (Faiz Phone, loạt 3 viên xòe). Crimson Smash: mũi nón Pointer ghim quái lại (`stun`) trước cú đá.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff4040`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `pointer` — mũi nón đỏ Pointer chĩa tới
- Dấu ấn trên quái khi Final trúng: `phi` — ký hiệu Φ đỏ

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.04 / 0.06 / 0.1 | 23 | (40, -10) | — | — |
| Đánh (đòn kết chuỗi) | 13 | 1 | 0.1 / 0.1 / 0.28 | 35 | (170, -60) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 29 | (260, -160) | `heavy` `stun` | lao tới 260, bật lên 140, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Crimson Smash**

- lao tới 260, bật lên 140 rồi tung đòn (tầm 29); 60 sát thương gốc; hất văng (260, -160); gây choáng 1.2s.
- Tag: `heavy` `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 98** · **Lv5 ≈ 137**.
- Hình ảnh: quanh Rider hiện mũi nón đỏ Pointer chĩa tới, trúng quái nổ sóng chấn động dẹt, in ký hiệu Φ đỏ lên quái (màu `#ff4040`); tiếng nạp *final_charge* + giọng `faiz_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Takumi:** Tôi không có ước mơ. Nhưng tôi có thể bảo vệ ước mơ của người khác.
> **{name}:** Tôi thì có. Tôi muốn tìm lại anh trai mình.
> **Takumi:** Vậy thì đừng có chết trước khi tìm được. Mã là 5-5-5.
> **Dẫn truyện:** 5... 5... 5... ENTER. Tinh thể tím vỡ tan. Sức mạnh của Faiz Driver đã trở về!

### 4.2 Axel Form  ·  _form đặc biệt, rơi ở màn 4-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 125 | 15 | 155 | ×1.05 | ×1.2 | 5 | 10/s | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Tăng tốc thời gian: quái chậm còn 15%, Faiz chạy và ra đòn nhanh ×1.6, mọi đòn mang tag `time`. Nộ tụt 10/giây (đầy thanh = 10 giây), HUD đếm ngược "AXEL n". Không có súng.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff594d`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `pointer` — mũi nón đỏ Pointer chĩa tới
- Dấu ấn trên quái khi Final trúng: `phi` — ký hiệu Φ đỏ

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.04 / 0.06 / 0.1 | 23 | (40, -10) | `time` | — |
| Đánh (đòn kết chuỗi) | 13 | 1 | 0.1 / 0.1 / 0.28 | 35 | (170, -60) | `heavy` `time` | — |
| **Final Attack** | 16 | 5 | 0.2 / 0.08 / 0.5 | 40 | (60, -20) | `time` | lao tới 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Accel Crimson Smash**

- lao tới 200 rồi tung đòn (tầm 40); 5 nhịp × 16 = 80 sát thương gốc; hất văng (60, -20); gây trúng chắc quái Fast (tag time).
- Đây là Final dạng tăng tốc thời gian: chuỗi 5 đòn lướt liên hoàn thay cho Final của kiểu đòn.
- Tag: `time` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 131** · **Lv5 ≈ 183**.
- Hình ảnh: quanh Rider hiện mũi nón đỏ Pointer chĩa tới, trúng quái nổ sóng chấn động dẹt, in ký hiệu Φ đỏ lên quái (màu `#ff594d`); tiếng nạp *final_charge* + giọng `faiz_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Takumi:** Start Up. Mười giây. Đừng phí giây nào.

### 4.3 Blaster Form  ·  _form đặc biệt, rơi ở màn 4-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 200 | 40 | 135 | ×0.95 | ×1.35 | 12 | 4/s | Brawler (tay chân) |

**Vũ khí:** Nút Bắn: **Faiz Blaster** — 10 sát thương/viên, hồi 0.5s, tốc độ 320, bay 1s, bán kính 5, đạn `ball` (viên đạn tròn), xuyên.

**Kỹ năng riêng:** Máu 200, giáp 40: form chiến đấu cuối. Faiz Blaster bắn đạn to, xuyên.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff3333`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `pointer` — mũi nón đỏ Pointer chĩa tới
- Dấu ấn trên quái khi Final trúng: `phi` — ký hiệu Φ đỏ

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.04 / 0.06 / 0.1 | 23 | (40, -10) | — | — |
| Đánh (đòn kết chuỗi) | 13 | 1 | 0.1 / 0.1 / 0.28 | 35 | (170, -60) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 29 | (260, -160) | `heavy` `stun` | lao tới 260, bật lên 140, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Crimson Smash**

- lao tới 260, bật lên 140 rồi tung đòn (tầm 29); 60 sát thương gốc; hất văng (260, -160); gây choáng 1.2s.
- Tag: `heavy` `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 110** · **Lv5 ≈ 154**.
- Hình ảnh: quanh Rider hiện mũi nón đỏ Pointer chĩa tới, trúng quái nổ sóng chấn động dẹt, in ký hiệu Φ đỏ lên quái (màu `#ff3333`); tiếng nạp *final_charge* + giọng `faiz_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Takumi:** Blaster Form. Nặng, chậm, nhưng Faiz Blaster bắn đạn xuyên. Giữ nút Bắn.

---

## 5. Kamen Rider Blade · 2004

- **Driver:** Blay Buckle · **Lối chơi:** Kiếm Blay Rouzer · lá bài Bích: tốc độ, sấm sét, đôi cánh · **Sức mạnh thế hệ:** ×1.48
- **Form gốc:** `ace`
- **Form rơi ở màn luyện tập:** 5-2 → **Mach Jaguar** · 5-3 → **Thunder Deer** · 5-4 → **Jack Form**
- **Thưởng theo cấp:** Lv1: Ace Form (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: King Form: Final Attack x1.5
- **Lv5 — King Form:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "King Form <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `cards` (hàng thẻ bài hologram)
- **Giọng đai / tiếng hô:** `final` "Kick. Thunder. Lightning Blast." · `henshin` "Turn up!" · `jack` "Absorb Queen. Fusion Jack." · `mach` "Mach." · `thunder` "Thunder."

### 5.1 Ace Form  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 28 | 128 | ×1.05 | ×1.1 | 8 | — | Blade (kiếm) |

**Vũ khí:** Vũ khí cầm sẵn trong hình (Blay Rouzer): nút Đánh chém luôn, **không có nút Chém**.

**Kỹ năng riêng:** Final Attack: thêm `shock`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#8cbfff`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `lightning` — tia sét gấp khúc
- Lúc tung Final (quanh Rider): `cards` — hàng thẻ bài hologram

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` `shock` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Lightning Blast** (Lv5: *King Form Lightning Blast*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100); gây điện lan 2 quái.
- Tag: `heavy` `shock` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 106** · **Lv5 ≈ 222** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hàng thẻ bài hologram, trúng quái nổ tia sét gấp khúc (màu `#8cbfff`); tiếng nạp *final_charge* + giọng `blade_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Lá Change Beetle trượt vào Blay Buckle. TURN UP! Tấm màn ánh sáng xanh dựng lên, {name} lao xuyên qua nó.
> **{name}:** Henshin!

### 5.2 Mach Jaguar  ·  _item, rơi ở màn 5-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 130 | 8 | 178 | ×1.3 | ×0.88 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Vũ khí cầm sẵn trong hình (Blay Rouzer): nút Đánh chém luôn, **không có nút Chém**.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#73f2d9`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `lightning` — tia sét gấp khúc
- Lúc tung Final (quanh Rider): `cards` — hàng thẻ bài hologram
- Để bóng mờ khi di chuyển (form tốc độ)

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Lightning Sonic** (Lv5: *King Form Lightning Sonic*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 59** · **Lv5 ≈ 123** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hàng thẻ bài hologram, trúng quái nổ tia sét gấp khúc (màu `#73f2d9`); tiếng nạp *final_charge* + giọng `blade_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kenzaki:** Mach Jaguar! Nhẹ và nhanh như báo, đâm liên tục từ xa hơn. Giáp mỏng lắm, đừng ham đỡ đòn.

### 5.3 Thunder Deer  ·  _item, rơi ở màn 5-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 15 | 118 | ×1 | ×1 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Vũ khí cầm sẵn trong hình (Blay Rouzer): nút Đánh chém luôn, **không có nút Chém**. Nút Bắn: **súng** — 7.5 sát thương/viên, hồi 0.42s, tốc độ 560, bay 0.45s, bán kính 3, đạn `bolt` (tia sét), xuyên, tag `shock`.

**Kỹ năng riêng:** Final Attack: thêm `shock`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#fff273`
- Đòn trúng: `lightning` — tia sét gấp khúc
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `lightning` — tia sét gấp khúc
- Lúc tung Final (quanh Rider): `cards` — hàng thẻ bài hologram

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` `shock` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Thunder Deer** (Lv5: *King Form Thunder Deer*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60); gây điện lan 2 quái.
- Tag: `ranged` `shock` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 74** · **Lv5 ≈ 155** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hàng thẻ bài hologram, trúng quái nổ tia sét gấp khúc (màu `#fff273`); tiếng nạp *final_charge* + giọng `blade_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kenzaki:** Thunder! Giữ nút Bắn là sét phóng từ mũi kiếm, xuyên cả hàng Undead và lan điện sang con bên cạnh. Tầm ngắn thôi.

### 5.4 Jack Form  ·  _form đặc biệt, rơi ở màn 5-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 170 | 35 | 132 | ×1.35 | ×1.25 | 11 | 4/s | Blade (kiếm) |

**Vũ khí:** Vũ khí cầm sẵn trong hình (Blay Rouzer): nút Đánh chém luôn, **không có nút Chém**.

**Kỹ năng riêng:** Final Attack: thêm `shock`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffcc4d`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `lightning` — tia sét gấp khúc
- Lúc tung Final (quanh Rider): `cards` — hàng thẻ bài hologram
- **Lượn**: giữ Nhảy khi đang rơi → rơi chậm tối đa 45, rắc lông vũ

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` `shock` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Lightning Slash** (Lv5: *King Form Lightning Slash*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100); gây điện lan 2 quái.
- Tag: `heavy` `shock` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 120** · **Lv5 ≈ 253** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hàng thẻ bài hologram, trúng quái nổ tia sét gấp khúc (màu `#ffcc4d`); tiếng nạp *final_charge* + giọng `blade_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kenzaki:** Jack Form! Giáp vàng, có cánh: giữ Nhảy khi rơi để lượn. Lightning Slash mang sét giật.

---

## 6. Kamen Rider Hibiki · 2005

- **Driver:** Henshin Onsa · **Lối chơi:** Âm thanh thanh tẩy · dùi trống lửa, trống lớn, lửa đỏ · **Sức mạnh thế hệ:** ×1.6
- **Form gốc:** `hibiki`
- **Form rơi ở màn luyện tập:** 6-2 → **Onibi** · 6-3 → **Kaentsuzumi** · 6-4 → **Hibiki Kurenai**
- **Thưởng theo cấp:** Lv1: Hibiki (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Armed Hibiki: Final Attack x1.5
- **Lv5 — Armed Hibiki:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Armed Hibiki <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** signature `taiko` (huy hiệu trống Ongeki + sóng âm)

### 6.1 Hibiki  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 25 | 128 | ×1.05 | ×1.05 | 8 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: 11 sát thương/nhịp, 6 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#bf80ff`
- Đòn trúng: `sound` — vòng sóng âm lan ra
- Final Attack trúng: `sound` — vòng sóng âm lan ra
- Dấu ấn trên quái khi Final trúng: `taiko` — huy hiệu trống Ongeki + sóng âm

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 11 | 6 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Kaen Renda no Kata** (Lv5: *Armed Hibiki Kaen Renda no Kata*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 6 nhịp × 11 = 66 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 111** · **Lv5 ≈ 233** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ vòng sóng âm lan ra, in huy hiệu trống Ongeki + sóng âm lên quái (màu `#bf80ff`); tiếng nạp *final_charge* + giọng `hibiki_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** {name} gõ Henshin Onsa rồi áp lên trán. Tiếng ngân lan ra, lửa tím bùng lên phủ kín người.
> **{name}:** Henshin!

### 6.2 Onibi  ·  _item, rơi ở màn 6-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 145 | 15 | 120 | ×1 | ×1 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **onibi** — 8 sát thương/viên, hồi 0.42s, tốc độ 330, bay 0.8s, bán kính 4.5, đạn `fire` (cầu lửa), tag `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff8033`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Final Attack trúng: `sound` — vòng sóng âm lan ra
- Dấu ấn trên quái khi Final trúng: `taiko` — huy hiệu trống Ongeki + sóng âm

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Rekka Dan** (Lv5: *Armed Hibiki Rekka Dan*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 80** · **Lv5 ≈ 168** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ vòng sóng âm lan ra, in huy hiệu trống Ongeki + sóng âm lên quái (màu `#ff8033`); tiếng nạp *final_charge* + giọng `hibiki_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Hidaka:** Onibi! Giữ nút Bắn, dùi trống phun cầu lửa Rekka Dan, quái trúng còn cháy thêm. Đừng để bị vây.

### 6.3 Kaentsuzumi  ·  _item, rơi ở màn 6-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 55 | 84 | ×0.85 | ×1.4 | 19 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Đánh (đòn kết chuỗi): thêm `stun`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffbf4d`
- Đòn trúng: `sound` — vòng sóng âm lan ra
- Final Attack trúng: `sound` — vòng sóng âm lan ra
- Dấu ấn trên quái khi Final trúng: `taiko` — huy hiệu trống Ongeki + sóng âm

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` `stun` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Bakuretsu Kyouda no Kata** (Lv5: *Armed Hibiki Bakuretsu Kyouda no Kata*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 157** · **Lv5 ≈ 329** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ vòng sóng âm lan ra, in huy hiệu trống Ongeki + sóng âm lên quái (màu `#ffbf4d`); tiếng nạp *final_charge* + giọng `hibiki_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Hidaka:** Kaentsuzumi! Gắn trống Ongeki lên quái: cú đánh kết làm nó choáng đứng im. Nặng tay, bước chậm.

### 6.4 Hibiki Kurenai  ·  _form đặc biệt, rơi ở màn 6-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 170 | 30 | 140 | ×1.1 | ×1.3 | 12 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **Ongekibo Rekka** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: thêm `burn`. Chém (nhát thường): thêm `burn`. Chém (nhát kết): thêm `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff4d40`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `sound` — vòng sóng âm lan ra
- Dấu ấn trên quái khi Final trúng: `taiko` — huy hiệu trống Ongeki + sóng âm

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | `burn` | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` `burn` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` `burn` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Shakunetsu Shinku no Kata** (Lv5: *Armed Hibiki Shakunetsu Shinku no Kata*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100); gây cháy 2s.
- Tag: `heavy` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 135** · **Lv5 ≈ 284** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ vòng sóng âm lan ra, in huy hiệu trống Ongeki + sóng âm lên quái (màu `#ff4d40`); tiếng nạp *final_charge* + giọng `hibiki_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Hidaka:** Kurenai! Cả người đỏ rực như than hồng. Bấm Chém để vung dùi Rekka thành kiếm lửa, đốt cháy quái.

---

## 7. Kamen Rider Kabuto · 2006

- **Driver:** Kabuto Zecter · **Lối chơi:** Thiên đạo · Hyper Form, Hyper Clock Up · **Sức mạnh thế hệ:** ×1.72
- **Form gốc:** `rider`
- **Form rơi ở màn luyện tập:** 7-4 → **Hyper Form** · (màn 7-2, 7-3 không rơi form)
- **Thưởng theo cấp:** Lv1: Rider Form (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Perfect Zecter: Final Attack x1.5
- **Lv5 — Perfect Zecter:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Perfect Zecter <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `tachyon` (hạt tachyon bắn ngược lên)
- **Giọng đai / tiếng hô:** `final` "One. Two. Three. Rider Kick." · `henshin` "Henshin. Change, Beetle." · `hyper` "Hyper Cast Off. Change, Hyper Beetle. Hyper Clock Up."

### 7.1 Rider Form  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 155 | 22 | 138 | ×1.1 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff5959`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `tachyon` — hạt tachyon bắn ngược lên
- Lúc tung Final (quanh Rider): `tachyon` — hạt tachyon bắn ngược lên

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Rider Kick** (Lv5: *Perfect Zecter Rider Kick*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 108** · **Lv5 ≈ 228** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hạt tachyon bắn ngược lên, trúng quái nổ hạt tachyon bắn ngược lên (màu `#ff5959`); tiếng nạp *final_charge* + giọng `kabuto_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Tinh thể tím vỡ tung. Kabuto Zecter vút qua không trung như một con bọ cánh cứng, đáp gọn vào tay {name}.
> **{name}:** Henshin!

### 7.2 Hyper Form  ·  _form đặc biệt, rơi ở màn 7-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 175 | 30 | 160 | ×1.25 | ×1.3 | 12 | 10/s | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** **Tăng tốc thời gian** (xem 0.5), chữ báo `HYPER CLOCK UP`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#d9e6ff`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `tachyon` — hạt tachyon bắn ngược lên
- Lúc tung Final (quanh Rider): `tachyon` — hạt tachyon bắn ngược lên
- Để bóng mờ khi di chuyển (form tốc độ)

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | `time` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` `time` | — |
| **Final Attack** | 16 | 5 | 0.2 / 0.08 / 0.5 | 40 | (60, -20) | `time` | lao tới 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Hyper Kick** (Lv5: *Perfect Zecter Hyper Kick*)

- lao tới 200 rồi tung đòn (tầm 40); 5 nhịp × 16 = 80 sát thương gốc; hất văng (60, -20); gây trúng chắc quái Fast (tag time).
- Đây là Final dạng tăng tốc thời gian: chuỗi 5 đòn lướt liên hoàn thay cho Final của kiểu đòn.
- Tag: `time` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 179** · **Lv5 ≈ 250** (Final tăng tốc thời gian **không** nhận ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hạt tachyon bắn ngược lên, trúng quái nổ hạt tachyon bắn ngược lên (màu `#d9e6ff`); tiếng nạp *final_charge* + giọng `kabuto_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Hyper Zecter vút xuống tay {name}. Hyper Cast Off! Bộ giáp đỏ dày lên, chiếc sừng vươn cao: Hyper Form.
> **Tendou:** Hyper Clock Up. Mọi thứ quanh cậu chậm lại, đòn của cậu trúng cả Worm đã lột xác. Nộ cạn thì về Rider Form, đừng phí.

---

## 8. Kamen Rider Den-O · 2007

- **Driver:** Den-O Belt · **Lối chơi:** Bốn Imagin · kiếm, cần câu, rìu, súng · **Sức mạnh thế hệ:** ×1.84
- **Form gốc:** `sword`
- **Form rơi ở màn luyện tập:** 8-2 → **Rod Form** · 8-3 → **Ax Form** · 8-4 → **Gun Form**
- **Thưởng theo cấp:** Lv1: Sword Form (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Climax Form: Final Attack x1.5
- **Lv5 — Climax Form:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Climax Form <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** signature `slash` (vệt chém hình cung)
- **Giọng đai / tiếng hô:** `ax` "Ax Form." · `final` "Full Charge." · `gun` "Gun Form." · `henshin` "Sword Form." · `rod` "Rod Form."

### 8.1 Sword Form  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 25 | 130 | ×1.05 | ×1.15 | 9 | — | Blade (kiếm) |

**Vũ khí:** Nút Chém: **DenGasher Sword** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: 34 sát thương/nhịp, 2 nhịp, vùng đánh 70×24, với tới 69.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff4d4d`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `slash` — vệt chém hình cung
- Dấu ấn trên quái khi Final trúng: `slash` — vệt chém hình cung

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 34 | 2 | 0.5 / 0.22 / 0.45 | 69 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Extreme Slash** (Lv5: *Climax Form Extreme Slash*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 69); 2 nhịp × 34 = 68 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 144** · **Lv5 ≈ 302** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ vệt chém hình cung, in vệt chém hình cung lên quái (màu `#ff4d4d`); tiếng nạp *final_charge* + giọng `den_o_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Rider Pass quẹt qua Den-O Belt. Một luồng cát đỏ lao thẳng vào người {name}: Momotaros nhập vào!
> **{name}:** Ore, sanjou! (Ta đây rồi!)

### 8.2 Rod Form  ·  _form đặc biệt, rơi ở màn 8-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 145 | 18 | 150 | ×1.15 | ×0.95 | 5 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Nút Chém: **DenGasher Rod** (3 nhát + nhát kết, bảng đòn lancer).

**Kỹ năng riêng:** Final Attack: thêm `stun`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#598cff`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Dấu ấn trên quái khi Final trúng: `slash` — vệt chém hình cung

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| Chém (nhát thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Chém (nhát kết) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | `stun` | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Solid Attack** (Lv5: *Climax Form Solid Attack*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120); gây choáng 1.2s.
- Tag: `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 79** · **Lv5 ≈ 165** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt, in vệt chém hình cung lên quái (màu `#598cff`); tiếng nạp *final_charge* + giọng `den_o_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Một giọng nói ngọt xớt vang lên: Urataros nhập vào! Rod Form chém bằng cần câu dài. Solid Attack quăng lưới trói quái.
> **{name}:** Muốn bị tôi câu không?

### 8.3 Ax Form  ·  _form đặc biệt, rơi ở màn 8-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 210 | 55 | 82 | ×0.85 | ×1.42 | 20 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Nút Chém: **DenGasher Axe** (2 nhát + nhát kết, bảng đòn heavy).

**Kỹ năng riêng:** Final Attack: lực đẩy (20, -340), thêm `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd94d`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Dấu ấn trên quái khi Final trúng: `slash` — vệt chém hình cung

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| Chém (nhát thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Chém (nhát kết) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (20, -340) | `heavy` `force` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết. Chuỗi nút Chém: 2 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Dynamic Chop** (Lv5: *Climax Form Dynamic Chop*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (20, -340); gây đẩy cưỡng bức.
- Tag: `heavy` `force` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 183** · **Lv5 ≈ 384** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt, in vệt chém hình cung lên quái (màu `#ffd94d`); tiếng nạp *final_charge* + giọng `den_o_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Tiếng bẻ cổ răng rắc: Kintaros nhập vào! Ax Form chậm, nhưng bổ rìu là giáp nào cũng vỡ, Dynamic Chop hất tung quái.
> **{name}:** Sức mạnh của ta khiến ngươi phải khóc! Nước mắt thì lau bằng cái này!

### 8.4 Gun Form  ·  _form đặc biệt, rơi ở màn 8-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 138 | 12 | 135 | ×1.1 | ×1 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **súng** — 6 sát thương/viên, hồi 0.22s, tốc độ 420, bay 0.9s, bán kính 3, đạn `ball` (viên đạn tròn).

**Kỹ năng riêng:** Final Attack: 18 sát thương/nhịp, 3 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#b366ff`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Dấu ấn trên quái khi Final trúng: `slash` — vệt chém hình cung

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 18 | 3 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Wild Shot** (Lv5: *Climax Form Wild Shot*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 3 nhịp × 18 = 54 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 99** · **Lv5 ≈ 209** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt, in vệt chém hình cung lên quái (màu `#b366ff`); tiếng nạp *final_charge* + giọng `den_o_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** {name} nhún nhảy theo điệu nhạc không ai nghe thấy: Ryutaros nhập vào! Giữ nút Bắn để bắn liên thanh. Giáp mỏng.
> **{name}:** Hạ ngươi được chứ? Ta không nghe trả lời đâu!

---

## 9. Kamen Rider Kiva · 2008

- **Driver:** Kivat-bat III · **Lối chơi:** Arms Monster · kiếm sói, súng nước, búa khổng lồ · **Sức mạnh thế hệ:** ×1.96
- **Form gốc:** `kiva`
- **Form rơi ở màn luyện tập:** 9-2 → **Garulu Form** · 9-3 → **Basshaa Form** · 9-4 → **Dogga Form**
- **Thưởng theo cấp:** Lv1: Kiva Form (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Emperor Form: Final Attack x1.5
- **Lv5 — Emperor Form:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Emperor Form <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `moon` (trăng lưỡi liềm sau lưng)
- **Giọng đai / tiếng hô:** `basshaa` "Basshaa Magnum!" · `dogga` "Dogga Hammer!" · `final` "Wake up!" · `garulu` "Garulu Saber!" · `henshin` "Gabu!"

### 9.1 Kiva Form  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 22 | 135 | ×1.15 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: thêm `stun`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff4d59`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `moon` — trăng lưỡi liềm sau lưng

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` `stun` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Darkness Moon Break** (Lv5: *Emperor Form Darkness Moon Break*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160); gây choáng 1.2s.
- Tag: `heavy` `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 123** · **Lv5 ≈ 259** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện trăng lưỡi liềm sau lưng, trúng quái nổ sóng chấn động dẹt (màu `#ff4d59`); tiếng nạp *final_charge* + giọng `kiva_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kivat:** Phù, ngủ đã đời! Ơ, người mới à? Không sao hết! Kivatte ikuze!
> **Dẫn truyện:** Kivat cắn vào tay {name}. Hoa văn đỏ như kính màu lan trên da, xích bạc quấn quanh eo.
> **{name}:** Henshin!

### 9.2 Garulu Form  ·  _form đặc biệt, rơi ở màn 9-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 15 | 160 | ×1.2 | ×1.2 | 8 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **Garulu Saber** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: 34 sát thương/nhịp, 2 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#668cff`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `wind` — vệt gió xoáy
- Lúc tung Final (quanh Rider): `moon` — trăng lưỡi liềm sau lưng

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 34 | 2 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Garulu Howling Slash** (Lv5: *Emperor Form Garulu Howling Slash*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 2 nhịp × 34 = 68 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 160** · **Lv5 ≈ 336** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện trăng lưỡi liềm sau lưng, trúng quái nổ vệt gió xoáy (màu `#668cff`); tiếng nạp *final_charge* + giọng `kiva_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kivat:** Garulu Saber! Xanh như trăng đêm. Bấm Chém để vung kiếm sói: nhanh, ba nhát rồi phá giáp.

### 9.3 Basshaa Form  ·  _form đặc biệt, rơi ở màn 9-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 145 | 20 | 115 | ×1 | ×1 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **basshaa_magnum** — 6.5 sát thương/viên, hồi 0.28s, tốc độ 400, bay 1s, bán kính 3, đạn `ball` (viên đạn tròn).

**Kỹ năng riêng:** Final Attack: lực đẩy (-220, -40) — **hút về**, thêm `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#4de6b3`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `wind` — vệt gió xoáy
- Lúc tung Final (quanh Rider): `moon` — trăng lưỡi liềm sau lưng

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (-220, -40) | `ranged` `force` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Basshaa Aqua Tornado** (Lv5: *Emperor Form Basshaa Aqua Tornado*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hút quái về phía Rider (-220, -40); gây đẩy cưỡng bức.
- Tag: `ranged` `force` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 98** · **Lv5 ≈ 206** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện trăng lưỡi liềm sau lưng, trúng quái nổ vệt gió xoáy (màu `#4de6b3`); tiếng nạp *final_charge* + giọng `kiva_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kivat:** Basshaa Magnum! Giữ nút Bắn để bắn đạn nước. Aqua Tornado hút quái về phía cậu. Giáp mỏng đó nha!

### 9.4 Dogga Form  ·  _form đặc biệt, rơi ở màn 9-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 215 | 60 | 78 | ×0.8 | ×1.45 | 21 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Nút Chém: **Dogga Hammer** (2 nhát + nhát kết, bảng đòn heavy).

**Kỹ năng riêng:** Final Attack: thêm `stun` `shock`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#a666e6`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Final Attack trúng: `lightning` — tia sét gấp khúc
- Lúc tung Final (quanh Rider): `moon` — trăng lưỡi liềm sau lưng

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| Chém (nhát thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Chém (nhát kết) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` `stun` `shock` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết. Chuỗi nút Chém: 2 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Dogga Thunder Slap** (Lv5: *Emperor Form Dogga Thunder Slap*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160); gây choáng 1.2s, điện lan 2 quái.
- Tag: `heavy` `stun` `shock` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 199** · **Lv5 ≈ 418** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện trăng lưỡi liềm sau lưng, trúng quái nổ tia sét gấp khúc (màu `#a666e6`); tiếng nạp *final_charge* + giọng `kiva_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kivat:** Dogga Hammer! Bấm Chém để vung búa to như cánh cửa. Thunder Slap giật điện, quái đứng hình luôn!

---

## 10. Kamen Rider Decade · 2009

- **Driver:** Decadriver · **Lối chơi:** Đổi thẻ · kiếm nhân bóng, súng chùm, Clock Up · **Sức mạnh thế hệ:** ×2.08
- **Form gốc:** `decade`
- **Form rơi ở màn luyện tập:** 10-2 → **Attack Ride: Slash** · 10-3 → **Attack Ride: Blast** · 10-4 → **Kamen Ride: Kabuto**
- **Thưởng theo cấp:** Lv1: Decade (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Complete Form: Final Attack x1.5
- **Lv5 — Complete Form:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Complete Form <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `cards` (hàng thẻ bài hologram)
- **Giọng đai / tiếng hô:** `blast` "Attack Ride. Blast!" · `final` "Final Attack Ride. De. De. De. Decade!" · `henshin` "Kamen Ride. Decade!" · `kabuto` "Kamen Ride. Kabuto! Attack Ride. Clock Up!" · `slash` "Attack Ride. Slash!"

### 10.1 Decade  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.05 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: 22 sát thương/nhịp, 3 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `cards` — hàng thẻ bài hologram

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 22 | 3 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Dimension Kick** (Lv5: *Complete Form Dimension Kick*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 3 nhịp × 22 = 66 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 144** · **Lv5 ≈ 303** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hàng thẻ bài hologram, trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `decade_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **{name}:** Henshin!
> **Dẫn truyện:** KAMEN RIDE: DECADE! Những tấm bảng ảo cắm vào mặt nạ, bộ giáp xám bừng lên màu hồng đỏ.

### 10.2 Attack Ride: Slash  ·  _form đặc biệt, rơi ở màn 10-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 28 | 120 | ×1 | ×1.25 | 11 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Chém (nhát thường): 3.5 sát thương/nhịp, 2 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `cards` — hàng thẻ bài hologram

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 3.5 | 2 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Dimension Slash** (Lv5: *Complete Form Dimension Slash*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 169** · **Lv5 ≈ 355** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hàng thẻ bài hologram, trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `decade_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Tsukasa:** ATTACK RIDE: SLASH! Bấm Chém, Ride Booker một nhát thành hai. Nhát cuối phá được giáp.

### 10.3 Attack Ride: Blast  ·  _form đặc biệt, rơi ở màn 10-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 12 | 120 | ×1 | ×0.9 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **booker_gun** — 3.5 sát thương/viên, hồi 0.4s, tốc độ 380, bay 0.8s, bán kính 3, đạn `ball` (viên đạn tròn), 3 viên xòe 0.12 rad.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `cards` — hàng thẻ bài hologram

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Dimension Blast** (Lv5: *Complete Form Dimension Blast*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 94** · **Lv5 ≈ 197** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hàng thẻ bài hologram, trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `decade_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Tsukasa:** ATTACK RIDE: BLAST! Giữ nút Bắn, Ride Booker hóa súng bắn cả chùm đạn. Giáp mỏng đi, đừng để chúng áp sát.

### 10.4 Kamen Ride: Kabuto  ·  _form đặc biệt, rơi ở màn 10-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 130 | 10 | 165 | ×1.2 | ×0.95 | 4 | 10/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** **Tăng tốc thời gian** (xem 0.5), chữ báo `CLOCK UP`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `cards` — hàng thẻ bài hologram

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | `time` | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | `time` | — |
| **Final Attack** | 16 | 5 | 0.2 / 0.08 / 0.5 | 40 | (60, -20) | `time` | lao tới 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Rider Kick** (Lv5: *Complete Form Rider Kick*)

- lao tới 200 rồi tung đòn (tầm 40); 5 nhịp × 16 = 80 sát thương gốc; hất văng (60, -20); gây trúng chắc quái Fast (tag time).
- Đây là Final dạng tăng tốc thời gian: chuỗi 5 đòn lướt liên hoàn thay cho Final của kiểu đòn.
- Tag: `time` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 158** · **Lv5 ≈ 221** (Final tăng tốc thời gian **không** nhận ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện hàng thẻ bài hologram, trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `decade_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Tsukasa:** KAMEN RIDE: KABUTO! ATTACK RIDE: CLOCK UP! Mọi thứ chậm lại quanh cậu, nhưng nộ tụt rất nhanh.

---

## 11. Kamen Rider W · 2009

- **Driver:** Double Driver · **Lối chơi:** Nhảy cao, ghép 2 nửa linh hoạt · **Sức mạnh thế hệ:** ×2.2
- **Form gốc:** `cyclone_joker`
- **Form rơi ở màn luyện tập:** 11-2 → **Memory Heat & Metal** · 11-3 → **Memory Luna & Trigger** · 11-4 → **Xtreme Memory**
- **Thưởng theo cấp:** Lv1: CycloneJoker (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: Best Match: sát thương +15% → Lv5: sát thương +40%, máu +32%
- **Ghép 2 nửa:** Soul (trái, đổi bằng L): Cyclone → Heat → Luna → Xtreme. Body (phải, giữ W + L): Joker → Metal → Trigger. Memory nhặt được mở nửa thứ i của *cả* Soul lẫn Body (11-2 HeatMetal mở Heat + Metal, 11-3 LunaTrigger mở Luna + Trigger). Mọi tổ hợp khác CycloneJoker là form đặc biệt (tốn nộ). Đổi Memory hồi chiêu 0.6s (Rider khác 1s).
- **Soul quyết định hiệu ứng:** Cyclone chạy 145 (khác 125) + lực đẩy ×1.5 · Heat sức đánh ×1.2 + mọi đòn gây cháy · Luna vùng đánh dài ×1.5. **Body quyết định vũ khí:** Joker tay chân · Metal gậy Metal Shaft (nút Chém, giáp 45, trụ 12) · Trigger súng Trigger Magnum (nút Bắn). W nhảy ×1.2 ở mọi tổ hợp.
- **Lv4 Best Match** (CycloneJoker, HeatMetal, LunaTrigger): +15% sát thương mọi đòn. Không có thưởng Lv5 riêng cho Final.
- **Giọng đai / tiếng hô:** `cyclone_metal` "Cyclone! Metal!" · `cyclone_trigger` "Cyclone! Trigger!" · `final` "Maximum Drive!" · `heat_joker` "Heat! Joker!" · `heat_metal` "Heat! Metal!" · `heat_trigger` "Heat! Trigger!" · `henshin` "Cyclone! Joker!" · `luna_joker` "Luna! Joker!" · `luna_metal` "Luna! Metal!" · `luna_trigger` "Luna! Trigger!" · `xtreme` "Xtreme!"

### 11.1 CycloneJoker  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 20 | 145 | ×1.2 | ×1 | 6 | — | brawler (Joker) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Cyclone: lực đẩy mọi đòn ×1.5. **Best Match** từ Lv4: +15% sát thương.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#66ff80`
- Đòn trúng: `wind` — vệt gió xoáy
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 23 | (75, -30) | `wind` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (270, -105) | `heavy` `wind` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.25 / 0.4 | 30 | (390, -240) | `heavy` `wind` | lao tới 240, bật lên 140, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Joker Extreme**

- lao tới 240, bật lên 140 rồi tung đòn (tầm 30); 65 sát thương gốc; hất văng (390, -240).
- Tag: `heavy` `wind` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 143** · **Lv5 ≈ 230** (đã gồm Best Match +15%).
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#66ff80`); tiếng nạp *final_charge* + giọng `double_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shotaro:** Rider không bao giờ chiến đấu một mình, kể cả khi trông có vẻ như vậy.
> **{name}:** Nhưng tôi đâu có cộng sự...
> **Pen:** ...Có đấy. Để tôi lo nửa bên trái.
> **Dẫn truyện:** Cyclone! Joker! Hai người, một Rider: Kamen Rider W!

### 11.2 CycloneMetal  ·  _form đặc biệt, tổ hợp_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 45 | 145 | ×1.2 | ×1 | 12 | 4/s | Joker tay + gậy Metal (heavy) |

**Vũ khí:** Nút Chém: **Metal Shaft** (2 nhát + nhát kết, bảng đòn heavy).

**Kỹ năng riêng:** Cyclone: lực đẩy mọi đòn ×1.5.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#66ff80`
- Đòn trúng: `wind` — vệt gió xoáy
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 23 | (75, -30) | `wind` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (270, -105) | `heavy` `wind` | — |
| Chém (nhát thường) | 7 | 1 | 0.1 / 0.1 / 0.25 | 39 | (90, -30) | `heavy` `wind` | — |
| Chém (nhát kết) | 16 | 1 | 0.2 / 0.12 / 0.4 | 43 | (345, -135) | `heavy` `wind` | — |
| **Final Attack** | 70 | 1 | 0.5 / 0.2 / 0.45 | 44 | (450, -225) | `heavy` `wind` | lao tới 160, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 2 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Metal Branding**

- lao tới 160, bật lên 60 rồi tung đòn (tầm 44); 70 sát thương gốc; hất văng (450, -225).
- Tag: `heavy` `wind` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 154** · **Lv5 ≈ 216**.
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#66ff80`); tiếng nạp *final_charge* + giọng `double_final`.

### 11.3 CycloneTrigger  ·  _form đặc biệt, tổ hợp_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 20 | 145 | ×1.2 | ×1 | 6 | 4/s | Joker tay + súng Trigger |

**Vũ khí:** Nút Bắn: **Trigger Magnum** — 4 sát thương/viên, hồi 0.13s, tốc độ 380, bay 1.2s, bán kính 3, đạn `ball` (viên đạn tròn).

**Kỹ năng riêng:** Cyclone: lực đẩy mọi đòn ×1.5.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#66ff80`
- Đòn trúng: `wind` — vệt gió xoáy
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 23 | (75, -30) | `wind` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (270, -105) | `heavy` `wind` | — |
| **Final Attack** | 12 | 6 | 0.4 / 0.06 / 0.4 | 180 | (90, -15) | `ranged` `wind` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Trigger Full Burst**

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 6 nhịp × 12 = 72 sát thương gốc; hất văng (90, -15).
- Tag: `ranged` `wind` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 158** · **Lv5 ≈ 222**.
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#66ff80`); tiếng nạp *final_charge* + giọng `double_final`.

### 11.4 HeatJoker  ·  _form đặc biệt, tổ hợp_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 20 | 125 | ×1.2 | ×1.2 | 6 | 4/s | brawler (Joker) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Heat: mọi đòn gây cháy (`burn`).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff6640`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 23 | (50, -20) | `fire` `burn` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` `fire` `burn` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` `fire` `burn` | lao tới 240, bật lên 140, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Joker Extreme**

- lao tới 240, bật lên 140 rồi tung đòn (tầm 30); 65 sát thương gốc; hất văng (260, -160); gây cháy 2s.
- Tag: `heavy` `fire` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 172** · **Lv5 ≈ 240**.
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#ff6640`); tiếng nạp *final_charge* + giọng `double_final`.

### 11.5 HeatMetal  ·  _form đặc biệt, rơi ở màn 11-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 45 | 125 | ×1.2 | ×1.2 | 12 | 4/s | Joker tay + gậy Metal (heavy) |

**Vũ khí:** Nút Chém: **Metal Shaft** (2 nhát + nhát kết, bảng đòn heavy).

**Kỹ năng riêng:** Heat: mọi đòn gây cháy (`burn`). **Best Match** từ Lv4: +15% sát thương.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff6640`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 23 | (50, -20) | `fire` `burn` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` `fire` `burn` | — |
| Chém (nhát thường) | 7 | 1 | 0.1 / 0.1 / 0.25 | 39 | (60, -20) | `heavy` `fire` `burn` | — |
| Chém (nhát kết) | 16 | 1 | 0.2 / 0.12 / 0.4 | 43 | (230, -90) | `heavy` `fire` `burn` | — |
| **Final Attack** | 70 | 1 | 0.5 / 0.2 / 0.45 | 44 | (300, -150) | `heavy` `fire` `burn` | lao tới 160, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 2 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Metal Branding**

- lao tới 160, bật lên 60 rồi tung đòn (tầm 44); 70 sát thương gốc; hất văng (300, -150); gây cháy 2s.
- Tag: `heavy` `fire` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 185** · **Lv5 ≈ 298** (đã gồm Best Match +15%).
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#ff6640`); tiếng nạp *final_charge* + giọng `double_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Pen:** Heat và Metal! Heat làm đòn nào cũng bốc lửa. Metal cầm gậy Metal Shaft: bấm Chém để quật.

### 11.6 HeatTrigger  ·  _form đặc biệt, tổ hợp_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 20 | 125 | ×1.2 | ×1.2 | 6 | 4/s | Joker tay + súng Trigger |

**Vũ khí:** Nút Bắn: **Trigger Magnum** — 5 sát thương/viên, hồi 0.13s, tốc độ 380, bay 1.2s, bán kính 3, đạn `ball` (viên đạn tròn).

**Kỹ năng riêng:** Heat: mọi đòn gây cháy (`burn`).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff6640`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 23 | (50, -20) | `fire` `burn` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` `fire` `burn` | — |
| **Final Attack** | 12 | 6 | 0.4 / 0.06 / 0.4 | 180 | (60, -10) | `ranged` `fire` `burn` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Trigger Full Burst**

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 6 nhịp × 12 = 72 sát thương gốc; hất văng (60, -10); gây cháy 2s.
- Tag: `ranged` `fire` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 190** · **Lv5 ≈ 266**.
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#ff6640`); tiếng nạp *final_charge* + giọng `double_final`.

### 11.7 LunaJoker  ·  _form đặc biệt, tổ hợp_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 20 | 125 | ×1.2 | ×1 | 6 | 4/s | brawler (Joker) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Luna: vùng đánh dài ×1.5 (đẩy tâm vùng đánh ra trước).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffe659`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 32 | (50, -20) | `luna` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 38 | (180, -70) | `heavy` `luna` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.25 / 0.4 | 44 | (260, -160) | `heavy` `luna` | lao tới 240, bật lên 140, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Joker Extreme**

- lao tới 240, bật lên 140 rồi tung đòn (tầm 44); 65 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` `luna` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 143** · **Lv5 ≈ 200**.
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#ffe659`); tiếng nạp *final_charge* + giọng `double_final`.

### 11.8 LunaMetal  ·  _form đặc biệt, tổ hợp_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 45 | 125 | ×1.2 | ×1 | 12 | 4/s | Joker tay + gậy Metal (heavy) |

**Vũ khí:** Nút Chém: **Metal Shaft** (2 nhát + nhát kết, bảng đòn heavy).

**Kỹ năng riêng:** Luna: vùng đánh dài ×1.5 (đẩy tâm vùng đánh ra trước).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffe659`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 32 | (50, -20) | `luna` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 38 | (180, -70) | `heavy` `luna` | — |
| Chém (nhát thường) | 7 | 1 | 0.1 / 0.1 / 0.25 | 56 | (60, -20) | `heavy` `luna` | — |
| Chém (nhát kết) | 16 | 1 | 0.2 / 0.12 / 0.4 | 62 | (230, -90) | `heavy` `luna` | — |
| **Final Attack** | 70 | 1 | 0.5 / 0.2 / 0.45 | 64 | (300, -150) | `heavy` `luna` | lao tới 160, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 2 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Metal Branding**

- lao tới 160, bật lên 60 rồi tung đòn (tầm 64); 70 sát thương gốc; hất văng (300, -150).
- Tag: `heavy` `luna` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 154** · **Lv5 ≈ 216**.
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#ffe659`); tiếng nạp *final_charge* + giọng `double_final`.

### 11.9 LunaTrigger  ·  _form đặc biệt, rơi ở màn 11-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 20 | 125 | ×1.2 | ×1 | 6 | 4/s | Joker tay + súng Trigger |

**Vũ khí:** Nút Bắn: **Trigger Magnum** — 4 sát thương/viên, hồi 0.13s, tốc độ 380, bay 1.2s, bán kính 3, đạn `ball` (viên đạn tròn), 3 viên xòe 0.22 rad.

**Kỹ năng riêng:** Luna: vùng đánh dài ×1.5 (đẩy tâm vùng đánh ra trước). **Best Match** từ Lv4: +15% sát thương.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffe659`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 32 | (50, -20) | `luna` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 38 | (180, -70) | `heavy` `luna` | — |
| **Final Attack** | 12 | 6 | 0.4 / 0.06 / 0.4 | 265 | (60, -10) | `ranged` `luna` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Trigger Full Burst**

- phát bắn tầm xa (vùng trúng dài 255, chạm tới 265 trước mặt); 6 nhịp × 12 = 72 sát thương gốc; hất văng (60, -10).
- Tag: `ranged` `luna` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 158** · **Lv5 ≈ 255** (đã gồm Best Match +15%).
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#ffe659`); tiếng nạp *final_charge* + giọng `double_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Pen:** Luna và Trigger! Đủ cả 9 tổ hợp rồi. Trigger cầm Trigger Magnum: giữ nút Bắn.

### 11.10 CycloneJokerXtreme  ·  _form đặc biệt, rơi ở màn 11-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 190 | 20 | 145 | ×1.2 | ×1.2 | 6 | 4/s | brawler (Joker) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** CycloneJokerXtreme: máu 190, sức đánh ×1.2, giữ tốc độ Cyclone. Không có nút Chém / Bắn. Cyclone: lực đẩy mọi đòn ×1.5.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#66ff80`
- Đòn trúng: `wind` — vệt gió xoáy
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `wind` — vệt gió xoáy

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.11 | 23 | (75, -30) | `wind` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (270, -105) | `heavy` `wind` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.25 / 0.4 | 30 | (390, -240) | `heavy` `wind` | lao tới 240, bật lên 140, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Xtreme Golden Extreme**

- lao tới 240, bật lên 140 rồi tung đòn (tầm 30); 65 sát thương gốc; hất văng (390, -240).
- Tag: `heavy` `wind` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 172** · **Lv5 ≈ 240**.
- Hình ảnh: quanh Rider hiện vệt gió xoáy, trúng quái nổ sóng chấn động dẹt (màu `#66ff80`); tiếng nạp *final_charge* + giọng `double_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Philip:** Tín hiệu... bắt được rồi. Xtreme Memory, gửi tới các cậu đây.
> **Shotaro:** Philip!

---

## 12. Kamen Rider OOO · 2010

- **Driver:** OOO Driver · **Lối chơi:** Đổi Medal · 8 combo, mỗi bộ ba một kỹ năng: choáng, điện, lửa, trọng lực, băng, khiên · **Sức mạnh thế hệ:** ×2.32
- **Form gốc:** `tatoba`
- **Form rơi ở màn luyện tập:** 12-2 → **LaTorarTar Combo** · 12-3 → **GataKiriBa Combo** · 12-4 → **ShaUTa Combo** · 12-5 → **TaJaDor Combo** · 12-6 → **SaGohZo Combo** · 12-7 → **PuToTyra Combo** · 12-8 → **BuraKaWani Combo**
- **Thưởng theo cấp:** Lv1: TaToBa Combo (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Super TaToBa: Final Attack x1.5
- **Lv5 — Super TaToBa:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Super TaToBa <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `rings3` (ba vòng Medal đỏ / vàng / lục)
- **Giọng đai / tiếng hô:** `burakawani` "Cobra! Kame! Wani! Bura-ka-wani!" · `final` "Scanning Charge!" · `gatakiriba` "Kuwagata! Kamakiri! Batta! Gata-gata-kiriba! Gata-kiriba!" · `henshin` "Taka! Tora! Batta! Ta-To-Ba! Ta-To-Ba! Ta-To-Ba!" · `latorartar` "Lion! Tora! Cheetah! La-Tora-Tah! La-Tora-Tah!" · `putotyra` "Ptera! Tricera! Tyranno! Pu-To-Tyranno-saurus!" · `sagohzo` "Sai! Gorilla! Zou! Sa-Go-Zo! Sa-Go-Zo!" · `shauta` "Shachi! Unagi! Tako! Sha-Sha-Shauta! Sha-Sha-Shauta!" · `tajador` "Taka! Kujaku! Condor! Ta-Ja-Dor!"

### 12.1 TaToBa Combo  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.2 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: 24 sát thương/nhịp, 3 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff664d`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `rings3` — ba vòng Medal đỏ / vàng / lục

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 24 | 3 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Tatoba Kick** (Lv5: *Super TaToBa Tatoba Kick*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 3 nhịp × 24 = 72 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 175** · **Lv5 ≈ 368** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện ba vòng Medal đỏ / vàng / lục, trúng quái nổ sóng chấn động dẹt (màu `#ff664d`); tiếng nạp *final_charge* + giọng `ooo_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **{name}:** Henshin!
> **Dẫn truyện:** O Scanner lướt qua ba Medal. TAKA! TORA! BATTA! Ta-To-Ba, TaToBa, Ta-To-Ba!
> **Eiji:** Bài hát đó thì cứ kệ nó. Lần nào biến thân nó cũng tự hát.

### 12.2 LaTorarTar Combo  ·  _form đặc biệt, rơi ở màn 12-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 130 | 10 | 182 | ×1.25 | ×0.95 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: 26 sát thương/nhịp, 2 nhịp, lướt (320, -40). Đánh (đòn kết chuỗi): 6 sát thương/nhịp, lực đẩy (20, -10), vùng đánh 90×50, với tới 45, thêm `stun`. Đánh (đòn thường): 2.5 sát thương/nhịp, 2 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd940`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `slash` — vệt chém hình cung
- Lúc tung Final (quanh Rider): `rings3` — ba vòng Medal đỏ / vàng / lục
- Để bóng mờ khi di chuyển (form tốc độ)

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 2.5 | 2 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 6 | 1 | 0.1 / 0.12 / 0.25 | 45 | (20, -10) | `stun` | — |
| **Final Attack** | 26 | 2 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 320, bật lên 40, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Gush Cross** (Lv5: *Super TaToBa Gush Cross*)

- lao tới 320, bật lên 40 rồi tung đòn (tầm 44); 2 nhịp × 26 = 52 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 115** · **Lv5 ≈ 241** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện ba vòng Medal đỏ / vàng / lục, trúng quái nổ vệt chém hình cung (màu `#ffd940`); tiếng nạp *final_charge* + giọng `ooo_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Eiji:** LION! TORA! CHEETAH! LaTorarTar! Chạy như gió, vuốt cào đôi. Cú kết chuỗi lóe sáng Lionde làm quái quanh mình choáng.

### 12.3 GataKiriBa Combo  ·  _form đặc biệt, rơi ở màn 12-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 148 | 18 | 148 | ×1.38 | ×1.08 | 7 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Mọi đòn mang thêm `shock` (điện lan 2 quái). Final Attack: 13 sát thương/nhịp, 6 nhịp, lướt (200, -260), vùng đánh 130×40, với tới 95.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#73ff66`
- Đòn trúng: `lightning` — tia sét gấp khúc
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `lightning` — tia sét gấp khúc
- Lúc tung Final (quanh Rider): `rings3` — ba vòng Medal đỏ / vàng / lục

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | `shock` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` `shock` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | `shock` | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` `shock` | — |
| **Final Attack** | 13 | 6 | 0.5 / 0.22 / 0.45 | 95 | (260, -100) | `heavy` `shock` | lao tới 200, bật lên 260, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Gatakiriba Kick** (Lv5: *Super TaToBa Gatakiriba Kick*)

- lao tới 200, bật lên 260 rồi tung đòn (tầm 95); 6 nhịp × 13 = 78 sát thương gốc; hất văng (260, -100); gây điện lan 2 quái.
- Tag: `heavy` `shock` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 195** · **Lv5 ≈ 410** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện ba vòng Medal đỏ / vàng / lục, trúng quái nổ tia sét gấp khúc (màu `#73ff66`); tiếng nạp *final_charge* + giọng `ooo_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Eiji:** KUWAGATA! KAMAKIRI! BATTA! GataKiriBa! Sừng Kuwagata phóng điện lan sang quái gần. Final tung cả bầy phân thân.

### 12.4 ShaUTa Combo  ·  _form đặc biệt, rơi ở màn 12-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 15 | 135 | ×1.15 | ×0.95 | 5 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn lancer).

**Kỹ năng riêng:** Final Attack: 10 sát thương/nhịp, 5 nhịp, lướt (220, -160). Chém (nhát thường): vùng đánh 52×10, với tới 58, thêm `shock`. Chém (nhát kết): lực đẩy (-180, -30) — **hút về**, vùng đánh 60×12, với tới 66, thêm `shock` `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#5999ff`
- Đòn trúng: `lightning` — tia sét gấp khúc
- Vệt vung đòn: `wind` — vệt gió xoáy
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `rings3` — ba vòng Medal đỏ / vàng / lục

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| Chém (nhát thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 58 | (40, -20) | `shock` | — |
| Chém (nhát kết) | 10 | 1 | 0.1 / 0.12 / 0.25 | 66 | (-180, -30) | `shock` `force` | — |
| **Final Attack** | 10 | 5 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 220, bật lên 160, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Octo Banish** (Lv5: *Super TaToBa Octo Banish*)

- lao tới 220, bật lên 160 rồi tung đòn (tầm 44); 5 nhịp × 10 = 50 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 110** · **Lv5 ≈ 231** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện ba vòng Medal đỏ / vàng / lục, trúng quái nổ sóng chấn động dẹt (màu `#5999ff`); tiếng nạp *final_charge* + giọng `ooo_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Eiji:** SHACHI! UNAGI! TAKO! ShaUTa! Roi điện Unagi quất xa, điện lan. Cú kết chuỗi quấn roi kéo quái về phía mình.

### 12.5 TaJaDor Combo  ·  _form đặc biệt, rơi ở màn 12-5_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 25 | 138 | ×1.3 | ×1.15 | 8 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **súng** — 6 sát thương/viên, hồi 0.32s, tốc độ 360, bay 0.8s, bán kính 4, đạn `fire` (cầu lửa), tag `burn`.

**Kỹ năng riêng:** Mọi đòn mang thêm `burn` (cháy 2s).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff7333`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Lúc tung Final (quanh Rider): `rings3` — ba vòng Medal đỏ / vàng / lục
- **Lượn**: giữ Nhảy khi đang rơi → rơi chậm tối đa 45, rắc lông vũ

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | `burn` | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` `burn` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` `burn` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Magna Blaze** (Lv5: *Super TaToBa Magna Blaze*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60); gây cháy 2s.
- Tag: `ranged` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 133** · **Lv5 ≈ 280** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện ba vòng Medal đỏ / vàng / lục, trúng quái nổ lửa bùng bốc lên (màu `#ff7333`); tiếng nạp *final_charge* + giọng `ooo_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** TAKA! KUJAKU! CONDOR! Ta~Ja~Dor~!
> **Eiji:** TaJaDor bay lượn được: giữ Nhảy khi rơi. Taja Spinner bắn lửa, quái trúng còn cháy thêm một lúc.

### 12.6 SaGohZo Combo  ·  _form đặc biệt, rơi ở màn 12-6_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 212 | 60 | 80 | ×0.8 | ×1.42 | 21 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Nút Bắn: **súng** — 14 sát thương/viên, hồi 1.1s, tốc độ 260, bay 0.9s, bán kính 5, đạn `ball` (viên đạn tròn), xuyên.

**Kỹ năng riêng:** Final Attack: 55 sát thương/nhịp, lực đẩy (-240, -60) — **hút về**, vùng đánh 260×90, với tới 130, thêm `force` `stun`. Đánh (đòn kết chuỗi): lực đẩy (10, -320), vùng đánh 140×18, với tới 70, thêm `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ccccd9`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `rings3` — ba vòng Medal đỏ / vàng / lục

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 70 | (10, -320) | `heavy` `force` | — |
| **Final Attack** | 55 | 1 | 0.55 / 0.2 / 0.5 | 130 | (-240, -60) | `heavy` `force` `stun` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Sagohzo Impact** (Lv5: *Super TaToBa Sagohzo Impact*)

- đứng tại chỗ tung đòn (tầm 130); 55 sát thương gốc; hút quái về phía Rider (-240, -60); gây đẩy cưỡng bức, choáng 1.2s.
- Tag: `heavy` `force` `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 181** · **Lv5 ≈ 381** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện ba vòng Medal đỏ / vàng / lục, trúng quái nổ sóng chấn động dẹt (màu `#ccccd9`); tiếng nạp *final_charge* + giọng `ooo_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Eiji:** SAI! GORILLA! ZOU! SaGohZo! Bắn nắm đấm Gorilla, dậm chân Zou hất tung quái. Final hút mọi quái về bằng trọng lực.

### 12.7 PuToTyra Combo  ·  _form đặc biệt, rơi ở màn 12-7_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 190 | 38 | 108 | ×1.1 | ×1.48 | 18 | 6.5/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (2 nhát + nhát kết, bảng đòn heavy).

**Kỹ năng riêng:** Nộ tụt 6.5/giây (thay vì 4). Final Attack: 75 sát thương/nhịp, vùng đánh 170×44, với tới 145, thêm `freeze`. Đánh (đòn kết chuỗi): 14 sát thương/nhịp, vùng đánh 80×26, với tới 86, thêm `freeze`. Đánh (đòn thường): vùng đánh 40×16, với tới 38.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#b373ff`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `slash` — vệt chém hình cung
- Lúc tung Final (quanh Rider): `rings3` — ba vòng Medal đỏ / vàng / lục
- **Lượn**: giữ Nhảy khi đang rơi → rơi chậm tối đa 45, rắc lông vũ

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 38 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 14 | 1 | 0.24 / 0.12 / 0.45 | 86 | (240, -100) | `heavy` `freeze` | — |
| Chém (nhát thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Chém (nhát kết) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 75 | 1 | 0.55 / 0.2 / 0.5 | 145 | (300, -160) | `heavy` `freeze` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết. Chuỗi nút Chém: 2 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Strain Doom** (Lv5: *Super TaToBa Strain Doom*)

- đứng tại chỗ tung đòn (tầm 145); 75 sát thương gốc; hất văng (300, -160); gây đóng băng 1.5s.
- Tag: `heavy` `freeze` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 258** · **Lv5 ≈ 541** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện ba vòng Medal đỏ / vàng / lục, trúng quái nổ vệt chém hình cung (màu `#b373ff`); tiếng nạp *final_charge* + giọng `ooo_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** PTERA! TRICERA! TYRANNO! PuToTyranosaurus!
> **Eiji:** Rìu Medagabryu chém rộng, hơi thở Ptera đóng băng quái. Nhưng Medal tím đói lắm: nộ tụt nhanh hơn.

### 12.8 BuraKaWani Combo  ·  _form đặc biệt, rơi ở màn 12-8_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 200 | 64 | 100 | ×0.9 | ×0.98 | 18 | 4/s | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** **Khiên** guard 0.4: đứng chắn chỉ nhận 40% sát thương từ phía trước. Final Attack: 20 sát thương/nhịp, 3 nhịp, lướt (200, -220). Đánh (đòn kết chuỗi): 7 sát thương/nhịp, 2 nhịp, lực đẩy (80, -40). Đánh (đòn thường): vùng đánh 28×10, với tới 36.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#f28c33`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `rings3` — ba vòng Medal đỏ / vàng / lục

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 36 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 7 | 2 | 0.12 / 0.1 / 0.3 | 27 | (80, -40) | `heavy` | — |
| **Final Attack** | 20 | 3 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 200, bật lên 220, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Burakawani Scanning Charge** (Lv5: *Super TaToBa Burakawani Scanning Charge*)

- lao tới 200, bật lên 220 rồi tung đòn (tầm 30); 3 nhịp × 20 = 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 136** · **Lv5 ≈ 286** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện ba vòng Medal đỏ / vàng / lục, trúng quái nổ sóng chấn động dẹt (màu `#f28c33`); tiếng nạp *final_charge* + giọng `ooo_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** COBRA! KAME! WANI! BuraKaWani!
> **Eiji:** Khiên Kame chặn hơn nửa sát thương phía trước khi cậu không ra đòn. Hàm Wani cắn hai nhát liền.

---

## 13. Kamen Rider Fourze · 2011

- **Driver:** Fourze Driver · **Lối chơi:** Công tắc · tên lửa, gậy điện, súng lửa · **Sức mạnh thế hệ:** ×2.44
- **Form gốc:** `base_states`
- **Form rơi ở màn luyện tập:** 13-2 → **Rocket States** · 13-3 → **Elek States** · 13-4 → **Fire States**
- **Thưởng theo cấp:** Lv1: Base States (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Cosmic States: Final Attack x1.5
- **Lv5 — Cosmic States:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Cosmic States <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `rocket` (lửa tên lửa phụt sau lưng)
- **Giọng đai / tiếng hô:** `elek` "Elek. On." · `final` "Rocket. Drill. Limit Break!" · `fire` "Fire. On." · `henshin` "Three. Two. One." · `rocket` "Rocket. On."

### 13.1 Base States  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.1 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: 16 sát thương/nhịp, 4 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `rocket` — lửa tên lửa phụt sau lưng

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 16 | 4 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Rider Rocket Drill Kick** (Lv5: *Cosmic States Rider Rocket Drill Kick*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 4 nhịp × 16 = 64 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 164** · **Lv5 ≈ 344** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện lửa tên lửa phụt sau lưng, trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `fourze_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Bốn công tắc gạt xuống. THREE... TWO... ONE...
> **{name}:** Henshin!
> **Gentaro:** Giờ giơ tay lên trời mà hét đi! UCHUU KITAAA!

### 13.2 Rocket States  ·  _form đặc biệt, rơi ở màn 13-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 130 | 8 | 180 | ×1.35 | ×0.9 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: lướt (340, -60). Đánh (đòn kết chuỗi): lướt (260, -20).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff8c33`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `rocket` — lửa tên lửa phụt sau lưng
- Để bóng mờ khi di chuyển (form tốc độ)

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | lao tới 260, bật lên 20 |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 340, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Rider Rocket Punch** (Lv5: *Cosmic States Rider Rocket Punch*)

- lao tới 340, bật lên 60 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 99** · **Lv5 ≈ 208** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện lửa tên lửa phụt sau lưng, trúng quái nổ sóng chấn động dẹt (màu `#ff8c33`); tiếng nạp *final_charge* + giọng `fourze_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kengo:** Rocket States! Cú đá kết lao theo tên lửa, chạy nhanh, nhảy xa. Nhưng giáp mỏng, đừng lao đầu bừa.

### 13.3 Elek States  ·  _form đặc biệt, rơi ở màn 13-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 28 | 118 | ×1 | ×1.25 | 11 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: thêm `shock`. Chém (nhát thường): thêm `shock`. Chém (nhát kết): thêm `shock`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `rocket` — lửa tên lửa phụt sau lưng

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | `shock` | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` `shock` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` `shock` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Rider 10 Billion Volt Break** (Lv5: *Cosmic States Rider 10 Billion Volt Break*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100); gây điện lan 2 quái.
- Tag: `heavy` `shock` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 198** · **Lv5 ≈ 416** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện lửa tên lửa phụt sau lưng, trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `fourze_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kengo:** Elek States! Bấm Chém để vung Billy the Rod: điện lan sang quái bên cạnh, nhát cuối phá giáp.

### 13.4 Fire States  ·  _form đặc biệt, rơi ở màn 13-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 20 | 115 | ×1 | ×0.95 | 6 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **hackgun** — 7 sát thương/viên, hồi 0.4s, tốc độ 340, bay 0.7s, bán kính 4, đạn `ball` (viên đạn tròn), tag `burn`.

**Kỹ năng riêng:** Final Attack: thêm `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `rocket` — lửa tên lửa phụt sau lưng

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` `burn` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Rider Bakunetsu Shoot** (Lv5: *Cosmic States Rider Bakunetsu Shoot*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60); gây cháy 2s.
- Tag: `ranged` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 116** · **Lv5 ≈ 243** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện lửa tên lửa phụt sau lưng, trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `fourze_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kengo:** Fire States! Giữ nút Bắn, Hee-Hackgun phun lửa, quái trúng còn cháy thêm. Giữ khoảng cách nhé.

---

## 14. Kamen Rider Wizard · 2012

- **Driver:** WizarDriver · **Lối chơi:** Nhẫn phép · súng nước, gió lốc, đá tảng · **Sức mạnh thế hệ:** ×2.56
- **Form gốc:** `flame`
- **Form rơi ở màn luyện tập:** 14-2 → **Water Style** · 14-3 → **Hurricane Style** · 14-4 → **Land Style**
- **Thưởng theo cấp:** Lv1: Flame Style (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Infinity Style: Final Attack x1.5
- **Lv5 — Infinity Style:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Infinity Style <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `circle` (vòng phép đỏ có ký tự), signature `circle` (vòng phép đỏ có ký tự)
- **Giọng đai / tiếng hô:** `final` "Very nice! Kick Strike! Saiko!" · `henshin` "Flame, please. Hi! Hi! Hi-Hi-Hi!" · `hurricane` "Hurricane, please. Fu! Fu! Fu-Fu-Fu!" · `land` "Land, please. Do! Do-Do-Do-Don!" · `water` "Water, please. Sui! Sui! Sui-Sui-Sui!"

### 14.1 Flame Style  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.1 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: thêm `burn`. Đánh (đòn kết chuỗi): thêm `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff594d`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Lúc tung Final (quanh Rider): `circle` — vòng phép đỏ có ký tự
- Dấu ấn trên quái khi Final trúng: `circle` — vòng phép đỏ có ký tự

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` `burn` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` `burn` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Strike Wizard** (Lv5: *Infinity Style Strike Wizard*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160); gây cháy 2s.
- Tag: `heavy` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 161** · **Lv5 ≈ 339** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện vòng phép đỏ có ký tự, trúng quái nổ lửa bùng bốc lên, in vòng phép đỏ có ký tự lên quái (màu `#ff594d`); tiếng nạp *final_charge* + giọng `wizard_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **{name}:** Henshin!
> **Dẫn truyện:** Flame Ring chạm vào bàn tay trên WizarDriver. FLAME, PLEASE! HI, HI, HI-HI-HI!
> **Haruto:** Giờ nói theo tôi. Saa, showtime da.

### 14.2 Water Style  ·  _form đặc biệt, rơi ở màn 14-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 145 | 15 | 125 | ×1.05 | ×0.95 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **wizargun** — 6.5 sát thương/viên, hồi 0.35s, tốc độ 380, bay 0.85s, bán kính 3.5, đạn `ball` (viên đạn tròn), xuyên.

**Kỹ năng riêng:** Final Attack: 18 sát thương/nhịp, 3 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#5999ff`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `circle` — vòng phép đỏ có ký tự
- Dấu ấn trên quái khi Final trúng: `circle` — vòng phép đỏ có ký tự

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 18 | 3 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Shooting Strike** (Lv5: *Infinity Style Shooting Strike*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 3 nhịp × 18 = 54 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 131** · **Lv5 ≈ 276** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện vòng phép đỏ có ký tự, trúng quái nổ sóng chấn động dẹt, in vòng phép đỏ có ký tự lên quái (màu `#5999ff`); tiếng nạp *final_charge* + giọng `wizard_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Haruto:** WATER, PLEASE! SUI, SUI, SUI-SUI! Đạn nước xuyên qua cả hàng quái. Mạnh về phép, đừng để bị áp sát.

### 14.3 Hurricane Style  ·  _form đặc biệt, rơi ở màn 14-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 130 | 8 | 175 | ×1.4 | ×0.9 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn lancer).

**Kỹ năng riêng:** Final Attack: 16 sát thương/nhịp, 3 nhịp, vùng đánh 60×20, với tới 62. Đánh (đòn kết chuỗi): lực đẩy (240, -80), thêm `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#73ff8c`
- Đòn trúng: `wind` — vệt gió xoáy
- Vệt vung đòn: `wind` — vệt gió xoáy
- Final Attack trúng: `wind` — vệt gió xoáy
- Lúc tung Final (quanh Rider): `circle` — vòng phép đỏ có ký tự
- Dấu ấn trên quái khi Final trúng: `circle` — vòng phép đỏ có ký tự
- Để bóng mờ khi di chuyển (form tốc độ)
- **Lượn**: giữ Nhảy khi đang rơi → rơi chậm tối đa 45, rắc lông vũ

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (240, -80) | `force` | — |
| Chém (nhát thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Chém (nhát kết) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 16 | 3 | 0.45 / 0.2 / 0.4 | 62 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Slash Strike** (Lv5: *Infinity Style Slash Strike*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 62); 3 nhịp × 16 = 48 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 111** · **Lv5 ≈ 232** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện vòng phép đỏ có ký tự, trúng quái nổ vệt gió xoáy, in vòng phép đỏ có ký tự lên quái (màu `#73ff8c`); tiếng nạp *final_charge* + giọng `wizard_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Haruto:** HURRICANE, PLEASE! FUU, FUU, FUU-FUU! Gió nâng người: giữ Nhảy khi rơi để lượn, cú kết thổi bay quái. Giáp mỏng lắm.

### 14.4 Land Style  ·  _form đặc biệt, rơi ở màn 14-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 58 | 82 | ×0.8 | ×1.4 | 19 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** **Khiên** guard 0.5: đứng chắn chỉ nhận 50% sát thương từ phía trước. Đánh (đòn kết chuỗi): lực đẩy (10, -260), vùng đánh 120×18, với tới 60, thêm `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd94d`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `circle` — vòng phép đỏ có ký tự
- Dấu ấn trên quái khi Final trúng: `circle` — vòng phép đỏ có ký tự

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 60 | (10, -260) | `heavy` `force` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Strike Wizard (Land)** (Lv5: *Infinity Style Strike Wizard (Land)*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 251** · **Lv5 ≈ 527** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện vòng phép đỏ có ký tự, trúng quái nổ sóng chấn động dẹt, in vòng phép đỏ có ký tự lên quái (màu `#ffd94d`); tiếng nạp *final_charge* + giọng `wizard_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Haruto:** LAND, PLEASE! DO-DO-DO-DON! Phép Defend dựng tường đá chặn nửa đòn phía trước. Dậm chân là quái bật lên.

---

## 15. Kamen Rider Gaim · 2013

- **Driver:** Sengoku Driver · **Lối chơi:** Lockseed · chùy nặng, kunai nhanh, cung xuyên · **Sức mạnh thế hệ:** ×2.68
- **Form gốc:** `orange`
- **Form rơi ở màn luyện tập:** 15-2 → **Pine Arms** · 15-3 → **Ichigo Arms** · 15-4 → **Jimber Lemon Arms**
- **Thưởng theo cấp:** Lv1: Orange Arms (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Kiwami Arms: Final Attack x1.5
- **Lv5 — Kiwami Arms:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Kiwami Arms <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `crack` (khe nứt khóa kéo Helheim mở trên đầu), signature `fruit` (lát trái cây khổng lồ chụp xuống rồi tách múi)
- **Giọng đai / tiếng hô:** `final` "Soiya! Squash!" · `henshin` "Lock on! Soiya! Orange Arms! Hanamichi, on stage!" · `ichigo` "Ichigo Arms! Shushutto spark!" · `jimber_lemon` "Mix! Jimber Lemon! Ha-ha!" · `pine` "Pine Arms! Funsai, destroy!"

### 15.1 Orange Arms  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.05 | ×1.1 | 8 | — | Blade (kiếm) |

**Vũ khí:** Nút Chém: **Daidaimaru** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: thêm `stun`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff8c1a`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `crack` — khe nứt khóa kéo Helheim mở trên đầu
- Dấu ấn trên quái khi Final trúng: `fruit` — lát trái cây khổng lồ chụp xuống rồi tách múi

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` `stun` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Naginata Musou Slicer** (Lv5: *Kiwami Arms Naginata Musou Slicer*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100); gây choáng 1.2s.
- Tag: `heavy` `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 192** · **Lv5 ≈ 402** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện khe nứt khóa kéo Helheim mở trên đầu, trúng quái nổ sóng chấn động dẹt, in lát trái cây khổng lồ chụp xuống rồi tách múi lên quái (màu `#ff8c1a`); tiếng nạp *final_charge* + giọng `gaim_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **{name}:** Henshin!
> **Dẫn truyện:** LOCK ON! SOIYA! ORANGE ARMS: HANAMICHI ON STAGE! Một quả cam khổng lồ rơi xuống, bung thành giáp.
> **Kouta:** Giờ nói đi! Từ đây trở đi là sân khấu của cậu!

### 15.2 Pine Arms  ·  _form đặc biệt, rơi ở màn 15-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 200 | 55 | 85 | ×0.85 | ×1.4 | 18 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Nút Chém: **Pine Iron** (2 nhát + nhát kết, bảng đòn heavy).

**Kỹ năng riêng:** Final Attack: lực đẩy (-120, -40) — **hút về**, vùng đánh 90×22, với tới 95, thêm `force` `stun`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#f2cc40`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `crack` — khe nứt khóa kéo Helheim mở trên đầu
- Dấu ấn trên quái khi Final trúng: `fruit` — lát trái cây khổng lồ chụp xuống rồi tách múi

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| Chém (nhát thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Chém (nhát kết) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 95 | (-120, -40) | `heavy` `force` `stun` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết. Chuỗi nút Chém: 2 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Pine Squash** (Lv5: *Kiwami Arms Pine Squash*)

- đứng tại chỗ tung đòn (tầm 95); 70 sát thương gốc; hút quái về phía Rider (-120, -40); gây đẩy cưỡng bức, choáng 1.2s.
- Tag: `heavy` `force` `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 263** · **Lv5 ≈ 552** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện khe nứt khóa kéo Helheim mở trên đầu, trúng quái nổ sóng chấn động dẹt, in lát trái cây khổng lồ chụp xuống rồi tách múi lên quái (màu `#f2cc40`); tiếng nạp *final_charge* + giọng `gaim_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kouta:** PINE ARMS: FUNSAI DESTROY! Chậm, nhưng vung chùy Pine Iron thì giáp nào cũng vỡ.

### 15.3 Ichigo Arms  ·  _form đặc biệt, rơi ở màn 15-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 132 | 10 | 175 | ×1.3 | ×0.9 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Nút Bắn: **Ichigo Kunai** — 3.5 sát thương/viên, hồi 0.4s, tốc độ 420, bay 0.6s, bán kính 2.5, đạn `arrow` (mũi tên khí), 2 viên xòe 0.08 rad.

**Kỹ năng riêng:** Final Attack: 13 sát thương/nhịp, 4 nhịp, vùng đánh 80×40, với tới 90.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff4d59`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `crack` — khe nứt khóa kéo Helheim mở trên đầu
- Dấu ấn trên quái khi Final trúng: `fruit` — lát trái cây khổng lồ chụp xuống rồi tách múi
- Để bóng mờ khi di chuyển (form tốc độ)

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 13 | 4 | 0.45 / 0.2 / 0.4 | 90 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Ichigo Squash** (Lv5: *Kiwami Arms Ichigo Squash*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 90); 4 nhịp × 13 = 52 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 125** · **Lv5 ≈ 263** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện khe nứt khóa kéo Helheim mở trên đầu, trúng quái nổ sóng chấn động dẹt, in lát trái cây khổng lồ chụp xuống rồi tách múi lên quái (màu `#ff4d59`); tiếng nạp *final_charge* + giọng `gaim_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kouta:** ICHIGO ARMS: SHUSHUTTO SPARK! Nhẹ như ninja, chạy nhanh, phóng Ichigo Kunai liên tục.

### 15.4 Jimber Lemon Arms  ·  _form đặc biệt, rơi ở màn 15-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 20 | 120 | ×1.05 | ×1 | 6 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **Sonic Arrow** — 7.5 sát thương/viên, hồi 0.45s, tốc độ 440, bay 0.9s, bán kính 3, đạn `arrow` (mũi tên khí), xuyên.

**Kỹ năng riêng:** Final Attack: 58 sát thương/nhịp, vùng đánh 230×12, với tới 235, thêm `heavy` `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffe64d`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `crack` — khe nứt khóa kéo Helheim mở trên đầu
- Dấu ấn trên quái khi Final trúng: `fruit` — lát trái cây khổng lồ chụp xuống rồi tách múi

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 58 | 1 | 0.6 / 0.1 / 0.4 | 235 | (200, -60) | `ranged` `heavy` `force` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Sonic Volley** (Lv5: *Kiwami Arms Sonic Volley*)

- phát bắn tầm xa (vùng trúng dài 230, chạm tới 235 trước mặt); 58 sát thương gốc; hất văng (200, -60); gây đẩy cưỡng bức.
- Tag: `ranged` `heavy` `force` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 155** · **Lv5 ≈ 326** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện khe nứt khóa kéo Helheim mở trên đầu, trúng quái nổ sóng chấn động dẹt, in lát trái cây khổng lồ chụp xuống rồi tách múi lên quái (màu `#ffe64d`); tiếng nạp *final_charge* + giọng `gaim_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Kouta:** MIX! JIMBER LEMON! HA-HA! Cung Sonic Arrow bắn xa, xuyên cả hàng quái. Cứ đứng xa mà ngắm.

---

## 16. Kamen Rider Drive · 2014

- **Driver:** Drive Driver · **Lối chơi:** Shift Car · xe tải, súng cửa, Formula siêu tốc · **Sức mạnh thế hệ:** ×2.8
- **Form gốc:** `speed`
- **Form rơi ở màn luyện tập:** 16-2 → **Type Wild** · 16-3 → **Type Technic** · 16-4 → **Type Formula**
- **Thưởng theo cấp:** Lv1: Type Speed (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Type Tridoron: Final Attack x1.5
- **Lv5 — Type Tridoron:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Type Tridoron <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `tire` (lốp xe vành bạc lăn vòng quanh Rider)
- **Giọng đai / tiếng hô:** `final` "Hissatsu! Full Throttle!" · `formula` "Drive! Type Formula!" · `henshin` "Drive! Type Speed!" · `technic` "Drive! Type Technic!" · `wild` "Drive! Type Wild!"

### 16.1 Type Speed  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 155 | 22 | 140 | ×1.05 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Nút Chém: **Handle-Ken** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: 20 sát thương/nhịp, 3 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff4040`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `tire` — lốp xe vành bạc lăn vòng quanh Rider
- Để bóng mờ khi di chuyển (form tốc độ)

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 20 | 3 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — SpeeDrop** (Lv5: *Type Tridoron SpeeDrop*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 3 nhịp × 20 = 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 176** · **Lv5 ≈ 370** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện lốp xe vành bạc lăn vòng quanh Rider, trúng quái nổ sóng chấn động dẹt (màu `#ff4040`); tiếng nạp *final_charge* + giọng `drive_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Krim:** Start your engine!
> **{name}:** Henshin!
> **Dẫn truyện:** DRIVE! TYPE SPEED! Một chiếc lốp đỏ bay tới, cài chéo qua ngực {name}. Vùng Don-yori vỡ tan.

### 16.2 Type Wild  ·  _form đặc biệt, rơi ở màn 16-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 55 | 85 | ×0.85 | ×1.4 | 18 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Nút Chém: **Rumble Dump** (2 nhát + nhát kết, bảng đòn heavy).

**Kỹ năng riêng:** Final Attack: lướt (220, 0), thêm `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#cccce0`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `tire` — lốp xe vành bạc lăn vòng quanh Rider

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| Chém (nhát thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Chém (nhát kết) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` `force` | lao tới 220, không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết. Chuỗi nút Chém: 2 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Full Throttle: Wild** (Lv5: *Type Tridoron Full Throttle: Wild*)

- lao tới 220 rồi tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160); gây đẩy cưỡng bức.
- Tag: `heavy` `force` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 274** · **Lv5 ≈ 576** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện lốp xe vành bạc lăn vòng quanh Rider, trúng quái nổ sóng chấn động dẹt (màu `#cccce0`); tiếng nạp *final_charge* + giọng `drive_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Krim:** DRIVE! TYPE WILD! Chậm hơn, nhưng mỗi cú húc như xe tải lao tới. Giáp nào cũng vỡ. Nice drive!

### 16.3 Type Technic  ·  _form đặc biệt, rơi ở màn 16-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 145 | 18 | 118 | ×1 | ×0.95 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **Door-Ju** — 7.5 sát thương/viên, hồi 0.32s, tốc độ 420, bay 0.9s, bán kính 3, đạn `ball` (viên đạn tròn).

**Kỹ năng riêng:** Final Attack: 18 sát thương/nhịp, 3 nhịp, thêm `stun`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#59f273`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `tire` — lốp xe vành bạc lăn vòng quanh Rider

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 18 | 3 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` `stun` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Full Throttle: Technic** (Lv5: *Type Tridoron Full Throttle: Technic*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 3 nhịp × 18 = 54 sát thương gốc; hất văng (200, -60); gây choáng 1.2s.
- Tag: `ranged` `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 144** · **Lv5 ≈ 302** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện lốp xe vành bạc lăn vòng quanh Rider, trúng quái nổ sóng chấn động dẹt (màu `#59f273`); tiếng nạp *final_charge* + giọng `drive_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Krim:** DRIVE! TYPE TECHNIC! Door-ju bắn cực chuẩn từ xa. Đứng xa mà ngắm, đừng để bị áp sát.

### 16.4 Type Formula  ·  _form đặc biệt, rơi ở màn 16-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 130 | 10 | 180 | ×1.25 | ×0.95 | 4 | 10/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** **Tăng tốc thời gian** (xem 0.5), chữ báo `TYPE FORMULA`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#4d8cff`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `tire` — lốp xe vành bạc lăn vòng quanh Rider
- Để bóng mờ khi di chuyển (form tốc độ)

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | `time` | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | `time` | — |
| **Final Attack** | 16 | 5 | 0.2 / 0.08 / 0.5 | 40 | (60, -20) | `time` | lao tới 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Formula Drop** (Lv5: *Type Tridoron Formula Drop*)

- lao tới 200 rồi tung đòn (tầm 40); 5 nhịp × 16 = 80 sát thương gốc; hất văng (60, -20); gây trúng chắc quái Fast (tag time).
- Đây là Final dạng tăng tốc thời gian: chuỗi 5 đòn lướt liên hoàn thay cho Final của kiểu đòn.
- Tag: `time` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 213** · **Lv5 ≈ 298** (Final tăng tốc thời gian **không** nhận ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện lốp xe vành bạc lăn vòng quanh Rider, trúng quái nổ sóng chấn động dẹt (màu `#4d8cff`); tiếng nạp *final_charge* + giọng `drive_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Krim:** DRIVE! TYPE FORMULA! Nhanh tới mức thế giới gần như đứng yên. Nhưng nộ tụt rất nhanh đấy!

---

## 17. Kamen Rider Ghost · 2015

- **Driver:** Ghost Driver · **Lối chơi:** Cân bằng · mượn hồn anh hùng: song kiếm, súng điện, trọng lực · **Sức mạnh thế hệ:** ×2.92
- **Form gốc:** `ore`
- **Form rơi ở màn luyện tập:** 17-2 → **Musashi Damashii** · 17-3 → **Edison Damashii** · 17-4 → **Newton Damashii**
- **Thưởng theo cấp:** Lv1: Ore Damashii (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Mugen Damashii: Final Attack x1.5
- **Lv5 — Mugen:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Mugen <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** intro `eye` (con mắt Ghost khổng lồ sau lưng, viền gai lửa)
- **Giọng đai / tiếng hô:** `edison` "Kaigan! Edison! Hirameki! Hatsumei! Hatsumei-ou!" · `final` "Dai Kaigan! Omega Drive!" · `henshin` "Kaigan! Ore! Let's go! Kakugo! Gho-Gho-Gho-Ghost!" · `musashi` "Kaigan! Musashi! Kettou! Zubatto! Chouken-gou!" · `newton` "Kaigan! Newton! Ringo ga rakka! Hikiyoseru gekka!"

### 17.1 Ore Damashii  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 158 | 24 | 132 | ×1.15 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Nút Chém: **Gan Gun Saber (kiếm)** (3 nhát + nhát kết, bảng đòn blade).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff8c26`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Lúc tung Final (quanh Rider): `eye` — con mắt Ghost khổng lồ sau lưng, viền gai lửa
- **Lượn**: giữ Nhảy khi đang rơi → rơi chậm tối đa 45, rắc lông vũ

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Omega Drive** (Lv5: *Mugen Omega Drive*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 184** · **Lv5 ≈ 386** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện con mắt Ghost khổng lồ sau lưng, viền gai lửa, trúng quái nổ lửa bùng bốc lên (màu `#ff8c26`); tiếng nạp *final_charge* + giọng `ghost_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Ore Eyecon mở mắt. Ghost Driver hiện ra, hồn {name} nhập lại vào xác trong một vạt áo choàng đen cam.
> **Takeru:** Nhịp tim đó là sinh mệnh của cậu. Đừng lãng phí nó. Thắp cháy nó lên!
> **{name}:** Henshin!

### 17.2 Musashi Damashii  ·  _form đặc biệt, rơi ở màn 17-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 26 | 122 | ×1 | ×1.25 | 11 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **Gan Gun Saber Nitoryu (song kiếm)** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: 34 sát thương/nhịp, 2 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff4033`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `slash` — vệt chém hình cung
- Lúc tung Final (quanh Rider): `eye` — con mắt Ghost khổng lồ sau lưng, viền gai lửa

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 34 | 2 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Omega Slash** (Lv5: *Mugen Omega Slash*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 2 nhịp × 34 = 68 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 248** · **Lv5 ≈ 521** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện con mắt Ghost khổng lồ sau lưng, viền gai lửa, trúng quái nổ vệt chém hình cung (màu `#ff4033`); tiếng nạp *final_charge* + giọng `ghost_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Takeru:** Musashi Damashii! Gan Gun Saber tách thành hai kiếm. Chém liên hoàn, nhát cuối phá giáp.

### 17.3 Edison Damashii  ·  _form đặc biệt, rơi ở màn 17-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 145 | 15 | 118 | ×1 | ×0.95 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **Gan Gun Saber (súng)** — 7 sát thương/viên, hồi 0.34s, tốc độ 400, bay 0.85s, bán kính 3, đạn `bolt` (tia sét), xuyên, tag `shock`.

**Kỹ năng riêng:** Final Attack: thêm `shock`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffeb59`
- Đòn trúng: `lightning` — tia sét gấp khúc
- Final Attack trúng: `lightning` — tia sét gấp khúc
- Lúc tung Final (quanh Rider): `eye` — con mắt Ghost khổng lồ sau lưng, viền gai lửa

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` `shock` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Omega Shoot** (Lv5: *Mugen Omega Shoot*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60); gây điện lan 2 quái.
- Tag: `ranged` `shock` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 139** · **Lv5 ≈ 291** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện con mắt Ghost khổng lồ sau lưng, viền gai lửa, trúng quái nổ tia sét gấp khúc (màu `#ffeb59`); tiếng nạp *final_charge* + giọng `ghost_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Pen:** Eyecon Edison! Gan Gun Saber thành súng, bắn tia điện xuyên qua cả hàng quái. Ông tổ bóng đèn đấy!

### 17.4 Newton Damashii  ·  _form đặc biệt, rơi ở màn 17-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 200 | 52 | 85 | ×0.85 | ×1.4 | 18 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: lực đẩy (-200, -40) — **hút về**, vùng đánh 140×40, với tới 110, thêm `force` `stun`. Đánh (đòn kết chuỗi): lực đẩy (260, -40), thêm `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#598cff`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Lúc tung Final (quanh Rider): `eye` — con mắt Ghost khổng lồ sau lưng, viền gai lửa

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (260, -40) | `heavy` `force` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 110 | (-200, -40) | `heavy` `force` `stun` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Omega Drive** (Lv5: *Mugen Omega Drive*)

- đứng tại chỗ tung đòn (tầm 110); 70 sát thương gốc; hút quái về phía Rider (-200, -40); gây đẩy cưỡng bức, choáng 1.2s.
- Tag: `heavy` `force` `stun` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 286** · **Lv5 ≈ 601** (đã gồm ×1.5 Lv5).
- Hình ảnh: quanh Rider hiện con mắt Ghost khổng lồ sau lưng, viền gai lửa, trúng quái nổ sóng chấn động dẹt (màu `#598cff`); tiếng nạp *final_charge* + giọng `ghost_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Takeru:** Newton Damashii! Tay trái đẩy, tay phải hút. Chậm, nhưng mỗi cú đấm nặng như trọng lực.

---

## 18. Kamen Rider Ex-Aid · 2016

- **Driver:** Gamer Driver · **Lối chơi:** Nhảy cao · đổi Level: xe đạp tốc độ, nắm đấm robot, rồng săn · **Sức mạnh thế hệ:** ×3.04
- **Form gốc:** `action_gamer`
- **Form rơi ở màn luyện tập:** 18-2 → **Sports Action Gamer Level 3** · 18-3 → **Robot Action Gamer Level 3** · 18-4 → **Hunter Action Gamer Level 5**
- **Thưởng theo cấp:** Lv1: Action Gamer Level 2 (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Muteki Gamer: Final Attack x1.5
- **Lv5 — Muteki Gamer:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Muteki Gamer <tên chiêu>"
- **Dấu hiệu tuyệt chiêu chung (mọi form):** signature `hit_text` (chữ HIT! vàng viền đen bật lên)
- **Giọng đai / tiếng hô:** `final` "Kimewaza! Mighty Critical Strike!" · `henshin` "Level up! Mighty jump! Mighty kick! Mighty Action X!" · `hunter` "Level up! Drago Knight Hunter Z!" · `robot` "Level up! Buttobi punch! Gekitotsu Robots!" · `sports` "Level up! Shakariki Sports!"

### 18.1 Action Gamer Level 2  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 155 | 22 | 135 | ×1.25 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Nút Chém: **Gashacon Breaker (búa)** (3 nhát + nhát kết, bảng đòn blade).

**Kỹ năng riêng:** Final Attack: 22 sát thương/nhịp, 3 nhịp.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ff59bf`
- Đòn trúng: `spark` — tia va chạm toả ra
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Dấu ấn trên quái khi Final trúng: `hit_text` — chữ HIT! vàng viền đen bật lên

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 22 | 3 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Mighty Critical Strike** (Lv5: *Muteki Gamer Mighty Critical Strike*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 3 nhịp × 22 = 66 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 211** · **Lv5 ≈ 442** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt, in chữ HIT! vàng viền đen bật lên lên quái (màu `#ff59bf`); tiếng nạp *final_charge* + giọng `ex_aid_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** GAME CLEAR! Gamer Driver bật sáng. Một bộ giáp hồng mắt to hiện ra, rồi vỡ vỏ thành Level 2.
> **Emu:** Số phận của bệnh nhân, tôi sẽ thay đổi nó! ...Câu cửa miệng của tôi đấy. Cho cậu mượn.
> **{name}:** Dai Henshin!

### 18.2 Sports Action Gamer Level 3  ·  _form đặc biệt, rơi ở màn 18-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 135 | 12 | 175 | ×1.2 | ×0.9 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Nút Bắn: **bánh xe Tricker** — 5 sát thương/viên, hồi 0.45s, tốc độ 300, bay 0.7s, bán kính 4.5, đạn `ball` (viên đạn tròn), xuyên.

**Kỹ năng riêng:** Final Attack: 16 sát thương/nhịp, 3 nhịp, vùng đánh 70×30, với tới 75.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#59e6d9`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Dấu ấn trên quái khi Final trúng: `hit_text` — chữ HIT! vàng viền đen bật lên
- Để bóng mờ khi di chuyển (form tốc độ)

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 16 | 3 | 0.45 / 0.2 / 0.4 | 75 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Shakariki Critical Strike** (Lv5: *Muteki Gamer Shakariki Critical Strike*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 75); 3 nhịp × 16 = 48 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 131** · **Lv5 ≈ 276** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt, in chữ HIT! vàng viền đen bật lên lên quái (màu `#59e6d9`); tiếng nạp *final_charge* + giọng `ex_aid_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Emu:** Sports Action Gamer Level 3! Chạy nhanh, ném bánh xe từ xa. Đánh nhẹ hơn, nhưng không ai bắt kịp.

### 18.3 Robot Action Gamer Level 3  ·  _form đặc biệt, rơi ở màn 18-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 55 | 84 | ×0.85 | ×1.42 | 19 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** Final Attack: lực đẩy (360, -120), lướt (200, 0), thêm `force`. Đánh (đòn kết chuỗi): lực đẩy (280, -60), thêm `force`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#f24d4d`
- Đòn trúng: `ring` — sóng chấn động dẹt
- Final Attack trúng: `ring` — sóng chấn động dẹt
- Dấu ấn trên quái khi Final trúng: `hit_text` — chữ HIT! vàng viền đen bật lên

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (280, -60) | `heavy` `force` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (360, -120) | `heavy` `force` | lao tới 200, không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Gekitotsu Critical Strike** (Lv5: *Muteki Gamer Gekitotsu Critical Strike*)

- lao tới 200 rồi tung đòn (tầm 35); 70 sát thương gốc; hất văng (360, -120); gây đẩy cưỡng bức.
- Tag: `heavy` `force` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 302** · **Lv5 ≈ 635** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt, in chữ HIT! vàng viền đen bật lên lên quái (màu `#f24d4d`); tiếng nạp *final_charge* + giọng `ex_aid_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Poppy:** Gekitotsu Robots! Tay robot khổng lồ, chậm rì rì nhưng đấm một phát là bay giáp nha!

### 18.4 Hunter Action Gamer Level 5  ·  _form đặc biệt, rơi ở màn 18-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 170 | 35 | 108 | ×0.95 | ×1.05 | 9 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Chém: **kiếm rồng Drago Knight** (3 nhát + nhát kết, bảng đòn blade). Nút Bắn: **súng rồng Drago Knight** — 8 sát thương/viên, hồi 0.38s, tốc độ 340, bay 0.7s, bán kính 4, đạn `fire` (cầu lửa), tag `burn`.

**Kỹ năng riêng:** Final Attack: thêm `burn`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#66e659`
- Đòn trúng: `fire` — lửa bùng bốc lên
- Vệt vung đòn: `slash` — vệt chém hình cung
- Final Attack trúng: `fire` — lửa bùng bốc lên
- Dấu ấn trên quái khi Final trúng: `hit_text` — chữ HIT! vàng viền đen bật lên

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` `burn` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Drago Knight Critical Strike** (Lv5: *Muteki Gamer Drago Knight Critical Strike*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60); gây cháy 2s.
- Tag: `ranged` `burn` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 160** · **Lv5 ≈ 335** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ lửa bùng bốc lên, in chữ HIT! vàng viền đen bật lên lên quái (màu `#66e659`); tiếng nạp *final_charge* + giọng `ex_aid_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Emu:** Hunter Action Gamer Level 5! Giáp rồng, một tay kiếm, một tay súng. Bắn lửa từ xa, chịu đòn tốt hơn hẳn.

---

## 19. Kamen Rider Build · 2017

- **Driver:** Build Driver · **Lối chơi:** Best Match · thỏ nhảy xa, đấm kim cương, diều hâu bắn, ninja chém · **Sức mạnh thế hệ:** ×3.16
- **Form gốc:** `rabbit_tank`
- **Form rơi ở màn luyện tập:** 19-2 → **GorillaMond** · 19-3 → **HawkGatling** · 19-4 → **NinninComic**
- **Thưởng theo cấp:** Lv1: RabbitTank (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Genius Form: Final Attack x1.5
- **Lv5 — Genius:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Genius <tên chiêu>"

### 19.1 RabbitTank  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 28 | 132 | ×1.3 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Vortex Finish** (Lv5: *Genius Vortex Finish*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 199** · **Lv5 ≈ 418** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `build_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Rabbit! Tank! Best Match! Tay quay xoay tít, hai nửa giáp đỏ và xanh ép lại quanh {name}.
> **Sento:** Are you ready?
> **{name}:** Henshin!

### 19.2 GorillaMond  ·  _form đặc biệt, rơi ở màn 19-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 58 | 82 | ×0.85 | ×1.42 | 19 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Vortex Finish** (Lv5: *Genius Vortex Finish*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 314** · **Lv5 ≈ 660** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `build_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Sento:** GorillaMond! Tay khỉ đột, thân kim cương. Chậm như rùa, nhưng mỗi cú đấm làm vỡ cả thép.

### 19.3 HawkGatling  ·  _form đặc biệt, rơi ở màn 19-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 14 | 125 | ×1.35 | ×0.9 | 4 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **súng** — 4.5 sát thương/viên, hồi 0.16s, tốc độ 460, bay 0.7s, bán kính 2.5, đạn `ball` (viên đạn tròn).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Full Bullet** (Lv5: *Genius Full Bullet*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 142** · **Lv5 ≈ 299** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `build_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Sento:** HawkGatling! Cánh diều hâu, súng Hawk Gatlinger. Nhảy cao, bắn như mưa. Bù lại, giáp mỏng.

### 19.4 NinninComic  ·  _form đặc biệt, rơi ở màn 19-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 138 | 14 | 170 | ×1.3 | ×1.1 | 6 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Kaen Giri** (Lv5: *Genius Kaen Giri*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 226** · **Lv5 ≈ 474** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `build_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Sento:** NinninComic! Kiếm Yonkoma Ninpoutou. Nhanh như ninja, chém ra lửa, nhưng máu mỏng. Đừng đứng yên.

---

## 20. Kamen Rider Zi-O · 2018

- **Driver:** Ziku Driver · **Lối chơi:** Kế thừa · khoác Armor của Build, Ex-Aid, Decade · **Sức mạnh thế hệ:** ×3.28
- **Form gốc:** `zi_o`
- **Form rơi ở màn luyện tập:** 20-2 → **Build Armor** · 20-3 → **Ex-Aid Armor** · 20-4 → **Decade Armor**
- **Thưởng theo cấp:** Lv1: Zi-O (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Grand Zi-O: Final Attack x1.5
- **Lv5 — Grand Zi-O:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Grand Zi-O <tên chiêu>"

### 20.1 Zi-O  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.05 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Time Break** (Lv5: *Grand Zi-O Time Break*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 207** · **Lv5 ≈ 434** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zi_o_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Ziku Driver xoay một vòng. Mặt đồng hồ khổng lồ hiện sau lưng {name}, chữ RIDER bay vào mặt nạ.
> **Woz:** Iwae! Hãy chúc mừng! Người kế thừa sức mạnh của các Rider, băng qua quá khứ và tương lai, đã ra đời!
> **{name}:** Henshin!

### 20.2 Build Armor  ·  _form đặc biệt, rơi ở màn 20-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 15 | 165 | ×1.25 | ×0.95 | 5 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Vortex Time Break** (Lv5: *Grand Zi-O Vortex Time Break*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 140** · **Lv5 ≈ 294** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zi_o_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Woz:** Iwae! Zi-O Build Armor! Mũi khoan Drill Crusher Crusher, đâm nhanh và xa, chạy cũng nhanh hơn.

### 20.3 Ex-Aid Armor  ·  _form đặc biệt, rơi ở màn 20-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 200 | 52 | 85 | ×0.9 | ×1.4 | 18 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Critical Time Break** (Lv5: *Grand Zi-O Critical Time Break*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 321** · **Lv5 ≈ 675** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zi_o_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Woz:** Iwae! Zi-O Ex-Aid Armor! Hai búa Gashacon Breaker Breaker. Chậm, nhưng mỗi nhát nện là vỡ giáp.

### 20.4 Decade Armor  ·  _form đặc biệt, rơi ở màn 20-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 170 | 32 | 128 | ×1.05 | ×1.25 | 12 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Attack Time Break** (Lv5: *Grand Zi-O Attack Time Break*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 266** · **Lv5 ≈ 560** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zi_o_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Woz:** Iwae! Zi-O Decade Armor! Kiếm Ride Heisaber, sức mạnh của kẻ hủy diệt thế giới. Chém nhanh, chém mạnh.

---

## 21. Kamen Rider Zero-One · 2019

- **Driver:** Hiden Zero-One Driver · **Lối chơi:** Nhảy vọt · hổ lửa, gấu băng, tốc độ dự đoán · **Sức mạnh thế hệ:** ×3.4
- **Form gốc:** `rising_hopper`
- **Form rơi ở màn luyện tập:** 21-2 → **Flaming Tiger** · 21-3 → **Freezing Bear** · 21-4 → **Shining Hopper**
- **Thưởng theo cấp:** Lv1: Rising Hopper (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Zero-Two: Final Attack x1.5
- **Lv5 — Zero-Two:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Zero-Two <tên chiêu>"

### 21.1 Rising Hopper  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 155 | 22 | 135 | ×1.35 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Rising Impact** (Lv5: *Zero-Two Rising Impact*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 214** · **Lv5 ≈ 450** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zero_one_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Jump! Authorize! Một con châu chấu kim loại khổng lồ nhảy qua đầu {name} rồi tách ra thành giáp.
> **Aruto:** Người duy nhất ngăn được ngươi... là tôi! Câu đó hợp với cậu đấy. Hô đi!
> **{name}:** Henshin!

### 21.2 Flaming Tiger  ·  _form đặc biệt, rơi ở màn 21-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 18 | 142 | ×1.15 | ×1.2 | 10 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Flaming Impact** (Lv5: *Zero-Two Flaming Impact*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 265** · **Lv5 ≈ 557** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zero_one_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Is:** Flaming Tiger. Móng vuốt lửa, lao nhanh, chém liên hoàn. Nhảy thấp hơn Rising Hopper một chút.

### 21.3 Freezing Bear  ·  _form đặc biệt, rơi ở màn 21-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 55 | 84 | ×0.85 | ×1.38 | 18 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Freezing Impact** (Lv5: *Zero-Two Freezing Impact*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 328** · **Lv5 ≈ 690** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zero_one_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Aruto:** Freezing Bear! Gấu Bắc Cực, tay băng. Chậm, nhưng mỗi cú đấm đóng băng cả lớp giáp.

### 21.4 Shining Hopper  ·  _form đặc biệt, rơi ở màn 21-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 132 | 10 | 180 | ×1.4 | ×0.95 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Shining Impact** (Lv5: *Zero-Two Shining Impact*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 145** · **Lv5 ≈ 305** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zero_one_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Aruto:** Shining Hopper! Khi tôi tỏa sáng, bóng tối sẽ tan. Nhanh nhất, nhảy cao nhất, nhưng giáp mỏng dính.

---

## 22. Kamen Rider Saber · 2020

- **Driver:** Seiken Swordriver · **Lối chơi:** Kiếm sĩ lửa · ba cuốn sách, hiệp sĩ rồng, kiếm nguyên tố · **Sức mạnh thế hệ:** ×3.52
- **Form gốc:** `brave_dragon`
- **Form rơi ở màn luyện tập:** 22-2 → **Crimson Dragon** · 22-3 → **Dragonic Knight** · 22-4 → **Elemental Primitive Dragon**
- **Thưởng theo cấp:** Lv1: Brave Dragon (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Xross Saber: Final Attack x1.5
- **Lv5 — Xross Saber:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Xross Saber <tên chiêu>"

### 22.1 Brave Dragon  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.05 | ×1.12 | 9 | — | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Kaen Juujizan** (Lv5: *Xross Saber Kaen Juujizan*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 256** · **Lv5 ≈ 538** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `saber_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** {name} rút Kaenken Rekka. Cuốn Brave Dragon mở ra, một con rồng lửa lượn quanh rồi hóa thành giáp.
> **Touma:** Cái kết của câu chuyện, tôi sẽ quyết định! ...Giờ tới lượt cậu.
> **{name}:** Henshin!

### 22.2 Crimson Dragon  ·  _form đặc biệt, rơi ở màn 22-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 14 | 168 | ×1.35 | ×0.95 | 5 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Sansatsu Giri** (Lv5: *Xross Saber Sansatsu Giri*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 150** · **Lv5 ≈ 316** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `saber_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Touma:** Crimson Dragon! Cánh đại bàng, gậy Như Ý. Bay nhảy nhẹ, đánh xa và nhanh, nhưng giáp mỏng.

### 22.3 Dragonic Knight  ·  _form đặc biệt, rơi ở màn 22-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 58 | 84 | ×0.85 | ×1.4 | 19 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Shinka Ryuuhazan** (Lv5: *Xross Saber Shinka Ryuuhazan*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 345** · **Lv5 ≈ 724** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `saber_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Touma:** Dragonic Knight! Giáp hiệp sĩ rồng. Chậm và nặng, nhưng mỗi nhát kiếm nghiền nát cả đá.

### 22.4 Elemental Primitive Dragon  ·  _form đặc biệt, rơi ở màn 22-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 28 | 145 | ×1.1 | ×1.3 | 11 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Hissatsu Dokuha** (Lv5: *Xross Saber Hissatsu Dokuha*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 297** · **Lv5 ≈ 625** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `saber_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Touma:** Elemental Primitive Dragon! Lửa, nước, gió, đất gom vào một thanh kiếm. Mạnh và nhanh. Đừng để nó điều khiển cậu.

---

## 23. Kamen Rider Revice · 2021

- **Driver:** Revice Driver · **Lối chơi:** Một người, một ác quỷ · form bay, form tốc độ, form ma-mút · **Sức mạnh thế hệ:** ×3.64
- **Form gốc:** `rex`
- **Form rơi ở màn luyện tập:** 23-2 → **Eagle Genome** · 23-3 → **Jackal Genome** · 23-4 → **Mammoth Genome**
- **Thưởng theo cấp:** Lv1: Rex Genome (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Ultimate Revice: Final Attack x1.5
- **Lv5 — Ultimate Revice:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Ultimate Revice <tên chiêu>"

### 23.1 Rex Genome  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.05 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Rex Stamping Finish** (Lv5: *Ultimate Revice Rex Stamping Finish*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 229** · **Lv5 ≈ 482** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `revice_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** {name} ấn Rex Vistamp. Từ cái bóng của cậu, một gã hồng tím bật dậy, vươn vai như vừa ngủ trưa xong.
> **Vice:** Yahoo, được ra ngoài rồi! Tôi là Vice... ơ, cậu đâu phải Ikki? Thôi kệ, tạm lập khế ước nhé!
> **{name}:** Henshin!

### 23.2 Eagle Genome  ·  _form đặc biệt, rơi ở màn 23-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 12 | 150 | ×1.45 | ×0.95 | 5 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Eagle Stamping Finish** (Lv5: *Ultimate Revice Eagle Stamping Finish*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 156** · **Lv5 ≈ 327** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `revice_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Vice:** Eagle Genome! Nhảy cao, lượn xa, vuốt đại bàng với tới xa hơn. Nhẹ ký, nên né đòn chứ đừng đỡ nha.

### 23.3 Jackal Genome  ·  _form đặc biệt, rơi ở màn 23-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 130 | 8 | 180 | ×1.2 | ×0.92 | 4 | 4/s | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Jackal Stamping Finish** (Lv5: *Ultimate Revice Jackal Stamping Finish*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 201** · **Lv5 ≈ 422** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `revice_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Vice:** Jackal Genome! Nhanh như chó rừng, đấm đá liên hoàn. Máu hơi mỏng, bù lại chẳng ai đuổi kịp.

### 23.4 Mammoth Genome  ·  _form đặc biệt, rơi ở màn 23-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 210 | 60 | 80 | ×0.8 | ×1.45 | 20 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Mammoth Stamping Finish** (Lv5: *Ultimate Revice Mammoth Stamping Finish*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 369** · **Lv5 ≈ 776** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `revice_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Vice:** Mammoth Genome! To, chậm, nặng như voi ma-mút. Giáp nào cũng nát, cứ lừ lừ mà tiến.

---

## 24. Kamen Rider Geats · 2022

- **Driver:** Desire Driver · **Lối chơi:** Xạ thủ · form tăng tốc thời gian, form máy xây dựng · **Sức mạnh thế hệ:** ×3.76
- **Form gốc:** `magnum`
- **Form rơi ở màn luyện tập:** 24-2 → **Boost Form** · 24-3 → **Powered Builder Form** · 24-4 → **Magnum Boost Form**
- **Thưởng theo cấp:** Lv1: Magnum Form (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Geats IX: Final Attack x1.5
- **Lv5 — Geats IX:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Geats IX <tên chiêu>"

### 24.1 Magnum Form  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 150 | 20 | 130 | ×1.05 | ×1 | 6 | — | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **súng** — 7.5 sát thương/viên, hồi 0.28s, tốc độ 440, bay 0.9s, bán kính 3, đạn `ball` (viên đạn tròn).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Magnum Strike** (Lv5: *Geats IX Magnum Strike*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 188** · **Lv5 ≈ 395** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `geats_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Desire Driver khóa quanh eo {name}. Magnum Raise Buckle cắm vào, trên tay hiện ra khẩu súng trắng Magnum Shooter 40X.
> **Ace:** Không tệ, tay mới. Nhớ lấy: trong trò chơi này, ai có điều ước mạnh nhất thì trụ lại lâu nhất.
> **{name}:** Henshin!

### 24.2 Boost Form  ·  _form đặc biệt, rơi ở màn 24-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 135 | 10 | 175 | ×1.3 | ×0.95 | 4 | 10/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Kỹ năng riêng:** **Tăng tốc thời gian** (xem 0.5), chữ báo `CLOCK UP`.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | `time` | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | `time` | — |
| **Final Attack** | 16 | 5 | 0.2 / 0.08 / 0.5 | 40 | (60, -20) | `time` | lao tới 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Boost Grand Strike** (Lv5: *Geats IX Boost Grand Strike*)

- lao tới 200 rồi tung đòn (tầm 40); 5 nhịp × 16 = 80 sát thương gốc; hất văng (60, -20); gây trúng chắc quái Fast (tag time).
- Đây là Final dạng tăng tốc thời gian: chuỗi 5 đòn lướt liên hoàn thay cho Final của kiểu đòn.
- Tag: `time` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 286** · **Lv5 ≈ 400** (Final tăng tốc thời gian **không** nhận ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `geats_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Ace:** Boost Form. Tay đấm phụt lửa, nhanh như cáo. Bật lên là mọi thứ quanh cậu chậm lại, nhưng ngốn nộ cực nhanh.

### 24.3 Powered Builder Form  ·  _form đặc biệt, rơi ở màn 24-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 58 | 82 | ×0.8 | ×1.42 | 20 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Cú giáng Powered Builder** (Lv5: *Geats IX Cú giáng Powered Builder*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 374** · **Lv5 ≈ 785** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `geats_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Pen:** Powered Builder Form! Cả một cỗ máy xây dựng đeo trên người. Chậm, to, nặng, đòn nào cũng phá giáp.

### 24.4 Magnum Boost Form  ·  _form đặc biệt, rơi ở màn 24-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 28 | 145 | ×1.15 | ×1.2 | 9 | 4/s | Brawler (tay chân) |

**Vũ khí:** Nút Bắn: **súng** — 7 sát thương/viên, hồi 0.35s, tốc độ 420, bay 0.9s, bán kính 3, đạn `ball` (viên đạn tròn).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Magnum Boost Grand Victory** (Lv5: *Geats IX Magnum Boost Grand Victory*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 271** · **Lv5 ≈ 569** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `geats_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Ace:** Magnum Boost Form. Súng trong tay, lửa dưới chân, cân bằng mọi mặt. Từ đây mới là cao trào.

---

## 25. Kamen Rider Gotchard · 2023

- **Driver:** Gotchard Driver · **Lối chơi:** Cân bằng · Chemy ghép đôi: lướt ván, ngư lôi, khỉ đột lửa · **Sức mạnh thế hệ:** ×3.88
- **Form gốc:** `steamhopper`
- **Form rơi ở màn luyện tập:** 25-2 → **Appare Skebow** · 25-3 → **Venom Mariner** · 25-4 → **Burning Gorilla**
- **Thưởng theo cấp:** Lv1: Steamhopper (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Rainbow Gotchard: Final Attack x1.5
- **Lv5 — Rainbow Gotchard:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Rainbow Gotchard <tên chiêu>"

### 25.1 Steamhopper  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 160 | 25 | 130 | ×1.15 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Steamhopper Fever** (Lv5: *Rainbow Gotchard Steamhopper Fever*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 244** · **Lv5 ≈ 513** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `gotchard_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Hopper1:** Hopper! Hoppaa!
> **Dẫn truyện:** Hopper1 nhảy vào tay {name}, hóa thành thẻ bài. Cùng Steamliner, hai lá Ride Chemy Card cắm vào Gotchard Driver.
> **Houtarou:** Tụi nó chọn cậu rồi! Cái cảm giác tim đập rộn ràng này đó... gọi là Gotcha!
> **{name}:** Henshin!

### 25.2 Appare Skebow  ·  _form đặc biệt, rơi ở màn 25-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 135 | 10 | 172 | ×1.25 | ×0.92 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Appare Skebow Fever** (Lv5: *Rainbow Gotchard Appare Skebow Fever*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 161** · **Lv5 ≈ 337** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `gotchard_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Houtarou:** Appare Skebow! Lướt ván, chém như samurai. Nhanh lắm, nhưng nhẹ ký nên đừng đứng chịu đòn.

### 25.3 Venom Mariner  ·  _form đặc biệt, rơi ở màn 25-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 148 | 18 | 112 | ×1 | ×0.95 | 6 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **súng** — 5.5 sát thương/viên, hồi 0.45s, tốc độ 320, bay 0.9s, bán kính 4, đạn `ball` (viên đạn tròn), 2 viên xòe 0.18 rad.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Venom Mariner Fever** (Lv5: *Rainbow Gotchard Venom Mariner Fever*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 184** · **Lv5 ≈ 387** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `gotchard_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Houtarou:** Venom Mariner! Vai phóng ngư lôi, mỗi loạt hai quả. Chậm một chút, nhưng đứng xa mà nã thì khỏi lo.

### 25.4 Burning Gorilla  ·  _form đặc biệt, rơi ở màn 25-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 55 | 85 | ×0.85 | ×1.42 | 19 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Burning Gorilla Fever** (Lv5: *Rainbow Gotchard Burning Gorilla Fever*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 386** · **Lv5 ≈ 810** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `gotchard_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Houtarou:** Burning Gorilla! Nắm đấm khỉ đột bốc lửa. Chậm, nhưng đấm đâu vỡ đó, giáp nào cũng nát.

---

## 26. Kamen Rider Gavv · 2024

- **Driver:** Henshin Belt Gavv · **Lối chơi:** Đồ ngọt thành sức mạnh · form nảy, form bắn sô-cô-la, form kiếm giòn · **Sức mạnh thế hệ:** ×4
- **Form gốc:** `poppingummy`
- **Form rơi ở màn luyện tập:** 26-2 → **Fuwamallow Form** · 26-3 → **Chocodan Form** · 26-4 → **Zakuzakuchips Form**
- **Thưởng theo cấp:** Lv1: Poppingummy Form (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Over Mode: Final Attack x1.5
- **Lv5 — Over Mode:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Over Mode <tên chiêu>"

### 26.1 Poppingummy Form  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 25 | 130 | ×1.1 | ×1.05 | 7 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Poppingummy Finish** (Lv5: *Over Mode Poppingummy Finish*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 252** · **Lv5 ≈ 529** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `gavv_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** {name} bóc viên kẹo dẻo Shouma đưa. Một Gochizo nhỏ bật ra, nhảy tưng tưng rồi chui vào Henshin Belt Gavv.
> **Shouma:** Ngon đúng không? Cái cảm giác vui đó chính là sức mạnh của Gavv.
> **{name}:** Henshin!

### 26.2 Fuwamallow Form  ·  _form đặc biệt, rơi ở màn 26-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 12 | 160 | ×1.45 | ×0.9 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Fuwamallow Finish** (Lv5: *Over Mode Fuwamallow Finish*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 162** · **Lv5 ≈ 340** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `gavv_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shouma:** Fuwamallow! Mềm như kẹo bông, nảy tưng tưng. Nhảy cao, lơ lửng lâu, đánh nhẹ mà với xa.

### 26.3 Chocodan Form  ·  _form đặc biệt, rơi ở màn 26-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 145 | 15 | 115 | ×1 | ×0.95 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **súng** — 7.5 sát thương/viên, hồi 0.3s, tốc độ 420, bay 0.9s, bán kính 3, đạn `ball` (viên đạn tròn).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Chocodan Finish** (Lv5: *Over Mode Chocodan Finish*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 190** · **Lv5 ≈ 399** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `gavv_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shouma:** Chocodan! Bắn đạn sô-cô-la, chuẩn từng phát. Đứng xa mà ngắm, đừng lao vào.

### 26.4 Zakuzakuchips Form  ·  _form đặc biệt, rơi ở màn 26-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 175 | 35 | 108 | ×0.95 | ×1.3 | 13 | 4/s | Blade (kiếm) |

**Vũ khí:** Nút Chém: **kiếm (hình mặc định)** (3 nhát + nhát kết, bảng đòn blade).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| Chém (nhát thường) | 6 | 1 | 0.07 / 0.08 / 0.14 | 31 | (50, -20) | — | — |
| Chém (nhát kết) | 14 | 1 | 0.14 / 0.1 / 0.3 | 36 | (190, -70) | `heavy` | — |
| **Final Attack** | 65 | 1 | 0.5 / 0.22 / 0.45 | 46 | (260, -100) | `heavy` | lao tới 240, bật lên 60, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết. Chuỗi nút Chém: 3 nhát + 1 nhát kết.

</details>

**Tuyệt chiêu — Zakuzakuchips Finish** (Lv5: *Over Mode Zakuzakuchips Finish*)

- lao tới 240, bật lên 60 rồi tung đòn (tầm 46); 65 sát thương gốc; hất văng (260, -100).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 338** · **Lv5 ≈ 710** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `gavv_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Shouma:** Zakuzakuchips! Giòn rụm như khoai tây chiên, cầm kiếm Gavvgablade. Chém nặng, giáp vỡ giòn tan.

---

## 27. Kamen Rider Zeztz · 2025

- **Driver:** Zeztz Driver · **Lối chơi:** Đặc vụ trong mơ · form cánh dơi, form tia sét, form trọng lực · **Sức mạnh thế hệ:** ×4.12
- **Form gốc:** `impact`
- **Form rơi ở màn luyện tập:** 27-2 → **Physicam Wing** · 27-3 → **Inazuma Plasma** · 27-4 → **Paradigm Gravity**
- **Thưởng theo cấp:** Lv1: Physicam Impact (form gốc) → Lv2: sát thương +10%, máu +8% → Lv3: sát thương +20%, máu +16% → Lv4: sát thương +30%, máu +24% → Lv5: Exdream: Final Attack x1.5
- **Lv5 — Exdream:** tên hiện kèm form, mọi Final ×1.5 và đổi tên thành "Exdream <tên chiêu>"

### 27.1 Physicam Impact  ·  _form gốc, nhận ở màn Thức tỉnh_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 165 | 25 | 128 | ×1.05 | ×1.1 | 8 | — | Brawler (tay chân) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 60 | 1 | 0.5 / 0.25 / 0.4 | 30 | (260, -160) | `heavy` | lao tới 260, bật lên 120, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Impact Vanish** (Lv5: *Exdream Impact Vanish*)

- lao tới 260, bật lên 120 rồi tung đòn (tầm 30); 60 sát thương gốc; hất văng (260, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 272** · **Lv5 ≈ 571** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zeztz_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Dẫn truyện:** Zeztz Driver quấn chéo qua ngực {name}, không phải ngang eo. Viên Impact Capsem xoay tít rồi lóe sáng.
> **{name}:** Henshin!

### 27.2 Physicam Wing  ·  _form đặc biệt, rơi ở màn 27-2_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 140 | 12 | 125 | ×1.4 | ×0.95 | 5 | 4/s | Gunner (bắn) |

**Vũ khí:** Nút Bắn: **súng** — 6.5 sát thương/viên, hồi 0.38s, tốc độ 400, bay 0.7s, bán kính 3, đạn `ball` (viên đạn tròn), 2 viên xòe 0.12 rad, xuyên.

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 5 | 1 | 0.05 / 0.08 / 0.12 | 23 | (50, -20) | — | — |
| Đánh (đòn kết chuỗi) | 12 | 1 | 0.12 / 0.1 / 0.3 | 27 | (180, -70) | `heavy` | — |
| **Final Attack** | 50 | 1 | 0.6 / 0.1 / 0.4 | 180 | (200, -60) | `ranged` | không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Wing Vanish** (Lv5: *Exdream Wing Vanish*)

- phát bắn tầm xa (vùng trúng dài 170, chạm tới 180 trước mặt); 50 sát thương gốc; hất văng (200, -60).
- Tag: `ranged` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 196** · **Lv5 ≈ 411** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zeztz_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Baku:** Physicam Wing! Cánh dơi, nhảy cao, lượn xa, phóng lưỡi năng lượng xuyên qua cả hàng Nightmare.

### 27.3 Inazuma Plasma  ·  _form đặc biệt, rơi ở màn 27-3_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 130 | 10 | 182 | ×1.3 | ×0.92 | 4 | 4/s | Lancer (giáo / tầm xa, nhẹ) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 4 | 1 | 0.04 / 0.08 / 0.1 | 35 | (40, -20) | — | — |
| Đánh (đòn kết chuỗi) | 10 | 1 | 0.1 / 0.12 / 0.25 | 39 | (160, -60) | — | — |
| **Final Attack** | 45 | 1 | 0.45 / 0.2 / 0.4 | 44 | (240, -120) | — | lao tới 200, bật lên 200, không hủy được |

Chuỗi nút Đánh: 3 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Plasma Vanish** (Lv5: *Exdream Plasma Vanish*)

- lao tới 200, bật lên 200 rồi tung đòn (tầm 44); 45 sát thương gốc; hất văng (240, -120).
- Tag: `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 171** · **Lv5 ≈ 358** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zeztz_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Baku:** Inazuma Plasma! Điện chạy khắp người, nhanh như tia sét. Đòn nhẹ nhưng liên hoàn, máu thì mỏng.

### 27.4 Paradigm Gravity  ·  _form đặc biệt, rơi ở màn 27-4_

| Máu | Giáp | Tốc độ | Nhảy | Sức đánh | Trụ đòn | Nộ tụt | Kiểu đòn |
|---|---|---|---|---|---|---|---|
| 205 | 55 | 85 | ×0.82 | ×1.42 | 19 | 4/s | Heavy (nặng, phá giáp) |

**Vũ khí:** Chỉ tay chân (không nút Chém, không súng).

**Hiệu ứng hình ảnh:**

- Màu hiệu ứng: `#ffd980`
- Đòn trúng: `spark` — tia va chạm toả ra
- Final Attack trúng: `ring` — sóng chấn động dẹt

<details><summary>Bảng đòn chi tiết (Lv1)</summary>

| Đòn | Sát thương gốc | Nhịp | Khởi / Ra / Hồi | Tầm | Lực đẩy (x, y) | Tag | Ghi chú |
|---|---|---|---|---|---|---|---|
| Đánh (đòn thường) | 9 | 1 | 0.14 / 0.1 / 0.3 | 28 | (60, -20) | `heavy` | — |
| Đánh (đòn kết chuỗi) | 25 | 1 | 0.24 / 0.12 / 0.45 | 32 | (240, -100) | `heavy` | — |
| **Final Attack** | 70 | 1 | 0.55 / 0.2 / 0.5 | 35 | (300, -160) | `heavy` | không hủy được |

Chuỗi nút Đánh: 2 đòn thường + 1 đòn kết.

</details>

**Tuyệt chiêu — Gravity Vanish** (Lv5: *Exdream Gravity Vanish*)

- đứng tại chỗ tung đòn (tầm 35); 70 sát thương gốc; hất văng (300, -160).
- Tag: `heavy` + `final` (xuyên giáp Armored). Bất tử khi ra chiêu, không hủy được.
- Sát thương thực (chưa tính combo): **Lv1 ≈ 410** · **Lv5 ≈ 860** (đã gồm ×1.5 Lv5).
- Hình ảnh: trúng quái nổ sóng chấn động dẹt (màu `#ffd980`); tiếng nạp *final_charge* + giọng `zeztz_final`.

*Mô tả trong game (thoại lúc nhận form):*

> **Baku:** Paradigm Gravity! Găng tay trọng lực, chậm mà nặng. Đấm một phát là kẻ thù dính chặt xuống đất.

---

## Phụ lục: bảng so sánh mọi form

Chỉ số Lv1 chưa nhân sức mạnh thế hệ. *Final thực* = sát thương Final đã nhân `atk`, cấp và thế hệ (không tính combo).

| # | Rider | Form | Loại | Máu | Giáp | Tốc | Nhảy | ATK | Kiểu | Súng | Chém | Final Attack | Final thực Lv1 | Lv5 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Kuuga | Mighty Form | form gốc | 170 | 30 | 125 | 1 | 1 | brawler |  |  | Mighty Kick | 60 | 126 |
| 1 | Kuuga | Dragon Form | form đặc biệt | 130 | 5 | 175 | 1.35 | 0.8 | lancer |  | ✓ | Splash Dragon | 36 | 76 |
| 1 | Kuuga | Pegasus Form | form đặc biệt | 140 | 15 | 110 | 1 | 0.9 | gunner | ✓ |  | Blast Pegasus | 45 | 94 |
| 1 | Kuuga | Titan Form | form đặc biệt | 200 | 60 | 80 | 0.8 | 1.4 | heavy |  | ✓ | Calamity Titan | 98 | 206 |
| 2 | Agito | Ground Form | form gốc | 160 | 25 | 130 | 1.05 | 1.05 | brawler |  |  | Rider Kick | 71 | 148 |
| 2 | Agito | Storm Form | form đặc biệt | 135 | 10 | 170 | 1.25 | 0.9 | lancer |  | ✓ | Haldent Tornado | 45 | 95 |
| 2 | Agito | Flame Form | form đặc biệt | 170 | 30 | 110 | 0.95 | 1.25 | blade |  | ✓ | Saber Slash | 91 | 191 |
| 2 | Agito | Trinity Form | form đặc biệt | 175 | 35 | 135 | 1.1 | 1.3 | blade |  | ✓ | Fire Storm Attack | 99 | 208 |
| 3 | Ryuki | Ryuki | form gốc | 160 | 25 | 130 | 1.05 | 1.05 | brawler |  |  | Dragon Rider Kick | 78 | 164 |
| 3 | Ryuki | Ryuki Survive | form đặc biệt | 195 | 40 | 145 | 1.1 | 1.45 | blade | ✓ | ✓ | Dragon Fire Stream | 117 | 245 |
| 3 | Ryuki | Sword Vent | item | 165 | 28 | 122 | 1 | 1.25 | blade |  | ✓ | Drag Saber Slash | 101 | 212 |
| 3 | Ryuki | Strike Vent | item | 145 | 15 | 118 | 1 | 1 | gunner | ✓ |  | Dragclaw Fire | 62 | 130 |
| 3 | Ryuki | Guard Vent | item | 205 | 58 | 82 | 0.85 | 1.35 | heavy |  |  | Advent: Dragreder | 117 | 246 |
| 4 | Faiz | Faiz (form gốc) | form gốc | 125 | 15 | 155 | 1.05 | 1.2 | brawler | ✓ |  | Crimson Smash | 98 | 137 |
| 4 | Faiz | Axel Form | form đặc biệt | 125 | 15 | 155 | 1.05 | 1.2 | brawler |  |  | Accel Crimson Smash | 131 | 183 |
| 4 | Faiz | Blaster Form | form đặc biệt | 200 | 40 | 135 | 0.95 | 1.35 | brawler | ✓ |  | Crimson Smash | 110 | 154 |
| 5 | Blade | Ace Form | form gốc | 160 | 28 | 128 | 1.05 | 1.1 | blade |  |  | Lightning Blast | 106 | 222 |
| 5 | Blade | Mach Jaguar | item | 130 | 8 | 178 | 1.3 | 0.88 | lancer |  |  | Lightning Sonic | 59 | 123 |
| 5 | Blade | Thunder Deer | item | 140 | 15 | 118 | 1 | 1 | gunner | ✓ |  | Thunder Deer | 74 | 155 |
| 5 | Blade | Jack Form | form đặc biệt | 170 | 35 | 132 | 1.35 | 1.25 | blade |  |  | Lightning Slash | 120 | 253 |
| 6 | Hibiki | Hibiki | form gốc | 165 | 25 | 128 | 1.05 | 1.05 | brawler |  |  | Kaen Renda no Kata | 111 | 233 |
| 6 | Hibiki | Onibi | item | 145 | 15 | 120 | 1 | 1 | gunner | ✓ |  | Rekka Dan | 80 | 168 |
| 6 | Hibiki | Kaentsuzumi | item | 205 | 55 | 84 | 0.85 | 1.4 | heavy |  |  | Bakuretsu Kyouda no Kata | 157 | 329 |
| 6 | Hibiki | Hibiki Kurenai | form đặc biệt | 170 | 30 | 140 | 1.1 | 1.3 | blade |  | ✓ | Shakunetsu Shinku no Kata | 135 | 284 |
| 7 | Kabuto | Rider Form | form gốc | 155 | 22 | 138 | 1.1 | 1.05 | brawler |  |  | Rider Kick | 108 | 228 |
| 7 | Kabuto | Hyper Form | form đặc biệt | 175 | 30 | 160 | 1.25 | 1.3 | brawler |  |  | Hyper Kick | 179 | 250 |
| 8 | Den-O | Sword Form | form gốc | 165 | 25 | 130 | 1.05 | 1.15 | blade |  | ✓ | Extreme Slash | 144 | 302 |
| 8 | Den-O | Rod Form | form đặc biệt | 145 | 18 | 150 | 1.15 | 0.95 | lancer |  | ✓ | Solid Attack | 79 | 165 |
| 8 | Den-O | Ax Form | form đặc biệt | 210 | 55 | 82 | 0.85 | 1.42 | heavy |  | ✓ | Dynamic Chop | 183 | 384 |
| 8 | Den-O | Gun Form | form đặc biệt | 138 | 12 | 135 | 1.1 | 1 | gunner | ✓ |  | Wild Shot | 99 | 209 |
| 9 | Kiva | Kiva Form | form gốc | 160 | 22 | 135 | 1.15 | 1.05 | brawler |  |  | Darkness Moon Break | 123 | 259 |
| 9 | Kiva | Garulu Form | form đặc biệt | 140 | 15 | 160 | 1.2 | 1.2 | blade |  | ✓ | Garulu Howling Slash | 160 | 336 |
| 9 | Kiva | Basshaa Form | form đặc biệt | 145 | 20 | 115 | 1 | 1 | gunner | ✓ |  | Basshaa Aqua Tornado | 98 | 206 |
| 9 | Kiva | Dogga Form | form đặc biệt | 215 | 60 | 78 | 0.8 | 1.45 | heavy |  | ✓ | Dogga Thunder Slap | 199 | 418 |
| 10 | Decade | Decade | form gốc | 160 | 25 | 130 | 1.05 | 1.05 | brawler |  |  | Dimension Kick | 144 | 303 |
| 10 | Decade | Attack Ride: Slash | form đặc biệt | 165 | 28 | 120 | 1 | 1.25 | blade |  | ✓ | Dimension Slash | 169 | 355 |
| 10 | Decade | Attack Ride: Blast | form đặc biệt | 140 | 12 | 120 | 1 | 0.9 | gunner | ✓ |  | Dimension Blast | 94 | 197 |
| 10 | Decade | Kamen Ride: Kabuto | form đặc biệt | 130 | 10 | 165 | 1.2 | 0.95 | lancer |  |  | Rider Kick | 158 | 221 |
| 11 | W | CycloneJoker | form gốc | 150 | 20 | 145 | 1.2 | 1 | brawler |  |  | Joker Extreme | 143 | 230 |
| 11 | W | CycloneMetal | form đặc biệt | 150 | 45 | 145 | 1.2 | 1 | Joker |  | ✓ | Metal Branding | 154 | 216 |
| 11 | W | CycloneTrigger | form đặc biệt | 150 | 20 | 145 | 1.2 | 1 | Joker | ✓ |  | Trigger Full Burst | 158 | 222 |
| 11 | W | HeatJoker | form đặc biệt | 150 | 20 | 125 | 1.2 | 1.2 | brawler |  |  | Joker Extreme | 172 | 240 |
| 11 | W | HeatMetal | form đặc biệt | 150 | 45 | 125 | 1.2 | 1.2 | Joker |  | ✓ | Metal Branding | 185 | 298 |
| 11 | W | HeatTrigger | form đặc biệt | 150 | 20 | 125 | 1.2 | 1.2 | Joker | ✓ |  | Trigger Full Burst | 190 | 266 |
| 11 | W | LunaJoker | form đặc biệt | 150 | 20 | 125 | 1.2 | 1 | brawler |  |  | Joker Extreme | 143 | 200 |
| 11 | W | LunaMetal | form đặc biệt | 150 | 45 | 125 | 1.2 | 1 | Joker |  | ✓ | Metal Branding | 154 | 216 |
| 11 | W | LunaTrigger | form đặc biệt | 150 | 20 | 125 | 1.2 | 1 | Joker | ✓ |  | Trigger Full Burst | 158 | 255 |
| 11 | W | CycloneJokerXtreme | form đặc biệt | 190 | 20 | 145 | 1.2 | 1.2 | brawler |  |  | Xtreme Golden Extreme | 172 | 240 |
| 12 | OOO | TaToBa Combo | form gốc | 160 | 25 | 130 | 1.2 | 1.05 | brawler |  |  | Tatoba Kick | 175 | 368 |
| 12 | OOO | LaTorarTar Combo | form đặc biệt | 130 | 10 | 182 | 1.25 | 0.95 | lancer |  |  | Gush Cross | 115 | 241 |
| 12 | OOO | GataKiriBa Combo | form đặc biệt | 148 | 18 | 148 | 1.38 | 1.08 | blade |  | ✓ | Gatakiriba Kick | 195 | 410 |
| 12 | OOO | ShaUTa Combo | form đặc biệt | 150 | 15 | 135 | 1.15 | 0.95 | lancer |  | ✓ | Octo Banish | 110 | 231 |
| 12 | OOO | TaJaDor Combo | form đặc biệt | 165 | 25 | 138 | 1.3 | 1.15 | gunner | ✓ |  | Magna Blaze | 133 | 280 |
| 12 | OOO | SaGohZo Combo | form đặc biệt | 212 | 60 | 80 | 0.8 | 1.42 | heavy | ✓ |  | Sagohzo Impact | 181 | 381 |
| 12 | OOO | PuToTyra Combo | form đặc biệt | 190 | 38 | 108 | 1.1 | 1.48 | heavy |  | ✓ | Strain Doom | 258 | 541 |
| 12 | OOO | BuraKaWani Combo | form đặc biệt | 200 | 64 | 100 | 0.9 | 0.98 | brawler |  |  | Burakawani Scanning Charge | 136 | 286 |
| 13 | Fourze | Base States | form gốc | 160 | 25 | 130 | 1.1 | 1.05 | brawler |  |  | Rider Rocket Drill Kick | 164 | 344 |
| 13 | Fourze | Rocket States | form đặc biệt | 130 | 8 | 180 | 1.35 | 0.9 | lancer |  |  | Rider Rocket Punch | 99 | 208 |
| 13 | Fourze | Elek States | form đặc biệt | 165 | 28 | 118 | 1 | 1.25 | blade |  | ✓ | Rider 10 Billion Volt Break | 198 | 416 |
| 13 | Fourze | Fire States | form đặc biệt | 150 | 20 | 115 | 1 | 0.95 | gunner | ✓ |  | Rider Bakunetsu Shoot | 116 | 243 |
| 14 | Wizard | Flame Style | form gốc | 160 | 25 | 130 | 1.1 | 1.05 | brawler |  |  | Strike Wizard | 161 | 339 |
| 14 | Wizard | Water Style | form đặc biệt | 145 | 15 | 125 | 1.05 | 0.95 | gunner | ✓ |  | Shooting Strike | 131 | 276 |
| 14 | Wizard | Hurricane Style | form đặc biệt | 130 | 8 | 175 | 1.4 | 0.9 | lancer |  | ✓ | Slash Strike | 111 | 232 |
| 14 | Wizard | Land Style | form đặc biệt | 205 | 58 | 82 | 0.8 | 1.4 | heavy |  |  | Strike Wizard (Land) | 251 | 527 |
| 15 | Gaim | Orange Arms | form gốc | 160 | 25 | 130 | 1.05 | 1.1 | blade |  | ✓ | Naginata Musou Slicer | 192 | 402 |
| 15 | Gaim | Pine Arms | form đặc biệt | 200 | 55 | 85 | 0.85 | 1.4 | heavy |  | ✓ | Pine Squash | 263 | 552 |
| 15 | Gaim | Ichigo Arms | form đặc biệt | 132 | 10 | 175 | 1.3 | 0.9 | lancer | ✓ |  | Ichigo Squash | 125 | 263 |
| 15 | Gaim | Jimber Lemon Arms | form đặc biệt | 150 | 20 | 120 | 1.05 | 1 | gunner | ✓ |  | Sonic Volley | 155 | 326 |
| 16 | Drive | Type Speed | form gốc | 155 | 22 | 140 | 1.05 | 1.05 | brawler |  | ✓ | SpeeDrop | 176 | 370 |
| 16 | Drive | Type Wild | form đặc biệt | 205 | 55 | 85 | 0.85 | 1.4 | heavy |  | ✓ | Full Throttle: Wild | 274 | 576 |
| 16 | Drive | Type Technic | form đặc biệt | 145 | 18 | 118 | 1 | 0.95 | gunner | ✓ |  | Full Throttle: Technic | 144 | 302 |
| 16 | Drive | Type Formula | form đặc biệt | 130 | 10 | 180 | 1.25 | 0.95 | lancer |  |  | Formula Drop | 213 | 298 |
| 17 | Ghost | Ore Damashii | form gốc | 158 | 24 | 132 | 1.15 | 1.05 | brawler |  | ✓ | Omega Drive | 184 | 386 |
| 17 | Ghost | Musashi Damashii | form đặc biệt | 165 | 26 | 122 | 1 | 1.25 | blade |  | ✓ | Omega Slash | 248 | 521 |
| 17 | Ghost | Edison Damashii | form đặc biệt | 145 | 15 | 118 | 1 | 0.95 | gunner | ✓ |  | Omega Shoot | 139 | 291 |
| 17 | Ghost | Newton Damashii | form đặc biệt | 200 | 52 | 85 | 0.85 | 1.4 | heavy |  |  | Omega Drive | 286 | 601 |
| 18 | Ex-Aid | Action Gamer Level 2 | form gốc | 155 | 22 | 135 | 1.25 | 1.05 | brawler |  | ✓ | Mighty Critical Strike | 211 | 442 |
| 18 | Ex-Aid | Sports Action Gamer Level 3 | form đặc biệt | 135 | 12 | 175 | 1.2 | 0.9 | lancer | ✓ |  | Shakariki Critical Strike | 131 | 276 |
| 18 | Ex-Aid | Robot Action Gamer Level 3 | form đặc biệt | 205 | 55 | 84 | 0.85 | 1.42 | heavy |  |  | Gekitotsu Critical Strike | 302 | 635 |
| 18 | Ex-Aid | Hunter Action Gamer Level 5 | form đặc biệt | 170 | 35 | 108 | 0.95 | 1.05 | gunner | ✓ | ✓ | Drago Knight Critical Strike | 160 | 335 |
| 19 | Build | RabbitTank | form gốc | 160 | 28 | 132 | 1.3 | 1.05 | brawler |  |  | Vortex Finish | 199 | 418 |
| 19 | Build | GorillaMond | form đặc biệt | 205 | 58 | 82 | 0.85 | 1.42 | heavy |  |  | Vortex Finish | 314 | 660 |
| 19 | Build | HawkGatling | form đặc biệt | 140 | 14 | 125 | 1.35 | 0.9 | gunner | ✓ |  | Full Bullet | 142 | 299 |
| 19 | Build | NinninComic | form đặc biệt | 138 | 14 | 170 | 1.3 | 1.1 | blade |  | ✓ | Kaen Giri | 226 | 474 |
| 20 | Zi-O | Zi-O | form gốc | 160 | 25 | 130 | 1.05 | 1.05 | brawler |  |  | Time Break | 207 | 434 |
| 20 | Zi-O | Build Armor | form đặc biệt | 140 | 15 | 165 | 1.25 | 0.95 | lancer |  |  | Vortex Time Break | 140 | 294 |
| 20 | Zi-O | Ex-Aid Armor | form đặc biệt | 200 | 52 | 85 | 0.9 | 1.4 | heavy |  |  | Critical Time Break | 321 | 675 |
| 20 | Zi-O | Decade Armor | form đặc biệt | 170 | 32 | 128 | 1.05 | 1.25 | blade |  | ✓ | Attack Time Break | 266 | 560 |
| 21 | Zero-One | Rising Hopper | form gốc | 155 | 22 | 135 | 1.35 | 1.05 | brawler |  |  | Rising Impact | 214 | 450 |
| 21 | Zero-One | Flaming Tiger | form đặc biệt | 150 | 18 | 142 | 1.15 | 1.2 | blade |  | ✓ | Flaming Impact | 265 | 557 |
| 21 | Zero-One | Freezing Bear | form đặc biệt | 205 | 55 | 84 | 0.85 | 1.38 | heavy |  |  | Freezing Impact | 328 | 690 |
| 21 | Zero-One | Shining Hopper | form đặc biệt | 132 | 10 | 180 | 1.4 | 0.95 | lancer |  |  | Shining Impact | 145 | 305 |
| 22 | Saber | Brave Dragon | form gốc | 160 | 25 | 130 | 1.05 | 1.12 | blade |  | ✓ | Kaen Juujizan | 256 | 538 |
| 22 | Saber | Crimson Dragon | form đặc biệt | 140 | 14 | 168 | 1.35 | 0.95 | lancer |  |  | Sansatsu Giri | 150 | 316 |
| 22 | Saber | Dragonic Knight | form đặc biệt | 205 | 58 | 84 | 0.85 | 1.4 | heavy |  |  | Shinka Ryuuhazan | 345 | 724 |
| 22 | Saber | Elemental Primitive Dragon | form đặc biệt | 165 | 28 | 145 | 1.1 | 1.3 | blade |  | ✓ | Hissatsu Dokuha | 297 | 625 |
| 23 | Revice | Rex Genome | form gốc | 160 | 25 | 130 | 1.05 | 1.05 | brawler |  |  | Rex Stamping Finish | 229 | 482 |
| 23 | Revice | Eagle Genome | form đặc biệt | 140 | 12 | 150 | 1.45 | 0.95 | lancer |  |  | Eagle Stamping Finish | 156 | 327 |
| 23 | Revice | Jackal Genome | form đặc biệt | 130 | 8 | 180 | 1.2 | 0.92 | brawler |  |  | Jackal Stamping Finish | 201 | 422 |
| 23 | Revice | Mammoth Genome | form đặc biệt | 210 | 60 | 80 | 0.8 | 1.45 | heavy |  |  | Mammoth Stamping Finish | 369 | 776 |
| 24 | Geats | Magnum Form | form gốc | 150 | 20 | 130 | 1.05 | 1 | gunner | ✓ |  | Magnum Strike | 188 | 395 |
| 24 | Geats | Boost Form | form đặc biệt | 135 | 10 | 175 | 1.3 | 0.95 | lancer |  |  | Boost Grand Strike | 286 | 400 |
| 24 | Geats | Powered Builder Form | form đặc biệt | 205 | 58 | 82 | 0.8 | 1.42 | heavy |  |  | Cú giáng Powered Builder | 374 | 785 |
| 24 | Geats | Magnum Boost Form | form đặc biệt | 165 | 28 | 145 | 1.15 | 1.2 | brawler | ✓ |  | Magnum Boost Grand Victory | 271 | 569 |
| 25 | Gotchard | Steamhopper | form gốc | 160 | 25 | 130 | 1.15 | 1.05 | brawler |  |  | Steamhopper Fever | 244 | 513 |
| 25 | Gotchard | Appare Skebow | form đặc biệt | 135 | 10 | 172 | 1.25 | 0.92 | lancer |  |  | Appare Skebow Fever | 161 | 337 |
| 25 | Gotchard | Venom Mariner | form đặc biệt | 148 | 18 | 112 | 1 | 0.95 | gunner | ✓ |  | Venom Mariner Fever | 184 | 387 |
| 25 | Gotchard | Burning Gorilla | form đặc biệt | 205 | 55 | 85 | 0.85 | 1.42 | heavy |  |  | Burning Gorilla Fever | 386 | 810 |
| 26 | Gavv | Poppingummy Form | form gốc | 165 | 25 | 130 | 1.1 | 1.05 | brawler |  |  | Poppingummy Finish | 252 | 529 |
| 26 | Gavv | Fuwamallow Form | form đặc biệt | 140 | 12 | 160 | 1.45 | 0.9 | lancer |  |  | Fuwamallow Finish | 162 | 340 |
| 26 | Gavv | Chocodan Form | form đặc biệt | 145 | 15 | 115 | 1 | 0.95 | gunner | ✓ |  | Chocodan Finish | 190 | 399 |
| 26 | Gavv | Zakuzakuchips Form | form đặc biệt | 175 | 35 | 108 | 0.95 | 1.3 | blade |  | ✓ | Zakuzakuchips Finish | 338 | 710 |
| 27 | Zeztz | Physicam Impact | form gốc | 165 | 25 | 128 | 1.05 | 1.1 | brawler |  |  | Impact Vanish | 272 | 571 |
| 27 | Zeztz | Physicam Wing | form đặc biệt | 140 | 12 | 125 | 1.4 | 0.95 | gunner | ✓ |  | Wing Vanish | 196 | 411 |
| 27 | Zeztz | Inazuma Plasma | form đặc biệt | 130 | 10 | 182 | 1.3 | 0.92 | lancer |  |  | Plasma Vanish | 171 | 358 |
| 27 | Zeztz | Paradigm Gravity | form đặc biệt | 205 | 55 | 85 | 0.82 | 1.42 | heavy |  |  | Gravity Vanish | 410 | 860 |

