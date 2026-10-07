#!/usr/bin/env python3
"""
NPC Resource & Asset Registry Generator for Godot 4.
Generates Godot .tres Resource files (NPCData) for all character spritesheets.
"""

import os
import re
import json
import hashlib

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets", "spritesheets", "characters")
NPCS_DIR = os.path.join(BASE_DIR, "data", "npcs")
REGISTRY_PATH = os.path.join(BASE_DIR, "data", "asset_registry.json")
NPCDATA_SCRIPT_PATH = "res://scripts/npcs/NPCData.gd"
NPCDATA_SCRIPT_UID = "uid://1jm7l62oqmyb"

# 44 Characters Metadata
CHARACTERS = [
    # City-Characters (28 characters)
    {
        "file": "City-Characters_09.png",
        "id": "001",
        "resource_name": "police_male_01",
        "display_name": "Cảnh Sát Nam",
        "role": "police",
        "gender": "male",
        "description": "Sĩ quan cảnh sát nam, sắc phục xanh lam, đội mũ kepi tuần tra.",
        "tags": ["police", "law", "officer", "male"],
        "speed": 65.0,
        "dialogues": [
            "Xin chào! Khu vực này đang được đảm bảo an ninh trật tự.",
            "Hãy luôn tuân thủ luật giao thông khi di chuyển trong thành phố nhé!",
            "Nếu phát hiện điều gì bất thường, hãy báo ngay cho chúng tôi."
        ]
    },
    {
        "file": "City-Characters_10.png",
        "id": "002",
        "resource_name": "police_female_01",
        "display_name": "Cảnh Sát Nữ",
        "role": "police",
        "gender": "female",
        "description": "Nữ sĩ quan cảnh sát, đồng phục xanh lam, tóc buộc gọn gàng.",
        "tags": ["police", "law", "officer", "female"],
        "speed": 65.0,
        "dialogues": [
            "Chào bạn! Thành phố hôm nay rất yên bình.",
            "Luôn chú ý an toàn khi đi lại vào ban đêm bạn nhé.",
            "Tôi đang đi tuần tra khu vực, có cần hỗ trợ gì không?"
        ]
    },
    {
        "file": "City-Characters_11.png",
        "id": "003",
        "resource_name": "construction_male_01",
        "display_name": "Thợ Xây Nam",
        "role": "construction",
        "gender": "male",
        "description": "Công nhân xây dựng nam, áo gile cam dạ quang, đội mũ bảo hộ vàng.",
        "tags": ["construction", "builder", "worker", "male"],
        "speed": 55.0,
        "dialogues": [
            "Chú ý an toàn lao động! Hãy đội mũ bảo hộ khi vào gần công trình.",
            "Chúng tôi đang xây thêm nhiều công trình mới cho thành phố.",
            "Cần một nền móng vững chắc thì nhà mới bền đẹp được!"
        ]
    },
    {
        "file": "City-Characters_12.png",
        "id": "004",
        "resource_name": "construction_female_01",
        "display_name": "Thợ Xây Nữ",
        "role": "construction",
        "gender": "female",
        "description": "Nữ công nhân xây dựng, áo bảo hộ phản quang, nón bảo hộ công trình.",
        "tags": ["construction", "builder", "worker", "female"],
        "speed": 55.0,
        "dialogues": [
            "Chào bạn, cẩn thận vật liệu xây dựng rơi vãi nhé.",
            "Bản vẽ kiến trúc đợt này được thiết kế rất thông minh và hiện đại.",
            "Công việc tuy vất vả nhưng nhìn thành phố phát triển là vui rồi!"
        ]
    },
    {
        "file": "City-Characters_13.png",
        "id": "005",
        "resource_name": "doctor_male_01",
        "display_name": "Bác Sĩ Nam",
        "role": "doctor",
        "gender": "male",
        "description": "Bác sĩ nam áo blouse trắng, đeo ống nghe y tế, phong thái ân cần.",
        "tags": ["doctor", "medical", "hospital", "male"],
        "speed": 60.0,
        "dialogues": [
            "Sức khỏe là vốn quý nhất, nhớ tập thể dục và uống đủ nước nhé.",
            "Bệnh viện thành phố luôn mở cửa tiếp nhận bệnh nhân 24/7.",
            "Hôm nay bạn cảm thấy trong người có khỏe khoắn không?"
        ]
    },
    {
        "file": "City-Characters_14.png",
        "id": "006",
        "resource_name": "doctor_female_01",
        "display_name": "Bác Sĩ Nữ",
        "role": "doctor",
        "gender": "female",
        "description": "Nữ bác sĩ / điều dưỡng, áo blouse trắng trang nhã, tóc nâu ngắn.",
        "tags": ["doctor", "medical", "nurse", "female"],
        "speed": 60.0,
        "dialogues": [
            "Xin chào! Đừng quên rửa tay thường xuyên và ăn uống điều độ.",
            "Nếu cảm thấy mệt mỏi, hãy nghỉ ngơi một chút nhé.",
            "Phòng y tế thành phố luôn sẵn sàng các loại thuốc thiết yếu."
        ]
    },
    {
        "file": "City-Characters_15.png",
        "id": "007",
        "resource_name": "chef_male_01",
        "display_name": "Đầu Bếp Nam",
        "role": "chef",
        "gender": "male",
        "description": "Đầu bếp trưởng nam, mũ bếp cao màu trắng và tạp dề nấu ăn chuyên nghiệp.",
        "tags": ["chef", "restaurant", "food", "cook", "male"],
        "speed": 55.0,
        "dialogues": [
            "Chào mừng! Hôm nay nhà hàng có món đặc biệt rất ngon miệng đấy.",
            "Bí quyết của món ăn ngon là nguyên liệu tươi và cái tâm của người nấu!",
            "Bạn có muốn thử một đĩa súp nóng hổi thơm phức không?"
        ]
    },
    {
        "file": "City-Characters_16.png",
        "id": "008",
        "resource_name": "chef_female_01",
        "display_name": "Đầu Bếp Nữ",
        "role": "chef",
        "gender": "female",
        "description": "Nữ đầu bếp làm bánh, đội mũ bếp trắng và trang phục bếp gọn gàng.",
        "tags": ["chef", "bakery", "restaurant", "food", "female"],
        "speed": 55.0,
        "dialogues": [
            "Tiệm bánh vừa ra lò mẻ bánh mì bơ tỏi thơm ngào ngạt đây!",
            "Tôi rất thích sáng tạo các món bánh ngọt mới cho cư dân thành phố.",
            "Chúc bạn một ngày ngọt ngào và tràn đầy hứng khởi!"
        ]
    },
    {
        "file": "City-Characters_17.png",
        "id": "009",
        "resource_name": "office_male_01",
        "display_name": "Nhân Viên Văn Phòng Nam",
        "role": "office",
        "gender": "male",
        "description": "Nhân viên công sở nam, mặc vest xanh lịch sự, cà vạt chỉnh chu.",
        "tags": ["office", "business", "worker", "male"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Tôi đang trên đường đến buổi họp giao ban buổi sáng.",
            "Khu văn phòng hôm nay có nhiều dự án công nghệ mới được triển khai.",
            "Một ly cà phê sáng giúp tôi tập trung làm việc hơn hẳn."
        ]
    },
    {
        "file": "City-Characters_18.png",
        "id": "010",
        "resource_name": "office_female_01",
        "display_name": "Nhân Viên Văn Phòng Nữ",
        "role": "office",
        "gender": "female",
        "description": "Nữ nhân viên văn phòng năng động, áo sơ mi trang nhã và chân váy công sở.",
        "tags": ["office", "business", "worker", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Deadline tuần này khá gấp nhưng mọi người đều nỗ lực.",
            "Thành phố này có rất nhiều cơ hội việc làm hấp dẫn.",
            "Hết giờ làm tôi sẽ đi dạo thư giãn một vòng quanh công viên."
        ]
    },
    {
        "file": "City-Characters_19.png",
        "id": "011",
        "resource_name": "sanitation_male_01",
        "display_name": "Nhân Viên Môi Trường Nam",
        "role": "sanitation",
        "gender": "male",
        "description": "Nhân viên vệ sinh đô thị nam, đồng phục xanh lá cây môi trường sạch đẹp.",
        "tags": ["sanitation", "cleaner", "environment", "male"],
        "speed": 55.0,
        "dialogues": [
            "Giữ gìn thành phố xanh - sạch - đẹp là niềm tự hào của chúng tôi!",
            "Hãy phân loại rác thải đúng cách để bảo vệ môi trường bạn nhé.",
            "Mỗi góc phố sạch sẽ làm thành phố đáng sống hơn từng ngày."
        ]
    },
    {
        "file": "City-Characters_20.png",
        "id": "012",
        "resource_name": "sanitation_female_01",
        "display_name": "Nhân Viên Môi Trường Nữ",
        "role": "sanitation",
        "gender": "female",
        "description": "Nữ nhân viên môi trường đô thị, đồng phục bảo hộ xanh lá cây.",
        "tags": ["sanitation", "cleaner", "environment", "female"],
        "speed": 55.0,
        "dialogues": [
            "Chào buổi sáng! Những bồn hoa trên vỉa hè hôm nay nở đẹp lắm.",
            "Hãy chung tay cùng chúng tôi giữ gìn vệ sinh chung nhé.",
            "Một nụ cười thân thiện sẽ làm ngày làm việc thêm nhiều niềm vui."
        ]
    },
    {
        "file": "City-Characters_21.png",
        "id": "013",
        "resource_name": "delivery_male_01",
        "display_name": "Nhân Viên Giao Hàng Nam",
        "role": "delivery",
        "gender": "male",
        "description": "Shipper giao hàng nam, đội mũ lưỡi trai, áo khoác vàng cam chuyển phát nhanh.",
        "tags": ["delivery", "courier", "shipper", "male"],
        "speed": 70.0,
        "dialogues": [
            "Đơn hàng tiếp theo đang chờ tôi giao đến tận tay khách hàng đây!",
            "Mọi ngõ ngách trong thành phố này tôi đều nhớ như in trong lòng bàn tay.",
            "Chúc bạn có một ngày nhận hàng đúng hẹn và vui vẻ!"
        ]
    },
    {
        "file": "City-Characters_22.png",
        "id": "014",
        "resource_name": "delivery_female_01",
        "display_name": "Nhân Viên Giao Hàng Nữ",
        "role": "delivery",
        "gender": "female",
        "description": "Nữ shipper giao nhận bưu phẩm, mũ lưỡi trai và đồng phục chuyển phát.",
        "tags": ["delivery", "courier", "shipper", "female"],
        "speed": 70.0,
        "dialogues": [
            "Kiện bưu phẩm của bạn đang trên đường vận chuyển an toàn!",
            "Giao hàng nhanh chóng và tận tâm là phương châm của tôi.",
            "Hôm nay số lượng đơn hàng tăng cao, thành phố thật tấp nập."
        ]
    },
    {
        "file": "City-Characters_23.png",
        "id": "015",
        "resource_name": "senior_male_01",
        "display_name": "Cụ Ông",
        "role": "senior",
        "gender": "male",
        "description": "Cụ ông tóc bạc, đeo kính lão, áo len xám ấm áp và dáng đi khoan thai.",
        "tags": ["senior", "elderly", "citizen", "male"],
        "speed": 45.0,
        "dialogues": [
            "Thành phố này thay đổi nhiều quá, ngày càng khang trang và hiện đại.",
            "Mỗi buổi sáng đi dạo dưới hàng cây thế này thật thư thái tâm hồn.",
            "Các cháu thanh niên hãy luôn giữ gìn sức khỏe và sống lạc quan nhé."
        ]
    },
    {
        "file": "City-Characters_24.png",
        "id": "016",
        "resource_name": "senior_female_01",
        "display_name": "Cụ Bà",
        "role": "senior",
        "gender": "female",
        "description": "Cụ bà tóc muối tiêu bới cao, đeo kính tròn, phong thái hiền từ.",
        "tags": ["senior", "elderly", "citizen", "female"],
        "speed": 45.0,
        "dialogues": [
            "Chào cháu! Cháu có muốn thử chút bánh quy bà mới nướng không?",
            "Không khí buổi sớm mai ở công viên trong lành và dễ chịu biết bao.",
            "Thời gian trôi nhanh thật, chúc các cháu luôn gặp nhiều điều may mắn."
        ]
    },
    {
        "file": "City-Characters_25.png",
        "id": "017",
        "resource_name": "firefighter_male_01",
        "display_name": "Lính Cứu Hỏa Nam",
        "role": "firefighter",
        "gender": "male",
        "description": "Chiến sĩ cứu hỏa nam, đồ bảo hộ chống cháy màu đỏ cam dũng cảm.",
        "tags": ["firefighter", "rescue", "emergency", "male"],
        "speed": 65.0,
        "dialogues": [
            "Đội cứu hỏa luôn túc trực 24/7 sẵn sàng ứng phó mọi tình huống khẩn cấp!",
            "Hãy kiểm tra ổ điện và bếp gas cẩn thận trước khi ra khỏi nhà.",
            "An toàn phòng cháy chữa cháy là trách nhiệm của mỗi chúng ta."
        ]
    },
    {
        "file": "City-Characters_26.png",
        "id": "018",
        "resource_name": "firefighter_female_01",
        "display_name": "Lính Cứu Hỏa Nữ",
        "role": "firefighter",
        "gender": "female",
        "description": "Nữ chiến sĩ cứu hỏa kiên cường, trang phục phòng cháy chữa cháy đỏ rực.",
        "tags": ["firefighter", "rescue", "emergency", "female"],
        "speed": 65.0,
        "dialogues": [
            "Chúng tôi vừa hoàn thành buổi diễn tập cứu hộ định kỳ tại tòa nhà.",
            "Hãy ghi nhớ số điện thoại khẩn cấp để gọi ngay khi gặp nguy hiểm.",
            "Bình tĩnh là yếu tố quan trọng nhất khi xử lý sự cố."
        ]
    },
    {
        "file": "City-Characters_27.png",
        "id": "019",
        "resource_name": "executive_male_01",
        "display_name": "Doanh Nhân Nam",
        "role": "executive",
        "gender": "male",
        "description": "Doanh nhân cấp cao nam, bộ âu phục tuxedo đen sang trọng, phong độ.",
        "tags": ["executive", "vip", "business", "male"],
        "speed": 60.0,
        "dialogues": [
            "Thời gian là tài sản quý báu nhất. Đầu tư đúng hướng sẽ mang lại tương lai.",
            "Thành phố này đang vươn mình thành trung tâm tài chính lớn.",
            "Tầm nhìn chiến lược và sự kiên trì là chìa khóa của mọi thành công."
        ]
    },
    {
        "file": "City-Characters_28.png",
        "id": "020",
        "resource_name": "executive_female_01",
        "display_name": "Doanh Nhân Nữ",
        "role": "executive",
        "gender": "female",
        "description": "Nữ giám đốc điều hành, vest đen quyền lực và thần thái quý phái.",
        "tags": ["executive", "vip", "business", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Tôi vừa ký kết một biên bản hợp tác phát triển đô thị xanh.",
            "Đổi mới và sáng tạo là động lực đưa doanh nghiệp vươn tầm cao mới.",
            "Một thành phố thịnh vượng bắt đầu từ những cư dân nhiệt huyết."
        ]
    },
    {
        "file": "City-Characters_01.png",
        "id": "021",
        "resource_name": "citizen_male_01",
        "display_name": "Cư Dân Nam Áo Xanh",
        "role": "civilian",
        "gender": "male",
        "description": "Cư dân thành phố nam trẻ tuổi, áo khoác denim xanh và quần tối màu.",
        "tags": ["civilian", "pedestrian", "citizen", "male"],
        "speed": 60.0,
        "dialogues": [
            "Xin chào! Hôm nay bạn có kế hoạch đi đâu trong thành phố chưa?",
            "Quán cà phê ở góc phố bên kia có góc nhìn ra quảng trường rất đẹp đấy.",
            "Thời tiết hôm nay dễ chịu thật, đi dạo một chút thôi!"
        ]
    },
    {
        "file": "City-Characters_02.png",
        "id": "022",
        "resource_name": "citizen_female_01",
        "display_name": "Cư Dân Nữ Áo Tím",
        "role": "civilian",
        "gender": "female",
        "description": "Cư dân nữ trẻ trung, áo len tím mận và quần skinny thanh lịch.",
        "tags": ["civilian", "pedestrian", "citizen", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Thành phố dạo này có thêm nhiều cửa hàng mới mở đẹp lắm.",
            "Tôi vừa mua được cuốn sách yêu thích ở hiệu sách trung tâm.",
            "Chúc bạn một ngày tràn đầy năng lượng tích cực nhé!"
        ]
    },
    {
        "file": "City-Characters_03.png",
        "id": "023",
        "resource_name": "citizen_male_02",
        "display_name": "Cư Dân Nam Áo Xám",
        "role": "civilian",
        "gender": "male",
        "description": "Nam thanh niên dạo phố, áo thun xám hiện đại và quần xanh ngọc.",
        "tags": ["civilian", "pedestrian", "citizen", "male"],
        "speed": 60.0,
        "dialogues": [
            "Chào người anh em! Có biết phòng tập thể thao gần nhất ở đâu không?",
            "Thành phố này nhộn nhịp về đêm lắm, bạn đã thử đi dạo đêm chưa?",
            "Âm nhạc đường phố ở quảng trường hôm nay nghe rất cuốn hút."
        ]
    },
    {
        "file": "City-Characters_04.png",
        "id": "024",
        "resource_name": "citizen_female_02",
        "display_name": "Cư Dân Nữ Áo Nâu",
        "role": "civilian",
        "gender": "female",
        "description": "Cô gái thành thị với áo len nâu ấm áp, mái tóc nâu bồng bềnh.",
        "tags": ["civilian", "pedestrian", "citizen", "female"],
        "speed": 60.0,
        "dialogues": [
            "Xin chào! Tôi đang chuẩn bị đến lớp học vẽ tranh vào buổi chiều.",
            "Những bức tranh tường graffiti ở bờ sông trông nghệ thuật ghê.",
            "Cuộc sống nơi thành thị lúc nào cũng ngập tràn màu sắc rực rỡ."
        ]
    },
    {
        "file": "City-Characters_05.png",
        "id": "025",
        "resource_name": "citizen_male_03",
        "display_name": "Cư Dân Nam Áo Rêu",
        "role": "civilian",
        "gender": "male",
        "description": "Cư dân nam phong cách đường phố, áo khoác xanh rêu cá tính.",
        "tags": ["civilian", "pedestrian", "citizen", "male"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Tôi đang thử tuyến xe buýt nhanh mới của thành phố.",
            "Giao thông công cộng tiện lợi giúp giảm đáng kể khói bụi xe cộ.",
            "Một ngày thong dong dạo ngắm phố phường thật thoải mái."
        ]
    },
    {
        "file": "City-Characters_06.png",
        "id": "026",
        "resource_name": "citizen_female_03",
        "display_name": "Cư Dân Nữ Áo Hồng",
        "role": "civilian",
        "gender": "female",
        "description": "Cô gái dịu dàng trong trang phục áo hồng pastel và váy sẫm màu.",
        "tags": ["civilian", "pedestrian", "citizen", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn nhé! Hôm nay trời trong xanh, rất thích hợp chụp ảnh.",
            "Khu chợ nông sản cuối tuần lúc nào cũng đông vui tấp nập.",
            "Chúc bạn luôn nở nụ cười rạng rỡ suốt cả ngày!"
        ]
    },
    {
        "file": "City-Characters_07.png",
        "id": "027",
        "resource_name": "citizen_male_04",
        "display_name": "Cư Dân Nam Áo Hoodie",
        "role": "civilian",
        "gender": "male",
        "description": "Chàng trai trẻ mặc áo hoodie tím năng động, giày thể thao.",
        "tags": ["civilian", "youth", "citizen", "male"],
        "speed": 65.0,
        "dialogues": [
            "Yo! Hôm nay thời tiết mát mẻ chuẩn bị đi trượt ván ở công viên thôi.",
            "Thành phố này có nhiều góc chụp ảnh sống ảo chất lượng lắm đó.",
            "Hãy tận hưởng từng khoảnh khắc tuổi trẻ bạn nhé!"
        ]
    },
    {
        "file": "City-Characters_08.png",
        "id": "028",
        "resource_name": "citizen_female_04",
        "display_name": "Cư Dân Nữ Áo Ngọc",
        "role": "civilian",
        "gender": "female",
        "description": "Nữ cư dân sành điệu với áo thun xanh ngọc mát mắt.",
        "tags": ["civilian", "pedestrian", "citizen", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Bạn đã thử đồ uống đá xay ở quán trà mới mở chưa?",
            "Công viên trung tâm có nhiều bóng mát, ngồi đọc sách rất tuyệt.",
            "Mỗi ngày ở thành phố đều có những điều bất ngờ thú vị chờ đón."
        ]
    },

    # Character-Variation-1 (16 characters)
    {
        "file": "Character-Variation-1_01.png",
        "id": "029",
        "resource_name": "resident_male_01",
        "display_name": "Thanh Niên Nam Áo Khoác Bò",
        "role": "civilian",
        "gender": "male",
        "description": "Thanh niên dạo phố với áo khoác jeans màu lam nhạt và quần tây.",
        "tags": ["civilian", "resident", "male"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Tôi vừa tan ca học ở trường đại học về.",
            "Thành phố này nhiều tiện ích thật, đi đâu cũng thuận lợi.",
            "Chúc bạn có một buổi dạo phố vui vẻ!"
        ]
    },
    {
        "file": "Character-Variation-1_02.png",
        "id": "030",
        "resource_name": "resident_female_01",
        "display_name": "Thanh Niên Nữ Áo Đỏ Cam",
        "role": "civilian",
        "gender": "female",
        "description": "Nữ sinh viên vui vẻ trong chiếc áo len màu cam san hô ấm cúng.",
        "tags": ["civilian", "resident", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn nhé! Màu áo ấm này rất hợp với tiết trời se lạnh hôm nay.",
            "Tôi đang chuẩn bị đến thư viện thành phố để ôn thi.",
            "Cố gắng hết mình rồi mọi chuyện đều sẽ tốt đẹp thôi!"
        ]
    },
    {
        "file": "Character-Variation-1_03.png",
        "id": "031",
        "resource_name": "resident_male_02",
        "display_name": "Thanh Niên Nam Áo Lam Nón Vàng",
        "role": "civilian",
        "gender": "male",
        "description": "Nam thiếu niên năng động với hoodie xanh biển phối viền vàng.",
        "tags": ["civilian", "resident", "teen", "male"],
        "speed": 65.0,
        "dialogues": [
            "Chào bạn! Tôi thích đi bộ dạo quanh các khu phố cổ.",
            "Kiến trúc ở đây giao thoa giữa nét cổ kính và hiện đại độc đáo ghê.",
            "Hẹn gặp lại bạn ở sân khấu ngoài trời nhé!"
        ]
    },
    {
        "file": "Character-Variation-1_04.png",
        "id": "032",
        "resource_name": "resident_female_02",
        "display_name": "Thanh Niên Nữ Áo Xanh Biển",
        "role": "civilian",
        "gender": "female",
        "description": "Cô gái trẻ trung với áo thun xanh lơ mát mẻ và quần jean tối màu.",
        "tags": ["civilian", "resident", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Không khí trong lành ven hồ thành phố làm lòng người nhẹ nhõm.",
            "Tôi vừa kết thúc ca trực tình nguyện tại trung tâm cộng đồng.",
            "Giúp đỡ mọi người luôn mang lại niềm hạnh phúc giản dị."
        ]
    },
    {
        "file": "Character-Variation-1_05.png",
        "id": "033",
        "resource_name": "resident_male_03",
        "display_name": "Thanh Niên Nam Áo Cardigan Xám",
        "role": "civilian",
        "gender": "male",
        "description": "Chàng trai thư sinh, áo len mỏng xám lịch lãm và quần âu.",
        "tags": ["civilian", "resident", "scholar", "male"],
        "speed": 55.0,
        "dialogues": [
            "Chào bạn! Một tách trà nóng và một cuốn sách hay là sở thích của tôi.",
            "Khu bảo tàng lịch sử thành phố vừa khai mạc triển lãm mới rất đáng xem.",
            "Tri thức mở ra cánh cửa nhìn ra thế giới rộng lớn."
        ]
    },
    {
        "file": "Character-Variation-1_06.png",
        "id": "034",
        "resource_name": "resident_female_03",
        "display_name": "Thanh Niên Nữ Đồ Thể Thao",
        "role": "civilian",
        "gender": "female",
        "description": "Cô gái yêu thể thao trong bộ đồ tập xanh dương khỏe khoắn.",
        "tags": ["civilian", "athlete", "resident", "female"],
        "speed": 65.0,
        "dialogues": [
            "Chào bạn! Tôi vừa chạy bộ được 5km quanh công viên về này.",
            "Rèn luyện thể thao mỗi ngày giúp tinh thần luôn sảng khoái và minh mẫn.",
            "Hãy cùng nhau duy trì lối sống lành mạnh nhé!"
        ]
    },
    {
        "file": "Character-Variation-1_07.png",
        "id": "035",
        "resource_name": "resident_male_04",
        "display_name": "Thanh Niên Nam Đồ Thể Thao Lam",
        "role": "civilian",
        "gender": "male",
        "description": "Vận động viên trẻ trong trang phục thể thao viền tím sành điệu.",
        "tags": ["civilian", "athlete", "resident", "male"],
        "speed": 65.0,
        "dialogues": [
            "Xin chào! Sân vận động thành phố hôm nay có trận bóng đá giao hữu đấy.",
            "Chơi thể thao tinh thần đồng đội luôn là điều tuyệt vời nhất.",
            "Chúc bạn luôn tràn trề sinh lực và nhiệt huyết!"
        ]
    },
    {
        "file": "Character-Variation-1_08.png",
        "id": "036",
        "resource_name": "resident_female_04",
        "display_name": "Thanh Niên Nữ Áo Cam Đất",
        "role": "civilian",
        "gender": "female",
        "description": "Cô gái mùa thu trong chiếc áo dài tay màu cam đất dịu ngọt.",
        "tags": ["civilian", "resident", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Cây cối hai bên đường đang vào mùa thay lá đẹp ngỡ ngàng.",
            "Tôi vừa ghé qua tiệm hoa mua một bó cúc họa mi nhỏ về cắm bàn.",
            "Yêu thương bản thân và ngắm nhìn những điều bình dị quanh mình."
        ]
    },
    {
        "file": "Character-Variation-1_09.png",
        "id": "037",
        "resource_name": "resident_male_05",
        "display_name": "Thanh Niên Nam Áo Sơ Mi Nâu",
        "role": "civilian",
        "gender": "male",
        "description": "Chàng trai lịch lãm với áo sơ mi màu nâu camel và quần xanh sẫm.",
        "tags": ["civilian", "resident", "male"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Hôm nay tôi có hẹn gặp đối tác ở quán cà phê trung tâm.",
            "Thành phố phát triển mở ra rất nhiều cơ hội hợp tác mới.",
            "Hy vọng công việc của bạn cũng luôn suôn sẻ và gặt hái thành công."
        ]
    },
    {
        "file": "Character-Variation-1_10.png",
        "id": "038",
        "resource_name": "resident_female_05",
        "display_name": "Thanh Niên Nữ Áo Tím Oải Hương",
        "role": "civilian",
        "gender": "female",
        "description": "Cô gái nữ tính với áo blouse màu tím lavender ngọt ngào.",
        "tags": ["civilian", "resident", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Mùi hương hoa oải hương làm dịu đi những căng thẳng bộn bề.",
            "Thành phố này có những góc ban công trồng hoa rực rỡ rất thơ mộng.",
            "Chúc bạn luôn tìm thấy niềm vui trong từng việc nhỏ nhặt!"
        ]
    },
    {
        "file": "Character-Variation-1_11.png",
        "id": "039",
        "resource_name": "resident_male_06",
        "display_name": "Thanh Niên Nam Áo Choàng Đỏ",
        "role": "civilian",
        "gender": "male",
        "description": "Nam thanh niên cá tính trong chiếc áo khoác dày đỏ thẫm ấm áp.",
        "tags": ["civilian", "resident", "male"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Mùa đông ở thành phố có chiếc áo ấm này là yên tâm rồi.",
            "Chợ đêm mùa lạnh đông đúc với vô số món ăn đường phố nghi ngút khói.",
            "Hãy nhớ giữ ấm cổ họng khi trời trở gió bạn nhé."
        ]
    },
    {
        "file": "Character-Variation-1_12.png",
        "id": "040",
        "resource_name": "resident_female_06",
        "display_name": "Thanh Niên Nữ Áo Hồng Phấn",
        "role": "civilian",
        "gender": "female",
        "description": "Nữ sinh dễ thương trong chiếc áo thun hồng phấn và mái tóc búi.",
        "tags": ["civilian", "resident", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn nha! Hôm nay là một ngày tuyệt vời để khám phá thành phố.",
            "Tôi vừa kết nạp thêm vài người bạn mới ở câu lạc bộ ngoại khóa.",
            "Thân thiện mở lòng sẽ giúp bạn có thêm thật nhiều bạn tốt!"
        ]
    },
    {
        "file": "Character-Variation-1_13.png",
        "id": "041",
        "resource_name": "resident_male_07",
        "display_name": "Thanh Niên Nam Áo Khoác Xanh Đậm",
        "role": "civilian",
        "gender": "male",
        "description": "Chàng trai phóng khoáng với áo khoác bomber màu xanh navy.",
        "tags": ["civilian", "resident", "male"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Điểm dừng chân tiếp theo của bạn trong chuyến đi là đâu?",
            "Thành phố này có hệ thống chỉ dẫn đường bộ rất rõ ràng và dễ tìm.",
            "Cứ tự tin khám phá, mỗi con phố đều có một câu chuyện riêng."
        ]
    },
    {
        "file": "Character-Variation-1_14.png",
        "id": "042",
        "resource_name": "resident_female_07",
        "display_name": "Thanh Niên Nữ Áo Xanh Cốm",
        "role": "civilian",
        "gender": "female",
        "description": "Cô gái tươi tắn trong chiếc áo màu xanh cốm mùa xuân rạng rỡ.",
        "tags": ["civilian", "resident", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Màu xanh lá luôn gợi nhắc đến sức sống tràn trề của thiên nhiên.",
            "Tôi đang tham gia dự án trồng thêm một triệu cây xanh cho đô thị.",
            "Cùng nhau chung tay để thành phố mãi xanh tươi nhé!"
        ]
    },
    {
        "file": "Character-Variation-1_15.png",
        "id": "043",
        "resource_name": "resident_male_08",
        "display_name": "Thanh Niên Nam Áo Khoác Xanh Xám",
        "role": "civilian",
        "gender": "male",
        "description": "Nam cư dân điềm đạm với áo khoác gió xanh xám nhẹ nhàng.",
        "tags": ["civilian", "resident", "male"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Thong thả tản bộ ngắm cảnh thành phố giúp xua tan áp lực.",
            "Tiếng chim hót ríu rít ở công viên hòa vào nhịp sống đô thị thật êm dịu.",
            "Chúc bạn có một buổi tối an lành và thư thái bên gia đình."
        ]
    },
    {
        "file": "Character-Variation-1_16.png",
        "id": "044",
        "resource_name": "resident_female_08",
        "display_name": "Thanh Niên Nữ Áo Cam Pastel",
        "role": "civilian",
        "gender": "female",
        "description": "Cô gái thanh lịch diện áo len mỏng màu cam phấn nhã nhặn.",
        "tags": ["civilian", "resident", "female"],
        "speed": 60.0,
        "dialogues": [
            "Chào bạn! Nắng chiều hoàng hôn chiếu lên các tòa nhà đẹp như một bức tranh.",
            "Tôi rất yêu nhịp sống chan hòa, văn minh của cư dân thành phố mình.",
            "Hy vọng bạn cũng cảm nhận được sự ấm áp của mảnh đất này!"
        ]
    }
]


