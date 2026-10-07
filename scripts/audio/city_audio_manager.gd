class_name CityAudioManager
extends Node

## Hệ thống Âm thanh Thành phố & Đời sống Đô thị (City Audio System)
## Quản lý:
## 1. Âm thanh bước chân đi bộ / chạy bộ (Footsteps) theo nhịp di chuyển và bề mặt
## 2. Tiếng động cơ xe (Engine Audio): Vòng tua máy (Pitch modulation) theo vận tốc lái xe
## 3. Tiếng bóp còi xe (Car Horn) khẩn cấp & xe cộ thành phố
## 4. Tiếng còi hú cảnh sát (Police Siren) tuần tra
## 5. Âm thanh môi trường đô thị náo nhiệt (City Ambience & Traffic sounds)

# --- Preload Audio Streams ---
const AMBIENCE_TOWN: AudioStream = preload("res://audio/ambience/town_day.wav")
const CAR_ENGINE_LOOP: AudioStream = preload("res://audio/vehicles/car_engine_idle.wav")
const CAR_START: AudioStream = preload("res://audio/vehicles/car_start.wav")
const CAR_STOP: AudioStream = preload("res://audio/vehicles/car_stop.wav")
const CAR_HORN: AudioStream = preload("res://audio/vehicles/car_horn.wav")
const POLICE_SIREN: AudioStream = preload("res://audio/vehicles/police_siren_soft.wav")
const CAR_PASS: AudioStream = preload("res://audio/vehicles/car_pass.wav")

const FOOTSTEPS_STONE: Array[AudioStream] = [
	preload("res://audio/footsteps/footstep_stone_01.wav"),
	preload("res://audio/footsteps/footstep_stone_02.wav"),
	preload("res://audio/footsteps/footstep_stone_03.wav"),
	preload("res://audio/footsteps/footstep_stone_04.wav"),
	preload("res://audio/footsteps/footstep_stone_05.wav"),
	preload("res://audio/footsteps/footstep_stone_06.wav"),
]

const FOOTSTEPS_ASPHALT: Array[AudioStream] = [
	preload("res://audio/footsteps/footstep_asphalt_01.wav"),
	preload("res://audio/footsteps/footstep_asphalt_02.wav"),
	preload("res://audio/footsteps/footstep_asphalt_03.wav"),
	preload("res://audio/footsteps/footstep_asphalt_04.wav"),
	preload("res://audio/footsteps/footstep_asphalt_05.wav"),
	preload("res://audio/footsteps/footstep_asphalt_06.wav"),
]

# Audio Players
var ambience_player: AudioStreamPlayer = null
var footstep_player: AudioStreamPlayer = null
var engine_player: AudioStreamPlayer = null
var car_sfx_player: AudioStreamPlayer = null
var siren_player: AudioStreamPlayer = null
var horn_player: AudioStreamPlayer = null
var traffic_player: AudioStreamPlayer = null

# Timers
var _ambient_traffic_timer: float = 8.0
var _horn_cooldown: float = 0.0
var _is_engine_running: bool = false
var _last_footstep_idx: int = -1


func _ready() -> void:
	_create_audio_players()
	start_city_ambience()
	_ambient_traffic_timer = randf_range(10.0, 20.0)


func _create_audio_players() -> void:
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbiencePlayer"
	ambience_player.volume_db = -14.0
	ambience_player.finished.connect(_on_ambience_finished)
	add_child(ambience_player)

	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.volume_db = -10.0
	add_child(footstep_player)

	engine_player = AudioStreamPlayer.new()
	engine_player.name = "EnginePlayer"
	engine_player.volume_db = -8.0
	engine_player.finished.connect(_on_engine_finished)
	add_child(engine_player)

	car_sfx_player = AudioStreamPlayer.new()
	car_sfx_player.name = "CarSfxPlayer"
	car_sfx_player.volume_db = -7.0
	add_child(car_sfx_player)

	siren_player = AudioStreamPlayer.new()
	siren_player.name = "SirenPlayer"
	siren_player.volume_db = -6.0
	siren_player.finished.connect(_on_siren_finished)
	add_child(siren_player)

	horn_player = AudioStreamPlayer.new()
	horn_player.name = "HornPlayer"
	horn_player.volume_db = -4.0
	add_child(horn_player)

	traffic_player = AudioStreamPlayer.new()
	traffic_player.name = "TrafficPlayer"
	traffic_player.volume_db = -17.0
	add_child(traffic_player)


func _process(delta: float) -> void:
	if _horn_cooldown > 0.0:
		_horn_cooldown -= delta

	# Mô phỏng tiếng còi xe hoặc xe lướt qua ở xa xa trong thành phố
	_ambient_traffic_timer -= delta
	if _ambient_traffic_timer <= 0.0:
		_ambient_traffic_timer = randf_range(14.0, 28.0)
		_play_ambient_city_honk()


