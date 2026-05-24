import re
from pathlib import Path

file_path = Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\migrate_menu_complaint_20260523.sql")
text = file_path.read_text(encoding="utf-8")

# Find all occurrences of fa-
matches = re.findall(r'\bfa-[a-z0-9-]+', text)
unique_matches = sorted(list(set(matches)))

print("=== Found FontAwesome Classes ===")
for m in unique_matches:
    print(m)
