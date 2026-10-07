class_name PoliceLifeManager
extends Node

## Hệ thống Mô phỏng Đời sống Cảnh sát Tokyo (Tokyo Police Life Sim System)
## Quản lý:
## - Cấp bậc cảnh sát (Rank), Điểm uy tín công dân (Reputation), Số vụ việc đã giải quyết
## - Đồng hồ thời gian ca trực thành phố (Sim City Clock: 08:00 - 22:00)
## - Tổng đài Bộ Đàm Cảnh Sát 110 (Police Radio Dispatch): Phát tín hiệu nhiệm vụ điều động tuần tra
## - Cơ chế Lên/Xuống xe cảnh sát tuần tra (Police Cruiser Drive mode)
## - Thông báo sự vụ & hội thoại khen thưởng

signal incident_dispatched(incident_data: Dictionary)
signal incident_resolved(incident_name: String, reputation_gained: int)
signal police_rank_promoted(new_rank: String)
signal police_drive_state_changed(is_driving: bool)
signal sim_clock_updated(time_str: String, shift_name: String)

enum RankLevel {
	PATROL_OFFICER,    # Hạ sĩ Tuần tra (0 - 49 điểm)
	SERGEANT,          # Trung sĩ Trưởng ca (50 - 149 điểm)
	LIEUTENANT,        # Thiếu úy Điều tra (150 - 299 điểm)
	CAPTAIN,           # Đại úy Trưởng đồn (300 - 499 điểm)
	POLICE_CHIEF       # Cảnh sát trưởng Tokyo (500+ điểm)
}

const RANK_TITLES: Dictionary = {
	RankLevel.PATROL_OFFICER: "Hạ Sĩ Tuần Tra (Patrol Officer)",
	RankLevel.SERGEANT: "Trung Sĩ Trưởng Ca (Sergeant)",
	RankLevel.LIEUTENANT: "Thiếu Úy Điều Tra (Lieutenant)",
	RankLevel.CAPTAIN: "Đại Úy Trưởng Đồn (Captain)",
	RankLevel.POLICE_CHIEF: "Cảnh Sát Trưởng Tokyo (Chief of Police)"
}

var current_rank: RankLevel = RankLevel.PATROL_OFFICER
var civic_reputation: int = 0
var resolved_cases_count: int = 0

# Sim Clock (Bắt đầu 08:00)
var sim_hour: int = 8
var sim_minute: int = 0
var _sim_timer: float = 0.0
const REAL_SEC_PER_SIM_MINUTE: float = 1.0 # 1 giây thực = 1 phút game

# Trạng thái nhiệm vụ điều động hiện tại
var active_incident: Dictionary = {}
var is_incident_active: bool = false
var _incident_cooldown: float = 8.0

# Trạng thái lái xe cảnh sát
var is_driving_police_car: bool = false
var boarded_police_car: Node2D = null

