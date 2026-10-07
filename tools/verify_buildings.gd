extends SceneTree

func _init() -> void:
	print("--- Bắt đầu kiểm tra hệ thống Buildings trong Godot ---")
	
	# 1. Kiểm tra load các tài nguyên .tres
	var dir = DirAccess.open("res://data/buildings")
	var count = 0
	var two_door_count = 0
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res = load("res://data/buildings/" + file_name)
				assert(res != null, "Lỗi load tài nguyên: " + file_name)
				assert(res is BuildingData, "Không phải BuildingData: " + file_name)
				assert(res.sprite_frames != null, "Thiếu sprite_frames: " + file_name)
				count += 1
				if res.door_count >= 2:
					two_door_count += 1
					assert(res.sprite_frames.has_animation("door_left_open"), "Thiếu anim door_left_open: " + file_name)
					assert(res.sprite_frames.has_animation("door_right_open"), "Thiếu anim door_right_open: " + file_name)
				else:
					assert(res.sprite_frames.has_animation("door_open"), "Thiếu anim door_open: " + file_name)
					assert(res.sprite_frames.has_animation("door_close"), "Thiếu anim door_close: " + file_name)
			file_name = dir.get_next()
	print("✓ Đã nạp thành công %d tài nguyên BuildingData (%d tòa 2 cửa)!" % [count, two_door_count])
	
	# 2. Kiểm tra load building_test_scene.tscn
	var scene_res = load("res://scenes/test/building_test_scene.tscn")
	assert(scene_res != null, "Không thể load building_test_scene.tscn")
	var scene_inst = scene_res.instantiate()
	assert(scene_inst != null, "Không thể instantiate building_test_scene.tscn")
	root.add_child(scene_inst)
	print("✓ Đã instantiate thành công building_test_scene.tscn")
	
	# 3. Kiểm tra các node tòa nhà bên trong
	var container = scene_inst.get_node("BuildingContainer")
	assert(container != null, "Không tìm thấy BuildingContainer")
	var bld_count = 0
	for child in container.get_children():
		if child is BuildingBase:
			bld_count += 1
			assert(child.data != null, "Tòa nhà thiếu BuildingData: " + child.name)
			assert(child.visual.sprite_frames != null, "Thiếu visual frames: " + child.name)
			
			# Test đóng mở cửa
			child.open_door(0)
			child.close_door(0)
			if child.data.door_count >= 2:
				child.open_door(1)
				child.close_door(1)
				child.open_all_doors()
				child.close_all_doors()
	print("✓ Đã kiểm tra thành công toàn bộ %d nodes tòa nhà trong Test Scene!" % bld_count)
	
	print("🎉 TẤT CẢ KIỂM TRA BUILDINGS ĐỀU VƯỢT QUA XUẤT SẮC!")
	quit(0)
