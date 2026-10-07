class_name CarVehicle
extends VehicleBase

## Lớp xe con / taxi dân sự kế thừa từ VehicleBase
## Tiếng còi bíp và phong cách di chuyển đô thị.

@export var horn_sound_pitch: float = 1.0

func _setup_vehicle() -> void:
	pass


func _on_interact(_driver: Node) -> void:
	# Còi xe khi click tương tác
	print("[%s]: Bíp bíp!" % (data.display_name if data else "Xe"))