def get_image_uid(filename: str) -> str:
    import_path = os.path.join(ASSETS_DIR, filename + ".import")
    if os.path.exists(import_path):
        with open(import_path, "r", encoding="utf-8") as f:
            m = re.search(r'uid="([^"]+)"', f.read())
            if m:
                return m.group(1)
    # deterministic fallback if not yet imported
    h = hashlib.sha1(filename.encode("utf-8")).hexdigest()[:13]
    return f"uid://c{h}"


def generate_sub_id(base_name: str, key: str) -> str:
    # 5 char alphanumeric hash
    h = hashlib.sha1(f"{base_name}_{key}".encode("utf-8")).hexdigest()[:5]
    return f"{key}_{h}"


def build_tres_content(char_info: dict) -> str:
    filename = char_info["file"]
    res_name = char_info["resource_name"]
    img_uid = get_image_uid(filename)
    tex_res_id = f"2_{res_name[:5]}"

    # Deterministic resource UID
    h = hashlib.sha1(res_name.encode("utf-8")).hexdigest()[:13]
    res_uid = f"uid://r{h}"

    # Animation definitions: 8 animations x 4 frames
    # Row 0 (y = 0): idle
    # Cols: front_left (0..3), front_right (4..7), back_right (8..11), back_left (12..15)
    # Row 1 (y = 48): walk
    anim_configs = [
        ("idle_front_left", 0, 0),
        ("idle_front_right", 128, 0),
        ("idle_back_right", 256, 0),
        ("idle_back_left", 384, 0),
        ("walk_front_left", 0, 48),
        ("walk_front_right", 128, 48),
        ("walk_back_right", 256, 48),
        ("walk_back_left", 384, 48),
    ]

    atlas_textures = []
    anim_frames = {}

    for anim_name, start_x, start_y in anim_configs:
        frame_ids = []
        for f in range(4):
            x = start_x + f * 32
            y = start_y
            sub_id = f"AtlasTexture_{res_name[:4]}_{anim_name}_{f}"
            atlas_textures.append({
                "id": sub_id,
                "region": f"Rect2({x}, {y}, 32, 48)"
            })
            frame_ids.append(sub_id)
        anim_frames[anim_name] = frame_ids


    sprite_frames_id = f"SpriteFrames_{res_name[:5]}"

    # Header
    out = []
    out.append(f'[gd_resource type="Resource" script_class="NPCData" format=3 uid="{res_uid}"]')
    out.append('')
    out.append(f'[ext_resource type="Script" uid="{NPCDATA_SCRIPT_UID}" path="{NPCDATA_SCRIPT_PATH}" id="1_npcdata"]')
    out.append(f'[ext_resource type="Texture2D" uid="{img_uid}" path="res://assets/spritesheets/characters/{filename}" id="{tex_res_id}"]')
    out.append('')

    # Sub-resources: AtlasTexture
    for at in atlas_textures:
        out.append(f'[sub_resource type="AtlasTexture" id="{at["id"]}"]')
        out.append(f'atlas = ExtResource("{tex_res_id}")')
        out.append(f'region = {at["region"]}')
        out.append('')

    # Sub-resource: SpriteFrames (Alphabetical animations order)
    out.append(f'[sub_resource type="SpriteFrames" id="{sprite_frames_id}"]')
    out.append('animations = [{')

    sorted_anims = sorted(anim_frames.keys())
    for idx, a_name in enumerate(sorted_anims):
        frames = anim_frames[a_name]
        out.append('"frames": [{')
        for f_idx, fid in enumerate(frames):
            out.append('"duration": 1.0,')
            out.append(f'"texture": SubResource("{fid}")')
            if f_idx < len(frames) - 1:
                out.append('}, {')
            else:
                out.append('}],')
        out.append('"loop": 1,')
        out.append(f'"name": &"{a_name}",')
        out.append('"speed": 5.0')
        if idx < len(sorted_anims) - 1:
            out.append('}, {')
        else:
            out.append('}]')

    out.append('')
    # Main resource block
    out.append('[resource]')
    out.append('script = ExtResource("1_npcdata")')
    out.append(f'id = &"{char_info["id"]}"')
    out.append(f'display_name = "{char_info["display_name"]}"')
    out.append(f'role = &"{char_info["role"]}"')
    out.append(f'gender = &"{char_info["gender"]}"')
    out.append(f'description = "{char_info["description"]}"')
    out.append(f'sprite_frames = SubResource("{sprite_frames_id}")')
    out.append(f'spritesheet_path = "res://assets/spritesheets/characters/{filename}"')
    out.append(f'move_speed = {char_info["speed"]}')
    out.append('wander_radius = 120.0')
    out.append('min_idle_time = 1.5')
    out.append('max_idle_time = 4.0')
    out.append('interaction_type = &"talk"')
    
    # Dialogues array formatted for Godot tres
    dialogues_escaped = [d.replace('"', '\\"') for d in char_info["dialogues"]]
    dialogues_str = ", ".join([f'"{d}"' for d in dialogues_escaped])
    out.append(f'dialogues = [{dialogues_str}]')
    
    tags_str = ", ".join([f'"{t}"' for t in char_info["tags"]])
    out.append(f'tags = PackedStringArray({tags_str})')
    out.append(f'metadata/_custom_type_script = "{NPCDATA_SCRIPT_UID}"')
    out.append('')

    return "\n".join(out)


