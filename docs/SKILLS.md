# Skill của Rider

Mỗi Rider có **bộ skill riêng theo form**, lấy từ nguyên tác: đổi form là đổi bộ skill. **Đã làm trong code** (mục 4);
các con số là bản đầu, chơi thử rồi chỉnh (`scripts/riders/skills.gd`).

## 1. Luật chung

**Nút bấm** (nút chỉ hiện khi form dùng được):

| Nút | Phím PC | Ghi chú |
|---|---|---|
| Đánh | J | tay không, luôn có |
| Chém | K | form có kiếm / vũ khí cận chiến (đã có) |
| Bắn | H | form có súng (đã có) |
| **Skill 1** | U | skill nhẹ của form |
| **Skill 2** | Y | skill mạnh của form |
| Đổi form | L | như hiện tại |
| **Final Attack** | O | tuyệt chiêu của form |
| Né | Shift | như hiện tại |

Trên điện thoại: Skill 1, Skill 2, Final xếp vòng cung quanh nút Đánh; nút mờ khi thiếu nộ, có vòng hồi chiêu và số nộ cần.

**Giá nộ** (thanh nộ 100):

| Bậc | Nộ | Hồi chiêu | Dùng cho |
|---|---|---|---|
| Skill 1 (nhẹ) | 15 | 2 giây | đòn nhanh, bắn, lướt, khiên |
| Skill 2 (mạnh) | 30 | 5 giây | trói, khoá, vùng, gọi đồng đội / quái thú |
| Final Attack | 60 | — | tuyệt chiêu |

Skill **khoá / trói** đắt hơn cùng bậc +5 nộ (Skill 1 khoá = 20, Skill 2 khoá = 35) vì không trượt.

**Sát thương:** chỉ Final Attack là đòn mạnh (~60 gốc). Skill 1 gốc 9 (ngang cú đá kết chuỗi), Skill 2 gốc 14, nhân
hệ số theo kiểu ở mục 2; skill nhiều nhịp ("hits") chia đều tổng sát thương, không cộng dồn.

**Nộ ở form đặc biệt** (mục 5, đã chốt theo đề xuất A): đổi sang form đặc biệt tốn 10 nộ một lần, form không tụt nộ
nữa, mọi form tích nộ khi đánh trúng. Form tăng tốc thời gian (Axel, Hyper, Formula...) vẫn tụt 10 nộ/giây và về form
gốc khi hết nộ. Đòn skill và Final không cộng nộ.

## 2. Kiểu skill

| Ký hiệu | Kiểu | Cách hoạt động | Trượt? | Cân bằng |
|---|---|---|---|---|
| **[Đ]** | Định hướng | đòn lướt / đạn / sóng theo hướng mặt hoặc hướng ngắm (8 hướng như nút Bắn) | có: nhảy, cúi, Né tránh được | rẻ, sát thương cao nhất |
| **[K]** | Khoá mục tiêu | chọn quái gần nhất trong tầm (mặc định 160 px phía trước), dấu khoá 0,3–0,5 giây rồi ra đòn chắc trúng | không (bị đánh lúc tụ thì hỏng) | sát thương ×0,7 so với [Đ] cùng bậc |
| **[K×n]** | Khoá nhiều | như [K], khoá tối đa n quái | không | sát thương mỗi quái ×0,5 |
| **[T]** | Trói | gắn / bắn vật trói: quái đứng im, không ra đòn N giây (mặc định 2,5) | tuỳ skill: trói định hướng hoặc trói khoá | trùm chỉ bị trói 40% thời gian, cùng một quái không trói liền 2 lần |
| **[V]** | Vùng | trúng mọi quái quanh Rider (mặc định bán kính 70 px) | không, trong vùng | tầm ngắn |
| **[P]** | Phản đòn | thế đỡ 0,5 giây, bị đánh trong lúc đó thì phản đòn chắc trúng (đạn thì phản đạn) | phụ thuộc thời điểm | bấm hụt vẫn mất nộ |
| **[C]** | Cường hoá | buff có thời hạn: tốc độ, giáp, sát thương, tăng tốc thời gian, phân thân | — | thời hạn 5–8 giây |

- **Chế độ đấu WiFi:** [K] / [T] luôn hiện dấu khoá trước để đối thủ kịp Né; sát thương skill lên người chơi ×0,6.
- **Tag hiệu ứng** dùng lại hệ hiện có: `burn` cháy, `freeze` đóng băng, `shock` điện lan, `stun` choáng, `force` đẩy /
  hút, `heavy` phá giáp, `crush` (form nặng), `time` (tăng tốc thời gian), `ranged` (đạn). Thêm mới: `bind` (trói).
  Skill cũng tính khắc chế quái đặc biệt màn EX (tools/special_caps.tscn cần đếm cả skill).
