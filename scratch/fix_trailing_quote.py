"""Fix trailing \') → ''') in salaryslip script HTML concatenations."""
path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\redesign_MnuPRL445_salaryslip_ParadiseStyle_20260527.sql'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix \') → ''') in HTML onclick handlers
# Pattern: + N'...' + N'\')  →  + N'...' + N''')
# The \') appears after literal strings in N'...' blocks
old = "+ N'\\')"
new = "+ N''')"

count = content.count(old)
print(f"Found {count} occurrences of + N'\\')'")
content = content.replace(old, new)
print(f"Replaced {count} occurrences")

# Verify
remaining = content.count("+ N'\\')")
print(f"Remaining: {remaining}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
