extends SceneTree

## Script Dựng Siêu Đô Thị Mở Mộc Thành (Grand Metropolis 260x160 Tiles)
## Quy mô khổng lồ: 260 x 160 tiles = 4,160 x 2,560 pixels (41,600 tiles)!
## Mô phỏng trung thực bức tranh siêu đô thị hoàn chỉnh:
## 1. Núi Tuyết Tây Bắc & Rừng Thông Mùa Đông
## 2. Sân Golf Xanh & Công Viên Sinh Thái Bắc Trung Tâm
## 3. Cao Nguyên Sa Thạch Đỏ Hẻm Núi Đông Bắc
## 4. Trái Tim Đô Thị Downtown: Cao ốc, Ngân hàng, Mall, Phố cổ, Sân vận động, Vòng quay bờ biển
## 5. Bán Đảo Công Viên & Cầu Cảng Quảng Trường Phía Nam
## 6. Đảo Công Nghiệp, Cánh Đồng Năng Lượng Gió & Cảng Container Phía Tây ("DREXEL")
## 7. CÂY CẦU VƯỢT BIỂN DÀI nối Đảo Tây với Trung Tâm Downtown
## 8. Dòng Sông Uốn Lượn & Khu Ngoại Ô Đảo Phía Đông

const MAP_W: int = 260
const MAP_H: int = 160

func _init() -> void:
	print("==================================================================")
	print("🌆 BẮT ĐẦU DỰNG SIÊU ĐÔ THỊ MỘC THÀNH (260x160 TILES — 41,600 TILES)...")
	print("==================================================================")

	var root_node = Node2D.new()
	root_node.name = "MocThanhGame"
	var main_script = load("res://scenes/main/moc_thanh_game.gd")
	root_node.set_script(main_script)

	var city_tileset = load("res://data/tilesets/city_tileset.tres")
	var deco_tileset = load("res://tilesets/decoration.tres")

	# 1. WorldLighting
	var world_lighting = CanvasModulate.new()
	world_lighting.name = "WorldLighting"
	world_lighting.color = Color(1.0, 0.98, 0.92, 1.0) # Nắng sớm
	root_node.add_child(world_lighting)

	# 2. TileMapRoot & Layers
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

	# 3. Dựng địa hình toàn siêu đô thị (Terrain Generation)
	_build_grand_terrain(ground_layer, road_layer, deco_layer)

	# 4. Entities container (Y-Sort)
	var entities_node = Node2D.new()
	entities_node.name = "Entities"
	entities_node.z_index = 3
	entities_node.y_sort_enabled = true
	root_node.add_child(entities_node)

	var npc_base_scene = load("res://scenes/characters/NPCBase.tscn")
	var veh_base_scene = load("res://scenes/vehicles/VehicleBase.tscn")
	var bld_base_scene = load("res://scenes/buildings/BuildingBase.tscn")
	var player_script = load("res://scenes/test/player_npc_controller.gd")

	# 5. Người chơi (Nhân vật chính 29 tuổi - Bạn)
	var player = npc_base_scene.instantiate()
	player.name = "Player_Main_Character"
	player.set_script(player_script)
	player.data = load("res://data/npcs/citizen_male_01.tres")
	player.position = Vector2(2520, 1180) # Xuất phát trước Căn nhà cũ & Trụ sở Downtown
	player.add_to_group(&"player")
	player.add_to_group(&"npcs")

	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.zoom = Vector2(1.5, 1.5)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP_W * 16 # 4160 px
	cam.limit_bottom = MAP_H * 16 # 2560 px
	player.add_child(cam)
	entities_node.add_child(player)

	# 6. Dựng toàn bộ 50+ Tòa nhà kiến trúc Mộc Thành
	_spawn_all_buildings(entities_node, bld_base_scene)

	# 7. Dựng toàn bộ 30+ Phương tiện & Tàu bè
	_spawn_all_vehicles(entities_node, veh_base_scene)

	# 8. Dựng toàn bộ 35+ NPC cư dân & Nhóm 6 người bạn cũ
	_spawn_all_npcs(entities_node, npc_base_scene)

	# 9. Dựng HUD giao diện Mộc Thành & Sổ tay Ký ức
	_build_moc_thanh_hud(root_node)

	# 10. Đóng gói & Lưu Scene
	_set_owner_recursive(root_node, root_node)

	var packed = PackedScene.new()
	var pack_res = packed.pack(root_node)
	if pack_res != OK:
		push_error("Lỗi đóng gói: " + str(pack_res))
		quit(1)
		return

	var save_path = "res://scenes/main/moc_thanh_game.tscn"
	var err = ResourceSaver.save(packed, save_path)
	if err == OK:
		print("✅ ĐÃ LƯU THÀNH CÔNG SIÊU ĐÔ THỊ MỘC THÀNH (260x160 TILES): ", save_path)
	else:
		push_error("Lỗi lưu scene: " + str(err))
		quit(1)
		return

	quit(0)


