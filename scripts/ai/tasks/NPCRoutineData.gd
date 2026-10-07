class_name NPCRoutineData
extends Resource

const NPCTaskData = preload("res://scripts/ai/tasks/NPCTaskData.gd")

## Chuỗi Lộ Trình / Nhiệm Vụ Hàng Ngày của NPC (Data-Driven Routine).
## Quản lý danh sách các công việc, lịch trình sinh hoạt và hành vi tuần tự.

@export_category("Routine Identity")
@export var routine_id: StringName
@export var routine_name: String
@export var category: StringName = &"general" ## worker, patrol, citizen, sailor, service
@export_multiline var description: String = ""

@export_category("Execution Settings")
@export var loop_infinitely: bool = true
@export var max_loops: int = -1
@export var tasks: Array[NPCTaskData] = []


func get_task_count() -> int:
	return tasks.size()


func get_task(index: int) -> NPCTaskData:
	if index >= 0 and index < tasks.size():
		return tasks[index]
	return null


func is_valid() -> bool:
	return not routine_id.is_empty() and not tasks.is_empty()
