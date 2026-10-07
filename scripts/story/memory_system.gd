class_name MemorySystem
extends Node

## Hệ Thống Ký Ức Đa Tầng 12 Năm Trước (Memory & Timeline Shift System)
## Nguyên lý cốt lõi: MỘT BẢN ĐỒ — HAI THỜI ĐẠI (Single Map / Dual Timeline)
## Khi kích hoạt Flashback:
## 1. Không load Scene mới! Dùng CanvasModulate chuyển tone màu hoài niệm (Sepia Retro / Warm Nostalgia)
## 2. Người chơi điều khiển phiên bản 17 tuổi cùng nhóm bạn thời thơ ấu
## 3. Khi kết thúc ký ức: Chuyển mờ trở về hiện tại (29 tuổi), đứng trơ trọi tại đúng vị trí đó
## 4. Mở khóa manh mối mới trong ClueJournal và thay đổi phản ứng của NPC xung quanh

signal flashback_started(memory_id: String, title: String)
signal flashback_ended(memory_id: String)

var is_in_flashback: bool = false
var active_memory_id: String = ""

# Lưu lại trạng thái của nhân vật trước khi vào ký ức
var _pre_flashback_pos: Vector2 = Vector2.ZERO


## Kích hoạt một đoạn hồi ức 12 năm trước trên cùng không gian bản đồ
func trigger_flashback(memory_id: String, memory_title: String, root_scene: Node2D) -> void:
	if is_in_flashback:
		return

	is_in_flashback = true
	active_memory_id = memory_id

	# Đổi ánh sáng toàn màn hình sang tone màu vàng nâu hoài niệm (Sepia Retro)
	var modulate = root_scene.get_node_or_null("WorldLighting") as CanvasModulate
	if modulate:
		var tween = root_scene.create_tween()
		tween.tween_property(modulate, "color", Color(1.15, 0.95, 0.72, 1.0), 1.2)

	flashback_started.emit(memory_id, memory_title)


## Trở về thực tại (29 tuổi)
func return_to_present(root_scene: Node2D, original_color: Color = Color.WHITE) -> void:
	if not is_in_flashback:
		return

	is_in_flashback = false
	var finished_id = active_memory_id
	active_memory_id = ""

	# Khôi phục ánh sáng hiện tại
	var modulate = root_scene.get_node_or_null("WorldLighting") as CanvasModulate
	if modulate:
		var tween = root_scene.create_tween()
		tween.tween_property(modulate, "color", original_color, 1.5)

	flashback_ended.emit(finished_id)
