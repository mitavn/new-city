#!/usr/bin/env python3
"""
Công cụ Thêm NPC mới tự động (Add NPC Tool).
Chỉ cần cung cấp tên tệp ảnh và tên hiển thị:
    python tools/add_npc.py <ten_file_anh> <ten_hien_thi> [vai_tro] [gioi_tinh] [toc_do]

Ví dụ:
    python tools/add_npc.py Security-Guard.png "Bảo Vệ Ca Đêm" police male 60
    python tools/add_npc.py --sync  (Tự quét thư mục và thêm mọi ảnh mới chưa có .tres)
"""

import os
import sys
import re
import json
import hashlib
import argparse

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets", "spritesheets", "characters")
NPCS_DIR = os.path.join(BASE_DIR, "data", "npcs")
REGISTRY_PATH = os.path.join(BASE_DIR, "data", "asset_registry.json")
NPCDATA_SCRIPT_PATH = "res://scripts/npcs/NPCData.gd"
NPCDATA_SCRIPT_UID = "uid://1jm7l62oqmyb"


def get_image_uid(filename: str) -> str:
    import_path = os.path.join(ASSETS_DIR, filename + ".import")
    if os.path.exists(import_path):
        with open(import_path, "r", encoding="utf-8") as f:
            m = re.search(r'uid="([^"]+)"', f.read())
            if m:
                return m.group(1)
    # Tự sinh UID dự phòng
    h = hashlib.sha1(filename.encode("utf-8")).hexdigest()[:13]
    return f"uid://c{h}"


def build_tres_content(char_info: dict) -> str:
    filename = char_info["file"]
    res_name = char_info["resource_name"]
    img_uid = get_image_uid(filename)
    tex_res_id = f"2_{res_name[:5]}"

    h = hashlib.sha1(res_name.encode("utf-8")).hexdigest()[:13]
    res_uid = f"uid://r{h}"

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

    out = []
    out.append(f'[gd_resource type="Resource" script_class="NPCData" format=3 uid="{res_uid}"]')
    out.append('')
    out.append(f'[ext_resource type="Script" uid="{NPCDATA_SCRIPT_UID}" path="{NPCDATA_SCRIPT_PATH}" id="1_npcdata"]')
    out.append(f'[ext_resource type="Texture2D" uid="{img_uid}" path="res://assets/spritesheets/characters/{filename}" id="{tex_res_id}"]')
    out.append('')

    # Sub-resources: AtlasTexture (32 frames)
    for at in atlas_textures:
        out.append(f'[sub_resource type="AtlasTexture" id="{at["id"]}"]')
        out.append(f'atlas = ExtResource("{tex_res_id}")')
        out.append(f'region = {at["region"]}')
        out.append('')

    # Sub-resource: SpriteFrames (8 animations)
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
    out.append('[resource]')
    out.append('script = ExtResource("1_npcdata")')
    out.append(f'id = &"{char_info["id"]}"')
    out.append(f'display_name = "{char_info["display_name"]}"')
    out.append(f'role = &"{char_info["role"]}"')
    out.append(f'gender = &"{char_info["gender"]}"')
    out.append(f'description = "{char_info.get("description", "")}"')
    out.append(f'sprite_frames = SubResource("{sprite_frames_id}")')
    out.append(f'spritesheet_path = "res://assets/spritesheets/characters/{filename}"')
    out.append(f'move_speed = {char_info.get("speed", 60.0)}')
    out.append('wander_radius = 120.0')
    out.append('min_idle_time = 1.5')
    out.append('max_idle_time = 4.0')
    out.append('interaction_type = &"talk"')

    dialogues = char_info.get("dialogues", [
        f"Xin chào! Tôi là {char_info['display_name']}.",
        "Chúc bạn một ngày tràn đầy niềm vui!"
    ])
    dialogues_escaped = [d.replace('"', '\\"') for d in dialogues]
    dialogues_str = ", ".join([f'"{d}"' for d in dialogues_escaped])
    out.append(f'dialogues = [{dialogues_str}]')

    tags = char_info.get("tags", [char_info["role"], char_info["gender"]])
    tags_str = ", ".join([f'"{t}"' for t in tags])
    out.append(f'tags = PackedStringArray({tags_str})')
    out.append(f'metadata/_custom_type_script = "{NPCDATA_SCRIPT_UID}"')
    out.append('')

    return "\n".join(out)