def main():
    os.makedirs(NPCS_DIR, exist_ok=True)
    registry_assets = {}

    print(f"Generating resources for {len(CHARACTERS)} characters...")

    for char in CHARACTERS:
        tres_path = os.path.join(NPCS_DIR, f"{char['resource_name']}.tres")
        content = build_tres_content(char)
        with open(tres_path, "w", encoding="utf-8") as f:
            f.write(content)
        
        # Add to asset_registry
        registry_assets[char["id"]] = {
            "id": char["id"],
            "resource_name": char["resource_name"],
            "display_name": char["display_name"],
            "role": char["role"],
            "gender": char["gender"],
            "description": char["description"],
            "spritesheet": f"res://assets/spritesheets/characters/{char['file']}",
            "resource_path": f"res://data/npcs/{char['resource_name']}.tres",
            "speed": char["speed"],
            "tags": char["tags"]
        }

    # Also register by resource_name alias in registry
    print(f"Saved {len(CHARACTERS)} .tres files in {NPCS_DIR}")

    # Write asset_registry.json
    registry_data = {
        "_comment": "AI-readable asset registry. Generated for all 44 NPCs in the city game.",
        "total_npcs": len(CHARACTERS),
        "assets": registry_assets
    }
    with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
        json.dump(registry_data, f, ensure_ascii=False, indent=2)

    print(f"Updated {REGISTRY_PATH}")


if __name__ == "__main__":
    main()