- **Hình ảnh:** dùng lại animation có sẵn (light / heavy / slash / final) + hiệu ứng Fx; vật trói, quái thú gọi tới
  (Dragreder, Tridoron...) vẽ bằng Fx như các dấu tuyệt chiêu hiện có. Không tốn lượt PixelLab.

## 3. Bảng skill theo Rider

Cột: **Skill 1 (15)** · **Skill 2 (30)** · **Final (60)**. Final giữ tên hiện có trong game, thêm kiểu.
Dấu ⚠ = chưa chắc nguyên tác, cần xác minh khi làm.

### 1 · Kuuga (2000) — màn EX: khổng lồ (Titan)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Mighty | **Mighty Punch** [Đ] đấm lao tới, `heavy` | **Linto Seal** [T] khắc dấu phong ấn lên quái gần, trói 2 giây rồi nổ `burn` | Mighty Kick [Đ] nhảy đá, `burn` |
| Dragon | **Dragon Leap** [Đ] nhảy siêu cao rồi bổ gậy xuống | **Dragon Rod Sweep** [V] xoay gậy quét quanh mình, `force` | Splash Dragon [Đ] lao gậy đâm |
| Pegasus | **Hyper Sense** [C] siêu thị giác 6 giây: đạn Bắn tự đuổi quái | **Pegasus Snipe** [K] tụ 1 giây, bắn mũi tên khí chắc trúng xa 300 px | Blast Pegasus [K] bắn xuyên chắc trúng |
| Titan | **Titan Guard** [P] giáp đỡ đòn, phản nhát kiếm | **Titan Stride** [Đ] bước tới đâm kiếm xuyên giáp, `crush` | Calamity Titan [Đ] đâm kiếm phong ấn, `stun` |

### 2 · Agito (2001) — màn EX: bóng ma (Flame)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Ground | **Agito Crest** [C] mở sừng Crosshorn, sát thương +25% 6 giây | **Ground Uppercut** [Đ] đấm hất tung, `force` | Rider Kick [Đ] dấu Agito dưới chân rồi đá |
| Storm | **Storm Halberd** [Đ] phóng xoáy gió theo hướng ngắm | **Haldent Whirl** [V] lốc xoáy **hút** quái lại gần, `force` | Haldent Tornado [V] |
| Flame | **Flame Saber** [Đ] lướt chém lửa, `burn` | **Sixth Sense** [K] giác quan thứ sáu: chém chắc trúng quái gần, `burn` | Saber Slash [K] |
| Trinity | **Double Saber** [Đ] chém chéo hai vũ khí, `burn` | **Trinity Storm** [V] xoay hai vũ khí, lửa + gió, `burn` `force` | Fire Storm Attack [Đ] |

### 3 · Ryuki (2002) — màn EX: quái bay (Strike Vent / Survive)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Ryuki | **Strike Vent** [Đ] Dragclaw phun lửa thẳng, `burn`, `ranged` | **Advent: Dragreder** [K] gọi rồng đỏ lượn tới cắn quái gần | Dragon Rider Kick [Đ] rồng đẩy lưng, đá xoáy lửa |
| Survive | **Drag Visor-Zwei** [Đ] đạn lửa nạp, `burn` | **Dragranzer** [V] rồng máy quét lửa quanh mình | Dragon Fire Stream [Đ] |
| Sword Vent (item) | **Drag Saber** [Đ] chém lửa, `burn` | **Mirror Dash** [Đ] lướt xuyên quái (bất tử khi lướt) | Drag Saber Slash [Đ] |
| Strike Vent (item) | **Dragclaw Fire** [Đ] cầu lửa, `burn` | **Fire Wall** [V] tường lửa trước mặt chặn đạn | Dragclaw Fire [Đ] |
| Guard Vent (item) | **Drag Shield** [P] khiên phản đòn | **Shield Bash** [Đ] húc khiên, `stun` | Advent: Dragreder [K] |

### 4 · Faiz (2003) — màn EX: siêu tốc (Axel)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Faiz | **Grand Impact** [Đ] Faiz Shot đấm tầm gần, `stun` | **Faiz Edge** [Đ] chém kiếm năng lượng đỏ (Auto Vajin trao kiếm) | Crimson Smash [K] Faiz Pointer ghim chóp nón rồi đá xuyên |
| Axel | **Accel Dash** [Đ] lướt xuyên nhiều quái, `time` | **Accel Grand Impact** [K] đấm liên hoàn chắc trúng, `time` | Accel Crimson Smash [K×4] ghim nón lên 4 quái, đá lần lượt |
| Blaster | **Photon Buster** [Đ] đạn to xuyên | **Blaster Spread** [V] bắn tỏa 5 tia quanh mình | Crimson Smash (Blaster) [K] |

