import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

pay_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1358\output.txt"

try:
    with open(pay_path, "r", encoding="utf-8") as f:
        pay_data = json.load(f)
    pay_def = pay_data["rows"][0][0]
    
    lines = pay_def.splitlines()
    
    targets = ["ttvExpanded", "ttvSearch", "ttvSkip", "ttvTake", "_isLoadingMore", "ttvSort"]
    
    for t in targets:
        refs = []
        for idx, line in enumerate(lines, 1):
            if t in line:
                refs.append((idx, line.strip()))
        print(f"References to '{t}' in Vietinsoft_Pay: {len(refs)}")
        
except Exception as e:
    print("Error:", e)
