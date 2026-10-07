class_name MotionTrail2D
extends Node2D

## Hiệu Ứng Vệt Chuyển Động / Tàn Ảnh (Motion Trail / Ghost Afterimage).
## Tự động sinh bóng mờ (ghost silhouettes) khi nhân vật di chuyển nhanh hoặc lướt (Dash / Sprint).
## Tạo cảm giác hành động mượt mà, sống động chuẩn pixel RPG.

@export_category("Trail Settings")
@export var target_sprite: CanvasItem = null
@export var emitting: bool = false
@export var min_speed_threshold: float = 120.0
@export var spawn_interval: float = 0.045
@export var trail_duration: float = 0.22
@export var trail_color: Color = Color(0.45, 0.8, 1.0, 0.65)
@export var max_ghosts: int = 10

var _spawn_timer: float = 0.0
var _active_ghosts: Array[Node2D] = []


func _ready() -> void:
	if target_sprite == null:
		var parent = get_parent()
		if parent:
			target_sprite = parent.get_node_or_null("Visual") as CanvasItem
			if target_sprite == null and (parent is Sprite2D or parent is AnimatedSprite2D):
				target_sprite = parent


func _physics_process(delta: float) -> void:
	var parent_body = get_parent() as CharacterBody2D
	var is_moving_fast: bool = false
	
	if parent_body != null:
		var current_speed: float = parent_body.velocity.length()
		is_moving_fast = current_speed >= min_speed_threshold

	var should_emit: bool = emitting or is_moving_fast

	if should_emit and target_sprite != null:
		_spawn_timer += delta
		if _spawn_timer >= spawn_interval:
			_spawn_timer = 0.0
			spawn_ghost_snapshot()
	else:
		_spawn_timer = 0.0


## Tạo một bóng ma tàn ảnh tại vị trí hiện tại
func spawn_ghost_snapshot() -> void:
	if target_sprite == null or not is_instance_valid(target_sprite):
		return

	if _active_ghosts.size() >= max_ghosts:
		var oldest = _active_ghosts.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var ghost: Sprite2D = Sprite2D.new()
	ghost.top_level = true
	ghost.global_position = target_sprite.global_position
	ghost.global_rotation = target_sprite.global_rotation
	ghost.global_scale = target_sprite.global_scale
	ghost.z_index = max(target_sprite.z_index - 1, 0)
	ghost.modulate = trail_color

	# Sao chép Frame Texture tương ứng
	if target_sprite is AnimatedSprite2D:
		var anim_sprite: AnimatedSprite2D = target_sprite as AnimatedSprite2D
		if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_sprite.animation):
			var tex: Texture2D = anim_sprite.sprite_frames.get_frame_texture(anim_sprite.animation, anim_sprite.frame)
			ghost.texture = tex
		ghost.flip_h = anim_sprite.flip_h
		ghost.flip_v = anim_sprite.flip_v
		ghost.offset = anim_sprite.offset
	elif target_sprite is Sprite2D:
		var s: Sprite2D = target_sprite as Sprite2D
		ghost.texture = s.texture
		ghost.region_enabled = s.region_enabled
		ghost.region_rect = s.region_rect
		ghost.flip_h = s.flip_h
		ghost.flip_v = s.flip_v
		ghost.offset = s.offset

	var root_scene = get_tree().current_scene
	if root_scene:
		root_scene.add_child(ghost)
	else:
		get_tree().root.add_child(ghost)

	_active_ghosts.append(ghost)

	# Hiệu ứng mờ dần (Fade out tween)
	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, trail_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		_active_ghosts.erase(ghost)
		if is_instance_valid(ghost):
			ghost.queue_free()
	)
