class_name NPCSteering
extends RefCounted

## Bộ Điều Khiển Lái Tự Nhiên & Né Tránh Vật Cản (Natural Steering & Obstacle Avoidance).
## Áp dụng mô hình Reynolds Steering kết hợp cảm biến râu (Whisker Raycast Sensing),
## lực tách mềm giữa các NPC (Soft Separation) và trượt mượt mà theo chân tường/vật cản (Wall Sliding).

const COLLISION_MASK_OBSTACLES: int = 1 | 2 | 8 | 16 ## World (1), NPC (2), Vehicle (8), Building (16)

# Cấu hình 7 cảm biến râu đa hướng quét vật cản và góc cạnh
const WHISKER_ANGLES: Array[float] = [
	0.0,
	deg_to_rad(28.0), deg_to_rad(-28.0),
	deg_to_rad(56.0), deg_to_rad(-56.0),
	deg_to_rad(82.0), deg_to_rad(-82.0)
]
const WHISKER_LENGTHS: Array[float] = [42.0, 34.0, 34.0, 26.0, 26.0, 20.0, 20.0]

## Tính toán vận tốc di chuyển mượt mà hướng tới mục tiêu và né tránh vật cản
static func compute_natural_velocity(
	npc: CharacterBody2D,
	target_pos: Vector2,
	current_velocity: Vector2,
	max_speed: float,
	acceleration: float,
	arrival_radius: float,
	delta: float,
	is_stuck: bool = false
) -> Vector2:
	if npc == null:
		return Vector2.ZERO

	var current_pos: Vector2 = npc.global_position
	var to_target: Vector2 = target_pos - current_pos
	var distance: float = to_target.length()

	# 1. Nếu đã tới rất gần đích (trong vòng 5px), hãm dừng tự nhiên
	if distance < 5.0:
		return current_velocity.move_toward(Vector2.ZERO, acceleration * 2.0 * delta)

	# 2. Lực tìm đường (Seek force) kết hợp Giảm tốc khi đến gần (Arrival behavior)
	var desired_speed: float = max_speed
	if distance < arrival_radius:
		var factor: float = distance / max(arrival_radius, 1.0)
		desired_speed = max_speed * ease(factor, 0.6)
		desired_speed = max(desired_speed, 14.0)

	var desired_dir: Vector2 = to_target.normalized()
	var desired_velocity: Vector2 = desired_dir * desired_speed

	# 3. Phản hồi va chạm vật lý trực tiếp (Slide Collision Feedback)
	# Giải quyết triệt để vấn đề NPC bị kẹt vào góc tường hoặc dính vào nhau!
	var slide_repulsion: Vector2 = Vector2.ZERO
	var wall_tangent: Vector2 = Vector2.ZERO
	var col_count: int = npc.get_slide_collision_count()
	
	if col_count > 0:
		for i in range(col_count):
			var col = npc.get_slide_collision(i)
			var normal: Vector2 = col.get_normal()
			var collider = col.get_collider()

			if collider is CharacterBody2D:
				# Tách mềm khi 2 NPC hoặc Xe cộ va chạm: Đẩy nhẹ nhau ra 2 hướng
				var push: Vector2 = (current_pos - collider.global_position).normalized()
				if push.length_squared() < 0.01:
					push = normal
				slide_repulsion += push * 55.0
			else:
				# Va chạm với tường/nhà/vật cản tĩnh: Trượt mượt mà dọc theo tiếp tuyến (Tangent)
				var tangent: Vector2 = Vector2(-normal.y, normal.x)
				if tangent.dot(desired_dir) < 0.0:
					tangent = -tangent
				wall_tangent += tangent * 50.0

	if slide_repulsion.length_squared() > 0.01:
		desired_velocity = (desired_velocity * 0.45 + slide_repulsion * 0.85).limit_length(max_speed)
	elif wall_tangent.length_squared() > 0.01:
		desired_velocity = (desired_velocity * 0.35 + wall_tangent * 0.85).normalized() * max_speed

	# 4. Cảm biến quét vật cản từ xa bằng tia râu (Whisker Raycasting)
	var space_state = npc.get_world_2d().direct_space_state
	if space_state != null and col_count == 0:
		var avoidance_force: Vector2 = _evaluate_whiskers(npc, space_state, desired_dir, current_pos)
		if avoidance_force.length_squared() > 0.001:
			var blend_dir: Vector2 = (desired_dir * 0.4 + avoidance_force * 0.85).normalized()
			desired_velocity = blend_dir * (desired_speed * 0.85)

	# 5. Cơ chế giải cứu tự động khi bị kẹt (Unstuck recovery)
	if is_stuck:
		# Bước chéo 90 độ so với hướng đích để lách ra khỏi góc kẹt
		var escape_dir: Vector2 = Vector2(-desired_dir.y, desired_dir.x)
		if randf() > 0.5:
			escape_dir = -escape_dir
		desired_velocity = escape_dir * (max_speed * 0.95)

	# 6. Gia tốc mượt mà 8 hướng (Smooth 8-Way Acceleration)
	return current_velocity.move_toward(desired_velocity, acceleration * delta)


## Bắn 7 tia râu để khảo sát không gian vật cản xung quanh hướng di chuyển
static func _evaluate_whiskers(
	npc: CharacterBody2D,
	space_state: PhysicsDirectSpaceState2D,
	forward_dir: Vector2,
	origin: Vector2
) -> Vector2:
	var total_avoidance: Vector2 = Vector2.ZERO
	var hits_count: int = 0
	
	var exclude_rids: Array[RID] = [npc.get_rid()]

	for i in range(WHISKER_ANGLES.size()):
		var angle_offset: float = WHISKER_ANGLES[i]
		var length: float = WHISKER_LENGTHS[i]
		var ray_dir: Vector2 = forward_dir.rotated(angle_offset).normalized()
		var ray_end: Vector2 = origin + ray_dir * length

		var query = PhysicsRayQueryParameters2D.create(origin, ray_end, COLLISION_MASK_OBSTACLES, exclude_rids)
		query.collide_with_areas = false
		query.collide_with_bodies = true

		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			var hit_normal: Vector2 = result["normal"]
			var hit_dist: float = origin.distance_to(result["position"])
			var hit_weight: float = clampf(1.0 - (hit_dist / length), 0.25, 1.0)
			
			var side_avoid: Vector2 = hit_normal * (1.6 * hit_weight)
			if i == 0:
				side_avoid += Vector2(-ray_dir.y, ray_dir.x) * (0.9 * hit_weight)
			
			total_avoidance += side_avoid
			hits_count += 1

	if hits_count > 0:
		return total_avoidance.normalized()

	return Vector2.ZERO
