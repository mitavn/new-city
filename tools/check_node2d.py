import struct, base64

with open('scenes/test/node_2d.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

import re
matches = re.findall(r'tile_map_data = PackedByteArray\("([^"]+)"\)', content)
print(f'Found {len(matches)} tile_map_data blocks in node_2d.tscn')

for idx, m in enumerate(matches):
    raw = base64.b64decode(m)
    print(f'Layer {idx} count = {len(raw)//12}')
    tiles = []
    for i in range(0, len(raw), 12):
        x, y, src, ax, ay, alt = struct.unpack('<hhhhhh', raw[i:i+12])
        tiles.append((x, y, src, ax, ay))
    # Check coords
    print(f'Layer {idx} sample coords:', tiles[:10])
    # check if any (ax, ay) in (2, 12), (4, 12), (2, 14), (4, 14)
    inners = [t for t in tiles if (t[3], t[4]) in [(2,12), (4,12), (2,14), (4,14)]]
    print(f'Layer {idx} inners count = {len(inners)}')
    if inners:
        print('Inners:', inners[:10])
