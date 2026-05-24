import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

file_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1358\output.txt"

try:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Find all occurrences of 'fa-'
    pos = 0
    found = []
    while True:
        pos = content.find('fa-', pos)
        if pos == -1:
            break
        snippet = content[max(0, pos-40):min(len(content), pos+40)].replace('\r', ' ').replace('\n', ' ')
        found.append((pos, snippet))
        pos += 3
        
    print(f"Found {len(found)} occurrences of 'fa-':")
    for idx, (p, s) in enumerate(found[:20]):
        print(f"  {idx+1}. Index {p}: {s}")
    if len(found) > 20:
        print(f"  ... and {len(found) - 20} more")
        
except Exception as e:
    print("Error:", e)
