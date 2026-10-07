# Script cấu hình toàn bộ 10 bộ Terrain trong tilesets/GroundTiles.png vào tilesets/city_ground.tres
# Mỗi bộ gồm đúng 27 tile theo chuẩn autotile hoàn hảo:
# - 4 góc ngoài bo tròn (8 tile gồm 4 cặp trùng)
# - 4 mép thẳng (8 tile gồm 4 cặp trùng)
# - 4 góc nách bo lõm / cua L (4 tile)
# - 7 ô ruột gạch nối kín 8 hướng (7 tile)

ALL_BITS = [
    'right_side', 'bottom_right_corner', 'bottom_side', 'bottom_left_corner',
    'left_side', 'top_left_corner', 'top_side', 'top_right_corner'
]

TERRAIN_DEFS = [
    {
        'id': 0,
        'name': 'stone_grey',
        'color': 'Color(0.60, 0.60, 0.62, 1)',
        'origin': (0, 10),
        'desc': 'Vỉa hè đá xám'
    },
    {
        'id': 1,
        'name': 'stone_brown',
        'color': 'Color(0.72, 0.48, 0.42, 1)',
        'origin': (6, 10),
        'desc': 'Gạch đá nâu đỏ'
    },
    {
        'id': 2,
        'name': 'stone_dark',
        'color': 'Color(0.42, 0.42, 0.46, 1)',
        'origin': (0, 16),
        'desc': 'Đá lát tối màu'
    },
    {
        'id': 3,
        'name': 'asphalt_black',
        'color': 'Color(0.25, 0.22, 0.26, 1)',
        'origin': (6, 16),
        'desc': 'Nhựa đường đen'
    },
    {
        'id': 4,
        'name': 'grass_green',
        'color': 'Color(0.28, 0.62, 0.32, 1)',
        'origin': (0, 22),
        'desc': 'Thảm cỏ xanh'
    },
    {
        'id': 5,
        'name': 'slate_purple',
        'color': 'Color(0.48, 0.42, 0.52, 1)',
        'origin': (6, 22),
        'desc': 'Đá hoa tím'
    },
    {
        'id': 6,
        'name': 'sand_yellow',
        'color': 'Color(0.88, 0.75, 0.52, 1)',
        'origin': (0, 28),
        'desc': 'Cát vàng'
    },
    {
        'id': 7,
        'name': 'dirt_brown',
        'color': 'Color(0.55, 0.36, 0.32, 1)',
        'origin': (6, 28),
        'desc': 'Đất đỏ nâu'
    },
    {
        'id': 8,
        'name': 'brick_red',
        'color': 'Color(0.62, 0.28, 0.35, 1)',
        'origin': (18, 11),
        'desc': 'Gạch nung đỏ'
    },
    {
        'id': 9,
        'name': 'stone_blue',
        'color': 'Color(0.42, 0.48, 0.65, 1)',
        'origin': (24, 11),
        'desc': 'Đá xanh mát'
    }
]

def build_terrain_tiles(bx, by, terrain_id):
    t_map = {}
    
    # 1. Outer corners
    for xy in [(bx + 2, by + 0), (bx + 0, by + 2)]:
        t_map[xy] = ['right_side', 'bottom_right_corner', 'bottom_side']
    for xy in [(bx + 4, by + 0), (bx + 5, by + 2)]:
        t_map[xy] = ['left_side', 'bottom_left_corner', 'bottom_side']
    for xy in [(bx + 2, by + 5), (bx + 0, by + 4)]:
        t_map[xy] = ['right_side', 'top_side', 'top_right_corner']
    for xy in [(bx + 4, by + 5), (bx + 5, by + 4)]:
        t_map[xy] = ['left_side', 'top_side', 'top_left_corner']

    # 2. Straight edges
    for xy in [(bx + 3, by + 0), (bx + 1, by + 2)]:
        t_map[xy] = ['left_side', 'right_side', 'bottom_left_corner', 'bottom_side', 'bottom_right_corner']
    for xy in [(bx + 3, by + 5), (bx + 1, by + 4)]:
        t_map[xy] = ['left_side', 'right_side', 'top_left_corner', 'top_side', 'top_right_corner']
    for xy in [(bx + 2, by + 1), (bx + 0, by + 3)]:
        t_map[xy] = ['top_side', 'bottom_side', 'right_side', 'top_right_corner', 'bottom_right_corner']
    for xy in [(bx + 4, by + 1), (bx + 5, by + 3)]:
        t_map[xy] = ['top_side', 'bottom_side', 'left_side', 'top_left_corner', 'bottom_left_corner']

    # 3. Inner corners
    t_map[(bx + 2, by + 2)] = [b for b in ALL_BITS if b != 'top_left_corner']
    t_map[(bx + 4, by + 2)] = [b for b in ALL_BITS if b != 'top_right_corner']
    t_map[(bx + 2, by + 4)] = [b for b in ALL_BITS if b != 'bottom_left_corner']
    t_map[(bx + 4, by + 4)] = [b for b in ALL_BITS if b != 'bottom_right_corner']

    # 4. Center fills
    center_coords = [
        (bx + 3, by + 1),
        (bx + 1, by + 3),
        (bx + 2, by + 3),
        (bx + 3, by + 2),
        (bx + 3, by + 3),
        (bx + 3, by + 4),
        (bx + 4, by + 3)
    ]
    for xy in center_coords:
        t_map[xy] = list(ALL_BITS)

    return t_map

# Generate city_ground.tres
lines = [
    '[gd_resource type="TileSet" format=3 uid="uid://dy05553t8lqk5"]',
    '',
    '[ext_resource type="Texture2D" uid="uid://bgvryb8mvitnt" path="res://tilesets/GroundTiles.png" id="1_cyhn1"]',
    '',
    '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_lop5g"]',
    'texture = ExtResource("1_cyhn1")'
]

all_tiles_by_coord = {}

for t_def in TERRAIN_DEFS:
    bx, by = t_def['origin']
    t_id = t_def['id']
    tiles = build_terrain_tiles(bx, by, t_id)
    for coord, bits in tiles.items():
        all_tiles_by_coord[coord] = (t_id, bits)

# Sort coordinates by y then x
for (x, y) in sorted(all_tiles_by_coord.keys(), key=lambda p: (p[1], p[0])):
    t_id, bits = all_tiles_by_coord[(x, y)]
    lines.append(f'{x}:{y}/0 = 0')
    lines.append(f'{x}:{y}/0/terrain_set = 0')
    lines.append(f'{x}:{y}/0/terrain = {t_id}')
    for b in bits:
        lines.append(f'{x}:{y}/0/terrains_peering_bit/{b} = {t_id}')

lines.extend([
    '',
    '[resource]',
    'terrain_set_0/mode = 0'
])

for t_def in TERRAIN_DEFS:
    lines.append(f'terrain_set_0/terrain_{t_def["id"]}/name = "{t_def["name"]}"')
    lines.append(f'terrain_set_0/terrain_{t_def["id"]}/color = {t_def["color"]}')

lines.extend([
    'sources/1 = SubResource("TileSetAtlasSource_lop5g")',
    ''
])

with open('tilesets/city_ground.tres', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f'Successfully generated {len(TERRAIN_DEFS)} terrains with {len(all_tiles_by_coord)} tiles into city_ground.tres!')
