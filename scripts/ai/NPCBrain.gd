class_name NPCBrain
extends Node

const NPCTaskData = preload("res://scripts/ai/tasks/NPCTaskData.gd")
const NPCRoutineData = preload("res://scripts/ai/tasks/NPCRoutineData.gd")
const NPCSteering = preload("res://scripts/ai/NPCSteering.gd")
const LocationResolver = preload("res://scripts/ai/LocationResolver.gd")

## Bộ Não AI Thông Minh Cho NPC (Smart NPC AI Brain).
## Điều khiển:
## 1. Lộ trình nhiệm vụ hàng ngày (Data-Driven Routine & Tasks).
## 2. Di chuyển tự nhiên, tăng giảm tốc mượt mà và né tránh vật cản (NPCSteering).
## 3. Hành vi vi mô tự nhiên khi đứng yên (Micro idle turns, nhìn quanh, biểu cảm).
## 4. Tự giải quyết tọa độ điểm mốc (LocationResolver POIs) và phát sinh sự kiện.

signal task_started(task: NPCTaskData)
signal task_completed(task: NPCTaskData)
signal routine_completed(routine: NPCRoutineData)
signal ai_state_changed(old_state: int, new_state: int)

enum AIState {
	IDLE,           ## Đứng nghỉ ngơi, nhìn quanh
	SMART_WANDER,   ## Tự do tản bộ với cơ chế né vật cản
	TASK_MOVING,    ## Đang di chuyển tới vị trí làm nhiệm vụ
	TASK_ACTION,    ## Đang thực hiện hành động tại nhiệm vụ (chờ, ăn, tương tác, phát biểu cảm)
	TALKING,        ## Đang đối thoại với người chơi
	PAUSED          ## Tạm dừng
}

@export_category("Routine & AI Data")
@export var routine: NPCRoutineData
@export var auto_start_routine: bool = true
@export var smart_avoidance_enabled: bool = true

@export_category("Movement Tuning")
@export var acceleration: float = 260.0
@export var arrival_radius: float = 28.0
@export var wander_radius: float = 120.0

var npc: CharacterBody2D = null
var current_ai_state: AIState = AIState.IDLE
var current_task_index: int = 0
var current_task: NPCTaskData = null
var task_action_timer: float = 0.0

# Biến hỗ trợ di chuyển tự nhiên & chống kẹt
var move_target: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _stuck_duration: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO
var _is_stuck: bool = false
var _idle_timer: float = 0.0
var _idle_look_timer: float = 0.0
var _current_idle_wait: float = 2.5
var _completed_loops: int = 0


func _ready() -> void:
	npc = get_parent() as CharacterBody2D
	if npc == null:
		push_error("NPCBrain phải là node con của một CharacterBody2D!")
		return

	_last_pos = npc.global_position
	_current_idle_wait = randf_range(1.5, 3.5)

	if auto_start_routine and routine != null:
		start_routine(routine)
	else:
		# Mặc định bắt đầu ở trạng thái tản bộ thông minh
		current_ai_state = AIState.IDLE


func _physics_process(delta: float) -> void:
	if npc == null or current_ai_state == AIState.PAUSED:
		return

	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.SMART_WANDER:
			_process_wander(delta)
		AIState.TASK_MOVING:
			_process_task_moving(delta)
		AIState.TASK_ACTION:
			_process_task_action(delta)
		AIState.TALKING:
			_process_talking(delta)


# ==============================================================================
# HỆ THỐNG XỬ LÝ NHIỆM VỤ & LỘ TRÌNH (ROUTINE & TASK EXECUTION)
# ==============================================================================

func start_routine(new_routine: NPCRoutineData) -> void:
	routine = new_routine
	current_task_index = 0
	_completed_loops = 0
	if routine != null and routine.get_task_count() > 0:
		_execute_current_task()
	else:
		current_ai_state = AIState.IDLE