def add_npc(image_filename: str, display_name: str, role: str = "civilian", gender: str = "unknown", speed: float = 60.0):
    os.makedirs(NPCS_DIR, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)

    # Đảm bảo tên file chỉ là base name
    img_basename = os.path.basename(image_filename)
    if not img_basename.endswith(".png"):
        img_basename += ".png"

    src_img = os.path.join(ASSETS_DIR, img_basename)
    if not os.path.exists(src_img):
        print(f"⚠️ Cảnh báo: File ảnh '{src_img}' chưa tồn tại trong thư mục characters.")
        print("Vui lòng copy file ảnh vào: res://assets/spritesheets/characters/")

    # Đọc registry hiện tại
    registry = {"total_npcs": 0, "assets": {}}
    if os.path.exists(REGISTRY_PATH):
        try:
            with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
                registry = json.load(f)
        except Exception:
            pass

    # Tạo ID và tên tài nguyên tự động
    existing_count = len(registry.get("assets", {}))
    new_num = existing_count + 1
    new_id = f"{new_num:03d}"

    # Tạo resource_name từ tên file hoặc display_name
    clean_name = re.sub(r'[^a-zA-Z0-9_]+', '_', os.path.splitext(img_basename)[0]).lower()
    res_name = clean_name

    char_info = {
        "file": img_basename,
        "id": new_id,
        "resource_name": res_name,
        "display_name": display_name,
        "role": role,
        "gender": gender,
        "description": f"NPC {display_name} ({role})",
        "speed": speed,
        "dialogues": [
            f"Xin chào! Tôi là {display_name}.",
            "Hôm nay bạn thế nào?"
        ],
        "tags": [role, gender, "city"]
    }

    # Xuất file .tres
    tres_path = os.path.join(NPCS_DIR, f"{res_name}.tres")
    content = build_tres_content(char_info)
    with open(tres_path, "w", encoding="utf-8") as f:
        f.write(content)

    # Cập nhật registry
    registry["assets"][new_id] = {
        "id": new_id,
        "resource_name": res_name,
        "display_name": display_name,
        "role": role,
        "gender": gender,
        "description": char_info["description"],
        "spritesheet": f"res://assets/spritesheets/characters/{img_basename}",
        "resource_path": f"res://data/npcs/{res_name}.tres",
        "speed": speed,
        "tags": char_info["tags"]
    }
    registry["total_npcs"] = len(registry["assets"])

    with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
        json.dump(registry, f, ensure_ascii=False, indent=2)

    print("=" * 60)
    print(f"✅ ĐÃ TẠO THÀNH CÔNG NPC MỚI!")
    print(f" - ID: {new_id}")
    print(f" - Tên hiển thị: {display_name}")
    print(f" - File ảnh: assets/spritesheets/characters/{img_basename}")
    print(f" - File tài nguyên: data/npcs/{res_name}.tres")
    print(f" - Vai trò: {role} | Giới tính: {gender} | Tốc độ: {speed}")
    print(f" - Tổng số NPC trong game: {registry['total_npcs']}")
    print("=" * 60)
    return char_info


def scan_and_sync():
    """Tự động quét thư mục ảnh characters và tạo file .tres cho bất kỳ ảnh mới nào."""
    print("Đang quét thư mục: assets/spritesheets/characters/...")
    if not os.path.exists(ASSETS_DIR):
        print("Thư mục ảnh không tồn tại.")
        return

    existing_tres_files = set()
    if os.path.exists(NPCS_DIR):
        for f in os.listdir(NPCS_DIR):
            if f.endswith(".tres"):
                # Đọc xem nó dùng ảnh nào
                with open(os.path.join(NPCS_DIR, f), "r", encoding="utf-8") as tf:
                    m = re.search(r'path="res://assets/spritesheets/characters/([^"]+)"', tf.read())
                    if m:
                        existing_tres_files.add(m.group(1))

    png_files = sorted([f for f in os.listdir(ASSETS_DIR) if f.endswith(".png")])
    new_count = 0

    for png in png_files:
        if png not in existing_tres_files:
            # Tên mới
            display_name = os.path.splitext(png)[0].replace("-", " ").replace("_", " ").title()
            print(f"Phát hiện ảnh mới: {png} -> Đang thêm NPC '{display_name}'...")
            add_npc(png, display_name)
            existing_tres_files.add(png)
            new_count += 1

    if new_count == 0:
        print("✨ Tất cả các ảnh đã được tạo tài nguyên NPC đầy đủ. Không có ảnh mới nào.")
    else:
        print(f"🎉 Đã thêm thành công {new_count} NPC mới vào hệ thống!")


if __name__ == "__main__":
    if len(sys.argv) == 1 or sys.argv[1] in ("--help", "-h"):
        print(__doc__)
    elif sys.argv[1] in ("--sync", "-s"):
        scan_and_sync()
    else:
        img = sys.argv[1]
        name = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(os.path.basename(img))[0]
        role = sys.argv[3] if len(sys.argv) > 3 else "civilian"
        gender = sys.argv[4] if len(sys.argv) > 4 else "unknown"
        speed = float(sys.argv[5]) if len(sys.argv) > 5 else 60.0
        add_npc(img, name, role, gender, speed)
