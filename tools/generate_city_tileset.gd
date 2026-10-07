extends SceneTree

const SHEET_COLS: int = 61
const SHEET_ROWS: int = 55
const TILE_SIZE: int = 16

func _init() -> void:
	print("==================================================")
	print("   BẮT ĐẦU TỰ ĐỘNG TẠO VÀ CẤU HÌNH TILESET TERRAIN")
	print("==================================================")
	var t_start = Time.get_ticks_msec()
	
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# 1. Physics Layer 0 (Vật cản / Nước / Tường bục)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 1)
	
	# 2. Custom Data Layers
	_setup_custom_data_layers(tileset)
	
	# 4. Terrain Sets
	# Set 0: Corners and Sides (Autotile 3x3 đầy đủ)
	tileset.add_terrain_set(0)
	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	_setup_terrains_for_set(tileset, 0)
	
	# Set 1: Sides Only (Autotile 4 hướng cơ bản, dễ vẽ không lỗi góc)
	tileset.add_terrain_set(1)
	tileset.set_terrain_set_mode(1, TileSet.TERRAIN_MODE_MATCH_SIDES)
	_setup_terrains_for_set(tileset, 1)
	
	# 5. Atlas Source
	var atlas = TileSetAtlasSource.new()
	var tex = load("res://assets/tilesets/GroundTiles.png")
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Phải gán source vào TileSet trước khi cấu hình TileData
	tileset.add_source(atlas, 0)
	
	var img = tex.get_image()
	var total_tiles_created = 0
	
	var col_box = PackedVector2Array([
		Vector2(-8, -8),
		Vector2(8, -8),
		Vector2(8, 8),
		Vector2(-8, 8)
	])
	
	# 6. Quét toàn bộ 61x55 ô và tạo tile hợp lệ
	for r in range(SHEET_ROWS):
		for c in range(SHEET_COLS):
			if _tile_has_pixels(img, c, r):
				atlas.create_tile(Vector2i(c, r))
				total_tiles_created += 1
				var td: TileData = atlas.get_tile_data(Vector2i(c, r), 0)
				_classify_and_setup_tile(td, c, r, col_box)
	
	print("Đã tạo thành công %d tiles trong Atlas!" % total_tiles_created)
	
	# 7. Cấu hình Terrain Peering Bits cho các khối Autotile 3x3
	_apply_autotile_3x3(atlas, Vector2i(55, 7), 0, 0)   # Grass 3x3 (Corners and sides)
	_apply_autotile_3x3(atlas, Vector2i(55, 12), 0, 0)  # Grass with flowers
	_apply_autotile_3x3(atlas, Vector2i(52, 7), 0, 1)   # Dirt 3x3
	_apply_autotile_3x3(atlas, Vector2i(46, 12), 0, 1)  # Dirt brown
	_apply_autotile_3x3(atlas, Vector2i(49, 12), 0, 2)  # Sand peach
	_apply_autotile_3x3(atlas, Vector2i(40, 12), 0, 3)  # Water blue
	_apply_autotile_3x3(atlas, Vector2i(43, 12), 0, 3)  # Water light
	_apply_autotile_3x3(atlas, Vector2i(46, 7), 0, 3)   # Water dark
	_apply_autotile_3x3(atlas, Vector2i(43, 7), 0, 4)   # Sidewalk Stone
	_apply_autotile_3x3(atlas, Vector2i(58, 7), 0, 6)   # Sidewalk Dark
	_apply_autotile_3x3(atlas, Vector2i(52, 12), 0, 6)  # Sidewalk Slate
	_apply_autotile_3x3(atlas, Vector2i(40, 7), 0, 8)   # Platform Stone
	
	# Cấu hình Terrain cho các khối chữ thập 7x7 (Center fill)
	_apply_cross_autotile(atlas, Vector2i(0, 10), 0, 4)   # Cobblestone cross
	_apply_cross_autotile(atlas, Vector2i(6, 10), 0, 5)   # Tan brick cross
	_apply_cross_autotile(atlas, Vector2i(19, 10), 0, 5)  # Red brick cross
	_apply_cross_autotile(atlas, Vector2i(0, 17), 0, 4)   # Grey stone cross
	_apply_cross_autotile(atlas, Vector2i(6, 17), 0, 6)   # Dark slate cross
	_apply_cross_autotile(atlas, Vector2i(0, 24), 0, 0)   # Grass cross
	_apply_cross_autotile(atlas, Vector2i(0, 31), 0, 2)   # Sand cross
	_apply_cross_autotile(atlas, Vector2i(6, 31), 0, 1)   # Dirt cross
	
	# 8. Lưu Resource ra đĩa
	var path_data = "res://data/tilesets/city_tileset.tres"
	var path_root = "res://tilesets/city_tileset.tres"
	
	var err1 = ResourceSaver.save(tileset, path_data)
	var err2 = ResourceSaver.save(tileset, path_root)
	
	var elapsed = Time.get_ticks_msec() - t_start
	print("Lưu tileset vào '%s' (Mã lỗi: %d)" % [path_data, err1])
	print("Lưu tileset vào '%s' (Mã lỗi: %d)" % [path_root, err2])
	print("Hoàn tất tạo TileSet trong %d ms!" % elapsed)
	print("==================================================")
	quit()

