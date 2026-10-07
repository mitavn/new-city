class_name WorldProgressionManager
extends Node

## Bộ Điều Phối Tiến Trình Thế Giới Độc Lập (World Progression Manager)
## Đảm bảo thế giới chuyển động tự nhiên theo thời gian, không chờ đợi thụ động:
## - Ngày 15: Dự án giải tỏa gửi thư mời hợp tác
## - Ngày 30: Dựng hàng rào tôn quanh khu chợ cũ
## - Ngày 45: Nguy cơ đóng cửa Tiệm sách cũ 30 năm (Tùy thuộc vào người chơi)
## - Ngày 60: Ngày phán quyết vận mệnh Mộc Thành

signal town_event_triggered(event_id: String, title: String, message: String)
signal town_ending_decided(ending_type: String, title: String)

var is_bookstore_saved: bool = false
var is_fences_erected: bool = false


func check_day_milestone(day: int, affinity_mgr: Node) -> void:
	match day:
		15:
			town_event_triggered.emit(
				"event_day_15_letter",
				"THƯ TỪ TẬP ĐOÀN BẤT ĐỘNG SẢN",
				"Tuấn gửi cho bạn lá thư đề nghị mua lại căn nhà cũ với số tiền khổng lồ để giải tỏa mặt bằng."
			)
		30:
			is_fences_erected = true
			town_event_triggered.emit(
				"event_day_30_fences",
				"CÔNG TRƯỜNG GIẢI TỎA DỰNG HÀNG RÀO",
				"Đoàn xe ủi và hàng rào tôn xanh bắt đầu quây kín khu chợ cũ bị cháy 12 năm trước. Thời gian đang cạn dần!"
			)
		45:
			var sau_score: int = affinity_mgr.get_score("sau_bookstore") if affinity_mgr else 0
			if sau_score >= 40:
				is_bookstore_saved = true
				town_event_triggered.emit(
					"event_day_45_saved",
					"CHIẾN DỊCH BẢO VỆ TIỆM SÁCH CŨ THÀNH CÔNG",
					"Nhờ sự giúp đỡ nhiệt tình của bạn và người dân, hiệu sách 30 năm của bà Sáu đã được công nhận là điểm di sản và được giữ lại!"
				)
			else:
				is_bookstore_saved = false
				town_event_triggered.emit(
					"event_day_45_demolished",
					"TIỆM SÁCH 30 NĂM ĐÓNG CỬA VĨNH VIỄN",
					"Bà Sáu lặng lẽ dọn đồ rời đi. Tiệm sách tuổi thơ bị phá dỡ thành một bãi đỗ xe lạnh lẽo..."
				)
		60:
			town_event_triggered.emit(
				"event_day_60_final_day",
				"NGÀY PHÁN QUYẾT VẬN MỆNH MỘC THÀNH",
				"Hạn chót đã đến. Tất cả bằng chứng và mối quan hệ bạn gây dựng trong 60 ngày qua sẽ quyết định tương lai của Mộc Thành!"
			)
