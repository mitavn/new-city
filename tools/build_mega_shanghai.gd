extends SceneTree

## Script Dựng Bản Đồ Siêu Đô Thị Bến Cảng Thượng Hải (Shanghai Mega Metropolis & Harbor)
## Kích thước lớn: 110 x 70 tiles (1760 x 1120 pixels)
## Tích hợp toàn bộ kiến trúc & cảnh quan tinh tế từ 5 bức ảnh demo của City Asset Pack:
## 1. Đại lộ mua sắm Kim Mậu & Trung tâm thương mại Mall khổng lồ (vệ sĩ, ATM, taxi zone, đèn giao thông)
## 2. Phố ẩm thực & dịch vụ (Cafe tách cafe to, Bakery mái hiên sọc, Burger bánh burger to, Barbershop cột xoay)
## 3. Khu công viên đài phun nước cẩm thạch bờ sông (Torii gate, ghế đá, bốt điện thoại Anh đỏ, máy bán nước)
## 4. Bờ kè bến phà Hoàng Phố & Ẩm thực Á Đông (quán Sushi lồng đèn, quầy mì Ramen tô to, hải đăng cổ kính)
## 5. Đội tàu thuyền viễn dương & ca-nô tuần tra rẽ sóng trên sông Hoàng Phố
## 6. Đầy đủ 25+ NPC sinh động & xe cộ tuần tra/taxi/cứu thương/cứu hỏa/food truck

const MAP_W: int = 110
const MAP_H: int = 70

func _init() -> void:
	print("==================================================================")
	print("🏗️ BẮT ĐẦU DỰNG BẢN ĐỒ SIÊU ĐÔ THỊ BẾN CẢNG THƯỢNG HẢI (110x70 TILES)...")
	print("==================================================================")

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

	# 2. Xây dựng toàn bộ địa hình gạch bản đồ
	_build_terrain_tiles(ground_layer, road_layer, deco_layer)

	# 3. Entities container (Y-Sort)
	var entities_node = Node2D.new()
	entities_node.name = "Entities"
	entities_node.z_index = 3
	entities_node.y_sort_enabled = true
	root_node.add_child(entities_node)

	var npc_base_scene = load("res://scenes/characters/NPCBase.tscn")
	var veh_base_scene = load("res://scenes/vehicles/VehicleBase.tscn")
	var bld_base_scene = load("res://scenes/buildings/BuildingBase.tscn")
	var player_script = load("res://scenes/test/player_npc_controller.gd")

	# 4. Người chơi (Sĩ quan Cảnh sát Cảng ID01-Anh Tâm)
	var player = npc_base_scene.instantiate()
	player.name = "Player_Officer_ID01"
	player.set_script(player_script)
	player.data = load("res://data/npcs/police_male_01.tres")
	player.position = Vector2(420, 480)
	player.add_to_group(&"player")
	player.add_to_group(&"npcs")

	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.zoom = Vector2(1.8, 1.8)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)
	entities_node.add_child(player)

	# 5. Dựng toàn bộ các Tòa nhà kiến trúc thành phố (Buildings)
	_spawn_all_buildings(entities_node, bld_base_scene)

	# 6. Dựng toàn bộ Xe cộ & Tàu thuyền (Vehicles & Ships)
	_spawn_all_vehicles(entities_node, veh_base_scene)

	# 7. Dựng dàn NPC cư dân sống động (NPCs)
	_spawn_all_npcs(entities_node, npc_base_scene)

	# 8. HUD Layer
	_build_hud(root_node)

	# 9. Đóng gói & Lưu Scene
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
		print("✅ ĐÃ LƯU THÀNH CÔNG BẢN ĐỒ SIÊU ĐÔ THỊ THƯỢNG HẢI: ", save_path)
	else:
		push_error("Lỗi lưu scene: " + str(save_result))
		quit(1)
		return

	quit(0)