func _setup_custom_data_layers(tileset: TileSet) -> void:
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "surface_type")
	tileset.set_custom_data_layer_type(0, TYPE_STRING)
	
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(1, "speed_multiplier")
	tileset.set_custom_data_layer_type(1, TYPE_FLOAT)
	
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(2, "is_road")
	tileset.set_custom_data_layer_type(2, TYPE_BOOL)
	
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(3, "is_sidewalk")
	tileset.set_custom_data_layer_type(3, TYPE_BOOL)
	
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(4, "is_water")
	tileset.set_custom_data_layer_type(4, TYPE_BOOL)
	
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(5, "is_crosswalk")
	tileset.set_custom_data_layer_type(5, TYPE_BOOL)
	
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(6, "is_parking")
	tileset.set_custom_data_layer_type(6, TYPE_BOOL)

func _setup_terrains_for_set(tileset: TileSet, set_idx: int) -> void:
	var terrains = [
		{"name": "Grass", "color": Color("#479038")},
		{"name": "Dirt", "color": Color("#8c5737")},
		{"name": "Sand", "color": Color("#f0be82")},
		{"name": "Water", "color": Color("#2b7dc0")},
		{"name": "Sidewalk_Stone", "color": Color("#787579")},
		{"name": "Sidewalk_Brick", "color": Color("#9c5c56")},
		{"name": "Sidewalk_Dark", "color": Color("#3d3b43")},
		{"name": "Road_Asphalt", "color": Color("#36323a")},
		{"name": "Platform_Stone", "color": Color("#5e5963")}
	]
	for i in range(terrains.size()):
		tileset.add_terrain(set_idx)
		tileset.set_terrain_name(set_idx, i, terrains[i].name)
		tileset.set_terrain_color(set_idx, i, terrains[i].color)

func _tile_has_pixels(img: Image, c: int, r: int) -> bool:
	for py in range(TILE_SIZE):
		for px in range(TILE_SIZE):
			var col = img.get_pixel(c * TILE_SIZE + px, r * TILE_SIZE + py)
			if col.a > 0.01:
				return true
	return false

func _classify_and_setup_tile(td: TileData, c: int, r: int, col_box: PackedVector2Array) -> void:
	# Xác định thuộc tính dựa vào vị trí địa lý trên spritesheet
	var surface: String = "ground"
	var speed: float = 1.0
	var is_road: bool = false
	var is_sidewalk: bool = false
	var is_water: bool = false
	var is_crosswalk: bool = false
	var is_parking: bool = false
	var has_collision: bool = false
	
	# 1. Mặt nước (Water)
	if (c >= 40 and c <= 48 and r >= 7 and r <= 9 and c in [46, 47, 48]) or \
	   (c >= 40 and c <= 45 and r >= 12 and r <= 14) or \
	   (c >= 12 and c <= 18 and r >= 18 and r <= 23) or \
	   (c >= 52 and c <= 58 and r >= 45 and r <= 48):
		surface = "water"
		speed = 0.0
		is_water = true
		has_collision = true
	# 2. Vạch sang đường (Crosswalks)
	elif (c >= 9 and c <= 15 and r <= 8) or \
	     (c >= 27 and c <= 36 and (r in [28, 42])) or \
	     (c in [22, 37] and r >= 35 and r <= 41):
		surface = "road"
		speed = 1.0
		is_road = true
		is_crosswalk = true
	# 3. Bãi đỗ xe (Parking)
	elif (c >= 15 and c <= 24 and r >= 48 and r <= 54) or \
	     (c >= 39 and c <= 48 and r >= 48 and r <= 54):
		surface = "road"
		speed = 1.0
		is_road = true
		is_parking = true
	# 4. Làn xe buýt (Bus lane)
	elif c <= 12 and r >= 38 and r <= 54:
		surface = "road"
		speed = 1.1
		is_road = true
	# 5. Giao lộ & đường nhựa chính
	elif (c >= 13 and c <= 48 and r >= 17 and r <= 54):
		# Kiểm tra nếu là bờ vỉa hè bao quanh giao lộ
		if (c in [13, 14, 47, 48] and r >= 35 and r <= 41) or \
		   (c >= 27 and c <= 36 and (r in [17, 18, 53, 54])):
			surface = "sidewalk"
			speed = 1.0
			is_sidewalk = true
		else:
			surface = "road"
			speed = 1.0
			is_road = true
	# 6. Vỉa hè / Lối đi lát gạch (Sidewalks)
	elif (c <= 12 and r >= 10 and r <= 23) or \
	     (c >= 19 and c <= 25 and r >= 10 and r <= 16) or \
	     (c >= 12 and c <= 24 and r >= 24 and r <= 30) or \
	     (c >= 43 and c <= 45 and r >= 7 and r <= 9) or \
	     (c >= 58 and c <= 60 and r >= 7 and r <= 9) or \
	     (c >= 52 and c <= 54 and r >= 12 and r <= 14):
		surface = "sidewalk"
		speed = 1.0
		is_sidewalk = true
	# 7. Cỏ xanh (Grass)
	elif (c >= 55 and c <= 57 and r >= 7 and r <= 14) or \
	     (c <= 6 and r >= 24 and r <= 30):
		surface = "grass"
		speed = 0.8
	# 8. Cát (Sand)
	elif (c >= 49 and c <= 51 and r >= 12 and r <= 14) or \
	     (c <= 6 and r >= 31 and r <= 37) or \
	     (c >= 50 and c <= 58 and r >= 51 and r <= 54):
		surface = "sand"
		speed = 0.6
	# 9. Đất nâu (Dirt)
	elif (c >= 52 and c <= 54 and r >= 7 and r <= 9) or \
	     (c >= 46 and c <= 48 and r >= 12 and r <= 14) or \
	     (c >= 6 and c <= 12 and r >= 31 and r <= 37):
		surface = "dirt"
		speed = 0.75
	# 10. Sân bóng rổ (Basketball Court)
	elif c >= 40 and c <= 49 and r <= 8:
		surface = "court"
		speed = 1.0
	# 11. Bục nâng cao / Sân thượng
	elif (c <= 8 and r <= 8) or (c >= 16 and c <= 29 and r <= 8) or (c >= 30 and c <= 39 and r <= 8):
		surface = "platform"
		speed = 1.0
	
	# Gán Custom Data
	td.set_custom_data("surface_type", surface)
	td.set_custom_data("speed_multiplier", speed)
	td.set_custom_data("is_road", is_road)
	td.set_custom_data("is_sidewalk", is_sidewalk)
	td.set_custom_data("is_water", is_water)
	td.set_custom_data("is_crosswalk", is_crosswalk)
	td.set_custom_data("is_parking", is_parking)
	
	# Gán Collision Polygon nếu là vật cản/nước
	if has_collision:
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, col_box)

