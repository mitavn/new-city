@tool
class_name NPCBase
extends CharacterBody2D

const NPCBrain = preload("res://scripts/ai/NPCBrain.gd")
const NPCRoutineData = preload("res://scripts/ai/tasks/NPCRoutineData.gd")

## Các trạng thái hành vi của NPC
enum State {
	IDLE,
	WANDER,
	NAVIGATE,
	TALKING,
	DISABLED
}

## Signals phục vụ tính trừu tượng và tách biệt logic (Decoupling)
signal interacted(initiator: Node)
signal dialogue_spoken(line: String)
signal state_changed(old_state: State, new_state: State)
signal destination_reached

## Dữ liệu NPC (Data-driven Resource)
@export var data: NPCData:
	set(value):
		if data and data.changed.is_connected(_apply_data):
			data.changed.disconnect(_apply_data)
		data = value
		if data and not data.changed.is_connected(_apply_data):
			data.changed.connect(_apply_data)
		_apply_data()

@export_category("Behavior Settings")
@export var auto_wander: bool = true
@export var routine: NPCRoutineData = null
@export var use_smart_ai: bool = true

var brain: NPCBrain = null
var _facing_direction_name: String = "front_right"

## Hướng quay mặt mặc định / hiện tại (Hiển thị trong Inspector và Editor)
@export_enum("front_right", "front_left", "back_right", "back_left") var facing_direction_name: String:
	set(value):
		if _facing_direction_name == value:
			return
		_facing_direction_name = value
		set_direction_by_name(value)
	get:
		return _facing_direction_name


@export var current_state: State = State.IDLE:
	set(value):
		if current_state != value:
			var prev: State = current_state
			current_state = value
			_on_state_changed(prev, current_state)
			state_changed.emit(prev, current_state)

## Node references
@onready var visual: AnimatedSprite2D = $Visual
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var interaction_area: Area2D = $InteractionArea
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

## Internal State Variables
var spawn_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2(1, 1).normalized()
var idle_timer: float = 0.0
var current_idle_duration: float = 2.0
var _wander_stuck_timer: float = 0.0
var _wander_last_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	spawn_position = global_position
	target_position = global_position
	_setup_interaction()
	_apply_data()
	
	if not Engine.is_editor_hint():
		if use_smart_ai:
			_setup_ai_brain()
		else:
			_reset_idle_timer()
			_setup_npc()


func _setup_ai_brain() -> void:
	brain = get_node_or_null("NPCBrain") as NPCBrain
	if brain == null:
		brain = NPCBrain.new()
		brain.name = "NPCBrain"
		add_child(brain)

	# Lấy routine từ export hoặc từ NPCData
	var active_routine: NPCRoutineData = routine
	if active_routine == null and data != null and data.get("default_routine") != null:
		active_routine = data.default_routine

	if active_routine != null:
		brain.start_routine(active_routine)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_on_behavior_tick(delta)

	if use_smart_ai and brain != null:
		# NPCBrain xử lý di chuyển thông minh, nhiệm vụ và né tránh vật cản
		return

	match current_state:
		State.IDLE:
			_process_idle_state(delta)
		State.WANDER:
			_process_wander_state(delta)
		State.NAVIGATE:
			_process_navigate_state(delta)
		State.TALKING:
			velocity = Vector2.ZERO
			move_and_slide()
			_update_animation_state(false, facing_direction)
		State.DISABLED:
			velocity = Vector2.ZERO


## Cập nhật dữ liệu từ Resource vào NPC
func _apply_data() -> void:
	if not is_node_ready() or visual == null or data == null:
		return

	visual.sprite_frames = data.sprite_frames

	if visual.sprite_frames:
		set_direction_by_name(facing_direction_name)


# ==============================================================================
# HƯỚNG ĐỐI TƯỢNG: CÁC PHƯƠNG THỨC ẢO (VIRTUAL / HOOK METHODS) CHO LỚP CON GHI ĐÈ
# ==============================================================================

## Hook khởi tạo riêng của từng loại NPC (Overridable)
func _setup_npc() -> void:
	pass


## Hook xử lý mỗi tick vật lý dành cho lớp con (Overridable)
func _on_behavior_tick(_delta: float) -> void:
	pass


## Hook khi chuyển đổi trạng thái (Overridable)
func _on_state_changed(_old_state: State, _new_state: State) -> void:
	pass