# ==============================================================================
# 1. XÂY DỰNG TOÀN BỘ GẠCH BẢN ĐỒ (GROUND, ROAD, DECORATION)
# ==============================================================================
func _build_terrain_tiles(ground: TileMapLayer, road: TileMapLayer, deco: TileMapLayer) -> void:
	# A. Nền đất liền (Cobblestone) toàn bộ bản đồ
	for y in range(MAP_H):
		for x in range(MAP_W):
			ground.set_cell(Vector2i(x, y), 0, Vector2i(44, 8))

	# B. Vùng cây xanh & công viên phía Bắc (Rows 0..6)
	for y in range(0, 6):
		for x in range(MAP_W):
			# Nền cỏ xanh phía trên
			ground.set_cell(Vector2i(x, y), 0, Vector2i(42, 22))

	# C. Đại Lộ Hoàng Phố 8 Làn (Grand Boulevard: Rows 19..28)
	for y in range(19, 29):
		for x in range(MAP_W):
			# Mặt đường nhựa đen bóng
			road.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))
			# Vạch vàng dải phân cách ở giữa (Row 23)
			if y == 23 and x % 2 == 0:
				deco.set_cell(Vector2i(x, y), 0, Vector2i(21, 38))
			# Vạch trắng phân làn (Row 21 & Row 26)
			elif (y == 21 or y == 26) and x % 3 == 0:
				deco.set_cell(Vector2i(x, y), 0, Vector2i(20, 38))

	# 3 Cụm Vạch Sang Đường Cho Người Đi Bộ (Zebra Crosswalks)
	var crosswalk_x_ranges = [[18, 22], [52, 56], [84, 88]]
	for r in crosswalk_x_ranges:
		for cx in range(r[0], r[1] + 1):
			for cy in range(19, 29):
				road.set_cell(Vector2i(cx, cy), 0, Vector2i(39, 48))

	# Nắp cống kim loại & rãnh thoát nước dọc mép đại lộ
	for x in range(4, MAP_W - 4, 8):
		deco.set_cell(Vector2i(x, 19), 0, Vector2i(34, 38))
		deco.set_cell(Vector2i(x + 4, 28), 0, Vector2i(34, 38))

	# D. Khu vực Sông Hoàng Phố (Water: Rows 48..69)
	for y in range(48, MAP_H):
		for x in range(MAP_W):
			var is_pier_jetty = (x >= 88 and x <= 108 and y <= 62)
			if not is_pier_jetty:
				# Nước sông xanh biếc
				ground.set_cell(Vector2i(x, y), 0, Vector2i(41, 13))

	# Bờ kè đá giáp sông (Row 47)
	for x in range(MAP_W):
		if not (x >= 88 and x <= 108):
			road.set_cell(Vector2i(x, 47), 0, Vector2i(15, 27))
			# Hàng rào xích sắt & cột gỗ (Seaside Chain Barrier) chạy dọc mép nước!
			deco.set_cell(Vector2i(x, 47), 0, Vector2i(26, 30))

	# Mũi đê đá ngọn hải đăng (Lighthouse Pier: x=88..108, y=48..62)
	for py in range(48, 63):
		road.set_cell(Vector2i(87, py), 0, Vector2i(15, 27))
		road.set_cell(Vector2i(109, py), 0, Vector2i(15, 27))
	for px in range(88, 109):
		road.set_cell(Vector2i(px, 62), 0, Vector2i(15, 27))
		for py in range(48, 62):
			ground.set_cell(Vector2i(px, py), 0, Vector2i(44, 8))

	# E. Công viên Thảm Cỏ Bờ Sông (Waterfront Park: x=46..72, y=32..44)
	for py in range(32, 45):
		for px in range(46, 73):
			ground.set_cell(Vector2i(px, py), 0, Vector2i(42, 22))

	# Đài phun nước cẩm thạch khổng lồ giữa công viên (x=58..63, y=36..40)
	for dy in range(4):
		for dx in range(5):
			deco.set_cell(Vector2i(58 + dx, 36 + dy), 0, Vector2i(34 + dx, 13 + dy))

	# Cổng Torii đỏ rực rỡ trước cầu tàu (x=30..33, y=44..47)
	for ty in range(4):
		for tx in range(3):
			deco.set_cell(Vector2i(30 + tx, 44 + ty), 0, Vector2i(36 + tx, 23 + ty))

	# Cầu gỗ dẫn ra bến phà từ cổng Torii (x=30..32, y=48..54)
	for py in range(48, 55):
		for px in range(30, 33):
			road.set_cell(Vector2i(px, py), 0, Vector2i(22, 27))

	# F. Đèn đường, cây xanh, thùng rác, ghế đá công viên
	# Hàng cây xanh bóng mát & đèn đường trên vỉa hè Đại lộ
	for x in range(6, MAP_W - 6, 10):
		# Cây xanh vỉa hè
		deco.set_cell(Vector2i(x, 17), 0, Vector2i(14, 10))
		# Đèn đường cổ điển
		deco.set_cell(Vector2i(x + 5, 18), 0, Vector2i(13, 12))
		deco.set_cell(Vector2i(x + 5, 29), 0, Vector2i(13, 12))

	# Ghế đá công viên quanh đài phun nước
	deco.set_cell(Vector2i(54, 38), 0, Vector2i(10, 12))
	deco.set_cell(Vector2i(66, 38), 0, Vector2i(10, 12))
	deco.set_cell(Vector2i(60, 33), 0, Vector2i(10, 12))
	deco.set_cell(Vector2i(60, 42), 0, Vector2i(10, 12))

	# Bàn ghế Cafe ngoài trời trước quán Cafe (x=46..49, y=16..17)
	deco.set_cell(Vector2i(46, 17), 0, Vector2i(10, 10))
	deco.set_cell(Vector2i(48, 17), 0, Vector2i(10, 10))

	# Bãi hàng hóa bến cảng (x=76..86, y=34..46): Thùng hàng container
	for cy in range(34, 46, 3):
		for cx in range(76, 86, 3):
			deco.set_cell(Vector2i(cx, cy), 0, Vector2i(18, 30))
			deco.set_cell(Vector2i(cx + 1, cy), 0, Vector2i(19, 30))


