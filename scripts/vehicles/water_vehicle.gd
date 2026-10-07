class_name WaterVehicle
extends VehicleBase

## Lớp phương tiện đường thủy (Thuyền, Tàu buôn, Phà) kế thừa từ VehicleBase
## Di chuyển trên mặt nước, có hiệu ứng nhấp nhô nhẹ.

var wave_time: float = 0.0

func _setup_vehicle() -> void:
	pass


func _on_vehicle_tick(delta: float) -> void:
	# Hiệu ứng nhấp nhô nhẹ trên mặt nước
	wave_time += delta * 2.0
	if visual:
		visual.position.y += sin(wave_time) * 0.15


func _on_interact(_driver: Node) -> void:
	print("[%s]: Tàu thuyền đường thủy sẵn sàng xuất bến!" % (data.display_name if data else "Tàu"))
