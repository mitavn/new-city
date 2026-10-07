class_name PoliceNPC
extends NPCBase

## Lớp đối tượng NPC Cảnh Sát kế thừa từ NPCBase
## Thực thi nhiệm vụ tuần tra an ninh, nhắc nhở trật tự.

@export var is_patrolling: bool = true
@export var patrol_alert_radius: float = 150.0

func _setup_npc() -> void:
	auto_wander = is_patrolling


func _on_interact(initiator: Node) -> void:
	super._on_interact(initiator)


func _get_dialogue() -> String:
	if data and not data.dialogues.is_empty():
		return "[Cảnh sát]: " + data.get_random_dialogue()
	return "[Cảnh sát]: Khu vực an toàn. Chúc bạn có một ngày tốt lành!"
