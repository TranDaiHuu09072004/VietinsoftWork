from pathlib import Path

p = Path(r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\sp_MainStyleCSSParadise_v3.sql')
s = p.read_text(encoding='utf-8')

in_str = False
i = 0
while i < len(s):
    if s[i] == "'":
        if in_str and i + 1 < len(s) and s[i + 1] == "'":
            i += 2
            continue
        in_str = not in_str
    i += 1
print('FINAL_IN_STRING for style script:', in_str)
