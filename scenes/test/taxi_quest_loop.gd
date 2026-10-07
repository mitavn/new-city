extends Node

## Controller Thử Nghiệm: Vòng Lặp NPC Gọi Taxi Ngẫu Nhiên và Di Chuyển (Taxi Quest Loop)
## Minh họa cơ chế Data-Driven Quest kết hợp Emote và Hành vi Xe cộ / NPC:
## 1. Một NPC ngẫu nhiên bên đường kích hoạt nhu cầu gọi taxi
## 2. NPC phát Emote "Chấm than / Vẫy xe" (exclamation) & gửi tín hiệu gọi taxi
## 3. Taxi nhận cuốc, phát Emote "Ý tưởng" (idea), nổ máy chuyển sang trạng thái DRIVING
## 4. Taxi di chuyển tới đón NPC, dừng lại chuyển sang PARKED
## 5. NPC bước lên taxi (ẩn vào trong), phát Emote "Vui vẻ" (happy)
## 6. Taxi chở khách di chuyển dọc tuyến đường tới điểm trả khách ngẫu nhiên
## 7. Khách xuống xe, phát Emote "Tiền thưởng / Xuất sắc" (star), cảm ơn bác tài
## 8. Taxi hoàn tất cuốc xe, tự động lặp lại chu kỳ tiếp theo hoặc kích hoạt bằng phím T

signal taxi_quest_event(title: String, message: String)

enum QuestStep {
	IDLE_WAITING,
	NPC_HAILING,
	TAXI_APPROACHING,
	PASSENGER_BOARDING,
	TAXI_TRAVELING,
	PASSENGER_DROPOFF,
	COOLDOWN
}

@export var taxi_node: CharacterBody2D
@export var entities_container: Node2D
@export var auto_loop: bool = true
@export var loop_interval: float = 6.0
@export var taxi_drive_speed: float = 130.0

var current_step: QuestStep = QuestStep.IDLE_WAITING
var _step_timer: float = 0.0
var _passenger: CharacterBody2D = null
var _passenger_orig_wander: bool = true
var _target_pos: Vector2 = Vector2.ZERO
var _current_dest_name: String = ""

# Các điểm đón / trả khách trên mạng lưới đường bến cảng
const DESTINATION_POINTS = [
	{"name": "Trạm Kiểm Soát Hải Quan", "pos": Vector2(370, 215)},
	{"name": "Ngân Hàng Trung Tâm The Bund", "pos": Vector2(200, 140)},
	{"name": "Cổng Bến Phà Hoàng Phố", "pos": Vector2(170, 240)},
	{"name": "Quán Mì & Điểm Tâm Bến Tàu", "pos": Vector2(610, 205)},
	{"name": "Kho Hàng Cảng Thượng Hải", "pos": Vector2(760, 215)},
	{"name": "Đồn Cảnh Sát Bến Cảng", "pos": Vector2(460, 140)}
]


func _ready() -> void:
	_step_timer = 3.0 # Chờ 3 giây trước cuốc đầu tiên


func _physics_process(delta: float) -> void:
	match current_step:
		QuestStep.IDLE_WAITING:
			if auto_loop:
				_step_timer -= delta
				if _step_timer <= 0.0:
					trigger_taxi_hail()

		QuestStep.TAXI_APPROACHING:
			_move_taxi_towards(_target_pos, delta, func():
				_on_taxi_arrived_pickup()
			)

		QuestStep.TAXI_TRAVELING:
			_move_taxi_towards(_target_pos, delta, func():
				_on_taxi_arrived_dropoff()
			)

		QuestStep.COOLDOWN:
			_step_timer -= delta
			if _step_timer <= 0.0:
				current_step = QuestStep.IDLE_WAITING
				_step_timer = loop_interval


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			trigger_taxi_hail()