# ==============================================================================
# 2. XẾP ĐẶT TOÀN BỘ CÁC TÒA NHÀ KIẾN TRÚC (BUILDINGS)
# ==============================================================================
func _spawn_all_buildings(parent: Node2D, base_scene: PackedScene) -> void:
	# --- HÀNG 1: ĐẠI LỘ MUA SẮM & TRUNG TÂM THƯƠNG MẠI (Y ~ 100..140) ---
	# 1. Ngân hàng Bến Thượng Hải
	_add_bld(parent, base_scene, "Bld_TheBundBank", "res://data/buildings/bank_central_01.tres", Vector2(120, 110))
	# 2. Trung Tâm Thương Mại Mall Khổng Lồ (Từ Demo 3)
	_add_bld(parent, base_scene, "Bld_CentralMall", "res://data/buildings/mall_shopping_01.tres", Vector2(320, 100))
	# 3. Rạp chiếu phim thành phố
	_add_bld(parent, base_scene, "Bld_CinemaTheater", "res://data/buildings/cinema_theater_01.tres", Vector2(500, 110))
	# 4. Khách sạn Grand Hotel Thượng Hải
	_add_bld(parent, base_scene, "Bld_GrandHotel", "res://data/buildings/hotel_grand_01.tres", Vector2(660, 100))
	# 5. Quán Cafe tách cafe to & bàn ngoài trời (Từ Demo 2)
	_add_bld(parent, base_scene, "Bld_CafeShop", "res://data/buildings/cafe_shop_01.tres", Vector2(800, 120))
	# 6. Tiệm bánh mì Bakery mái hiên sọc (Từ Demo 1 & 2)
	_add_bld(parent, base_scene, "Bld_Bakery", "res://data/buildings/bakery_standard_01.tres", Vector2(940, 120))
	# 7. Quán Burger bánh burger khổng lồ (Từ Demo 4)
	_add_bld(parent, base_scene, "Bld_BurgerShop", "res://data/buildings/burgershop_01.tres", Vector2(1090, 120))
	# 8. Tiệm cắt tóc Barbershop cột xoay (Từ Demo 4)
	_add_bld(parent, base_scene, "Bld_Barbershop", "res://data/buildings/barbershop_01.tres", Vector2(1230, 120))
	# 9. Quán Bar thủy thủ (Từ Demo 1)
	_add_bld(parent, base_scene, "Bld_SailorPub", "res://data/buildings/bar_pub_01.tres", Vector2(1370, 120))
	# 10. Khách sạn Motel biển hiệu dọc (Từ Demo 1)
	_add_bld(parent, base_scene, "Bld_MotelLodge", "res://data/buildings/motel_lodge_01.tres", Vector2(1520, 110))

	# --- HÀNG 2: KHU DỊCH VỤ CÔNG & Y TẾ (Y ~ 480..520) ---
	# 11. Đồn Cảnh Sát Thành Phố
	_add_bld(parent, base_scene, "Bld_PoliceStation", "res://data/buildings/police_station_01.tres", Vector2(140, 490))
	# 12. Trạm Cứu Hỏa Thành Phố
	_add_bld(parent, base_scene, "Bld_FireStation", "res://data/buildings/firestation_01.tres", Vector2(300, 490))
	# 13. Bệnh Viện Đa Khoa Thượng Hải
	_add_bld(parent, base_scene, "Bld_CityHospital", "res://data/buildings/hospital_city_01.tres", Vector2(480, 480))
	# 14. Siêu thị tiện lợi 24/7
	_add_bld(parent, base_scene, "Bld_ConvenientStore", "res://data/buildings/convenient_store_01.tres", Vector2(1260, 490))
	# 15. Kho hàng bến cảng
	_add_bld(parent, base_scene, "Bld_HarborWarehouse", "res://data/buildings/wood_building_01.tres", Vector2(1420, 490))
	# 16. Trạm Hải Quan Bến Tàu
	_add_bld(parent, base_scene, "Bld_CustomsOffice", "res://data/buildings/portable_office_01.tres", Vector2(1560, 490))

	# --- HÀNG 3: KHU ẨM THỰC Á ĐÔNG VEN SÔNG (Y ~ 680) ---
	# 17. Nhà hàng Sushi Nhật Bản lồng đèn đỏ (Từ Demo 5)
	_add_bld(parent, base_scene, "Bld_SushiRestaurant", "res://data/buildings/japanese_restaurant_01.tres", Vector2(360, 680))
	# 18. Quầy mì Ramen tô mì bốc khói (Từ Demo 5)
	_add_bld(parent, base_scene, "Bld_RamenStand", "res://data/buildings/ramen_stand_01.tres", Vector2(680, 680))
	# 19. Ngọn Hải Đăng Bến Cảng Uy Nghi ở Mũi Đê
	_add_bld(parent, base_scene, "Bld_HarborLighthouse", "res://data/buildings/lighthouse_01.tres", Vector2(1580, 920))


