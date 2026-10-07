class_name LargeVehicle
extends VehicleBase

## Lớp xe cỡ lớn (Xe buýt, Xe ủi, Xe tải thực phẩm) kế thừa từ VehicleBase
## Trọng tải lớn, vùng va chạm mở rộng và gia tốc đầm chắc.

func _setup_vehicle() -> void:
	# Đảm bảo va chạm đủ lớn theo xe
	if data and body_collision and body_collision.shape:
		body_collision.shape.size = data.collision_size


func _on_interact(_driver: Node) -> void:
	print("[%s]: Động cơ hạng nặng đang hoạt động." % (data.display_name if data else "Xe Lớn"))