## Bắt đầu một cuốc gọi taxi ngẫu nhiên
func trigger_taxi_hail() -> void:
	if current_step != QuestStep.IDLE_WAITING and current_step != QuestStep.COOLDOWN:
		return

	if taxi_node == null or entities_container == null:
		_find_references()

	if taxi_node == null or entities_container == null:
		return

	# Chọn một NPC ngẫu nhiên (không phải người chơi và không phải xe cộ)
	var available_npcs: Array[CharacterBody2D] = []
	for child in entities_container.get_children():
		if child is CharacterBody2D:
			var cname = child.name.to_lower()
			var is_player = child.is_in_group(&"player") or cname.begins_with("player")
			var is_veh = child.is_in_group(&"vehicles") or cname.contains("car") or cname.contains("taxi") or cname.contains("ship") or cname.contains("boat") or cname.contains("truck") or cname.contains("bulldozer")
			if not is_player and not is_veh and child.visible:
				available_npcs.append(child)

	if available_npcs.is_empty():
		return

	_passenger = available_npcs.pick_random()
	_passenger_orig_wander = _passenger.auto_wander if "auto_wander" in _passenger else true

	current_step = QuestStep.NPC_HAILING

	# NPC dừng lại vẫy xe
	if "auto_wander" in _passenger:
		_passenger.auto_wander = false
	if "velocity" in _passenger:
		_passenger.velocity = Vector2.ZERO
	var p_brain = _passenger.get_node_or_null("NPCBrain")
	if p_brain != null:
		p_brain.current_ai_state = p_brain.AIState.PAUSED

	# Quay mặt hướng về phía taxi
	var dir_to_taxi = (taxi_node.global_position - _passenger.global_position).normalized()
	if _passenger.has_method("set_facing_direction"):
		_passenger.set_facing_direction(dir_to_taxi)

	# Bật biểu cảm gọi xe bằng Data-Driven EmoteRegistry
	var passenger_name = _passenger.data.display_name if _passenger.get("data") and _passenger.data.get("display_name") else "Hành khách"
	_spawn_data_emote(_passenger, &"exclamation")

	taxi_quest_event.emit("🚕 KHÁCH VẪY TAXI", "%s: 'Bác tài ơi! Cho tôi đi một chuyến nhé!'" % passenger_name)

	# Taxi nhận tín hiệu sau 1.2 giây
	get_tree().create_timer(1.2).timeout.connect(func():
		if not is_instance_valid(taxi_node) or not is_instance_valid(_passenger):
			_reset_quest()
			return

		_spawn_data_emote(taxi_node, &"idea")
		taxi_quest_event.emit("🚕 TAXI NHẬN CUỐC", "Bác tài taxi: 'Có ngay! Đang tới đón quý khách!'")

		# Đặt điểm đón là vị trí lề đường gần NPC nhất
		_target_pos = Vector2(_passenger.global_position.x, 215.0)
		taxi_node.current_state = VehicleBase.VehicleState.DRIVING
		current_step = QuestStep.TAXI_APPROACHING
	)


func _move_taxi_towards(target: Vector2, delta: float, on_reached: Callable) -> void:
	if not is_instance_valid(taxi_node):
		return

	var dist = taxi_node.position.distance_to(target)
	if dist <= 10.0:
		taxi_node.position = target
		taxi_node.velocity = Vector2.ZERO
		on_reached.call()
		return

	var move_dir = (target - taxi_node.position).normalized()
	taxi_node.velocity = move_dir * taxi_drive_speed
	taxi_node.position += move_dir * taxi_drive_speed * delta

	if taxi_node.has_method("set_facing_direction"):
		taxi_node.set_facing_direction(move_dir)
	if taxi_node.has_method("_update_animation_state"):
		taxi_node._update_animation_state(true, move_dir)


func _on_taxi_arrived_pickup() -> void:
	if not is_instance_valid(_passenger) or not is_instance_valid(taxi_node):
		_reset_quest()
		return

	taxi_node.current_state = VehicleBase.VehicleState.PARKED
	taxi_node.velocity = Vector2.ZERO
	if taxi_node.has_method("_update_animation_state"):
		taxi_node._update_animation_state(false, taxi_node.facing_direction)

	current_step = QuestStep.PASSENGER_BOARDING

	# Chọn điểm đến ngẫu nhiên
	var dest_info = DESTINATION_POINTS.pick_random()
	_current_dest_name = dest_info["name"]
	_target_pos = dest_info["pos"]

	# Hành khách bước lên xe
	var passenger_name = _passenger.data.display_name if _passenger.get("data") and _passenger.data.get("display_name") else "Hành khách"
	_spawn_data_emote(_passenger, &"happy")
	_spawn_data_emote(taxi_node, &"check")

	taxi_quest_event.emit("🚖 LÊN XE TAXI", "%s: 'Bác tài chở tôi đến %s nhé!'" % [passenger_name, _current_dest_name])

	# Hiệu ứng hành khách bước vào trong xe
	var tween = create_tween()
	tween.tween_property(_passenger, "position", taxi_node.position, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(_passenger):
			_passenger.visible = false

		# Bắt đầu hành trình di chuyển
		get_tree().create_timer(0.6).timeout.connect(func():
			if not is_instance_valid(taxi_node):
				_reset_quest()
				return
			taxi_node.current_state = VehicleBase.VehicleState.DRIVING
			current_step = QuestStep.TAXI_TRAVELING
			taxi_quest_event.emit("🚕 ĐANG DI CHUYỂN", "Taxi đang đưa %s về %s..." % [passenger_name, _current_dest_name])
		)
	)


