class_name ClueJournal
extends Node

## Sổ Tay Điều Tra & Tiến Trình Sự Thật (Investigation Journal)
## Quản lý tiến trình: Rumor (Tin đồn) -> Memory (Ký ức lệch) -> Evidence (Chứng cứ) -> Truth (Sự thật)

signal clue_discovered(clue_id: String, clue_data: Dictionary)
signal clue_stage_advanced(clue_id: String, old_stage: Stage, new_stage: Stage, desc: String)

enum Stage {
	UNDISCOVERED,  ## Chưa biết gì
	RUMOR,         ## Tin đồn nghe lỏm từ NPC ngoài phố
	MEMORY,        ## Ký ức ban đầu trong đầu nhân vật chính (chưa đáng tin)
	EVIDENCE,      ## Bằng chứng vật lý tìm được (Ảnh, Băng cassette, Bản đồ ngầm)
	TRUTH          ## Sự thật cuối cùng được xâu chuỗi hoàn chỉnh
}

const STAGE_NAMES: Dictionary = {
	Stage.UNDISCOVERED: "Chưa Rõ",
	Stage.RUMOR: "Tin Đồn Ngoài Phố (Rumor)",
	Stage.MEMORY: "Ký Ức Của Bạn (Memory)",
	Stage.EVIDENCE: "Vật Chứng Thu Thập (Evidence)",
	Stage.TRUTH: "Sự Thật Phơi Bày (Truth)"
}

## Cơ sở dữ liệu các mảnh ghép bí ẩn cốt truyện 12 năm trước
var clues_database: Dictionary = {
	"fire_origin": {
		"id": "fire_origin",
		"title": "Vụ cháy Chợ Cũ 12 năm trước",
		"stage": Stage.RUMOR,
		"stages_data": {
			Stage.RUMOR: "Cư dân Mộc Thành đồn rằng Nam đã nổi giận và cầm can xăng đốt chợ cũ vì bị đuổi đi.",
			Stage.MEMORY: "Bạn nhớ như in đêm đó Nam cầm một can nhựa chạy trong màn khói dày đặc của khu chợ.",
			Stage.EVIDENCE: "Chiếc can nhựa cũ rỉ sét tìm thấy dưới giếng cạn chợ cũ thực chất là can đựng nước ngọt pha trà của bà Sáu.",
			Stage.TRUTH: "Một nhóm kẻ lạ mặt đã cố tình phóng hỏa để buộc giải tỏa khu chợ. Nam lao vào biển lửa là để cứu mẹ con cô bé hàng xóm."
		}
	},
	"nam_disappearance": {
		"id": "nam_disappearance",
		"title": "Sự mất tích bí ẩn của Nam",
		"stage": Stage.RUMOR,
		"stages_data": {
			Stage.RUMOR: "Mọi người bảo Nam đã chết cháy hoặc bỏ trốn khỏi Mộc Thành ngay trong đêm định mệnh.",
			Stage.MEMORY: "Bạn nhớ cả nhóm đã bỏ chạy tán loạn, không ai kịp nhìn lại xem Nam có thoát ra được không.",
			Stage.EVIDENCE: "Lá thư bưu kiện không người gửi bạn nhận được có nét chữ viết tắt 'N' rất quen thuộc ở góc ảnh.",
			Stage.TRUTH: "Nam chưa bao giờ rời Mộc Thành. Cậu ấy ẩn mình suốt 12 năm qua để bảo vệ chứng cứ hợp đồng đất đai và chờ bạn quay về."
		}
	},
	"land_deal": {
		"id": "land_deal",
		"title": "Bản hợp đồng thâu tóm khu phố",
		"stage": Stage.UNDISCOVERED,
		"stages_data": {
			Stage.RUMOR: "Tập đoàn bất động sản của Tuấn khẳng định khu đất đã được chính quyền bán đấu giá hợp pháp từ lâu.",
			Stage.MEMORY: "Bố bạn ngày xưa thường nhốt mình trong phòng làm việc với những tập hồ sơ dấu đỏ.",
			Stage.EVIDENCE: "Cuộn băng cassette của Lan ghi âm lại giọng nói của bố bạn phản đối kịch liệt vụ ép bán đất nhưng bị đe dọa.",
			Stage.TRUTH: "Gia đình bạn phải bỏ trốn 12 năm trước không phải vì phạm tội, mà vì bố bạn từ chối ký giấy bán khu phố và bị thế lực ngầm đe dọa an toàn của bạn."
		}
	},
	"childhood_promise": {
		"id": "childhood_promise",
		"title": "Lời hứa trên sân bóng cũ",
		"stage": Stage.MEMORY,
		"stages_data": {
			Stage.RUMOR: "Sân bóng năm xưa giờ đã thành bãi đất trống rào tôn, không ai còn nhớ gì.",
			Stage.MEMORY: "Trước đêm xảy ra vụ cháy, nhóm 6 đứa đã chôn một chiếc hộp thiếc hẹn 10 năm sau cùng đào lên.",
			Stage.EVIDENCE: "Chiếc chìa khóa cũ trong bưu kiện chính là chìa khóa mở chiếc hộp thiếc chôn dưới gốc cây long não.",
			Stage.TRUTH: "Lời hứa năm 17 tuổi: Dù cuộc đời đưa mỗi đứa về đâu, Mộc Thành vẫn luôn là mái nhà che chở cho cả nhóm."
		}
	}
}


## Nâng cấp tầng nhận thức của một manh mối
func advance_clue_stage(clue_id: String, target_stage: Stage) -> bool:
	if not clues_database.has(clue_id):
		return false

	var clue = clues_database[clue_id]
	var old_stage: Stage = clue["stage"]
	if target_stage <= old_stage:
		return false

	clue["stage"] = target_stage
	var desc: String = clue["stages_data"].get(target_stage, "")
	clue_stage_advanced.emit(clue_id, old_stage, target_stage, desc)
	return true


func get_clue_current_text(clue_id: String) -> String:
	if not clues_database.has(clue_id):
		return ""
	var clue = clues_database[clue_id]
	var stage: Stage = clue["stage"]
	return clue["stages_data"].get(stage, "Chưa rõ thông tin")


func get_all_clues() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for cid in clues_database.keys():
		list.append(clues_database[cid])
	return list
