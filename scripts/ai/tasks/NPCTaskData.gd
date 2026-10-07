class_name NPCTaskData
extends Resource

## Nhiệm vụ nguyên tử dành cho NPC trong Hệ Thống AI Data-Driven.
## Cho phép cấu hình các hành vi: Di chuyển tới toạ độ / POI, đứng chờ, phát biểu cảm,
## nói thoại, tương tác công trình hoặc đi tuần theo lộ trình.

enum TaskType {
	GOTO_LOCATION,   ## Đi tới vị trí toạ độ cụ thể
	GOTO_POI,        ## Đi tới Điểm Yêu Thích (POI tag: ramen_stand, customs, bank, etc.)
	WAIT,            ## Đứng chờ tại chỗ (nhìn quanh, nghỉ ngơi)
	PLAY_EMOTE,      ## Kích hoạt Emote từ EmoteRegistry
	SPEAK,           ## Phát câu thoại / hội thoại
	INTERACT_OBJECT, ## Tương tác với công trình / phương tiện (gõ cửa, lên xe)
	WANDER_AREA,     ## Đi tản bộ tự do trong bán kính xác định
	PATROL           ## Đi tuần giữa các trạm kiểm soát
}

@export_category("Task Identity")
@export var task_id: StringName
@export var task_name: String
@export var type: TaskType = TaskType.GOTO_POI
@export_multiline var description: String = ""

@export_category("Target & Navigation")
@export var target_pos: Vector2 = Vector2.ZERO
@export var poi_tag: StringName = &""
@export var arrival_distance: float = 18.0
@export var speed_multiplier: float = 1.0

@export_category("Action & Interaction")
@export var duration: float = 3.0
@export var emote_id: StringName = &""
@export var dialogue_text: String = ""
@export var wander_radius: float = 80.0


func is_valid() -> bool:
	return not task_id.is_empty()
