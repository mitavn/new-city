from PIL import Image
import numpy as np
import re

im = Image.open('tilesets/CIty Decoration.png').convert('RGBA')
arr = np.array(im)
cols, rows = im.size[0]//16, im.size[1]//16

# Read existing decoration.tres
with open('tilesets/decoration.tres', 'r', encoding='utf-8') as f:
    content = f.read()

# Find existing tile coordinates in the atlas source
existing = set()
for m in re.finditer(r'(\d+):(\d+)(?:/size_in_atlas = Vector2i\((\d+), (\d+)\))?/0 = 0', content):
    x, y = int(m.group(1)), int(m.group(2))
    existing.add((x, y))

print(f'Existing tiles in decoration.tres: {len(existing)}')

# Find all non-empty tiles in CIty Decoration.png
new_tiles = []
for r in range(rows):
    for c in range(cols):
        tile = arr[r*16:(r+1)*16, c*16:(c+1)*16]
        if np.any(tile[:,:,3] > 10):
            if (c, r) not in existing:
                new_tiles.append((c, r))

print(f'Found {len(new_tiles)} additional non-empty tiles to register!')

# Append new tiles before [resource]
# In decoration.tres, the atlas source has entries like:
# x:y/0 = 0
insert_idx = content.find('\n[resource]')
if insert_idx == -1:
    print('Error: [resource] section not found')
else:
    new_lines = []
    for x, y in sorted(new_tiles, key=lambda p: (p[1], p[0])):
        new_lines.append(f'{x}:{y}/0 = 0')
    
    updated_content = content[:insert_idx] + '\n' + '\n'.join(new_lines) + content[insert_idx:]
    with open('tilesets/decoration.tres', 'w', encoding='utf-8') as f:
        f.write(updated_content)
    print(f'Successfully updated tilesets/decoration.tres with {len(new_tiles)} new tiles! Total tiles now: {len(existing) + len(new_tiles)}')