# ==============================================================================
# ĐỊA HÌNH TOÀN CẢNH SIÊU ĐÔ THỊ (260x160 TILES)
# ==============================================================================
func _build_grand_terrain(ground: TileMapLayer, road: TileMapLayer, deco: TileMapLayer) -> void:
	# A. Nền Nước Biển Xanh Toàn Bộ (Water: Vector2i(41, 13))
	for y in range(MAP_H):
		for x in range(MAP_W):
			ground.set_cell(Vector2i(x, y), 0, Vector2i(41, 13))

	# B. ĐẤT LIỀN PHÍA BẮC (North Mainland: y = 0..65)
	# 1. Tây Bắc: Núi Tuyết & Thị Trấn Mùa Đông (x = 0..72, y = 0..48)
	for py in range(0, 49):
		for px in range(0, 73):
			# Nền đá xám tuyết / vỉa hè lạnh
			ground.set_cell(Vector2i(px, py), 0, Vector2i(50, 0))

	# 2. Bắc Trung Tâm: Núi Đá, Sân Golf & Công Viên Sinh Thái (x = 73..175, y = 0..48)
	for py in range(0, 49):
		for px in range(73, 176):
			ground.set_cell(Vector2i(px, py), 0, Vector2i(56, 8)) # Cỏ xanh mướt

	# Sân Golf với các hồ nước và bẫy cát (Golf Greens & Bunkers: x = 110..150, y = 6..28)
	for gy in range(8, 26):
		for gx in range(112, 146):
			ground.set_cell(Vector2i(gx, gy), 0, Vector2i(56, 5))
	# Bẫy cát vàng trong sân golf
	for by in range(12, 16):
		for bx in range(118, 124):
			ground.set_cell(Vector2i(bx, by), 0, Vector2i(50, 13))
	for by in range(18, 22):
		for bx in range(134, 140):
			ground.set_cell(Vector2i(bx, by), 0, Vector2i(50, 13))

	# 3. Đông Bắc: Cao Nguyên Sa Thạch Đỏ & Hẻm Núi (x = 176..259, y = 0..48)
	for py in range(0, 49):
		for px in range(176, MAP_W):
			ground.set_cell(Vector2i(px, py), 0, Vector2i(56, 51)) # Đất đá đỏ sa thạch

	# C. TRÁI TIM ĐÔ THỊ DOWNTOWN MỘC THÀNH (Bán đảo trung tâm: x = 120..202, y = 35..110)
	for py in range(35, 111):
		for px in range(120, 203):
			ground.set_cell(Vector2i(px, py), 0, Vector2i(44, 8)) # Lát đá hoa cương đô thị

	# Mũi Bán Đảo Công Viên & Cầu Cảng Quảng Trường Phía Nam (x = 145..178, y = 111..138)
	for py in range(111, 139):
		for px in range(145, 179):
			ground.set_cell(Vector2i(px, py), 0, Vector2i(44, 8))

	# Công viên quảng trường đối xứng giữa bán đảo Nam
	for py in range(116, 132):
		for px in range(152, 172):
			ground.set_cell(Vector2i(px, py), 0, Vector2i(56, 8)) # Thảm cỏ quảng trường

	# D. BÁN ĐẢO TÂY NAM — NÔNG TRẠI, NĂNG LƯỢNG GIÓ & CẢNG CÔNG NGHIỆP ("DREXEL": x = 10..105, y = 68..150)
	for py in range(68, 151):
		for px in range(10, 106):
			# Phía tây là nông trại và cánh đồng lúa mì, phía đông là khu công nghiệp
			if px <= 62:
				ground.set_cell(Vector2i(px, py), 0, Vector2i(53, 8)) # Đất nông trại / đồng lúa
			else:
				ground.set_cell(Vector2i(px, py), 0, Vector2i(50, 0)) # Bê tông công nghiệp

	# Bãi biển cát vàng bao bọc rìa bờ Tây Nam (Beach: x = 6..14, y = 74..148)
	for py in range(74, 149):
		ground.set_cell(Vector2i(6, py), 0, Vector2i(50, 13))
		ground.set_cell(Vector2i(7, py), 0, Vector2i(50, 13))
		ground.set_cell(Vector2i(8, py), 0, Vector2i(50, 13))
		ground.set_cell(Vector2i(9, py), 0, Vector2i(50, 13))

	# Đường băng Sân Bay Tây Nam (Airport Runway: x = 20..75, y = 142..150)
	for py in range(142, 151):
		for px in range(20, 76):
			road.set_cell(Vector2i(px, py), 0, Vector2i(31, 38))
			if py == 146 and px % 3 == 0:
				deco.set_cell(Vector2i(px, py), 0, Vector2i(20, 38)) # Vạch trắng tim đường băng

	# E. ĐẢO MÓNG NGỰA PHÍA ĐÔNG NAM (Horseshoe Island: x = 215..256, y = 102..145)
	for py in range(102, 146):
		for px in range(215, 257):
			ground.set_cell(Vector2i(px, py), 0, Vector2i(56, 8)) # Đảo cây xanh

	# Khu ngoại ô ven biển phía Đông (Suburbs: x = 204..259, y = 48..95)
	for py in range(48, 96):
		for px in range(204, MAP_W):
			ground.set_cell(Vector2i(px, py), 0, Vector2i(56, 8))

	# F. DÒNG SÔNG XANH BIẾC UỐN LƯỢN (Winding River: từ núi phía Bắc xuống biển phía Đông)
	for ry in range(0, 75):
		var rx = 180 + int(sin(ry * 0.15) * 8.0)
		for w in range(-4, 5):
			ground.set_cell(Vector2i(rx + w, ry), 0, Vector2i(45, 16)) # Nước sông xanh ngọc

	# Cây cầu bắc qua sông nối Downtown với Bờ Đông (x = 175..190, y = 56..60)
	for by in range(56, 61):
		for bx in range(174, 192):
			road.set_cell(Vector2i(bx, by), 0, Vector2i(31, 38))

	# G. CÂY CẦU VƯỢT BIỂN DÀI NỐI ĐẢO TÂY NAM VỚI DOWNTOWN (Long Sea Suspension Bridge)
	# Đi từ x = 104 đến x = 122 (y = 86..92) băng qua mặt biển xanh!
	for by in range(86, 93):
		for bx in range(104, 123):
			road.set_cell(Vector2i(bx, by), 0, Vector2i(31, 38))
			# Trụ lan can cầu trên biển
			if by == 86 or by == 92:
				deco.set_cell(Vector2i(bx, by), 0, Vector2i(26, 30))
			elif by == 89 and bx % 2 == 0:
				deco.set_cell(Vector2i(bx, by), 0, Vector2i(21, 38)) # Vạch vàng phân làn cầu

	# H. MẠNG LƯỚI ĐƯỜNG PHỐ DOWNTOWN (Grid Road Network)
	# 1. Đại lộ chính Đông-Tây 1 (Rows 46..52, x = 120..202)
	for y in range(46, 53):
		for x in range(120, 203):
			road.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))
			if y == 49 and x % 2 == 0:
				deco.set_cell(Vector2i(x, y), 0, Vector2i(21, 38))

	# 2. Đại lộ chính Đông-Tây 2 (Rows 70..76, x = 120..202)
	for y in range(70, 77):
		for x in range(120, 203):
			road.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))
			if y == 73 and x % 2 == 0:
				deco.set_cell(Vector2i(x, y), 0, Vector2i(21, 38))

	# 3. Đại lộ chính Đông-Tây 3 (Rows 86..92, x = 120..202 - nối với Cầu Vượt Biển!)
	for y in range(86, 93):
		for x in range(120, 203):
			road.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))
			if y == 89 and x % 2 == 0:
				deco.set_cell(Vector2i(x, y), 0, Vector2i(21, 38))

	# 4. Trục Bắc-Nam 1 (Cols 134..140, y = 35..110)
	for x in range(134, 141):
		for y in range(35, 111):
			road.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))
			if x == 137 and y % 2 == 0:
				deco.set_cell(Vector2i(x, y), 0, Vector2i(21, 38))

	# 5. Trục Bắc-Nam 2 (Cols 158..164, y = 35..138 - trục chính chạy ra Mũi Bán Đảo Nam!)
	for x in range(158, 165):
		for y in range(35, 139):
			road.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))
			if x == 161 and y % 2 == 0:
				deco.set_cell(Vector2i(x, y), 0, Vector2i(21, 38))

	# 6. Trục Bắc-Nam 3 (Cols 184..190, y = 35..110)
	for x in range(184, 191):
		for y in range(35, 111):
			road.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))
			if x == 187 and y % 2 == 0:
				deco.set_cell(Vector2i(x, y), 0, Vector2i(21, 38))

	# Vạch sang đường Zebra tại các ngã tư chính
	var intersections = [
		Vector2i(134, 46), Vector2i(158, 46), Vector2i(184, 46),
		Vector2i(134, 70), Vector2i(158, 70), Vector2i(184, 70),
		Vector2i(134, 86), Vector2i(158, 86), Vector2i(184, 86)
	]
	for inter in intersections:
		for ix in range(inter.x, inter.x + 7):
			for iy in range(inter.y, inter.y + 7):
				road.set_cell(Vector2i(ix, iy), 0, Vector2i(39, 48))

	# Tuyến đường công nghiệp trên Đảo Tây Nam (x = 64..104, y = 86..92)
	for y in range(86, 93):
		for x in range(64, 105):
			road.set_cell(Vector2i(x, y), 0, Vector2i(31, 38))

	# Cầu cảng bến tàu & Bờ kè đá ven biển (Seawall & Docks)
	for x in range(120, 203):
		deco.set_cell(Vector2i(x, 110), 0, Vector2i(26, 30))
	for y in range(111, 139):
		deco.set_cell(Vector2i(145, y), 0, Vector2i(26, 30))
		deco.set_cell(Vector2i(178, y), 0, Vector2i(26, 30))


