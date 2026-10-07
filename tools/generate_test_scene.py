#!/usr/bin/env python3
"""
Generator for Godot 4 NPC Test Scene.
Places all 44 NPCs in an 11x4 grid with overhead labels, camera controls, and UI.
"""

import os
import json
import hashlib

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY_PATH = os.path.join(BASE_DIR, "data", "asset_registry.json")
SCENE_PATH = os.path.join(BASE_DIR, "scenes", "test", "npc_test_scene.tscn")

def generate():
    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        registry = json.load(f)

    # Sort assets by ID
    assets = sorted(list(registry["assets"].values()), key=lambda x: x["id"])

    # Build ExtResources
    # 1: script
    # 2: NPCBase packed scene
    # 3..46: NPCData resources
    # ExtResources
    ext_resources = [
        ('Script', 'uid://dqth4aqj40gt5', 'res://scenes/test/npc_test_scene.gd', '1_testscript'),
        ('PackedScene', 'uid://b165b61a7qluq', 'res://scenes/characters/NPCBase.tscn', '2_npcbase'),
    ]

    res_id_map = {}
    for idx, asset in enumerate(assets):
        res_id = f"{idx + 3}_{asset['resource_name'][:6]}"
        res_id_map[asset["id"]] = res_id
        ext_resources.append((
            'Resource',
            None,
            f"res://data/npcs/{asset['resource_name']}.tres",
            res_id
        ))

    out = []
    # Scene header
    out.append('[gd_scene format=3]')
    out.append('')


    for res_type, uid_val, path_val, ext_id in ext_resources:
        if uid_val:
            out.append(f'[ext_resource type="{res_type}" uid="{uid_val}" path="{path_val}" id="{ext_id}"]')
        else:
            out.append(f'[ext_resource type="{res_type}" path="{path_val}" id="{ext_id}"]')
    out.append('')

    # Root Node
    out.append('[node name="NPCTestScene" type="Node2D"]')
    out.append('script = ExtResource("1_testscript")')
    out.append('')

    # Background
    out.append('[node name="Background" type="ColorRect" parent="." unique_id=1001]')
    out.append('offset_left = -400.0')
    out.append('offset_top = -300.0')
    out.append('offset_right = 1800.0')
    out.append('offset_bottom = 1000.0')
    out.append('mouse_filter = 2')
    out.append('color = Color(0.125, 0.145, 0.176, 1)')
    out.append('')

    # NPC Container
    out.append('[node name="NPCContainer" type="Node2D" parent="." unique_id=1002]')
    out.append('y_sort_enabled = true')
    out.append('')

    # 11 columns x 4 rows
    cols = 11
    col_spacing = 115.0
    row_spacing = 125.0
    start_x = 80.0
    start_y = 110.0

    for idx, asset in enumerate(assets):
        c = idx % cols
        r = idx // cols
        x = start_x + c * col_spacing
        y = start_y + r * row_spacing
        node_name = f"NPC_{asset['id']}_{asset['resource_name']}"
        res_id = res_id_map[asset["id"]]

        out.append(f'[node name="{node_name}" parent="NPCContainer" instance=ExtResource("2_npcbase")]')
        out.append(f'position = Vector2({x:.1f}, {y:.1f})')
        out.append(f'data = ExtResource("{res_id}")')
        out.append('auto_wander = false')
        out.append('')

        # Overhead Label
        label_text = f"{asset['id']}: {asset['display_name']}"
        out.append(f'[node name="Label" type="Label" parent="NPCContainer/{node_name}"]')
        out.append('offset_left = -55.0')
        out.append('offset_top = -48.0')
        out.append('offset_right = 55.0')
        out.append('offset_bottom = -34.0')
        out.append('theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.8)')
        out.append('theme_override_constants/shadow_offset_x = 1')
        out.append('theme_override_constants/shadow_offset_y = 1')
        out.append('theme_override_font_sizes/font_size = 9')
        out.append(f'text = "{label_text}"')
        out.append('horizontal_alignment = 1')
        out.append('')

    # Camera2D
    out.append('[node name="Camera2D" type="Camera2D" parent="." unique_id=1003]')
    out.append('position = Vector2(650, 290)')
    out.append('zoom = Vector2(1.2, 1.2)')
    out.append('')

    # CanvasLayer UI
    out.append('[node name="CanvasLayer" type="CanvasLayer" parent="." unique_id=1004]')
    out.append('')

    # Top Panel
    out.append('[node name="TopPanel" type="PanelContainer" parent="CanvasLayer" unique_id=1005]')
    out.append('anchors_preset = 10')
    out.append('anchor_right = 1.0')
    out.append('offset_bottom = 50.0')
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
    out.append('text = "🏙️ 44 NPC"')
    out.append('')

    out.append('[node name="StatsLabel" type="Label" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('size_flags_horizontal = 3')
    out.append('theme_override_colors/font_color = Color(0.7, 0.75, 0.85, 1.0)')
    out.append('theme_override_font_sizes/font_size = 11')
    out.append('text = "Phím R / 1-4: Đổi hướng | Click NPC: Nói chuyện | WASD: Camera"')
    out.append('')

    out.append('[node name="RotateButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Hướng: Trước-Phải (Phím R)"')
    out.append('')

    out.append('[node name="WanderButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Tự do đi dạo: TẮT"')
    out.append('')

    out.append('[node name="ResetCamButton" type="Button" parent="CanvasLayer/TopPanel/MarginContainer/HBoxContainer"]')
    out.append('text = "Camera"')
    out.append('')


    # Dialogue Box
    out.append('[node name="DialogueBox" type="PanelContainer" parent="CanvasLayer" unique_id=1006]')
    out.append('anchors_preset = 12')
    out.append('anchor_top = 1.0')
    out.append('anchor_right = 1.0')
    out.append('anchor_bottom = 1.0')
    out.append('offset_left = 60.0')
    out.append('offset_top = -100.0')
    out.append('offset_right = -60.0')
    out.append('offset_bottom = -16.0')
    out.append('grow_horizontal = 2')
    out.append('grow_vertical = 0')
    out.append('')

    out.append('[node name="MarginContainer" type="MarginContainer" parent="CanvasLayer/DialogueBox"]')
    out.append('theme_override_constants/margin_left = 18')
    out.append('theme_override_constants/margin_top = 10')
    out.append('theme_override_constants/margin_right = 18')
    out.append('theme_override_constants/margin_bottom = 10')
    out.append('')

    out.append('[node name="VBoxContainer" type="VBoxContainer" parent="CanvasLayer/DialogueBox/MarginContainer"]')
    out.append('theme_override_constants/separation = 4')
    out.append('')

    out.append('[node name="Header" type="HBoxContainer" parent="CanvasLayer/DialogueBox/MarginContainer/VBoxContainer"]')
    out.append('theme_override_constants/separation = 10')
    out.append('')

    out.append('[node name="NameLabel" type="Label" parent="CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/Header"]')
    out.append('theme_override_colors/font_color = Color(1, 0.85, 0.3, 1)')
    out.append('theme_override_font_sizes/font_size = 14')
    out.append('text = "Tên NPC"')
    out.append('')

    out.append('[node name="RoleLabel" type="Label" parent="CanvasLayer/DialogueBox/MarginContainer/VBoxContainer/Header"]')
    out.append('theme_override_colors/font_color = Color(0.4, 0.8, 1, 1)')
    out.append('theme_override_font_sizes/font_size = 12')
    out.append('text = "[ROLE]"')
    out.append('')

    out.append('[node name="ContentLabel" type="Label" parent="CanvasLayer/DialogueBox/MarginContainer/VBoxContainer"]')
    out.append('theme_override_colors/font_color = Color(0.95, 0.95, 0.95, 1)')
    out.append('theme_override_font_sizes/font_size = 13')
    out.append('text = "Nội dung đối thoại..."')
    out.append('autowrap_mode = 2')
    out.append('')

    # Connections
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/WanderButton" to="." method="_on_wander_button_pressed"]')
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/RotateButton" to="." method="_on_rotate_direction_pressed"]')
    out.append('[connection signal="pressed" from="CanvasLayer/TopPanel/MarginContainer/HBoxContainer/ResetCamButton" to="." method="_on_reset_camera_pressed"]')
    out.append('')

    scene_content = "\n".join(out)
    with open(SCENE_PATH, "w", encoding="utf-8") as f:
        f.write(scene_content)
    print(f"Generated test scene at: {SCENE_PATH}")

if __name__ == "__main__":
    generate()
