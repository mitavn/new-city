@tool
extends NPCBase

## Bộ điều khiển Người chơi cho NPC (Player NPC Controller)
## Dùng trong màn Test Scene: Cho phép người chơi trực tiếp điều khiển NPC (WASD / Mũi tên)
## Hỗ trợ:
## - Di chuyển 8 hướng theo chuẩn isometric / 2.5D của game
## - Tăng tốc chạy khi giữ phím Shift
## - Hệ thống va chạm đầy đủ (không đi xuyên tường, nhà, xe cộ, nước)
## - Phím E / Phím Space: Tương tác với NPC, còi/đèn xe cộ, đóng mở cửa tòa nhà xung quanh
## - Phát tín hiệu hiển thị thông báo / hội thoại lên HUD

signal player_interacted_target(target_name: String, message: String)
signal player_position_updated(pos: Vector2, vel: Vector2)
signal player_board_vehicle_requested(vehicle_node: Node)

@export_category("Player Controls")
@export var move_speed: float = 120.0
@export var sprint_speed: float = 180.0
@export var enable_player_input: bool = true
@export var interaction_range: float = 80.0

var _is_interacting: bool = false
var _interaction_cooldown: float = 0.0


func _ready() -> void:
	auto_wander = false
	use_smart_ai = false
	super._ready()
	current_state = State.IDLE

	if not Engine.is_editor_hint():
		var MotionTrailClass = preload("res://scripts/effects/MotionTrail2D.gd")
		if MotionTrailClass and not has_node("MotionTrail2D"):
			var trail = MotionTrailClass.new()
			trail.name = "MotionTrail2D"
			trail.min_speed_threshold = 140.0
			trail.trail_color = Color(0.4, 0.85, 1.0, 0.6)
			add_child(trail)


@export_category("Movement Dynamics")
@export var acceleration: float = 850.0
@export var friction: float = 950.0

var _step_timer: float = 0.0
var _city_audio_cache: Node = null


func _get_city_audio() -> Node:
	if _city_audio_cache and is_instance_valid(_city_audio_cache):
		return _city_audio_cache
	var tree = get_tree()
	if tree:
		var audio_node = tree.current_scene.get_node_or_null("CityAudioManager")
		if audio_node:
			_city_audio_cache = audio_node
			return _city_audio_cache
	return null


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _interaction_cooldown > 0.0:
		_interaction_cooldown -= delta

	if not enable_player_input:
		return

	# Xử lý input di chuyển 8 hướng mượt mà
	var input_vec: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vec.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vec.x += 1.0

	var is_sprint: bool = Input.is_key_pressed(KEY_SHIFT)
	var max_speed: float = sprint_speed if is_sprint else move_speed

	if input_vec.length_squared() > 0.001:
		input_vec = input_vec.normalized()
		facing_direction = input_vec
		_facing_direction_name = get_direction_suffix(facing_direction)

		# Tăng tốc tự nhiên (Smooth Acceleration)
		var target_vel = input_vec * max_speed
		velocity = velocity.move_toward(target_vel, acceleration * delta)
		current_state = State.WANDER
		_update_animation_state(true, facing_direction)

		# Nhịp bước chân tự nhiên theo tốc độ đi bộ / chạy bộ
		_step_timer -= delta
		var step_interval = 0.26 if is_sprint else 0.38
		if _step_timer <= 0.0:
			_step_timer = step_interval
			var audio = _get_city_audio()
			if audio and audio.has_method("play_footstep"):
				audio.play_footstep(is_sprint, "asphalt")
	else:
		# Giảm tốc tự nhiên theo quán tính (Smooth Friction)
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if velocity.length_squared() < 4.0:
			velocity = Vector2.ZERO
			current_state = State.IDLE
			_update_animation_state(false, facing_direction)
		else:
			_update_animation_state(true, facing_direction)

	move_and_slide()
	player_position_updated.emit(global_position, velocity)


func _unhandled_input(event: InputEvent) -> void:
	if not enable_player_input:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			execute_interaction()
			get_viewport().set_input_as_handled()


