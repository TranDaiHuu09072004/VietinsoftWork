# 29 — Skill: Viết Python Tool an toàn, tránh lỗi cú pháp

> Dùng khi cần viết Python script để thao tác file SQL/HTML/JS trong repo, hoặc bất kỳ lúc nào cần `execute_command` với Python.
>
> Mục tiêu: tránh **SyntaxError**, **quote mismatch**, **PowerShell interpolation** gây hỏng script.

---

## ⚠️ 3 lỗi chết người (NEVER FACTOR)

| # | Lỗi | Hậu quả | Khi nào xảy ra |
|---|---|---|---|
| 1 | **Triple quote trong JS string** | `SyntaxError: unterminated string literal` | Dùng `"""..."""` Python chứa JS string `'"..."'` |
| 2 | **Single quote trong SQL N'...'** | `Incorrect syntax near 'function'` | Viết HTML/JS chứa `'` trong `N'...'` của SQL |
| 3 | **PowerShell inline string** | `Unexpected token`, `Missing closing ')'` | Dùng `-c "..."` dài trên Windows Shell |

---

## Rule 1 — Luôn viết tool trong `.py` file, không inline

❌ **SAI** — 100% sẽ lỗi trên Windows Shell:
```powershell
python -c "content.replace('''foo''', '''bar''')"
```

✅ **ĐÚNG** — viết file `.py` riêng:
```python
# fix_something.py
import re
with open('target.sql', 'r', encoding='utf-8') as f:
    content = f.read()
# ... làm gì thì làm
with open('target.sql', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
```

**Lý do:** PowerShell (cmd.exe) xử lý `\"` và `'` khác hoàn toàn Python. File-based approach tránh mọi conflict.

---

## Rule 2 — Never use triple quotes for JS/SQL content

❌ **SAI** — Python triple quote `"""..."""` chứa JS `'''`:
```python
content = content.replace("""function foo() { return '''; }""", """function bar() {}""")
```

✅ **ĐÚNG** — dùng string concatenation hoặc single-line:
```python
old = "function foo() { return '''; }"
new = "function bar() {}"
content = content.replace(old, new)
```

**Lý do:** Python `"""` kết thúc khi gặp `'''` ở bất kỳ đâu trong content. JS/SQL thường chứa `'''`

---

## Rule 3 — Escape quotes for SQL when writing replacement strings

Khi viết replace code chứa JS strings (mà JS strings sẽ được nhúng trong SQL N'...'):

### 3.1 Content sẽ nhúng vào SQL N'...'
```python
# Trong SQL:  N'...text với ''double single''...'
# Trong Python: dùng "", không dùng '' 
old = "reject(new Error(''Native timeout''));"
new = "reject(new Error(''Cannot connect''));"
```

### 3.2 File Python chứa JS code
Viết JS raw (single quote `'`), Python không convert:
```python
# Code JS embed trong Python string
js_code = "alert('hello');"   # OK, ' trong "" không sao
```

---

## Rule 4 — Luôn verify trước khi write

Trước khi dùng `write_to_file` cho Python script PHỨC TẠP, luôn kiểm tra:
- [ ] Có `'''` (triple single quote) trong content không? → Thay bằng `"""` hoặc `f"""` hoặc gộp biến
- [ ] Có `"""` (triple double quote) trong content không? → Thay bằng single-line `"..."` với `\n`
- [ ] Nếu dùng `"..."` bình thường, có `"` trong content không? → Escape `\"`

---

## Rule 5 — Folder tạm thời để chạy tool

Khi cần viết Python tool để thao tác 1 lần (replace, refactor):
1. Đặt file trong `SQL script/LongKa/` (cùng folder với file cần sửa)
2. Chạy bằng:
```bash
python "SQL script/LongKa/ten_script.py"
```
3. Sau khi chạy xong, xoá file tool nếu không cần giữ

---

## Rule 6 — Debug công thức

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `SyntaxError: unterminated string literal` | Python string chứa `'''` (triple quote) | Chuyển sang `"""` hoặc single-line |
| `SyntaxError: unexpected character after line continuation` | Backslash `\` cuối dòng trong Python string | Dùng `\\` hoặc raw string `r"..."` |
| `re.error: unterminated character set` | Regex chứa `[` không đóng | Double-escape trong Python: `\\[` |
| Lỗi PowerShell `At line:1 char:NN` | Dùng inline `-c "..."` dài | Chuyển sang file `.py` |

---

## Ví dụ pattern an toàn

```python
# ===== AN TOÀN =====
# 1. File-based
# 2. Không triple quote
# 3. Single-line strings
# 4. Có verify cuối

import re

filepath = 'SQL script/LongKa/sp_MainGPS_html.sql'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Sửa JS trong SQL: dùng double quote Python, single quote SQL
old = "reject(new Error(''Native timeout''));"
new = "reject(new Error(''New message''));"
content = content.replace(old, new)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')