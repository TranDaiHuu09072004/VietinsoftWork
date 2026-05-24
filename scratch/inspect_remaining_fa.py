from pathlib import Path
import re

file_path = Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\migrate_menu_complaint_20260523.sql")
content = file_path.read_text(encoding="utf-8")

lines = content.splitlines()
print("=== Remaining FontAwesome classes in migrate_menu_complaint_20260523.sql ===")
for idx, line in enumerate(lines, 1):
    if 'fa-' in line:
        print(f"Line {idx}: {line.strip()}")