# ==============================================================================
# TOÀN BỘ 50+ TÒA NHÀ KIẾN TRÚC PHÂN BỔ THEO BIOME & PHÂN KHU
# ==============================================================================
func _spawn_all_buildings(parent: Node2D, bld_scene: PackedScene) -> void:
	# --- PHÂN KHU 1: DOWNTOWN METROPOLIS & CÔNG QUYỀN (x ~ 125..200, y ~ 40..105) ---
	_add_bld(parent, bld_scene, "Bld_MocThanhBank", "res://data/buildings/bank_central_01.tres", Vector2(2360, 800))
	_add_bld(parent, bld_scene, "Bld_CentralMall", "res://data/buildings/mall_shopping_01.tres", Vector2(2580, 780))
	_add_bld(parent, bld_scene, "Bld_CityCinema", "res://data/buildings/cinema_theater_01.tres", Vector2(2820, 800))
	_add_bld(parent, bld_scene, "Bld_GrandHotel", "res://data/buildings/hotel_grand_01.tres", Vector2(3040, 780))
	_add_bld(parent, bld_scene, "Bld_TuanPlazaHQ", "res://data/buildings/campus_building_01.tres", Vector2(2200, 1180)) # Trụ sở Bất Động Sản Tuấn
	_add_bld(parent, bld_scene, "Bld_MinhPoliceHQ", "res://data/buildings/police_station_01.tres", Vector2(2540, 1180)) # Đồn Cảnh Sát Minh
	_add_bld(parent, bld_scene, "Bld_DetentionPrison", "res://data/buildings/prison_city_01.tres", Vector2(2760, 1160))
	_add_bld(parent, bld_scene, "Bld_CentralFireStation", "res://data/buildings/firestation_01.tres", Vector2(2980, 1180))
	_add_bld(parent, bld_scene, "Bld_MocThanhHospital", "res://data/buildings/hospital_city_01.tres", Vector2(3180, 1160))

	# --- PHÂN KHU 2: PHỐ CỔ 12 NĂM TRƯỚC (OLD QUARTER & FOOD STREET: x ~ 125..190, y ~ 55..68) ---
	_add_bld(parent, bld_scene, "Bld_LanCafe", "res://data/buildings/cafe_shop_01.tres", Vector2(2280, 980)) # Quán Café hoa giấy của Lan
	_add_bld(parent, bld_scene, "Bld_NightRamenStand", "res://data/buildings/ramen_stand_01.tres", Vector2(2440, 990)) # Tiệm mì đêm
	_add_bld(parent, bld_scene, "Bld_SushiRestaurant", "res://data/buildings/japanese_restaurant_01.tres", Vector2(2600, 990))
	_add_bld(parent, bld_scene, "Bld_SauBookstore", "res://data/buildings/library_city_01.tres", Vector2(2760, 980)) # Hiệu sách cũ 30 năm của bà Sáu
	_add_bld(parent, bld_scene, "Bld_BakeryFresh", "res://data/buildings/bakery_standard_01.tres", Vector2(2920, 990))
	_add_bld(parent, bld_scene, "Bld_BurgerFastFood", "res://data/buildings/burgershop_01.tres", Vector2(3080, 990))
	_add_bld(parent, bld_scene, "Bld_BarbershopOld", "res://data/buildings/barbershop_01.tres", Vector2(3220, 990))
	_add_bld(parent, bld_scene, "Bld_SailorPub", "res://data/buildings/bar_pub_01.tres", Vector2(2280, 1380))
	_add_bld(parent, bld_scene, "Bld_LawsonStore_1", "res://data/buildings/convenient_store_clean_01.tres", Vector2(2460, 1380))
	_add_bld(parent, bld_scene, "Bld_SupermarketEast", "res://data/buildings/supermarket_city_01.tres", Vector2(2660, 1380))

	# --- PHÂN KHU 3: BÁN ĐẢO CÔNG VIÊN & CẦU CẢNG NAM (x ~ 145..178, y ~ 110..138) ---
	_add_bld(parent, bld_scene, "Bld_HarborCustoms", "res://data/buildings/portable_office_01.tres", Vector2(2420, 1920))
	_add_bld(parent, bld_scene, "Bld_MocThanhLighthouse", "res://data/buildings/lighthouse_01.tres", Vector2(2720, 2180)) # Hải đăng Mộc Thành
	_add_bld(parent, bld_scene, "Bld_HarborWarehouse_1", "res://data/buildings/wood_building_01.tres", Vector2(2360, 2060))
	_add_bld(parent, bld_scene, "Bld_HarborWarehouse_2", "res://data/buildings/brick_building_01.tres", Vector2(2560, 2060))

	# --- PHÂN KHU 4: ĐẢO CÔNG NGHIỆP & CẢNG CONTAINER TÂY NAM ("DREXEL") ---
	_add_bld(parent, bld_scene, "Bld_FactoryPlant_1", "res://data/buildings/brick_building_01.tres", Vector2(1200, 1500))
	_add_bld(parent, bld_scene, "Bld_FactoryPlant_2", "res://data/buildings/wood_building_01.tres", Vector2(1420, 1500))
	_add_bld(parent, bld_scene, "Bld_AirportTerminal", "res://data/buildings/mall_shopping_01.tres", Vector2(650, 2260))
	_add_bld(parent, bld_scene, "Bld_FarmStorage_1", "res://data/buildings/wood_building_01.tres", Vector2(480, 1280))
	_add_bld(parent, bld_scene, "Bld_FarmStorage_2", "res://data/buildings/wood_building_01.tres", Vector2(720, 1280))

	# --- PHÂN KHU 5: TÂY BẮC (NÚI TUYẾT & THỊ TRẤN MÙA ĐÔNG) ---
	_add_bld(parent, bld_scene, "Bld_SnowLodge_1", "res://data/buildings/motel_lodge_01.tres", Vector2(400, 360))
	_add_bld(parent, bld_scene, "Bld_SnowLodge_2", "res://data/buildings/wood_building_01.tres", Vector2(680, 360))

	# --- PHÂN KHU 6: ĐÔNG BẮC (HẺM NÚI ĐÁ ĐỎ & NGOẠI Ô) ---
	_add_bld(parent, bld_scene, "Bld_CanyonRanch", "res://data/buildings/wood_building_01.tres", Vector2(3480, 380))
	_add_bld(parent, bld_scene, "Bld_SuburbanVilla_1", "res://data/buildings/brick_building_01.tres", Vector2(3560, 1080))
	_add_bld(parent, bld_scene, "Bld_SuburbanVilla_2", "res://data/buildings/convenient_store_01.tres", Vector2(3780, 1080))