# ==============================================================================
# 3. XẾP ĐẶT TOÀN BỘ XE CỘ & TÀU THUYỀN (VEHICLES & SHIPS)
# ==============================================================================
func _spawn_all_vehicles(parent: Node2D, base_scene: PackedScene) -> void:
	# A. Xe Cảnh Sát Tuần Tra trước sảnh Mall (Demo 3)
	_add_veh(parent, base_scene, "PoliceCar_Mall", "res://data/vehicles/police_car_01.tres", Vector2(250, 400), "front_right", false)
	# B. Xe Cảnh Sát trước Đồn Cảnh Sát
	_add_veh(parent, base_scene, "PoliceCar_Station", "res://data/vehicles/police_car_01.tres", Vector2(140, 440), "front_left", false)
	# C. Xe Taxi Xanh đón khách tại Taxi Zone (Demo 4)
	_add_veh(parent, base_scene, "TaxiGreen_Standard", "res://data/vehicles/taxi_standard_01.tres", Vector2(380, 400), "front_right", false)
	# D. Xe Taxi Vàng đón khách trên Đại lộ
	_add_veh(parent, base_scene, "TaxiYellow_Avenue", "res://data/vehicles/taxi_yellow_01.tres", Vector2(1040, 400), "front_left", false)
	# E. Xe Cứu Hỏa đỏ rực trước Trạm Cứu Hỏa
	_add_veh(parent, base_scene, "FireTruck_Rescue", "res://data/vehicles/firetruck_01.tres", Vector2(300, 440), "front_right", false)
	# F. Xe Cấp Cứu trước Bệnh Viện
	_add_veh(parent, base_scene, "Ambulance_Emergency", "res://data/vehicles/ambulance_01.tres", Vector2(480, 440), "front_right", false)
	# G. Xe Bán Thức Ăn Di Động (Food Truck)
	_add_veh(parent, base_scene, "FoodTruck_Snacks", "res://data/vehicles/foodtruck_moving_01.tres", Vector2(650, 400), "front_right", false)
	# H. Xe Bus Thành Phố tại trạm dừng
	_add_veh(parent, base_scene, "CityBus_BundLine", "res://data/vehicles/bus_city_01.tres", Vector2(850, 370), "front_left", false)
	# I. Xe Ủi Hàng Bến Bãi Cảng
	_add_veh(parent, base_scene, "Bulldozer_CargoBay", "res://data/vehicles/bulldozer_01.tres", Vector2(1380, 680), "front_left", false)
	# J. Xe Hơi Dân Sự đủ màu đậu ven đường
	_add_veh(parent, base_scene, "CarBlue_Civilian", "res://data/vehicles/car_blue_01.tres", Vector2(740, 400), "front_right", false)
	_add_veh(parent, base_scene, "CarRed_Civilian", "res://data/vehicles/car_red_01.tres", Vector2(1180, 400), "front_right", false)
	_add_veh(parent, base_scene, "CarBlack_VIP", "res://data/vehicles/car_black_01.tres", Vector2(1480, 400), "front_left", false)

	# K. Đội Tàu Thuyền Sông Hoàng Phố
	# Tàu Phà Khách Cập Bến Cổng Torii
	_add_veh(parent, base_scene, "ShipFerry_HoangPho", "res://data/vehicles/ship_ferry_01.tres", Vector2(500, 880), "front_right", false)
	# Tàu Chở Hàng Viễn Dương neo ngoài luồng cảng
	_add_veh(parent, base_scene, "ShipTrade_VienDuong", "res://data/vehicles/ship_trade_01.tres", Vector2(1120, 920), "front_left", false)
	# Ca-nô Tuần Tra Cảnh Sát Cảng rẽ sóng
	_add_veh(parent, base_scene, "PatrolBoat_Cano", "res://data/vehicles/boat_small_01.tres", Vector2(820, 1020), "front_right", true)


