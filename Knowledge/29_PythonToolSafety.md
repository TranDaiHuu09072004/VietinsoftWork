# 29 — Skill: Viết Python Tool an toàn, tránh lỗi cú pháp

> Dùng khi cần viết Python script để thao tác file SQL/HTML/JS trong repo, hoặc bất kỳ lúc nào cần `execute_command` với Python.
>
> Mục tiêu: tránh **SyntaxError**, **quote mismatch**, **PowerShell interpolation** gây hỏng script.

---

## ⚠️ 3 lỗi chết người (NEVER FACTOR)

| # | Lỗi | Hậu quả | Khi nào xảy ra |
|---|---|---|---|
| 1 | **Triple quote trong JS string** | `SyntaxError: unterminated string literal` | Dùng `"""..."""` Python chứa JS string `'"..."'` |
| 2 | **Single quote không escape trong SQL N'...'** | `Incorrect syntax near 'function'` / `SyntaxError` trong Python | Viết HTML/JS chứa `'` trong `N'...'` của SQL, hoặc Python string chứa SQL content |
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

✅ **ĐÚNG** — dùng single-line strings:
```python
old = "function foo() { return '''; }"
new = "function bar() {}"
content = content.replace(old, new)
```

**Lý do:** Python `"""` kết thúc khi gặp `'''` ở bất kỳ đâu trong content. JS/SQL thường chứa `'''`.

---

## Rule 3 — Escape quotes cho SQL content

Khi viết Python tool để replace content trong file SQL, mọi dấu `'` trong chuỗi JavaScript embed phải được escape `''` (double single quote).

### 3.1 Python string chứa SQL content

```python
# ❌ SAI — Python hiểu kết thúc string tại dấu ' thứ 3
old = "reject(new Error('Native timeout'));"  # SyntaxError

# ✅ ĐÚNG — Dùng '' (double single quote) để biểu thị 1 dấu ' trong SQL
old = "reject(new Error(''Native timeout''));"
```

### 3.2 File Python chứa JS code thuần (không trong SQL)

```python
# JS code đơn thuần — ' trong "" không sao
js_code = "alert('hello');"
```

### 3.3 Biến text nhúng SQL N'...'

```python
# Trong SQL:  N'...text với ''double single''...'
# Trong Python: dùng "", không dùng ''
old = "reject(new Error(''Cannot connect''));"
```

---

## Rule 4 — Luôn verify trước khi write

Trước khi dùng `write_to_file` cho Python script PHỨC TẠP, luôn kiểm tra:
- [ ] Có `'''` (triple single quote) trong content không? → Thay bằng `"""` hoặc gộp biến
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

## Rule 6 — `replace_in_file` SEARCH block phải CHÍNH XÁC tuyệt đối

Khi dùng `replace_in_file`, SEARCH block phải khớp **từng byte** với nội dung file hiện tại. File đã bị sửa bởi tool trước đó → SEARCH block cũ không còn match.

❌ **SAI** — Dùng SEARCH block từ lần đọc file đầu tiên:
```
# Lần 1: đọc file → thấy "console.log('xxx')"
# Lần 2: thay console.log đầu tiên → file thay đổi
# Lần 3: dùng SEARCH block cũ cho dòng khác → KHÔNG MATCH → tool fail
```

✅ **ĐÚNG** — Luôn `read_file` lại ngay trước khi `replace_in_file`:
```
1. read_file → lấy nội dung CHÍNH XÁC hiện tại
2. Copy-paste đoạn cần thay từ nội dung vừa đọc
3. replace_in_file với SEARCH block vừa copy
```

---

## Rule 7 — PowerShell không hỗ trợ `&&` và `||`

❌ **SAI**:
```powershell
cd /d "path" && git pull  # Lỗi: The token '&&' is not a valid statement separator
python script.py || echo FAIL  # Lỗi: The token '||' is not a valid statement separator
```

✅ **ĐÚNG**: Chạy từng lệnh riêng biệt, hoặc dùng `;`:
```powershell
cd /d "path"; git pull
python script.py; if ($LASTEXITCODE -ne 0) { echo FAIL }
```

---

## Debug công thức

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `SyntaxError: unterminated string literal` | Python string chứa `'''` (triple quote) hoặc single quote chưa escape `''` | Chuyển sang `"""` hoặc escape `''` |
| `SyntaxError: unexpected character after line continuation` | Backslash `\` cuối dòng trong Python string | Dùng `\\` hoặc raw string `r"..."` |
| `re.error: unterminated character set` | Regex chứa `[` không đóng | Double-escape trong Python: `\\[` |
| Lỗi PowerShell `At line:1 char:NN` | Dùng inline `-c "..."` dài | Chuyển sang file `.py` |
| `SEARCH block not found` trong `replace_in_file` | File đã bị thay đổi từ lần đọc trước | `read_file` lại trước khi `replace_in_file` |

---

## Ví dụ pattern an toàn

```python
# ===== AN TOÀN =====
# 1. File-based
# 2. Không triple quote
# 3. Single-line strings
# 4. Escape SQL quotes đúng cách
# 5. Có verify cuối

import re

filepath = 'SQL script/LongKa/sp_MainGPS_html.sql'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Sửa JS trong SQL: dùng double quote Python, double single quote SQL
old = "reject(new Error(''Native timeout''));"
new = "reject(new Error(''New message''));"
content = content.replace(old, new)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')