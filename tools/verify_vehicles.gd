extends SceneTree

func _init() -> void:
	print("--- Bắt đầu kiểm tra hệ thống Vehicles trong Godot ---")
	
	# 1. Kiểm tra load các tài nguyên .tres
	var dir = DirAccess.open("res://data/vehicles")
	var count = 0
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res = load("res://data/vehicles/" + file_name)
				assert(res != null, "Lỗi load tài nguyên: " + file_name)
				assert(res is VehicleData, "Không phải VehicleData: " + file_name)
				assert(res.sprite_frames != null, "Thiếu sprite_frames: " + file_name)
				count += 1
			file_name = dir.get_next()
	print("✓ Đã nạp thành công %d tài nguyên VehicleData (.tres)" % count)
	
	# 2. Kiểm tra load VehicleTestScene.tscn
	var scene_res = load("res://scenes/test/vehicle_test_scene.tscn")
	assert(scene_res != null, "Không thể load vehicle_test_scene.tscn")
	var scene_inst = scene_res.instantiate()
	assert(scene_inst != null, "Không thể instantiate vehicle_test_scene.tscn")
	root.add_child(scene_inst)
	print("✓ Đã instantiate thành công vehicle_test_scene.tscn")
	
	# 3. Kiểm tra các node xe bên trong
	var container = scene_inst.get_node("VehicleContainer")
	assert(container != null, "Không tìm thấy VehicleContainer")
	var veh_count = 0
	for child in container.get_children():
		if child is VehicleBase:
			veh_count += 1
			assert(child.data != null, "Xe thiếu VehicleData: " + child.name)
			assert(child.visual.sprite_frames != null, "Xe thiếu visual frames: " + child.name)
			
			# Test đổi hướng
			child.set_direction_by_name("back")
			child.set_direction_by_name("front_left")
			child.set_direction_by_name("front")
			child.set_direction_by_name("front_right")
			
			# Test siren nếu có
			if child.data.has_siren:
				child.siren_active = true
				child.siren_active = false
	print("✓ Đã kiểm tra thành công toàn bộ %d nodes xe trong Test Scene!" % veh_count)
	
	print("🎉 TẤT CẢ KIỂM TRA ĐỀU VƯỢT QUA XUẤT SẮC!")
	quit(0)
