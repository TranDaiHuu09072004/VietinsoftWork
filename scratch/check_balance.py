from pathlib import Path

p = Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\update_menu_ResignationLeave_html_ParadiseStyle.sql")
s = p.read_text(encoding="utf-8-sig")

in_str = False
i = 0
length = len(s)
line = 1

while i < length:
    if s[i] == '\n':
        line += 1
    if s[i] == "'":
        if in_str and i + 1 < length and s[i + 1] == "'":
            i += 2
            continue
        in_str = not in_str
    i += 1

print("FINAL_IN_STRING:", in_str)
if in_str:
    print("Warning: Single quotes are not balanced! Check the string literal borders.")
else:
    print("Success: Single quotes are perfectly balanced.")
