extends Node2D

## Scene Kiểm Tra Bản Đồ Thành Phố (Map Test Scene)
## Minh họa cách sử dụng TileSet Terrain với TileMapLayer, tích hợp NPC, Xe cộ và Tòa nhà.

const CityMapManagerClass = preload("res://scripts/world/city_map_manager.gd")

@onready var map_manager: Node2D = $MapManager
@onready var ground_layer: TileMapLayer = $MapManager/GroundLayer
@onready var road_layer: TileMapLayer = $MapManager/RoadLayer
@onready var decoration_layer: TileMapLayer = $MapManager/DecorationLayer
@onready var entities: Node2D = $Entities
@onready var camera: Camera2D = $Camera2D

# UI Nodes
@onready var lbl_hover_info: Label = %LblHoverInfo
@onready var lbl_coords: Label = %LblCoords
@onready var lbl_surface: Label = %LblSurface
@onready var lbl_speed: Label = %LblSpeed
@onready var lbl_flags: Label = %LblFlags
@onready var chk_ground: CheckBox = %ChkGround
@onready var chk_road: CheckBox = %ChkRoad
@onready var chk_deco: CheckBox = %ChkDeco
@onready var chk_entities: CheckBox = %ChkEntities
@onready var btn_reset_cam: Button = %BtnResetCam
@onready var btn_regen: Button = %BtnRegen

var _is_dragging: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_cam: Vector2 = Vector2.ZERO
var _camera_zoom: float = 2.0


func _ready() -> void:
	print("--- KHỞI ĐỘNG MAP TEST SCENE ---")
	camera.zoom = Vector2(_camera_zoom, _camera_zoom)
	
	_connect_ui_signals()
	_generate_sample_city_map()
	_spawn_sample_entities()
	
	# Đặt camera vào trung tâm ngã tư
	camera.position = Vector2(480, 480)


func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)
	_update_hover_inspector()


