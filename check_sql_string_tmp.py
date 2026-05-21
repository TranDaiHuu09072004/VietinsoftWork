from pathlib import Path

p = Path(r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\update_menu_HelloWorldVietinsoft_paradisestyle_20260520.sql')
s = p.read_text(encoding='utf-8-sig')

def state_at(pos: int):
    in_str = False
    i = 0
    line = 1
    while i < pos:
        if s[i] == '\n':
            line += 1
        if s[i] == "'":
            if in_str and i + 1 < len(s) and s[i + 1] == "'":
                i += 2
                continue
            in_str = not in_str
        i += 1
    return in_str, line

in_str = False
i = 0
while i < len(s):
    if s[i] == "'":
        if in_str and i + 1 < len(s) and s[i + 1] == "'":
            i += 2
            continue
        in_str = not in_str
    i += 1
print('FINAL_IN_STRING', in_str)
for kw in ['<script>', 'var EMPTY_MSG', 'var LOADING_MSG', 'function escapeHtml', 'function setCount', 'function render', 'function setLoading', 'function normalizeRows', 'function loadData', '</script>', 'MERGE dbo.tblHtmlScriptCache']:
    idx = s.find(kw)
    inside, line = state_at(idx)
    print(f'{line}: {kw}: inside_string={inside}')

bad = ['background:', 'background-color', 'background-image', 'linear-gradient', 'radial-gradient', 'rgba(', 'style=', ".replace(/''/g"]
for b in bad:
    print(f'PATTERN {b!r}:', s.lower().find(b.lower()))