# ==============================================================================
# 1. ÂM THANH MÔI TRƯỜNG ĐÔ THỊ (CITY AMBIENCE)
# ==============================================================================

func start_city_ambience() -> void:
	if ambience_player and AMBIENCE_TOWN:
		ambience_player.stream = AMBIENCE_TOWN
		ambience_player.play()


func _on_ambience_finished() -> void:
	if ambience_player:
		ambience_player.play()


func _play_ambient_city_honk() -> void:
	if traffic_player and not traffic_player.playing:
		if randf() < 0.6:
			traffic_player.stream = CAR_HORN
			traffic_player.pitch_scale = randf_range(0.85, 1.15)
			traffic_player.volume_db = -19.0
		else:
			traffic_player.stream = CAR_PASS
			traffic_player.pitch_scale = randf_range(0.95, 1.05)
			traffic_player.volume_db = -16.0
		traffic_player.play()


# ==============================================================================
# 2. ÂM THANH BƯỚC CHÂN (FOOTSTEPS)
# ==============================================================================

func play_footstep(is_sprint: bool = false, surface: String = "stone") -> void:
	if footstep_player == null:
		return

	var list = FOOTSTEPS_ASPHALT if surface == "asphalt" else FOOTSTEPS_STONE
	if list.is_empty():
		return

	# Tránh lặp lại đúng file vừa phát
	var idx = randi() % list.size()
	if idx == _last_footstep_idx:
		idx = (idx + 1) % list.size()
	_last_footstep_idx = idx

	footstep_player.stream = list[idx]
	footstep_player.pitch_scale = randf_range(0.92, 1.08)
	footstep_player.volume_db = -7.5 if is_sprint else -11.0
	footstep_player.play()


# ==============================================================================
# 3. ĐỘNG CƠ XE & TĂNG GA (ENGINE & REV)
# ==============================================================================

func start_car_engine() -> void:
	_is_engine_running = true
	if car_sfx_player:
		car_sfx_player.stream = CAR_START
		car_sfx_player.play()
	if engine_player:
		engine_player.stream = CAR_ENGINE_LOOP
		engine_player.pitch_scale = 0.85
		engine_player.volume_db = -9.0
		engine_player.play()


func update_engine_speed(current_speed: float, max_speed: float) -> void:
	if not _is_engine_running or engine_player == null:
		return

	var ratio: float = clampf(current_speed / max(max_speed, 1.0), 0.0, 1.0)
	# Vòng tua máy (Pitch) chuyển mượt mà từ 0.82 (nổ cầm chừng) lên 1.38 (hết ga)
	var target_pitch: float = lerpf(0.82, 1.38, ratio)
	engine_player.pitch_scale = move_toward(engine_player.pitch_scale, target_pitch, 0.05)
	
	# Âm lượng tăng nhẹ khi nhấn ga
	var target_vol: float = lerpf(-9.0, -5.0, ratio)
	engine_player.volume_db = move_toward(engine_player.volume_db, target_vol, 0.2)


func stop_car_engine() -> void:
	_is_engine_running = false
	if engine_player and engine_player.playing:
		engine_player.stop()
	if car_sfx_player:
		car_sfx_player.stream = CAR_STOP
		car_sfx_player.play()
	stop_police_siren()


func _on_engine_finished() -> void:
	if _is_engine_running and engine_player:
		engine_player.play()


# ==============================================================================
# 4. BÓP CÒI XE (CAR HORN)
# ==============================================================================

func play_horn() -> void:
	if _horn_cooldown > 0.0 or horn_player == null:
		return
	_horn_cooldown = 0.45
	horn_player.stream = CAR_HORN
	horn_player.pitch_scale = randf_range(0.98, 1.02)
	horn_player.volume_db = -4.0
	horn_player.play()


# ==============================================================================
# 5. CÒI HÚ CẢNH SÁT (POLICE SIREN)
# ==============================================================================

func start_police_siren() -> void:
	if siren_player and not siren_player.playing:
		siren_player.stream = POLICE_SIREN
		siren_player.pitch_scale = 1.0
		siren_player.volume_db = -6.0
		siren_player.play()


func stop_police_siren() -> void:
	if siren_player and siren_player.playing:
		siren_player.stop()


func toggle_police_siren() -> bool:
	if siren_player and siren_player.playing:
		stop_police_siren()
		return false
	else:
		start_police_siren()
		return true


func _on_siren_finished() -> void:
	if siren_player and siren_player.stream == POLICE_SIREN:
		siren_player.play()
