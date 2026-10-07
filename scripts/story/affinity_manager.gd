class_name AffinityManager
extends Node

## Hệ Thống Mối Quan Hệ & Thiện Cảm 5 Người Bạn Cũ (Character Affinity & Trust)
## Quản lý mức độ gắn kết, sự tha thứ và hiềm khích sau 12 năm rời đi

signal affinity_changed(char_id: String, old_val: int, new_val: int, tier_name: String)

enum Tier {
	RESENTFUL,  ## Căm ghét, trách móc vì bạn bỏ đi không một lời từ biệt (-50 .. -1)
	COLD,       ## Xa cách, nghi ngại (0 .. 25)
	WARM,       ## Bắt đầu mở lòng, hàn gắn (26 .. 60)
	CLOSE,      ## Tin tưởng, chia sẻ bí mật cũ (61 .. 85)
	CONFIDANT   ## Tri kỷ trọn đời, đồng lòng cứu Mộc Thành (86 .. 100)
}

const TIER_NAMES: Dictionary = {
	Tier.RESENTFUL: "Trách Móc / Oán Hận (Resentful)",
	Tier.COLD: "Xa Lạ / Đề Phòng (Cold)",
	Tier.WARM: "Bắt Đầu Hàn Gắn (Warm)",
	Tier.CLOSE: "Tin Cậy / Thấu Hiểu (Close)",
	Tier.CONFIDANT: "Tri Kỷ Tuyệt Đối (Confidant)"
}

var affinities: Dictionary = {
	"minh_police": {
		"name": "Minh Cảnh Sát",
		"score": 10,
		"title": "Sĩ quan tuần tra Mộc Thành"
	},
	"lan_cafe": {
		"name": "Lan Quán Café",
		"score": 25,
		"title": "Chủ quán Café hoa giấy"
	},
	"tuan_realestate": {
		"name": "Tuấn Bất Động Sản",
		"score": 15,
		"title": "Giám đốc dự án Mộc Thành Plaza"
	},
	"binh_teacher": {
		"name": "Bình Thầy Giáo",
		"score": 20,
		"title": "Cố vấn bảo tồn di sản"
	},
	"nam_ghost": {
		"name": "Nam 'Bóng Ma Ga Tàu'",
		"score": 5,
		"title": "Người bạn mất tích 12 năm trước"
	},
	"sau_bookstore": {
		"name": "Bà Sáu Tiệm Sách",
		"score": 30,
		"title": "Chủ hiệu sách cũ 30 năm"
	}
}


func add_affinity(char_id: String, amount: int) -> void:
	if not affinities.has(char_id):
		return

	var old_val: int = affinities[char_id]["score"]
	var new_val: int = clamp(old_val + amount, -50, 100)
	affinities[char_id]["score"] = new_val

	var tier = get_tier(char_id)
	var tname = TIER_NAMES.get(tier, "")
	affinity_changed.emit(char_id, old_val, new_val, tname)


func get_score(char_id: String) -> int:
	if affinities.has(char_id):
		return affinities[char_id]["score"]
	return 0


func get_tier(char_id: String) -> Tier:
	var s: int = get_score(char_id)
	if s < 0:
		return Tier.RESENTFUL
	elif s <= 25:
		return Tier.COLD
	elif s <= 60:
		return Tier.WARM
	elif s <= 85:
		return Tier.CLOSE
	else:
		return Tier.CONFIDANT


func get_tier_name(char_id: String) -> String:
	return TIER_NAMES.get(get_tier(char_id), "")