func _unhandled_input(event: InputEvent) -> void:
	# Kéo chuột phải hoặc chuột giữa để cuộn camera
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				_is_dragging = true
				_drag_start_mouse = event.position
				_drag_start_cam = camera.position
			else:
				_is_dragging = false
		# Lăn chuột để phóng to / thu nhỏ
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_camera_zoom(_camera_zoom * 1.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_camera_zoom(_camera_zoom / 1.15)
			
	elif event is InputEventMouseMotion and _is_dragging:
		var delta_mouse = event.position - _drag_start_mouse
		camera.position = _drag_start_cam - (delta_mouse / camera.zoom.x)


func _handle_keyboard_pan(delta: float) -> void:
	var move_vec = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vec.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0
		
	if move_vec != Vector2.ZERO:
		var pan_speed = 300.0 / camera.zoom.x
		camera.position += move_vec.normalized() * pan_speed * delta


func _set_camera_zoom(new_zoom: float) -> void:
	_camera_zoom = clampf(new_zoom, 0.5, 5.0)
	camera.zoom = Vector2(_camera_zoom, _camera_zoom)


func _update_hover_inspector() -> void:
	var mouse_world = get_global_mouse_position()
	var tile_coord = map_manager.world_to_tile(mouse_world)
	var td = map_manager.get_tile_data_at(mouse_world)
	
	lbl_coords.text = "Tọa độ: (%d, %d) | Thế giới: (%.0f, %.0f)" % [tile_coord.x, tile_coord.y, mouse_world.x, mouse_world.y]
	
	if td:
		var surf = str(td.get_custom_data("surface_type"))
		var spd = float(td.get_custom_data("speed_multiplier"))
		var is_r = bool(td.get_custom_data("is_road"))
		var is_sw = bool(td.get_custom_data("is_sidewalk"))
		var is_cw = bool(td.get_custom_data("is_crosswalk"))
		var is_pk = bool(td.get_custom_data("is_parking"))
		var is_wt = bool(td.get_custom_data("is_water"))
		
		lbl_surface.text = "Bề mặt: %s" % surf.to_upper()
		lbl_speed.text = "Hệ số tốc độ: %.2fx" % spd
		
		var flags_str = []
		if is_r: flags_str.append("[Đường Xe]")
		if is_sw: flags_str.append("[Vỉa Hè]")
		if is_cw: flags_str.append("[Vạch Sang Đường]")
		if is_pk: flags_str.append("[Bãi Đỗ Xe]")
		if is_wt: flags_str.append("[Nước / Vật Cản]")
		
		lbl_flags.text = "Cờ: %s" % (" ".join(flags_str) if not flags_str.is_empty() else "Không")
	else:
		lbl_surface.text = "Bề mặt: Trống"
		lbl_speed.text = "Hệ số tốc độ: 1.00x"
		lbl_flags.text = "Cờ: Không có tile"


func _connect_ui_signals() -> void:
	chk_ground.toggled.connect(func(toggled: bool): ground_layer.visible = toggled)
	chk_road.toggled.connect(func(toggled: bool): road_layer.visible = toggled)
	chk_deco.toggled.connect(func(toggled: bool): decoration_layer.visible = toggled)
	chk_entities.toggled.connect(func(toggled: bool): entities.visible = toggled)
	
	btn_reset_cam.pressed.connect(func():
		camera.position = Vector2(480, 480)
		_set_camera_zoom(2.0)
	)
	
	btn_regen.pressed.connect(func():
		_generate_sample_city_map()
	)


## Xây dựng bản đồ thành phố mẫu hoàn chỉnh
func _generate_sample_city_map() -> void:
	ground_layer.clear()
	road_layer.clear()
	decoration_layer.clear()
	
	# Bản đồ mẫu kích thước 60x60 ô (960x960 px)
	var map_w = 60
	var map_h = 60
	
	# 1. Nền Cỏ xanh (Grass Ground) trên toàn bộ bản đồ
	for y in range(map_h):
		for x in range(map_w):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(56, 8)) # Ô cỏ xanh trung tâm
			
	# 2. Ao nước tự nhiên (Water Pond) tại góc trên bên trái (x: 4..14, y: 4..12)
	_stamp_autotile_rect(ground_layer, Vector2i(4, 4), Vector2i(11, 9), Vector2i(40, 12))
	
	# 3. Bãi cát ven hồ (Sandy Shore) tại x: 15..20, y: 4..10
	_stamp_autotile_rect(ground_layer, Vector2i(15, 4), Vector2i(6, 7), Vector2i(49, 12))
	
	# 4. Đường mòn đất nâu (Dirt Path) tại x: 4..12, y: 14..18
	_stamp_autotile_rect(ground_layer, Vector2i(4, 14), Vector2i(9, 5), Vector2i(52, 7))
	
	# 5. Sân bóng rổ (Basketball Court) tại x: 44..53, y: 4..12
	for by in range(9):
		for bx in range(10):
			ground_layer.set_cell(Vector2i(44 + bx, 4 + by), 0, Vector2i(40 + bx, by))
	
	# 6. Giao lộ đường lớn 4 ngả (Main 4-Way Road Intersection)
	# Trục đường dọc chính (Road North-South: x: 26..35, y: 0..59)
	# Trục đường ngang chính (Road East-West: x: 0..59, y: 26..35)
	
	# Lát mặt đường nhựa cho ngã tư trung tâm
	for y in range(map_h):
		for x in range(map_w):
			var in_vert_road = (x >= 27 and x <= 34)
			var in_horiz_road = (y >= 27 and y <= 34)
			var in_vert_sidewalk = (x in [25, 26, 35, 36])
			var in_horiz_sidewalk = (y in [25, 26, 35, 36])
			
			if in_vert_road or in_horiz_road:
				# Mặt đường nhựa
				road_layer.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))
				
				# Vạch phân làn đứt đoạn
				if in_vert_road and not in_horiz_road and x in [30, 31]:
					if y % 3 == 0:
						decoration_layer.set_cell(Vector2i(x, y), 0, Vector2i(32, 22))
				if in_horiz_road and not in_vert_road and y in [30, 31]:
					if x % 3 == 0:
						decoration_layer.set_cell(Vector2i(x, y), 0, Vector2i(20, 38))
						
			elif (in_vert_sidewalk and (y < 25 or y > 36)) or (in_horiz_sidewalk and (x < 25 or x > 36)):
				# Vỉa hè đá lát (Cobblestone)
				road_layer.set_cell(Vector2i(x, y), 0, Vector2i(44, 8))
			elif in_vert_sidewalk and in_horiz_sidewalk:
				# Góc cua vỉa hè (Red Brick)
				road_layer.set_cell(Vector2i(x, y), 0, Vector2i(15, 27))
	
	# 7. Vạch sang đường (Zebra Crosswalks)
	# Phía Bắc (North Crosswalk)
	for cx in range(27, 35):
		road_layer.set_cell(Vector2i(cx, 25), 0, Vector2i(cx, 28))
	# Phía Nam (South Crosswalk)
	for cx in range(27, 35):
		road_layer.set_cell(Vector2i(cx, 36), 0, Vector2i(cx, 42))
	# Phía Tây (West Crosswalk)
	for cy in range(27, 35):
		road_layer.set_cell(Vector2i(25, cy), 0, Vector2i(22, cy))
	# Phía Đông (East Crosswalk)
	for cy in range(27, 35):
		road_layer.set_cell(Vector2i(36, cy), 0, Vector2i(37, cy))
		
	# 8. Bãi đỗ xe ô tô chữ P (Parking Bays) tại góc Đông Nam (x: 38..48, y: 38..45)
	for py in range(7):
		for px in range(10):
			road_layer.set_cell(Vector2i(38 + px, 38 + py), 0, Vector2i(39 + px, 48 + py))
			
	# 9. Làn đường xe buýt (Bus Lane) tại góc Tây Nam (x: 12..24, y: 38..48)
	for by in range(11):
		for bx in range(13):
			road_layer.set_cell(Vector2i(12 + bx, 38 + by), 0, Vector2i(bx, 38 + by))
			
	# 10. Mũi tên chỉ hướng trên đường (Road Arrows)
	decoration_layer.set_cell(Vector2i(29, 21), 0, Vector2i(41, 23)) # Mũi tên đi thẳng
	decoration_layer.set_cell(Vector2i(32, 21), 0, Vector2i(44, 23)) # Mũi tên rẽ
	decoration_layer.set_cell(Vector2i(29, 40), 0, Vector2i(41, 23))
	decoration_layer.set_cell(Vector2i(32, 40), 0, Vector2i(44, 23))
	
	# 11. Cây hoa trang trí trên bãi cỏ
	var flower_positions = [
		Vector2i(3, 3), Vector2i(6, 2), Vector2i(20, 2), Vector2i(22, 5),
		Vector2i(40, 3), Vector2i(55, 3), Vector2i(56, 16), Vector2i(40, 20),
		Vector2i(3, 40), Vector2i(5, 52), Vector2i(50, 50), Vector2i(55, 55)
	]
	for f_pos in flower_positions:
		decoration_layer.set_cell(f_pos, 0, Vector2i(56, 13)) # Cỏ hoa