### 5 · Blade (2004) — màn EX: bóng ma (Thunder Deer)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Ace | **Slash Lizard** [Đ] chém kiếm nhanh | **Rouse: Metal Trilobite** [C] thân thép 5 giây: giáp cao, không bị khựng | Lightning Blast [Đ] đá sét, `shock` |
| Mach Jaguar (item) | **Mach** [C] tốc độ ×1,5 trong 6 giây | **Mach Strike** [Đ] lướt chém xuyên nhiều quái | Lightning Sonic [Đ] |
| Thunder Deer (item) | **Thunder** [K] sét đánh từ trên xuống quái gần, `shock` | **Thunder Field** [V] sét lan vùng, `shock` | Thunder Deer [K] |
| Jack | **Jack Glide** [C] lượn trên không 5 giây (bay) | **Eagle Dive** [Đ] bổ nhào chém từ trên không | Lightning Slash [Đ] `shock` |

### 6 · Hibiki (2005) — màn EX: khổng lồ (Kaentsuzumi)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Hibiki | **Onibi** [V] thổi lửa quỷ quanh mình, `burn` | **Ongekidaiko** [T] gắn trống lên quái gần (khoá), trói 3 giây. Trong lúc trói, nút Đánh thành **đánh trống theo nhịp**: mỗi nhịp đúng +sát thương, hết nhịp thì "thanh tẩy" nổ | Kaen Renda no Kata [T] đánh trống liên hoàn (như Ongekidaiko, mạnh hơn) |
| Onibi (item) | **Rekka Dan** [Đ] cầu lửa từ dùi trống, `burn` | **Onibi Spread** [Đ] 3 cầu lửa tỏa | Rekka Dan [Đ] loạt lửa |
| Kaentsuzumi (item) | **Ongekidaiko Kaen** [T] trống to gắn quái, `stun` | **Bakuretsu** [V] nện trống dội sóng âm vùng | Bakuretsu Kyouda no Kata [T] |
| Kurenai | **Ongekibou Rekka** [Đ] phóng cầu lửa đỏ, `burn` | **Shakunetsu** [V] hào quang đỏ thiêu quanh mình | Shakunetsu Shinku no Kata [T] |

### 7 · Kabuto (2006) — màn EX: siêu tốc (Hyper)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Rider | **Clock Up** [C] tăng tốc thời gian 4 giây (`time`) | **Rider Kick (counter)** [P] đứng quay lưng, quái tới gần thì đá xoay ngược chắc trúng | Rider Kick [P] |
| Hyper | **Hyper Clock Up** [C] tăng tốc 6 giây | **Perfect Zecter** [Đ] chém sóng năng lượng xa | Hyper Kick [Đ] |

### 8 · Den-O (2007) — màn EX: quái bay (Gun)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Sword | **Ore Sanjou** [C] tạo dáng, khiêu khích: quái quanh mình dồn vào đánh, sát thương +20% | **Extreme Slash Toss** [Đ] lưỡi kiếm bay ra, **điều khiển hướng** (giữ ↑ ↓) rồi quay về | Extreme Slash [Đ] |
| Rod | **Rod Hook** [Đ] móc kéo quái về phía mình, `force` | **Solid Attack** [T] ném Dengasher Rod tạo lưới lục giác trói quái (định hướng) | Solid Attack [T] trói rồi đá |
| Ax | **Dynamic Chop Lite** [Đ] bổ rìu, `crush` | **Kintaros Sumo** [V] dậm đất dội sóng, `stun` | Dynamic Chop [Đ] nhảy bổ rìu |
| Gun | **Wild Shot Lite** [Đ] bắn tỏa 3 viên | **Dance Shot** [V] xoay người bắn vòng tròn | Wild Shot [Đ] |

### 9 · Kiva (2008) — màn EX: quái bay (Basshaa)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Kiva | **Kiva Bat** [K] Kivat cắn quái gần, hồi chút máu | **Kiva Emblem** [T] dấu Kiva ghim quái xuống đất | Darkness Moon Break [T] trói bằng dấu rồi đá trên trời |
| Garulu | **Garulu Saber** [Đ] chém răng sói nhanh | **Howling** [V] tru: quái quanh mình bị `stun` | Garulu Howling Slash [Đ] |
| Basshaa | **Aqua Bullet** [K] đạn nước tự đuổi | **Aqua Field** [V] biển nước quanh mình làm chậm quái | Basshaa Aqua Tornado [K] |
| Dogga | **Dogga Hammer** [Đ] búa nặng, `crush` | **Thunder Grip** [T] nắm tay sét bóp giữ quái, `shock` | Dogga Thunder Slap [T] |

