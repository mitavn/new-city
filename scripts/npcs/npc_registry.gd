extends Node

## Hệ thống Đăng ký và Quản lý Trung tâm cho NPC (NPC Registry & Factory)
## Quản lý toàn bộ cơ sở dữ liệu NPCData, hỗ trợ tìm kiếm và tạo (spawn) NPC linh hoạt.

const NPC_BASE_SCENE: PackedScene = preload("res://scenes/characters/NPCBase.tscn")
const NPC_DATA_DIR: String = "res://data/npcs/"

## Dictionary lưu trữ: key (StringName) -> NPCData
var _registry: Dictionary = {}
## Phân loại theo vai trò: role (StringName) -> Array[NPCData]
var _by_role: Dictionary = {}
## Phân loại theo giới tính: gender (StringName) -> Array[NPCData]
var _by_gender: Dictionary = {}


func _ready() -> void:
	load_all_npc_data()


## Tải tự động toàn bộ tài nguyên NPCData trong thư mục res://data/npcs/
func load_all_npc_data() -> void:
	_registry.clear()
	_by_role.clear()
	_by_gender.clear()

	var dir: DirAccess = DirAccess.open(NPC_DATA_DIR)
	if dir == null:
		push_warning("NPCRegistry: Không thể mở thư mục " + NPC_DATA_DIR)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path: String = NPC_DATA_DIR + file_name
			var res: Resource = load(full_path)
			if res is NPCData:
				var file_key: StringName = StringName(file_name.get_basename())
				register_npc_data(res, file_key)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("NPCRegistry: Đã tải thành công %d NPC vào hệ thống!" % _registry.size())


## Đăng ký thủ công hoặc tự động một NPCData
func register_npc_data(npc_data: NPCData, file_key: StringName = &"") -> void:
	if npc_data == null or npc_data.id.is_empty():
		return

	# Đăng ký theo ID chính
	_registry[npc_data.id] = npc_data

	# Nếu có key tên file riêng (vd: police_male_01), đăng ký thêm alias để tra cứu linh hoạt
	if not file_key.is_empty() and file_key != npc_data.id:
		_registry[file_key] = npc_data

	# Gom nhóm theo role
	var role: StringName = npc_data.role
	if not _by_role.has(role):
		_by_role[role] = [] as Array[NPCData]
	if not _by_role[role].has(npc_data):
		_by_role[role].append(npc_data)

	# Gom nhóm theo gender
	var gender: StringName = npc_data.gender
	if not _by_gender.has(gender):
		_by_gender[gender] = [] as Array[NPCData]
	if not _by_gender[gender].has(npc_data):
		_by_gender[gender].append(npc_data)


## Kiểm tra tồn tại NPC theo ID hoặc Key
func has_npc_data(id_or_key: StringName) -> bool:
	return _registry.has(id_or_key)


## Lấy NPCData theo ID (ví dụ: &"001") hoặc Alias (ví dụ: &"police_male_01")
func get_npc_data(id_or_key: StringName) -> NPCData:
	return _registry.get(id_or_key, null)


## Lấy danh sách toàn bộ NPCData duy nhất
func get_all_npcs() -> Array[NPCData]:
	var result: Array[NPCData] = []
	for item in _registry.values():
		if not result.has(item):
			result.append(item)
	return result


## Lấy danh sách NPC theo vai trò (police, doctor, chef, civilian, v.v.)
func get_npcs_by_role(role: StringName) -> Array[NPCData]:
	return _by_role.get(role, [] as Array[NPCData])


## Lấy danh sách NPC theo giới tính
func get_npcs_by_gender(gender: StringName) -> Array[NPCData]:
	return _by_gender.get(gender, [] as Array[NPCData])


## Factory Method: Tạo mới một đối tượng NPC trong thế giới game
func spawn_npc(id_or_key: StringName, spawn_pos: Vector2 = Vector2.ZERO, parent: Node = null) -> NPCBase:
	var data_res: NPCData = get_npc_data(id_or_key)
	if data_res == null:
		push_error("NPCRegistry: Không tìm thấy NPC với ID '%s' để tạo!" % str(id_or_key))
		return null

	var npc_instance: NPCBase = NPC_BASE_SCENE.instantiate() as NPCBase
	npc_instance.data = data_res
	npc_instance.global_position = spawn_pos

	if parent != null:
		parent.add_child(npc_instance)

	return npc_instance
