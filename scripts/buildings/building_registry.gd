extends Node

## Singleton Autoload quản lý toàn bộ Tòa Nhà trong game (Building Registry & Factory).
## Đăng ký trong project.godot với tên BuildingRegistry.

var _buildings_by_id: Dictionary = {}
var _buildings_by_type: Dictionary = {}
var _loaded: bool = false


func _ready() -> void:
	load_all_buildings()


func load_all_buildings() -> void:
	if _loaded:
		return

	_buildings_by_id.clear()
	_buildings_by_type.clear()

	var dir: DirAccess = DirAccess.open("res://data/buildings")
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res_path: String = "res://data/buildings/" + file_name
				var data: BuildingData = load(res_path) as BuildingData
				if data and data.id != &"":
					register_building(data)
			file_name = dir.get_next()

	_loaded = true


func register_building(data: BuildingData) -> void:
	if data == null:
		return

	_buildings_by_id[data.id] = data

	var btype: StringName = data.building_type
	if not _buildings_by_type.has(btype):
		_buildings_by_type[btype] = []
	_buildings_by_type[btype].append(data)


func get_building_data(id: StringName) -> BuildingData:
	return _buildings_by_id.get(id, null)


func get_all_buildings() -> Array:
	return _buildings_by_id.values()


func get_by_type(btype: StringName) -> Array:
	return _buildings_by_type.get(btype, [])


func get_two_door_buildings() -> Array:
	var result: Array = []
	for b in _buildings_by_id.values():
		if b is BuildingData and b.is_two_door():
			result.append(b)
	return result


func spawn_building(id: StringName, spawn_position: Vector2, parent: Node = null) -> BuildingBase:
	var b_data: BuildingData = get_building_data(id)
	if b_data == null:
		push_error("BuildingRegistry: Không tìm thấy tòa nhà ID '%s'" % str(id))
		return null

	var base_scene: PackedScene = load("res://scenes/buildings/BuildingBase.tscn")
	var instance: BuildingBase = base_scene.instantiate() as BuildingBase
	instance.data = b_data
	instance.position = spawn_position

	if parent:
		parent.add_child(instance)

	return instance
