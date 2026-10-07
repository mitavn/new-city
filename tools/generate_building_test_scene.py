#!/usr/bin/env python3
"""
Generator cho Godot 4 Building Test Scene.
Sắp xếp toàn bộ 45 tòa nhà đô thị (từ tiệm bánh nhỏ đến trạm cứu hỏa 2 cửa và bệnh viện cao tầng)
trong lưới 9 cột x 5 hàng với nhãn tên, số cửa, các nút bấm mở/đóng cửa và camera điều hướng.
"""

import os
import sys
import json

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY_PATH = os.path.join(BASE_DIR, "data", "asset_registry.json")
SCENE_PATH = os.path.join(BASE_DIR, "scenes", "test", "building_test_scene.tscn")


def generate():
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        registry = json.load(f)

    buildings = sorted(list(registry["buildings"].values()), key=lambda x: x["id"])

    ext_resources = [
        ('Script', 'res://scenes/test/building_test_scene.gd', '1_testscript'),
        ('PackedScene', 'uid://c5q3xrvq8bl4v', 'res://scenes/buildings/BuildingBase.tscn', '2_bldbase'),
    ]

    res_id_map = {}
    for idx, bld in enumerate(buildings):
        res_id = f"{idx + 3}_{bld['resource_name'][:6]}"
        res_id_map[bld["id"]] = res_id
        ext_resources.append((
            'Resource',
            f"res://data/buildings/{bld['resource_name']}.tres",
            res_id
        ))

    out = []
    out.append('[gd_scene format=3]')
    out.append('')

    for item in ext_resources:
        if len(item) == 4:
            res_type, uid_val, path_val, ext_id = item
            out.append(f'[ext_resource type="{res_type}" uid="{uid_val}" path="{path_val}" id="{ext_id}"]')
        else:
            res_type, path_val, ext_id = item
            out.append(f'[ext_resource type="{res_type}" path="{path_val}" id="{ext_id}"]')
    out.append('')

    # Root Node
    out.append('[node name="BuildingTestScene" type="Node2D"]')
    out.append('script = ExtResource("1_testscript")')
    out.append('')

    # Background
    out.append('[node name="Background" type="ColorRect" parent="." unique_id=3001]')
    out.append('offset_left = -500.0')
    out.append('offset_top = -400.0')
    out.append('offset_right = 3800.0')
    out.append('offset_bottom = 2600.0')
    out.append('mouse_filter = 2')
    out.append('color = Color(0.12, 0.14, 0.17, 1)')
    out.append('')

    # Building Container
    out.append('[node name="BuildingContainer" type="Node2D" parent="." unique_id=3002]')
    out.append('y_sort_enabled = true')
    out.append('')

    # 9 columns x 5 rows = 45 buildings
    cols = 9
    col_spacing = 380.0
    row_spacing = 420.0
    start_x = 200.0
    start_y = 260.0

    for idx, bld in enumerate(buildings):
        c = idx % cols
        r = idx // cols
        x = start_x + c * col_spacing
        y = start_y + r * row_spacing
        node_name = f"Bld_{bld['id']}_{bld['resource_name']}"
        res_id = res_id_map[bld["id"]]

        out.append(f'[node name="{node_name}" parent="BuildingContainer" instance=ExtResource("2_bldbase")]')
        out.append(f'position = Vector2({x:.1f}, {y:.1f})')
        out.append(f'data = ExtResource("{res_id}")')
        out.append('')

        # Overhead Label
        doors_tag = " [2 CỬA]" if bld.get("door_count", 1) >= 2 else ""
        color_tag = f" ({bld['color_variant']})" if bld.get("color_variant", "default") != "default" else ""
        fw, fh = bld["frame_size"]
        label_text = f"{bld['display_name']}{color_tag}\n({fw}x{fh}){doors_tag}"
        out.append(f'[node name="Label" type="Label" parent="BuildingContainer/{node_name}"]')
        out.append('offset_left = -120.0')
        out.append('offset_top = 18.0')
        out.append('offset_right = 120.0')
        out.append('offset_bottom = 54.0')
        out.append('theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.85)')
        out.append('theme_override_constants/shadow_offset_x = 1')
        out.append('theme_override_constants/shadow_offset_y = 1')
        out.append('theme_override_font_sizes/font_size = 11')
        out.append(f'text = "{label_text}"')
        out.append('horizontal_alignment = 1')
        out.append('')

    # Camera2D
    out.append('[node name="Camera2D" type="Camera2D" parent="." unique_id=3003]')
    out.append('position = Vector2(1700, 1100)')
    out.append('zoom = Vector2(0.55, 0.55)')
    out.append('')

    # CanvasLayer UI
    out.append('[node name="CanvasLayer" type="CanvasLayer" parent="." unique_id=3004]')
    out.append('')

    # Top Panel
    out.append('[node name="TopPanel" type="PanelContainer" parent="CanvasLayer" unique_id=3005]')
    out.append('anchors_preset = 10')
    out.append('anchor_right = 1.0')
    out.append('offset_bottom = 54.0')
    out.append('grow_horizontal = 2')
    out.append('')

    out.append('[node name="MarginContainer" type="MarginContainer" parent="CanvasLayer/TopPanel"]')
    out.append('theme_override_constants/margin_left = 16')
    out.append('theme_override_constants/margin_top = 8')
    out.append('theme_override_constants/margin_right = 16')
    out.append('theme_override_constants/margin_bottom = 8')
    out.append('')

    out.append('[node name="HBoxContainer" type="HBoxContainer" parent="CanvasLayer/TopPanel/MarginContainer"]')
    out.append('theme_override_constants/separation = 10')
    out.append('')

    out.append('[node name="TitleLabel" type="Label" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('theme_override_colors/font_color = Color(0.95, 0.9, 0.6, 1.0)')
    out.append('theme_override_font_sizes/font_size = 14')
    out.append('text = "🏢 45 Tòa Nhà"')
    out.append('')

    out.append('[node name="StatsLabel" type="Label" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('size_flags_horizontal = 3')
    out.append('theme_override_colors/font_color = Color(0.7, 0.75, 0.85, 1.0)')
    out.append('theme_override_font_sizes/font_size = 11')
    out.append('text = "Space/E: Mở/Đóng Tất Cả | Phím 1/2: Mở Cửa 1 / Cửa 2 | Phím 3: Đóng Hết | Click cửa: Tương tác"')
    out.append('')

    out.append('[node name="ToggleAllButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Mở/Đóng Hết (Space)"')
    out.append('')

    out.append('[node name="DoorLeftButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Mở Cửa 1 (Phím 1)"')
    out.append('')

    out.append('[node name="DoorRightButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Mở Cửa 2 (Phím 2)"')
    out.append('')

    out.append('[node name="ResetCamButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Camera (F)"')
    out.append('')

    # Info Box
    out.append('[node name="InfoBox" type="PanelContainer" parent="CanvasLayer" unique_id=3006]')
    out.append('anchors_preset = 12')
    out.append('anchor_top = 1.0')
    out.append('anchor_right = 1.0')
    out.append('anchor_bottom = 1.0')
    out.append('offset_left = 100.0')
    out.append('offset_top = -140.0')
    out.append('offset_right = -100.0')
    out.append('offset_bottom = -16.0')
    out.append('grow_horizontal = 2')
    out.append('grow_vertical = 0')
    out.append('')

    out.append('[node name="MarginContainer" type="MarginContainer" parent="CanvasLayer/InfoBox"]')
    out.append('theme_override_constants/margin_left = 18')
    out.append('theme_override_constants/margin_top = 10')
    out.append('theme_override_constants/margin_right = 18')
    out.append('theme_override_constants/margin_bottom = 10')
    out.append('')

    out.append('[node name="VBoxContainer" type="VBoxContainer" parent="CanvasLayer/InfoBox/MarginContainer"]')
    out.append('theme_override_constants/separation = 4')
    out.append('')

    out.append('[node name="Header" type="HBoxContainer" parent="CanvasLayer/InfoBox/MarginContainer/VBoxContainer"]')
    out.append('theme_override_constants/separation = 10')
    out.append('')

    out.append('[node name="NameLabel" type="Label" parent="CanvasLayer/InfoBox/MarginContainer/VBoxContainer/Header"]')
    out.append('theme_override_colors/font_color = Color(1, 0.85, 0.3, 1)')
    out.append('theme_override_font_sizes/font_size = 14')
    out.append('text = "Tên Tòa Nhà"')
    out.append('')

    out.append('[node name="TypeLabel" type="Label" parent="CanvasLayer/InfoBox/MarginContainer/VBoxContainer/Header"]')
    out.append('theme_override_colors/font_color = Color(0.4, 0.8, 1, 1)')
    out.append('theme_override_font_sizes/font_size = 12')
    out.append('text = "[COMMERCIAL]"')
    out.append('')

    out.append('[node name="ContentLabel" type="Label" parent="CanvasLayer/InfoBox/MarginContainer/VBoxContainer"]')
    out.append('theme_override_colors/font_color = Color(0.95, 0.95, 0.95, 1)')
    out.append('theme_override_font_sizes/font_size = 12')
    out.append('text = "Thông số tòa nhà..."')
    out.append('autowrap_mode = 2')
    out.append('')

    # Connections
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/ToggleAllButton" to="." method="_on_toggle_all_doors_pressed"]')
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/DoorLeftButton" to="." method="_on_door_left_pressed"]')
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/DoorRightButton" to="." method="_on_door_right_pressed"]')
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/ResetCamButton" to="." method="_on_reset_camera_pressed"]')
    out.append('')

    scene_content = "\n".join(out)
    with open(SCENE_PATH, "w", encoding="utf-8") as f:
        f.write(scene_content)
    print(f"✅ Đã tạo Building Test Scene thành công tại: {SCENE_PATH}")


if __name__ == "__main__":
    generate()
