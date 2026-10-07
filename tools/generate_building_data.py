#!/usr/bin/env python3
"""
Bộ sinh tài nguyên BuildingData (.tres) và Asset Registry cho toàn bộ 45 tòa nhà đô thị.
Hỗ trợ:
- 1 cửa đơn (34 tòa nhà)
- 2 cửa đóng mở độc lập (5 tòa nhà: Firestation, PoliceStation, Library, Prison, Restroom)
- Nhiều biến thể màu sắc khác nhau trong cùng 1 ảnh (Beachhouse 3 màu, Small Beachhouse 3 màu)
"""

import os
import sys
import re
import json
import hashlib

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets", "spritesheets", "buildings", "Building Door Animations")
BUILDINGS_DIR = os.path.join(BASE_DIR, "data", "buildings")
REGISTRY_PATH = os.path.join(BASE_DIR, "data", "asset_registry.json")
BUILDDATA_SCRIPT_PATH = "res://scripts/buildings/BuildingData.gd"


BUILDINGS = [
    # ==========================================================================
    # 1. TÒA NHÀ 2 CỬA ĐÓNG MỞ ĐỘC LẬP (TWO DOORS)
    # ==========================================================================
    {
        "file": "Firestation Animation.png",
        "id": "bld_001",
        "resource_name": "firestation_01",
        "display_name": "Trạm Cứu Hỏa Thành Phố",
        "building_type": "emergency",
        "door_count": 2,
        "door_names": ["Cửa Nhân Viên", "Cửa Cuốn Gara Xe"],
        "color_variant": "default",
        "frame_size": [304, 224],
        "door_rows": [1, 0], # Row 1: Left personnel door, Row 0: Right garage door
        "collision_size": [270, 70],
        "door_positions": [[-110, -10], [70, -10]],
        "description": "Trạm cứu hỏa trung tâm trang bị 2 cửa: cửa đi bộ nhân viên bên trái và cửa cuốn gara xe bên phải."
    },
    {
        "file": "PoliceStation Animation.png",
        "id": "bld_002",
        "resource_name": "police_station_01",
        "display_name": "Đồn Cảnh Sát Thành Phố",
        "building_type": "emergency",
        "door_count": 2,
        "door_names": ["Cửa Văn Phòng", "Cửa Cuốn Gara Xe"],
        "color_variant": "default",
        "frame_size": [224, 160],
        "door_rows": [0, 1], # Row 0: Left office door, Row 1: Right garage door
        "collision_size": [200, 50],
        "door_positions": [[-70, -8], [50, -8]],
        "description": "Trụ sở cảnh sát đô thị với cửa kính văn phòng bên trái và cửa cuốn gara xe tuần tra bên phải."
    },
    {
        "file": "Library Sheet.png",
        "id": "bld_003",
        "resource_name": "library_city_01",
        "display_name": "Thư Viện Trung Tâm",
        "building_type": "public",
        "door_count": 2,
        "door_names": ["Cửa Cánh Trái", "Cửa Cánh Phải"],
        "color_variant": "default",
        "frame_size": [224, 160],
        "door_rows": [0, 1], # Row 0: Left door, Row 1: Right door
        "collision_size": [200, 50],
        "door_positions": [[-55, -8], [55, -8]],
        "description": "Thư viện thành phố với sảnh lớn và 2 cánh cửa ra vào độc lập hai bên."
    },
    {
        "file": "Prison-Sheet.png",
        "id": "bld_004",
        "resource_name": "prison_city_01",
        "display_name": "Trại Giam / Nhà Tù",
        "building_type": "public",
        "door_count": 2,
        "door_names": ["Cổng Sắt Trái", "Cổng Sắt Phải"],
        "color_variant": "default",
        "frame_size": [272, 176],
        "door_rows": [0, 1], # Row 0: Left gate, Row 1: Right gate
        "collision_size": [245, 60],
        "door_positions": [[-90, -10], [90, -10]],
        "description": "Trại giam kiên cố với 2 cổng an ninh bằng thép bảo vệ nghiêm ngặt."
    },
    {
        "file": "Restroom Animation.png",
        "id": "bld_005",
        "resource_name": "restroom_public_01",
        "display_name": "Nhà Vệ Sinh Công Cộng",
        "building_type": "amenity",
        "door_count": 2,
        "door_names": ["Cửa Nam (Trái)", "Cửa Nữ (Phải)"],
        "color_variant": "default",
        "frame_size": [112, 96],
        "door_rows": [0, 1], # Row 0: Left door (Men), Row 1: Right door (Women)
        "collision_size": [100, 36],
        "door_positions": [[-28, -6], [28, -6]],
        "description": "Nhà vệ sinh công cộng đô thị với 2 cửa riêng biệt cho Nam (trái) và Nữ (phải)."
    },

    # ==========================================================================
    # 2. TÒA NHÀ CÙNG LOẠI KHÁC MÀU CHUNG 1 ẢNH (MULTI-COLOR)
    # ==========================================================================
    # Beachhouseblue Animation.png (3 hàng = 3 màu)
    {
        "file": "Beachhouseblue Animation.png",
        "id": "bld_006",
        "resource_name": "beachhouse_blue_01",
        "display_name": "Nhà Bãi Biển Xanh Dương",
        "building_type": "residential",
        "door_count": 1,
        "door_names": ["Cửa Chính"],
        "color_variant": "blue",
        "frame_size": [176, 176],
        "row_index": 0,
        "collision_size": [150, 50],
        "door_positions": [[0, -8]],
        "description": "Biệt thự nghỉ dưỡng bãi biển sơn màu xanh dương ven bờ biển."
    },
    {
        "file": "Beachhouseblue Animation.png",
        "id": "bld_007",
        "resource_name": "beachhouse_yellow_01",
        "display_name": "Nhà Bãi Biển Vàng Kem",
        "building_type": "residential",
        "door_count": 1,
        "door_names": ["Cửa Chính"],
        "color_variant": "yellow",
        "frame_size": [176, 176],
        "row_index": 1,
        "collision_size": [150, 50],
        "door_positions": [[0, -8]],
        "description": "Biệt thự nghỉ dưỡng bãi biển sơn màu vàng kem ấm áp."
    },
    {
        "file": "Beachhouseblue Animation.png",
        "id": "bld_008",
        "resource_name": "beachhouse_pink_01",
        "display_name": "Nhà Bãi Biển Hồng Pastel",
        "building_type": "residential",
        "door_count": 1,
        "door_names": ["Cửa Chính"],
        "color_variant": "pink",
        "frame_size": [176, 176],
        "row_index": 2,
        "collision_size": [150, 50],
        "door_positions": [[0, -8]],
        "description": "Biệt thự nghỉ dưỡng bãi biển sơn màu hồng pastel thơ mộng."
    },

    # Small Beach House-Sheet.png (3 hàng = 3 màu)
    {
        "file": "Small Beach House-Sheet.png",
        "id": "bld_009",
        "resource_name": "small_beachhouse_yellow_01",
        "display_name": "Nhà Gỗ Bãi Biển Vàng",
        "building_type": "residential",
        "door_count": 1,
        "door_names": ["Cửa Chính"],
        "color_variant": "yellow",
        "frame_size": [128, 144],
        "row_index": 0,
        "collision_size": [110, 44],
        "door_positions": [[16, -6]],
        "description": "Nhà gỗ nhỏ ven biển mái dốc màu vàng tươi tắn."
    },
    {
        "file": "Small Beach House-Sheet.png",
        "id": "bld_010",
        "resource_name": "small_beachhouse_red_01",
        "display_name": "Nhà Gỗ Bãi Biển Đỏ",
        "building_type": "residential",
        "door_count": 1,
        "door_names": ["Cửa Chính"],
        "color_variant": "red",
        "frame_size": [128, 144],
        "row_index": 1,
        "collision_size": [110, 44],
        "door_positions": [[16, -6]],
        "description": "Nhà gỗ nhỏ ven biển mái dốc màu đỏ nổi bật."
    },
    {
        "file": "Small Beach House-Sheet.png",
        "id": "bld_011",
        "resource_name": "small_beachhouse_blue_01",
        "display_name": "Nhà Gỗ Bãi Biển Xanh",
        "building_type": "residential",
        "door_count": 1,
        "door_names": ["Cửa Chính"],
        "color_variant": "blue",
        "frame_size": [128, 144],
        "row_index": 2,
        "collision_size": [110, 44],
        "door_positions": [[16, -6]],
        "description": "Nhà gỗ nhỏ ven biển mái dốc màu xanh biển thanh bình."
    },

    # ==========================================================================
    # 3. TÒA NHÀ 1 CỬA TIÊU CHUẨN (SINGLE DOOR - 34 TÒA NHÀ)
    # ==========================================================================
    {
        "file": "Bakery Animation.png",
        "id": "bld_012",
        "resource_name": "bakery_standard_01",
        "display_name": "Tiệm Bánh Mì Cổ Điển",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [112, 160],
        "description": "Tiệm bánh mì thơm lừng phong cách gạch cổ điển có biển hiệu và mái che sọc xanh."
    },
    {
        "file": "Bakery Clean Animation.png",
        "id": "bld_013",
        "resource_name": "bakery_clean_01",
        "display_name": "Tiệm Bánh Mì Hiện Đại",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [112, 144],
        "description": "Tiệm bánh mì phong cách hiện đại tối giản với cửa kính trong suốt."
    },
    {
        "file": "Bank Animation.png",
        "id": "bld_014",
        "resource_name": "bank_central_01",
        "display_name": "Ngân Hàng Trung Tâm",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [208, 208],
        "description": "Trụ sở ngân hàng đồ sộ với mái vòm và cửa kính sang trọng an toàn."
    },
    {
        "file": "Bar Animation.png",
        "id": "bld_015",
        "resource_name": "bar_pub_01",
        "display_name": "Quán Rượu / Bar Phố",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [96, 144],
        "description": "Quán bar sôi động với đèn neon và cửa gỗ mở đón khách buổi tối."
    },
    {
        "file": "Bar Clean Animation.png",
        "id": "bld_016",
        "resource_name": "bar_clean_01",
        "display_name": "Quán Bar Hiện Đại Clean",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [96, 144],
        "description": "Quán bar hiện đại phong cách tối giản thanh lịch."
    },
    {
        "file": "Barbershop Animation.png",
        "id": "bld_017",
        "resource_name": "barbershop_01",
        "display_name": "Tiệm Cắt Tóc Barbershop",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [144, 128],
        "description": "Tiệm cắt tóc quý ông cổ điển với cột xoay sọc màu đặc trưng."
    },
    {
        "file": "Barbershop Clean Animation.png",
        "id": "bld_018",
        "resource_name": "barbershop_clean_01",
        "display_name": "Tiệm Cắt Tóc Hiện Đại",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [144, 128],
        "description": "Salon tóc hiện đại phong cách trẻ trung."
    },
    {
        "file": "Brick Building Animation.png",
        "id": "bld_019",
        "resource_name": "brick_building_01",
        "display_name": "Tòa Nhà Gạch Nâu",
        "building_type": "residential",
        "door_count": 1,
        "frame_size": [112, 208],
        "description": "Tòa nhà chung cư / văn phòng ốp gạch nâu trầm cổ kính."
    },
    {
        "file": "Burgershop Animation.png",
        "id": "bld_020",
        "resource_name": "burgershop_01",
        "display_name": "Tiệm Bánh Burger",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [176, 128],
        "description": "Quán đồ ăn nhanh phục vụ hamburger và khoai tây chiên."
    },
    {
        "file": "Cafe Animation.png",
        "id": "bld_021",
        "resource_name": "cafe_shop_01",
        "display_name": "Quán Cà Phê Phố",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [144, 112],
        "description": "Quán cà phê góc phố có mái hiên che và cửa kính mở rộng chào đón khách."
    },
    {
        "file": "Cafe Clean Animation.png",
        "id": "bld_022",
        "resource_name": "cafe_clean_01",
        "display_name": "Quán Cà Phê Hiện Đại",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [144, 112],
        "description": "Quán cà phê phong cách tối giản không gian mở."
    },
    {
        "file": "Campus Building Animation.png",
        "id": "bld_023",
        "resource_name": "campus_building_01",
        "display_name": "Tòa Giảng Đường Campus",
        "building_type": "public",
        "door_count": 1,
        "frame_size": [112, 208],
        "description": "Tòa nhà khuôn viên trường đại học với cửa kính ra vào giảng đường."
    },
    {
        "file": "Cinema Door Animation.png",
        "id": "bld_024",
        "resource_name": "cinema_theater_01",
        "display_name": "Rạp Chiếu Phim Cinema",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [208, 224],
        "description": "Rạp chiếu phim thành phố với bảng đèn áp phích phim rực rỡ."
    },
    {
        "file": "Convenient Store Animation.png",
        "id": "bld_025",
        "resource_name": "convenient_store_01",
        "display_name": "Cửa Hàng Tiện Lợi 24/7",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [160, 160],
        "description": "Cửa hàng tiện ích mở cửa 24/7 phục vụ nhu yếu phẩm hàng ngày."
    },
    {
        "file": "Convenient Store Clean Animation.png",
        "id": "bld_026",
        "resource_name": "convenient_store_clean_01",
        "display_name": "Cửa Hàng Tiện Lợi Clean",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [160, 160],
        "description": "Cửa hàng tiện lợi hiện đại phiên bản sạch sẽ tinh tế."
    },
    {
        "file": "Fast food restaurant Animation.png",
        "id": "bld_027",
        "resource_name": "fast_food_restaurant_01",
        "display_name": "Nhà Hàng Thức Ăn Nhanh",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [176, 128],
        "description": "Nhà hàng thức ăn nhanh phục vụ các món ăn nóng hổi nhanh gọn."
    },
    {
        "file": "Gas Station-Sheet.png",
        "id": "bld_028",
        "resource_name": "gas_station_01",
        "display_name": "Trạm Xăng Đô Thị",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [208, 160],
        "description": "Cửa hàng tiện ích kèm trạm tiếp nhiên liệu cho xe cộ qua lại."
    },
    {
        "file": "Green Brick building Animation.png",
        "id": "bld_029",
        "resource_name": "green_brick_building_01",
        "display_name": "Tòa Nhà Gạch Xanh Lá",
        "building_type": "residential",
        "door_count": 1,
        "frame_size": [112, 192],
        "description": "Tòa nhà gạch phủ rêu xanh mát mắt mang phong cách thiên nhiên."
    },
    {
        "file": "Hospital-Sheet.png",
        "id": "bld_030",
        "resource_name": "hospital_city_01",
        "display_name": "Bệnh Viện Đa Khoa",
        "building_type": "emergency",
        "door_count": 1,
        "frame_size": [144, 320],
        "description": "Bệnh viện đa khoa cao tầng với sân bay trực thăng y tế trên mái nhà."
    },
    {
        "file": "Hotel Door Animation.png",
        "id": "bld_031",
        "resource_name": "hotel_grand_01",
        "display_name": "Khách Sạn Grand Hotel",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [192, 192],
        "description": "Khách sạn cao cấp sang trọng đón tiếp du khách bốn phương."
    },
    {
        "file": "Inn Animation.png",
        "id": "bld_032",
        "resource_name": "inn_hotel_01",
        "display_name": "Quán Trọ Lữ Hành Inn",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [144, 176],
        "description": "Quán trọ dừng chân ấm cúng cho các lữ khách qua đường."
    },
    {
        "file": "Japanese Restaurant Animation.png",
        "id": "bld_033",
        "resource_name": "japanese_restaurant_01",
        "display_name": "Nhà Hàng Nhật Bản",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [160, 112],
        "description": "Nhà hàng ẩm thực truyền thống Nhật Bản với mái ngói và rèm cửa noren."
    },
    {
        "file": "Lightblue Building-Sheet.png",
        "id": "bld_034",
        "resource_name": "lightblue_building_01",
        "display_name": "Tòa Nhà Xanh Nhạt",
        "building_type": "residential",
        "door_count": 1,
        "frame_size": [144, 224],
        "description": "Tòa nhà căn hộ cao tầng sơn màu xanh nhạt hiện đại."
    },
    {
        "file": "Lighthouse-Sheet.png",
        "id": "bld_035",
        "resource_name": "lighthouse_01",
        "display_name": "Ngọn Hải Đăng Cảng Biển",
        "building_type": "public",
        "door_count": 1,
        "frame_size": [128, 288],
        "description": "Ngọn hải đăng sừng sững ven cảng biển dẫn lối cho tàu thuyền cập bến."
    },
    {
        "file": "Mall Door Animation.png",
        "id": "bld_036",
        "resource_name": "mall_shopping_01",
        "display_name": "Trung Tâm Thương Mại Mall",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [224, 304],
        "description": "Trung tâm thương mại sầm uất với cửa xoay tự động và biển hiệu lớn."
    },
    {
        "file": "Motel-Sheet.png",
        "id": "bld_037",
        "resource_name": "motel_lodge_01",
        "display_name": "Nhà Nghỉ Ven Đường Motel",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [208, 176],
        "description": "Nhà nghỉ ven đường cao tốc với biển hiệu neon quen thuộc."
    },
    {
        "file": "Pizza shop Animation.png",
        "id": "bld_038",
        "resource_name": "pizza_shop_01",
        "display_name": "Tiệm Pizza Ý",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [144, 128],
        "description": "Tiệm bánh pizza nướng củi thơm phức phong cách Ý."
    },
    {
        "file": "Pizza shop Clean Animation.png",
        "id": "bld_039",
        "resource_name": "pizza_shop_clean_01",
        "display_name": "Tiệm Pizza Hiện Đại",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [144, 128],
        "description": "Tiệm pizza phong cách hiện đại sạch sẽ gọn gàng."
    },
    {
        "file": "Portable Office-sheet.png",
        "id": "bld_040",
        "resource_name": "portable_office_01",
        "display_name": "Văn Phòng Di Động",
        "building_type": "industrial",
        "door_count": 1,
        "frame_size": [128, 112],
        "description": "Văn phòng container di động phục vụ ban quản lý công trường."
    },
    {
        "file": "Portable Toilet-sheet.png",
        "id": "bld_041",
        "resource_name": "portable_toilet_01",
        "display_name": "Nhà Vệ Sinh Lưu Động",
        "building_type": "amenity",
        "door_count": 1,
        "frame_size": [32, 96],
        "description": "Bốt vệ sinh lưu động màu xanh đặt tại các sự kiện hoặc công trường."
    },
    {
        "file": "Ramen stand Animation.png",
        "id": "bld_042",
        "resource_name": "ramen_stand_01",
        "display_name": "Quán Mì Ramen Nhật",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [128, 128],
        "description": "Quán mì ramen ấm áp với đèn lồng đỏ và rèm che phấp phới."
    },
    {
        "file": "Supermarket Animation.png",
        "id": "bld_043",
        "resource_name": "supermarket_city_01",
        "display_name": "Siêu Thị Đô Thị Supermarket",
        "building_type": "commercial",
        "door_count": 1,
        "frame_size": [304, 176],
        "description": "Đại siêu thị mua sắm với cửa trượt tự động và sảnh đón rộng lớn."
    },
    {
        "file": "Wood Building-Sheet.png",
        "id": "bld_044",
        "resource_name": "wood_building_01",
        "display_name": "Tòa Nhà Gỗ Truyền Thống",
        "building_type": "residential",
        "door_count": 1,
        "frame_size": [112, 176],
        "description": "Nhà ở bằng gỗ mộc mạc lưu giữ nét kiến trúc cổ điển."
    },
    {
        "file": "Yellow Building-Sheet.png",
        "id": "bld_045",
        "resource_name": "yellow_building_01",
        "display_name": "Tòa Nhà Màu Vàng",
        "building_type": "residential",
        "door_count": 1,
        "frame_size": [112, 192],
        "description": "Tòa nhà đô thị sơn vàng nổi bật giữa góc phố nhộn nhịp."
    }
]


