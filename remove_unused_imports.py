import re
import os

with open('analyze2.txt', 'r') as f:
    lines = f.readlines()

errors = []
for line in lines:
    if 'unused_import' in line:
        parts = line.split(' • ')
        if len(parts) >= 3:
            file_info = parts[2].strip()
            file_parts = file_info.split(':')
            if len(file_parts) >= 2:
                filename = file_parts[0]
                lineno = int(file_parts[1])
                errors.append((filename, lineno))

from collections import defaultdict
file_to_errors = defaultdict(list)
for f, l in errors:
    file_to_errors[f].append(l)

for filename, linenos in file_to_errors.items():
    if not os.path.exists(filename):
        continue
    with open(filename, 'r') as f:
        file_lines = f.readlines()
    
    # Sort descending to delete without affecting subsequent line numbers
    linenos = sorted(list(set(linenos)), reverse=True)
    
    for l in linenos:
        idx = l - 1
        if idx >= 0 and idx < len(file_lines):
            # Only delete if it is actually an import statement
            if file_lines[idx].startswith('import'):
                del file_lines[idx]
                
    with open(filename, 'w') as f:
        f.writelines(file_lines)

print(f"Removed unused imports from {len(file_to_errors)} files")
