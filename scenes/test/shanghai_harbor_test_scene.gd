extends Node2D

## Script Điều Khiển Màn Tokyo Sim City Life & Nhập Vai Sĩ Quan Cảnh Sát (Tokyo Police RPG)
## Bản đồ siêu đô thị Tokyo 160 x 100 tiles (2560 x 1600 px)
## Tích hợp:
## - Hệ thống mô phỏng đời sống cảnh sát (PoliceLifeManager): Cấp bậc, Uy tín công dân, Ca trực 110
## - Chế độ điều khiển xe cảnh sát tuần tra (Police Cruiser Drive mode) với phím F
## - Tổng đài bộ đàm 110 phát lệnh nhiệm vụ điều động khẩn cấp với phím J
## - Điều khiển Sĩ quan Cảnh sát Tokyo (Officer ID01-Anh Tâm) với WASD, Sprint Shift, Tương tác E
## - Hơn 25 tòa nhà kiến trúc Tokyo, 20 phương tiện đường phố/vịnh biển, 30 NPC cư dân đời sống

const NPCBaseScene: PackedScene = preload("res://scenes/characters/NPCBase.tscn")
const VehicleBaseScene: PackedScene = preload("res://scenes/vehicles/VehicleBase.tscn")
const BuildingBaseScene: PackedScene = preload("res://scenes/buildings/BuildingBase.tscn")
const PlayerControllerScript = preload("res://scenes/test/player_npc_controller.gd")
const PoliceLifeManagerScript = preload("res://scripts/police/police_life_manager.gd")
const TaxiQuestLoopClass = preload("res://scenes/test/taxi_quest_loop.gd")
const CityAudioManagerScript = preload("res://scripts/audio/city_audio_manager.gd")

@onready var ground_layer: TileMapLayer = $TileMapRoot/GroundLayer
@onready var road_layer: TileMapLayer = $TileMapRoot/RoadLayer
@onready var decoration_layer: TileMapLayer = $TileMapRoot/DecorationLayer
@onready var entities: Node2D = $Entities

var camera: Camera2D = null
var player_node: CharacterBody2D = null
var police_mgr: PoliceLifeManager = null
var taxi_quest: Node = null
var city_audio: CityAudioManager = null

# HUD UI References
@onready var hud: CanvasLayer = get_node_or_null("HUD")
@onready var lbl_header: Label = get_node_or_null("%LblHeader")
@onready var lbl_sub: Label = get_node_or_null("%LblSub")
@onready var lbl_controls: Label = get_node_or_null("%LblControls")
@onready var lbl_player_pos: Label = get_node_or_null("%LblPlayerPos")
@onready var dispatch_card: PanelContainer = get_node_or_null("%DispatchCard")
@onready var lbl_dispatch_title: Label = get_node_or_null("%LblDispatchTitle")
@onready var lbl_dispatch_desc: Label = get_node_or_null("%LblDispatchDesc")
@onready var btn_radio_dispatch: Button = get_node_or_null("%BtnRadioDispatch")
@onready var btn_toggle_car: Button = get_node_or_null("%BtnToggleCar")
@onready var btn_trigger_taxi: Button = get_node_or_null("%BtnTriggerTaxi")
@onready var btn_reset_player: Button = get_node_or_null("%BtnResetPlayer")
var btn_horn: Button = null
var btn_siren: Button = null
@onready var dialogue_panel: PanelContainer = get_node_or_null("%DialoguePanel")
@onready var lbl_speaker: Label = get_node_or_null("%LblSpeaker")
@onready var lbl_dialogue_content: Label = get_node_or_null("%LblDialogueContent")

var camera_zoom_level: float = 1.8
var _dialogue_display_timer: float = 0.0

const MAP_WIDTH: int = 160
const MAP_HEIGHT: int = 100
const PLAYER_SPAWN_POS: Vector2 = Vector2(1500, 860) # Trước Trụ Sở Cảnh Sát Tokyo