# ==============================================================================
# 4. XẾP ĐẶT 25+ NPC CƯ DÂN & NGHỀ NGHIỆP SINH ĐỘNG (NPCS)
# ==============================================================================
func _spawn_all_npcs(parent: Node2D, base_scene: PackedScene) -> void:
	# A. Hai Vệ Sĩ Áo Vest Đứng Gác Sảnh Mall (Demo 3)
	_add_npc(parent, base_scene, "NPC_ID08_VeSi_Tuan", "res://data/npcs/executive_male_01.tres", Vector2(290, 160), false)
	_add_npc(parent, base_scene, "NPC_ID09_VeSi_Lan", "res://data/npcs/executive_female_01.tres", Vector2(350, 160), false)

	# B. Đầu Bếp Quán Mì Ramen & Sushi Ven Sông (Demo 5)
	_add_npc(parent, base_scene, "NPC_ID10_Chef_DauBepNam", "res://data/npcs/chef_male_01.tres", Vector2(680, 720), false)
	_add_npc(parent, base_scene, "NPC_ID11_Chef_NuSushi", "res://data/npcs/chef_female_01.tres", Vector2(360, 720), false)

	# C. Bác Sĩ & Lính Cứu Hỏa
	_add_npc(parent, base_scene, "NPC_ID12_BacSi_Ha", "res://data/npcs/doctor_female_01.tres", Vector2(520, 520), true)
	_add_npc(parent, base_scene, "NPC_ID14_LinhCuuHoa_Huy", "res://data/npcs/firefighter_male_01.tres", Vector2(330, 520), false)

	# D. Công Nhân & Nhân Viên Bến Cảng
	_add_npc(parent, base_scene, "NPC_ID03_AnhTuan_ThoDien", "res://data/npcs/construction_male_01.tres", Vector2(1360, 720), true)
	_add_npc(parent, base_scene, "NPC_ID04_ChiHoa_KiemHang", "res://data/npcs/construction_female_01.tres", Vector2(1440, 700), true)
	_add_npc(parent, base_scene, "NPC_ID13_AnhNam_GiaoHang", "res://data/npcs/delivery_male_01.tres", Vector2(960, 480), true)

	# E. Cư Dân Thư Thái Tại Công Viên & Quán Cafe
	_add_npc(parent, base_scene, "NPC_ID15_OngTu_NghiMat", "res://data/npcs/senior_male_01.tres", Vector2(920, 590), false)
	_add_npc(parent, base_scene, "NPC_ID16_BaSau_UongCafe", "res://data/npcs/citizen_female_04.tres", Vector2(760, 160), false)

	# F. Cư Dân Đi Dạo & Mua Sắm Dọc Các Tuyến Phố
	_add_npc(parent, base_scene, "NPC_ID20_EmLan_DạoPho", "res://data/npcs/citizen_female_01.tres", Vector2(440, 160), true)
	_add_npc(parent, base_scene, "NPC_ID21_AnhMinh_MuaSam", "res://data/npcs/citizen_male_01.tres", Vector2(600, 160), true)
	_add_npc(parent, base_scene, "NPC_ID22_ChiTam_HanhKhach", "res://data/npcs/citizen_female_02.tres", Vector2(880, 160), true)
	_add_npc(parent, base_scene, "NPC_ID23_AnhBinh_DiBo", "res://data/npcs/citizen_male_02.tres", Vector2(1020, 160), true)
	_add_npc(parent, base_scene, "NPC_ID24_CoMai_VaoTiemToc", "res://data/npcs/citizen_female_03.tres", Vector2(1180, 160), true)
	_add_npc(parent, base_scene, "NPC_ID25_BacHung_ThuyThu", "res://data/npcs/citizen_male_03.tres", Vector2(1320, 160), true)

	# G. Khách Bộ Hành Bờ Kè Hoàng Phố
	_add_npc(parent, base_scene, "NPC_ID26_BanTre_NgamSong_1", "res://data/npcs/citizen_male_04.tres", Vector2(440, 720), true)
	_add_npc(parent, base_scene, "NPC_ID27_BanTre_NgamSong_2", "res://data/npcs/citizen_female_01.tres", Vector2(470, 720), true)
	_add_npc(parent, base_scene, "NPC_ID28_KhachDuLich_HaiDang", "res://data/npcs/citizen_male_01.tres", Vector2(1520, 850), true)


