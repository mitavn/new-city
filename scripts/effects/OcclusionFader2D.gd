class_name OcclusionFader2D
extends Area2D

## Bộ Làm Mờ Vật Thể 2D Khi Người Chơi Đi Phía Sau (2D Occluder Fade).
## Tự động phát hiện khi Player bước vào vùng bị khuất tầm nhìn (phía sau tòa nhà / vật thể),
## thực hiện hiệu ứng Tween làm mờ êm dịu (fade opacity) giúp người chơi luôn nhìn thấy
## nhân vật của mình, và khôi phục độ mờ khi bước ra ngoài.

signal occlusion_state_changed(is_occluded: bool)

@export_category("Fader Settings")
@export var target_node: CanvasItem = null
@export var faded_alpha: float = 0.35
@export var normal_alpha: float = 1.0
@export var fade_duration: float = 0.22
@export var target_group: StringName = &"player"

var _occluding_bodies: Array[Node2D] = []
var _tween: Tween = null


func _ready() -> void:
	if target_node == null:
		target_node = get_parent() as CanvasItem

	collision_layer = 0
	collision_mask = 2 # Detect layer 2 (NPCs / Player)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body == target_node or not is_instance_valid(body):
		return

	if body.is_in_group(target_group) or body.name.to_lower().contains("player"):
		if not _occluding_bodies.has(body):
			_occluding_bodies.append(body)
		_apply_fade(true)


func _on_body_exited(body: Node2D) -> void:
	if _occluding_bodies.has(body):
		_occluding_bodies.erase(body)

	if _occluding_bodies.is_empty():
		_apply_fade(false)


func _apply_fade(should_fade: bool) -> void:
	if target_node == null or not is_instance_valid(target_node):
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()

	var dest_alpha: float = faded_alpha if should_fade else normal_alpha
	_tween = create_tween()
	_tween.tween_property(target_node, "modulate:a", dest_alpha, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	occlusion_state_changed.emit(should_fade)


## Tự động thiết lập vùng che khuất dựa trên kích thước khung hình và va chạm chân đế
func setup_auto_occlusion_shape(visual_height: float, base_width: float, base_y_offset: float = -10.0) -> void:
	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col_shape == null:
		col_shape = CollisionShape2D.new()
		col_shape.name = "CollisionShape2D"
		add_child(col_shape)

	var rect: RectangleShape2D = RectangleShape2D.new()
	# Chiều cao vùng che khuất là phần nóc/thân tòa nhà nhô lên khỏi chân đế
	var occlude_height: float = max(visual_height * 0.75, 48.0)
	rect.size = Vector2(base_width * 1.05, occlude_height)
	col_shape.shape = rect
	# Đặt tâm vùng che khuất nằm phía trên chân đế
	col_shape.position = Vector2(0, base_y_offset - (occlude_height * 0.5) - 6.0)