func _execute_current_task() -> void:
	if routine == null or current_task_index >= routine.get_task_count():
		_on_routine_finished()
		return

	current_task = routine.get_task(current_task_index)
	if current_task == null:
		_advance_next_task()
		return

	task_started.emit(current_task)

	match current_task.type:
		NPCTaskData.TaskType.GOTO_LOCATION:
			move_target = current_task.target_pos
			current_ai_state = AIState.TASK_MOVING

		NPCTaskData.TaskType.GOTO_POI:
			move_target = LocationResolver.resolve_poi_position(
				get_tree(),
				current_task.poi_tag,
				npc.global_position
			)
			current_ai_state = AIState.TASK_MOVING

		NPCTaskData.TaskType.WAIT, NPCTaskData.TaskType.PLAY_EMOTE, NPCTaskData.TaskType.SPEAK, NPCTaskData.TaskType.INTERACT_OBJECT:
			_start_task_action()

		NPCTaskData.TaskType.WANDER_AREA:
			wander_radius = current_task.wander_radius
			task_action_timer = current_task.duration
			current_ai_state = AIState.SMART_WANDER


func _start_task_action() -> void:
	current_ai_state = AIState.TASK_ACTION
	task_action_timer = current_task.duration if current_task else 2.5
	npc.velocity = Vector2.ZERO

	# Kích hoạt Emote tương ứng từ EmoteRegistry
	if current_task and not current_task.emote_id.is_empty():
		_play_emote(current_task.emote_id)

	# Phát câu thoại
	if current_task and not current_task.dialogue_text.is_empty():
		if npc.has_signal("dialogue_spoken"):
			npc.dialogue_spoken.emit(current_task.dialogue_text)
		if npc.has_method("show_dialogue_bubble"):
			npc.show_dialogue_bubble(current_task.dialogue_text, task_action_timer)


func _advance_next_task() -> void:
	if current_task:
		task_completed.emit(current_task)

	current_task_index += 1
	if routine != null and current_task_index >= routine.get_task_count():
		_on_routine_finished()
	else:
		_execute_current_task()


func _on_routine_finished() -> void:
	routine_completed.emit(routine)
	_completed_loops += 1

	if routine != null and (routine.loop_infinitely or (routine.max_loops > 0 and _completed_loops < routine.max_loops)):
		# Lặp lại lộ trình từ đầu sau 2 giây nghỉ ngơi
		current_task_index = 0
		current_ai_state = AIState.IDLE
		_current_idle_wait = 2.0
		_idle_timer = 0.0
	else:
		current_ai_state = AIState.SMART_WANDER


# ==============================================================================
# QUY TRÌNH DI CHUYỂN & HÀNH VI TỰ NHIÊN (NATURAL MOVEMENT & BEHAVIORS)
# ==============================================================================

func _process_idle(delta: float) -> void:
	npc.velocity = npc.velocity.move_toward(Vector2.ZERO, acceleration * 2.0 * delta)
	npc.move_and_slide()
	_update_npc_animation(false, npc.get("facing_direction") if "facing_direction" in npc else Vector2.DOWN)

	# Nhìn quanh ngẫu nhiên khi đứng nghỉ
	_idle_look_timer += delta
	if _idle_look_timer >= 1.8:
		_idle_look_timer = 0.0
		_pick_random_glance_direction()

	_idle_timer += delta
	if _idle_timer >= _current_idle_wait:
		_idle_timer = 0.0
		_current_idle_wait = randf_range(1.5, 4.0)

		if routine != null and current_task != null:
			_execute_current_task()
		else:
			_pick_random_wander_point()
			current_ai_state = AIState.SMART_WANDER


func _process_wander(delta: float) -> void:
	_check_stuck(delta)

	var speed: float = npc.data.move_speed if npc.get("data") and npc.data.get("move_speed") else 55.0
	var new_vel: Vector2 = NPCSteering.compute_natural_velocity(
		npc,
		move_target,
		npc.velocity,
		speed,
		acceleration,
		arrival_radius,
		delta,
		_is_stuck
	)

	npc.velocity = new_vel
	npc.move_and_slide()

	if new_vel.length_squared() > 4.0:
		_update_npc_facing(new_vel)
		_update_npc_animation(true, new_vel)

	var dist: float = npc.global_position.distance_to(move_target)
	if dist <= 12.0 or (_is_stuck and dist <= 24.0):
		_is_stuck = false
		current_ai_state = AIState.IDLE
		_current_idle_wait = randf_range(1.5, 3.5)
		_idle_timer = 0.0


