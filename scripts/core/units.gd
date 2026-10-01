extends RefCounted
class_name Units
## Tỉ lệ đổi từ "đơn vị thiết kế" sang pixel thật trên màn hình.
##
## Mọi thông số trong GDD và trong code (tầm đánh, kích thước hitbox, tốc độ, lực đẩy) được viết cho
## nhân vật cao ~32 px. Sprite PixelLab cao ~60 px, nên các giá trị đó nhân với SCALE lúc chạy:
## Hitbox (kích thước, vị trí), tốc độ di chuyển, nhảy, né, lao tới, lực đẩy, tầm nhìn và tầm đánh của quái.
## Trọng lực trong project.godot đã nhân sẵn (900 × 1.8 = 1620).
## Nhờ vậy số liệu cân bằng trong GDD giữ nguyên, muốn đổi cỡ nhân vật chỉ cần sửa một số này.

const SCALE := 1.8
