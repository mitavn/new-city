extends SceneTree

## Script biên dịch và tạo sẵn màn Test Scene Bến Tàu Thượng Hải 2000 (.tscn)
## để toàn bộ TileMapLayer, Tòa nhà, Xe cộ, Tàu thuyền và NPC hiển thị đầy đủ trong Editor.
## Cho phép người dùng kéo thả, di chuyển trực tiếp trên viewport 2D của Godot.

func _init() -> void:
	print("--- BẮT ĐẦU TẠO SCENE BẾN CẢNG THƯỢNG HẢI TRỰC QUAN TRONG EDITOR ---")

	var root_node = Node2D.new()
	root_node.name = "ShanghaiHarborTestScene"
	var scene_script = load("res://scenes/test/shanghai_harbor_test_scene.gd")
	root_node.set_script(scene_script)

	var city_tileset = load("res://data/tilesets/city_tileset.tres")
	var deco_tileset = load("res://tilesets/decoration.tres")

	# 1. TileMapRoot & Layers
	var tilemap_root = Node2D.new()
	tilemap_root.name = "TileMapRoot"
	root_node.add_child(tilemap_root)

	var ground_layer = TileMapLayer.new()
	ground_layer.name = "GroundLayer"
	ground_layer.tile_set = city_tileset
	tilemap_root.add_child(ground_layer)

	var road_layer = TileMapLayer.new()
	road_layer.name = "RoadLayer"
	road_layer.z_index = 1
	road_layer.tile_set = city_tileset
	tilemap_root.add_child(road_layer)

	var deco_layer = TileMapLayer.new()
	deco_layer.name = "DecorationLayer"
	deco_layer.z_index = 2
	deco_layer.tile_set = deco_tileset
	tilemap_root.add_child(deco_layer)

	# Tô các ô gạch bản đồ bến cảng
	_generate_tiles(ground_layer, road_layer, deco_layer)

	# 2. Entities container
	var entities_node = Node2D.new()
	entities_node.name = "Entities"
	entities_node.z_index = 3
	entities_node.y_sort_enabled = true
	root_node.add_child(entities_node)

	# 3. Tạo Player (NPC 001 - Sĩ quan Cảnh sát) với Camera2D bám theo
	var npc_base_scene = load("res://scenes/characters/NPCBase.tscn")
	var veh_base_scene = load("res://scenes/vehicles/VehicleBase.tscn")
	var bld_base_scene = load("res://scenes/buildings/BuildingBase.tscn")
	var player_script = load("res://scenes/test/player_npc_controller.gd")

	var player = npc_base_scene.instantiate()
	player.name = "Player_Officer_ID01"
	player.set_script(player_script)
	player.data = load("res://data/npcs/police_male_01.tres")
	player.position = Vector2(400, 320)
	player.add_to_group(&"player")
	player.add_to_group(&"npcs")

	# Camera2D đặt ngay bên trong Player để luôn bám sát theo người chơi
	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.zoom = Vector2(2, 2)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)
	entities_node.add_child(player)

	# 4. Tàu thuyền
	_add_vehicle(entities_node, veh_base_scene, "ShipFerry_HoangPho", "res://data/vehicles/ship_ferry_01.tres", Vector2(250, 560), "front_right", false)
	_add_vehicle(entities_node, veh_base_scene, "ShipTrade_VienDuong", "res://data/vehicles/ship_trade_01.tres", Vector2(700, 580), "front_left", false)
	_add_vehicle(entities_node, veh_base_scene, "PatrolBoat_Cano", "res://data/vehicles/boat_small_01.tres", Vector2(470, 680), "front_right", true)

	# 5. Xe cộ trên cảng
	_add_vehicle(entities_node, veh_base_scene, "PoliceCar_TuanTra", "res://data/vehicles/police_car_01.tres", Vector2(320, 310), "front_right", false)
	_add_vehicle(entities_node, veh_base_scene, "Bulldozer_BaiHang", "res://data/vehicles/bulldozer_01.tres", Vector2(820, 310), "front_left", false)
	_add_vehicle(entities_node, veh_base_scene, "TaxiYellow_ThuongHai", "res://data/vehicles/taxi_yellow_01.tres", Vector2(160, 220), "front_right", false)
	_add_vehicle(entities_node, veh_base_scene, "FoodTruck_LuuDong", "res://data/vehicles/foodtruck_moving_01.tres", Vector2(530, 230), "front_left", false)

	# 6. Tòa nhà bến cảng
	_add_building(entities_node, bld_base_scene, "Bld_Lighthouse", "res://data/buildings/lighthouse_01.tres", Vector2(1020, 480))
	_add_building(entities_node, bld_base_scene, "Bld_CustomsOffice", "res://data/buildings/portable_office_01.tres", Vector2(380, 230))
	_add_building(entities_node, bld_base_scene, "Bld_PoliceStation", "res://data/buildings/police_station_01.tres", Vector2(450, 80))
	_add_building(entities_node, bld_base_scene, "Bld_TheBundBank", "res://data/buildings/bank_central_01.tres", Vector2(180, 80))
	_add_building(entities_node, bld_base_scene, "Bld_WoodWarehouse", "res://data/buildings/wood_building_01.tres", Vector2(720, 80))
	_add_building(entities_node, bld_base_scene, "Bld_SailorPub", "res://data/buildings/bar_pub_01.tres", Vector2(940, 80))
	_add_building(entities_node, bld_base_scene, "Bld_RamenStand", "res://data/buildings/ramen_stand_01.tres", Vector2(610, 220))

	# 7. NPC đời sống bến cảng
	_add_npc(entities_node, npc_base_scene, "NPC_ID03_AnhTuan", "res://data/npcs/construction_male_01.tres", Vector2(760, 340))
	_add_npc(entities_node, npc_base_scene, "NPC_ID04_ChiHoa", "res://data/npcs/construction_female_01.tres", Vector2(860, 320))
	_add_npc(entities_node, npc_base_scene, "NPC_ID13_AnhNam", "res://data/npcs/delivery_male_01.tres", Vector2(680, 280))
	_add_npc(entities_node, npc_base_scene, "NPC_ID15_OngTu", "res://data/npcs/senior_male_01.tres", Vector2(210, 330))
	_add_npc(entities_node, npc_base_scene, "NPC_ID23_AnhBinh", "res://data/npcs/citizen_male_02.tres", Vector2(260, 320))
	_add_npc(entities_node, npc_base_scene, "NPC_ID22_ChiTam", "res://data/npcs/citizen_female_01.tres", Vector2(480, 290))

	# 8. HUD Layer
	_build_hud(root_node)

	# Thiết lập owner cho tất cả các node để Pack thành công
	_set_owner_recursive(root_node, root_node)

	var packed_scene = PackedScene.new()
	var pack_result = packed_scene.pack(root_node)
	if pack_result != OK:
		push_error("Lỗi đóng gói scene: " + str(pack_result))
		quit(1)
		return

	var save_path = "res://scenes/test/shanghai_harbor_test_scene.tscn"
	var save_result = ResourceSaver.save(packed_scene, save_path)
	if save_result == OK:
		print("✓ Đã lưu thành công scene: ", save_path)
	else:
		push_error("Lỗi lưu scene: " + str(save_result))
		quit(1)
		return

	quit(0)