func _apply_autotile_3x3(atlas: TileSetAtlasSource, origin: Vector2i, terrain_set: int, terrain: int) -> void:
	# Cấu hình 9 ô của khối 3x3
	var peering_patterns = [
		# (0, 0) Top-Left
		[TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		# (1, 0) Top-Center
		[TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		# (2, 0) Top-Right
		[TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		# (0, 1) Middle-Left
		[TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		# (1, 1) Center (All 8)
		[
			TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
			TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
			TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER
		],
		# (2, 1) Middle-Right
		[TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		# (0, 2) Bottom-Left
		[TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		# (1, 2) Bottom-Center
		[TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_TOP_SIDE],
		# (2, 2) Bottom-Right
		[TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_LEFT_SIDE]
	]
	
	var idx = 0
	for dr in range(3):
		for dc in range(3):
			var coord = origin + Vector2i(dc, dr)
			if atlas.has_tile(coord):
				var td = atlas.get_tile_data(coord, 0)
				td.terrain_set = terrain_set
				td.terrain = terrain
				var bits = peering_patterns[idx]
				for b in bits:
					td.set_terrain_peering_bit(b, terrain)
			idx += 1

func _apply_cross_autotile(atlas: TileSetAtlasSource, origin: Vector2i, terrain_set: int, terrain: int) -> void:
	# Khối chữ thập 7x7: Vùng lõi trung tâm 3x3 tại (c+2..c+4, r+2..r+4)
	var center_origin = origin + Vector2i(2, 2)
	_apply_autotile_3x3(atlas, center_origin, terrain_set, terrain)
	
	# Lobe trên: (c+3, r+0), (c+3, r+1)
	for dr in range(2):
		var coord = origin + Vector2i(3, dr)
		if atlas.has_tile(coord):
			var td = atlas.get_tile_data(coord, 0)
			td.terrain_set = terrain_set
			td.terrain = terrain
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, terrain)
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, terrain)
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, terrain)
	
	# Lobe dưới: (c+3, r+5), (c+3, r+6)
	for dr in [5, 6]:
		var coord = origin + Vector2i(3, dr)
		if atlas.has_tile(coord):
			var td = atlas.get_tile_data(coord, 0)
			td.terrain_set = terrain_set
			td.terrain = terrain
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE, terrain)
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, terrain)
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, terrain)
	
	# Lobe trái: (c+0, r+3), (c+1, r+3)
	for dc in range(2):
		var coord = origin + Vector2i(dc, 3)
		if atlas.has_tile(coord):
			var td = atlas.get_tile_data(coord, 0)
			td.terrain_set = terrain_set
			td.terrain = terrain
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, terrain)
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE, terrain)
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, terrain)
	
	# Lobe phải: (c+5, r+3), (c+6, r+3)
	for dc in [5, 6]:
		var coord = origin + Vector2i(dc, 3)
		if atlas.has_tile(coord):
			var td = atlas.get_tile_data(coord, 0)
			td.terrain_set = terrain_set
			td.terrain = terrain
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, terrain)
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE, terrain)
			td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, terrain)
