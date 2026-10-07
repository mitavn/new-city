class_name CivilianNPC
extends NPCBase

## Lớp đối tượng NPC Người Dân kế thừa từ NPCBase
## Thực hiện hành vi đi dạo tự do và chào hỏi thân thiện.

@export var greeting_prefix: String = "Chào bạn! "

func _setup_npc() -> void:
	# Người dân thành phố mặc định tự do đi dạo
	auto_wander = true


func _on_interact(initiator: Node) -> void:
	# Gọi logic tương tác cơ bản (quay mặt về phía người gọi)
	super._on_interact(initiator)


func _get_dialogue() -> String:
	if data and not data.dialogues.is_empty():
		return greeting_prefix + data.get_random_dialogue()
	return greeting_prefix + "Hôm nay thời tiết đẹp quá!"
