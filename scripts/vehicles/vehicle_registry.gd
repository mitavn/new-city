extends Node

## Hệ thống Quản lý và Đăng ký Trung tâm cho Phương Tiện (Vehicle Registry & Factory)
## Tự động quét và lập chỉ mục toàn bộ VehicleData trong res://data/vehicles/

const VEHICLE_BASE_SCENE: PackedScene = preload("res://scenes/vehicles/VehicleBase.tscn")
const VEHICLE_DATA_DIR: String = "res://data/vehicles/"

var _registry: Dictionary = {}
var _by_type: Dictionary = {}
var _by_category: Dictionary = {}


func _ready() -> void:
	load_all_vehicle_data()


## Tải tự động toàn bộ tài nguyên VehicleData
func load_all_vehicle_data() -> void:
	_registry.clear()
	_by_type.clear()
	_by_category.clear()

	var dir: DirAccess = DirAccess.open(VEHICLE_DATA_DIR)
	if dir == null:
		push_warning("VehicleRegistry: Chưa có thư mục " + VEHICLE_DATA_DIR)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path: String = VEHICLE_DATA_DIR + file_name
			var res: Resource = load(full_path)
			if res is VehicleData:
				var file_key: StringName = StringName(file_name.get_basename())
				register_vehicle_data(res, file_key)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("VehicleRegistry: Đã tải thành công %d phương tiện vào hệ thống!" % get_all_vehicles().size())


## Đăng ký dữ liệu phương tiện
func register_vehicle_data(veh_data: VehicleData, file_key: StringName = &"") -> void:
	if veh_data == null or veh_data.id.is_empty():
		return

	_registry[veh_data.id] = veh_data
	if not file_key.is_empty() and file_key != veh_data.id:
		_registry[file_key] = veh_data

	var vtype: StringName = veh_data.vehicle_type
	if not _by_type.has(vtype):
		_by_type[vtype] = [] as Array[VehicleData]
	if not _by_type[vtype].has(veh_data):
		_by_type[vtype].append(veh_data)

	var vcat: StringName = veh_data.category
	if not _by_category.has(vcat):
		_by_category[vcat] = [] as Array[VehicleData]
	if not _by_category[vcat].has(veh_data):
		_by_category[vcat].append(veh_data)


func has_vehicle_data(id_or_key: StringName) -> bool:
	return _registry.has(id_or_key)


func get_vehicle_data(id_or_key: StringName) -> VehicleData:
	return _registry.get(id_or_key, null)


func get_all_vehicles() -> Array[VehicleData]:
	var result: Array[VehicleData] = []
	for item in _registry.values():
		if not result.has(item):
			result.append(item)
	return result


func get_vehicles_by_type(vtype: StringName) -> Array[VehicleData]:
	return _by_type.get(vtype, [] as Array[VehicleData])


func get_vehicles_by_category(category: StringName) -> Array[VehicleData]:
	return _by_category.get(category, [] as Array[VehicleData])


## Factory Method: Tạo mới đối tượng xe vào thế giới game
func spawn_vehicle(id_or_key: StringName, spawn_pos: Vector2 = Vector2.ZERO, parent: Node = null) -> VehicleBase:
	var data_res: VehicleData = get_vehicle_data(id_or_key)
	if data_res == null:
		push_error("VehicleRegistry: Không tìm thấy xe với ID '%s'!" % str(id_or_key))
		return null

	var veh_instance: VehicleBase = VEHICLE_BASE_SCENE.instantiate() as VehicleBase
	veh_instance.data = data_res
	veh_instance.global_position = spawn_pos

	if parent != null:
		parent.add_child(veh_instance)

	return veh_instance