func _on_taxi_arrived_dropoff() -> void:
	if not is_instance_valid(taxi_node):
		_reset_quest()
		return

	taxi_node.current_state = VehicleBase.VehicleState.PARKED
	taxi_node.velocity = Vector2.ZERO
	if taxi_node.has_method("_update_animation_state"):
		taxi_node._update_animation_state(false, taxi_node.facing_direction)

	current_step = QuestStep.PASSENGER_DROPOFF

	# Khách xuống xe cạnh taxi
	if is_instance_valid(_passenger):
		_passenger.position = taxi_node.position + Vector2(18, 16)
		_passenger.visible = true

		var passenger_name = _passenger.data.display_name if _passenger.get("data") and _passenger.data.get("display_name") else "Hành khách"

		# Khách trả tiền & biểu cảm ngôi sao vàng
		_spawn_data_emote(_passenger, &"star")
		_spawn_data_emote(taxi_node, &"heart")

		taxi_quest_event.emit("⭐ ĐÃ ĐẾN NƠI", "%s: 'Cảm ơn bác tài! Xe chạy êm ru, chúc bác tài đắt khách!'" % passenger_name)

		# Khôi phục trạng thái đi tuần cho NPC
		if "auto_wander" in _passenger:
			_passenger.auto_wander = _passenger_orig_wander
		if "current_state" in _passenger:
			_passenger.current_state = 0 # State.IDLE
		var p_brain = _passenger.get_node_or_null("NPCBrain")
		if p_brain != null:
			p_brain.current_ai_state = p_brain.AIState.IDLE

	# Kết thúc cuốc xe, chuyển sang thời gian chờ cuốc tiếp theo
	_passenger = null
	current_step = QuestStep.COOLDOWN
	_step_timer = loop_interval


func _reset_quest() -> void:
	if is_instance_valid(_passenger):
		_passenger.visible = true
		if "auto_wander" in _passenger:
			_passenger.auto_wander = _passenger_orig_wander
		var p_brain = _passenger.get_node_or_null("NPCBrain")
		if p_brain != null:
			p_brain.current_ai_state = p_brain.AIState.IDLE
	_passenger = null
	if is_instance_valid(taxi_node):
		taxi_node.current_state = VehicleBase.VehicleState.PARKED
		taxi_node.velocity = Vector2.ZERO
	current_step = QuestStep.COOLDOWN
	_step_timer = 4.0


func _find_references() -> void:
	var tree = get_tree()
	if tree == null:
		return
	if entities_container == null:
		var root_scene = tree.current_scene
		if root_scene:
			entities_container = root_scene.get_node_or_null("Entities")
	if taxi_node == null:
		if entities_container != null:
			for child in entities_container.get_children():
				if child is CharacterBody2D and child.name.to_lower().contains("taxi"):
					taxi_node = child
					break
		if taxi_node == null:
			for veh in tree.get_nodes_in_group(&"vehicles"):
				if veh.name.contains("Taxi") or (veh.get("data") and "taxi" in str(veh.data.id).to_lower()):
					taxi_node = veh
					break


func _spawn_data_emote(target: Node2D, emote_id: StringName) -> void:
	if has_node("/root/EmoteRegistry"):
		get_node("/root/EmoteRegistry").spawn_emote(target, emote_id)
	else:
		var eb = load("res://scenes/test/emote_bubble.gd")
		if eb:
			eb.spawn_emote(target, str(emote_id))
