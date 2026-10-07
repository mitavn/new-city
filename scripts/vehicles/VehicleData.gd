class_name VehicleData
extends Resource

## Định danh và Thông tin cơ bản
@export var id: StringName
@export var display_name: String
@export var vehicle_type: StringName = &"car"  ## car, bus, truck, emergency, heavy, water, air, cart, shop
@export var category: StringName = &"land"      ## land, water, air, static
@export_multiline var description: String = ""

@export_category("Visual & Frame Metrics")
## Kích thước frame của từng loại xe (96x96, 112x112, 160x160, 176x176, 192x128, 352x352...)
@export var frame_size: Vector2i = Vector2i(112, 112)
## Offset căn chỉnh để bánh xe / đáy xe chạm đất tại tọa độ gốc (0, 0)
@export var visual_offset: Vector2 = Vector2.ZERO
@export var sprite_frames: SpriteFrames
@export var spritesheet_path: String = ""

@export_category("Gameplay & Physics")
## Kích cỡ vùng va chạm thích ứng theo độ to nhỏ của xe
@export var collision_size: Vector2 = Vector2(48, 24)
## Độ dời vị trí hộp va chạm so với gốc toạ độ (0, 0) của xe
@export var collision_offset: Vector2 = Vector2(0, -6)
@export var max_speed: float = 120.0
@export var acceleration: float = 80.0
@export var has_siren: bool = false
@export var passenger_capacity: int = 4
@export var tags: PackedStringArray = []


## Kiểm tra tài nguyên xe hợp lệ
func is_valid() -> bool:
	return not id.is_empty() and sprite_frames != null


## Lưu tài nguyên xe thành file .tres
func save_to_tres(target_path: String = "") -> Error:
	var path: String = target_path
	if path.is_empty():
		path = "res://data/vehicles/%s.tres" % str(id)
	return ResourceSaver.save(self, path)


# ==============================================================================
# STATIC FACTORY: TỰ ĐỘNG SINH SPRITEFRAMES VỚI CÁC KÍCH THƯỚC XE KHÁC NHAU
# ==============================================================================

## Tự động tính toán và cắt frames cho xe dựa trên kích thước ảnh và frame
static func build_sprite_frames_from_texture(
	texture: Texture2D,
	p_frame_size: Vector2i,
	p_has_siren: bool = false,
	p_is_helicopter: bool = false,
	p_is_shop: bool = false
) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var fw: int = p_frame_size.x
	var fh: int = p_frame_size.y

	# Trường hợp 1: Quầy hàng Food truck shop tĩnh
	if p_is_shop:
		frames.add_animation(&"idle")
		frames.set_animation_speed(&"idle", 1.0)
		frames.set_animation_loop(&"idle", true)
		for f in range(2):
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(f * fw, 0, fw, fh)
			frames.add_frame(&"idle", atlas)
		return frames

	# Trường hợp 2: Trực thăng (2 hàng x 4 cột)
	if p_is_helicopter:
		var heli_anims = [
			{"name": &"fly_right", "row": 0},
			{"name": &"fly_left", "row": 1}
		]
		for ha in heli_anims:
			var an: StringName = ha["name"]
			frames.add_animation(an)
			frames.set_animation_speed(an, 10.0)
			frames.set_animation_loop(an, true)
			for f in range(4):
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(f * fw, ha["row"] * fh, fw, fh)
				frames.add_frame(an, atlas)
		return frames

	# Trường hợp 3: Xe thông thường 4 hướng (4 hàng x 4 cột)
	var dir_configs = [
		{"name": &"drive_front_right", "row": 0},
		{"name": &"drive_front_left", "row": 1},
		{"name": &"drive_back", "row": 2},
		{"name": &"drive_front", "row": 3}
	]

	for cfg in dir_configs:
		var an: StringName = cfg["name"]
		frames.add_animation(an)
		frames.set_animation_speed(an, 6.0)
		frames.set_animation_loop(an, true)

		for f in range(4):
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(f * fw, cfg["row"] * fh, fw, fh)
			frames.add_frame(an, atlas)

	# Nếu có còi đèn ưu tiên (hàng 4..7)
	if p_has_siren:
		var siren_configs = [
			{"name": &"siren_front_right", "row": 4},
			{"name": &"siren_front_left", "row": 5},
			{"name": &"siren_back", "row": 6},
			{"name": &"siren_front", "row": 7}
		]
		for scfg in siren_configs:
			var san: StringName = scfg["name"]
			frames.add_animation(san)
			frames.set_animation_speed(san, 8.0)
			frames.set_animation_loop(san, true)

			for f in range(4):
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(f * fw, scfg["row"] * fh, fw, fh)
				frames.add_frame(san, atlas)

	return frames


## Tạo mới đối tượng VehicleData nhanh chóng
static func create_from_texture(
	texture: Texture2D,
	p_id: StringName,
	p_display_name: String,
	p_frame_size: Vector2i,
	p_type: StringName = &"car",
	p_has_siren: bool = false
) -> VehicleData:
	var data: VehicleData = VehicleData.new()
	data.id = p_id
	data.display_name = p_display_name
	data.frame_size = p_frame_size
	data.vehicle_type = p_type
	data.has_siren = p_has_siren
	
	var is_heli: bool = p_type == &"air"
	var is_shop: bool = p_type == &"shop"
	data.sprite_frames = build_sprite_frames_from_texture(texture, p_frame_size, p_has_siren, is_heli, is_shop)
	if texture:
		data.spritesheet_path = texture.resource_path

	return data
