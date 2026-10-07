@tool
class_name VehicleBase
extends CharacterBody2D

## Base Controller cho tất cả các loại phương tiện (Ô tô, Xe buýt, Tàu thuyền, Trực thăng...)
## Hỗ trợ tự động căn chỉnh kích thước va chạm (Collision Size) theo độ to nhỏ của xe,
## hoạt ảnh 4 hướng 2.5D và chế độ còi đèn ưu tiên (Siren).

enum VehicleState {
	PARKED,
	IDLE,
	DRIVING,
	DISABLED
}

signal interacted(driver: Node)
signal siren_toggled(active: bool)
signal state_changed(old_state: VehicleState, new_state: VehicleState)

## Dữ liệu cấu hình xe (Data-driven Resource)
@export var data: VehicleData:
	set(value):
		if data and data.changed.is_connected(_apply_data):
			data.changed.disconnect(_apply_data)
		data = value
		if data and not data.changed.is_connected(_apply_data):
			data.changed.connect(_apply_data)
		_apply_data()

var _facing_direction_name: String = "front_right"

## Hướng quay mặt hiện tại (Inspector và Runtime)
@export_enum("front_right", "front_left", "back", "front") var facing_direction_name: String:
	set(value):
		if _facing_direction_name == value:
			return
		_facing_direction_name = value
		set_direction_by_name(value)
	get:
		return _facing_direction_name

## Trạng thái bật/tắt còi đèn ưu tiên (cho Cảnh sát, Cứu thương, Cứu hỏa)
@export var siren_active: bool = false:
	set(value):
		siren_active = value
		siren_toggled.emit(siren_active)
		_on_siren_toggled(siren_active)
		_update_animation_state(velocity.length_squared() > 1.0, facing_direction)

@export var current_state: VehicleState = VehicleState.IDLE

## Node References
@onready var visual: AnimatedSprite2D = $Visual
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var interaction_area: Area2D = $InteractionArea
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

## Internal Variables
var facing_direction: Vector2 = Vector2(1, 1).normalized()


func _ready() -> void:
	_setup_interaction()
	_apply_data()
	
	if not Engine.is_editor_hint():
		_setup_vehicle()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_on_vehicle_tick(delta)

	match current_state:
		VehicleState.PARKED, VehicleState.IDLE:
			velocity = Vector2.ZERO
			# Không gọi move_and_slide() khi đỗ hoặc đứng yên để xe/thuyền không bị NPC xô đẩy hay trôi dạt!
			_update_animation_state(false, facing_direction)
		VehicleState.DRIVING:
			move_and_slide()
			_update_animation_state(true, facing_direction)


## Áp dụng toàn bộ dữ liệu từ VehicleData vào thực thể (Collision, Visual Offset, Frames)
func _apply_data() -> void:
	if not is_node_ready() or visual == null or data == null:
		return

	visual.sprite_frames = data.sprite_frames

	# Tự động điều chỉnh kích thước va chạm thích ứng theo độ to nhỏ của xe
	if body_collision and body_collision.shape:
		if not body_collision.shape.resource_local_to_scene:
			body_collision.shape = body_collision.shape.duplicate()
		if body_collision.shape is RectangleShape2D:
			body_collision.shape.size = data.collision_size
		elif body_collision.shape is CircleShape2D:
			body_collision.shape.radius = maxf(data.collision_size.x, data.collision_size.y) * 0.5
		body_collision.position = data.collision_offset

	# Tự động căn chỉnh vị trí Visual để bánh xe tiếp xúc đúng mặt đất (0, 0)
	var fh: float = float(data.frame_size.y)
	if data.visual_offset != Vector2.ZERO:
		visual.position = data.visual_offset
	else:
		visual.position = Vector2(0, -fh * 0.35)

	set_direction_by_name(_facing_direction_name)


# ==============================================================================
# HƯỚNG ĐỐI TƯỢNG: CÁC PHƯƠNG THỨC ẢO (VIRTUAL / HOOK METHODS)
# ==============================================================================

func _setup_vehicle() -> void:
	pass


func _on_vehicle_tick(_delta: float) -> void:
	pass


func _on_siren_toggled(_active: bool) -> void:
	pass


func interact(driver: Node = null) -> void:
	interacted.emit(driver)
	_on_interact(driver)


func _on_interact(_driver: Node) -> void:
	if data and data.has_siren:
		siren_active = not siren_active


