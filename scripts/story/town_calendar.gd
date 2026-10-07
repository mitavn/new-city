class_name TownCalendar
extends Node

## Hệ Thống Lịch Trình & 4 Ca Thời Gian Mộc Thành (Town Calendar & 4 Daily Phases)
## Quản lý:
## - Tiến trình ngày (Day 1..60+)
## - 4 Ca thời gian: Sáng (Morning) -> Chiều (Afternoon) -> Tối (Evening) -> Nửa Đêm (Late Night)
## - Chiếu sáng động (Dynamic Ambient Lighting) tạo không khí hoài niệm và huyền ảo

signal phase_changed(new_phase: DayPhase, phase_name: String)
signal day_passed(new_day: int)
signal clock_tick(hour: int, minute: int, time_str: String)

enum DayPhase {
	MORNING,    ## 06:00 - 12:00: Mở tiệm, giao hàng, kiếm tiền, sửa nhà
	AFTERNOON,  ## 12:00 - 18:00: Gặp gỡ NPC tại Café Lan, Công viên, Arcade
	EVENING,    ## 18:00 - 24:00: Phố đêm, tiệm mì, Cảnh sát Minh tuần tra
	LATE_NIGHT  ## 00:00 - 04:00: Tĩnh mịch, ga tàu cũ, manh mối quá khứ
}

const PHASE_NAMES: Dictionary = {
	DayPhase.MORNING: "Buổi Sáng (Morning)",
	DayPhase.AFTERNOON: "Buổi Chiều (Afternoon)",
	DayPhase.EVENING: "Buổi Tối (Evening)",
	DayPhase.LATE_NIGHT: "Nửa Đêm (Late Night)"
}

# Bảng màu ánh sáng theo ca thời gian (Ambient Colors)
const PHASE_COLORS: Dictionary = {
	DayPhase.MORNING: Color(1.0, 0.98, 0.92, 1.0),      # Nắng sớm ấm áp, trong trẻo
	DayPhase.AFTERNOON: Color(1.0, 0.88, 0.74, 1.0),    # Chiều tà vàng cam hoài niệm
	DayPhase.EVENING: Color(0.45, 0.52, 0.78, 1.0),      # Ánh đèn neon, chạng vạng xanh tím
	DayPhase.LATE_NIGHT: Color(0.25, 0.28, 0.45, 1.0)   # Đêm khuya tĩnh mịch, cô đơn
}

@export var current_day: int = 1
@export var current_hour: int = 8
@export var current_minute: int = 0
@export var time_scale: float = 1.0 # 1.0 giây thực = 1 phút trong game

var current_phase: DayPhase = DayPhase.MORNING
var _second_accumulator: float = 0.0


func _ready() -> void:
	_update_phase_state(false)


func _process(delta: float) -> void:
	_second_accumulator += delta * time_scale
	if _second_accumulator >= 1.0:
		_second_accumulator -= 1.0
		current_minute += 1
		if current_minute >= 60:
			current_minute = 0
			current_hour += 1
			if current_hour >= 24:
				current_hour = 6 # Bắt đầu ngày mới lúc 06:00 sáng
				advance_to_next_day()
			_update_phase_state(true)

		var time_str = "%02d:%02d" % [current_hour, current_minute]
		clock_tick.emit(current_hour, current_minute, time_str)


func _update_phase_state(emit_event: bool = true) -> void:
	var old_phase = current_phase
	if current_hour >= 6 and current_hour < 12:
		current_phase = DayPhase.MORNING
	elif current_hour >= 12 and current_hour < 18:
		current_phase = DayPhase.AFTERNOON
	elif current_hour >= 18 and current_hour < 24:
		current_phase = DayPhase.EVENING
	else:
		current_phase = DayPhase.LATE_NIGHT

	if old_phase != current_phase or not emit_event:
		var pname = PHASE_NAMES.get(current_phase, "Thời gian")
		if emit_event:
			phase_changed.emit(current_phase, pname)


func advance_to_next_day() -> void:
	current_day += 1
	day_passed.emit(current_day)


func get_current_ambient_color() -> Color:
	return PHASE_COLORS.get(current_phase, Color.WHITE)


func get_phase_name() -> String:
	return PHASE_NAMES.get(current_phase, "")
