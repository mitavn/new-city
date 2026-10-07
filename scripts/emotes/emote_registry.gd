extends Node

## Hệ thống Quản Lý và Đăng Ký Trung Tâm Biểu Cảm (Emote Registry & Factory)
## Data-Driven cho Quest, Sự kiện, Đối thoại và Tương tác.
## Tự động tải từ res://data/emotes/ hoặc khởi tạo đầy đủ 21 loại biểu cảm chuẩn.

const EMOTE_DATA_DIR: String = "res://data/emotes/"
const DEFAULT_SHEET_PATH: String = "res://assets/spritesheets/characters/Character Emoteicon-Sheet.png"

var _registry: Dictionary = {}        ## id (StringName) -> EmoteData
var _by_category: Dictionary = {}    ## category (StringName) -> Array[EmoteData]
var _by_tag: Dictionary = {}         ## tag (StringName) -> Array[EmoteData]
var _sheet_texture: Texture2D = null


func _ready() -> void:
	load_all_emotes()


func load_all_emotes() -> void:
	_registry.clear()
	_by_category.clear()
	_by_tag.clear()

	_ensure_texture_loaded()

	# 1. Tải các file .tres trong data/emotes/ nếu có
	var dir = DirAccess.open(EMOTE_DATA_DIR)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(EMOTE_DATA_DIR + file_name)
				if res is EmoteData:
					register_emote(res)
			file_name = dir.get_next()
		dir.list_dir_end()

	# 2. Nếu chưa có hoặc thiếu, tự động đăng ký các Emote chuẩn & Quest
	_register_default_emotes_if_needed()
	print("EmoteRegistry: Đã tải thành công %d biểu cảm vào hệ thống!" % _registry.size())


func _ensure_texture_loaded() -> void:
	if _sheet_texture != null:
		return
	if ResourceLoader.exists(DEFAULT_SHEET_PATH):
		_sheet_texture = load(DEFAULT_SHEET_PATH)
	if _sheet_texture == null:
		var img = Image.load_from_file(DEFAULT_SHEET_PATH)
		if img:
			_sheet_texture = ImageTexture.create_from_image(img)


func register_emote(emote: EmoteData) -> void:
	if emote == null or emote.id.is_empty():
		return

	# Tạo sprite_frames nếu chưa có
	if emote.sprite_frames == null and _sheet_texture != null:
		emote.sprite_frames = EmoteData.build_sprite_frames_from_texture(
			_sheet_texture,
			emote.row_index,
			emote.frame_size,
			emote.frame_count,
			emote.fps
		)

	_registry[emote.id] = emote

	# Phân loại category
	if not _by_category.has(emote.category):
		_by_category[emote.category] = []
	_by_category[emote.category].append(emote)

	# Phân loại tags
	for tag in emote.tags:
		var tag_name = StringName(tag)
		if not _by_tag.has(tag_name):
			_by_tag[tag_name] = []
		_by_tag[tag_name].append(emote)


func get_emote(id_or_tag: StringName) -> EmoteData:
	if _registry.has(id_or_tag):
		return _registry[id_or_tag]
	if _by_tag.has(id_or_tag) and not _by_tag[id_or_tag].is_empty():
		return _by_tag[id_or_tag][0]
	return null


func has_emote(id_name: StringName) -> bool:
	return _registry.has(id_name)


