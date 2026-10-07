@tool
class_name BuildingBase
extends StaticBody2D

## Base Controller cho tất cả các Tòa Nhà Đô Thị có cửa đóng mở (Building Entity).
## Hỗ trợ 1 cửa đơn hoặc 2 cửa độc lập (Cửa Trái / Cửa Phải / Cửa Cuốn Gara),
## tương tác khi click chuột hoặc khi người chơi / NPC bước vào khu vực cửa.

signal door_opened(door_index: int)
signal door_closed(door_index: int)
signal interacted(door_index: int, visitor: Node)

enum DoorState {
	CLOSED,
	OPENING,
	OPENED,
	CLOSING
}

## Tài nguyên dữ liệu của tòa nhà
@export var data: BuildingData:
	set(value):
		if data and data.changed.is_connected(_apply_data):
			data.changed.disconnect(_apply_data)
		data = value
		if data and not data.changed.is_connected(_apply_data):
			data.changed.connect(_apply_data)
		_apply_data()

## Trạng thái Cửa 1 (Cửa Chính / Cửa Trái) trong Inspector & Runtime
@export var door_0_open: bool = false:
	set(value):
		door_0_open = value
		if not is_node_ready():
			return
		if door_0_open:
			_play_open_door(0)
		else:
			_play_close_door(0)

## Trạng thái Cửa 2 (Cửa Phải / Cửa Gara) trong Inspector & Runtime
@export var door_1_open: bool = false:
	set(value):
		door_1_open = value
		if not is_node_ready():
			return
		if door_1_open:
			_play_open_door(1)
		else:
			_play_close_door(1)

const OcclusionFader2DClass = preload("res://scripts/effects/OcclusionFader2D.gd")

## Tự động đóng cửa sau số giây (0 = không tự đóng)
@export var auto_close_delay: float = 3.5

## Bật hiệu ứng làm mờ khi người chơi đứng phía sau tòa nhà
@export var enable_occlusion_fade: bool = true

## Node References
@onready var visual: AnimatedSprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $BodyCollision
@onready var door_0_area: Area2D = $Door0Area
@onready var door_1_area: Area2D = $Door1Area

var occluder_fader: Area2D = null

var _door_0_state: DoorState = DoorState.CLOSED
var _door_1_state: DoorState = DoorState.CLOSED
var _door_0_timer: float = 0.0
var _door_1_timer: float = 0.0


func _ready() -> void:
	_setup_interaction_areas()
	_apply_data()

	if visual:
		if not visual.animation_finished.is_connected(_on_visual_animation_finished):
			visual.animation_finished.connect(_on_visual_animation_finished)

	# Khởi tạo trạng thái ban đầu
	if door_0_open:
		_set_door_state_immediate(0, true)
	else:
		_set_door_state_immediate(0, false)

	if data and data.door_count >= 2:
		if door_1_open:
			_set_door_state_immediate(1, true)
		else:
			_set_door_state_immediate(1, false)

	if enable_occlusion_fade and not Engine.is_editor_hint():
		_setup_occlusion_fader()


func _setup_occlusion_fader() -> void:
	occluder_fader = get_node_or_null("OcclusionFader2D")
	if occluder_fader == null:
		occluder_fader = OcclusionFader2DClass.new()
		occluder_fader.name = "OcclusionFader2D"
		occluder_fader.target_node = visual if visual else self
		add_child(occluder_fader)

	if data != null and occluder_fader.has_method("setup_auto_occlusion_shape"):
		var vh: float = float(data.frame_size.y)
		var bw: float = data.collision_size.x
		var by: float = data.collision_offset.y
		occluder_fader.setup_auto_occlusion_shape(vh, bw, by)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Xử lý tự động đóng cửa nếu có bật auto_close_delay
	if auto_close_delay > 0.0:
		if _door_0_state == DoorState.OPENED:
			_door_0_timer += delta
			if _door_0_timer >= auto_close_delay:
				close_door(0)

		if _door_1_state == DoorState.OPENED:
			_door_1_timer += delta
			if _door_1_timer >= auto_close_delay:
				close_door(1)


func _apply_data() -> void:
	if not is_node_ready() or visual == null or data == null:
		return

	visual.sprite_frames = data.sprite_frames

	# Căn chỉnh vị trí Visual: Gốc toạ độ (0, 0) tại chân đế mặt đất
	var fh: float = float(data.frame_size.y)
	visual.position = Vector2(0, -fh * 0.5)

	# Căn chỉnh kích thước va chạm chân đế
	if collision_shape and collision_shape.shape is RectangleShape2D:
		if not collision_shape.shape.resource_local_to_scene:
			collision_shape.shape = collision_shape.shape.duplicate()
		collision_shape.shape.size = data.collision_size
		collision_shape.position = data.collision_offset

	# Căn chỉnh khu vực tương tác cửa
	if door_0_area and data.door_positions.size() > 0:
		door_0_area.position = data.door_positions[0]

	if door_1_area:
		if data.door_count >= 2 and data.door_positions.size() > 1:
			door_1_area.visible = true
			door_1_area.position = data.door_positions[1]
		else:
			door_1_area.visible = false


# ==============================================================================
# HỆ THỐNG ĐIỀU KHIỂN HOẠT ẢNH CỬA (DOOR ANIMATION CONTROLLER)
# ==============================================================================

func open_door(door_index: int = 0) -> void:
	if door_index == 0:
		door_0_open = true
	elif door_index == 1 and data and data.door_count >= 2:
		door_1_open = true


func close_door(door_index: int = 0) -> void:
	if door_index == 0:
		door_0_open = false
	elif door_index == 1 and data and data.door_count >= 2:
		door_1_open = false


