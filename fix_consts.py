import re
import os

with open('analyze.txt', 'r') as f:
    lines = f.readlines()

errors = []
for line in lines:
    if 'invalid_constant' in line:
        parts = line.split(' • ')
        if len(parts) >= 3:
            file_info = parts[2].strip()
            file_parts = file_info.split(':')
            if len(file_parts) == 3:
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
    
    linenos = sorted(list(set(linenos)), reverse=True)
    
    for l in linenos:
        idx = l - 1
        if idx >= len(file_lines):
            continue
        # go backwards up to 20 lines to find 'const '
        for i in range(idx, max(-1, idx - 20), -1):
            if 'const ' in file_lines[i]:
                # Remove const. Be careful not to remove constant declarations like `static const` or `const int`
                # Only remove `const ` before capitalized words (widgets) or before `[` or `{`
                # But to be safe and simple: just replace `const ` with nothing if it's instantiating a widget.
                file_lines[i] = re.sub(r'\bconst\s+(?=[A-Z_\[\{])', '', file_lines[i])
                # if the replacement happened, break
                if 'const ' not in file_lines[i] or re.search(r'\bconst\s+(?=[A-Z_\[\{])', file_lines[i]) is None:
                    break
                
    with open(filename, 'w') as f:
        f.writelines(file_lines)

print(f"Fixed invalid constants in {len(file_to_errors)} files")
