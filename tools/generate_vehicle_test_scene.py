#!/usr/bin/env python3
"""
Generator cho Godot 4 Vehicle Test Scene.
Sắp xếp toàn bộ 24 phương tiện (từ ô tô 96x96 đến phà lớn 352x352)
trong lưới 6 cột x 4 hàng với nhãn thông số, còi Siren và camera điều hướng.
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
SCENE_PATH = os.path.join(BASE_DIR, "scenes", "test", "vehicle_test_scene.tscn")

def generate():
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        registry = json.load(f)

    vehicles = sorted(list(registry["vehicles"].values()), key=lambda x: x["id"])

    ext_resources = [
        ('Script', 'res://scenes/test/vehicle_test_scene.gd', '1_testscript'),
        ('PackedScene', 'uid://lubgeoikqoxy', 'res://scenes/vehicles/VehicleBase.tscn', '2_vehbase'),
    ]

    res_id_map = {}
    for idx, veh in enumerate(vehicles):
        res_id = f"{idx + 3}_{veh['resource_name'][:6]}"
        res_id_map[veh["id"]] = res_id
        ext_resources.append((
            'Resource',
            f"res://data/vehicles/{veh['resource_name']}.tres",
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
    out.append('[node name="VehicleTestScene" type="Node2D"]')
    out.append('script = ExtResource("1_testscript")')
    out.append('')

    # Background
    out.append('[node name="Background" type="ColorRect" parent="." unique_id=2001]')
    out.append('offset_left = -400.0')
    out.append('offset_top = -300.0')
    out.append('offset_right = 2200.0')
    out.append('offset_bottom = 1600.0')
    out.append('mouse_filter = 2')
    out.append('color = Color(0.11, 0.13, 0.16, 1)')
    out.append('')

    # Vehicle Container
    out.append('[node name="VehicleContainer" type="Node2D" parent="." unique_id=2002]')
    out.append('y_sort_enabled = true')
    out.append('')

    # 5 columns x 5 rows
    col_x = [120.0, 420.0, 720.0, 1020.0, 1400.0]
    row_y = [140.0, 360.0, 580.0, 800.0, 1080.0]

    for idx, veh in enumerate(vehicles):
        c = idx % 5
        r = idx // 5
        x = col_x[c]
        y = row_y[r]
        node_name = f"Veh_{veh['id']}_{veh['resource_name']}"
        res_id = res_id_map[veh["id"]]

        out.append(f'[node name="{node_name}" parent="VehicleContainer" instance=ExtResource("2_vehbase")]')
        out.append(f'position = Vector2({x:.1f}, {y:.1f})')
        out.append(f'data = ExtResource("{res_id}")')
        out.append('')

        # Overhead Label
        siren_tag = " [SIREN]" if veh.get("has_siren") else ""
        fw, fh = veh["frame_size"]
        label_text = f"{veh['display_name']}\n({fw}x{fh}){siren_tag}"
        out.append(f'[node name="Label" type="Label" parent="VehicleContainer/{node_name}"]')
        out.append('offset_left = -80.0')
        out.append('offset_top = 22.0')
        out.append('offset_right = 80.0')
        out.append('offset_bottom = 54.0')
        out.append('theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.85)')
        out.append('theme_override_constants/shadow_offset_x = 1')
        out.append('theme_override_constants/shadow_offset_y = 1')
        out.append('theme_override_font_sizes/font_size = 10')
        out.append(f'text = "{label_text}"')
        out.append('horizontal_alignment = 1')
        out.append('')

    # Camera2D
    out.append('[node name="Camera2D" type="Camera2D" parent="." unique_id=2003]')
    out.append('position = Vector2(750, 580)')
    out.append('zoom = Vector2(0.85, 0.85)')
    out.append('')

    # CanvasLayer UI
    out.append('[node name="CanvasLayer" type="CanvasLayer" parent="." unique_id=2004]')
    out.append('')

    # Top Panel
    out.append('[node name="TopPanel" type="PanelContainer" parent="CanvasLayer" unique_id=2005]')
    out.append('anchors_preset = 10')
    out.append('anchor_right = 1.0')
    out.append('offset_bottom = 52.0')
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
    out.append('theme_override_colors/font_color = Color(0.9, 0.95, 1.0, 1.0)')
    out.append('theme_override_font_sizes/font_size = 14')
    out.append('text = "🚗 25 Phương Tiện"')
    out.append('')

    out.append('[node name="StatsLabel" type="Label" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('size_flags_horizontal = 3')
    out.append('theme_override_colors/font_color = Color(0.7, 0.75, 0.85, 1.0)')
    out.append('theme_override_font_sizes/font_size = 11')
    out.append('text = "Phím R / 1-4: Đổi hướng | Phím Space/E: Còi Siren | Click xe: Thông số | WASD: Camera"')
    out.append('')

    out.append('[node name="RotateButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Hướng: Trước-Phải (Phím R)"')
    out.append('')

    out.append('[node name="SirenButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Còi Siren: TẮT (Space/E)"')
    out.append('')

    out.append('[node name="ResetCamButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Camera (F)"')
    out.append('')

    # Info Box
    out.append('[node name="InfoBox" type="PanelContainer" parent="CanvasLayer" unique_id=2006]')
    out.append('anchors_preset = 12')
    out.append('anchor_top = 1.0')
    out.append('anchor_right = 1.0')
    out.append('anchor_bottom = 1.0')
    out.append('offset_left = 80.0')
    out.append('offset_top = -120.0')
    out.append('offset_right = -80.0')
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
    out.append('text = "Tên Phương Tiện"')
    out.append('')

    out.append('[node name="TypeLabel" type="Label" parent="CanvasLayer/InfoBox/MarginContainer/VBoxContainer/Header"]')
    out.append('theme_override_colors/font_color = Color(0.4, 0.8, 1, 1)')
    out.append('theme_override_font_sizes/font_size = 12')
    out.append('text = "[CAR - LAND]"')
    out.append('')

    out.append('[node name="ContentLabel" type="Label" parent="CanvasLayer/InfoBox/MarginContainer/VBoxContainer"]')
    out.append('theme_override_colors/font_color = Color(0.95, 0.95, 0.95, 1)')
    out.append('theme_override_font_sizes/font_size = 12')
    out.append('text = "Thông số phương tiện..."')
    out.append('autowrap_mode = 2')
    out.append('')

    # Connections
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/RotateButton" to="." method="_on_rotate_direction_pressed"]')
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/SirenButton" to="." method="_on_siren_button_pressed"]')
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/ResetCamButton" to="." method="_on_reset_camera_pressed"]')
    out.append('')

    scene_content = "\n".join(out)
    with open(SCENE_PATH, "w", encoding="utf-8") as f:
        f.write(scene_content)
    print(f"✅ Đã tạo Vehicle Test Scene thành công tại: {SCENE_PATH}")

if __name__ == "__main__":
    generate()
