@tool
class_name EmergencyBuilding
extends BuildingBase

## Tòa nhà khẩn cấp (Trạm Cứu Hỏa, Đồn Cảnh Sát)
## Thường có 2 cửa: Cửa đi bộ nhân viên và Cửa cuốn gara xuất xe cứu hỏa / xe tuần tra.

signal emergency_alarm_triggered(active: bool)

@export var alarm_active: bool = false:
	set(value):
		alarm_active = value
		emergency_alarm_triggered.emit(alarm_active)
		if alarm_active:
			open_all_doors()

## Mở cửa cuốn gara để xe xuất kích
func dispatch_vehicle() -> void:
	if data and data.door_count >= 2:
		open_door(1) # Cửa gara
