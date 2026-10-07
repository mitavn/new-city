class_name CityMapManager
extends Node2D

## Trình Quản Lý Bản Đồ Thành Phố (City Map Manager)
## Quản lý các lớp TileMapLayer và cung cấp API truy vấn dữ liệu địa hình tại tọa độ thế giới.

@export var tile_set: TileSet

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var road_layer: TileMapLayer = $RoadLayer
@onready var decoration_layer: TileMapLayer = $DecorationLayer

const TILE_SIZE: int = 16


func _ready() -> void:
	if not tile_set:
		tile_set = load("res://data/tilesets/city_tileset.tres")
	
	if ground_layer and not ground_layer.tile_set:
		ground_layer.tile_set = tile_set
	if road_layer and not road_layer.tile_set:
		road_layer.tile_set = tile_set
	if decoration_layer and not decoration_layer.tile_set:
		decoration_layer.tile_set = tile_set


## Chuyển đổi tọa độ thế giới sang tọa độ ô tile
func world_to_tile(world_pos: Vector2) -> Vector2i:
	if road_layer:
		return road_layer.local_to_map(road_layer.to_local(world_pos))
	elif ground_layer:
		return ground_layer.local_to_map(ground_layer.to_local(world_pos))
	return Vector2i(floor(world_pos.x / TILE_SIZE), floor(world_pos.y / TILE_SIZE))


## Chuyển đổi tọa độ ô tile sang tọa độ trung tâm thế giới
func tile_to_world(tile_pos: Vector2i) -> Vector2:
	if road_layer:
		return road_layer.to_global(road_layer.map_to_local(tile_pos))
	elif ground_layer:
		return ground_layer.to_global(ground_layer.map_to_local(tile_pos))
	return Vector2((tile_pos.x + 0.5) * TILE_SIZE, (tile_pos.y + 0.5) * TILE_SIZE)


## Lấy TileData ưu tiên từ lớp trên xuống lớp dưới (Decoration -> Road -> Ground)
func get_tile_data_at(world_pos: Vector2) -> TileData:
	var tile_pos = world_to_tile(world_pos)
	
	if decoration_layer:
		var td = decoration_layer.get_cell_tile_data(tile_pos)
		if td:
			return td
	
	if road_layer:
		var td = road_layer.get_cell_tile_data(tile_pos)
		if td:
			return td
			
	if ground_layer:
		var td = ground_layer.get_cell_tile_data(tile_pos)
		if td:
			return td
			
	return null


## Lấy loại bề mặt (road, sidewalk, grass, sand, dirt, water, court, platform)
func get_surface_type(world_pos: Vector2) -> String:
	var td = get_tile_data_at(world_pos)
	if td:
		var surface = td.get_custom_data("surface_type")
		if surface != null and surface != "":
			return str(surface)
	return "unknown"


## Lấy hệ số tốc độ di chuyển tại vị trí thế giới
func get_speed_multiplier(world_pos: Vector2) -> float:
	var td = get_tile_data_at(world_pos)
	if td:
		var mult = td.get_custom_data("speed_multiplier")
		if mult != null and mult is float:
			return mult
	return 1.0


## Kiểm tra có phải mặt đường xe chạy không
func is_road(world_pos: Vector2) -> bool:
	var td = get_tile_data_at(world_pos)
	if td:
		return bool(td.get_custom_data("is_road"))
	return false


## Kiểm tra có phải vỉa hè cho người đi bộ không
func is_sidewalk(world_pos: Vector2) -> bool:
	var td = get_tile_data_at(world_pos)
	if td:
		return bool(td.get_custom_data("is_sidewalk"))
	return false


## Kiểm tra có phải vạch sang đường không
func is_crosswalk(world_pos: Vector2) -> bool:
	var td = get_tile_data_at(world_pos)
	if td:
		return bool(td.get_custom_data("is_crosswalk"))
	return false


## Kiểm tra có phải ô đỗ xe không
func is_parking(world_pos: Vector2) -> bool:
	var td = get_tile_data_at(world_pos)
	if td:
		return bool(td.get_custom_data("is_parking"))
	return false


## Kiểm tra có phải vùng nước không
func is_water(world_pos: Vector2) -> bool:
	var td = get_tile_data_at(world_pos)
	if td:
		return bool(td.get_custom_data("is_water"))
	return false


## Kiểm tra vị trí có đi bộ được không (không phải nước hoặc vật cản)
func is_walkable(world_pos: Vector2) -> bool:
	var td = get_tile_data_at(world_pos)
	if not td:
		return true
	if bool(td.get_custom_data("is_water")):
		return false
	return td.get_collision_polygons_count(0) == 0
