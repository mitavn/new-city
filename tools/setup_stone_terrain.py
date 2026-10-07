# Script cấu hình chuẩn 100% TileSet city_ground.tres
# Hỗ trợ 2 Terrain tiện lợi:
# - Terrain 0: "stone_platform" (23 tiles: bo góc ngoài, mép cạnh, ruột gạch. Tuyệt đối KHÔNG BỊ CHÍP LÕM khi vẽ bằng cọ tự do!)
# - Terrain 1: "stone_road_full" (27 tiles: đầy đủ cả 4 góc lõm L-shape cho khúc cua ngã rẽ)

ALL_BITS = [
    'right_side', 'bottom_right_corner', 'bottom_side', 'bottom_left_corner',
    'left_side', 'top_left_corner', 'top_side', 'top_right_corner'
]

# 1. Outer Corners (Góc bo tròn ngoài)
outer_corners = {
    (2, 10): ['right_side', 'bottom_right_corner', 'bottom_side'],
    (0, 12): ['right_side', 'bottom_right_corner', 'bottom_side'],
    (4, 10): ['left_side', 'bottom_left_corner', 'bottom_side'],
    (5, 12): ['left_side', 'bottom_left_corner', 'bottom_side'],
    (2, 15): ['right_side', 'top_side', 'top_right_corner'],
    (0, 14): ['right_side', 'top_side', 'top_right_corner'],
    (4, 15): ['left_side', 'top_side', 'top_left_corner'],
    (5, 14): ['left_side', 'top_side', 'top_left_corner']
}

# 2. Straight Edges (Mép thẳng ngoài)
straight_edges = {
    (3, 10): ['left_side', 'right_side', 'bottom_left_corner', 'bottom_side', 'bottom_right_corner'],
    (1, 12): ['left_side', 'right_side', 'bottom_left_corner', 'bottom_side', 'bottom_right_corner'],
    (3, 15): ['left_side', 'right_side', 'top_left_corner', 'top_side', 'top_right_corner'],
    (1, 14): ['left_side', 'right_side', 'top_left_corner', 'top_side', 'top_right_corner'],
    (2, 11): ['top_side', 'bottom_side', 'right_side', 'top_right_corner', 'bottom_right_corner'],
    (0, 13): ['top_side', 'bottom_side', 'right_side', 'top_right_corner', 'bottom_right_corner'],
    (4, 11): ['top_side', 'bottom_side', 'left_side', 'top_left_corner', 'bottom_left_corner'],
    (5, 13): ['top_side', 'bottom_side', 'left_side', 'top_left_corner', 'bottom_left_corner']
}

# 3. Center Fills (Ruột gạch 8 hướng kín)
center_fills = [(3, 11), (1, 13), (2, 13), (3, 12), (3, 13), (3, 14), (4, 13)]

# 4. Inner Corners (Góc lõm / cua nách bo trong)
inner_corners = {
    (2, 12): [b for b in ALL_BITS if b != 'top_left_corner'],
    (4, 12): [b for b in ALL_BITS if b != 'top_right_corner'],
    (2, 14): [b for b in ALL_BITS if b != 'bottom_left_corner'],
    (4, 14): [b for b in ALL_BITS if b != 'bottom_right_corner']
}

lines = [
    '[gd_resource type="TileSet" format=3 uid="uid://dy05553t8lqk5"]',
    '',
    '[ext_resource type="Texture2D" uid="uid://bgvryb8mvitnt" path="res://tilesets/GroundTiles.png" id="1_cyhn1"]',
    '',
    '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_lop5g"]',
    'texture = ExtResource("1_cyhn1")'
]

all_coords = sorted(set(list(outer_corners.keys()) + list(straight_edges.keys()) + center_fills + list(inner_corners.keys())), key=lambda p: (p[1], p[0]))

for (x, y) in all_coords:
    lines.append(f'{x}:{y}/0 = 0')
    lines.append(f'{x}:{y}/0/terrain_set = 0')
    
    is_inner = (x, y) in inner_corners
    if not is_inner:
        # Thuộc Terrain 0 (stone_platform)
        lines.append(f'{x}:{y}/0/terrain = 0')
        if (x, y) in outer_corners:
            bits = outer_corners[(x, y)]
        elif (x, y) in straight_edges:
            bits = straight_edges[(x, y)]
        else:
            bits = ALL_BITS
        for b in bits:
            lines.append(f'{x}:{y}/0/terrains_peering_bit/{b} = 0')
    else:
        # Thuộc Terrain 1 (stone_inner_corner)
        lines.append(f'{x}:{y}/0/terrain = 1')
        for b in inner_corners[(x, y)]:
            lines.append(f'{x}:{y}/0/terrains_peering_bit/{b} = 1')

lines.extend([
    '',
    '[resource]',
    'terrain_set_0/mode = 0',
    'terrain_set_0/terrain_0/name = "stone_platform"',
    'terrain_set_0/terrain_0/color = Color(0.48, 0.42, 0.15, 1)',
    'terrain_set_0/terrain_1/name = "stone_inner_corners"',
    'terrain_set_0/terrain_1/color = Color(0.85, 0.35, 0.15, 1)',
    'sources/1 = SubResource("TileSetAtlasSource_lop5g")',
    ''
])

with open('tilesets/city_ground.tres', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print("Successfully generated city_ground.tres with clean stone_platform & inner_corners!")