### 10 · Decade (2009) — màn EX: siêu tốc (Kamen Ride: Kabuto)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Decade | **Attack Ride: Illusion** [C] 2 phân thân đánh theo 5 giây | **Attack Ride: Invisible** [C] tàng hình 3 giây, quái mất dấu | Dimension Kick [Đ] đá xuyên hàng thẻ |
| Attack Ride: Slash | **Slash** [Đ] chém nhân bóng (3 vệt) | **Dimension Card Wall** [P] hàng thẻ chặn đòn | Dimension Slash [Đ] |
| Attack Ride: Blast | **Blast** [Đ] bắn nhân bóng tỏa | **Blast Homing** [K×3] đạn nhân bóng đuổi 3 quái | Dimension Blast [Đ] |
| Kamen Ride: Kuuga | = Kuuga Mighty: **Mighty Punch** [Đ] | = **Linto Seal** [T] | Mighty Kick [Đ] |
| Kamen Ride: Agito | = Agito Ground: **Agito Crest** [C] | = **Ground Uppercut** [Đ] | Rider Kick [Đ] |
| Kamen Ride: Ryuki | = Ryuki: **Strike Vent** [Đ] | = **Advent: Dragreder** [K] | Dragon Rider Kick [Đ] |
| Kamen Ride: Faiz | = Faiz: **Grand Impact** [Đ] | = **Faiz Edge** [Đ] | Crimson Smash [K] |
| Kamen Ride: Blade | = Blade Ace: **Slash Lizard** [Đ] | = **Rouse: Metal Trilobite** [C] | Lightning Blast [Đ] |
| Kamen Ride: Hibiki | = Hibiki: **Onibi** [V] | = **Ongekidaiko** [T] (đánh trống theo nhịp) | Kaen Renda no Kata [T] |
| Kamen Ride: Den-O | = Den-O Sword: **Ore Sanjou** [C] | = **Extreme Slash Toss** [Đ] | Extreme Slash [Đ] |
| Kamen Ride: Kiva | = Kiva: **Kiva Bat** [K] | = **Kiva Emblem** [T] | Darkness Moon Break [T] |
| Kamen Ride: Kabuto | = Kabuto Rider: **Clock Up** [C] | = **Rider Kick (counter)** [P] | Rider Kick [P] |

**Kamen Ride dùng đúng bộ skill của form gốc Rider được triệu hồi** (dấu "="): cùng tên, kiểu, giá nộ, hồi chiêu, hiệu ứng.
Trong code không chép lại mà trỏ tới form gốc (`"skills_from": [&"faiz", &"faiz"]`), sửa skill của Rider gốc là Kamen
Ride đổi theo. Kamen Ride: Kabuto còn giữ tăng tốc thời gian sẵn có của form (hạ quái siêu tốc màn EX).

### 11 · W (2009) — màn EX: bóng ma (Heat)

W ghép 2 nửa: **Skill 1 theo nửa Soul (trái), Skill 2 theo nửa Body (phải)**, Final theo Body như hiện tại.

| Nửa | Skill | |
|---|---|---|
| Cyclone (Soul) | **Cyclone Gust** [Đ] cú đá gió đẩy xa, `force` | Skill 1 |
| Heat (Soul) | **Heat Flare** [V] bùng lửa quanh mình, `burn` | Skill 1 |
| Luna (Soul) | **Luna Stretch** [K] tay dài uốn cong đánh chắc trúng quái gần | Skill 1 |
| Joker (Body) | **Joker Rush** [Đ] chuỗi đấm đá lao tới | Skill 2 |
| Metal (Body) | **Metal Shaft Twirl** [V] xoay gậy, `crush` | Skill 2 |
| Trigger (Body) | **Trigger Lock** [K×3] ngắm đạn đuổi 3 quái | Skill 2 |
| Xtreme | **Prism Bicker** [Đ] khiên kiếm Prism, xuyên mọi giáp · **Xtreme Analysis** [C] phân tích: quái mất giáp và kháng 6 giây | cả 2 skill |

Final: Joker Extreme [Đ] · Metal Branding [Đ] · Trigger Full Burst [K×3] · Xtreme Golden Extreme [Đ].

### 12 · OOO (2010) — màn EX: quái bay (TaJaDor)