func _process_task_moving(delta: float) -> void:
	_check_stuck(delta)

	var speed_mult: float = current_task.speed_multiplier if current_task else 1.0
	var base_speed: float = npc.data.move_speed if npc.get("data") and npc.data.get("move_speed") else 60.0
	var max_speed: float = base_speed * speed_mult
	var target_dist_stop: float = current_task.arrival_distance if current_task else 18.0

	var new_vel: Vector2 = NPCSteering.compute_natural_velocity(
		npc,
		move_target,
		npc.velocity,
		max_speed,
		acceleration,
		arrival_radius,
		delta,
		_is_stuck
	)

	npc.velocity = new_vel
	npc.move_and_slide()

	if new_vel.length_squared() > 4.0:
		_update_npc_facing(new_vel)
		_update_npc_animation(true, new_vel)

	# Kiểm tra đến đích
	var dist: float = npc.global_position.distance_to(move_target)
	if dist <= target_dist_stop:
		_is_stuck = false
		npc.velocity = Vector2.ZERO
		_start_task_action()


func _process_task_action(delta: float) -> void:
	npc.velocity = npc.velocity.move_toward(Vector2.ZERO, acceleration * delta)
	npc.move_and_slide()
	_update_npc_animation(false, npc.get("facing_direction") if "facing_direction" in npc else Vector2.DOWN)

	task_action_timer -= delta
	if task_action_timer <= 0.0:
		_advance_next_task()


func _process_talking(delta: float) -> void:
	npc.velocity = Vector2.ZERO
	npc.move_and_slide()
	_update_npc_animation(false, npc.get("facing_direction") if "facing_direction" in npc else Vector2.DOWN)


# ==============================================================================
# HỖ TRỢ VẬT LÝ, QUAN SÁT & HOẠT HỌA (UTILITY METHODS)
# ==============================================================================

func _check_stuck(delta: float) -> void:
	_stuck_timer += delta
	if _stuck_timer >= 0.4:
		var moved_dist: float = npc.global_position.distance_to(_last_pos)
		var currently_blocked = (npc.velocity.length() > 15.0 and moved_dist < 4.0)
		_last_pos = npc.global_position
		_stuck_timer = 0.0

		if currently_blocked:
			_is_stuck = true
			_stuck_duration += 0.4
			# Nếu bị kẹt quá 1.0 giây, tự động giải cứu thông minh
			if _stuck_duration >= 1.0:
				_stuck_duration = 0.0
				_is_stuck = false
				if current_ai_state == AIState.SMART_WANDER:
					# Chọn ngay điểm dạo mới ở vùng thoáng
					_pick_random_wander_point()
				elif current_ai_state == AIState.TASK_MOVING:
					var dist: float = npc.global_position.distance_to(move_target)
					if dist < arrival_radius * 1.8:
						# Đã rất gần mục tiêu, cho phép tiếp tục hành động
						npc.velocity = Vector2.ZERO
						_start_task_action()
					else:
						# Nới rộng mục tiêu tránh điểm kẹt
						move_target += Vector2(randf_range(-35.0, 35.0), randf_range(-35.0, 35.0))
		else:
			_is_stuck = false
			_stuck_duration = max(0.0, _stuck_duration - 0.4)


func _pick_random_wander_point() -> void:
	var spawn_pos: Vector2 = npc.get("spawn_position") if "spawn_position" in npc else npc.global_position
	var angle: float = randf_range(0.0, TAU)
	var r: float = randf_range(25.0, wander_radius)
	move_target = spawn_pos + Vector2(cos(angle), sin(angle)) * r


func _pick_random_glance_direction() -> void:
	var directions: Array[String] = ["front_right", "front_left", "back_right", "back_left"]
	var chosen: String = directions.pick_random()
	if npc.has_method("set_direction_by_name"):
		npc.set_direction_by_name(chosen)


func _update_npc_facing(dir: Vector2) -> void:
	if npc.has_method("set_facing_direction"):
		npc.set_facing_direction(dir)


func _update_npc_animation(is_moving: bool, dir: Vector2) -> void:
	if npc.has_method("_update_animation_state"):
		npc._update_animation_state(is_moving, dir)


func _play_emote(emote_id: StringName) -> void:
	if npc.has_method("show_emote"):
		npc.show_emote(emote_id)
	elif has_node("/root/EmoteRegistry"):
		get_node("/root/EmoteRegistry").spawn_emote(npc, emote_id)