# Danh sách sự vụ mô phỏng phong phú tại các địa điểm Tokyo
var incident_pool: Array[Dictionary] = [
	{
		"id": "inc_mall_security",
		"title": "Bảo vệ an ninh sảnh Shibuya Central Mall",
		"location_name": "Sảnh Trung tâm Thương mại Shibuya Mall",
		"target_pos": Vector2(480, 240),
		"radius": 100.0,
		"dialogue": "[Bảo vệ Mall]: Cảm ơn Sĩ quan! Có sự xuất hiện của anh giúp tình hình an ninh tại sảnh mua sắm ổn định ngay lập tức.",
		"reward": 25,
		"dialogue_speaker": "Vệ sĩ Mall"
	},
	{
		"id": "inc_ramen_dispute",
		"title": "Nhắc nhở trật tự tại Hẻm Mì Ramen Akihabara",
		"location_name": "Quán Mì Ramen Akihabara",
		"target_pos": Vector2(1760, 260),
		"radius": 90.0,
		"dialogue": "[Chủ quán Mì]: Ôi may quá, cảm ơn Sĩ quan đã nhắc nhở khách xếp hàng ngay ngắn. Xin mời anh ghé ăn thử bát ramen nóng hổi!",
		"reward": 20,
		"dialogue_speaker": "Đầu bếp Ramen"
	},
	{
		"id": "inc_park_lost_child",
		"title": "Hỗ trợ bé gái tìm người thân tại Công viên Yoyogi",
		"location_name": "Đài phun nước Công viên Yoyogi",
		"target_pos": Vector2(620, 960),
		"radius": 110.0,
		"dialogue": "[Cư dân công viên]: Cảm ơn chú cảnh sát! Bé gái đã tìm lại được mẹ rồi. Chú cảnh sát Tokyo thật tuyệt vời!",
		"reward": 35,
		"dialogue_speaker": "Bác Tư Công Viên"
	},
	{
		"id": "inc_hospital_escort",
		"title": "Điều tiết lối vào khẩn cấp Bệnh viện Tokyo",
		"location_name": "Lối vào Cấp cứu Bệnh viện Đa khoa",
		"target_pos": Vector2(2100, 960),
		"radius": 100.0,
		"dialogue": "[Bác sĩ Hà]: Cảm ơn Sĩ quan đã dọn đường thông thoáng, xe cấp cứu vừa đưa bệnh nhân vào an toàn kịp thời!",
		"reward": 30,
		"dialogue_speaker": "Bác sĩ Trực"
	},
	{
		"id": "inc_dock_cargo_check",
		"title": "Kiểm tra an ninh hàng hóa Cầu Cảng Odaiba",
		"location_name": "Bến Cảng Hàng Hóa & Đê Hải Đăng Odaiba",
		"target_pos": Vector2(2360, 1380),
		"radius": 120.0,
		"dialogue": "[Thủy thủ Cảng]: Chào Sĩ quan! Toàn bộ container tàu cập bến hôm nay đều hợp lệ và niêm phong an toàn.",
		"reward": 25,
		"dialogue_speaker": "Thủy thủ Cảng"
	},
	{
		"id": "inc_traffic_scramble",
		"title": "Điều tiết giao thông Ngã tư Shibuya Scramble",
		"location_name": "Ngã tư Đại Lộ Shibuya",
		"target_pos": Vector2(1100, 640),
		"radius": 100.0,
		"dialogue": "[Người đi bộ]: Cảm ơn Sĩ quan đã điều tiết đèn tín hiệu. Giờ cao điểm hôm nay qua đường rất trật tự và an toàn!",
		"reward": 20,
		"dialogue_speaker": "Người đi bộ"
	}
]


func _process(delta: float) -> void:
	_update_sim_clock(delta)
	
	if not is_incident_active:
		_incident_cooldown -= delta
		if _incident_cooldown <= 0.0:
			trigger_random_incident()


## Cập nhật đồng hồ ca trực
func _update_sim_clock(delta: float) -> void:
	_sim_timer += delta
	if _sim_timer >= REAL_SEC_PER_SIM_MINUTE:
		_sim_timer -= REAL_SEC_PER_SIM_MINUTE
		sim_minute += 1
		if sim_minute >= 60:
			sim_minute = 0
			sim_hour += 1
			if sim_hour >= 24:
				sim_hour = 6 # Bắt đầu ca mới lúc 06:00 sáng
		
		var time_str = "%02d:%02d" % [sim_hour, sim_minute]
		var shift = "Ca Sáng (Day Patrol)"
		if sim_hour >= 18 or sim_hour < 6:
			shift = "Ca Đêm (Night Patrol)"
		elif sim_hour >= 12:
			shift = "Ca Chiều (Afternoon Duty)"
			
		sim_clock_updated.emit(time_str, shift)


## Phát tín hiệu nhiệm vụ điều động ngẫu nhiên từ Tổng đài 110
func trigger_random_incident() -> void:
	if is_incident_active or incident_pool.is_empty():
		return
		
	var idx = randi() % incident_pool.size()
	active_incident = incident_pool[idx]
	is_incident_active = true
	_incident_cooldown = 20.0 # Thời gian chờ sau khi giải quyết
	
	incident_dispatched.emit(active_incident)


