import json
import re

pay_output_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1358\output.txt"

with open(pay_output_path, "r", encoding="utf-8") as f:
    pay_data = json.load(f)
task_list_html_def = pay_data["rows"][0][0]

# Find all occurrences of classes containing "fa-"
matches = re.findall(r'class=["\'][^"\']*\b(fa-[a-zA-Z0-9-]+)\b[^"\']*["\']', task_list_html_def)
# Let's also look for any string containing fa- like fa-solid, fa-regular, fa-circle etc.
all_fa_classes = re.findall(r'\bfa-[a-zA-Z0-9-]+\b', task_list_html_def)

print("Unique classes matching fa-*:")
for c in sorted(set(all_fa_classes)):
    print(f" - {c}")