func _generate_tiles(ground: TileMapLayer, road: TileMapLayer, deco: TileMapLayer) -> void:
	var w = 72
	var h = 48
	# Nền đá lát cảng
	for y in range(h):
		for x in range(w):
			ground.set_cell(Vector2i(x, y), 0, Vector2i(44, 8))

	# Đường nhựa đại lộ
	for y in range(6, 12):
		for x in range(w):
			road.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))
			if y in [8, 9] and x % 3 == 0:
				deco.set_cell(Vector2i(x, y), 0, Vector2i(20, 38))

	# Vạch sang đường
	for cx in range(24, 28):
		for cy in range(6, 12):
			road.set_cell(Vector2i(cx, cy), 0, Vector2i(39, 48))
	for cx in range(44, 48):
		for cy in range(6, 12):
			road.set_cell(Vector2i(cx, cy), 0, Vector2i(39, 48))

	# Mặt nước sông Hoàng Phố
	for y in range(26, h):
		for x in range(w):
			var is_jetty = (x >= 58 and x <= 71 and y <= 38)
			if not is_jetty:
				ground.set_cell(Vector2i(x, y), 0, Vector2i(41, 13))

	# Bờ kè đá giáp sông
	for x in range(w):
		if not (x >= 58 and x <= 71):
			road.set_cell(Vector2i(x, 25), 0, Vector2i(15, 27))
			if x % 4 == 0:
				deco.set_cell(Vector2i(x, 25), 0, Vector2i(26, 30))

	# Mũi đê ngọn hải đăng
	for ly in range(26, 39):
		road.set_cell(Vector2i(57, ly), 0, Vector2i(15, 27))
	for lx in range(58, 72):
		road.set_cell(Vector2i(lx, 38), 0, Vector2i(15, 27))

	# Bãi hàng hóa
	for cy in range(14, 25):
		for cx in range(48, 57):
			road.set_cell(Vector2i(cx, cy), 0, Vector2i(31, 38))

	# Props trang trí
	var deco_props = [
		Vector2i(50, 16), Vector2i(51, 16), Vector2i(52, 17), Vector2i(54, 18),
		Vector2i(50, 21), Vector2i(51, 21), Vector2i(55, 22),
		Vector2i(10, 4), Vector2i(20, 4), Vector2i(35, 4), Vector2i(50, 4), Vector2i(65, 4),
		Vector2i(12, 13), Vector2i(28, 13), Vector2i(42, 13), Vector2i(60, 27)
	]
	for dp in deco_props:
		deco.set_cell(dp, 0, Vector2i(18, 30))


