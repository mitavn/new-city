class_name NPCEmote
extends Node2D

## Bộ Điều Khiển Biểu Cảm NPC (NPCEmote Component).
## Tích hợp hiển thị hoạt ảnh biểu cảm Data-Driven (EmoteRegistry),
## hiệu ứng pop-in nảy mầm, lơ lửng nhẹ và âm thanh vòm 2D tương ứng từ Audio Pack.

signal emote_started(emote_id: StringName)
signal emote_finished(emote_id: StringName)

@export var offset_y: float = -44.0
@export var play_sound_effects: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null

var current_emote_id: StringName = &""
var _tween: Tween = null
var _bob_time: float = 0.0
var _is_active: bool = false
var _base_y: float = -44.0

const EMOTE_SOUND_MAP: Dictionary = {
	&"exclamation": "res://audio/dialogue/npc_alert.wav",
	&"alert": "res://audio/dialogue/npc_alert.wav",
	&"happy": "res://audio/dialogue/npc_happy.wav",
	&"sad": "res://audio/dialogue/npc_sad.wav",
	&"angry": "res://audio/dialogue/npc_angry.wav",
	&"question": "res://audio/dialogue/npc_question.wav",
	&"idea": "res://audio/dialogue/npc_surprised.wav",
	&"star": "res://audio/items/reward.wav",
	&"heart": "res://audio/items/rare_item.wav",
	&"check": "res://audio/ui/ui_confirm.wav",
	&"speech_dots": "res://audio/dialogue/dialogue_bloop_03.wav"
}


func _ready() -> void:
	_base_y = offset_y
	position = Vector2(0, _base_y)
	z_index = 45

	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		add_child(sprite)

	if audio_player == null:
		audio_player = AudioStreamPlayer2D.new()
		audio_player.name = "AudioStreamPlayer2D"
		audio_player.max_distance = 450.0
		audio_player.attenuation = 1.2
		add_child(audio_player)

	visible = false


func _process(delta: float) -> void:
	if _is_active and visible:
		# Hiệu ứng dập dềnh nhẹ (Bobbing float)
		_bob_time += delta * 4.5
		position.y = _base_y + sin(_bob_time) * 2.0


## Phát biểu cảm theo emote_id từ EmoteRegistry
func play_emote(emote_id: StringName, duration: float = 2.2, play_audio: bool = true) -> void:
	current_emote_id = emote_id
	_base_y = offset_y
	_bob_time = 0.0

	var emote_data: EmoteData = null
	if has_node("/root/EmoteRegistry"):
		var reg = get_node("/root/EmoteRegistry")
		emote_data = reg.get_emote(emote_id)

	if emote_data != null and emote_data.sprite_frames != null:
		sprite.sprite_frames = emote_data.sprite_frames
		sprite.play(&"play")
	else:
		# Fallback từ EmoteBubble frames
		var eb = load("res://scenes/test/emote_bubble.gd")
		if eb and eb.has_method("get_emote_sprite_frames"):
			sprite.sprite_frames = eb.get_emote_sprite_frames()
			var anim_str = str(emote_id)
			if sprite.sprite_frames.has_animation(anim_str):
				sprite.play(anim_str)
			else:
				sprite.play("speech_dots")

	# Phát âm thanh tương ứng
	if play_sound_effects and play_audio:
		_play_associated_audio(emote_id)

	# Bật hiển thị và kích hoạt hiệu ứng pop-in nảy nhẹ
	visible = true
	_is_active = true
	modulate.a = 1.0
	sprite.scale = Vector2(0.2, 0.2)

	if _tween != null and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(sprite, "scale", Vector2(1.22, 1.22), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.08)

	# Chờ hết thời lượng rồi làm mờ dần
	var dur = duration if duration > 0.0 else (emote_data.default_duration if emote_data else 2.2)
	_tween.tween_interval(dur)
	_tween.tween_property(self, "position:y", _base_y - 12.0, 0.32)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.32)
	_tween.tween_callback(func():
		visible = false
		_is_active = false
		emote_finished.emit(current_emote_id)
	)

	emote_started.emit(current_emote_id)


func stop_emote() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = false
	_is_active = false


func _play_associated_audio(emote_id: StringName) -> void:
	if audio_player == null:
		return

	var path: String = EMOTE_SOUND_MAP.get(emote_id, "res://audio/dialogue/dialogue_bloop_02.wav")
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			audio_player.stream = stream
			audio_player.pitch_scale = randf_range(0.96, 1.04)
			audio_player.play()


## Static Helper: Tự động gắn hoặc lấy NPCEmote trên bất kỳ Node2D nào và phát emote
static func show_on(target: Node2D, emote_id: StringName, duration: float = 2.2) -> Node2D:
	if target == null or not is_instance_valid(target):
		return null

	var emote_node = target.get_node_or_null("NPCEmote")
	if emote_node == null:
		var script_res = load("res://scripts/emotes/NPCEmote.gd")
		emote_node = script_res.new()
		emote_node.name = "NPCEmote"
		target.add_child(emote_node)

	if emote_node.has_method("play_emote"):
		emote_node.play_emote(emote_id, duration)
	return emote_node

