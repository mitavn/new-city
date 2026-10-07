extends Node2D

## Emote Bubble Controller (Hệ thống biểu cảm tương tác cho NPC & Thực thể)
## Sử dụng spritesheet Character Emoteicon-Sheet.png
## Cấu trúc chuẩn của Spritesheet:
## - Kích thước tổng: 128 x 336 px
## - Mỗi hàng: 1 biểu cảm gồm 4 frame hoạt ảnh thở / nhấp nháy
## - Kích thước mỗi frame: 32 px chiều rộng x 16 px chiều cao (Rect2(col * 32, row * 16, 32, 16))

const EMOTE_SHEET_PATH: String = "res://assets/spritesheets/characters/Character Emoteicon-Sheet.png"
static var _shared_frames: SpriteFrames = null

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D


## Khởi tạo và lưu cache SpriteFrames cho tất cả các loại biểu cảm (32x16, 4 frames)
static func get_emote_sprite_frames() -> SpriteFrames:
	if _shared_frames != null:
		return _shared_frames

	var tex: Texture2D = null
	if ResourceLoader.exists(EMOTE_SHEET_PATH):
		tex = load(EMOTE_SHEET_PATH)
	if tex == null:
		var img = Image.load_from_file(EMOTE_SHEET_PATH)
		if img:
			tex = ImageTexture.create_from_image(img)

	if tex == null:
		push_warning("EmoteBubble: Không tìm thấy Character Emoteicon-Sheet.png")
		return null

	var sf = SpriteFrames.new()
	var row_to_names = {
		0: ["heart", "love"],
		1: ["happy", "smile"],
		2: ["neutral"],
		3: ["sad"],
		4: ["angry"],
		5: ["exclamation", "alert"],
		6: ["question"],
		7: ["speech_dots", "dots"],
		8: ["music"],
		9: ["sleep", "zzz"],
		10: ["sweat"],
		11: ["check", "yes"],
		12: ["cross", "no"],
		13: ["badge"],
		14: ["sing"],
		15: ["laugh"],
		16: ["star"],
		17: ["swirl"],
		18: ["lightning"],
		19: ["spark"],
		20: ["idea", "lightbulb"]
	}

	for row in range(21):
		var names = row_to_names.get(row, ["emote_%d" % row])
		var main_name = names[0]
		sf.add_animation(main_name)
		sf.set_animation_speed(main_name, 5.0)
		sf.set_animation_loop(main_name, true)

		for col in range(4):
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * 32, row * 16, 32, 16)
			sf.add_frame(main_name, atlas)

		# Đăng ký các tên alias phụ
		for i in range(1, names.size()):
			var alias_name = names[i]
			sf.add_animation(alias_name)
			sf.set_animation_speed(alias_name, 5.0)
			sf.set_animation_loop(alias_name, true)
			for col in range(4):
				var atlas = AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = Rect2(col * 32, row * 16, 32, 16)
				sf.add_frame(alias_name, atlas)

	_shared_frames = sf
	return _shared_frames


## Tạo và hiển thị một emote bubble nổi trên đầu đối tượng
static func spawn_emote(target_node: Node2D, anim_name: String = "speech_dots", offset_y: float = -42.0) -> Node2D:
	if target_node == null or not is_instance_valid(target_node):
		return null

	# Dọn emote cũ nếu đang hiển thị
	for child in target_node.get_children():
		if child.name.begins_with("EmoteBubble_"):
			child.queue_free()

	var bubble = Node2D.new()
	bubble.name = "EmoteBubble_" + anim_name
	bubble.z_index = 40
	bubble.position = Vector2(0, offset_y)

	var anim = AnimatedSprite2D.new()
	anim.sprite_frames = get_emote_sprite_frames()
	if anim.sprite_frames and anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	elif anim.sprite_frames and anim.sprite_frames.has_animation("speech_dots"):
		anim.play("speech_dots")

	bubble.add_child(anim)
	target_node.add_child(bubble)

	# Hiệu ứng nảy (pop-in scale)
	anim.scale = Vector2(0.2, 0.2)
	var tween = bubble.create_tween()
	tween.tween_property(anim, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(anim, "scale", Vector2(1.0, 1.0), 0.08)

	# Nổi nhẹ lên trên và mờ dần sau 2.2 giây
	var float_tween = bubble.create_tween()
	float_tween.tween_interval(2.0)
	float_tween.tween_property(bubble, "position:y", offset_y - 12.0, 0.4)
	float_tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.4)
	float_tween.tween_callback(bubble.queue_free)

	return bubble
