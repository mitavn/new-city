class_name DialogueBubble
extends Node2D

## Bong Bóng Hội Thoại & Hiệu Ứng Máy Đánh Chữ Trong Thế Giới (In-World Dialogue Bubble & Typewriter Effect).
## Tích hợp:
## 1. Khung bong bóng lời thoại tự co giãn theo độ dài văn bản với đuôi trỏ về nhân vật.
## 2. Hiệu ứng Typewriter gõ từng chữ chân thực kèm nhịp ngắt câu (dấu phẩy, chấm, hỏi).
## 3. Đồng bộ âm thanh gõ chữ dễ thương từ audio/dialogue/dialogue_bloop_01-08.wav.
## 4. Bỏ qua nhanh khi bấm phím và tự biến mất êm dịu sau khi đọc xong.

signal typing_started
signal typing_completed
signal bubble_dismissed

@export_category("Bubble Layout")
@export var offset_y: float = -52.0
@export var max_width: float = 340.0
@export var padding: Vector2 = Vector2(18.0, 7.0)

@export_category("Typewriter Settings")
@export var chars_per_second: float = 34.0
@export var pause_comma: float = 0.12
@export var pause_period: float = 0.25
@export var play_typing_sounds: bool = true
@export var auto_dismiss_delay: float = 3.5

# Node References
var panel: PanelContainer = null
var label: Label = null
var audio_player: AudioStreamPlayer2D = null

# State variables
var _full_text: String = ""
var _current_char_index: int = 0
var _char_timer: float = 0.0
var _is_typing: bool = false
var _dismiss_timer: float = 0.0
var _bloops: Array[AudioStream] = []
var _tween: Tween = null


func _ready() -> void:
	z_index = 50
	position = Vector2(0, offset_y)
	_setup_ui_nodes()
	_load_bloop_sounds()
	visible = false


func _setup_ui_nodes() -> void:
	# Khung bong bóng đối thoại
	panel = PanelContainer.new()
	panel.name = "BubblePanel"
	
	# Phong cách hộp thoại Pixel RPG - Tone Silver kim loại thanh lịch
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.15, 0.94) # Nền than chì / slate tối
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.80, 0.85, 0.92, 0.98) # Viền bạc sáng bóng (Metallic Silver)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = padding.x
	style.content_margin_right = padding.x
	style.content_margin_top = padding.y
	style.content_margin_bottom = padding.y
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)

	label = Label.new()
	label.name = "DialogueLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(80, 0)
	
	# Font chữ LiberationSans chuẩn dự án - Kích cỡ nhỏ thanh lịch (font_size 10)
	var font = load("res://assets/fonts/LiberationSans.ttf")
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98, 1))

	panel.add_child(label)
	add_child(panel)

	# Nguồn phát âm thanh thoại 2D
	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "DialogueAudio"
	audio_player.max_distance = 400.0
	audio_player.attenuation = 1.0
	add_child(audio_player)


func _load_bloop_sounds() -> void:
	for i in range(1, 9):
		var p = "res://audio/dialogue/dialogue_bloop_0%d.wav" % i
		if ResourceLoader.exists(p):
			var s = load(p)
			if s:
				_bloops.append(s)


func _process(delta: float) -> void:
	if not visible:
		return

	# Cập nhật căn giữa vị trí bong bóng phía trên đầu nhân vật, giới hạn bề ngang max_width
	if panel:
		if panel.size.x > max_width and label.custom_minimum_size.x < (max_width - padding.x * 2.0):
			label.custom_minimum_size.x = max_width - (padding.x * 2.0)
		panel.position = Vector2(-panel.size.x * 0.5, -panel.size.y)

	if _is_typing:
		_char_timer -= delta
		if _char_timer <= 0.0:
			_advance_typewriter()
	else:
		if auto_dismiss_delay > 0.0:
			_dismiss_timer -= delta
			if _dismiss_timer <= 0.0:
				dismiss()


## Bắt đầu hiển thị câu thoại với hiệu ứng Typewriter
func say(text: String, custom_speed: float = 0.0, custom_dismiss_delay: float = -1.0) -> void:
	_full_text = text
	_current_char_index = 0
	_is_typing = true
	_char_timer = 0.0
	chars_per_second = custom_speed if custom_speed > 0.0 else 34.0
	if custom_dismiss_delay >= 0.0:
		auto_dismiss_delay = custom_dismiss_delay

	label.text = ""
	visible = true
	modulate.a = 1.0
	scale = Vector2(0.2, 0.2)

	# Hiệu ứng nảy vào (Pop-in)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.06)

	typing_started.emit()


## Nhảy trực tiếp tới toàn bộ câu thoại (Skip / Fast-forward)
func skip_to_end() -> void:
	if _is_typing:
		label.text = _full_text
		_is_typing = false
		_dismiss_timer = auto_dismiss_delay
		typing_completed.emit()


func _advance_typewriter() -> void:
	if _current_char_index >= _full_text.length():
		_is_typing = false
		_dismiss_timer = auto_dismiss_delay
		typing_completed.emit()
		return

	_current_char_index += 1
	label.text = _full_text.substr(0, _current_char_index)

	var last_char = _full_text[_current_char_index - 1]

	# Nhịp ngắt câu tự nhiên theo dấu câu
	if last_char in [".", "!", "?"]:
		_char_timer = pause_period
	elif last_char in [",", ";", ":"]:
		_char_timer = pause_comma
	else:
		_char_timer = 1.0 / max(chars_per_second, 1.0)

	# Phát âm thanh bloop gõ chữ
	if play_typing_sounds and last_char != " " and not _bloops.is_empty():
		# Chỉ phát ngắt quãng mỗi 2 ký tự để âm thanh nhịp nhàng không bị rối
		if _current_char_index % 2 == 1:
			_play_random_bloop()


func _play_random_bloop() -> void:
	if audio_player and not _bloops.is_empty():
		audio_player.stream = _bloops.pick_random()
		audio_player.pitch_scale = randf_range(0.95, 1.05)
		audio_player.play()


## Đóng bong bóng hội thoại với hiệu ứng thu nhỏ và làm mờ
func dismiss() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.14)
	_tween.tween_callback(func():
		visible = false
		bubble_dismissed.emit()
	)


## Vẽ đuôi bong bóng trỏ xuống đầu nhân vật
func _draw() -> void:
	if panel and visible:
		# Điểm chân bong bóng - Tone Silver kim loại
		var p1 = Vector2(-5, 0)
		var p2 = Vector2(5, 0)
		var p3 = Vector2(0, 7)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(0.80, 0.85, 0.92, 0.98))
		draw_colored_polygon(PackedVector2Array([p1 + Vector2(1, -1), p2 + Vector2(-1, -1), p3 + Vector2(0, -1)]), Color(0.09, 0.11, 0.15, 0.94))


## Static Helper: Hiển thị nhanh một câu thoại bong bóng trên bất kỳ Node2D nào
static func speak_above(target: Node2D, text: String, dismiss_delay: float = 3.5) -> Node2D:
	if target == null or not is_instance_valid(target):
		return null

	var bubble = target.get_node_or_null("DialogueBubble")
	if bubble == null:
		var script_res = load("res://scripts/ui/DialogueBubble.gd")
		bubble = script_res.new()
		bubble.name = "DialogueBubble"
		target.add_child(bubble)

	if bubble.has_method("say"):
		bubble.say(text, 34.0, dismiss_delay)
	return bubble

