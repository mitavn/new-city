extends Node2D

## Script Điều Khiển Màn Chơi Chính: 12 YEARS LATER (12 Năm Sau — Mộc Thành)
## Tích hợp toàn diện:
## 1. Bản đồ Siêu Đô Thị Mộc Thành (160x100 tiles) với đầy đủ khu phố cũ, chợ cháy, ga tàu, đồn cảnh sát
## 2. Hệ thống Lịch Trình 4 Ca (TownCalendar: Sáng, Chiều, Tối, Đêm) & Ánh sáng đổi màu (WorldLighting)
## 3. Hệ thống Sổ Tay Điều Tra (ClueJournal: Rumor -> Memory -> Evidence -> Truth)
## 4. Hệ thống Ký Ức "Một Bản Đồ — Hai Thời Đại" (MemorySystem: Flashback phím K)
## 5. Hệ thống Thiện Cảm 5 Người Bạn Cũ (AffinityManager: Minh, Lan, Tuấn, Bình, Nam)
## 6. Hệ thống Di chuyển 8 hướng mượt mà, Động cơ xe, Bóp còi (H), Còi hú (G), Bước chân (Footsteps)
## 7. Giao diện Sổ Tay Điều Tra (Journal Pinboard phím M) và HUD Đời Sống

const TownCalendarScript = preload("res://scripts/story/town_calendar.gd")
const ClueJournalScript = preload("res://scripts/story/clue_journal.gd")
const MemorySystemScript = preload("res://scripts/story/memory_system.gd")
const AffinityManagerScript = preload("res://scripts/story/affinity_manager.gd")
const WorldProgressionScript = preload("res://scripts/story/world_progression_manager.gd")
const CityAudioManagerScript = preload("res://scripts/audio/city_audio_manager.gd")

const NPCBaseScene: PackedScene = preload("res://scenes/characters/NPCBase.tscn")
const VehicleBaseScene: PackedScene = preload("res://scenes/vehicles/VehicleBase.tscn")
const BuildingBaseScene: PackedScene = preload("res://scenes/buildings/BuildingBase.tscn")
const PlayerControllerScript = preload("res://scenes/test/player_npc_controller.gd")
const PoliceLifeManagerScript = preload("res://scripts/police/police_life_manager.gd")

@onready var ground_layer: TileMapLayer = $TileMapRoot/GroundLayer
@onready var road_layer: TileMapLayer = $TileMapRoot/RoadLayer
@onready var decoration_layer: TileMapLayer = $TileMapRoot/DecorationLayer
@onready var entities: Node2D = $Entities
@onready var world_lighting: CanvasModulate = $WorldLighting

var camera: Camera2D = null
var player_node: CharacterBody2D = null
var police_mgr: PoliceLifeManager = null

# Story Core Subsystems
var calendar: TownCalendar = null
var journal: ClueJournal = null
var memory_sys: MemorySystem = null
var affinity_mgr: AffinityManager = null
var world_progression: WorldProgressionManager = null
var city_audio: CityAudioManager = null

# HUD References
@onready var hud: CanvasLayer = get_node_or_null("HUD")
@onready var lbl_header: Label = get_node_or_null("%LblHeader")
@onready var lbl_sub: Label = get_node_or_null("%LblSub")
@onready var lbl_controls: Label = get_node_or_null("%LblControls")
@onready var lbl_player_pos: Label = get_node_or_null("%LblPlayerPos")
@onready var journal_panel: PanelContainer = get_node_or_null("%JournalPanel")
@onready var lbl_journal_content: Label = get_node_or_null("%LblJournalContent")
@onready var dialogue_panel: PanelContainer = get_node_or_null("%DialoguePanel")
@onready var lbl_speaker: Label = get_node_or_null("%LblSpeaker")
@onready var lbl_dialogue_content: Label = get_node_or_null("%LblDialogueContent")

var camera_zoom_level: float = 1.8
var _dialogue_display_timer: float = 0.0
var playable_characters: Array[CharacterBody2D] = []
var _current_character_title: String = "Bạn (Nhân vật chính 29 tuổi)"

const MAP_WIDTH: int = 260
const MAP_HEIGHT: int = 160
const PLAYER_SPAWN_POS: Vector2 = Vector2(2520, 1180) # Trước Căn nhà cũ & Trụ sở Downtown Mộc Thành


