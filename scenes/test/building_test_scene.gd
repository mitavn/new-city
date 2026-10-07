extends Node2D

## Script điều khiển Test Scene cho toàn bộ 45 Tòa Nhà Đô Thị (Buildings)
## Hỗ trợ điều hướng Camera, mở/đóng đồng loạt, mở độc lập cửa trái/cửa phải và xem chi tiết thông số.

@onready var camera: Camera2D = $Camera2D
@onready var building_container: Node2D = $BuildingContainer
@onready var background: ColorRect = $Background
@onready var info_panel: PanelContainer = $CanvasLayer/InfoBox
@onready var name_label: Label = $CanvasLayer/InfoBox/MarginContainer/VBoxContainer/Header/NameLabel
@onready var type_label: Label = $CanvasLayer/InfoBox/MarginContainer/VBoxContainer/Header/TypeLabel
@onready var content_label: Label = $CanvasLayer/InfoBox/MarginContainer/VBoxContainer/ContentLabel
@onready var stats_label: Label = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/StatsLabel
@onready var toggle_all_button: Button = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/ToggleAllButton
@onready var door_left_button: Button = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/DoorLeftButton
@onready var door_right_button: Button = $CanvasLayer/TopPanel/MarginContainer/HBoxContainer/DoorRightButton

var is_dragging_camera: bool = false
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_camera_pos: Vector2 = Vector2.ZERO
var camera_speed: float = 750.0
var all_doors_open_state: bool = false
var info_timer: float = 0.0


func _ready() -> void:
	if background:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if info_panel:
		info_panel.visible = false

	_connect_building_signals()
	_update_stats()


func _process(delta: float) -> void:
	_handle_keyboard_camera_movement(delta)

	if info_panel and info_panel.visible:
		info_timer -= delta
		if info_timer <= 0.0:
			info_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			_on_toggle_all_doors_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			_on_door_left_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			_on_door_right_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3 or event.keycode == KEY_C:
			close_all_doors()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F:
			_on_reset_camera_pressed()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_dragging_camera = true
				drag_start_mouse_pos = event.position
				drag_start_camera_pos = camera.position
			else:
				is_dragging_camera = false

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
	target_zoom.x = clampf(target_zoom.x, 0.25, 3.0)
	target_zoom.y = clampf(target_zoom.y, 0.25, 3.0)
	camera.zoom = target_zoom


func _connect_building_signals() -> void:
	for child in building_container.get_children():
		if child is BuildingBase:
			child.interacted.connect(_on_building_interacted.bind(child))


func _on_building_interacted(door_index: int, _visitor: Node, bld: BuildingBase) -> void:
	_show_building_info(bld, door_index)


func _show_building_info(bld: BuildingBase, door_index: int = 0) -> void:
	if bld == null or bld.data == null or info_panel == null:
		return

	var d: BuildingData = bld.data
	name_label.text = d.display_name
	type_label.text = "[%s - %s]" % [str(d.building_type).to_upper(), str(d.color_variant).to_upper()]

	var door_desc: String = ""
	if d.door_count >= 2:
		var d0_status: String = "Đang MỞ" if bld.door_0_open else "Đang ĐÓNG"
		var d1_status: String = "Đang MỞ" if bld.door_1_open else "Đang ĐÓNG"
		door_desc = "• Cửa 1 (%s): %s\n• Cửa 2 (%s): %s" % [d.get_door_name(0), d0_status, d.get_door_name(1), d1_status]
	else:
		var status: String = "Đang MỞ" if bld.door_0_open else "Đang ĐÓNG"
		door_desc = "• %s: %s" % [d.get_door_name(0), status]

	var desc: String = "%s\n\n%s\n• Kích thước Frame: %dx%d px\n• Chân đế va chạm: %dx%d px\n• Vừa tương tác: %s" % [
		d.description,
		door_desc,
		d.frame_size.x, d.frame_size.y,
		int(d.collision_size.x), int(d.collision_size.y),
		d.get_door_name(door_index)
	]

	content_label.text = desc
	info_panel.visible = true
	info_timer = 6.0


func _update_stats() -> void:
	var total: int = 0
	var two_doors: int = 0
	for child in building_container.get_children():
		if child is BuildingBase:
			total += 1
			if child.data and child.data.is_two_door():
				two_doors += 1
	if stats_label:
		stats_label.text = "Tổng: %d Tòa Nhà (%d tòa 2 cửa) | Space/E: Mở/Đóng Tất Cả | Phím 1/2: Mở Cửa 1 / Cửa 2 | Click cửa: Tương tác" % [total, two_doors]


func _on_toggle_all_doors_pressed() -> void:
	all_doors_open_state = not all_doors_open_state
	for child in building_container.get_children():
		if child is BuildingBase:
			if all_doors_open_state:
				child.open_all_doors()
			else:
				child.close_all_doors()
	if toggle_all_button:
		toggle_all_button.text = "Đóng Hết (Space)" if all_doors_open_state else "Mở Hết (Space)"


func _on_door_left_pressed() -> void:
	for child in building_container.get_children():
		if child is BuildingBase:
			child.open_door(0)


func _on_door_right_pressed() -> void:
	for child in building_container.get_children():
		if child is BuildingBase and child.data and child.data.is_two_door():
			child.open_door(1)


func close_all_doors() -> void:
	all_doors_open_state = false
	for child in building_container.get_children():
		if child is BuildingBase:
			child.close_all_doors()
	if toggle_all_button:
		toggle_all_button.text = "Mở Hết (Space)"


func _on_reset_camera_pressed() -> void:
	camera.position = Vector2(1600, 1100)
	camera.zoom = Vector2(0.55, 0.55)
