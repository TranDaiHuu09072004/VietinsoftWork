import difflib
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

pay_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1422\output.txt"
dev_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1434\output.txt"

try:
    with open(pay_path, "r", encoding="utf-8") as f:
        pay_data = json.load(f)
    pay_def = pay_data["rows"][0][0]
    
    with open(dev_path, "r", encoding="utf-8") as f:
        dev_data = json.load(f)
    dev_def = dev_data["rows"][0][0]
    
    pay_lines = pay_def.splitlines()
    dev_lines = dev_def.splitlines()
    
    diff = list(difflib.unified_diff(pay_lines, dev_lines, fromfile="Vietinsoft_Pay", tofile="Paradise_Dev", lineterm=""))
    
    print(f"Diff lines count: {len(diff)}")
    for line in diff[:100]:
        print(line)
        
except Exception as e:
    print("Error:", e)