## Kích hoạt hành động tương tác với thực thể gần nhất
func execute_interaction() -> void:
	if _interaction_cooldown > 0.0:
		return
	_interaction_cooldown = 0.4

	var tree: SceneTree = get_tree()
	if tree == null:
		return

	var best_target: Node = null
	var min_dist: float = interaction_range
	var target_type: String = ""

	# 1. Tìm NPC gần nhất
	for npc in tree.get_nodes_in_group(&"npcs"):
		if npc == self or not is_instance_valid(npc):
			continue
		var dist = global_position.distance_to(npc.global_position)
		if dist < min_dist:
			min_dist = dist
			best_target = npc
			target_type = "npc"

	# 2. Tìm Xe cộ gần nhất
	for veh in tree.get_nodes_in_group(&"vehicles"):
		if not is_instance_valid(veh):
			continue
		var dist = global_position.distance_to(veh.global_position)
		if dist < min_dist:
			min_dist = dist
			best_target = veh
			target_type = "vehicle"

	# 3. Tìm Tòa nhà gần nhất (cho phép khoảng cách rộng hơn vì nhà to)
	for bld in tree.get_nodes_in_group(&"buildings"):
		if not is_instance_valid(bld):
			continue
		var dist = global_position.distance_to(bld.global_position)
		if dist < (min_dist + 40.0):
			min_dist = dist
			best_target = bld
			target_type = "building"

	# Thực thi tương tác & Hiển thị Emote biểu cảm
	var EmoteBubbleClass = load("res://scenes/test/emote_bubble.gd")
	if best_target != null:
		match target_type:
			"npc":
				if best_target.has_method("interact"):
					best_target.interact(self)
				var line = best_target.get_dialogue_line() if best_target.has_method("get_dialogue_line") else "..."
				var name_str = best_target.data.display_name if best_target.get("data") and best_target.data.get("display_name") else "NPC"
				player_interacted_target.emit(name_str, line)
				if EmoteBubbleClass:
					EmoteBubbleClass.spawn_emote(best_target, "happy", -38.0)
					EmoteBubbleClass.spawn_emote(self, "speech_dots", -38.0)

			"vehicle":
				var veh_name = best_target.data.display_name if best_target.get("data") and best_target.data.get("display_name") else "Phương tiện"
				if "siren_active" in best_target:
					best_target.siren_active = not best_target.siren_active
					var status = "BẬT" if best_target.siren_active else "TẮT"
					player_interacted_target.emit(veh_name, "Đã %s còi/đèn ưu tiên của %s!" % [status, veh_name])
					if EmoteBubbleClass:
						EmoteBubbleClass.spawn_emote(best_target, "exclamation", -34.0)
				elif best_target.has_method("interact"):
					best_target.interact(self)
					player_interacted_target.emit(veh_name, "Đang kiểm tra tình trạng phương tiện %s." % veh_name)
					if EmoteBubbleClass:
						EmoteBubbleClass.spawn_emote(best_target, "question", -34.0)
				else:
					player_interacted_target.emit(veh_name, "Phương tiện neo đậu an toàn tại bến cảng.")
					if EmoteBubbleClass:
						EmoteBubbleClass.spawn_emote(best_target, "check", -34.0)

			"building":
				var bld_name = best_target.data.display_name if best_target.get("data") and best_target.data.get("display_name") else "Tòa nhà"
				if best_target.has_method("toggle_all_doors"):
					best_target.toggle_all_doors()
					var is_open = best_target.get("door_0_open")
					var door_str = "MỞ" if is_open else "ĐÓNG"
					player_interacted_target.emit(bld_name, "Đã %s cửa chính tòa nhà %s!" % [door_str, bld_name])
					if EmoteBubbleClass:
						EmoteBubbleClass.spawn_emote(best_target, "check", -50.0)
				else:
					player_interacted_target.emit(bld_name, "Cửa tòa nhà %s đang khóa kiểm soát hải quan." % bld_name)
					if EmoteBubbleClass:
						EmoteBubbleClass.spawn_emote(best_target, "cross", -50.0)
	else:
		# Không có ai ở gần: Thông báo suy nghĩ tuần tra của Sĩ quan
		var self_name = data.display_name if data and data.get("display_name") else "Sĩ quan Cảnh sát Tuần tra"
		var patrol_thoughts: Array[String] = [
			"Bến tàu Thượng Hải hôm nay trời trong xanh, các chuyến tàu ra vào cảng ổn định.",
			"Khu vực phà Hoàng Phố đông đúc hành khách, trật tự an ninh tốt.",
			"Tàu buôn quốc tế đang bốc dỡ hàng tại cầu cảng phía Đông.",
			"Không phát hiện dấu hiệu vi phạm trật tự tại trạm kiểm soát bến cảng."
		]
		var thought_line = patrol_thoughts.pick_random()
		player_interacted_target.emit(self_name, thought_line)
		show_dialogue_bubble(thought_line, 3.5)
		show_emote(&"idea")