def get_image_uid(filename: str) -> str:
    import_path = os.path.join(ASSETS_DIR, filename + ".import")
    if os.path.exists(import_path):
        with open(import_path, "r", encoding="utf-8") as f:
            m = re.search(r'uid="([^"]+)"', f.read())
            if m:
                return m.group(1)
    h = hashlib.sha1(filename.encode("utf-8")).hexdigest()[:13]
    return f"uid://c{h}"


def build_tres_content(bld_info: dict) -> str:
    filename = bld_info["file"]
    res_name = bld_info["resource_name"]
    img_uid = get_image_uid(filename)
    tex_res_id = f"2_{res_name[:6]}"

    h = hashlib.sha1(res_name.encode("utf-8")).hexdigest()[:13]
    res_uid = f"uid://b{h}"

    fw, fh = bld_info["frame_size"]
    door_count = bld_info.get("door_count", 1)
    row_idx = bld_info.get("row_index", 0)

    atlas_textures = []
    anim_frames = {}

    if door_count >= 2:
        door_rows = bld_info.get("door_rows", [0, 1])
        # Door 0 (Left Door)
        r0 = door_rows[0]
        # Door 1 (Right Door)
        r1 = door_rows[1]

        # Left Door Animation frames
        f_left_closed = f"AtlasTexture_{res_name[:4]}_dl_closed"
        f_left_opened = f"AtlasTexture_{res_name[:4]}_dl_opened"
        atlas_textures.append({"id": f_left_closed, "region": f"Rect2(0, {r0 * fh}, {fw}, {fh})"})
        atlas_textures.append({"id": f_left_opened, "region": f"Rect2({3 * fw}, {r0 * fh}, {fw}, {fh})"})

        left_open_ids = []
        for f in [0, 1, 2, 3]:
            sub_id = f"AtlasTexture_{res_name[:4]}_dl_op_{f}"
            atlas_textures.append({"id": sub_id, "region": f"Rect2({f * fw}, {r0 * fh}, {fw}, {fh})"})
            left_open_ids.append(sub_id)

        left_close_ids = []
        for f in [3, 4, 5, 0]:
            sub_id = f"AtlasTexture_{res_name[:4]}_dl_cl_{f}"
            atlas_textures.append({"id": sub_id, "region": f"Rect2({f * fw}, {r0 * fh}, {fw}, {fh})"})
            left_close_ids.append(sub_id)

        anim_frames["door_left_closed"] = ([f_left_closed], 1.0, 0)
        anim_frames["door_left_opened"] = ([f_left_opened], 1.0, 0)
        anim_frames["door_left_open"] = (left_open_ids, 6.0, 0)
        anim_frames["door_left_close"] = (left_close_ids, 6.0, 0)

        # Right Door Animation frames
        f_right_closed = f"AtlasTexture_{res_name[:4]}_dr_closed"
        f_right_opened = f"AtlasTexture_{res_name[:4]}_dr_opened"
        atlas_textures.append({"id": f_right_closed, "region": f"Rect2(0, {r1 * fh}, {fw}, {fh})"})
        atlas_textures.append({"id": f_right_opened, "region": f"Rect2({3 * fw}, {r1 * fh}, {fw}, {fh})"})

        right_open_ids = []
        for f in [0, 1, 2, 3]:
            sub_id = f"AtlasTexture_{res_name[:4]}_dr_op_{f}"
            atlas_textures.append({"id": sub_id, "region": f"Rect2({f * fw}, {r1 * fh}, {fw}, {fh})"})
            right_open_ids.append(sub_id)

        right_close_ids = []
        for f in [3, 4, 5, 0]:
            sub_id = f"AtlasTexture_{res_name[:4]}_dr_cl_{f}"
            atlas_textures.append({"id": sub_id, "region": f"Rect2({f * fw}, {r1 * fh}, {fw}, {fh})"})
            right_close_ids.append(sub_id)

        anim_frames["door_right_closed"] = ([f_right_closed], 1.0, 0)
        anim_frames["door_right_opened"] = ([f_right_opened], 1.0, 0)
        anim_frames["door_right_open"] = (right_open_ids, 6.0, 0)
        anim_frames["door_right_close"] = (right_close_ids, 6.0, 0)

        # Alias for single-door compatibility
        anim_frames["door_closed"] = ([f_left_closed], 1.0, 0)
        anim_frames["door_opened"] = ([f_left_opened], 1.0, 0)

    else:
        # 1 Cửa đơn
        y = row_idx * fh
        f_closed = f"AtlasTexture_{res_name[:4]}_d_closed"
        f_opened = f"AtlasTexture_{res_name[:4]}_d_opened"
        atlas_textures.append({"id": f_closed, "region": f"Rect2(0, {y}, {fw}, {fh})"})
        atlas_textures.append({"id": f_opened, "region": f"Rect2({3 * fw}, {y}, {fw}, {fh})"})

        open_ids = []
        for f in [0, 1, 2, 3]:
            sub_id = f"AtlasTexture_{res_name[:4]}_d_op_{f}"
            atlas_textures.append({"id": sub_id, "region": f"Rect2({f * fw}, {y}, {fw}, {fh})"})
            open_ids.append(sub_id)

        close_ids = []
        for f in [3, 4, 5, 0]:
            sub_id = f"AtlasTexture_{res_name[:4]}_d_cl_{f}"
            atlas_textures.append({"id": sub_id, "region": f"Rect2({f * fw}, {y}, {fw}, {fh})"})
            close_ids.append(sub_id)

        cycle_ids = []
        for f in range(6):
            sub_id = f"AtlasTexture_{res_name[:4]}_d_cy_{f}"
            atlas_textures.append({"id": sub_id, "region": f"Rect2({f * fw}, {y}, {fw}, {fh})"})
            cycle_ids.append(sub_id)

        anim_frames["door_closed"] = ([f_closed], 1.0, 0)
        anim_frames["door_opened"] = ([f_opened], 1.0, 0)
        anim_frames["door_open"] = (open_ids, 6.0, 0)
        anim_frames["door_close"] = (close_ids, 6.0, 0)
        anim_frames["door_cycle"] = (cycle_ids, 5.0, 1)

    sprite_frames_id = f"SpriteFrames_{res_name[:6]}"

    out = []
    out.append(f'[gd_resource type="Resource" script_class="BuildingData" format=3 uid="{res_uid}"]')
    out.append('')
    out.append(f'[ext_resource type="Script" path="{BUILDDATA_SCRIPT_PATH}" id="1_builddata"]')
    out.append(f'[ext_resource type="Texture2D" uid="{img_uid}" path="res://assets/spritesheets/buildings/Building Door Animations/{filename}" id="{tex_res_id}"]')
    out.append('')

    for at in atlas_textures:
        out.append(f'[sub_resource type="AtlasTexture" id="{at["id"]}"]')
        out.append(f'atlas = ExtResource("{tex_res_id}")')
        out.append(f'region = {at["region"]}')
        out.append('')

    out.append(f'[sub_resource type="SpriteFrames" id="{sprite_frames_id}"]')
    out.append('animations = [{')

    sorted_anims = sorted(anim_frames.keys())
    for idx, a_name in enumerate(sorted_anims):
        frames, speed, loop = anim_frames[a_name]
        out.append('"frames": [{')
        for f_idx, fid in enumerate(frames):
            out.append('"duration": 1.0,')
            out.append(f'"texture": SubResource("{fid}")')
            if f_idx < len(frames) - 1:
                out.append('}, {')
            else:
                out.append('}],')
        out.append(f'"loop": {loop},')
        out.append(f'"name": &"{a_name}",')
        out.append(f'"speed": {speed:.1f}')
        if idx < len(sorted_anims) - 1:
            out.append('}, {')
        else:
            out.append('}]')

    out.append('')
    out.append('[resource]')
    out.append('script = ExtResource("1_builddata")')
    out.append(f'id = &"{bld_info["id"]}"')
    out.append(f'display_name = "{bld_info["display_name"]}"')
    out.append(f'building_type = &"{bld_info["building_type"]}"')
    out.append(f'description = "{bld_info.get("description", "")}"')
    out.append(f'frame_size = Vector2i({fw}, {fh})')
    out.append(f'door_count = {door_count}')

    door_names = bld_info.get("door_names", ["Cửa Chính"])
    door_names_str = ", ".join([f'"{d}"' for d in door_names])
    out.append(f'door_names = [{door_names_str}]')
    out.append(f'color_variant = "{bld_info.get("color_variant", "default")}"')
    out.append(f'sprite_frames = SubResource("{sprite_frames_id}")')
    out.append(f'spritesheet_path = "res://assets/spritesheets/buildings/Building Door Animations/{filename}"')

    cw, ch = bld_info.get("collision_size", [max(24, int(fw * 0.85)), max(20, int(fh * 0.35))])
    out.append(f'collision_size = Vector2({cw}, {ch})')
    out.append('collision_offset = Vector2(0, -10)')

    door_positions = bld_info.get("door_positions", [[0, 0]])
    door_positions_str = ", ".join([f'Vector2({p[0]}, {p[1]})' for p in door_positions])
    out.append(f'door_positions = [{door_positions_str}]')

    tags = [bld_info["building_type"], "building", bld_info.get("color_variant", "default")]
    if door_count >= 2:
        tags.append("two_door")
    tags_str = ", ".join([f'"{t}"' for t in tags])
    out.append(f'tags = PackedStringArray({tags_str})')
    out.append('')

    return "\n".join(out)