func _ready() -> void:
	print("🌿 [12 YEARS LATER] Bắt đầu khởi tạo Siêu Đô Thị Mộc Thành (260x160 tiles — 41,600 tiles)...")

	_init_story_subsystems()
	_connect_ui_signals()
	_ensure_entity_groups()
	_setup_player()
	_refresh_playable_characters()
	_setup_key_friends_ai()

	_update_hud_display()
	_show_notification(
		"MỘC THÀNH — 12 NĂM SAU",
		"Bạn nhận được bưu kiện không người gửi: 1 chiếc chìa khóa cũ & ảnh nhóm 6 người bạn. 'Nếu còn nhớ lời hứa năm đó, hãy quay về trước khi nơi này biến mất.' Nhấn M để mở Sổ tay điều tra, K để hồi tưởng ký ức!"
	)


func _init_story_subsystems() -> void:
	# 1. Âm thanh Thành phố
	city_audio = CityAudioManagerScript.new()
	city_audio.name = "CityAudioManager"
	add_child(city_audio)

	# 2. Lịch trình 4 Ca (TownCalendar)
	calendar = TownCalendarScript.new()
	calendar.name = "TownCalendar"
	calendar.phase_changed.connect(_on_calendar_phase_changed)
	calendar.clock_tick.connect(_on_calendar_clock_tick)
	calendar.day_passed.connect(_on_calendar_day_passed)
	add_child(calendar)

	# 3. Sổ tay Điều tra Manh mối (ClueJournal)
	journal = ClueJournalScript.new()
	journal.name = "ClueJournal"
	journal.clue_stage_advanced.connect(_on_clue_stage_advanced)
	add_child(journal)

	# 4. Ký ức 12 năm trước (MemorySystem)
	memory_sys = MemorySystemScript.new()
	memory_sys.name = "MemorySystem"
	memory_sys.flashback_started.connect(_on_flashback_started)
	memory_sys.flashback_ended.connect(_on_flashback_ended)
	add_child(memory_sys)

	# 5. Thiện cảm 5 người bạn cũ (AffinityManager)
	affinity_mgr = AffinityManagerScript.new()
	affinity_mgr.name = "AffinityManager"
	affinity_mgr.affinity_changed.connect(_on_affinity_changed)
	add_child(affinity_mgr)

	# 6. Tiến trình Thế giới độc lập (WorldProgressionManager)
	world_progression = WorldProgressionScript.new()
	world_progression.name = "WorldProgressionManager"
	world_progression.town_event_triggered.connect(_on_town_event_triggered)
	add_child(world_progression)

	# 7. Quản lý cảnh sát tuần tra (PoliceLifeManager)
	police_mgr = PoliceLifeManagerScript.new()
	police_mgr.name = "PoliceLifeManager"
	add_child(police_mgr)

	# Cập nhật ánh sáng theo ca đầu tiên
	if world_lighting and calendar:
		world_lighting.color = calendar.get_current_ambient_color()


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
		elif cname.contains("car") or cname.contains("taxi") or cname.contains("bus") or cname.contains("ship") or cname.contains("boat") or cname.contains("police") or cname.contains("truck") or cname.contains("bulldozer"):
			child.add_to_group(&"vehicles")


func _process(delta: float) -> void:
	if dialogue_panel and dialogue_panel.visible:
		_dialogue_display_timer -= delta
		if _dialogue_display_timer <= 0.0:
			dialogue_panel.visible = false


func _physics_process(delta: float) -> void:
	if police_mgr and police_mgr.is_driving_police_car:
		_drive_police_car_tick(delta)
	elif player_node and is_instance_valid(player_node):
		player_node.global_position.x = clampf(player_node.global_position.x, 24.0, MAP_WIDTH * 16.0 - 24.0)
		player_node.global_position.y = clampf(player_node.global_position.y, 24.0, MAP_HEIGHT * 16.0 - 24.0)