# ==============================================================================
# TOÀN BỘ 30+ PHƯƠNG TIỆN ĐƯỜNG BỘ & ĐỘI TÀU THUYỀN VIỄN DƯƠNG
# ==============================================================================
func _spawn_all_vehicles(parent: Node2D, veh_scene: PackedScene) -> void:
	# Đội Xe Cảnh Sát Tuần Tra (Cruisers)
	_add_veh(parent, veh_scene, "PoliceCar_HQ", "res://data/vehicles/police_car_01.tres", Vector2(2480, 1220), "front_right", false)
	_add_veh(parent, veh_scene, "PoliceCar_Bridge", "res://data/vehicles/police_car_01.tres", Vector2(1820, 1420), "front_right", false) # Đầu cầu vượt biển
	_add_veh(parent, veh_scene, "PoliceCar_North", "res://data/vehicles/police_car_01.tres", Vector2(2520, 740), "front_left", false)

	# Taxi Mộc Thành
	_add_veh(parent, veh_scene, "TaxiYellow_Downtown", "res://data/vehicles/taxi_yellow_01.tres", Vector2(2360, 1120), "front_right", false)
	_add_veh(parent, veh_scene, "TaxiGreen_Cafe", "res://data/vehicles/taxi_standard_01.tres", Vector2(2240, 1020), "front_right", false)
	_add_veh(parent, veh_scene, "TaxiYellow_Mall", "res://data/vehicles/taxi_yellow_01.tres", Vector2(2640, 840), "front_left", false)

	# Xe Buýt Tuyến Liên Phân Khu (City Buses)
	_add_veh(parent, veh_scene, "CityBus_ExpressBridge", "res://data/vehicles/bus_city_01.tres", Vector2(1920, 1420), "front_right", false) # Chạy trên cầu vượt biển
	_add_veh(parent, veh_scene, "CityBus_Downtown", "res://data/vehicles/bus_city_01.tres", Vector2(2840, 1120), "front_left", false)

	# Xe Cứu Hỏa & Cứu Thương
	_add_veh(parent, veh_scene, "FireTruck_1", "res://data/vehicles/firetruck_01.tres", Vector2(2940, 1220), "front_right", false)
	_add_veh(parent, veh_scene, "Ambulance_1", "res://data/vehicles/ambulance_01.tres", Vector2(3140, 1220), "front_right", false)

	# Xe Bán Hàng Lưu Động & Dân Sự
	_add_veh(parent, veh_scene, "FoodTruck_Park", "res://data/vehicles/foodtruck_moving_01.tres", Vector2(2580, 1860), "front_left", false)
	_add_veh(parent, veh_scene, "CarBlue_1", "res://data/vehicles/car_blue_01.tres", Vector2(2720, 1120), "front_right", false)
	_add_veh(parent, veh_scene, "CarRed_1", "res://data/vehicles/car_red_01.tres", Vector2(2960, 1120), "front_left", false)
	_add_veh(parent, veh_scene, "Bulldozer_Port", "res://data/vehicles/bulldozer_01.tres", Vector2(1380, 1580), "front_left", false)

	# Đội Tàu Biển & Ca-nô Tuần Tra Vịnh Mộc Thành
	_add_veh(parent, veh_scene, "ShipFerry_MocThanh", "res://data/vehicles/ship_ferry_01.tres", Vector2(2280, 2040), "front_right", false)
	_add_veh(parent, veh_scene, "ShipTrade_GiantCargo", "res://data/vehicles/ship_trade_01.tres", Vector2(1480, 1780), "front_left", false) # Tàu container cảng Tây
	_add_veh(parent, veh_scene, "PatrolBoat_Police", "res://data/vehicles/boat_small_01.tres", Vector2(1780, 1620), "front_right", true) # Ca-nô dưới chân cầu vượt biển


