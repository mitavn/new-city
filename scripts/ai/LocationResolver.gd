class_name LocationResolver
extends RefCounted

## Tra cứu và Định vị Điểm Quan Trọng trong Đô Thị (Points of Interest - POI).
## Tự động tìm kiếm toạ độ cửa các toà nhà hoặc các điểm mốc đô thị theo tag.

## Bản đồ toạ độ mặc định cho Bến Cảng Thượng Hải & Thành Phố (Shanghai Harbor Fallbacks)
const HARBOR_POI_COORDS: Dictionary = {
	&"customs": Vector2(380, 230),
	&"customs_office": Vector2(380, 230),
	&"ramen": Vector2(610, 220),
	&"ramen_stand": Vector2(610, 220),
	&"police": Vector2(450, 120),
	&"police_station": Vector2(450, 120),
	&"bank": Vector2(180, 120),
	&"the_bund_bank": Vector2(180, 120),
	&"warehouse": Vector2(720, 120),
	&"cargo_warehouse": Vector2(720, 120),
	&"pub": Vector2(940, 120),
	&"sailor_pub": Vector2(940, 120),
	&"lighthouse": Vector2(980, 420),
	&"ferry_pier": Vector2(250, 480),
	&"container_yard": Vector2(520, 260),
	&"taxi_stand": Vector2(160, 220),
	&"promenade": Vector2(420, 310)
}

## Tìm toạ độ mục tiêu từ một POI tag trong thế giới game
static func resolve_poi_position(tree: SceneTree, poi_tag: StringName, fallback_pos: Vector2 = Vector2.ZERO) -> Vector2:
	if poi_tag.is_empty():
		return fallback_pos

	var tag_str: String = str(poi_tag).to_lower()

	# 1. Thử quét trong các Building trong scene hiện tại
	if tree != null:
		var buildings = tree.get_nodes_in_group(&"buildings")
		for b in buildings:
			var bname = b.name.to_lower()
			var b_id = str(b.data.id).to_lower() if b.get("data") and b.data.get("id") else ""
			if bname.contains(tag_str) or b_id.contains(tag_str):
				# Nếu tòa nhà có vị trí cửa, trả về vị trí trước cửa
				if b.get("data") and b.data.get("door_positions") and not b.data.door_positions.is_empty():
					return b.global_position + b.data.door_positions[0] + Vector2(0, 16)
				return b.global_position + Vector2(0, 24)

	# 2. Sử dụng bản đồ toạ độ mặc định
	if HARBOR_POI_COORDS.has(poi_tag):
		return HARBOR_POI_COORDS[poi_tag]

	for key in HARBOR_POI_COORDS.keys():
		if str(key).contains(tag_str) or tag_str.contains(str(key)):
			return HARBOR_POI_COORDS[key]

	return fallback_pos
