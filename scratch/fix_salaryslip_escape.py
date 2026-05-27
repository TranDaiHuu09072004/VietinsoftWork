"""Fix single-quote escaping in salaryslip ParadiseStyle script."""
path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\redesign_MnuPRL445_salaryslip_ParadiseStyle_20260527.sql'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# The stripHtml function has .replace(/[<>"'&]/g, "") inside T-SQL N'...'
# The ' char closes the T-SQL string. Fix: use ' unicode escape.
# Pattern to find: .replace(/[<>"'&]/g, "")
# The ' is U+0027

SQ = chr(0x27)  # single quote character

# Find all instances of the problematic regex
old_regex = f'.replace(/[<>"{SQ}&]/g, "")'
new_regex = '.replace(/[<>"\\u0027&]/g, "")'

count = content.count(old_regex)
print(f"Found {count} occurrences of problematic stripHtml regex")

if count > 0:
    content = content.replace(old_regex, new_regex)
    print("Replaced successfully")
else:
    # Try alternative search
    idx = content.find('stripHtml')
    if idx >= 0:
        chunk = content[idx:idx+120]
        print(f"stripHtml context: {repr(chunk)}")

    # Try broader search
    idx = content.find('/[<>"')
    if idx >= 0:
        chunk = content[idx:idx+40]
        hex_str = chunk.encode('utf-8').hex(' ')
        print(f"Regex context: {repr(chunk)}")
        print(f"Hex: {hex_str}")

# Also check for any other ' chars inside JS that might break T-SQL N-string
# We're looking for ' inside the big N'...' block that aren't properly escaped
# But most uses should be fine since they use " for JS strings

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify
with open(path, 'r', encoding='utf-8') as f:
    verify = f.read()

# Check that \\u0027 is now in place
if '\\u0027' in verify:
    print("SUCCESS: \\u0027 properly placed in file")
else:
    print("WARNING: \\u0027 not found in file")

# Double-check no remaining problematic patterns
remaining = verify.count(f'.replace(/[<>"{SQ}&]/g, "")')
print(f"Remaining problematic patterns: {remaining}")