# ==============================================================================
# NHÓM 6 NGƯỜI BẠN CŨ & DÀN CƯ DÂN (35+ NHÂN VẬT)
# ==============================================================================
func _spawn_all_npcs(parent: Node2D, npc_scene: PackedScene) -> void:
	# 1. Minh Cảnh Sát (Minh - Sĩ quan tuần tra Đồn Mộc Thành)
	_add_npc(parent, npc_scene, "NPC_Minh_CanhSat", "res://data/npcs/police_male_01.tres", Vector2(2500, 1200), true)

	# 2. Lan Quán Café (Lan - Chủ quán café hoa giấy)
	_add_npc(parent, npc_scene, "NPC_Lan_QuanCafe", "res://data/npcs/citizen_female_01.tres", Vector2(2260, 1020), false)

	# 3. Tuấn Bất Động Sản (Tuấn - Giám đốc dự án Mộc Thành Plaza)
	_add_npc(parent, npc_scene, "NPC_Tuan_BatDongSan", "res://data/npcs/executive_male_01.tres", Vector2(2180, 1220), false)

	# 4. Bình Thầy Giáo (Bình - Cố vấn bảo tồn khu phố cũ)
	_add_npc(parent, npc_scene, "NPC_Binh_ThayGiao", "res://data/npcs/citizen_male_02.tres", Vector2(2720, 1020), false)

	# 5. Nam 'Bóng Ma Ga Tàu' (Nam - Người bạn mất tích 12 năm trước)
	_add_npc(parent, npc_scene, "NPC_Nam_BongMaGaTau", "res://data/npcs/delivery_male_01.tres", Vector2(1960, 1460), true) # Đứng quanh chân cầu vượt biển

	# 6. Bà Sáu Tiệm Sách (Bà Sáu - Chủ hiệu sách 30 năm tuổi)
	_add_npc(parent, npc_scene, "NPC_Sau_TiemSachCu", "res://data/npcs/senior_female_01.tres", Vector2(2780, 1020), false)

	# Cư dân đời sống khác
	_add_npc(parent, npc_scene, "NPC_Chef_RamenNam", "res://data/npcs/chef_male_01.tres", Vector2(2440, 1030), false)
	_add_npc(parent, npc_scene, "NPC_BacSi_Ha", "res://data/npcs/doctor_female_01.tres", Vector2(3180, 1200), true)
	_add_npc(parent, npc_scene, "NPC_LinhCuuHoa_Huy", "res://data/npcs/firefighter_male_01.tres", Vector2(2980, 1200), false)
	_add_npc(parent, npc_scene, "NPC_CongNhan_Cang_1", "res://data/npcs/construction_male_01.tres", Vector2(1360, 1540), true)
	_add_npc(parent, npc_scene, "NPC_CongNhan_Cang_2", "res://data/npcs/construction_female_01.tres", Vector2(1460, 1540), true)
	_add_npc(parent, npc_scene, "NPC_DanPho_1", "res://data/npcs/citizen_female_02.tres", Vector2(2620, 1120), true)
	_add_npc(parent, npc_scene, "NPC_DanPho_2", "res://data/npcs/citizen_male_03.tres", Vector2(2860, 1120), true)
	_add_npc(parent, npc_scene, "NPC_DanPho_3", "res://data/npcs/citizen_female_04.tres", Vector2(2560, 1840), true)


