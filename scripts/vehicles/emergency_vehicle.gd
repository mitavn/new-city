class_name EmergencyVehicle
extends VehicleBase

## Lớp xe ưu tiên (Cảnh sát, Cứu thương, Cứu hỏa) kế thừa từ VehicleBase
## Có còi hú và đèn nhấp nháy khẩn cấp (Siren).

func _setup_vehicle() -> void:
	if data:
		data.has_siren = true


func _on_interact(_driver: Node) -> void:
	siren_active = not siren_active
	var status = "BẬT" if siren_active else "TẮT"
	print("[%s]: Đã %s còi đèn ưu tiên (Siren)!" % [(data.display_name if data else "Xe Ưu Tiên"), status])