## Xử lý lái xe 8 hướng với quán tính mượt mà và âm thanh động cơ
func _drive_police_car_tick(delta: float) -> void:
	var car = police_mgr.boarded_police_car
	if not is_instance_valid(car):
		police_mgr.is_driving_police_car = false
		if city_audio:
			city_audio.stop_car_engine()
		return

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
		car.velocity = car.velocity.move_toward(target_vel, 460.0 * delta)
		if car.has_method("set_facing_direction"):
			car.set_facing_direction(input_vec)
		if "current_state" in car:
			car.current_state = 2 # VehicleState.DRIVING
	else:
		car.velocity = car.velocity.move_toward(Vector2.ZERO, 380.0 * delta)
		if car.velocity.length_squared() < 4.0:
			car.velocity = Vector2.ZERO
			if "current_state" in car:
				car.current_state = 1 # VehicleState.IDLE

	if city_audio:
		city_audio.update_engine_speed(car.velocity.length(), max_speed)

	car.global_position.x = clampf(car.global_position.x, 32.0, MAP_WIDTH * 16.0 - 32.0)
	car.global_position.y = clampf(car.global_position.y, 48.0, MAP_HEIGHT * 16.0 - 48.0)

	if is_instance_valid(player_node):
		player_node.global_position = car.global_position
		_on_player_position_updated(car.global_position, car.velocity)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_camera_zoom(camera_zoom_level * 1.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_camera_zoom(camera_zoom_level / 1.15)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_char = _find_npc_at_mouse(get_global_mouse_position())
			if clicked_char and clicked_char != player_node:
				switch_to_character(clicked_char)
				get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB, KEY_C:
				switch_to_next_character()
				get_viewport().set_input_as_handled()
			KEY_M:
				_toggle_journal()
				get_viewport().set_input_as_handled()
			KEY_K:
				_toggle_memory_flashback()
				get_viewport().set_input_as_handled()
			KEY_H:
				_honk_horn()
				get_viewport().set_input_as_handled()
			KEY_G:
				_toggle_police_siren()
				get_viewport().set_input_as_handled()
			KEY_F:
				_toggle_player_vehicle()
				get_viewport().set_input_as_handled()
			KEY_R:
				_reset_player_position()
				get_viewport().set_input_as_handled()


# ==============================================================================
# HỆ THỐNG CHỌN & CHUYỂN ĐỔI NHÂN VẬT ĐIỀU KHIỂN (CHARACTER SWITCHING)
# ==============================================================================
func switch_to_next_character() -> void:
	if playable_characters.is_empty():
		_refresh_playable_characters()
	if playable_characters.is_empty():
		return

	var cur_idx = playable_characters.find(player_node)
	var next_idx = (cur_idx + 1) % playable_characters.size()
	switch_to_character(playable_characters[next_idx])


func switch_to_character(target_char: CharacterBody2D) -> void:
	if target_char == null or not is_instance_valid(target_char):
		return
	if target_char == player_node:
		return

	# Nếu đang lái xe, bước xuống trước
	if police_mgr and police_mgr.is_driving_police_car:
		police_mgr.is_driving_police_car = false
		if city_audio:
			city_audio.stop_car_engine()

	var old_player = player_node

	# 1. Trả lại trạng thái cho nhân vật cũ
	if old_player and is_instance_valid(old_player):
		if old_player.has_signal("player_interacted_target") and old_player.player_interacted_target.is_connected(_on_player_interacted):
			old_player.player_interacted_target.disconnect(_on_player_interacted)
		if old_player.has_signal("player_position_updated") and old_player.player_position_updated.is_connected(_on_player_position_updated):
			old_player.player_position_updated.disconnect(_on_player_position_updated)

		# Bỏ quyền điều khiển khỏi nhân vật cũ
		if "enable_player_input" in old_player:
			old_player.enable_player_input = false
		if old_player.name != "Player_Main_Character":
			if "auto_wander" in old_player:
				old_player.auto_wander = true

		# Gỡ Camera2D ra khỏi nhân vật cũ
		if camera and camera.get_parent() == old_player:
			old_player.remove_child(camera)

	# 2. Cài đặt quyền điều khiển cho nhân vật mới
	if target_char.get_script() != PlayerControllerScript:
		var saved_data = target_char.data
		target_char.set_script(PlayerControllerScript)
		target_char.data = saved_data

	target_char.auto_wander = false
	target_char.enable_player_input = true
	target_char.use_smart_ai = false

	# Gắn Camera2D vào nhân vật mới
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 7.0
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = MAP_WIDTH * 16
		camera.limit_bottom = MAP_HEIGHT * 16

	target_char.add_child(camera)
	camera.zoom = Vector2(camera_zoom_level, camera_zoom_level)

	# Kết nối lại tín hiệu
	if not target_char.player_interacted_target.is_connected(_on_player_interacted):
		target_char.player_interacted_target.connect(_on_player_interacted)
	if not target_char.player_position_updated.is_connected(_on_player_position_updated):
		target_char.player_position_updated.connect(_on_player_position_updated)

	player_node = target_char
	_current_character_title = get_character_display_name(target_char)

	# Cập nhật HUD & thông báo
	_show_notification("ĐỔI NHÂN VẬT ĐIỀU KHIỂN", "Bạn đang điều khiển: " + _current_character_title + ".\nSử dụng WASD để di chuyển, Shift chạy nhanh, F lái xe, E tương tác.")
	if lbl_player_pos:
		lbl_player_pos.text = "Đang điều khiển: %s | Tọa độ: (%.0f, %.0f)" % [_current_character_title, target_char.position.x, target_char.position.y]


func _find_npc_at_mouse(global_pos: Vector2) -> CharacterBody2D:
	if entities == null:
		return null
	var best_char: CharacterBody2D = null
	var min_dist: float = 48.0 # bán kính click 48px
	for child in entities.get_children():
		if child is CharacterBody2D and child != player_node and child.is_in_group(&"npcs"):
			var dist = child.global_position.distance_to(global_pos)
			if dist < min_dist:
				min_dist = dist
				best_char = child
	return best_char


func _refresh_playable_characters() -> void:
	playable_characters.clear()
	if entities == null:
		return

	var priority_names = [
		"Player_Main_Character",
		"NPC_Minh_CanhSat",
		"NPC_Lan_QuanCafe",
		"NPC_Tuan_BatDongSan",
		"NPC_Binh_ThayGiao",
		"NPC_Nam_BongMaGaTau",
		"NPC_Sau_TiemSachCu"
	]
	for pname in priority_names:
		var n = entities.get_node_or_null(pname)
		if n is CharacterBody2D and not playable_characters.has(n):
			playable_characters.append(n)

	for child in entities.get_children():
		if child is CharacterBody2D and child.is_in_group(&"npcs") and not playable_characters.has(child):
			playable_characters.append(child)


func get_character_display_name(node: CharacterBody2D) -> String:
	if node == null:
		return "Chưa rõ"
	if node.name.begins_with("Player"):
		return "Bạn (Nhân vật chính 29 tuổi)"
	if node.name.contains("Minh"):
		return "Minh (Cảnh sát tuần tra)"
	if node.name.contains("Lan"):
		return "Lan (Chủ quán café hoa giấy)"
	if node.name.contains("Tuan"):
		return "Tuấn (Giám đốc Bất động sản)"
	if node.name.contains("Binh"):
		return "Bình (Thầy giáo bảo tồn khu phố)"
	if node.name.contains("Nam"):
		return "Nam (Người bạn mất tích 12 năm trước)"
	if node.name.contains("Sau"):
		return "Bà Sáu (Hiệu sách cổ)"
	if node.data and "display_name" in node.data and not node.data.display_name.is_empty():
		return node.data.display_name
	return node.name


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
		_show_notification("CĂN NHÀ CŨ", "Bạn đã trở về căn nhà cũ phủ đầy bụi thời gian của gia đình bạn.")


## Bật/Tắt Sổ Tay Điều Tra (Phím M)
func _toggle_journal() -> void:
	if journal_panel == null:
		return
	journal_panel.visible = not journal_panel.visible
	if journal_panel.visible:
		_refresh_journal_text()


func _refresh_journal_text() -> void:
	if lbl_journal_content == null or journal == null or affinity_mgr == null:
		return

	var text = "═══════════════ SỔ TAY ĐIỀU TRA: MỘC THÀNH (12 NĂM SAU) ═══════════════\n"
	text += "Vật phẩm: [Chiếc Chìa Khóa Cũ] | [Bức Ảnh 6 Người Bạn Thuở Nhỏ]\n\n"
	text += "▶ 1. VỤ CHÁY CHỢ CŨ 12 NĂM TRƯỚC:\n"
	text += "   Trạng thái: " + ClueJournal.STAGE_NAMES[journal.clues_database["fire_origin"]["stage"]] + "\n"
	text += "   Nội dung: " + journal.get_clue_current_text("fire_origin") + "\n\n"

	text += "▶ 2. SỰ MẤT TÍCH BÍ ẨN CỦA NAM:\n"
	text += "   Trạng thái: " + ClueJournal.STAGE_NAMES[journal.clues_database["nam_disappearance"]["stage"]] + "\n"
	text += "   Nội dung: " + journal.get_clue_current_text("nam_disappearance") + "\n\n"

	text += "▶ 3. BẢN HỢP ĐỒNG THÂU TÓM KHU PHỐ:\n"
	text += "   Trạng thái: " + ClueJournal.STAGE_NAMES[journal.clues_database["land_deal"]["stage"]] + "\n"
	text += "   Nội dung: " + journal.get_clue_current_text("land_deal") + "\n\n"

	text += "▶ 4. LỜI HỨA NĂM 17 TUỔI DƯỚI GỐC CÂY:\n"
	text += "   Trạng thái: " + ClueJournal.STAGE_NAMES[journal.clues_database["childhood_promise"]["stage"]] + "\n"
	text += "   Nội dung: " + journal.get_clue_current_text("childhood_promise") + "\n\n"

	text += "─────────── MỐI QUAN HỆ & THIỆN CẢM VỚI 5 NGƯỜI BẠN CŨ ───────────\n"
	text += "• Minh Cảnh Sát: %d pts [%s]\n" % [affinity_mgr.get_score("minh_police"), affinity_mgr.get_tier_name("minh_police")]
	text += "• Lan Quán Café: %d pts [%s]\n" % [affinity_mgr.get_score("lan_cafe"), affinity_mgr.get_tier_name("lan_cafe")]
	text += "• Tuấn Bất Động Sản: %d pts [%s]\n" % [affinity_mgr.get_score("tuan_realestate"), affinity_mgr.get_tier_name("tuan_realestate")]
	text += "• Bình Thầy Giáo: %d pts [%s]\n" % [affinity_mgr.get_score("binh_teacher"), affinity_mgr.get_tier_name("binh_teacher")]
	text += "• Nam 'Bóng Ma Ga Tàu': %d pts [%s]\n" % [affinity_mgr.get_score("nam_ghost"), affinity_mgr.get_tier_name("nam_ghost")]

	lbl_journal_content.text = text


## Kích hoạt Ký ức 12 năm trước (Phím K)
func _toggle_memory_flashback() -> void:
	if memory_sys == null:
		return

	if memory_sys.is_in_flashback:
		# Quay về hiện tại 29 tuổi
		var current_ambient = calendar.get_current_ambient_color() if calendar else Color.WHITE
		memory_sys.return_to_present(self, current_ambient)
		_show_notification(
			"TRỞ VỀ THỰC TẠI (29 TUỔI)",
			"Tiếng cười đùa tan biến. Bạn đứng một mình trong gió lạnh ngay đúng vị trí này. 12 năm đã trôi qua thật rồi..."
		)
	else:
		# Vào ký ức tuổi 17
		memory_sys.trigger_flashback("flashback_san_bong", "Hồi Ức Trận Bóng Mùa Hè Năm 17 Tuổi", self)
		_show_notification(
			"🎞️ HỒI ỨC 12 NĂM TRƯỚC (TUỔI 17)",
			"[Minh 17t]: Chuyền bóng cho tao nhanh lên! Trận này mà thắng tao khao cả lũ chè đậu đỏ!\n[Lan 17t]: Uống nước đi các cậu! Đừng có ngã rách áo nhé!\n[Nam 17t]: Nhớ lời hứa chôn chiếc hộp thiếc ở gốc cây long não đấy nhé!"
		)
		# Tự động nâng cấp manh mối lời hứa
		if journal:
			journal.advance_clue_stage("childhood_promise", ClueJournal.Stage.EVIDENCE)


## Bóp còi xe (Phím H)
func _honk_horn() -> void:
	if city_audio:
		city_audio.play_horn()
	_show_notification("🔊 CÒI XE", "Bíp bíp! Tiếng còi vang vọng giữa lòng thành phố Mộc Thành.")


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
			_show_notification("🚨 CÒI HÚ ƯU TIÊN 110", "Đã " + ("BẬT" if car.siren_active else "TẮT") + " còi hú xe tuần tra.")
	else:
		if city_audio:
			var active = city_audio.toggle_police_siren()
			_show_notification("🚨 CÒI HÚ", "Đã " + ("BẬT" if active else "TẮT") + " còi hú cảnh sát.")


## Lên/Xuống xe (Phím F)
func _toggle_player_vehicle() -> void:
	if police_mgr == null or player_node == null:
		return

	if police_mgr.is_driving_police_car:
		police_mgr.toggle_police_car_drive(player_node, null)
		if city_audio:
			city_audio.stop_car_engine()
		_show_notification("SĨ QUAN ID01-ANH TÂM", "Đã rời xe. Bắt đầu tuần tra đi bộ qua các con phố Mộc Thành.")
	else:
		var best_veh: Node2D = null
		var min_dist: float = 140.0
		for child in entities.get_children():
			if child.is_in_group(&"vehicles") and child is CharacterBody2D:
				var dist = player_node.global_position.distance_to(child.global_position)
				if dist <= min_dist:
					if child.name.to_lower().contains("police") or child.name.to_lower().contains("patrol"):
						best_veh = child
						min_dist = dist * 0.5
					elif best_veh == null:
						best_veh = child
						min_dist = dist

		if best_veh:
			police_mgr.toggle_police_car_drive(player_node, best_veh)
			if city_audio:
				city_audio.start_car_engine()
				if "siren_active" in best_veh and best_veh.siren_active:
					city_audio.start_police_siren()
			_show_notification("XE TUẦN TRA MỘC THÀNH", "Đã lên xe! Động cơ nổ máy. Nhấn H để bóp còi, G đổi còi hú.")


# ==============================================================================
# SỰ KIỆN TƯƠNG TÁC NPC & GIẢI MÃ CỐT TRUYỆN (RUMOR -> MEMORY -> TRUTH)
# ==============================================================================
func _on_player_interacted(target_name: String, message: String) -> void:
	var t_lower = target_name.to_lower()

	# 1. Tương tác với Minh Cảnh Sát
	if t_lower.contains("minh") or t_lower.contains("canhsat") or t_lower.contains("id02"):
		affinity_mgr.add_affinity("minh_police", 15)
		journal.advance_clue_stage("fire_origin", ClueJournal.Stage.MEMORY)
		_show_notification(
			"Minh Cảnh Sát (Bạn cũ):",
			"Cậu quay về làm gì? 12 năm trước cậu bỏ đi một mạch... Vụ cháy năm đó hồ sơ đã bị niêm phong. Cậu càng đào bới chỉ càng nguy hiểm thôi."
		)
		return

	# 2. Tương tác với Lan Quán Café
	if t_lower.contains("lan") or t_lower.contains("cafe") or t_lower.contains("id20"):
		affinity_mgr.add_affinity("lan_cafe", 20)
		journal.advance_clue_stage("land_deal", ClueJournal.Stage.EVIDENCE)
		_show_notification(
			"Lan (Chủ Quán Café hoa giấy):",
			"12 năm rồi... cậu không thay đổi chút nào. Uống ly café phin này đi. Tớ vẫn giữ cuộn băng cassette của đêm hôm đó. Bố cậu không hề ký vào giấy bán khu phố đâu!"
		)
		return

	# 3. Tương tác với Tuấn Bất Động Sản
	if t_lower.contains("tuan") or t_lower.contains("vesi") or t_lower.contains("id08"):
		affinity_mgr.add_affinity("tuan_realestate", -5)
		journal.advance_clue_stage("land_deal", ClueJournal.Stage.RUMOR)
		_show_notification(
			"Tuấn (Giám Đốc Dự Án Plaza):",
			"Chào bạn cũ! Nghe nói cậu vừa về? Bán lại căn nhà cũ cho công ty tao đi. Giá cao ngất ngưởng. Kỷ niệm thì có ăn được đâu, giữ lại khu ổ chuột cháy rụi làm gì!"
		)
		return

	# 4. Tương tác với Nam 'Bóng Ma Ga Tàu' (Chỉ xuất hiện đêm hoặc ở góc vắng)
	if t_lower.contains("nam") or t_lower.contains("shipper") or t_lower.contains("id13"):
		affinity_mgr.add_affinity("nam_ghost", 25)
		journal.advance_clue_stage("nam_disappearance", ClueJournal.Stage.TRUTH)
		journal.advance_clue_stage("fire_origin", ClueJournal.Stage.TRUTH)
		_show_notification(
			"Nam (Người Bạn Tưởng Đã Mất Tích):",
			"Cậu đã tìm ra chìa khóa rồi à? Tớ chưa từng rời khỏi Mộc Thành. Can nhựa đêm đó là đựng nước cứu người, không phải can xăng. Bây giờ cậu hãy chọn đi: Mộc Thành đáng được cứu, hay nên để nó biến mất?"
		)
		return

	# 5. Tương tác với Bà Sáu Tiệm Sách
	if t_lower.contains("sau") or t_lower.contains("basau") or t_lower.contains("id16"):
		affinity_mgr.add_affinity("sau_bookstore", 25)
		_show_notification(
			"Bà Sáu (Hiệu Sách Cũ 30 Năm):",
			"Cậu bé nhà bên về rồi đấy à? Mấy tập truyện tranh bọn cháu đọc dở 12 năm trước bà vẫn để trên giá kìa. Bọn họ sắp phá tiệm sách của bà rồi..."
		)
		return

	_show_notification(target_name, message)


# ==============================================================================
# PHẢN HỒI THỜI GIAN & ÁNH SÁNG ĐỘNG
# ==============================================================================
func _on_calendar_phase_changed(new_phase: TownCalendar.DayPhase, phase_name: String) -> void:
	if world_lighting and calendar and not (memory_sys and memory_sys.is_in_flashback):
		var target_color = calendar.get_current_ambient_color()
		var tween = create_tween()
		tween.tween_property(world_lighting, "color", target_color, 2.5)

	_update_hud_display()
	_show_notification("THỜI KHẮC MỘC THÀNH", "Đã chuyển sang: " + phase_name)


func _on_calendar_clock_tick(_h: int, _m: int, _t_str: String) -> void:
	_update_hud_display()


func _on_calendar_day_passed(new_day: int) -> void:
	if world_progression:
		world_progression.check_day_milestone(new_day, affinity_mgr)
	_update_hud_display()


func _on_clue_stage_advanced(clue_id: String, _old: int, new_stage: int, desc: String) -> void:
	var stage_name = ClueJournal.STAGE_NAMES.get(new_stage, "")
	_show_notification("🔍 MANH MỐI TIẾN TRIỂN: " + stage_name, desc)
	_refresh_journal_text()


func _on_affinity_changed(char_id: String, _old_s: int, new_s: int, tier_name: String) -> void:
	var char_name = affinity_mgr.affinities[char_id]["name"] if affinity_mgr else char_id
	_show_notification("❤️ MỐI QUAN HỆ: " + char_name, "Thiện cảm: %d điểm [%s]" % [new_s, tier_name])
	_refresh_journal_text()


func _on_town_event_triggered(_event_id: String, title: String, message: String) -> void:
	_show_notification("📢 BIẾN ĐỘNG MỘC THÀNH: " + title, message)


func _on_flashback_started(_mem_id: String, title: String) -> void:
	_update_hud_display()


func _on_flashback_ended(_mem_id: String) -> void:
	_update_hud_display()


func _update_hud_display() -> void:
	if lbl_header:
		lbl_header.text = "🌿 12 YEARS LATER — MỘC THÀNH (NGÀY %d)" % (calendar.current_day if calendar else 1)
	if lbl_sub and calendar:
		var time_str = "%02d:%02d" % [calendar.current_hour, calendar.current_minute]
		var phase = calendar.get_phase_name()
		var fb_status = " [🎞️ ĐANG Ở KÝ ỨC 12 NĂM TRƯỚC]" if (memory_sys and memory_sys.is_in_flashback) else ""
		lbl_sub.text = "Thời gian: %s (%s) | Đồng hồ: %s%s | Tiền mặt: 1,250,000 đ" % [phase, "Thường nhật", time_str, fb_status]
	if lbl_controls:
		lbl_controls.text = "🎮 WASD: Di chuyển 8 hướng | Tab / Click NPC: Đổi nhân vật điều khiển | Shift: Chạy nhanh / Tăng tốc\n📖 M: Sổ tay điều tra | 🎞️ K: Hồi tưởng ký ức 12 năm trước | 🚓 F: Lên/Xuống xe | 🔊 H: Còi xe | 🚨 G: Còi hú"


func _connect_ui_signals() -> void:
	var btn_journal = get_node_or_null("%BtnJournal")
	if btn_journal and not btn_journal.pressed.is_connected(_toggle_journal):
		btn_journal.pressed.connect(_toggle_journal)

	var btn_flashback = get_node_or_null("%BtnFlashback")
	if btn_flashback and not btn_flashback.pressed.is_connected(_toggle_memory_flashback):
		btn_flashback.pressed.connect(_toggle_memory_flashback)

	var btn_horn = get_node_or_null("%BtnHorn")
	if btn_horn and not btn_horn.pressed.is_connected(_honk_horn):
		btn_horn.pressed.connect(_honk_horn)

	var btn_siren = get_node_or_null("%BtnSiren")
	if btn_siren and not btn_siren.pressed.is_connected(_toggle_police_siren):
		btn_siren.pressed.connect(_toggle_police_siren)

	var btn_toggle_car = get_node_or_null("%BtnToggleCar")
	if btn_toggle_car and not btn_toggle_car.pressed.is_connected(_toggle_player_vehicle):
		btn_toggle_car.pressed.connect(_toggle_player_vehicle)

	var btn_reset_player = get_node_or_null("%BtnResetPlayer")
	if btn_reset_player and not btn_reset_player.pressed.is_connected(_reset_player_position):
		btn_reset_player.pressed.connect(_reset_player_position)

	var btn_switch_char = get_node_or_null("%BtnSwitchChar")
	if btn_switch_char and not btn_switch_char.pressed.is_connected(switch_to_next_character):
		btn_switch_char.pressed.connect(switch_to_next_character)
	elif btn_journal:
		var hbox = btn_journal.get_parent()
		if hbox and not hbox.has_node("BtnSwitchChar"):
			var btn_switch = Button.new()
			btn_switch.name = "BtnSwitchChar"
			btn_switch.text = "👥 Đổi Nhân Vật (Tab)"
			btn_switch.pressed.connect(switch_to_next_character)
			hbox.add_child(btn_switch)


func _on_player_position_updated(pos: Vector2, _vel: Vector2) -> void:
	if lbl_player_pos:
		lbl_player_pos.text = "Đang điều khiển: %s | Tọa độ: (%.0f, %.0f) | Siêu Đô Thị: 260x160 Ô gạch" % [_current_character_title, pos.x, pos.y]


func _show_notification(speaker: String, content: String) -> void:
	if lbl_speaker and lbl_dialogue_content and dialogue_panel:
		lbl_speaker.text = speaker
		lbl_dialogue_content.text = content
		dialogue_panel.visible = true
		_dialogue_display_timer = 5.5


func _setup_key_friends_ai() -> void:
	# Cài đặt lộ trình công việc cho các cư dân và người bạn cũ
	var stroll_routine = load("res://data/routines/routine_citizen_stroll.tres")
	var worker_routine = load("res://data/routines/routine_harbor_worker.tres")

	for child in entities.get_children():
		if child is CharacterBody2D and child.is_in_group(&"npcs") and not child.is_in_group(&"player"):
			var brain = child.get_node_or_null("NPCBrain")
			if brain == null and child.has_method("_setup_ai_brain"):
				child._setup_ai_brain()
				brain = child.get_node_or_null("NPCBrain")
			if brain != null:
				if child.name.contains("ID20") or child.name.contains("ID21"):
					if stroll_routine:
						brain.start_routine(stroll_routine)
				elif child.name.contains("ID03") or child.name.contains("ID04"):
					if worker_routine:
						brain.start_routine(worker_routine)
