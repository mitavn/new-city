class_name NPCData
extends Resource

const NPCRoutineData = preload("res://scripts/ai/tasks/NPCRoutineData.gd")

## Định danh và Thông tin cơ bản
@export var id: StringName
@export var display_name: String
@export var role: StringName = &"civilian"
@export var gender: StringName = &"unknown"
@export_multiline var description: String = ""

@export_category("Visual")
@export var sprite_frames: SpriteFrames
@export var spritesheet_path: String = ""

@export_category("Gameplay")
@export var move_speed: float = 60.0
@export var wander_radius: float = 120.0
@export var min_idle_time: float = 1.5
@export var max_idle_time: float = 4.0
@export var default_routine: NPCRoutineData

@export_category("Dialogue & Interaction")
@export var interaction_type: StringName = &"talk"
@export var dialogues: Array[String] = []
@export var tags: PackedStringArray = []


## Lấy câu thoại ngẫu nhiên của NPC
func get_random_dialogue() -> String:
	if dialogues.is_empty():
		return "..."
	return dialogues[randi() % dialogues.size()]


## Kiểm tra tag định danh
func has_tag(tag: StringName) -> bool:
	return tags.has(str(tag))


## Kiểm tra tài nguyên NPC hợp lệ
func is_valid() -> bool:
	return not id.is_empty() and sprite_frames != null


## Lưu tài nguyên này thành tệp .tres trong Godot
func save_to_tres(target_path: String = "") -> Error:
	var path: String = target_path
	if path.is_empty():
		path = "res://data/npcs/%s.tres" % str(id)
	return ResourceSaver.save(self, path)


# ==============================================================================
# STATIC FACTORY: TỰ ĐỘNG SINH SPRITEFRAMES VÀ NPCDATA CHỈ TỪ TEXTURE & TÊN
# ==============================================================================

## Tự động phân chia 32 frame cho 8 animation từ bất kỳ spritesheet Texture2D (512x96)
static func build_sprite_frames_from_texture(texture: Texture2D) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var anim_configs: Array[Dictionary] = [
		{"name": &"idle_front_left", "x": 0, "y": 0},
		{"name": &"idle_front_right", "x": 128, "y": 0},
		{"name": &"idle_back_right", "x": 256, "y": 0},
		{"name": &"idle_back_left", "x": 384, "y": 0},
		{"name": &"walk_front_left", "x": 0, "y": 48},
		{"name": &"walk_front_right", "x": 128, "y": 48},
		{"name": &"walk_back_right", "x": 256, "y": 48},
		{"name": &"walk_back_left", "x": 384, "y": 48},
	]

	for cfg in anim_configs:
		var anim_name: StringName = cfg["name"]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, 5.0)
		frames.set_animation_loop(anim_name, true)

		for f in range(4):
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(cfg["x"] + f * 32, cfg["y"], 32, 48)
			frames.add_frame(anim_name, atlas)

	return frames


## Tạo mới đối tượng NPCData chỉ bằng Texture và Tên
static func create_from_texture(
	texture: Texture2D,
	p_id: StringName,
	p_display_name: String,
	p_role: StringName = &"civilian",
	p_gender: StringName = &"unknown",
	p_speed: float = 60.0
) -> NPCData:
	var data: NPCData = NPCData.new()
	data.id = p_id
	data.display_name = p_display_name
	data.role = p_role
	data.gender = p_gender
	data.move_speed = p_speed
	data.sprite_frames = build_sprite_frames_from_texture(texture)
	if texture:
		data.spritesheet_path = texture.resource_path
	return data