func _add_vehicle(parent: Node, base_scene: PackedScene, name_str: String, res_path: String, pos: Vector2, facing: String, siren: bool) -> void:
	var inst = base_scene.instantiate()
	inst.name = name_str
	inst.data = load(res_path)
	inst.position = pos
	inst.facing_direction_name = facing
	if "siren_active" in inst:
		inst.siren_active = siren
	inst.add_to_group(&"vehicles")
	parent.add_child(inst)


func _add_building(parent: Node, base_scene: PackedScene, name_str: String, res_path: String, pos: Vector2) -> void:
	var inst = base_scene.instantiate()
	inst.name = name_str
	inst.data = load(res_path)
	inst.position = pos
	inst.add_to_group(&"buildings")
	parent.add_child(inst)


func _add_npc(parent: Node, base_scene: PackedScene, name_str: String, res_path: String, pos: Vector2) -> void:
	var inst = base_scene.instantiate()
	inst.name = name_str
	inst.data = load(res_path)
	inst.position = pos
	inst.auto_wander = true
	inst.add_to_group(&"npcs")
	parent.add_child(inst)


func _build_hud(root: Node2D) -> void:
	var hud = CanvasLayer.new()
	hud.name = "HUD"
	root.add_child(hud)

	var ui_root = Control.new()
	ui_root.name = "UIRoot"
	ui_root.layout_mode = 3
	ui_root.anchors_preset = Control.PRESET_FULL_RECT
	ui_root.anchor_right = 1.0
	ui_root.anchor_bottom = 1.0
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(ui_root)

	# Top Panel
	var top_panel = PanelContainer.new()
	top_panel.name = "TopPanel"
	top_panel.offset_left = 16.0
	top_panel.offset_top = 16.0
	top_panel.offset_right = 530.0
	top_panel.offset_bottom = 165.0
	var style_top = StyleBoxFlat.new()
	style_top.bg_color = Color(0.08, 0.1, 0.14, 0.88)
	style_top.border_color = Color(0.78, 0.84, 0.92, 0.95)
	style_top.set_border_width_all(2)
	style_top.set_corner_radius_all(8)
	style_top.content_margin_left = 16.0
	style_top.content_margin_top = 12.0
	style_top.content_margin_right = 16.0
	style_top.content_margin_bottom = 12.0
	top_panel.add_theme_stylebox_override("panel", style_top)
	ui_root.add_child(top_panel)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	top_panel.add_child(vbox)

	var lbl_hdr = Label.new()
	lbl_hdr.name = "LblHeader"
	lbl_hdr.unique_name_in_owner = true
	lbl_hdr.text = "⚓ BẾN TÀU THƯỢNG HẢI NĂM 2000 (SHANGHAI HARBOR)"
	lbl_hdr.add_theme_color_override("font_color", Color(0.88, 0.93, 0.98, 1))
	lbl_hdr.add_theme_font_size_override("font_size", 15)
	vbox.add_child(lbl_hdr)

	var lbl_sub = Label.new()
	lbl_sub.name = "LblSub"
	lbl_sub.text = "Nhân vật: Sĩ quan Cảnh sát Cảng (ID01-Anh Tâm)"
	lbl_sub.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 1))
	lbl_sub.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_sub)

	var lbl_ctrl = Label.new()
	lbl_ctrl.name = "LblControls"
	lbl_ctrl.unique_name_in_owner = true
	lbl_ctrl.text = "🎮 WASD / Mũi tên: Di chuyển | Giữ Shift: Chạy nhanh\n💬 Phím E / Space: Tương tác biểu cảm (Emote), Còi xe, Cửa nhà\n🔍 Camera luôn bám sát theo người chơi (Camera2D)"
	lbl_ctrl.add_theme_color_override("font_color", Color(0.7, 0.82, 0.88, 1))
	lbl_ctrl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_ctrl)

	var lbl_pos = Label.new()
	lbl_pos.name = "LblPlayerPos"
	lbl_pos.unique_name_in_owner = true
	lbl_pos.text = "Vị trí Sĩ quan: (400, 320)"
	lbl_pos.add_theme_color_override("font_color", Color(0.55, 0.75, 0.9, 1))
	lbl_pos.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_pos)

	var btn_reset = Button.new()
	btn_reset.name = "BtnResetPlayer"
	btn_reset.unique_name_in_owner = true
	btn_reset.text = "Đưa Sĩ Quan Về Trạm (R)"
	vbox.add_child(btn_reset)

	# Dialogue Panel
	var dlg_panel = PanelContainer.new()
	dlg_panel.name = "DialoguePanel"
	dlg_panel.unique_name_in_owner = true
	dlg_panel.layout_mode = 1
	dlg_panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	dlg_panel.anchor_left = 0.5
	dlg_panel.anchor_top = 1.0
	dlg_panel.anchor_right = 0.5
	dlg_panel.anchor_bottom = 1.0
	dlg_panel.offset_left = -580.0
	dlg_panel.offset_top = -120.0
	dlg_panel.offset_right = 580.0
	dlg_panel.offset_bottom = -24.0
	dlg_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dlg_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style_dlg = StyleBoxFlat.new()
	style_dlg.bg_color = Color(0.08, 0.1, 0.14, 0.94)
	style_dlg.border_color = Color(0.8, 0.85, 0.92, 0.98)
	style_dlg.set_border_width_all(2)
	style_dlg.set_corner_radius_all(8)
	style_dlg.content_margin_left = 32.0
	style_dlg.content_margin_top = 14.0
	style_dlg.content_margin_right = 32.0
	style_dlg.content_margin_bottom = 14.0
	dlg_panel.add_theme_stylebox_override("panel", style_dlg)
	ui_root.add_child(dlg_panel)

	var vbox_dlg = VBoxContainer.new()
	vbox_dlg.name = "VBoxDialogue"
	dlg_panel.add_child(vbox_dlg)

	var lbl_spk = Label.new()
	lbl_spk.name = "LblSpeaker"
	lbl_spk.unique_name_in_owner = true
	lbl_spk.text = "ID01-Anh Tâm:"
	lbl_spk.add_theme_color_override("font_color", Color(0.82, 0.88, 0.96, 1))
	lbl_spk.add_theme_font_size_override("font_size", 12)
	vbox_dlg.add_child(lbl_spk)

	var lbl_cnt = Label.new()
	lbl_cnt.name = "LblDialogueContent"
	lbl_cnt.unique_name_in_owner = true
	lbl_cnt.text = "Bến tàu Thượng Hải hôm nay bình yên, các chuyến tàu ra vào cảng ổn định."
	lbl_cnt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_cnt.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98, 1))
	lbl_cnt.add_theme_font_size_override("font_size", 11)
	vbox_dlg.add_child(lbl_cnt)


func _set_owner_recursive(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		_set_owner_recursive(child, owner_root)
