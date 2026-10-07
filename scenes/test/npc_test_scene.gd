extends Node2D

## Script điều khiển Test Scene cho toàn bộ 44 NPC
## Hỗ trợ điều hướng Camera, tương tác hội thoại, bật/tắt di chuyển và đổi hướng quay mặt.

@onready var camera: Camera2D = $Camera2D
@onready var npc_container: Node2D = $NPCContainer
@onready var background: ColorRect = $Background
@onready var dialogue_panel: PanelContainer = $CanvasLayer/DialogueBox
@onready var name_label: Label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/Header/NameLabel
@onready var role_label: Label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/Header/RoleLabel
@onready var content_label: Label = $CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/ContentLabel
@onready var stats_label: Label = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/StatsLabel
@onready var wander_button: Button = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/WanderButton
@onready var rotate_button: Button = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/RotateButton

var is_dragging_camera: bool = false
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_camera_pos: Vector2 = Vector2.ZERO
var camera_speed: float = 600.0
var wander_enabled: bool = false
var dialogue_timer: float = 0.0

const DIRECTION_NAMES: Array[String] = [
	"front_right",
	"front_left",
	"back_right",
	"back_left"
]

const DIRECTION_LABELS: Array[String] = [
	"Trước-Phải",
	"Trước-Trái",
	"Sau-Phải",
	"Sau-Trái"
]

var current_dir_idx: int = 0


func _ready() -> void:
	if background:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	dialogue_panel.visible = false
	_connect_npc_signals()
	_update_stats()
	_apply_wander_mode(wander_enabled)
	_update_rotate_button_text()


func _process(delta: float) -> void:
	_handle_keyboard_camera_movement(delta)

	if dialogue_panel.visible:
		dialogue_timer -= delta
		if dialogue_timer <= 0.0:
			dialogue_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	# Phím tắt đổi hướng nhanh: Phím R để xoay vòng, phím 1 2 3 4 cho từng hướng
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_on_rotate_direction_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			set_all_npcs_direction("front_right")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			set_all_npcs_direction("front_left")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			set_all_npcs_direction("back_right")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_4:
			set_all_npcs_direction("back_left")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE:
			_on_wander_button_pressed()
			get_viewport().set_input_as_handled()

	# Kéo chuột giữa hoặc chuột phải để di chuyển camera
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_dragging_camera = true
				drag_start_mouse_pos = event.position
				drag_start_camera_pos = camera.position
			else:
				is_dragging_camera = false

		# Cuộn chuột để phóng to / thu nhỏ
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(1.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(1.0 / 1.15)

	elif event is InputEventMouseMotion and is_dragging_camera:
		var diff: Vector2 = (event.position - drag_start_mouse_pos) / camera.zoom.x
		camera.position = drag_start_camera_pos - diff


func _handle_keyboard_camera_movement(delta: float) -> void:
	var move_vec: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vec.y += 1.0

	if move_vec.length_squared() > 0.0:
		camera.position += move_vec.normalized() * (camera_speed / camera.zoom.x) * delta


func _zoom_camera(factor: float) -> void:
	var target_zoom: Vector2 = camera.zoom * factor
	target_zoom.x = clampf(target_zoom.x, 0.5, 3.5)
	target_zoom.y = clampf(target_zoom.y, 0.5, 3.5)
	camera.zoom = target_zoom


func _connect_npc_signals() -> void:
	for child in npc_container.get_children():
		if child is NPCBase:
			child.interacted.connect(_on_npc_interacted.bind(child))
			child.dialogue_spoken.connect(_on_npc_dialogue_spoken.bind(child))


func _on_npc_interacted(_initiator: Node, npc: NPCBase) -> void:
	_show_dialogue(npc, npc.get_dialogue_line())


func _on_npc_dialogue_spoken(line: String, npc: NPCBase) -> void:
	_show_dialogue(npc, line)


func _show_dialogue(npc: NPCBase, text: String) -> void:
	if npc == null or npc.data == null:
		return

	name_label.text = npc.data.display_name
	role_label.text = "[%s - %s]" % [str(npc.data.role).to_upper(), str(npc.data.gender).to_upper()]
	content_label.text = '"%s"' % text
	dialogue_panel.visible = true
	dialogue_timer = 5.0


func _update_stats() -> void:
	var count: int = 0
	for child in npc_container.get_children():
		if child is NPCBase:
			count += 1
	stats_label.text = "Tổng: %d NPC | Phím R / 1-4: Đổi hướng | Click NPC: Nói chuyện | Phím WASD: Camera" % count


func _on_wander_button_pressed() -> void:
	wander_enabled = not wander_enabled
	_apply_wander_mode(wander_enabled)
	wander_button.text = "Tự do đi dạo: BẬT" if wander_enabled else "Tự do đi dạo: TẮT"


func _apply_wander_mode(enabled: bool) -> void:
	for child in npc_container.get_children():
		if child is NPCBase:
			child.auto_wander = enabled
			if not enabled:
				child.current_state = NPCBase.State.IDLE
				child.velocity = Vector2.ZERO


## Đổi xoay vòng hướng tiếp theo
func _on_rotate_direction_pressed() -> void:
	current_dir_idx = (current_dir_idx + 1) % DIRECTION_NAMES.size()
	set_all_npcs_direction(DIRECTION_NAMES[current_dir_idx])


## Đặt hướng cho toàn bộ NPC
func set_all_npcs_direction(dir_name: String) -> void:
	var idx: int = DIRECTION_NAMES.find(dir_name)
	if idx != -1:
		current_dir_idx = idx

	for child in npc_container.get_children():
		if child is NPCBase:
			child.set_direction_by_name(dir_name)

	_update_rotate_button_text()


func _update_rotate_button_text() -> void:
	if rotate_button:
		rotate_button.text = "Hướng: %s (Phím R)" % DIRECTION_LABELS[current_dir_idx]


func _on_reset_camera_pressed() -> void:
	camera.position = Vector2(650, 290)
	camera.zoom = Vector2(1.2, 1.2)