def main():
    os.makedirs(BUILDINGS_DIR, exist_ok=True)
    print(f"Bắt đầu tạo tài nguyên cho {len(BUILDINGS)} tòa nhà đô thị...")

    registry_data = {"total_npcs": 0, "total_vehicles": 0, "total_buildings": 0, "assets": {}, "vehicles": {}, "buildings": {}}
    if os.path.exists(REGISTRY_PATH):
        try:
            with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
                registry_data = json.load(f)
        except Exception:
            pass

    buildings_dict = {}

    for bld in BUILDINGS:
        tres_path = os.path.join(BUILDINGS_DIR, f"{bld['resource_name']}.tres")
        content = build_tres_content(bld)
        with open(tres_path, "w", encoding="utf-8") as f:
            f.write(content)

        buildings_dict[bld["id"]] = {
            "id": bld["id"],
            "resource_name": bld["resource_name"],
            "display_name": bld["display_name"],
            "building_type": bld["building_type"],
            "door_count": bld.get("door_count", 1),
            "door_names": bld.get("door_names", ["Cửa Chính"]),
            "color_variant": bld.get("color_variant", "default"),
            "frame_size": bld["frame_size"],
            "collision_size": bld.get("collision_size", [int(bld["frame_size"][0] * 0.85), int(bld["frame_size"][1] * 0.35)]),
            "spritesheet": f"res://assets/spritesheets/buildings/Building Door Animations/{bld['file']}",
            "resource_path": f"res://data/buildings/{bld['resource_name']}.tres"
        }

    registry_data["buildings"] = buildings_dict
    registry_data["total_buildings"] = len(buildings_dict)

    with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
        json.dump(registry_data, f, ensure_ascii=False, indent=2)

    print(f"✅ Đã tạo thành công {len(BUILDINGS)} file .tres tại: {BUILDINGS_DIR}")
    print(f"✅ Đã cập nhật tệp registry tại: {REGISTRY_PATH}")


if __name__ == "__main__":
    main()