func toggle_door(door_index: int = 0) -> void:
	if door_index == 0:
		open_door(0) if not door_0_open else close_door(0)
	elif door_index == 1 and data and data.door_count >= 2:
		open_door(1) if not door_1_open else close_door(1)


func open_all_doors() -> void:
	open_door(0)
	if data and data.door_count >= 2:
		open_door(1)


func close_all_doors() -> void:
	close_door(0)
	if data and data.door_count >= 2:
		close_door(1)


func toggle_all_doors() -> void:
	var any_closed: bool = not door_0_open or (data and data.door_count >= 2 and not door_1_open)
	if any_closed:
		open_all_doors()
	else:
		close_all_doors()


func _play_open_door(door_index: int) -> void:
	if visual == null or visual.sprite_frames == null:
		return

	if door_index == 0:
		_door_0_timer = 0.0
		_door_0_state = DoorState.OPENING
		var anim: StringName = &"door_open" if data.door_count == 1 else &"door_left_open"
		if visual.sprite_frames.has_animation(anim):
			visual.play(anim)
		elif visual.sprite_frames.has_animation(&"door_left_opened"):
			visual.play(&"door_left_opened")
		door_opened.emit(0)

	elif door_index == 1 and data.door_count >= 2:
		_door_1_timer = 0.0
		_door_1_state = DoorState.OPENING
		var anim: StringName = &"door_right_open"
		if visual.sprite_frames.has_animation(anim):
			visual.play(anim)
		elif visual.sprite_frames.has_animation(&"door_right_opened"):
			visual.play(&"door_right_opened")
		door_opened.emit(1)


func _play_close_door(door_index: int) -> void:
	if visual == null or visual.sprite_frames == null:
		return

	if door_index == 0:
		_door_0_state = DoorState.CLOSING
		var anim: StringName = &"door_close" if data.door_count == 1 else &"door_left_close"
		if visual.sprite_frames.has_animation(anim):
			visual.play(anim)
		elif visual.sprite_frames.has_animation(&"door_left_closed"):
			visual.play(&"door_left_closed")
		elif visual.sprite_frames.has_animation(&"door_closed"):
			visual.play(&"door_closed")
		door_closed.emit(0)

	elif door_index == 1 and data.door_count >= 2:
		_door_1_state = DoorState.CLOSING
		var anim: StringName = &"door_right_close"
		if visual.sprite_frames.has_animation(anim):
			visual.play(anim)
		elif visual.sprite_frames.has_animation(&"door_right_closed"):
			visual.play(&"door_right_closed")
		door_closed.emit(1)


func _set_door_state_immediate(door_index: int, is_open: bool) -> void:
	if visual == null or visual.sprite_frames == null or data == null:
		return

	if data.door_count == 1:
		var target_anim: StringName = &"door_opened" if is_open else &"door_closed"
		if visual.sprite_frames.has_animation(target_anim):
			visual.play(target_anim)
	else:
		if door_index == 0:
			var target_anim: StringName = &"door_left_opened" if is_open else &"door_left_closed"
			if visual.sprite_frames.has_animation(target_anim):
				visual.play(target_anim)
		elif door_index == 1:
			var target_anim: StringName = &"door_right_opened" if is_open else &"door_right_closed"
			if visual.sprite_frames.has_animation(target_anim):
				visual.play(target_anim)


func _on_visual_animation_finished() -> void:
	if visual == null or data == null:
		return

	var curr: StringName = visual.animation

	# Kết thúc mở cửa
	if curr == &"door_open":
		_door_0_state = DoorState.OPENED
		if visual.sprite_frames.has_animation(&"door_opened"):
			visual.play(&"door_opened")
	elif curr == &"door_left_open":
		_door_0_state = DoorState.OPENED
		if visual.sprite_frames.has_animation(&"door_left_opened"):
			visual.play(&"door_left_opened")
	elif curr == &"door_right_open":
		_door_1_state = DoorState.OPENED
		if visual.sprite_frames.has_animation(&"door_right_opened"):
			visual.play(&"door_right_opened")

	# Kết thúc đóng cửa
	elif curr == &"door_close":
		_door_0_state = DoorState.CLOSED
		if visual.sprite_frames.has_animation(&"door_closed"):
			visual.play(&"door_closed")
	elif curr == &"door_left_close":
		_door_0_state = DoorState.CLOSED
		if visual.sprite_frames.has_animation(&"door_left_closed"):
			visual.play(&"door_left_closed")
	elif curr == &"door_right_close":
		_door_1_state = DoorState.CLOSED
		if visual.sprite_frames.has_animation(&"door_right_closed"):
			visual.play(&"door_right_closed")


# ==============================================================================
# TƯƠNG TÁC (INTERACTION AREA & CLICK)
# ==============================================================================

func _setup_interaction_areas() -> void:
	if door_0_area:
		if not door_0_area.input_event.is_connected(_on_door_0_input):
			door_0_area.input_event.connect(_on_door_0_input)
		if not door_0_area.body_entered.is_connected(_on_door_0_body_entered):
			door_0_area.body_entered.connect(_on_door_0_body_entered)

	if door_1_area:
		if not door_1_area.input_event.is_connected(_on_door_1_input):
			door_1_area.input_event.connect(_on_door_1_input)
		if not door_1_area.body_entered.is_connected(_on_door_1_body_entered):
			door_1_area.body_entered.connect(_on_door_1_body_entered)


func _on_door_0_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_door(0)
		interacted.emit(0, null)


func _on_door_1_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_door(1)
		interacted.emit(1, null)


func _on_door_0_body_entered(body: Node) -> void:
	if body != self:
		open_door(0)
		interacted.emit(0, body)


func _on_door_1_body_entered(body: Node) -> void:
	if body != self and data and data.door_count >= 2:
		open_door(1)
		interacted.emit(1, body)