## Polymorphic method: Kích hoạt tương tác với NPC
func interact(initiator: Node = null) -> void:
	interacted.emit(initiator)
	_on_interact(initiator)


## Hook xử lý tương tác riêng của từng loại NPC (Overridable)
func _on_interact(initiator: Node) -> void:
	if initiator is Node2D:
		# Quay mặt về phía người tương tác
		var dir_to_initiator: Vector2 = initiator.global_position - global_position
		if dir_to_initiator.length_squared() > 0.01:
			set_facing_direction(dir_to_initiator)
	else:
		# Khi click chuột vào NPC, quay mặt về phía con trỏ chuột
		var mouse_pos: Vector2 = get_global_mouse_position()
		var dir_to_mouse: Vector2 = mouse_pos - global_position
		if dir_to_mouse.length_squared() > 0.01:
			set_facing_direction(dir_to_mouse)

	if brain != null:
		brain.current_ai_state = NPCBrain.AIState.TALKING

	current_state = State.TALKING
	var line: String = get_dialogue_line()
	dialogue_spoken.emit(line)
	show_dialogue_bubble(line, 3.5)
	
	# Mặc định kết thúc tương tác sau một khoảng thời gian hoặc theo cơ chế game
	var tree: SceneTree = get_tree()
	if tree:
		await tree.create_timer(3.5).timeout
		if current_state == State.TALKING:
			current_state = State.IDLE
			if brain != null:
				brain.current_ai_state = NPCBrain.AIState.IDLE
			_reset_idle_timer()


## Polymorphic method: Lấy câu thoại từ NPC
func get_dialogue_line() -> String:
	return _get_dialogue()


## Hook lấy câu thoại (Overridable)
func _get_dialogue() -> String:
	if data:
		return data.get_random_dialogue()
	return "..."


## Hiển thị bong bóng thoại Typewriter trên đầu NPC
func show_dialogue_bubble(text: String, duration: float = 3.5) -> Node2D:
	var DialogueBubbleClass = preload("res://scripts/ui/DialogueBubble.gd")
	if DialogueBubbleClass:
		return DialogueBubbleClass.speak_above(self, text, duration)
	return null


## Hiển thị biểu cảm NPCEmote trên đầu NPC kèm âm thanh
func show_emote(emote_id: StringName, duration: float = 2.2) -> Node2D:
	var NPCEmoteClass = preload("res://scripts/emotes/NPCEmote.gd")
	if NPCEmoteClass:
		return NPCEmoteClass.show_on(self, emote_id, duration)
	return null


# ==============================================================================
# HỆ THỐNG HOẠT HỌA & ĐIỀU HƯỚNG 2.5D / ISOMETRIC
# ==============================================================================

## Chuyển đổi vector hướng 2D thành tên hướng 2.5D:
## front_left, front_right, back_left, back_right
func get_direction_suffix(dir: Vector2) -> String:
	if dir == Vector2.ZERO:
		dir = facing_direction

	# Trục Y hướng xuống: dir.y >= 0 là hướng trước (front), dir.y < 0 là hướng sau (back)
	# Trục X: dir.x >= 0 là bên phải (right), dir.x < 0 là bên trái (left)
	if dir.y >= 0.0:
		return "front_right" if dir.x >= 0.0 else "front_left"
	else:
		return "back_right" if dir.x >= 0.0 else "back_left"


## Cập nhật animation dựa vào trạng thái di chuyển và hướng
func _update_animation_state(is_moving: bool, dir: Vector2) -> void:
	if visual == null or visual.sprite_frames == null:
		return

	var suffix: String = get_direction_suffix(dir)
	var prefix: String = "walk_" if is_moving else "idle_"
	var anim_name: String = prefix + suffix

	if visual.sprite_frames.has_animation(anim_name):
		if visual.animation != anim_name or not visual.is_playing():
			visual.play(anim_name)
	elif visual.sprite_frames.has_animation("idle_front_right"):
		if visual.animation != "idle_front_right" or not visual.is_playing():
			visual.play("idle_front_right")


## Đặt hướng quay mặt của NPC bằng tên chuỗi ("front_right", "front_left", "back_right", "back_left")
func set_direction_by_name(dir_name: String) -> void:
	match dir_name:
		"front_right":
			facing_direction = Vector2(1, 1).normalized()
		"front_left":
			facing_direction = Vector2(-1, 1).normalized()
		"back_right":
			facing_direction = Vector2(1, -1).normalized()
		"back_left":
			facing_direction = Vector2(-1, -1).normalized()
	_facing_direction_name = dir_name
	_update_animation_state(velocity.length_squared() > 1.0, facing_direction)


