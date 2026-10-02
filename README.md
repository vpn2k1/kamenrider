# Kamen Rider: Chrono Henshin (fan game)

Game 2D pixel đánh quái, đi qua chuỗi các thế giới Kamen Rider. Quái rơi ra Driver để biến thân và các form đặc biệt của Rider; Rider lên cấp qua từng màn, và trùm cuối mỗi thế giới rơi ra Driver của thế giới tiếp theo. Fan game phi thương mại.

**Cốt truyện:** có vô số Trái Đất song song, mỗi Trái Đất là một thế giới Rider. Trùm cuối **Chronos Void** hút hết sức mạnh Driver của mọi Rider rồi trốn tới Trái Đất **Điểm Không**, khóa đường sau lưng bằng Chuỗi Phong Ấn. Nhân vật chính, một shipper ở Tokyo 2026, được **Pen** (AI trong tấm vé Chrono Pass) giao nhiệm vụ đi qua từng Trái Đất lấy lại sức mạnh các Driver. Phần mở đầu kể chuyện này; trong màn có hội thoại dạng chữ để theo dõi diễn biến (GDD mục 2.1, 2.5, 3.18).

- Tài liệu thiết kế (kịch bản, logic, lộ trình): [docs/GDD.md](docs/GDD.md)
- Engine: **Godot 4.4 trở lên** (https://godotengine.org)

## Chạy bản mẫu

1. Cài Godot 4.4+ (bản Standard). Trên macOS: `brew install --cask godot`.
2. Mở Godot → **Import** → chọn `project.godot` trong thư mục này.
3. Bấm **F5**. Màn hình chính có 2 lựa chọn: **CHƠI** (hành trình qua các thế giới) và **COMBAT** (đấu 2 người cùng WiFi, xem mục dưới); cả hai đều qua màn đặt tên (◀ Quay lại / Esc để về màn hình chính). CHƠI: đặt tên nhân vật → **phần mở đầu** (6 cảnh + thẻ tựa; Esc / "BỎ QUA" để bỏ qua) → lần đầu chơi vào thẳng **màn 1-1** (thế giới Kuuga); các lần sau là **màn chọn thế giới → chọn màn**.

**Chạy trên web:** xuất bản web rồi mở http://localhost:8060 (lần đầu cài template: Godot → **Editor → Manage Export Templates → Download and Install**):

```bash
mkdir -p export/web && godot --headless --path . --export-release "Web" export/web/index.html && python3 -m http.server 8060 -d export/web
```

**27 thế giới theo năm phát sóng**, chơi liền mạch 135 màn: Kuuga (2000) → Agito → Ryuki → Faiz → Blade → Hibiki → Kabuto → Den-O → Kiva → Decade → W (2009) → OOO → Fourze → Wizard → Gaim → Drive → Ghost → Ex-Aid → Build → Zi-O → Zero-One → Saber → Revice → Geats → Gotchard → Gavv → Zeztz (2025). Mã màn "4-1" = thế giới 4 (Faiz), màn 1. Mỗi thế giới 5 màn: Thức tỉnh (quái rơi Driver), 3 màn luyện tập (mỗi màn quái rơi một form), trùm (rơi Driver của thế giới kế tiếp; thế giới 27 rơi Chrono Driver). Mỗi màn là một **lộ trình kiểu Contra / Contra 2** gồm nhiều đoạn: chạy sang phải, **chạy ngược sang trái**, **leo giếng lên** (bệ zig-zag), **tụt giếng xuống**. **Camera đi theo cả hai chiều**: chạy ngược lại, leo ngược giếng đều được; chỉ bị chặn ở đầu màn (sau điểm xuất phát), cuối màn và hai bên đấu trường trùm. Quái đã xuất hiện ở lại chỗ của nó, quay lại vẫn gặp. Trên đường có vực, bệ, **thùng và bậc khối để nhảy lên** (khối chặn được đạn), cột đá giữa vực rộng. Quái chạy ào từ mép màn hình rồi dừng lại đánh khi tới gần, lính bắn đứng gác; tối đa 2 quái đánh cùng lúc, đánh xong nghỉ 1 giây để nhường lượt. **Phải diệt hết quái** rồi tới vạch đích ở cuối lộ trình mới qua màn (HUD ghi số quái còn lại và hướng tới con gần nhất; quái chạy ngang ra khỏi màn hình sẽ quay lại chứ không biến mất). Màn Thức tỉnh: đánh nhóm canh giữ; màn trùm: đấu trường khóa camera, quái không ra khỏi đấu trường được. Lộ trình từng màn nằm ở `"route"` trong `WorldData`, bảng đầy đủ ở GDD mục 3.14.

**Chọn màn, Rider, item:**
- **Màn chọn màn** hiện sau mỗi màn và khi bấm **Menu** (Esc / P / nút ≡ bên trái thanh máu) trong màn; lần đầu chơi (chưa qua màn nào) thì vào thẳng 1-1. Hai bước: **chọn thế giới** (mỗi hàng một thế giới đã mở, 5 ô nhỏ cho biết màn đã qua; chỉ mới mở một thế giới thì bỏ qua bước này) rồi **chọn màn** của thế giới đó (5 ô màn; Esc / nút "◀ THẾ GIỚI" để quay lại); màn mở dần (qua màn xa nhất thì mở màn kế), màn đã mở **chơi lại được** để luyện cấp và nhặt item còn thiếu. Ô màn ghi món quái rơi (Driver / form / item, ✓ nếu đã có).
- Trước khi vào màn chọn **một Rider** (khi có từ 2 Rider), trong màn **không đổi sang Rider khác** (bỏ phím / nút Đổi Rider). Rồi chọn **tối đa 2 item** của Rider đó để mang theo.
- **Item** là form chỉ gồm vũ khí / lá bài / đòn (`"item": true` trong RIDER): Ryuki Sword / Strike / Guard Vent, Blade Mach Jaguar / Thunder Deer, Hibiki Onibi / Kaentsuzumi. Quái ở màn có item đó rơi ra (không bắt buộc, lỡ thì chơi lại màn); vào màn bằng nút Kỹ năng (L) như form, item không mang thì không dùng được; nhặt giữa màn thì dùng được ngay. Form đổi ngoại hình thật (Kuuga, Agito, Faiz, Blade Jack, Hibiki Kurenai, Kabuto Hyper) vẫn rơi ở màn cố định như cũ.
- Nhặt Driver / form / item của **Rider khác** Rider đang dùng thì chỉ mở khóa, dùng ở màn sau.

**Luật chính:**
- **Chỉ form có súng mới bắn được** (ví dụ Kuuga Pegasus, Faiz, W nửa Trigger, Ryuki Strike Vent, Den-O Gun Form...). Dạng người và các form khác phải đánh gần.
- **Rider thế hệ sau mạnh hơn:** máu và sát thương × (1 + 0.12 × số thứ tự thế giới), hiện ở màn chọn Rider là "Sức mạnh ×N". Quái cũng mạnh dần theo cùng nhịp, nên nên dùng Rider mới nhất làm Rider chính.
- **Màn đầu dễ thở:** chưa có Driver (màn 1-1) quái chỉ gây 35% sát thương; thế giới 1 tăng dần 60% → 75% → 90% → 100% ở trùm. Trúng đòn xong được bất tử ngắn (người 0.6 giây, Rider 0.35 giây).
- **Quái bắn đạn bay ngang ở 2 độ cao:** quái ửng **đỏ**, đạn đỏ ngang ngực thì **cúi** (S). Quái ửng **xanh**, đạn xanh sát đất thì **nhảy**. Né (Shift) không tránh được đạn.
- **Quái rơi đồ ngẫu nhiên**, mỗi lúc chỉ một món, tồn tại 10 giây. Mỗi màn có một món chính: Driver của thế giới (màn X-1) hoặc form của màn (xem bảng dưới). Càng hạ nhiều quái mà chưa rơi thì tỉ lệ rơi càng cao. Nhặt **lần đầu** thì mở khóa, **nộ đầy** và **biến thân ngay** vào form đó. Tới vạch đích mà chưa nhặt được thì món đó rơi ở vạch đích. Khi đã có món chính, quái thỉnh thoảng rơi **nạp nộ** (+40).
- **Qua màn:** quái và đạn còn lại tan biến, nhân vật **giải trừ biến thân về dạng người** (cảnh biến thân chạy ngược), rồi thoại và bảng kết quả. Màn hình tối dần, màn mới **đổi nền theo bối cảnh** (14 nền: di tích Nagano, tháp Tokyo, bến cảng, cao tốc, phòng thí nghiệm, tháp gió Fuuto...) rồi sáng dần.
- **Vào màn** (kể cả chơi lại từ checkpoint): luôn ở **dạng người, máu người đầy, nộ đầy**. Đã có Driver thì bấm **Biến thân (I)** lúc nào cũng được; banner đầu màn nhắc việc này.
- **Thanh nộ là nhiên liệu của form đặc biệt:** ở form đặc biệt nộ tụt dần (khoảng 25 giây nếu đầy; riêng Faiz Axel 10 giây), đánh trúng cũng không được cộng. Hết nộ thì tự về **form gốc** (Kuuga Mighty, Faiz, W CycloneJoker). Máu Rider và Henshin Break giữ nguyên như cũ.

```
1-1 dạng người, hạ quái → Arcle rơi ra → nhặt → Kuuga Mighty Lv1
1-2 … 1-4 quái rơi Dragon / Pegasus / Titan; qua màn Kuuga +1 cấp (sát thương, máu)
1-B trùm Daguba → Kuuga Lv5 (Rising) → rơi Alter Ring (phong ấn)
2-1 dùng Kuuga, hạ quái → Alter Ring rơi ra → Agito Lv1 … và tiếp tục như vậy qua 27 thế giới
```

Bảng Rider, form, trùm của cả 27 thế giới: GDD mục 2.8.

Rơi vực mất 25% máu rồi hồi sinh ở chỗ đứng an toàn trong màn hình. Gục thì chơi lại từ checkpoint gần nhất; cấp và Driver đã có vẫn giữ nguyên. **Tiến trình được lưu trên máy** (`user://save.json`; bản web lưu trong trình duyệt): Driver, cấp, form và item đã nhặt, màn đã qua, bộ đã chọn cho COMBAT. Nhặt Driver / form / item giữa màn là lưu ngay, tắt game giữa chừng cũng không mất. Muốn mỗi lần mở game đều chơi lại từ 1-1 thì đặt `GameState.DEBUG_FRESH_START = true`. Các bot test chạy với tiến trình trống riêng (`GameState.use_test_profile()`), không đọc cũng không ghi đè save thật.

Bật **Debug → Visible Collision Shapes** trong editor để thấy hitbox khi chơi.

| Phím | Hành động |
|---|---|
| A / D | Di chuyển (camera theo cả hai chiều) |
| W (giữ) | Ngắm lên (form có súng): W bắn thẳng lên, W + A/D bắn chéo |
| H (giữ) | **Bắn** liên tục, chỉ khi form có súng (súng chỉ hiện ở tay lúc bắn) |
| K | **Chém**, chỉ khi form có kiếm / vũ khí cận chiến (vũ khí chỉ hiện khi chém) |
| S (giữ) | Cúi / thủ thế: đứng yên, thân thấp lại (đạn cao bay qua), đòn cận chiến chỉ còn 40%, không bị đẩy lùi |
| Space | Nhảy. Đứng trên bệ thì S + Space (hoặc bấm đúp S) để xuống |
| J | **Đánh**: bấm liên tục để đấm theo chuỗi, đủ số đòn thì tự ra **cú đá** kết thúc (sát thương cao hơn, đẩy xa, phá giáp). Nút Đánh luôn là tay không. Dạng người và form thường: 3 đấm + 1 đá; form nặng (Titan, Land...): 2 đòn + 1 đá; Kuuga Pegasus: 2 phát + 1 phát nạp mạnh. Ngừng bấm thì chuỗi về đầu |
| L | **Đổi form** theo vòng các form đã nhặt (W: đổi nửa trái, giữ W + L đổi nửa phải). Vào form đặc biệt cần ≥ 20 nộ và tốn 10; về form gốc thì miễn phí |
| Shift | Né (hồi 0.6 giây, bất tử với đòn cận chiến, **không** tránh được đạn) |
| I | Biến thân vào form gốc (cần nộ đầy và đã có Driver, không mất nộ) |
| Esc / P | Menu: về màn chọn màn (bỏ màn đang chơi) |
| U | Final Attack (cần ≥ 50 nộ, đốt hết nộ; ở form đặc biệt thì đánh xong về form gốc) |

**Hội thoại:** Đánh (J) / Enter / Space / chạm để hiện hết câu rồi sang câu kế; Esc hoặc "BỎ QUA" để bỏ cả đoạn. Trong lúc thoại cả màn dừng lại. Hội thoại hiện ở đầu màn, lúc gặp trùm, lúc nhặt Driver / form của màn và lúc qua màn; sau mỗi trùm có **bản đồ Chuỗi Trái Đất** cho thấy Trái Đất vừa giải cứu và chặng tiếp theo. Mỗi đoạn chỉ hiện một lần mỗi lượt chơi.

**Nút trên màn hình** (bấm chuột hoặc chạm):
- **Góc trái:** D-pad ◀ ▶ ▲ ▼, 4 nút cùng cỡ. **▲ = nhảy** (giữ ▲ còn để ngắm lên khi có súng, và để W đổi nửa phải). **▼ = cúi**, bấm đúp ▼ trên bệ = xuống khỏi bệ.
- **Góc phải:** nút **Đánh** to (đấm theo chuỗi rồi tự đá) và Né. Chỉ hiện khi dùng được: **Biến thân / Tuyệt chiêu**, Đổi form, Bắn (form có súng).
- **Góc trên trái, bên trái thanh máu:** nút **≡ Menu** về màn chọn màn.
- Mỗi nút có chữ ngắn bên dưới và vòng hồi chiêu, mờ đi khi thiếu nộ; nút Biến thân / Tuyệt chiêu phát sáng khi dùng được. Biểu tượng vẽ bằng `tools/gen_ui_icons.py`; tile thùng gỗ và vách thép vẽ bằng `tools/gen_tiles.py`.

**Chọn Rider:** sau khi chọn màn (khi đã có từ 2 Rider) hiện màn chọn: mỗi thẻ có cấp, lối chơi, 5 thanh chỉ số (Máu · Giáp · Tốc độ · Sức đánh · Nhảy), số form, và dấu ★ cho Rider của thế giới (form / item của màn là của Rider này). ◀ ▶ hoặc chạm thẻ để chọn, Đánh / Enter / "CHỌN" để chọn, rồi tới màn chọn item. Mỗi màn một Rider. Mỗi Rider một kiểu (ví dụ **Kuuga** bền, **Faiz** nhanh và có súng, **W** nhảy cao). Có nhiều Rider thì 3 thẻ hiện một lúc, ◀ ▶ để cuộn; mỗi thẻ ghi thêm "Sức mạnh ×N" theo thế hệ.

**Thanh NỘ:** màu cam. Ở dạng Rider có vạch trắng đánh dấu mức Final Attack (50). Ở form đặc biệt thanh chuyển tím và hiện số giây còn lại; dưới 25% thì nháy đỏ. Chi tiết ở mục 3.8 của GDD.

Thế giới 1–3 (Kuuga, Agito, Ryuki) đã có hình thật cho Rider, quái và trùm; Faiz có hình Rider. Quái thường của thế giới 4–27 là quái ghép (`tools/kitbash.py`); trùm thế giới 4 trở đi chưa có hình. Phần chưa có hình vẫn là **khối màu** theo màu nhận diện của Rider (`"color"` trong file thế giới):
- **Quái thế giới 1:** Grongi tím = thường, xanh lục = nhanh (né đòn, dùng Faiz Axel), nâu đồng = giáp (dùng Kuuga Titan / W Metal / Final Attack). Trùm là Daguba.
- **Quái thế giới 2:** Jaguar Lord vàng = thường, Crow Lord xanh đen = nhanh, Tortoise Lord xanh rêu = giáp. Trùm là Overlord of Darkness.
- **Quái thế giới 3:** Sheerghost xám bạc = thường, Raydragoon xanh ngọc = nhanh, Metalgelas nâu đồng = giáp. Trùm là Kamen Rider Odin.
- Mở game sẽ vào **màn hình chính** (CHƠI / COMBAT), rồi tới màn **nhập tên nhân vật**.
- **Vật phẩm rơi ra:** hình Driver của thế giới = Driver để kích hoạt · kim cương màu của Rider = form mới · kim cương cam, nhỏ = nạp nộ · hình Driver nhuộm xanh = Driver của thế giới kế tiếp (còn phong ấn). Hình Driver nằm ở `art/items/drivers/<id Rider>.png` (64×40, vẽ bằng lệnh pixel của PixelLab, không tốn lượt); thiếu hình thì hiện kim cương như cũ.

## Đấu qua WiFi: 1 VS 1 và ALL COMBAT

Ở màn hình chính chọn **COMBAT** (cần mở khoá ít nhất 1 Rider ở CHƠI, tức nhặt Driver đầu tiên ở màn 1-1; chưa có thì bấm vào chỉ hiện thông báo), đặt tên (tên hiện trong phòng đấu) rồi **Vào sảnh đấu**. Hai máy phải cùng một mạng WiFi. Ở sảnh, "◀ QUAY LẠI" / Esc về màn hình chính.

1. **Máy A tạo phòng**, chọn một trong hai kiểu. Màn hình hiện IP của máy (vd `192.168.1.5`).
   - **TẠO PHÒNG 1 VS 1**: đúng 2 người.
   - **TẠO PHÒNG ALL COMBAT**: hỗn chiến 2–4 người, ai cũng đánh được tất cả. Gục thì nằm xem tới hết hiệp, **người cuối cùng còn đứng thắng hiệp**. Trên đầu mỗi nhân vật có bảng tên P1–P4 theo màu, HUD xếp các ô máu thành một hàng trên cùng.
2. **Các máy khác:** phòng của máy A tự hiện trong danh sách "Phòng trong mạng WiFi" (kèm kiểu phòng và số người, vd "ALL COMBAT 2/4"), bấm vào để vào. Không thấy thì gõ IP của máy A rồi bấm **VÀO**.
3. Mỗi người bấm **CHỌN RIDER**, gồm 3 bước (**hai người chọn trùng Rider cũng được**):
   - **Rider**: chỉ các Rider đã mở khoá ở CHƠI, với cấp và sức mạnh như ở hành trình.
   - **Form biến đổi**: tối đa 1 form đã nhặt được (Kuuga Dragon, W HeatMetal...), hoặc không chọn thì chỉ có form gốc. Rider chưa nhặt form nào thì bỏ qua bước này.
   - **Vũ khí**: mang tối đa 2 item đã nhặt (Ryuki Sword Vent, Blade Mach Jaguar...) hoặc không mang. Rider chưa có item thì bỏ qua.

   Trong trận chỉ đổi được sang form / vũ khí đã chọn (nút Kỹ năng L, tốn nộ như ở hành trình). Bộ đã chọn được lưu: lần sau vào phòng tự chọn sẵn, muốn đổi thì bấm CHỌN RIDER.
4. Chủ phòng bấm **BẮT ĐẦU** khi đủ người (1 VS 1: 2 người; ALL COMBAT: từ 2 người) và ai cũng đã chọn. Thắng 2 hiệp là thắng trận. Có người thoát giữa trận thì tính như gục; còn dưới 2 người thì mọi người về phòng. Mỗi hiệp bắt đầu ở dạng người, nộ đầy: bấm **Biến thân (I)**. Luật như màn thường: máu Rider về 0 thì vỡ giáp về dạng người, máu người về 0 là thua hiệp. Phím và nút cảm ứng giữ nguyên. Bấm **Menu hai lần** để bỏ trận. Đấu xong mọi người quay về phòng: đấu lại hoặc đổi Rider.

**Bản nào tạo phòng được:** kết nối bằng WebSocket (cổng TCP 24990, tìm phòng bằng UDP broadcast cổng 24991). Bản cài trên máy tính (chạy từ Godot bằng F5, hoặc xuất bản macOS / Windows / Linux / Android) tạo phòng, tìm phòng và vào phòng được. **Bản web (trình duyệt) chỉ VÀO phòng được, bằng cách gõ IP**: trình duyệt không mở server, không nghe UDP, và trang mở qua `https://` thì không kết nối được tới `ws://`. Lần đầu tạo phòng, macOS / Windows có thể hỏi cho phép kết nối đến: chọn Cho phép. Wi-Fi công cộng / khách sạn thường chặn các máy nói chuyện với nhau.

Test tự động: các tiến trình Godot trên cùng máy, một tạo phòng, các máy khác tìm phòng qua broadcast (hoặc 127.0.0.1) rồi vào, bot tự đánh hết trận; in kết quả và số đòn trúng mỗi bên thấy. `RIDERS="faiz double"` để đổi Rider; 3–4 Rider (vd `RIDERS="kuuga ryuki faiz double"`) thì chạy phòng ALL COMBAT; `VERBOSE=--verbose` để in vị trí / trạng thái mỗi 2 giây:

```bash
sh tools/run_versus.sh
```

## Kiểm tra tự động

Bot tự chơi khoảng 90 giây (chạy, bắn, nhảy qua vực, xuống bệ, đánh, nhặt vật phẩm rơi, biến thân, đổi form bằng nộ, hết nộ về form gốc, đổi Rider, tuyệt chiêu, vỡ giáp) để bắt lỗi:

```bash
godot --headless --path . res://tools/smoke_test.tscn
```

Test cả chiến dịch: bot chơi lần lượt các màn, đi theo lộ trình (chạy hai chiều, leo / tụt giếng), tự nhặt đồ rơi, né đạn theo màu báo hiệu, dùng nộ, đánh trùm; in báo cáo từng màn (thời gian, số quái hạ, món chính rơi từ quái hay ở vạch đích, nhặt xong có vào đúng form không, số lần trúng đạn / vỡ giáp / hết nộ về form gốc, kẹt quá 20 giây, bố cục đè lên nhau, hội thoại của màn có hiện đủ không) và thoát với mã lỗi bằng số màn có vấn đề. Bot tự bấm qua từng câu thoại. `--fixed-fps 60` để chạy nhanh hết mức máy. `CAMP_FROM="4-1"` / `CAMP_TO="6-B"` để chạy một đoạn:

```bash
CAMP_FROM=4-1 CAMP_TO=4-B godot --headless --path . --fixed-fps 60 res://tools/campaign_test.tscn
```

Cả 27 thế giới, chia thành 9 phần chạy song song (mỗi phần 3 thế giới):

```bash
sh tools/run_campaign.sh
```

Kiểm tra dữ liệu các file thế giới (khóa, form, người nói, độ dài câu thoại, tên nền...):

```bash
godot --headless --path . -s tools/validate_worlds.gd
```

Test né đạn (đứng/cúi/nhảy/né trước đạn cao và đạn thấp, in OK/SAI từng trường hợp):

```bash
godot --headless --path . res://tools/dodge_test.tscn
```

Quay video (cho sẵn Kuuga và cả 3 form): `godot --path . --always-on-top --fixed-fps 60 --write-movie <thư_mục>/f.png res://tools/smoke_test.tscn -- --showcase`

## Cấu trúc

```
scripts/
  autoload/game_state.gd       tiến trình thế giới/màn, Driver, cấp Rider, đội hình, save, phím
  autoload/combat_director.gd  hit-stop, làm chậm quái, giới hạn số quái tấn công cùng lúc
  data/world_data.gd           bộ nạp thế giới: danh sách file theo năm phát sóng, tự đánh số màn, nối chuỗi Driver
  data/worlds/wNN_<id>.gd      mỗi thế giới một file: Rider + form, quái, 5 màn, trùm, thoại, nền (27 file)
  data/story_data.gd           phần mở đầu và người nói chung; thoại từng màn lấy từ file thế giới
  player/player.gd             nhân vật: máy trạng thái, biến thân, đổi Rider, Final Attack
  riders/rider_form.gd         lớp gốc của mọi Rider (có cấp 1–5)
  riders/kuuga.gd, faiz.gd, double.gd   Rider có cơ chế riêng
  riders/data_rider.gd         Rider dựng từ dữ liệu RIDER của file thế giới (24 Rider còn lại)
  items/driver_pickup.gd       vật phẩm rơi ra để nhặt (Driver, form, nạp nộ)
  combat/                      Hitbox, Hurtbox, DamageInfo
  enemies/enemy.gd             AI quái
  levels/stage_builder.gd      sinh bố cục màn theo lộ trình (đoạn ngang, giếng leo / tụt, vực, bệ, khối,
                               điểm ra quái, checkpoint, đường camera) + kiểm tra các đoạn không đè lên nhau
  levels/stage_run.gd          màn chơi cuộn ngang: camera, thả quái, rơi vực, vạch đích, trùm
  combat/projectile.gd         đạn của người chơi và quái
  ui/stage_select.gd           màn chọn màn (thế giới × 5 màn, mở dần, chơi lại được)
  ui/rider_select.gd           màn chọn Rider dùng trong màn (thẻ + thanh chỉ số)
  ui/item_select.gd            chọn tối đa 2 item mang vào màn
  ui/touch_controls.gd         nút cảm ứng: D-pad góc trái, Đánh + kỹ năng góc phải
  ui/main_menu.gd              màn hình chính: CHƠI (hành trình) / COMBAT (đấu 2 người)
  ui/name_entry.gd             đặt tên, rồi vào hành trình hoặc sảnh đấu theo lựa chọn ở màn hình chính
  ui/intro.gd                  phần mở đầu: các cảnh vẽ bằng code + thoại, thẻ tựa
  ui/dialogue_box.gd           khung thoại: chân dung, tên, chữ chạy, bỏ qua; dừng game khi thoại
  ui/earth_map.gd              bản đồ Chuỗi Trái Đất (intro và sau mỗi trùm)
  versus/versus.gd             đấu qua WiFi (1 VS 1 / ALL COMBAT 2–4 người): sảnh, phòng, chọn Rider, đấu trường, đồng bộ mạng, hiệp đấu
  versus/versus_lan.gd         kết nối WebSocket (chủ phòng là server) + tìm phòng bằng UDP broadcast
  versus/versus_hud.gd         thanh máu / nộ từng người chơi (tới 4 ô), số hiệp thắng, chữ lớn giữa màn hình
scenes/                        player.tscn, enemy.tscn, levels/stage_run.tscn, ui/main_menu.tscn, ui/name_entry.tscn, ui/intro.tscn,
                               versus/versus.tscn
```

**Thêm một thế giới mới** (đặc tả đầy đủ: `docs/WORLD_FILES.md`, file mẫu `scripts/data/worlds/w02_agito.gd`):
1. Tạo `scripts/data/worlds/wNN_<id>.gd` với `WORLD` (Rider, Driver, quái, 5 màn, trùm), `RIDER` (form gốc + 3 form, kiểu đòn, chỉ số, súng), `SPEAKERS`, `STORY`, `WORLD_CLEAR`.
2. Thêm một dòng vào `WorldData.FILES` đúng vị trí năm phát sóng. Mã màn và chuỗi Driver tự tính lại.
3. `godot --headless --path . -s tools/validate_worlds.gd`, rồi `python3 tools/gen_backgrounds.py` và `python3 tools/gen_story_art.py` để vẽ nền và chân dung.

**Nền từng màn:** `python3 tools/gen_backgrounds.py` vẽ nền xa 800×224 (nối liền hai mép) vào `art/backgrounds/` cho mọi màn của 27 thế giới, theo `"bg"` / `"bg_theme"` trong file thế giới (50 kiểu nền: phố, núi, rừng, đền, thế giới gương, lâu đài, sa mạc thời gian, mặt trăng, Helheim, thế giới game, thư viện, giấc mơ...). Bằng hình khối nên không tốn lượt PixelLab. Màn 1-1 dùng ảnh Shibuya có sẵn. **Chân dung khung thoại:** `python3 tools/gen_story_art.py` vẽ theo `"look"` của từng người nói.

**Sprite:** nhân vật chính, Kuuga, Agito, Ryuki, Faiz, quái thường và trùm của thế giới 1–3 dùng hình **PixelLab**:

```bash
python3 tools/import_pixellab.py --download
```

Script tải nhân vật từ PixelLab (ID trong `art/pixellab/characters.json`) rồi ghi `art/characters/player_frames.tres` và `art/characters/enemy_frames.tres`. Nó tự tạo thêm, không tốn lượt PixelLab: 4 form Kuuga đổi màu từ Mighty, Grongi hạng Me và Go đổi màu từ Grongi Zu, cảnh biến hình, né và vỡ giáp.

**Rider bộ gọn** (Agito, Ryuki, Faiz, Blade, Hibiki, Kabuto, Den-O, Kiva; bảng `DATA_RIDERS` trong script): PixelLab chỉ làm 5 animation (đứng, chạy, đấm, đá, bị đánh), mỗi Rider tốn 6 lượt kể cả tạo hình. Nhảy lấy frame chạy, cúi nén từ tư thế đứng, tuyệt chiêu là cú đá thêm lửa theo màu form. 3 form còn lại làm từ form gốc: Agito đổi màu giáp vàng (Storm xanh, Flame đỏ, Trinity nửa xanh nửa đỏ), Ryuki vẽ thêm kiếm / đầu rồng / khiên cho Sword, Strike, Guard Vent, Faiz đổi màu cho Axel và Blaster. Form theo nguyên tác: lá bài / đòn / khả năng giữ nguyên ngoại hình (Blade Mach Jaguar, Thunder Deer), form đổi ngoại hình thì đổi màu (Blade Jack Form giáp vàng, Hibiki Kurenai đỏ toàn thân), Hibiki Onibi và Kaentsuzumi chỉ rút dùi trống / trống ra khi đấm. Kabuto chỉ có Rider Form và Hyper Form; Hyper Form có hình riêng (`art/pixelengine/kabuto_hyper/`, khai báo bằng phần tử thứ ba của form trong `DATA_RIDERS`). Den-O mỗi form là một Imagin nhập vào nên cả 4 form đều có hình riêng: Sword (`art/pixelengine/den_o/`), Rod mặt nạ mai rùa xanh, Ax vàng, Gun rồng tím (`den_o_rod`, `den_o_ax`, `den_o_gun`). Kiva: Kiva Form ảnh gốc PixelEngine + 5 animation PixelLab (5 lượt); Garulu, Basshaa, Dogga đổi màu mắt và giáp nửa trên sang lam / lục / tím (`kiva_rule`), thắt lưng Kivat và chân giữ nguyên. Tốc độ đòn khớp kiểu đòn (`"style"`) của form trong file thế giới. Tiền tố animation là `<rider>_<form>` (ví dụ `agito_storm_run`).

**Hiệu ứng đánh** (`scripts/combat/fx.gd`): vẽ bằng code, không tốn lượt. Mỗi form chọn hiệu ứng theo nguyên tác qua `"fx"` trong RIDER (Kuuga, Faiz: hằng `FX` trong script): `hit` khi trúng, `swing` khi vung (vệt chém, gió), `shot` kiểu đạn (cầu, tia sét, cầu lửa, mũi tên khí), `final` khi Final Attack trúng, `color`, `trail` (bóng mờ), `glide` (giữ Nhảy để lượn, Blade Jack Form). Ví dụ: Hibiki đánh ra sóng âm thanh tẩy, Blade Thunder Deer bắn tia sét, Kabuto Rider Kick bắn hạt tachyon. Form `"effect": "time"` (Clock Up, Hyper Clock Up, Faiz Axel): quái đi **và cử động** chậm còn 15%, Rider chạy **và ra đòn** nhanh ×1.6 kèm bóng mờ, màn hình ngả xanh, hiện `"time_call"`. Final Attack: chớp trắng + tên tuyệt chiêu.

**Quái bộ gọn** (bảng `EXTRA_ENEMIES`): một loại quái thường làm bằng PixelLab (tạo + chạy, đánh, bị đánh, gục = 5 lượt), loại nhanh và loại giáp đổi màu từ nó. Trùm tốn 4 lượt (không có animation gục, dùng lại bị đánh). Khóa `"sprite"` của quái và trùm trong file thế giới trỏ tới tên bộ hình.

**Quái ghép** (`tools/kitbash.py`, không tốn credit AI): quái thường PixelLab cùng mẫu dáng `mannequin` nên tư thế từng frame gần giống nhau. Script lấy animation thân của một trong 3 quái (Jaguar Lord lực lưỡng, Sheerghost mảnh, Grongi có cánh), dò vị trí và góc nghiêng của đầu ở từng frame, thay bằng đầu mới, rồi đổi màu cả con (màu nền + màu nhấn cho phần lông / trang sức vàng, giữ viền tối và độ sáng; Fangire có kiểu kính màu). Đầu mới hoặc cắt từ hình tĩnh có sẵn (sói Orphnoch, mèo Jaguar Lord, dơi Grongi, sọ Masquerade, mặt nạ Faiz), hoặc vẽ bằng code từ các mảnh `PARTS` (đầu tròn + mõm, mỏ, sừng, gạc, râu, mắt kép, vỏ ốc, mũ...). Frame dò không ra (nằm gục) giữ đầu cũ, chỉ đổi màu. Bảng `KITBASH` trong script có 72 quái cho thế giới 4–27 (thường / nhanh / giáp theo nguyên tác: Darkroach, Salis Worm, Mole Imagin, Spider Fangire, Masquerade Dopant, Waste Yummy...); kết quả ở `art/kitbash/<tên>/` cùng cấu trúc PixelLab, khai báo trong `EXTRA_ENEMIES` với `{}`, khóa `"sprite"` trong file thế giới:

```
python3 tools/kitbash.py --preview <thư_mục>
python3 tools/import_pixellab.py
```

Lưu ý khi tạo animation mới: dùng animation mẫu (template) và chỉ hướng `east`, mỗi animation 1 lượt. Không chỉ hướng thì PixelLab làm cả 4 hướng, tốn gấp 4. Gói miễn phí chỉ chạy một việc mỗi lần.

**PixelEngine** (Blade, Hibiki, Kabuto, Kabuto Hyper, Ryuki theo nguyên tác `art/pixelengine/ryuki_canon/`: chạy làm bằng PixelEngine, 4 animation còn lại bằng PixelLab `animate_image` từ cùng ảnh gốc, cắt về 64×64 để mỗi animation tốn 1 lượt; Den-O: ảnh gốc Sword Form bằng PixelEngine, 3 form kia sửa từ ảnh đó bằng PixelLab `edit_image_pro_flash` (5 lượt mỗi ảnh 68×68), cả 5 animation mỗi form bằng PixelLab `animate_image` (1 lượt mỗi animation 68×68), tổng 35 lượt cho 4 form): `tools/pixelengine.py` gọi API [PixelEngine](https://pixelengine.ai/docs/api-reference), key đặt trong `.env` (mẫu `.env.example`, không commit). Một Rider tốn khoảng 74 credit: tạo hình 6 (`image --model oai_gpt25_low --ref <sprite mẫu>`, ra ~92 px nên phải thu về khung 68×68) + 5 animation 68 khi gửi gộp (`animate` 20 cho animation đầu, `batch` 20 + 12 mỗi animation thêm). Ảnh trả về có nền đặc (`--matte`, mặc định hồng), `pack` xoá nền, vá sừng / mào mà AI vẽ thiếu ở frame đánh (dò vị trí đầu theo ảnh gốc; `--crest-min 0.7` cho sừng to như Kabuto Hyper) rồi xếp vào `art/pixelengine/<tên>/` cùng cấu trúc PixelLab để `import_pixellab.py` đọc như thường. `fit --height 60` khi nhân vật có sừng cao để thân giữ cùng cỡ:

```bash
python3 tools/pixelengine.py balance
python3 tools/pixelengine.py batch art/pixelengine/blade_nbflash_68.png "idle=8:mô tả" "light=4:mô tả" ...
python3 tools/pixelengine.py pack blade art/pixelengine/blade_nbflash_68.png idle=<sheet>.png run=<sheet>.png ...
python3 tools/import_pixellab.py
```

Nhân vật PixelLab cao khoảng 60 px nên game chạy ở 480×270. Mọi thông số thiết kế (tầm đánh, tốc độ…) được nhân với `Units.SCALE = 1.8` (`scripts/core/units.gd`).

W và trùm từ thế giới 4 trở đi chưa có hình, sẽ hiện khối màu tạm. `tools/gen_sprites.py` vẽ sprite bằng code làm bản dự phòng (ghi vào `art/characters/procedural/`).

**Hình phần truyện:** `python3 tools/gen_story_art.py` vẽ chân dung khung thoại (`art/ui/portraits/`, cắt đầu từ sprite PixelLab đã tải và đổi màu cho các Echo Rider; Void và Pen vẽ bằng hình khối) cùng hành tinh và dáng Void (`art/story/`). Không tốn lượt PixelLab.