## Đóng dấu một hình chữ nhật bằng các khối autotile 3x3
func _stamp_autotile_rect(layer: TileMapLayer, pos: Vector2i, size: Vector2i, atlas_3x3: Vector2i) -> void:
	for dy in range(size.y):
		for dx in range(size.x):
			var src_x = atlas_3x3.x + (0 if dx == 0 else (2 if dx == size.x - 1 else 1))
			var src_y = atlas_3x3.y + (0 if dy == 0 else (2 if dy == size.y - 1 else 1))
			layer.set_cell(pos + Vector2i(dx, dy), 0, Vector2i(src_x, src_y))


## Thêm NPC, Phương tiện và Tòa nhà vào bản đồ thế giới
func _spawn_sample_entities() -> void:
	# Dọn dẹp entities cũ nếu có
	for c in entities.get_children():
		c.queue_free()
		
	# 1. Thêm Tòa nhà mẫu bên lề đường
	var bld_res: Resource = null
	if has_node("/root/BuildingRegistry"):
		bld_res = get_node("/root/BuildingRegistry").get_building_data(&"bld_001")
	if not bld_res and ResourceLoader.exists("res://data/buildings/bld_001.tres"):
		bld_res = load("res://data/buildings/bld_001.tres")
		
	if bld_res:
		var bld_scene = load("res://scenes/buildings/BuildingBase.tscn")
		var bld_node = bld_scene.instantiate()
		bld_node.set("building_data", bld_res)
		# Đặt tòa nhà tại lề đường phía Đông Bắc
		bld_node.position = Vector2(620, 320)
		entities.add_child(bld_node)
		print("Đã đặt tòa nhà: %s tại %s" % [bld_res.get("display_name"), bld_node.position])
	
	# 2. Thêm Xe cộ mẫu đỗ trong bãi đỗ xe
	var veh_res: Resource = null
	if has_node("/root/VehicleRegistry"):
		veh_res = get_node("/root/VehicleRegistry").get_vehicle_data(&"veh_016")
	if not veh_res and ResourceLoader.exists("res://data/vehicles/veh_016.tres"):
		veh_res = load("res://data/vehicles/veh_016.tres")
	elif not veh_res and ResourceLoader.exists("res://data/vehicles/veh_001.tres"):
		veh_res = load("res://data/vehicles/veh_001.tres")
		
	if veh_res:
		var veh_scene = load("res://scenes/vehicles/VehicleBase.tscn")
		var veh_node = veh_scene.instantiate()
		veh_node.set("vehicle_data", veh_res)
		# Đặt trong ô đỗ xe
		veh_node.position = Vector2(700, 680)
		entities.add_child(veh_node)
		print("Đã đặt phương tiện: %s tại %s" % [veh_res.get("display_name"), veh_node.position])
		
	# 3. Thêm NPC đi dạo trên vỉa hè
	var npc_res: Resource = null
	if has_node("/root/NPCRegistry"):
		npc_res = get_node("/root/NPCRegistry").get_npc_data(&"npc_001")
	if not npc_res and ResourceLoader.exists("res://data/npcs/citizen_male_01.tres"):
		npc_res = load("res://data/npcs/citizen_male_01.tres")
		
	if npc_res:
		var npc_scene = load("res://scenes/characters/NPCBase.tscn")
		var npc_node = npc_scene.instantiate()
		npc_node.set("npc_data", npc_res)
		# Đặt trên vỉa hè phía Tây
		npc_node.position = Vector2(400, 390)
		entities.add_child(npc_node)
		print("Đã đặt NPC: %s tại %s" % [npc_res.get("display_name"), npc_node.position])
