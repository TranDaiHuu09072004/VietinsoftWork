"""Fix the regex single-quote escape in fix script to use unicode pattern."""
import sys

path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\fix_menu_HelloVietinsoft_ParadiseStyle_v3_20260527.sql'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# The problematic pattern: .replace(/'/g, "&#039;");
# Inside T-SQL N'...', the ' char (U+0027) closes the string prematurely.
# Rule 2 / Section 3.2 Case B of 17_RendererHtmlJsSafe.md:
#   MUST use unicode escape: .replace(/'/g, "&#039;");
# This is safe in T-SQL N-strings because ' has no single-quote chars.

old = ".replace(/\x27/g, " + '"' + "&#039;" + '"' + ");"
new = ".replace(/\\u0027/g, " + '"' + "&#039;" + '"' + ");"

count = content.count(old)
print(f"Found {count} occurrences of old pattern")
if count > 0:
    content = content.replace(old, new)
    print("Replaced successfully")
else:
    print("ERROR: Old pattern not found!")
    # Search for what's actually there
    idx = content.find("&#039")
    if idx > 0:
        print(f"Context around &#039: {repr(content[idx-30:idx+15])}")
    sys.exit(1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify
with open(path, 'r', encoding='utf-8') as f:
    verify = f.read()
idx = verify.find("&#039")
if idx > 0:
    chunk = verify[idx-20:idx+10]
    print(f"Verification chunk: {repr(chunk)}")
    hex_str = chunk.encode('utf-8').hex(' ')
    print(f"Hex: {hex_str}")
    # Check for the 6-byte sequence '
    target = b'\\u0027'.decode('utf-8')
    if target in chunk:
        print("SUCCESS: \\u0027 properly in file")
    else:
        print("FAILED: Still has raw single quote")
        sys.exit(1)
