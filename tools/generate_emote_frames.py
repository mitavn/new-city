import os

header = """[gd_resource type="SpriteFrames" format=3 uid="uid://dm6yem0t3s1c8"]

[ext_resource type="Texture2D" uid="uid://df7w0c2yqepk6" path="res://assets/spritesheets/characters/Character Emoteicon-Sheet.png" id="1_emote_tex"]
"""

anim_names = [
    "heart",        # 0
    "happy",        # 1
    "question",     # 2
    "speech_dots",  # 3
    "exclamation",  # 4
    "sweat",        # 5
    "angry",        # 6
    "sleep",        # 7
    "music",        # 8
    "shock",        # 9
    "coin",         # 10
    "idea",         # 11
    "cross",        # 12
    "check",        # 13
    "tear",         # 14
    "laugh",        # 15
    "heart_break",  # 16
    "speechless",   # 17
    "lightning",    # 18
    "wave",         # 19
    "lightbulb"     # 20
]

sub_resources = []
animations_def = []

for row_idx, anim_name in enumerate(anim_names):
    y_pos = row_idx * 16
    frame_refs = []
    for col_idx in range(8):
        x_pos = col_idx * 16
        sub_id = f"AtlasTexture_{anim_name}_{col_idx}"
        sub_resources.append(f"""[sub_resource type="AtlasTexture" id="{sub_id}"]
atlas = ExtResource("1_emote_tex")
region = Rect2({x_pos}, {y_pos}, 16, 16)
""")
        frame_refs.append(f'{{"duration": 1.0, "texture": SubResource("{sub_id}")}}')
    
    frames_str = ", ".join(frame_refs)
    animations_def.append(f"""{{
"frames": [{frames_str}],
"loop": true,
"name": &"{anim_name}",
"speed": 8.0
}}""")

content = header + "\n".join(sub_resources) + f"""
[resource]
animations = [{", ".join(animations_def)}]
"""

output_path = "scenes/test/character_emotes.tres"
with open(output_path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Created {output_path} with {len(anim_names)} animations!")