## Kích hoạt hiển thị biểu cảm nổi trên đối tượng phục vụ Quest / Hội thoại
func spawn_emote(target_node: Node2D, emote_id_or_tag: StringName, custom_duration: float = 0.0) -> Node2D:
	if target_node == null or not is_instance_valid(target_node):
		return null

	var emote: EmoteData = get_emote(emote_id_or_tag)
	if emote == null:
		# Fallback thử lấy speech_dots
		emote = get_emote(&"speech_dots")
		if emote == null:
			return null

	# Dọn emote cũ trên đối tượng nếu có
	for child in target_node.get_children():
		if child.name.begins_with("EmoteBubble_"):
			child.queue_free()

	var bubble = Node2D.new()
	bubble.name = "EmoteBubble_" + str(emote.id)
	bubble.z_index = 45
	bubble.position = Vector2(0, emote.offset_y)

	var anim = AnimatedSprite2D.new()
	anim.sprite_frames = emote.sprite_frames
	anim.play(&"play")
	bubble.add_child(anim)
	target_node.add_child(bubble)

	# Hiệu ứng nảy vào (pop-in)
	anim.scale = Vector2(0.2, 0.2)
	var tween = bubble.create_tween()
	tween.tween_property(anim, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(anim, "scale", Vector2(1.0, 1.0), 0.08)

	# Nổi nhẹ lên và mờ dần biến mất
	var dur = custom_duration if custom_duration > 0.0 else emote.default_duration
	var float_tween = bubble.create_tween()
	float_tween.tween_interval(dur)
	float_tween.tween_property(bubble, "position:y", emote.offset_y - 14.0, 0.35)
	float_tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.35)
	float_tween.tween_callback(bubble.queue_free)

	return bubble


func _register_default_emotes_if_needed() -> void:
	var defs = [
		{"id": &"heart", "name": "Yêu Thích / Cảm Ơn", "row": 0, "cat": &"mood", "tags": ["love", "thanks", "quest_complete"]},
		{"id": &"happy", "name": "Vui Vẻ / Thân Thiện", "row": 1, "cat": &"mood", "tags": ["smile", "friendly"]},
		{"id": &"neutral", "name": "Bình Thường", "row": 2, "cat": &"mood", "tags": ["normal"]},
		{"id": &"sad", "name": "Buồn Rầu / Thất Vọng", "row": 3, "cat": &"mood", "tags": ["cry", "fail"]},
		{"id": &"angry", "name": "Giận Dữ / Bất Bình", "row": 4, "cat": &"mood", "tags": ["rage"]},
		{"id": &"exclamation", "name": "Chấm Than / Cảnh Báo", "row": 5, "cat": &"quest", "tags": ["alert", "taxi_call", "quest_start"]},
		{"id": &"question", "name": "Thắc Mắc / Tìm Đường", "row": 6, "cat": &"quest", "tags": ["ask", "quest_help"]},
		{"id": &"speech_dots", "name": "Đang Nói / Suy Nghĩ", "row": 7, "cat": &"action", "tags": ["talk", "wait", "dots"]},
		{"id": &"music", "name": "Giai Điệu / Thư Thái", "row": 8, "cat": &"mood", "tags": ["song"]},
		{"id": &"sleep", "name": "Ngái Ngủ", "row": 9, "cat": &"status", "tags": ["zzz", "tired"]},
		{"id": &"sweat", "name": "Lo Lắng / Toát Mồ Hôi", "row": 10, "cat": &"mood", "tags": ["nervous"]},
		{"id": &"check", "name": "Đồng Ý / Hoàn Thành", "row": 11, "cat": &"quest", "tags": ["yes", "done", "boarded"]},
		{"id": &"sing", "name": "Ca Hát", "row": 14, "cat": &"action", "tags": ["joy"]},
		{"id": &"star", "name": "Xuất Sắc / Tiền Thưởng", "row": 16, "cat": &"quest", "tags": ["reward", "cash", "paid"]},
		{"id": &"lightning", "name": "Bất Ngờ / Sốc", "row": 18, "cat": &"reaction", "tags": ["shock"]},
		{"id": &"idea", "name": "Ý Tưởng / Sáng Kiến", "row": 20, "cat": &"quest", "tags": ["lightbulb", "plan", "patrol"]}
	]

	for d in defs:
		if not _registry.has(d["id"]):
			var e = EmoteData.new()
			e.id = d["id"]
			e.display_name = d["name"]
			e.row_index = d["row"]
			e.category = d["cat"]
			e.tags = PackedStringArray(d["tags"])
			register_emote(e)
