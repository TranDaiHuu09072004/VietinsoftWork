import difflib
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

pay_path = r"C:\Users\cuomed\..\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1358\output.txt"
dev_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1440\output.txt"

# Let's fix the path in case we made a typo
import os
if not os.path.exists(pay_path):
    pay_path = pay_path.replace("cuomed", "cuong.vu")

try:
    with open(pay_path, "r", encoding="utf-8") as f:
        pay_data = json.load(f)
    pay_def = pay_data["rows"][0][0]
    
    with open(dev_path, "r", encoding="utf-8") as f:
        dev_data = json.load(f)
    dev_def = dev_data["rows"][0][0]
    
    pay_lines = [l.strip() for l in pay_def.splitlines() if l.strip()]
    dev_lines = [l.strip() for l in dev_def.splitlines() if l.strip()]
    
    # Also replace 'var ' with 'let ' to normalize variable declarations
    pay_lines_norm = [re.sub(r'\bvar\b', 'let', l) for l in pay_lines]
    dev_lines_norm = [re.sub(r'\bvar\b', 'let', l) for l in dev_lines]
    
    diff = list(difflib.unified_diff(pay_lines_norm, dev_lines_norm, fromfile="Vietinsoft_Pay_Normalized", tofile="Paradise_Dev_Normalized", lineterm=""))
    
    print(f"Normalized diff lines count: {len(diff)}")
    for line in diff[:100]:
        print(line)
        
except Exception as e:
    print("Error:", e)