## Đặt hướng quay mặt của NPC bằng Vector2
func set_facing_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.001:
		facing_direction = dir.normalized()
		_facing_direction_name = get_direction_suffix(facing_direction)
		_update_animation_state(velocity.length_squared() > 1.0, facing_direction)




# ==============================================================================
# AI ĐI TUẦN & DI CHUYỂN TỰ ĐỘNG (WANDER AI)
# ==============================================================================

func _reset_idle_timer() -> void:
	var min_t: float = data.min_idle_time if data else 1.5
	var max_t: float = data.max_idle_time if data else 4.0
	current_idle_duration = randf_range(min_t, max_t)
	idle_timer = 0.0


func _process_idle_state(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_update_animation_state(false, facing_direction)

	if not auto_wander or data == null:
		return

	idle_timer += delta
	if idle_timer >= current_idle_duration:
		_pick_random_wander_target()


func _pick_random_wander_target() -> void:
	var radius: float = data.wander_radius if data else 120.0
	var random_offset: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	random_offset *= randf_range(20.0, radius)
	target_position = spawn_position + random_offset
	
	if navigation_agent:
		navigation_agent.target_position = target_position

	current_state = State.WANDER


func _process_wander_state(delta: float) -> void:
	var to_target: Vector2 = target_position - global_position
	var dist: float = to_target.length()

	if dist <= 10.0:
		velocity = Vector2.ZERO
		move_and_slide()
		current_state = State.IDLE
		_reset_idle_timer()
		_wander_stuck_timer = 0.0
		destination_reached.emit()
		return

	var move_dir: Vector2 = to_target.normalized()
	var speed: float = data.move_speed if data else 60.0
	var desired_vel: Vector2 = move_dir * speed

	# Phản xạ trượt né va chạm khi chạm tường hoặc NPC khác
	var col_count: int = get_slide_collision_count()
	if col_count > 0:
		for i in range(col_count):
			var col = get_slide_collision(i)
			var normal: Vector2 = col.get_normal()
			var collider = col.get_collider()
			if collider is CharacterBody2D:
				var push = (global_position - collider.global_position).normalized()
				if push.length_squared() < 0.01:
					push = normal
				desired_vel += push * 40.0
			else:
				var tangent = Vector2(-normal.y, normal.x)
				if tangent.dot(move_dir) < 0.0:
					tangent = -tangent
				desired_vel = (desired_vel * 0.4 + tangent * speed * 0.7).normalized() * speed

	# Chống kẹt nếu dẫm chân tại chỗ > 1.0 giây
	_wander_stuck_timer += delta
	if _wander_stuck_timer >= 0.4:
		var moved_dist = global_position.distance_to(_wander_last_pos)
		_wander_last_pos = global_position
		if moved_dist < 3.0:
			# Kẹt: ngay lập tức hủy mục tiêu và đứng nghỉ ngơi
			current_state = State.IDLE
			_reset_idle_timer()
			_wander_stuck_timer = 0.0
			return
		_wander_stuck_timer = 0.0

	velocity = velocity.move_toward(desired_vel, 350.0 * delta)
	facing_direction = velocity.normalized() if velocity.length_squared() > 1.0 else move_dir
	move_and_slide()
	_update_animation_state(true, facing_direction)


func _process_navigate_state(_delta: float) -> void:
	if navigation_agent == null or navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		current_state = State.IDLE
		_reset_idle_timer()
		destination_reached.emit()
		return

	var next_path_pos: Vector2 = navigation_agent.get_next_path_position()
	var move_dir: Vector2 = (next_path_pos - global_position).normalized()
	if move_dir.length_squared() > 0.001:
		facing_direction = move_dir

	var speed: float = data.move_speed if data else 60.0
	velocity = move_dir * speed
	move_and_slide()
	_update_animation_state(true, facing_direction)


func _setup_interaction() -> void:
	if interaction_area:
		if not interaction_area.input_event.is_connected(_on_interaction_area_input):
			interaction_area.input_event.connect(_on_interaction_area_input)


func _on_interaction_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interact(null)