func _ready() -> void:
	print("🚨 [TOKYO SIM CITY] Khởi tạo Hệ thống Mô phỏng Đời sống Cảnh sát Tokyo (160x100 tiles)...")
	
	# Khởi tạo Hệ thống Âm thanh Thành phố (Động cơ, Còi xe, Còi hú, Bước chân, Môi trường)
	city_audio = CityAudioManagerScript.new()
	city_audio.name = "CityAudioManager"
	add_child(city_audio)

	_setup_police_manager()
	_connect_ui_signals()
	_ensure_entity_groups()
	_setup_player()

	# Khởi tạo các lộ trình hành vi AI sống động cho NPC
	_setup_npc_ai_routines()

	# Vòng lặp mô phỏng Taxi di chuyển
	taxi_quest = TaxiQuestLoopClass.new()
	taxi_quest.name = "TaxiQuestLoop"
	taxi_quest.entities_container = entities
	taxi_quest.taxi_quest_event.connect(_on_taxi_quest_event)
	add_child(taxi_quest)

	_update_hud_status_bar()
	_show_notification("BỘ TỔNG TƯ LỆNH CẢNH SÁT TOKYO", "Chào mừng Sĩ quan ID01-Anh Tâm nhận ca trực! Dùng WASD di chuyển 8 hướng, F lên xe, H bóp còi, G còi hú!")


## Khởi tạo và kết nối PoliceLifeManager
func _setup_police_manager() -> void:
	police_mgr = PoliceLifeManager.new()
	police_mgr.name = "PoliceLifeManager"
	add_child(police_mgr)

	police_mgr.incident_dispatched.connect(_on_incident_dispatched)
	police_mgr.incident_resolved.connect(_on_incident_resolved)
	police_mgr.police_rank_promoted.connect(_on_police_rank_promoted)
	police_mgr.police_drive_state_changed.connect(_on_police_drive_state_changed)
	police_mgr.sim_clock_updated.connect(_on_sim_clock_updated)


func _setup_player() -> void:
	for child in entities.get_children():
		if child.is_in_group(&"player") or child.name.begins_with("Player"):
			player_node = child
			break

	if player_node:
		camera = player_node.get_node_or_null("Camera2D")
		if camera:
			camera.zoom = Vector2(camera_zoom_level, camera_zoom_level)
			camera.limit_left = 0
			camera.limit_top = 0
			camera.limit_right = MAP_WIDTH * 16
			camera.limit_bottom = MAP_HEIGHT * 16

		if not player_node.player_interacted_target.is_connected(_on_player_interacted):
			player_node.player_interacted_target.connect(_on_player_interacted)
		if not player_node.player_position_updated.is_connected(_on_player_position_updated):
			player_node.player_position_updated.connect(_on_player_position_updated)


func _ensure_entity_groups() -> void:
	if entities == null:
		return
	for child in entities.get_children():
		var cname = child.name.to_lower()
		if cname.begins_with("player"):
			child.add_to_group(&"player")
			child.add_to_group(&"npcs")
		elif cname.begins_with("npc"):
			child.add_to_group(&"npcs")
		elif cname.begins_with("bld"):
			child.add_to_group(&"buildings")
		elif cname.contains("ship") or cname.contains("boat") or cname.contains("car") or cname.contains("truck") or cname.contains("taxi") or cname.contains("bus") or cname.contains("bulldozer") or cname.contains("police"):
			child.add_to_group(&"vehicles")


func _process(delta: float) -> void:
	# Quản lý thời gian hiển thị khung thoại tương tác
	if dialogue_panel and dialogue_panel.visible:
		_dialogue_display_timer -= delta
		if _dialogue_display_timer <= 0.0:
			dialogue_panel.visible = false


func _physics_process(delta: float) -> void:
	if police_mgr and police_mgr.is_driving_police_car:
		_drive_police_car_tick(delta)
	elif player_node and is_instance_valid(player_node):
		# Giới hạn người chơi trên cạn trong bản đồ Tokyo
		player_node.global_position.x = clampf(player_node.global_position.x, 24.0, MAP_WIDTH * 16.0 - 24.0)
		player_node.global_position.y = clampf(player_node.global_position.y, 24.0, 1300.0)


