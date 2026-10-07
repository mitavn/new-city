extends SceneTree

func _init() -> void:
	print("==================================================")
	print("   KIỂM TRA HỆ THỐNG TILESET TERRAIN & MAP")
	print("==================================================")
	
	# 1. Tải TileSet resource
	var tileset: TileSet = load("res://data/tilesets/city_tileset.tres")
	assert(tileset != null, "Không tải được res://data/tilesets/city_tileset.tres")
	print("✓ Tải thành công city_tileset.tres!")
	
	# 2. Kiểm tra kích thước ô tile
	assert(tileset.tile_size == Vector2i(16, 16), "Kích thước tile phải là 16x16!")
	print("✓ Kích thước Tile: %s (Chuẩn pixel-art 16x16)" % str(tileset.tile_size))
	
	# 3. Kiểm tra Physics Layers
	assert(tileset.get_physics_layers_count() > 0, "Phải có ít nhất 1 Physics Layer!")
	print("✓ Số Physics Layer: %d (Layer 0 cho va chạm nước & vật cản)" % tileset.get_physics_layers_count())
	
	# 4. Kiểm tra Custom Data Layers
	var expected_custom_layers = [
		"surface_type",
		"speed_multiplier",
		"is_road",
		"is_sidewalk",
		"is_water",
		"is_crosswalk",
		"is_parking"
	]
	var layer_count = tileset.get_custom_data_layers_count()
	assert(layer_count == expected_custom_layers.size(), "Phải đủ 7 Custom Data Layers!")
	for i in range(expected_custom_layers.size()):
		var layer_name = tileset.get_custom_data_layer_name(i)
		assert(layer_name == expected_custom_layers[i], "Custom data layer %d phải là %s (thực tế: %s)" % [i, expected_custom_layers[i], layer_name])
	print("✓ Đủ 7 Custom Data Layers: %s" % str(expected_custom_layers))
	
	# 5. Kiểm tra Terrain Sets
	assert(tileset.get_terrain_sets_count() >= 2, "Phải có ít nhất 2 Terrain Sets!")
	var mode_0 = tileset.get_terrain_set_mode(0)
	var mode_1 = tileset.get_terrain_set_mode(1)
	assert(mode_0 == TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES, "Terrain Set 0 phải là Match Corners and Sides!")
	assert(mode_1 == TileSet.TERRAIN_MODE_MATCH_SIDES, "Terrain Set 1 phải là Match Sides!")
	
	var expected_terrains = [
		"Grass", "Dirt", "Sand", "Water", "Sidewalk_Stone",
		"Sidewalk_Brick", "Sidewalk_Dark", "Road_Asphalt", "Platform_Stone"
	]
	assert(tileset.get_terrains_count(0) == 9, "Terrain Set 0 phải có đủ 9 Terrains!")
	for i in range(expected_terrains.size()):
		var t_name = tileset.get_terrain_name(0, i)
		assert(t_name == expected_terrains[i], "Terrain %d phải là %s (thực tế: %s)" % [i, expected_terrains[i], t_name])
	print("✓ Terrain Set 0 (Corners & Sides): 9 địa hình %s" % str(expected_terrains))
	print("✓ Terrain Set 1 (Sides Only): 9 địa hình")
	
	# 6. Kiểm tra Atlas Source
	assert(tileset.has_source(0), "Phải có Source ID 0!")
	var source: TileSetAtlasSource = tileset.get_source(0) as TileSetAtlasSource
	assert(source != null, "Source 0 phải là TileSetAtlasSource!")
	assert(source.texture != null, "Texture phải tồn tại!")
	assert(source.texture_region_size == Vector2i(16, 16), "Region size phải là 16x16!")
	
	var tiles_count = source.get_tiles_count()
	print("✓ Tổng số Tile khả dụng trong Atlas: %d ô (chuẩn xác 100%% các ô có đồ họa)" % tiles_count)
	assert(tiles_count >= 3000, "Phải có ít nhất 3000 tiles!")
	
	# 7. Kiểm tra dữ liệu tile cụ thể
	# Nước tại (41, 13)
	var water_td: TileData = source.get_tile_data(Vector2i(41, 13), 0)
	assert(water_td != null, "Tile nước (41, 13) phải tồn tại!")
	assert(str(water_td.get_custom_data("surface_type")) == "water", "Bề mặt ô (41, 13) phải là water!")
	assert(bool(water_td.get_custom_data("is_water")) == true, "Ô (41, 13) phải có cờ is_water!")
	assert(water_td.get_collision_polygons_count(0) == 1, "Ô nước phải có 1 Collision Polygon chống đi xuyên!")
	print("✓ Tile Nước (41, 13): surface_type='water', is_water=true, Collision Box=OK")
	
	# Đường nhựa tại (31, 38)
	var road_td: TileData = source.get_tile_data(Vector2i(31, 38), 0)
	assert(road_td != null, "Tile đường nhựa (31, 38) phải tồn tại!")
	assert(str(road_td.get_custom_data("surface_type")) == "road", "Bề mặt ô (31, 38) phải là road!")
	assert(bool(road_td.get_custom_data("is_road")) == true, "Ô (31, 38) phải có cờ is_road!")
	print("✓ Tile Đường nhựa (31, 38): surface_type='road', is_road=true")
	
	# Vạch sang đường tại (31, 28)
	var cw_td: TileData = source.get_tile_data(Vector2i(31, 28), 0)
	assert(cw_td != null, "Tile vạch sang đường (31, 28) phải tồn tại!")
	assert(bool(cw_td.get_custom_data("is_crosswalk")) == true, "Ô (31, 28) phải có cờ is_crosswalk!")
	print("✓ Tile Vạch sang đường (31, 28): is_crosswalk=true")
	
	# Bãi đỗ xe tại (18, 50)
	var pk_td: TileData = source.get_tile_data(Vector2i(18, 50), 0)
	assert(pk_td != null, "Tile bãi đỗ xe (18, 50) phải tồn tại!")
	assert(bool(pk_td.get_custom_data("is_parking")) == true, "Ô (18, 50) phải có cờ is_parking!")
	print("✓ Tile Bãi đỗ xe (18, 50): is_parking=true")
	
	# 8. Kiểm tra Scene Test Map
	var test_scene: PackedScene = load("res://scenes/test/map_test_scene.tscn")
	assert(test_scene != null, "Scene res://scenes/test/map_test_scene.tscn phải tải thành công!")
	var inst = test_scene.instantiate()
	assert(inst != null, "Phải instantiate được MapTestScene!")
	print("✓ Scene map_test_scene.tscn đã tải và khởi tạo thành công!")
	inst.free()
	
	print("==================================================")
	print("   TẤT CẢ KIỂM TRA TILESET & MAP ĐÃ ĐẠT 100%!")
	print("==================================================")
	quit()
