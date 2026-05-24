import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

file_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1370\output.txt"

try:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    procs = set(re.findall(r'\bsp_[a-zA-Z0-9_]+\b', content))
    
    print("Found procedures in sp_Task_TaskDetail_html:")
    for p in sorted(procs):
        print(f"  - {p}")
        
except Exception as e:
    print("Error:", e)
