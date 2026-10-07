extends SceneTree

func _init() -> void:
	print("--- TẠO SCENE MAP TEST SCENE ---")
	var tileset = load("res://data/tilesets/city_tileset.tres")
	assert(tileset != null, "Không tìm thấy res://data/tilesets/city_tileset.tres")
	
	var root = Node2D.new()
	root.name = "MapTestScene"
	root.set_script(load("res://scenes/test/map_test_scene.gd"))
	
	# 1. MapManager
	var map_mgr = Node2D.new()
	map_mgr.name = "MapManager"
	map_mgr.set_script(load("res://scripts/world/city_map_manager.gd"))
	map_mgr.set("tile_set", tileset)
	root.add_child(map_mgr)
	map_mgr.owner = root
	
	# GroundLayer
	var ground = TileMapLayer.new()
	ground.name = "GroundLayer"
	ground.tile_set = tileset
	map_mgr.add_child(ground)
	ground.owner = root
	
	# RoadLayer
	var road = TileMapLayer.new()
	road.name = "RoadLayer"
	road.tile_set = tileset
	road.z_index = 1
	map_mgr.add_child(road)
	road.owner = root
	
	# DecorationLayer
	var deco = TileMapLayer.new()
	deco.name = "DecorationLayer"
	deco.tile_set = tileset
	deco.z_index = 2
	map_mgr.add_child(deco)
	deco.owner = root
	
	# 2. Entities
	var entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	entities.z_index = 3
	root.add_child(entities)
	entities.owner = root
	
	# 3. Camera2D
	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.position = Vector2(480, 480)
	cam.zoom = Vector2(2.0, 2.0)
	root.add_child(cam)
	cam.owner = root
	
	# 4. CanvasLayer (HUD)
	var canvas = CanvasLayer.new()
	canvas.name = "HUD"
	root.add_child(canvas)
	canvas.owner = root
	
	var ui_root = Control.new()
	ui_root.name = "UIRoot"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui_root)
	ui_root.owner = root
	
	# Top Left Title Card
	var title_panel = PanelContainer.new()
	title_panel.name = "TitlePanel"
	title_panel.position = Vector2(20, 20)
	title_panel.custom_minimum_size = Vector2(360, 80)
	ui_root.add_child(title_panel)
	title_panel.owner = root
	
	var title_vbox = VBoxContainer.new()
	title_panel.add_child(title_vbox)
	title_vbox.owner = root
	
	var lbl_title = Label.new()
	lbl_title.text = "🌆 THÀNH PHỐ MỚI - BẢN ĐỒ TILESET"
	lbl_title.add_theme_font_size_override("font_size", 18)
	lbl_title.add_theme_color_override("font_color", Color("#f0e68c"))
	title_vbox.add_child(lbl_title)
	lbl_title.owner = root
	
	var lbl_sub = Label.new()
	lbl_sub.text = "Godot 4.7 TileMapLayer | Autotile 3x3 | 3.059 Tiles"
	lbl_sub.add_theme_font_size_override("font_size", 13)
	lbl_sub.add_theme_color_override("font_color", Color("#b0b0b0"))
	title_vbox.add_child(lbl_sub)
	lbl_sub.owner = root
	
	# Top Right Control Panel
	var ctrl_panel = PanelContainer.new()
	ctrl_panel.name = "ControlPanel"
	ctrl_panel.anchor_left = 1.0
	ctrl_panel.anchor_right = 1.0
	ctrl_panel.offset_left = -320
	ctrl_panel.offset_top = 20
	ctrl_panel.offset_right = -20
	ctrl_panel.offset_bottom = 260
	ui_root.add_child(ctrl_panel)
	ctrl_panel.owner = root
	
	var ctrl_vbox = VBoxContainer.new()
	ctrl_panel.add_child(ctrl_vbox)
	ctrl_vbox.owner = root
	
	var lbl_layers_title = Label.new()
	lbl_layers_title.text = "⚙️ QUẢN LÝ LỚP BẢN ĐỒ"
	lbl_layers_title.add_theme_font_size_override("font_size", 15)
	lbl_layers_title.add_theme_color_override("font_color", Color("#87cefa"))
	ctrl_vbox.add_child(lbl_layers_title)
	lbl_layers_title.owner = root
	
	var chk_ground = CheckBox.new()
	chk_ground.name = "ChkGround"
	chk_ground.unique_name_in_owner = true
	chk_ground.text = "Lớp Mặt Đất (Ground)"
	chk_ground.button_pressed = true
	ctrl_vbox.add_child(chk_ground)
	chk_ground.owner = root
	
	var chk_road = CheckBox.new()
	chk_road.name = "ChkRoad"
	chk_road.unique_name_in_owner = true
	chk_road.text = "Lớp Đường & Vỉa Hè (Roads)"
	chk_road.button_pressed = true
	ctrl_vbox.add_child(chk_road)
	chk_road.owner = root
	
	var chk_deco = CheckBox.new()
	chk_deco.name = "ChkDeco"
	chk_deco.unique_name_in_owner = true
	chk_deco.text = "Lớp Trang Trí (Decorations)"
	chk_deco.button_pressed = true
	ctrl_vbox.add_child(chk_deco)
	chk_deco.owner = root
	
	var chk_ent = CheckBox.new()
	chk_ent.name = "ChkEntities"
	chk_ent.unique_name_in_owner = true
	chk_ent.text = "Thực thể (NPC / Xe / Nhà)"
	chk_ent.button_pressed = true
	ctrl_vbox.add_child(chk_ent)
	chk_ent.owner = root
	
	var btn_reset_cam = Button.new()
	btn_reset_cam.name = "BtnResetCam"
	btn_reset_cam.unique_name_in_owner = true
	btn_reset_cam.text = "🎯 Đặt lại Camera (Trung tâm)"
	ctrl_vbox.add_child(btn_reset_cam)
	btn_reset_cam.owner = root
	
	var btn_regen = Button.new()
	btn_regen.name = "BtnRegen"
	btn_regen.unique_name_in_owner = true
	btn_regen.text = "🔄 Vẽ lại bản đồ mẫu"
	ctrl_vbox.add_child(btn_regen)
	btn_regen.owner = root
	
	var lbl_help = Label.new()
	lbl_help.text = "WASD/Chuột phải: Cuộn\nCon lăn chuột: Phóng to/thu nhỏ"
	lbl_help.add_theme_font_size_override("font_size", 12)
	lbl_help.add_theme_color_override("font_color", Color("#888888"))
	ctrl_vbox.add_child(lbl_help)
	lbl_help.owner = root
	
	# Bottom Left Inspector Panel
	var insp_panel = PanelContainer.new()
	insp_panel.name = "InspectorPanel"
	insp_panel.anchor_top = 1.0
	insp_panel.anchor_bottom = 1.0
	insp_panel.offset_left = 20
	insp_panel.offset_top = -170
	insp_panel.offset_right = 440
	insp_panel.offset_bottom = -20
	ui_root.add_child(insp_panel)
	insp_panel.owner = root
	
	var insp_vbox = VBoxContainer.new()
	insp_panel.add_child(insp_vbox)
	insp_vbox.owner = root
	
	var lbl_insp_title = Label.new()
	lbl_insp_title.name = "LblHoverInfo"
	lbl_insp_title.unique_name_in_owner = true
	lbl_insp_title.text = "🔍 THÔNG TIN Ô TILE DƯỚI CON TRỎ"
	lbl_insp_title.add_theme_font_size_override("font_size", 14)
	lbl_insp_title.add_theme_color_override("font_color", Color("#98fb98"))
	insp_vbox.add_child(lbl_insp_title)
	lbl_insp_title.owner = root
	
	var lbl_coords = Label.new()
	lbl_coords.name = "LblCoords"
	lbl_coords.unique_name_in_owner = true
	lbl_coords.text = "Tọa độ: (0, 0) | Thế giới: (0, 0)"
	insp_vbox.add_child(lbl_coords)
	lbl_coords.owner = root
	
	var lbl_surface = Label.new()
	lbl_surface.name = "LblSurface"
	lbl_surface.unique_name_in_owner = true
	lbl_surface.text = "Bề mặt: ROAD"
	insp_vbox.add_child(lbl_surface)
	lbl_surface.owner = root
	
	var lbl_speed = Label.new()
	lbl_speed.name = "LblSpeed"
	lbl_speed.unique_name_in_owner = true
	lbl_speed.text = "Hệ số tốc độ: 1.00x"
	insp_vbox.add_child(lbl_speed)
	lbl_speed.owner = root
	
	var lbl_flags = Label.new()
	lbl_flags.name = "LblFlags"
	lbl_flags.unique_name_in_owner = true
	lbl_flags.text = "Cờ: [Đường Xe]"
	insp_vbox.add_child(lbl_flags)
	lbl_flags.owner = root
	
	# Lưu PackedScene
	var scene = PackedScene.new()
	scene.pack(root)
	var err = ResourceSaver.save(scene, "res://scenes/test/map_test_scene.tscn")
	print("Lưu scenes/test/map_test_scene.tscn kết quả: ", err)
	quit()