## Kiểm tra và giải quyết sự vụ khi cảnh sát đến vị trí
func check_and_resolve_incident_at(player_pos: Vector2) -> bool:
	if not is_incident_active or active_incident.is_empty():
		return false
		
	var target_pos: Vector2 = active_incident.get("target_pos", Vector2.ZERO)
	var radius: float = active_incident.get("radius", 100.0)
	
	if player_pos.distance_to(target_pos) <= radius:
		resolve_current_incident()
		return true
	return false


## Giải quyết sự vụ thành công
func resolve_current_incident() -> void:
	if not is_incident_active:
		return
		
	var inc_title: String = active_incident.get("title", "Sự vụ")
	var rew: int = active_incident.get("reward", 20)
	
	civic_reputation += rew
	resolved_cases_count += 1
	is_incident_active = false
	_incident_cooldown = 15.0
	
	_check_rank_promotion()
	incident_resolved.emit(inc_title, rew)


## Kiểm tra thăng cấp bậc cảnh sát
func _check_rank_promotion() -> void:
	var old_rank = current_rank
	if civic_reputation >= 500:
		current_rank = RankLevel.POLICE_CHIEF
	elif civic_reputation >= 300:
		current_rank = RankLevel.CAPTAIN
	elif civic_reputation >= 150:
		current_rank = RankLevel.LIEUTENANT
	elif civic_reputation >= 50:
		current_rank = RankLevel.SERGEANT
	else:
		current_rank = RankLevel.PATROL_OFFICER
		
	if current_rank != old_rank:
		police_rank_promoted.emit(get_rank_title())


func get_rank_title() -> String:
	return RANK_TITLES.get(current_rank, "Sĩ quan")


## Chuyển đổi trạng thái Lên/Xuống xe cảnh sát tuần tra
func toggle_police_car_drive(player_node: CharacterBody2D, car_node: Node2D) -> bool:
	if is_driving_police_car:
		# Xuống xe
		is_driving_police_car = false
		if is_instance_valid(boarded_police_car):
			boarded_police_car.velocity = Vector2.ZERO
			if "current_state" in boarded_police_car:
				boarded_police_car.current_state = 1 # VehicleState.IDLE
			if "siren_active" in boarded_police_car:
				boarded_police_car.siren_active = false
				
		if is_instance_valid(player_node):
			player_node.visible = true
			if "enable_player_input" in player_node:
				player_node.enable_player_input = true
			player_node.collision_layer = player_node.get_meta(&"orig_col_layer", 2)
			player_node.collision_mask = player_node.get_meta(&"orig_col_mask", 3)
			var col = player_node.get_node_or_null("BodyCollision") as CollisionShape2D
			if col:
				col.set_deferred("disabled", false)
			if is_instance_valid(boarded_police_car):
				player_node.global_position = boarded_police_car.global_position + Vector2(28, 16)
			player_node.velocity = Vector2.ZERO

		boarded_police_car = null
		police_drive_state_changed.emit(false)
		return false
	else:
		# Lên xe
		if car_node == null or not is_instance_valid(car_node):
			return false
		is_driving_police_car = true
		boarded_police_car = car_node
		
		if "current_state" in car_node:
			car_node.current_state = 2 # VehicleState.DRIVING
		if "siren_active" in car_node:
			car_node.siren_active = true

		if is_instance_valid(player_node):
			player_node.visible = false
			if "enable_player_input" in player_node:
				player_node.enable_player_input = false
			player_node.set_meta(&"orig_col_layer", player_node.collision_layer)
			player_node.set_meta(&"orig_col_mask", player_node.collision_mask)
			player_node.collision_layer = 0
			player_node.collision_mask = 0
			var col = player_node.get_node_or_null("BodyCollision") as CollisionShape2D
			if col:
				col.set_deferred("disabled", true)
			player_node.velocity = Vector2.ZERO
			player_node.global_position = car_node.global_position

		police_drive_state_changed.emit(true)
		return true
