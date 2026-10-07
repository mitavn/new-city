#!/usr/bin/env python3
"""
Bộ sinh tài nguyên VehicleData (.tres) và Asset Registry cho toàn bộ 24 phương tiện.
Hỗ trợ kích thước frame khác nhau (96x96, 112x112, 160x160, 176x176, 352x352, 192x128...)
và chế độ còi đèn ưu tiên (Siren) cho các xe khẩn cấp.
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
ASSETS_DIR = os.path.join(BASE_DIR, "assets", "spritesheets", "vehicles")
VEHICLES_DIR = os.path.join(BASE_DIR, "data", "vehicles")
REGISTRY_PATH = os.path.join(BASE_DIR, "data", "asset_registry.json")
VEHDATA_SCRIPT_PATH = "res://scripts/vehicles/VehicleData.gd"
VEHDATA_SCRIPT_UID = "uid://dijugjd2akk5r"


VEHICLES = [
    # 1. Xe Ô Tô Con Nhỏ (96x96)
    {
        "file": "Black Car-(96x96)Sheet.png",
        "id": "veh_001",
        "resource_name": "car_black_01",
        "display_name": "Xe Ô Tô Đen",
        "vehicle_type": "car",
        "category": "land",
        "frame_size": [96, 96],
        "collision_size": [44, 22],
        "speed": 120.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe sedan đô thị 4 chỗ màu đen bóng sang trọng."
    },
    {
        "file": "Dark Blue Car-(96x96)Sheet.png",
        "id": "veh_002",
        "resource_name": "car_dark_blue_01",
        "display_name": "Xe Ô Tô Xanh Đậm",
        "vehicle_type": "car",
        "category": "land",
        "frame_size": [96, 96],
        "collision_size": [44, 22],
        "speed": 120.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe sedan gia đình màu xanh navy đậm thanh lịch."
    },
    {
        "file": "Grey Car-(96x96)Sheet.png",
        "id": "veh_003",
        "resource_name": "car_grey_01",
        "display_name": "Xe Ô Tô Xám",
        "vehicle_type": "car",
        "category": "land",
        "frame_size": [96, 96],
        "collision_size": [44, 22],
        "speed": 120.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe sedan màu xám bạc hiện đại, bền bỉ."
    },
    {
        "file": "Orange Car-Sheet.png",
        "id": "veh_004",
        "resource_name": "car_orange_01",
        "display_name": "Xe Ô Tô Cam",
        "vehicle_type": "car",
        "category": "land",
        "frame_size": [96, 96],
        "collision_size": [44, 22],
        "speed": 125.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe thể thao cỡ nhỏ màu cam nổi bật, trẻ trung."
    },
    {
        "file": "Pink Car-(96x96)Sheet.png",
        "id": "veh_005",
        "resource_name": "car_pink_01",
        "display_name": "Xe Ô Tô Hồng",
        "vehicle_type": "car",
        "category": "land",
        "frame_size": [96, 96],
        "collision_size": [44, 22],
        "speed": 120.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe ô tô màu hồng pastel dễ thương, cá tính."
    },
    {
        "file": "White Car-(96x96)Sheet.png",
        "id": "veh_006",
        "resource_name": "car_white_01",
        "display_name": "Xe Ô Tô Trắng",
        "vehicle_type": "car",
        "category": "land",
        "frame_size": [96, 96],
        "collision_size": [44, 22],
        "speed": 120.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe ô tô màu trắng tinh khôi, trang nhã."
    },

    # 2. Xe Ô Tô Tiêu Chuẩn & Taxi (112x112)
    {
        "file": "Blue car-Sheet(112x112).png",
        "id": "veh_007",
        "resource_name": "car_blue_01",
        "display_name": "Xe Ô Tô Xanh Dương",
        "vehicle_type": "car",
        "category": "land",
        "frame_size": [112, 112],
        "collision_size": [48, 24],
        "speed": 125.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe hatchback đô thị màu xanh dương năng động."
    },
    {
        "file": "Green car-Sheet(112x112).png",
        "id": "veh_008",
        "resource_name": "car_green_01",
        "display_name": "Xe Ô Tô Xanh Lá",
        "vehicle_type": "car",
        "category": "land",
        "frame_size": [112, 112],
        "collision_size": [48, 24],
        "speed": 125.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe ô tô màu xanh lá cây phong cách môi trường."
    },
    {
        "file": "Red car-Sheet(112x112).png",
        "id": "veh_009",
        "resource_name": "car_red_01",
        "display_name": "Xe Ô Tô Đỏ Thể Thao",
        "vehicle_type": "car",
        "category": "land",
        "frame_size": [112, 112],
        "collision_size": [48, 24],
        "speed": 135.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe ô tô đỏ thể thao tốc độ cao đầy lôi cuốn."
    },
    {
        "file": "Taxi-Sheet(112x112).png",
        "id": "veh_010",
        "resource_name": "taxi_standard_01",
        "display_name": "Xe Taxi Đô Thị",
        "vehicle_type": "taxi",
        "category": "land",
        "frame_size": [112, 112],
        "collision_size": [48, 24],
        "speed": 130.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe taxi công cộng phục vụ đưa đón cư dân thành phố."
    },
    {
        "file": "Taxi Yellow(112x112)t.png",
        "id": "veh_011",
        "resource_name": "taxi_yellow_01",
        "display_name": "Xe Taxi Vàng",
        "vehicle_type": "taxi",
        "category": "land",
        "frame_size": [112, 112],
        "collision_size": [48, 24],
        "speed": 130.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Xe taxi vàng biểu tượng cổ điển đặc trưng của thành phố."
    },
    {
        "file": "FoodCart-Sheet(112x112).png",
        "id": "veh_012",
        "resource_name": "food_cart_01",
        "display_name": "Xe Đẩy Đồ Ăn Đường Phố",
        "vehicle_type": "cart",
        "category": "land",
        "frame_size": [112, 112],
        "collision_size": [36, 22],
        "speed": 45.0,
        "capacity": 1,
        "has_siren": False,
        "description": "Xe đẩy bán thức ăn nhanh và nước giải khát vỉa hè."
    },

    # 3. Xe Ưu Tiên & Khẩn Cấp (Có còi đèn Siren)
    {
        "file": "Police car-Sheet(112x112).png",
        "id": "veh_013",
        "resource_name": "police_car_01",
        "display_name": "Xe Cảnh Sát Tuần Tra",
        "vehicle_type": "emergency",
        "category": "land",
        "frame_size": [112, 112],
        "collision_size": [48, 24],
        "speed": 150.0,
        "capacity": 4,
        "has_siren": True,
        "description": "Xe cảnh sát tuần tra trang bị còi hú và đèn chớp xanh đỏ."
    },
    {
        "file": "Ambulance-Sheet(160x160).png",
        "id": "veh_014",
        "resource_name": "ambulance_01",
        "display_name": "Xe Cứu Thương Y Tế",
        "vehicle_type": "emergency",
        "category": "land",
        "frame_size": [160, 160],
        "collision_size": [64, 32],
        "speed": 140.0,
        "capacity": 6,
        "has_siren": True,
        "description": "Xe cấp cứu y tế trang bị đèn còi khẩn cấp và thiết bị y khoa."
    },
    {
        "file": "Firetruck (176x176)-Sheet.png",
        "id": "veh_015",
        "resource_name": "firetruck_01",
        "display_name": "Xe Cứu Hỏa",
        "vehicle_type": "emergency",
        "category": "land",
        "frame_size": [176, 176],
        "collision_size": [76, 36],
        "speed": 130.0,
        "capacity": 6,
        "has_siren": True,
        "description": "Xe cứu hỏa chuyên dụng trang bị vòi rồng và thang cứu nạn."
    },

    # 4. Xe Công Trình & Xe Hạng Nặng (160x160 & 176x176)
    {
        "file": "Bus-Sheet(176x176).png",
        "id": "veh_016",
        "resource_name": "bus_city_01",
        "display_name": "Xe Buýt Công Cộng",
        "vehicle_type": "bus",
        "category": "land",
        "frame_size": [176, 176],
        "collision_size": [80, 36],
        "speed": 95.0,
        "capacity": 30,
        "has_siren": False,
        "description": "Xe buýt vận chuyển hành khách công cộng tuyến nội đô."
    },
    {
        "file": "BullDozer-Sheet(160x160).png",
        "id": "veh_017",
        "resource_name": "bulldozer_01",
        "display_name": "Xe Ủi Đất Công Trình",
        "vehicle_type": "heavy",
        "category": "land",
        "frame_size": [160, 160],
        "collision_size": [60, 34],
        "speed": 60.0,
        "capacity": 1,
        "has_siren": False,
        "description": "Xe cơ giới hạng nặng phục vụ san lấp và thi công công trình."
    },
    {
        "file": "Foodtruck-Sheet.png",
        "id": "veh_018",
        "resource_name": "foodtruck_moving_01",
        "display_name": "Xe Tải Ẩm Thực Lưu Động",
        "vehicle_type": "truck",
        "category": "land",
        "frame_size": [160, 160],
        "collision_size": [62, 32],
        "speed": 90.0,
        "capacity": 2,
        "has_siren": False,
        "description": "Xe tải phục vụ đồ ăn lưu động trên các tuyến phố."
    },
    {
        "file": "Food truckshop-Sheet.png",
        "id": "veh_019",
        "resource_name": "food_truck_shop_01",
        "display_name": "Quầy Rơ-Moóc Ẩm Thực",
        "vehicle_type": "shop",
        "category": "static",
        "frame_size": [114, 96],
        "custom_region": [0, 0, 114, 96],
        "collision_size": [48, 24],
        "speed": 0.0,
        "capacity": 2,
        "has_siren": False,
        "description": "Quầy rơ-moóc ẩm thực lưu động phục vụ đồ ăn nhanh tại chỗ."
    },
    {
        "file": "Food truckshop-Sheet.png",
        "id": "veh_025",
        "resource_name": "food_truck_shop_02",
        "display_name": "Xe Tải Ẩm Thực Mở Quầy",
        "vehicle_type": "shop",
        "category": "static",
        "frame_size": [154, 96],
        "custom_region": [118, 0, 154, 96],
        "collision_size": [62, 28],
        "speed": 0.0,
        "capacity": 2,
        "has_siren": False,
        "description": "Xe tải ẩm thực mở bạt và quầy phục vụ khách ăn uống tại chỗ."
    },

    # 5. Phương Tiện Hàng Không (Trực thăng 192x128)
    {
        "file": "Helicopter sheet.png",
        "id": "veh_020",
        "resource_name": "helicopter_civilian_01",
        "display_name": "Trực Thăng Dân Dụng",
        "vehicle_type": "air",
        "category": "air",
        "frame_size": [192, 128],
        "collision_size": [50, 30],
        "speed": 200.0,
        "capacity": 6,
        "has_siren": False,
        "description": "Máy bay trực thăng dân dụng phục vụ ngắm cảnh và di chuyển nhanh."
    },
    {
        "file": "Helicopter sheet1.png",
        "id": "veh_021",
        "resource_name": "helicopter_rescue_01",
        "display_name": "Trực Thăng Cứu Hộ / Tuần Tra",
        "vehicle_type": "air",
        "category": "air",
        "frame_size": [192, 128],
        "collision_size": [50, 30],
        "speed": 210.0,
        "capacity": 6,
        "has_siren": True,
        "description": "Trực thăng chuyên dụng tuần tra bầu trời và cứu nạn khẩn cấp."
    },

    # 6. Phương Tiện Đường Thủy (Thuyền & Tàu)
    {
        "file": "Small Boat(80x80)-Sheet.png",
        "id": "veh_022",
        "resource_name": "boat_small_01",
        "display_name": "Thuyền Nhỏ Đường Sông",
        "vehicle_type": "water",
        "category": "water",
        "frame_size": [80, 80],
        "collision_size": [36, 20],
        "speed": 85.0,
        "capacity": 4,
        "has_siren": False,
        "description": "Thuyền máy cỡ nhỏ di chuyển linh hoạt trên các kênh rạch."
    },
    {
        "file": "Trade Ship-Sheet(192x192).png",
        "id": "veh_023",
        "resource_name": "ship_trade_01",
        "display_name": "Tàu Chở Hàng Thương Mại",
        "vehicle_type": "water",
        "category": "water",
        "frame_size": [192, 192],
        "collision_size": [90, 42],
        "speed": 70.0,
        "capacity": 12,
        "has_siren": False,
        "description": "Tàu vận tải thương mại đường thủy chuyên chở hàng hóa bến cảng."
    },
    {
        "file": "Ferry(352x352)-Sheet.png",
        "id": "veh_024",
        "resource_name": "ship_ferry_01",
        "display_name": "Phà Lớn Chở Khách",
        "vehicle_type": "water",
        "category": "water",
        "frame_size": [352, 352],
        "collision_size": [160, 75],
        "speed": 65.0,
        "capacity": 100,
        "has_siren": False,
        "description": "Phà lớn kết nối giao thông hai bờ sông, vận chuyển người và xe cộ."
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


def build_tres_content(veh_info: dict) -> str:
    filename = veh_info["file"]
    res_name = veh_info["resource_name"]
    img_uid = get_image_uid(filename)
    tex_res_id = f"2_{res_name[:6]}"

    h = hashlib.sha1(res_name.encode("utf-8")).hexdigest()[:13]
    res_uid = f"uid://v{h}"

    fw, fh = veh_info["frame_size"]
    vtype = veh_info["vehicle_type"]
    has_siren = veh_info.get("has_siren", False)

    # Cấu hình danh sách animation
    anim_configs = []

    if vtype == "shop":
        anim_configs = [("idle", 0)]
    elif vtype == "air":
        anim_configs = [
            ("fly_right", 0),
            ("fly_left", 1)
        ]
    else:
        anim_configs = [
            ("drive_front_right", 0),
            ("drive_front_left", 1),
            ("drive_back", 2),
            ("drive_front", 3)
        ]
        if has_siren:
            anim_configs.extend([
                ("siren_front_right", 4),
                ("siren_front_left", 5),
                ("siren_back", 6),
                ("siren_front", 7)
            ])

    atlas_textures = []
    anim_frames = {}

    if vtype == "shop":
        rx, ry, rw, rh = veh_info.get("custom_region", [0, 0, fw, fh])
        sub_id = f"AtlasTexture_{res_name[:4]}_idle_0"
        atlas_textures.append({
            "id": sub_id,
            "region": f"Rect2({rx}, {ry}, {rw}, {rh})"
        })
        anim_frames["idle"] = [sub_id]
    else:
        frame_count = 4
        for anim_name, row in anim_configs:
            frame_ids = []
            for f in range(frame_count):
                x = f * fw
                y = row * fh
                sub_id = f"AtlasTexture_{res_name[:4]}_{anim_name}_{f}"
                atlas_textures.append({
                    "id": sub_id,
                    "region": f"Rect2({x}, {y}, {fw}, {fh})"
                })
                frame_ids.append(sub_id)
            anim_frames[anim_name] = frame_ids

    sprite_frames_id = f"SpriteFrames_{res_name[:6]}"

    out = []
    out.append(f'[gd_resource type="Resource" script_class="VehicleData" format=3 uid="{res_uid}"]')
    out.append('')
    out.append(f'[ext_resource type="Script" uid="{VEHDATA_SCRIPT_UID}" path="{VEHDATA_SCRIPT_PATH}" id="1_vehdata"]')
    out.append(f'[ext_resource type="Texture2D" uid="{img_uid}" path="res://assets/spritesheets/vehicles/{filename}" id="{tex_res_id}"]')
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
        speed = 10.0 if vtype == "air" else 6.0
        out.append(f'"speed": {speed:.1f}')
        if idx < len(sorted_anims) - 1:
            out.append('}, {')
        else:
            out.append('}]')

    out.append('')
    out.append('[resource]')
    out.append('script = ExtResource("1_vehdata")')
    out.append(f'id = &"{veh_info["id"]}"')
    out.append(f'display_name = "{veh_info["display_name"]}"')
    out.append(f'vehicle_type = &"{veh_info["vehicle_type"]}"')
    out.append(f'category = &"{veh_info["category"]}"')
    out.append(f'description = "{veh_info.get("description", "")}"')
    out.append(f'frame_size = Vector2i({fw}, {fh})')
    
    # Visual offset: tính toán thích ứng theo độ cao của frame
    offset_y = -fh * 0.35
    out.append(f'visual_offset = Vector2(0, {offset_y:.1f})')
    out.append(f'sprite_frames = SubResource("{sprite_frames_id}")')
    out.append(f'spritesheet_path = "res://assets/spritesheets/vehicles/{filename}"')
    
    cw, ch = veh_info["collision_size"]
    out.append(f'collision_size = Vector2({cw}, {ch})')
    out.append(f'max_speed = {veh_info["speed"]}')
    out.append('acceleration = 80.0')
    out.append(f'has_siren = {str(has_siren).lower()}')
    out.append(f'passenger_capacity = {veh_info["capacity"]}')
    
    tags = [veh_info["vehicle_type"], veh_info["category"], "vehicle"]
    tags_str = ", ".join([f'"{t}"' for t in tags])
    out.append(f'tags = PackedStringArray({tags_str})')
    out.append(f'metadata/_custom_type_script = "{VEHDATA_SCRIPT_UID}"')
    out.append('')

    return "\n".join(out)


def main():
    os.makedirs(VEHICLES_DIR, exist_ok=True)

    print(f"Bắt đầu tạo tài nguyên cho {len(VEHICLES)} phương tiện...")

    registry_data = {"total_npcs": 0, "total_vehicles": 0, "assets": {}, "vehicles": {}}
    if os.path.exists(REGISTRY_PATH):
        try:
            with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
                registry_data = json.load(f)
        except Exception:
            pass

    vehicles_dict = {}

    for veh in VEHICLES:
        tres_path = os.path.join(VEHICLES_DIR, f"{veh['resource_name']}.tres")
        content = build_tres_content(veh)
        with open(tres_path, "w", encoding="utf-8") as f:
            f.write(content)

        vehicles_dict[veh["id"]] = {
            "id": veh["id"],
            "resource_name": veh["resource_name"],
            "display_name": veh["display_name"],
            "vehicle_type": veh["vehicle_type"],
            "category": veh["category"],
            "frame_size": veh["frame_size"],
            "collision_size": veh["collision_size"],
            "speed": veh["speed"],
            "capacity": veh["capacity"],
            "has_siren": veh.get("has_siren", False),
            "spritesheet": f"res://assets/spritesheets/vehicles/{veh['file']}",
            "resource_path": f"res://data/vehicles/{veh['resource_name']}.tres"
        }

    registry_data["vehicles"] = vehicles_dict
    registry_data["total_vehicles"] = len(vehicles_dict)

    with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
        json.dump(registry_data, f, ensure_ascii=False, indent=2)

    print(f"✅ Đã tạo thành công {len(VEHICLES)} file .tres tại: {VEHICLES_DIR}")
    print(f"✅ Đã cập nhật tệp registry tại: {REGISTRY_PATH}")


if __name__ == "__main__":
    main()