| Combo | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| TaToBa | **Tora Claws** [Đ] cào vuốt hổ | **Batta Leap** [Đ] nhảy chân châu chấu xa | Tatoba Kick [Đ] lao qua 3 vòng Medal |
| LaTorarTar | **Lion Flash** [V] lóe sáng làm choáng quanh mình, `stun` | **Cheetah Dash** [C] chạy tốc độ cao 5 giây | Gush Cross [Đ] |
| GataKiriBa | **Kiriba Slash** [Đ] chém lưỡi bọ ngựa, `shock` | **Gatakiriba Clones** [C] phân thân 3 bản đánh cùng 5 giây | Gatakiriba Kick [Đ] cả phân thân cùng đá |
| ShaUTa | **Unagi Whip** [T] roi lươn quấn trói quái, `shock` | **Shachi Water** [V] cột nước dội quanh mình | Octo Banish [K] chân bạch tuộc khoan |
| TaJaDor | **Taja Spinner** [K] đạn lửa đuổi, `burn` | **Condor Flight** [C] bay 5 giây | Magna Blaze [Đ] bổ nhào lửa |
| SaGohZo | **Gorilla Bazooka** [Đ] bắn tay đấm, `crush` | **Sagohzo Gravity** [T] dậm đất trọng lực ghì mọi quái quanh mình (vùng trói) | Sagohzo Impact [T] |
| PuToTyra | **Tail Swing** [V] quật đuôi, `freeze` | **Freezing Breath** [Đ] thổi băng, `freeze` | Strain Doom [Đ] |
| BuraKaWani | **Cobra Charm** [T] thổi sáo rắn: quái gần đứng ngây | **Wani Jaws** [Đ] cú đá hàm cá sấu | Burakawani Scanning Charge [Đ] |

### 13 · Fourze (2011) — màn EX: bóng ma (Elek)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Base States | **Drill Module** [Đ] đá khoan | **Chain Array** [T] quả tạ xích quấn quái ⚠ | Rider Rocket Drill Kick [Đ] |
| Rocket States | **Rocket Rush** [Đ] tên lửa lao thẳng | **Rocket Lift** [C] bay bằng tên lửa 4 giây | Rider Rocket Punch [Đ] |
| Elek States | **Billy the Rod** [Đ] chém điện, `shock` | **Plug Shock** [V] cắm cáp phóng điện vùng, `shock` | Rider 10 Billion Volt Break [Đ] |
| Fire States | **Hee-hackgun** [Đ] phun lửa, `burn` | **Fire Extinguish** [V] phun bọt dập: quái quanh mình chậm lại | Rider Bakunetsu Shoot [Đ] |

### 14 · Wizard (2012) — màn EX: khổng lồ (Land)

| Style | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Flame | **Defend (Flame)** [P] tường lửa chặn đòn / đạn, `burn` | **Bind** [T] xích phép trói quái gần (khoá) | Strike Wizard [Đ] |
| Water | **Liquid** [C] hoá lỏng 3 giây: đòn đánh xuyên qua người | **Blizzard** [V] đóng băng quanh mình, `freeze` | Shooting Strike [Đ] |
| Hurricane | **Hurricane Fly** [C] bay 5 giây | **Thunder** [K] sét đánh quái gần, `shock` | Slash Strike [Đ] |
| Land | **Defend (Land)** [P] tường đá | **Big** [Đ] phép khổng lồ: bàn tay to đập xuống, `crush` | Strike Wizard (Land) [Đ] |

### 15 · Gaim (2013) — màn EX: khổng lồ (Pine)

| Arms | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Orange | **Musou Saber Shot** [Đ] bắn từ kiếm | **Daidaimaru Spin** [V] xoay hai kiếm | Naginata Musou Slicer [Đ] lưỡi cam bay |
| Pine | **Pine Iron** [T] ném quả thông chụp đầu quái (định hướng), trói | **Pine Swing** [V] quăng xích quả thông vòng tròn, `crush` | Pine Squash [T] |
| Ichigo | **Ichigo Kunai** [Đ] mưa phi tiêu dâu | **Kunai Rain** [V] phi tiêu rơi khắp vùng trước mặt | Ichigo Squash [V] |
| Jimber Lemon | **Sonic Arrow** [Đ] tên nhanh | **Lemon Lock** [K] tên tụ khoá quái | Sonic Volley [K] |

### 16 · Drive (2014) — màn EX: siêu tốc (Formula)

| Type | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Speed | **Tire Koukan: Midnight Shadow** [Đ] phi tiêu bóng | **Handle-Ken Drift** [V] chém xoay drift | SpeeDrop [K] Tridoron chạy vòng tạo lồng, dội đá chắc trúng |
| Wild | **Rumble Dump** [Đ] khoan tay | **Wild Drift** [P] lốp xoay đỡ đòn | Full Throttle: Wild [Đ] |
| Technic | **Funky Spike** [Đ] lốp gai | **Technic Scan** [K] ngắm phân tích bắn chắc trúng | Full Throttle: Technic [K] |
| Formula | **Formula Boost** [C] tăng tốc thời gian 4 giây (`time`) | **Formula Cannon** [Đ] đại bác kép | Formula Drop [K] |

