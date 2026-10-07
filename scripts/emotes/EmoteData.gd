class_name EmoteData
extends Resource

## Định danh và Thông tin cơ bản của Biểu Cảm (Data-Driven Emote)
## Hỗ trợ tạo Quest, hội thoại, sự kiện đô thị và tương tác trực quan.
@export var id: StringName
@export var display_name: String
@export var category: StringName = &"general" ## general, quest, mood, reaction, action
@export var row_index: int = 0                ## Vị trí hàng trên spritesheet (0..20)
@export_multiline var description: String = ""

@export_category("Frame Metrics")
@export var frame_size: Vector2i = Vector2i(32, 16)
@export var frame_count: int = 4
@export var fps: float = 5.0
@export var loop: bool = true
@export var offset_y: float = -42.0
@export var default_duration: float = 2.2

@export_category("Spritesheet & Resources")
@export var sprite_frames: SpriteFrames
@export var spritesheet_path: String = "res://assets/spritesheets/characters/Character Emoteicon-Sheet.png"
@export var tags: PackedStringArray = []


func has_tag(p_tag: StringName) -> bool:
	return tags.has(str(p_tag))


func is_valid() -> bool:
	return not id.is_empty() and sprite_frames != null


func save_to_tres(target_path: String = "") -> Error:
	var path: String = target_path
	if path.is_empty():
		path = "res://data/emotes/%s.tres" % str(id)
	return ResourceSaver.save(self, path)


## Static Factory: Tạo SpriteFrames 32x16 cho một hàng biểu cảm
static func build_sprite_frames_from_texture(
	texture: Texture2D,
	p_row: int,
	p_frame_size: Vector2i = Vector2i(32, 16),
	p_count: int = 4,
	p_fps: float = 5.0
) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"play")
	frames.set_animation_speed(&"play", p_fps)
	frames.set_animation_loop(&"play", true)

	for c in range(p_count):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(c * p_frame_size.x, p_row * p_frame_size.y, p_frame_size.x, p_frame_size.y)
		frames.add_frame(&"play", atlas)

	return frames
