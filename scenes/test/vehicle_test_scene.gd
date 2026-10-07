extends Node2D

## Script điều khiển Test Scene cho toàn bộ 24 Phương Tiện (Vehicles)
## Hỗ trợ điều hướng Camera, đổi hướng đồng loạt 4 hướng 2.5D, bật/tắt còi Siren và xem chi tiết thông số xe.

@onready var camera: Camera2D = $Camera2D
@onready var vehicle_container: Node2D = $VehicleContainer
@onready var background: ColorRect = $Background
@onready var info_panel: PanelContainer = $CanvasLayer/InfoBox
@onready var name_label: Label = $CanvasLayer/InfoBox/MarginContainer/VBoxContainer/Header/NameLabel
@onready var type_label: Label = $CanvasLayer/InfoBox/MarginContainer/VBoxContainer/Header/TypeLabel
@onready var content_label: Label = $CanvasLayer/InfoBox/MarginContainer/VBoxContainer/ContentLabel
@onready var stats_label: Label = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/StatsLabel
@onready var siren_button: Button = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/SirenButton
@onready var rotate_button: Button = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/RotateButton

var is_dragging_camera: bool = false
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_camera_pos: Vector2 = Vector2.ZERO
var camera_speed: float = 700.0
var global_siren_active: bool = false
var info_timer: float = 0.0

const DIRECTION_NAMES: Array[String] = [
	"front_right",
	"front_left",
	"back",
	"front"
]

const DIRECTION_LABELS: Array[String] = [
	"Trước-Phải",
	"Trước-Trái",
	"Phía Sau (Lên)",
	"Phía Trước (Xuống)"
]

var current_dir_idx: int = 0


func _ready() -> void:
	if background:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if info_panel:
		info_panel.visible = false

	_connect_vehicle_signals()
	_update_stats()
	_update_rotate_button_text()
	_update_siren_button_text()


func _process(delta: float) -> void:
	_handle_keyboard_camera_movement(delta)

	if info_panel and info_panel.visible:
		info_timer -= delta
		if info_timer <= 0.0:
			info_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	# Phím tắt đổi hướng nhanh
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_on_rotate_direction_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			set_all_vehicles_direction("front_right")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			set_all_vehicles_direction("front_left")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			set_all_vehicles_direction("back")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_4:
			set_all_vehicles_direction("front")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_E:
			_on_siren_button_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F:
			_on_reset_camera_pressed()
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
	target_zoom.x = clampf(target_zoom.x, 0.35, 3.0)
	target_zoom.y = clampf(target_zoom.y, 0.35, 3.0)
	camera.zoom = target_zoom


func _connect_vehicle_signals() -> void:
	for child in vehicle_container.get_children():
		if child is VehicleBase:
			child.interacted.connect(_on_vehicle_interacted.bind(child))


func _on_vehicle_interacted(_driver: Node, veh: VehicleBase) -> void:
	_show_vehicle_info(veh)


func _show_vehicle_info(veh: VehicleBase) -> void:
	if veh == null or veh.data == null or info_panel == null:
		return

	var d: VehicleData = veh.data
	name_label.text = d.display_name
	type_label.text = "[%s - %s]" % [str(d.vehicle_type).to_upper(), str(d.category).to_upper()]

	var siren_str: String = "CÓ (Đang " + ("BẬT)" if veh.siren_active else "TẮT)") if d.has_siren else "KHÔNG CÓ"
	var desc: String = "%s\n\n• Kích thước Frame: %dx%d px\n• Kích thước va chạm: %dx%d px\n• Tốc độ tối đa: %d px/s\n• Sức chứa: %d người\n• Còi ưu tiên (Siren): %s" % [
		d.description,
		d.frame_size.x, d.frame_size.y,
		int(d.collision_size.x), int(d.collision_size.y),
		int(d.max_speed),
		d.passenger_capacity,
		siren_str
	]

	content_label.text = desc
	info_panel.visible = true
	info_timer = 6.0


func _update_stats() -> void:
	var count: int = 0
	for child in vehicle_container.get_children():
		if child is VehicleBase:
			count += 1
	if stats_label:
		stats_label.text = "Tổng: %d Phương Tiện | Phím R / 1-4: Đổi hướng | Phím Space/E: Còi Siren | Click xe: Thông số" % count


func _on_siren_button_pressed() -> void:
	global_siren_active = not global_siren_active
	for child in vehicle_container.get_children():
		if child is VehicleBase and child.data and child.data.has_siren:
			child.siren_active = global_siren_active
	_update_siren_button_text()


func _update_siren_button_text() -> void:
	if siren_button:
		siren_button.text = "Còi Siren: " + ("BẬT (Space/E)" if global_siren_active else "TẮT (Space/E)")


func _on_rotate_direction_pressed() -> void:
	current_dir_idx = (current_dir_idx + 1) % DIRECTION_NAMES.size()
	set_all_vehicles_direction(DIRECTION_NAMES[current_dir_idx])


func set_all_vehicles_direction(dir_name: String) -> void:
	var idx: int = DIRECTION_NAMES.find(dir_name)
	if idx != -1:
		current_dir_idx = idx

	for child in vehicle_container.get_children():
		if child is VehicleBase:
			child.set_direction_by_name(dir_name)

	_update_rotate_button_text()


func _update_rotate_button_text() -> void:
	if rotate_button:
		rotate_button.text = "Hướng: %s (Phím R)" % DIRECTION_LABELS[current_dir_idx]


func _on_reset_camera_pressed() -> void:
	camera.position = Vector2(750, 580)
	camera.zoom = Vector2(0.85, 0.85)