### 17 · Ghost (2015) — màn EX: bóng ma (Edison)

| Damashii | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Ore | **Ghost Phase** [C] hoá ma xuyên đòn 2 giây | **Parka Ghost** [K] áo ma bay tới quấn quái | Omega Drive [Đ] con mắt sau lưng rồi đá |
| Musashi | **Nitoryu** [Đ] chém hai kiếm chéo | **Gan-Gun Saber Slash** [Đ] sóng chém xa | Omega Slash [Đ] |
| Edison | **Edison Shock** [Đ] tia điện, `shock` | **Light Bulb** [V] bóng đèn chớp: quái quanh mình `stun` | Omega Shoot [Đ] `shock` |
| Newton | **Newton Repel** [V] đẩy bay quái, `force` | **Newton Attract** [T] hút quái lại gần rồi giữ trọng lực | Omega Drive (Newton) [T] |

### 18 · Ex-Aid (2016) — màn EX: quái bay (Sports)

| Level | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Action Gamer 2 | **Speed Up item** [C] vật phẩm tốc độ 6 giây | **Muteki Jump** [Đ] nhảy đạp đầu quái (như game) | Mighty Critical Strike [Đ] chữ HIT! |
| Sports | **Shakariki Wheel** [Đ] ném bánh xe (bay vòng về) | **Sports Ride** [Đ] đạp xe lao tới | Shakariki Critical Strike [Đ] |
| Robot | **Robot Arm** [Đ] cánh tay đấm phóng, `crush` | **Gekitotsu Grab** [T] tay robot tóm giữ quái | Gekitotsu Critical Strike [T] |
| Hunter | **Drago Fang** [Đ] chém kiếm rồng | **Drago Breath** [Đ] lửa rồng, `burn` | Drago Knight Critical Strike [Đ] |

### 19 · Build (2017) — màn EX: quái bay (HawkGatling)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| RabbitTank | **Rabbit Hop** [Đ] nhảy lò xo cao | **Tank Tread** [Đ] lăn xích lao tới | Vortex Finish [T] **đồ thị Build**: đường cong trói quái rồi trượt đá theo đồ thị |
| GorillaMond | **Gorilla Punch** [Đ] đấm, `crush` | **Diamond Wall** [P] tường kim cương hấp thụ đạn, phản lại | Vortex Finish (GorillaMond) [T] |
| HawkGatling | **Hawk Flight** [C] bay 5 giây | **Gatling Sphere** [T] lồng cầu bắt quái rồi xả đạn | Full Bullet [T] |
| NinninComic | **Shuriken Clone** [C] phân thân ninja 5 giây | **Comic Shield** [P] trang truyện chặn đòn | Kaen Giri [Đ] `burn` |

### 20 · Zi-O (2018) — màn EX: khổng lồ (Ex-Aid Armor)

8 armor kế thừa sức mạnh Rider. **Mỗi armor dùng đúng bộ skill của form gốc Rider đó** (dấu "="), như Kamen Ride của
Decade; trong code trỏ tới form gốc (`"skills_from"`). Final giữ tên Time Break riêng của armor, kiểu đòn theo Final của
Rider gốc. Chỉ form Zi-O có skill riêng.

| Armor | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Zi-O | **Zikan Girade** [Đ] chém kiếm chữ "KEN" | **Zikan Jacorder** [K] ⚠ cung bắn chắc trúng | Time Break [Đ] đá xuyên chữ "KICK" |
| Build Armor | = Build RabbitTank: **Rabbit Hop** [Đ] | = **Tank Tread** [Đ] | Vortex Time Break [T] (đồ thị trói như Vortex Finish) |
| Ex-Aid Armor | = Ex-Aid Action Gamer 2: **Speed Up item** [C] | = **Muteki Jump** [Đ] | Critical Time Break [Đ] |
| Ghost Armor | = Ghost Ore: **Ghost Phase** [C] | = **Parka Ghost** [K] | Omega Time Break [Đ] |
| Drive Armor | = Drive Type Speed: **Tire Koukan: Midnight Shadow** [Đ] | = **Handle-Ken Drift** [V] | Hissatsu Time Break [K] (lồng Tridoron như SpeeDrop) |
| Gaim Armor | = Gaim Orange: **Musou Saber Shot** [Đ] | = **Daidaimaru Spin** [V] | Burai Time Break [Đ] |
| Wizard Armor | = Wizard Flame: **Defend (Flame)** [P] | = **Bind** [T] | Strike Time Break [Đ] |
| OOO Armor | = OOO TaToBa: **Tora Claws** [Đ] | = **Batta Leap** [Đ] | Scanning Time Break [Đ] (qua 3 vòng Medal) |
| Decade Armor | = Decade: **Attack Ride: Illusion** [C] | = **Attack Ride: Invisible** [C] | Attack Time Break [Đ] |

