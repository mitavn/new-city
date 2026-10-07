@tool
extends SceneTree

func _init():
	var scene = load("res://scenes/test/node_2d.tscn").instantiate()
	var ground: TileMapLayer = scene.get_node_or_null("ground")

	# Inspect area around (37, 41) and (42, 41)
	print("--- INSPECTING (35..45, 38..44) ---")
	for y in range(38, 44):
		var row = "y=%d: " % y
		for x in range(35, 45):
			var coords = ground.get_cell_atlas_coords(Vector2i(x, y))
			row += "(%2d,%2d) " % [coords.x, coords.y]
		print(row)

	scene.free()
	quit(0)