# ==============================================================================
# 5. HÀM HELPER THÊM THỰC THỂ (ENTITIES HELPERS)
# ==============================================================================
func _add_bld(parent: Node, base_scene: PackedScene, name_str: String, res_path: String, pos: Vector2) -> void:
	var inst = base_scene.instantiate()
	inst.name = name_str
	inst.data = load(res_path)
	inst.position = pos
	inst.add_to_group(&"buildings")
	parent.add_child(inst)


func _add_veh(parent: Node, base_scene: PackedScene, name_str: String, res_path: String, pos: Vector2, facing: String, siren: bool) -> void:
	var inst = base_scene.instantiate()
	inst.name = name_str
	inst.data = load(res_path)
	inst.position = pos
	inst.facing_direction_name = facing
	if "siren_active" in inst:
		inst.siren_active = siren
	inst.add_to_group(&"vehicles")
	parent.add_child(inst)


func _add_npc(parent: Node, base_scene: PackedScene, name_str: String, res_path: String, pos: Vector2, wander: bool) -> void:
	var inst = base_scene.instantiate()
	inst.name = name_str
	inst.data = load(res_path)
	inst.position = pos
	inst.auto_wander = wander
	inst.add_to_group(&"npcs")
	parent.add_child(inst)


# ==============================================================================
# 6. GIAO DIỆN HUD ĐỒ HỌA SANG TRỌNG (HUD UI)
# ==============================================================================
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

	# Bảng thông tin điều khiển phía trên góc trái (Top Panel)
	var top_panel = PanelContainer.new()
	top_panel.name = "TopPanel"
	top_panel.offset_left = 16.0
	top_panel.offset_top = 16.0
	top_panel.offset_right = 560.0
	top_panel.offset_bottom = 175.0
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
	lbl_hdr.text = "⚓ SIÊU ĐÔ THỊ BẾN CẢNG THƯỢNG HẢI (SHANGHAI METROPOLIS)"
	lbl_hdr.add_theme_color_override("font_color", Color(0.88, 0.93, 0.98, 1))
	lbl_hdr.add_theme_font_size_override("font_size", 15)
	vbox.add_child(lbl_hdr)

	var lbl_sub = Label.new()
	lbl_sub.name = "LblSub"
	lbl_sub.text = "Nhân vật: Sĩ quan Cảnh sát Cảng (ID01-Anh Tâm) | Quy mô: 110x70 Tiles"
	lbl_sub.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 1))
	lbl_sub.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_sub)

	var lbl_ctrl = Label.new()
	lbl_ctrl.name = "LblControls"
	lbl_ctrl.unique_name_in_owner = true
	lbl_ctrl.text = "🎮 WASD / Mũi tên: Di chuyển | Giữ Shift: Chạy nhanh\n💬 Phím E: Tương tác NPC / Còi xe / Cửa nhà | Phím T: Gọi Taxi đón khách\n🔍 Cuộn chuột: Phóng to/thu nhỏ Camera2D | R: Về vị trí xuất phát"
	lbl_ctrl.add_theme_color_override("font_color", Color(0.7, 0.82, 0.88, 1))
	lbl_ctrl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_ctrl)

	var lbl_pos = Label.new()
	lbl_pos.name = "LblPlayerPos"
	lbl_pos.unique_name_in_owner = true
	lbl_pos.text = "Tọa độ Sĩ quan: (420, 480)"
	lbl_pos.add_theme_color_override("font_color", Color(0.55, 0.75, 0.9, 1))
	lbl_pos.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_pos)

	var hbox_btns = HBoxContainer.new()
	vbox.add_child(hbox_btns)

	var btn_reset = Button.new()
	btn_reset.name = "BtnResetPlayer"
	btn_reset.unique_name_in_owner = true
	btn_reset.text = "Đưa Sĩ Quan Về Trạm (R)"
	hbox_btns.add_child(btn_reset)

	var btn_taxi = Button.new()
	btn_taxi.name = "BtnTriggerTaxi"
	btn_taxi.unique_name_in_owner = true
	btn_taxi.text = "🚖 Thử Gọi Taxi (T)"
	hbox_btns.add_child(btn_taxi)

	# Khung Thoại Tương Tác Phía Dưới (Dialogue Panel)
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
	lbl_cnt.text = "Siêu đô thị Bến cảng Thượng Hải hôm nay cực kỳ nhộn nhịp và sầm uất!"
	lbl_cnt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_cnt.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98, 1))
	lbl_cnt.add_theme_font_size_override("font_size", 11)
	vbox_dlg.add_child(lbl_cnt)


func _set_owner_recursive(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		_set_owner_recursive(child, owner_root)