### 21 · Zero-One (2019) — màn EX: khổng lồ (Freezing Bear)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Rising Hopper | **Hopper Leap** [Đ] nhảy đá bật xa | **Prediction** [C] dự đoán 0,02 giây: né tự động đòn kế tiếp | Rising Impact [Đ] |
| Flaming Tiger | **Tiger Claw** [Đ] vuốt lửa, `burn` | **Flame Burst** [V] phun lửa toàn thân, `burn` | Flaming Impact [Đ] |
| Freezing Bear | **Bear Claw** [Đ] vuốt băng, `freeze` | **Freezing Field** [V] đóng băng mặt đất quanh mình, `freeze` | Freezing Impact [V] |
| Shining Hopper | **Shining Arrow** [Đ] lướt sáng | **Shining Prediction** [K] tính toán, đá chắc trúng | Shining Impact [K] |

### 22 · Saber (2020) — màn EX: khổng lồ (Dragonic Knight)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Brave Dragon | **Kaenken Slash** [Đ] chém lửa, `burn` | **Wonder Ride: Dragon** [K] rồng sách bay tới cắn | Kaen Juujizan [Đ] chém chữ thập lửa |
| Crimson Dragon | **Crimson Wing** [C] cánh lửa bay 4 giây | **Triple Strike** [Đ] 3 nhát chém lửa | Sansatsu Giri [Đ] |
| Dragonic Knight | **Knight Shield** [P] khiên phản đòn | **Dragon Lance** [Đ] đâm thương, `crush` | Shinka Ryuuhazan [Đ] |
| Elemental Primitive | **Element Shift** [C] đổi nguyên tố: đòn có `burn` / `freeze` / `shock` theo vòng | **Elemental Wave** [V] sóng 4 nguyên tố | Hissatsu Dokuha [Đ] |

### 23 · Revice (2021) — màn EX: khổng lồ (Mammoth)

| Genome | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Rex | **Rex Bite** [Đ] cú đá hàm khủng long | **Vice Assist** [K] Vice (con quỷ đồng hành) lao ra đánh quái gần | Rex Stamping Finish [Đ] đá in dấu tem |
| Eagle | **Eagle Flight** [C] bay 5 giây | **Eagle Dive** [Đ] bổ nhào | Eagle Stamping Finish [Đ] |
| Jackal | **Jackal Dash** [Đ] lướt xuyên quái | **Ice Skate** [Đ] trượt băng chém, `freeze` ⚠ | Jackal Stamping Finish [Đ] |
| Mammoth | **Mammoth Stomp** [V] dậm đất, `crush` `stun` | **Tusk Charge** [Đ] húc ngà, `crush` | Mammoth Stamping Finish [V] |

### 24 · Geats (2022) — màn EX: siêu tốc (Boost)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Magnum | **Magnum Shooter** [Đ] bắn liên thanh | **Magnum Lock** [K×2] ngắm 2 quái | Magnum Strike [K] |
| Boost | **Boost Rush** [C] tăng tốc thời gian 4 giây (`time`) | **Boost Kick** [Đ] đá phản lực | Boost Grand Strike [Đ] |
| Powered Builder | **Builder Crane** [T] cần cẩu móc giữ quái | **Builder Drop** [V] thả khối thép, `crush` | Cú giáng Powered Builder [V] |
| Magnum Boost | **Fox Tail** [Đ] đá lửa đuôi cáo | **Boost Magnum Lock** [K×3] | Magnum Boost Grand Victory [K×3] |

### 25 · Gotchard (2023) — màn EX: quái bay (Venom Mariner)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Steamhopper | **Steam Jump** [Đ] nhảy hơi nước | **Steam Cloud** [V] mây hơi nóng, `burn` | Steamhopper Fever [Đ] |
| Appare Skebow | **Skebow Ride** [Đ] lướt ván trượt | **Appare Fan** [V] quạt gió quanh mình, `force` | Appare Skebow Fever [Đ] |
| Venom Mariner | **Venom Shot** [Đ] đạn độc (mất máu theo nhịp) | **Mariner Net** [T] lưới biển trói quái (định hướng) ⚠ | Venom Mariner Fever [K] |
| Burning Gorilla | **Burning Punch** [Đ] đấm lửa, `burn` `crush` | **Gorilla Drum** [V] đấm ngực sóng lửa | Burning Gorilla Fever [Đ] |

