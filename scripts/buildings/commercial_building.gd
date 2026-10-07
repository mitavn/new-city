@tool
class_name CommercialBuilding
extends BuildingBase

## Tòa nhà thương mại / dịch vụ (Tiệm bánh, Quán cafe, Siêu thị, Ngân hàng...)
## Có logic chuông báo khách khi cửa mở và thời gian mở/đóng kinh doanh.

@export var store_open: bool = true
@export var bell_chime: bool = true

func _ready() -> void:
	super._ready()
	door_opened.connect(_on_commercial_door_opened)

func _on_commercial_door_opened(_door_idx: int) -> void:
	# Khách bước vào cửa hàng
	pass
