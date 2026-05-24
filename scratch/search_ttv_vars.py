import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

dev_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1440\output.txt"

try:
    with open(dev_path, "r", encoding="utf-8") as f:
        dev_data = json.load(f)
    dev_def = dev_data["rows"][0][0]
    
    lines = dev_def.splitlines()
    
    targets = ["ttvExpanded", "ttvSearch", "ttvSkip", "ttvTake", "_isLoadingMore", "ttvSort"]
    
    for t in targets:
        print(f"\nReferences to '{t}':")
        refs = []
        for idx, line in enumerate(lines, 1):
            if t in line:
                refs.append((idx, line.strip()))
        print(f"Total references: {len(refs)}")
        for r in refs[:10]:
            print(f"  Line {r[0]}: {r[1]}")
            
except Exception as e:
    print("Error:", e)