### 26 · Gavv (2024) — màn EX: quái bay (Chocodan)

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Poppingummy | **Gummy Punch** [Đ] đấm kẹo dẻo nảy | **Gummy Bounce** [P] thân kẹo dẻo bật đòn ngược lại | Poppingummy Finish [Đ] |
| Fuwamallow | **Mallow Cushion** [P] đệm kẹo xốp đỡ đòn | **Mallow Wrap** [T] bọc kẹo xốp trói quái ⚠ | Fuwamallow Finish [T] |
| Chocodan | **Choco Shot** [Đ] bắn sôcôla | **Choco Lock** [K×3] đạn sôcôla đuổi ⚠ | Chocodan Finish [Đ] |
| Zakuzakuchips | **Chips Slash** [Đ] chém lát khoai | **Chips Rain** [V] mưa lát khoai sắc ⚠ | Zakuzakuchips Finish [Đ] |

### 27 · Zeztz (2025) — màn EX: khổng lồ (Paradigm Gravity)

Nguyên tác còn mới, skill chủ yếu suy theo tên form (⚠ cần xác minh).

| Form | Skill 1 | Skill 2 | Final |
|---|---|---|---|
| Physicam Impact | **Impact Fist** [Đ] đấm chấn động | **Dream Dive** [C] lặn vào giấc mơ: bất tử 2 giây rồi trồi ra sau lưng quái ⚠ | Impact Vanish [Đ] |
| Physicam Wing | **Wing Shot** [Đ] bắn từ trên không | **Wing Flight** [C] bay 5 giây | Wing Vanish [K] |
| Inazuma Plasma | **Plasma Bolt** [Đ] tia sét, `shock` | **Plasma Field** [V] trường điện, `shock` | Plasma Vanish [V] |
| Paradigm Gravity | **Gravity Press** [V] ép trọng lực, `crush` | **Gravity Well** [T] giếng trọng lực hút và giữ quái | Gravity Vanish [T] |

## 4. Trong code

| Phần | File |
|---|---|
| Định dạng skill, giá nộ, hồi chiêu, sát thương mặc định | `scripts/riders/skills.gd` (`Skills.resolve`) |
| Thi triển: khoá, trói, vùng, phản đòn, buff, phân thân, đánh trống, Final theo kiểu | `scripts/player/skill_caster.gd`, `skill_clone.gd` |
| Dữ liệu skill: `"skills"`, `"skills_from"`, `"final_type"`, `"final_targets"` trong form | `scripts/data/worlds/wNN_*.gd`; Kuuga / Faiz / W: hằng `SKILLS` trong `scripts/riders/` |
| Nút U / Y / O, nộ, bị trói / khoá (chế độ đấu), bay, tàng hình | `scripts/player/player.gd`, `scripts/autoload/game_state.gd` (`INPUT_KEYS`) |
| Quái: trói, dấu khoá, lộ điểm yếu, làm chậm | `scripts/enemies/enemy.gd` |
| Đạn skill: tự đuổi, boomerang, lái được, sóng chém | `scripts/combat/projectile.gd` |
| Nút cảm ứng (vòng cung quanh nút Đánh, số nộ ở góc), bảng hướng dẫn, màn chọn form | `scripts/ui/touch_controls.gd`, `touch_button.gd`, `help_overlay.gd`, `figure_picker.gd` |
| Chế độ đấu: skill ×0,6 lên người chơi, trói đứng im ≤ 1,2 giây, báo dấu khoá sang máy đối thủ | `scripts/versus/versus.gd` |
| Khắc chế màn EX tính cả skill | `scripts/riders/rider_caps.gd` |

Kiểm tra:

```bash
godot --headless --path . -s tools/validate_worlds.gd
godot --headless --path . res://tools/skill_test.tscn -- kuuga faiz
```

`skill_test` tung Skill 1, Skill 2, Final của mọi form vào hàng bia và in sát thương / hiệu ứng; dòng `!!` là đáng ngờ.

Khác bảng trên một chút khi làm: Decade Kamen Ride và Zi-O Armor của các Rider ngoài bảng (W, OOO, Fourze... và
Kuuga / Agito... Armor) cũng mượn skill form gốc của Rider đó. Skill "độc" (Venom Shot) dùng cháy vì chưa có hiệu ứng
riêng.

## 5. Đã chốt (theo đề xuất)

- **Nộ ở form đặc biệt:** chọn (A): form đặc biệt thôi tụt nộ, chỉ tốn 10 khi đổi; mọi form đều tích nộ khi đánh
  trúng (form tăng tốc thời gian vẫn tụt). (B) giữ tụt nộ, skill rẻ hơn (10 / 20 / 50).
- **Final:** tốn 60 cố định.
- **Số skill mỗi form:** 2.
