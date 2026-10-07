class_name ServiceNPC
extends NPCBase

## Lớp đối tượng NPC Dịch Vụ / Ngành Nghề (Bác sĩ, Đầu bếp, Thợ xây, Cứu hỏa, v.v.)
## Kế thừa từ NPCBase với các hành vi chuyên biệt theo vai trò công việc.

@export var workplace_name: String = ""

func _setup_npc() -> void:
	# NPC ngành nghề có thể đứng tại chỗ làm việc hoặc đi tuần trong phạm vi hẹp
	if data and data.wander_radius > 60.0:
		data.wander_radius = 60.0


func _on_interact(initiator: Node) -> void:
	super._on_interact(initiator)


func _get_dialogue() -> String:
	var role_title: String = str(data.role).capitalize() if data else "Dịch Vụ"
	if data and not data.dialogues.is_empty():
		return "[%s]: %s" % [role_title, data.get_random_dialogue()]
	return "[%s]: Rất vui được hỗ trợ bạn!" % role_title
