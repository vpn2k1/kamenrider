# Kế hoạch sản xuất — Thế giới 1 (Kuuga)

> 29/09/2026 · Đã dùng 29/40 lượt PixelLab, còn 11 (đủ cho bước 4: tileset ~8 lượt).
> Mục tiêu: **5 màn 1-1 → 1-B chơi được hoàn chỉnh**, có hình thật (PixelLab + vẽ bằng code), màn cuộn ngang thật thay cho đấu trường thử nghiệm.
> Nội dung cốt truyện của từng màn nằm ở GDD mục 2.5. File này chỉ lo **làm gì, bằng gì, theo thứ tự nào**.

---

## 1. Thiết kế 5 màn

Cấp quái theo công thức trong GDD (mục 3.13): 1-1 Lv1 → 1-4 Lv4, 1-B Lv5, trùm Lv7.

| Màn | Bối cảnh | Người chơi có | Cấu trúc | Quái | Cổng kỹ năng / sự kiện | Thưởng |
|---|---|---|---|---|---|---|
| **1-1** Shibuya hỗn loạn | Phố đêm, trời nứt tím | Dạng người | Đi đường (hướng dẫn di chuyển, nhảy qua xe) → **đấu trường A**: 2 Grongi (hướng dẫn đánh, né) → Pen xuất hiện → **đấu trường B**: 3 Grongi + đầu lĩnh (hướng dẫn thanh năng lượng và Đá xoay) → Arcle rơi (từ quái bất kỳ, hoặc đầu lĩnh nếu chưa rơi) → nhặt → biến thân Mighty, nộ đầy → 2 Grongi để thử sức → Void xuất hiện | Grongi Zu ×7, đầu lĩnh ×1, lính bắn (dạy cúi / nhảy né đạn) | Lần biến thân đầu tiên, dạy thanh nộ | Arcle → Mighty, Lv1 |
| **1-2** Di tích Kuuga | Đá cổ, rêu, đuốc | Mighty | Đi đường có vài bậc nhảy → đấu trường ×2 → Godai nói chuyện đầu và cuối màn | Grongi Zu ×6 | Cửa đá chỉ mở khi hết quái | Quái rơi Dragon · Lv2 |
| **1-3** Tokyo về đêm | Sân thượng, bảng hiệu neon | Mighty, Dragon | Nhảy qua các nóc nhà → đấu trường ×2 → thanh tra Ichijo bắn yểm trợ (sự kiện có kịch bản) | Zu ×4, **Go giáp ×1** cuối màn | Grongi hạng Me nhảy xuống từ trên cao | Quái rơi Pegasus · Lv3 |
| **1-4** Kho hàng bến cảng | Container, cần cẩu | Mighty, Dragon, Pegasus | Tường container cao **cần Dragon** nhảy qua → công tắc trên cao **cần Pegasus** bắn để mở cửa → đấu trường ×2 | Zu ×4, Go giáp ×2 | Hai cổng kỹ năng (nộ phải đủ để giữ Dragon / Pegasus tới cổng) | Quái rơi Titan · Lv4 |
| **1-B** Núi tuyết | Đỉnh núi, bão tuyết | Đủ 4 form | Một đấu trường rộng 1 màn hình | 2 Zu mở màn, **N-Daguba-Zeba** | Pha 1 cận chiến (dùng Titan đỡ) · pha 2 lửa chạy trên mặt đất (dùng Dragon nhảy) · pha 3 đốt từ xa (dùng Pegasus bắn từ chỗ nấp) | Lv5 Rising + Faiz Driver |

**Thay đổi so với dữ liệu hiện tại (`world_data.gd`):** thêm đợt quái sau khi nhặt Driver ở 1-1 (để thử biến thân), thêm loại quái "đầu lĩnh", và gắn tên sprite cho từng loại quái.

---

## 2. Danh sách hình ảnh

### 2.1 Tạo bằng PixelLab (tốn lượt)

| Hạng mục | Chi tiết | Lượt |
|---|---|---|
| ✅ Thiết kế đã tạo | Kuuga Mighty, Grongi Zu, Orphnoch, Dopant (hai cái sau để dành cho thế giới 2, 3) | 4 (đã dùng) |
| Sora dạng người | tạo hình + đứng yên, chạy, đấm, đá, bị đánh, gục | 7 |
| Kuuga Mighty | đứng yên, chạy, nhảy, đấm, đá cao, bị đánh, Rider Kick (`flying-kick`) | 7 |
| Grongi Zu | đi, đấm, bị đánh, gục | 4 |
| N-Daguba-Zeba | tạo hình 64 px + đi, đánh, bị đánh | 4 |
| Tileset | phố (1-1, 1-3) · đá cổ (1-2) · kho cảng (1-4). Núi tuyết dùng lại bộ đá cổ rồi đổi màu | 3 × ~2.6 ≈ 8 |
| **Tổng** | | **34 / 40**, còn khoảng 6 lượt để làm lại |