# ==============================================================================
# HỆ THỐNG HOẠT HỌA & ĐIỀU HƯỚNG XE 2.5D
# ==============================================================================

## Chuyển vector hướng thành tên hướng của xe:
## front_right (xuống phải / phải), front_left (xuống trái / trái), back (lên), front (xuống)
func get_direction_suffix(dir: Vector2) -> String:
	if dir == Vector2.ZERO:
		dir = facing_direction

	# Trực thăng chỉ có 2 hướng trái/phải
	if data and data.vehicle_type == &"air":
		return "right" if dir.x >= 0.0 else "left"

	# Xe 4 hướng:
	# Nếu di chuyển nghiêng hoặc ngang
	if absf(dir.x) > absf(dir.y) * 0.7:
		return "front_right" if dir.x >= 0.0 else "front_left"
	else:
		# Di chuyển thẳng đứng lên/xuống
		return "front" if dir.y >= 0.0 else "back"


## Cập nhật animation tương ứng
func _update_animation_state(_is_moving: bool, dir: Vector2) -> void:
	if visual == null or visual.sprite_frames == null or data == null:
		return

	# Shop tĩnh
	if data.vehicle_type == &"shop":
		if visual.sprite_frames.has_animation(&"idle"):
			visual.play(&"idle")
		return

	# Trực thăng
	if data.vehicle_type == &"air":
		var heli_anim = "fly_" + ("right" if dir.x >= 0.0 else "left")
		if visual.sprite_frames.has_animation(heli_anim):
			visual.play(heli_anim)
		return

	var suffix: String = get_direction_suffix(dir)

	# Khi phương tiện đứng yên (đỗ hoặc IDLE):
	if not _is_moving or current_state == VehicleState.PARKED:
		if visual.sprite_frames.has_animation("idle_" + suffix):
			if visual.animation != "idle_" + suffix or not visual.is_playing():
				visual.play("idle_" + suffix)
		elif visual.sprite_frames.has_animation("idle"):
			if visual.animation != "idle" or not visual.is_playing():
				visual.play("idle")
		else:
			# Dừng hoạt ảnh drive, giữ frame 0 để thuyền/xe tĩnh mượt mà, không bị giật hình
			var base_anim = "drive_" + suffix
			if not visual.sprite_frames.has_animation(base_anim):
				base_anim = "drive_front_right" if visual.sprite_frames.has_animation("drive_front_right") else visual.sprite_frames.get_animation_names()[0]
			if visual.animation != base_anim:
				visual.animation = base_anim
			visual.stop()
			visual.frame = 0
		return

	# Khi phương tiện đang di chuyển (DRIVING):
	var prefix: String = "siren_" if (siren_active and data.has_siren) else "drive_"
	var anim_name: String = prefix + suffix

	if visual.sprite_frames.has_animation(anim_name):
		if visual.animation != anim_name or not visual.is_playing():
			visual.play(anim_name)
	elif visual.sprite_frames.has_animation("drive_" + suffix):
		if visual.animation != ("drive_" + suffix) or not visual.is_playing():
			visual.play("drive_" + suffix)
	elif visual.sprite_frames.has_animation("drive_front_right"):
		if visual.animation != "drive_front_right" or not visual.is_playing():
			visual.play("drive_front_right")


## Đặt hướng xe theo tên chuỗi ("front_right", "front_left", "back", "front")
func set_direction_by_name(dir_name: String) -> void:
	match dir_name:
		"front_right":
			facing_direction = Vector2(1, 0.5).normalized()
		"front_left":
			facing_direction = Vector2(-1, 0.5).normalized()
		"back":
			facing_direction = Vector2(0, -1)
		"front":
			facing_direction = Vector2(0, 1)

	_facing_direction_name = dir_name
	_update_animation_state(velocity.length_squared() > 1.0, facing_direction)


## Đặt hướng xe bằng Vector2
func set_facing_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.001:
		facing_direction = dir.normalized()
		_facing_direction_name = get_direction_suffix(facing_direction)
		_update_animation_state(velocity.length_squared() > 1.0, facing_direction)


func _setup_interaction() -> void:
	if interaction_area:
		if not interaction_area.input_event.is_connected(_on_interaction_area_input):
			interaction_area.input_event.connect(_on_interaction_area_input)


func _on_interaction_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interact(null)
