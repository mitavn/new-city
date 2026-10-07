#!/usr/bin/env python3
"""
Công cụ Thêm Tòa Nhà mới tự động (Add Building Tool).
Hỗ trợ:
- 1 cửa đơn
- 2 cửa đóng mở độc lập (Cửa Trái / Cửa Phải / Cửa Gara)
- Biến thể nhiều màu trong cùng 1 file ảnh.

Cách sử dụng:
    python tools/add_building.py <ten_file_anh> <ten_hien_thi> [loai_toa_nha] [so_cua] [mau_sac] [frame_w] [frame_h]

Ví dụ:
    python tools/add_building.py "Bakery Animation.png" "Tiệm Bánh Mì Mới" commercial 1 default
    python tools/add_building.py --sync  (Tự quét thư mục và thêm mọi tòa nhà mới)
"""

import os
import sys
import re
import json
import struct
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


def get_png_size(file_path: str):
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
        r0 = door_rows[0]
        r1 = door_rows[1]

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

        anim_frames["door_closed"] = ([f_left_closed], 1.0, 0)
        anim_frames["door_opened"] = ([f_left_opened], 1.0, 0)
    else:
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


def add_building(filename: str, display_name: str, building_type: str = "commercial",
                 door_count: int = 1, color_variant: str = "default",
                 frame_w: int = None, frame_h: int = None):
    os.makedirs(BUILDINGS_DIR, exist_ok=True)
    img_basename = os.path.basename(filename)
    if not img_basename.endswith(".png"):
        img_basename += ".png"

    src_img = os.path.join(ASSETS_DIR, img_basename)
    img_w, img_h = get_png_size(src_img) if os.path.exists(src_img) else (None, None)

    if frame_w is None and img_w:
        frame_w = img_w // 6
    if frame_h is None and img_h:
        frame_h = img_h

    if frame_w is None or frame_h is None:
        frame_w, frame_h = 112, 160

    # Đọc registry hiện tại
    registry = {"total_npcs": 0, "total_vehicles": 0, "total_buildings": 0, "assets": {}, "vehicles": {}, "buildings": {}}
    if os.path.exists(REGISTRY_PATH):
        try:
            with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
                registry = json.load(f)
        except Exception:
            pass

    existing_count = len(registry.get("buildings", {}))
    new_id = f"bld_{existing_count + 1:03d}"
    clean_name = re.sub(r'[^a-zA-Z0-9_]+', '_', os.path.splitext(img_basename)[0]).lower()
    res_name = f"bld_{clean_name}" if not clean_name.startswith("bld_") else clean_name

    door_names = ["Cửa Trái", "Cửa Phải"] if door_count >= 2 else ["Cửa Chính"]
    door_positions = [[-int(frame_w * 0.25), -8], [int(frame_w * 0.25), -8]] if door_count >= 2 else [[0, -8]]

    bld_info = {
        "file": img_basename,
        "id": new_id,
        "resource_name": res_name,
        "display_name": display_name,
        "building_type": building_type,
        "door_count": door_count,
        "door_names": door_names,
        "color_variant": color_variant,
        "frame_size": [frame_w, frame_h],
        "collision_size": [max(24, int(frame_w * 0.85)), max(20, int(frame_h * 0.35))],
        "door_positions": door_positions,
        "description": f"Tòa nhà {display_name} ({building_type})."
    }

    tres_path = os.path.join(BUILDINGS_DIR, f"{res_name}.tres")
    content = build_tres_content(bld_info)
    with open(tres_path, "w", encoding="utf-8") as f:
        f.write(content)

    if "buildings" not in registry:
        registry["buildings"] = {}

    registry["buildings"][new_id] = {
        "id": new_id,
        "resource_name": res_name,
        "display_name": display_name,
        "building_type": building_type,
        "door_count": door_count,
        "door_names": door_names,
        "color_variant": color_variant,
        "frame_size": [frame_w, frame_h],
        "collision_size": bld_info["collision_size"],
        "spritesheet": f"res://assets/spritesheets/buildings/Building Door Animations/{img_basename}",
        "resource_path": f"res://data/buildings/{res_name}.tres"
    }
    registry["total_buildings"] = len(registry["buildings"])

    with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
        json.dump(registry, f, ensure_ascii=False, indent=2)

    print("=" * 65)
    print(f"✅ ĐÃ TẠO THÀNH CÔNG TÒA NHÀ MỚI!")
    print(f" - ID: {new_id} | Tên hiển thị: {display_name}")
    print(f" - Kích thước Frame: {frame_w}x{frame_h} px | Số cửa: {door_count}")
    print(f" - Loại: {building_type} | Màu sắc: {color_variant}")
    print(f" - File tài nguyên: data/buildings/{res_name}.tres")
    print(f" - Tổng số tòa nhà hiện có: {registry['total_buildings']}")
    print("=" * 65)
    return bld_info


def scan_and_sync():
    """Tự động gọi generator để đồng bộ hóa toàn bộ ảnh tòa nhà."""
    print("Đang đồng bộ hóa toàn bộ tòa nhà...")
    from generate_building_data import main as gen_main
    gen_main()


if __name__ == "__main__":
    if len(sys.argv) == 1 or sys.argv[1] in ("--help", "-h"):
        print(__doc__)
    elif sys.argv[1] in ("--sync", "-s"):
        scan_and_sync()
    else:
        f = sys.argv[1]
        name = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(os.path.basename(f))[0]
        btype = sys.argv[3] if len(sys.argv) > 3 else "commercial"
        doors = int(sys.argv[4]) if len(sys.argv) > 4 else 1
        col = sys.argv[5] if len(sys.argv) > 5 else "default"
        fw = int(sys.argv[6]) if len(sys.argv) > 6 else None
        fh = int(sys.argv[7]) if len(sys.argv) > 7 else None
        add_building(f, name, btype, doors, col, fw, fh)