### 2.2 Làm miễn phí bằng code (Python trên máy)

- **Kuuga Dragon / Pegasus / Titan:** đổi màu từ bộ frame của Mighty, vẽ thêm gậy, súng cung, kiếm. (Growing đã bỏ khỏi game, sprite cũ để nguyên.)
- **Grongi hạng Go (giáp), hạng Me, đầu lĩnh:** đổi màu và thêm chi tiết từ Grongi Zu.
- **Cảnh biến hình:** ghép từ frame của Sora và Kuuga, cộng hiệu ứng vòng sáng và chớp trắng có sẵn trong `gen_sprites.py`. Không tốn lượt PixelLab.
- **Hiệu ứng** (lửa Mighty Kick, tia Pegasus, vệt chém): dùng lại từ `gen_sprites.py`.
- **Nền parallax 5 màn:** vẽ bằng code (trời, dãy nhà, núi, 2–3 lớp trôi với tốc độ khác nhau).
- **Đồ vật:** thùng hàng, xe, công tắc, cửa đá.

---

## 3. Việc code

| # | Việc | Ghi chú |
|---|---|---|
| C1 | **Công cụ import PixelLab** (`tools/import_pixellab.py`) | Tải spritesheet → cắt frame hướng `east` → căn chân chạm đáy ô → ghi SpriteFrames theo đúng tên animation game đang dùng. Animation nào chưa có thì giữ bản vẽ bằng code |
| C2 | **Đổi tỉ lệ game** | Nhân vật PixelLab cao ~60 px (sprite tạm ~32 px). Đổi viewport **320×180 → 480×270** và nhân hitbox, hurtbox, vùng va chạm, tầm đánh lên khoảng ×1.8 (gom thành một hằng số tỉ lệ) |
| C3 | **Quái có sprite** | Mỗi loại quái có bộ animation riêng (`grongi_zu_walk`...); `WorldData` thêm khóa `sprite` |
| C4 | **Hệ thống màn chơi** | Scene mẫu cho một màn gồm: TileMapLayer, nền parallax, `StageManager` (đọc dữ liệu màn), `ArenaTrigger` (khóa camera, dựng tường, chạy các đợt quái), điểm kết thúc màn |
| C5 | **Hội thoại** | Hộp thoại dưới màn hình, đọc lời thoại từ JSON (dữ liệu từ GDD mục 2.5), dừng game khi đang nói |
| C6 | **Cổng kỹ năng** | Tường cao (chỉ Dragon nhảy tới), công tắc (chỉ đòn `ranged` bật được), cửa mở khi hết quái |
| C7 | **Lớp Boss** | Kế thừa `Enemy`, chuyển pha ở 66% và 33% máu, mỗi pha một danh sách chiêu. Daguba có lửa chạy trên mặt đất và cầu lửa bắn xa |
| C8 | **Dựng 5 màn** | Vẽ bản đồ bằng tileset, đặt đấu trường, NPC, sự kiện |
| C9 | **Chơi thử và cân bằng** | Máu và sát thương quái theo cấp, số đợt quái, độ dài màn |

---

## 4. Thứ tự làm

| Bước | Nội dung | Lượt PixelLab | Duyệt |
|---|---|---|---|
| 1 | ✅ Tạo 4 thiết kế nhân vật đầu tiên | 4 | ✅ |
| 2 | ✅ Thiết kế nhân vật chính (tóc đen) và Daguba; Kuuga Mighty sửa tay cho giống bản gốc rồi dựng lại bằng PixelLab | 5 | ✅ |
| 3 | ✅ Animation: Kuuga (7), nhân vật chính (6), Grongi (4), Daguba (3) | 20 | ✅ |
| 4 | 3 bộ tileset | ~8 | Bạn duyệt |
| 5 | ✅ Code C1 → C3: `tools/import_pixellab.py`, tỉ lệ `Units.SCALE = 1.8`, viewport 480×270, quái có sprite. Đấu trường thử nghiệm dùng hình thật | 0 | Chơi thử (cần Godot) |
| 6 | Code C4 → C7: hệ thống màn chơi, hội thoại, cổng kỹ năng, Boss | 0 | |
| 7 | Dựng màn 1-1 hoàn chỉnh, sau đó 1-2 → 1-B | 0 | Chơi thử từng màn |
| 8 | Cân bằng, sửa lỗi | 0 | |

Bước 5–8 không tốn lượt PixelLab, làm song song được với việc chờ bạn duyệt hình.
Cần **cài Godot** trước bước 5 để chạy thử được.
