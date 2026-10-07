#!/usr/bin/env python3
"""
Công cụ Thêm Phương Tiện mới tự động (Add Vehicle Tool).
Hỗ trợ kích thước frame và animation khác nhau cho từng loại xe.

Cách sử dụng:
    python tools/add_vehicle.py <ten_file_anh> <ten_hien_thi> [loai_xe] [danh_muc] [frame_w] [frame_h] [toc_do] [co_siren]

Ví dụ:
    python tools/add_vehicle.py "SportsCar-(96x96)Sheet.png" "Xe Thể Thao Đua" car land 96 96 160 false
    python tools/add_vehicle.py --sync  (Tự quét thư mục và thêm mọi ảnh xe mới chưa có .tres)
"""

import os
import sys
import re
import json
import struct
import hashlib
import argparse

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


def get_png_size(file_path: str):
    """Đọc kích thước ảnh PNG trực tiếp từ header IHDR (chuẩn 100% không cần thư viện ngoài)."""
    try:
        with open(file_path, "rb") as f:
            header = f.read(24)
            if len(header) >= 24 and header[:8] == b"\x89PNG\r\n\x1a\n":
                w, h = struct.unpack(">II", header[16:24])
                return w, h
    except Exception:
        pass
    return None, None


def get_image_uid(filename: str) -> str:
    """Lấy UID từ tệp .import hoặc sinh UID tương thích."""
    import_path = os.path.join(ASSETS_DIR, filename + ".import")
    if os.path.exists(import_path):
        try:
            with open(import_path, "r", encoding="utf-8") as f:
                m = re.search(r'uid="([^"]+)"', f.read())
                if m:
                    return m.group(1)
        except Exception:
            pass
    h = hashlib.sha1(filename.encode("utf-8")).hexdigest()[:13]
    return f"uid://c{h}"