func _add_bld(parent: Node, scene: PackedScene, name_str: String, res_path: String, pos: Vector2) -> void:
	var inst = scene.instantiate()
	inst.name = name_str
	inst.data = load(res_path)
	inst.position = pos
	inst.add_to_group(&"buildings")
	parent.add_child(inst)


func _add_veh(parent: Node, scene: PackedScene, name_str: String, res_path: String, pos: Vector2, facing: String, siren: bool) -> void:
	var inst = scene.instantiate()
	inst.name = name_str
	inst.data = load(res_path)
	inst.position = pos
	inst.facing_direction_name = facing
	if "siren_active" in inst:
		inst.siren_active = siren
	inst.add_to_group(&"vehicles")
	parent.add_child(inst)


func _add_npc(parent: Node, scene: PackedScene, name_str: String, res_path: String, pos: Vector2, wander: bool) -> void:
	var inst = scene.instantiate()
	inst.name = name_str
	inst.data = load(res_path)
	inst.position = pos
	inst.auto_wander = wander
	inst.add_to_group(&"npcs")
	parent.add_child(inst)


# ==============================================================================
# GIAO DIỆN HUD ĐỒ HỌA MỘC THÀNH
# ==============================================================================
func _build_moc_thanh_hud(root: Node2D) -> void:
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

	# Bảng thông tin điều khiển & Thời gian (Top Panel)
	var top_panel = PanelContainer.new()
	top_panel.name = "TopPanel"
	top_panel.offset_left = 16.0
	top_panel.offset_top = 16.0
	top_panel.offset_right = 650.0
	top_panel.offset_bottom = 205.0
	var style_top = StyleBoxFlat.new()
	style_top.bg_color = Color(0.06, 0.08, 0.12, 0.92)
	style_top.border_color = Color(0.4, 0.85, 0.65, 0.95) # Viền xanh ngọc Mộc Thành
	style_top.set_border_width_all(2)
	style_top.set_corner_radius_all(8)
	style_top.content_margin_left = 16.0
	style_top.content_margin_top = 12.0
	style_top.content_margin_right = 16.0
	style_top.content_margin_bottom = 12.0
	top_panel.add_theme_stylebox_override("panel", style_top)
	ui_root.add_child(top_panel)

	var vbox = VBoxContainer.new()
	top_panel.add_child(vbox)

	var lbl_hdr = Label.new()
	lbl_hdr.name = "LblHeader"
	lbl_hdr.unique_name_in_owner = true
	lbl_hdr.text = "🌿 12 YEARS LATER — MỘC THÀNH (NGÀY 1)"
	lbl_hdr.add_theme_color_override("font_color", Color(0.5, 0.95, 0.75, 1))
	lbl_hdr.add_theme_font_size_override("font_size", 15)
	vbox.add_child(lbl_hdr)

	var lbl_sub = Label.new()
	lbl_sub.name = "LblSub"
	lbl_sub.unique_name_in_owner = true
	lbl_sub.text = "Thời gian: Buổi Sáng | Đồng hồ: 08:00 | Tiền mặt: 1,250,000 đ"
	lbl_sub.add_theme_color_override("font_color", Color(0.9, 0.94, 0.98, 1))
	lbl_sub.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_sub)

	var lbl_ctrl = Label.new()
	lbl_ctrl.name = "LblControls"
	lbl_ctrl.unique_name_in_owner = true
	lbl_ctrl.text = "🎮 WASD: Di chuyển 8 hướng | Shift: Chạy nhanh / Tăng tốc | E: Tương tác / Khám phá bí mật\n📖 M: Mở Sổ tay điều tra | 🎞️ K: Hồi tưởng ký ức 12 năm trước | 🚓 F: Lái xe | 🔊 H: Bóp còi | 🚨 G: Còi hú"
	lbl_ctrl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.92, 1))
	lbl_ctrl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_ctrl)

	var lbl_pos = Label.new()
	lbl_pos.name = "LblPlayerPos"
	lbl_pos.unique_name_in_owner = true
	lbl_pos.text = "Tọa độ: (2520, 1180) | Siêu Đô Thị: 260x160 Ô gạch (41,600 tiles)"
	lbl_pos.add_theme_color_override("font_color", Color(0.6, 0.8, 0.95, 1))
	lbl_pos.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_pos)

	var hbox_btns = HBoxContainer.new()
	vbox.add_child(hbox_btns)

	var btn_journal = Button.new()
	btn_journal.name = "BtnJournal"
	btn_journal.unique_name_in_owner = true
	btn_journal.text = "📖 Sổ Tay Ký Ức (M)"
	hbox_btns.add_child(btn_journal)

	var btn_flashback = Button.new()
	btn_flashback.name = "BtnFlashback"
	btn_flashback.unique_name_in_owner = true
	btn_flashback.text = "🎞️ Ký Ức 12 Năm Trước (K)"
	hbox_btns.add_child(btn_flashback)

	var btn_horn = Button.new()
	btn_horn.name = "BtnHorn"
	btn_horn.unique_name_in_owner = true
	btn_horn.text = "🔊 Bóp Còi (H)"
	hbox_btns.add_child(btn_horn)

	var btn_siren = Button.new()
	btn_siren.name = "BtnSiren"
	btn_siren.unique_name_in_owner = true
	btn_siren.text = "🚨 Còi Hú (G)"
	hbox_btns.add_child(btn_siren)

	var btn_car = Button.new()
	btn_car.name = "BtnToggleCar"
	btn_car.unique_name_in_owner = true
	btn_car.text = "🚓 Lên/Xuống Xe (F)"
	hbox_btns.add_child(btn_car)

	var btn_home = Button.new()
	btn_home.name = "BtnResetPlayer"
	btn_home.unique_name_in_owner = true
	btn_home.text = "🏠 Về Nhà Cũ (R)"
	hbox_btns.add_child(btn_home)

	# Bảng Sổ Tay Điều Tra (Journal Pinboard Panel)
	var journal_panel = PanelContainer.new()
	journal_panel.name = "JournalPanel"
	journal_panel.unique_name_in_owner = true
	journal_panel.visible = false
	journal_panel.anchor_left = 0.5
	journal_panel.anchor_top = 0.5
	journal_panel.anchor_right = 0.5
	journal_panel.anchor_bottom = 0.5
	journal_panel.offset_left = -380.0
	journal_panel.offset_top = -250.0
	journal_panel.offset_right = 380.0
	journal_panel.offset_bottom = 250.0
	
	var style_j = StyleBoxFlat.new()
	style_j.bg_color = Color(0.08, 0.09, 0.12, 0.96)
	style_j.border_color = Color(1.0, 0.85, 0.45, 0.95)
	style_j.set_border_width_all(3)
	style_j.set_corner_radius_all(10)
	style_j.content_margin_left = 24.0
	style_j.content_margin_top = 18.0
	style_j.content_margin_right = 24.0
	style_j.content_margin_bottom = 18.0
	journal_panel.add_theme_stylebox_override("panel", style_j)
	ui_root.add_child(journal_panel)

	var vbox_j = VBoxContainer.new()
	journal_panel.add_child(vbox_j)

	var lbl_j_title = Label.new()
	lbl_j_title.text = "📖 SỔ TAY ĐIỀU TRA — MỘC THÀNH (12 NĂM SAU)"
	lbl_j_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5, 1))
	lbl_j_title.add_theme_font_size_override("font_size", 16)
	vbox_j.add_child(lbl_j_title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(710, 410)
	vbox_j.add_child(scroll)

	var lbl_j_cnt = Label.new()
	lbl_j_cnt.name = "LblJournalContent"
	lbl_j_cnt.unique_name_in_owner = true
	lbl_j_cnt.text = "Nhấn M để mở sổ tay..."
	lbl_j_cnt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_j_cnt.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1))
	lbl_j_cnt.add_theme_font_size_override("font_size", 12)
	scroll.add_child(lbl_j_cnt)

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
	style_dlg.border_color = Color(0.4, 0.8, 1.0, 0.98)
	style_dlg.set_border_width_all(2)
	style_dlg.set_corner_radius_all(8)
	style_dlg.content_margin_left = 32.0
	style_dlg.content_margin_top = 14.0
	style_dlg.content_margin_right = 32.0
	style_dlg.content_margin_bottom = 14.0
	dlg_panel.add_theme_stylebox_override("panel", style_dlg)
	ui_root.add_child(dlg_panel)

	var vbox_dlg = VBoxContainer.new()
	dlg_panel.add_child(vbox_dlg)

	var lbl_spk = Label.new()
	lbl_spk.name = "LblSpeaker"
	lbl_spk.unique_name_in_owner = true
	lbl_spk.text = "Nhân vật:"
	lbl_spk.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0, 1))
	lbl_spk.add_theme_font_size_override("font_size", 12)
	vbox_dlg.add_child(lbl_spk)

	var lbl_cnt = Label.new()
	lbl_cnt.name = "LblDialogueContent"
	lbl_cnt.unique_name_in_owner = true
	lbl_cnt.text = "Nội dung thoại..."
	lbl_cnt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_cnt.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98, 1))
	lbl_cnt.add_theme_font_size_override("font_size", 11)
	vbox_dlg.add_child(lbl_cnt)


func _set_owner_recursive(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		_set_owner_recursive(child, owner_root)
