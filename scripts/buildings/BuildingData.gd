@tool
class_name BuildingData
extends Resource

## Data model cho tòa nhà với hoạt ảnh cửa đóng mở (Building Door Animation Data).
## Hỗ trợ 1 cửa đơn hoặc 2 cửa độc lập (cửa trái / cửa phải),
## và các biến thể màu sắc khác nhau trong cùng 1 spritesheet.

@export var id: StringName = &""
@export var display_name: String = ""
@export var building_type: StringName = &"commercial" ## commercial, public, residential, emergency, industrial, amenity
@export_multiline var description: String = ""

## Kích thước của mỗi frame (pixel)
@export var frame_size: Vector2i = Vector2i(112, 160)

## Số lượng cửa có thể mở độc lập (1 hoặc 2)
@export_range(1, 2) var door_count: int = 1

## Tên cửa (Ví dụ: ["Cửa Chính"] hoặc ["Cửa Trái", "Cửa Phải"] / ["Cửa Nhân Viên", "Cửa Cuốn Gara"])
@export var door_names: Array[String] = ["Cửa Chính"]

## Biến thể màu sắc (ví dụ: "default", "blue", "yellow", "red", "pink")
@export var color_variant: String = "default"

## Bộ SpriteFrames chứa các animation đóng/mở cửa
@export var sprite_frames: SpriteFrames

## Đường dẫn tệp ảnh spritesheet gốc
@export_file("*.png") var spritesheet_path: String = ""

## Kích thước hộp va chạm chân đế tòa nhà (Collision Footprint)
@export var collision_size: Vector2 = Vector2(96, 60)

## Độ dời chân đế va chạm so với gốc toạ độ (0, 0)
@export var collision_offset: Vector2 = Vector2(0, -10)

## Vị trí tương đối của các cửa (Door Hotspots) để người chơi/NPC tương tác hoặc đi vào
@export var door_positions: Array[Vector2] = [Vector2(0, 0)]

## Nhãn phân loại
@export var tags: PackedStringArray = []


func is_two_door() -> bool:
	return door_count >= 2


func get_door_name(index: int) -> String:
	if index >= 0 and index < door_names.size():
		return door_names[index]
	return "Cửa %d" % (index + 1)