def infer_vehicle_specs(filename: str, img_w: int = None, img_h: int = None) -> dict:
    """Tự động suy đoán kích thước frame, loại xe, và siren từ tên file và kích thước ảnh."""
    lower = filename.lower()

    # 1. Đoán frame từ tên file trước
    size_match = re.search(r'\((\d+)\s*x\s*(\d+)\)', filename)
    fw, fh = None, None
    if size_match:
        fw = int(size_match.group(1))
        fh = int(size_match.group(2))

    # 2. Suy đoán loại xe và danh mục
    has_siren = False
    vtype = "car"
    category = "land"
    speed = 120.0
    capacity = 4

    if "police" in lower:
        vtype = "emergency"
        category = "land"
        has_siren = True
        speed = 150.0
    elif "ambulance" in lower:
        vtype = "emergency"
        category = "land"
        has_siren = True
        speed = 140.0
        capacity = 6
    elif "fire" in lower:
        vtype = "emergency"
        category = "land"
        has_siren = True
        speed = 130.0
        capacity = 6
    elif "taxi" in lower:
        vtype = "taxi"
        category = "land"
        speed = 130.0
    elif "cart" in lower:
        vtype = "cart"
        category = "land"
        speed = 45.0
        capacity = 1
    elif "bus" in lower:
        vtype = "bus"
        category = "land"
        speed = 95.0
        capacity = 30
    elif "dozer" in lower or "heavy" in lower:
        vtype = "heavy"
        category = "land"
        speed = 60.0
        capacity = 1
    elif "helicopter" in lower or "heli" in lower:
        vtype = "air"
        category = "air"
        speed = 200.0
        capacity = 6
        if "rescue" in lower or "1" in lower:
            has_siren = True
    elif "boat" in lower:
        vtype = "water"
        category = "water"
        speed = 85.0
    elif "ship" in lower:
        vtype = "water"
        category = "water"
        speed = 70.0
        capacity = 12
    elif "ferry" in lower:
        vtype = "water"
        category = "water"
        speed = 65.0
        capacity = 100
    elif "shop" in lower:
        vtype = "shop"
        category = "static"
        speed = 0.0
        capacity = 2
    elif "foodtruck" in lower or "truck" in lower:
        vtype = "truck"
        category = "land"
        speed = 90.0
        capacity = 2

    # 3. Nếu chưa có fw, fh, tính từ kích thước ảnh thực tế
    if (fw is None or fh is None) and img_w and img_h:
        if vtype == "shop":
            fw = img_w // 2
            fh = img_h
        elif vtype == "air":
            fw = img_w // 4
            fh = img_h // 2
        elif has_siren and img_h >= 8 * (img_w // 4):
            fw = img_w // 4
            fh = img_h // 8
        else:
            fw = img_w // 4
            fh = img_h // 4

    if fw is None or fh is None:
        fw, fh = 96, 96

    cw = max(24, int(fw * 0.45))
    ch = max(16, int(fh * 0.22))

    return {
        "frame_size": [fw, fh],
        "collision_size": [cw, ch],
        "vehicle_type": vtype,
        "category": category,
        "speed": speed,
        "capacity": capacity,
        "has_siren": has_siren
    }


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


def add_vehicle(image_filename: str, display_name: str, vehicle_type: str = None, category: str = None,
                frame_w: int = None, frame_h: int = None, speed: float = None, has_siren: bool = None):
    os.makedirs(VEHICLES_DIR, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)

    img_basename = os.path.basename(image_filename)
    if not img_basename.endswith(".png"):
        img_basename += ".png"

    src_img = os.path.join(ASSETS_DIR, img_basename)
    img_w, img_h = get_png_size(src_img) if os.path.exists(src_img) else (None, None)

    specs = infer_vehicle_specs(img_basename, img_w, img_h)

    # Ghi đè tham số nếu người dùng cung cấp
    if vehicle_type:
        specs["vehicle_type"] = vehicle_type
    if category:
        specs["category"] = category
    if frame_w and frame_h:
        specs["frame_size"] = [frame_w, frame_h]
        specs["collision_size"] = [max(24, int(frame_w * 0.45)), max(16, int(frame_h * 0.22))]
    if speed is not None:
        specs["speed"] = speed
    if has_siren is not None:
        specs["has_siren"] = has_siren

    # Đọc registry hiện tại
    registry = {"total_npcs": 0, "total_vehicles": 0, "assets": {}, "vehicles": {}}
    if os.path.exists(REGISTRY_PATH):
        try:
            with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
                registry = json.load(f)
        except Exception:
            pass

    existing_count = len(registry.get("vehicles", {}))
    new_id = f"veh_{existing_count + 1:03d}"
    clean_name = re.sub(r'[^a-zA-Z0-9_]+', '_', os.path.splitext(img_basename)[0]).lower()
    res_name = f"veh_{clean_name}" if not clean_name.startswith("veh_") else clean_name

    veh_info = {
        "file": img_basename,
        "id": new_id,
        "resource_name": res_name,
        "display_name": display_name,
        "vehicle_type": specs["vehicle_type"],
        "category": specs["category"],
        "frame_size": specs["frame_size"],
        "collision_size": specs["collision_size"],
        "speed": specs["speed"],
        "capacity": specs["capacity"],
        "has_siren": specs["has_siren"],
        "description": f"Phương tiện {display_name} ({specs['vehicle_type']}, {specs['category']})"
    }

    # Xuất file .tres
    tres_path = os.path.join(VEHICLES_DIR, f"{res_name}.tres")
    content = build_tres_content(veh_info)
    with open(tres_path, "w", encoding="utf-8") as f:
        f.write(content)

    # Cập nhật registry
    if "vehicles" not in registry:
        registry["vehicles"] = {}

    registry["vehicles"][new_id] = {
        "id": new_id,
        "resource_name": res_name,
        "display_name": display_name,
        "vehicle_type": specs["vehicle_type"],
        "category": specs["category"],
        "frame_size": specs["frame_size"],
        "collision_size": specs["collision_size"],
        "speed": specs["speed"],
        "capacity": specs["capacity"],
        "has_siren": specs["has_siren"],
        "spritesheet": f"res://assets/spritesheets/vehicles/{img_basename}",
        "resource_path": f"res://data/vehicles/{res_name}.tres"
    }
    registry["total_vehicles"] = len(registry["vehicles"])

    with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
        json.dump(registry, f, ensure_ascii=False, indent=2)

    print("=" * 65)
    print(f"✅ ĐÃ TẠO THÀNH CÔNG PHƯƠNG TIỆN MỚI!")
    print(f" - ID: {new_id}")
    print(f" - Tên hiển thị: {display_name}")
    print(f" - Kích thước Frame: {specs['frame_size'][0]}x{specs['frame_size'][1]} px")
    print(f" - Loại: {specs['vehicle_type']} | Danh mục: {specs['category']}")
    print(f" - Tốc độ: {specs['speed']} px/s | Còi Siren: {'CÓ' if specs['has_siren'] else 'KHÔNG'}")
    print(f" - File tài nguyên: data/vehicles/{res_name}.tres")
    print(f" - Tổng số phương tiện hiện có: {registry['total_vehicles']}")
    print("=" * 65)
    return veh_info


def scan_and_sync():
    """Tự động quét thư mục ảnh vehicles và tạo file .tres cho mọi file chưa đăng ký."""
    print("Đang quét thư mục: assets/spritesheets/vehicles/...")
    if not os.path.exists(ASSETS_DIR):
        print("Thư mục ảnh xe không tồn tại.")
        return

    existing_images = set()
    if os.path.exists(VEHICLES_DIR):
        for f in os.listdir(VEHICLES_DIR):
            if f.endswith(".tres"):
                with open(os.path.join(VEHICLES_DIR, f), "r", encoding="utf-8") as tf:
                    m = re.search(r'path="res://assets/spritesheets/vehicles/([^"]+)"', tf.read())
                    if m:
                        existing_images.add(m.group(1))

    png_files = sorted([f for f in os.listdir(ASSETS_DIR) if f.endswith(".png")])
    new_count = 0

    for png in png_files:
        if png not in existing_images:
            raw_title = os.path.splitext(png)[0]
            raw_title = re.sub(r'[\(\)\-\_]', ' ', raw_title)
            raw_title = re.sub(r'sheet|\d+x\d+', '', raw_title, flags=re.I).strip().title()
            display_name = f"Xe {raw_title}" if raw_title else "Xe Mới"
            print(f"Phát hiện ảnh xe mới: {png} -> Đang thêm '{display_name}'...")
            add_vehicle(png, display_name)
            existing_images.add(png)
            new_count += 1

    if new_count == 0:
        print("✨ Tất cả 24 phương tiện đã có tài nguyên .tres đầy đủ. Không có ảnh nào bị thiếu.")
    else:
        print(f"🎉 Đã thêm thành công {new_count} xe mới vào hệ thống!")


if __name__ == "__main__":
    if len(sys.argv) == 1 or sys.argv[1] in ("--help", "-h"):
        print(__doc__)
    elif sys.argv[1] in ("--sync", "-s"):
        scan_and_sync()
    else:
        img = sys.argv[1]
        name = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(os.path.basename(img))[0]
        vtype = sys.argv[3] if len(sys.argv) > 3 else None
        cat = sys.argv[4] if len(sys.argv) > 4 else None
        fw = int(sys.argv[5]) if len(sys.argv) > 5 else None
        fh = int(sys.argv[6]) if len(sys.argv) > 6 else None
        spd = float(sys.argv[7]) if len(sys.argv) > 7 else None
        siren = (sys.argv[8].lower() in ("true", "1", "yes")) if len(sys.argv) > 8 else None
        add_vehicle(img, name, vtype, cat, fw, fh, spd, siren)