## Xử lý vật lý lái xe cảnh sát 8 hướng mượt mà, quán tính tự nhiên và âm thanh động cơ
func _drive_police_car_tick(delta: float) -> void:
	var car = police_mgr.boarded_police_car
	if not is_instance_valid(car):
		police_mgr.is_driving_police_car = false
		if city_audio:
			city_audio.stop_car_engine()
		return

	# Đọc phím điều khiển di chuyển 8 hướng WASD / Mũi tên
	var input_vec = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_vec.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_vec.x += 1.0

	var is_sprint = Input.is_key_pressed(KEY_SHIFT)
	var max_speed = 340.0 if is_sprint else 230.0

	if input_vec.length_squared() > 0.001:
		input_vec = input_vec.normalized()
		var target_vel = input_vec * max_speed
		# Tăng tốc xe tự nhiên (Smooth Acceleration)
		car.velocity = car.velocity.move_toward(target_vel, 460.0 * delta)
		if car.has_method("set_facing_direction"):
			car.set_facing_direction(input_vec)
		if "current_state" in car:
			car.current_state = 2 # VehicleState.DRIVING
	else:
		# Giảm tốc tự nhiên theo quán tính phanh xe (Smooth Braking Inertia)
		car.velocity = car.velocity.move_toward(Vector2.ZERO, 380.0 * delta)
		if car.velocity.length_squared() < 4.0:
			car.velocity = Vector2.ZERO
			if "current_state" in car:
				car.current_state = 1 # VehicleState.IDLE

	# Cập nhật tiếng nổ máy và vòng tua động cơ theo vận tốc thực tế
	if city_audio:
		city_audio.update_engine_speed(car.velocity.length(), max_speed)

	# Giới hạn xe trong lòng thành phố (32..2528 px, 48..1300 px)
	car.global_position.x = clampf(car.global_position.x, 32.0, MAP_WIDTH * 16.0 - 32.0)
	car.global_position.y = clampf(car.global_position.y, 48.0, 1300.0)

	# Đồng bộ tọa độ player (đã disable collision) theo xe để Camera2D đi theo mượt mà
	if is_instance_valid(player_node):
		player_node.global_position = car.global_position
		_on_player_position_updated(car.global_position, car.velocity)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_camera_zoom(camera_zoom_level * 1.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_camera_zoom(camera_zoom_level / 1.15)

	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_reset_player_position()
				get_viewport().set_input_as_handled()
			KEY_T:
				_on_btn_trigger_taxi_pressed()
				get_viewport().set_input_as_handled()
			KEY_J:
				_trigger_radio_dispatch()
				get_viewport().set_input_as_handled()
			KEY_F:
				_toggle_player_vehicle()
				get_viewport().set_input_as_handled()
			KEY_H:
				_honk_horn()
				get_viewport().set_input_as_handled()
			KEY_G:
				_toggle_police_siren()
				get_viewport().set_input_as_handled()
			KEY_E:
				_check_resolve_active_incident()


## Bóp còi xe (Phím H)
func _honk_horn() -> void:
	if city_audio:
		city_audio.play_horn()
	_show_notification("🔊 CÒI XE CẢNH SÁT", "Bíp bíp! Đề nghị người đi bộ và phương tiện chú ý nhường đường.")


## Bật/Tắt còi hú cảnh sát ưu tiên (Phím G)
func _toggle_police_siren() -> void:
	if police_mgr and police_mgr.is_driving_police_car and is_instance_valid(police_mgr.boarded_police_car):
		var car = police_mgr.boarded_police_car
		if "siren_active" in car:
			car.siren_active = not car.siren_active
			if city_audio:
				if car.siren_active:
					city_audio.start_police_siren()
				else:
					city_audio.stop_police_siren()
			_show_notification("🚨 CÒI HÚ ƯU TIÊN 110", "Đã " + ("BẬT" if car.siren_active else "TẮT") + " còi hú cảnh sát tuần tra.")
	else:
		if city_audio:
			var active = city_audio.toggle_police_siren()
			_show_notification("🚨 CÒI HÚ CẢNH SÁT", "Đã " + ("BẬT" if active else "TẮT") + " tín hiệu còi hú.")


func _set_camera_zoom(target_zoom: float) -> void:
	camera_zoom_level = clampf(target_zoom, 0.6, 3.5)
	if camera:
		camera.zoom = Vector2(camera_zoom_level, camera_zoom_level)


func _reset_player_position() -> void:
	if player_node and is_instance_valid(player_node):
		player_node.position = PLAYER_SPAWN_POS
		player_node.velocity = Vector2.ZERO
		if police_mgr and police_mgr.is_driving_police_car and is_instance_valid(police_mgr.boarded_police_car):
			police_mgr.boarded_police_car.position = PLAYER_SPAWN_POS
			police_mgr.boarded_police_car.velocity = Vector2.ZERO
		_show_notification("ĐIỀU PHỐI TRỤ SỞ", "Sĩ quan đã trở về Trụ sở Cảnh sát Trung tâm Tokyo.")


## Bật/Tắt chế độ lái xe tuần tra (Phím F)
func _toggle_player_vehicle() -> void:
	if police_mgr == null or player_node == null:
		return

	if police_mgr.is_driving_police_car:
		# Xuống xe
		police_mgr.toggle_police_car_drive(player_node, null)
		if city_audio:
			city_audio.stop_car_engine()
		_show_notification("SĨ QUAN ID01-ANH TÂM", "Đã rời xe cảnh sát. Bắt đầu tuần tra đi bộ.")
	else:
		# Tìm xe gần nhất trong bán kính 140px, ưu tiên xe cảnh sát
		var best_veh: Node2D = null
		var min_dist: float = 140.0
		for child in entities.get_children():
			if child.is_in_group(&"vehicles") and child is CharacterBody2D:
				var dist = player_node.global_position.distance_to(child.global_position)
				if dist <= min_dist:
					if child.name.to_lower().contains("police") or child.name.to_lower().contains("patrol"):
						best_veh = child
						min_dist = dist * 0.5 # Ưu tiên xe cảnh sát
					elif best_veh == null:
						best_veh = child
						min_dist = dist

		if best_veh:
			police_mgr.toggle_police_car_drive(player_node, best_veh)
			if city_audio:
				city_audio.start_car_engine()
				if "siren_active" in best_veh and best_veh.siren_active:
					city_audio.start_police_siren()
			_show_notification("XE TUẦN TRA TOKYO", "Đã lên xe cảnh sát! Nổ máy động cơ, còi hú khẩn cấp kích hoạt. Nhấn H để bóp còi, G đổi còi hú.")
		else:
			_show_notification("SĨ QUAN TUẦN TRA", "Không có phương tiện tuần tra nào ở gần (Hãy lại gần xe cảnh sát trong bán kính 140px và nhấn F).")





## Gọi bộ đàm 110 xin điều động sự vụ tuần tra
func _trigger_radio_dispatch() -> void:
	if police_mgr == null:
		return
	if police_mgr.is_incident_active:
		_show_notification("TỔNG ĐÀI 110", "Đang có sự vụ chưa xử lý! Hãy đến mục tiêu trên bản đồ và nhấn E để xử lý.")
	else:
		police_mgr.trigger_random_incident()


## Kiểm tra giải quyết sự vụ khi nhấn E
func _check_resolve_active_incident() -> void:
	if police_mgr and police_mgr.is_incident_active and player_node:
		var target_pos: Vector2 = police_mgr.active_incident.get("target_pos", Vector2.ZERO)
		var rad: float = police_mgr.active_incident.get("radius", 100.0)
		var dist: float = player_node.global_position.distance_to(target_pos)
		
		if dist <= rad:
			police_mgr.resolve_current_incident()
		else:
			var loc = police_mgr.active_incident.get("location_name", "hiện trường")
			_show_notification("BỘ ĐÀM 110", "Chưa tới đúng hiện trường! Mục tiêu: %s (cách %.0f px)." % [loc, dist])


# ==============================================================================
# SỰ KIỆN TỪ POLICE LIFE MANAGER
# ==============================================================================
func _on_incident_dispatched(inc: Dictionary) -> void:
	var title = inc.get("title", "Sự vụ mới")
	var loc = inc.get("location_name", "Khu vực")
	var target_pos = inc.get("target_pos", Vector2.ZERO)
	
	if lbl_dispatch_title:
		lbl_dispatch_title.text = "🚨 [110 ĐIỀU ĐỘNG KHẨN CẤP]: " + title
	if lbl_dispatch_desc:
		lbl_dispatch_desc.text = "Địa điểm: %s | Tọa độ: (%.0f, %.0f)\nĐến hiện trường và nhấn E để giải quyết sự vụ!" % [loc, target_pos.x, target_pos.y]
	
	_show_notification("TỔNG ĐÀI ĐIỀU ĐỘNG 110", "Khẩn cấp: Có tin báo tại %s! Sĩ quan hãy lập tức di chuyển đến hỗ trợ." % loc)


func _on_incident_resolved(inc_title: String, rep_gained: int) -> void:
	_update_hud_status_bar()
	if lbl_dispatch_title:
		lbl_dispatch_title.text = "✅ [110 THÀNH CÔNG]: ĐÃ XỬ LÝ SỰ VỤ"
	if lbl_dispatch_desc:
		lbl_dispatch_desc.text = "Vụ việc: %s đã được giải quyết êm đẹp. Cộng +%d điểm Uy tín!" % [inc_title, rep_gained]
		
	var spk = police_mgr.active_incident.get("dialogue_speaker", "Cư dân Tokyo") if police_mgr else "Cư dân Tokyo"
	var dlg = police_mgr.active_incident.get("dialogue", "Cảm ơn Sĩ quan Cảnh sát đã giữ gìn trật tự Tokyo!") if police_mgr else "Cảm ơn Sĩ quan!"
	_show_notification(spk, dlg)


func _on_police_rank_promoted(new_rank_title: String) -> void:
	_update_hud_status_bar()
	_show_notification("⭐ SỞ CẢNH SÁT TOKYO VINH DANH", "Chúc mừng Sĩ quan ID01-Anh Tâm đã xuất sắc được thăng cấp lên: %s!" % new_rank_title)


func _on_police_drive_state_changed(is_driving: bool) -> void:
	if btn_toggle_car:
		btn_toggle_car.text = "🚶 Xuống Xe (F)" if is_driving else "🚓 Lên Xe (F)"


func _on_sim_clock_updated(_time_str: String, _shift_name: String) -> void:
	_update_hud_status_bar()


func _update_hud_status_bar() -> void:
	if lbl_sub and police_mgr:
		var time_str = "%02d:%02d" % [police_mgr.sim_hour, police_mgr.sim_minute]
		var shift_name = "Ca Sáng"
		if police_mgr.sim_hour >= 18 or police_mgr.sim_hour < 6:
			shift_name = "Ca Đêm"
		elif police_mgr.sim_hour >= 12:
			shift_name = "Ca Chiều"
			
		lbl_sub.text = "Sĩ quan: ID01-Anh Tâm | Cấp: %s | Uy tín: %d pts | Vụ đã giải quyết: %d | Đồng hồ: %s (%s)" % [
			police_mgr.get_rank_title(),
			police_mgr.civic_reputation,
			police_mgr.resolved_cases_count,
			time_str,
			shift_name
		]


# ==============================================================================
# UI & SỰ KIỆN TƯƠNG TÁC
# ==============================================================================
func _connect_ui_signals() -> void:
	if btn_reset_player and not btn_reset_player.pressed.is_connected(_reset_player_position):
		btn_reset_player.pressed.connect(_reset_player_position)
	if btn_trigger_taxi and not btn_trigger_taxi.pressed.is_connected(_on_btn_trigger_taxi_pressed):
		btn_trigger_taxi.pressed.connect(_on_btn_trigger_taxi_pressed)
	if btn_radio_dispatch and not btn_radio_dispatch.pressed.is_connected(_trigger_radio_dispatch):
		btn_radio_dispatch.pressed.connect(_trigger_radio_dispatch)
	if btn_toggle_car and not btn_toggle_car.pressed.is_connected(_toggle_player_vehicle):
		btn_toggle_car.pressed.connect(_toggle_player_vehicle)

	# Bổ sung nút Bóp Còi và Còi Hú Siren vào thanh công cụ
	var btn_parent = btn_toggle_car.get_parent() if btn_toggle_car else null
	if btn_parent:
		if btn_parent.get_node_or_null("BtnHorn") == null:
			btn_horn = Button.new()
			btn_horn.name = "BtnHorn"
			btn_horn.text = "🔊 Bóp Còi (H)"
			btn_horn.pressed.connect(_honk_horn)
			btn_parent.add_child(btn_horn)
		if btn_parent.get_node_or_null("BtnSiren") == null:
			btn_siren = Button.new()
			btn_siren.name = "BtnSiren"
			btn_siren.text = "🚨 Còi Hú (G)"
			btn_siren.pressed.connect(_toggle_police_siren)
			btn_parent.add_child(btn_siren)

	if lbl_controls:
		lbl_controls.text = "🎮 WASD: Di chuyển 8 hướng mượt mà | Shift: Chạy nhanh / Tăng tốc | E: Tương tác / Xử lý sự vụ\n🚓 F: Lên/Xuống xe cảnh sát | 🔊 H: Bóp Còi xe | 🚨 G: Bật/Tắt Còi Hú | 📻 J: Bộ đàm 110 | 🚖 T: Taxi | R: Về Đồn"


func _on_btn_trigger_taxi_pressed() -> void:
	if taxi_quest and taxi_quest.has_method("trigger_taxi_hail"):
		taxi_quest.trigger_taxi_hail()


func _on_taxi_quest_event(title: String, message: String) -> void:
	_show_notification(title, message)


func _on_player_position_updated(pos: Vector2, _vel: Vector2) -> void:
	if lbl_player_pos:
		lbl_player_pos.text = "Tọa độ Sĩ quan: (%.0f, %.0f) | Bản đồ Tokyo: 160x100 Ô gạch (2560x1600 px)" % [pos.x, pos.y]


func _on_player_interacted(target_name: String, message: String) -> void:
	# Nếu ở gần mục tiêu sự vụ, phím E vừa nói chuyện vừa giải quyết sự vụ
	if police_mgr and police_mgr.is_incident_active and player_node:
		var target_pos: Vector2 = police_mgr.active_incident.get("target_pos", Vector2.ZERO)
		var rad: float = police_mgr.active_incident.get("radius", 100.0)
		if player_node.global_position.distance_to(target_pos) <= rad:
			police_mgr.resolve_current_incident()
			return

	_show_notification(target_name, message)


func _show_notification(speaker: String, content: String) -> void:
	if lbl_speaker and lbl_dialogue_content and dialogue_panel:
		lbl_speaker.text = speaker
		lbl_dialogue_content.text = content
		dialogue_panel.visible = true
		_dialogue_display_timer = 5.0


func _setup_npc_ai_routines() -> void:
	var worker_routine = load("res://data/routines/routine_harbor_worker.tres")
	var citizen_routine = load("res://data/routines/routine_citizen_stroll.tres")

	for child in entities.get_children():
		if child is CharacterBody2D and child.is_in_group(&"npcs") and not child.is_in_group(&"player"):
			var cname = child.name
			var brain = child.get_node_or_null("NPCBrain")
			if brain == null and child.has_method("_setup_ai_brain"):
				child._setup_ai_brain()
				brain = child.get_node_or_null("NPCBrain")

			if brain != null:
				if cname.contains("ID03") or cname.contains("ID04"):
					if worker_routine:
						brain.start_routine(worker_routine)
				elif cname.contains("ID20") or cname.contains("ID21") or cname.contains("ID26") or cname.contains("ID27"):
					if citizen_routine:
						brain.start_routine(citizen_routine)

				if not child.dialogue_spoken.is_connected(_on_npc_dialogue_spoken.bind(child)):
					child.dialogue_spoken.connect(_on_npc_dialogue_spoken.bind(child))


func _on_npc_dialogue_spoken(line: String, npc_source: CharacterBody2D) -> void:
	if npc_source == null or not is_instance_valid(npc_source):
		return
	var sname = npc_source.data.display_name if npc_source.get("data") and npc_source.data.get("display_name") else npc_source.name
	if player_node != null and is_instance_valid(player_node):
		if player_node.global_position.distance_to(npc_source.global_position) <= 260.0:
			_show_notification(sname, line)
